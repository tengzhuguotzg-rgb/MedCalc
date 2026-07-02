import { CalcResult , getTierColor, getTierBgColor } from '../../engine/CalcEngine';
import { calculateTimiStemi, calculateTimiNstemi } from '../../engine/TimiCalculator';

@Component
export struct TimiStemiCalculator {
  @State ageCat: number = 0;
  @State sbpLt100: boolean = false;
  @State hrGt100: boolean = false;
  @State weightLt67: boolean = false;
  @State dmHtnAngina: boolean = false;
  @State killip: number = 1;
  @State anteriorLbbb: boolean = false;
  @State timeToTreat: boolean = false;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateTimiStemi(this.ageCat, this.dmHtnAngina, this.sbpLt100, this.hrGt100, this.killip, this.weightLt67, this.anteriorLbbb, this.timeToTreat); }

  @Builder
  YesNoBtn(value: boolean, onSelect: (v: boolean) => void) {
    Row() { Button('否').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!value ? '#FFFFFF' : '#2D5440').backgroundColor(!value ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !value ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => onSelect(false));
      Button('是').fontSize(14).fontWeight(FontWeight.Bold).fontColor(value ? '#FFFFFF' : '#2D5440').backgroundColor(value ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: value ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).margin({ left: 4 }).onClick(() => onSelect(true));
    }.width(100);
  }

  build() {
    Column() {
      Column() { Text('TIMI STEMI — ST段抬高型心肌梗死').fontSize(16).fontColor('#1F3D2F').fontWeight(FontWeight.Bold); Text('30天死亡风险 · 0-14分 (InTIME-II 2000)').fontSize(12).fontColor('#7A8074').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Text('— 患者因素').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 10 });
        Column() { Text('年龄').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 });
          Flex({ wrap: FlexWrap.Wrap }) {
            Button('< 55').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.ageCat === 0 ? '#FFFFFF' : '#2D5440').backgroundColor(this.ageCat === 0 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.ageCat === 0 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(6).height(32).padding({ left: 10, right: 10 }).margin({ right: 6, bottom: 4 }).onClick(() => { this.ageCat = 0; this.calculate(); });
            Button('55-64').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.ageCat === 1 ? '#FFFFFF' : '#2D5440').backgroundColor(this.ageCat === 1 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.ageCat === 1 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(6).height(32).padding({ left: 10, right: 10 }).margin({ right: 6, bottom: 4 }).onClick(() => { this.ageCat = 1; this.calculate(); });
            Button('65-74').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.ageCat === 2 ? '#FFFFFF' : '#2D5440').backgroundColor(this.ageCat === 2 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.ageCat === 2 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(6).height(32).padding({ left: 10, right: 10 }).margin({ right: 6, bottom: 4 }).onClick(() => { this.ageCat = 2; this.calculate(); });
            Button('≥ 75').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.ageCat === 3 ? '#FFFFFF' : '#2D5440').backgroundColor(this.ageCat === 3 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.ageCat === 3 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(6).height(32).padding({ left: 10, right: 10 }).margin({ bottom: 4 }).onClick(() => { this.ageCat = 3; this.calculate(); });
          }.width('100%');
        }.width('100%').margin({ bottom: 10 });

        Row() { Text('糖尿病/高血压/心绞痛').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1); this.YesNoBtn(this.dmHtnAngina, (v) => { this.dmHtnAngina = v; this.calculate(); }); }.width('100%').margin({ bottom: 14 });

        Text('— 生命体征').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 10 });
        Row() { Column() { Text('SBP < 100 mmHg').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); this.YesNoBtn(this.sbpLt100, (v) => { this.sbpLt100 = v; this.calculate(); }); }.layoutWeight(1);
          Column() { Text('HR > 100 / min').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); this.YesNoBtn(this.hrGt100, (v) => { this.hrGt100 = v; this.calculate(); }); }.layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 10 });
        Row() { Column() { Text('体重 < 67 kg').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); this.YesNoBtn(this.weightLt67, (v) => { this.weightLt67 = v; this.calculate(); }); }.layoutWeight(1); }.width('100%').margin({ bottom: 14 });

        Text('— 临床特征').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 10 });
        Column() { Text('Killip 分级').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
          Flex({ wrap: FlexWrap.Wrap }) {
            Button('I 无心衰').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.killip === 1 ? '#FFFFFF' : '#2D5440').backgroundColor(this.killip === 1 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.killip === 1 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(6).height(32).padding({ left: 8, right: 8 }).margin({ right: 6, bottom: 4 }).onClick(() => { this.killip = 1; this.calculate(); });
            Button('II 啰音/奔马律').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.killip === 2 ? '#FFFFFF' : '#2D5440').backgroundColor(this.killip === 2 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.killip === 2 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(6).height(32).padding({ left: 8, right: 8 }).margin({ right: 6, bottom: 4 }).onClick(() => { this.killip = 2; this.calculate(); });
            Button('III 肺水肿').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.killip === 3 ? '#FFFFFF' : '#2D5440').backgroundColor(this.killip === 3 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.killip === 3 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(6).height(32).padding({ left: 8, right: 8 }).margin({ right: 6, bottom: 4 }).onClick(() => { this.killip = 3; this.calculate(); });
            Button('IV 心源性休克').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.killip === 4 ? '#FFFFFF' : '#2D5440').backgroundColor(this.killip === 4 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.killip === 4 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(6).height(32).padding({ left: 8, right: 8 }).margin({ bottom: 4 }).onClick(() => { this.killip = 4; this.calculate(); });
          }.width('100%');
        }.width('100%').margin({ bottom: 10 });

        Row() { Text('前壁STEMI 或 LBBB').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1); this.YesNoBtn(this.anteriorLbbb, (v) => { this.anteriorLbbb = v; this.calculate(); }); }.width('100%').margin({ bottom: 10 });
        Row() { Text('就诊到再灌注 > 4h').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1); this.YesNoBtn(this.timeToTreat, (v) => { this.timeToTreat = v; this.calculate(); }); }.width('100%').margin({ bottom: 0 });
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() { Row() {
          Column() { Text('TIMI STEMI').fontSize(12).fontColor('#7A8074').letterSpacing(1.5).fontWeight(FontWeight.Medium);
            Text(this.result!.value !== null ? `${this.result!.value!.toFixed(0)} ${this.result!.unit}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor('#1F3D2F').margin({ top: 8 });
            Text(this.result!.tier).fontSize(13).fontWeight(FontWeight.Bold).fontColor(getTierColor(this.result!.tierClass)).backgroundColor(getTierBgColor(this.result!.tierClass)).borderRadius(20).padding({ left: 12, right: 12, top: 4, bottom: 4 }).margin({ top: 8 });
          }.alignItems(HorizontalAlign.Start).layoutWeight(1);
          Column() { Text(this.result!.footnote).fontSize(14).fontColor('#4A5247').lineHeight(22); }.layoutWeight(1).alignItems(HorizontalAlign.Start);
        }.width('100%'); }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%');
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(16).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}

@Component
export struct TimiNstemiCalculator {
  @State ageGte65: boolean = false;
  @State rfHtn: boolean = false;
  @State rfDm: boolean = false;
  @State rfSmoker: boolean = false;
  @State rfHyperlipid: boolean = false;
  @State rfFamily: boolean = false;
  @State knownCAD: boolean = false;
  @State priorAspirin: boolean = false;
  @State severeAngina: boolean = false;
  @State stDevGte05: boolean = false;
  @State biomarkerElevated: boolean = false;
  @State result: CalcResult | null = null;

  getRiskFactorCount(): number {
    let n = 0;
    if (this.rfHtn) n++; if (this.rfDm) n++; if (this.rfSmoker) n++; if (this.rfHyperlipid) n++; if (this.rfFamily) n++;
    return n;
  }
  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateTimiNstemi(this.ageGte65, this.getRiskFactorCount() >= 3, this.knownCAD, this.priorAspirin, this.severeAngina, this.stDevGte05, this.biomarkerElevated); }

  @Builder
  YesNoBtn(value: boolean, onSelect: (v: boolean) => void) {
    Row() { Button('否').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!value ? '#FFFFFF' : '#2D5440').backgroundColor(!value ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !value ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => onSelect(false));
      Button('是').fontSize(14).fontWeight(FontWeight.Bold).fontColor(value ? '#FFFFFF' : '#2D5440').backgroundColor(value ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: value ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).margin({ left: 4 }).onClick(() => onSelect(true));
    }.width(100);
  }

  build() {
    Column() {
      Column() { Text('TIMI NSTEMI — 非ST段抬高型心肌梗死/不稳定型心绞痛').fontSize(16).fontColor('#1F3D2F').fontWeight(FontWeight.Bold); Text('14天死亡/MI风险 · 0-7分 (Antman 2000)').fontSize(12).fontColor('#7A8074').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Text('— 患者因素').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 10 });
        Row() { Column() { Text('年龄 ≥ 65 岁').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); this.YesNoBtn(this.ageGte65, (v) => { this.ageGte65 = v; this.calculate(); }); }.layoutWeight(1);
          Column() { Text('冠脉狭窄 ≥ 50% (已知CAD)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); this.YesNoBtn(this.knownCAD, (v) => { this.knownCAD = v; this.calculate(); }); }.layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 14 });

        Text('— 临床特征').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 10 });
        Row() { Column() { Text('24h ≥ 2次心绞痛').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); this.YesNoBtn(this.severeAngina, (v) => { this.severeAngina = v; this.calculate(); }); }.layoutWeight(1);
          Column() { Text('7天内阿司匹林使用').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); this.YesNoBtn(this.priorAspirin, (v) => { this.priorAspirin = v; this.calculate(); }); }.layoutWeight(1).margin({ left: 12 });
        }.width('100%');

        Column() { Text('CAD 危险因素（≥ 3 项阳性 = 1分）').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ top: 10, bottom: 6 });
          Flex({ wrap: FlexWrap.Wrap }) {
            Button(this.rfHtn ? '✓ 高血压' : '高血压').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.rfHtn ? '#FFFFFF' : '#2D5440').backgroundColor(this.rfHtn ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.rfHtn ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(32).padding({ left: 8, right: 8 }).margin({ right: 6, bottom: 4 }).onClick(() => { this.rfHtn = !this.rfHtn; this.calculate(); });
            Button(this.rfDm ? '✓ 糖尿病' : '糖尿病').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.rfDm ? '#FFFFFF' : '#2D5440').backgroundColor(this.rfDm ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.rfDm ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(32).padding({ left: 8, right: 8 }).margin({ right: 6, bottom: 4 }).onClick(() => { this.rfDm = !this.rfDm; this.calculate(); });
            Button(this.rfSmoker ? '✓ 吸烟' : '吸烟').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.rfSmoker ? '#FFFFFF' : '#2D5440').backgroundColor(this.rfSmoker ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.rfSmoker ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(32).padding({ left: 8, right: 8 }).margin({ right: 6, bottom: 4 }).onClick(() => { this.rfSmoker = !this.rfSmoker; this.calculate(); });
            Button(this.rfHyperlipid ? '✓ 高脂血症' : '高脂血症').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.rfHyperlipid ? '#FFFFFF' : '#2D5440').backgroundColor(this.rfHyperlipid ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.rfHyperlipid ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(32).padding({ left: 8, right: 8 }).margin({ right: 6, bottom: 4 }).onClick(() => { this.rfHyperlipid = !this.rfHyperlipid; this.calculate(); });
            Button(this.rfFamily ? '✓ 家族史' : '家族史').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.rfFamily ? '#FFFFFF' : '#2D5440').backgroundColor(this.rfFamily ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.rfFamily ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(32).padding({ left: 8, right: 8 }).margin({ bottom: 4 }).onClick(() => { this.rfFamily = !this.rfFamily; this.calculate(); });
          }.width('100%');
          Text(`已选 ${this.getRiskFactorCount()}/5 · ≥ 3 项阳性`).fontSize(10).fontColor('#7A8074').margin({ top: 2 });
        }.width('100%').margin({ bottom: 14 });

        Text('— 检查').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 10 });
        Row() { Column() { Text('ST段偏移 ≥ 0.5mm').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); this.YesNoBtn(this.stDevGte05, (v) => { this.stDevGte05 = v; this.calculate(); }); }.layoutWeight(1);
          Column() { Text('心肌标志物升高').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); this.YesNoBtn(this.biomarkerElevated, (v) => { this.biomarkerElevated = v; this.calculate(); }); }.layoutWeight(1).margin({ left: 12 });
        }.width('100%');
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() { Row() {
          Column() { Text('TIMI NSTEMI').fontSize(12).fontColor('#7A8074').letterSpacing(1.5).fontWeight(FontWeight.Medium);
            Text(this.result!.value !== null ? `${this.result!.value!.toFixed(0)} ${this.result!.unit}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor('#1F3D2F').margin({ top: 8 });
            Text(this.result!.tier).fontSize(13).fontWeight(FontWeight.Bold).fontColor(getTierColor(this.result!.tierClass)).backgroundColor(getTierBgColor(this.result!.tierClass)).borderRadius(20).padding({ left: 12, right: 12, top: 4, bottom: 4 }).margin({ top: 8 });
          }.alignItems(HorizontalAlign.Start).layoutWeight(1);
          Column() { Text(this.result!.footnote).fontSize(14).fontColor('#4A5247').lineHeight(22); }.layoutWeight(1).alignItems(HorizontalAlign.Start);
        }.width('100%'); }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%');
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(16).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
