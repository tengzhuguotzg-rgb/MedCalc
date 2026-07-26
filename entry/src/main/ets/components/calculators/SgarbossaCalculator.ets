import { CalcResult } from '../../engine/CalcEngine';
import { calculateSgarbossa } from '../../engine/Batch3bCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, OptionChip, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct SgarbossaCalculator {
  @State resetKey: number = 0;
  @State concordantSte: boolean = false;
  @State concordantStd: boolean = false;
  @State discordantMode: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateSgarbossa(this.concordantSte, this.concordantStd, this.discordantMode); }

  reset() {
    this.concordantSte = false;
    this.concordantStd = false;
    this.discordantMode = 0;
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
        Text('Sgarbossa / Smith 改良标准').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('仅用于 LBBB 或心室起搏心律下的 AMI 判断').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '心电图标准（点击切换）', resetAction: () => { this.reset(); } })
        Row({ space: 8 }) {
          OptionChip({ label: '协调性ST抬高≥1mm (5分)', selected: this.concordantSte, onChipClick: () => { this.concordantSte = !this.concordantSte; this.calculate(); } });
        }.width('100%').margin({ bottom: 8 });
        Row({ space: 8 }) {
          OptionChip({ label: 'V1-V3协调性ST压低≥1mm (3分)', selected: this.concordantStd, onChipClick: () => { this.concordantStd = !this.concordantStd; this.calculate(); } });
        }.width('100%').margin({ bottom: 8 });

        Text('不协调 ST 抬高（二选一）').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row({ space: 8 }) {
          OptionChip({ label: '无', selected: this.discordantMode === 0, onChipClick: () => { this.discordantMode = 0; this.calculate(); } });
          OptionChip({ label: '≥5mm 原始 (2分)', selected: this.discordantMode === 1, onChipClick: () => { this.discordantMode = 1; this.calculate(); } });
          OptionChip({ label: 'ST/S≤-0.25 改良 (2分)', selected: this.discordantMode === 2, onChipClick: () => { this.discordantMode = 2; this.calculate(); } });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'Sgarbossa', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
