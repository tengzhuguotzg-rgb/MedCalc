import { CalcResult } from '../../engine/CalcEngine';
import { calculateCrusade } from '../../engine/Batch2bCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct CrusadeCalculator {
  @State resetKey: number = 0;
  @State hct: number = 0;
  @State crcl: number = 0;
  @State hr: number = 0;
  @State female: boolean = false;
  @State chfSigns: boolean = false;
  @State priorVascular: boolean = false;
  @State dm: boolean = false;
  @State sbp: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateCrusade(this.hct, this.crcl, this.hr, this.female, this.chfSigns, this.priorVascular, this.dm, this.sbp); }

  reset() {
    this.hct = 0;
    this.crcl = 0;
    this.hr = 0;
    this.female = false;
    this.chfSigns = false;
    this.priorVascular = false;
    this.dm = false;
    this.sbp = 0;
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
        Text('CRUSADE：ACS 住院大出血风险').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('红细胞压积/CrCl/HR/性别/心衰/血管病/糖尿病/SBP').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '输入参数', resetAction: () => { this.reset(); } })
        Row() {
          InputRow({ label: '红细胞压积 (%)', placeholder: 'Hct', onTextChange: (value: string) => { this.hct = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: 'CrCl/eGFR (mL/min)', placeholder: 'CrCl', onTextChange: (value: string) => { this.crcl = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        Row() {
          InputRow({ label: '心率 (次/分)', placeholder: 'HR', onTextChange: (value: string) => { this.hr = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '收缩压 (mmHg)', placeholder: 'SBP', onTextChange: (value: string) => { this.sbp = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });

        Text('风险因素').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row({ space: 8 }) {
          OptionChip({ label: '女性', selected: this.female, onChipClick: () => { this.female = !this.female; this.calculate(); } });
          OptionChip({ label: '心衰体征', selected: this.chfSigns, onChipClick: () => { this.chfSigns = !this.chfSigns; this.calculate(); } });
          OptionChip({ label: '血管病史', selected: this.priorVascular, onChipClick: () => { this.priorVascular = !this.priorVascular; this.calculate(); } });
          OptionChip({ label: '糖尿病', selected: this.dm, onChipClick: () => { this.dm = !this.dm; this.calculate(); } });
        }.width('100%');
        Text('血管病史=外周动脉病或卒中史；CrCl 可用 eGFR 近似').fontSize(11).fontColor(AppColors.textSecondary).margin({ top: 6 });
      }

      if (this.result) {
        ResultCard({ title: 'CRUSADE', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding({ left: 16, right: 16, top: 8, bottom: 16 }).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
