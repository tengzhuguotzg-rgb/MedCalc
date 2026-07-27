import { CalcResult } from '../../engine/CalcEngine';
import { calculateAspiration } from '../../engine/Batch2bCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, OptionChip, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct AspirationCalculator {
  @State resetKey: number = 0;
  @State dysphagia: boolean = false;
  @State impairedConsciousness: boolean = false;
  @State vomitReflux: boolean = false;
  @State enteralTube: boolean = false;
  @State sedation: boolean = false;
  @State poorOral: boolean = false;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    this.result = calculateAspiration(this.dysphagia, this.impairedConsciousness, this.vomitReflux, this.enteralTube, this.sedation, this.poorOral);
  }

  reset() {
    this.dysphagia = false;
    this.impairedConsciousness = false;
    this.vomitReflux = false;
    this.enteralTube = false;
    this.sedation = false;
    this.poorOral = false;
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
        Text('吸入性肺炎风险因素核对').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('核对清单（非验证评分）；≥4 项提示高风险').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '危险因素（点击切换）', resetAction: () => { this.reset(); } })
        Row({ space: 8 }) {
          OptionChip({ label: '吞咽困难/误吸史', selected: this.dysphagia, onChipClick: () => { this.dysphagia = !this.dysphagia; this.calculate(); } });
          OptionChip({ label: '意识障碍', selected: this.impairedConsciousness, onChipClick: () => { this.impairedConsciousness = !this.impairedConsciousness; this.calculate(); } });
          OptionChip({ label: '呕吐/反流', selected: this.vomitReflux, onChipClick: () => { this.vomitReflux = !this.vomitReflux; this.calculate(); } });
        }.width('100%').margin({ bottom: 8 });
        Row({ space: 8 }) {
          OptionChip({ label: '鼻饲/肠内管', selected: this.enteralTube, onChipClick: () => { this.enteralTube = !this.enteralTube; this.calculate(); } });
          OptionChip({ label: '镇静状态', selected: this.sedation, onChipClick: () => { this.sedation = !this.sedation; this.calculate(); } });
          OptionChip({ label: '口腔卫生差', selected: this.poorOral, onChipClick: () => { this.poorOral = !this.poorOral; this.calculate(); } });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: '风险核对', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding({ left: 16, right: 16, top: 8, bottom: 16 }).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
