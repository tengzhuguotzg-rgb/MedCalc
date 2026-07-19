import { CalcResult , getTierColor, getTierBgColor } from '../../engine/CalcEngine';
import { calculateSf } from '../../engine/SfCalculator';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';

@Component
export struct SfCalculator {
  @State resetKey: number = 0;  @State spo2: number = 0;
  @State fio2: number = 0;
  @State fio2Mode: string = 'dec';
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateSf(this.spo2, this.fio2, this.fio2Mode); }

  reset() {
    this.spo2 = 0;
    this.fio2 = 0;
    this.fio2Mode = 'dec';
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
      Column() { Text('用于无动脉血气时床旁ARDS筛查').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('SpO₂/FiO₂比值替代P/F，无需动脉血气').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Row() { Text('— 输入参数').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });
        
        Row() {
          Column() {
            Text('SpO₂ (%)').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 });
            TextInput({ placeholder: '请输入SpO2' }).type(InputType.Number).height(AppDimens.inputHeight).fontSize(16).fontColor(AppColors.textPrimary)
              .placeholderColor(AppColors.placeholder).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border })
              .padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.spo2 = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1);
          Column() {
            Text('FiO₂').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 });
            TextInput({ placeholder: this.fio2Mode === 'dec' ? '小数(0.21-1.0)' : '百分比(21-100)' }).type(InputType.NUMBER_DECIMAL).height(AppDimens.inputHeight).fontSize(16).fontColor(AppColors.textPrimary)
              .placeholderColor(AppColors.placeholder).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border })
              .padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.fio2 = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 16 });

        Row() {
          Button('小数').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.fio2Mode === 'dec' ? AppColors.card : AppColors.textOption)
            .backgroundColor(this.fio2Mode === 'dec' ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.fio2Mode === 'dec' ? AppColors.primary : AppColors.border })
            .borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.fio2Mode = 'dec'; this.calculate(); });
          Button('百分比').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.fio2Mode === 'pct' ? AppColors.card : AppColors.textOption)
            .backgroundColor(this.fio2Mode === 'pct' ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.fio2Mode === 'pct' ? AppColors.primary : AppColors.border })
            .borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.fio2Mode = 'pct'; this.calculate(); });
        }.width('100%');
      }.padding(AppDimens.cardPadding).backgroundColor(AppColors.card).borderRadius(AppDimens.cardRadius).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() {
              Text('S/F').fontSize(12).fontColor(AppColors.textSecondary).letterSpacing(1.5).fontWeight(FontWeight.Medium);
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
