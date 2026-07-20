import { PatientAlert, PatientRecord, PatientDiagnosis, PatientDashboard, PatientLabAlert, DATA_DOMAINS, DOMAIN_COLORS } from '../../model/Patient';
import { CalcResult } from '../../engine/CalcEngine';
import { AppColors } from '../../utils/AppColors';
import { SearchResult } from '../../services/KnowledgeService';
import { DIAGNOSIS_RULES, DiagnosisRule } from '../../model/DiagnosisRules';
import { CALCULATORS, Calculator } from '../../model/CalculatorRegistry';
import { GuidelineRecommendation, ParsedRecommendations, GapSignal, AgentStep, DomainEntry, DiagnosisKbData } from './PatientDetailTypes';
import { DataFieldSpec } from '../../services/AssistantService';
import { hilog } from '@kit.PerformanceAnalysisKit';

export function criterionOpSymbol(op: string): string {
  if (op === 'lt') {
    return '<';
  }
  if (op === 'gt') {
    return '>';
  }
  if (op === 'le' || op === 'lte') {
    return '<=';
  }
  if (op === 'ge' || op === 'gte') {
    return '>=';
  }
  if (op === 'eq') {
    return '=';
  }
  if (op === 'ne' || op === 'neq') {
    return '≠';
  }
  return '';
}

export function parseAlertResult(alert: PatientAlert): CalcResult {
  const parsed: Object = JSON.parse(alert.resultJson);
  const obj = parsed as Record<string, Object>;
  return {
    value: obj['value'] as number | null,
    unit: obj['unit'] as string,
    tier: obj['tier'] as string,
    tierClass: obj['tierClass'] as string,
    footnote: obj['footnote'] as string
  };
}

export function formatTime(ts: number): string {
  const d = new Date(ts);
  const h = d.getHours().toString().padStart(2, '0');
  const m = d.getMinutes().toString().padStart(2, '0');
  return h + ':' + m;
}

export function formatDateTime(ts: number): string {
  const d = new Date(ts);
  const mo = (d.getMonth() + 1).toString().padStart(2, '0');
  const da = d.getDate().toString().padStart(2, '0');
  const h = d.getHours().toString().padStart(2, '0');
  const m = d.getMinutes().toString().padStart(2, '0');
  return mo + '/' + da + ' ' + h + ':' + m;
}

export function getRecordIcon(type: string): string {
  if (type === 'image') {
    return '📷';
  }
  if (type === 'text') {
    return '📝';
  }
  return '✏️';
}

export function getRecordLabel(record: PatientRecord): string {
  if (record.label.length > 0) {
    return record.label;
  }
  if (record.type === 'image') {
    return '图片上传';
  }
  if (record.type === 'text') {
    return '文本输入';
  }
  return '手动录入';
}

export function formatResultValue(value: number | null): string {
  if (value === null) {
    return '—';
  }
  return value.toFixed(1).replace(/\.0$/, '');
}

export function getUrgencyColor(urgency: string): ResourceStr {
  if (urgency === 'critical') {
    return AppColors.danger;
  }
  if (urgency === 'warning') {
    return AppColors.tierWarn;
  }
  return AppColors.tierOk;
}

export function getUrgencyBgColor(urgency: string): ResourceStr {
  if (urgency === 'critical') {
    return AppColors.tierDangerBg;
  }
  if (urgency === 'warning') {
    return AppColors.tierWarnBg;
  }
  return AppColors.tierOkBg;
}

export function getUrgencyLabel(urgency: string): string {
  if (urgency === 'critical') {
    return '危重';
  }
  if (urgency === 'warning') {
    return '警示';
  }
  return '关注';
}

export function getLlmConfirmLabel(confirmed: number): string {
  if (confirmed === 1) {
    return '已确认';
  }
  if (confirmed === -1) {
    return '已排除';
  }
  if (confirmed === 2) {
    return '待定';
  }
  return '待确认';
}

export function getLlmConfirmColor(confirmed: number): ResourceStr {
  if (confirmed === 1) {
    return AppColors.tierOk;
  }
  if (confirmed === -1) {
    return AppColors.textSecondary;
  }
  if (confirmed === 2) {
    return AppColors.tierWarn;
  }
  return AppColors.textSecondary;
}

