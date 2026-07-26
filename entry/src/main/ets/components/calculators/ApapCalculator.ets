import { CalcResult } from '../../engine/CalcEngine';
import { calculateApapNomogram } from '../../engine/Batch3aCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct ApapCalculator {
  @State resetKey: number = 0;
  @State hours: number = 0;
  @State level: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateApapNomogram(this.hours, this.level); }

  reset() {
    this.hours = 0;
    this.level = 0;
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
        Text('对乙酰氨基酚：Rumack-Matthew 列线图核对').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('仅适用摄入时间明确的单次急性摄入（4-24h）').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '输入参数', resetAction: () => { this.reset(); } })
        Row() {
          InputRow({ label: '摄入后时间 (h)', placeholder: '4-24', onTextChange: (value: string) => { this.hours = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '血药浓度 (mg/L)', placeholder: 'μg/mL 同值', onTextChange: (value: string) => { this.level = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%');
        Text('按 150 治疗线；缓释剂型/反复超量/时间不确定者按高危处理，勿仅凭本结果排除').fontSize(11).fontColor(AppColors.textSecondary).margin({ top: 6 });
      }

      if (this.result) {
        ResultCard({ title: '列线图核对', value: this.result!.value, unit: this.result!.unit, decimals: 1, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
