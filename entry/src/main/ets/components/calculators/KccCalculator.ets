import { CalcResult, getTierColor, getTierBgColor } from '../../engine/CalcEngine';
import { calculateKcc } from '../../engine/KccCalculator';

@Component
export struct KccCalculator {  @State inr: number = 0;
  @State bilirubin: number = 0;
  @State bilirubinUnit: string = 'umol';
  @State age: number = 0;
  @State etiology: number = -1;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    if (this.etiology < 0) {
      this.result = { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
      return;
    }
    this.result = calculateKcc(this.inr, this.bilirubin, this.bilirubinUnit, this.age, this.etiology === 1);
  }

  build() {
    Column() {
      Column() { Text('用于急性肝衰竭紧急肝移植决策').fontSize(14).fontColor('#1F3D2F').fontWeight(FontWeight.Medium); Text('对乙酰氨基酚/非对乙酰氨基酚两种标准评估').fontSize(12).fontColor('#7A8074').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Text('— 输入参数').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });

        Row() {
          Column() { Text('INR').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '请输入INR' }).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.inr = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1);
          Column() { Text(this.bilirubinUnit === 'umol' ? '胆红素 (µmol/L)' : '胆红素 (mg/dL)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '请输入胆红素' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.bilirubin = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });

        Row() {
          Text('胆红素单位').fontSize(12).fontColor('#7A8074').layoutWeight(1);
          Button('µmol/L').fontSize(11).fontWeight(FontWeight.Bold).fontColor(this.bilirubinUnit === 'umol' ? '#FFFFFF' : '#2D5440').backgroundColor(this.bilirubinUnit === 'umol' ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.bilirubinUnit === 'umol' ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).onClick(() => { this.bilirubinUnit = 'umol'; this.calculate(); });
          Button('mg/dL').fontSize(11).fontWeight(FontWeight.Bold).fontColor(this.bilirubinUnit === 'mgdl' ? '#FFFFFF' : '#2D5440').backgroundColor(this.bilirubinUnit === 'mgdl' ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.bilirubinUnit === 'mgdl' ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).margin({ left: 6 }).onClick(() => { this.bilirubinUnit = 'mgdl'; this.calculate(); });
        }.width('100%').margin({ bottom: 8 });

        Column() { Text('年龄 (岁)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '请输入年龄' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.age = parseFloat(value) || 0; this.calculate(); }); }.width('100%').margin({ bottom: 16 });

        Row() { Text('病因：扑热息痛/不明原因').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('否').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.etiology === 0 ? '#FFFFFF' : '#2D5440').backgroundColor(this.etiology === 0 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.etiology === 0 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.etiology = 0; this.calculate(); });
            Button('是').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.etiology === 1 ? '#FFFFFF' : '#2D5440').backgroundColor(this.etiology === 1 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.etiology === 1 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.etiology = 1; this.calculate(); });
          }.width(100);
        }.width('100%');
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() { Text('KCC').fontSize(12).fontColor('#7A8074').letterSpacing(1.5).fontWeight(FontWeight.Medium);
              Text(this.result!.value !== null ? (this.result!.value === 1 ? '符合' : '不符合') : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor('#1F3D2F').margin({ top: 8 });
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
