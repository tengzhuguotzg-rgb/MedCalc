import { CalcResult } from '../../engine/CalcEngine';
import { calculateCrCl } from '../../engine/CrClCalculator';

@Component
export struct CrClCalculator {  @State sex: string = 'male';
  @State age: number = 0;
  @State weight: number = 0;
  @State creatinine: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() {
    this.calculate();
  }

  calculate() {
    this.result = calculateCrCl(this.sex, this.age, this.weight, this.creatinine);
  }

  build() {
    Column() {
      this.Header();
      this.InputForm();
      if (this.result) {
        this.ResultCard();
      }
    }
    .width('100%')
    .constraintSize({ minHeight: '100%' })
    .padding(16).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }

  @Builder
  Header() {
    Column() {
      Text('用于评估肾功能，指导经肾药物剂量调整')
          .fontSize(14)
          .fontColor('#1F3D2F')
          .fontWeight(FontWeight.Medium);
        Text('Cockcroft-Gault公式，需肌酐+年龄+体重+性别')
          .fontSize(12)
          .fontColor('#7A8074')
          .margin({ top: 2 });
      }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .margin({ bottom: 12 });
  }

  @Builder
  InputForm() {
    Column() {
      Text('— 输入参数')
        .fontSize(12)
        .fontColor('#E76F2C')
        .fontWeight(FontWeight.Bold)
        .letterSpacing(1.5)
        .margin({ bottom: 12 });

      Row() {
        Button('男')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.sex === 'male' ? '#FFFFFF' : '#2D5440')
          .backgroundColor(this.sex === 'male' ? '#1F3D2F' : '#F5F5F5')
          .border({ width: 1, color: this.sex === 'male' ? '#1F3D2F' : '#E0E0E0' })
          .borderRadius(8)
          .height(40)
          .layoutWeight(1)
          .onClick(() => {
            this.sex = 'male';
            this.calculate();
          });
        Button('女')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.sex === 'female' ? '#FFFFFF' : '#2D5440')
          .backgroundColor(this.sex === 'female' ? '#1F3D2F' : '#F5F5F5')
          .border({ width: 1, color: this.sex === 'female' ? '#1F3D2F' : '#E0E0E0' })
          .borderRadius(8)
          .height(40)
          .layoutWeight(1)
          .onClick(() => {
            this.sex = 'female';
            this.calculate();
          });
      }
      .width('100%')
      .margin({ bottom: 16 });

      Row() {
        Column() {
          Text('年龄 (岁)')
            .fontSize(14)
            .fontColor('#1F2421')
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 6 });
          TextInput({ placeholder: '请输入年龄' })
            .type(InputType.Number)
            .height(40)
            .fontSize(16)
            .fontColor('#1F2421')
            .placeholderColor('#999999')
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 })
            .width('100%')
            .onChange((value: string) => {
              this.age = parseFloat(value) || 0;
              this.calculate();
            });
        }
        .layoutWeight(1);
        Column() {
          Text('体重 (kg)')
            .fontSize(14)
            .fontColor('#1F2421')
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 6 });
          TextInput({ placeholder: '请输入体重' })
            .type(InputType.Number)
            .height(40)
            .fontSize(16)
            .fontColor('#1F2421')
            .placeholderColor('#999999')
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 })
            .width('100%')
            .onChange((value: string) => {
              this.weight = parseFloat(value) || 0;
              this.calculate();
            });
        }
        .layoutWeight(1)
        .margin({ left: 12 });
      }
      .width('100%')
      .margin({ bottom: 16 });

      Column() {
        Text('血肌酐 (µmol/L)')
          .fontSize(14)
          .fontColor('#1F2421')
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 6 });
        TextInput({ placeholder: '请输入血肌酐值' })
          .type(InputType.Number)
          .height(40)
          .fontSize(16)
          .fontColor('#1F2421')
          .placeholderColor('#999999')
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .border({ width: 1, color: '#E0E0E0' })
          .padding({ left: 12, right: 12 })
          .width('100%')
          .onChange((value: string) => {
            this.creatinine = parseFloat(value) || 0;
            this.calculate();
          });
      }
      .width('100%')
      .margin({ bottom: 16 });
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .width('100%')
    .margin({ bottom: 16 });
  }

  @Builder
  ResultCard() {
    Column() {
      Row() {
        Column() {
          Text('CrCl')
            .fontSize(12)
            .fontColor('#7A8074')
            .letterSpacing(1.5)
            .fontWeight(FontWeight.Medium);
          Text(this.result!.value !== null ? 
            `${this.result!.value!.toFixed(1).replace(/\.0$/, '')} ${this.result!.unit}` : '—')
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F3D2F')
            .margin({ top: 8 });
          Text(this.result!.tier)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getTierTextColor(this.result!.tierClass))
            .backgroundColor(this.getTierBgColor(this.result!.tierClass))
            .borderRadius(20)
            .padding({ left: 12, right: 12, top: 4, bottom: 4 })
            .margin({ top: 8 });
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1);

        Column() {
          Text(this.result!.footnote)
            .fontSize(14)
            .fontColor('#4A5247')
            .lineHeight(22);
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start);
      }
      .width('100%');
    }
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .width('100%');
  }

  private getTierTextColor(tierClass: string): ResourceColor {
    switch (tierClass) {
      case 'tier-ok':
        return '#3D6B4F';
      case 'tier-warn':
        return '#C8881A';
      case 'tier-danger':
        return '#B1452A';
      default:
        return '#2D5440';
    }
  }

  private getTierBgColor(tierClass: string): ResourceColor {
    switch (tierClass) {
      case 'tier-ok':
        return '#3D6B4F';
      case 'tier-warn':
        return '#C8881A';
      case 'tier-danger':
        return '#B1452A';
      default:
        return '#F0F4F2';
    }
  }
}
