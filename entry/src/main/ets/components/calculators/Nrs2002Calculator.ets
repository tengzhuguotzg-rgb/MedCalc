import { CalcResult } from '../../engine/CalcEngine';
import { calculateNrs2002 } from '../../engine/Nrs2002Calculator';

@Component
export struct Nrs2002Calculator {  @State patientHeight: number = 0;
  @State patientWeight: number = 0;
  @State weightLoss: string = 'none';
  @State intake: string = 'none';
  @State disease: string = 'none';
  @State ageAdj: boolean = false;
  @State result: CalcResult | null = null;

  aboutToAppear() {
    this.calculate();
  }

  calculate() {
    this.result = calculateNrs2002(this.patientHeight, this.patientWeight, this.weightLoss, this.intake, this.disease, this.ageAdj);
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
      Text('用于住院患者营养风险筛查')
          .fontSize(14)
          .fontColor('#1F3D2F')
          .fontWeight(FontWeight.Medium);
        Text('4项：BMI+体重下降+摄食减少+疾病严重度，≥3有营养风险')
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
        Column() {
          Text('身高 (cm)')
            .fontSize(14)
            .fontColor('#1F2421')
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 6 });
          TextInput({ placeholder: '请输入身高' })
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
              this.patientHeight = parseFloat(value) || 0;
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
              this.patientWeight = parseFloat(value) || 0;
              this.calculate();
            });
        }
        .layoutWeight(1)
        .margin({ left: 12 });
      }
      .width('100%')
      .margin({ bottom: 16 });

      Column() {
        Text('体重下降程度')
          .fontSize(14)
          .fontColor('#1F2421')
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 6 });
        Row() {
          Button('无')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.weightLoss === 'none' ? '#FFFFFF' : '#2D5440')
            .backgroundColor(this.weightLoss === 'none' ? '#1F3D2F' : '#F5F5F5')
            .border({ width: 1, color: this.weightLoss === 'none' ? '#1F3D2F' : '#E0E0E0' })
            .borderRadius(8)
            .height(36)
            .layoutWeight(1)
            .onClick(() => {
              this.weightLoss = 'none';
              this.calculate();
            });
          Button('>5%')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.weightLoss === 'mild' ? '#FFFFFF' : '#2D5440')
            .backgroundColor(this.weightLoss === 'mild' ? '#1F3D2F' : '#F5F5F5')
            .border({ width: 1, color: this.weightLoss === 'mild' ? '#1F3D2F' : '#E0E0E0' })
            .borderRadius(8)
            .height(36)
            .layoutWeight(1)
            .margin({ left: 4 })
            .onClick(() => {
              this.weightLoss = 'mild';
              this.calculate();
            });
          Button('>10%')
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.weightLoss === 'mod' ? '#FFFFFF' : '#2D5440')
            .backgroundColor(this.weightLoss === 'mod' ? '#1F3D2F' : '#F5F5F5')
            .border({ width: 1, color: this.weightLoss === 'mod' ? '#1F3D2F' : '#E0E0E0' })
            .borderRadius(8)
            .height(36)
            .layoutWeight(1)
            .margin({ left: 4 })
            .onClick(() => {
              this.weightLoss = 'mod';
              this.calculate();
            });
          Button('>15%')
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.weightLoss === 'severe' ? '#FFFFFF' : '#2D5440')
            .backgroundColor(this.weightLoss === 'severe' ? '#1F3D2F' : '#F5F5F5')
            .border({ width: 1, color: this.weightLoss === 'severe' ? '#1F3D2F' : '#E0E0E0' })
            .borderRadius(8)
            .height(36)
            .layoutWeight(1)
            .margin({ left: 4 })
            .onClick(() => {
              this.weightLoss = 'severe';
              this.calculate();
            });
        }
        .width('100%');
      }
      .width('100%')
      .margin({ bottom: 16 });

      Column() {
        Text('进食量 (占正常饮食比例)')
          .fontSize(14)
          .fontColor('#1F2421')
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 6 });
        Row() {
          Button('正常')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.intake === 'none' ? '#FFFFFF' : '#2D5440')
            .backgroundColor(this.intake === 'none' ? '#1F3D2F' : '#F5F5F5')
            .border({ width: 1, color: this.intake === 'none' ? '#1F3D2F' : '#E0E0E0' })
            .borderRadius(8)
            .height(36)
            .layoutWeight(1)
            .onClick(() => {
              this.intake = 'none';
              this.calculate();
            });
          Button('>50%')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.intake === 'mild' ? '#FFFFFF' : '#2D5440')
            .backgroundColor(this.intake === 'mild' ? '#1F3D2F' : '#F5F5F5')
            .border({ width: 1, color: this.intake === 'mild' ? '#1F3D2F' : '#E0E0E0' })
            .borderRadius(8)
            .height(36)
            .layoutWeight(1)
            .margin({ left: 4 })
            .onClick(() => {
              this.intake = 'mild';
              this.calculate();
            });
          Button('25-50%')
            .fontSize(9)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.intake === 'mod' ? '#FFFFFF' : '#2D5440')
            .backgroundColor(this.intake === 'mod' ? '#1F3D2F' : '#F5F5F5')
            .border({ width: 1, color: this.intake === 'mod' ? '#1F3D2F' : '#E0E0E0' })
            .borderRadius(8)
            .height(36)
            .layoutWeight(1)
            .margin({ left: 4 })
            .onClick(() => {
              this.intake = 'mod';
              this.calculate();
            });
          Button('<25%')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.intake === 'severe' ? '#FFFFFF' : '#2D5440')
            .backgroundColor(this.intake === 'severe' ? '#1F3D2F' : '#F5F5F5')
            .border({ width: 1, color: this.intake === 'severe' ? '#1F3D2F' : '#E0E0E0' })
            .borderRadius(8)
            .height(36)
            .layoutWeight(1)
            .margin({ left: 4 })
            .onClick(() => {
              this.intake = 'severe';
              this.calculate();
            });
        }
        .width('100%');
      }
      .width('100%')
      .margin({ bottom: 16 });

      Column() {
        Text('疾病严重度')
          .fontSize(14)
          .fontColor('#1F2421')
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 6 });
        Row() {
          Button('无/轻')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.disease === 'none' ? '#FFFFFF' : '#2D5440')
            .backgroundColor(this.disease === 'none' ? '#1F3D2F' : '#F5F5F5')
            .border({ width: 1, color: this.disease === 'none' ? '#1F3D2F' : '#E0E0E0' })
            .borderRadius(8)
            .height(36)
            .layoutWeight(1)
            .onClick(() => {
              this.disease = 'none';
              this.calculate();
            });
          Button('中度')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.disease === 'moderate' ? '#FFFFFF' : '#2D5440')
            .backgroundColor(this.disease === 'moderate' ? '#1F3D2F' : '#F5F5F5')
            .border({ width: 1, color: this.disease === 'moderate' ? '#1F3D2F' : '#E0E0E0' })
            .borderRadius(8)
            .height(36)
            .layoutWeight(1)
            .margin({ left: 6 })
            .onClick(() => {
              this.disease = 'moderate';
              this.calculate();
            });
          Button('重度')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.disease === 'severe' ? '#FFFFFF' : '#2D5440')
            .backgroundColor(this.disease === 'severe' ? '#1F3D2F' : '#F5F5F5')
            .border({ width: 1, color: this.disease === 'severe' ? '#1F3D2F' : '#E0E0E0' })
            .borderRadius(8)
            .height(36)
            .layoutWeight(1)
            .margin({ left: 6 })
            .onClick(() => {
              this.disease = 'severe';
              this.calculate();
            });
        }
        .width('100%');
      }
      .width('100%')
      .margin({ bottom: 16 });

      Column() {
        Text('年龄 ≥ 70 岁')
          .fontSize(14)
          .fontColor('#1F2421')
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 6 });
        Row() {
          Button('否')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(!this.ageAdj ? '#FFFFFF' : '#2D5440')
            .backgroundColor(!this.ageAdj ? '#1F3D2F' : '#F5F5F5')
            .border({ width: 1, color: !this.ageAdj ? '#1F3D2F' : '#E0E0E0' })
            .borderRadius(8)
            .height(40)
            .layoutWeight(1)
            .onClick(() => {
              this.ageAdj = false;
              this.calculate();
            });
          Button('是')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.ageAdj ? '#FFFFFF' : '#2D5440')
            .backgroundColor(this.ageAdj ? '#1F3D2F' : '#F5F5F5')
            .border({ width: 1, color: this.ageAdj ? '#1F3D2F' : '#E0E0E0' })
            .borderRadius(8)
            .height(40)
            .layoutWeight(1)
            .margin({ left: 12 })
            .onClick(() => {
              this.ageAdj = true;
              this.calculate();
            });
        }
        .width('100%');
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
          Text('NRS-2002')
            .fontSize(12)
            .fontColor('#7A8074')
            .letterSpacing(1.5)
            .fontWeight(FontWeight.Medium);
          Text(this.result!.value !== null ? 
            `${this.result!.value!.toFixed(0)} ${this.result!.unit}` : '—')
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
