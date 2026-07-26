import { CalcResult } from '../../engine/CalcEngine';
import { calculateDuke } from '../../engine/Batch3bCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, OptionChip, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct DukeCalculator {
  @State resetKey: number = 0;
  @State cultureMajor: boolean = false;
  @State echoMajor: boolean = false;
  @State predisposition: boolean = false;
  @State fever: boolean = false;
  @State vascular: boolean = false;
  @State immunological: boolean = false;
  @State microEvidence: boolean = false;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    this.result = calculateDuke(this.cultureMajor, this.echoMajor, this.predisposition, this.fever, this.vascular, this.immunological, this.microEvidence);
  }

  reset() {
    this.cultureMajor = false;
    this.echoMajor = false;
    this.predisposition = false;
    this.fever = false;
    this.vascular = false;
    this.immunological = false;
    this.microEvidence = false;
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
        Text('改良 Duke 感染性心内膜炎标准核对').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('确诊=2主要 / 1主要+3次要 / 5次要；标准核对非最终诊断').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '主要标准', resetAction: () => { this.reset(); } })
        Row({ space: 8 }) {
          OptionChip({ label: '血培养阳性（典型菌/持续）', selected: this.cultureMajor, onChipClick: () => { this.cultureMajor = !this.cultureMajor; this.calculate(); } });
          OptionChip({ label: '心内膜受累（超声/新反流）', selected: this.echoMajor, onChipClick: () => { this.echoMajor = !this.echoMajor; this.calculate(); } });
        }.width('100%');
      }

      CalcCard() {
        Text('次要标准').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row({ space: 8 }) {
          OptionChip({ label: '易感因素/IVDU', selected: this.predisposition, onChipClick: () => { this.predisposition = !this.predisposition; this.calculate(); } });
          OptionChip({ label: '发热≥38', selected: this.fever, onChipClick: () => { this.fever = !this.fever; this.calculate(); } });
          OptionChip({ label: '血管现象', selected: this.vascular, onChipClick: () => { this.vascular = !this.vascular; this.calculate(); } });
        }.width('100%').margin({ bottom: 8 });
        Row({ space: 8 }) {
          OptionChip({ label: '免疫现象', selected: this.immunological, onChipClick: () => { this.immunological = !this.immunological; this.calculate(); } });
          OptionChip({ label: '未达主要的微生物证据', selected: this.microEvidence, onChipClick: () => { this.microEvidence = !this.microEvidence; this.calculate(); } });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'Duke 标准', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
