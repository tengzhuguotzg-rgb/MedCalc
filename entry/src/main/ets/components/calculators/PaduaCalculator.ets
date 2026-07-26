import { CalcResult } from '../../engine/CalcEngine';
import { calculatePadua } from '../../engine/Batch3aCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct PaduaCalculator {
  @State resetKey: number = 0;
  @State age: number = 0;
  @State bmi: number = 0;
  @State cancer: boolean = false;
  @State prevVte: boolean = false;
  @State immobility: boolean = false;
  @State thrombophilia: boolean = false;
  @State traumaSurg: boolean = false;
  @State hfRespFail: boolean = false;
  @State miStroke: boolean = false;
  @State infection: boolean = false;
  @State hormoneRx: boolean = false;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    this.result = calculatePadua(this.age, this.cancer, this.prevVte, this.immobility, this.thrombophilia, this.traumaSurg, this.hfRespFail, this.miStroke, this.infection, this.bmi, this.hormoneRx);
  }

  reset() {
    this.age = 0;
    this.bmi = 0;
    this.cancer = false;
    this.prevVte = false;
    this.immobility = false;
    this.thrombophilia = false;
    this.traumaSurg = false;
    this.hfRespFail = false;
    this.miStroke = false;
    this.infection = false;
    this.hormoneRx = false;
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
        Text('Padua：内科住院患者 VTE 风险').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('≥4 分高危，建议药物预防（结合出血风险）').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '输入参数', resetAction: () => { this.reset(); } })
        Row() {
          InputRow({ label: '年龄 (岁)', placeholder: '≥70计1', onTextChange: (value: string) => { this.age = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: 'BMI', placeholder: '≥30计1', onTextChange: (value: string) => { this.bmi = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });

        Text('风险因素（点击切换）').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row({ space: 8 }) {
          OptionChip({ label: '活动性肿瘤 +3', selected: this.cancer, onChipClick: () => { this.cancer = !this.cancer; this.calculate(); } });
          OptionChip({ label: '既往VTE +3', selected: this.prevVte, onChipClick: () => { this.prevVte = !this.prevVte; this.calculate(); } });
          OptionChip({ label: '制动≥3天 +3', selected: this.immobility, onChipClick: () => { this.immobility = !this.immobility; this.calculate(); } });
        }.width('100%').margin({ bottom: 8 });
        Row({ space: 8 }) {
          OptionChip({ label: '易栓症 +3', selected: this.thrombophilia, onChipClick: () => { this.thrombophilia = !this.thrombophilia; this.calculate(); } });
          OptionChip({ label: '近期创伤/手术 +2', selected: this.traumaSurg, onChipClick: () => { this.traumaSurg = !this.traumaSurg; this.calculate(); } });
          OptionChip({ label: '心衰/呼衰 +1', selected: this.hfRespFail, onChipClick: () => { this.hfRespFail = !this.hfRespFail; this.calculate(); } });
        }.width('100%').margin({ bottom: 8 });
        Row({ space: 8 }) {
          OptionChip({ label: '急性心梗/卒中 +1', selected: this.miStroke, onChipClick: () => { this.miStroke = !this.miStroke; this.calculate(); } });
          OptionChip({ label: '急性感染/风湿 +1', selected: this.infection, onChipClick: () => { this.infection = !this.infection; this.calculate(); } });
          OptionChip({ label: '激素治疗 +1', selected: this.hormoneRx, onChipClick: () => { this.hormoneRx = !this.hormoneRx; this.calculate(); } });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'Padua', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
