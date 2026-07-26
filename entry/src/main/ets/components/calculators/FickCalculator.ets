import { CalcResult } from '../../engine/CalcEngine';
import { calculateFick } from '../../engine/Batch3aCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct FickCalculator {
  @State resetKey: number = 0;
  @State hgb: number = 0;
  @State sao2: number = 0;
  @State svo2: number = 0;
  @State vo2: number = 0;
  @State heightCm: number = 0;
  @State weight: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateFick(this.hgb, this.sao2, this.svo2, this.vo2, this.heightCm, this.weight); }

  reset() {
    this.hgb = 0;
    this.sao2 = 0;
    this.svo2 = 0;
    this.vo2 = 0;
    this.heightCm = 0;
    this.weight = 0;
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
        Text('Fick 心排量').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('CO = VO₂ / (CaO₂ - CvO₂)；VO₂ 可留空按 125×BSA 估计').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '输入参数', resetAction: () => { this.reset(); } })
        Row() {
          InputRow({ label: '血红蛋白 (g/L)', placeholder: 'Hgb', onTextChange: (value: string) => { this.hgb = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: 'VO₂ (mL/min，可空)', placeholder: '留空估计', onTextChange: (value: string) => { this.vo2 = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        Row() {
          InputRow({ label: 'SaO₂ (%)', placeholder: '动脉', onTextChange: (value: string) => { this.sao2 = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: 'SvO₂ (%)', placeholder: '混合静脉', onTextChange: (value: string) => { this.svo2 = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        Row() {
          InputRow({ label: '身高 (cm)', placeholder: '估计VO₂用', onTextChange: (value: string) => { this.heightCm = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '体重 (kg)', placeholder: '估计VO₂用', onTextChange: (value: string) => { this.weight = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'Fick CO', value: this.result!.value, unit: this.result!.unit, decimals: 2, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
