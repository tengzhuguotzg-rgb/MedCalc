import { CalcResult } from '../../engine/CalcEngine';
import { calculateApache2 } from '../../engine/Apache2Calculator';
import { AppColors } from '../../utils/AppColors';

@Component
export struct Apache2Calculator {
  @State resetKey: number = 0;  @State temp: number = 0;
  @State sbp: number = 0;
  @State dbp: number = 0;
  @State hr: number = 0;
  @State rr: number = 0;
  @State fio2: number = 0;
  @State fio2Mode: string = 'pct';
  @State pao2: number = 0;
  @State paco2: number = 0;
  @State paco2Filled: boolean = true;
  @State ph: number = 0;
  @State phFilled: boolean = true;
  @State hco3: number = 0;
  @State hco3Filled: boolean = false;
  @State na: number = 0;
  @State k: number = 0;
  @State cr: number = 0;
  @State crUnit: string = 'umol';
  @State arf: number = -1;
  @State hct: number = 0;
  @State wbc: number = 0;
  @State gcs: number = 0;
  @State age: number = 0;
  @State chronic: string = '';
  @State result: CalcResult | null = null;

  aboutToAppear() {
    this.calculate();
  }

  calculate() {
    if (this.arf < 0) {
      this.result = { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
      return;
    }
    this.result = calculateApache2(
      this.temp, this.sbp, this.dbp, this.hr, this.rr,
      this.fio2, this.fio2Mode, this.pao2,
      this.paco2Filled && this.paco2 > 0 ? this.paco2 : null,
      this.phFilled && this.ph > 0 ? this.ph : null,
      this.hco3Filled && this.hco3 > 0 ? this.hco3 : null,
      this.na, this.k, this.cr, this.crUnit, this.arf === 1,
      this.hct, this.wbc, this.gcs, this.age, this.chronic
    );
  }

  reset() {
    this.temp = 0;
    this.sbp = 0;
    this.dbp = 0;
    this.hr = 0;
    this.rr = 0;
    this.fio2 = 0;
    this.fio2Mode = 'pct';
    this.pao2 = 0;
    this.paco2 = 0;
    this.paco2Filled = true;
    this.ph = 0;
    this.phFilled = true;
    this.hco3 = 0;
    this.hco3Filled = false;
    this.na = 0;
    this.k = 0;
    this.cr = 0;
    this.crUnit = 'umol';
    this.arf = -1;
    this.hct = 0;
    this.wbc = 0;
    this.gcs = 0;
    this.age = 0;
    this.chronic = '';
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
          .fontColor(AppColors.primary)
          .fontWeight(FontWeight.Medium);
        Text('14生理参数+年龄+慢性健康，总分0-71')
          .fontSize(12)
          .fontColor(AppColors.textSecondary)
          .margin({ top: 2 });
      }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .margin({ bottom: 12 });
  }

