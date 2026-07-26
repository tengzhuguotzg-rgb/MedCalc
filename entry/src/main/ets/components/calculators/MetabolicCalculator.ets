import { CalcResult } from '../../engine/CalcEngine';
import { calculateMetabolic } from '../../engine/Batch1aCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct MetabolicCalculator {
  @State resetKey: number = 0;
  @State ca: number = 0;
  @State alb: number = 0;
  @State albUnit: string = 'gl';
  @State na: number = 0;
  @State glu: number = 0;
  @State bun: number = 0;
  @State measuredOsm: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateMetabolic(this.ca, this.alb, this.albUnit, this.na, this.glu, this.bun, this.measuredOsm); }

  reset() {
    this.ca = 0;
    this.alb = 0;
    this.albUnit = 'gl';
    this.na = 0;
    this.glu = 0;
    this.bun = 0;
    this.measuredOsm = 0;
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
        Text('校正钙 + 计算渗透压/渗透间隙快速核对').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('AG 请用“白蛋白校准 AG”；本卡补校正钙与渗透间隙').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '输入参数', resetAction: () => { this.reset(); } })
        Row() {
          InputRow({ label: '血钙 (mmol/L)', placeholder: 'Ca', inputType: InputType.NUMBER_DECIMAL, onTextChange: (value: string) => { this.ca = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '白蛋白', placeholder: 'Alb', inputType: InputType.NUMBER_DECIMAL, onTextChange: (value: string) => { this.alb = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        Row() {
          Column() {
            Text('白蛋白单位').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            Row({ space: 8 }) {
              OptionChip({ label: 'g/L', selected: this.albUnit === 'gl', chipHeight: AppDimens.inputHeight, onChipClick: () => { this.albUnit = 'gl'; this.calculate(); } });
              OptionChip({ label: 'g/dL', selected: this.albUnit === 'gdl', chipHeight: AppDimens.inputHeight, onChipClick: () => { this.albUnit = 'gdl'; this.calculate(); } });
            }
          }.layoutWeight(1);
          InputRow({ label: '实测渗透压 (可选)', placeholder: 'mOsm/kg', inputType: InputType.NUMBER_DECIMAL, onTextChange: (value: string) => { this.measuredOsm = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        Row() {
          InputRow({ label: 'Na (可选)', placeholder: 'Na', inputType: InputType.NUMBER_DECIMAL, onTextChange: (value: string) => { this.na = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: 'Glu (可选)', placeholder: 'Glu', inputType: InputType.NUMBER_DECIMAL, onTextChange: (value: string) => { this.glu = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
          InputRow({ label: 'BUN (可选)', placeholder: 'BUN', inputType: InputType.NUMBER_DECIMAL, onTextChange: (value: string) => { this.bun = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: '校正钙', value: this.result!.value, unit: this.result!.unit, decimals: 2, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