export function getLlmConfirmBgColor(confirmed: number): ResourceStr {
  if (confirmed === 1) {
    return AppColors.tierOkBg;
  }
  if (confirmed === -1) {
    return AppColors.fillNeutral;
  }
  if (confirmed === 2) {
    return AppColors.tierWarnBg;
  }
  return AppColors.fillNeutral;
}

export function parseRecommendations(responseText: string): GuidelineRecommendation[] {
  const result: GuidelineRecommendation[] = [];
  let jsonStr = responseText;
  const codeBlockStart = responseText.indexOf('```json');
  if (codeBlockStart >= 0) {
    const afterStart = responseText.indexOf('{', codeBlockStart);
    const codeBlockEnd = responseText.indexOf('```', afterStart >= 0 ? afterStart : codeBlockStart + 7);
    if (afterStart >= 0 && codeBlockEnd > afterStart) {
      jsonStr = responseText.substring(afterStart, codeBlockEnd);
    }
  } else {
    const jsonStart = responseText.indexOf('{');
    const jsonEnd = responseText.indexOf('}', jsonStart >= 0 ? jsonStart : 0);
    if (jsonStart >= 0 && jsonEnd > jsonStart) {
      let depth = 0;
      let endIdx = -1;
      for (let i = jsonStart; i < responseText.length; i++) {
        if (responseText.charAt(i) === '{') {
          depth++;
        } else if (responseText.charAt(i) === '}') {
          depth--;
          if (depth === 0) {
            endIdx = i;
            break;
          }
        }
      }
      if (endIdx > jsonStart) {
        jsonStr = responseText.substring(jsonStart, endIdx + 1);
      }
    }
  }
  const parsed: Object | null = JSON.parse(jsonStr);
  if (parsed === null) {
    return result;
  }
  const obj = parsed as Record<string, Object>;
  const arr = obj['recommendations'];
  if (arr === undefined || arr === null) {
    return result;
  }
  const recArr = arr as Array<Record<string, string>>;
  const validCategories: string[] = ['病理生理', '诊断要点', '监测评估', '治疗建议'];
  const categoryMap: Record<string, string> = { '病理生理': '病理生理', '诊断': '诊断要点', '诊断要点': '诊断要点', '监测': '监测评估', '监测评估': '监测评估', '治疗': '治疗建议', '治疗建议': '治疗建议' };
  for (const rec of recArr) {
    const gr = new GuidelineRecommendation();
    gr.text = rec['text'] || '';
    gr.evidenceLevel = rec['evidenceLevel'] || '未标注';
    gr.source = rec['source'] || '';
    gr.category = rec['category'] || '';
    gr.type = rec['type'] || '';
    const validTypes: string[] = ['推荐意见', '知识要点', '混合'];
    if (validTypes.indexOf(gr.type) < 0) {
      gr.type = '';
    }
    const mapped = categoryMap[gr.category];
    if (mapped !== undefined) {
      gr.category = mapped;
    } else {
      gr.category = '治疗建议';
    }
    if (gr.text.length > 0) {
      result.push(gr);
    }
  }
  return result;
}

export function parseRecommendationsAndSummary(responseText: string): ParsedRecommendations {
  const result = new ParsedRecommendations();
  const summaryMarker = '## 临床要点';
  const markerIdx = responseText.indexOf(summaryMarker);
  let jsonPart = responseText;
  let summaryPart = '';
  if (markerIdx >= 0) {
    jsonPart = responseText.substring(0, markerIdx);
    summaryPart = responseText.substring(markerIdx);
  }
  result.recommendations = parseRecommendations(jsonPart);
  result.gaps = parseGapsFromJson(jsonPart);
  if (summaryPart.length > 0) {
    const headerEnd = summaryPart.indexOf('\n');
    if (headerEnd >= 0 && summaryPart.substring(0, headerEnd).trim() === '## 临床要点') {
      result.summary = summaryPart.substring(headerEnd + 1).trim();
    } else {
      result.summary = summaryPart.trim();
    }
  } else {
    const afterJson = responseText.lastIndexOf('```');
    if (afterJson >= 0 && afterJson < responseText.length - 3) {
      const remaining = responseText.substring(afterJson + 3).trim();
      if (remaining.length > 20) {
        result.summary = remaining;
      }
    }
  }
  return result;
}

