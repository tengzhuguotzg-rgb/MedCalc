import { Patient, PatientDataPoint, PatientRecord, PatientAlert, PatientDiagnosis, PatientLabAlert, PatientDashboard, DATA_DOMAINS } from '../model/Patient';
import { PatientRepository } from './PatientRepository';
import { ImageStore } from './ImageStore';
import { AssistantService, CalcMatch, DataFieldSpec, CalcInputSpec } from './AssistantService';
import { CalcResult } from '../engine/CalcEngine';
import { CALCULATORS } from '../model/CalculatorRegistry';
import { DiagnosisEngine, DiagnosisMatch, DiagnosisResult, PartialMatch } from './DiagnosisEngine';
import { DiagnosisRule } from '../model/DiagnosisRules';
import { sendVisionRequest, ApiServiceConfig } from './LlmService';
import { PreferencesService } from './PreferencesService';
import { hilog } from '@kit.PerformanceAnalysisKit';

class CalcResultJson {
  value: number | null = null;
  unit: string = '';
  tier: string = '';
  tierClass: string = '';
  footnote: string = '';
}

const FIELD_PRIORITY: string[] = [
  'sbp', 'dbp', 'map', 'hr', 'rr', 'temp', 'spo2',
  'crp', 'pct', 'esr', 'il6',
  'tnt', 'ckmb', 'ntprobnp',
  'ph', 'paco2', 'pao2', 'hco3', 'lac', 'fio2',
  'na', 'k', 'cl', 'ca', 'mg', 'p',
  'creatinine', 'bun', 'urineOutput', 'gfr',
  'bilirubin', 'alb', 'alt', 'ast', 'ammonia',
  'hgb', 'platelet', 'wbc', 'mcv',
  'inr', 'aptt', 'fib', 'dDimer',
  'glu', 'ck', 'ldh',
  'tsh', 'ft3', 'ft4', 'cortisol',
  'gcs', 'rassScore', 'vaso', 'peep',
];

function buildDataSummaryWithLabels(latestData: Map<string, string>, specs: DataFieldSpec[], maxFields: number): string {
  const labelMap = new Map<string, string>();
  for (let i = 0; i < specs.length; i++) {
    labelMap.set(specs[i].key, specs[i].label);
  }
  const prioritized: string[] = [];
  const remaining: string[] = [];
  const prioritySet = new Set<string>();
  for (let i = 0; i < FIELD_PRIORITY.length; i++) {
    prioritySet.add(FIELD_PRIORITY[i]);
  }
  const keys = Array.from(latestData.keys());
  for (let i = 0; i < keys.length; i++) {
    if (keys[i] === 'reportdate' || keys[i] === 'reporttime' || keys[i].endsWith('Unit')) {
      continue;
    }
    if (latestData.has(keys[i]) && prioritySet.has(keys[i])) {
      prioritized.push(keys[i]);
    } else if (latestData.has(keys[i])) {
      remaining.push(keys[i]);
    }
  }
  const ordered = prioritized.concat(remaining);
  let summary = '';
  for (let i = 0; i < ordered.length && i < maxFields; i++) {
    const key = ordered[i];
    const label = labelMap.get(key);
    const displayLabel = label !== undefined && label.length > 0 ? label : key;
    summary += displayLabel + '=' + (latestData.get(key) || '') + ' ';
  }
  return summary;
}

export class PatientService {
  private static instance: PatientService | null = null;
  private repo: PatientRepository = PatientRepository.getInstance();
  private imageStore: ImageStore = ImageStore.getInstance();
  private assistantService: AssistantService = AssistantService.getInstance();
  private diagnosisEngine: DiagnosisEngine = DiagnosisEngine.getInstance();

  private constructor() {}

  static getInstance(): PatientService {
    if (!PatientService.instance) {
      PatientService.instance = new PatientService();
    }
    return PatientService.instance;
  }

  async createPatient(name: string, bedNo: string, age: number, sex: string): Promise<Patient> {
    const patient = new Patient();
    patient.id = 'pt_' + Date.now().toString();
    patient.name = name;
    patient.bedNo = bedNo;
    patient.age = age;
    patient.sex = sex;
    patient.createdAt = Date.now();
    patient.updatedAt = Date.now();
    await this.repo.insertPatient(patient);
    return patient;
  }

