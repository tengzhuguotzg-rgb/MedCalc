import { CalcResult } from '../../engine/CalcEngine';
import { calculateAbc2 } from '../../engine/Batch2aCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct Abc2Calculator {
  @State resetKey: number = 0;
  @State a: number = 0;
  @State b: number = 0;
  @State c: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateAbc2(this.a, this.b, this.c); }

  reset() {
    this.a = 0;
    this.b = 0;
    this.c = 0;
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
        Text('ABC/2：脑出血体积快速估计').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('A×B×C/2，>60 mL 常需神经外科评估').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: 'CT 测量', resetAction: () => { this.reset(); } })
        Row() {
          InputRow({ label: 'A 最大直径 (cm)', placeholder: 'A', onTextChange: (value: string) => { this.a = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: 'B 垂直直径 (cm)', placeholder: 'B', onTextChange: (value: string) => { this.b = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        InputRow({ label: 'C 头尾径 (cm)', placeholder: '层面数×层厚', onTextChange: (value: string) => { this.c = parseFloat(value) || 0; this.calculate(); } });
        Text('A=最大层面血肿最长径；B=同层与 A 垂直最长径；C=出血层面数×层厚（cm）').fontSize(11).fontColor(AppColors.textSecondary).margin({ top: 6 });
      }

      if (this.result) {
        ResultCard({ title: '血肿体积', value: this.result!.value, unit: this.result!.unit, decimals: 1, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
