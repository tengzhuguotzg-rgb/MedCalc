import { CalcResult, getTierColor, getTierBgColor } from '../../engine/CalcEngine';
import { calculateFssicu } from '../../engine/FssicuCalculator';
import { AppColors } from '../../utils/AppColors';

@Component
export struct FssicuCalculator {
  @State resetKey: number = 0;
  @State roll: number = -1;
  @State situp: number = -1;
  @State sit: number = -1;
  @State standup: number = -1;
  @State stand: number = -1;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateFssicu(this.roll, this.situp, this.sit, this.standup, this.stand); }

  reset() {
    this.roll = -1;
    this.situp = -1;
    this.sit = -1;
    this.standup = -1;
    this.stand = -1;
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
      Column() { Text('用于 ICU 患者功能状态评估').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('5 项各 0-7, 总分 0-35 (Thrush 2012)').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Row() { Text('— 评分标准: 0=无法 · 1=完全帮助 · 2=最大帮助 · 3=中度帮助 · 4=最小帮助 · 5=监护 · 6=独立(需辅) · 7=完全独立').fontSize(12).fontColor(AppColors.textSecondary); Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });

        FssRowComponent({ label: '① 翻身 (仰卧→侧卧)', value: this.roll, onChange: (v: number): void => { this.roll = v; this.calculate(); } });
        FssRowComponent({ label: '② 卧位→坐位', value: this.situp, onChange: (v: number): void => { this.situp = v; this.calculate(); } });
        FssRowComponent({ label: '③ 床缘静坐平衡', value: this.sit, onChange: (v: number): void => { this.sit = v; this.calculate(); } });
        FssRowComponent({ label: '④ 坐位→站立', value: this.standup, onChange: (v: number): void => { this.standup = v; this.calculate(); } });
        FssRowComponent({ label: '⑤ 站立平衡', value: this.stand, onChange: (v: number): void => { this.stand = v; this.calculate(); } });
      }.padding(16).backgroundColor(AppColors.card).borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() {
              Text('FSS-ICU').fontSize(12).fontColor(AppColors.textSecondary).letterSpacing(1.5);
              Text(this.result!.value !== null ? `${this.result!.value!.toFixed(0)} ${this.result!.unit}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor(AppColors.primary).margin({ top: 4 });
              Text(this.result!.tier).fontSize(13).fontWeight(FontWeight.Bold).fontColor(getTierColor(this.result!.tierClass)).backgroundColor(getTierBgColor(this.result!.tierClass)).borderRadius(20).padding({ left: 12, right: 12, top: 4, bottom: 4 }).margin({ top: 4 });
            }.alignItems(HorizontalAlign.Start).layoutWeight(1);
            Column() {
              Text(this.result!.footnote).fontSize(14).fontColor('#4A5247').lineHeight(22);
            }.layoutWeight(1).alignItems(HorizontalAlign.Start);
          }.width('100%');
        }.padding(16).backgroundColor(AppColors.card).borderRadius(12).width('100%');
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(16).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}

@Component
struct FssRowComponent {
  @Prop value: number = -1;
  @Prop label: string = '';
  private onChange?: (v: number) => void;

  build() {
    Column() {
      Text(this.label).fontSize(13).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
      Row() {
        Button('0').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.value === 0 ? AppColors.card : '#2D5440').backgroundColor(this.value === 0 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.value === 0 ? AppColors.primary : '#E0E0E0' }).borderRadius(6).height(32).width(32).margin({ right: 3, bottom: 4 }).onClick(() => { if (this.onChange) { this.onChange(0); } });
        Button('1').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.value === 1 ? AppColors.card : '#2D5440').backgroundColor(this.value === 1 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.value === 1 ? AppColors.primary : '#E0E0E0' }).borderRadius(6).height(32).width(32).margin({ right: 3, bottom: 4 }).onClick(() => { if (this.onChange) { this.onChange(1); } });
        Button('2').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.value === 2 ? AppColors.card : '#2D5440').backgroundColor(this.value === 2 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.value === 2 ? AppColors.primary : '#E0E0E0' }).borderRadius(6).height(32).width(32).margin({ right: 3, bottom: 4 }).onClick(() => { if (this.onChange) { this.onChange(2); } });
        Button('3').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.value === 3 ? AppColors.card : '#2D5440').backgroundColor(this.value === 3 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.value === 3 ? AppColors.primary : '#E0E0E0' }).borderRadius(6).height(32).width(32).margin({ right: 3, bottom: 4 }).onClick(() => { if (this.onChange) { this.onChange(3); } });
        Button('4').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.value === 4 ? AppColors.card : '#2D5440').backgroundColor(this.value === 4 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.value === 4 ? AppColors.primary : '#E0E0E0' }).borderRadius(6).height(32).width(32).margin({ right: 3, bottom: 4 }).onClick(() => { if (this.onChange) { this.onChange(4); } });
        Button('5').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.value === 5 ? AppColors.card : '#2D5440').backgroundColor(this.value === 5 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.value === 5 ? AppColors.primary : '#E0E0E0' }).borderRadius(6).height(32).width(32).margin({ right: 3, bottom: 4 }).onClick(() => { if (this.onChange) { this.onChange(5); } });
        Button('6').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.value === 6 ? AppColors.card : '#2D5440').backgroundColor(this.value === 6 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.value === 6 ? AppColors.primary : '#E0E0E0' }).borderRadius(6).height(32).width(32).margin({ right: 3, bottom: 4 }).onClick(() => { if (this.onChange) { this.onChange(6); } });
        Button('7').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.value === 7 ? AppColors.card : '#2D5440').backgroundColor(this.value === 7 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.value === 7 ? AppColors.primary : '#E0E0E0' }).borderRadius(6).height(32).width(32).margin({ right: 3, bottom: 4 }).onClick(() => { if (this.onChange) { this.onChange(7); } });
      }.width('100%');
    }.width('100%').margin({ bottom: 10 });
  }
}
