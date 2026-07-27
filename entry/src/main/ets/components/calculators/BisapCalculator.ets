import { CalcResult } from '../../engine/CalcEngine';
import { calculateBisap, calculateRanson } from '../../engine/Batch1bCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct BisapCalculator {
  @State resetKey: number = 0;
  // BISAP
  @State bun: number = 0;
  @State bunUnit: string = 'mmol';
  @State gcs: number = 0;
  @State sirsCount: number = 0;
  @State age: number = 0;
  @State pleuralEffusion: boolean = false;
  // Ranson 入院项
  @State wbc: number = 0;
  @State glu: number = 0;
  @State ldh: number = 0;
  @State ast: number = 0;
  // Ranson 48h 项（可选）
  @State hctDrop: number = 0;
  @State bunRise: number = 0;
  @State ca: number = 0;
  @State pao2: number = 0;
  @State baseDeficit: number = 0;
  @State fluidSeq: number = 0;
  @State bisapResult: CalcResult | null = null;
  @State ransonResult: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    const bunMgDl = this.bunUnit === 'mmol' ? this.bun * 2.8 : this.bun;
    this.bisapResult = calculateBisap(bunMgDl, this.gcs, this.sirsCount, this.age, this.pleuralEffusion);
    this.ransonResult = calculateRanson(this.age, this.wbc, this.glu, this.ldh, this.ast, this.hctDrop, this.bunRise, this.ca, this.pao2, this.baseDeficit, this.fluidSeq);
  }

  reset() {
    this.bun = 0;
    this.bunUnit = 'mmol';
    this.gcs = 0;
    this.sirsCount = 0;
    this.age = 0;
    this.pleuralEffusion = false;
    this.wbc = 0;
    this.glu = 0;
    this.ldh = 0;
    this.ast = 0;
    this.hctDrop = 0;
    this.bunRise = 0;
    this.ca = 0;
    this.pao2 = 0;
    this.baseDeficit = 0;
    this.fluidSeq = 0;
    this.bisapResult = null;
    this.ransonResult = null;
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
        Text('急性胰腺炎严重度：BISAP（即时）+ Ranson（48h）').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('BISAP ≥3 分或 Ranson ≥3 分提示重症倾向').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: 'BISAP 输入', resetAction: () => { this.reset(); } })
        Row() {
          InputRow({ label: '尿素氮/尿素', placeholder: 'BUN', onTextChange: (value: string) => { this.bun = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          Column() {
            Text('单位').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            Row({ space: 8 }) {
              OptionChip({ label: 'mmol/L(尿素)', selected: this.bunUnit === 'mmol', chipHeight: AppDimens.inputHeight, onChipClick: () => { this.bunUnit = 'mmol'; this.calculate(); } });
              OptionChip({ label: 'mg/dL(BUN)', selected: this.bunUnit === 'mgdl', chipHeight: AppDimens.inputHeight, onChipClick: () => { this.bunUnit = 'mgdl'; this.calculate(); } });
            }
          }.layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        Row() {
          InputRow({ label: 'GCS', placeholder: '3-15', onTextChange: (value: string) => { this.gcs = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: 'SIRS 项数 (0-4)', placeholder: 'SIRS', onTextChange: (value: string) => { this.sirsCount = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        Row() {
          InputRow({ label: '年龄 (岁)', placeholder: '年龄', onTextChange: (value: string) => { this.age = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          Column() {
            Text('胸腔积液').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            Row({ space: 8 }) {
              OptionChip({ label: '无/未填', selected: !this.pleuralEffusion, chipHeight: AppDimens.inputHeight, onChipClick: () => { this.pleuralEffusion = false; this.calculate(); } });
              OptionChip({ label: '有', selected: this.pleuralEffusion, chipHeight: AppDimens.inputHeight, onChipClick: () => { this.pleuralEffusion = true; this.calculate(); } });
            }
          }.layoutWeight(1).margin({ left: 12 });
        }.width('100%');
      }

      if (this.bisapResult) {
        ResultCard({ title: 'BISAP', value: this.bisapResult!.value, unit: this.bisapResult!.unit, decimals: 0, tier: this.bisapResult!.tier, tierClass: this.bisapResult!.tierClass, footnote: this.bisapResult!.footnote });
      }

      CalcCard() {
        Text('Ranson 入院项').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row() {
          InputRow({ label: 'WBC (×10⁹/L)', placeholder: 'WBC', onTextChange: (value: string) => { this.wbc = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '血糖 (mmol/L)', placeholder: 'Glu', onTextChange: (value: string) => { this.glu = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        Row() {
          InputRow({ label: 'LDH (U/L)', placeholder: 'LDH', onTextChange: (value: string) => { this.ldh = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: 'AST (U/L)', placeholder: 'AST', onTextChange: (value: string) => { this.ast = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });

        Text('Ranson 48h 项（可选，不填不计）').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row() {
          InputRow({ label: 'Hct 下降 (%)', placeholder: '>10计1', onTextChange: (value: string) => { this.hctDrop = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: 'BUN 上升 (mg/dL)', placeholder: '>5计1', onTextChange: (value: string) => { this.bunRise = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        Row() {
          InputRow({ label: '血钙 (mmol/L)', placeholder: '<2.0计1', onTextChange: (value: string) => { this.ca = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: 'PaO₂ (mmHg)', placeholder: '<60计1', onTextChange: (value: string) => { this.pao2 = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        Row() {
          InputRow({ label: '碱缺失 (mEq/L)', placeholder: '>4计1', onTextChange: (value: string) => { this.baseDeficit = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '液体隔离 (L)', placeholder: '>6计1', onTextChange: (value: string) => { this.fluidSeq = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%');
      }

      if (this.ransonResult) {
        ResultCard({ title: 'Ranson', value: this.ransonResult!.value, unit: this.ransonResult!.unit, decimals: 0, tier: this.ransonResult!.tier, tierClass: this.ransonResult!.tierClass, footnote: this.ransonResult!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding({ left: 16, right: 16, top: 8, bottom: 16 }).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
