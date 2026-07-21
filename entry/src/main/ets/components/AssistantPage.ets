import { AssistantService, AssistantMessage, CalcMatch } from '../services/AssistantService';
import { PreferencesService } from '../services/PreferencesService';
import { ApiServiceConfig, sendVisionRequest } from '../services/LlmService';
import { CalcResult, getTierColor, getTierBgColor } from '../engine/CalcEngine';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo, picker } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { image } from '@kit.ImageKit';
import { pdfService } from '@kit.PDFKit';
import { ImageEditor } from './ImageEditor';
import { ImageStore } from '../services/ImageStore';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppColors } from '../utils/AppColors';
import { AppDimens } from '../utils/AppDimens';
import { showConfirmDialog } from '../utils/ConfirmDialog';

class DataDisplayItem {
  key: string = '';
  label: string = '';
  value: string = '';
}

@Component
export struct AssistantPage {
  @Link currentCalc: string;
  @Link currentTab: number;
  @State userInput: string = '';
  @State messages: AssistantMessage[] = [];
  @State loading: boolean = false;
  @State errorMsg: string = '';
  @State selectedImageUri: string = '';
  @State imageBase64: string = '';
  @State imageMime: string = '';
  @State supplementFields: Record<string, string> = {};
  @State showExpandedEditor: boolean = false;
  @State expandedEditorText: string = '';
  @State expandedCalcIds: Set<string> = new Set();
  @State @Watch('onImageEditorClosed') showImageEditor: boolean = false;
  @State editorImageUri: string = '';
  @State editorResultBase64: string = '';
  @State editorResultMime: string = '';
  @State showAttachMenu: boolean = false;

  private assistantService = AssistantService.getInstance();
  private prefsService = PreferencesService.getInstance();
  private scroller: Scroller = new Scroller();

  aboutToAppear() {
    this.messages = this.assistantService.getMessages();
  }

  getActiveService(): ApiServiceConfig | null {
    return this.prefsService.getActiveLlmConfig();
  }

  sendQuery() {
    const trimmed = this.userInput.trim();
    if (!trimmed && this.imageBase64.length === 0) {
      return;
    }
    const config = this.getActiveService();
    if (!config) {
      this.errorMsg = '请先在设置中配置 API 服务';
      return;
    }

    this.errorMsg = '';
    this.loading = true;

    this.assistantService.sendMessage(trimmed, this.imageBase64, this.imageMime, config).then((msg: AssistantMessage) => {
      this.loading = false;
      this.messages = this.assistantService.getMessages();
      this.userInput = '';
      this.imageBase64 = '';
      this.imageMime = '';
      this.selectedImageUri = '';
      this.scroller.scrollToIndex(this.messages.length - 1);
    }).catch((err: Error) => {
      this.loading = false;
      this.errorMsg = '请求失败，请重试';
    });
  }

  pickImage() {
    try {
      const picker = new photoAccessHelper.PhotoViewPicker();
      const options = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      options.maxSelectNumber = 1;
      picker.select(options).then((result: photoAccessHelper.PhotoSelectResult) => {
        if (result.photoUris && result.photoUris.length > 0) {
          this.editorImageUri = result.photoUris[0];
          this.editorResultBase64 = '';
          this.editorResultMime = '';
          this.showImageEditor = true;
        }
      }).catch((_err: Error) => {});
    } catch (_e) {}
  }

  onImageEditorClosed() {
    if (!this.showImageEditor && this.editorResultBase64.length > 0) {
      this.imageBase64 = this.editorResultBase64;
      this.imageMime = this.editorResultMime;
      this.selectedImageUri = 'data:' + this.editorResultMime + ';base64,' + this.editorResultBase64;
      this.errorMsg = '';
    }
  }

  clearImage() {
    this.selectedImageUri = '';
    this.imageBase64 = '';
    this.imageMime = '';
  }

