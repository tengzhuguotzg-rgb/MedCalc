import { CalcResult } from '../../engine/CalcEngine';
import { calculateRts } from '../../engine/Batch1aCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct RtsCalculator {
  @State resetKey: number = 0;
  @State gcs: number = 0;
  @State sbp: number = 0;
  @State rr: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateRts(this.gcs, this.sbp, this.rr); }

  reset() {
    this.gcs = 0;
    this.sbp = 0;
    this.rr = 0;
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
        Text('用于创伤分诊和创伤严重度评估').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('coded RTS 0-12；另在脚注显示 weighted RTS').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '输入参数', resetAction: () => { this.reset(); } })
        Row() {
          InputRow({ label: 'GCS (3-15)', placeholder: 'GCS', onTextChange: (value: string) => { this.gcs = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: 'SBP (mmHg)', placeholder: 'SBP', onTextChange: (value: string) => { this.sbp = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        InputRow({ label: '呼吸频率 RR (次/分)', placeholder: 'RR', onTextChange: (value: string) => { this.rr = parseFloat(value) || 0; this.calculate(); } }).width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'coded RTS', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