export function parseGapsFromJson(responseText: string): GapSignal[] {
  const gaps: GapSignal[] = [];
  let jsonStr = responseText;
  const codeBlockStart = responseText.indexOf('```json');
  if (codeBlockStart >= 0) {
    const afterStart = responseText.indexOf('{', codeBlockStart);
    const codeBlockEnd = responseText.indexOf('```', afterStart >= 0 ? afterStart : codeBlockStart + 7);
    if (afterStart >= 0 && codeBlockEnd > afterStart) {
      jsonStr = responseText.substring(afterStart, codeBlockEnd);
    }
  } else {
    const jsonStart = responseText.indexOf('{');
    if (jsonStart >= 0) {
      let depth = 0;
      let endIdx = -1;
      for (let i = jsonStart; i < responseText.length; i++) {
        if (responseText.charAt(i) === '{') { depth++; }
        else if (responseText.charAt(i) === '}') {
          depth--;
          if (depth === 0) { endIdx = i; break; }
        }
      }
      if (endIdx > jsonStart) {
        jsonStr = responseText.substring(jsonStart, endIdx + 1);
      }
    }
  }
  try {
    const parsed: Object | null = JSON.parse(jsonStr);
    if (parsed !== null) {
      const obj = parsed as Record<string, Object>;
      const gapsArr = obj['gaps'] as Array<Record<string, Object>>;
      if (gapsArr !== undefined && gapsArr !== null) {
        for (const item of gapsArr) {
          const gs = new GapSignal();
          gs.category = (item['category'] as string) || '';
          const terms = item['supplementaryTerms'] as Array<string>;
          if (terms !== undefined && terms !== null) {
            gs.supplementaryTerms = terms;
          }
          if (gs.category.length > 0) {
            gaps.push(gs);
          }
        }
      }
    }
  } catch (_e) {
    hilog.warn(0x0001, 'MedCalc', 'parseGapsFromJson: failed to parse gaps');
  }
  return gaps;
}

export function getKbSearchResultTitle(sr: SearchResult): string {
  if (sr.title.length > 0) {
    return sr.title;
  }
  return sr.path.split('/').pop() || sr.path;
}

export function getKbGuidelineName(sr: SearchResult): string {
  const parts = sr.path.split('/');
  if (parts.length >= 3) {
    return parts.slice(0, parts.length - 1).join('/');
  } else if (parts.length === 2) {
    return parts[0];
  }
  return '';
}

export function getRecommendationSummary(recs: GuidelineRecommendation[]): string {
  let count = 0;
  const catCount: string[] = [];
  const categories: string[] = ['病理生理', '诊断要点', '监测评估', '治疗建议'];
  for (const cat of categories) {
    let c = 0;
    for (const rec of recs) {
      if (rec.category === cat) {
        c++;
      }
    }
    if (c > 0) {
      catCount.push(c.toString());
      count += c;
    }
  }
  if (count === 0) {
    return '0条';
  }
  return count.toString() + '条';
}

export function getCategoryCount(recs: GuidelineRecommendation[], cat: string): number {
  let c = 0;
  for (const rec of recs) {
    if (rec.category === cat) {
      c++;
    }
  }
  return c;
}

export function getCategoryBorderColor(cat: string): ResourceStr {
  if (cat === '病理生理') {
    return AppColors.aiAccent;
  }
  if (cat === '诊断要点') {
    return AppColors.infoAccent;
  }
  if (cat === '监测评估') {
    return AppColors.tierWarn;
  }
  if (cat === '治疗建议') {
    return AppColors.tierOk;
  }
  return AppColors.textSecondary;
}

export function getCategoryLabel(cat: string): string {
  if (cat === '病理生理') {
    return '病理';
  }
  if (cat === '诊断要点') {
    return '诊断';
  }
  if (cat === '监测评估') {
    return '监测';
  }
  if (cat === '治疗建议') {
    return '治疗';
  }
  return '其他';
}

