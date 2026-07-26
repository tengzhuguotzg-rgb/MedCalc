import { CalcResult } from '../../engine/CalcEngine';
import { calculateQtc } from '../../engine/Batch3aCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct QtcCalculator {
  @State resetKey: number = 0;
  @State qtMs: number = 0;
  @State hr: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateQtc(this.qtMs, this.hr); }

  reset() {
    this.qtMs = 0;
    this.hr = 0;
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
        Text('QTc 校正（Bazett 为主，附三种公式）').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('≥500 ms 尖端扭转风险显著升高').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '输入参数', resetAction: () => { this.reset(); } })
        Row() {
          InputRow({ label: 'QT 间期 (ms)', placeholder: 'QT', onTextChange: (value: string) => { this.qtMs = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '心率 (次/分)', placeholder: 'HR', onTextChange: (value: string) => { this.hr = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'QTc (Bazett)', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
