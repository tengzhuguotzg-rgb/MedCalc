import { CalcResult } from '../../engine/CalcEngine';
import { calculateMehran } from '../../engine/MehranCalculator';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard } from './widgets/CalcWidgets';

@Component
export struct MehranCalculator {
  @State resetKey: number = 0;  @State age: number = 0;
  @State chf: number = -1;
  @State dm: number = -1;
  @State gfr: number = 0;
  @State contrastVol: number = 0;
  @State anemia: number = -1;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    if (this.chf < 0 || this.dm < 0 || this.anemia < 0) {
      this.result = { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
      return;
    }
    this.result = calculateMehran(this.age, this.chf === 1, this.dm === 1, this.gfr, this.contrastVol, this.anemia === 1);
  }

  reset() {
    this.age = 0;
    this.chf = -1;
    this.dm = -1;
    this.gfr = 0;
    this.contrastVol = 0;
    this.anemia = -1;
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
      Column() { Text('用于预测冠脉介入后造影剂肾病风险').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('8项：低血压+IABP+心衰+年龄+贫血+糖尿病+造影剂+肌酐/eGFR').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        Row() { Text('— 输入参数').fontSize(12).fontColor(AppColors.textSecondary).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });

        Row() {
          InputRow({ label: '年龄 (岁)', placeholder: '请输入年龄', onTextChange: (value: string) => { this.age = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: 'eGFR (mL/min)', placeholder: '请输入eGFR', onTextChange: (value: string) => { this.gfr = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 16 });

        InputRow({ label: '造影剂用量 (mL)', placeholder: '请输入用量', onTextChange: (value: string) => { this.contrastVol = parseFloat(value) || 0; this.calculate(); } }).width('100%').margin({ bottom: 16 });

        Row() { Text('心力衰竭').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() { OptionChip({ label: '无', selected: this.chf === 0, fontSize: 14, bold: true, onChipClick: () => { this.chf = 0; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: '有', selected: this.chf === 1, fontSize: 14, bold: true, onChipClick: () => { this.chf = 1; this.calculate(); } }).layoutWeight(1);
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('糖尿病').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() { OptionChip({ label: '无', selected: this.dm === 0, fontSize: 14, bold: true, onChipClick: () => { this.dm = 0; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: '有', selected: this.dm === 1, fontSize: 14, bold: true, onChipClick: () => { this.dm = 1; this.calculate(); } }).layoutWeight(1);
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('贫血').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() { OptionChip({ label: '无', selected: this.anemia === 0, fontSize: 14, bold: true, onChipClick: () => { this.anemia = 0; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: '有', selected: this.anemia === 1, fontSize: 14, bold: true, onChipClick: () => { this.anemia = 1; this.calculate(); } }).layoutWeight(1);
          }.width(100);
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'Mehran', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
