import { Patient, PatientDataPoint, PatientRecord, PatientDiagnosis, PatientDashboard } from '../model/Patient';
import { PatientService } from '../services/PatientService';
import { AssistantService, DataFieldSpec } from '../services/AssistantService';
import { PreferencesService } from '../services/PreferencesService';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { sendVisionRequest, ApiServiceConfig } from '../services/LlmService';
import { ImageStore } from '../services/ImageStore';
import { KnowledgeService, SearchResult, KnowledgePage, ExpandedQueryResult, SmartSearchResult } from '../services/KnowledgeService';
import {
  MarkdownLine,
  parseKbMarkdown
} from '../utils/KbMarkdownParser';
import { DIAGNOSIS_RULES, DiagnosisRule } from '../model/DiagnosisRules';

import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo, picker } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { image } from '@kit.ImageKit';
import { pdfService } from '@kit.PDFKit';
import { ImageEditor } from './ImageEditor';
import { AppColors } from '../utils/AppColors';
import { AppDimens } from '../utils/AppDimens';
import { DomainEntry, GuidelineRecommendation, PathScore, AgentStep, AuditIssue, GapSignal, AuditAgentResult, DiagnosisKbData } from './patient/PatientDetailTypes';
import { KbReaderOverlay } from './patient/KbReaderOverlay';
import { criterionOpSymbol, parseAlertResult, parseRecommendations, parseRecommendationsAndSummary, formatCriterion, formatMissingCriteria, getDomainColor, getDomainDataCount, domainHasData, buildDomainEntries, getDiagnosesBySource, getDiagnosisKb } from './patient/PatientDetailUtils';
import { AlertPreviewCard, DiagnosisPreviewCard as DiagnosisPreviewCardView, DataPreviewCard, RecordsPreviewCard } from './patient/DashboardPreviewCards';
import { getDataFieldCount, getDataPreviewItems, getRecordPreviewItems, getDiagnosisCategoryTags, findFieldSpec, getFieldValueLabel, getFieldUnit, isDerivedFlagField, isDisplayableDataKey } from './patient/PatientDetailUtils';
import { AlertDetailPageView, DiagnosisDetailPageView, RecommendationsDetailPageView, DataDetailPageView, RecordsDetailPageView } from './patient/DetailPageViews';
import { TimelineDialog, ExamTimeEditorDialog, ManualInputDialog, DeleteConfirmDialog, AddDiagnosisDialog } from './patient/PatientDetailDialogs';

@Component
export struct PatientDetailPage {
  patientStack: NavPathStack = new NavPathStack();
  @Prop currentPatientId: string = '';
  @Watch('onBackFlagChanged') @Prop backFlag: number = 0;
  private lastBackFlag: number = 0;
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
  @State showAlertDetail: boolean = false;
  @State showDiagnosisDetail: boolean = false;
  @State showDataDetail: boolean = false;
  @State showRecordsDetail: boolean = false;
  @State deleteRecordId: string = '';
  @State showDeleteConfirm: boolean = false;
  @State uploading: boolean = false;
  @State uploadMsg: string = '';
  @State @Watch('onImageEditorClosed') showImageEditor: boolean = false;
  @State editorImageUri: string = '';
  @State editorResultBase64: string = '';
  @State editorResultMime: string = '';
  @State diagnosisKbMap: DiagnosisKbData[] = [];
  @Provide showKbReader: boolean = false;
  @Provide @Watch('onKbReaderPathChanged') kbReaderPath: string = '';
  @Provide kbReaderTitle: string = '';
  @Provide kbReaderLines: MarkdownLine[] = [];
  @State expandedCategories: Set<string> = new Set();
  @State expandedRefIds: Set<string> = new Set();
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

  aboutToAppear() {
    const paramArr: string[] = this.patientStack.getParamByName('PatientDetail') as string[];
    if (paramArr !== null && paramArr !== undefined && paramArr.length > 0) {
      const paramId = paramArr[0];
      if (paramId !== undefined && paramId !== null && paramId.length > 0) {
        this.currentPatientId = paramId;
      }
    }
    this.dataFieldSpecs = this.assistantService.getDataFieldSpecs();
    this.loadDashboard();
  }

