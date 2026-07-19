import { CalcResult , getTierColor, getTierBgColor } from '../../engine/CalcEngine';
import { calculateMap } from '../../engine/MapCalculator';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';

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

      Column() {
        Row() { Text('— 输入参数').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });
        Row() {
          Column() {
            Text('收缩压 SBP (mmHg)').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 });
            TextInput({ placeholder: '请输入SBP' }).type(InputType.Number).height(AppDimens.inputHeight).fontSize(16).fontColor(AppColors.textPrimary)
              .placeholderColor(AppColors.placeholder).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border })
              .padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.sbp = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1);
          Column() {
            Text('舒张压 DBP (mmHg)').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 });
            TextInput({ placeholder: '请输入DBP' }).type(InputType.Number).height(AppDimens.inputHeight).fontSize(16).fontColor(AppColors.textPrimary)
              .placeholderColor(AppColors.placeholder).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border })
              .padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.dbp = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1).margin({ left: 12 });
        }.width('100%');
      }.padding(AppDimens.cardPadding).backgroundColor(AppColors.card).borderRadius(AppDimens.cardRadius).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() {
              Text('MAP').fontSize(12).fontColor(AppColors.textSecondary).letterSpacing(1.5).fontWeight(FontWeight.Medium);
              Text(this.result!.value !== null ? `${this.result!.value!.toFixed(1).replace(/\.0$/, '')} ${this.result!.unit}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor(AppColors.primary).margin({ top: 8 });
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