export function getEvidenceColor(level: string): ResourceStr {
  if (level.indexOf('强') >= 0) {
    return AppColors.tierOk;
  }
  if (level.indexOf('条件') >= 0) {
    return AppColors.warningText;
  }
  if (level.indexOf('GPS') >= 0 || level.indexOf('良好') >= 0) {
    return AppColors.infoAccent;
  }
  return AppColors.textSecondary;
}

export function getEvidenceBgColor(level: string): ResourceStr {
  if (level.indexOf('强') >= 0) {
    return AppColors.tierOkBg;
  }
  if (level.indexOf('条件') >= 0) {
    return AppColors.tierWarnBg;
  }
  if (level.indexOf('GPS') >= 0 || level.indexOf('良好') >= 0) {
    return AppColors.infoAccentBg;
  }
  return AppColors.surfaceMuted;
}

export function getDiagnosisNameByRuleId(diagnoses: PatientDiagnosis[], ruleId: string): string {
  for (const diag of diagnoses) {
    if (diag.ruleId === ruleId) {
      return diag.name;
    }
  }
  return '';
}

export function getLabAlertUrgencyColor(urgency: string): ResourceStr {
  if (urgency === 'critical') {
    return AppColors.danger;
  }
  if (urgency === 'warning') {
    return AppColors.tierWarn;
  }
  return AppColors.tierOk;
}

export function getLabAlertUrgencyLabel(urgency: string): string {
  if (urgency === 'critical') {
    return '危急';
  }
  if (urgency === 'warning') {
    return '警示';
  }
  return '关注';
}

export function getWarningAlerts(alerts: PatientAlert[]): PatientAlert[] {
  const result: PatientAlert[] = [];
  for (let i = 0; i < alerts.length; i++) {
    const tierClass = parseAlertResult(alerts[i]).tierClass;
    if (tierClass !== 'tier-ok' && tierClass !== 'tier-info') {
      result.push(alerts[i]);
    }
  }
  return result;
}

export function getDiagnosisCategoryTags(diagnoses: PatientDiagnosis[]): string[] {
  const tagSet = new Set<string>();
  for (let i = 0; i < diagnoses.length; i++) {
    tagSet.add(diagnoses[i].category);
  }
  return Array.from(tagSet);
}

export function findFieldSpec(key: string, specs: DataFieldSpec[]): DataFieldSpec | null {
  for (let i = 0; i < specs.length; i++) {
    if (specs[i].key === key) {
      return specs[i];
    }
  }
  const lowerKey = key.toLowerCase();
  for (let i = 0; i < specs.length; i++) {
    if (specs[i].key.toLowerCase() === lowerKey) {
      return specs[i];
    }
  }
  return null;
}

export function getFieldValueLabel(key: string, specs: DataFieldSpec[]): string {
  const spec = findFieldSpec(key, specs);
  if (spec !== null) {
    return spec.label;
  }
  return key;
}

export function getFieldUnit(key: string, specs: DataFieldSpec[]): string {
  const spec = findFieldSpec(key, specs);
  if (spec !== null) {
    return spec.unit;
  }
  return '';
}

export function isDerivedFlagField(key: string, specs: DataFieldSpec[]): boolean {
  const spec = findFieldSpec(key, specs);
  if (spec === null) {
    return false;
  }
  if (spec.type === 'select' && spec.options !== undefined &&
    spec.options.length === 2 && spec.options[0] === '0' && spec.options[1] === '1') {
    return true;
  }
  return false;
}

export function isDisplayableDataKey(key: string, specs: DataFieldSpec[]): boolean {
  return !isDerivedFlagField(key, specs);
}

export function getDataFieldCount(dashboard: PatientDashboard, specs: DataFieldSpec[]): number {
  let count = 0;
  dashboard.latestData.forEach((val: string, key: string) => {
    if (isDisplayableDataKey(key, specs)) {
      count++;
    }
  });
  return count;
}

export function getDataPreviewItems(dashboard: PatientDashboard, specs: DataFieldSpec[]): string[] {
  const items: string[] = [];
  const keys = Array.from(dashboard.latestData.keys());
  for (let i = 0; i < keys.length && items.length < 5; i++) {
    const key = keys[i];
    if (!isDisplayableDataKey(key, specs)) {
      continue;
    }
    const val = dashboard.latestData.get(key);
    const unit = getFieldUnit(key, specs);
    items.push(getFieldValueLabel(key, specs) + ' ' + val + (unit.length > 0 ? ' ' + unit : ''));
  }
  return items;
}

