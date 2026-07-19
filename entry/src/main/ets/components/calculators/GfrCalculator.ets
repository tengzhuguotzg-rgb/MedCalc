import { CalcResult } from '../../engine/CalcEngine';
import { calculateGfr } from '../../engine/GfrCalculator';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard } from './widgets/CalcWidgets';

@Component
export struct GfrCalculator {
  @State resetKey: number = 0;  @State sex: string = '';
  @State age: number = 0;
  @State creatinine: number = 0;
  @State crUnit: string = 'umol';
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateGfr(this.sex, this.age, this.creatinine, this.crUnit); }

  reset() {
    this.sex = '';
    this.age = 0;
    this.creatinine = 0;
    this.crUnit = 'umol';
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
      Column() { Text('用于评估肾小球滤过率，CKD分期').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('CKD-EPI 2021 race-free公式，需肌酐+年龄+性别').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        Row() { Text('— 输入参数').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });

        Row() {
          OptionChip({ label: '男', selected: this.sex === 'male', fontSize: 15, bold: true, chipHeight: AppDimens.inputHeight, onChipClick: () => { this.sex = 'male'; this.calculate(); } }).layoutWeight(1);
          OptionChip({ label: '女', selected: this.sex === 'female', fontSize: 15, bold: true, chipHeight: AppDimens.inputHeight, onChipClick: () => { this.sex = 'female'; this.calculate(); } }).layoutWeight(1);
        }.width('100%').margin({ bottom: 16 });

        InputRow({ label: '年龄 (岁)', placeholder: '请输入年龄', onTextChange: (value: string) => { this.age = parseFloat(value) || 0; this.calculate(); } }).width('100%').margin({ bottom: 12 });

        Column() {
          InputRow({ label: '血肌酐', placeholder: '肌酐', onTextChange: (value: string) => { this.creatinine = parseFloat(value) || 0; this.calculate(); } });
          Flex({ wrap: FlexWrap.Wrap }) {
            OptionChip({ label: 'µmol/L', selected: this.crUnit === 'umol', fontSize: 12, bold: true, chipHeight: 28, chipRadius: 6, horizontalPadding: 6, onChipClick: () => { this.crUnit = 'umol'; this.calculate(); } }).margin({ right: 4, bottom: 4 });
            OptionChip({ label: 'mg/dL', selected: this.crUnit === 'mgdl', fontSize: 12, bold: true, chipHeight: 28, chipRadius: 6, horizontalPadding: 6, onChipClick: () => { this.crUnit = 'mgdl'; this.calculate(); } }).margin({ bottom: 4 });
          }.width('100%').margin({ top: 4 });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'eGFR', value: this.result!.value, unit: this.result!.unit, decimals: 1, trimZero: true, valueMarginTop: 4, tierMarginTop: 4, unitInline: false, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
