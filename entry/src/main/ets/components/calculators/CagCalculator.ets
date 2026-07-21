import { CalcResult } from '../../engine/CalcEngine';
import { calculateCag } from '../../engine/MoreCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, ResetButton, ResultCard } from './widgets/CalcWidgets';

@Component
export struct CagCalculator {
  @State resetKey: number = 0;  @State na: number = 0;
  @State cl: number = 0;
  @State hco3: number = 0;
  @State alb: number = 0;
  @State albUnit: string = 'gl';
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateCag(this.na, this.cl, this.hco3, this.alb, this.albUnit); }

  reset() {
    this.na = 0;
    this.cl = 0;
    this.hco3 = 0;
    this.alb = 0;
    this.albUnit = 'gl';
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
        Text('用于校正低蛋白血症时的阴离子间隙')
          .fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('校正AG = 计算AG + 2.5×(4 - 白蛋白g/dL)，低蛋白时必校')
          .fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        Row() { Text('— 电解质').fontSize(12).fontColor(AppColors.textSecondary).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); ResetButton({ onReset: () => { this.reset(); } }) }.width('100%').margin({ bottom: 12 });
        Row() {
          Column() {
            Text('Na⁺ (mmol/L)').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            TextInput({ placeholder: 'Na' }).type(InputType.Number).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder)
              .onChange((value: string) => { this.na = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1);
          Column() {
            Text('Cl⁻ (mmol/L)').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            TextInput({ placeholder: 'Cl' }).type(InputType.Number).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder)
              .onChange((value: string) => { this.cl = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 8 });

        Column() {
          Text('HCO₃⁻ (mmol/L)').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
          TextInput({ placeholder: 'HCO3' }).type(InputType.Number).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder)
            .onChange((value: string) => { this.hco3 = parseFloat(value) || 0; this.calculate(); });
        }.width('100%').margin({ bottom: 8 });

        Column() {
          Text('血清白蛋白').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
          Row() {
            TextInput({ placeholder: '白蛋白' })
              .type(InputType.NUMBER_DECIMAL).height(AppDimens.inputHeight).fontSize(16)
              .backgroundColor(AppColors.card).borderRadius(8)
              .border({ width: 1, color: AppColors.border })
              .padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder)
              .layoutWeight(1)
              .onChange((value: string) => { this.alb = parseFloat(value) || 0; this.calculate(); });
            Row() {
              Button('g/L').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.albUnit === 'gl' ? AppColors.card : AppColors.textOption)
                .backgroundColor(this.albUnit === 'gl' ? AppColors.primary : AppColors.fillNeutral).borderRadius(8).border({ width: 1, color: this.albUnit === 'gl' ? AppColors.primary : AppColors.border })
                .onClick(() => { this.albUnit = 'gl'; this.calculate(); });
              Button('g/dL').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.albUnit === 'gdl' ? AppColors.card : AppColors.textOption)
                .backgroundColor(this.albUnit === 'gdl' ? AppColors.primary : AppColors.fillNeutral).borderRadius(8).border({ width: 1, color: this.albUnit === 'gdl' ? AppColors.primary : AppColors.border })
                .onClick(() => { this.albUnit = 'gdl'; this.calculate(); });
            }.margin({ left: 4 });
          }.width('100%');
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: '校正 AG', value: this.result!.value, unit: this.result!.unit, decimals: 1, valueMarginTop: 4, tierMarginTop: 4, titleMedium: false, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
