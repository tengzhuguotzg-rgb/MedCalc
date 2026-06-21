import { CalcResult } from '../../engine/CalcEngine';
import { calculateNa } from '../../engine/CommonCalculators';

@Component
export struct NaCalculator {
  @State na: number = 0;
  @State glu: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() {
    this.calculate();
  }

  calculate() {
    this.result = calculateNa(this.na, this.glu);
  }

  build() {
    Column() {
      Column() {
        Text('校正血钠')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F3D2F');
        Text('高血糖时假性低钠校正')
          .fontSize(11.5)
          .fontColor('#4A5247')
          .margin({ top: 2 });
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .margin({ bottom: 12 });

      Column() {
        Text('— 输入参数').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });

        Row() {
          Column() {
            Text('实测血 Na⁺ (mmol/L)')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1F2421')
              .margin({ bottom: 6 });
            TextInput({ placeholder: 'Na' })
              .type(InputType.Number)
              .height(40)
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
              .height(40)
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
                .fontSize(10)
                .fontColor('#7A8074')
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
                .fontColor(this.result!.tierClass === 'tier-ok' ? '#3D6B4F' : 
                           this.result!.tierClass === 'tier-warn' ? '#C8881A' : '#B1452A')
                .backgroundColor(this.result!.tierClass === 'tier-ok' ? '#E8F0EC' : 
                                 this.result!.tierClass === 'tier-warn' ? '#F5EFE0' : '#F5E4E0')
                .borderRadius(20)
                .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                .margin({ top: 4 });
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1);

            
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
    .padding(16);
  }
}