  @Builder
  InputForm() {
    Column() {
      Row() { Text('— 生命体征')
        .fontSize(12)
        .fontColor(AppColors.warning)
        .fontWeight(FontWeight.Bold)
        .letterSpacing(1.5)
        ; Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });

      Row() {
        Column() {
          Text('体温 (°C)')
            .fontSize(14)
            .fontColor('#1F2421')
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 6 });
          TextInput({ placeholder: '37.0' }).type(InputType.NUMBER_DECIMAL)
            .height(48)
            .fontSize(16)
            .fontColor('#1F2421')
            .placeholderColor('#999999')
            .backgroundColor(AppColors.card)
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 })
            .width('100%')
            .onChange((value: string) => {
              this.temp = parseFloat(value) || 0;
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
            .height(48)
            .fontSize(16)
            .fontColor('#1F2421')
            .placeholderColor('#999999')
            .backgroundColor(AppColors.card)
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 })
            .width('100%')
            .onChange((value: string) => {
              this.hr = parseFloat(value) || 0;
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
            .height(48)
            .fontSize(16)
            .fontColor('#1F2421')
            .placeholderColor('#999999')
            .backgroundColor(AppColors.card)
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 })
            .width('100%')
            .onChange((value: string) => {
              this.sbp = parseFloat(value) || 0;
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
            .height(48)
            .fontSize(16)
            .fontColor('#1F2421')
            .placeholderColor('#999999')
            .backgroundColor(AppColors.card)
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 })
            .width('100%')
            .onChange((value: string) => {
              this.dbp = parseFloat(value) || 0;
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
          .height(48)
          .fontSize(16)
          .fontColor('#1F2421')
          .placeholderColor('#999999')
          .backgroundColor(AppColors.card)
          .borderRadius(8)
          .border({ width: 1, color: '#E0E0E0' })
          .padding({ left: 12, right: 12 })
          .width('100%')
          .onChange((value: string) => {
            this.rr = parseFloat(value) || 0;
            this.calculate();
          });
      }
      .width('100%')
      .margin({ bottom: 16 });

      Text('— 氧合参数')
        .fontSize(12)
        .fontColor(AppColors.warning)
        .fontWeight(FontWeight.Bold)
        .letterSpacing(1.5)
        .margin({ bottom: 12 });

      Column() {
        Text('FiO₂')
          .fontSize(14)
          .fontColor('#1F2421')
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 6 });
        TextInput({ placeholder: '21' }).type(InputType.NUMBER_DECIMAL)
          .height(48)
          .fontSize(16)
          .fontColor('#1F2421')
          .placeholderColor('#999999')
          .backgroundColor(AppColors.card)
          .borderRadius(8)
          .border({ width: 1, color: '#E0E0E0' })
          .padding({ left: 12, right: 12 })
          .width('100%')
          .onChange((value: string) => {
            this.fio2 = parseFloat(value) || 0;
            this.calculate();
          });
        Row() {
          Button('%')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.fio2Mode === 'pct' ? AppColors.card : '#2D5440')
            .backgroundColor(this.fio2Mode === 'pct' ? AppColors.primary : AppColors.fillNeutral)
            .border({ width: 1, color: this.fio2Mode === 'pct' ? AppColors.primary : '#E0E0E0' })
            .borderRadius(6)
            .height(28)
            .layoutWeight(1)
            .onClick(() => {
              this.fio2Mode = 'pct';
              this.calculate();
            });
          Button('小数')
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.fio2Mode === 'dec' ? AppColors.card : '#2D5440')
            .backgroundColor(this.fio2Mode === 'dec' ? AppColors.primary : AppColors.fillNeutral)
            .border({ width: 1, color: this.fio2Mode === 'dec' ? AppColors.primary : '#E0E0E0' })
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
            .height(48)
            .fontSize(16)
            .fontColor('#1F2421')
            .placeholderColor('#999999')
            .backgroundColor(AppColors.card)
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 })
            .width('100%')
            .onChange((value: string) => {
              this.pao2 = parseFloat(value) || 0;
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
            .height(48)
            .fontSize(16)
            .fontColor('#1F2421')
            .placeholderColor('#999999')
            .backgroundColor(AppColors.card)
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 })
            .width('100%')
            .enabled(this.paco2Filled)
            .onChange((value: string) => {
              this.paco2 = parseFloat(value) || 0;
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
        .fontColor(AppColors.warning)
        .fontWeight(FontWeight.Bold)
        .letterSpacing(1.5)
        .margin({ bottom: 12 });

      Row() {
        Button('pH (首选)').fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.phFilled ? AppColors.card : '#2D5440').backgroundColor(this.phFilled ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.phFilled ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(44).layoutWeight(1).margin({ right: 4 }).onClick(() => { this.phFilled = true; this.hco3Filled = false; this.calculate(); });
        Button('HCO₃⁻ (备选)').fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.hco3Filled ? AppColors.card : '#2D5440').backgroundColor(this.hco3Filled ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.hco3Filled ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(44).layoutWeight(1).margin({ left: 4 }).onClick(() => { this.hco3Filled = true; this.phFilled = false; this.calculate(); });
      }.width('100%').margin({ bottom: 10 });

      Row() {
        Column() {
          Text('pH')
            .fontSize(14)
            .fontColor('#1F2421')
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 6 });
          TextInput({ placeholder: '7.40' }).type(InputType.NUMBER_DECIMAL)
            .height(48)
            .fontSize(16)
            .fontColor('#1F2421')
            .placeholderColor('#999999')
            .backgroundColor(AppColors.card)
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 })
            .width('100%')
            .enabled(this.phFilled)
            .onChange((value: string) => {
              this.ph = parseFloat(value) || 0;
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
          TextInput({ placeholder: '24' }).type(InputType.NUMBER_DECIMAL)
            .height(48)
            .fontSize(16)
            .fontColor('#1F2421')
            .placeholderColor('#999999')
            .backgroundColor(AppColors.card)
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 })
            .width('100%')
            .enabled(this.hco3Filled)
            .onChange((value: string) => {
              this.hco3 = parseFloat(value) || 0;
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
        .fontColor(AppColors.warning)
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
            .height(48)
            .fontSize(16)
            .fontColor('#1F2421')
            .placeholderColor('#999999')
            .backgroundColor(AppColors.card)
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 })
            .width('100%')
            .onChange((value: string) => {
              this.na = parseFloat(value) || 0;
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
          TextInput({ placeholder: '4.0' }).type(InputType.NUMBER_DECIMAL)
            .height(48)
            .fontSize(16)
            .fontColor('#1F2421')
            .placeholderColor('#999999')
            .backgroundColor(AppColors.card)
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 })
            .width('100%')
            .onChange((value: string) => {
              this.k = parseFloat(value) || 0;
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
            .height(48)
            .fontSize(16)
            .fontColor('#1F2421')
            .placeholderColor('#999999')
            .backgroundColor(AppColors.card)
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 })
            .width('100%')
            .onChange((value: string) => {
              this.cr = parseFloat(value) || 0;
              this.calculate();
            });
          Row() {
            Button('µmol/L')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.crUnit === 'umol' ? AppColors.card : '#2D5440')
              .backgroundColor(this.crUnit === 'umol' ? AppColors.primary : AppColors.fillNeutral)
              .border({ width: 1, color: this.crUnit === 'umol' ? AppColors.primary : '#E0E0E0' })
              .borderRadius(6)
              .height(28)
              .layoutWeight(1)
              .onClick(() => {
                this.crUnit = 'umol';
                this.calculate();
              });
            Button('mg/dL')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.crUnit === 'mgdl' ? AppColors.card : '#2D5440')
              .backgroundColor(this.crUnit === 'mgdl' ? AppColors.primary : AppColors.fillNeutral)
              .border({ width: 1, color: this.crUnit === 'mgdl' ? AppColors.primary : '#E0E0E0' })
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
            .fontColor(this.arf === 0 ? AppColors.card : '#2D5440')
            .backgroundColor(this.arf === 0 ? AppColors.primary : AppColors.fillNeutral)
            .border({ width: 1, color: this.arf === 0 ? AppColors.primary : '#E0E0E0' })
            .borderRadius(8)
            .height(48)
            .layoutWeight(1)
            .onClick(() => {
              this.arf = 0;
              this.calculate();
            });
          Button('是')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.arf === 1 ? AppColors.card : '#2D5440')
            .backgroundColor(this.arf === 1 ? AppColors.primary : AppColors.fillNeutral)
            .border({ width: 1, color: this.arf === 1 ? AppColors.primary : '#E0E0E0' })
            .borderRadius(8)
            .height(48)
            .layoutWeight(1)
            .margin({ left: 12 })
            .onClick(() => {
              this.arf = 1;
              this.calculate();
            });
        }
        .width('100%');
      }
      .width('100%')
      .margin({ bottom: 16 });

      Text('— 血液学')
        .fontSize(12)
        .fontColor(AppColors.warning)
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
            .height(48)
            .fontSize(16)
            .fontColor('#1F2421')
            .placeholderColor('#999999')
            .backgroundColor(AppColors.card)
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 })
            .width('100%')
            .onChange((value: string) => {
              this.hct = parseFloat(value) || 0;
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
            .height(48)
            .fontSize(16)
            .fontColor('#1F2421')
            .placeholderColor('#999999')
            .backgroundColor(AppColors.card)
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 })
            .width('100%')
            .onChange((value: string) => {
              this.wbc = parseFloat(value) || 0;
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
        .fontColor(AppColors.warning)
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
            .height(48)
            .fontSize(16)
            .fontColor('#1F2421')
            .placeholderColor('#999999')
            .backgroundColor(AppColors.card)
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 })
            .width('100%')
            .onChange((value: string) => {
              this.gcs = parseFloat(value) || 0;
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
            .height(48)
            .fontSize(16)
            .fontColor('#1F2421')
            .placeholderColor('#999999')
            .backgroundColor(AppColors.card)
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 })
            .width('100%')
            .onChange((value: string) => {
              this.age = parseFloat(value) || 0;
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
        .fontColor(AppColors.warning)
        .fontWeight(FontWeight.Bold)
        .letterSpacing(1.5)
        .margin({ bottom: 12 });

      Row() {
        Button('无')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.chronic === 'none' ? AppColors.card : '#2D5440')
          .backgroundColor(this.chronic === 'none' ? AppColors.primary : AppColors.fillNeutral)
          .border({ width: 1, color: this.chronic === 'none' ? AppColors.primary : '#E0E0E0' })
          .borderRadius(8)
          .height(44)
          .layoutWeight(1)
          .onClick(() => {
            this.chronic = 'none';
            this.calculate();
          });
        Button('择期术后')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.chronic === 'elective' ? AppColors.card : '#2D5440')
          .backgroundColor(this.chronic === 'elective' ? AppColors.primary : AppColors.fillNeutral)
          .border({ width: 1, color: this.chronic === 'elective' ? AppColors.primary : '#E0E0E0' })
          .borderRadius(8)
          .height(44)
          .layoutWeight(1)
          .margin({ left: 4 })
          .onClick(() => {
            this.chronic = 'elective';
            this.calculate();
          });
        Button('非手术/急诊')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.chronic === 'nonop' ? AppColors.card : '#2D5440')
          .backgroundColor(this.chronic === 'nonop' ? AppColors.primary : AppColors.fillNeutral)
          .border({ width: 1, color: this.chronic === 'nonop' ? AppColors.primary : '#E0E0E0' })
          .borderRadius(8)
          .height(44)
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
    .backgroundColor(AppColors.card)
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
            .fontColor(AppColors.textSecondary)
            .letterSpacing(1.5)
            .fontWeight(FontWeight.Medium);
          Text(this.result!.value !== null ? 
            `${this.result!.value!.toFixed(0)} ${this.result!.unit}` : '—')
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.primary)
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
    .backgroundColor(AppColors.card)
    .borderRadius(12)
    .width('100%');
  }

  private getTierTextColor(tierClass: string): ResourceColor {
    switch (tierClass) {
      case 'tier-ok':
        return AppColors.tierOk;
      case 'tier-warn':
        return AppColors.tierWarn;
      case 'tier-danger':
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }

  private getTierBgColor(tierClass: string): ResourceColor {
    switch (tierClass) {
      case 'tier-ok':
        return AppColors.tierOk;
      case 'tier-warn':
        return AppColors.tierWarn;
      case 'tier-danger':
        return AppColors.danger;
      default:
        return AppColors.fillNeutral;
    }
  }
}