  async pickPdf() {
    this.showAttachMenu = false;
    try {
      const documentSelectOptions = new picker.DocumentSelectOptions();
      documentSelectOptions.fileSuffixFilters = ['.pdf'];
      documentSelectOptions.maxSelectNumber = 1;
      const documentPicker = new picker.DocumentViewPicker();
      const uris = await documentPicker.select(documentSelectOptions);
      if (uris.length > 0) {
        await this.processPdfForAssistant(uris[0]);
      }
    } catch (e) {
      hilog.error(0xF000, 'AssistantPage', 'pickPdf failed: ' + (e instanceof Error ? e.message : String(e)));
    }
  }

  async processPdfForAssistant(uri: string) {
    try {
      this.loading = true;
      const context = getContext(this);
      const imageStore = ImageStore.getInstance();
      imageStore.init(context);

      const tempId = 'pdf_' + Date.now().toString();
      const sandboxPath = imageStore.copyToTemp(uri, tempId);
      if (sandboxPath.length === 0) {
        this.loading = false;
        this.errorMsg = 'PDF文件复制失败';
        return;
      }

      const pdfDoc = new pdfService.PdfDocument();
      const loadResult = pdfDoc.loadDocument(sandboxPath);
      if (loadResult !== pdfService.ParseResult.PARSE_SUCCESS) {
        pdfDoc.releaseDocument();
        imageStore.clearTemp();
        this.loading = false;
        this.errorMsg = 'PDF文件加载失败';
        return;
      }

      const pageCount = pdfDoc.getPageCount();
      if (pageCount === 0) {
        pdfDoc.releaseDocument();
        imageStore.clearTemp();
        this.loading = false;
        this.errorMsg = 'PDF无有效页面';
        return;
      }

      const page = pdfDoc.getPage(0);
      const pixelMap = page.getPagePixelMap();
      pdfDoc.releaseDocument();
      imageStore.clearTemp();

      if (!pixelMap) {
        this.loading = false;
        this.errorMsg = 'PDF页面渲染失败';
        return;
      }

      const imagePackerApi = image.createImagePacker();
      const packOpts: image.PackingOption = { format: 'image/jpeg', quality: 85 };
      const packedData = await imagePackerApi.packToData(pixelMap, packOpts);
      imagePackerApi.release();

      const uint8Arr = new Uint8Array(packedData);
      const base64Helper = new util.Base64Helper();
      this.imageBase64 = base64Helper.encodeToStringSync(uint8Arr);
      this.imageMime = 'image/jpeg';
      this.selectedImageUri = uri;
      this.errorMsg = '';
      this.loading = false;

      if (this.userInput.trim().length === 0) {
        this.userInput = '请分析这份PDF报告（第1页/' + pageCount + '页）中的医学数据';
      }
    } catch (e) {
      this.loading = false;
      this.errorMsg = 'PDF处理失败: ' + (e instanceof Error ? e.message : String(e));
      hilog.error(0xF000, 'AssistantPage', 'processPdf failed: ' + (e instanceof Error ? e.stack : String(e)));
    }
  }

  clearSession() {
    this.assistantService.clearSession();
    this.messages = [];
    this.errorMsg = '';
  }

  supplementAndCalc(calcId: string) {
    const fieldSpecs = this.assistantService.getMissingFieldSpecs(calcId);
    const fields: Record<string, string> = {};
    for (let i = 0; i < fieldSpecs.length; i++) {
      const key = fieldSpecs[i].key;
      const val = this.supplementFields[key];
      if (val !== undefined && val.length > 0) {
        fields[key] = val;
      }
    }
    if (Object.keys(fields).length === 0) {
      return;
    }
    const msg = this.assistantService.supplementData(fields);
    this.messages = this.assistantService.getMessages();
    this.supplementFields = {};
  }

  jumpToCalc(calcId: string) {
    this.currentCalc = calcId;
    this.currentTab = 0;
  }

