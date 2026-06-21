import { CalcResult } from '../../engine/CalcEngine';
import { calculateClifC } from '../../engine/ClifCCalculator';

@Component
export struct ClifCCalculator {
  @State bilirubin: number = 0;
  @State bilUnit: string = 'umol';
  @State inr: number = 0;
  @State hepaticEnceph: number = 0;
  @State map: number = 80;
  @State vasoNorepi: boolean = false;
  @State vasoDopamine: boolean = false;
  @State vasoEpi: boolean = false;
  @State creatinine: number = 0;
  @State crUnit: string = 'umol';
  @State rr: number = 20;
  @State spo2: number = 98;
  @State fio2: number = 21;
  @State fio2Mode: string = 'pct';
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateClifC(this.bilirubin, this.bilUnit, this.inr, this.hepaticEnceph, this.map, this.vasoNorepi, this.vasoDopamine, this.vasoEpi, this.creatinine, this.crUnit, this.rr, this.spo2, this.fio2, this.fio2Mode); }

  build() {
    Column() {
      Column() { Text('CLIF-C ACLF').fontSize(17).fontWeight(FontWeight.Bold).fontColor('#1F3D2F'); Text('慢加急性肝衰竭死亡率 · EASL-CLIF (2013)').fontSize(11.5).fontColor('#4A5247').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Text('— 肝功能').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });

        Column() { Text('胆红素').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '请输入' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.bilirubin = parseFloat(value) || 0; this.calculate(); }); }.width('100%').margin({ bottom: 6 });
        Row() { Button('µmol/L').fontSize(11).fontWeight(FontWeight.Bold).fontColor(this.bilUnit === 'umol' ? '#FFFFFF' : '#2D5440').backgroundColor(this.bilUnit === 'umol' ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.bilUnit === 'umol' ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(32).layoutWeight(1).onClick(() => { this.bilUnit = 'umol'; this.calculate(); });
          Button('mg/dL').fontSize(11).fontWeight(FontWeight.Bold).fontColor(this.bilUnit === 'mgdl' ? '#FFFFFF' : '#2D5440').backgroundColor(this.bilUnit === 'mgdl' ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.bilUnit === 'mgdl' ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(32).layoutWeight(1).margin({ left: 6 }).onClick(() => { this.bilUnit = 'mgdl'; this.calculate(); });
        }.width('100%').margin({ bottom: 12 });
        Column() { Text('INR').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '请输入' }).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.inr = parseFloat(value) || 0; this.calculate(); }); }.width('100%').margin({ bottom: 12 });

        Column() {
          Text('肝性脑病').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 8 });
          Row() {
            Button('0').fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.hepaticEnceph === 0 ? '#FFFFFF' : '#2D5440').backgroundColor(this.hepaticEnceph === 0 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.hepaticEnceph === 0 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.hepaticEnceph = 0; this.calculate(); });
            Button('I-II').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.hepaticEnceph === 1 ? '#FFFFFF' : '#2D5440').backgroundColor(this.hepaticEnceph === 1 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.hepaticEnceph === 1 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).margin({ left: 6 }).onClick(() => { this.hepaticEnceph = 1; this.calculate(); });
            Button('III-IV').fontSize(11).fontWeight(FontWeight.Bold).fontColor(this.hepaticEnceph === 2 ? '#FFFFFF' : '#2D5440').backgroundColor(this.hepaticEnceph === 2 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.hepaticEnceph === 2 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).margin({ left: 6 }).onClick(() => { this.hepaticEnceph = 2; this.calculate(); });
          }.width('100%');
        }.width('100%').margin({ bottom: 16 });

        Text('— 循环').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });

        Column() { Text('MAP (mmHg)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '80' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.map = parseFloat(value) || 80; this.calculate(); }); }.width('100%').margin({ bottom: 12 });

        Row() { Text('去甲肾上腺素').fontSize(13).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(12).fontWeight(FontWeight.Bold).fontColor(!this.vasoNorepi ? '#FFFFFF' : '#2D5440').backgroundColor(!this.vasoNorepi ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.vasoNorepi ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(32).layoutWeight(1).onClick(() => { this.vasoNorepi = false; this.calculate(); });
            Button('有').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.vasoNorepi ? '#FFFFFF' : '#2D5440').backgroundColor(this.vasoNorepi ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.vasoNorepi ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(32).layoutWeight(1).margin({ left: 8 }).onClick(() => { this.vasoNorepi = true; this.calculate(); });
          }.layoutWeight(1);
        }.width('100%').margin({ bottom: 8 });

        Row() { Text('多巴胺').fontSize(13).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(12).fontWeight(FontWeight.Bold).fontColor(!this.vasoDopamine ? '#FFFFFF' : '#2D5440').backgroundColor(!this.vasoDopamine ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.vasoDopamine ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(32).layoutWeight(1).onClick(() => { this.vasoDopamine = false; this.calculate(); });
            Button('有').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.vasoDopamine ? '#FFFFFF' : '#2D5440').backgroundColor(this.vasoDopamine ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.vasoDopamine ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(32).layoutWeight(1).margin({ left: 8 }).onClick(() => { this.vasoDopamine = true; this.calculate(); });
          }.layoutWeight(1);
        }.width('100%').margin({ bottom: 8 });

        Row() { Text('肾上腺素').fontSize(13).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(12).fontWeight(FontWeight.Bold).fontColor(!this.vasoEpi ? '#FFFFFF' : '#2D5440').backgroundColor(!this.vasoEpi ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.vasoEpi ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(32).layoutWeight(1).onClick(() => { this.vasoEpi = false; this.calculate(); });
            Button('有').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.vasoEpi ? '#FFFFFF' : '#2D5440').backgroundColor(this.vasoEpi ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.vasoEpi ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(32).layoutWeight(1).margin({ left: 8 }).onClick(() => { this.vasoEpi = true; this.calculate(); });
          }.layoutWeight(1);
        }.width('100%').margin({ bottom: 16 });

        Text('— 肾功能').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });

        Column() { Text('肌酐').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '请输入' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.creatinine = parseFloat(value) || 0; this.calculate(); }); }.width('100%').margin({ bottom: 6 });
        Row() { Button('µmol/L').fontSize(11).fontWeight(FontWeight.Bold).fontColor(this.crUnit === 'umol' ? '#FFFFFF' : '#2D5440').backgroundColor(this.crUnit === 'umol' ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.crUnit === 'umol' ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(32).layoutWeight(1).onClick(() => { this.crUnit = 'umol'; this.calculate(); });
          Button('mg/dL').fontSize(11).fontWeight(FontWeight.Bold).fontColor(this.crUnit === 'mgdl' ? '#FFFFFF' : '#2D5440').backgroundColor(this.crUnit === 'mgdl' ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.crUnit === 'mgdl' ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(32).layoutWeight(1).margin({ left: 6 }).onClick(() => { this.crUnit = 'mgdl'; this.calculate(); });
        }.width('100%').margin({ bottom: 16 });

        Text('— 呼吸').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });

        Row() {
          Column() { Text('SpO₂ (%)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '98' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.spo2 = parseFloat(value) || 98; this.calculate(); }); }.layoutWeight(1);
          Column() { Text('RR (次/分)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '20' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.rr = parseFloat(value) || 20; this.calculate(); }); }.layoutWeight(1).margin({ left: 8 });
          Column() { Text('FiO₂').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '21' }).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.fio2 = parseFloat(value) || 21; this.calculate(); }); }.layoutWeight(1).margin({ left: 8 });
        }.width('100%');
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() { Text('CLIF-C ACLF').fontSize(12).fontColor('#7A8074').letterSpacing(1.5).fontWeight(FontWeight.Medium);
              Text(this.result!.value !== null ? `${this.result!.value!.toFixed(0)} ${this.result!.unit}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor('#1F3D2F').margin({ top: 8 });
              Text(this.result!.tier).fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.result!.tierClass === 'tier-ok' ? '#3D6B4F' : this.result!.tierClass === 'tier-warn' ? '#C8881A' : '#B1452A')
                .backgroundColor(this.result!.tierClass === 'tier-ok' ? '#E8F0EC' : this.result!.tierClass === 'tier-warn' ? '#F5EFE0' : '#F5E4E0').borderRadius(20).padding({ left: 12, right: 12, top: 4, bottom: 4 }).margin({ top: 8 });
            }.alignItems(HorizontalAlign.Start).layoutWeight(1);
            Column() { Text(this.result!.footnote).fontSize(14).fontColor('#4A5247').lineHeight(22); }.layoutWeight(1).alignItems(HorizontalAlign.Start);
          }.width('100%');
        }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%');
      }
    }.width('100%').padding(16);
  }
}
