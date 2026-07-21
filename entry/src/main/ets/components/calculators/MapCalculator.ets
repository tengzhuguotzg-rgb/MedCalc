import { CalcResult } from '../../engine/CalcEngine';
import { calculateMap } from '../../engine/MapCalculator';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, ResetButton, ResultCard } from './widgets/CalcWidgets';

@Component
export struct MapCalculator {
  @State resetKey: number = 0;  @State sbp: number = 0;
  @State dbp: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateMap(this.sbp, this.dbp); }

  reset() {
    this.sbp = 0;
    this.dbp = 0;
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
      Column() { Text('用于计算平均动脉压，指导休克复苏').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('MAP = 舒张压 + 1/3脉压差，SSC目标≥65mmHg').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        Row() { Text('— 输入参数').fontSize(12).fontColor(AppColors.textSecondary).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); ResetButton({ onReset: () => { this.reset(); } }) }.width('100%').margin({ bottom: 12 });
        Row() {
          InputRow({ label: '收缩压 SBP (mmHg)', placeholder: '请输入SBP', onTextChange: (value: string) => { this.sbp = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '舒张压 DBP (mmHg)', placeholder: '请输入DBP', onTextChange: (value: string) => { this.dbp = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'MAP', value: this.result!.value, unit: this.result!.unit, decimals: 1, trimZero: true, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
