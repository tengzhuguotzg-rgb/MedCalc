import { CalcResult } from '../../engine/CalcEngine';
import { calculateTimiStemi, calculateTimiNstemi } from '../../engine/TimiCalculator';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, ResetButton, ResultCard } from './widgets/CalcWidgets';

@Component
export struct TimiStemiCalculator {
  @State resetKey: number = 0;
  @State ageCat: number = -1;
  @State sbpLt100: number = -1;
  @State hrGt100: number = -1;
  @State weightLt67: number = -1;
  @State dmHtnAngina: number = -1;
  @State killip: number = 0;
  @State anteriorLbbb: number = -1;
  @State timeToTreat: number = -1;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    if (this.ageCat < 0 || this.dmHtnAngina < 0 || this.sbpLt100 < 0 || this.hrGt100 < 0 || this.killip < 1
      || this.weightLt67 < 0 || this.anteriorLbbb < 0 || this.timeToTreat < 0) {
      this.result = { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
      return;
    }
    this.result = calculateTimiStemi(this.ageCat, this.dmHtnAngina === 1, this.sbpLt100 === 1, this.hrGt100 === 1, this.killip, this.weightLt67 === 1, this.anteriorLbbb === 1, this.timeToTreat === 1);
  }

  @Builder
  YesNoBtn(value: number, onSelect: (v: number) => void) {
    Row() {
      Button('否')
        .fontSize(14).fontWeight(FontWeight.Bold)
        .fontColor(value === 0 ? AppColors.card : AppColors.textOption)
        .backgroundColor(value === 0 ? AppColors.primary : AppColors.fillNeutral)
        .border({ width: 1, color: value === 0 ? AppColors.primary : AppColors.border })
        .borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1)
        .onClick(() => onSelect(0));
      Button('是')
        .fontSize(14).fontWeight(FontWeight.Bold)
        .fontColor(value === 1 ? AppColors.card : AppColors.textOption)
        .backgroundColor(value === 1 ? AppColors.primary : AppColors.fillNeutral)
        .border({ width: 1, color: value === 1 ? AppColors.primary : AppColors.border })
        .borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1)
        .margin({ left: 4 })
        .onClick(() => onSelect(1));
    }.width(100);
  }

  reset() {
    this.ageCat = -1;
    this.sbpLt100 = -1;
    this.hrGt100 = -1;
    this.weightLt67 = -1;
    this.dmHtnAngina = -1;
    this.killip = 0;
    this.anteriorLbbb = -1;
    this.timeToTreat = -1;
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
      Column() {
        Text('TIMI STEMI — ST段抬高型心肌梗死')
          .fontSize(16).fontColor(AppColors.primary).fontWeight(FontWeight.Bold);
        Text('30天死亡风险 · 0-14分 (InTIME-II 2000)')
          .fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        Row() {
          Text('— 患者因素').fontSize(12).fontColor(AppColors.textSecondary).fontWeight(FontWeight.Bold).letterSpacing(1.5);
          Blank();
          ResetButton({ onReset: () => { this.reset(); } })
        }.width('100%').margin({ bottom: 10 });
        Column() {
          Text('年龄').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 });
          Flex({ wrap: FlexWrap.Wrap }) {
            Button('< 55')
              .fontSize(12).fontWeight(FontWeight.Bold)
              .fontColor(this.ageCat === 0 ? AppColors.card : AppColors.textOption)
              .backgroundColor(this.ageCat === 0 ? AppColors.primary : AppColors.fillNeutral)
              .border({ width: 1, color: this.ageCat === 0 ? AppColors.primary : AppColors.border })
              .borderRadius(6).height(32).padding({ left: 10, right: 10 })
              .margin({ right: 6, bottom: 4 })
              .onClick(() => { this.ageCat = 0; this.calculate(); });
            Button('55-64')
              .fontSize(12).fontWeight(FontWeight.Bold)
              .fontColor(this.ageCat === 1 ? AppColors.card : AppColors.textOption)
              .backgroundColor(this.ageCat === 1 ? AppColors.primary : AppColors.fillNeutral)
              .border({ width: 1, color: this.ageCat === 1 ? AppColors.primary : AppColors.border })
              .borderRadius(6).height(32).padding({ left: 10, right: 10 })
              .margin({ right: 6, bottom: 4 })
              .onClick(() => { this.ageCat = 1; this.calculate(); });
            Button('65-74')
              .fontSize(12).fontWeight(FontWeight.Bold)
              .fontColor(this.ageCat === 2 ? AppColors.card : AppColors.textOption)
              .backgroundColor(this.ageCat === 2 ? AppColors.primary : AppColors.fillNeutral)
              .border({ width: 1, color: this.ageCat === 2 ? AppColors.primary : AppColors.border })
              .borderRadius(6).height(32).padding({ left: 10, right: 10 })
              .margin({ right: 6, bottom: 4 })
              .onClick(() => { this.ageCat = 2; this.calculate(); });
            Button('≥ 75')
              .fontSize(12).fontWeight(FontWeight.Bold)
              .fontColor(this.ageCat === 3 ? AppColors.card : AppColors.textOption)
              .backgroundColor(this.ageCat === 3 ? AppColors.primary : AppColors.fillNeutral)
              .border({ width: 1, color: this.ageCat === 3 ? AppColors.primary : AppColors.border })
              .borderRadius(6).height(32).padding({ left: 10, right: 10 })
              .margin({ bottom: 4 })
              .onClick(() => { this.ageCat = 3; this.calculate(); });
          }.width('100%');
        }.width('100%').margin({ bottom: 10 });

        Row() {
          Text('糖尿病/高血压/心绞痛').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          this.YesNoBtn(this.dmHtnAngina, (v) => { this.dmHtnAngina = v; this.calculate(); });
        }.width('100%').margin({ bottom: 14 });

        Text('— 生命体征').fontSize(12).fontColor(AppColors.textSecondary).fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 10 });
        Row() {
          Column() {
            Text('SBP < 100 mmHg').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 });
            this.YesNoBtn(this.sbpLt100, (v) => { this.sbpLt100 = v; this.calculate(); });
          }.layoutWeight(1);
          Column() {
            Text('HR > 100 / min').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 });
            this.YesNoBtn(this.hrGt100, (v) => { this.hrGt100 = v; this.calculate(); });
          }.layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 10 });
        Row() {
          Column() {
            Text('体重 < 67 kg').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 });
            this.YesNoBtn(this.weightLt67, (v) => { this.weightLt67 = v; this.calculate(); });
          }.layoutWeight(1);
        }.width('100%').margin({ bottom: 14 });

        Text('— 临床特征').fontSize(12).fontColor(AppColors.textSecondary).fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 10 });
        Column() {
          Text('Killip 分级').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
          Flex({ wrap: FlexWrap.Wrap }) {
            Button('I 无心衰')
              .fontSize(12).fontWeight(FontWeight.Bold)
              .fontColor(this.killip === 1 ? AppColors.card : AppColors.textOption)
              .backgroundColor(this.killip === 1 ? AppColors.primary : AppColors.fillNeutral)
              .border({ width: 1, color: this.killip === 1 ? AppColors.primary : AppColors.border })
              .borderRadius(6).height(32).padding({ left: 8, right: 8 })
              .margin({ right: 6, bottom: 4 })
              .onClick(() => { this.killip = 1; this.calculate(); });
            Button('II 啰音/奔马律')
              .fontSize(12).fontWeight(FontWeight.Bold)
              .fontColor(this.killip === 2 ? AppColors.card : AppColors.textOption)
              .backgroundColor(this.killip === 2 ? AppColors.primary : AppColors.fillNeutral)
              .border({ width: 1, color: this.killip === 2 ? AppColors.primary : AppColors.border })
              .borderRadius(6).height(32).padding({ left: 8, right: 8 })
              .margin({ right: 6, bottom: 4 })
              .onClick(() => { this.killip = 2; this.calculate(); });
            Button('III 肺水肿')
              .fontSize(12).fontWeight(FontWeight.Bold)
              .fontColor(this.killip === 3 ? AppColors.card : AppColors.textOption)
              .backgroundColor(this.killip === 3 ? AppColors.primary : AppColors.fillNeutral)
              .border({ width: 1, color: this.killip === 3 ? AppColors.primary : AppColors.border })
              .borderRadius(6).height(32).padding({ left: 8, right: 8 })
              .margin({ right: 6, bottom: 4 })
              .onClick(() => { this.killip = 3; this.calculate(); });
            Button('IV 心源性休克')
              .fontSize(12).fontWeight(FontWeight.Bold)
              .fontColor(this.killip === 4 ? AppColors.card : AppColors.textOption)
              .backgroundColor(this.killip === 4 ? AppColors.primary : AppColors.fillNeutral)
              .border({ width: 1, color: this.killip === 4 ? AppColors.primary : AppColors.border })
              .borderRadius(6).height(32).padding({ left: 8, right: 8 })
              .margin({ bottom: 4 })
              .onClick(() => { this.killip = 4; this.calculate(); });
          }.width('100%');
        }.width('100%').margin({ bottom: 10 });

        Row() {
          Text('前壁STEMI 或 LBBB').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          this.YesNoBtn(this.anteriorLbbb, (v) => { this.anteriorLbbb = v; this.calculate(); });
        }.width('100%').margin({ bottom: 10 });
        Row() {
          Text('就诊到再灌注 > 4h').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          this.YesNoBtn(this.timeToTreat, (v) => { this.timeToTreat = v; this.calculate(); });
        }.width('100%').margin({ bottom: 0 });
      }

      if (this.result) {
        ResultCard({ title: 'TIMI STEMI', value: this.result!.value, unit: this.result!.unit, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}

@Component
export struct TimiNstemiCalculator {
  @State resetKey: number = 0;
  @State ageGte65: number = -1;
  @State rfHtn: number = -1;
  @State rfDm: number = -1;
  @State rfSmoker: number = -1;
  @State rfHyperlipid: number = -1;
  @State rfFamily: number = -1;
  @State knownCAD: number = -1;
  @State priorAspirin: number = -1;
  @State severeAngina: number = -1;
  @State stDevGte05: number = -1;
  @State biomarkerElevated: number = -1;
  @State result: CalcResult | null = null;

  getRiskFactorCount(): number {
    let n = 0;
    if (this.rfHtn === 1) n++;
    if (this.rfDm === 1) n++;
    if (this.rfSmoker === 1) n++;
    if (this.rfHyperlipid === 1) n++;
    if (this.rfFamily === 1) n++;
    return n;
  }
  aboutToAppear() { this.calculate(); }
  calculate() {
    if (this.ageGte65 < 0 || this.rfHtn < 0 || this.rfDm < 0 || this.rfSmoker < 0 || this.rfHyperlipid < 0 || this.rfFamily < 0
      || this.knownCAD < 0 || this.priorAspirin < 0 || this.severeAngina < 0 || this.stDevGte05 < 0 || this.biomarkerElevated < 0) {
      this.result = { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
      return;
    }
    this.result = calculateTimiNstemi(this.ageGte65 === 1, this.getRiskFactorCount() >= 3, this.knownCAD === 1, this.priorAspirin === 1, this.severeAngina === 1, this.stDevGte05 === 1, this.biomarkerElevated === 1);
  }

  @Builder
  YesNoBtn(value: number, onSelect: (v: number) => void) {
    Row() {
      Button('否')
        .fontSize(14).fontWeight(FontWeight.Bold)
        .fontColor(value === 0 ? AppColors.card : AppColors.textOption)
        .backgroundColor(value === 0 ? AppColors.primary : AppColors.fillNeutral)
        .border({ width: 1, color: value === 0 ? AppColors.primary : AppColors.border })
        .borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1)
        .onClick(() => onSelect(0));
      Button('是')
        .fontSize(14).fontWeight(FontWeight.Bold)
        .fontColor(value === 1 ? AppColors.card : AppColors.textOption)
        .backgroundColor(value === 1 ? AppColors.primary : AppColors.fillNeutral)
        .border({ width: 1, color: value === 1 ? AppColors.primary : AppColors.border })
        .borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1)
        .margin({ left: 4 })
        .onClick(() => onSelect(1));
    }.width(100);
  }

  reset() {
    this.ageGte65 = -1;
    this.rfHtn = -1;
    this.rfDm = -1;
    this.rfSmoker = -1;
    this.rfHyperlipid = -1;
    this.rfFamily = -1;
    this.knownCAD = -1;
    this.priorAspirin = -1;
    this.severeAngina = -1;
    this.stDevGte05 = -1;
    this.biomarkerElevated = -1;
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
      Column() {
        Text('TIMI NSTEMI — 非ST段抬高型心肌梗死/不稳定型心绞痛')
          .fontSize(16).fontColor(AppColors.primary).fontWeight(FontWeight.Bold);
        Text('14天死亡/MI风险 · 0-7分 (Antman 2000)')
          .fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        Row() {
          Text('— 患者因素').fontSize(12).fontColor(AppColors.textSecondary).fontWeight(FontWeight.Bold).letterSpacing(1.5);
          Blank();
          ResetButton({ onReset: () => { this.reset(); } })
        }.width('100%').margin({ bottom: 10 });
        Row() {
          Column() {
            Text('年龄 ≥ 65 岁').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 });
            this.YesNoBtn(this.ageGte65, (v) => { this.ageGte65 = v; this.calculate(); });
          }.layoutWeight(1);
          Column() {
            Text('冠脉狭窄 ≥ 50% (已知CAD)').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 });
            this.YesNoBtn(this.knownCAD, (v) => { this.knownCAD = v; this.calculate(); });
          }.layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 14 });

        Text('— 临床特征').fontSize(12).fontColor(AppColors.textSecondary).fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 10 });
        Row() {
          Column() {
            Text('24h ≥ 2次心绞痛').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 });
            this.YesNoBtn(this.severeAngina, (v) => { this.severeAngina = v; this.calculate(); });
          }.layoutWeight(1);
          Column() {
            Text('7天内阿司匹林使用').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 });
            this.YesNoBtn(this.priorAspirin, (v) => { this.priorAspirin = v; this.calculate(); });
          }.layoutWeight(1).margin({ left: 12 });
        }.width('100%');

        Column() {
          Text('CAD 危险因素（≥ 3 项阳性 = 1分）').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ top: 10, bottom: 6 });
          Flex({ wrap: FlexWrap.Wrap }) {
            Button(this.rfHtn === 1 ? '✓ 高血压' : (this.rfHtn === 0 ? '✗ 高血压' : '高血压'))
              .fontSize(12).fontWeight(FontWeight.Bold)
              .fontColor(this.rfHtn === 1 ? AppColors.card : AppColors.textOption)
              .backgroundColor(this.rfHtn === 1 ? AppColors.primary : AppColors.fillNeutral)
              .border({ width: 1, color: this.rfHtn === 1 ? AppColors.primary : AppColors.border })
              .borderRadius(8).height(32).padding({ left: 8, right: 8 })
              .margin({ right: 6, bottom: 4 })
              .onClick(() => { this.rfHtn = this.rfHtn === 1 ? 0 : 1; this.calculate(); });
            Button(this.rfDm === 1 ? '✓ 糖尿病' : (this.rfDm === 0 ? '✗ 糖尿病' : '糖尿病'))
              .fontSize(12).fontWeight(FontWeight.Bold)
              .fontColor(this.rfDm === 1 ? AppColors.card : AppColors.textOption)
              .backgroundColor(this.rfDm === 1 ? AppColors.primary : AppColors.fillNeutral)
              .border({ width: 1, color: this.rfDm === 1 ? AppColors.primary : AppColors.border })
              .borderRadius(8).height(32).padding({ left: 8, right: 8 })
              .margin({ right: 6, bottom: 4 })
              .onClick(() => { this.rfDm = this.rfDm === 1 ? 0 : 1; this.calculate(); });
            Button(this.rfSmoker === 1 ? '✓ 吸烟' : (this.rfSmoker === 0 ? '✗ 吸烟' : '吸烟'))
              .fontSize(12).fontWeight(FontWeight.Bold)
              .fontColor(this.rfSmoker === 1 ? AppColors.card : AppColors.textOption)
              .backgroundColor(this.rfSmoker === 1 ? AppColors.primary : AppColors.fillNeutral)
              .border({ width: 1, color: this.rfSmoker === 1 ? AppColors.primary : AppColors.border })
              .borderRadius(8).height(32).padding({ left: 8, right: 8 })
              .margin({ right: 6, bottom: 4 })
              .onClick(() => { this.rfSmoker = this.rfSmoker === 1 ? 0 : 1; this.calculate(); });
            Button(this.rfHyperlipid === 1 ? '✓ 高脂血症' : (this.rfHyperlipid === 0 ? '✗ 高脂血症' : '高脂血症'))
              .fontSize(12).fontWeight(FontWeight.Bold)
              .fontColor(this.rfHyperlipid === 1 ? AppColors.card : AppColors.textOption)
              .backgroundColor(this.rfHyperlipid === 1 ? AppColors.primary : AppColors.fillNeutral)
              .border({ width: 1, color: this.rfHyperlipid === 1 ? AppColors.primary : AppColors.border })
              .borderRadius(8).height(32).padding({ left: 8, right: 8 })
              .margin({ right: 6, bottom: 4 })
              .onClick(() => { this.rfHyperlipid = this.rfHyperlipid === 1 ? 0 : 1; this.calculate(); });
            Button(this.rfFamily === 1 ? '✓ 家族史' : (this.rfFamily === 0 ? '✗ 家族史' : '家族史'))
              .fontSize(12).fontWeight(FontWeight.Bold)
              .fontColor(this.rfFamily === 1 ? AppColors.card : AppColors.textOption)
              .backgroundColor(this.rfFamily === 1 ? AppColors.primary : AppColors.fillNeutral)
              .border({ width: 1, color: this.rfFamily === 1 ? AppColors.primary : AppColors.border })
              .borderRadius(8).height(32).padding({ left: 8, right: 8 })
              .margin({ bottom: 4 })
              .onClick(() => { this.rfFamily = this.rfFamily === 1 ? 0 : 1; this.calculate(); });
          }.width('100%');
          Text(`已选 ${this.getRiskFactorCount()}/5 · ≥ 3 项阳性`).fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
        }.width('100%').margin({ bottom: 14 });

        Text('— 检查').fontSize(12).fontColor(AppColors.textSecondary).fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 10 });
        Row() {
          Column() {
            Text('ST段偏移 ≥ 0.5mm').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 });
            this.YesNoBtn(this.stDevGte05, (v) => { this.stDevGte05 = v; this.calculate(); });
          }.layoutWeight(1);
          Column() {
            Text('心肌标志物升高').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 });
            this.YesNoBtn(this.biomarkerElevated, (v) => { this.biomarkerElevated = v; this.calculate(); });
          }.layoutWeight(1).margin({ left: 12 });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'TIMI NSTEMI', value: this.result!.value, unit: this.result!.unit, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
