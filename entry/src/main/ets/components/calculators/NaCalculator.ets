import { CalcResult } from '../../engine/CalcEngine';
import { calculateNa } from '../../engine/CommonCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, ResetButton, ResultCard } from './widgets/CalcWidgets';

@Component
export struct NaCalculator {
  @State resetKey: number = 0;  @State na: number = 0;
  @State glu: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() {
    this.calculate();
  }

  calculate() {
    this.result = calculateNa(this.na, this.glu);
  }

  reset() {
    this.na = 0;
    this.glu = 0;
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
        Text('用于校正高血糖所致假性低钠血症')
          .fontSize(14)
          .fontColor(AppColors.primary)
          .fontWeight(FontWeight.Medium);
        Text('校正Na = 实测Na + 1.6×(Glu-5.6)/5.6')
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
            Text('实测血 Na⁺ (mmol/L)')
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
          .layoutWeight(1);
          Column() {
            Text('血糖 Glu (mmol/L)')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.textPrimary)
              .margin({ bottom: 6 });
            TextInput({ placeholder: 'Glu' })
              .type(InputType.NUMBER_DECIMAL)
              .height(AppDimens.inputHeight)
              .fontSize(16)
              .backgroundColor(AppColors.card)
              .borderRadius(8)
              .border({ width: 1, color: AppColors.border })
              .padding({ left: 12, right: 12 })
              .placeholderColor(AppColors.placeholder)
              .onChange((value: string) => {
                this.glu = parseFloat(value) || 0;
                this.calculate();
              });
          }
          .layoutWeight(1)
          .margin({ left: 8 });
        }
        .width('100%');
      }

      if (this.result) {
        ResultCard({ title: '校正 Na⁺', value: this.result!.value, unit: this.result!.unit, decimals: 1, valueMarginTop: 4, tierMarginTop: 4, titleMedium: false, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }
    .width('100%')
    .constraintSize({ minHeight: '100%' })
    .padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
