import { CalcResult } from '../../engine/CalcEngine';
import { calculateBap65 } from '../../engine/Batch2bCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct Bap65Calculator {
  @State resetKey: number = 0;
  @State bun: number = 0;
  @State bunUnit: string = 'mmol';
  @State pulse: number = 0;
  @State age: number = 0;
  @State altered: boolean = false;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    const bunMgDl = this.bunUnit === 'mmol' ? this.bun * 2.8 : this.bun;
    this.result = calculateBap65(bunMgDl, this.pulse, this.age, this.altered);
  }

  reset() {
    this.bun = 0;
    this.bunUnit = 'mmol';
    this.pulse = 0;
    this.age = 0;
    this.altered = false;
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
        Text('BAP-65：慢阻肺急性加重（AECOPD）风险').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('BUN>25、意识改变、脉搏>109、年龄>65 各 1 分').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '输入参数', resetAction: () => { this.reset(); } })
        Row() {
          InputRow({ label: '尿素氮/尿素', placeholder: 'BUN', onTextChange: (value: string) => { this.bun = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          Column() {
            Text('单位').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            Row({ space: 8 }) {
              OptionChip({ label: 'mmol/L(尿素)', selected: this.bunUnit === 'mmol', chipHeight: AppDimens.inputHeight, onChipClick: () => { this.bunUnit = 'mmol'; this.calculate(); } });
              OptionChip({ label: 'mg/dL(BUN)', selected: this.bunUnit === 'mgdl', chipHeight: AppDimens.inputHeight, onChipClick: () => { this.bunUnit = 'mgdl'; this.calculate(); } });
            }
          }.layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        Row() {
          InputRow({ label: '脉搏 (次/分)', placeholder: 'HR', onTextChange: (value: string) => { this.pulse = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '年龄 (岁)', placeholder: '年龄', onTextChange: (value: string) => { this.age = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });

        Text('意识状态').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row({ space: 8 }) {
          OptionChip({ label: '清楚', selected: !this.altered, onChipClick: () => { this.altered = false; this.calculate(); } });
          OptionChip({ label: '意识改变', selected: this.altered, onChipClick: () => { this.altered = true; this.calculate(); } });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'BAP-65', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding({ left: 16, right: 16, top: 8, bottom: 16 }).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
