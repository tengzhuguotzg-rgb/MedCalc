import { CalcResult } from '../../engine/CalcEngine';
import { calculateIsth } from '../../engine/Batch2aCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct IsthCalculator {
  @State resetKey: number = 0;
  @State platelet: number = 0;
  @State ddimerGrade: number = 0;
  @State ptProlong: number = 0;
  @State fib: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateIsth(this.platelet, this.ddimerGrade, this.ptProlong, this.fib); }

  reset() {
    this.platelet = 0;
    this.ddimerGrade = 0;
    this.ptProlong = 0;
    this.fib = 0;
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
        Text('ISTH 显性 DIC 评分').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('≥5 分符合显性 DIC；前提：存在 DIC 相关基础疾病').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '输入参数', resetAction: () => { this.reset(); } })
        Row() {
          InputRow({ label: '血小板 (×10⁹/L)', placeholder: 'PLT', onTextChange: (value: string) => { this.platelet = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '纤维蛋白原 (g/L)', placeholder: 'Fib', onTextChange: (value: string) => { this.fib = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });

        Text('纤溶标志物升高程度（D-二聚体/FDP）').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row({ space: 8 }) {
          OptionChip({ label: '无升高 0', selected: this.ddimerGrade === 0, onChipClick: () => { this.ddimerGrade = 0; this.calculate(); } });
          OptionChip({ label: '中度 2', selected: this.ddimerGrade === 2, onChipClick: () => { this.ddimerGrade = 2; this.calculate(); } });
          OptionChip({ label: '重度 3', selected: this.ddimerGrade === 3, onChipClick: () => { this.ddimerGrade = 3; this.calculate(); } });
        }.width('100%').margin({ bottom: 8 });

        Text('PT 延长').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row({ space: 8 }) {
          OptionChip({ label: '<3秒 0', selected: this.ptProlong === 0, onChipClick: () => { this.ptProlong = 0; this.calculate(); } });
          OptionChip({ label: '3-6秒 1', selected: this.ptProlong === 1, onChipClick: () => { this.ptProlong = 1; this.calculate(); } });
          OptionChip({ label: '>6秒 2', selected: this.ptProlong === 2, onChipClick: () => { this.ptProlong = 2; this.calculate(); } });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'ISTH DIC', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