export function getRecordPreviewItems(records: PatientRecord[]): string[] {
  const items: string[] = [];
  for (let i = 0; i < records.length && items.length < 3; i++) {
    const record = records[i];
    items.push(getRecordIcon(record.type) + ' ' + getRecordLabel(record) + ' ' + formatTime(record.timestamp));
  }
  return items;
}

export function formatCriterion(criterion: string, specs: DataFieldSpec[]): string {
  const tokens = criterion.split(' ');
  if (tokens.length !== 3) {
    return criterion;
  }
  const field = tokens[0];
  const op = tokens[1];
  const value = tokens[2];
  if (field.indexOf('calcResult:') === 0) {
    const calcId = field.substring('calcResult:'.length);
    const calc = CALCULATORS.find((c: Calculator) => c.id === calcId);
    const calcName = calc !== undefined ? calc.name : calcId;
    if (op === 'has_tier') {
      return calcName + ' 达到' + value;
    }
    if (op === 'has_tier_containing') {
      return calcName + ' 分级含"' + value + '"';
    }
    const opSym = criterionOpSymbol(op);
    if (opSym.length === 0) {
      return criterion;
    }
    return calcName + ' ' + opSym + ' ' + value;
  }
  const opSym = criterionOpSymbol(op);
  if (opSym.length === 0) {
    return criterion;
  }
  const label = getFieldValueLabel(field, specs);
  const unit = getFieldUnit(field, specs);
  return label + ' ' + opSym + ' ' + value + (unit.length > 0 ? ' ' + unit : '');
}

export function formatMissingCriteria(raw: string, specs: DataFieldSpec[]): string {
  if (raw.length === 0) {
    return raw;
  }
  const parts = raw.split('; ');
  const out: string[] = [];
  for (let i = 0; i < parts.length; i++) {
    out.push(formatCriterion(parts[i], specs));
  }
  return out.join('；');
}

export function getDomainColor(domainName: string): ResourceStr {
  const color = DOMAIN_COLORS[domainName];
  if (color !== undefined && color !== null) {
    return color;
  }
  return AppColors.textSecondary;
}

export function getDomainDataCount(domainKeys: string[], dashboard: PatientDashboard, specs: DataFieldSpec[]): number {
  let count = 0;
  for (let i = 0; i < domainKeys.length; i++) {
    if (dashboard.latestData.has(domainKeys[i]) && isDisplayableDataKey(domainKeys[i], specs)) {
      count++;
    }
  }
  return count;
}

export function domainHasData(domainKeys: string[], dashboard: PatientDashboard): boolean {
  for (let i = 0; i < domainKeys.length; i++) {
    if (dashboard.latestData.has(domainKeys[i])) {
      return true;
    }
  }
  return false;
}

export function buildDomainEntries(dashboard: PatientDashboard, specs: DataFieldSpec[]): DomainEntry[] {
  const entries: DomainEntry[] = [];
  const domainKeys = Object.keys(DATA_DOMAINS);
  for (let i = 0; i < domainKeys.length; i++) {
    const name = domainKeys[i];
    const keys: string[] = DATA_DOMAINS[name];
    let hasData = false;
    for (let j = 0; j < keys.length; j++) {
      if (dashboard.latestData.has(keys[j]) && isDisplayableDataKey(keys[j], specs)) {
        hasData = true;
        break;
      }
    }
    if (hasData) {
      const entry = new DomainEntry();
      entry.name = name;
      entry.keys = keys;
      entry.hasData = true;
      entries.push(entry);
    }
  }
  return entries;
}

export function getDiagnosesBySource(diagnoses: PatientDiagnosis[], source: string): PatientDiagnosis[] {
  return diagnoses.filter((d: PatientDiagnosis): boolean => d.source === source);
}

export function getDiagnosisKb(diagnosisKbMap: DiagnosisKbData[], ruleId: string): DiagnosisKbData | null {
  for (const item of diagnosisKbMap) {
    if (item.ruleId === ruleId) {
      return item;
    }
  }
  return null;
}
