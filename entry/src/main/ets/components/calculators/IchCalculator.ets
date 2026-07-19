import { CalcResult , getTierColor, getTierBgColor } from '../../engine/CalcEngine';
import { calculateIch } from '../../engine/IchCalculator';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';

@Component
export struct IchCalculator {
  @State resetKey: number = 0;  @State vol: number = 0;
  @State location: number = -1;
  @State ivh: number = -1;
  @State age: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    if (this.ivh < 0) {
      this.result = { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
      return;
    }
    this.result = calculateIch(this.vol, this.location, this.ivh === 1, this.age);
  }

  reset() {
    this.vol = 0;
    this.location = -1;
    this.ivh = -1;
    this.age = 0;
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
      Column() { Text('用于自发性脑出血30天死亡率预测').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('5项：GCS+年龄+幕下+出血量+脑室出血，总分0-6').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Row() { Text('— 输入参数').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });

        Column() { Text('血肿体积 (mL)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '请输入体积' }).type(InputType.Number).height(AppDimens.inputHeight).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.vol = parseFloat(value) || 0; this.calculate(); }); }.width('100%').margin({ bottom: 16 });

        Column() {
          Text('出血部位').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 8 });
          Row() {
            Button('幕上').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.location === 0 ? AppColors.card : '#2D5440').backgroundColor(this.location === 0 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.location === 0 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.location = 0; this.calculate(); });
            Button('幕下').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.location === 1 ? AppColors.card : '#2D5440').backgroundColor(this.location === 1 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.location === 1 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).margin({ left: 8 }).onClick(() => { this.location = 1; this.calculate(); });
          }.width('100%');
        }.width('100%').margin({ bottom: 16 });

        Row() { Text('脑室出血').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.ivh === 0 ? AppColors.card : '#2D5440').backgroundColor(this.ivh === 0 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.ivh === 0 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.ivh = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.ivh === 1 ? AppColors.card : '#2D5440').backgroundColor(this.ivh === 1 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.ivh === 1 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { this.ivh = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 16 });

        Column() { Text('年龄 (岁)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '请输入年龄' }).type(InputType.Number).height(AppDimens.inputHeight).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.age = parseFloat(value) || 0; this.calculate(); }); }.width('100%');
      }.padding(AppDimens.cardPadding).backgroundColor(AppColors.card).borderRadius(AppDimens.cardRadius).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() { Text('ICH Score').fontSize(12).fontColor(AppColors.textSecondary).letterSpacing(1.5).fontWeight(FontWeight.Medium);
              Text(this.result!.value !== null ? `${this.result!.value!.toFixed(0)} ${this.result!.unit}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor(AppColors.primary).margin({ top: 8 });
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
