import { CalcResult , getTierColor, getTierBgColor } from '../../engine/CalcEngine';
import { calculateNihss } from '../../engine/MoreCalculators';

@Component
export struct NihssCalculator {  @State ia: number = 0;
  @State ib: number = 0;
  @State ic: number = 0;
  @State gaze: number = 0;
  @State vis: number = 0;
  @State face: number = 0;
  @State armA: number = 0;
  @State armB: number = 0;
  @State ata: number = 0;
  @State sens: number = 0;
  @State lang: number = 0;
  @State dys: number = 0;
  @State neg: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateNihss(this.ia, this.ib, this.ic, this.gaze, this.vis, this.face, this.armA, this.armB, this.ata, this.sens, this.lang, this.dys, this.neg); }

  build() {
    Column() {
      Column() { Text('用于评估脑卒中神经功能缺损严重程度').fontSize(14).fontColor('#1F3D2F').fontWeight(FontWeight.Medium); Text('11项评估，总分0-42，≥6分考虑溶栓/取栓').fontSize(12).fontColor('#7A8074').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });
      Column() {
        Text('— 输入参数').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });
        Row() {
          Column() { Text('1a 意识水平').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '0-3' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.ia = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1);
          Column() { Text('1b 提问').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '0-2' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.ib = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1).margin({ left: 8 });
          Column() { Text('1c 指令').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '0-2' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.ic = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 12 });
        Row() {
          Column() { Text('2 凝视').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '0-2' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.gaze = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1);
          Column() { Text('3 视野').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '0-3' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.vis = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1).margin({ left: 8 });
          Column() { Text('4 面瘫').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '0-3' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.face = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 12 });
        Row() {
          Column() { Text('5a 左上肢').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '0-4' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.armA = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1);
          Column() { Text('5b 右上肢').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '0-4' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.armB = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 12 });
        Row() {
          Column() { Text('6 共济失调').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '0-2' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.ata = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1);
          Column() { Text('7 感觉').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '0-2' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.sens = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1).margin({ left: 8 });
          Column() { Text('8 语言').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '0-3' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.lang = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 12 });
        Row() {
          Column() { Text('9 构音').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '0-2' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.dys = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1);
          Column() { Text('10 忽视').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '0-2' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.neg = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1).margin({ left: 8 });
        }.width('100%');
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });
      if (this.result) { Column() { Row() {
        Column() { Text('NIHSS Total').fontSize(12).fontColor('#7A8074').letterSpacing(1.5).fontWeight(FontWeight.Medium);
          Text(this.result!.value !== null ? `${this.result!.value!.toFixed(0)}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor('#1F3D2F').margin({ top: 8 });
          Text(this.result!.tier).fontSize(13).fontWeight(FontWeight.Bold).fontColor(getTierColor(this.result!.tierClass))
            .backgroundColor(getTierBgColor(this.result!.tierClass)).borderRadius(20).padding({ left: 12, right: 12, top: 4, bottom: 4 }).margin({ top: 8 });
        }.alignItems(HorizontalAlign.Start).layoutWeight(1);
        Column() { Text(this.result!.footnote).fontSize(14).fontColor('#4A5247').lineHeight(22); }.layoutWeight(1).alignItems(HorizontalAlign.Start);
      }.width('100%'); }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%'); }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(16).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
