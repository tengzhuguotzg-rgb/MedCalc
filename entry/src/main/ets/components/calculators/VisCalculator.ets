import { CalcResult } from '../../engine/CalcEngine';
import { calculateVis } from '../../engine/Batch2aCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct VisCalculator {
  @State resetKey: number = 0;
  @State dopamine: number = 0;
  @State dobutamine: number = 0;
  @State epinephrine: number = 0;
  @State norepinephrine: number = 0;
  @State milrinone: number = 0;
  @State vasopressin: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateVis(this.dopamine, this.dobutamine, this.epinephrine, this.norepinephrine, this.milrinone, this.vasopressin); }

  reset() {
    this.dopamine = 0;
    this.dobutamine = 0;
    this.epinephrine = 0;
    this.norepinephrine = 0;
    this.milrinone = 0;
    this.vasopressin = 0;
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
        Text('VIS：血管活性-正性肌力药物负荷评分').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('剂量单位 μg/kg/min；未用药物留 0').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '药物剂量', resetAction: () => { this.reset(); } })
        Row() {
          InputRow({ label: '多巴胺', placeholder: '0', onTextChange: (value: string) => { this.dopamine = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '多巴酚丁胺', placeholder: '0', onTextChange: (value: string) => { this.dobutamine = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        Row() {
          InputRow({ label: '肾上腺素', placeholder: '0', onTextChange: (value: string) => { this.epinephrine = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '去甲肾上腺素', placeholder: '0', onTextChange: (value: string) => { this.norepinephrine = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        Row() {
          InputRow({ label: '米力农', placeholder: '0', onTextChange: (value: string) => { this.milrinone = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '血管加压素 (U/kg/min)', placeholder: '0', onTextChange: (value: string) => { this.vasopressin = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'VIS', value: this.result!.value, unit: this.result!.unit, decimals: 1, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
