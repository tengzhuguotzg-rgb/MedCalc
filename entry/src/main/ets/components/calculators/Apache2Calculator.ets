import { CalcResult } from '../../engine/CalcEngine';
import { calculateApache2 } from '../../engine/Apache2Calculator';

@Component
export struct Apache2Calculator {  @State temp: number = 37;
  @State sbp: number = 120;
  @State dbp: number = 80;
  @State hr: number = 80;
  @State rr: number = 16;
  @State fio2: number = 21;
  @State fio2Mode: string = 'pct';
  @State pao2: number = 80;
  @State paco2: number = 40;
  @State paco2Filled: boolean = true;
  @State ph: number = 7.40;
  @State phFilled: boolean = true;
  @State hco3: number = 24;
  @State hco3Filled: boolean = false;
  @State na: number = 140;
  @State k: number = 4.0;
  @State cr: number = 80;
  @State crUnit: string = 'umol';
  @State arf: boolean = false;
  @State hct: number = 40;
  @State wbc: number = 8;
  @State gcs: number = 15;
  @State age: number = 0;
  @State chronic: string = 'none';
  @State result: CalcResult | null = null;

  aboutToAppear() {
    this.calculate();
  }

  calculate() {
    this.result = calculateApache2(
      this.temp, this.sbp, this.dbp, this.hr, this.rr,
      this.fio2, this.fio2Mode, this.pao2,
      this.paco2Filled ? this.paco2 : null,
      this.phFilled ? this.ph : null,
      this.hco3Filled ? this.hco3 : null,
      this.na, this.k, this.cr, this.crUnit, this.arf,
      this.hct, this.wbc, this.gcs, this.age, this.chronic
    );
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
      Text('用于ICU患者病情严重度及死亡风险预测')
          .fontSize(14)
          .fontColor('#1F3D2F')
          .fontWeight(FontWeight.Medium);
        Text('14生理参数+年龄+慢性健康，总分0-71')
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
      Text('— 生命体征')
        .fontSize(12)
        .fontColor('#E76F2C')
        .fontWeight(FontWeight.Bold)
        .letterSpacing(1.5)
        .margin({ bottom: 12 });

      Row() {
        Column() {
          Text('体温 (°C)')
            .fontSize(14)
            .fontColor('#1F2421')
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 6 });
          TextInput({ placeholder: '37.0' })
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
              this.temp = parseFloat(value) || 37;
              this.calculate();
            });
        }
        .layoutWeight(1);
        Column() {
          Text('心率 (次/分)')
            .fontSize(14)
            .fontColor('#1F2421')
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 6 });
          TextInput({ placeholder: '80' })
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
              this.hr = parseFloat(value) || 80;
              this.calculate();
            });
        }
        .layoutWeight(1)
        .margin({ left: 12 });
      }
      .width('100%')
      .margin({ bottom: 16 });

      Row() {
        Column() {
          Text('收缩压 (mmHg)')
            .fontSize(14)
            .fontColor('#1F2421')
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 6 });
          TextInput({ placeholder: '120' })
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
              this.sbp = parseFloat(value) || 120;
              this.calculate();
            });
        }
        .layoutWeight(1);
        Column() {
          Text('舒张压 (mmHg)')
            .fontSize(14)
            .fontColor('#1F2421')
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 6 });
          TextInput({ placeholder: '80' })
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
              this.dbp = parseFloat(value) || 80;
              this.calculate();
            });
        }
        .layoutWeight(1)
        .margin({ left: 12 });
      }
      .width('100%')
      .margin({ bottom: 16 });

      Column() {
        Text('呼吸频率 (次/分)')
          .fontSize(14)
          .fontColor('#1F2421')
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 6 });
        TextInput({ placeholder: '16' })
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
            this.rr = parseFloat(value) || 16;
            this.calculate();
          });
      }
      .width('100%')
      .margin({ bottom: 16 });

      Text('— 氧合参数')
        .fontSize(12)
        .fontColor('#E76F2C')
        .fontWeight(FontWeight.Bold)
        .letterSpacing(1.5)
        .margin({ bottom: 12 });

      Column() {
        Text('FiO₂')
          .fontSize(14)
          .fontColor('#1F2421')
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 6 });
        TextInput({ placeholder: '21' })
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
            this.fio2 = parseFloat(value) || 21;
            this.calculate();
          });
        Row() {
          Button('%')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.fio2Mode === 'pct' ? '#FFFFFF' : '#2D5440')
            .backgroundColor(this.fio2Mode === 'pct' ? '#1F3D2F' : '#F5F5F5')
            .border({ width: 1, color: this.fio2Mode === 'pct' ? '#1F3D2F' : '#E0E0E0' })
            .borderRadius(6)
            .height(28)
            .layoutWeight(1)
            .onClick(() => {
              this.fio2Mode = 'pct';
              this.calculate();
            });
          Button('小数')
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.fio2Mode === 'dec' ? '#FFFFFF' : '#2D5440')
            .backgroundColor(this.fio2Mode === 'dec' ? '#1F3D2F' : '#F5F5F5')
            .border({ width: 1, color: this.fio2Mode === 'dec' ? '#1F3D2F' : '#E0E0E0' })
            .borderRadius(6)
            .height(28)
            .layoutWeight(1)
            .margin({ left: 4 })
            .onClick(() => {
              this.fio2Mode = 'dec';
              this.calculate();
            });
        }
        .width('100%')
        .margin({ top: 6 });
      }
      .width('100%')
      .margin({ bottom: 16 });

      Row() {
        Column() {
          Text('PaO₂ (mmHg)')
            .fontSize(14)
            .fontColor('#1F2421')
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 6 });
          TextInput({ placeholder: '80' })
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
              this.pao2 = parseFloat(value) || 80;
              this.calculate();
            });
        }
        .layoutWeight(1);
        Column() {
          Text('PaCO₂ (mmHg)')
            .fontSize(14)
            .fontColor('#1F2421')
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 6 });
          TextInput({ placeholder: '40' })
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
            .enabled(this.paco2Filled)
            .onChange((value: string) => {
              this.paco2 = parseFloat(value) || 40;
              this.calculate();
            });
        }
        .layoutWeight(1)
        .margin({ left: 12 });
      }
      .width('100%')
      .margin({ bottom: 16 });

      Text('— 酸碱状态')
        .fontSize(12)
        .fontColor('#E76F2C')
        .fontWeight(FontWeight.Bold)
        .letterSpacing(1.5)
        .margin({ bottom: 12 });

      Row() {
        Button('pH (首选)').fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.phFilled ? '#FFFFFF' : '#2D5440').backgroundColor(this.phFilled ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.phFilled ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).margin({ right: 4 }).onClick(() => { this.phFilled = true; this.hco3Filled = false; this.calculate(); });
        Button('HCO₃⁻ (备选)').fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.hco3Filled ? '#FFFFFF' : '#2D5440').backgroundColor(this.hco3Filled ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.hco3Filled ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).margin({ left: 4 }).onClick(() => { this.hco3Filled = true; this.phFilled = false; this.calculate(); });
      }.width('100%').margin({ bottom: 10 });

      Row() {
        Column() {
          Text('pH')
            .fontSize(14)
            .fontColor('#1F2421')
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 6 });
          TextInput({ placeholder: '7.40' })
            .height(40)
            .fontSize(16)
            .fontColor('#1F2421')
            .placeholderColor('#999999')
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 })
            .width('100%')
            .enabled(this.phFilled)
            .onChange((value: string) => {
              this.ph = parseFloat(value) || 7.4;
              this.calculate();
            });
        }
        .layoutWeight(1);
        Column() {
          Text('HCO₃⁻ (mmol/L)')
            .fontSize(14)
            .fontColor('#1F2421')
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 6 });
          TextInput({ placeholder: '24' })
            .height(40)
            .fontSize(16)
            .fontColor('#1F2421')
            .placeholderColor('#999999')
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 })
            .width('100%')
            .enabled(this.hco3Filled)
            .onChange((value: string) => {
              this.hco3 = parseFloat(value) || 24;
              this.calculate();
            });
        }
        .layoutWeight(1)
        .margin({ left: 12 });
      }
      .width('100%')
      .margin({ bottom: 16 });

      Text('— 电解质与肾功能')
        .fontSize(12)
        .fontColor('#E76F2C')
        .fontWeight(FontWeight.Bold)
        .letterSpacing(1.5)
        .margin({ bottom: 12 });

      Row() {
        Column() {
          Text('Na⁺ (mmol/L)')
            .fontSize(14)
            .fontColor('#1F2421')
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 6 });
          TextInput({ placeholder: '140' })
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
              this.na = parseFloat(value) || 140;
              this.calculate();
            });
        }
        .layoutWeight(1);
        Column() {
          Text('K⁺ (mmol/L)')
            .fontSize(14)
            .fontColor('#1F2421')
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 6 });
          TextInput({ placeholder: '4.0' })
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
              this.k = parseFloat(value) || 4.0;
              this.calculate();
            });
        }
        .layoutWeight(1)
        .margin({ left: 12 });
      }
      .width('100%')
      .margin({ bottom: 16 });

      Row() {
        Column() {
          Text('肌酐')
            .fontSize(14)
            .fontColor('#1F2421')
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 6 });
          TextInput({ placeholder: '80' })
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
              this.cr = parseFloat(value) || 80;
              this.calculate();
            });
          Row() {
            Button('µmol/L')
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.crUnit === 'umol' ? '#FFFFFF' : '#2D5440')
              .backgroundColor(this.crUnit === 'umol' ? '#1F3D2F' : '#F5F5F5')
              .border({ width: 1, color: this.crUnit === 'umol' ? '#1F3D2F' : '#E0E0E0' })
              .borderRadius(6)
              .height(28)
              .layoutWeight(1)
              .onClick(() => {
                this.crUnit = 'umol';
                this.calculate();
              });
            Button('mg/dL')
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.crUnit === 'mgdl' ? '#FFFFFF' : '#2D5440')
              .backgroundColor(this.crUnit === 'mgdl' ? '#1F3D2F' : '#F5F5F5')
              .border({ width: 1, color: this.crUnit === 'mgdl' ? '#1F3D2F' : '#E0E0E0' })
              .borderRadius(6)
              .height(28)
              .layoutWeight(1)
              .margin({ left: 4 })
              .onClick(() => {
                this.crUnit = 'mgdl';
                this.calculate();
              });
          }
          .width('100%')
          .margin({ top: 6 });
        }
        .layoutWeight(1);
      }
      .width('100%')
      .margin({ bottom: 16 });

      Column() {
        Text('急性肾衰竭')
          .fontSize(14)
          .fontColor('#1F2421')
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 6 });
        Row() {
          Button('否')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(!this.arf ? '#FFFFFF' : '#2D5440')
            .backgroundColor(!this.arf ? '#1F3D2F' : '#F5F5F5')
            .border({ width: 1, color: !this.arf ? '#1F3D2F' : '#E0E0E0' })
            .borderRadius(8)
            .height(40)
            .layoutWeight(1)
            .onClick(() => {
              this.arf = false;
              this.calculate();
            });
          Button('是')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.arf ? '#FFFFFF' : '#2D5440')
            .backgroundColor(this.arf ? '#1F3D2F' : '#F5F5F5')
            .border({ width: 1, color: this.arf ? '#1F3D2F' : '#E0E0E0' })
            .borderRadius(8)
            .height(40)
            .layoutWeight(1)
            .margin({ left: 12 })
            .onClick(() => {
              this.arf = true;
              this.calculate();
            });
        }
        .width('100%');
      }
      .width('100%')
      .margin({ bottom: 16 });

      Text('— 血液学')
        .fontSize(12)
        .fontColor('#E76F2C')
        .fontWeight(FontWeight.Bold)
        .letterSpacing(1.5)
        .margin({ bottom: 12 });

      Row() {
        Column() {
          Text('HCT (%)')
            .fontSize(14)
            .fontColor('#1F2421')
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 6 });
          TextInput({ placeholder: '40' })
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
              this.hct = parseFloat(value) || 40;
              this.calculate();
            });
        }
        .layoutWeight(1);
        Column() {
          Text('WBC (×10⁹/L)')
            .fontSize(14)
            .fontColor('#1F2421')
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 6 });
          TextInput({ placeholder: '8' })
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
              this.wbc = parseFloat(value) || 8;
              this.calculate();
            });
        }
        .layoutWeight(1)
        .margin({ left: 12 });
      }
      .width('100%')
      .margin({ bottom: 16 });

      Text('— 神经与年龄')
        .fontSize(12)
        .fontColor('#E76F2C')
        .fontWeight(FontWeight.Bold)
        .letterSpacing(1.5)
        .margin({ bottom: 12 });

      Row() {
        Column() {
          Text('GCS (3-15)')
            .fontSize(14)
            .fontColor('#1F2421')
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 6 });
          TextInput({ placeholder: '15' })
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
              this.gcs = parseFloat(value) || 15;
              this.calculate();
            });
        }
        .layoutWeight(1);
        Column() {
          Text('年龄 (岁)')
            .fontSize(14)
            .fontColor('#1F2421')
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 6 });
          TextInput({ placeholder: '50' })
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
              this.age = parseFloat(value) || 50;
              this.calculate();
            });
        }
        .layoutWeight(1)
        .margin({ left: 12 });
      }
      .width('100%')
      .margin({ bottom: 16 });

      Text('— 慢性健康状态')
        .fontSize(12)
        .fontColor('#E76F2C')
        .fontWeight(FontWeight.Bold)
        .letterSpacing(1.5)
        .margin({ bottom: 12 });

      Row() {
        Button('无')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.chronic === 'none' ? '#FFFFFF' : '#2D5440')
          .backgroundColor(this.chronic === 'none' ? '#1F3D2F' : '#F5F5F5')
          .border({ width: 1, color: this.chronic === 'none' ? '#1F3D2F' : '#E0E0E0' })
          .borderRadius(8)
          .height(36)
          .layoutWeight(1)
          .onClick(() => {
            this.chronic = 'none';
            this.calculate();
          });
        Button('择期术后')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.chronic === 'elective' ? '#FFFFFF' : '#2D5440')
          .backgroundColor(this.chronic === 'elective' ? '#1F3D2F' : '#F5F5F5')
          .border({ width: 1, color: this.chronic === 'elective' ? '#1F3D2F' : '#E0E0E0' })
          .borderRadius(8)
          .height(36)
          .layoutWeight(1)
          .margin({ left: 4 })
          .onClick(() => {
            this.chronic = 'elective';
            this.calculate();
          });
        Button('非手术/急诊')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.chronic === 'nonop' ? '#FFFFFF' : '#2D5440')
          .backgroundColor(this.chronic === 'nonop' ? '#1F3D2F' : '#F5F5F5')
          .border({ width: 1, color: this.chronic === 'nonop' ? '#1F3D2F' : '#E0E0E0' })
          .borderRadius(8)
          .height(36)
          .layoutWeight(1)
          .margin({ left: 4 })
          .onClick(() => {
            this.chronic = 'nonop';
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
          Text('APACHE II')
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
