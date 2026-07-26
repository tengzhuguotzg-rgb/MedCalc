import { CALCULATORS, Calculator } from '../model/CalculatorRegistry';
import { AppColors } from '../utils/AppColors';

@Component
export struct CalcKbLinks {
  @Prop calcId: string = '';

  private getReference(): string {
    const calc = CALCULATORS.find((c: Calculator): boolean => c.id === this.calcId);
    if (calc === undefined || calc.reference === undefined || calc.reference === null) {
      return '';
    }
    return calc.reference;
  }

  build() {
    if (this.getReference().length > 0) {
      Column() {
        Row() {
          Text('\u{1F4D6}')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.primary)
            .margin({ right: 4 });
          Text('来源')
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.primary);
        }
        .width('100%');

        Text(this.getReference())
          .fontSize(12)
          .fontColor(AppColors.textSecondary)
          .width('100%')
          .margin({ top: 4 });
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .backgroundColor(AppColors.card)
      .borderRadius(8)
      .margin({ top: 8 });
    }
  }
}
