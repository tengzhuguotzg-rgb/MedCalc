import { CalcResult , getTierColor, getTierBgColor } from '../../engine/CalcEngine';
import { calculateNa } from '../../engine/CommonCalculators';

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
          .fontColor('#1F3D2F')
          .fontWeight(FontWeight.Medium);
        Text('校正Na = 实测Na + 1.6×(Glu-5.6)/5.6')
          .fontSize(12)
          .fontColor('#5F6654')
          .margin({ top: 2 });
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .margin({ bottom: 12 });

      Column() {
        Row() { Text('— 输入参数').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor('#5F6654').onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });

        Row() {
          Column() {
            Text('实测血 Na⁺ (mmol/L)')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1F2421')
              .margin({ bottom: 6 });
            TextInput({ placeholder: 'Na' })
              .type(InputType.Number)
              .height(48)
              .fontSize(16)
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
              .border({ width: 1, color: '#E0E0E0' })
              .padding({ left: 12, right: 12 })
              .placeholderColor('#999999')
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
              .fontColor('#1F2421')
              .margin({ bottom: 6 });
            TextInput({ placeholder: 'Glu' })
              .type(InputType.Number)
              .height(48)
              .fontSize(16)
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
              .border({ width: 1, color: '#E0E0E0' })
              .padding({ left: 12, right: 12 })
              .placeholderColor('#999999')
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
      .padding(16)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .width('100%')
      .margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() {
              Text('校正 Na⁺')
                .fontSize(12)
                .fontColor('#5F6654')
                .letterSpacing(1.5);
              Text(this.result!.value !== null ? 
                `${this.result!.value!.toFixed(1)} ${this.result!.unit}` : '—')
                .fontSize(32)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1F3D2F')
                .margin({ top: 4 });
              Text(this.result!.tier)
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
                .fontColor(getTierColor(this.result!.tierClass))
                .backgroundColor(getTierBgColor(this.result!.tierClass))
                .borderRadius(20)
                .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                .margin({ top: 4 });
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1);
            Column() {
              Text(this.result!.footnote).fontSize(14).fontColor('#4A5247').lineHeight(22);
            }.layoutWeight(1).alignItems(HorizontalAlign.Start);
          }
          .width('100%');
        }
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .width('100%');
      }
    }
    .width('100%')
    .constraintSize({ minHeight: '100%' })
    .padding(16).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
