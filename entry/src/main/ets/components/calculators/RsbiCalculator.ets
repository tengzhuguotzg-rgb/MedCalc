import { CalcResult } from '../../engine/CalcEngine';
import { calculateRsbi } from '../../engine/Batch1aCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct RsbiCalculator {
  @State resetKey: number = 0;
  @State rr: number = 0;
  @State vtMl: number = 0;
  @State sbtStatus: string = 'unknown';
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateRsbi(this.rr, this.vtMl, this.sbtStatus); }

  reset() {
    this.rr = 0;
    this.vtMl = 0;
    this.sbtStatus = 'unknown';
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
        Text('用于撤机/自主呼吸试验浅快呼吸评估').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('RSBI = RR/VT(L)，>105 提示撤机失败风险高').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '输入参数', resetAction: () => { this.reset(); } })
        Row() {
          InputRow({ label: '呼吸频率 RR (次/分)', placeholder: 'RR', onTextChange: (value: string) => { this.rr = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '潮气量 VT (mL)', placeholder: 'VT mL', onTextChange: (value: string) => { this.vtMl = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });

        Text('呼吸状态').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row({ space: 8 }) {
          OptionChip({ label: '机械通气', selected: this.sbtStatus === 'vent', onChipClick: () => { this.sbtStatus = 'vent'; this.calculate(); } });
          OptionChip({ label: '自主呼吸', selected: this.sbtStatus === 'spont', onChipClick: () => { this.sbtStatus = 'spont'; this.calculate(); } });
          OptionChip({ label: 'SBT', selected: this.sbtStatus === 'sbt', onChipClick: () => { this.sbtStatus = 'sbt'; this.calculate(); } });
          OptionChip({ label: '未填', selected: this.sbtStatus === 'unknown', onChipClick: () => { this.sbtStatus = 'unknown'; this.calculate(); } });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'RSBI', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
