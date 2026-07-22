import { CalcResult } from '../../engine/CalcEngine';
import { calculateSf } from '../../engine/SfCalculator';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResetButton, ResultCard } from './widgets/CalcWidgets';

@Component
export struct SfCalculator {
  @State resetKey: number = 0;  @State spo2: number = 0;
  @State fio2: number = 0;
  @State fio2Mode: string = 'dec';
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateSf(this.spo2, this.fio2, this.fio2Mode); }

  reset() {
    this.spo2 = 0;
    this.fio2 = 0;
    this.fio2Mode = 'dec';
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
      Column() { Text('用于无动脉血气时床旁ARDS筛查').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('SpO₂/FiO₂比值替代P/F，无需动脉血气').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        Row() { Text('— 输入参数').fontSize(12).fontColor(AppColors.textSecondary).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); ResetButton({ onReset: () => { this.reset(); } }) }.width('100%').margin({ bottom: 12 });

        Row() {
          InputRow({ label: 'SpO₂ (%)', placeholder: '请输入SpO2', onTextChange: (value: string) => { this.spo2 = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: 'FiO₂', placeholder: this.fio2Mode === 'dec' ? '小数(0.21-1.0)' : '百分比(21-100)', inputType: InputType.NUMBER_DECIMAL, onTextChange: (value: string) => { this.fio2 = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 16 });

        Row() {
          OptionChip({ label: '小数', selected: this.fio2Mode === 'dec', fontSize: 12, bold: true, onChipClick: () => { this.fio2Mode = 'dec'; this.calculate(); } }).layoutWeight(1);
          OptionChip({ label: '百分比', selected: this.fio2Mode === 'pct', fontSize: 12, bold: true, onChipClick: () => { this.fio2Mode = 'pct'; this.calculate(); } }).layoutWeight(1);
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'S/F', value: this.result!.value, unit: this.result!.unit, decimals: 1, trimZero: true, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
