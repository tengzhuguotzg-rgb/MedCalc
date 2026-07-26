import { CalcResult } from '../../engine/CalcEngine';
import { calculateAwol } from '../../engine/Batch3bCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, OptionChip, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct AwolCalculator {
  @State resetKey: number = 0;
  @State age80: boolean = false;
  @State worldBackward: boolean = false;
  @State disoriented: boolean = false;
  @State severeIllness: boolean = false;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateAwol(this.age80, this.worldBackward, this.disoriented, this.severeIllness); }

  reset() {
    this.age80 = false;
    this.worldBackward = false;
    this.disoriented = false;
    this.severeIllness = false;
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
        Text('AWOL 谵妄风险筛查（老年急诊/住院）').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('≥2 分启动预防；筛查阳性用 CAM/CAM-ICU 确认').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '四项核对（点击切换）', resetAction: () => { this.reset(); } })
        Row({ space: 8 }) {
          OptionChip({ label: '年龄≥80 (A)', selected: this.age80, onChipClick: () => { this.age80 = !this.age80; this.calculate(); } });
          OptionChip({ label: '倒拼WORLD失败 (W)', selected: this.worldBackward, onChipClick: () => { this.worldBackward = !this.worldBackward; this.calculate(); } });
        }.width('100%').margin({ bottom: 8 });
        Row({ space: 8 }) {
          OptionChip({ label: '地点定向障碍 (O)', selected: this.disoriented, onChipClick: () => { this.disoriented = !this.disoriented; this.calculate(); } });
          OptionChip({ label: '病情较重/护士判断 (L)', selected: this.severeIllness, onChipClick: () => { this.severeIllness = !this.severeIllness; this.calculate(); } });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'AWOL', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
