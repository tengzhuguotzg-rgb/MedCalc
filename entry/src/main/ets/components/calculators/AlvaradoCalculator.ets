import { CalcResult } from '../../engine/CalcEngine';
import { calculateAlvarado } from '../../engine/Batch3aCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct AlvaradoCalculator {
  @State resetKey: number = 0;
  @State temp: number = 0;
  @State wbc: number = 0;
  @State neutPct: number = 0;
  @State migratory: boolean = false;
  @State anorexia: boolean = false;
  @State nauseaVomit: boolean = false;
  @State rlqTender: boolean = false;
  @State rebound: boolean = false;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    this.result = calculateAlvarado(this.temp, this.wbc, this.neutPct, this.migratory, this.anorexia, this.nauseaVomit, this.rlqTender, this.rebound);
  }

  reset() {
    this.temp = 0;
    this.wbc = 0;
    this.neutPct = 0;
    this.migratory = false;
    this.anorexia = false;
    this.nauseaVomit = false;
    this.rlqTender = false;
    this.rebound = false;
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
        Text('Alvarado 阑尾炎评分（MANTRELS）').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('≥7 高概率；5-6 建议影像/留观').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '客观项', resetAction: () => { this.reset(); } })
        Row() {
          InputRow({ label: '体温 (°C)', placeholder: 'Temp', onTextChange: (value: string) => { this.temp = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: 'WBC (×10⁹/L)', placeholder: 'WBC', onTextChange: (value: string) => { this.wbc = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        InputRow({ label: '中性粒细胞 (%)', placeholder: '>75计左移', onTextChange: (value: string) => { this.neutPct = parseFloat(value) || 0; this.calculate(); } }).margin({ bottom: 8 });

        Text('症状/体征（点击切换）').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row({ space: 8 }) {
          OptionChip({ label: '转移性右下腹痛', selected: this.migratory, onChipClick: () => { this.migratory = !this.migratory; this.calculate(); } });
          OptionChip({ label: '厌食', selected: this.anorexia, onChipClick: () => { this.anorexia = !this.anorexia; this.calculate(); } });
          OptionChip({ label: '恶心呕吐', selected: this.nauseaVomit, onChipClick: () => { this.nauseaVomit = !this.nauseaVomit; this.calculate(); } });
        }.width('100%').margin({ bottom: 8 });
        Row({ space: 8 }) {
          OptionChip({ label: '右下腹压痛 +2', selected: this.rlqTender, onChipClick: () => { this.rlqTender = !this.rlqTender; this.calculate(); } });
          OptionChip({ label: '反跳痛', selected: this.rebound, onChipClick: () => { this.rebound = !this.rebound; this.calculate(); } });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'Alvarado', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
