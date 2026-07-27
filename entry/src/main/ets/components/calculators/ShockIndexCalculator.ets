import { CalcResult } from '../../engine/CalcEngine';
import { calculateShockIndex } from '../../engine/Batch1aCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct ShockIndexCalculator {
  @State resetKey: number = 0;
  @State hr: number = 0;
  @State sbp: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateShockIndex(this.hr, this.sbp); }

  reset() {
    this.hr = 0;
    this.sbp = 0;
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
        Text('用于快速识别隐匿性休克/循环失代偿').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('Shock Index = HR/SBP，≥0.9 需警惕').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '输入参数', resetAction: () => { this.reset(); } })
        Row() {
          InputRow({ label: '心率 HR (次/分)', placeholder: 'HR', onTextChange: (value: string) => { this.hr = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '收缩压 SBP (mmHg)', placeholder: 'SBP', onTextChange: (value: string) => { this.sbp = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'Shock Index', value: this.result!.value, unit: this.result!.unit, decimals: 2, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding({ left: 16, right: 16, top: 8, bottom: 16 }).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
