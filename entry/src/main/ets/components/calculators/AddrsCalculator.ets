import { CalcResult } from '../../engine/CalcEngine';
import { calculateAddrs } from '../../engine/Batch2aCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct AddrsCalculator {
  @State resetKey: number = 0;
  @State condition: boolean = false;
  @State pain: boolean = false;
  @State exam: boolean = false;
  @State ddimer: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateAddrs(this.condition, this.pain, this.exam, this.ddimer); }

  reset() {
    this.condition = false;
    this.pain = false;
    this.exam = false;
    this.ddimer = 0;
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
        Text('ADD-RS：主动脉夹层检出风险评分').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('三类高危特征各 1 分；≥2 分建议直接影像').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '高危特征（点击切换）', resetAction: () => { this.reset(); } })
        Row({ space: 8 }) {
          OptionChip({ label: '高危基础/病史', selected: this.condition, onChipClick: () => { this.condition = !this.condition; this.calculate(); } });
          OptionChip({ label: '高危疼痛特征', selected: this.pain, onChipClick: () => { this.pain = !this.pain; this.calculate(); } });
          OptionChip({ label: '高危查体', selected: this.exam, onChipClick: () => { this.exam = !this.exam; this.calculate(); } });
        }.width('100%').margin({ bottom: 8 });
        InputRow({ label: 'D-二聚体 (mg/L FEU，可空)', placeholder: '可选', onTextChange: (value: string) => { this.ddimer = parseFloat(value) || 0; this.calculate(); } });
        Text('高危基础：马凡/结缔组织病、家族史、已知主动脉瓣病/胸主动脉瘤、近期主动脉操作；疼痛：突发/剧烈/撕裂样；查体：脉搏差/血压差/局灶神经缺损、舒张期杂音、低血压休克').fontSize(11).fontColor(AppColors.textSecondary).margin({ top: 6 });
      }

      if (this.result) {
        ResultCard({ title: 'ADD-RS', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
