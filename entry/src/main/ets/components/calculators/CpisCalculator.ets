import { CalcResult } from '../../engine/CalcEngine';
import { calculateCpis } from '../../engine/Batch1bCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct CpisCalculator {
  @State resetKey: number = 0;
  @State temp: number = 0;
  @State wbc: number = 0;
  @State bands: number = 0;
  @State secretions: number = 0;
  @State pao2: number = 0;
  @State fio2Pct: number = 0;
  @State cxr: number = 0;
  @State culture: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    const pf = this.pao2 > 0 && this.fio2Pct > 0 ? this.pao2 / (this.fio2Pct / 100) : 0;
    this.result = calculateCpis(this.temp, this.wbc, this.bands, this.secretions, pf, this.cxr, this.culture);
  }

  reset() {
    this.temp = 0;
    this.wbc = 0;
    this.bands = 0;
    this.secretions = 0;
    this.pao2 = 0;
    this.fio2Pct = 0;
    this.cxr = 0;
    this.culture = 0;
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
        Text('CPIS：呼吸机相关肺炎（VAP）辅助评分').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('≥6 分提示 VAP 可能性高；辅助工具，不单独诊断').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '输入参数', resetAction: () => { this.reset(); } })
        Row() {
          InputRow({ label: '体温 (°C)', placeholder: 'Temp', onTextChange: (value: string) => { this.temp = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: 'WBC (×10⁹/L)', placeholder: 'WBC', onTextChange: (value: string) => { this.wbc = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        Row() {
          InputRow({ label: '杆状核 (%)', placeholder: '≥50加1', onTextChange: (value: string) => { this.bands = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: 'PaO₂ (mmHg)', placeholder: 'PaO2', onTextChange: (value: string) => { this.pao2 = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        InputRow({ label: 'FiO₂ (%)', placeholder: '21-100', onTextChange: (value: string) => { this.fio2Pct = parseFloat(value) || 0; this.calculate(); } }).margin({ bottom: 8 });

        Text('气道分泌物').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row({ space: 8 }) {
          OptionChip({ label: '无/少 0', selected: this.secretions === 0, onChipClick: () => { this.secretions = 0; this.calculate(); } });
          OptionChip({ label: '非脓性 1', selected: this.secretions === 1, onChipClick: () => { this.secretions = 1; this.calculate(); } });
          OptionChip({ label: '脓性 2', selected: this.secretions === 2, onChipClick: () => { this.secretions = 2; this.calculate(); } });
        }.width('100%').margin({ bottom: 8 });

        Text('胸片浸润影').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row({ space: 8 }) {
          OptionChip({ label: '无 0', selected: this.cxr === 0, onChipClick: () => { this.cxr = 0; this.calculate(); } });
          OptionChip({ label: '弥漫/斑片 1', selected: this.cxr === 1, onChipClick: () => { this.cxr = 1; this.calculate(); } });
          OptionChip({ label: '局灶 2', selected: this.cxr === 2, onChipClick: () => { this.cxr = 2; this.calculate(); } });
        }.width('100%').margin({ bottom: 8 });

        Text('气道标本培养').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row({ space: 8 }) {
          OptionChip({ label: '无/未送 0', selected: this.culture === 0, onChipClick: () => { this.culture = 0; this.calculate(); } });
          OptionChip({ label: '致病菌 1', selected: this.culture === 1, onChipClick: () => { this.culture = 1; this.calculate(); } });
          OptionChip({ label: '致病菌+涂片一致 2', selected: this.culture === 2, onChipClick: () => { this.culture = 2; this.calculate(); } });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'CPIS', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
