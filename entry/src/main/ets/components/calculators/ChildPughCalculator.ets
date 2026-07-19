import { CalcResult , getTierColor, getTierBgColor } from '../../engine/CalcEngine';
import { calculateChildPugh } from '../../engine/ChildPughCalculator';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';

@Component
export struct ChildPughCalculator {
  @State resetKey: number = 0;  @State bilirubin: number = 0;
  @State bilirubinUnit: string = 'umol';
  @State albumin: number = 0;
  @State albUnit: string = 'gl';
  @State inr: number = 0;
  @State ascites: number = 0;
  @State encephalopathy: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateChildPugh(this.bilirubin, this.bilirubinUnit, this.albumin, this.albUnit, this.inr, this.ascites, this.encephalopathy); }

  reset() {
    this.bilirubin = 0;
    this.bilirubinUnit = 'umol';
    this.albumin = 0;
    this.albUnit = 'gl';
    this.inr = 0;
    this.ascites = 0;
    this.encephalopathy = 0;
    this.result = null;
    this.resetKey = this.resetKey + 1;
    this.calculate();
  }

  build() {
    if (this.resetKey % 2 === 0) {
      this.CalcContent();
    } else {
      this.CalcContent();
    }
  }

  @Builder
  CalcContent() {
    Column() {
      Column() { Text('用于评估肝硬化患者肝功能储备及手术风险').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('5项：胆红素+白蛋白+INR+腹水+肝性脑病，A/B/C三级').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Row() { Text('— 输入参数').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });

        Row() {
          Column() { Text(this.bilirubinUnit === 'umol' ? '胆红素 (µmol/L)' : '胆红素 (mg/dL)').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '请输入胆红素' }).type(InputType.Number).height(AppDimens.inputHeight).fontSize(16).fontColor(AppColors.textPrimary).placeholderColor(AppColors.placeholder).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.bilirubin = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1);
          Column() { Text(this.albUnit === 'gl' ? '白蛋白 (g/L)' : '白蛋白 (g/dL)').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '请输入白蛋白' }).type(InputType.Number).height(AppDimens.inputHeight).fontSize(16).fontColor(AppColors.textPrimary).placeholderColor(AppColors.placeholder).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.albumin = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });

        Row() {
          Text('胆红素单位').fontSize(12).fontColor(AppColors.textSecondary).layoutWeight(1);
          Button('µmol/L').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.bilirubinUnit === 'umol' ? AppColors.card : AppColors.textOption).backgroundColor(this.bilirubinUnit === 'umol' ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.bilirubinUnit === 'umol' ? AppColors.primary : AppColors.border }).borderRadius(8).height(AppDimens.touchTarget).onClick(() => { this.bilirubinUnit = 'umol'; this.calculate(); });
          Button('mg/dL').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.bilirubinUnit === 'mgdl' ? AppColors.card : AppColors.textOption).backgroundColor(this.bilirubinUnit === 'mgdl' ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.bilirubinUnit === 'mgdl' ? AppColors.primary : AppColors.border }).borderRadius(8).height(AppDimens.touchTarget).margin({ left: 6 }).onClick(() => { this.bilirubinUnit = 'mgdl'; this.calculate(); });
        }.width('100%').margin({ bottom: 8 });

        Row() {
          Text('白蛋白单位').fontSize(12).fontColor(AppColors.textSecondary).layoutWeight(1);
          Button('g/L').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.albUnit === 'gl' ? AppColors.card : AppColors.textOption).backgroundColor(this.albUnit === 'gl' ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.albUnit === 'gl' ? AppColors.primary : AppColors.border }).borderRadius(8).height(AppDimens.touchTarget).onClick(() => { this.albUnit = 'gl'; this.calculate(); });
          Button('g/dL').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.albUnit === 'gdl' ? AppColors.card : AppColors.textOption).backgroundColor(this.albUnit === 'gdl' ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.albUnit === 'gdl' ? AppColors.primary : AppColors.border }).borderRadius(8).height(AppDimens.touchTarget).margin({ left: 6 }).onClick(() => { this.albUnit = 'gdl'; this.calculate(); });
        }.width('100%').margin({ bottom: 8 });

        Column() { Text('INR').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '请输入INR' }).type(InputType.NUMBER_DECIMAL).height(AppDimens.inputHeight).fontSize(16).fontColor(AppColors.textPrimary).placeholderColor(AppColors.placeholder).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.inr = parseFloat(value) || 0; this.calculate(); }); }.width('100%').margin({ bottom: 16 });

        Column() {
          Text('腹水').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 8 });
          Row() {
            Button('无').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.ascites === 1 ? AppColors.card : AppColors.textOption).backgroundColor(this.ascites === 1 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.ascites === 1 ? AppColors.primary : AppColors.border }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.ascites = 1; this.calculate(); });
            Button('轻度').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.ascites === 2 ? AppColors.card : AppColors.textOption).backgroundColor(this.ascites === 2 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.ascites === 2 ? AppColors.primary : AppColors.border }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).margin({ left: 6 }).onClick(() => { this.ascites = 2; this.calculate(); });
            Button('中重度').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.ascites === 3 ? AppColors.card : AppColors.textOption).backgroundColor(this.ascites === 3 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.ascites === 3 ? AppColors.primary : AppColors.border }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).margin({ left: 6 }).onClick(() => { this.ascites = 3; this.calculate(); });
          }.width('100%');
        }.width('100%').margin({ bottom: 16 });

        Column() {
          Text('肝性脑病').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 8 });
          Row() {
            Button('无').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.encephalopathy === 1 ? AppColors.card : AppColors.textOption).backgroundColor(this.encephalopathy === 1 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.encephalopathy === 1 ? AppColors.primary : AppColors.border }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.encephalopathy = 1; this.calculate(); });
            Button('I-II期').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.encephalopathy === 2 ? AppColors.card : AppColors.textOption).backgroundColor(this.encephalopathy === 2 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.encephalopathy === 2 ? AppColors.primary : AppColors.border }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).margin({ left: 6 }).onClick(() => { this.encephalopathy = 2; this.calculate(); });
            Button('III-IV期').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.encephalopathy === 3 ? AppColors.card : AppColors.textOption).backgroundColor(this.encephalopathy === 3 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.encephalopathy === 3 ? AppColors.primary : AppColors.border }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).margin({ left: 6 }).onClick(() => { this.encephalopathy = 3; this.calculate(); });
          }.width('100%');
        }.width('100%');
      }.padding(AppDimens.cardPadding).backgroundColor(AppColors.card).borderRadius(AppDimens.cardRadius).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() { Text('Child-Pugh').fontSize(12).fontColor(AppColors.textSecondary).letterSpacing(1.5).fontWeight(FontWeight.Medium);
              Text(this.result!.value !== null ? `${this.result!.value!.toFixed(0)} ${this.result!.unit}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor(AppColors.primary).margin({ top: 8 });
              Text(this.result!.tier).fontSize(13).fontWeight(FontWeight.Bold).fontColor(getTierColor(this.result!.tierClass))
                .backgroundColor(getTierBgColor(this.result!.tierClass)).borderRadius(20).padding({ left: 12, right: 12, top: 4, bottom: 4 }).margin({ top: 8 });
            }.alignItems(HorizontalAlign.Start).layoutWeight(1);
            Column() { Text(this.result!.footnote).fontSize(14).fontColor(AppColors.textBody).lineHeight(22); }.layoutWeight(1).alignItems(HorizontalAlign.Start);
          }.width('100%');
        }.padding(AppDimens.cardPadding).backgroundColor(AppColors.card).borderRadius(AppDimens.cardRadius).width('100%');
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
