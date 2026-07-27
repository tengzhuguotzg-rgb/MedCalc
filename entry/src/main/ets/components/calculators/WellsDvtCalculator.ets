import { CalcResult } from '../../engine/CalcEngine';
import { calculateWellsDvt } from '../../engine/Batch1bCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, OptionChip, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct WellsDvtCalculator {
  @State resetKey: number = 0;
  @State activeCancer: boolean = false;
  @State immobilization: boolean = false;
  @State bedriddenSurgery: boolean = false;
  @State tenderness: boolean = false;
  @State legSwollen: boolean = false;
  @State calfDiff3cm: boolean = false;
  @State pittingEdema: boolean = false;
  @State collateralVeins: boolean = false;
  @State priorDvt: boolean = false;
  @State altDiagnosis: boolean = false;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    this.result = calculateWellsDvt(this.activeCancer, this.immobilization, this.bedriddenSurgery, this.tenderness, this.legSwollen, this.calfDiff3cm, this.pittingEdema, this.collateralVeins, this.priorDvt, this.altDiagnosis);
  }

  reset() {
    this.activeCancer = false;
    this.immobilization = false;
    this.bedriddenSurgery = false;
    this.tenderness = false;
    this.legSwollen = false;
    this.calfDiff3cm = false;
    this.pittingEdema = false;
    this.collateralVeins = false;
    this.priorDvt = false;
    this.altDiagnosis = false;
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
        Text('Wells DVT：下肢深静脉血栓验前概率').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('每项 +1，替代诊断更可能 -2；与 Wells PE 不混用').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '符合项（点击切换）', resetAction: () => { this.reset(); } })
        Row({ space: 8 }) {
          OptionChip({ label: '活动性肿瘤', selected: this.activeCancer, onChipClick: () => { this.activeCancer = !this.activeCancer; this.calculate(); } });
          OptionChip({ label: '下肢制动/石膏', selected: this.immobilization, onChipClick: () => { this.immobilization = !this.immobilization; this.calculate(); } });
          OptionChip({ label: '卧床>3天/12周内手术', selected: this.bedriddenSurgery, onChipClick: () => { this.bedriddenSurgery = !this.bedriddenSurgery; this.calculate(); } });
        }.width('100%').margin({ bottom: 8 });
        Row({ space: 8 }) {
          OptionChip({ label: '深静脉走行压痛', selected: this.tenderness, onChipClick: () => { this.tenderness = !this.tenderness; this.calculate(); } });
          OptionChip({ label: '整条腿肿胀', selected: this.legSwollen, onChipClick: () => { this.legSwollen = !this.legSwollen; this.calculate(); } });
          OptionChip({ label: '小腿周径差≥3cm', selected: this.calfDiff3cm, onChipClick: () => { this.calfDiff3cm = !this.calfDiff3cm; this.calculate(); } });
        }.width('100%').margin({ bottom: 8 });
        Row({ space: 8 }) {
          OptionChip({ label: '患侧凹陷性水肿', selected: this.pittingEdema, onChipClick: () => { this.pittingEdema = !this.pittingEdema; this.calculate(); } });
          OptionChip({ label: '浅表侧支静脉', selected: this.collateralVeins, onChipClick: () => { this.collateralVeins = !this.collateralVeins; this.calculate(); } });
          OptionChip({ label: '既往 DVT', selected: this.priorDvt, onChipClick: () => { this.priorDvt = !this.priorDvt; this.calculate(); } });
        }.width('100%').margin({ bottom: 8 });
        Row({ space: 8 }) {
          OptionChip({ label: '替代诊断更可能 -2', selected: this.altDiagnosis, onChipClick: () => { this.altDiagnosis = !this.altDiagnosis; this.calculate(); } });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'Wells DVT', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding({ left: 16, right: 16, top: 8, bottom: 16 }).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
