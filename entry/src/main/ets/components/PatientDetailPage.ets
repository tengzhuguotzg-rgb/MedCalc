import { Patient, PatientDataPoint, PatientRecord, PatientAlert, PatientDiagnosis, PatientLabAlert, PatientDashboard, DATA_DOMAINS, DOMAIN_COLORS } from '../model/Patient';
import { PatientService } from '../services/PatientService';
import { AssistantService, DataFieldSpec, CalcMatch } from '../services/AssistantService';
import { CalcResult, getTierColor, getTierBgColor } from '../engine/CalcEngine';
import { PreferencesService } from '../services/PreferencesService';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { sendVisionRequest, ApiServiceConfig } from '../services/LlmService';
import { ImageStore } from '../services/ImageStore';
import { KnowledgeService, SearchResult, KnowledgePage, ExpandedQueryResult, SmartSearchResult } from '../services/KnowledgeService';
import {
  MarkdownLine, CalloutStyle, AnnotationBadge,
  parseKbMarkdown, stripMarkdownInline, stripTableMarkdown, getCalloutStyle, getAnnotationBadgeInfo, parseTableCells
} from '../utils/KbMarkdownParser';
import { DIAGNOSIS_RULES, DIAGNOSIS_CATEGORIES, DiagnosisRule } from '../model/DiagnosisRules';
import { CALCULATORS, Calculator } from '../model/CalculatorRegistry';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo, picker } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { image } from '@kit.ImageKit';
import { pdfService } from '@kit.PDFKit';
import { ImageEditor } from './ImageEditor';

class DomainEntry {
  name: string = '';
  keys: string[] = [];
  hasData: boolean = false;
}

class ParsedRecommendations {
  recommendations: GuidelineRecommendation[] = [];
  summary: string = '';
  gaps: GapSignal[] = [];
}

class GuidelineRecommendation {
  text: string = '';
  evidenceLevel: string = '';
  source: string = '';
  category: string = '';
  type: string = '';
}

class PathScore {
  path: string = '';
  score: number = 0;
}

class AgentStep {
  agent: string = '';
  status: string = '';
  input: string = '';
  output: string = '';
  durationMs: number = 0;

  toJson(): Record<string, Object> {
    return {
      'agent': this.agent,
      'status': this.status,
      'input': this.input,
      'output': this.output,
      'durationMs': this.durationMs,
    };
  }

  static fromJson(obj: Record<string, Object>): AgentStep {
    const s = new AgentStep();
    s.agent = (obj['agent'] as string) || '';
    s.status = (obj['status'] as string) || '';
    s.input = (obj['input'] as string) || '';
    s.output = (obj['output'] as string) || '';
    s.durationMs = (obj['durationMs'] as number) || 0;
    return s;
  }
}

class AuditIssue {
  index: number = 0;
  type: string = '';
  description: string = '';
}

class GapSignal {
  category: string = '';
  supplementaryTerms: string[] = [];
}

class AuditAgentResult {
  issues: AuditIssue[] = [];
  gaps: GapSignal[] = [];
}

class DiagnosisKbData {
  ruleId: string = '';
  searchResults: SearchResult[] = [];
  verifiedPaths: string[] = [];
  partialPaths: string[] = [];
  candidatePaths: string[] = [];
  recommendations: GuidelineRecommendation[] = [];
  loadingKb: boolean = false;
  loadingAdvice: boolean = false;
  summary: string = '';
  verifyInfo: string = '';
  isLowRelevance: boolean = false;
  adviceError: string = '';
  agentSteps: AgentStep[] = [];
  feedbackRound: number = 0;
  expandedInfo: string = '';
  matchedDirs: string[] = [];
  expandedSearchTerms: string[] = [];
  expandedEtiologyTerms: string[] = [];
  expandedTreatmentTerms: string[] = [];
  expandedMonitoringTerms: string[] = [];

  toJson(): string {
    const srList: Record<string, string>[] = [];
    for (const sr of this.searchResults) {
      srList.push({ 'path': sr.path, 'title': sr.title });
    }
    const recList: Record<string, string>[] = [];
    for (const rec of this.recommendations) {
      recList.push({ 'text': rec.text, 'evidenceLevel': rec.evidenceLevel, 'source': rec.source, 'category': rec.category, 'type': rec.type });
    }
    const stepsList: Record<string, Object>[] = [];
    for (const step of this.agentSteps) {
      stepsList.push(step.toJson());
    }
    const obj: Record<string, Object> = {
      'ruleId': this.ruleId,
      'searchResults': srList,
      'verifiedPaths': this.verifiedPaths,
      'partialPaths': this.partialPaths,
      'candidatePaths': this.candidatePaths,
      'recommendations': recList,
      'summary': this.summary,
      'verifyInfo': this.verifyInfo,
      'isLowRelevance': this.isLowRelevance,
      'adviceError': this.adviceError,
      'agentSteps': stepsList,
      'feedbackRound': this.feedbackRound,
      'expandedInfo': this.expandedInfo,
      'matchedDirs': this.matchedDirs,
      'expandedSearchTerms': this.expandedSearchTerms,
      'expandedEtiologyTerms': this.expandedEtiologyTerms,
      'expandedTreatmentTerms': this.expandedTreatmentTerms,
      'expandedMonitoringTerms': this.expandedMonitoringTerms,
    };
    return JSON.stringify(obj);
  }

  static fromJson(jsonStr: string): DiagnosisKbData | null {
    const parsed: Object | null = JSON.parse(jsonStr);
    if (parsed === null) {
      return null;
    }
    const obj = parsed as Record<string, Object>;
    const d = new DiagnosisKbData();
    d.ruleId = (obj['ruleId'] as string) || '';
    const srArr = obj['searchResults'] as Array<Record<string, string>>;
    if (srArr !== undefined && srArr !== null) {
      for (const sr of srArr) {
        const searchResult = new SearchResult();
        searchResult.path = sr['path'] || '';
        searchResult.title = sr['title'] || '';
        d.searchResults.push(searchResult);
      }
    }
    const vpArr = obj['verifiedPaths'] as Array<string>;
    if (vpArr !== undefined && vpArr !== null) {
      d.verifiedPaths = vpArr;
    }
    const ppArr = obj['partialPaths'] as Array<string>;
    if (ppArr !== undefined && ppArr !== null) {
      d.partialPaths = ppArr;
    }
    const recArr = obj['recommendations'] as Array<Record<string, string>>;
    if (recArr !== undefined && recArr !== null) {
      for (const rec of recArr) {
        const gr = new GuidelineRecommendation();
        gr.text = rec['text'] || '';
        gr.evidenceLevel = rec['evidenceLevel'] || '未标注';
        gr.source = rec['source'] || '';
        gr.category = rec['category'] || '';
        gr.type = rec['type'] || '';
        d.recommendations.push(gr);
      }
    }
    d.summary = (obj['summary'] as string) || '';
    d.verifyInfo = (obj['verifyInfo'] as string) || '';
    d.isLowRelevance = (obj['isLowRelevance'] as boolean) || false;
    d.adviceError = (obj['adviceError'] as string) || '';
    const cpArr = obj['candidatePaths'] as Array<string>;
    if (cpArr !== undefined && cpArr !== null) {
      d.candidatePaths = cpArr;
    }
    const stepsArr = obj['agentSteps'] as Array<Record<string, Object>>;
    if (stepsArr !== undefined && stepsArr !== null) {
      for (const stepObj of stepsArr) {
        d.agentSteps.push(AgentStep.fromJson(stepObj));
      }
    }
    d.feedbackRound = (obj['feedbackRound'] as number) || 0;
    d.expandedInfo = (obj['expandedInfo'] as string) || '';
    const mdArr = obj['matchedDirs'] as Array<string>;
    if (mdArr !== undefined && mdArr !== null) {
      d.matchedDirs = mdArr;
    }
    const estArr = obj['expandedSearchTerms'] as Array<string>;
    if (estArr !== undefined && estArr !== null) { d.expandedSearchTerms = estArr; }
    const eetArr = obj['expandedEtiologyTerms'] as Array<string>;
    if (eetArr !== undefined && eetArr !== null) { d.expandedEtiologyTerms = eetArr; }
    const ettArr = obj['expandedTreatmentTerms'] as Array<string>;
    if (ettArr !== undefined && ettArr !== null) { d.expandedTreatmentTerms = ettArr; }
    const emtArr = obj['expandedMonitoringTerms'] as Array<string>;
    if (emtArr !== undefined && emtArr !== null) { d.expandedMonitoringTerms = emtArr; }
    return d;
  }
}

@Component
export struct PatientDetailPage {
  @Link currentPatientId: string;
  @State dashboard: PatientDashboard = new PatientDashboard();
  @State loading: boolean = false;
  @State expandedAlertIds: Set<number> = new Set();
  @State expandedDomains: Set<string> = new Set();
  @State timelineField: string = '';
  @State timelineData: PatientDataPoint[] = [];
  @State showTimelineDialog: boolean = false;
  @State editExamTimePointId: number = 0;
  @State showExamTimeEditor: boolean = false;
  @State editExamYear: number = 2025;
  @State editExamMonth: number = 1;
  @State editExamDay: number = 1;
  @State editExamHour: number = 0;
  @State editExamMinute: number = 0;
  @State showManualInput: boolean = false;
  @State manualFieldKey: string = '';
  @State manualFieldValue: string = '';
  @State manualFilterKeyword: string = '';
  @State domainEntries: DomainEntry[] = [];
  @State expandedRecordIds: Set<string> = new Set();
  @State @Watch('onDetailNavChanged') showAlertDetail: boolean = false;
  @State @Watch('onDetailNavChanged') showDiagnosisDetail: boolean = false;
  @State @Watch('onDetailNavChanged') showDataDetail: boolean = false;
  @State @Watch('onDetailNavChanged') showRecordsDetail: boolean = false;
  @StorageLink('patientNavDepth') patientNavDepth: number = 0;
  @Watch('onBackFlagChanged') @StorageLink('patientBackFlag') patientBackFlag: number = 0;
  @State deleteRecordId: string = '';
  @State showDeleteConfirm: boolean = false;
  @State uploading: boolean = false;
  @State uploadMsg: string = '';
  @State @Watch('onImageEditorClosed') showImageEditor: boolean = false;
  @State editorImageUri: string = '';
  @State editorResultBase64: string = '';
  @State editorResultMime: string = '';
  @State diagnosisKbMap: DiagnosisKbData[] = [];
  @State showKbReader: boolean = false;
  @State @Watch('onKbReaderPathChanged') kbReaderPath: string = '';
  @State expandedCategories: Set<string> = new Set();
  @State expandedRefIds: Set<string> = new Set();
  @State kbReaderTitle: string = '';
  @State showRecommendationsDetail: boolean = false;
  @State activeAdviceRuleId: string = '';
  @State adviceReadyRuleId: string = '';
  @State summaryLines: MarkdownLine[] = [];
  @State showAddDiagnosis: boolean = false;
  @State addDiagName: string = '';
  @State addDiagCategory: string = '代谢';

  private patientService: PatientService = PatientService.getInstance();
  private assistantService: AssistantService = AssistantService.getInstance();
  private kbService: KnowledgeService = KnowledgeService.getInstance();
  private dataFieldSpecs: DataFieldSpec[] = [];
  private lastBackFlag: number = 0;

  aboutToAppear() {
    this.dataFieldSpecs = this.assistantService.getDataFieldSpecs();
    this.loadDashboard();
    this.syncNavDepth();
  }

  saveKbData(kbData: DiagnosisKbData) {
    if (this.currentPatientId.length === 0) {
      return;
    }
    const prefsService = PreferencesService.getInstance();
    prefsService.saveDiagnosisKbData(this.currentPatientId, kbData.ruleId, kbData.toJson());
  }

  loadSavedKbData() {
    if (this.currentPatientId.length === 0 || this.dashboard.diagnoses.length === 0) {
      return;
    }
    const prefsService = PreferencesService.getInstance();
    for (const diag of this.dashboard.diagnoses) {
      const jsonStr = prefsService.getDiagnosisKbData(this.currentPatientId, diag.ruleId);
      if (jsonStr.length > 0) {
        const saved = DiagnosisKbData.fromJson(jsonStr);
        if (saved !== null && (saved.searchResults.length > 0 || saved.recommendations.length > 0)) {
          this.diagnosisKbMap = [...this.diagnosisKbMap, saved];
        }
      }
    }
  }

  onDetailNavChanged() {
    this.syncNavDepth();
  }

  onKbReaderPathChanged() {
    if (this.showKbReader && this.kbReaderPath.length > 0) {
      this.loadKbReaderContent(this.kbReaderPath);
    }
  }

  syncNavDepth() {
    let depth = 0;
    if (this.currentPatientId.length > 0) {
      depth = 1;
    }
    if (this.showAlertDetail || this.showDiagnosisDetail || this.showDataDetail || this.showRecordsDetail || this.showRecommendationsDetail) {
      depth = 2;
    }
    AppStorage.setOrCreate<number>('patientNavDepth', depth);
  }

  onBackFlagChanged() {
    if (this.patientBackFlag !== this.lastBackFlag) {
      this.lastBackFlag = this.patientBackFlag;
      if (this.patientNavDepth > 0) {
        this.navigateBack();
      }
    }
  }

  navigateBack(): boolean {
    if (this.showRecommendationsDetail) {
      this.showRecommendationsDetail = false;
      this.activeAdviceRuleId = '';
      return true;
    }
    if (this.showAlertDetail) {
      this.showAlertDetail = false;
      return true;
    }
    if (this.showDiagnosisDetail) {
      this.showDiagnosisDetail = false;
      this.activeAdviceRuleId = '';
      return true;
    }
    if (this.showDataDetail) {
      this.showDataDetail = false;
      return true;
    }
    if (this.showRecordsDetail) {
      this.showRecordsDetail = false;
      return true;
    }
    if (this.currentPatientId.length > 0) {
      this.currentPatientId = '';
      return true;
    }
    return false;
  }

  async loadDashboard() {
    if (this.currentPatientId.length === 0) {
      return;
    }
    this.loading = true;
    this.dashboard = await this.patientService.getDashboard(this.currentPatientId);
    this.domainEntries = this.buildDomainEntries();
    this.loading = false;
    this.loadSavedKbData();
    if (this.dashboard.diagnoses.length > 0) {
      this.loadDiagnosisKb();
      this.patientService.reconfirmPendingDiagnoses(this.currentPatientId);
    }
  }

