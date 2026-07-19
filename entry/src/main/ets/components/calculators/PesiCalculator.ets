import { CalcResult, getTierColor, getTierBgColor } from '../../engine/CalcEngine';
import { calculatePesi } from '../../engine/PesiCalculator';

@Component
export struct PesiCalculator {
  @State age: number = 0;
  @State sex: number = -1;
  @State cancer: number = -1;
  @State chf: number = -1;
  @State cld: number = -1;
  @State hr: number = 0;
  @State sbp: number = 0;
  @State rr: number = 0;
  @State temp: number = 0;
  @State ams: number = -1;
  @State osp: number = -1;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculatePesi(this.age, this.sex, this.cancer, this.chf, this.cld, this.hr, this.sbp, this.rr, this.temp, this.ams, this.osp); }

  build() {
    Column() {
      Column() { Text('用于肺栓塞 30 天死亡风险分层').fontSize(14).fontColor('#1F3D2F').fontWeight(FontWeight.Medium); Text('11 项, 总分 0-300+, sPESI 简化版 (Aujesky 2005)').fontSize(12).fontColor('#7A8074').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Text('— PESI 参数').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });

        Row() {
          Column() {
            Text('年龄 (岁)').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
            TextInput({ placeholder: '年龄' }).type(InputType.Number).height(40).fontSize(16).backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).placeholderColor('#999999').onChange((v: string) => { this.age = parseFloat(v) || 0; this.calculate(); });
          }.layoutWeight(1);
          Column() {
            Text('性别').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
            Row() {
              Button('女').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.sex === 0 ? '#FFFFFF' : '#2D5440').backgroundColor(this.sex === 0 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.sex === 0 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).layoutWeight(1).onClick(() => { this.sex = 0; this.calculate(); });
              Button('男').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.sex === 10 ? '#FFFFFF' : '#2D5440').backgroundColor(this.sex === 10 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.sex === 10 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).layoutWeight(1).margin({ left: 4 }).onClick(() => { this.sex = 10; this.calculate(); });
            }.width('100%');
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 8 });

        Row() {
          Column() {
            Text('恶性肿瘤').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
            Row() {
              Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.cancer === 0 ? '#FFFFFF' : '#2D5440').backgroundColor(this.cancer === 0 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.cancer === 0 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).layoutWeight(1).onClick(() => { this.cancer = 0; this.calculate(); });
              Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.cancer === 30 ? '#FFFFFF' : '#2D5440').backgroundColor(this.cancer === 30 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.cancer === 30 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).layoutWeight(1).margin({ left: 4 }).onClick(() => { this.cancer = 30; this.calculate(); });
            }.width('100%');
          }.layoutWeight(1);
          Column() {
            Text('心衰').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
            Row() {
              Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.chf === 0 ? '#FFFFFF' : '#2D5440').backgroundColor(this.chf === 0 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.chf === 0 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).layoutWeight(1).onClick(() => { this.chf = 0; this.calculate(); });
              Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.chf === 10 ? '#FFFFFF' : '#2D5440').backgroundColor(this.chf === 10 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.chf === 10 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).layoutWeight(1).margin({ left: 4 }).onClick(() => { this.chf = 10; this.calculate(); });
            }.width('100%');
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 8 });

        Row() {
          Column() {
            Text('慢性肺病').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
            Row() {
              Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.cld === 0 ? '#FFFFFF' : '#2D5440').backgroundColor(this.cld === 0 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.cld === 0 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).layoutWeight(1).onClick(() => { this.cld = 0; this.calculate(); });
              Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.cld === 10 ? '#FFFFFF' : '#2D5440').backgroundColor(this.cld === 10 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.cld === 10 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).layoutWeight(1).margin({ left: 4 }).onClick(() => { this.cld = 10; this.calculate(); });
            }.width('100%');
          }.layoutWeight(1);
          Column() {
            Text('心率 (bpm)').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
            TextInput({ placeholder: 'HR' }).type(InputType.Number).height(40).fontSize(16).backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).placeholderColor('#999999').onChange((v: string) => { this.hr = parseFloat(v) || 0; this.calculate(); });
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 8 });

        Row() {
          Column() {
            Text('SBP (mmHg)').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
            TextInput({ placeholder: 'SBP' }).type(InputType.Number).height(40).fontSize(16).backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).placeholderColor('#999999').onChange((v: string) => { this.sbp = parseFloat(v) || 0; this.calculate(); });
          }.layoutWeight(1);
          Column() {
            Text('呼吸频率 (次/分)').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
            TextInput({ placeholder: 'RR' }).type(InputType.Number).height(40).fontSize(16).backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).placeholderColor('#999999').onChange((v: string) => { this.rr = parseFloat(v) || 0; this.calculate(); });
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 8 });

        Row() {
          Column() {
            Text('体温 (°C)').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
            TextInput({ placeholder: '体温' }).type(InputType.Number).height(40).fontSize(16).backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).placeholderColor('#999999').onChange((v: string) => { this.temp = parseFloat(v) || 0; this.calculate(); });
          }.layoutWeight(1);
          Column() {
            Text('意识状态').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
            Row() {
              Button('正常').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.ams === 0 ? '#FFFFFF' : '#2D5440').backgroundColor(this.ams === 0 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.ams === 0 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).layoutWeight(1).onClick(() => { this.ams = 0; this.calculate(); });
              Button('改变').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.ams === 60 ? '#FFFFFF' : '#2D5440').backgroundColor(this.ams === 60 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.ams === 60 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).layoutWeight(1).margin({ left: 4 }).onClick(() => { this.ams = 60; this.calculate(); });
            }.width('100%');
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 8 });

        Column() {
          Text('SpO₂ < 90%').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
          Row() {
            Button('≥ 90%').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.osp === 0 ? '#FFFFFF' : '#2D5440').backgroundColor(this.osp === 0 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.osp === 0 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).layoutWeight(1).onClick(() => { this.osp = 0; this.calculate(); });
            Button('< 90%').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.osp === 20 ? '#FFFFFF' : '#2D5440').backgroundColor(this.osp === 20 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.osp === 20 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).layoutWeight(1).margin({ left: 4 }).onClick(() => { this.osp = 20; this.calculate(); });
          }.width('100%');
        }.width('100%');
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() {
              Text('PESI 总分').fontSize(10).fontColor('#7A8074').letterSpacing(1.5);
              Text(this.result!.value !== null ? `${this.result!.value!.toFixed(0)}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor('#1F3D2F').margin({ top: 4 });
              Text(this.result!.tier).fontSize(13).fontWeight(FontWeight.Bold).fontColor(getTierColor(this.result!.tierClass)).backgroundColor(getTierBgColor(this.result!.tierClass)).borderRadius(20).padding({ left: 12, right: 12, top: 4, bottom: 4 }).margin({ top: 4 });
            }.alignItems(HorizontalAlign.Start).layoutWeight(1);
            Column() {
              Text(this.result!.footnote).fontSize(14).fontColor('#4A5247').lineHeight(22);
            }.layoutWeight(1).alignItems(HorizontalAlign.Start);
          }.width('100%');
        }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%');
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(16).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
