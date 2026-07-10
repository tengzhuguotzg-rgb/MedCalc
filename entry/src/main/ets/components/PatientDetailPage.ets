import { Patient, PatientDataPoint, PatientRecord, PatientAlert, PatientDiagnosis, PatientDashboard, DATA_DOMAINS, DOMAIN_COLORS } from '../model/Patient';
import { PatientService } from '../services/PatientService';
import { AssistantService, DataFieldSpec, CalcMatch } from '../services/AssistantService';
import { CalcResult, getTierColor, getTierBgColor } from '../engine/CalcEngine';
import { PreferencesService } from '../services/PreferencesService';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { sendVisionRequest, ApiServiceConfig } from '../services/LlmService';
import { ImageStore } from '../services/ImageStore';
import { KnowledgeService, SearchResult, KnowledgePage } from '../services/KnowledgeService';
import {
  MarkdownLine, CalloutStyle, AnnotationBadge,
  parseKbMarkdown, stripMarkdownInline, stripTableMarkdown, getCalloutStyle, getAnnotationBadgeInfo, parseTableCells
} from '../utils/KbMarkdownParser';
import { DIAGNOSIS_RULES, DIAGNOSIS_CATEGORIES } from '../model/DiagnosisRules';
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
}

class GuidelineRecommendation {
  text: string = '';
  evidenceLevel: string = '';
  source: string = '';
  category: string = '';
  type: string = '';
}

class DiagnosisKbData {
  ruleId: string = '';
  searchResults: SearchResult[] = [];
  verifiedPaths: string[] = [];
  partialPaths: string[] = [];
  recommendations: GuidelineRecommendation[] = [];
  loadingKb: boolean = false;
  loadingAdvice: boolean = false;
  summary: string = '';
  verifyInfo: string = '';
  isLowRelevance: boolean = false;

