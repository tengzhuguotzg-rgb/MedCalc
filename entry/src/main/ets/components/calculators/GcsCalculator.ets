import { CalcResult , getTierColor, getTierBgColor } from '../../engine/CalcEngine';
import { calculateGcs } from '../../engine/GcsCalculator';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';

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

      Column() {
        Row() { Text('— 输入参数').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });

        Column() {
          Text('睁眼反应 E').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 8 });
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(['4自动', '3呼唤', '2刺激', '1无'], (item: string) => {
              Button(item).fontSize(13).fontWeight(FontWeight.Medium).fontColor(this.eye === parseInt(item[0]) ? AppColors.card : AppColors.textOption)
                .backgroundColor(this.eye === parseInt(item[0]) ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.eye === parseInt(item[0]) ? AppColors.primary : AppColors.border })
                .borderRadius(8).height(AppDimens.touchTarget).margin({ right: 8, bottom: 8 }).onClick(() => { this.eye = parseInt(item[0]); this.calculate(); });
            });
          }.width('100%');
        }.width('100%').margin({ bottom: 16 });

        Column() {
          Text('语言反应 V').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 8 });
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(['5正常', '4含糊', '3吐词', '2发音', '1无'], (item: string) => {
              Button(item).fontSize(13).fontWeight(FontWeight.Medium).fontColor(this.verbal === parseInt(item[0]) ? AppColors.card : AppColors.textOption)
                .backgroundColor(this.verbal === parseInt(item[0]) ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.verbal === parseInt(item[0]) ? AppColors.primary : AppColors.border })
                .borderRadius(8).height(AppDimens.touchTarget).margin({ right: 8, bottom: 8 }).onClick(() => { this.verbal = parseInt(item[0]); this.calculate(); });
            });
          }.width('100%');
        }.width('100%').margin({ bottom: 16 });

        Column() {
          Text('运动反应 M').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 8 });
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(['6遵嘱', '5定位', '4退缩', '3屈曲', '2伸直', '1无'], (item: string) => {
              Button(item).fontSize(13).fontWeight(FontWeight.Medium).fontColor(this.motor === parseInt(item[0]) ? AppColors.card : AppColors.textOption)
                .backgroundColor(this.motor === parseInt(item[0]) ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.motor === parseInt(item[0]) ? AppColors.primary : AppColors.border })
                .borderRadius(8).height(AppDimens.touchTarget).margin({ right: 8, bottom: 8 }).onClick(() => { this.motor = parseInt(item[0]); this.calculate(); });
            });
          }.width('100%');
        }.width('100%');
      }.padding(AppDimens.cardPadding).backgroundColor(AppColors.card).borderRadius(AppDimens.cardRadius).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() {
              Text('GCS').fontSize(12).fontColor(AppColors.textSecondary).letterSpacing(1.5).fontWeight(FontWeight.Medium);
              Text(this.result!.value !== null ? `${this.result!.value!.toFixed(0)} ${this.result!.unit}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor(AppColors.primary).margin({ top: 8 });
              Text(this.result!.tier).fontSize(13).fontWeight(FontWeight.Bold).fontColor(getTierColor(this.result!.tierClass))
                .backgroundColor(getTierBgColor(this.result!.tierClass)).borderRadius(20).padding({ left: 12, right: 12, top: 4, bottom: 4 }).margin({ top: 8 });
            }.alignItems(HorizontalAlign.Start).layoutWeight(1);
            Column() { Text(this.result!.footnote).fontSize(14).fontColor(AppColors.textBody).lineHeight(22); }.layoutWeight(1).alignItems(HorizontalAlign.Start);
          }.width('100%');
        }.padding(AppDimens.cardPadding).backgroundColor(AppColors.card).borderRadius(AppDimens.cardRadius).width('100%');
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
