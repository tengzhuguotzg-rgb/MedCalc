import { CalcResult } from '../../engine/CalcEngine';
import { calculateKdigo } from '../../engine/KdigoCalculator';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, ResultCard } from './widgets/CalcWidgets';

@Component
export struct KdigoCalculator {
  @State resetKey: number = 0;
  @State cr0Raw: number = 0;
  @State cr0Unit: string = 'mgdl';
  @State cr1Raw: number = 0;
  @State cr1Unit: string = 'mgdl';
  @State urine: number = 0;
  @State rrt: number = -1;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    if (this.rrt < 0) {
      this.result = { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
      return;
    }
    const cr0 = this.cr0Raw > 0 ? this.cr0Raw : null;
    this.result = calculateKdigo(cr0, this.cr0Unit, this.cr1Raw, this.cr1Unit, this.urine > 0 ? this.urine : null, this.rrt === 1);
  }

  reset() {
    this.cr0Raw = 0;
    this.cr0Unit = 'mgdl';
    this.cr1Raw = 0;
    this.cr1Unit = 'mgdl';
    this.urine = 0;
    this.rrt = -1;
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
      Column() { Text('用于急性肾损伤分期评估').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('基于肌酐变化和尿量，KDIGO 2012').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        Row() { Text('— 基础 Cr (如未知填 0)').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });
        Row() {
          Column() {
            Text('基础 Cr').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            TextInput({ placeholder: '基础 Cr' }).type(InputType.NUMBER_DECIMAL).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder).onChange((value: string) => { this.cr0Raw = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1);
          Column() {
            Text('单位').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            Flex({ wrap: FlexWrap.Wrap }) {
              Button('mg/dL').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.cr0Unit === 'mgdl' ? AppColors.card : AppColors.textOption).backgroundColor(this.cr0Unit === 'mgdl' ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.cr0Unit === 'mgdl' ? AppColors.primary : AppColors.border }).borderRadius(8).height(34).padding({ left: 8, right: 8 }).margin({ right: 4, bottom: 4 }).onClick(() => { this.cr0Unit = 'mgdl'; this.calculate(); });
              Button('µmol/L').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.cr0Unit === 'umol' ? AppColors.card : AppColors.textOption).backgroundColor(this.cr0Unit === 'umol' ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.cr0Unit === 'umol' ? AppColors.primary : AppColors.border }).borderRadius(8).height(34).padding({ left: 8, right: 8 }).margin({ bottom: 4 }).onClick(() => { this.cr0Unit = 'umol'; this.calculate(); });
            }.width('100%');
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 12 });

        Text('— 当前 Cr (7 天内)').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });
        Row() {
          Column() {
            Text('当前 Cr').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            TextInput({ placeholder: '当前 Cr' }).type(InputType.NUMBER_DECIMAL).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder).onChange((value: string) => { this.cr1Raw = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1);
          Column() {
            Text('单位').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            Flex({ wrap: FlexWrap.Wrap }) {
              Button('mg/dL').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.cr1Unit === 'mgdl' ? AppColors.card : AppColors.textOption).backgroundColor(this.cr1Unit === 'mgdl' ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.cr1Unit === 'mgdl' ? AppColors.primary : AppColors.border }).borderRadius(8).height(34).padding({ left: 8, right: 8 }).margin({ right: 4, bottom: 4 }).onClick(() => { this.cr1Unit = 'mgdl'; this.calculate(); });
              Button('µmol/L').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.cr1Unit === 'umol' ? AppColors.card : AppColors.textOption).backgroundColor(this.cr1Unit === 'umol' ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.cr1Unit === 'umol' ? AppColors.primary : AppColors.border }).borderRadius(8).height(34).padding({ left: 8, right: 8 }).margin({ bottom: 4 }).onClick(() => { this.cr1Unit = 'umol'; this.calculate(); });
            }.width('100%');
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 12 });

        Column() {
          Text('尿量 (mL/kg/h)').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
          TextInput({ placeholder: '未监测可不填' }).type(InputType.NUMBER_DECIMAL).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder).onChange((value: string) => { this.urine = parseFloat(value) || 0; this.calculate(); });
          Text('≤0.3×≥24h=3期 · ≤0.5×≥12h=2期 · <0.5×6-12h=1期').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
        }.width('100%').margin({ bottom: 12 });

        Column() {
          Text('已启动 RRT').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
          Row() {
            Button('否').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.rrt === 0 ? AppColors.card : AppColors.textOption).backgroundColor(this.rrt === 0 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.rrt === 0 ? AppColors.primary : AppColors.border }).borderRadius(8).layoutWeight(1).onClick(() => { this.rrt = 0; this.calculate(); });
            Button('是').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.rrt === 1 ? AppColors.card : AppColors.textOption).backgroundColor(this.rrt === 1 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.rrt === 1 ? AppColors.primary : AppColors.border }).borderRadius(8).layoutWeight(1).margin({ left: 4 }).onClick(() => { this.rrt = 1; this.calculate(); });
          }.width('100%');
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'KDIGO AKI', value: this.result!.value, unit: this.result!.unit, decimals: 0, valueMarginTop: 4, tierMarginTop: 4, titleMedium: false, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
