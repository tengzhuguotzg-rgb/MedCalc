import { CalcResult , getTierColor, getTierBgColor } from '../../engine/CalcEngine';
import { calculateWells } from '../../engine/WellsCalculator';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';

@Component
export struct WellsCalculator {
  @State resetKey: number = 0;  @State clinical: number = -1;
  @State hr: number = -1;
  @State surgery: number = -1;
  @State hemoptysis: number = -1;
  @State cancer: number = -1;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    if (this.clinical < 0 || this.hr < 0 || this.surgery < 0 || this.hemoptysis < 0 || this.cancer < 0) {
      this.result = { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
      return;
    }
    this.result = calculateWells(this.clinical === 1, this.hr === 1, this.surgery === 1, this.hemoptysis === 1, this.cancer === 1);
  }

  reset() {
    this.clinical = -1;
    this.hr = -1;
    this.surgery = -1;
    this.hemoptysis = -1;
    this.cancer = -1;
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
      Column() { Text('用于评估肺栓塞临床概率，指导D-二聚体解读').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('7项：DVT症状+PE主诊断+心率+制动+咯血+肿瘤+其他').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Row() { Text('— 输入参数').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });

        Row() { Text('深静脉血栓临床表现').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.clinical === 0 ? AppColors.card : AppColors.textOption).backgroundColor(this.clinical === 0 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.clinical === 0 ? AppColors.primary : AppColors.border }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.clinical = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.clinical === 1 ? AppColors.card : AppColors.textOption).backgroundColor(this.clinical === 1 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.clinical === 1 ? AppColors.primary : AppColors.border }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.clinical = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('心率>100次/分').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.hr === 0 ? AppColors.card : AppColors.textOption).backgroundColor(this.hr === 0 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.hr === 0 ? AppColors.primary : AppColors.border }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.hr = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.hr === 1 ? AppColors.card : AppColors.textOption).backgroundColor(this.hr === 1 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.hr === 1 ? AppColors.primary : AppColors.border }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.hr = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('近期手术或制动').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.surgery === 0 ? AppColors.card : AppColors.textOption).backgroundColor(this.surgery === 0 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.surgery === 0 ? AppColors.primary : AppColors.border }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.surgery = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.surgery === 1 ? AppColors.card : AppColors.textOption).backgroundColor(this.surgery === 1 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.surgery === 1 ? AppColors.primary : AppColors.border }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.surgery = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('咯血').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.hemoptysis === 0 ? AppColors.card : AppColors.textOption).backgroundColor(this.hemoptysis === 0 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.hemoptysis === 0 ? AppColors.primary : AppColors.border }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.hemoptysis = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.hemoptysis === 1 ? AppColors.card : AppColors.textOption).backgroundColor(this.hemoptysis === 1 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.hemoptysis === 1 ? AppColors.primary : AppColors.border }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.hemoptysis = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('活动性癌症').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.cancer === 0 ? AppColors.card : AppColors.textOption).backgroundColor(this.cancer === 0 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.cancer === 0 ? AppColors.primary : AppColors.border }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.cancer = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.cancer === 1 ? AppColors.card : AppColors.textOption).backgroundColor(this.cancer === 1 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.cancer === 1 ? AppColors.primary : AppColors.border }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.cancer = 1; this.calculate(); });
          }.width(100);
        }.width('100%');
      }.padding(AppDimens.cardPadding).backgroundColor(AppColors.card).borderRadius(AppDimens.cardRadius).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() { Text('WELLS').fontSize(12).fontColor(AppColors.textSecondary).letterSpacing(1.5).fontWeight(FontWeight.Medium);
              Text(this.result!.value !== null ? `${this.result!.value!.toFixed(1)} ${this.result!.unit}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor(AppColors.primary).margin({ top: 8 });
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
