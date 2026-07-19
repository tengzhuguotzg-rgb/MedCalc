import { CalcResult } from '../../engine/CalcEngine';
import { calculateClifC } from '../../engine/ClifCCalculator';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, OptionChip, ResultCard } from './widgets/CalcWidgets';

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

      CalcCard() {
        Row() { Text('— 肝功能').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });

        Column() { Text('胆红素').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '胆红素' }).type(InputType.NUMBER_DECIMAL).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder).width('100%').onChange((value: string) => { this.bilirubin = parseFloat(value) || 0; this.calculate(); }); }.width('100%').margin({ bottom: 4 });
        Flex({ wrap: FlexWrap.Wrap }) {
          OptionChip({ label: 'µmol/L', selected: this.bilUnit === 'umol', fontSize: 12, bold: true, chipHeight: 28, chipRadius: 6, horizontalPadding: 6, onChipClick: () => { this.bilUnit = 'umol'; this.calculate(); } }).margin({ right: 4, bottom: 4 });
          OptionChip({ label: 'mg/dL', selected: this.bilUnit === 'mgdl', fontSize: 12, bold: true, chipHeight: 28, chipRadius: 6, horizontalPadding: 6, onChipClick: () => { this.bilUnit = 'mgdl'; this.calculate(); } }).margin({ bottom: 4 });
        }.width('100%').margin({ bottom: 8 });

        Column() { Text('INR').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: 'INR' }).type(InputType.NUMBER_DECIMAL).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder).width('100%').onChange((value: string) => { this.inr = parseFloat(value) || 0; this.calculate(); }); }.width('100%').margin({ bottom: 8 });

        Column() {
          Text('肝性脑病').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 });
          Flex({ wrap: FlexWrap.Wrap }) {
            OptionChip({ label: '0 无', selected: this.hepaticEnceph === 0, fontSize: 12, bold: true, chipHeight: 32, chipRadius: 6, horizontalPadding: 8, onChipClick: () => { this.hepaticEnceph = 0; this.calculate(); } }).margin({ right: 6, bottom: 4 });
            OptionChip({ label: 'I-II 级', selected: this.hepaticEnceph === 1, fontSize: 12, bold: true, chipHeight: 32, chipRadius: 6, horizontalPadding: 8, onChipClick: () => { this.hepaticEnceph = 1; this.calculate(); } }).margin({ right: 6, bottom: 4 });
            OptionChip({ label: 'III-IV 级', selected: this.hepaticEnceph === 2, fontSize: 12, bold: true, chipHeight: 32, chipRadius: 6, horizontalPadding: 8, onChipClick: () => { this.hepaticEnceph = 2; this.calculate(); } }).margin({ bottom: 4 });
          }.width('100%');
        }.width('100%').margin({ bottom: 16 });

        Text('— 肾功能').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });
        Column() { Text('肌酐').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '肌酐' }).type(InputType.NUMBER_DECIMAL).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder).width('100%').onChange((value: string) => { this.creatinine = parseFloat(value) || 0; this.calculate(); }); }.width('100%').margin({ bottom: 4 });
        Flex({ wrap: FlexWrap.Wrap }) {
          OptionChip({ label: 'µmol/L', selected: this.crUnit === 'umol', fontSize: 12, bold: true, chipHeight: 28, chipRadius: 6, horizontalPadding: 6, onChipClick: () => { this.crUnit = 'umol'; this.calculate(); } }).margin({ right: 4, bottom: 4 });
          OptionChip({ label: 'mg/dL', selected: this.crUnit === 'mgdl', fontSize: 12, bold: true, chipHeight: 28, chipRadius: 6, horizontalPadding: 6, onChipClick: () => { this.crUnit = 'mgdl'; this.calculate(); } }).margin({ bottom: 4 });
        }.width('100%').margin({ bottom: 16 });

        Text('— 循环').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });

        Column() { Text('MAP (mmHg)').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: 'MAP' }).type(InputType.NUMBER_DECIMAL).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder).width('100%').onChange((value: string) => { this.map = parseFloat(value) || 0; this.calculate(); }); }.width('100%').margin({ bottom: 8 });

        Column() {
          Text('血管活性药').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 });
          Flex({ wrap: FlexWrap.Wrap }) {
            OptionChip({ label: '无', selected: this.vaso === 'none', fontSize: 12, bold: true, chipHeight: 32, chipRadius: 6, horizontalPadding: 8, onChipClick: () => { this.vaso = 'none'; this.calculate(); } }).margin({ right: 6, bottom: 4 });
            OptionChip({ label: '低剂量', selected: this.vaso === 'low', fontSize: 12, bold: true, chipHeight: 32, chipRadius: 6, horizontalPadding: 8, onChipClick: () => { this.vaso = 'low'; this.calculate(); } }).margin({ right: 6, bottom: 4 });
            OptionChip({ label: '高剂量', selected: this.vaso === 'high', fontSize: 12, bold: true, chipHeight: 32, chipRadius: 6, horizontalPadding: 8, onChipClick: () => { this.vaso = 'high'; this.calculate(); } }).margin({ bottom: 4 });
          }.width('100%');
        }.width('100%').margin({ bottom: 16 });

        Text('— 呼吸').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });
        Row() {
          Column() { Text('PaO₂ (mmHg)').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: 'PaO2' }).type(InputType.NUMBER_DECIMAL).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder).width('100%').onChange((value: string) => { this.pao2 = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1);
          Column() { Text('FiO₂').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '0.21' }).type(InputType.NUMBER_DECIMAL).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder).width('100%').onChange((value: string) => { this.fio2 = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 8 });

        Row() {
          OptionChip({ label: '小数', selected: this.fio2Mode === 'dec', fontSize: 12, bold: true, chipHeight: 28, chipRadius: 6, onChipClick: () => { this.fio2Mode = 'dec'; this.calculate(); } }).layoutWeight(1).margin({ right: 4 });
          OptionChip({ label: '百分比', selected: this.fio2Mode === 'pct', fontSize: 12, bold: true, chipHeight: 28, chipRadius: 6, onChipClick: () => { this.fio2Mode = 'pct'; this.calculate(); } }).layoutWeight(1).margin({ left: 4 });
        }.width('100%').margin({ bottom: 16 });

        Text('— 患者参数').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });
        Row() {
          Column() { Text('年龄 (岁)').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '年龄' }).type(InputType.Number).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder).width('100%').onChange((value: string) => { this.age = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1);
          Column() { Text('WBC (×10⁹/L)').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: 'WBC' }).type(InputType.NUMBER_DECIMAL).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder).width('100%').onChange((value: string) => { this.wbc = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1).margin({ left: 8 });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'CLIF-C ACLF', value: this.result!.value, unit: this.result!.unit, decimals: 1, valueMarginTop: 4, tierMarginTop: 4, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
