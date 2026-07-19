import { CalcResult } from '../../engine/CalcEngine';
import { calculateAbcd2 } from '../../engine/MoreCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, OptionChip, ResultCard } from './widgets/CalcWidgets';

@Component
export struct Abcd2Calculator {
  @State resetKey: number = 0;  @State age: number = -1;
  @State bp: number = -1;
  @State clin: number = -1;
  @State dur: number = -1;
  @State dm: number = -1;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    if (this.age < 0 || this.bp < 0 || this.clin < 0 || this.dur < 0 || this.dm < 0) {
      this.result = { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
      return;
    }
    this.result = calculateAbcd2(this.age === 1, this.bp === 1, this.clin, this.dur, this.dm === 1);
  }

  reset() {
    this.age = -1;
    this.bp = -1;
    this.clin = -1;
    this.dur = -1;
    this.dm = -1;
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
      Column() { Text('用于评估TIA后短期脑卒中风险').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('5项：年龄+血压+临床表现+持续时间+糖尿病，总分0-7').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });
      CalcCard() {
        Row() { Text('— 输入参数').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });
        OptRow({ label: 'A 年龄 ≥ 60 岁', value: this.age, onChange: (v: number) => { this.age = v; this.calculate(); } });
        OptRow({ label: 'B 血压 ≥ 140/90', value: this.bp, onChange: (v: number) => { this.bp = v; this.calculate(); } });
        Column() {
          Text('C 临床特征').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 8 });
          Row() {
            OptionChip({ label: '其他', selected: this.clin === 0, bold: true, onChipClick: () => { this.clin = 0; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: '言语', selected: this.clin === 1, bold: true, onChipClick: () => { this.clin = 1; this.calculate(); } }).layoutWeight(1).margin({ left: 8 });
            OptionChip({ label: '无力', selected: this.clin === 2, bold: true, onChipClick: () => { this.clin = 2; this.calculate(); } }).layoutWeight(1).margin({ left: 8 });
          }.width('100%');
        }.width('100%').alignItems(HorizontalAlign.Start).margin({ bottom: 12 });
        Column() {
          Text('D 持续时间').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 8 });
          Row() {
            OptionChip({ label: '<10min', selected: this.dur === 0, bold: true, onChipClick: () => { this.dur = 0; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: '10-59min', selected: this.dur === 1, bold: true, onChipClick: () => { this.dur = 1; this.calculate(); } }).layoutWeight(1).margin({ left: 8 });
            OptionChip({ label: '≥60min', selected: this.dur === 2, bold: true, onChipClick: () => { this.dur = 2; this.calculate(); } }).layoutWeight(1).margin({ left: 8 });
          }.width('100%');
        }.width('100%').alignItems(HorizontalAlign.Start).margin({ bottom: 12 });
        OptRow({ label: 'D 糖尿病', value: this.dm, onChange: (v: number) => { this.dm = v; this.calculate(); } });
      }
      if (this.result) {
        ResultCard({ title: 'ABCD² Total', value: this.result!.value, unit: '', decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}

@Component
struct OptRow {
  @Prop value: number = -1;
  private label: string = '';
  private onChange?: (v: number) => void;

  build() {
    Row() {
      Text(this.label).fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
      Row() {
        Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.value === 0 ? AppColors.card : AppColors.textOption).backgroundColor(this.value === 0 ? AppColors.primary : AppColors.fillNeutral).border({ width: this.value === 0 ? 0 : 1, color: AppColors.border }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { if (this.onChange) { this.onChange(0); } });
        Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.value === 1 ? AppColors.card : AppColors.textOption).backgroundColor(this.value === 1 ? AppColors.primary : AppColors.fillNeutral).border({ width: this.value === 1 ? 0 : 1, color: AppColors.border }).borderRadius(8).height(AppDimens.touchTarget).layoutWeight(1).onClick(() => { if (this.onChange) { this.onChange(1); } });
      }.width(100);
    }.width('100%').margin({ bottom: 12 });
  }
}
