import { CalcResult } from '../../engine/CalcEngine';
import { calculateParkland } from '../../engine/Batch3aCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct ParklandCalculator {
  @State resetKey: number = 0;
  @State weight: number = 0;
  @State tbsa: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateParkland(this.weight, this.tbsa); }

  reset() {
    this.weight = 0;
    this.tbsa = 0;
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
        Text('Parkland 烧伤补液公式').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('4 mL × kg × %TBSA，前 8h 输一半（自受伤时刻起算）').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '输入参数', resetAction: () => { this.reset(); } })
        Row() {
          InputRow({ label: '体重 (kg)', placeholder: 'kg', onTextChange: (value: string) => { this.weight = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '烧伤面积 TBSA (%)', placeholder: '%', onTextChange: (value: string) => { this.tbsa = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%');
        Text('TBSA 九分法：头颈9%、每上肢9%、躯干前/后各18%、每下肢18%、会阴1%；仅计 II° 及以上烧伤').fontSize(11).fontColor(AppColors.textSecondary).margin({ top: 6 });
      }

      if (this.result) {
        ResultCard({ title: 'Parkland 24h 总量', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
