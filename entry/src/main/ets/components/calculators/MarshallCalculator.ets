import { CalcResult } from '../../engine/CalcEngine';
import { calculateMarshall } from '../../engine/MarshallCalculator';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard } from './widgets/CalcWidgets';

@Component
export struct MarshallCalculator {
  @State resetKey: number = 0;  @State pao2: number = 0;
  @State fio2: number = 0;
  @State fio2Mode: string = 'dec';
  @State peep: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    const fio2 = this.fio2Mode === 'pct' ? this.fio2 / 100 : this.fio2;
    this.result = calculateMarshall(this.pao2, fio2, this.peep);
  }

  reset() {
    this.pao2 = 0;
    this.fio2 = 0;
    this.fio2Mode = 'dec';
    this.peep = 0;
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
      Column() { Text('用于评估ARDS严重程度').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('基于P/F比值和PEEP水平分级').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        Row() { Text('— 输入参数').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });

        Row() {
          InputRow({ label: 'PaO₂ (mmHg)', placeholder: '请输入PaO2', onTextChange: (value: string) => { this.pao2 = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: 'FiO₂', placeholder: this.fio2Mode === 'dec' ? '小数' : '百分比', inputType: InputType.NUMBER_DECIMAL, onTextChange: (value: string) => { this.fio2 = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 16 });

        Row() {
          OptionChip({ label: '小数', selected: this.fio2Mode === 'dec', fontSize: 12, bold: true, onChipClick: () => { this.fio2Mode = 'dec'; this.calculate(); } }).layoutWeight(1);
          OptionChip({ label: '百分比', selected: this.fio2Mode === 'pct', fontSize: 12, bold: true, onChipClick: () => { this.fio2Mode = 'pct'; this.calculate(); } }).layoutWeight(1);
        }.width('100%').margin({ bottom: 16 });

        InputRow({ label: 'PEEP (cmH₂O)', placeholder: '请输入PEEP', onTextChange: (value: string) => { this.peep = parseFloat(value) || 0; this.calculate(); } }).width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'Marshall', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
