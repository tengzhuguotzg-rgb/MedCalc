import { CalcResult } from '../../engine/CalcEngine';
import { calculateGoldAbe } from '../../engine/Batch2bCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct GoldAbeCalculator {
  @State resetKey: number = 0;
  @State mmrc: number = -1;
  @State cat: number = -1;
  @State exacCount: number = -1;
  @State exacHosp: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateGoldAbe(this.mmrc, this.cat, this.exacCount, this.exacHosp); }

  reset() {
    this.mmrc = -1;
    this.cat = -1;
    this.exacCount = -1;
    this.exacHosp = 0;
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
        Text('GOLD ABE：慢阻肺综合评估分组').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('症状（mMRC/CAT）× 急性加重风险 → A/B/E 组').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '输入参数', resetAction: () => { this.reset(); } })
        Row() {
          InputRow({ label: 'mMRC (0-4)', placeholder: '呼吸困难', onTextChange: (value: string) => { const v = parseFloat(value); this.mmrc = isNaN(v) ? -1 : v; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: 'CAT (0-40，可空)', placeholder: 'CAT', onTextChange: (value: string) => { const v = parseFloat(value); this.cat = isNaN(v) ? -1 : v; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        Row() {
          InputRow({ label: '年中度加重次数', placeholder: '0', onTextChange: (value: string) => { const v = parseFloat(value); this.exacCount = isNaN(v) ? -1 : v; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '其中住院次数', placeholder: '0', onTextChange: (value: string) => { this.exacHosp = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%');
        Text('mMRC≥2 或 CAT≥10 = 症状多；≥2 次中度加重或 ≥1 次住院加重 = 高风险（E 组）').fontSize(11).fontColor(AppColors.textSecondary).margin({ top: 6 });
      }

      if (this.result) {
        ResultCard({ title: 'GOLD 分组', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
