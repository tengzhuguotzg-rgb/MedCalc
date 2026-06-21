import { CalcResult , getTierColor, getTierBgColor } from '../../engine/CalcEngine';
import { calculateSofa } from '../../engine/SofaCalculator';

@Component
export struct SofaCalculator {  @State pao2: number = 0;
  @State fio2: number = 0;
  @State platelet: number = 0;
  @State bilirubin: number = 0;
  @State bilirubinUnit: string = 'umol';
  @State map: number = 0;
  @State vaso: string = 'none';
  @State gcs: number = 15;
  @State creatinine: number = 0;
  @State creatinineUnit: string = 'umol';
  @State urineOutput: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateSofa(this.pao2, this.fio2, this.platelet, this.bilirubin, this.bilirubinUnit, this.map, this.vaso, this.gcs, this.creatinine, this.creatinineUnit, this.urineOutput); }

  build() {
    Column() {
      Column() { Text('用于评估器官功能障碍程度，Sepsis-3诊断').fontSize(14).fontColor('#1F3D2F').fontWeight(FontWeight.Medium); Text('6系统：呼吸+凝血+肝+循环+神经+肾，0-24分').fontSize(12).fontColor('#7A8074').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Text('— 呼吸').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });
        Row() {
          Column() { Text('PaO₂ (mmHg)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '请输入PaO2' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.pao2 = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1);
          Column() { Text('FiO₂').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '请输入FiO2' }).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.fio2 = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1).margin({ left: 12 });
        }.width('100%');
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      Column() {
        Text('— 凝血 / 肝脏').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });
        Row() {
          Column() { Text('血小板 PLT (×10⁹/L)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '请输入PLT' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.platelet = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1);
          Column() { Text('胆红素 (µmol/L)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '请输入胆红素' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.bilirubin = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1).margin({ left: 12 });
        }.width('100%');
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      Column() {
        Text('— 心血管 / 神经').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });
        Column() {
          Text('升压药').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 8 });
          Flex({ wrap: FlexWrap.Wrap }) {
            Button('无').fontSize(12).fontWeight(FontWeight.Medium).fontColor(this.vaso === 'none' ? '#FFFFFF' : '#2D5440')
              .backgroundColor(this.vaso === 'none' ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.vaso === 'none' ? '#1F3D2F' : '#E0E0E0' })
              .borderRadius(8).height(36).margin({ right: 8, bottom: 8 }).onClick(() => { this.vaso = 'none'; this.calculate(); });
            Button('多巴胺≤5').fontSize(12).fontWeight(FontWeight.Medium).fontColor(this.vaso === 'dopaLo' ? '#FFFFFF' : '#2D5440')
              .backgroundColor(this.vaso === 'dopaLo' ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.vaso === 'dopaLo' ? '#1F3D2F' : '#E0E0E0' })
              .borderRadius(8).height(36).margin({ right: 8, bottom: 8 }).onClick(() => { this.vaso = 'dopaLo'; this.calculate(); });
            Button('NE≤0.1').fontSize(12).fontWeight(FontWeight.Medium).fontColor(this.vaso === 'nore' ? '#FFFFFF' : '#2D5440')
              .backgroundColor(this.vaso === 'nore' ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.vaso === 'nore' ? '#1F3D2F' : '#E0E0E0' })
              .borderRadius(8).height(36).margin({ right: 8, bottom: 8 }).onClick(() => { this.vaso = 'nore'; this.calculate(); });
            Button('多巴胺5-15').fontSize(12).fontWeight(FontWeight.Medium).fontColor(this.vaso === 'dopaMid' ? '#FFFFFF' : '#2D5440')
              .backgroundColor(this.vaso === 'dopaMid' ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.vaso === 'dopaMid' ? '#1F3D2F' : '#E0E0E0' })
              .borderRadius(8).height(36).margin({ right: 8, bottom: 8 }).onClick(() => { this.vaso = 'dopaMid'; this.calculate(); });
            Button('NE>0.1').fontSize(12).fontWeight(FontWeight.Medium).fontColor(this.vaso === 'noreHi' ? '#FFFFFF' : '#2D5440')
              .backgroundColor(this.vaso === 'noreHi' ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.vaso === 'noreHi' ? '#1F3D2F' : '#E0E0E0' })
              .borderRadius(8).height(36).margin({ right: 8, bottom: 8 }).onClick(() => { this.vaso = 'noreHi'; this.calculate(); });
            Button('多巴胺>15').fontSize(12).fontWeight(FontWeight.Medium).fontColor(this.vaso === 'dopa15' ? '#FFFFFF' : '#2D5440')
              .backgroundColor(this.vaso === 'dopa15' ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.vaso === 'dopa15' ? '#1F3D2F' : '#E0E0E0' })
              .borderRadius(8).height(36).margin({ right: 8, bottom: 8 }).onClick(() => { this.vaso = 'dopa15'; this.calculate(); });
          }.width('100%');
        }.width('100%').margin({ bottom: 16 });
        Row() {
          Column() { Text('MAP (mmHg)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '请输入MAP' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.map = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1);
          Column() { Text('GCS 评分').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '请输入GCS' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.gcs = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1).margin({ left: 12 });
        }.width('100%');
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      Column() {
        Text('— 肾脏').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });
        Row() {
          Column() { Text('血肌酐 (µmol/L)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '请输入肌酐' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.creatinine = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1);
          Column() { Text('尿量 (mL/d)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '请输入尿量' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.urineOutput = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1).margin({ left: 12 });
        }.width('100%');
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() { Text('SOFA Total').fontSize(12).fontColor('#7A8074').letterSpacing(1.5).fontWeight(FontWeight.Medium); Text(this.result!.value !== null ? `${this.result!.value!.toFixed(0)}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor('#1F3D2F').margin({ top: 8 }); Text(this.result!.tier).fontSize(13).fontWeight(FontWeight.Bold).fontColor(getTierColor(this.result!.tierClass)).backgroundColor(getTierBgColor(this.result!.tierClass)).borderRadius(20).padding({ left: 12, right: 12, top: 4, bottom: 4 }).margin({ top: 8 }); }.alignItems(HorizontalAlign.Start).layoutWeight(1);
            Column() { Text(this.result!.footnote).fontSize(14).fontColor('#4A5247').lineHeight(22); }.layoutWeight(1).alignItems(HorizontalAlign.Start);
          }.width('100%');
        }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%');
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(16).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
