import { CalcResult } from '../../engine/CalcEngine';
import { calculateLactateClearance } from '../../engine/Batch2aCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct LactateClearanceCalculator {
  @State resetKey: number = 0;
  @State lac0: number = 0;
  @State lac1: number = 0;
  @State hours: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateLactateClearance(this.lac0, this.lac1, this.hours); }

  reset() {
    this.lac0 = 0;
    this.lac1 = 0;
    this.hours = 0;
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
        Text('乳酸清除率：复苏反应动态评估').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('≥10%（常按 6h）提示清除良好').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '输入参数', resetAction: () => { this.reset(); } })
        Row() {
          InputRow({ label: '初始乳酸 (mmol/L)', placeholder: 'Lac₀', onTextChange: (value: string) => { this.lac0 = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '复查乳酸 (mmol/L)', placeholder: 'Lac₁', onTextChange: (value: string) => { this.lac1 = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        InputRow({ label: '间隔时间 (h，可空)', placeholder: '如 6', onTextChange: (value: string) => { this.hours = parseFloat(value) || 0; this.calculate(); } });
      }

      if (this.result) {
        ResultCard({ title: '乳酸清除率', value: this.result!.value, unit: this.result!.unit, decimals: 1, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding({ left: 16, right: 16, top: 8, bottom: 16 }).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
