import { CalcResult } from '../../engine/CalcEngine';
import { calculateMcmahon } from '../../engine/Batch2aCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct McmahonCalculator {
  @State resetKey: number = 0;
  @State age: number = 0;
  @State sex: string = 'male';
  @State ck: number = 0;
  @State cr: number = 0;
  @State phos: number = 0;
  @State ca: number = 0;
  @State hco3: number = 0;
  @State lowRiskEtiology: boolean = false;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateMcmahon(this.age, this.sex, this.ck, this.cr, this.phos, this.ca, this.hco3, this.lowRiskEtiology); }

  reset() {
    this.age = 0;
    this.sex = 'male';
    this.ck = 0;
    this.cr = 0;
    this.phos = 0;
    this.ca = 0;
    this.hco3 = 0;
    this.lowRiskEtiology = false;
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
        Text('McMahon：横纹肌溶解 RRT/死亡风险').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('>10 分高危（RRT/死亡风险 >20%）').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '输入参数', resetAction: () => { this.reset(); } })
        Row() {
          InputRow({ label: '年龄 (岁)', placeholder: '年龄', onTextChange: (value: string) => { this.age = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          Column() {
            Text('性别').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            Row({ space: 8 }) {
              OptionChip({ label: '男', selected: this.sex === 'male', chipHeight: AppDimens.inputHeight, onChipClick: () => { this.sex = 'male'; this.calculate(); } });
              OptionChip({ label: '女', selected: this.sex === 'female', chipHeight: AppDimens.inputHeight, onChipClick: () => { this.sex = 'female'; this.calculate(); } });
            }
          }.layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        Row() {
          InputRow({ label: 'CK (U/L)', placeholder: 'CK', onTextChange: (value: string) => { this.ck = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '肌酐 (μmol/L)', placeholder: 'Cr', onTextChange: (value: string) => { this.cr = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        Row() {
          InputRow({ label: '血磷 (mmol/L，可空)', placeholder: 'P', onTextChange: (value: string) => { this.phos = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '血钙 (mmol/L，可空)', placeholder: 'Ca', onTextChange: (value: string) => { this.ca = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        InputRow({ label: 'HCO₃⁻ (mmol/L，可空)', placeholder: 'HCO3', onTextChange: (value: string) => { this.hco3 = parseFloat(value) || 0; this.calculate(); } }).margin({ bottom: 8 });

        Text('病因').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row({ space: 8 }) {
          OptionChip({ label: '癫痫/晕厥/运动/他汀/肌炎', selected: this.lowRiskEtiology, onChipClick: () => { this.lowRiskEtiology = true; this.calculate(); } });
          OptionChip({ label: '其他病因', selected: !this.lowRiskEtiology, onChipClick: () => { this.lowRiskEtiology = false; this.calculate(); } });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'McMahon 评分', value: this.result!.value, unit: this.result!.unit, decimals: 1, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
