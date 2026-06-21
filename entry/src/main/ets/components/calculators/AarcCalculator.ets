import { CalcResult , getTierColor, getTierBgColor } from '../../engine/CalcEngine';
import { calculateAarc } from '../../engine/AarcCalculator';

@Component
export struct AarcCalculator {  @State bilirubin: number = 0;
  @State bilUnit: string = 'umol';
  @State inr: number = 0;
  @State lactate: number = 0;
  @State hepaticEnceph: number = 0;
  @State age: number = 0;
  @State acKf: boolean = false;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateAarc(this.bilirubin, this.bilUnit, this.inr, this.lactate, this.hepaticEnceph, this.age, this.acKf); }

  build() {
    Column() {
      Column() { Text('用于评估慢加急性肝衰竭严重程度及预后').fontSize(14).fontColor('#1F3D2F').fontWeight(FontWeight.Medium); Text('5项指标：胆红素 + INR + 乳酸 + 肝性脑病 + 年龄 + AKI').fontSize(12).fontColor('#7A8074').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Text('— 输入参数').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });

        Column() { Text('胆红素').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '请输入' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.bilirubin = parseFloat(value) || 0; this.calculate(); }); }.width('100%').margin({ bottom: 6 });
        Row() { Button('µmol/L').fontSize(11).fontWeight(FontWeight.Bold).fontColor(this.bilUnit === 'umol' ? '#FFFFFF' : '#2D5440').backgroundColor(this.bilUnit === 'umol' ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.bilUnit === 'umol' ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(32).layoutWeight(1).onClick(() => { this.bilUnit = 'umol'; this.calculate(); });
          Button('mg/dL').fontSize(11).fontWeight(FontWeight.Bold).fontColor(this.bilUnit === 'mgdl' ? '#FFFFFF' : '#2D5440').backgroundColor(this.bilUnit === 'mgdl' ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.bilUnit === 'mgdl' ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(32).layoutWeight(1).margin({ left: 6 }).onClick(() => { this.bilUnit = 'mgdl'; this.calculate(); });
        }.width('100%').margin({ bottom: 12 });

        Row() {
          Column() { Text('INR').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '请输入' }).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.inr = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1);
          Column() { Text('乳酸 (mmol/L)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '请输入' }).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.lactate = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 12 });

        Column() {
          Text('肝性脑病').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 8 });
          Row() {
            Button('0').fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.hepaticEnceph === 0 ? '#FFFFFF' : '#2D5440').backgroundColor(this.hepaticEnceph === 0 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.hepaticEnceph === 0 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.hepaticEnceph = 0; this.calculate(); });
            Button('I-II').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.hepaticEnceph === 1 ? '#FFFFFF' : '#2D5440').backgroundColor(this.hepaticEnceph === 1 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.hepaticEnceph === 1 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).margin({ left: 6 }).onClick(() => { this.hepaticEnceph = 1; this.calculate(); });
            Button('III-IV').fontSize(11).fontWeight(FontWeight.Bold).fontColor(this.hepaticEnceph === 2 ? '#FFFFFF' : '#2D5440').backgroundColor(this.hepaticEnceph === 2 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.hepaticEnceph === 2 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).margin({ left: 6 }).onClick(() => { this.hepaticEnceph = 2; this.calculate(); });
            Button('V').fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.hepaticEnceph === 3 ? '#FFFFFF' : '#2D5440').backgroundColor(this.hepaticEnceph === 3 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.hepaticEnceph === 3 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).margin({ left: 6 }).onClick(() => { this.hepaticEnceph = 3; this.calculate(); });
          }.width('100%');
        }.width('100%').margin({ bottom: 12 });

        Column() { Text('年龄 (岁)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '请输入年龄' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.age = parseFloat(value) || 0; this.calculate(); }); }.width('100%').margin({ bottom: 12 });

        Row() { Text('急性肾衰竭').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!this.acKf ? '#FFFFFF' : '#2D5440').backgroundColor(!this.acKf ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.acKf ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.acKf = false; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.acKf ? '#FFFFFF' : '#2D5440').backgroundColor(this.acKf ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.acKf ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.acKf = true; this.calculate(); });
          }.width(100);
        }.width('100%');
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() { Text('AARC').fontSize(12).fontColor('#7A8074').letterSpacing(1.5).fontWeight(FontWeight.Medium);
              Text(this.result!.value !== null ? `${this.result!.value!.toFixed(0)} ${this.result!.unit}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor('#1F3D2F').margin({ top: 8 });
              Text(this.result!.tier).fontSize(13).fontWeight(FontWeight.Bold).fontColor(getTierColor(this.result!.tierClass))
                .backgroundColor(getTierBgColor(this.result!.tierClass)).borderRadius(20).padding({ left: 12, right: 12, top: 4, bottom: 4 }).margin({ top: 8 });
            }.alignItems(HorizontalAlign.Start).layoutWeight(1);
            Column() { Text(this.result!.footnote).fontSize(14).fontColor('#4A5247').lineHeight(22); }.layoutWeight(1).alignItems(HorizontalAlign.Start);
          }.width('100%');
        }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%');
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(16).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