  toJson(): string {
    const srList: Record<string, string>[] = [];
    for (const sr of this.searchResults) {
      srList.push({ 'path': sr.path, 'title': sr.title });
    }
    const recList: Record<string, string>[] = [];
    for (const rec of this.recommendations) {
      recList.push({ 'text': rec.text, 'evidenceLevel': rec.evidenceLevel, 'source': rec.source, 'category': rec.category, 'type': rec.type });
    }
    const obj: Record<string, Object> = {
      'ruleId': this.ruleId,
      'searchResults': srList,
      'verifiedPaths': this.verifiedPaths,
      'partialPaths': this.partialPaths,
      'recommendations': recList,
      'summary': this.summary,
      'verifyInfo': this.verifyInfo,
      'isLowRelevance': this.isLowRelevance,
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
        if (this.dashboard.latestData.has(keys[j])) {
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

  getFieldValueLabel(key: string): string {
    for (let i = 0; i < this.dataFieldSpecs.length; i++) {
      if (this.dataFieldSpecs[i].key === key) {
        return this.dataFieldSpecs[i].label;
      }
    }
    return key;
  }

  getFieldUnit(key: string): string {
    for (let i = 0; i < this.dataFieldSpecs.length; i++) {
      if (this.dataFieldSpecs[i].key === key) {
        return this.dataFieldSpecs[i].unit;
      }
    }
    return '';
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
      if (this.dashboard.latestData.has(domainKeys[i])) {
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

  getTierIcon(tierClass: string): string {
    if (tierClass === 'tier-danger') {
      return '🔴';
    }
    if (tierClass === 'tier-warn') {
      return '🟡';
    }
    return '🟢';
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
        if (this.getWarningAlerts().length > 0) {
          Text(this.getWarningAlerts().length.toString())
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor('#B1452A')
            .borderRadius(10)
            .padding({ left: 6, right: 6, top: 1, bottom: 1 })
            .margin({ left: 6 })
        }
        Blank()
        Row() {
          if (this.getDangerCount() > 0) {
            Row() {
              Text(this.getDangerCount().toString())
                .fontSize(12)
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Bold)
            }
            .backgroundColor('#B1452A')
            .borderRadius(8)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          }
          if (this.getWarnCount() > 0) {
            Row() {
              Text(this.getWarnCount().toString())
                .fontSize(12)
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Bold)
            }
            .backgroundColor('#C8881A')
            .borderRadius(8)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .margin({ left: 4 })
          }
        }
      }
      .width('100%')

      if (this.getWarningAlerts().length > 0) {
        Column() {
          ForEach(this.getWarningAlerts().slice(0, 3), (alert: PatientAlert) => {
            Row() {
              Text(this.getTierIcon(this.parseAlertResult(alert).tierClass))
                .fontSize(12)
                .margin({ right: 4 })
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
            Text('还有' + (this.getWarningAlerts().length - 3) + '项...')
              .fontSize(11)
              .fontColor('#7A8074')
              .margin({ top: 2 })
          }
        }
        .width('100%')
        .margin({ top: 8 })
      } else {
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
                .backgroundColor(this.getSourceColor(diag.source))
                .borderRadius(1)
                .margin({ right: 6 })
              Text(diag.name)
                .fontSize(13)
                .fontColor('#1F3D2F')
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(this.getSourceLabel(diag.source))
                .fontSize(9)
                .fontColor(this.getSourceColor(diag.source))
                .margin({ left: 4 })
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
        Row() {
          if (this.getDangerCount() > 0) {
            Row() {
              Text(this.getDangerCount().toString())
                .fontSize(12)
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Bold)
            }
            .backgroundColor('#B1452A')
            .borderRadius(8)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          }
          if (this.getWarnCount() > 0) {
            Row() {
              Text(this.getWarnCount().toString())
                .fontSize(12)
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Bold)
            }
            .backgroundColor('#C8881A')
            .borderRadius(8)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .margin({ left: 4 })
          }
        }
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column() {
          if (this.getWarningAlerts().length === 0) {
            Text('当前无异常预警')
              .fontSize(14)
              .fontColor('#7A8074')
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(40)
          } else {
            ForEach(this.getWarningAlerts(), (alert: PatientAlert) => {
              this.AlertCard(alert);
            }, (alert: PatientAlert) => alert.id.toString())
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
          ForEach(this.getDiagnosisCategoryTags(), (tag: string) => {
            Text(tag)
              .fontSize(10)
              .fontColor('#1F3D2F')
              .backgroundColor('#E8E5D8')
              .borderRadius(4)
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .margin({ left: 3 })
          }, (tag: string) => tag)
          Text('+')
            .fontSize(14)
            .fontColor('#2B6CB0')
            .margin({ left: 6 })
            .onClick(() => {
              this.addDiagName = '';
              this.addDiagCategory = '代谢';
              this.showAddDiagnosis = true;
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
            ForEach(this.dashboard.diagnoses, (diag: PatientDiagnosis) => {
              this.DiagnosisCard(diag);
            }, (diag: PatientDiagnosis) => diag.id.toString())
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
    if (source === 'suggestion') {
      return '提示';
    }
    if (source === 'user') {
      return '自添加';
    }
    return '确定性';
  }

  getSourceColor(source: string): string {
    if (source === 'suggestion') {
      return '#C8881A';
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
      try {
        const smartResults = await this.kbService.smartSearch(query, 10);
        kbData.searchResults = smartResults;
        const partialPathSet = new Set<string>();
        for (const pp of this.kbService.lastPartialPaths) {
          partialPathSet.add(pp);
        }
        kbData.partialPaths = this.kbService.lastPartialPaths;
        const fullPaths: string[] = [];
        for (const sr of smartResults) {
          if (!partialPathSet.has(sr.path)) {
            fullPaths.push(sr.path);
          }
        }
        kbData.verifiedPaths = fullPaths;
        const totalExpanded = this.kbService.lastExpandedCount;
        const yCount = fullPaths.length;
        const pCount = kbData.partialPaths.length;
        kbData.verifyInfo = '广搜:' + totalExpanded.toString() + '→全文:' + yCount.toString() + '+片段:' + pCount.toString();
      } catch (_e) {
        kbData.searchResults = [];
        kbData.verifiedPaths = [];
        kbData.partialPaths = [];
        kbData.verifyInfo = '搜索异常';
      }
      kbData.loadingKb = false;
      this.diagnosisKbMap = [...this.diagnosisKbMap];
      this.saveKbData(kbData);
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
    const kbData = this.getDiagnosisKb(diag.ruleId);
    if (kbData === null) {
      return;
    }
    if (kbData.recommendations.length > 0) {
      this.activeAdviceRuleId = diag.ruleId;
      this.summaryLines = kbData.summary.length > 0 ? parseKbMarkdown(kbData.summary) : [];
      this.showRecommendationsDetail = true;
      return;
    }
    kbData.loadingAdvice = true;
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

    let contextText = '';
    let guidelineChars = 0;
    for (const path of guidelinePaths) {
      const page = await this.kbService.getPage(path);
      if (page !== null && page.content.trim().length >= 100) {
        contextText += '### [指南] ' + path + '\n---\n' + page.content + '\n\n';
        guidelineChars += page.content.length;
      }
    }
    const remainingBudget = Math.max(0, 87000 - guidelineChars);
    const textbookCount = textbookPaths.length;
    let perChapterBudget = 20000;
    if (textbookCount > 0) {
      perChapterBudget = Math.min(20000, Math.floor(remainingBudget / textbookCount));
    }
    const queryKeywords: string[] = diag.name.split(/\s+/);
    for (const path of textbookPaths) {
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
    const partialBudget = Math.max(0, remainingBudget - textbookCount * perChapterBudget);
    for (const path of kbData.partialPaths) {
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
      kbData.loadingAdvice = false;
      kbData.recommendations = [];
      this.diagnosisKbMap = [...this.diagnosisKbMap];
      return;
    }

    const config = this.getLlmConfig();
    if (config === null) {
      kbData.loadingAdvice = false;
      this.diagnosisKbMap = [...this.diagnosisKbMap];
      return;
    }

    const rule = DIAGNOSIS_RULES.find((r): boolean => r.id === diag.ruleId);
    const patientContext = this.buildPatientContextStr();
    const isLowRel = kbData.verifiedPaths.length === 0 && kbData.partialPaths.length === 0 && kbData.searchResults.length > 0;
    kbData.isLowRelevance = isLowRel;

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
      '第一部分：JSON，只包含recommendations数组，不要在JSON中放summary。格式如下：\n' +
      '```json\n{"recommendations":[{"text":"内容","evidenceLevel":"级别或-","source":"来源标注","category":"病理生理|诊断要点|监测评估|治疗建议","type":"推荐意见|知识要点|混合"}]}\n```\n' +
      '第二部分：临床要点归纳（纯markdown，不在JSON内）。以"## 临床要点"开头，按"病理生理""诊断要点""监测评估""治疗建议"四方面分节归纳，用分点列表呈现，整合相关条目为逻辑清晰的要点，保留关键数值和药物信息，用**加粗**标记关键词。不是精简而是重组，不要遗漏已有条目。某类别无内容则不输出该节。' +
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

    try {
      const response = await sendVisionRequest(config, systemPrompt, userText, '', '');
      const parsed = this.parseRecommendationsAndSummary(response);
      kbData.recommendations = parsed.recommendations;
      kbData.summary = parsed.summary;
      if (this.activeAdviceRuleId === diag.ruleId) {
        this.summaryLines = kbData.summary.length > 0 ? parseKbMarkdown(kbData.summary) : [];
      }
    } catch (_e) {
      kbData.recommendations = [];
      kbData.summary = 'AI暂不可用，请稍后重试';
    }
    kbData.loadingAdvice = false;
    this.diagnosisKbMap = [...this.diagnosisKbMap];
    this.activeAdviceRuleId = diag.ruleId;
    this.summaryLines = kbData.summary.length > 0 ? parseKbMarkdown(kbData.summary) : [];
    this.saveKbData(kbData);
    if (kbData.recommendations.length > 0) {
      this.adviceReadyRuleId = diag.ruleId;
      setTimeout(() => {
        if (this.adviceReadyRuleId === diag.ruleId) {
          this.adviceReadyRuleId = '';
        }
      }, 3000);
    }
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
  DiagnosisCard(diag: PatientDiagnosis) {
    Column() {
      Row() {
        Text(diag.name)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F3D2F')
          .layoutWeight(1)
        Text(this.getSourceLabel(diag.source))
          .fontSize(10)
          .fontColor(this.getSourceColor(diag.source))
          .backgroundColor(this.getSourceColor(diag.source) + '20')
          .borderRadius(4)
          .padding({ left: 4, right: 4, top: 1, bottom: 1 })
          .margin({ left: 4 })
        Text(this.getUrgencyLabel(diag.urgency))
          .fontSize(10)
          .fontColor(this.getUrgencyColor(diag.urgency))
          .backgroundColor(this.getUrgencyColor(diag.urgency) + '20')
          .borderRadius(4)
          .padding({ left: 4, right: 4, top: 1, bottom: 1 })
          .margin({ left: 4 })
        if (diag.source === 'rule') {
          Text(this.getLlmConfirmLabel(diag.llmConfirmed))
            .fontSize(10)
            .fontColor(this.getLlmConfirmColor(diag.llmConfirmed))
            .backgroundColor(this.getLlmConfirmColor(diag.llmConfirmed) + '20')
            .borderRadius(4)
            .padding({ left: 4, right: 4, top: 1, bottom: 1 })
            .margin({ left: 4 })
        }
        if (diag.source !== 'rule') {
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
          Text('缺：' + diag.missingCriteria)
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
    .backgroundColor(diag.source === 'rule' ? '#FFFFFF' : (diag.source === 'suggestion' ? '#FFFCF5' : '#F5FFF5'))
    .borderRadius(8)
    .border({ width: { left: 4, right: 0, top: 0, bottom: 0 }, color: this.getSourceColor(diag.source) })
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
            if (this.getDiagnosisKb(diag.ruleId)!.verifyInfo.length > 0) {
              Text(this.getDiagnosisKb(diag.ruleId)!.verifyInfo)
                .fontSize(9)
                .fontColor('#999999')
                .margin({ left: 4 });
            }
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
          Row() {
            LoadingProgress().width(16).height(16).color('#7A8074');
            Text('检索指南中...')
              .fontSize(11)
              .fontColor('#7A8074')
              .margin({ left: 6 });
          }
          .margin({ top: 4 });
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
          Row() {
            LoadingProgress().width(14).height(14).color('#7A8074');
            Text('提取指南建议中...')
              .fontSize(11)
              .fontColor('#7A8074')
              .margin({ left: 6 });
          }
          .margin({ top: 6 });
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
        Text(this.getTierIcon(this.parseAlertResult(alert).tierClass))
          .fontSize(14)
          .margin({ right: 6 })
        Text(alert.calcName)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F3D2F')
          .layoutWeight(1)
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

  getDataFieldCount(): number {
    return this.dashboard.latestData.size;
  }

  getDataDomainCount(): number {
    return this.domainEntries.length;
  }

  getDataPreviewItems(): string[] {
    const items: string[] = [];
    const keys = Array.from(this.dashboard.latestData.keys());
    for (let i = 0; i < keys.length && items.length < 5; i++) {
      const key = keys[i];
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
                      if (this.dashboard.latestData.has(key)) {
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
