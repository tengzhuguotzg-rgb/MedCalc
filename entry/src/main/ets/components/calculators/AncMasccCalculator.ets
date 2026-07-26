import { CalcResult } from '../../engine/CalcEngine';
import { calculateAncMascc } from '../../engine/Batch1bCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct AncMasccCalculator {
  @State resetKey: number = 0;
  @State anc: number = 0;
  @State wbc: number = 0;
  @State neutPct: number = 0;
  @State masccBurden: number = 0;
  @State noHypotension: boolean = false;
  @State noCopd: boolean = false;
  @State solidTumorNoFungal: boolean = false;
  @State noDehydration: boolean = false;
  @State outpatient: boolean = false;
  @State age: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    this.result = calculateAncMascc(this.anc, this.wbc, this.neutPct, this.masccBurden, this.noHypotension, this.noCopd, this.solidTumorNoFungal, this.noDehydration, this.outpatient, this.age);
  }

  reset() {
    this.anc = 0;
    this.wbc = 0;
    this.neutPct = 0;
    this.masccBurden = 0;
    this.noHypotension = false;
    this.noCopd = false;
    this.solidTumorNoFungal = false;
    this.noDehydration = false;
    this.outpatient = false;
    this.age = 0;
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
        Text('ANC 中性粒细胞绝对值 + MASCC 粒缺发热风险').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('MASCC ≥21 分低危；ANC 可直接录入或由 WBC×中性粒%推算').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: 'ANC', resetAction: () => { this.reset(); } })
        InputRow({ label: 'ANC (×10⁹/L，可留空)', placeholder: '直接录入优先', onTextChange: (value: string) => { this.anc = parseFloat(value) || 0; this.calculate(); } }).margin({ bottom: 8 });
        Row() {
          InputRow({ label: 'WBC (×10⁹/L)', placeholder: 'WBC', onTextChange: (value: string) => { this.wbc = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '中性粒细胞 (%)', placeholder: 'Neut%', onTextChange: (value: string) => { this.neutPct = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%');
      }

      CalcCard() {
        Text('MASCC 项（不填则只算 ANC）').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Text('疾病负担').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row({ space: 8 }) {
          OptionChip({ label: '不填', selected: this.masccBurden === 0, onChipClick: () => { this.masccBurden = 0; this.calculate(); } });
          OptionChip({ label: '无/轻 5', selected: this.masccBurden === 5, onChipClick: () => { this.masccBurden = 5; this.calculate(); } });
          OptionChip({ label: '中 3', selected: this.masccBurden === 3, onChipClick: () => { this.masccBurden = 3; this.calculate(); } });
        }.width('100%').margin({ bottom: 8 });
        Row({ space: 8 }) {
          OptionChip({ label: '无低血压 +5', selected: this.noHypotension, onChipClick: () => { this.noHypotension = !this.noHypotension; this.calculate(); } });
          OptionChip({ label: '无COPD +4', selected: this.noCopd, onChipClick: () => { this.noCopd = !this.noCopd; this.calculate(); } });
          OptionChip({ label: '实体瘤/无真菌 +4', selected: this.solidTumorNoFungal, onChipClick: () => { this.solidTumorNoFungal = !this.solidTumorNoFungal; this.calculate(); } });
        }.width('100%').margin({ bottom: 8 });
        Row({ space: 8 }) {
          OptionChip({ label: '无脱水 +3', selected: this.noDehydration, onChipClick: () => { this.noDehydration = !this.noDehydration; this.calculate(); } });
          OptionChip({ label: '门诊状态 +3', selected: this.outpatient, onChipClick: () => { this.outpatient = !this.outpatient; this.calculate(); } });
        }.width('100%').margin({ bottom: 8 });
        InputRow({ label: '年龄 (岁，<60 加2)', placeholder: '年龄', onTextChange: (value: string) => { this.age = parseFloat(value) || 0; this.calculate(); } });
      }

      if (this.result) {
        ResultCard({ title: 'ANC / MASCC', value: this.result!.value, unit: this.result!.unit, decimals: 2, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
