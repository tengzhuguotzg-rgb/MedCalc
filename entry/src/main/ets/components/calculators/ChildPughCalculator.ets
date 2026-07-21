import { CalcResult } from '../../engine/CalcEngine';
import { calculateChildPugh } from '../../engine/ChildPughCalculator';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard } from './widgets/CalcWidgets';

@Component
export struct ChildPughCalculator {
  @State resetKey: number = 0;  @State bilirubin: number = 0;
  @State bilirubinUnit: string = 'umol';
  @State albumin: number = 0;
  @State albUnit: string = 'gl';
  @State inr: number = 0;
  @State ascites: number = 0;
  @State encephalopathy: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateChildPugh(this.bilirubin, this.bilirubinUnit, this.albumin, this.albUnit, this.inr, this.ascites, this.encephalopathy); }

  reset() {
    this.bilirubin = 0;
    this.bilirubinUnit = 'umol';
    this.albumin = 0;
    this.albUnit = 'gl';
    this.inr = 0;
    this.ascites = 0;
    this.encephalopathy = 0;
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
      Column() { Text('用于评估肝硬化患者肝功能储备及手术风险').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('5项：胆红素+白蛋白+INR+腹水+肝性脑病，A/B/C三级').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        Row() { Text('— 输入参数').fontSize(12).fontColor(AppColors.textSecondary).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });

        Row() {
          InputRow({ label: this.bilirubinUnit === 'umol' ? '胆红素 (µmol/L)' : '胆红素 (mg/dL)', placeholder: '请输入胆红素', onTextChange: (value: string) => { this.bilirubin = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: this.albUnit === 'gl' ? '白蛋白 (g/L)' : '白蛋白 (g/dL)', placeholder: '请输入白蛋白', onTextChange: (value: string) => { this.albumin = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });

        Row() {
          Text('胆红素单位').fontSize(12).fontColor(AppColors.textSecondary).layoutWeight(1);
          OptionChip({ label: 'µmol/L', selected: this.bilirubinUnit === 'umol', fontSize: 12, bold: true, onChipClick: () => { this.bilirubinUnit = 'umol'; this.calculate(); } });
          OptionChip({ label: 'mg/dL', selected: this.bilirubinUnit === 'mgdl', fontSize: 12, bold: true, onChipClick: () => { this.bilirubinUnit = 'mgdl'; this.calculate(); } }).margin({ left: 6 });
        }.width('100%').margin({ bottom: 8 });

        Row() {
          Text('白蛋白单位').fontSize(12).fontColor(AppColors.textSecondary).layoutWeight(1);
          OptionChip({ label: 'g/L', selected: this.albUnit === 'gl', fontSize: 12, bold: true, onChipClick: () => { this.albUnit = 'gl'; this.calculate(); } });
          OptionChip({ label: 'g/dL', selected: this.albUnit === 'gdl', fontSize: 12, bold: true, onChipClick: () => { this.albUnit = 'gdl'; this.calculate(); } }).margin({ left: 6 });
        }.width('100%').margin({ bottom: 8 });

        InputRow({ label: 'INR', placeholder: '请输入INR', inputType: InputType.NUMBER_DECIMAL, onTextChange: (value: string) => { this.inr = parseFloat(value) || 0; this.calculate(); } }).width('100%').margin({ bottom: 16 });

        Column() {
          Text('腹水').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 8 });
          Row() {
            OptionChip({ label: '无', selected: this.ascites === 1, fontSize: 12, bold: true, onChipClick: () => { this.ascites = 1; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: '轻度', selected: this.ascites === 2, fontSize: 12, bold: true, onChipClick: () => { this.ascites = 2; this.calculate(); } }).layoutWeight(1).margin({ left: 6 });
            OptionChip({ label: '中重度', selected: this.ascites === 3, fontSize: 12, bold: true, onChipClick: () => { this.ascites = 3; this.calculate(); } }).layoutWeight(1).margin({ left: 6 });
          }.width('100%');
        }.width('100%').margin({ bottom: 16 });

        Column() {
          Text('肝性脑病').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 8 });
          Row() {
            OptionChip({ label: '无', selected: this.encephalopathy === 1, fontSize: 12, bold: true, onChipClick: () => { this.encephalopathy = 1; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: 'I-II期', selected: this.encephalopathy === 2, fontSize: 12, bold: true, onChipClick: () => { this.encephalopathy = 2; this.calculate(); } }).layoutWeight(1).margin({ left: 6 });
            OptionChip({ label: 'III-IV期', selected: this.encephalopathy === 3, fontSize: 12, bold: true, onChipClick: () => { this.encephalopathy = 3; this.calculate(); } }).layoutWeight(1).margin({ left: 6 });
          }.width('100%');
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'Child-Pugh', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
