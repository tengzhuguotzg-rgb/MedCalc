import { CalcResult, getTierColor, getTierBgColor } from '../../engine/CalcEngine';
import { calculateClifC } from '../../engine/ClifCCalculator';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';

@Component
export struct ClifCCalculator {
  @State resetKey: number = 0;
  @State bilirubin: number = 0;
  @State bilUnit: string = 'umol';
  @State inr: number = 0;
  @State hepaticEnceph: number = -1;
  @State map: number = 0;
  @State vaso: string = '';
  @State creatinine: number = 0;
  @State crUnit: string = 'umol';
  @State pao2: number = 0;
  @State fio2: number = 0;
  @State fio2Mode: string = 'dec';
  @State age: number = 0;
  @State wbc: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateClifC(this.bilirubin, this.bilUnit, this.creatinine, this.crUnit, this.inr, this.hepaticEnceph, this.map, this.vaso, this.pao2, this.fio2, this.fio2Mode, this.age, this.wbc); }

  reset() {
    this.bilirubin = 0;
    this.bilUnit = 'umol';
    this.inr = 0;
    this.hepaticEnceph = -1;
    this.map = 0;
    this.vaso = '';
    this.creatinine = 0;
    this.crUnit = 'umol';
    this.pao2 = 0;
    this.fio2 = 0;
    this.fio2Mode = 'dec';
    this.age = 0;
    this.wbc = 0;
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
      Column() { Text('用于慢加急性肝衰竭死亡率预测 (CLIF-C ACLF)').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('6器官评估(0-3) + 年龄 + WBC，连续评分 (Jalan 2014)').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Row() { Text('— 肝功能').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });

        Column() { Text('胆红素').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '胆红素' }).type(InputType.NUMBER_DECIMAL).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder).width('100%').onChange((value: string) => { this.bilirubin = parseFloat(value) || 0; this.calculate(); }); }.width('100%').margin({ bottom: 4 });
        Flex({ wrap: FlexWrap.Wrap }) {
          Button('µmol/L').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.bilUnit === 'umol' ? AppColors.card : AppColors.textOption).backgroundColor(this.bilUnit === 'umol' ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.bilUnit === 'umol' ? AppColors.primary : AppColors.border }).borderRadius(6).height(28).padding({ left: 6, right: 6 }).margin({ right: 4, bottom: 4 }).onClick(() => { this.bilUnit = 'umol'; this.calculate(); });
          Button('mg/dL').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.bilUnit === 'mgdl' ? AppColors.card : AppColors.textOption).backgroundColor(this.bilUnit === 'mgdl' ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.bilUnit === 'mgdl' ? AppColors.primary : AppColors.border }).borderRadius(6).height(28).padding({ left: 6, right: 6 }).margin({ bottom: 4 }).onClick(() => { this.bilUnit = 'mgdl'; this.calculate(); });
        }.width('100%').margin({ bottom: 8 });

        Column() { Text('INR').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: 'INR' }).type(InputType.NUMBER_DECIMAL).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder).width('100%').onChange((value: string) => { this.inr = parseFloat(value) || 0; this.calculate(); }); }.width('100%').margin({ bottom: 8 });

        Column() {
          Text('肝性脑病').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 });
          Flex({ wrap: FlexWrap.Wrap }) {
            Button('0 无').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.hepaticEnceph === 0 ? AppColors.card : AppColors.textOption).backgroundColor(this.hepaticEnceph === 0 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.hepaticEnceph === 0 ? AppColors.primary : AppColors.border }).borderRadius(6).height(32).padding({ left: 8, right: 8 }).margin({ right: 6, bottom: 4 }).onClick(() => { this.hepaticEnceph = 0; this.calculate(); });
            Button('I-II 级').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.hepaticEnceph === 1 ? AppColors.card : AppColors.textOption).backgroundColor(this.hepaticEnceph === 1 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.hepaticEnceph === 1 ? AppColors.primary : AppColors.border }).borderRadius(6).height(32).padding({ left: 8, right: 8 }).margin({ right: 6, bottom: 4 }).onClick(() => { this.hepaticEnceph = 1; this.calculate(); });
            Button('III-IV 级').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.hepaticEnceph === 2 ? AppColors.card : AppColors.textOption).backgroundColor(this.hepaticEnceph === 2 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.hepaticEnceph === 2 ? AppColors.primary : AppColors.border }).borderRadius(6).height(32).padding({ left: 8, right: 8 }).margin({ bottom: 4 }).onClick(() => { this.hepaticEnceph = 2; this.calculate(); });
          }.width('100%');
        }.width('100%').margin({ bottom: 16 });

        Text('— 肾功能').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });
        Column() { Text('肌酐').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '肌酐' }).type(InputType.NUMBER_DECIMAL).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder).width('100%').onChange((value: string) => { this.creatinine = parseFloat(value) || 0; this.calculate(); }); }.width('100%').margin({ bottom: 4 });
        Flex({ wrap: FlexWrap.Wrap }) {
          Button('µmol/L').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.crUnit === 'umol' ? AppColors.card : AppColors.textOption).backgroundColor(this.crUnit === 'umol' ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.crUnit === 'umol' ? AppColors.primary : AppColors.border }).borderRadius(6).height(28).padding({ left: 6, right: 6 }).margin({ right: 4, bottom: 4 }).onClick(() => { this.crUnit = 'umol'; this.calculate(); });
          Button('mg/dL').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.crUnit === 'mgdl' ? AppColors.card : AppColors.textOption).backgroundColor(this.crUnit === 'mgdl' ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.crUnit === 'mgdl' ? AppColors.primary : AppColors.border }).borderRadius(6).height(28).padding({ left: 6, right: 6 }).margin({ bottom: 4 }).onClick(() => { this.crUnit = 'mgdl'; this.calculate(); });
        }.width('100%').margin({ bottom: 16 });

        Text('— 循环').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });

        Column() { Text('MAP (mmHg)').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: 'MAP' }).type(InputType.NUMBER_DECIMAL).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder).width('100%').onChange((value: string) => { this.map = parseFloat(value) || 0; this.calculate(); }); }.width('100%').margin({ bottom: 8 });

        Column() {
          Text('血管活性药').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 });
          Flex({ wrap: FlexWrap.Wrap }) {
            Button('无').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.vaso === 'none' ? AppColors.card : AppColors.textOption).backgroundColor(this.vaso === 'none' ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.vaso === 'none' ? AppColors.primary : AppColors.border }).borderRadius(6).height(32).padding({ left: 8, right: 8 }).margin({ right: 6, bottom: 4 }).onClick(() => { this.vaso = 'none'; this.calculate(); });
            Button('低剂量').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.vaso === 'low' ? AppColors.card : AppColors.textOption).backgroundColor(this.vaso === 'low' ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.vaso === 'low' ? AppColors.primary : AppColors.border }).borderRadius(6).height(32).padding({ left: 8, right: 8 }).margin({ right: 6, bottom: 4 }).onClick(() => { this.vaso = 'low'; this.calculate(); });
            Button('高剂量').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.vaso === 'high' ? AppColors.card : AppColors.textOption).backgroundColor(this.vaso === 'high' ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.vaso === 'high' ? AppColors.primary : AppColors.border }).borderRadius(6).height(32).padding({ left: 8, right: 8 }).margin({ bottom: 4 }).onClick(() => { this.vaso = 'high'; this.calculate(); });
          }.width('100%');
        }.width('100%').margin({ bottom: 16 });

        Text('— 呼吸').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });
        Row() {
          Column() { Text('PaO₂ (mmHg)').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: 'PaO2' }).type(InputType.NUMBER_DECIMAL).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder).width('100%').onChange((value: string) => { this.pao2 = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1);
          Column() { Text('FiO₂').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '0.21' }).type(InputType.NUMBER_DECIMAL).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder).width('100%').onChange((value: string) => { this.fio2 = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 8 });

        Row() {
          Button('小数').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.fio2Mode === 'dec' ? AppColors.card : AppColors.textOption).backgroundColor(this.fio2Mode === 'dec' ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.fio2Mode === 'dec' ? AppColors.primary : AppColors.border }).borderRadius(6).height(28).layoutWeight(1).margin({ right: 4 }).onClick(() => { this.fio2Mode = 'dec'; this.calculate(); });
          Button('百分比').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.fio2Mode === 'pct' ? AppColors.card : AppColors.textOption).backgroundColor(this.fio2Mode === 'pct' ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.fio2Mode === 'pct' ? AppColors.primary : AppColors.border }).borderRadius(6).height(28).layoutWeight(1).margin({ left: 4 }).onClick(() => { this.fio2Mode = 'pct'; this.calculate(); });
        }.width('100%').margin({ bottom: 16 });

        Text('— 患者参数').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });
        Row() {
          Column() { Text('年龄 (岁)').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '年龄' }).type(InputType.Number).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder).width('100%').onChange((value: string) => { this.age = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1);
          Column() { Text('WBC (×10⁹/L)').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: 'WBC' }).type(InputType.NUMBER_DECIMAL).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder).width('100%').onChange((value: string) => { this.wbc = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1).margin({ left: 8 });
        }.width('100%');
      }.padding(AppDimens.cardPadding).backgroundColor(AppColors.card).borderRadius(AppDimens.cardRadius).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() { Text('CLIF-C ACLF').fontSize(12).fontColor(AppColors.textSecondary).letterSpacing(1.5).fontWeight(FontWeight.Medium);
              Text(this.result!.value !== null ? `${this.result!.value!.toFixed(1)} ${this.result!.unit}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor(AppColors.primary).margin({ top: 4 });
              Text(this.result!.tier).fontSize(13).fontWeight(FontWeight.Bold).fontColor(getTierColor(this.result!.tierClass))
                .backgroundColor(getTierBgColor(this.result!.tierClass)).borderRadius(20).padding({ left: 12, right: 12, top: 4, bottom: 4 }).margin({ top: 4 });
            }.alignItems(HorizontalAlign.Start).layoutWeight(1);
            Column() { Text(this.result!.footnote).fontSize(14).fontColor(AppColors.textBody).lineHeight(22); }.layoutWeight(1).alignItems(HorizontalAlign.Start);
          }.width('100%');
        }.padding(AppDimens.cardPadding).backgroundColor(AppColors.card).borderRadius(AppDimens.cardRadius).width('100%');
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