  build() {
     Stack() {
     if (!this.showImageEditor) {
     Column() {
      this.HeaderBar();

      if (this.errorMsg) {
        Row() {
          Text('⚠ ')
            .fontSize(12)
            .fontColor(AppColors.warning)
          Text(this.errorMsg)
            .fontSize(12)
            .fontColor(AppColors.warning)
        }
        .width('100%')
        .padding(8)
        .backgroundColor(AppColors.tierWarnBg)
      }

      List({ space: 12, scroller: this.scroller }) {
        if (this.messages.length === 0) {
          ListItem() {
            this.WelcomeCard();
          }
          .margin({ top: 24 })
        }

        ForEach(this.messages, (msg: AssistantMessage) => {
          ListItem() {
            if (msg.role === 'user') {
              this.UserBubble(msg);
            } else {
              this.AssistantBubble(msg);
            }
          }
        }, (msg: AssistantMessage) => msg.id)

        if (this.loading) {
          ListItem() {
            this.LoadingBubble();
          }
        }
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .divider({ strokeWidth: 0 })

       this.InputBar();
     }
     .width('100%')
     .height('100%')
      .backgroundColor(AppColors.background)
      .bindSheet($$this.showExpandedEditor, this.ExpandedEditorBuilder(), {
        height: SheetSize.LARGE,
        dragBar: false,
        showClose: false,
        backgroundColor: AppColors.card
      })
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
  HeaderBar() {
    Row() {
      Text('智能助手')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.primary)
        .layoutWeight(1)

      Button() {
        Text('🗑')
          .fontSize(16)
          .fontColor(AppColors.textSecondary)
      }
      .width(44)
      .height(AppDimens.touchTarget)
      .backgroundColor('transparent')
      .onClick(() => {
        showConfirmDialog('清空会话', '确定要清空当前会话记录吗？此操作不可恢复。', () => { this.clearSession(); });
      })
    }
    .width('100%')
    .height(AppDimens.touchTarget)
    .padding({ left: 16, right: 16 })
    .backgroundColor(AppColors.card)
    .border({ width: { bottom: 1 }, color: AppColors.divider })
  }

  @Builder
  WelcomeCard() {
    Column() {
      Text('智能医学助手')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.primary)
      Text('输入病情描述或上传检查报告图片，自动提取数据并计算相关评分')
        .fontSize(12)
        .fontColor(AppColors.textSecondary)
        .margin({ top: 4 })
        .textAlign(TextAlign.Center)
      Column() {
        Text('示例输入：').fontSize(12).fontColor(AppColors.textSecondary).margin({ bottom: 4 })
        Text('• 65岁男性，肌酐200μmol/L，体重70kg').fontSize(12).fontColor(AppColors.textBody)
        Text('• 患者GCS 8分，收缩压90，心率110').fontSize(12).fontColor(AppColors.textBody)
        Text('• [上传血气分析报告图片]').fontSize(12).fontColor(AppColors.textBody)
      }
      .margin({ top: 8 })
      .padding(8)
      .backgroundColor(AppColors.surfaceSubtle)
      .borderRadius(8)
    }
    .width('100%')
    .padding(AppDimens.cardPadding)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(AppColors.card)
    .borderRadius(AppDimens.cardRadius)
  }

  @Builder
  UserBubble(msg: AssistantMessage) {
    Column() {
      Row() {
        Column() {
          if (msg.text.length > 0) {
            Text(msg.text)
              .fontSize(14)
              .fontColor(AppColors.onPrimary)
              .width('100%')
          }
        }
        .padding(12)
        .backgroundColor(AppColors.primary)
        .borderRadius({ topLeft: 12, topRight: 12, bottomLeft: 4, bottomRight: 12 })
        .constraintSize({ maxWidth: '80%' })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
  }

  @Builder
  AssistantBubble(msg: AssistantMessage) {
    Column() {
      Column() {
        if (msg.summaryText.length > 0) {
          Text(msg.summaryText)
            .fontSize(14)
            .fontColor(AppColors.primary)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })
        }

        if (Object.keys(msg.extractedData).length > 0) {
          this.ExtractedDataCard(msg.extractedData);
        }

        if (msg.matches.length > 0) {
          this.MatchesCards(msg.matches);
        }
      }
      .padding(12)
      .backgroundColor(AppColors.card)
      .borderRadius({ topLeft: 12, topRight: 12, bottomLeft: 12, bottomRight: 4 })
      .width('92%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
  }

  @Builder
  ExtractedDataCard(data: Record<string, string>) {
    Column() {
      Text('提取数据')
        .fontSize(12)
        .fontColor(AppColors.textSecondary)
        .letterSpacing(1)
        .width('100%')
        .margin({ bottom: 6 })

      ForEach(this.formatExtractedData(data), (item: DataDisplayItem) => {
        Row() {
          Text(item.label)
            .fontSize(12)
            .fontColor(AppColors.textSecondary)
            .width('40%')
          Text(item.value)
            .fontSize(12)
            .fontColor(AppColors.primary)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
        }
        .width('100%')
        .padding({ top: 2, bottom: 2 })
      }, (item: DataDisplayItem) => item.key)
    }
    .width('100%')
    .padding(8)
    .backgroundColor(AppColors.surfaceSubtle)
    .borderRadius(6)
    .margin({ bottom: 8 })
  }

  @Builder
  MatchesCards(matches: CalcMatch[]) {
    Column() {
      Text('📊 计算结果')
        .fontSize(12)
        .fontColor(AppColors.textSecondary)
        .letterSpacing(1)
        .width('100%')
        .margin({ bottom: 6 })

      ForEach(matches, (match: CalcMatch) => {
        this.CalcCard(match);
      }, (match: CalcMatch) => match.calcId)
    }
    .width('100%')
  }

  private isCalcExpanded(match: CalcMatch): boolean {
    if (this.expandedCalcIds.has(match.calcId)) {
      return true;
    }
    return false;
  }

  private toggleCalc(calcId: string): void {
    if (this.expandedCalcIds.has(calcId)) {
      this.expandedCalcIds.delete(calcId);
    } else {
      this.expandedCalcIds.add(calcId);
    }
    this.expandedCalcIds = new Set(this.expandedCalcIds);
  }

  @Builder
  CalcCard(match: CalcMatch) {
    Column() {
      Row() {
        Text(match.icon)
          .fontSize(16)
          .margin({ right: 6 })
        Text(match.calcName)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.primary)
          .layoutWeight(1)

        if (match.completeness === 100) {
          Text('✓')
            .fontSize(14)
            .fontColor(AppColors.tierOk)
            .margin({ right: 8 })
        }

        Text(match.completeness + '%')
          .fontSize(12)
          .fontColor(match.completeness === 100 ? AppColors.tierOk : AppColors.tierWarn)
          .fontWeight(FontWeight.Bold)

        if (match.completeness < 100) {
          Text(' ' + match.availableFields.length + '/' + (match.availableFields.length + match.missingFields.length))
            .fontSize(12)
            .fontColor(AppColors.textSecondary)
        }

        Text(this.isCalcExpanded(match) ? ' ▲' : ' ▼')
          .fontSize(12)
          .fontColor(AppColors.textSecondary)
          .margin({ left: 4 })
      }
      .width('100%')
      .onClick(() => {
        this.toggleCalc(match.calcId);
      })

      if (this.isCalcExpanded(match)) {
        if (match.completeness === 100 && match.result) {
          this.ExpandedResult(match);
        } else {
          this.ExpandedPartial(match);
        }
      }
    }
    .width('100%')
    .padding(10)
    .backgroundColor(match.completeness === 100 ? AppColors.surfaceSubtle : AppColors.tierWarnBg)
    .borderRadius(8)
    .margin({ bottom: 6 })
  }

  @Builder
  ExpandedResult(match: CalcMatch) {
    Column() {
      Row() {
        Column() {
          Text(match.result!.value !== null ? match.result!.value!.toFixed(1).replace(/\.0$/, '') : '—')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.primary)
          Text(match.result!.unit)
            .fontSize(12)
            .fontColor(AppColors.textSecondary)
            .margin({ top: 2 })
          Text(match.result!.tier)
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(getTierColor(match.result!.tierClass))
            .backgroundColor(getTierBgColor(match.result!.tierClass))
            .borderRadius(20)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column() {
          Text(match.result!.footnote)
            .fontSize(12)
            .fontColor(AppColors.textBody)
            .lineHeight(18)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .margin({ top: 6 })

      Button('查看详情 →')
        .fontSize(12)
        .fontColor(AppColors.primary)
        .backgroundColor(AppColors.fillBeige)
        .borderRadius(6)
        .height(28)
        .width('100%')
        .margin({ top: 6 })
        .onClick(() => {
          this.jumpToCalc(match.calcId);
        })
    }
  }

  @Builder
  ExpandedPartial(match: CalcMatch) {
    Column() {
      Text('还需: ' + match.missingFields.map((k: string) => this.assistantService.getFieldLabel(k)).join(', '))
        .fontSize(12)
        .fontColor(AppColors.textSecondary)
        .width('100%')
        .margin({ top: 6, bottom: 6 })

      this.SupplementForm(match.calcId, match.missingFields)

      Button('计算')
        .fontSize(12)
        .fontColor(AppColors.onPrimary)
        .backgroundColor(AppColors.primary)
        .borderRadius(6)
        .height(28)
        .width('100%')
        .margin({ top: 6 })
        .onClick(() => {
          this.supplementAndCalc(match.calcId);
        })
    }
  }

  @Builder
  SupplementForm(calcId: string, missingFields: string[]) {
    Column() {
      ForEach(missingFields, (fieldKey: string) => {
        Row() {
          Text(this.assistantService.getFieldLabel(fieldKey))
            .fontSize(12)
            .fontColor(AppColors.textSecondary)
            .width('35%')
          this.FieldInput(fieldKey)
        }
        .width('100%')
        .margin({ bottom: 4 })
      }, (fieldKey: string) => calcId + '_' + fieldKey)
    }
    .width('100%')
  }

  @Builder
  FieldInput(fieldKey: string) {
    if (this.isSelectField(fieldKey)) {
      Row() {
        ForEach(this.getFieldOptions(fieldKey), (opt: string) => {
          Button(this.getOptionLabel(fieldKey, opt))
            .fontSize(12)
            .fontColor(this.supplementFields[fieldKey] === opt ? AppColors.card : AppColors.textOption)
            .backgroundColor(this.supplementFields[fieldKey] === opt ? AppColors.primary : AppColors.fillNeutral)
            .border({ width: 1, color: this.supplementFields[fieldKey] === opt ? AppColors.primary : AppColors.border })
            .borderRadius(8)
            .height(30)
            .padding({ left: 8, right: 8 })
            .margin({ left: 4 })
            .onClick(() => {
              const updated: Record<string, string> = {};
              const existingKeys = Object.keys(this.supplementFields);
              for (let i = 0; i < existingKeys.length; i++) {
                updated[existingKeys[i]] = this.supplementFields[existingKeys[i]];
              }
              updated[fieldKey] = opt;
              this.supplementFields = updated;
            })
        }, (opt: string) => fieldKey + '_' + opt)
      }
      .layoutWeight(1)
    } else {
      TextInput({ placeholder: '请输入' })
        .height(32)
        .fontSize(12)
        .layoutWeight(1)
        .backgroundColor(AppColors.card)
        .borderRadius(6)
        .padding({ left: 8 })
        .onChange((value: string) => {
          const updated: Record<string, string> = {};
          const existingKeys = Object.keys(this.supplementFields);
          for (let i = 0; i < existingKeys.length; i++) {
            updated[existingKeys[i]] = this.supplementFields[existingKeys[i]];
          }
          updated[fieldKey] = value;
          this.supplementFields = updated;
        })
    }
  }

  isSelectField(fieldKey: string): boolean {
    const spec = this.assistantService.getFieldSpec(fieldKey);
    return spec !== null && spec.type === 'select' && spec.options !== undefined && spec.options.length > 0;
  }

  getFieldOptions(fieldKey: string): string[] {
    const spec = this.assistantService.getFieldSpec(fieldKey);
    if (spec !== null && spec.type === 'select' && spec.options !== undefined && spec.options.length > 0) {
      return spec.options;
    }
    return [];
  }

  getOptionLabel(fieldKey: string, opt: string): string {
    if (fieldKey === 'albUnit') {
      return opt === 'gl' ? 'g/L' : 'g/dL';
    }
    if (fieldKey === 'bilirubinUnit') {
      return opt === 'umol' ? 'μmol/L' : 'mg/dL';
    }
    if (fieldKey === 'crUnit' || fieldKey === 'cr0Unit' || fieldKey === 'cr1Unit') {
      return opt === 'umol' ? 'μmol/L' : 'mg/dL';
    }
    if (fieldKey === 'hgbUnit') {
      return opt === 'gl' ? 'g/L' : 'g/dL';
    }
    if (fieldKey === 'ureaUnit') {
      return opt === 'mmol' ? 'mmol/L' : 'mg/dL';
    }
    if (fieldKey === 'fio2Mode') {
      return opt === 'dec' ? '小数' : '%';
    }
    if (fieldKey === 'pao2Unit' || fieldKey === 'paco2Unit') {
      return opt === 'mmhg' ? 'mmHg' : 'kPa';
    }
    if (fieldKey === 'sex') {
      return opt === 'male' ? '男' : '女';
    }
    if (fieldKey === 'acute') {
      return opt === 'acute' ? '急性' : '慢性';
    }
    if (fieldKey === 'consciousness') {
      if (opt === 'alert') return '清醒';
      if (opt === 'voice') return '对声音有反应';
      if (opt === 'pain') return '对疼痛有反应';
      return '无反应';
    }
    if (fieldKey === 'vaso') {
      if (opt === 'none') return '无';
      if (opt === 'dopamine_low') return '多巴胺(低)';
      if (opt === 'dopamine_mid') return '多巴胺(中)';
      if (opt === 'dopamine_high') return '多巴胺(高)';
      if (opt === 'norepinephrine') return '去甲肾上腺素';
      if (opt === 'epinephrine') return '肾上腺素';
      if (opt === 'dobutamine') return '多巴酚丁胺';
      return opt;
    }
    if (fieldKey === 'o2supplement') {
      return opt === 'air' ? '空气' : '吸氧';
    }
    if (fieldKey === 'ichLocation') {
      return opt === '0' ? '幕上' : '幕下';
    }
    if (fieldKey === 'ichIvh') {
      return opt === '0' ? '无' : '有';
    }
    if (fieldKey === 'etiology') {
      if (opt === 'acetaminophen') return '对乙酰氨基酚';
      return '其他';
    }
    if (fieldKey === 'chronic') {
      if (opt === 'none') return '无';
      if (opt === 'nonSurgical') return '非手术';
      return '择期手术';
    }
    if (fieldKey === 'perf' || fieldKey === 'resus') {
      if (opt === 'A') return 'A-稳定';
      if (opt === 'B') return 'B-危险';
      return 'C-致命';
    }
    if (fieldKey === 'weightLoss') {
      if (opt === 'none') return '无';
      if (opt === 'mild') return '轻度';
      if (opt === 'mod') return '中度';
      return '重度';
    }
    if (fieldKey === 'intake') {
      if (opt === 'normal') return '正常';
      if (opt === 'mild') return '轻度减少';
      if (opt === 'mod') return '中度减少';
      return '重度减少';
    }
    if (fieldKey === 'disease') {
      if (opt === 'none') return '无';
      if (opt === 'moderate') return '中度';
      return '重度';
    }
    const boolFields: string[] = [
      'confusion', 'chf', 'htn', 'dm', 'stroke', 'vasc', 'female', 'age75', 'age65',
      'renal', 'liver', 'bleed', 'inrAbn', 'drugs', 'alcohol', 'bpAbn', 'dur',
      'arf', 'dmHtnAngina', 'sbpLt100', 'hrGt100', 'weightLt67', 'anteriorLbbb',
      'timeToTreat', 'ageGte65', 'riskFactorsGte3', 'knownCAD', 'priorAspirin',
      'severeAngina', 'stDevGte05', 'biomarkerElevated', 'clinicalPe', 'hrGt100Pe',
      'surgery', 'hemoptysis', 'cancer', 'anemia', 'sexPesi', 'cancerPesi',
      'chfPesi', 'cldPesi', 'ams', 'osp', 'comorb', 'rrt', 'ageAdj', 'acKf'
    ];
    if (boolFields.indexOf(fieldKey) >= 0) {
      return opt === '0' ? '否' : '是';
    }
    return opt;
  }

  private unitKeys: string[] = [
    'crUnit', 'cr0Unit', 'cr1Unit', 'albUnit', 'bilirubinUnit', 'hgbUnit',
    'ureaUnit', 'pao2Unit', 'paco2Unit', 'fio2Mode'
  ];

  private unitParentMap: Map<string, string> = new Map([
    ['crUnit', 'creatinine'], ['cr0Unit', 'cr0'], ['cr1Unit', 'cr1'],
    ['albUnit', 'alb'], ['bilirubinUnit', 'bilirubin'], ['hgbUnit', 'hgb'],
    ['ureaUnit', 'urea'], ['pao2Unit', 'pao2'], ['paco2Unit', 'paco2'],
    ['fio2Mode', 'fio2']
  ]);

  private unitValueMap: Map<string, Map<string, string>> = new Map([
    ['crUnit', new Map([['umol', 'μmol/L'], ['mgdl', 'mg/dL']])],
    ['cr0Unit', new Map([['umol', 'μmol/L'], ['mgdl', 'mg/dL']])],
    ['cr1Unit', new Map([['umol', 'μmol/L'], ['mgdl', 'mg/dL']])],
    ['albUnit', new Map([['gl', 'g/L'], ['gdl', 'g/dL']])],
    ['bilirubinUnit', new Map([['umol', 'μmol/L'], ['mgdl', 'mg/dL']])],
    ['hgbUnit', new Map([['gl', 'g/L'], ['gdl', 'g/dL']])],
    ['ureaUnit', new Map([['mmol', 'mmol/L'], ['mgdl', 'mg/dL']])],
    ['pao2Unit', new Map([['mmhg', 'mmHg'], ['kpa', 'kPa']])],
    ['paco2Unit', new Map([['mmhg', 'mmHg'], ['kpa', 'kPa']])],
    ['fio2Mode', new Map([['dec', ''], ['pct', '%']])]
  ]);

  formatExtractedData(data: Record<string, string>): DataDisplayItem[] {
    const result: DataDisplayItem[] = [];
    const keys = Object.keys(data);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      if (this.unitKeys.indexOf(key) >= 0) {
        continue;
      }
      const item = new DataDisplayItem();
      item.key = key;
      item.label = this.assistantService.getFieldLabel(key);
      const value = data[key];
      const spec = this.assistantService.getFieldSpec(key);
      if (spec !== null && spec.type === 'select') {
        item.value = this.getOptionLabel(key, value);
      } else if (spec !== null && spec.type === 'number') {
        let unitStr = spec.unit;
        const parentUnitKey = this.findUnitKeyForField(key);
        if (parentUnitKey.length > 0 && data[parentUnitKey] !== undefined) {
          const unitMap = this.unitValueMap.get(parentUnitKey);
          if (unitMap !== undefined) {
            const resolvedUnit = unitMap.get(data[parentUnitKey]);
            if (resolvedUnit !== undefined) {
              unitStr = resolvedUnit;
            }
          }
        }
        item.value = value + (unitStr.length > 0 ? ' ' + unitStr : '');
      } else {
        item.value = value;
      }
      result.push(item);
    }
    return result;
  }

  private findUnitKeyForField(key: string): string {
    const iter = this.unitParentMap.entries();
    let entry = iter.next();
    while (!entry.done) {
      if (entry.value[1] === key) {
        return entry.value[0];
      }
      entry = iter.next();
    }
    return '';
  }
  @Builder
  LoadingBubble() {
    Column() {
      Row() {
        LoadingProgress()
          .width(18)
          .height(18)
          .color(AppColors.textSecondary)
          .margin({ right: 8 })
        Text('分析中...')
          .fontSize(13)
          .fontColor(AppColors.textSecondary)
      }
      .padding(12)
      .backgroundColor(AppColors.card)
      .borderRadius({ topLeft: 12, topRight: 12, bottomLeft: 12, bottomRight: 4 })
    }
    .width('100%')
  }

  @Builder
  InputBar() {
    Column() {
      if (this.selectedImageUri.length > 0) {
        Row() {
          Image(this.selectedImageUri)
            .width(36)
            .height(36)
            .borderRadius(4)
            .objectFit(ImageFit.Cover)
            .flexShrink(0)
          Text('已选择图片')
            .fontSize(12)
            .fontColor(AppColors.textBody)
            .layoutWeight(1)
            .margin({ left: 6 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text('×')
            .fontSize(16)
            .fontColor(AppColors.textSecondary)
            .width(24)
            .height(24)
            .textAlign(TextAlign.Center)
            .borderRadius(AppDimens.cardRadius)
            .backgroundColor(AppColors.fillBeige)
            .onClick(() => {
              this.clearImage();
            })
            .flexShrink(0)
        }
        .width('100%')
        .height(AppDimens.inputHeight)
        .padding({ left: 8, right: 8 })
        .alignItems(VerticalAlign.Center)
        .borderRadius({ topLeft: 8, topRight: 8 })
      }

      Row() {
        Stack() {
          Button() {
            Text('+')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
          }
          .width(44)
          .height(AppDimens.touchTarget)
          .backgroundColor('transparent')
          .onClick(() => {
            this.showAttachMenu = !this.showAttachMenu;
          })

          if (this.showAttachMenu) {
            Column() {
              Text('图片')
                .fontSize(13)
                .fontColor(AppColors.primary)
                .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                .onClick(() => {
                  this.showAttachMenu = false;
                  this.pickImage();
                })
              Divider().width('100%')
              Text('PDF')
                .fontSize(13)
                .fontColor(AppColors.primary)
                .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                .onClick(() => {
                  this.pickPdf();
                })
            }
            .backgroundColor(AppColors.card)
            .borderRadius(8)
            .shadow({ radius: 4, color: '#40000000', offsetY: 2 })
            .position({ x: 0, y: -80 })
            .width(80)
          }
        }
        .width(36)

        Stack({ alignContent: Alignment.TopEnd }) {
          TextArea({ text: this.userInput, placeholder: '描述病情或补充数据...' })
            .height(AppDimens.inputHeight)
            .fontSize(14)
            .layoutWeight(1)
            .backgroundColor(AppColors.background)
            .borderRadius(8)
            .padding({ left: 10, right: 30, top: 8, bottom: 8 })
            .onChange((value: string) => {
              this.userInput = value;
            })

          Text('⤢')
            .fontSize(18)
            .fontColor(AppColors.textSecondary)
            .padding({ top: 4, right: 8 })
            .onClick(() => {
              this.expandedEditorText = this.userInput;
              this.showExpandedEditor = true;
            })
        }
        .layoutWeight(1)

        Button() {
          if (this.loading) {
            LoadingProgress()
              .width(18)
              .height(18)
              .color(AppColors.onPrimary)
          } else {
            Text('➤')
              .fontSize(18)
              .fontColor(AppColors.onPrimary)
          }
        }
        .width(40)
        .height(AppDimens.inputHeight)
        .backgroundColor(this.loading ? AppColors.textSecondary : AppColors.primary)
        .borderRadius(20)
        .margin({ left: 8 })
        .enabled(!this.loading)
        .onClick(() => {
          this.sendQuery();
        })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor(AppColors.card)
      .borderRadius(this.selectedImageUri.length > 0 ? { bottomLeft: 8, bottomRight: 8 } : 8)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .backgroundColor(AppColors.card)
  }

  @Builder
  ExpandedEditorBuilder() {
    Column() {
      Row() {
        Text('取消')
          .fontSize(16)
          .fontColor(AppColors.textSecondary)
          .padding({ left: 16, top: 12, bottom: 12 })
          .onClick(() => {
            this.showExpandedEditor = false;
          })
        Text('编辑输入')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.primary)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text('确认')
          .fontSize(16)
          .fontColor(AppColors.primary)
          .fontWeight(FontWeight.Medium)
          .padding({ right: 16, top: 12, bottom: 12 })
          .onClick(() => {
            this.userInput = this.expandedEditorText;
            this.showExpandedEditor = false;
          })
      }
      .width('100%')
      .backgroundColor(AppColors.card)

      Divider().color(AppColors.divider)

      TextArea({ text: this.expandedEditorText })
        .fontSize(16)
        .fontColor(AppColors.primary)
        .backgroundColor(AppColors.surfaceSubtle)
        .borderRadius(0)
        .layoutWeight(1)
        .width('100%')
        .padding(AppDimens.cardPadding)
        .onChange((v: string) => {
          this.expandedEditorText = v;
        })
     }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.surfaceSubtle)
   }
  }
