import { CalcResult } from '../../engine/CalcEngine';
import { calculateGcsP } from '../../engine/Batch2bCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct GcsPCalculator {
  @State resetKey: number = 0;
  @State gcs: number = 0;
  @State pupilScore: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateGcsP(this.gcs, this.pupilScore); }

  reset() {
    this.gcs = 0;
    this.pupilScore = 0;
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
        Text('GCS-Pupils：GCS 结合瞳孔反应').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('GCS-P = GCS - 瞳孔分（双侧0/一侧1/均无2）').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '输入参数', resetAction: () => { this.reset(); } })
        InputRow({ label: 'GCS (3-15)', placeholder: 'GCS', onTextChange: (value: string) => { this.gcs = parseFloat(value) || 0; this.calculate(); } }).margin({ bottom: 8 });

        Text('瞳孔对光反射').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row({ space: 8 }) {
          OptionChip({ label: '双侧有 0', selected: this.pupilScore === 0, onChipClick: () => { this.pupilScore = 0; this.calculate(); } });
          OptionChip({ label: '一侧无 1', selected: this.pupilScore === 1, onChipClick: () => { this.pupilScore = 1; this.calculate(); } });
          OptionChip({ label: '双侧均无 2', selected: this.pupilScore === 2, onChipClick: () => { this.pupilScore = 2; this.calculate(); } });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'GCS-P', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding({ left: 16, right: 16, top: 8, bottom: 16 }).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