  buildDomainEntries(): DomainEntry[] {
    const entries: DomainEntry[] = [];
    const domainKeys = Object.keys(DATA_DOMAINS);
    for (let i = 0; i < domainKeys.length; i++) {
      const name = domainKeys[i];
      const keys: string[] = DATA_DOMAINS[name];
      let hasData = false;
      for (let j = 0; j < keys.length; j++) {
        if (this.dashboard.latestData.has(keys[j]) && this.isDisplayableDataKey(keys[j])) {
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

  isAlertExpanded(alertId: number): boolean {
    return this.expandedAlertIds.has(alertId);
  }

  toggleAlert(alertId: number) {
    if (this.expandedAlertIds.has(alertId)) {
      this.expandedAlertIds.delete(alertId);
    } else {
      this.expandedAlertIds.add(alertId);
    }
    this.expandedAlertIds = new Set(this.expandedAlertIds);
  }

  isDomainExpanded(domain: string): boolean {
    return this.expandedDomains.has(domain);
  }

  toggleDomain(domain: string) {
    if (this.expandedDomains.has(domain)) {
      this.expandedDomains.delete(domain);
    } else {
      this.expandedDomains.add(domain);
    }
    this.expandedDomains = new Set(this.expandedDomains);
  }

  domainHasData(domainKeys: string[]): boolean {
    for (let i = 0; i < domainKeys.length; i++) {
      if (this.dashboard.latestData.has(domainKeys[i])) {
        return true;
      }
    }
    return false;
  }

  findFieldSpec(key: string): DataFieldSpec | null {
    for (let i = 0; i < this.dataFieldSpecs.length; i++) {
      if (this.dataFieldSpecs[i].key === key) {
        return this.dataFieldSpecs[i];
      }
    }
    const lowerKey = key.toLowerCase();
    for (let i = 0; i < this.dataFieldSpecs.length; i++) {
      if (this.dataFieldSpecs[i].key.toLowerCase() === lowerKey) {
        return this.dataFieldSpecs[i];
      }
    }
    return null;
  }

  getFieldValueLabel(key: string): string {
    const spec = this.findFieldSpec(key);
    if (spec !== null) {
      return spec.label;
    }
    return key;
  }

  getFieldUnit(key: string): string {
    const spec = this.findFieldSpec(key);
    if (spec !== null) {
      return spec.unit;
    }
    return '';
  }

  isDerivedFlagField(key: string): boolean {
    const spec = this.findFieldSpec(key);
    if (spec === null) {
      return false;
    }
    if (spec.type === 'select' && spec.options !== undefined &&
      spec.options.length === 2 && spec.options[0] === '0' && spec.options[1] === '1') {
      return true;
    }
    return false;
  }

  isDisplayableDataKey(key: string): boolean {
    return !this.isDerivedFlagField(key);
  }

  criterionOpSymbol(op: string): string {
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

  formatCriterion(criterion: string): string {
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
      const opSym = this.criterionOpSymbol(op);
      if (opSym.length === 0) {
        return criterion;
      }
      return calcName + ' ' + opSym + ' ' + value;
    }
    const opSym = this.criterionOpSymbol(op);
    if (opSym.length === 0) {
      return criterion;
    }
    const label = this.getFieldValueLabel(field);
    const unit = this.getFieldUnit(field);
    return label + ' ' + opSym + ' ' + value + (unit.length > 0 ? ' ' + unit : '');
  }

  formatMissingCriteria(raw: string): string {
    if (raw.length === 0) {
      return raw;
    }
    const parts = raw.split('; ');
    const out: string[] = [];
    for (let i = 0; i < parts.length; i++) {
      out.push(this.formatCriterion(parts[i]));
    }
    return out.join('；');
  }

  getDomainColor(domainName: string): string {
    const color = DOMAIN_COLORS[domainName];
    if (color !== undefined && color !== null) {
      return color;
    }
    return '#7A8074';
  }

  getDomainDataCount(domainKeys: string[]): number {
    let count = 0;
    for (let i = 0; i < domainKeys.length; i++) {
      if (this.dashboard.latestData.has(domainKeys[i]) && this.isDisplayableDataKey(domainKeys[i])) {
        count++;
      }
    }
    return count;
  }

  parseAlertResult(alert: PatientAlert): CalcResult {
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

  formatTime(ts: number): string {
    const d = new Date(ts);
    const h = d.getHours().toString().padStart(2, '0');
    const m = d.getMinutes().toString().padStart(2, '0');
    return h + ':' + m;
  }

  formatDateTime(ts: number): string {
    const d = new Date(ts);
    const mo = (d.getMonth() + 1).toString().padStart(2, '0');
    const da = d.getDate().toString().padStart(2, '0');
    const h = d.getHours().toString().padStart(2, '0');
    const m = d.getMinutes().toString().padStart(2, '0');
    return mo + '/' + da + ' ' + h + ':' + m;
  }

  getRecordIcon(type: string): string {
    if (type === 'image') {
      return '📷';
    }
    if (type === 'text') {
      return '📝';
    }
    return '✏️';
  }

  getRecordLabel(record: PatientRecord): string {
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

  formatResultValue(value: number | null): string {
    if (value === null) {
      return '—';
    }
    return value.toFixed(1).replace(/\.0$/, '');
  }

  async pickImage() {
    try {
      const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 1;
      const photoViewPicker = new photoAccessHelper.PhotoViewPicker();
      const photoSelectResult = await photoViewPicker.select(photoSelectOptions);
      if (photoSelectResult.photoUris.length > 0) {
        this.editorImageUri = photoSelectResult.photoUris[0];
        this.editorResultBase64 = '';
        this.editorResultMime = '';
        this.showImageEditor = true;
      }
    } catch (e) {
      hilog.error(0xF000, 'PatientDetail', 'pickImage failed: ' + (e instanceof Error ? e.stack : String(e)));
    }
  }

  async pickPdf() {
    try {
      const documentSelectOptions = new picker.DocumentSelectOptions();
      documentSelectOptions.fileSuffixFilters = ['.pdf'];
      documentSelectOptions.maxSelectNumber = 1;
      const documentPicker = new picker.DocumentViewPicker();
      const uris = await documentPicker.select(documentSelectOptions);
      hilog.info(0xF000, 'PatientDetail', 'pdf selected, count=' + uris.length);
      if (uris.length > 0) {
        await this.processPdfUpload(uris[0]);
      }
    } catch (e) {
      hilog.error(0xF000, 'PatientDetail', 'pickPdf failed: ' + (e instanceof Error ? e.stack : String(e)));
    }
  }

  async processPdfUpload(uri: string) {
    try {
      this.uploading = true;
      this.uploadMsg = '正在加载PDF...';

      const context = getContext(this);
      const imageStore = ImageStore.getInstance();
      imageStore.init(context);

      const tempId = 'pdf_' + Date.now().toString();
      const sandboxPath = imageStore.copyToTemp(uri, tempId);
      if (sandboxPath.length === 0) {
        this.uploading = false;
        this.uploadMsg = 'PDF文件复制失败';
        return;
      }

      const pdfDoc = new pdfService.PdfDocument();
      const loadResult = pdfDoc.loadDocument(sandboxPath);
      if (loadResult !== pdfService.ParseResult.PARSE_SUCCESS) {
        pdfDoc.releaseDocument();
        imageStore.clearTemp();
        this.uploading = false;
        this.uploadMsg = 'PDF文件加载失败';
        return;
      }

      const pageCount = pdfDoc.getPageCount();
      hilog.info(0xF000, 'PatientDetail', 'pdf page count=' + pageCount);

      if (pageCount === 0) {
        pdfDoc.releaseDocument();
        imageStore.clearTemp();
        this.uploading = false;
        this.uploadMsg = 'PDF无有效页面';
        return;
      }

      const prefsService = PreferencesService.getInstance();
      const config = prefsService.getActiveLlmConfig();
      if (!config) {
        pdfDoc.releaseDocument();
        imageStore.clearTemp();
        this.uploading = false;
        this.uploadMsg = '请先在设置页配置LLM';
        return;
      }

      const systemPrompt = this.assistantService.getExtractionPrompt();
      const mergedExtracted: Record<string, string> = {};
      const recordId = 'rec_' + Date.now().toString();
      let savedFilePath = '';

      const imagePackerApi = image.createImagePacker();
      const packOpts: image.PackingOption = { format: 'image/jpeg', quality: 85 };

      for (let i = 0; i < pageCount; i++) {
        this.uploadMsg = '正在处理第 ' + (i + 1) + '/' + pageCount + ' 页...';
        try {
          const page = pdfDoc.getPage(i);
          const pixelMap = page.getPagePixelMap();
          if (!pixelMap) {
            continue;
          }

          const packedData = await imagePackerApi.packToData(pixelMap, packOpts);
          const uint8Arr = new Uint8Array(packedData);
          const base64Helper = new util.Base64Helper();
          const pageBase64 = base64Helper.encodeToStringSync(uint8Arr);

          if (i === 0) {
            const filePath = imageStore.saveImage(this.currentPatientId, recordId, uint8Arr, 'jpg');
            savedFilePath = filePath;
          }

          this.uploadMsg = '正在识别第 ' + (i + 1) + '/' + pageCount + ' 页...';
          const userContent = '请从这张医学检查报告（PDF第' + (i + 1) + '页）中提取所有可识别的医疗数据参数';
          const response = await sendVisionRequest(config, systemPrompt, userContent, pageBase64, 'image/jpeg');
          hilog.info(0xF000, 'PatientDetail', 'page ' + i + ' vision response len=' + response.length);

          const pageExtracted = this.assistantService.parseExtractionResponsePublic(response);
          const keys = Object.keys(pageExtracted);
          for (let k = 0; k < keys.length; k++) {
            if (mergedExtracted[keys[k]] === undefined) {
              mergedExtracted[keys[k]] = pageExtracted[keys[k]];
            }
          }
        } catch (pageErr) {
          hilog.error(0xF000, 'PatientDetail', 'page ' + i + ' error: ' + (pageErr instanceof Error ? pageErr.message : String(pageErr)));
        }
      }

      imagePackerApi.release();
      pdfDoc.releaseDocument();
      imageStore.clearTemp();

      this.uploadMsg = '正在保存数据...';
      hilog.info(0xF000, 'PatientDetail', 'total extracted fields=' + Object.keys(mergedExtracted).length);
      const savedRecord = await this.patientService.saveRecord(this.currentPatientId, 'pdf', savedFilePath, '', JSON.stringify(mergedExtracted as Object), '');
      await this.patientService.mergeExtractedData(this.currentPatientId, mergedExtracted, 'upload', 'PDF上传', savedRecord.id);

      this.uploading = false;
      this.uploadMsg = '';
      this.loadDashboard();
    } catch (e) {
      this.uploading = false;
      this.uploadMsg = 'PDF处理失败: ' + (e instanceof Error ? e.message : String(e));
      hilog.error(0xF000, 'PatientDetail', 'processPdfUpload failed: ' + (e instanceof Error ? e.stack : String(e)));
    }
  }

  onImageEditorClosed() {
    if (!this.showImageEditor && this.editorResultBase64.length > 0) {
      this.processUpload(this.editorResultBase64, this.editorResultMime);
    }
  }

  async processUpload(base64: string, mime: string) {
    if (base64.length === 0) {
      return;
    }
    try {
      this.uploading = true;
      this.uploadMsg = '正在调用AI提取数据...';

      const prefsService = PreferencesService.getInstance();
      const config = prefsService.getActiveLlmConfig();
      if (!config) {
        this.uploadMsg = '请先在设置页配置LLM';
        this.uploading = false;
        return;
      }
      hilog.info(0xF000, 'PatientDetail', 'calling vision API, model=' + config.model);

      const context = getContext(this);
      const imageStore = ImageStore.getInstance();
      imageStore.init(context);
      const recordId = 'rec_' + Date.now().toString();

      const base64Helper = new util.Base64Helper();
      const uint8Arr = base64Helper.decodeSync(base64);
      const filePath = imageStore.saveImage(this.currentPatientId, recordId, uint8Arr, 'jpg');

      const systemPrompt = this.assistantService.getExtractionPrompt();
      const userContent = '请从这张医学检查报告中提取所有可识别的医疗数据参数';
      const response = await sendVisionRequest(config, systemPrompt, userContent, base64, mime);
      hilog.info(0xF000, 'PatientDetail', 'vision response len=' + response.length);

      this.uploadMsg = '正在保存数据...';
      const extractedRecord = this.assistantService.parseExtractionResponsePublic(response);
      hilog.info(0xF000, 'PatientDetail', 'extracted fields=' + Object.keys(extractedRecord).length);
      const savedRecord = await this.patientService.saveRecord(this.currentPatientId, 'image', filePath, '', JSON.stringify(extractedRecord as Object), '');
      await this.patientService.mergeExtractedData(this.currentPatientId, extractedRecord, 'upload', '图片上传', savedRecord.id);

      this.uploading = false;
      this.uploadMsg = '';
      this.loadDashboard();
    } catch (e) {
      this.uploading = false;
      const errMsg = e instanceof Error ? e.message : '未知错误';
      this.uploadMsg = '上传失败: ' + errMsg;
      hilog.error(0xF000, 'PatientDetail', 'processUpload failed');
    }
  }

   build() {
      Stack() {
      if (!this.showImageEditor) {
      Column() {
         if (this.showAlertDetail) {
           this.AlertDetailPage();
         } else if (this.showRecommendationsDetail) {
           this.RecommendationsDetailPage();
         } else if (this.showDiagnosisDetail) {
          this.DiagnosisDetailPage();
        } else if (this.showDataDetail) {
          this.DataDetailPage();
        } else if (this.showRecordsDetail) {
          this.RecordsDetailPage();
        } else {
        Row() {
          Button('< 返回')
            .fontSize(14)
            .fontColor('#1F3D2F')
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.navigateBack();
            })
          Text(this.dashboard.patient.name)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F3D2F')
            .layoutWeight(1)
            .margin({ left: 8 })
          if (this.dashboard.patient.bedNo.length > 0) {
            Text(this.dashboard.patient.bedNo + '床')
              .fontSize(13)
              .fontColor('#7A8074')
              .backgroundColor('#E8E5D8')
              .borderRadius(4)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })

        if (this.loading) {
          Column() {
            LoadingProgress()
              .width(40)
              .height(40)
              .color('#1F3D2F')
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          Scroll() {
            Column() {
               this.AlertPreviewCard();
               this.DiagnosisPreviewCard();
               this.DataPreviewCard();
               this.RecordsPreviewCard();
            }
            .padding({ left: 16, right: 16, bottom: 80 })
          }
          .layoutWeight(1)
        }

        Row() {
          Button('上传图片')
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor('#1F3D2F')
            .borderRadius(8)
            .height(40)
            .layoutWeight(1)
            .onClick(() => { this.pickImage(); })
          Button('上传PDF')
            .fontSize(12)
            .fontColor('#1F3D2F')
            .backgroundColor('#E8E5D8')
            .borderRadius(8)
            .height(40)
            .layoutWeight(1)
            .margin({ left: 8 })
            .onClick(() => { this.pickPdf(); })
          Button('输入文本')
            .fontSize(12)
            .fontColor('#1F3D2F')
            .backgroundColor('#E8E5D8')
            .borderRadius(8)
            .height(40)
            .layoutWeight(1)
            .margin({ left: 8 })
          Button('手动录入')
            .fontSize(12)
            .fontColor('#1F3D2F')
            .backgroundColor('#E8E5D8')
            .borderRadius(8)
            .height(40)
            .layoutWeight(1)
            .margin({ left: 8 })
            .onClick(() => { this.showManualInput = true; })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .backgroundColor('#FFFFFF')

        if (this.uploading) {
          Row() {
            LoadingProgress()
              .width(20)
              .height(20)
              .color('#1F3D2F')
              .margin({ right: 8 })
            Text(this.uploadMsg)
              .fontSize(13)
              .fontColor('#1F3D2F')
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 6, bottom: 6 })
          .backgroundColor('#FFF8E1')
        } else if (this.uploadMsg.length > 0) {
          Text(this.uploadMsg)
            .fontSize(13)
            .fontColor('#E76F2C')
            .width('100%')
            .padding({ left: 16, right: 16, top: 6, bottom: 6 })
            .backgroundColor('#FFF3E0')
        }
        }
       }
       .width('100%')
       .height('100%')
       .backgroundColor('#F5F4EF')

        if (this.showTimelineDialog) {
          this.TimelineDialog();
        }
        if (this.showExamTimeEditor) {
          this.ExamTimeEditorDialog();
        }
        if (this.showManualInput) {
         this.ManualInputDialog();
       }
        if (this.showDeleteConfirm) {
           this.DeleteConfirmDialog();
         }
         if (this.showKbReader) {
           this.KbReaderOverlay();
         }
         if (this.showAddDiagnosis) {
           this.AddDiagnosisDialog();
         }
      } else {
       ImageEditor({
         showEditor: $showImageEditor,
         editorResultBase64: $editorResultBase64,
         editorResultMime: $editorResultMime,
         imageUri: this.editorImageUri
       })
      }
     }
     .width('100%')
     .height('100%')
    }

   @Builder
  AlertPreviewCard() {
    Column() {
      Row() {
        Text('预警')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F3D2F')
        if (this.getWarningAlerts().length + this.dashboard.labAlerts.length > 0) {
          Text((this.getWarningAlerts().length + this.dashboard.labAlerts.length).toString())
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor('#B1452A')
            .borderRadius(10)
            .padding({ left: 6, right: 6, top: 1, bottom: 1 })
            .margin({ left: 6 })
        }
        Blank()
      }
      .width('100%')

      if (this.getWarningAlerts().length > 0) {
        Column() {
          ForEach(this.getWarningAlerts().slice(0, 3), (alert: PatientAlert) => {
            Row() {
              Column()
                .width(3)
                .height(12)
                .backgroundColor(getTierColor(this.parseAlertResult(alert).tierClass))
                .borderRadius(1)
                .margin({ right: 6 })
              Text(alert.calcName)
                .fontSize(13)
                .fontColor('#1F3D2F')
                .layoutWeight(1)
              Text(this.parseAlertResult(alert).tier)
                .fontSize(11)
                .fontColor(getTierColor(this.parseAlertResult(alert).tierClass))
                .maxLines(1)
            }
            .width('100%')
            .padding({ top: 4, bottom: 4 })
          }, (alert: PatientAlert) => alert.id.toString())
          if (this.getWarningAlerts().length > 3) {
            Text('还有' + (this.getWarningAlerts().length - 3) + '项评分预警...')
              .fontSize(11)
              .fontColor('#7A8074')
              .margin({ top: 2 })
          }
        }
        .width('100%')
        .margin({ top: 8 })
      }

      if (this.dashboard.labAlerts.length > 0) {
        Column() {
          Row()
            .width('100%')
            .height(1)
            .backgroundColor('#E0DCC8')
            .margin({ top: 4, bottom: 4 });
          ForEach(this.dashboard.labAlerts.slice(0, 3), (la: PatientLabAlert) => {
            Row() {
              Column()
                .width(3)
                .height(12)
                .backgroundColor(this.getLabAlertUrgencyColor(la.urgency))
                .borderRadius(1)
                .margin({ right: 6 })
              Text(la.fieldLabel + ' ' + la.value)
                .fontSize(12)
                .fontColor('#1F3D2F')
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(la.threshold)
                .fontSize(10)
                .fontColor(this.getLabAlertUrgencyColor(la.urgency))
                .maxLines(1)
            }
            .width('100%')
            .padding({ top: 3, bottom: 3 })
          }, (la: PatientLabAlert) => la.id.toString())
          if (this.dashboard.labAlerts.length > 3) {
            Text('还有' + (this.dashboard.labAlerts.length - 3) + '项检验预警...')
              .fontSize(11)
              .fontColor('#7A8074')
              .margin({ top: 2 })
          }
        }
        .width('100%')
        .margin({ top: 4 })
      }

      if (this.getWarningAlerts().length === 0 && this.dashboard.labAlerts.length === 0) {
        Text('暂无异常预警')
          .fontSize(12)
          .fontColor('#7A8074')
          .margin({ top: 4 })
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .margin({ bottom: 8 })
    .onClick(() => { this.showAlertDetail = true; })
  }

  @Builder
  DiagnosisPreviewCard() {
    Column() {
      Row() {
        Text('诊断')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F3D2F')
        if (this.dashboard.diagnosisCount > 0) {
          Text(this.dashboard.diagnosisCount.toString())
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor('#1F3D2F')
            .borderRadius(10)
            .padding({ left: 6, right: 6, top: 1, bottom: 1 })
            .margin({ left: 6 })
        }
        Blank()
        Row() {
          ForEach(this.getDiagnosisCategoryTags().slice(0, 4), (tag: string) => {
            Text(tag)
              .fontSize(10)
              .fontColor('#1F3D2F')
              .backgroundColor('#E8E5D8')
              .borderRadius(4)
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .margin({ left: 3 })
          }, (tag: string) => tag)
        }
      }
      .width('100%')

      if (this.dashboard.diagnoses.length > 0) {
        Column() {
          ForEach(this.dashboard.diagnoses.slice(0, 3), (diag: PatientDiagnosis) => {
            Row() {
              Column()
                .width(3)
                .height(14)
                .backgroundColor(this.getUrgencyColor(diag.urgency))
                .borderRadius(1)
                .margin({ right: 6 })
              Text(diag.name)
                .fontSize(13)
                .fontColor('#1F3D2F')
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(this.getUrgencyLabel(diag.urgency))
                .fontSize(9)
                .fontColor(this.getUrgencyColor(diag.urgency))
                .margin({ left: 4 })
            }
            .width('100%')
            .padding({ top: 3, bottom: 3 })
          }, (diag: PatientDiagnosis) => diag.id.toString())
          if (this.dashboard.diagnoses.length > 3) {
            Text('还有' + (this.dashboard.diagnoses.length - 3) + '项...')
              .fontSize(11)
              .fontColor('#7A8074')
              .margin({ top: 2 })
          }
        }
        .width('100%')
        .margin({ top: 8 })
      } else {
        Text('暂无诊断')
          .fontSize(12)
          .fontColor('#7A8074')
          .margin({ top: 4 })
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .margin({ bottom: 12 })
    .onClick(() => { this.showDiagnosisDetail = true; })
  }

  @Builder
  AlertDetailPage() {
    Column() {
      Row() {
        Button('< 返回')
          .fontSize(14)
          .fontColor('#1F3D2F')
          .backgroundColor(Color.Transparent)
          .onClick(() => { this.showAlertDetail = false; })
        Text('预警详情')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F3D2F')
          .layoutWeight(1)
          .margin({ left: 8 })
        if (this.getWarningAlerts().length + this.dashboard.labAlerts.length > 0) {
          Text((this.getWarningAlerts().length + this.dashboard.labAlerts.length).toString())
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor('#B1452A')
            .borderRadius(10)
            .padding({ left: 6, right: 6, top: 1, bottom: 1 })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column() {
          if (this.getWarningAlerts().length === 0 && this.dashboard.labAlerts.length === 0) {
            Text('当前无异常预警')
              .fontSize(14)
              .fontColor('#7A8074')
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(40)
          } else {
            if (this.getWarningAlerts().length > 0) {
              Column() {
                Row() {
                  Text('评分预警')
                    .fontSize(13)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#1F3D2F')
                }
                .width('100%')
                .margin({ bottom: 4 })
                ForEach(this.getWarningAlerts(), (alert: PatientAlert) => {
                  this.AlertCard(alert);
                }, (alert: PatientAlert) => alert.id.toString())
              }
              .width('100%')
              .margin({ bottom: 8 });
            }
            if (this.dashboard.labAlerts.length > 0) {
              Column() {
                Row() {
                  Text('检验预警')
                    .fontSize(13)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#1F3D2F')
                }
                .width('100%')
                .margin({ bottom: 4 })
                ForEach(this.dashboard.labAlerts, (la: PatientLabAlert) => {
                  this.LabAlertCard(la);
                }, (la: PatientLabAlert) => la.id.toString())
              }
              .width('100%');
            }
          }
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 16 })
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F4EF')
  }

  getWarningAlerts(): PatientAlert[] {
    const result: PatientAlert[] = [];
    for (let i = 0; i < this.dashboard.alerts.length; i++) {
      const tierClass = this.parseAlertResult(this.dashboard.alerts[i]).tierClass;
      if (tierClass !== 'tier-ok' && tierClass !== 'tier-info') {
        result.push(this.dashboard.alerts[i]);
      }
    }
    return result;
  }

  @Builder
  DiagnosisDetailPage() {
    Column() {
      Row() {
        Button('< 返回')
          .fontSize(14)
          .fontColor('#1F3D2F')
          .backgroundColor(Color.Transparent)
          .onClick(() => { this.showDiagnosisDetail = false; })
        Text('诊断详情')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F3D2F')
          .layoutWeight(1)
          .margin({ left: 8 })
        Row() {
          Text('+')
            .fontSize(14)
            .fontColor('#2B6CB0')
            .margin({ left: 6 })
            .onClick(() => {
              this.addDiagName = '';
              this.addDiagCategory = '代谢';
              this.showAddDiagnosis = true;
            })
          Text('⟳')
            .fontSize(16)
            .fontColor('#3D6B4F')
            .margin({ left: 8 })
            .onClick(async () => {
              this.loading = true;
              await this.patientService.fullReDiagnose(this.currentPatientId);
              this.loading = false;
              this.loadDashboard();
            })
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column() {
          if (this.dashboard.diagnoses.length === 0) {
            Text('暂无诊断')
              .fontSize(14)
              .fontColor('#7A8074')
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(40)
          } else {
            this.DiagnosisGroup('rule', '确定性', '#1F3D2F', false);
            this.DiagnosisGroup('user', '自添加', '#3D6B4F', false);
            this.DiagnosisGroup('partial', '可能性', '#C8881A', false);
            this.DiagnosisGroup('llm_hint', 'LLM提示', '#7A6B9D', true);
          }
          Row() {
            Text('+ 添加诊断')
              .fontSize(13)
              .fontColor('#2B6CB0')
              .margin({ top: 8 })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.addDiagName = '';
            this.addDiagCategory = '代谢';
            this.showAddDiagnosis = true;
          })
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 16 })
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F4EF')
  }

  getDiagnosesBySource(source: string): PatientDiagnosis[] {
    return this.dashboard.diagnoses.filter((d: PatientDiagnosis): boolean => d.source === source);
  }

  @Builder
  DiagnosisGroup(source: string, label: string, color: string, isLlmGroup: boolean) {
    if (this.getDiagnosesBySource(source).length > 0) {
      Column() {
        Row() {
          Column()
            .width(4)
            .height(16)
            .backgroundColor(color)
            .borderRadius(2)
            .margin({ right: 6 })
          Text(label)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(color)
          Text(this.getDiagnosesBySource(source).length.toString())
            .fontSize(11)
            .fontColor('#7A8074')
            .margin({ left: 4 })
        }
        .width('100%')
        .margin({ top: 8, bottom: 4 })

        ForEach(this.getDiagnosesBySource(source), (diag: PatientDiagnosis) => {
          Row() {
            this.DiagnosisCard(diag, isLlmGroup);
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
        }, (diag: PatientDiagnosis) => diag.id.toString())
      }
      .width('100%');
    }
  }

  getDangerCount(): number {
    let count = 0;
    for (let i = 0; i < this.dashboard.alerts.length; i++) {
      if (this.parseAlertResult(this.dashboard.alerts[i]).tierClass === 'tier-danger') {
        count++;
      }
    }
    return count;
  }

  getWarnCount(): number {
    let count = 0;
    for (let i = 0; i < this.dashboard.alerts.length; i++) {
      if (this.parseAlertResult(this.dashboard.alerts[i]).tierClass === 'tier-warn') {
        count++;
      }
    }
    return count;
  }

  getDiagnosisCategoryTags(): string[] {
    const tagSet = new Set<string>();
    for (let i = 0; i < this.dashboard.diagnoses.length; i++) {
      tagSet.add(this.dashboard.diagnoses[i].category);
    }
    return Array.from(tagSet);
  }

  getUrgencyColor(urgency: string): string {
    if (urgency === 'critical') {
      return '#B1452A';
    }
    if (urgency === 'warning') {
      return '#C8881A';
    }
    return '#3D6B4F';
  }

  getUrgencyLabel(urgency: string): string {
    if (urgency === 'critical') {
      return '危重';
    }
    if (urgency === 'warning') {
      return '警示';
    }
    return '关注';
  }

  getLlmConfirmLabel(confirmed: number): string {
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

  getLlmConfirmColor(confirmed: number): string {
    if (confirmed === 1) {
      return '#3D6B4F';
    }
    if (confirmed === -1) {
      return '#7A8074';
    }
    if (confirmed === 2) {
      return '#C8881A';
    }
    return '#7A8074';
  }

  getSourceLabel(source: string): string {
    if (source === 'partial') {
      return '可能性';
    }
    if (source === 'llm_hint') {
      return 'LLM提示';
    }
    if (source === 'user') {
      return '自添加';
    }
    return '确定性';
  }

  getSourceColor(source: string): string {
    if (source === 'partial') {
      return '#C8881A';
    }
    if (source === 'llm_hint') {
      return '#7A6B9D';
    }
    if (source === 'user') {
      return '#3D6B4F';
    }
    return '#1F3D2F';
  }

  async loadDiagnosisKb() {
    for (const diag of this.dashboard.diagnoses) {
      const existing = this.diagnosisKbMap.find((d: DiagnosisKbData): boolean => d.ruleId === diag.ruleId);
      if (existing !== undefined) {
        continue;
      }
      const kbData = new DiagnosisKbData();
      kbData.ruleId = diag.ruleId;
      kbData.loadingKb = true;
      this.diagnosisKbMap = [...this.diagnosisKbMap, kbData];
      const query = diag.name;
      const rule = DIAGNOSIS_RULES.find((r: DiagnosisRule): boolean => r.id === diag.ruleId);
      const ruleDesc = rule !== undefined ? rule.description : '';
      hilog.info(0x0001, 'MedCalc', 'loadDiagnosisKb: ruleId=' + diag.ruleId + ' name=' + query);

      const expandStep = new AgentStep();
      expandStep.agent = 'ExpandAgent';
      expandStep.status = 'running';
      expandStep.input = query;
      kbData.agentSteps = [expandStep];
      this.diagnosisKbMap = [...this.diagnosisKbMap];

      try {
        const searchResult = await this.kbService.smartSearchV2Full(query, ruleDesc);
        const expanded = searchResult.expanded;

        expandStep.status = 'done';
        expandStep.output = expanded.searchTerms.slice(0, 5).join('/') + ' → ' + expanded.directories.slice(0, 5).join('/');
        expandStep.durationMs = 0;
        kbData.expandedInfo = '搜索词: ' + expanded.searchTerms.join(', ') + '\n目录: ' + searchResult.matchedDirs.join(', ');
        kbData.expandedSearchTerms = expanded.searchTerms.slice();
        kbData.expandedEtiologyTerms = expanded.etiologyTerms.slice();
        kbData.expandedTreatmentTerms = expanded.treatmentTerms.slice();
        kbData.expandedMonitoringTerms = expanded.monitoringTerms.slice();

        const searchStep = new AgentStep();
        searchStep.agent = 'SearchAgent';
        searchStep.status = 'done';
        searchStep.input = searchResult.matchedDirs.length.toString() + '个目录';
        searchStep.output = searchResult.candidatePaths.length.toString() + '篇候选';
        kbData.agentSteps = [expandStep, searchStep];

        kbData.candidatePaths = searchResult.candidatePaths;
        kbData.verifiedPaths = searchResult.candidatePaths;
        kbData.matchedDirs = searchResult.matchedDirs;
        const searchResults: SearchResult[] = [];
        for (const path of searchResult.candidatePaths) {
          const sr = new SearchResult();
          sr.path = path;
          sr.title = path.split('/').pop()?.replace(/\.md$/, '') || '';
          searchResults.push(sr);
        }
        kbData.searchResults = searchResults;
        kbData.verifyInfo = '目录限域FTS: ' + searchResult.candidatePaths.length.toString() + '篇候选';
      } catch (_e) {
        expandStep.status = 'error';
        expandStep.output = '搜索异常';
        kbData.searchResults = [];
        kbData.verifiedPaths = [];
        kbData.candidatePaths = [];
        kbData.verifyInfo = '搜索异常';
      }
      kbData.loadingKb = false;
      this.diagnosisKbMap = [...this.diagnosisKbMap];
      this.saveKbData(kbData);
      hilog.info(0x0001, 'MedCalc', 'loadDiagnosisKb: done, verifiedPaths=' + kbData.verifiedPaths.length.toString());
      if (kbData.verifiedPaths.length > 0) {
        this.loadDiagnosisAdvice(diag);
      }
    }
  }

  getDiagnosisKb(ruleId: string): DiagnosisKbData | null {
    for (const item of this.diagnosisKbMap) {
      if (item.ruleId === ruleId) {
        return item;
      }
    }
    return null;
  }

  async loadDiagnosisAdvice(diag: PatientDiagnosis) {
    hilog.info(0x0001, 'MedCalc', 'loadDiagnosisAdvice called for ' + diag.ruleId);
    const kbData = this.getDiagnosisKb(diag.ruleId);
    if (kbData === null) {
      hilog.warn(0x0001, 'MedCalc', 'loadDiagnosisAdvice: kbData is null');
      return;
    }
    if (kbData.recommendations.length > 0) {
      hilog.info(0x0001, 'MedCalc', 'loadDiagnosisAdvice: already has ' + kbData.recommendations.length.toString() + ' recommendations');
      this.activeAdviceRuleId = diag.ruleId;
      this.summaryLines = kbData.summary.length > 0 ? parseKbMarkdown(kbData.summary) : [];
      this.showRecommendationsDetail = true;
      return;
    }
    kbData.loadingAdvice = true;
    kbData.adviceError = '';
    const extractStep = new AgentStep();
    extractStep.agent = 'ExtractAgent';
    extractStep.status = 'running';
    extractStep.input = kbData.verifiedPaths.length.toString() + '篇文献';
    kbData.agentSteps = [...kbData.agentSteps, extractStep];
    this.diagnosisKbMap = [...this.diagnosisKbMap];

    const guidelinePaths: string[] = [];
    const textbookPaths: string[] = [];
    for (const path of kbData.verifiedPaths) {
      if (path.startsWith('实用重症医学/')) {
        textbookPaths.push(path);
      } else {
        guidelinePaths.push(path);
      }
    }

     const MAX_CONTEXT_CHARS = 80000;
     const MAX_GUIDELINE_PER_FILE = 15000;
      const eqr = new ExpandedQueryResult();
      eqr.searchTerms = kbData.expandedSearchTerms;
      eqr.etiologyTerms = kbData.expandedEtiologyTerms;
      eqr.treatmentTerms = kbData.expandedTreatmentTerms;
      eqr.monitoringTerms = kbData.expandedMonitoringTerms;
      const guidelinePathsSorted = await this.prioritizePaths(guidelinePaths, diag.name, eqr);
     let contextText = '';
     let guidelineChars = 0;
     for (const path of guidelinePathsSorted) {
       if (contextText.length >= MAX_CONTEXT_CHARS) { break; }
       const page = await this.kbService.getPage(path);
       if (page !== null && page.content.trim().length >= 100) {
         let content = page.content;
         if (content.length > MAX_GUIDELINE_PER_FILE) {
           const kw: string[] = diag.name.split(/\s+/);
           content = this.kbService.excerptContent(content, kw, MAX_GUIDELINE_PER_FILE);
         }
         contextText += '### [指南] ' + path + '\n---\n' + content + '\n\n';
         guidelineChars += content.length;
       }
     }
     const remainingBudget = Math.max(0, MAX_CONTEXT_CHARS - contextText.length);
    const textbookCount = textbookPaths.length;
    let perChapterBudget = 20000;
    if (textbookCount > 0) {
      perChapterBudget = Math.min(20000, Math.floor(remainingBudget / textbookCount));
    }
     const queryKeywords: string[] = diag.name.split(/\s+/);
     for (const path of textbookPaths) {
       if (contextText.length >= MAX_CONTEXT_CHARS) { break; }
       const page = await this.kbService.getPage(path);
      if (page !== null && page.content.trim().length >= 100) {
        let content: string;
        if (perChapterBudget > 0 && page.content.length > perChapterBudget) {
          content = this.kbService.excerptContent(page.content, queryKeywords, perChapterBudget);
        } else if (perChapterBudget <= 0) {
          content = this.kbService.excerptContent(page.content, queryKeywords, 5000);
        } else {
          content = page.content;
        }
        contextText += '### [教材] ' + path + '\n---\n' + content + '\n\n';
      }
    }
     const partialBudget = Math.max(0, MAX_CONTEXT_CHARS - contextText.length);
     for (const path of kbData.partialPaths) {
       if (contextText.length >= MAX_CONTEXT_CHARS) { break; }
      const page = await this.kbService.getPage(path);
      if (page !== null && page.content.trim().length >= 100) {
        const excerptBudget = Math.min(15000, partialBudget > 0 ? Math.floor(partialBudget / kbData.partialPaths.length) : 5000);
        const content = this.kbService.excerptContent(page.content, queryKeywords, excerptBudget);
        if (content.length >= 100) {
          contextText += '### [片段参考·主题非' + diag.name + '] ' + path + '\n---\n' + content + '\n\n';
        }
      }
    }

    if (contextText.length === 0) {
      extractStep.status = 'error';
      extractStep.output = '无文献内容';
      kbData.loadingAdvice = false;
      kbData.recommendations = [];
      kbData.adviceError = '未找到与当前诊断相关的高质量文献，无法提取建议';
      this.diagnosisKbMap = [...this.diagnosisKbMap];
      this.saveKbData(kbData);
      return;
    }

    const config = this.getLlmConfig();
    if (config === null) {
      extractStep.status = 'error';
      extractStep.output = 'LLM未配置';
      kbData.loadingAdvice = false;
      kbData.adviceError = 'AI模型未配置，请在设置页配置LLM后重试';
      this.diagnosisKbMap = [...this.diagnosisKbMap];
      this.saveKbData(kbData);
      return;
    }

    const rule = DIAGNOSIS_RULES.find((r): boolean => r.id === diag.ruleId);
    const patientContext = this.buildPatientContextStr();
    const isLowRel = kbData.verifiedPaths.length === 0 && kbData.partialPaths.length === 0 && kbData.searchResults.length > 0;
    kbData.isLowRelevance = isLowRel;

    const extractStartTime = Date.now();
    const systemPrompt = '你是ICU临床指南助手。从给定的参考资料中提取与当前诊断直接相关的临床推荐意见和知识要点，同时生成临床要点归纳。' +
      '体裁区分：' +
      '1)对于有明确推荐等级/证据级别的结构化指南内容(如"强烈推荐""条件推荐""GPS"等)，type="推荐意见"，保留原文等级；' +
      '2)对于叙述式教材内容(无明确推荐等级的病理生理、机制、诊断依据、监测方法等)，type="知识要点"，evidenceLevel填"-"；' +
      '3)如果同一来源同时包含两种体裁，type="混合"。' +
      '判断示例：' +
      '- "脓毒症1小时集束化治疗：1)测量乳酸-强烈推荐(Grade 1)"→type="推荐意见"，保留等级' +
      '- "脓毒症休克的病理生理特征包括..."→type="知识要点"，不编造等级' +
      '- "AKI的诊断标准：KDIGO分期...推荐监测尿量"→type="混合"' +
      '段落级相关性约束：只提取段落主题与查询疾病直接相关的段落，排除仅作为鉴别诊断提及、病原学举例、或并发症列表中顺带提及的段落。' +
      '片段参考约束：标记为[片段参考]的资料来自主题非查询疾病的文章，只包含与查询疾病相关的段落截取。只从这些片段中提取与查询疾病直接相关的临床内容，不要提取原文中关于其他疾病的诊断或治疗内容。' +
      '留空原则：如果某类别在参考资料中确实没有相关内容，该类别输出空数组[]，严禁从常识推断或编造。' +
      '将推荐意见分为以下4类（每类名称严格使用下方4字名称）：' +
      '"病理生理"：机制、病理生理要点；' +
      '"诊断要点"：诊断标准、诊断要点、鉴别诊断要点；' +
      '"监测评估"：监测指标、评估方法、复查时机、评分工具、观察项目；' +
      '"治疗建议"：治疗措施、药物方案、剂量建议、复苏目标。' +
      '特别注意"监测评估"类：如果参考资料提到任何需要监测/复查/评估的指标（如乳酸、尿量、生命体征、器官功能等）或评分工具（如SOFA、APACHE、CURB-65等），必须提取到"监测评估"类，不要遗漏。' +
      '\n\n输出格式要求（严格遵守）：' +
      '第一部分：JSON，包含recommendations和gaps数组，不要在JSON中放summary。格式如下：\n' +
      '```json\n{"recommendations":[{"text":"内容","evidenceLevel":"级别或-","source":"来源标注","category":"病理生理|诊断要点|监测评估|治疗建议","type":"推荐意见|知识要点|混合"}],"gaps":[{"category":"治疗建议","supplementaryTerms":["补搜词1","补搜词2"]}]}\n```\n' +
      '第二部分：临床要点归纳（纯markdown，不在JSON内）。以"## 临床要点"开头，按"病理生理""诊断要点""监测评估""治疗建议"四方面分节归纳，用分点列表呈现，整合相关条目为逻辑清晰的要点，保留关键数值和药物信息，用**加粗**标记关键词。不是精简而是重组，不要遗漏已有条目。某类别无内容则不输出该节。' +
      '\n\n缺口检测：如果某类别在参考资料中确实为空，判断该类别是否属于"该诊断在ICU一定有此类内容"的情况：治疗建议/诊断要点/监测评估为空时，在gaps数组中输出该类别及补搜词(如药物名、检查名、操作名)；病理生理为空不输出gaps。如果无缺口，gaps输出空数组[]。' +
      '\n\n关键约束（严格遵守，违反即为严重错误）：' +
      '1. 临床要点归纳(summary)中的每一条内容，必须在recommendations数组中有对应的条目。summary不能包含recommendations中不存在的内容。' +
      '2. 每条recommendation的text必须直接来自参考资料中与当前诊断疾病直接相关的段落，不能把讲其他疾病的内容张冠李戴。例如参考资料来自"脓毒症/机制"文章，其中关于脓毒症心肌抑制的段落不应提取为"代谢性酸中毒的诊断要点"。' +
      '3. 如果参考资料中确实没有某类别的相关内容，该类别在recommendations中输出空数组[]，summary中也不输出该节。严禁从常识或其他疾病的内容推断填补。';

    const userText = '## 患者情况\n- 诊断：' + diag.name +
      (rule !== undefined ? '\n- 依据：' + rule.description : '') +
      '\n' + patientContext +
      (isLowRel ? '\n⚠️ 注意：以下文献为FTS回退结果，可能与诊断主题相关性较低，请严格按相关性提取，不确定则不提取。' : '') +
      '\n## 参考资料\n' + contextText +
      '\n## 任务\n从以上参考资料提取相关推荐意见和知识要点，并生成临床要点归纳。先输出JSON部分，再输出markdown临床要点部分。';

    let recommendations: GuidelineRecommendation[] = [];
    let summary = '';
    let gaps: GapSignal[] = [];

    try {
      hilog.info(0x0001, 'MedCalc', 'ExtractAgent: calling LLM, contextLen=' + contextText.length.toString());
      const response = await sendVisionRequest(config, systemPrompt, userText, '', '');
      hilog.info(0x0001, 'MedCalc', 'ExtractAgent: LLM response length=' + response.length.toString());
      const parsed = this.parseRecommendationsAndSummary(response);
      recommendations = parsed.recommendations;
      summary = parsed.summary;
      gaps = parsed.gaps;
      extractStep.status = 'done';
      extractStep.durationMs = Date.now() - extractStartTime;
      extractStep.output = recommendations.length.toString() + '条建议' +
        (gaps.length > 0 ? ' ⚠️缺口:' + gaps.map((g: GapSignal): string => g.category).join(',') : '');
      hilog.info(0x0001, 'MedCalc', 'ExtractAgent: parsed ' + recommendations.length.toString() + ' recommendations, gaps=' + gaps.length.toString());
    } catch (_e) {
      hilog.error(0x0001, 'MedCalc', 'ExtractAgent: LLM call failed: ' + String(_e));
      extractStep.status = 'error';
      extractStep.output = 'LLM调用失败';
      kbData.recommendations = [];
      kbData.summary = '';
      kbData.loadingAdvice = false;
      kbData.adviceError = 'AI服务调用失败，请检查LLM配置或网络后重试';
      this.diagnosisKbMap = [...this.diagnosisKbMap];
      this.saveKbData(kbData);
      return;
    }

    kbData.agentSteps = [...kbData.agentSteps];

    let auditIssues: AuditIssue[] = [];
    if (recommendations.length > 0) {
      const auditResult = await this.runAuditAgent(recommendations, diag.name, config, kbData);
      auditIssues = auditResult.issues;
      gaps = auditResult.gaps;
      if (auditResult.issues.length > 0) {
        const removedSet = new Set<number>();
        for (const issue of auditResult.issues) {
          if (issue.type === '交叉污染') {
            removedSet.add(issue.index);
          } else if (issue.type === '证据等级错误') {
            if (issue.index >= 0 && issue.index < recommendations.length) {
              recommendations[issue.index].evidenceLevel = '-';
            }
          }
        }
        if (removedSet.size > 0) {
          const filtered: GuidelineRecommendation[] = [];
          for (let i = 0; i < recommendations.length; i++) {
            if (!removedSet.has(i)) {
              filtered.push(recommendations[i]);
            }
          }
          recommendations = filtered;
        }
      }
    }

    if (gaps.length > 0 && kbData.feedbackRound < 1 && kbData.matchedDirs.length > 0) {
      const feedbackStep = new AgentStep();
      feedbackStep.agent = 'Feedback';
      feedbackStep.status = 'running';
      feedbackStep.input = gaps.map((g: GapSignal): string => g.category + ':' + g.supplementaryTerms.slice(0, 3).join(',')).join('; ');
      kbData.agentSteps = [...kbData.agentSteps, feedbackStep];
      this.diagnosisKbMap = [...this.diagnosisKbMap];

      const suppTerms: string[] = [];
      for (const gap of gaps) {
        for (const term of gap.supplementaryTerms) {
          if (suppTerms.indexOf(term) < 0) {
            suppTerms.push(term);
          }
        }
      }

      let suppPaths: string[] = [];
      try {
        suppPaths = await this.kbService.directoryLimitedFts(kbData.matchedDirs, suppTerms);
      } catch (_e) {
        hilog.warn(0x0001, 'MedCalc', 'Feedback: supplementary search failed');
      }

      const existingPathSet: Record<string, boolean> = {};
      for (const p of kbData.verifiedPaths) { existingPathSet[p] = true; }
      const newPaths: string[] = [];
      for (const p of suppPaths) {
        if (existingPathSet[p] === undefined) {
          newPaths.push(p);
          existingPathSet[p] = true;
        }
      }

      feedbackStep.output = '补搜' + newPaths.length.toString() + '篇';
      hilog.info(0x0001, 'MedCalc', 'Feedback: supplementary found ' + newPaths.length.toString() + ' new articles');

      if (newPaths.length > 0) {
        const suppExtractStep = new AgentStep();
        suppExtractStep.agent = 'ExtractAgent';
        suppExtractStep.status = 'running';
        suppExtractStep.input = '补搜' + newPaths.length.toString() + '篇(缺口类别)';
        kbData.agentSteps = [...kbData.agentSteps, suppExtractStep];
        this.diagnosisKbMap = [...this.diagnosisKbMap];

        let suppContext = '';
        for (const path of newPaths) {
          const page = await this.kbService.getPage(path);
          if (page !== null && page.content.trim().length >= 100) {
            const excerpt = this.kbService.excerptContent(page.content, queryKeywords, 6000);
            suppContext += '### [补搜] ' + path + '\n---\n' + excerpt + '\n\n';
          }
        }

        if (suppContext.length > 0) {
          const gapCategories = gaps.map((g: GapSignal): string => g.category);
          const suppSystemPrompt = '你是ICU临床指南助手。从给定的补搜资料中只提取以下缺口类别的建议：' +
            gapCategories.join('、') +
            '。格式：```json\n{"recommendations":[{"text":"内容","evidenceLevel":"级别或-","source":"来源","category":"类别","type":"推荐意见|知识要点|混合"}]}\n```\n' +
            '只提取与诊断"' + diag.name + '"直接相关的内容，不要提取其他疾病的建议。';
          const suppUserText = '诊断：' + diag.name + '\n## 补搜参考资料\n' + suppContext;

          try {
            const suppStartTime = Date.now();
            const suppResponse = await sendVisionRequest(config, suppSystemPrompt, suppUserText, '', '');
            const suppParsed = this.parseRecommendations(suppResponse);
            for (const rec of suppParsed) {
              recommendations.push(rec);
            }
            suppExtractStep.status = 'done';
            suppExtractStep.durationMs = Date.now() - suppStartTime;
            suppExtractStep.output = suppParsed.length.toString() + '条补充建议';
            hilog.info(0x0001, 'MedCalc', 'Feedback ExtractAgent: got ' + suppParsed.length.toString() + ' supplementary recommendations');
          } catch (_e) {
            suppExtractStep.status = 'error';
            suppExtractStep.output = '补搜提取失败';
          }
        } else {
          suppExtractStep.status = 'done';
          suppExtractStep.output = '无有效内容';
        }

        for (const p of newPaths) {
          kbData.verifiedPaths.push(p);
          kbData.candidatePaths.push(p);
          const sr = new SearchResult();
          sr.path = p;
          sr.title = p.split('/').pop()?.replace(/\.md$/, '') || '';
          kbData.searchResults.push(sr);
        }
      }

      feedbackStep.status = 'done';
      kbData.feedbackRound = 1;
      kbData.agentSteps = [...kbData.agentSteps];
    }

    const mergeStep = new AgentStep();
    mergeStep.agent = 'MergeAgent';
    mergeStep.status = 'done';
    mergeStep.input = recommendations.length.toString() + '条建议';
    const catCount: Record<string, number> = {};
    for (const rec of recommendations) {
      if (catCount[rec.category] === undefined) {
        catCount[rec.category] = 0;
      }
      catCount[rec.category] = catCount[rec.category] + 1;
    }
    mergeStep.output = Object.keys(catCount).map((k: string): string => k + catCount[k] + '条').join(' ');
    kbData.agentSteps = [...kbData.agentSteps, mergeStep];

    kbData.recommendations = recommendations;
    kbData.summary = summary;
    if (recommendations.length === 0) {
      kbData.adviceError = summary.length > 0 ? summary.substring(0, 120) : 'AI未能从文献中提取出有效建议，可点击重搜后再试';
    }
    if (this.activeAdviceRuleId === diag.ruleId) {
      this.summaryLines = summary.length > 0 ? parseKbMarkdown(summary) : [];
    }
    kbData.loadingAdvice = false;
    this.diagnosisKbMap = [...this.diagnosisKbMap];
    this.activeAdviceRuleId = diag.ruleId;
    this.summaryLines = summary.length > 0 ? parseKbMarkdown(summary) : [];
    this.saveKbData(kbData);
    if (recommendations.length > 0) {
      this.adviceReadyRuleId = diag.ruleId;
      setTimeout(() => {
        if (this.adviceReadyRuleId === diag.ruleId) {
          this.adviceReadyRuleId = '';
        }
      }, 3000);
    }
  }

  async prioritizePaths(paths: string[], query: string, expanded?: ExpandedQueryResult): Promise<string[]> {
    const titleMap = await this.kbService.batchGetIndexedTitles(paths);
    const searchTerms = expanded !== undefined ? expanded.searchTerms : [];
    const treatmentTerms = expanded !== undefined ? expanded.treatmentTerms : [];
    const monitoringTerms = expanded !== undefined ? expanded.monitoringTerms : [];
    const etiologyTerms = expanded !== undefined ? expanded.etiologyTerms : [];
    const queryLower = query.toLowerCase();
    const scored: PathScore[] = [];
    for (const p of paths) {
      let s = 0;
      const pLower = p.toLowerCase();
      if (pLower.includes(queryLower)) { s += 10; }
      const indexedTitle = titleMap.get(p);
      const tagText = indexedTitle !== undefined ? indexedTitle.toLowerCase() : pLower;
      for (const term of searchTerms) {
        if (tagText.includes(term.toLowerCase())) { s += 6; }
      }
      for (const term of treatmentTerms) {
        if (tagText.includes(term.toLowerCase())) { s += 5; }
      }
      for (const term of monitoringTerms) {
        if (tagText.includes(term.toLowerCase())) { s += 3; }
      }
      for (const term of etiologyTerms) {
        if (tagText.includes(term.toLowerCase())) { s += 1; }
      }
      if (p.includes('实用重症医学')) { s += 5; }
      if (p.match(/20\d{2}\s/) !== null) { s += 3; }
      const ps = new PathScore();
      ps.path = p;
      ps.score = s;
      scored.push(ps);
    }
    scored.sort((a: PathScore, b: PathScore): number => b.score - a.score);
    const result: string[] = [];
    for (const item of scored) { result.push(item.path); }
    return result;
  }

  async runAuditAgent(recommendations: GuidelineRecommendation[], diagName: string, config: ApiServiceConfig, kbData: DiagnosisKbData): Promise<AuditAgentResult> {
    const auditStep = new AgentStep();
    auditStep.agent = 'AuditAgent';
    auditStep.status = 'running';
    auditStep.input = recommendations.length.toString() + '条建议';
    kbData.agentSteps = [...kbData.agentSteps, auditStep];
    this.diagnosisKbMap = [...this.diagnosisKbMap];

    const auditStartTime = Date.now();
    const recList: Record<string, string>[] = [];
    for (let i = 0; i < recommendations.length; i++) {
      recList.push({
        'index': i.toString(),
        'text': recommendations[i].text.substring(0, 200),
        'evidenceLevel': recommendations[i].evidenceLevel,
        'category': recommendations[i].category,
        'type': recommendations[i].type,
        'source': recommendations[i].source,
      });
    }

    const auditPrompt = '你是ICU临床建议质量审核员。审核以下提取结果，检查3类问题：\n\n' +
      '1. 交叉污染：某条建议描述的疾病/主题与诊断"' + diagName + '"无关\n' +
      '   判断标准：建议text中提到其他疾病作为主语/主要对象，而非作为鉴别诊断提及\n' +
      '   例：诊断是"代谢性酸中毒"，某条建议主要讲"脓毒症的心肌抑制"→交叉污染\n' +
      '   非：诊断是"代谢性酸中毒"，建议提到"脓毒症可导致代谢性酸中毒"→不是交叉污染\n\n' +
      '2. 证据等级错误：type="知识要点"但evidenceLevel不是"-"\n' +
      '   知识要点不应有证据等级，应填"-"\n\n' +
      '3. 类别缺口：某类别为空，但该诊断在ICU临床实践中一定有此类内容\n' +
      '   高钾血症/脓毒症/ARDS/呼吸衰竭等一定有治疗措施\n' +
      '   大多数ICU诊断都有监测指标\n\n' +
      '输出JSON（严格遵守格式）：\n' +
      '```json\n{"issues":[{"index":0,"type":"交叉污染","description":"问题描述"}],"gaps":[{"category":"治疗建议","supplementaryTerms":["补搜词1","补搜词2"]}]}\n```\n' +
      '如果没有问题，issues和gaps输出空数组[]。\n\n' +
      '审核的recommendations列表：\n' +
      JSON.stringify(recList);

    const auditResult = new AuditAgentResult();

    try {
      const auditResponse = await sendVisionRequest(config, auditPrompt, '', '', '');
      hilog.info(0x0001, 'MedCalc', 'AuditAgent: response=' + auditResponse.substring(0, 500));

      let jsonStr = auditResponse;
      const cbStart = auditResponse.indexOf('```json');
      if (cbStart >= 0) {
        const afterStart = auditResponse.indexOf('{', cbStart);
        const cbEnd = auditResponse.indexOf('```', afterStart >= 0 ? afterStart : cbStart + 7);
        if (afterStart >= 0 && cbEnd > afterStart) {
          jsonStr = auditResponse.substring(afterStart, cbEnd);
        }
      } else {
        const jStart = auditResponse.indexOf('{');
        const jEnd = auditResponse.lastIndexOf('}');
        if (jStart >= 0 && jEnd > jStart) {
          jsonStr = auditResponse.substring(jStart, jEnd + 1);
        }
      }

      const parsed: Object | null = JSON.parse(jsonStr);
      if (parsed !== null) {
        const obj = parsed as Record<string, Object>;
        const issuesArr = obj['issues'] as Array<Record<string, Object>>;
        if (issuesArr !== undefined && issuesArr !== null) {
          for (const item of issuesArr) {
            const ai = new AuditIssue();
            ai.index = (item['index'] as number) || 0;
            ai.type = (item['type'] as string) || '';
            ai.description = (item['description'] as string) || '';
            auditResult.issues.push(ai);
          }
        }
        const gapsArr = obj['gaps'] as Array<Record<string, Object>>;
        if (gapsArr !== undefined && gapsArr !== null) {
          for (const item of gapsArr) {
            const gs = new GapSignal();
            gs.category = (item['category'] as string) || '';
            const terms = item['supplementaryTerms'] as Array<string>;
            if (terms !== undefined && terms !== null) {
              gs.supplementaryTerms = terms;
            }
            auditResult.gaps.push(gs);
          }
        }
      }

      auditStep.status = 'done';
      auditStep.durationMs = Date.now() - auditStartTime;
      const issueSummary: string[] = [];
      if (auditResult.issues.length > 0) {
        const crossCount = auditResult.issues.filter((ii: AuditIssue): boolean => ii.type === '交叉污染').length;
        const levelCount = auditResult.issues.filter((ii: AuditIssue): boolean => ii.type === '证据等级错误').length;
        if (crossCount > 0) { issueSummary.push('交叉污染:' + crossCount.toString() + '条'); }
        if (levelCount > 0) { issueSummary.push('证据等级:' + levelCount.toString() + '条'); }
      }
      if (auditResult.gaps.length > 0) {
        issueSummary.push('缺口:' + auditResult.gaps.map((g: GapSignal): string => g.category).join(','));
      }
      auditStep.output = issueSummary.length > 0 ? issueSummary.join(' ') : '通过';
    } catch (_e) {
      hilog.warn(0x0001, 'MedCalc', 'AuditAgent: failed: ' + String(_e));
      auditStep.status = 'error';
      auditStep.output = '审核失败';
    }

    kbData.agentSteps = [...kbData.agentSteps];
    this.diagnosisKbMap = [...this.diagnosisKbMap];

    return auditResult;
  }

  getLlmConfig(): ApiServiceConfig | null {
    const prefsService = PreferencesService.getInstance();
    const models = prefsService.getLlmModels();
    const selectedId = prefsService.getSelectedLlmId();
    if (selectedId.length === 0 || models.length === 0) {
      return null;
    }
    const model = models.find((m): boolean => m.id === selectedId);
    if (model === undefined) {
      return null;
    }
    return model.toApiServiceConfig();
  }

  buildPatientContextStr(): string {
    const parts: string[] = [];
    for (const diag of this.dashboard.diagnoses) {
      parts.push(diag.name);
    }
    const alertTiers: string[] = [];
    for (const alert of this.dashboard.alerts) {
      const tier = this.parseAlertResult(alert).tier;
      if (tier.length > 0) {
        alertTiers.push(alert.calcName + ':' + tier);
      }
    }
    if (alertTiers.length > 0) {
      parts.push('评分: ' + alertTiers.slice(0, 5).join(', '));
    }
    return '- 关键数据：' + parts.join(', ');
  }

  parseRecommendations(responseText: string): GuidelineRecommendation[] {
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

  parseRecommendationsAndSummary(responseText: string): ParsedRecommendations {
    const result = new ParsedRecommendations();
    const summaryMarker = '## 临床要点';
    const markerIdx = responseText.indexOf(summaryMarker);
    let jsonPart = responseText;
    let summaryPart = '';
    if (markerIdx >= 0) {
      jsonPart = responseText.substring(0, markerIdx);
      summaryPart = responseText.substring(markerIdx);
    }
    result.recommendations = this.parseRecommendations(jsonPart);
    result.gaps = this.parseGapsFromJson(jsonPart);
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

  parseGapsFromJson(responseText: string): GapSignal[] {
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

  getKbSearchResultTitle(sr: SearchResult): string {
    if (sr.title.length > 0) {
      return sr.title;
    }
    return sr.path.split('/').pop() || sr.path;
  }

  getKbGuidelineName(sr: SearchResult): string {
    const parts = sr.path.split('/');
    if (parts.length >= 3) {
      return parts.slice(0, parts.length - 1).join('/');
    } else if (parts.length === 2) {
      return parts[0];
    }
    return '';
  }

  getRecommendationSummary(recs: GuidelineRecommendation[]): string {
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

  getCategoryCount(recs: GuidelineRecommendation[], cat: string): number {
    let c = 0;
    for (const rec of recs) {
      if (rec.category === cat) {
        c++;
      }
    }
    return c;
  }

  getCategoryBorderColor(cat: string): string {
    if (cat === '病理生理') {
      return '#7A6B9D';
    }
    if (cat === '诊断要点') {
      return '#5B7FA5';
    }
    if (cat === '监测评估') {
      return '#C8881A';
    }
    if (cat === '治疗建议') {
      return '#3D6B4F';
    }
    return '#7A8074';
  }

  getCategoryLabel(cat: string): string {
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

  @Builder
  DiagnosisCard(diag: PatientDiagnosis, isLlmGroup: boolean) {
    Column() {
      Row() {
        if (isLlmGroup) {
          Text('💡')
            .fontSize(12)
            .margin({ right: 4 })
        }
        Text(diag.name)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F3D2F')
          .layoutWeight(1)
        Text(this.getUrgencyLabel(diag.urgency))
          .fontSize(10)
          .fontColor(this.getUrgencyColor(diag.urgency))
          .backgroundColor(this.getUrgencyColor(diag.urgency) + '20')
          .borderRadius(4)
          .padding({ left: 4, right: 4, top: 1, bottom: 1 })
          .margin({ left: 4 })
        if (diag.source === 'rule' && diag.llmConfirmed !== 1) {
          Text(this.getLlmConfirmLabel(diag.llmConfirmed))
            .fontSize(10)
            .fontColor(this.getLlmConfirmColor(diag.llmConfirmed))
            .backgroundColor(this.getLlmConfirmColor(diag.llmConfirmed) + '20')
            .borderRadius(4)
            .padding({ left: 4, right: 4, top: 1, bottom: 1 })
            .margin({ left: 4 })
        }
        if (diag.source === 'user') {
          Text('×')
            .fontSize(14)
            .fontColor('#7A8074')
            .margin({ left: 4 })
            .onClick(() => {
              this.patientService.deleteUserDiagnosis(diag.id).then(() => {
                this.loadDashboard();
                this.diagnosisKbMap = this.diagnosisKbMap.filter((d: DiagnosisKbData): boolean => d.ruleId !== diag.ruleId);
              });
            })
        }
      }
      .width('100%')
      if (diag.missingCriteria.length > 0) {
        Column() {
          Text('缺：' + this.formatMissingCriteria(diag.missingCriteria))
            .fontSize(11)
            .fontColor('#C8881A')
            .width('100%')
        }
        .width('100%')
        .margin({ top: 4 })
        .padding(6)
        .backgroundColor('#FFF8E7')
        .borderRadius(4)
      }
      if (diag.llmNote.length > 0) {
        Text(diag.llmNote)
          .fontSize(12)
          .fontColor('#4A5247')
          .margin({ top: 4 })
          .width('100%')
      }
      Row() {
        Text(diag.category)
          .fontSize(10)
          .fontColor('#7A8074')
          .backgroundColor('#F5F4EF')
          .borderRadius(4)
          .padding({ left: 4, right: 4, top: 1, bottom: 1 })
        Text(this.formatDateTime(diag.triggeredAt))
          .fontSize(10)
          .fontColor('#7A8074')
          .margin({ left: 8 })
      }
      .margin({ top: 4 })
      .width('100%')

      this.DiagnosisKbSection(diag);
    }
    .width('100%')
    .padding(10)
    .backgroundColor(diag.source === 'rule' ? '#FFFFFF' : (diag.source === 'partial' ? '#FFFCF5' : (diag.source === 'llm_hint' ? '#F8F5FF' : '#F5FFF5')))
    .borderRadius(8)
    .border({ width: { left: 4, right: 0, top: 0, bottom: 0 }, color: this.getUrgencyColor(diag.urgency) })
    .margin({ bottom: 6 })
  }

  @Builder
  DiagnosisKbSection(diag: PatientDiagnosis) {
    if (this.getDiagnosisKb(diag.ruleId) !== null) {
      Column() {
        Row()
          .width('100%')
          .height(1)
          .backgroundColor('#E0DCC8')
          .margin({ top: 8, bottom: 8 });

        Row() {
          Text('指南参考')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F3D2F');
          if (this.getDiagnosisKb(diag.ruleId)!.searchResults.length > 0) {
            Text(this.expandedRefIds.has(diag.ruleId) ? ' ▲' : ' ▼')
              .fontSize(11)
              .fontColor('#7A8074')
              .margin({ left: 4 });
            Text(this.getDiagnosisKb(diag.ruleId)!.searchResults.length.toString() + '篇')
              .fontSize(10)
              .fontColor('#7A8074')
              .margin({ left: 4 });
          }
          Blank();
          if (!this.getDiagnosisKb(diag.ruleId)!.loadingKb) {
            Text('重搜')
              .fontSize(10)
              .fontColor('#9A6B1E')
              .backgroundColor('#FFF3E0')
              .borderRadius(3)
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .margin({ right: 8 })
              .onClick(() => {
                this.diagnosisKbMap = this.diagnosisKbMap.filter((d: DiagnosisKbData): boolean => d.ruleId !== diag.ruleId);
                this.expandedRefIds.delete(diag.ruleId);
                this.expandedRefIds = new Set(this.expandedRefIds);
                const prefsService = PreferencesService.getInstance();
                prefsService.saveDiagnosisKbData(this.currentPatientId, diag.ruleId, '');
                this.loadDiagnosisKb();
              });
          }
          if (this.getDiagnosisKb(diag.ruleId)!.searchResults.length > 0) {
            Text(this.expandedRefIds.has(diag.ruleId) ? '收起' : '展开')
              .fontSize(11)
              .fontColor('#2B6CB0');
          }
        }
        .width('100%')
        .onClick(() => {
          if (this.expandedRefIds.has(diag.ruleId)) {
            this.expandedRefIds.delete(diag.ruleId);
          } else {
            this.expandedRefIds.add(diag.ruleId);
          }
          this.expandedRefIds = new Set(this.expandedRefIds);
        });

        if (this.getDiagnosisKb(diag.ruleId)!.loadingKb) {
          Column() {
            ForEach(this.getDiagnosisKb(diag.ruleId)!.agentSteps, (step: AgentStep) => {
              Row() {
                if (step.status === 'done') {
                  Text('✓')
                    .fontSize(10)
                    .fontColor('#2D6A4F')
                    .margin({ right: 4 });
                } else {
                  LoadingProgress().width(10).height(10).color('#7A8074')
                    .margin({ right: 4 });
                }
                Text(step.agent)
                  .fontSize(10)
                  .fontWeight(step.status === 'running' ? FontWeight.Bold : FontWeight.Normal)
                  .fontColor(step.status === 'running' ? '#1F3D2F' : '#7A8074');
                if (step.output.length > 0) {
                  Text(step.output)
                    .fontSize(9)
                    .fontColor('#7A8074')
                    .margin({ left: 4 });
                }
              }
              .width('100%')
              .padding({ top: 2, bottom: 2 });
            }, (step: AgentStep, index: number) => step.agent + index.toString());
          }
          .margin({ top: 4, left: 4 })
          .width('100%');
        } else if (this.expandedRefIds.has(diag.ruleId) && this.getDiagnosisKb(diag.ruleId)!.searchResults.length > 0) {
          Column() {
            ForEach(this.getDiagnosisKb(diag.ruleId)!.searchResults, (sr: SearchResult) => {
              Column() {
                Row() {
                  Text(this.getKbSearchResultTitle(sr))
                    .fontSize(10)
                    .fontColor('#2B6CB0')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1);
                  if (this.getDiagnosisKb(diag.ruleId)!.partialPaths.indexOf(sr.path) >= 0) {
                    Text('片段')
                      .fontSize(8)
                      .fontColor('#9A6B1E')
                      .backgroundColor('#FFF3E0')
                      .borderRadius(2)
                      .padding({ left: 3, right: 3, top: 0, bottom: 0 })
                      .margin({ left: 4 });
                  }
                }
                .width('100%');
                Text(this.getKbGuidelineName(sr))
                  .fontSize(9)
                  .fontColor('#7A8074')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%');
              }
              .width('100%')
              .padding({ top: 4, bottom: 4 })
              .onClick(() => {
                this.kbReaderPath = sr.path;
                this.kbReaderTitle = this.getKbSearchResultTitle(sr);
                this.showKbReader = true;
              });
            }, (sr: SearchResult) => sr.path);
          }
          .margin({ top: 4 });
        }

        Row()
          .width('100%')
          .height(1)
          .backgroundColor('#E0DCC8')
          .margin({ top: 8, bottom: 8 });

        if (this.getDiagnosisKb(diag.ruleId)!.loadingKb) {
          Row() {
            LoadingProgress().width(14).height(14).color('#7A8074');
            Text('搜索指南中...')
              .fontSize(11)
              .fontColor('#7A8074')
              .margin({ left: 6 });
          }
          .margin({ top: 6 });
        } else if (this.getDiagnosisKb(diag.ruleId)!.loadingAdvice) {
          Column() {
            ForEach(this.getDiagnosisKb(diag.ruleId)!.agentSteps, (step: AgentStep) => {
              Row() {
                if (step.status === 'done') {
                  Text('✓')
                    .fontSize(10)
                    .fontColor('#2D6A4F')
                    .margin({ right: 4 });
                } else if (step.status === 'error') {
                  Text('✗')
                    .fontSize(10)
                    .fontColor('#C8881A')
                    .margin({ right: 4 });
                } else {
                  LoadingProgress().width(10).height(10).color('#7A8074')
                    .margin({ right: 4 });
                }
                Text(step.agent)
                  .fontSize(10)
                  .fontWeight(step.status === 'running' ? FontWeight.Bold : FontWeight.Normal)
                  .fontColor(step.status === 'running' ? '#1F3D2F' : '#7A8074');
                if (step.output.length > 0) {
                  Text(step.output)
                    .fontSize(9)
                    .fontColor('#7A8074')
                    .margin({ left: 4 });
                }
              }
              .width('100%')
              .padding({ top: 2, bottom: 2 });
            }, (step: AgentStep, index: number) => step.agent + index.toString());
          }
          .margin({ top: 4, left: 4 })
          .width('100%');
        } else if (this.getDiagnosisKb(diag.ruleId)!.recommendations.length > 0) {
          Row() {
            Text('指南建议 · ' + this.getRecommendationSummary(this.getDiagnosisKb(diag.ruleId)!.recommendations))
              .fontSize(12)
              .fontColor('#1F3D2F')
              .fontWeight(FontWeight.Medium);
            Blank();
            if (this.adviceReadyRuleId === diag.ruleId) {
              Text('已就绪')
                .fontSize(10)
                .fontColor('#2D6A4F')
                .backgroundColor('#E8F5E9')
                .borderRadius(3)
                .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                .margin({ right: 4 });
            }
            Text('查看 >')
              .fontSize(12)
              .fontColor('#2B6CB0');
          }
          .width('100%')
          .padding({ top: 6, bottom: 6 })
          .onClick(() => {
             this.activeAdviceRuleId = diag.ruleId;
             const kbData2 = this.getDiagnosisKb(diag.ruleId);
             this.summaryLines = kbData2 !== null && kbData2.summary.length > 0 ? parseKbMarkdown(kbData2.summary) : [];
             this.showRecommendationsDetail = true;
          });
        } else if (this.getDiagnosisKb(diag.ruleId)!.adviceError.length > 0) {
          Column() {
            Row() {
              Text(this.getDiagnosisKb(diag.ruleId)!.adviceError)
                .fontSize(10)
                .fontColor('#C8881A')
                .layoutWeight(1)
                .maxLines(3)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            Row() {
              if (this.getDiagnosisKb(diag.ruleId)!.summary.length > 0) {
                Text('详情 >')
                  .fontSize(10)
                  .fontColor('#2B6CB0')
                  .onClick(() => {
                    this.activeAdviceRuleId = diag.ruleId;
                    const kbD = this.getDiagnosisKb(diag.ruleId);
                    this.summaryLines = kbD !== null && kbD.summary.length > 0 ? parseKbMarkdown(kbD.summary) : [];
                    this.showRecommendationsDetail = true;
                  });
              }
              if (this.getDiagnosisKb(diag.ruleId)!.searchResults.length > 0) {
                Text('重试建议')
                  .fontSize(10)
                  .fontColor('#2B6CB0')
                  .margin({ left: 8 })
                  .onClick(() => {
                    const kbD2 = this.getDiagnosisKb(diag.ruleId);
                    if (kbD2 !== null) {
                      kbD2.loadingAdvice = true;
                      kbD2.adviceError = '';
                      kbD2.recommendations = [];
                      this.diagnosisKbMap = [...this.diagnosisKbMap];
                      this.loadDiagnosisAdvice(diag);
                    }
                  });
              }
              Blank();
              Text('重搜')
                .fontSize(10)
                .fontColor('#2B6CB0')
                .onClick(() => {
                  this.diagnosisKbMap = this.diagnosisKbMap.filter((d: DiagnosisKbData): boolean => d.ruleId !== diag.ruleId);
                  this.expandedRefIds.delete(diag.ruleId);
                  this.expandedRefIds = new Set(this.expandedRefIds);
                  const prefsService = PreferencesService.getInstance();
                  prefsService.saveDiagnosisKbData(this.currentPatientId, diag.ruleId, '');
                  this.loadDiagnosisKb();
                });
            }
            .width('100%')
            .margin({ top: 2 })
          }
          .width('100%')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('#FFF8E1')
          .borderRadius(4)
          .margin({ top: 4 });
        } else if (this.getDiagnosisKb(diag.ruleId)!.verifiedPaths.length > 0) {
          Row() {
            Text('查看指南建议')
              .fontSize(12)
              .fontColor('#2B6CB0');
            Blank();
            Text('>')
              .fontSize(12)
              .fontColor('#2B6CB0');
          }
          .width('100%')
          .padding({ top: 6, bottom: 6 })
          .onClick(() => { this.loadDiagnosisAdvice(diag); });
        } else {
          Text('暂无指南建议')
            .fontSize(11)
            .fontColor('#7A8074')
            .margin({ top: 4 });
        }
      }
      .width('100%');
    }
  }

  getEvidenceColor(level: string): string {
    if (level.indexOf('强') >= 0) {
      return '#2D6A4F';
    }
    if (level.indexOf('条件') >= 0) {
      return '#9A6B1E';
    }
    if (level.indexOf('GPS') >= 0 || level.indexOf('良好') >= 0) {
      return '#2B5C8A';
    }
    return '#7A8074';
  }

  getEvidenceBgColor(level: string): string {
    if (level.indexOf('强') >= 0) {
      return '#D8F3DC';
    }
    if (level.indexOf('条件') >= 0) {
      return '#FEF3C7';
    }
    if (level.indexOf('GPS') >= 0 || level.indexOf('良好') >= 0) {
      return '#DBEAFE';
    }
    return '#F0EDE2';
  }

  getDiagnosisNameByRuleId(ruleId: string): string {
    for (const diag of this.dashboard.diagnoses) {
      if (diag.ruleId === ruleId) {
        return diag.name;
      }
    }
    return '';
  }

  @Builder
  RecommendationsDetailPage() {
    Column() {
      Row() {
        Button('< 返回')
          .fontSize(14)
          .fontColor('#1F3D2F')
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.showRecommendationsDetail = false;
            this.activeAdviceRuleId = '';
          })
        Text(this.getDiagnosisNameByRuleId(this.activeAdviceRuleId) + ' · 指南建议')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F3D2F')
          .layoutWeight(1)
          .margin({ left: 8 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor('#FFFFFF');

      Scroll() {
        Column() {
          if (this.activeAdviceRuleId.length > 0 && this.getDiagnosisKb(this.activeAdviceRuleId) !== null) {
            if (this.getDiagnosisKb(this.activeAdviceRuleId)!.isLowRelevance) {
              Row() {
                Text('⚠️ 低相关性文献')
                  .fontSize(11)
                  .fontColor('#9A6B1E')
                  .fontWeight(FontWeight.Medium)
                Text('未找到高度相关文献，以下内容可能仅供参考')
                  .fontSize(10)
                  .fontColor('#9A9E94')
                  .margin({ left: 6 })
              }
              .width('100%')
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .backgroundColor('#FFF8E1')
              .borderRadius(6)
              .margin({ bottom: 8 });
            }
            if (this.getDiagnosisKb(this.activeAdviceRuleId)!.summary.length > 0) {
              Column() {
                Row() {
                  Text('临床要点')
                    .fontSize(14)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#1F3D2F');
                }
                .width('100%')
                .margin({ bottom: 4 });
                Text('以下内容由AI根据指南和教材推荐意见归纳整理，仅供参考，详细内容请展开下方各分类查看原文。')
                  .fontSize(10)
                  .fontColor('#9A9E94')
                  .width('100%')
                  .margin({ bottom: 6 });
                ForEach(this.summaryLines, (ml: MarkdownLine) => {
                  this.KbMarkdownLineView(ml);
                }, (ml: MarkdownLine, index: number) => index.toString());
              }
              .width('100%')
              .padding(10)
              .backgroundColor('#FFF9F0')
              .borderRadius(8)
              .border({ width: 1, color: '#E8DCC8' })
              .margin({ bottom: 8 });
            }
            this.RecommendationCategorySection(this.activeAdviceRuleId, '病理生理', '病理生理');
            this.RecommendationCategorySection(this.activeAdviceRuleId, '诊断要点', '诊断要点');
            this.RecommendationCategorySection(this.activeAdviceRuleId, '监测评估', '监测评估');
            this.RecommendationCategorySection(this.activeAdviceRuleId, '治疗建议', '治疗建议');
          }
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 16 })
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F4EF')
  }

  @Builder
  RecommendationCategorySection(ruleId: string, category: string, title: string) {
    if (this.getDiagnosisKb(ruleId) !== null) {
      if (this.getCategoryCount(this.getDiagnosisKb(ruleId)!.recommendations, category) > 0) {
        Column() {
          Row() {
            Row()
              .width(3)
              .height(14)
              .backgroundColor(this.getCategoryBorderColor(category))
              .borderRadius(2)
              .margin({ right: 6 });
            Text(title)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1F3D2F');
            Text(this.getCategoryCount(this.getDiagnosisKb(ruleId)!.recommendations, category).toString() + '条')
              .fontSize(11)
              .fontColor('#7A8074')
              .margin({ left: 6 });
            Blank();
            Text(this.expandedCategories.has(category) ? '▲ 收起' : '▼ 展开')
              .fontSize(11)
              .fontColor('#2B6CB0');
          }
          .width('100%')
          .margin({ top: 8, bottom: 4 })
          .onClick(() => {
            if (this.expandedCategories.has(category)) {
              this.expandedCategories.delete(category);
            } else {
              this.expandedCategories.add(category);
            }
            this.expandedCategories = new Set(this.expandedCategories);
          });

          if (this.expandedCategories.has(category)) {
            ForEach(this.getDiagnosisKb(ruleId)!.recommendations, (rec: GuidelineRecommendation) => {
              if (rec.category === category) {
                Column() {
                  Text(rec.text)
                    .fontSize(13)
                    .fontColor('#4A5247')
                    .width('100%');
                  Row() {
                    if (rec.type.length > 0) {
                      Text(rec.type)
                        .fontSize(9)
                        .fontColor(rec.type === '推荐意见' ? '#2D6A4F' : (rec.type === '知识要点' ? '#2B5C8A' : '#7A6B9D'))
                        .backgroundColor(rec.type === '推荐意见' ? '#E8F5E9' : (rec.type === '知识要点' ? '#E3F2FD' : '#F0EBF5'))
                        .borderRadius(3)
                        .padding({ left: 4, right: 4, top: 1, bottom: 1 });
                    }
                    if (rec.evidenceLevel.length > 0 && rec.evidenceLevel !== '未标注' && rec.evidenceLevel !== '-') {
                      Text(rec.evidenceLevel)
                        .fontSize(10)
                        .fontColor(this.getEvidenceColor(rec.evidenceLevel))
                        .backgroundColor(this.getEvidenceBgColor(rec.evidenceLevel))
                        .borderRadius(3)
                        .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                        .margin({ left: 4 });
                    }
                    Blank();
                    if (rec.source.length > 0) {
                      Text(rec.source)
                        .fontSize(9)
                        .fontColor('#9A9E94')
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .layoutWeight(1)
                        .textAlign(TextAlign.End);
                    }
                  }
                  .width('100%')
                  .margin({ top: 2 });
                }
                .width('100%')
                .alignItems(HorizontalAlign.Start)
                .padding({ top: 4, bottom: 4, left: 8 })
                .border({ width: { left: 2, right: 0, top: 0, bottom: 0 }, color: this.getCategoryBorderColor(category) })
                .margin({ bottom: 4 });
              }
            }, (rec: GuidelineRecommendation, index: number) => category + index.toString())
          }
        }
        .width('100%');
      }
    }
  }

  @Builder
  AlertCard(alert: PatientAlert) {
    Column() {
      Row() {
        Column()
          .width(4)
          .height(16)
          .backgroundColor(getTierColor(this.parseAlertResult(alert).tierClass))
          .borderRadius(2)
          .margin({ right: 8 })
        Text(alert.calcName)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F3D2F')
          .layoutWeight(1)
        Text(this.parseAlertResult(alert).tier)
          .fontSize(11)
          .fontColor(getTierColor(this.parseAlertResult(alert).tierClass))
          .maxLines(1)
          .margin({ right: 6 })
        Text(alert.completeness + '%')
          .fontSize(12)
          .fontColor('#7A8074')
        Text(this.isAlertExpanded(alert.id) ? ' ▲' : ' ▼')
          .fontSize(10)
          .fontColor('#7A8074')
          .margin({ left: 4 })
      }
      .width('100%')
      .onClick(() => { this.toggleAlert(alert.id); })

      if (this.isAlertExpanded(alert.id)) {
        this.AlertDetail(alert);
      }
    }
    .width('100%')
    .padding(10)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ bottom: 6 })
  }

  @Builder
  AlertDetail(alert: PatientAlert) {
    Column() {
      if (this.parseAlertResult(alert).value !== null) {
        Row() {
          Text(this.formatResultValue(this.parseAlertResult(alert).value))
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F3D2F')
          Text(this.parseAlertResult(alert).unit)
            .fontSize(12)
            .fontColor('#7A8074')
            .margin({ left: 4, top: 10 })
        }
        .margin({ top: 6, bottom: 4 })
      }
      Text(this.parseAlertResult(alert).tier)
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(getTierColor(this.parseAlertResult(alert).tierClass))
        .backgroundColor(getTierBgColor(this.parseAlertResult(alert).tierClass))
        .borderRadius(20)
        .padding({ left: 8, right: 8, top: 2, bottom: 2 })
        .margin({ bottom: 6 })
      if (this.parseAlertResult(alert).footnote.length > 0) {
        Text(this.parseAlertResult(alert).footnote)
          .fontSize(12)
          .fontColor('#4A5247')
          .lineHeight(18)
      }
      Text(this.formatDateTime(alert.triggeredAt))
        .fontSize(11)
        .fontColor('#7A8074')
        .margin({ top: 4 })
    }
    .width('100%')
    .padding({ top: 6 })
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  LabAlertCard(la: PatientLabAlert) {
    Column() {
      Row() {
        Column()
          .width(4)
          .height(16)
          .backgroundColor(this.getLabAlertUrgencyColor(la.urgency))
          .borderRadius(2)
          .margin({ right: 8 })
        Column() {
          Text(la.name)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F3D2F')
            .width('100%')
          Row() {
            Text(la.fieldLabel + ' ' + la.value + ' ' + la.unit)
              .fontSize(12)
              .fontColor('#4A5247')
              .layoutWeight(1)
            Text(la.threshold)
              .fontSize(11)
              .fontColor(this.getLabAlertUrgencyColor(la.urgency))
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .margin({ top: 2 })
          if (la.description.length > 0) {
            Text(la.description)
              .fontSize(11)
              .fontColor('#7A8074')
              .width('100%')
              .margin({ top: 2 })
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        Text(this.getLabAlertUrgencyLabel(la.urgency))
          .fontSize(10)
          .fontColor('#FFFFFF')
          .backgroundColor(this.getLabAlertUrgencyColor(la.urgency))
          .borderRadius(4)
          .padding({ left: 4, right: 4, top: 1, bottom: 1 })
          .margin({ left: 4 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
    .padding(10)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ bottom: 6 })
  }

  getLabAlertUrgencyColor(urgency: string): string {
    if (urgency === 'critical') {
      return '#B1452A';
    }
    if (urgency === 'warning') {
      return '#C8881A';
    }
    return '#3D6B4F';
  }

  getLabAlertUrgencyLabel(urgency: string): string {
    if (urgency === 'critical') {
      return '危急';
    }
    if (urgency === 'warning') {
      return '警示';
    }
    return '关注';
  }

  getDataFieldCount(): number {
    let count = 0;
    this.dashboard.latestData.forEach((val: string, key: string) => {
      if (this.isDisplayableDataKey(key)) {
        count++;
      }
    });
    return count;
  }

  getDataDomainCount(): number {
    return this.domainEntries.length;
  }

  getDataPreviewItems(): string[] {
    const items: string[] = [];
    const keys = Array.from(this.dashboard.latestData.keys());
    for (let i = 0; i < keys.length && items.length < 5; i++) {
      const key = keys[i];
      if (!this.isDisplayableDataKey(key)) {
        continue;
      }
      const val = this.dashboard.latestData.get(key);
      const unit = this.getFieldUnit(key);
      items.push(this.getFieldValueLabel(key) + ' ' + val + (unit.length > 0 ? ' ' + unit : ''));
    }
    return items;
  }

  @Builder
  DataPreviewCard() {
    Column() {
      Row() {
        Text('结构化数据')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F3D2F')
        if (this.getDataFieldCount() > 0) {
          Text(this.getDataFieldCount().toString())
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor('#3D6B4F')
            .borderRadius(10)
            .padding({ left: 6, right: 6, top: 1, bottom: 1 })
            .margin({ left: 6 })
        }
        Blank()
        Row() {
          ForEach(this.domainEntries.slice(0, 4), (entry: DomainEntry) => {
            Text(entry.name)
              .fontSize(10)
              .fontColor('#3D6B4F')
              .backgroundColor('#E8E5D8')
              .borderRadius(4)
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .margin({ left: 3 })
          }, (entry: DomainEntry) => entry.name)
        }
      }
      .width('100%')

      if (this.getDataFieldCount() > 0) {
        Column() {
          ForEach(this.getDataPreviewItems(), (item: string) => {
            Row() {
              Column()
                .width(3)
                .height(14)
                .backgroundColor('#3D6B4F')
                .borderRadius(1)
                .margin({ right: 6 })
              Text(item)
                .fontSize(13)
                .fontColor('#1F3D2F')
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .padding({ top: 3, bottom: 3 })
          }, (item: string, index: number) => index.toString())
          if (this.getDataFieldCount() > 5) {
            Text('还有' + (this.getDataFieldCount() - 5) + '项...')
              .fontSize(11)
              .fontColor('#7A8074')
              .margin({ top: 2 })
          }
        }
        .width('100%')
        .margin({ top: 8 })
      } else {
        Text('暂无数据，上传报告或手动录入')
          .fontSize(12)
          .fontColor('#7A8074')
          .margin({ top: 4 })
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .margin({ bottom: 8 })
    .onClick(() => { this.showDataDetail = true; })
  }

  @Builder
  DataDetailPage() {
    Column() {
      Row() {
        Button('< 返回')
          .fontSize(14)
          .fontColor('#1F3D2F')
          .backgroundColor(Color.Transparent)
          .onClick(() => { this.showDataDetail = false; })
        Text('结构化数据')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F3D2F')
          .layoutWeight(1)
          .margin({ left: 8 })
        Text(this.getDataFieldCount() + '项')
          .fontSize(13)
          .fontColor('#7A8074')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column() {
          if (this.getDataFieldCount() === 0) {
            Text('暂无数据，上传报告或手动录入')
              .fontSize(14)
              .fontColor('#7A8074')
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(40)
          } else {
            ForEach(this.domainEntries, (entry: DomainEntry) => {
               Column() {
                 Row() {
                   Column()
                     .width(4)
                     .height(16)
                     .backgroundColor(this.getDomainColor(entry.name))
                     .borderRadius(2)
                     .margin({ right: 8 })
                   Text(entry.name)
                     .fontSize(13)
                     .fontWeight(FontWeight.Bold)
                     .fontColor('#1F3D2F')
                     .layoutWeight(1)
                   Text(this.getDomainDataCount(entry.keys) + '项')
                     .fontSize(10)
                     .fontColor('#FFFFFF')
                     .backgroundColor(this.getDomainColor(entry.name))
                     .borderRadius(8)
                     .padding({ left: 5, right: 5, top: 1, bottom: 1 })
                     .margin({ right: 6 })
                   Text(this.isDomainExpanded(entry.name) ? ' ▲' : ' ▼')
                     .fontSize(10)
                     .fontColor('#7A8074')
                 }
                 .width('100%')
                 .onClick(() => { this.toggleDomain(entry.name); })

                if (this.isDomainExpanded(entry.name)) {
                  Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start, alignContent: FlexAlign.Start }) {
                    ForEach(entry.keys, (key: string) => {
                      if (this.dashboard.latestData.has(key) && this.isDisplayableDataKey(key)) {
                        Column() {
                          Text(this.getFieldValueLabel(key))
                            .fontSize(10)
                            .fontColor('#7A8074')
                            .maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                          Row() {
                            Text(this.dashboard.latestData.get(key))
                              .fontSize(14)
                              .fontColor('#1F3D2F')
                              .fontWeight(FontWeight.Bold)
                            if (this.getFieldUnit(key).length > 0) {
                              Text(this.getFieldUnit(key))
                                .fontSize(10)
                                .fontColor('#7A8074')
                                .margin({ left: 2 })
                            }
                          }
                          .margin({ top: 2 })
                        }
                        .width('48%')
                        .padding({ left: 8, right: 8, top: 6, bottom: 6 })
                        .backgroundColor('#F5F4EF')
                        .borderRadius(6)
                        .margin({ bottom: 4, right: '2%' })
                        .alignItems(HorizontalAlign.Start)
                        .onClick(() => {
                          this.timelineField = key;
                          this.patientService.getDataTimeline(this.currentPatientId, key).then((data: PatientDataPoint[]) => {
                            this.timelineData = data;
                            this.showTimelineDialog = true;
                          });
                        })
                      }
                    }, (key: string) => key)
                  }
                  .width('100%')
                  .padding({ top: 6 })
                }
              }
              .width('100%')
              .padding(10)
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
              .margin({ bottom: 6 })
            }, (entry: DomainEntry) => entry.name)
          }
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 16 })
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F4EF')
  }

  getRecordPreviewItems(): string[] {
    const items: string[] = [];
    for (let i = 0; i < this.dashboard.records.length && items.length < 3; i++) {
      const record = this.dashboard.records[i];
      items.push(this.getRecordIcon(record.type) + ' ' + this.getRecordLabel(record) + ' ' + this.formatTime(record.timestamp));
    }
    return items;
  }

  @Builder
  RecordsPreviewCard() {
    Column() {
      Row() {
        Text('上传记录')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F3D2F')
        if (this.dashboard.records.length > 0) {
          Text(this.dashboard.records.length.toString())
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor('#7A8074')
            .borderRadius(10)
            .padding({ left: 6, right: 6, top: 1, bottom: 1 })
            .margin({ left: 6 })
        }
        Blank()
        if (this.dashboard.records.length > 3) {
          Text('查看全部')
            .fontSize(12)
            .fontColor('#3D6B4F')
        }
      }
      .width('100%')

      if (this.dashboard.records.length > 0) {
        Column() {
          ForEach(this.getRecordPreviewItems(), (item: string) => {
            Row() {
              Column()
                .width(3)
                .height(14)
                .backgroundColor('#7A8074')
                .borderRadius(1)
                .margin({ right: 6 })
              Text(item)
                .fontSize(13)
                .fontColor('#1F3D2F')
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .padding({ top: 3, bottom: 3 })
          }, (item: string, index: number) => index.toString())
          if (this.dashboard.records.length > 3) {
            Text('还有' + (this.dashboard.records.length - 3) + '条...')
              .fontSize(11)
              .fontColor('#7A8074')
              .margin({ top: 2 })
          }
        }
        .width('100%')
        .margin({ top: 8 })
      } else {
        Text('暂无上传记录')
          .fontSize(12)
          .fontColor('#7A8074')
          .margin({ top: 4 })
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .margin({ bottom: 12 })
    .onClick(() => { this.showRecordsDetail = true; })
  }

  @Builder
  RecordsDetailPage() {
    Column() {
      Row() {
        Button('< 返回')
          .fontSize(14)
          .fontColor('#1F3D2F')
          .backgroundColor(Color.Transparent)
          .onClick(() => { this.showRecordsDetail = false; })
        Text('上传记录')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F3D2F')
          .layoutWeight(1)
          .margin({ left: 8 })
        Text(this.dashboard.records.length + '条')
          .fontSize(13)
          .fontColor('#7A8074')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column() {
          if (this.dashboard.records.length === 0) {
            Text('暂无上传记录')
              .fontSize(14)
              .fontColor('#7A8074')
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(40)
          } else {
            ForEach(this.dashboard.records, (record: PatientRecord) => {
              Column() {
                Row() {
                  Text(this.getRecordIcon(record.type))
                    .fontSize(14)
                    .margin({ right: 8 })
                  Text(this.getRecordLabel(record))
                    .fontSize(13)
                    .fontColor('#1F3D2F')
                    .layoutWeight(1)
                  Text('删除')
                    .fontSize(12)
                    .fontColor('#E76F2C')
                    .margin({ right: 8 })
                    .onClick(() => {
                      this.deleteRecordId = record.id;
                      this.showDeleteConfirm = true;
                    })
                  Text(this.formatTime(record.timestamp))
                    .fontSize(12)
                    .fontColor('#7A8074')
                    .margin({ right: 4 })
                  Text(this.expandedRecordIds.has(record.id) ? ' ▲' : ' ▼')
                    .fontSize(10)
                    .fontColor('#7A8074')
                }
                .width('100%')
                .onClick(() => {
                  if (this.expandedRecordIds.has(record.id)) {
                    this.expandedRecordIds.delete(record.id);
                  } else {
                    this.expandedRecordIds.add(record.id);
                  }
                  this.expandedRecordIds = new Set(this.expandedRecordIds);
                })
                if (this.expandedRecordIds.has(record.id) && record.extractedJson.length > 0) {
                  Text(record.extractedJson)
                    .fontSize(11)
                    .fontColor('#4A5247')
                    .width('100%')
                    .padding({ top: 6, bottom: 6 })
                    .lineHeight(16)
                }
              }
              .width('100%')
              .padding(10)
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
              .margin({ bottom: 4 })
            }, (record: PatientRecord) => record.id)
          }
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 16 })
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F4EF')
  }

  @Builder
  TimelineDialog() {
    Column() {
      Column() {
        Text(this.getFieldValueLabel(this.timelineField) + ' 时间线')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F3D2F')
          .margin({ bottom: 12 })

        if (this.timelineData.length === 0) {
          Text('无历史记录')
            .fontSize(13)
            .fontColor('#7A8074')
        } else {
          ForEach(this.timelineData, (dp: PatientDataPoint) => {
            Column() {
              Row() {
                Text(dp.value + ' ' + this.getFieldUnit(this.timelineField))
                  .fontSize(14)
                  .fontColor('#1F3D2F')
                  .fontWeight(FontWeight.Bold)
                  .layoutWeight(1)
              }
              .width('100%')
              Row() {
                Text('报告')
                  .fontSize(10)
                  .fontColor('#FFFFFF')
                  .backgroundColor(dp.examTime > 0 ? '#3D6B4F' : '#B1452A')
                  .borderRadius(3)
                  .padding({ left: 3, right: 3, top: 1, bottom: 1 })
                  .margin({ right: 4 })
                if (dp.examTime > 0) {
                  Text(this.formatDateTime(dp.examTime))
                    .fontSize(12)
                    .fontColor('#1F3D2F')
                    .layoutWeight(1)
                  Text('修改')
                    .fontSize(10)
                    .fontColor('#3D6B4F')
                    .margin({ left: 4 })
                    .onClick(() => {
                      this.openExamTimeEditor(dp);
                    })
                } else {
                  Text('未设置')
                    .fontSize(12)
                    .fontColor('#B1452A')
                    .layoutWeight(1)
                  Text('录入')
                    .fontSize(10)
                    .fontColor('#FFFFFF')
                    .backgroundColor('#3D6B4F')
                    .borderRadius(3)
                    .padding({ left: 3, right: 3, top: 1, bottom: 1 })
                    .margin({ left: 4 })
                    .onClick(() => {
                      this.openExamTimeEditor(dp);
                    })
                }
              }
              .width('100%')
              .margin({ top: 2 })
              Row() {
                Text('上传')
                  .fontSize(10)
                  .fontColor('#7A8074')
                  .margin({ right: 4 })
                Text(this.formatDateTime(dp.timestamp))
                  .fontSize(11)
                  .fontColor('#7A8074')
              }
              .width('100%')
              .margin({ top: 1 })
            }
            .width('100%')
            .padding({ top: 8, bottom: 8 })
            .borderRadius(6)
            .backgroundColor('#F9F8F3')
            .padding({ left: 8, right: 8, top: 8, bottom: 8 })
            .margin({ bottom: 6 })
          }, (dp: PatientDataPoint) => dp.id.toString())
        }

        Button('关闭')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#1F3D2F')
          .borderRadius(8)
          .height(36)
          .width('100%')
          .margin({ top: 12 })
          .onClick(() => { this.showTimelineDialog = false; })
      }
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .width('85%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0,0,0,0.4)')
    .justifyContent(FlexAlign.Center)
  }

  openExamTimeEditor(dp: PatientDataPoint) {
    this.editExamTimePointId = dp.id;
    if (dp.examTime > 0) {
      const d = new Date(dp.examTime);
      this.editExamYear = d.getFullYear();
      this.editExamMonth = d.getMonth() + 1;
      this.editExamDay = d.getDate();
      this.editExamHour = d.getHours();
      this.editExamMinute = d.getMinutes();
    } else {
      const d = new Date(dp.timestamp);
      this.editExamYear = d.getFullYear();
      this.editExamMonth = d.getMonth() + 1;
      this.editExamDay = d.getDate();
      this.editExamHour = d.getHours();
      this.editExamMinute = d.getMinutes();
    }
    this.showExamTimeEditor = true;
  }

  async saveExamTime() {
    const d = new Date(this.editExamYear, this.editExamMonth - 1, this.editExamDay, this.editExamHour, this.editExamMinute, 0, 0);
    const ts = d.getTime();
    await this.patientService.updateExamTime(this.editExamTimePointId, ts);
    this.showExamTimeEditor = false;
    this.patientService.getDataTimeline(this.currentPatientId, this.timelineField).then((data: PatientDataPoint[]) => {
      this.timelineData = data;
    });
  }

  @Builder
  ExamTimeEditorDialog() {
    Column() {
      Column() {
        Text('设置报告时间')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F3D2F')
          .margin({ bottom: 12 })

        DatePicker({
          selected: new Date(this.editExamYear, this.editExamMonth - 1, this.editExamDay)
        })
          .onChange((value: DatePickerResult) => {
            if (value.year !== undefined) this.editExamYear = value.year as number;
            if (value.month !== undefined) this.editExamMonth = (value.month as number) + 1;
            if (value.day !== undefined) this.editExamDay = value.day as number;
          })

        TimePicker({
          selected: new Date(2025, 0, 1, this.editExamHour, this.editExamMinute)
        })
          .onChange((value: TimePickerResult) => {
            if (value.hour !== undefined) this.editExamHour = value.hour as number;
            if (value.minute !== undefined) this.editExamMinute = value.minute as number;
          })
          .margin({ top: 8 })

        Row() {
          Button('取消')
            .fontSize(14)
            .fontColor('#7A8074')
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .height(36)
            .layoutWeight(1)
            .onClick(() => {
              this.showExamTimeEditor = false;
            })
          Button('保存')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#3D6B4F')
            .borderRadius(8)
            .height(36)
            .layoutWeight(1)
            .margin({ left: 8 })
            .onClick(() => {
              this.saveExamTime();
            })
        }
        .width('100%')
        .margin({ top: 12 })
      }
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .width('85%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0,0,0,0.4)')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  ManualInputDialog() {
    Column() {
      Column() {
        Text('手动录入')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F3D2F')
          .margin({ bottom: 12 })

        TextInput({ placeholder: '搜索字段名...' })
          .height(40)
          .fontSize(14)
          .margin({ bottom: 8 })
          .onChange((value: string) => { this.manualFilterKeyword = value; })

        List({ space: 4 }) {
          ForEach(this.dataFieldSpecs, (spec: DataFieldSpec) => {
            if (spec.type === 'number') {
              if (this.manualFilterKeyword.length === 0 || spec.label.indexOf(this.manualFilterKeyword) >= 0 || spec.key.indexOf(this.manualFilterKeyword) >= 0) {
                ListItem() {
                  Row() {
                    Text(spec.label)
                      .fontSize(13)
                      .fontColor('#1F3D2F')
                      .layoutWeight(1)
                    Text(spec.key)
                      .fontSize(11)
                      .fontColor('#7A8074')
                  }
                  .width('100%')
                  .padding(8)
                  .backgroundColor(this.manualFieldKey === spec.key ? '#E8E5D8' : '#F9F8F3')
                  .borderRadius(6)
                  .onClick(() => { this.manualFieldKey = spec.key; })
                }
              }
            }
          }, (spec: DataFieldSpec) => spec.key)
        }
        .height(200)
        .margin({ bottom: 8 })

        TextInput({ placeholder: '输入数值' })
          .height(40)
          .fontSize(14)
          .type(InputType.Number)
          .margin({ bottom: 12 })
          .onChange((value: string) => { this.manualFieldValue = value; })

        Row() {
          Button('取消')
            .fontSize(14)
            .fontColor('#7A8074')
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .height(36)
            .layoutWeight(1)
            .onClick(() => {
              this.showManualInput = false;
              this.manualFieldKey = '';
              this.manualFieldValue = '';
            })
          Button('录入')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#1F3D2F')
            .borderRadius(8)
            .height(36)
            .layoutWeight(1)
            .margin({ left: 8 })
            .onClick(async () => {
              if (this.manualFieldKey.length > 0 && this.manualFieldValue.length > 0) {
                const savedRec = await this.patientService.saveRecord(this.currentPatientId, 'manual', '', this.manualFieldKey + '=' + this.manualFieldValue, '', '手动录入: ' + this.getFieldValueLabel(this.manualFieldKey));
                await this.patientService.addManualData(this.currentPatientId, this.manualFieldKey, this.manualFieldValue, savedRec.id);
                this.showManualInput = false;
                this.manualFieldKey = '';
                this.manualFieldValue = '';
                this.loadDashboard();
              }
            })
        }
        .width('100%')
      }
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .width('85%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0,0,0,0.4)')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  DeleteConfirmDialog() {
    Column() {
      Column() {
        Text('确认删除')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F3D2F')
          .margin({ bottom: 8 })
        Text('删除此记录后，由它提供的数据将被一并删除，预警也将重新计算。')
          .fontSize(13)
          .fontColor('#4A5247')
          .lineHeight(20)
          .margin({ bottom: 16 })
        Row() {
          Button('取消')
            .fontSize(14)
            .fontColor('#7A8074')
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .height(36)
            .layoutWeight(1)
            .onClick(() => {
              this.showDeleteConfirm = false;
              this.deleteRecordId = '';
            })
          Button('删除')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#E76F2C')
            .borderRadius(8)
            .height(36)
            .layoutWeight(1)
            .margin({ left: 8 })
            .onClick(async () => {
              if (this.deleteRecordId.length > 0) {
                await this.patientService.deleteRecord(this.deleteRecordId);
                this.showDeleteConfirm = false;
                this.deleteRecordId = '';
                this.loadDashboard();
              }
            })
        }
        .width('100%')
      }
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .width('85%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0,0,0,0.4)')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  KbReaderOverlay() {
    Column() {
      Row() {
        Button('< 返回')
          .fontSize(14)
          .fontColor('#1F3D2F')
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.showKbReader = false;
            this.kbReaderPath = '';
          });
        Text(this.kbReaderTitle)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F3D2F')
          .layoutWeight(1)
          .margin({ left: 8 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis });
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor('#FFFFFF');

      Scroll() {
        Column() {
          Text(this.kbReaderTitle)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F3D2F')
            .width('100%');
          Text(this.kbReaderPath)
            .fontSize(11)
            .fontColor('#7A8074')
            .width('100%')
            .margin({ top: 4, bottom: 8 });
          this.KbReaderContent();
        }
        .padding(12);
      }
      .layoutWeight(1);
    }
    .width('95%')
    .height('85%')
    .backgroundColor('#FFFFFF')
    .borderRadius(12);
  }

  @State kbReaderLines: MarkdownLine[] = [];

  async loadKbReaderContent(path: string) {
    const page = await this.kbService.getPage(path);
    if (page !== null) {
      this.kbReaderTitle = page.title.length > 0 ? page.title : path.split('/').pop() || '';
      this.kbReaderLines = parseKbMarkdown(page.content);
    }
  }

  @Builder
  KbReaderContent() {
    ForEach(this.kbReaderLines, (ml: MarkdownLine) => {
      this.KbMarkdownLineView(ml);
    }, (ml: MarkdownLine, index: number) => index.toString());
  }

  @Builder
  KbMarkdownLineView(ml: MarkdownLine) {
    if (ml.type === 'h1') {
      Text(stripMarkdownInline(ml.text))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1F3D2F')
        .width('100%')
        .margin({ top: 12, bottom: 6 });
    } else if (ml.type === 'h2') {
      Text(stripMarkdownInline(ml.text))
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1F3D2F')
        .width('100%')
        .margin({ top: 8, bottom: 4 });
    } else if (ml.type === 'h3') {
      Text(stripMarkdownInline(ml.text))
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1F3D2F')
        .width('100%')
        .margin({ top: 6, bottom: 3 });
    } else if (ml.type === 'callout') {
      this.KbCalloutView(ml);
    } else if (ml.type === 'codeBlock') {
      this.KbCodeBlockView(ml);
    } else if (ml.type === 'annotation') {
      Row() {
        Text(getAnnotationBadgeInfo(ml.text).keyword)
          .fontSize(11)
          .fontColor('#FFFFFF')
          .backgroundColor(getAnnotationBadgeInfo(ml.text).color)
          .borderRadius(3)
          .padding({ left: 6, right: 6, top: 1, bottom: 1 });
        if (getAnnotationBadgeInfo(ml.text).detail.length > 0) {
          Text(getAnnotationBadgeInfo(ml.text).detail)
            .fontSize(11)
            .fontColor('#7A8074')
            .margin({ left: 6 });
        }
      }
      .margin({ top: 4, bottom: 4 });
    } else if (ml.type === 'kvQuote') {
      Row() {
        Row()
          .width(3)
          .height('100%')
          .backgroundColor('#4A7C6F')
          .borderRadius(2);
        Text(stripMarkdownInline(ml.text))
          .fontSize(12)
          .fontColor('#3A3F35')
          .layoutWeight(1)
          .padding({ left: 8, right: 8, top: 6, bottom: 6 });
      }
      .width('100%')
      .backgroundColor('#EDF5F0')
      .borderRadius({ topLeft: 0, bottomLeft: 0, topRight: 6, bottomRight: 6 })
      .margin({ top: 4, bottom: 4 });
    } else if (ml.type === 'li') {
      Row() {
        Text('\u2022')
          .fontSize(12)
          .fontColor('#7A8074')
          .margin({ right: 6 });
        Text(stripMarkdownInline(ml.text))
          .fontSize(12)
          .fontColor('#4A5247')
          .layoutWeight(1);
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
      .padding({ left: ml.indent * 12 + 8, top: 1, bottom: 1 });
    } else if (ml.type === 'quote') {
      Row() {
        Row()
          .width(3)
          .height(14)
          .backgroundColor('#C8881A')
          .borderRadius(2)
          .margin({ top: 4, bottom: 4 });
        Text(stripMarkdownInline(ml.text))
          .fontSize(11)
          .fontColor('#5A5F4E')
          .layoutWeight(1)
          .padding({ left: 8 });
      }
      .width('100%')
      .margin({ top: 2, bottom: 2 });
    } else if (ml.type === 'hr') {
      Row()
        .width('100%')
        .height(1)
        .backgroundColor('#E0DCC8')
        .margin({ top: 6, bottom: 6 });
    } else if (ml.type === 'blank') {
      Row().height(4);
    } else if (ml.type === 'tableSep') {
      Row();
    } else if (ml.type === 'tableHeader') {
      if (ml.cells.length > 0) {
        Row() {
          ForEach(ml.cells, (cell: string, idx: number) => {
            Text(cell)
              .fontSize(11)
              .fontColor('#1F3D2F')
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1)
              .padding({ left: 4, right: 4, top: 3, bottom: 3 });
          }, (cell: string, idx: number) => idx.toString());
        }
        .width('100%')
        .backgroundColor('#E8E6DA')
        .borderRadius(2);
      } else {
        Text(stripTableMarkdown(stripMarkdownInline(ml.text)))
          .fontSize(11)
          .fontColor('#1F3D2F')
          .fontWeight(FontWeight.Bold)
          .fontFamily('monospace')
          .width('100%')
          .padding({ left: 6, right: 6, top: 3, bottom: 3 })
          .backgroundColor('#E8E6DA')
          .borderRadius(2);
      }
    } else if (ml.type === 'table') {
      if (ml.cells.length > 0) {
        Row() {
          ForEach(ml.cells, (cell: string, idx: number) => {
            Text(cell)
              .fontSize(11)
              .fontColor('#4A5247')
              .layoutWeight(1)
              .padding({ left: 4, right: 4, top: 2, bottom: 2 });
          }, (cell: string, idx: number) => idx.toString());
        }
        .width('100%')
        .backgroundColor('#FAFAF5')
        .borderRadius(2);
      } else {
        Text(stripTableMarkdown(stripMarkdownInline(ml.text)))
          .fontSize(11)
          .fontColor('#4A5247')
          .fontFamily('monospace')
          .width('100%')
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .backgroundColor('#FAFAF5')
          .borderRadius(2);
      }
    } else if (ml.type === 'tagLine') {
      Row() {
        ForEach(ml.text.split(/\s+/).filter((t: string): boolean => t.startsWith('#') && t.length > 1), (tag: string) => {
          Text(tag.substring(1))
            .fontSize(11)
            .fontColor('#2B6CB0')
            .backgroundColor('#EBF2FA')
            .borderRadius(10)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .margin({ right: 4, bottom: 4 });
        }, (tag: string) => tag);
      }
      .width('100%')
      .margin({ top: 4, bottom: 4 });
    } else {
      Text(stripMarkdownInline(ml.text))
        .fontSize(12)
        .fontColor('#4A5247')
        .width('100%')
        .margin({ top: 1, bottom: 1 });
    }
  }

  @Builder
  KbCalloutView(ml: MarkdownLine) {
    Column() {
      if (ml.calloutTitle.length > 0) {
        Row() {
          Text(getCalloutStyle(ml.calloutType).icon)
            .fontSize(14)
            .margin({ right: 6 });
          Text(stripMarkdownInline(ml.calloutTitle))
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(getCalloutStyle(ml.calloutType).borderColor)
            .layoutWeight(1);
        }
        .width('100%')
        .padding({ left: 12, right: 10, top: 8, bottom: 4 });
      }
      if (ml.calloutBody.length > 0) {
        Text(stripMarkdownInline(ml.calloutBody))
          .fontSize(12)
          .fontColor('#4A5247')
          .width('100%')
          .padding({ left: 12, right: 10, top: ml.calloutTitle.length > 0 ? 0 : 8, bottom: 8 });
      }
    }
    .width('100%')
    .borderRadius(6)
    .border({ width: { left: 4, right: 0, top: 0, bottom: 0 }, color: getCalloutStyle(ml.calloutType).borderColor })
    .backgroundColor(getCalloutStyle(ml.calloutType).bgColor)
    .margin({ top: 6, bottom: 6 });
  }

  @Builder
  KbCodeBlockView(ml: MarkdownLine) {
    Scroll() {
      Text(ml.codeContent)
        .fontSize(11)
        .fontFamily('monospace')
        .fontColor('#3A3F35')
        .width('100%');
    }
    .scrollable(ScrollDirection.Horizontal)
    .width('100%')
    .padding(10)
    .backgroundColor('#F5F5F0')
    .borderRadius(6)
    .margin({ top: 6, bottom: 6 });
  }

  @Builder
  AddDiagnosisDialog() {
    Column() {
      Column() {
        Text('添加诊断')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F3D2F')
          .margin({ bottom: 16 })

        TextInput({ placeholder: '诊断名称', text: this.addDiagName })
          .fontSize(14)
          .width('100%')
          .onChange((value: string) => {
            this.addDiagName = value;
          })

        Text('分类')
          .fontSize(13)
          .fontColor('#4A5247')
          .margin({ top: 12, bottom: 6 })

        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start }) {
          ForEach(DIAGNOSIS_CATEGORIES, (cat: string) => {
            Text(cat)
              .fontSize(12)
              .fontColor(this.addDiagCategory === cat ? '#FFFFFF' : '#1F3D2F')
              .backgroundColor(this.addDiagCategory === cat ? '#1F3D2F' : '#E8E5D8')
              .borderRadius(4)
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .margin({ right: 4, bottom: 4 })
              .onClick(() => {
                this.addDiagCategory = cat;
              })
          }, (cat: string) => cat)
        }

        Row() {
          Text('取消')
            .fontSize(14)
            .fontColor('#7A8074')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .padding(10)
            .onClick(() => {
              this.showAddDiagnosis = false;
            })
          Text('添加')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .backgroundColor('#1F3D2F')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .padding(10)
            .borderRadius(6)
            .onClick(() => {
              if (this.addDiagName.trim().length > 0) {
                this.patientService.addUserDiagnosis(
                  this.currentPatientId, this.addDiagName.trim(), this.addDiagCategory
                ).then(() => {
                  this.showAddDiagnosis = false;
                  this.loadDashboard();
                });
              }
            })
        }
        .width('100%')
        .margin({ top: 20 })
      }
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .width('85%')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('rgba(0,0,0,0.4)')
    .onClick(() => {
      this.showAddDiagnosis = false;
    })
  }
}
