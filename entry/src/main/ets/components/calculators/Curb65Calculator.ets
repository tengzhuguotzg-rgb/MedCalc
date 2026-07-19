import { CalcResult } from '../../engine/CalcEngine';
import { calculateCurb65 } from '../../engine/CommonCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, ResultCard } from './widgets/CalcWidgets';

@Component
export struct Curb65Calculator {
  @State resetKey: number = 0;  @State confusion: number = -1;
  @State urea: number = 0;
  @State ureaUnit: string = 'mmol';
  @State rr: number = 0;
  @State sbp: number = 0;
  @State dbp: number = 0;
  @State age: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    if (this.confusion < 0) {
      this.result = { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
      return;
    }
    this.result = calculateCurb65(this.confusion === 1, this.urea, this.ureaUnit, this.rr, this.sbp, this.dbp, this.age);
  }

  reset() {
    this.confusion = -1;
    this.urea = 0;
    this.ureaUnit = 'mmol';
    this.rr = 0;
    this.sbp = 0;
    this.dbp = 0;
    this.age = 0;
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
      Column() { Text('用于评估社区获得性肺炎严重程度及住院决策').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('5项：意识+BUN+呼吸+血压+年龄≥65，0-5分').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        Row() { Text('— 输入参数').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });

        Row() {
          Text('C 意识混乱').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() {
            Button('否').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.confusion === 0 ? AppColors.card : AppColors.textOption)
              .backgroundColor(this.confusion === 0 ? AppColors.primary : AppColors.fillNeutral).borderRadius(8).border({ width: 1, color: this.confusion === 0 ? AppColors.primary : AppColors.border }).layoutWeight(1)
              .onClick(() => { this.confusion = 0; this.calculate(); });
            Button('是').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.confusion === 1 ? AppColors.card : AppColors.textOption)
              .backgroundColor(this.confusion === 1 ? AppColors.primary : AppColors.fillNeutral).borderRadius(8).border({ width: 1, color: this.confusion === 1 ? AppColors.primary : AppColors.border }).layoutWeight(1)
              .onClick(() => { this.confusion = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 8 });

        Row() {
          Column() {
            Text('尿素氮').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            TextInput({ placeholder: 'Urea' }).type(InputType.NUMBER_DECIMAL).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder)
              .onChange((value: string) => { this.urea = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1);
          Column() {
            Text('呼吸频率').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            TextInput({ placeholder: 'RR' }).type(InputType.Number).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder)
              .onChange((value: string) => { this.rr = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 8 });

        Row() {
          Column() {
            Text('收缩压 SBP').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            TextInput({ placeholder: 'SBP' }).type(InputType.Number).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder)
              .onChange((value: string) => { this.sbp = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1);
          Column() {
            Text('舒张压 DBP').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            TextInput({ placeholder: 'DBP' }).type(InputType.Number).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder)
              .onChange((value: string) => { this.dbp = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 8 });

        Column() {
          Text('年龄').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
          TextInput({ placeholder: '年龄' }).type(InputType.Number).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder)
            .onChange((value: string) => { this.age = parseFloat(value) || 0; this.calculate(); });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'CURB-65 Total', value: this.result!.value, unit: '', decimals: 0, valueMarginTop: 4, tierMarginTop: 4, titleMedium: false, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
