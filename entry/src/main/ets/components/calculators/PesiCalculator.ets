import { CalcResult } from '../../engine/CalcEngine';
import { calculatePesi } from '../../engine/PesiCalculator';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, ResetButton, ResultCard } from './widgets/CalcWidgets';

@Component
export struct PesiCalculator {
  @State resetKey: number = 0;
  @State age: number = 0;
  @State sex: number = -1;
  @State cancer: number = -1;
  @State chf: number = -1;
  @State cld: number = -1;
  @State hr: number = 0;
  @State sbp: number = 0;
  @State rr: number = 0;
  @State temp: number = 0;
  @State ams: number = -1;
  @State osp: number = -1;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculatePesi(this.age, this.sex, this.cancer, this.chf, this.cld, this.hr, this.sbp, this.rr, this.temp, this.ams, this.osp); }

  reset() {
    this.age = 0;
    this.sex = -1;
    this.cancer = -1;
    this.chf = -1;
    this.cld = -1;
    this.hr = 0;
    this.sbp = 0;
    this.rr = 0;
    this.temp = 0;
    this.ams = -1;
    this.osp = -1;
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
        Text('用于肺栓塞 30 天死亡风险分层')
          .fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('11 项, 总分 0-300+, sPESI 简化版 (Aujesky 2005)')
          .fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        Row() {
          Text('— PESI 参数').fontSize(12).fontColor(AppColors.textSecondary).fontWeight(FontWeight.Bold).letterSpacing(1.5);
          Blank();
          ResetButton({ onReset: () => { this.reset(); } })
        }.width('100%').margin({ bottom: 12 });

        Row() {
          Column() {
            Text('年龄 (岁)').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            TextInput({ placeholder: '年龄' })
              .type(InputType.Number).height(AppDimens.inputHeight).fontSize(16)
              .backgroundColor(AppColors.card).borderRadius(8)
              .border({ width: 1, color: AppColors.border })
              .padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder)
              .onChange((v: string) => { this.age = parseFloat(v) || 0; this.calculate(); });
          }.layoutWeight(1);
          Column() {
            Text('性别').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            Row() {
              Button('女')
                .fontSize(14).fontWeight(FontWeight.Bold)
                .fontColor(this.sex === 0 ? AppColors.card : AppColors.textOption)
                .backgroundColor(this.sex === 0 ? AppColors.primary : AppColors.fillNeutral)
                .border({ width: 1, color: this.sex === 0 ? AppColors.primary : AppColors.border })
                .borderRadius(8).layoutWeight(1)
                .onClick(() => { this.sex = 0; this.calculate(); });
              Button('男')
                .fontSize(14).fontWeight(FontWeight.Bold)
                .fontColor(this.sex === 10 ? AppColors.card : AppColors.textOption)
                .backgroundColor(this.sex === 10 ? AppColors.primary : AppColors.fillNeutral)
                .border({ width: 1, color: this.sex === 10 ? AppColors.primary : AppColors.border })
                .borderRadius(8).layoutWeight(1).margin({ left: 4 })
                .onClick(() => { this.sex = 10; this.calculate(); });
            }.width('100%');
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 8 });

        Row() {
          Column() {
            Text('恶性肿瘤').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            Row() {
              Button('无')
                .fontSize(14).fontWeight(FontWeight.Bold)
                .fontColor(this.cancer === 0 ? AppColors.card : AppColors.textOption)
                .backgroundColor(this.cancer === 0 ? AppColors.primary : AppColors.fillNeutral)
                .border({ width: 1, color: this.cancer === 0 ? AppColors.primary : AppColors.border })
                .borderRadius(8).layoutWeight(1)
                .onClick(() => { this.cancer = 0; this.calculate(); });
              Button('有')
                .fontSize(14).fontWeight(FontWeight.Bold)
                .fontColor(this.cancer === 30 ? AppColors.card : AppColors.textOption)
                .backgroundColor(this.cancer === 30 ? AppColors.primary : AppColors.fillNeutral)
                .border({ width: 1, color: this.cancer === 30 ? AppColors.primary : AppColors.border })
                .borderRadius(8).layoutWeight(1).margin({ left: 4 })
                .onClick(() => { this.cancer = 30; this.calculate(); });
            }.width('100%');
          }.layoutWeight(1);
          Column() {
            Text('心衰').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            Row() {
              Button('无')
                .fontSize(14).fontWeight(FontWeight.Bold)
                .fontColor(this.chf === 0 ? AppColors.card : AppColors.textOption)
                .backgroundColor(this.chf === 0 ? AppColors.primary : AppColors.fillNeutral)
                .border({ width: 1, color: this.chf === 0 ? AppColors.primary : AppColors.border })
                .borderRadius(8).layoutWeight(1)
                .onClick(() => { this.chf = 0; this.calculate(); });
              Button('有')
                .fontSize(14).fontWeight(FontWeight.Bold)
                .fontColor(this.chf === 10 ? AppColors.card : AppColors.textOption)
                .backgroundColor(this.chf === 10 ? AppColors.primary : AppColors.fillNeutral)
                .border({ width: 1, color: this.chf === 10 ? AppColors.primary : AppColors.border })
                .borderRadius(8).layoutWeight(1).margin({ left: 4 })
                .onClick(() => { this.chf = 10; this.calculate(); });
            }.width('100%');
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 8 });

        Row() {
          Column() {
            Text('慢性肺病').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            Row() {
              Button('无')
                .fontSize(14).fontWeight(FontWeight.Bold)
                .fontColor(this.cld === 0 ? AppColors.card : AppColors.textOption)
                .backgroundColor(this.cld === 0 ? AppColors.primary : AppColors.fillNeutral)
                .border({ width: 1, color: this.cld === 0 ? AppColors.primary : AppColors.border })
                .borderRadius(8).layoutWeight(1)
                .onClick(() => { this.cld = 0; this.calculate(); });
              Button('有')
                .fontSize(14).fontWeight(FontWeight.Bold)
                .fontColor(this.cld === 10 ? AppColors.card : AppColors.textOption)
                .backgroundColor(this.cld === 10 ? AppColors.primary : AppColors.fillNeutral)
                .border({ width: 1, color: this.cld === 10 ? AppColors.primary : AppColors.border })
                .borderRadius(8).layoutWeight(1).margin({ left: 4 })
                .onClick(() => { this.cld = 10; this.calculate(); });
            }.width('100%');
          }.layoutWeight(1);
          Column() {
            Text('心率 (bpm)').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            TextInput({ placeholder: 'HR' })
              .type(InputType.Number).height(AppDimens.inputHeight).fontSize(16)
              .backgroundColor(AppColors.card).borderRadius(8)
              .border({ width: 1, color: AppColors.border })
              .padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder)
              .onChange((v: string) => { this.hr = parseFloat(v) || 0; this.calculate(); });
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 8 });

        Row() {
          Column() {
            Text('SBP (mmHg)').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            TextInput({ placeholder: 'SBP' })
              .type(InputType.Number).height(AppDimens.inputHeight).fontSize(16)
              .backgroundColor(AppColors.card).borderRadius(8)
              .border({ width: 1, color: AppColors.border })
              .padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder)
              .onChange((v: string) => { this.sbp = parseFloat(v) || 0; this.calculate(); });
          }.layoutWeight(1);
          Column() {
            Text('呼吸频率 (次/分)').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            TextInput({ placeholder: 'RR' })
              .type(InputType.Number).height(AppDimens.inputHeight).fontSize(16)
              .backgroundColor(AppColors.card).borderRadius(8)
              .border({ width: 1, color: AppColors.border })
              .padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder)
              .onChange((v: string) => { this.rr = parseFloat(v) || 0; this.calculate(); });
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 8 });

        Row() {
          Column() {
            Text('体温 (°C)').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            TextInput({ placeholder: '体温' })
              .type(InputType.NUMBER_DECIMAL).height(AppDimens.inputHeight).fontSize(16)
              .backgroundColor(AppColors.card).borderRadius(8)
              .border({ width: 1, color: AppColors.border })
              .padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder)
              .onChange((v: string) => { this.temp = parseFloat(v) || 0; this.calculate(); });
          }.layoutWeight(1);
          Column() {
            Text('意识状态').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            Row() {
              Button('正常')
                .fontSize(14).fontWeight(FontWeight.Bold)
                .fontColor(this.ams === 0 ? AppColors.card : AppColors.textOption)
                .backgroundColor(this.ams === 0 ? AppColors.primary : AppColors.fillNeutral)
                .border({ width: 1, color: this.ams === 0 ? AppColors.primary : AppColors.border })
                .borderRadius(8).layoutWeight(1)
                .onClick(() => { this.ams = 0; this.calculate(); });
              Button('改变')
                .fontSize(14).fontWeight(FontWeight.Bold)
                .fontColor(this.ams === 60 ? AppColors.card : AppColors.textOption)
                .backgroundColor(this.ams === 60 ? AppColors.primary : AppColors.fillNeutral)
                .border({ width: 1, color: this.ams === 60 ? AppColors.primary : AppColors.border })
                .borderRadius(8).layoutWeight(1).margin({ left: 4 })
                .onClick(() => { this.ams = 60; this.calculate(); });
            }.width('100%');
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 8 });

        Column() {
          Text('SpO₂ < 90%').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
          Row() {
            Button('≥ 90%')
              .fontSize(14).fontWeight(FontWeight.Bold)
              .fontColor(this.osp === 0 ? AppColors.card : AppColors.textOption)
              .backgroundColor(this.osp === 0 ? AppColors.primary : AppColors.fillNeutral)
              .border({ width: 1, color: this.osp === 0 ? AppColors.primary : AppColors.border })
              .borderRadius(8).layoutWeight(1)
              .onClick(() => { this.osp = 0; this.calculate(); });
            Button('< 90%')
              .fontSize(14).fontWeight(FontWeight.Bold)
              .fontColor(this.osp === 20 ? AppColors.card : AppColors.textOption)
              .backgroundColor(this.osp === 20 ? AppColors.primary : AppColors.fillNeutral)
              .border({ width: 1, color: this.osp === 20 ? AppColors.primary : AppColors.border })
              .borderRadius(8).layoutWeight(1).margin({ left: 4 })
              .onClick(() => { this.osp = 20; this.calculate(); });
          }.width('100%');
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'PESI 总分', value: this.result!.value, unit: '', decimals: 0, valueMarginTop: 4, tierMarginTop: 4, titleMedium: false, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
