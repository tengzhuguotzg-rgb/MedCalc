import { CalcResult } from '../../engine/CalcEngine';
import { calculateAsthma } from '../../engine/Batch2bCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct AsthmaCalculator {
  @State resetKey: number = 0;
  @State pefPct: number = 0;
  @State rr: number = 0;
  @State hr: number = 0;
  @State speech: string = '';
  @State silentChest: boolean = false;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateAsthma(this.pefPct, this.rr, this.hr, this.speech, this.silentChest); }

  reset() {
    this.pefPct = 0;
    this.rr = 0;
    this.hr = 0;
    this.speech = '';
    this.silentChest = false;
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
        Text('哮喘急性加重严重度分级（GINA）').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('取各指标最差项；危重=PEF<33%或沉默胸').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '输入参数', resetAction: () => { this.reset(); } })
        InputRow({ label: 'PEF 占预计值 (%)', placeholder: '如 40', onTextChange: (value: string) => { this.pefPct = parseFloat(value) || 0; this.calculate(); } }).margin({ bottom: 8 });
        Row() {
          InputRow({ label: '呼吸频率 (次/分)', placeholder: 'RR', onTextChange: (value: string) => { this.rr = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '心率 (次/分)', placeholder: 'HR', onTextChange: (value: string) => { this.hr = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });

        Text('说话能力').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row({ space: 8 }) {
          OptionChip({ label: '未填', selected: this.speech === '', onChipClick: () => { this.speech = ''; this.calculate(); } });
          OptionChip({ label: '成句', selected: this.speech === 'sentences', onChipClick: () => { this.speech = 'sentences'; this.calculate(); } });
          OptionChip({ label: '成短语', selected: this.speech === 'phrases', onChipClick: () => { this.speech = 'phrases'; this.calculate(); } });
          OptionChip({ label: '单词', selected: this.speech === 'words', onChipClick: () => { this.speech = 'words'; this.calculate(); } });
        }.width('100%').margin({ bottom: 8 });

        Text('危重征象').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row({ space: 8 }) {
          OptionChip({ label: '沉默胸', selected: this.silentChest, onChipClick: () => { this.silentChest = !this.silentChest; this.calculate(); } });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: '严重度分级', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding({ left: 16, right: 16, top: 8, bottom: 16 }).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
