import { CalcResult } from '../../engine/CalcEngine';
import { calculatePlasmic } from '../../engine/Batch2aCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct PlasmicCalculator {
  @State resetKey: number = 0;
  @State platelet: number = 0;
  @State hemolysisEvidence: boolean = false;
  @State activeCancer: boolean = false;
  @State transplant: boolean = false;
  @State mcv: number = 0;
  @State inr: number = 0;
  @State cr: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    const crMgDl = this.cr / 88.4;
    this.result = calculatePlasmic(this.platelet, this.hemolysisEvidence, this.activeCancer, this.transplant, this.mcv, this.inr, crMgDl);
  }

  reset() {
    this.platelet = 0;
    this.hemolysisEvidence = false;
    this.activeCancer = false;
    this.transplant = false;
    this.mcv = 0;
    this.inr = 0;
    this.cr = 0;
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
        Text('PLASMIC：TTP（ADAMTS13 重度缺乏）风险').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('6-7 分高风险：立即血浆置换并查 ADAMTS13').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '输入参数', resetAction: () => { this.reset(); } })
        Row() {
          InputRow({ label: '血小板 (×10⁹/L)', placeholder: 'PLT', onTextChange: (value: string) => { this.platelet = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: 'MCV (fL)', placeholder: 'MCV', onTextChange: (value: string) => { this.mcv = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        Row() {
          InputRow({ label: 'INR', placeholder: 'INR', onTextChange: (value: string) => { this.inr = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '肌酐 (μmol/L)', placeholder: 'Cr', onTextChange: (value: string) => { this.cr = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });

        Text('临床项').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row({ space: 8 }) {
          OptionChip({ label: '溶血证据', selected: this.hemolysisEvidence, onChipClick: () => { this.hemolysisEvidence = !this.hemolysisEvidence; this.calculate(); } });
          OptionChip({ label: '活动性肿瘤', selected: this.activeCancer, onChipClick: () => { this.activeCancer = !this.activeCancer; this.calculate(); } });
          OptionChip({ label: '实体器官/骨髓移植史', selected: this.transplant, onChipClick: () => { this.transplant = !this.transplant; this.calculate(); } });
        }.width('100%');
        Text('溶血证据=网织红>2.5%、结合珠蛋白测不出或间接胆红素>2 mg/dL 任一').fontSize(11).fontColor(AppColors.textSecondary).margin({ top: 6 });
      }

      if (this.result) {
        ResultCard({ title: 'PLASMIC', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding({ left: 16, right: 16, top: 8, bottom: 16 }).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
