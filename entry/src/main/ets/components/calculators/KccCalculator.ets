import { CalcResult } from '../../engine/CalcEngine';
import { calculateKcc } from '../../engine/KccCalculator';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard } from './widgets/CalcWidgets';

@Component
export struct KccCalculator {
  @State resetKey: number = 0;  @State inr: number = 0;
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

  reset() {
    this.inr = 0;
    this.bilirubin = 0;
    this.bilirubinUnit = 'umol';
    this.age = 0;
    this.etiology = -1;
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
      Column() { Text('用于急性肝衰竭紧急肝移植决策').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('对乙酰氨基酚/非对乙酰氨基酚两种标准评估').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        Row() { Text('— 输入参数').fontSize(12).fontColor(AppColors.textSecondary).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });

        Row() {
          InputRow({ label: 'INR', placeholder: '请输入INR', inputType: InputType.NUMBER_DECIMAL, onTextChange: (value: string) => { this.inr = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: this.bilirubinUnit === 'umol' ? '胆红素 (µmol/L)' : '胆红素 (mg/dL)', placeholder: '请输入胆红素', onTextChange: (value: string) => { this.bilirubin = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });

        Row() {
          Text('胆红素单位').fontSize(12).fontColor(AppColors.textSecondary).layoutWeight(1);
          OptionChip({ label: 'µmol/L', selected: this.bilirubinUnit === 'umol', fontSize: 12, bold: true, onChipClick: () => { this.bilirubinUnit = 'umol'; this.calculate(); } });
          OptionChip({ label: 'mg/dL', selected: this.bilirubinUnit === 'mgdl', fontSize: 12, bold: true, onChipClick: () => { this.bilirubinUnit = 'mgdl'; this.calculate(); } }).margin({ left: 6 });
        }.width('100%').margin({ bottom: 8 });

        InputRow({ label: '年龄 (岁)', placeholder: '请输入年龄', onTextChange: (value: string) => { this.age = parseFloat(value) || 0; this.calculate(); } }).width('100%').margin({ bottom: 16 });

        Row() { Text('病因：扑热息痛/不明原因').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() { OptionChip({ label: '否', selected: this.etiology === 0, fontSize: 14, bold: true, onChipClick: () => { this.etiology = 0; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: '是', selected: this.etiology === 1, fontSize: 14, bold: true, onChipClick: () => { this.etiology = 1; this.calculate(); } }).layoutWeight(1);
          }.width(100);
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'KCC', value: this.result!.value, valueText: this.result!.value === 1 ? '符合' : '不符合', tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
