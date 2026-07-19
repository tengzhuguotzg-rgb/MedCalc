import { CalcResult } from '../../engine/CalcEngine';
import { calculateChadsvasc } from '../../engine/MoreCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, OptionChip, ResultCard } from './widgets/CalcWidgets';

@Component
export struct ChadsvascCalculator {
  @State resetKey: number = 0;  @State chf: number = -1;
  @State htn: number = -1;
  @State age75: number = -1;
  @State dm: number = -1;
  @State stroke: number = -1;
  @State vasc: number = -1;
  @State age65: number = -1;
  @State female: number = -1;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    if (this.chf < 0 || this.htn < 0 || this.age75 < 0 || this.dm < 0 || this.stroke < 0 || this.vasc < 0 || this.age65 < 0 || this.female < 0) {
      this.result = { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
      return;
    }
    this.result = calculateChadsvasc(this.chf === 1, this.htn === 1, this.age75 === 1, this.dm === 1, this.stroke === 1, this.vasc === 1, this.age65 === 1, this.female === 1);
  }

  reset() {
    this.chf = -1;
    this.htn = -1;
    this.age75 = -1;
    this.dm = -1;
    this.stroke = -1;
    this.vasc = -1;
    this.age65 = -1;
    this.female = -1;
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
      Column() { Text('用于评估房颤患者脑卒中风险，指导抗凝决策').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('8项：心衰+高血压+年龄+糖尿病+卒中+血管病+性别，总分0-9').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        Row() { Text('— 输入参数').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });

        Row() { Text('C 心衰').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() { OptionChip({ label: '无', selected: this.chf === 0, fontSize: 14, bold: true, onChipClick: () => { this.chf = 0; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: '有', selected: this.chf === 1, fontSize: 14, bold: true, onChipClick: () => { this.chf = 1; this.calculate(); } }).layoutWeight(1);
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('H 高血压').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() { OptionChip({ label: '无', selected: this.htn === 0, fontSize: 14, bold: true, onChipClick: () => { this.htn = 0; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: '有', selected: this.htn === 1, fontSize: 14, bold: true, onChipClick: () => { this.htn = 1; this.calculate(); } }).layoutWeight(1);
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('A₂ 年龄 ≥ 75 岁').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() { OptionChip({ label: '无', selected: this.age75 === 0, fontSize: 14, bold: true, onChipClick: () => { this.age75 = 0; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: '有', selected: this.age75 === 1, fontSize: 14, bold: true, onChipClick: () => { this.age75 = 1; this.calculate(); } }).layoutWeight(1);
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('D 糖尿病').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() { OptionChip({ label: '无', selected: this.dm === 0, fontSize: 14, bold: true, onChipClick: () => { this.dm = 0; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: '有', selected: this.dm === 1, fontSize: 14, bold: true, onChipClick: () => { this.dm = 1; this.calculate(); } }).layoutWeight(1);
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('S₂ 卒中/TIA/血栓史').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() { OptionChip({ label: '无', selected: this.stroke === 0, fontSize: 14, bold: true, onChipClick: () => { this.stroke = 0; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: '有', selected: this.stroke === 1, fontSize: 14, bold: true, onChipClick: () => { this.stroke = 1; this.calculate(); } }).layoutWeight(1);
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('V 血管疾病').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() { OptionChip({ label: '无', selected: this.vasc === 0, fontSize: 14, bold: true, onChipClick: () => { this.vasc = 0; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: '有', selected: this.vasc === 1, fontSize: 14, bold: true, onChipClick: () => { this.vasc = 1; this.calculate(); } }).layoutWeight(1);
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('A 年龄 65-74 岁').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() { OptionChip({ label: '无', selected: this.age65 === 0, fontSize: 14, bold: true, onChipClick: () => { this.age65 = 0; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: '有', selected: this.age65 === 1, fontSize: 14, bold: true, onChipClick: () => { this.age65 = 1; this.calculate(); } }).layoutWeight(1);
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('Sc 女性').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() { OptionChip({ label: '无', selected: this.female === 0, fontSize: 14, bold: true, onChipClick: () => { this.female = 0; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: '有', selected: this.female === 1, fontSize: 14, bold: true, onChipClick: () => { this.female = 1; this.calculate(); } }).layoutWeight(1);
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
      }

      if (this.result) {
        ResultCard({ title: 'CHADS₂-VASc 总分', value: this.result!.value, unit: '', decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
