import { CalcResult } from '../../engine/CalcEngine';
import { calculatePf } from '../../engine/CommonCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResetButton, ResultCard } from './widgets/CalcWidgets';

@Component
export struct PfCalculator {
  @State resetKey: number = 0;  @State pao2: number = 0;
  @State fio2: number = 0;
  @State fio2Mode: string = 'dec';
  @State peep: number | null = null;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculatePf(this.pao2, this.fio2, this.fio2Mode, this.peep); }

  reset() {
    this.pao2 = 0;
    this.fio2 = 0;
    this.fio2Mode = 'dec';
    this.peep = null;
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
      Column() { Text('用于评估氧合功能，ARDS诊断分级').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('PaO₂/FiO₂比值，Berlin 2012标准，需PEEP≥5').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        Row() { Text('— 输入参数').fontSize(12).fontColor(AppColors.textSecondary).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); ResetButton({ onReset: () => { this.reset(); } }) }.width('100%').margin({ bottom: 12 });

        Row() {
          InputRow({ label: 'PaO₂ (mmHg)', placeholder: '请输入PaO2', onTextChange: (value: string) => { this.pao2 = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: 'FiO₂', placeholder: this.fio2Mode === 'dec' ? '小数(0.21-1.0)' : '百分比(21-100)', inputType: InputType.NUMBER_DECIMAL, onTextChange: (value: string) => { this.fio2 = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 16 });

        Row() {
          OptionChip({ label: '小数', selected: this.fio2Mode === 'dec', fontSize: 12, bold: true, onChipClick: () => { this.fio2Mode = 'dec'; this.calculate(); } }).layoutWeight(1);
          OptionChip({ label: '百分比', selected: this.fio2Mode === 'pct', fontSize: 12, bold: true, onChipClick: () => { this.fio2Mode = 'pct'; this.calculate(); } }).layoutWeight(1);
        }.width('100%').margin({ bottom: 16 });

        InputRow({ label: 'PEEP (cmH₂O, 可选)', placeholder: '建议≥5, 未填则不评估', inputType: InputType.NUMBER_DECIMAL, onTextChange: (value: string) => { const v = parseFloat(value); this.peep = isNaN(v) ? null : v; this.calculate(); } }).width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'P/F', value: this.result!.value, unit: this.result!.unit, decimals: 1, trimZero: true, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
