import { CalcResult } from '../../engine/CalcEngine';
import { calculateHellp } from '../../engine/Batch1aCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct HellpCalculator {
  @State resetKey: number = 0;
  @State platelet: number = 0;
  @State ast: number = 0;
  @State alt: number = 0;
  @State ldh: number = 0;
  @State bilirubin: number = 0;
  @State bilirubinUnit: string = 'umol';
  @State hemolysis: boolean = false;
  @State pregnancyStatus: string = 'unknown';
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateHellp(this.platelet, this.ast, this.alt, this.ldh, this.bilirubin, this.bilirubinUnit, this.hemolysis, this.pregnancyStatus); }

  reset() {
    this.platelet = 0;
    this.ast = 0;
    this.alt = 0;
    this.ldh = 0;
    this.bilirubin = 0;
    this.bilirubinUnit = 'umol';
    this.hemolysis = false;
    this.pregnancyStatus = 'unknown';
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
        Text('HELLP 标准核对：溶血 + 肝酶升高 + 血小板减少').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('标准核对/分层，不是最终诊断').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '输入参数', resetAction: () => { this.reset(); } })
        Row() {
          InputRow({ label: '血小板 (×10⁹/L)', placeholder: 'PLT', onTextChange: (value: string) => { this.platelet = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: 'LDH (U/L)', placeholder: 'LDH', onTextChange: (value: string) => { this.ldh = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        Row() {
          InputRow({ label: 'AST (U/L)', placeholder: 'AST', onTextChange: (value: string) => { this.ast = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: 'ALT (U/L)', placeholder: 'ALT', onTextChange: (value: string) => { this.alt = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        Row() {
          InputRow({ label: '总胆红素', placeholder: 'TBil', onTextChange: (value: string) => { this.bilirubin = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          Column() {
            Text('胆红素单位').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            Row({ space: 8 }) {
              OptionChip({ label: 'μmol/L', selected: this.bilirubinUnit === 'umol', chipHeight: AppDimens.inputHeight, onChipClick: () => { this.bilirubinUnit = 'umol'; this.calculate(); } });
              OptionChip({ label: 'mg/dL', selected: this.bilirubinUnit === 'mgdl', chipHeight: AppDimens.inputHeight, onChipClick: () => { this.bilirubinUnit = 'mgdl'; this.calculate(); } });
            }
          }.layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });

        Text('溶血证据').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row({ space: 8 }) {
          OptionChip({ label: '无/未填', selected: !this.hemolysis, onChipClick: () => { this.hemolysis = false; this.calculate(); } });
          OptionChip({ label: '有', selected: this.hemolysis, onChipClick: () => { this.hemolysis = true; this.calculate(); } });
        }.width('100%').margin({ bottom: 8 });

        Text('妊娠/产后状态').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row({ space: 8 }) {
          OptionChip({ label: '未填', selected: this.pregnancyStatus === 'unknown', onChipClick: () => { this.pregnancyStatus = 'unknown'; this.calculate(); } });
          OptionChip({ label: '妊娠期', selected: this.pregnancyStatus === 'pregnant', onChipClick: () => { this.pregnancyStatus = 'pregnant'; this.calculate(); } });
          OptionChip({ label: '产后', selected: this.pregnancyStatus === 'postpartum', onChipClick: () => { this.pregnancyStatus = 'postpartum'; this.calculate(); } });
          OptionChip({ label: '非', selected: this.pregnancyStatus === 'no', onChipClick: () => { this.pregnancyStatus = 'no'; this.calculate(); } });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'HELLP 核对', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
