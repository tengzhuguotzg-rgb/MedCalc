import { CalcResult } from '../../engine/CalcEngine';
import { calculateStess } from '../../engine/Batch2aCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct StessCalculator {
  @State resetKey: number = 0;
  @State consciousness: number = 0;
  @State seizureType: number = 1;
  @State age: number = 0;
  @State priorSeizures: boolean = false;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateStess(this.consciousness, this.seizureType, this.age, this.priorSeizures); }

  reset() {
    this.consciousness = 0;
    this.seizureType = 1;
    this.age = 0;
    this.priorSeizures = false;
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
        Text('STESS：癫痫持续状态严重度评分').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('0-2 分预后较好；≥3 分死亡风险升高').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '输入参数', resetAction: () => { this.reset(); } })

        Text('意识水平').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row({ space: 8 }) {
          OptionChip({ label: '清醒/嗜睡模糊 0', selected: this.consciousness === 0, onChipClick: () => { this.consciousness = 0; this.calculate(); } });
          OptionChip({ label: '木僵/昏迷 1', selected: this.consciousness === 1, onChipClick: () => { this.consciousness = 1; this.calculate(); } });
        }.width('100%').margin({ bottom: 8 });

        Text('最重发作类型').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row({ space: 8 }) {
          OptionChip({ label: '非GTCS 0', selected: this.seizureType === 0, onChipClick: () => { this.seizureType = 0; this.calculate(); } });
          OptionChip({ label: '全面强直阵挛 1', selected: this.seizureType === 1, onChipClick: () => { this.seizureType = 1; this.calculate(); } });
          OptionChip({ label: '昏迷中NCSE 2', selected: this.seizureType === 2, onChipClick: () => { this.seizureType = 2; this.calculate(); } });
        }.width('100%').margin({ bottom: 8 });

        Row() {
          InputRow({ label: '年龄 (岁)', placeholder: '年龄', onTextChange: (value: string) => { this.age = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          Column() {
            Text('既往癫痫发作史').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            Row({ space: 8 }) {
              OptionChip({ label: '无', selected: !this.priorSeizures, chipHeight: AppDimens.inputHeight, onChipClick: () => { this.priorSeizures = false; this.calculate(); } });
              OptionChip({ label: '有', selected: this.priorSeizures, chipHeight: AppDimens.inputHeight, onChipClick: () => { this.priorSeizures = true; this.calculate(); } });
            }
          }.layoutWeight(1).margin({ left: 12 });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'STESS', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
