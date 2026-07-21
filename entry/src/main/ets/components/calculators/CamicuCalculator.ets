import { CalcResult } from '../../engine/CalcEngine';
import { calculateCamicu } from '../../engine/CamicuCalculator';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, ResetButton, ResultCard } from './widgets/CalcWidgets';

@Component
export struct CamicuCalculator {
  @State resetKey: number = 0;
  @State f1: number = -1;
  @State f2: number = -1;
  @State f3: number = -1;
  @State f4: number = -1;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateCamicu(this.f1, this.f2, this.f3, this.f4); }

  reset() {
    this.f1 = -1;
    this.f2 = -1;
    this.f3 = -1;
    this.f4 = -1;
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
        Text('用于ICU谵妄筛查金标准')
          .fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('4 步法 · 特征①+②+(③或④) (Ely 2001)')
          .fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        Row() {
          Text('— 评估特征').fontSize(12).fontColor(AppColors.textSecondary).fontWeight(FontWeight.Bold).letterSpacing(1.5);
          Blank();
          ResetButton({ onReset: () => { this.reset(); } })
        }.width('100%').margin({ bottom: 12 });

        Column() {
          Text('① 意识状态急性改变或波动').fontSize(13).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
          Row() {
            Button('无')
              .fontSize(14).fontWeight(FontWeight.Bold)
              .fontColor(this.f1 === 0 ? AppColors.card : AppColors.textOption)
              .backgroundColor(this.f1 === 0 ? AppColors.primary : AppColors.fillNeutral)
              .border({ width: 1, color: this.f1 === 0 ? AppColors.primary : AppColors.border })
              .borderRadius(8).layoutWeight(1)
              .onClick(() => { this.f1 = 0; this.calculate(); });
            Button('有')
              .fontSize(14).fontWeight(FontWeight.Bold)
              .fontColor(this.f1 === 1 ? AppColors.card : AppColors.textOption)
              .backgroundColor(this.f1 === 1 ? AppColors.primary : AppColors.fillNeutral)
              .border({ width: 1, color: this.f1 === 1 ? AppColors.primary : AppColors.border })
              .borderRadius(8).layoutWeight(1).margin({ left: 4 })
              .onClick(() => { this.f1 = 1; this.calculate(); });
          }.width('100%');
          Text('基线GCS与当前不同? 或过去24h内意识波动?')
            .fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2, bottom: 8 });
        }.width('100%');

        Column() {
          Text('② 注意力缺损').fontSize(13).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
          Row() {
            Button('无')
              .fontSize(14).fontWeight(FontWeight.Bold)
              .fontColor(this.f2 === 0 ? AppColors.card : AppColors.textOption)
              .backgroundColor(this.f2 === 0 ? AppColors.primary : AppColors.fillNeutral)
              .border({ width: 1, color: this.f2 === 0 ? AppColors.primary : AppColors.border })
              .borderRadius(8).layoutWeight(1)
              .onClick(() => { this.f2 = 0; this.calculate(); });
            Button('有')
              .fontSize(14).fontWeight(FontWeight.Bold)
              .fontColor(this.f2 === 1 ? AppColors.card : AppColors.textOption)
              .backgroundColor(this.f2 === 1 ? AppColors.primary : AppColors.fillNeutral)
              .border({ width: 1, color: this.f2 === 1 ? AppColors.primary : AppColors.border })
              .borderRadius(8).layoutWeight(1).margin({ left: 4 })
              .onClick(() => { this.f2 = 1; this.calculate(); });
          }.width('100%');
          Text('ASE法: 说"S-A-V-E-A-H-A-R-T", 听到"A"握手, ≥3次误答=异常')
            .fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2, bottom: 8 });
        }.width('100%');

        Column() {
          Text('③ 意识水平改变 (RASS ≠ 0)').fontSize(13).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
          Row() {
            Button('RASS=0 (清醒)')
              .fontSize(14).fontWeight(FontWeight.Bold)
              .fontColor(this.f3 === 0 ? AppColors.card : AppColors.textOption)
              .backgroundColor(this.f3 === 0 ? AppColors.primary : AppColors.fillNeutral)
              .border({ width: 1, color: this.f3 === 0 ? AppColors.primary : AppColors.border })
              .borderRadius(8).layoutWeight(1)
              .onClick(() => { this.f3 = 0; this.calculate(); });
            Button('RASS≠0')
              .fontSize(14).fontWeight(FontWeight.Bold)
              .fontColor(this.f3 === 1 ? AppColors.card : AppColors.textOption)
              .backgroundColor(this.f3 === 1 ? AppColors.primary : AppColors.fillNeutral)
              .border({ width: 1, color: this.f3 === 1 ? AppColors.primary : AppColors.border })
              .borderRadius(8).layoutWeight(1).margin({ left: 4 })
              .onClick(() => { this.f3 = 1; this.calculate(); });
          }.width('100%').margin({ bottom: 8 });
        }.width('100%');

        Column() {
          Text('④ 思维紊乱').fontSize(13).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
          Row() {
            Button('无')
              .fontSize(14).fontWeight(FontWeight.Bold)
              .fontColor(this.f4 === 0 ? AppColors.card : AppColors.textOption)
              .backgroundColor(this.f4 === 0 ? AppColors.primary : AppColors.fillNeutral)
              .border({ width: 1, color: this.f4 === 0 ? AppColors.primary : AppColors.border })
              .borderRadius(8).layoutWeight(1)
              .onClick(() => { this.f4 = 0; this.calculate(); });
            Button('有')
              .fontSize(14).fontWeight(FontWeight.Bold)
              .fontColor(this.f4 === 1 ? AppColors.card : AppColors.textOption)
              .backgroundColor(this.f4 === 1 ? AppColors.primary : AppColors.fillNeutral)
              .border({ width: 1, color: this.f4 === 1 ? AppColors.primary : AppColors.border })
              .borderRadius(8).layoutWeight(1).margin({ left: 4 })
              .onClick(() => { this.f4 = 1; this.calculate(); });
          }.width('100%');
          Text('是非题(石头会浮吗?) + 指令评估')
            .fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'CAM-ICU', value: this.result!.value, valueText: this.result!.value === 1 ? '阳性' : '阴性', titleMedium: false, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
