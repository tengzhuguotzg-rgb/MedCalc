import { CalcResult } from '../../engine/CalcEngine';
import { calculateCsf } from '../../engine/Batch3aCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct CsfCalculator {
  @State resetKey: number = 0;
  @State csfWbc: number = 0;
  @State csfNeutPct: number = 0;
  @State csfProtein: number = 0;
  @State csfGlu: number = 0;
  @State serumGlu: number = 0;
  @State csfRbc: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateCsf(this.csfWbc, this.csfNeutPct, this.csfProtein, this.csfGlu, this.serumGlu, this.csfRbc); }

  reset() {
    this.csfWbc = 0;
    this.csfNeutPct = 0;
    this.csfProtein = 0;
    this.csfGlu = 0;
    this.serumGlu = 0;
    this.csfRbc = 0;
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
        Text('脑脊液（CSF）细菌性/病毒性倾向核对').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('模式核对，不能单独诊断脑膜炎').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '脑脊液指标', resetAction: () => { this.reset(); } })
        Row() {
          InputRow({ label: 'WBC (个/μL)', placeholder: 'WBC', onTextChange: (value: string) => { this.csfWbc = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: 'RBC (个/μL，可空)', placeholder: '损伤穿刺校正', onTextChange: (value: string) => { this.csfRbc = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        Row() {
          InputRow({ label: '中性粒细胞 (%)', placeholder: 'Neut%', onTextChange: (value: string) => { this.csfNeutPct = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '蛋白 (g/L)', placeholder: '≥1.5计', onTextChange: (value: string) => { this.csfProtein = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        Row() {
          InputRow({ label: 'CSF 糖 (mmol/L)', placeholder: 'CSF Glu', onTextChange: (value: string) => { this.csfGlu = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '血糖 (mmol/L)', placeholder: 'Serum Glu', onTextChange: (value: string) => { this.serumGlu = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%');
        Text('细菌性特征：WBC≥1000、中性粒≥80%、蛋白≥1.5 g/L、CSF糖/血糖<0.4').fontSize(11).fontColor(AppColors.textSecondary).margin({ top: 6 });
      }

      if (this.result) {
        ResultCard({ title: 'CSF 倾向核对', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding({ left: 16, right: 16, top: 8, bottom: 16 }).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
