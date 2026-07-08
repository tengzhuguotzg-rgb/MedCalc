import { Patient, PatientDataPoint, PatientRecord, PatientAlert, PatientDiagnosis, PatientDashboard, DATA_DOMAINS, DOMAIN_COLORS } from '../model/Patient';
import { PatientService } from '../services/PatientService';
import { AssistantService, DataFieldSpec, CalcMatch } from '../services/AssistantService';
import { CalcResult, getTierColor, getTierBgColor } from '../engine/CalcEngine';
import { PreferencesService } from '../services/PreferencesService';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { sendVisionRequest, ApiServiceConfig } from '../services/LlmService';
import { ImageStore } from '../services/ImageStore';
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

  private patientService: PatientService = PatientService.getInstance();
  private assistantService: AssistantService = AssistantService.getInstance();
  private dataFieldSpecs: DataFieldSpec[] = [];
  private lastBackFlag: number = 0;

  aboutToAppear() {
    this.dataFieldSpecs = this.assistantService.getDataFieldSpecs();
    this.loadDashboard();
    this.syncNavDepth();
  }

  onDetailNavChanged() {
    this.syncNavDepth();
  }

  syncNavDepth() {
    let depth = 0;
    if (this.currentPatientId.length > 0) {
      depth = 1;
    }
    if (this.showAlertDetail || this.showDiagnosisDetail || this.showDataDetail || this.showRecordsDetail) {
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
    if (this.showAlertDetail) {
      this.showAlertDetail = false;
      return true;
    }
    if (this.showDiagnosisDetail) {
      this.showDiagnosisDetail = false;
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

  @Builder
  DiagnosisCard(diag: PatientDiagnosis) {
    Column() {
      Row() {
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
          .margin({ left: 6 })
        Text(this.getLlmConfirmLabel(diag.llmConfirmed))
          .fontSize(10)
          .fontColor(this.getLlmConfirmColor(diag.llmConfirmed))
          .backgroundColor(this.getLlmConfirmColor(diag.llmConfirmed) + '20')
          .borderRadius(4)
          .padding({ left: 4, right: 4, top: 1, bottom: 1 })
          .margin({ left: 4 })
      }
      .width('100%')
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
    }
    .width('100%')
    .padding(10)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .border({ width: { left: 4, right: 0, top: 0, bottom: 0 }, color: this.getUrgencyColor(diag.urgency) })
    .margin({ bottom: 6 })
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
}