  onBackFlagChanged() {
    if (this.backFlag !== this.lastBackFlag) {
      this.lastBackFlag = this.backFlag;
      if (!this.navigateBack()) {
        this.patientStack.pop();
      }
    }
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

  onKbReaderPathChanged() {
    if (this.showKbReader && this.kbReaderPath.length > 0) {
      this.loadKbReaderContent(this.kbReaderPath);
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
    return false;
  }

  async loadDashboard() {
    if (this.currentPatientId.length === 0) {
      return;
    }
    this.loading = true;
    this.dashboard = await this.patientService.getDashboard(this.currentPatientId);
    this.domainEntries = buildDomainEntries(this.dashboard, this.dataFieldSpecs);
    this.loading = false;
    this.loadSavedKbData();
    if (this.dashboard.diagnoses.length > 0) {
      this.loadDiagnosisKb();
      this.patientService.reconfirmPendingDiagnoses(this.currentPatientId);
    }
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
      this.uploadMsg = '上传失败，请重试';
      hilog.error(0xF000, 'PatientDetail', 'processUpload failed: ' + errMsg);
    }
  }

   build() {
      Stack() {
      if (!this.showImageEditor) {
      Column() {
         if (this.showAlertDetail) {
           AlertDetailPageView({
             dashboard: this.dashboard,
             expandedAlertIds: $expandedAlertIds,
             onBack: () => { this.showAlertDetail = false; }
           });
          } else if (this.showRecommendationsDetail) {
            RecommendationsDetailPageView({
              dashboard: this.dashboard,
              activeAdviceRuleId: $activeAdviceRuleId,
              summaryLines: this.summaryLines,
              expandedCategories: $expandedCategories,
              diagnosisKbMap: this.diagnosisKbMap,
              onBack: () => {
                this.showRecommendationsDetail = false;
                this.activeAdviceRuleId = '';
              }
            });
          } else if (this.showDiagnosisDetail) {
            DiagnosisDetailPageView({
              dashboard: this.dashboard,
              currentPatientId: this.currentPatientId,
              loading: this.loading,
              dataFieldSpecs: this.dataFieldSpecs,
             addDiagName: $addDiagName,
             addDiagCategory: $addDiagCategory,
             showAddDiagnosis: $showAddDiagnosis,
             diagnosisKbMap: $diagnosisKbMap,
             expandedRefIds: $expandedRefIds,
             adviceReadyRuleId: this.adviceReadyRuleId,
             activeAdviceRuleId: $activeAdviceRuleId,
             summaryLines: $summaryLines,
             showRecommendationsDetail: $showRecommendationsDetail,
             onBack: () => { this.showDiagnosisDetail = false; },
             onReDiagnose: async () => {
               this.loading = true;
               await this.patientService.fullReDiagnose(this.currentPatientId);
               this.loading = false;
               this.loadDashboard();
             },
             onToggleAddDiagnosis: () => {
               this.addDiagName = '';
               this.addDiagCategory = '代谢';
               this.showAddDiagnosis = true;
             },
             onLoadDiagnosisKb: () => { this.loadDiagnosisKb(); },
             onLoadDiagnosisAdvice: (d: PatientDiagnosis) => { this.loadDiagnosisAdvice(d); },
             onDeleteUserDiagnosis: (diag: PatientDiagnosis) => {
               this.patientService.deleteUserDiagnosis(diag.id).then(() => {
                 this.loadDashboard();
                 this.diagnosisKbMap = this.diagnosisKbMap.filter((d: DiagnosisKbData): boolean => d.ruleId !== diag.ruleId);
               });
             }
           });
         } else if (this.showDataDetail) {
           DataDetailPageView({
             dashboard: this.dashboard,
             domainEntries: this.domainEntries,
             currentPatientId: this.currentPatientId,
             expandedDomains: $expandedDomains,
             dataFieldSpecs: this.dataFieldSpecs,
             onBack: () => { this.showDataDetail = false; },
             onTimelineRequest: (key: string) => {
               this.timelineField = key;
               this.patientService.getDataTimeline(this.currentPatientId, key).then((data: PatientDataPoint[]) => {
                 this.timelineData = data;
                 this.showTimelineDialog = true;
               });
             }
           });
         } else if (this.showRecordsDetail) {
            RecordsDetailPageView({
              dashboard: this.dashboard,
              dataFieldSpecs: this.dataFieldSpecs,
              expandedRecordIds: $expandedRecordIds,
             deleteRecordId: $deleteRecordId,
             showDeleteConfirm: $showDeleteConfirm,
             onBack: () => { this.showRecordsDetail = false; }
           });
        } else {
        Row() {
           Button($r('app.string.common_back'))
            .fontSize(14)
            .fontColor(AppColors.primary)
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              if (!this.navigateBack()) {
                this.patientStack.pop();
              }
            })
          Text(this.dashboard.patient.name)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.primary)
            .layoutWeight(1)
            .margin({ left: 8 })
          if (this.dashboard.patient.bedNo.length > 0) {
            Text(this.dashboard.patient.bedNo + '床')
              .fontSize(13)
              .fontColor(AppColors.textSecondary)
              .backgroundColor(AppColors.fillBeige)
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
              .color(AppColors.primary)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          Scroll() {
            Column() {
                AlertPreviewCard({ dashboard: this.dashboard, onTap: () => { this.showAlertDetail = true; } });
                DiagnosisPreviewCardView({ dashboard: this.dashboard, onTap: () => { this.showDiagnosisDetail = true; } });
                DataPreviewCard({
                  dashboard: this.dashboard,
                  domainEntries: this.domainEntries,
                  dataFieldCount: getDataFieldCount(this.dashboard, this.dataFieldSpecs),
                  dataPreviewItems: getDataPreviewItems(this.dashboard, this.dataFieldSpecs),
                  onTap: () => { this.showDataDetail = true; }
                });
                RecordsPreviewCard({
                  dashboard: this.dashboard,
                  recordPreviewItems: getRecordPreviewItems(this.dashboard.records),
                  onTap: () => { this.showRecordsDetail = true; }
                });
            }
            .padding({ left: 16, right: 16, bottom: 80 })
          }
          .layoutWeight(1)
        }

        Row() {
           Button($r('app.string.detail_upload_image'))
            .fontSize(12)
             .fontColor(AppColors.onPrimary)
             .backgroundColor(AppColors.primary)
            .borderRadius(8)
            .height(40)
            .layoutWeight(1)
            .onClick(() => { this.pickImage(); })
           Button($r('app.string.detail_upload_pdf'))
            .fontSize(12)
            .fontColor(AppColors.primary)
            .backgroundColor(AppColors.fillBeige)
            .borderRadius(8)
            .height(40)
            .layoutWeight(1)
            .margin({ left: 8 })
            .onClick(() => { this.pickPdf(); })
           Button($r('app.string.detail_input_text'))
            .fontSize(12)
            .fontColor(AppColors.primary)
            .backgroundColor(AppColors.fillBeige)
            .borderRadius(8)
            .height(40)
            .layoutWeight(1)
            .margin({ left: 8 })
           Button($r('app.string.detail_manual_input'))
            .fontSize(12)
            .fontColor(AppColors.primary)
            .backgroundColor(AppColors.fillBeige)
            .borderRadius(8)
            .height(40)
            .layoutWeight(1)
            .margin({ left: 8 })
            .onClick(() => { this.showManualInput = true; })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .backgroundColor(AppColors.card)

        if (this.uploading) {
          Row() {
            LoadingProgress()
              .width(20)
              .height(20)
              .color(AppColors.primary)
              .margin({ right: 8 })
            Text(this.uploadMsg)
              .fontSize(13)
              .fontColor(AppColors.primary)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 6, bottom: 6 })
          .backgroundColor(AppColors.tierWarnBg)
        } else if (this.uploadMsg.length > 0) {
          Text(this.uploadMsg)
            .fontSize(13)
            .fontColor(AppColors.warning)
            .width('100%')
            .padding({ left: 16, right: 16, top: 6, bottom: 6 })
            .backgroundColor(AppColors.tierWarnBg)
        }
        }
       }
       .width('100%')
       .height('100%')
       .backgroundColor(AppColors.surfaceMuted)

        if (this.showTimelineDialog) {
          TimelineDialog({
            timelineField: this.timelineField,
            timelineData: this.timelineData,
            showTimelineDialog: $showTimelineDialog,
            dataFieldSpecs: this.dataFieldSpecs,
            onOpenExamTimeEditor: (dp: PatientDataPoint) => { this.openExamTimeEditor(dp); }
          });
        }
        if (this.showExamTimeEditor) {
          ExamTimeEditorDialog({
            editExamYear: $editExamYear,
            editExamMonth: $editExamMonth,
            editExamDay: $editExamDay,
            editExamHour: $editExamHour,
            editExamMinute: $editExamMinute,
            showExamTimeEditor: $showExamTimeEditor,
            onSave: () => { this.saveExamTime(); }
          });
        }
        if (this.showManualInput) {
          ManualInputDialog({
            showManualInput: $showManualInput,
            manualFieldKey: $manualFieldKey,
            manualFieldValue: $manualFieldValue,
            manualFilterKeyword: $manualFilterKeyword,
            dataFieldSpecs: this.dataFieldSpecs,
            currentPatientId: this.currentPatientId,
            onManualInputSave: (fieldKey: string, fieldValue: string) => {
              this.executeManualInputSave(fieldKey, fieldValue);
            }
          });
        }
        if (this.showDeleteConfirm) {
          DeleteConfirmDialog({
            showDeleteConfirm: $showDeleteConfirm,
            deleteRecordId: $deleteRecordId,
            onDelete: (recordId: string) => {
              this.executeDeleteRecord(recordId);
            }
          });
        }
          if (this.showKbReader) {
            KbReaderOverlay();
          }
         if (this.showAddDiagnosis) {
           AddDiagnosisDialog({
             showAddDiagnosis: $showAddDiagnosis,
             addDiagName: $addDiagName,
             addDiagCategory: $addDiagCategory,
             currentPatientId: this.currentPatientId,
             onAddDiagnosis: (name: string, category: string) => {
               this.executeAddDiagnosis(name, category);
             }
           });
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

  async loadDiagnosisAdvice(diag: PatientDiagnosis) {
    hilog.info(0x0001, 'MedCalc', 'loadDiagnosisAdvice called for ' + diag.ruleId);
    const kbData = getDiagnosisKb(this.diagnosisKbMap, diag.ruleId);
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
      const parsed = parseRecommendationsAndSummary(response);
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
            const suppParsed = parseRecommendations(suppResponse);
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
      const tier = parseAlertResult(alert).tier;
      if (tier.length > 0) {
        alertTiers.push(alert.calcName + ':' + tier);
      }
    }
    if (alertTiers.length > 0) {
      parts.push('评分: ' + alertTiers.slice(0, 5).join(', '));
    }
    return '- 关键数据：' + parts.join(', ');
  }






  getDataDomainCount(): number {
    return this.domainEntries.length;
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

  async executeManualInputSave(fieldKey: string, fieldValue: string) {
    const savedRec = await this.patientService.saveRecord(this.currentPatientId, 'manual', '', fieldKey + '=' + fieldValue, '', '手动录入: ' + getFieldValueLabel(fieldKey, this.dataFieldSpecs));
    await this.patientService.addManualData(this.currentPatientId, fieldKey, fieldValue, savedRec.id);
    this.showManualInput = false;
    this.manualFieldKey = '';
    this.manualFieldValue = '';
    this.loadDashboard();
  }

  async executeDeleteRecord(recordId: string) {
    await this.patientService.deleteRecord(recordId);
    this.showDeleteConfirm = false;
    this.deleteRecordId = '';
    this.loadDashboard();
  }

  executeAddDiagnosis(name: string, category: string) {
    this.patientService.addUserDiagnosis(this.currentPatientId, name, category).then(() => {
      this.showAddDiagnosis = false;
      this.loadDashboard();
    });
  }

  async loadKbReaderContent(path: string) {
    const page = await this.kbService.getPage(path);
    if (page !== null) {
      this.kbReaderTitle = page.title.length > 0 ? page.title : path.split('/').pop() || '';
      this.kbReaderLines = parseKbMarkdown(page.content);
    }
  }
}
