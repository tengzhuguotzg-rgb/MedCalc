import { CalcResult } from '../../engine/CalcEngine';
import { calculateAgeAdjustedDdimer } from '../../engine/Batch2aCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct DdimerAgeCalculator {
  @State resetKey: number = 0;
  @State age: number = 0;
  @State ddimer: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateAgeAdjustedDdimer(this.age, this.ddimer); }

  reset() {
    this.age = 0;
    this.ddimer = 0;
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
        Text('年龄校正 D-二聚体：VTE 排除阈值').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('年龄>50 时阈值 = 年龄×10 ng/mL FEU').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '输入参数', resetAction: () => { this.reset(); } })
        Row() {
          InputRow({ label: '年龄 (岁)', placeholder: '年龄', onTextChange: (value: string) => { this.age = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: 'D-二聚体 (mg/L FEU)', placeholder: 'D-dimer', onTextChange: (value: string) => { this.ddimer = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%');
        Text('仅用于验前概率低/中患者；DDU 单位需先换算（1 mg/L FEU ≈ 0.5 mg/L DDU）').fontSize(11).fontColor(AppColors.textSecondary).margin({ top: 6 });
      }

      if (this.result) {
        ResultCard({ title: '校正阈值', value: this.result!.value, unit: this.result!.unit, decimals: 2, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding({ left: 16, right: 16, top: 8, bottom: 16 }).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
