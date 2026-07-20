import { CalcResult } from '../../engine/CalcEngine';
import { calculateScai } from '../../engine/ScaiCalculator';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, OptionChip, ResultCard } from './widgets/CalcWidgets';

@Component
export struct ScaiCalculator {
  @State resetKey: number = 0;
  @State sbp: number = 0;
  @State lac: number = 0;
  @State vaso: string = '';
  @State perf: string = '';
  @State resus: string = '';
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateScai(this.sbp, this.lac, this.vaso, this.perf, this.resus); }

  reset() {
    this.sbp = 0;
    this.lac = 0;
    this.vaso = '';
    this.perf = '';
    this.resus = '';
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
        Text('用于心源性休克分层 (SCAI 2019/2024)')
          .fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('A-E 五级, 基于血压/乳酸/血管活性药/灌注/CPR')
          .fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        Row() {
          Text('— 输入参数').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5);
          Blank();
          Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); });
        }.width('100%').margin({ bottom: 12 });

        Row() {
          Column() {
            Text('收缩压 SBP (mmHg)').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            TextInput({ placeholder: 'SBP' })
              .type(InputType.NUMBER_DECIMAL).height(AppDimens.inputHeight).fontSize(16)
              .backgroundColor(AppColors.card).borderRadius(8)
              .border({ width: 1, color: AppColors.border })
              .padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder)
              .onChange((v: string) => { this.sbp = parseFloat(v) || 0; this.calculate(); });
          }.layoutWeight(1);
          Column() {
            Text('乳酸 (mmol/L)').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            TextInput({ placeholder: '乳酸' })
              .type(InputType.NUMBER_DECIMAL).height(AppDimens.inputHeight).fontSize(16)
              .backgroundColor(AppColors.card).borderRadius(8)
              .border({ width: 1, color: AppColors.border })
              .padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder)
              .onChange((v: string) => { this.lac = parseFloat(v) || 0; this.calculate(); });
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 8 });

        Column() {
          Text('血管活性药').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
          Flex({ wrap: FlexWrap.Wrap }) {
            OptionChip({ label: '无', selected: this.vaso === 'none', bold: true, chipHeight: 34, horizontalPadding: 8, onChipClick: () => { this.vaso = 'none'; this.calculate(); } }).margin({ right: 6, bottom: 4 });
            OptionChip({ label: '1种低剂量', selected: this.vaso === 'low', bold: true, chipHeight: 34, horizontalPadding: 8, onChipClick: () => { this.vaso = 'low'; this.calculate(); } }).margin({ right: 6, bottom: 4 });
            OptionChip({ label: '≥2种/高剂量', selected: this.vaso === 'high', bold: true, chipHeight: 34, horizontalPadding: 8, onChipClick: () => { this.vaso = 'high'; this.calculate(); } }).margin({ bottom: 4 });
          }.width('100%');
        }.width('100%').margin({ bottom: 8 });

        Column() {
          Text('末梢灌注').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
          Row() {
            Button('正常')
              .fontSize(14).fontWeight(FontWeight.Bold)
              .fontColor(this.perf === 'ok' ? AppColors.card : AppColors.textOption)
              .backgroundColor(this.perf === 'ok' ? AppColors.primary : AppColors.fillNeutral)
              .border({ width: 1, color: this.perf === 'ok' ? AppColors.primary : AppColors.border })
              .borderRadius(8).layoutWeight(1)
              .onClick(() => { this.perf = 'ok'; this.calculate(); });
            Button('差 (冷/紫/少尿)')
              .fontSize(14).fontWeight(FontWeight.Bold)
              .fontColor(this.perf === 'bad' ? AppColors.card : AppColors.textOption)
              .backgroundColor(this.perf === 'bad' ? AppColors.primary : AppColors.fillNeutral)
              .border({ width: 1, color: this.perf === 'bad' ? AppColors.primary : AppColors.border })
              .borderRadius(8).layoutWeight(1).margin({ left: 4 })
              .onClick(() => { this.perf = 'bad'; this.calculate(); });
          }.width('100%');
        }.width('100%').margin({ bottom: 8 });

        Column() {
          Text('CPR / ECMO / 机械循环支持?').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
          Row() {
            Button('否')
              .fontSize(14).fontWeight(FontWeight.Bold)
              .fontColor(this.resus === 'no' ? AppColors.card : AppColors.textOption)
              .backgroundColor(this.resus === 'no' ? AppColors.primary : AppColors.fillNeutral)
              .border({ width: 1, color: this.resus === 'no' ? AppColors.primary : AppColors.border })
              .borderRadius(8).layoutWeight(1)
              .onClick(() => { this.resus = 'no'; this.calculate(); });
            Button('是')
              .fontSize(14).fontWeight(FontWeight.Bold)
              .fontColor(this.resus === 'yes' ? AppColors.card : AppColors.textOption)
              .backgroundColor(this.resus === 'yes' ? AppColors.primary : AppColors.fillNeutral)
              .border({ width: 1, color: this.resus === 'yes' ? AppColors.primary : AppColors.border })
              .borderRadius(8).layoutWeight(1).margin({ left: 4 })
              .onClick(() => { this.resus = 'yes'; this.calculate(); });
          }.width('100%');
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'SCAI 休克', value: this.result!.value, valueText: `Stage ${this.result!.unit}`, valueFontSize: 28, valueMarginTop: 4, tierFontSize: 12, tierMarginTop: 4, titleMedium: false, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
