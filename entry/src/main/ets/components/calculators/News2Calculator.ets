import { CalcResult } from '../../engine/CalcEngine';
import { calculateNews2 } from '../../engine/News2Calculator';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard } from './widgets/CalcWidgets';

@Component
export struct News2Calculator {
  @State resetKey: number = 0;  @State resp: number = 0;
  @State spo2: number = 0;
  @State o2supplement: string = '';
  @State temp: number = 0;
  @State sbp: number = 0;
  @State pulse: number = 0;
  @State consciousness: string = '';
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateNews2(this.resp, this.spo2, this.o2supplement, this.temp, this.sbp, this.pulse, this.consciousness); }

  reset() {
    this.resp = 0;
    this.spo2 = 0;
    this.o2supplement = '';
    this.temp = 0;
    this.sbp = 0;
    this.pulse = 0;
    this.consciousness = '';
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
      Column() { Text('用于早期识别危重患者病情恶化').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('7参数：RR+SpO₂+体温+收缩压+心率+意识+吸氧，0-20分').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        Row() { Text('— 输入参数').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });

        Row() {
          InputRow({ label: '呼吸频率 (次/分)', placeholder: '呼吸频率', onTextChange: (value: string) => { this.resp = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: 'SpO₂ (%)', placeholder: 'SpO2', onTextChange: (value: string) => { this.spo2 = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 12 });

        Row() {
          Column() {
            Text('氧疗').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            Row() {
              OptionChip({ label: '无', selected: this.o2supplement === 'no', fontSize: 14, bold: true, chipHeight: AppDimens.inputHeight, onChipClick: () => { this.o2supplement = 'no'; this.calculate(); } }).layoutWeight(1);
              OptionChip({ label: '有', selected: this.o2supplement === 'yes', fontSize: 14, bold: true, chipHeight: AppDimens.inputHeight, onChipClick: () => { this.o2supplement = 'yes'; this.calculate(); } }).layoutWeight(1);
            }.width('100%');
          }.layoutWeight(1);
        }.width('100%').margin({ bottom: 12 });

        Row() {
          Column() {
            Text('体温 (°C)').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            TextInput({ placeholder: '体温' })
              .type(InputType.NUMBER_DECIMAL).height(AppDimens.inputHeight).fontSize(16)
              .backgroundColor(AppColors.card).borderRadius(8)
              .border({ width: 1, color: AppColors.border })
              .padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder)
              .width('100%')
              .onChange((value: string) => { this.temp = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1);
          Column() {
            Text('收缩压 SBP (mmHg)').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            TextInput({ placeholder: 'SBP' })
              .type(InputType.Number).height(AppDimens.inputHeight).fontSize(16)
              .backgroundColor(AppColors.card).borderRadius(8)
              .border({ width: 1, color: AppColors.border })
              .padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder)
              .width('100%')
              .onChange((value: string) => { this.sbp = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 12 });

        Row() {
          InputRow({ label: '脉搏 (次/分)', placeholder: '脉搏', onTextChange: (value: string) => { this.pulse = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          Column() {
            Text('意识状态').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            Flex({ wrap: FlexWrap.Wrap }) {
              OptionChip({ label: '清醒', selected: this.consciousness === 'alert', fontSize: 13, bold: true, horizontalPadding: 8, onChipClick: () => { this.consciousness = 'alert'; this.calculate(); } }).margin({ right: 6, bottom: 4 });
              OptionChip({ label: '新意识模糊', selected: this.consciousness === 'confusion', fontSize: 13, bold: true, horizontalPadding: 8, onChipClick: () => { this.consciousness = 'confusion'; this.calculate(); } }).margin({ bottom: 4 });
            }.width('100%');
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'NEWS2', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
