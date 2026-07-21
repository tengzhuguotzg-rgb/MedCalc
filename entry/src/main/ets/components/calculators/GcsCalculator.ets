import { CalcResult } from '../../engine/CalcEngine';
import { calculateGcs } from '../../engine/GcsCalculator';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, OptionChip, ResetButton, ResultCard } from './widgets/CalcWidgets';

@Component
export struct GcsCalculator {
  @State resetKey: number = 0;  @State eye: number = 0;
  @State verbal: number = 0;
  @State motor: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateGcs(this.eye, this.verbal, this.motor); }

  reset() {
    this.eye = 0;
    this.verbal = 0;
    this.motor = 0;
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
      Column() { Text('用于评估意识障碍程度').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('3维度：睁眼(E)+语言(V)+运动(M)，总分3-15，≤8重度').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        Row() { Text('— 输入参数').fontSize(12).fontColor(AppColors.textSecondary).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); ResetButton({ onReset: () => { this.reset(); } }) }.width('100%').margin({ bottom: 12 });

        Column() {
          Text('睁眼反应 E').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 8 });
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(['4自动', '3呼唤', '2刺激', '1无'], (item: string) => {
              OptionChip({ label: item, selected: this.eye === parseInt(item[0]), onChipClick: () => { this.eye = parseInt(item[0]); this.calculate(); } }).margin({ right: 8, bottom: 8 });
            });
          }.width('100%');
        }.width('100%').margin({ bottom: 16 });

        Column() {
          Text('语言反应 V').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 8 });
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(['5正常', '4含糊', '3吐词', '2发音', '1无'], (item: string) => {
              OptionChip({ label: item, selected: this.verbal === parseInt(item[0]), onChipClick: () => { this.verbal = parseInt(item[0]); this.calculate(); } }).margin({ right: 8, bottom: 8 });
            });
          }.width('100%');
        }.width('100%').margin({ bottom: 16 });

        Column() {
          Text('运动反应 M').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 8 });
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(['6遵嘱', '5定位', '4退缩', '3屈曲', '2伸直', '1无'], (item: string) => {
              OptionChip({ label: item, selected: this.motor === parseInt(item[0]), onChipClick: () => { this.motor = parseInt(item[0]); this.calculate(); } }).margin({ right: 8, bottom: 8 });
            });
          }.width('100%');
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'GCS', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
