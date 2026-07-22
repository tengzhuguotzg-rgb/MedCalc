import { CalcResult } from '../../engine/CalcEngine';
import { calculateSirs } from '../../engine/CommonCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, ResetButton, ResultCard } from './widgets/CalcWidgets';

@Component
export struct SirsCalculator {
  @State resetKey: number = 0;  @State temp: number = 0;
  @State hr: number = 0;
  @State rr: number = 0;
  @State paco2: number = 0;
  @State wbc: number = 0;
  @State bands: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateSirs(this.temp, this.hr, this.rr, this.paco2, this.wbc, this.bands); }

  reset() {
    this.temp = 0;
    this.hr = 0;
    this.rr = 0;
    this.paco2 = 0;
    this.wbc = 0;
    this.bands = 0;
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
      Column() { Text('用于筛查全身炎症反应综合征/脓毒症').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('4项：体温+心率+呼吸+WBC，≥2项阳性').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        Row() { Text('— 输入参数').fontSize(12).fontColor(AppColors.textSecondary).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); ResetButton({ onReset: () => { this.reset(); } }) }.width('100%').margin({ bottom: 12 });

        Row() {
          Column() {
            Text('体温 (°C)').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            TextInput({ placeholder: '体温' }).type(InputType.NUMBER_DECIMAL).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder)
              .onChange((value: string) => { this.temp = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1);
          Column() {
            Text('心率 (次/分)').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            TextInput({ placeholder: 'HR' }).type(InputType.Number).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder)
              .onChange((value: string) => { this.hr = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 8 });

        Row() {
          Column() {
            Text('呼吸频率 (次/分)').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            TextInput({ placeholder: 'RR' }).type(InputType.Number).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder)
              .onChange((value: string) => { this.rr = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1);
          Column() {
            Text('PaCO₂ (mmHg)').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            TextInput({ placeholder: 'PaCO2' }).type(InputType.Number).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder)
              .onChange((value: string) => { this.paco2 = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 8 });

        Row() {
          Column() {
            Text('WBC (×10⁹/L)').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            TextInput({ placeholder: 'WBC' }).type(InputType.NUMBER_DECIMAL).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder)
              .onChange((value: string) => { this.wbc = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1);
          Column() {
            Text('未成熟粒细胞 %').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            TextInput({ placeholder: 'Bands' }).type(InputType.NUMBER_DECIMAL).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder)
              .onChange((value: string) => { this.bands = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'SIRS Total', value: this.result!.value, valueMarginTop: 4, tierMarginTop: 4, titleMedium: false, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
