import { CalcResult } from '../../engine/CalcEngine';
import { calculateMnutric } from '../../engine/MnutricCalculator';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, OptionChip, ResetButton, ResultCard } from './widgets/CalcWidgets';

@Component
export struct MnutricCalculator {
  @State resetKey: number = 0;
  @State age: number = -1;
  @State apache2: number = 0;
  @State sofa: number = 0;
  @State comorb: number = -1;
  @State icuDay: number = -1;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateMnutric(this.age, this.apache2, this.sofa, this.comorb, this.icuDay); }

  reset() {
    this.age = -1;
    this.apache2 = 0;
    this.sofa = 0;
    this.comorb = -1;
    this.icuDay = -1;
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
      Column() {
        Text('用于 ICU 患者营养风险评估')
          .fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('5 项, 总分 0-9, ≥5 高营养风险 (Heyland 2011)')
          .fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        Row() { Text('— 输入参数').fontSize(12).fontColor(AppColors.textSecondary).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); ResetButton({ onReset: () => { this.reset(); } }) }.width('100%').margin({ bottom: 12 });

        Column() {
          Text('年龄').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
          Row() {
            OptionChip({ label: '< 50', selected: this.age === 0, fontSize: 14, bold: true, chipHeight: AppDimens.inputHeight, onChipClick: () => { this.age = 0; this.calculate(); } }).layoutWeight(1).margin({ right: 4 });
            OptionChip({ label: '50-74', selected: this.age === 1, fontSize: 14, bold: true, chipHeight: AppDimens.inputHeight, onChipClick: () => { this.age = 1; this.calculate(); } }).layoutWeight(1).margin({ left: 4, right: 4 });
            OptionChip({ label: '≥ 75', selected: this.age === 2, fontSize: 14, bold: true, chipHeight: AppDimens.inputHeight, onChipClick: () => { this.age = 2; this.calculate(); } }).layoutWeight(1).margin({ left: 4 });
          }.width('100%');
        }.width('100%').margin({ bottom: 10 });

        Text('疾病严重度评分').fontSize(12).fontColor(AppColors.textSecondary).margin({ bottom: 8 });
        Row() {
          Column() {
            Text('APACHE II').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            TextInput({ placeholder: '0-71' })
              .type(InputType.Number).height(AppDimens.inputHeight).fontSize(16)
              .backgroundColor(AppColors.card).borderRadius(8)
              .border({ width: 1, color: AppColors.border })
              .padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder)
              .onChange((v: string) => { this.apache2 = parseFloat(v) || 0; this.calculate(); });
          }.layoutWeight(1);
          Column() {
            Text('SOFA 评分').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            TextInput({ placeholder: '0-24' })
              .type(InputType.Number).height(AppDimens.inputHeight).fontSize(16)
              .backgroundColor(AppColors.card).borderRadius(8)
              .border({ width: 1, color: AppColors.border })
              .padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder)
              .onChange((v: string) => { this.sofa = parseFloat(v) || 0; this.calculate(); });
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 10 });

        Column() {
          Text('合并症数量').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
          Row() {
            OptionChip({ label: '0-1 种', selected: this.comorb === 0, fontSize: 14, bold: true, chipHeight: AppDimens.inputHeight, onChipClick: () => { this.comorb = 0; this.calculate(); } }).layoutWeight(1).margin({ right: 4 });
            OptionChip({ label: '≥ 2 种', selected: this.comorb === 1, fontSize: 14, bold: true, chipHeight: AppDimens.inputHeight, onChipClick: () => { this.comorb = 1; this.calculate(); } }).layoutWeight(1).margin({ left: 4 });
          }.width('100%');
        }.width('100%').margin({ bottom: 10 });

        Column() {
          Text('住院→ICU 天数').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
          Row() {
            OptionChip({ label: '直接入ICU', selected: this.icuDay === 0, fontSize: 14, bold: true, chipHeight: AppDimens.inputHeight, onChipClick: () => { this.icuDay = 0; this.calculate(); } }).layoutWeight(1).margin({ right: 4 });
            OptionChip({ label: '≥ 1 天后', selected: this.icuDay === 1, fontSize: 14, bold: true, chipHeight: AppDimens.inputHeight, onChipClick: () => { this.icuDay = 1; this.calculate(); } }).layoutWeight(1).margin({ left: 4 });
          }.width('100%');
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'mNUTRIC', value: this.result!.value, unit: this.result!.unit, decimals: 0, valueMarginTop: 4, tierMarginTop: 4, titleMedium: false, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
