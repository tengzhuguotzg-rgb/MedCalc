import { CalcResult } from '../../engine/CalcEngine';
import { calculateSteroid } from '../../engine/Batch3aCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct SteroidCalculator {
  @State resetKey: number = 0;
  @State drug: string = 'prednisone';
  @State dose: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateSteroid(this.drug, this.dose); }

  reset() {
    this.drug = 'prednisone';
    this.dose = 0;
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
        Text('糖皮质激素等效剂量换算').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('按抗炎效价换算为泼尼松当量及各药等效剂量').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '当前用药', resetAction: () => { this.reset(); } })
        Row({ space: 8 }) {
          OptionChip({ label: '泼尼松', selected: this.drug === 'prednisone', onChipClick: () => { this.drug = 'prednisone'; this.calculate(); } });
          OptionChip({ label: '泼尼松龙', selected: this.drug === 'prednisolone', onChipClick: () => { this.drug = 'prednisolone'; this.calculate(); } });
          OptionChip({ label: '甲泼尼龙', selected: this.drug === 'methylpred', onChipClick: () => { this.drug = 'methylpred'; this.calculate(); } });
          OptionChip({ label: '氢化可的松', selected: this.drug === 'hydrocortisone', onChipClick: () => { this.drug = 'hydrocortisone'; this.calculate(); } });
        }.width('100%').margin({ bottom: 8 });
        Row({ space: 8 }) {
          OptionChip({ label: '可的松', selected: this.drug === 'cortisone', onChipClick: () => { this.drug = 'cortisone'; this.calculate(); } });
          OptionChip({ label: '曲安西龙', selected: this.drug === 'triamcinolone', onChipClick: () => { this.drug = 'triamcinolone'; this.calculate(); } });
          OptionChip({ label: '地塞米松', selected: this.drug === 'dexamethasone', onChipClick: () => { this.drug = 'dexamethasone'; this.calculate(); } });
          OptionChip({ label: '倍他米松', selected: this.drug === 'betamethasone', onChipClick: () => { this.drug = 'betamethasone'; this.calculate(); } });
        }.width('100%').margin({ bottom: 8 });
        InputRow({ label: '日剂量 (mg)', placeholder: 'mg', onTextChange: (value: string) => { this.dose = parseFloat(value) || 0; this.calculate(); } });
      }

      if (this.result) {
        ResultCard({ title: '泼尼松当量', value: this.result!.value, unit: this.result!.unit, decimals: 1, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding({ left: 16, right: 16, top: 8, bottom: 16 }).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
