import { CalcResult } from '../../engine/CalcEngine';
import { calculateAarc } from '../../engine/AarcCalculator';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard } from './widgets/CalcWidgets';

@Component
export struct AarcCalculator {
  @State resetKey: number = 0;  @State bilirubin: number = 0;
  @State bilUnit: string = 'umol';
  @State inr: number = 0;
  @State lactate: number = 0;
  @State hepaticEnceph: number = -1;
  @State age: number = 0;
  @State acKf: number = -1;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    if (this.acKf < 0) {
      this.result = { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
      return;
    }
    this.result = calculateAarc(this.bilirubin, this.bilUnit, this.inr, this.lactate, this.hepaticEnceph, this.age, this.acKf === 1);
  }

  reset() {
    this.bilirubin = 0;
    this.bilUnit = 'umol';
    this.inr = 0;
    this.lactate = 0;
    this.hepaticEnceph = -1;
    this.age = 0;
    this.acKf = -1;
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
      Column() { Text('用于评估慢加急性肝衰竭严重程度及预后').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('5项指标：胆红素 + INR + 乳酸 + 肝性脑病 + 年龄 + AKI').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        Row() { Text('— 输入参数').fontSize(12).fontColor(AppColors.textSecondary).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });

        InputRow({ label: '胆红素', placeholder: '请输入', inputType: InputType.NUMBER_DECIMAL, onTextChange: (value: string) => { this.bilirubin = parseFloat(value) || 0; this.calculate(); } }).width('100%').margin({ bottom: 6 });
        Row() { OptionChip({ label: 'µmol/L', selected: this.bilUnit === 'umol', fontSize: 12, bold: true, chipHeight: 32, onChipClick: () => { this.bilUnit = 'umol'; this.calculate(); } }).layoutWeight(1);
          OptionChip({ label: 'mg/dL', selected: this.bilUnit === 'mgdl', fontSize: 12, bold: true, chipHeight: 32, onChipClick: () => { this.bilUnit = 'mgdl'; this.calculate(); } }).layoutWeight(1).margin({ left: 6 });
        }.width('100%').margin({ bottom: 12 });

        Row() {
          InputRow({ label: 'INR', placeholder: '请输入', inputType: InputType.NUMBER_DECIMAL, onTextChange: (value: string) => { this.inr = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '乳酸 (mmol/L)', placeholder: '请输入', inputType: InputType.NUMBER_DECIMAL, onTextChange: (value: string) => { this.lactate = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 12 });

        Column() {
          Text('肝性脑病').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 8 });
          Row() {
            OptionChip({ label: '0', selected: this.hepaticEnceph === 0, bold: true, onChipClick: () => { this.hepaticEnceph = 0; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: 'I-II', selected: this.hepaticEnceph === 1, fontSize: 12, bold: true, onChipClick: () => { this.hepaticEnceph = 1; this.calculate(); } }).layoutWeight(1).margin({ left: 6 });
            OptionChip({ label: 'III-IV', selected: this.hepaticEnceph === 2, fontSize: 12, bold: true, onChipClick: () => { this.hepaticEnceph = 2; this.calculate(); } }).layoutWeight(1).margin({ left: 6 });
            OptionChip({ label: 'V', selected: this.hepaticEnceph === 3, bold: true, onChipClick: () => { this.hepaticEnceph = 3; this.calculate(); } }).layoutWeight(1).margin({ left: 6 });
          }.width('100%');
        }.width('100%').margin({ bottom: 12 });

        InputRow({ label: '年龄 (岁)', placeholder: '请输入年龄', onTextChange: (value: string) => { this.age = parseFloat(value) || 0; this.calculate(); } }).width('100%').margin({ bottom: 12 });

        Row() { Text('急性肾衰竭').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() { OptionChip({ label: '无', selected: this.acKf === 0, fontSize: 14, bold: true, onChipClick: () => { this.acKf = 0; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: '有', selected: this.acKf === 1, fontSize: 14, bold: true, onChipClick: () => { this.acKf = 1; this.calculate(); } }).layoutWeight(1);
          }.width(100);
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'AARC', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
