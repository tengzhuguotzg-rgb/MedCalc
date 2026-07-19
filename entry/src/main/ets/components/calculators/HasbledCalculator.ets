import { CalcResult , getTierColor, getTierBgColor } from '../../engine/CalcEngine';
import { calculateHasbled } from '../../engine/MoreCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';

@Component
export struct HasbledCalculator {
  @State resetKey: number = 0;  @State htn: number = -1;
  @State renal: number = -1;
  @State liver: number = -1;
  @State stroke: number = -1;
  @State bleed: number = -1;
  @State inr: number = -1;
  @State age: number = -1;
  @State drugs: number = -1;
  @State alcohol: number = -1;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    if (this.htn < 0 || this.renal < 0 || this.liver < 0 || this.stroke < 0 || this.bleed < 0 || this.inr < 0 || this.age < 0 || this.drugs < 0 || this.alcohol < 0) {
      this.result = { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
      return;
    }
    this.result = calculateHasbled(this.htn === 1, this.renal === 1, this.liver === 1, this.stroke === 1, this.bleed === 1, this.inr === 1, this.age === 1, this.drugs === 1, this.alcohol === 1);
  }

  reset() {
    this.htn = -1;
    this.renal = -1;
    this.liver = -1;
    this.stroke = -1;
    this.bleed = -1;
    this.inr = -1;
    this.age = -1;
    this.drugs = -1;
    this.alcohol = -1;
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
      Column() { Text('用于评估房颤患者抗凝治疗出血风险').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('7项：高血压+肾肝+卒中+出血+INR+年龄+药物/酒精，0-9分').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Row() { Text('— 输入参数').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('H 高血压').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.htn === 0 ? AppColors.card : '#2D5440').backgroundColor(this.htn === 0 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.htn === 0 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.htn = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.htn === 1 ? AppColors.card : '#2D5440').backgroundColor(this.htn === 1 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.htn === 1 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.htn = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('A 肾功能异常').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.renal === 0 ? AppColors.card : '#2D5440').backgroundColor(this.renal === 0 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.renal === 0 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.renal = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.renal === 1 ? AppColors.card : '#2D5440').backgroundColor(this.renal === 1 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.renal === 1 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.renal = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('A 肝功能异常').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.liver === 0 ? AppColors.card : '#2D5440').backgroundColor(this.liver === 0 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.liver === 0 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.liver = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.liver === 1 ? AppColors.card : '#2D5440').backgroundColor(this.liver === 1 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.liver === 1 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.liver = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('S 卒中史').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.stroke === 0 ? AppColors.card : '#2D5440').backgroundColor(this.stroke === 0 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.stroke === 0 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.stroke = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.stroke === 1 ? AppColors.card : '#2D5440').backgroundColor(this.stroke === 1 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.stroke === 1 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.stroke = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('B 出血史').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.bleed === 0 ? AppColors.card : '#2D5440').backgroundColor(this.bleed === 0 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.bleed === 0 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.bleed = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.bleed === 1 ? AppColors.card : '#2D5440').backgroundColor(this.bleed === 1 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.bleed === 1 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.bleed = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('L 不稳定 INR').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.inr === 0 ? AppColors.card : '#2D5440').backgroundColor(this.inr === 0 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.inr === 0 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.inr = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.inr === 1 ? AppColors.card : '#2D5440').backgroundColor(this.inr === 1 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.inr === 1 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.inr = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('E 年龄 ≥ 65 岁').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.age === 0 ? AppColors.card : '#2D5440').backgroundColor(this.age === 0 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.age === 0 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.age = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.age === 1 ? AppColors.card : '#2D5440').backgroundColor(this.age === 1 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.age === 1 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.age = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('D 药物').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.drugs === 0 ? AppColors.card : '#2D5440').backgroundColor(this.drugs === 0 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.drugs === 0 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.drugs = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.drugs === 1 ? AppColors.card : '#2D5440').backgroundColor(this.drugs === 1 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.drugs === 1 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.drugs = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('D 酒精').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.alcohol === 0 ? AppColors.card : '#2D5440').backgroundColor(this.alcohol === 0 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.alcohol === 0 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.alcohol = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.alcohol === 1 ? AppColors.card : '#2D5440').backgroundColor(this.alcohol === 1 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.alcohol === 1 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.alcohol = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
      }.padding(AppDimens.cardPadding).backgroundColor(AppColors.card).borderRadius(AppDimens.cardRadius).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() { Text('HAS-BLED 总分').fontSize(12).fontColor(AppColors.textSecondary).letterSpacing(1.5).fontWeight(FontWeight.Medium);
              Text(this.result!.value !== null ? `${this.result!.value!.toFixed(0)}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor(AppColors.primary).margin({ top: 8 });
              Text(this.result!.tier).fontSize(13).fontWeight(FontWeight.Bold).fontColor(getTierColor(this.result!.tierClass))
                .backgroundColor(getTierBgColor(this.result!.tierClass)).borderRadius(20).padding({ left: 12, right: 12, top: 4, bottom: 4 }).margin({ top: 8 });
            }.alignItems(HorizontalAlign.Start).layoutWeight(1);
            Column() { Text(this.result!.footnote).fontSize(14).fontColor('#4A5247').lineHeight(22); }.layoutWeight(1).alignItems(HorizontalAlign.Start);
          }.width('100%');
        }.padding(AppDimens.cardPadding).backgroundColor(AppColors.card).borderRadius(AppDimens.cardRadius).width('100%');
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
