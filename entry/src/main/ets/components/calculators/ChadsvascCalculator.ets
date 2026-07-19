import { CalcResult , getTierColor, getTierBgColor } from '../../engine/CalcEngine';
import { calculateChadsvasc } from '../../engine/MoreCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';

@Component
export struct ChadsvascCalculator {
  @State resetKey: number = 0;  @State chf: number = -1;
  @State htn: number = -1;
  @State age75: number = -1;
  @State dm: number = -1;
  @State stroke: number = -1;
  @State vasc: number = -1;
  @State age65: number = -1;
  @State female: number = -1;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    if (this.chf < 0 || this.htn < 0 || this.age75 < 0 || this.dm < 0 || this.stroke < 0 || this.vasc < 0 || this.age65 < 0 || this.female < 0) {
      this.result = { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
      return;
    }
    this.result = calculateChadsvasc(this.chf === 1, this.htn === 1, this.age75 === 1, this.dm === 1, this.stroke === 1, this.vasc === 1, this.age65 === 1, this.female === 1);
  }

  reset() {
    this.chf = -1;
    this.htn = -1;
    this.age75 = -1;
    this.dm = -1;
    this.stroke = -1;
    this.vasc = -1;
    this.age65 = -1;
    this.female = -1;
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
      Column() { Text('用于评估房颤患者脑卒中风险，指导抗凝决策').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('8项：心衰+高血压+年龄+糖尿病+卒中+血管病+性别，总分0-9').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Row() { Text('— 输入参数').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('C 心衰').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.chf === 0 ? AppColors.card : '#2D5440').backgroundColor(this.chf === 0 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.chf === 0 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.chf = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.chf === 1 ? AppColors.card : '#2D5440').backgroundColor(this.chf === 1 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.chf === 1 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.chf = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('H 高血压').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.htn === 0 ? AppColors.card : '#2D5440').backgroundColor(this.htn === 0 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.htn === 0 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.htn = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.htn === 1 ? AppColors.card : '#2D5440').backgroundColor(this.htn === 1 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.htn === 1 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.htn = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('A₂ 年龄 ≥ 75 岁').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.age75 === 0 ? AppColors.card : '#2D5440').backgroundColor(this.age75 === 0 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.age75 === 0 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.age75 = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.age75 === 1 ? AppColors.card : '#2D5440').backgroundColor(this.age75 === 1 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.age75 === 1 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.age75 = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('D 糖尿病').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.dm === 0 ? AppColors.card : '#2D5440').backgroundColor(this.dm === 0 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.dm === 0 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.dm = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.dm === 1 ? AppColors.card : '#2D5440').backgroundColor(this.dm === 1 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.dm === 1 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.dm = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('S₂ 卒中/TIA/血栓史').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.stroke === 0 ? AppColors.card : '#2D5440').backgroundColor(this.stroke === 0 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.stroke === 0 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.stroke = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.stroke === 1 ? AppColors.card : '#2D5440').backgroundColor(this.stroke === 1 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.stroke === 1 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.stroke = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('V 血管疾病').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.vasc === 0 ? AppColors.card : '#2D5440').backgroundColor(this.vasc === 0 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.vasc === 0 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.vasc = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.vasc === 1 ? AppColors.card : '#2D5440').backgroundColor(this.vasc === 1 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.vasc === 1 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.vasc = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('A 年龄 65-74 岁').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.age65 === 0 ? AppColors.card : '#2D5440').backgroundColor(this.age65 === 0 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.age65 === 0 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.age65 = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.age65 === 1 ? AppColors.card : '#2D5440').backgroundColor(this.age65 === 1 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.age65 === 1 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.age65 = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('Sc 女性').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.female === 0 ? AppColors.card : '#2D5440').backgroundColor(this.female === 0 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.female === 0 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.female = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.female === 1 ? AppColors.card : '#2D5440').backgroundColor(this.female === 1 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.female === 1 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.female = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
      }.padding(AppDimens.cardPadding).backgroundColor(AppColors.card).borderRadius(AppDimens.cardRadius).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() { Text('CHADS₂-VASc 总分').fontSize(12).fontColor(AppColors.textSecondary).letterSpacing(1.5).fontWeight(FontWeight.Medium); Text(this.result!.value !== null ? `${this.result!.value!.toFixed(0)}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor(AppColors.primary).margin({ top: 8 }); Text(this.result!.tier).fontSize(13).fontWeight(FontWeight.Bold).fontColor(getTierColor(this.result!.tierClass)).backgroundColor(getTierBgColor(this.result!.tierClass)).borderRadius(20).padding({ left: 12, right: 12, top: 4, bottom: 4 }).margin({ top: 8 }); }.alignItems(HorizontalAlign.Start).layoutWeight(1);
            Column() { Text(this.result!.footnote).fontSize(14).fontColor('#4A5247').lineHeight(22); }.layoutWeight(1).alignItems(HorizontalAlign.Start);
          }.width('100%');
        }.padding(AppDimens.cardPadding).backgroundColor(AppColors.card).borderRadius(AppDimens.cardRadius).width('100%');
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