  async getPatients(keyword: string): Promise<Patient[]> {
    return await this.repo.queryPatients(keyword);
  }

  async getPatientById(id: string): Promise<Patient | null> {
    return await this.repo.getPatientById(id);
  }

  async updatePatient(patient: Patient): Promise<void> {
    patient.updatedAt = Date.now();
    await this.repo.updatePatient(patient);
  }

  async deletePatient(id: string): Promise<void> {
    this.imageStore.deletePatientImages(id);
    await this.repo.deleteDiagnosesByPatient(id);
    await this.repo.deleteLabAlertsByPatient(id);
    await this.repo.deletePatient(id);
  }

  async mergeExtractedData(patientId: string, extractedData: Record<string, string>, source: string, note: string, recordId: string): Promise<void> {
    let reportDate = '';
    let reportTime = '';
    try {
      const rd = extractedData['reportdate'];
      if (rd !== undefined && rd !== null && typeof rd === 'string') {
        reportDate = rd;
      }
      const rt = extractedData['reporttime'];
      if (rt !== undefined && rt !== null && typeof rt === 'string') {
        reportTime = rt;
      }
    } catch (e) {
      // ignore
    }
    const examTime = this.parseExamTime(reportDate, reportTime);

    const entries = Object.entries(extractedData);
    const now = Date.now();
    let changed = false;

    for (let i = 0; i < entries.length; i++) {
      const key = entries[i][0];
      const val = entries[i][1];
      if (val.length === 0) {
        continue;
      }
      if (key === 'reportdate' || key === 'reporttime') {
        continue;
      }
      const existing = await this.repo.getLatestValue(patientId, key);
      if (existing !== val) {
        const dp = new PatientDataPoint();
        dp.patientId = patientId;
        dp.fieldKey = key;
        dp.value = val;
        dp.source = source;
        dp.timestamp = now;
        dp.examTime = examTime;
        dp.note = recordId.length > 0 ? recordId : note;
        await this.repo.insertDataPoint(dp);
        changed = true;
      }
    }

    if (changed) {
      const patient = await this.repo.getPatientById(patientId);
      if (patient) {
        patient.updatedAt = now;
        await this.repo.updatePatient(patient);
      }
      await this.refreshAlerts(patientId);
    }
  }

