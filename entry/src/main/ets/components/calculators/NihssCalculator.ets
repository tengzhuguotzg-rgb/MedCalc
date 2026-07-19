import { CalcResult , getTierColor, getTierBgColor } from '../../engine/CalcEngine';
import { calculateNihss } from '../../engine/MoreCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';

@Component
export struct NihssCalculator {
  @State resetKey: number = 0;  @State ia: number = -1;
  @State ib: number = -1;
  @State ic: number = -1;
  @State gaze: number = -1;
  @State vis: number = -1;
  @State face: number = -1;
  @State armA: number = -1;
  @State armB: number = -1;
  @State ata: number = -1;
  @State sens: number = -1;
  @State lang: number = -1;
  @State dys: number = -1;
  @State neg: number = -1;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateNihss(this.ia, this.ib, this.ic, this.gaze, this.vis, this.face, this.armA, this.armB, this.ata, this.sens, this.lang, this.dys, this.neg); }

  reset() {
    this.ia = -1;
    this.ib = -1;
    this.ic = -1;
    this.gaze = -1;
    this.vis = -1;
    this.face = -1;
    this.armA = -1;
    this.armB = -1;
    this.ata = -1;
    this.sens = -1;
    this.lang = -1;
    this.dys = -1;
    this.neg = -1;
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
      Column() { Text('用于评估脑卒中神经功能缺损严重程度').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('11项评估，总分0-42，≥6分考虑溶栓/取栓').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });
      Column() {
        Row() { Text('— 输入参数').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });
        Row() {
          Column() { Text('1a 意识水平').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '0-3' }).type(InputType.Number).height(AppDimens.inputHeight).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.ia = value === '' ? -1 : (parseFloat(value) || 0); this.calculate(); }); }.layoutWeight(1);
          Column() { Text('1b 提问').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '0-2' }).type(InputType.Number).height(AppDimens.inputHeight).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.ib = value === '' ? -1 : (parseFloat(value) || 0); this.calculate(); }); }.layoutWeight(1).margin({ left: 8 });
          Column() { Text('1c 指令').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '0-2' }).type(InputType.Number).height(AppDimens.inputHeight).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.ic = value === '' ? -1 : (parseFloat(value) || 0); this.calculate(); }); }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 12 });
        Row() {
          Column() { Text('2 凝视').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '0-2' }).type(InputType.Number).height(AppDimens.inputHeight).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.gaze = value === '' ? -1 : (parseFloat(value) || 0); this.calculate(); }); }.layoutWeight(1);
          Column() { Text('3 视野').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '0-3' }).type(InputType.Number).height(AppDimens.inputHeight).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.vis = value === '' ? -1 : (parseFloat(value) || 0); this.calculate(); }); }.layoutWeight(1).margin({ left: 8 });
          Column() { Text('4 面瘫').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '0-3' }).type(InputType.Number).height(AppDimens.inputHeight).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.face = value === '' ? -1 : (parseFloat(value) || 0); this.calculate(); }); }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 12 });
        Row() {
          Column() { Text('5a 左上肢').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '0-4' }).type(InputType.Number).height(AppDimens.inputHeight).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.armA = value === '' ? -1 : (parseFloat(value) || 0); this.calculate(); }); }.layoutWeight(1);
          Column() { Text('5b 右上肢').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '0-4' }).type(InputType.Number).height(AppDimens.inputHeight).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.armB = value === '' ? -1 : (parseFloat(value) || 0); this.calculate(); }); }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 12 });
        Row() {
          Column() { Text('6 共济失调').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '0-2' }).type(InputType.Number).height(AppDimens.inputHeight).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.ata = value === '' ? -1 : (parseFloat(value) || 0); this.calculate(); }); }.layoutWeight(1);
          Column() { Text('7 感觉').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '0-2' }).type(InputType.Number).height(AppDimens.inputHeight).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.sens = value === '' ? -1 : (parseFloat(value) || 0); this.calculate(); }); }.layoutWeight(1).margin({ left: 8 });
          Column() { Text('8 语言').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '0-3' }).type(InputType.Number).height(AppDimens.inputHeight).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.lang = value === '' ? -1 : (parseFloat(value) || 0); this.calculate(); }); }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 12 });
        Row() {
          Column() { Text('9 构音').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '0-2' }).type(InputType.Number).height(AppDimens.inputHeight).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.dys = value === '' ? -1 : (parseFloat(value) || 0); this.calculate(); }); }.layoutWeight(1);
          Column() { Text('10 忽视').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '0-2' }).type(InputType.Number).height(AppDimens.inputHeight).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.neg = value === '' ? -1 : (parseFloat(value) || 0); this.calculate(); }); }.layoutWeight(1).margin({ left: 8 });
        }.width('100%');
      }.padding(AppDimens.cardPadding).backgroundColor(AppColors.card).borderRadius(AppDimens.cardRadius).width('100%').margin({ bottom: 16 });
      if (this.result) { Column() { Row() {
        Column() { Text('NIHSS Total').fontSize(12).fontColor(AppColors.textSecondary).letterSpacing(1.5).fontWeight(FontWeight.Medium);
          Text(this.result!.value !== null ? `${this.result!.value!.toFixed(0)}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor(AppColors.primary).margin({ top: 8 });
          Text(this.result!.tier).fontSize(13).fontWeight(FontWeight.Bold).fontColor(getTierColor(this.result!.tierClass))
            .backgroundColor(getTierBgColor(this.result!.tierClass)).borderRadius(20).padding({ left: 12, right: 12, top: 4, bottom: 4 }).margin({ top: 8 });
        }.alignItems(HorizontalAlign.Start).layoutWeight(1);
        Column() { Text(this.result!.footnote).fontSize(14).fontColor('#4A5247').lineHeight(22); }.layoutWeight(1).alignItems(HorizontalAlign.Start);
      }.width('100%'); }.padding(AppDimens.cardPadding).backgroundColor(AppColors.card).borderRadius(AppDimens.cardRadius).width('100%'); }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
