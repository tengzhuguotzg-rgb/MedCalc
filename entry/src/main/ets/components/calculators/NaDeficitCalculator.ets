import { CalcResult } from '../../engine/CalcEngine';
import { calculateNaDeficit } from '../../engine/CommonCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, ResetButton, ResultCard } from './widgets/CalcWidgets';

@Component
export struct NaDeficitCalculator {
  @State resetKey: number = 0;
  @State weight: number = 0;
  @State na: number = 0;
  @State targetNa: number = 0;
  @State tbwGroup: number = -1;
  @State result: CalcResult | null = null;

  aboutToAppear() {
    this.calculate();
  }

  calculate() {
    if (this.tbwGroup < 0) {
      this.result = { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
      return;
    }
    this.result = calculateNaDeficit(this.weight, this.na, this.targetNa, this.tbwGroup === 1, this.tbwGroup === 2);
  }

  reset() {
    this.weight = 0;
    this.na = 0;
    this.targetNa = 0;
    this.tbwGroup = -1;
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
        Text('计算低钠血症的钠缺失量')
          .fontSize(14)
          .fontColor(AppColors.primary)
          .fontWeight(FontWeight.Medium);
        Text('Na缺失 = TBW因子 × 体重 × (目标Na - 实测Na)')
          .fontSize(12)
          .fontColor(AppColors.textSecondary)
          .margin({ top: 2 });
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .margin({ bottom: 12 });

      CalcCard() {
        Row() { Text('— 输入参数').fontSize(12).fontColor(AppColors.textSecondary).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); ResetButton({ onReset: () => { this.reset(); } }) }.width('100%').margin({ bottom: 12 });

        Row() {
          Column() {
            Text('体重 (kg)')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.textPrimary)
              .margin({ bottom: 6 });
            TextInput({ placeholder: 'kg' })
              .type(InputType.NUMBER_DECIMAL)
              .height(AppDimens.inputHeight)
              .fontSize(16)
              .backgroundColor(AppColors.card)
              .borderRadius(8)
              .border({ width: 1, color: AppColors.border })
              .padding({ left: 12, right: 12 })
              .placeholderColor(AppColors.placeholder)
              .onChange((value: string) => {
                this.weight = parseFloat(value) || 0;
                this.calculate();
              });
          }
          .layoutWeight(1);
          Column() {
            Text('实测 Na⁺ (mmol/L)')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.textPrimary)
              .margin({ bottom: 6 });
            TextInput({ placeholder: 'Na' })
              .type(InputType.Number)
              .height(AppDimens.inputHeight)
              .fontSize(16)
              .backgroundColor(AppColors.card)
              .borderRadius(8)
              .border({ width: 1, color: AppColors.border })
              .padding({ left: 12, right: 12 })
              .placeholderColor(AppColors.placeholder)
              .onChange((value: string) => {
                this.na = parseFloat(value) || 0;
                this.calculate();
              });
          }
          .layoutWeight(1)
          .margin({ left: 8 });
        }
        .width('100%');

        Row() {
          Column() {
            Text('目标 Na⁺ (mmol/L)')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.textPrimary)
              .margin({ bottom: 6 });
            TextInput({ placeholder: '140', text: this.targetNa > 0 ? this.targetNa.toString() : '' })
              .type(InputType.Number)
              .height(AppDimens.inputHeight)
              .fontSize(16)
              .backgroundColor(AppColors.card)
              .borderRadius(8)
              .border({ width: 1, color: AppColors.border })
              .padding({ left: 12, right: 12 })
              .placeholderColor(AppColors.placeholder)
              .onChange((value: string) => {
                this.targetNa = parseFloat(value) || 0;
                this.calculate();
              });
          }
          .layoutWeight(1);
        }
        .width('100%')
        .margin({ top: 8 });

        Column() {
          Text('TBW因子')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.textPrimary)
            .margin({ bottom: 8 });
          Row() {
            Toggle({ type: ToggleType.Button, isOn: this.tbwGroup === 0 })
              .selectedColor(AppColors.primary)
              .onChange((isOn: boolean) => {
                if (isOn) { this.tbwGroup = 0; this.calculate(); }
              })
              .width(48).height(32);
            Text('男0.6').fontSize(12).fontColor(AppColors.textBody).margin({ left: 4, right: 16 });

            Toggle({ type: ToggleType.Button, isOn: this.tbwGroup === 1 })
              .selectedColor(AppColors.primary)
              .onChange((isOn: boolean) => {
                if (isOn) { this.tbwGroup = 1; this.calculate(); }
              })
              .width(48).height(32);
            Text('女0.5').fontSize(12).fontColor(AppColors.textBody).margin({ left: 4, right: 16 });

            Toggle({ type: ToggleType.Button, isOn: this.tbwGroup === 2 })
              .selectedColor(AppColors.primary)
              .onChange((isOn: boolean) => {
                if (isOn) { this.tbwGroup = 2; this.calculate(); }
              })
              .width(48).height(32);
            Text('儿童0.6').fontSize(12).fontColor(AppColors.textBody).margin({ left: 4 });
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .margin({ top: 8 });
      }

      if (this.result) {
        ResultCard({ title: 'Na⁺ 缺失量', value: this.result!.value, unit: this.result!.unit, valueMarginTop: 4, tierMarginTop: 4, titleMedium: false, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }
    .width('100%')
    .constraintSize({ minHeight: '100%' })
    .padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
