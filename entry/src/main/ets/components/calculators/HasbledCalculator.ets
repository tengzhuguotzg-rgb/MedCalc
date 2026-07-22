import { CalcResult } from '../../engine/CalcEngine';
import { calculateHasbled } from '../../engine/MoreCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, OptionChip, ResetButton, ResultCard } from './widgets/CalcWidgets';

@Component
export struct HasbledCalculator {
  @State resetKey: number = 0;  @State htn: number = -1;
  @State renal: number = -1;
  @State liver: number = -1;
  @State stroke: number = -1;
  @State bleed: number = -1;
  @State inr: number = -1;
  @State age: number = -1;
  @State drugs: number = -1;
  @State alcohol: number = -1;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    if (this.htn < 0 || this.renal < 0 || this.liver < 0 || this.stroke < 0 || this.bleed < 0 || this.inr < 0 || this.age < 0 || this.drugs < 0 || this.alcohol < 0) {
      this.result = { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
      return;
    }
    this.result = calculateHasbled(this.htn === 1, this.renal === 1, this.liver === 1, this.stroke === 1, this.bleed === 1, this.inr === 1, this.age === 1, this.drugs === 1, this.alcohol === 1);
  }

  reset() {
    this.htn = -1;
    this.renal = -1;
    this.liver = -1;
    this.stroke = -1;
    this.bleed = -1;
    this.inr = -1;
    this.age = -1;
    this.drugs = -1;
    this.alcohol = -1;
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
      Column() { Text('用于评估房颤患者抗凝治疗出血风险').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('7项：高血压+肾肝+卒中+出血+INR+年龄+药物/酒精，0-9分').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        Row() { Text('— 输入参数').fontSize(12).fontColor(AppColors.textSecondary).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); ResetButton({ onReset: () => { this.reset(); } }) }.width('100%').margin({ bottom: 12 });

        Row() { Text('H 高血压').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() { OptionChip({ label: '无', selected: this.htn === 0, fontSize: 14, bold: true, onChipClick: () => { this.htn = 0; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: '有', selected: this.htn === 1, fontSize: 14, bold: true, onChipClick: () => { this.htn = 1; this.calculate(); } }).layoutWeight(1);
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('A 肾功能异常').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() { OptionChip({ label: '无', selected: this.renal === 0, fontSize: 14, bold: true, onChipClick: () => { this.renal = 0; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: '有', selected: this.renal === 1, fontSize: 14, bold: true, onChipClick: () => { this.renal = 1; this.calculate(); } }).layoutWeight(1);
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('A 肝功能异常').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() { OptionChip({ label: '无', selected: this.liver === 0, fontSize: 14, bold: true, onChipClick: () => { this.liver = 0; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: '有', selected: this.liver === 1, fontSize: 14, bold: true, onChipClick: () => { this.liver = 1; this.calculate(); } }).layoutWeight(1);
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('S 卒中史').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() { OptionChip({ label: '无', selected: this.stroke === 0, fontSize: 14, bold: true, onChipClick: () => { this.stroke = 0; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: '有', selected: this.stroke === 1, fontSize: 14, bold: true, onChipClick: () => { this.stroke = 1; this.calculate(); } }).layoutWeight(1);
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('B 出血史').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() { OptionChip({ label: '无', selected: this.bleed === 0, fontSize: 14, bold: true, onChipClick: () => { this.bleed = 0; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: '有', selected: this.bleed === 1, fontSize: 14, bold: true, onChipClick: () => { this.bleed = 1; this.calculate(); } }).layoutWeight(1);
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('L 不稳定 INR').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() { OptionChip({ label: '无', selected: this.inr === 0, fontSize: 14, bold: true, onChipClick: () => { this.inr = 0; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: '有', selected: this.inr === 1, fontSize: 14, bold: true, onChipClick: () => { this.inr = 1; this.calculate(); } }).layoutWeight(1);
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('E 年龄 ≥ 65 岁').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() { OptionChip({ label: '无', selected: this.age === 0, fontSize: 14, bold: true, onChipClick: () => { this.age = 0; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: '有', selected: this.age === 1, fontSize: 14, bold: true, onChipClick: () => { this.age = 1; this.calculate(); } }).layoutWeight(1);
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('D 药物').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() { OptionChip({ label: '无', selected: this.drugs === 0, fontSize: 14, bold: true, onChipClick: () => { this.drugs = 0; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: '有', selected: this.drugs === 1, fontSize: 14, bold: true, onChipClick: () => { this.drugs = 1; this.calculate(); } }).layoutWeight(1);
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('D 酒精').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() { OptionChip({ label: '无', selected: this.alcohol === 0, fontSize: 14, bold: true, onChipClick: () => { this.alcohol = 0; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: '有', selected: this.alcohol === 1, fontSize: 14, bold: true, onChipClick: () => { this.alcohol = 1; this.calculate(); } }).layoutWeight(1);
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
      }

      if (this.result) {
        ResultCard({ title: 'HAS-BLED 总分', value: this.result!.value, unit: '', decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
