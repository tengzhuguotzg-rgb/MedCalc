import { CalcResult , getTierColor, getTierBgColor } from '../../engine/CalcEngine';
import { calculateNews2 } from '../../engine/News2Calculator';
import { AppColors } from '../../utils/AppColors';

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

      Column() {
        Row() { Text('— 输入参数').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });

        Row() {
          Column() {
            Text('呼吸频率 (次/分)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 });
            TextInput({ placeholder: '呼吸频率' }).type(InputType.Number).height(48).fontSize(16).fontColor('#1F2421')
              .placeholderColor('#999999').backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: '#E0E0E0' })
              .padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.resp = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1);
          Column() {
            Text('SpO₂ (%)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 });
            TextInput({ placeholder: 'SpO2' }).type(InputType.Number).height(48).fontSize(16).fontColor('#1F2421')
              .placeholderColor('#999999').backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: '#E0E0E0' })
              .padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.spo2 = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 12 });

        Row() {
          Column() {
            Text('氧疗').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
            Row() {
              Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.o2supplement === 'no' ? AppColors.card : '#2D5440')
                .backgroundColor(this.o2supplement === 'no' ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.o2supplement === 'no' ? AppColors.primary : '#E0E0E0' })
                .borderRadius(8).height(48).layoutWeight(1).onClick(() => { this.o2supplement = 'no'; this.calculate(); });
              Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.o2supplement === 'yes' ? AppColors.card : '#2D5440')
                .backgroundColor(this.o2supplement === 'yes' ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.o2supplement === 'yes' ? AppColors.primary : '#E0E0E0' })
                .borderRadius(8).height(48).layoutWeight(1).onClick(() => { this.o2supplement = 'yes'; this.calculate(); });
            }.width('100%');
          }.layoutWeight(1);
        }.width('100%').margin({ bottom: 12 });

        Row() {
          Column() {
            Text('体温 (°C)').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
            TextInput({ placeholder: '体温' }).type(InputType.NUMBER_DECIMAL).height(48).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).placeholderColor('#999999').width('100%').onChange((value: string) => { this.temp = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1);
          Column() {
            Text('收缩压 SBP (mmHg)').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
            TextInput({ placeholder: 'SBP' }).type(InputType.Number).height(48).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).placeholderColor('#999999').width('100%').onChange((value: string) => { this.sbp = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 12 });

        Row() {
          Column() {
            Text('脉搏 (次/分)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 });
            TextInput({ placeholder: '脉搏' }).type(InputType.Number).height(48).fontSize(16).fontColor('#1F2421')
              .placeholderColor('#999999').backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: '#E0E0E0' })
              .padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.pulse = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1);
          Column() {
            Text('意识状态').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
            Flex({ wrap: FlexWrap.Wrap }) {
              Button('清醒').fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.consciousness === 'alert' ? AppColors.card : '#2D5440')
                .backgroundColor(this.consciousness === 'alert' ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.consciousness === 'alert' ? AppColors.primary : '#E0E0E0' })
                .borderRadius(8).height(44).padding({ left: 8, right: 8 }).margin({ right: 6, bottom: 4 }).onClick(() => { this.consciousness = 'alert'; this.calculate(); });
              Button('新意识模糊').fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.consciousness === 'confusion' ? AppColors.card : '#2D5440')
                .backgroundColor(this.consciousness === 'confusion' ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.consciousness === 'confusion' ? AppColors.primary : '#E0E0E0' })
                .borderRadius(8).height(44).padding({ left: 8, right: 8 }).margin({ bottom: 4 }).onClick(() => { this.consciousness = 'confusion'; this.calculate(); });
            }.width('100%');
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%');
      }.padding(16).backgroundColor(AppColors.card).borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() {
              Text('NEWS2').fontSize(12).fontColor(AppColors.textSecondary).letterSpacing(1.5).fontWeight(FontWeight.Medium);
              Text(this.result!.value !== null ? `${this.result!.value!.toFixed(0)} ${this.result!.unit}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor(AppColors.primary).margin({ top: 8 });
              Text(this.result!.tier).fontSize(13).fontWeight(FontWeight.Bold).fontColor(getTierColor(this.result!.tierClass))
                .backgroundColor(getTierBgColor(this.result!.tierClass)).borderRadius(20).padding({ left: 12, right: 12, top: 4, bottom: 4 }).margin({ top: 8 });
            }.alignItems(HorizontalAlign.Start).layoutWeight(1);
            Column() { Text(this.result!.footnote).fontSize(14).fontColor('#4A5247').lineHeight(22); }.layoutWeight(1).alignItems(HorizontalAlign.Start);
          }.width('100%');
        }.padding(16).backgroundColor(AppColors.card).borderRadius(12).width('100%');
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(16).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