  parseExamTime(dateStr: string, timeStr: string): number {
    if (dateStr.length === 0) {
      return 0;
    }
    try {
      let isoStr = dateStr;
      if (timeStr.length > 0) {
        isoStr += 'T' + timeStr;
      } else {
        isoStr += 'T00:00';
      }
      const d = new Date(isoStr);
      const ts = d.getTime();
      if (ts > 0) {
        return ts;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  async addManualData(patientId: string, fieldKey: string, value: string, recordId: string): Promise<void> {
    const existing = await this.repo.getLatestValue(patientId, fieldKey);
    if (existing === value) {
      return;
    }
    const dp = new PatientDataPoint();
    dp.patientId = patientId;
    dp.fieldKey = fieldKey;
    dp.value = value;
    dp.source = 'manual';
    dp.timestamp = Date.now();
    dp.note = recordId.length > 0 ? recordId : '手动录入';
    await this.repo.insertDataPoint(dp);

    const patient = await this.repo.getPatientById(patientId);
    if (patient) {
      patient.updatedAt = Date.now();
      await this.repo.updatePatient(patient);
    }
    await this.refreshAlerts(patientId);
  }

  async saveRecord(patientId: string, type: string, filePath: string, textContent: string, extractedJson: string, label: string): Promise<PatientRecord> {
    const record = new PatientRecord();
    record.id = 'rec_' + Date.now().toString();
    record.patientId = patientId;
    record.type = type;
    record.filePath = filePath;
    record.textContent = textContent;
    record.extractedJson = extractedJson;
    record.timestamp = Date.now();
    record.label = label;
    await this.repo.insertRecord(record);
    return record;
  }

  async getRecords(patientId: string): Promise<PatientRecord[]> {
    return await this.repo.getRecordsByPatient(patientId);
  }

  async deleteRecord(id: string): Promise<void> {
    const record = await this.repo.getRecordById(id);
    if (!record) {
      return;
    }
    if (record.filePath.length > 0) {
      this.imageStore.deleteImage(record.filePath);
    }
    await this.repo.deleteDataByNote(record.patientId, id);
    if (record.extractedJson.length > 2) {
      const parsed: Object | null = JSON.parse(record.extractedJson);
      if (parsed !== null) {
        const entries = Object.entries(parsed as Record<string, string>);
        const keys: string[] = [];
        for (let i = 0; i < entries.length; i++) {
          keys.push(entries[i][0]);
        }
        await this.repo.deleteDataByFieldKeys(record.patientId, keys, record.timestamp);
      }
    }
    if (record.type === 'manual' && record.textContent.length > 0) {
      const eqIdx = record.textContent.indexOf('=');
      if (eqIdx > 0) {
        const key = record.textContent.substring(0, eqIdx);
        await this.repo.deleteDataByFieldKeys(record.patientId, [key], record.timestamp);
      }
    }
    await this.repo.deleteRecord(id);
    const patient = await this.repo.getPatientById(record.patientId);
    if (patient) {
      patient.updatedAt = Date.now();
      await this.repo.updatePatient(patient);
    }
    await this.repo.resolveAllDiagnoses(record.patientId);
    await this.repo.resolveAllLabAlerts(record.patientId);
    await this.repo.resolveAllAlerts(record.patientId);
    await this.refreshAlerts(record.patientId);
  }

  async refreshAlerts(patientId: string): Promise<PatientAlert[]> {
    const latestData = await this.repo.getLatestData(patientId);
    const dataRecord: Record<string, string> = {};
    latestData.forEach((value: string, key: string) => {
      dataRecord[key] = value;
    });

    const matches = this.assistantService.computeAllMatchesFromRecord(dataRecord);
    const now = Date.now();
    const matchedCalcIds = new Set<string>();
    const alertResults = new Map<string, CalcResult>();

    for (let i = 0; i < matches.length; i++) {
      const match = matches[i];
      if (match.completeness < 100 || !match.result) {
        continue;
      }
      matchedCalcIds.add(match.calcId);
      alertResults.set(match.calcId, match.result);
      const resultObj = new CalcResultJson();
      resultObj.value = match.result.value;
      resultObj.unit = match.result.unit;
      resultObj.tier = match.result.tier;
      resultObj.tierClass = match.result.tierClass;
      resultObj.footnote = match.result.footnote;
      const resultJson = JSON.stringify(resultObj as Object);
      await this.repo.upsertAlert(patientId, match.calcId, match.calcName, match.completeness, resultJson, now);
    }

    const allSpecs = this.assistantService.getCalcInputSpecs();
    for (let i = 0; i < allSpecs.length; i++) {
      const spec = allSpecs[i];
      if (!matchedCalcIds.has(spec.calcId)) {
        await this.repo.resolveAlertsForCalc(patientId, spec.calcId);
      }
    }

    await this.refreshDiagnoses(patientId, latestData, alertResults);

    return await this.repo.getActiveAlerts(patientId);
  }

  async getDashboard(patientId: string): Promise<PatientDashboard> {
    const patient = await this.repo.getPatientById(patientId);
    const dashboard = new PatientDashboard();
    if (!patient) {
      return dashboard;
    }
    dashboard.patient = patient;
    dashboard.latestData = await this.repo.getLatestData(patientId);
    dashboard.alerts = await this.repo.getActiveAlerts(patientId);
    dashboard.diagnoses = await this.repo.getActiveDiagnoses(patientId);
    dashboard.labAlerts = await this.repo.getActiveLabAlerts(patientId);
    dashboard.records = await this.repo.getRecordsByPatient(patientId);
    let warningAlertCount = 0;
    for (let i = 0; i < dashboard.alerts.length; i++) {
      const parsed: Object | null = JSON.parse(dashboard.alerts[i].resultJson);
      if (parsed !== null) {
        const obj = parsed as Record<string, string>;
        const tierClass = obj['tierClass'];
        if (tierClass !== 'tier-ok' && tierClass !== 'tier-info') {
          warningAlertCount++;
        }
      }
    }
    dashboard.alertCount = warningAlertCount;
    dashboard.diagnosisCount = dashboard.diagnoses.length;
    dashboard.labAlertCount = dashboard.labAlerts.length;
    dashboard.domainTags = this.computeDomainTags(dashboard.latestData);
    return dashboard;
  }

  async getDataTimeline(patientId: string, fieldKey: string): Promise<PatientDataPoint[]> {
    return await this.repo.getDataTimeline(patientId, fieldKey);
  }

  async updateExamTime(dataPointId: number, examTime: number): Promise<void> {
    await this.repo.updateExamTime(dataPointId, examTime);
  }

  async getAlertCounts(): Promise<Map<string, number>> {
    const allCounts = await this.repo.getAllActiveAlertCount();
    if (allCounts.size === 0) {
      return allCounts;
    }
    const warningCounts = new Map<string, number>();
    const patientIds = Array.from(allCounts.keys());
    for (let i = 0; i < patientIds.length; i++) {
      const pid = patientIds[i];
      const alerts = await this.repo.getActiveAlerts(pid);
      let count = 0;
      for (let j = 0; j < alerts.length; j++) {
        const parsed: Object | null = JSON.parse(alerts[j].resultJson);
        if (parsed !== null) {
          const obj = parsed as Record<string, string>;
          const tierClass = obj['tierClass'];
          if (tierClass !== 'tier-ok' && tierClass !== 'tier-info') {
            count++;
          }
        }
      }
      warningCounts.set(pid, count);
    }
    return warningCounts;
  }

  async getAlertCount(patientId: string): Promise<number> {
    return await this.repo.getAlertCount(patientId);
  }

  private computeDomainTags(data: Map<string, string>): string[] {
    const tags: string[] = [];
    const domainEntries = Object.entries(DATA_DOMAINS);
    for (let i = 0; i < domainEntries.length; i++) {
      const domainName = domainEntries[i][0];
      const domainKeys = domainEntries[i][1];
      let hasData = false;
      for (let j = 0; j < domainKeys.length; j++) {
        if (data.has(domainKeys[j])) {
          hasData = true;
          break;
        }
      }
      if (hasData) {
        tags.push(domainName);
      }
    }
    return tags;
  }

  async refreshDiagnoses(patientId: string, latestData: Map<string, string>,
    alertResults: Map<string, CalcResult>): Promise<void> {
    const diagnosisResult = this.diagnosisEngine.evaluate(latestData, alertResults);
    const now = Date.now();
    const matchedRuleIds = new Set<string>();
    const matchedLabRuleIds = new Set<string>();
    const newMatches: DiagnosisMatch[] = [];

    const existingDiagnoses = await this.repo.getActiveDiagnoses(patientId);
    const existingRuleIds = new Set<string>();
    for (let i = 0; i < existingDiagnoses.length; i++) {
      existingRuleIds.add(existingDiagnoses[i].ruleId);
    }

    const fieldSpecs = this.assistantService.getDataFieldSpecs();
    const labelMap = new Map<string, string>();
    const unitMap = new Map<string, string>();
    for (let i = 0; i < fieldSpecs.length; i++) {
      labelMap.set(fieldSpecs[i].key, fieldSpecs[i].label);
      unitMap.set(fieldSpecs[i].key, fieldSpecs[i].unit);
    }

    for (let i = 0; i < diagnosisResult.confirmed.length; i++) {
      const match = diagnosisResult.confirmed[i];
      matchedRuleIds.add(match.rule.id);
      const isNew = !existingRuleIds.has(match.rule.id);
      const sortOrder = this.computeSortOrder('rule', existingDiagnoses);
      await this.repo.upsertDiagnosis(
        patientId, match.rule.id, match.rule.name, match.rule.category,
        match.rule.urgency, 'rule', '', 0, '', now, sortOrder
      );
      if (isNew) {
        newMatches.push(match);
      }
    }

    for (let i = 0; i < diagnosisResult.partial.length; i++) {
      const partial = diagnosisResult.partial[i];
      matchedRuleIds.add(partial.rule.id);
      const missingStr = partial.missingCriteria.join('; ');
      const isNew = !existingRuleIds.has(partial.rule.id);
      const sortOrder = this.computeSortOrder('partial', existingDiagnoses);
      await this.repo.upsertDiagnosis(
        patientId, partial.rule.id, partial.rule.name, partial.rule.category,
        partial.rule.urgency, 'partial', missingStr, 0, '', now, sortOrder
      );
    }

    for (let i = 0; i < diagnosisResult.labAlerts.length; i++) {
      const match = diagnosisResult.labAlerts[i];
      matchedLabRuleIds.add(match.rule.id);
      const fieldKey = match.rule.criteria.length > 0 ? match.rule.criteria[0].field : '';
      const rawValue = fieldKey.length > 0 ? (latestData.get(fieldKey) || '') : '';
      const fieldLabel = labelMap.get(fieldKey) || fieldKey;
      const unit = unitMap.get(fieldKey) || '';
      const op = match.rule.criteria.length > 0 ? match.rule.criteria[0].operator : '';
      const val = match.rule.criteria.length > 0 ? match.rule.criteria[0].value : '';
      const thresholdStr = this.buildThresholdStr(op, val, unit);
      await this.repo.upsertLabAlert(
        patientId, match.rule.id, match.rule.name, match.rule.category,
        match.rule.urgency, fieldKey, fieldLabel, rawValue,
        thresholdStr, unit, match.rule.description, now
      );
      await this.repo.resolveDiagnosesForRule(patientId, match.rule.id);
    }

    const allRules = this.diagnosisEngine.getDiagnosisRules();
    for (let i = 0; i < allRules.length; i++) {
      const rule = allRules[i];
      if (rule.ruleType === 'alert') {
        if (!matchedLabRuleIds.has(rule.id)) {
          await this.repo.resolveLabAlertsForRule(patientId, rule.id);
        }
      } else {
        if (!matchedRuleIds.has(rule.id)) {
          await this.repo.resolveDiagnosesForRule(patientId, rule.id);
        }
      }
    }

    if (newMatches.length > 0) {
      this.confirmDiagnosesWithLlm(patientId, newMatches, latestData, alertResults);
    }

    const confirmedRuleIds = new Set<string>();
    for (let i = 0; i < diagnosisResult.confirmed.length; i++) {
      confirmedRuleIds.add(diagnosisResult.confirmed[i].rule.id);
    }
    if (diagnosisResult.confirmed.length === 0 && latestData.size >= 5) {
      this.suggestDiagnosesWithLlm(patientId, latestData, alertResults, confirmedRuleIds);
    }
  }

  private buildThresholdStr(op: string, val: string, unit: string): string {
    const unitStr = unit.length > 0 ? unit : '';
    if (op === 'gt') {
      return '>' + val + unitStr;
    }
    if (op === 'gte') {
      return '≥' + val + unitStr;
    }
    if (op === 'lt') {
      return '<' + val + unitStr;
    }
    if (op === 'lte') {
      return '≤' + val + unitStr;
    }
    if (op === 'eq') {
      return '=' + val + unitStr;
    }
    return op + ' ' + val + unitStr;
  }

  private async confirmDiagnosesWithLlm(patientId: string, newMatches: DiagnosisMatch[],
    latestData: Map<string, string>, alertResults: Map<string, CalcResult>): Promise<void> {
    try {
      const prefsService = PreferencesService.getInstance();
      const config = prefsService.getActiveLlmConfig();
      if (!config) {
        return;
      }

      let diagnosisList = '';
      for (let i = 0; i < newMatches.length; i++) {
        diagnosisList += (i + 1).toString() + '. ' + newMatches[i].rule.name +
          ' (规则ID: ' + newMatches[i].rule.id + ', 依据: ' + newMatches[i].matchedCriteria.join(', ') + ')\n';
      }

      let dataSummary = '';
      const fieldSpecs = this.assistantService.getDataFieldSpecs();
      dataSummary = buildDataSummaryWithLabels(latestData, fieldSpecs, 60);

      let alertSummary = '';
      const alertKeys = Array.from(alertResults.keys());
      for (let i = 0; i < alertKeys.length; i++) {
        const r = alertResults.get(alertKeys[i]);
        if (r) {
          alertSummary += alertKeys[i] + '=' + (r.value !== null ? r.value.toFixed(1) : 'null') + '(' + r.tier + ') ';
        }
      }

      const systemPrompt = '你是一名ICU主治医师。根据患者数据和计算器结果，系统已自动匹配以下疑似诊断。' +
        '请对每项诊断确认是否成立，并补充说明。' +
        '严格按以下JSON格式回复，不要添加其他内容：' +
        '{"confirmations":[{"ruleId":"id","status":"confirmed或rejected或uncertain","note":"补充说明"}]}';

      const userText = '疑似诊断：\n' + diagnosisList + '\n患者数据：' + dataSummary +
        '\n计算器结果：' + alertSummary;

      const response = await sendVisionRequest(config, systemPrompt, userText, '', '');
      hilog.info(0xF000, 'PatientService', 'LLM diagnosis response: ' + response);

      const parsed: Object | null = JSON.parse(response);
      if (parsed === null) {
        return;
      }
      const obj = parsed as Record<string, Object>;
      const confirmArr = obj['confirmations'];
      if (confirmArr === undefined || confirmArr === null) {
        return;
      }
      const confirmations = confirmArr as Array<Record<string, string>>;
      const activeDiagnoses = await this.repo.getActiveDiagnoses(patientId);

      for (let i = 0; i < confirmations.length; i++) {
        const conf = confirmations[i];
        const ruleId = conf['ruleId'];
        const status = conf['status'];
        const note = conf['note'] || '';
        if (ruleId === undefined) {
          continue;
        }
        for (let j = 0; j < activeDiagnoses.length; j++) {
          if (activeDiagnoses[j].ruleId === ruleId) {
            const confirmed = status === 'confirmed' ? 1 : (status === 'uncertain' ? 2 : -1);
            await this.repo.updateDiagnosisLlmResult(activeDiagnoses[j].id, confirmed, note);
            break;
          }
        }
      }
    } catch (e) {
      hilog.error(0xF000, 'PatientService', 'LLM diagnosis confirmation failed: ' +
        (e instanceof Error ? e.message : String(e)));
    }
  }

  async reconfirmPendingDiagnoses(patientId: string): Promise<void> {
    try {
      const activeDiagnoses = await this.repo.getActiveDiagnoses(patientId);
      const pending = activeDiagnoses.filter((d: PatientDiagnosis): boolean => d.source === 'rule' && d.llmConfirmed === 0);
      if (pending.length === 0) {
        return;
      }
      const prefsService = PreferencesService.getInstance();
      const config = prefsService.getActiveLlmConfig();
      if (!config) {
        return;
      }
      const latestData = await this.repo.getLatestData(patientId);
      const dataRecord: Record<string, string> = {};
      latestData.forEach((value: string, key: string) => {
        dataRecord[key] = value;
      });
      const matches = this.assistantService.computeAllMatchesFromRecord(dataRecord);
      const alertResults = new Map<string, CalcResult>();
      for (let i = 0; i < matches.length; i++) {
        const match = matches[i];
        if (match.completeness < 100 || !match.result) {
          continue;
        }
        alertResults.set(match.calcId, match.result);
      }
      let diagnosisList = '';
      for (let i = 0; i < pending.length; i++) {
        diagnosisList += (i + 1).toString() + '. ' + pending[i].name +
          ' (规则ID: ' + pending[i].ruleId + ')\n';
      }
      const fieldSpecs = this.assistantService.getDataFieldSpecs();
      let dataSummary = buildDataSummaryWithLabels(latestData, fieldSpecs, 60);
      let alertSummary = '';
      const alertKeys = Array.from(alertResults.keys());
      for (let i = 0; i < alertKeys.length; i++) {
        const r = alertResults.get(alertKeys[i]);
        if (r) {
          alertSummary += alertKeys[i] + '=' + (r.value !== null ? r.value.toFixed(1) : 'null') + '(' + r.tier + ') ';
        }
      }
      const systemPrompt = '你是一名ICU主治医师。根据患者数据和计算器结果，系统已自动匹配以下疑似诊断。' +
        '请对每项诊断确认是否成立，并补充说明。' +
        '严格按以下JSON格式回复，不要添加其他内容：' +
        '{"confirmations":[{"ruleId":"id","status":"confirmed或rejected或uncertain","note":"补充说明"}]}';
      const userText = '疑似诊断：\n' + diagnosisList + '\n患者数据：' + dataSummary +
        '\n计算器结果：' + alertSummary;
      const response = await sendVisionRequest(config, systemPrompt, userText, '', '');
      hilog.info(0xF000, 'PatientService', 'LLM re-confirm response: ' + response);
      const parsed: Object | null = JSON.parse(response);
      if (parsed === null) {
        return;
      }
      const obj = parsed as Record<string, Object>;
      const confirmArr = obj['confirmations'];
      if (confirmArr === undefined || confirmArr === null) {
        return;
      }
      const confirmations = confirmArr as Array<Record<string, string>>;
      for (let i = 0; i < confirmations.length; i++) {
        const conf = confirmations[i];
        const ruleId = conf['ruleId'];
        const status = conf['status'];
        const note = conf['note'] || '';
        if (ruleId === undefined) {
          continue;
        }
        for (let j = 0; j < activeDiagnoses.length; j++) {
          if (activeDiagnoses[j].ruleId === ruleId) {
            const confirmed = status === 'confirmed' ? 1 : (status === 'uncertain' ? 2 : -1);
            await this.repo.updateDiagnosisLlmResult(activeDiagnoses[j].id, confirmed, note);
            break;
          }
        }
      }
    } catch (e) {
      hilog.error(0xF000, 'PatientService', 'LLM re-confirm failed: ' +
        (e instanceof Error ? e.message : String(e)));
    }
  }

  async fullReDiagnose(patientId: string): Promise<void> {
    await this.repo.resolveAllDiagnoses(patientId);
    await this.repo.resolveAllLabAlerts(patientId);
    await this.repo.resolveAllAlerts(patientId);
    await this.refreshAlerts(patientId);
    const latestData = await this.repo.getLatestData(patientId);
    if (latestData.size >= 3) {
      this.reconfirmPendingDiagnoses(patientId);
    }
  }

  private async suggestDiagnosesWithLlm(patientId: string,
    latestData: Map<string, string>, alertResults: Map<string, CalcResult>,
    existingRuleIds: Set<string>): Promise<void> {
    try {
      const prefsService = PreferencesService.getInstance();
      const config = prefsService.getActiveLlmConfig();
      if (!config) {
        return;
      }

      let dataSummary = '';
      const fieldSpecs = this.assistantService.getDataFieldSpecs();
      dataSummary = buildDataSummaryWithLabels(latestData, fieldSpecs, 60);

      let alertSummary = '';
      const alertKeys = Array.from(alertResults.keys());
      for (let i = 0; i < alertKeys.length; i++) {
        const r = alertResults.get(alertKeys[i]);
        if (r) {
          alertSummary += alertKeys[i] + '=' + (r.value !== null ? r.value.toFixed(1) : 'null') + '(' + r.tier + ') ';
        }
      }

      const systemPrompt = '你是一名ICU主治医师。根据患者数据，系统未能完全匹配任何确定性诊断规则。' +
        '请分析患者数据，给出最可能的诊断提示（最多5个）。' +
        '每个提示说明：1)诊断名 2)可能性(高/中/低) 3)已有支持数据 4)还需要什么检查来确认。' +
        '注意：仅给出提示，不做确诊。' +
        '严格按JSON格式回复：{"suggestions":[{"name":"诊断名","category":"感染|呼吸|肾脏|心血管|神经|血液|肝|代谢|营养","likelihood":"高|中|低","supportingData":"已有支持","missingChecks":"需要补充的检查"}]}';

      const userText = '患者数据：' + dataSummary + '\n计算器结果：' + alertSummary;

      const response = await sendVisionRequest(config, systemPrompt, userText, '', '');
      hilog.info(0xF000, 'PatientService', 'LLM suggestion response: ' + response);

      const parsed: Object | null = JSON.parse(response);
      if (parsed === null) {
        return;
      }
      const obj = parsed as Record<string, Object>;
      const sugArr = obj['suggestions'];
      if (sugArr === undefined || sugArr === null) {
        return;
      }
      const suggestions = sugArr as Array<Record<string, string>>;
      const now = Date.now();

      for (let i = 0; i < suggestions.length; i++) {
        const sug = suggestions[i];
        const name = sug['name'];
        if (name === undefined || name.length === 0) {
          continue;
        }
        const category = sug['category'] || '代谢';
        const likelihood = sug['likelihood'] || '低';
        const urgency = likelihood === '高' ? 'warning' : 'attention';
        const missingChecks = sug['missingChecks'] || '';
        const ruleId = 'llm_' + name.replace(/[^a-zA-Z\u4e00-\u9fa50-9]/g, '_').substring(0, 30);
        if (existingRuleIds.has(ruleId)) {
          continue;
        }
        const activeDiags = await this.repo.getActiveDiagnoses(patientId);
        const sortOrder = this.computeSortOrder('llm_hint', activeDiags);
        await this.repo.upsertDiagnosis(
          patientId, ruleId, name, category,
          urgency, 'llm_hint', missingChecks, 0, '', now, sortOrder
        );
      }
    } catch (e) {
      hilog.error(0xF000, 'PatientService', 'LLM suggestion failed: ' +
        (e instanceof Error ? e.message : String(e)));
    }
  }

  async addUserDiagnosis(patientId: string, name: string, category: string): Promise<PatientDiagnosis> {
    const now = Date.now();
    const ruleId = 'user_' + name.replace(/[^a-zA-Z\u4e00-\u9fa50-9]/g, '_').substring(0, 30) + '_' + now.toString();
    const existingDiagnoses = await this.repo.getActiveDiagnoses(patientId);
    const sortOrder = this.computeSortOrder('user', existingDiagnoses);
    await this.repo.upsertDiagnosis(
      patientId, ruleId, name, category,
      'attention', 'user', '', 0, '', now, sortOrder
    );
    const diagnoses = await this.repo.getActiveDiagnoses(patientId);
    const found = diagnoses.find((d: PatientDiagnosis): boolean => d.ruleId === ruleId);
    return found !== undefined ? found : new PatientDiagnosis();
  }

  async moveDiagnosisUp(patientId: string, diagnosisId: number): Promise<void> {
    const diagnoses = await this.repo.getActiveDiagnoses(patientId);
    const idx = diagnoses.findIndex((d: PatientDiagnosis): boolean => d.id === diagnosisId);
    if (idx <= 0) {
      return;
    }
    const current = diagnoses[idx];
    const prev = diagnoses[idx - 1];
    if (current.source !== prev.source) {
      return;
    }
    const tmpSort = current.sortOrder;
    await this.repo.updateDiagnosisSortOrder(current.id, prev.sortOrder);
    await this.repo.updateDiagnosisSortOrder(prev.id, tmpSort);
  }

  async moveDiagnosisDown(patientId: string, diagnosisId: number): Promise<void> {
    const diagnoses = await this.repo.getActiveDiagnoses(patientId);
    const idx = diagnoses.findIndex((d: PatientDiagnosis): boolean => d.id === diagnosisId);
    if (idx < 0 || idx >= diagnoses.length - 1) {
      return;
    }
    const current = diagnoses[idx];
    const next = diagnoses[idx + 1];
    if (current.source !== next.source) {
      return;
    }
    const tmpSort = current.sortOrder;
    await this.repo.updateDiagnosisSortOrder(current.id, next.sortOrder);
    await this.repo.updateDiagnosisSortOrder(next.id, tmpSort);
  }

  private computeSortOrder(source: string, existingDiagnoses: PatientDiagnosis[]): number {
    const sourcePriority: Record<string, number> = {
      'rule': 0,
      'user': 1,
      'partial': 2,
      'llm_hint': 3
    };
    const priority = sourcePriority[source];
    if (priority === undefined) {
      return 0;
    }
    const base = priority * 10000;
    let maxSeq = 0;
    for (let i = 0; i < existingDiagnoses.length; i++) {
      const d = existingDiagnoses[i];
      if (d.source === source) {
        const seq = d.sortOrder - base;
        if (seq > maxSeq) {
          maxSeq = seq;
        }
      }
    }
    return base + maxSeq + 100;
  }

  async deleteUserDiagnosis(diagnosisId: number): Promise<void> {
    await this.repo.deleteDiagnosis(diagnosisId);
  }

  async editUserDiagnosis(diagnosisId: number, name: string, category: string): Promise<void> {
    await this.repo.updateUserDiagnosis(diagnosisId, name, category);
  }
}
