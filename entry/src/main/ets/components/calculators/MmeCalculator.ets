import { CalcResult } from '../../engine/CalcEngine';
import { calculateMme } from '../../engine/Batch3aCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct MmeCalculator {
  @State resetKey: number = 0;
  @State morphine: number = 0;
  @State oxycodone: number = 0;
  @State hydrocodone: number = 0;
  @State hydromorphone: number = 0;
  @State tramadol: number = 0;
  @State fentanylPatch: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateMme(this.morphine, this.oxycodone, this.hydrocodone, this.hydromorphone, this.tramadol, this.fentanylPatch); }

  reset() {
    this.morphine = 0;
    this.oxycodone = 0;
    this.hydrocodone = 0;
    this.hydromorphone = 0;
    this.tramadol = 0;
    this.fentanylPatch = 0;
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
        Text('MME 口服吗啡当量（CDC 2022）').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('日剂量 mg/日，未用药物留 0；≥90 MME 高风险').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '日剂量 (mg/日)', resetAction: () => { this.reset(); } })
        Row() {
          InputRow({ label: '吗啡', placeholder: '0', onTextChange: (value: string) => { this.morphine = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '羟考酮', placeholder: '0', onTextChange: (value: string) => { this.oxycodone = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        Row() {
          InputRow({ label: '氢可酮', placeholder: '0', onTextChange: (value: string) => { this.hydrocodone = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '氢吗啡酮', placeholder: '0', onTextChange: (value: string) => { this.hydromorphone = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        Row() {
          InputRow({ label: '曲马多', placeholder: '0', onTextChange: (value: string) => { this.tramadol = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '芬太尼贴剂 (mcg/hr)', placeholder: '0', onTextChange: (value: string) => { this.fentanylPatch = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%');
        Text('美沙酮转换为非线性，未纳入；MME 不用于患者间直接剂量转换').fontSize(11).fontColor(AppColors.textSecondary).margin({ top: 6 });
      }

      if (this.result) {
        ResultCard({ title: 'MME', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
