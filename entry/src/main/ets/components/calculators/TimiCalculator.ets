import { CalcResult , getTierColor, getTierBgColor } from '../../engine/CalcEngine';
import { calculateTimiStemi, calculateTimiNstemi } from '../../engine/TimiCalculator';

@Component
export struct TimiStemiCalculator {
  @State age: number = 0;
  @State sbp: number = 0;
  @State hr: number = 0;
  @State weight: number = 0;
  @State dmHtnAngina: boolean = false;
  @State killip: number = 1;
  @State anteriorLbbb: boolean = false;
  @State timeToTreat: boolean = false;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateTimiStemi(this.age, this.dmHtnAngina, this.sbp, this.hr, this.killip, this.weight, this.anteriorLbbb, this.timeToTreat); }

  build() {
    Column() {
      Column() { Text('用于评估STEMI（ST段抬高型心肌梗死）患者30天死亡风险').fontSize(14).fontColor('#1F3D2F').fontWeight(FontWeight.Medium); Text('8项：年龄+合并症+SBP+心率+Killip+体重+前壁/LBBB+就诊时间').fontSize(12).fontColor('#7A8074').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Text('— 输入参数').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });

        Row() {
          Column() { Text('年龄 (岁)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '年龄' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.age = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1);
          Column() { Text('收缩压 SBP (mmHg)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: 'SBP' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.sbp = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 16 });

        Row() {
          Column() { Text('心率 (次/分)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: 'HR' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.hr = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1);
          Column() { Text('体重 (kg)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '体重' }).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.weight = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 16 });

        Row() { Text('糖尿病/高血压/心绞痛').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!this.dmHtnAngina ? '#FFFFFF' : '#2D5440').backgroundColor(!this.dmHtnAngina ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.dmHtnAngina ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.dmHtnAngina = false; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.dmHtnAngina ? '#FFFFFF' : '#2D5440').backgroundColor(this.dmHtnAngina ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.dmHtnAngina ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.dmHtnAngina = true; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Column() {
          Text('Killip 分级').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
          Flex({ wrap: FlexWrap.Wrap }) {
            Button('I 无心衰').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.killip === 1 ? '#FFFFFF' : '#2D5440').backgroundColor(this.killip === 1 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.killip === 1 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(32).padding({ left: 8, right: 8 }).margin({ right: 6, bottom: 4 }).onClick(() => { this.killip = 1; this.calculate(); });
            Button('II 啰音/奔马律').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.killip === 2 ? '#FFFFFF' : '#2D5440').backgroundColor(this.killip === 2 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.killip === 2 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(32).padding({ left: 8, right: 8 }).margin({ right: 6, bottom: 4 }).onClick(() => { this.killip = 2; this.calculate(); });
            Button('III 肺水肿').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.killip === 3 ? '#FFFFFF' : '#2D5440').backgroundColor(this.killip === 3 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.killip === 3 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(32).padding({ left: 8, right: 8 }).margin({ right: 6, bottom: 4 }).onClick(() => { this.killip = 3; this.calculate(); });
            Button('IV 心源性休克').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.killip === 4 ? '#FFFFFF' : '#2D5440').backgroundColor(this.killip === 4 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.killip === 4 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(32).padding({ left: 8, right: 8 }).margin({ bottom: 4 }).onClick(() => { this.killip = 4; this.calculate(); });
          }.width('100%');
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('前壁STEMI 或 LBBB').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!this.anteriorLbbb ? '#FFFFFF' : '#2D5440').backgroundColor(!this.anteriorLbbb ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.anteriorLbbb ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.anteriorLbbb = false; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.anteriorLbbb ? '#FFFFFF' : '#2D5440').backgroundColor(this.anteriorLbbb ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.anteriorLbbb ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.anteriorLbbb = true; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('就诊到再灌注 > 4h').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('否').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!this.timeToTreat ? '#FFFFFF' : '#2D5440').backgroundColor(!this.timeToTreat ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.timeToTreat ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.timeToTreat = false; this.calculate(); });
            Button('是').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.timeToTreat ? '#FFFFFF' : '#2D5440').backgroundColor(this.timeToTreat ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.timeToTreat ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.timeToTreat = true; this.calculate(); });
          }.width(100);
        }.width('100%');
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() { Text('TIMI STEMI').fontSize(12).fontColor('#7A8074').letterSpacing(1.5).fontWeight(FontWeight.Medium);
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

@Component
export struct TimiNstemiCalculator {
  @State age: number = 0;
  @State rfHtn: boolean = false;
  @State rfDm: boolean = false;
  @State rfSmoker: boolean = false;
  @State rfHyperlipid: boolean = false;
  @State rfFamily: boolean = false;
  @State priorAspirin: boolean = false;
  @State stDev: number = 0;
  @State troponin: number = 0;
  @State result: CalcResult | null = null;

  getRiskFactorCount(): number {
    let n = 0;
    if (this.rfHtn) n++;
    if (this.rfDm) n++;
    if (this.rfSmoker) n++;
    if (this.rfHyperlipid) n++;
    if (this.rfFamily) n++;
    return n;
  }

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateTimiNstemi(this.age, this.getRiskFactorCount() >= 3, this.priorAspirin, this.stDev, this.troponin); }

  build() {
    Column() {
      Column() { Text('用于评估NSTEMI/UA（非ST段抬高型心肌梗死/不稳定型心绞痛）患者14天事件风险').fontSize(14).fontColor('#1F3D2F').fontWeight(FontWeight.Medium); Text('7项：年龄+危险因素+冠脉病变+ST段偏移+症状+心梗史+阿司匹林').fontSize(12).fontColor('#7A8074').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Text('— 输入参数').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });

        Row() {
          Column() { Text('年龄 (岁)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '请输入年龄' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.age = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1);
          Column() { Text('ST段偏移 (mm)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: 'ST段偏移' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.stDev = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 16 });

        Column() {
          Text('肌钙蛋白 (ng/mL)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 });
          TextInput({ placeholder: '肌钙蛋白' }).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.troponin = parseFloat(value) || 0; this.calculate(); });
        }.width('100%').margin({ bottom: 16 });

        Column() {
          Text('CAD 危险因素').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 });
          Flex({ wrap: FlexWrap.Wrap }) {
            Button(this.rfHtn ? '✓ 高血压' : '高血压').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.rfHtn ? '#FFFFFF' : '#2D5440').backgroundColor(this.rfHtn ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.rfHtn ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(32).padding({ left: 8, right: 8 }).margin({ right: 6, bottom: 4 }).onClick(() => { this.rfHtn = !this.rfHtn; this.calculate(); });
            Button(this.rfDm ? '✓ 糖尿病' : '糖尿病').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.rfDm ? '#FFFFFF' : '#2D5440').backgroundColor(this.rfDm ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.rfDm ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(32).padding({ left: 8, right: 8 }).margin({ right: 6, bottom: 4 }).onClick(() => { this.rfDm = !this.rfDm; this.calculate(); });
            Button(this.rfSmoker ? '✓ 吸烟' : '吸烟').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.rfSmoker ? '#FFFFFF' : '#2D5440').backgroundColor(this.rfSmoker ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.rfSmoker ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(32).padding({ left: 8, right: 8 }).margin({ right: 6, bottom: 4 }).onClick(() => { this.rfSmoker = !this.rfSmoker; this.calculate(); });
            Button(this.rfHyperlipid ? '✓ 高脂血症' : '高脂血症').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.rfHyperlipid ? '#FFFFFF' : '#2D5440').backgroundColor(this.rfHyperlipid ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.rfHyperlipid ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(32).padding({ left: 8, right: 8 }).margin({ right: 6, bottom: 4 }).onClick(() => { this.rfHyperlipid = !this.rfHyperlipid; this.calculate(); });
            Button(this.rfFamily ? '✓ 家族史' : '家族史').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.rfFamily ? '#FFFFFF' : '#2D5440').backgroundColor(this.rfFamily ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.rfFamily ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(32).padding({ left: 8, right: 8 }).margin({ bottom: 4 }).onClick(() => { this.rfFamily = !this.rfFamily; this.calculate(); });
          }.width('100%');
          Text(`已选 ${this.getRiskFactorCount()}/5 · ≥ 3 项为阳性`).fontSize(10).fontColor('#7A8074').margin({ top: 2 });
        }.width('100%').margin({ bottom: 16 });

        Row() { Text('既往阿司匹林使用').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!this.priorAspirin ? '#FFFFFF' : '#2D5440').backgroundColor(!this.priorAspirin ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.priorAspirin ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.priorAspirin = false; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.priorAspirin ? '#FFFFFF' : '#2D5440').backgroundColor(this.priorAspirin ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.priorAspirin ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.priorAspirin = true; this.calculate(); });
          }.width(100);
        }.width('100%');
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() { Text('TIMI NSTEMI').fontSize(12).fontColor('#7A8074').letterSpacing(1.5).fontWeight(FontWeight.Medium);
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
