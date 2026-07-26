import { CalcResult } from '../../engine/CalcEngine';
import { calculateAdhere } from '../../engine/Batch2aCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct AdhereCalculator {
  @State resetKey: number = 0;
  @State bun: number = 0;
  @State bunUnit: string = 'mmol';
  @State sbp: number = 0;
  @State cr: number = 0;
  @State crUnit: string = 'umol';
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    const bunMgDl = this.bunUnit === 'mmol' ? this.bun * 2.8 : this.bun;
    const crMgDl = this.crUnit === 'umol' ? this.cr / 88.4 : this.cr;
    this.result = calculateAdhere(bunMgDl, this.sbp, crMgDl);
  }

  reset() {
    this.bun = 0;
    this.bunUnit = 'mmol';
    this.sbp = 0;
    this.cr = 0;
    this.crUnit = 'umol';
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
        Text('ADHERE：急性心衰住院死亡风险树').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('三个高危因子：BUN≥43 mg/dL、SBP<115、Cr≥2.75 mg/dL').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
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
        InputRow({ label: '收缩压 SBP (mmHg)', placeholder: 'SBP', onTextChange: (value: string) => { this.sbp = parseFloat(value) || 0; this.calculate(); } }).margin({ bottom: 8 });
        Row() {
          InputRow({ label: '肌酐', placeholder: 'Cr', onTextChange: (value: string) => { this.cr = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          Column() {
            Text('单位').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            Row({ space: 8 }) {
              OptionChip({ label: 'μmol/L', selected: this.crUnit === 'umol', chipHeight: AppDimens.inputHeight, onChipClick: () => { this.crUnit = 'umol'; this.calculate(); } });
              OptionChip({ label: 'mg/dL', selected: this.crUnit === 'mgdl', chipHeight: AppDimens.inputHeight, onChipClick: () => { this.crUnit = 'mgdl'; this.calculate(); } });
            }
          }.layoutWeight(1).margin({ left: 12 });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'ADHERE 风险', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
