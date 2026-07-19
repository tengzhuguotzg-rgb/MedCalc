import { BgResult, BgInput, calculateBg } from '../../engine/BloodGasCalculator';

interface CritLine {
  level: string;
  text: string;
}

@Component
export struct BloodGasCalculator {
  @State resetKey: number = 0;  @State ph: string = '';
  @State paco2: string = '';
  @State paco2Unit: string = 'mmhg';
  @State pao2: string = '';
  @State pao2Unit: string = 'mmhg';
  @State hco3: string = '';
  @State be: string = '';
  @State sao2: string = '';
  @State lac: string = '';
  @State hgb: string = '';
  @State hgbUnit: string = 'gl';
  @State k: string = '';
  @State na: string = '';
  @State cl: string = '';
  @State glu: string = '';
  @State fio2: string = '';
  @State fio2Mode: string = 'dec';
  @State acute: string = 'chronic';
  @State pvco2: string = '';
  @State pvco2Unit: string = 'mmhg';
  @State svo2: string = '';
  @State pvo2: string = '';
  @State pvo2Unit: string = 'mmhg';
  @State showVenous: boolean = false;
  @State result: BgResult | null = null;

  @State hypoxiaType: string = '';
  @State hypoxiaDetail: string = '';
  @State hypoxiaCalc: string = '';
  @State hypoxiaCls: string = '';
  @State hypoxiaTierText: string = '';
  @State hypoxiaHtml: string = '';

  @State rConclusion: string = '';
  @State rDetail: string = '';
  @State rCls: string = '';
  @State rTierText: string = '';
  @State rHtml: string = '';

  @State critLines: CritLine[] = [];
  @State critHtml: string = '';

  aboutToAppear() {
    this.calculate();
  }

  toNull(v: string): number | null {
    let n = parseFloat(v);
    if (isNaN(n)) {
      return null;
    }
    return n;
  }

  calculate() {
    let input: BgInput = {
      ph: this.toNull(this.ph),
      paco2: this.toNull(this.paco2),
      paco2Unit: this.paco2Unit,
      pao2: this.toNull(this.pao2),
      pao2Unit: this.pao2Unit,
      hco3: this.toNull(this.hco3),
      be: this.toNull(this.be),
      sao2: this.toNull(this.sao2),
      lac: this.toNull(this.lac),
      hgb: this.toNull(this.hgb),
      hgbUnit: this.hgbUnit,
      k: this.toNull(this.k),
      na: this.toNull(this.na),
      cl: this.toNull(this.cl),
      glu: this.toNull(this.glu),
      fio2: this.toNull(this.fio2),
      fio2Mode: this.fio2Mode,
      acute: this.acute,
      pvco2: this.toNull(this.pvco2),
      pvco2Unit: this.pvco2Unit,
      svo2: this.toNull(this.svo2),
      pvo2: this.toNull(this.pvo2),
      pvo2Unit: this.pvo2Unit
    };
    this.result = calculateBg(input);
    this.parseResult();
  }

  parseResult() {
    if (!this.result) {
      this.hypoxiaType = '';
      this.hypoxiaDetail = '';
      this.hypoxiaCalc = '';
      this.hypoxiaCls = '';
      this.hypoxiaTierText = '';
      this.hypoxiaHtml = '';
      this.rConclusion = '';
      this.rDetail = '';
      this.rCls = '';
      this.rTierText = '';
      this.rHtml = '';
      this.critLines = [];
      this.critHtml = '';
      return;
    }

    let hHtml = this.result.hypoxia.html;
    this.hypoxiaHtml = hHtml;
    if (hHtml.indexOf('|') >= 0) {
      let parts = hHtml.split('|');
      if (parts.length >= 5) {
        this.hypoxiaType = parts[0];
        this.hypoxiaDetail = parts[1];
        this.hypoxiaCalc = parts[2];
        this.hypoxiaCls = parts[3];
        this.hypoxiaTierText = parts[4];
      } else {
        this.hypoxiaType = '';
        this.hypoxiaDetail = hHtml;
        this.hypoxiaCalc = '';
        this.hypoxiaCls = '';
        this.hypoxiaTierText = '';
      }
    } else {
      this.hypoxiaType = '';
      this.hypoxiaDetail = hHtml;
      this.hypoxiaCalc = '';
      this.hypoxiaCls = '';
      this.hypoxiaTierText = '';
    }

    let rHtmlRaw = this.result.r.html;
    this.rHtml = rHtmlRaw;
    if (rHtmlRaw.indexOf('|') >= 0) {
      let parts = rHtmlRaw.split('|');
      if (parts.length >= 3) {
        this.rConclusion = parts[0];
        this.rDetail = parts[1];
        this.rCls = parts[2];
        this.rTierText = parts.length >= 4 ? parts[3] : parts[2];
      } else {
        this.rConclusion = '';
        this.rDetail = rHtmlRaw;
        this.rCls = '';
        this.rTierText = '';
      }
    } else {
      this.rConclusion = '';
      this.rDetail = rHtmlRaw;
      this.rCls = '';
      this.rTierText = '';
    }

    let cHtml = this.result.critical.html;
    this.critHtml = cHtml;
    if (cHtml.indexOf('|') >= 0) {
      let lines = cHtml.split('\n');
      let parsed: CritLine[] = [];
      for (let i = 0; i < lines.length; i++) {
        let line = lines[i];
        if (line.length === 0) {
          continue;
        }
        let idx = line.indexOf('|');
        if (idx > 0) {
          parsed.push({ level: line.substring(0, idx), text: line.substring(idx + 1) });
        }
      }
      this.critLines = parsed;
    } else {
      this.critLines = [];
    }
  }

  getTierColor(cls: string): string {
    if (cls === 'tier-danger') {
      return '#DC3545';
    }
    if (cls === 'tier-warn') {
      return '#E76F2C';
    }
    if (cls === 'tier-ok') {
      return '#28A745';
    }
    return '#6C757D';
  }

  getCritItemColor(level: string): string {
    if (level === 'danger') {
      return '#DC3545';
    }
    if (level === 'warn') {
      return '#E76F2C';
    }
    return '#28A745';
  }

  reset() {
    this.ph = '';
    this.paco2 = '';
    this.paco2Unit = 'mmhg';
    this.pao2 = '';
    this.pao2Unit = 'mmhg';
    this.hco3 = '';
    this.be = '';
    this.sao2 = '';
    this.lac = '';
    this.hgb = '';
    this.hgbUnit = 'gl';
    this.k = '';
    this.na = '';
    this.cl = '';
    this.glu = '';
    this.fio2 = '';
    this.fio2Mode = 'dec';
    this.acute = 'chronic';
    this.pvco2 = '';
    this.pvco2Unit = 'mmhg';
    this.svo2 = '';
    this.pvo2 = '';
    this.pvo2Unit = 'mmhg';
    this.showVenous = false;
    this.result = null;
    this.hypoxiaType = '';
    this.hypoxiaDetail = '';
    this.hypoxiaCalc = '';
    this.hypoxiaCls = '';
    this.hypoxiaTierText = '';
    this.hypoxiaHtml = '';
    this.rConclusion = '';
    this.rDetail = '';
    this.rCls = '';
    this.rTierText = '';
    this.rHtml = '';
    this.critLines = [];
    this.critHtml = '';
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
        this.Results();
      }
    }
    .width('100%')
    .constraintSize({ minHeight: '100%' })
    .padding(16).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }

  @Builder
  Header() {
    Column() {
      Text('用于判断酸碱失衡类型及氧合状态，鉴别缺氧机制')
        .fontSize(14)
        .fontColor('#1F3D2F')
        .fontWeight(FontWeight.Medium);
      Text('6步法判断酸碱失衡 + 氧合评估 + 缺氧分型(需静脉) + 呼吸商 + 危急值')
        .fontSize(12)
        .fontColor('#5F6654')
        .margin({ top: 2 });
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .margin({ bottom: 12 });
  }

  @Builder
  InputForm() {
    Column() {
      Row() { Text('— 动脉血气 (必填)')
        .fontSize(12)
        .fontColor('#E76F2C')
        .fontWeight(FontWeight.Bold)
        .letterSpacing(1.5)
        ; Blank(); Text('重置').fontSize(12).fontColor('#5F6654').onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });

      Row() {
        Button('急性')
          .height(32)
          .fontSize(13)
          .fontColor(this.acute === 'acute' ? '#FFFFFF' : '#2D5440')
          .backgroundColor(this.acute === 'acute' ? '#1F3D2F' : '#F5F5F5')
          .borderRadius(6)
          .layoutWeight(1)
          .onClick(() => { this.acute = 'acute'; this.calculate(); });
        Button('慢性')
          .height(32)
          .fontSize(13)
          .fontColor(this.acute === 'chronic' ? '#FFFFFF' : '#2D5440')
          .backgroundColor(this.acute === 'chronic' ? '#1F3D2F' : '#F5F5F5')
          .borderRadius(6)
          .layoutWeight(1)
          .margin({ left: 6 })
          .margin({ left: 8 })
          .onClick(() => { this.acute = 'chronic'; this.calculate(); });
      }
      .width('100%')
      .margin({ bottom: 12 });

      Row() {
        Column() {
          Text('pH')
            .fontSize(14)
            .fontColor('#1F2421')
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 6 });
          TextInput({ placeholder: '7.35-7.45' }).type(InputType.NUMBER_DECIMAL)
            .height(48)
            .fontSize(16)
            .fontColor('#1F2421')
            .placeholderColor('#999999')
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 })
            .width('100%')
            .onChange((value: string) => { this.ph = value; this.calculate(); });
        }
        .layoutWeight(1);
        Column() {
          Text('HCO\u2083\u207B (mmol/L)')
            .fontSize(14)
            .fontColor('#1F2421')
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 6 });
          TextInput({ placeholder: '22-27' }).type(InputType.NUMBER_DECIMAL)
            .height(48)
            .fontSize(16)
            .fontColor('#1F2421')
            .placeholderColor('#999999')
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 })
            .width('100%')
            .onChange((value: string) => { this.hco3 = value; this.calculate(); });
        }
        .layoutWeight(1)
        .margin({ left: 12 });
      }
      .width('100%')
      .margin({ bottom: 12 });

      Column() {
        Text('PaCO\u2082')
          .fontSize(14)
          .fontColor('#1F2421')
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 6 });
        Row() {
          TextInput({ placeholder: '35-45' }).type(InputType.NUMBER_DECIMAL)
            .height(48)
            .fontSize(16)
            .fontColor('#1F2421')
            .placeholderColor('#999999')
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 })
            .layoutWeight(1)
            .onChange((value: string) => { this.paco2 = value; this.calculate(); });
          Row() {
            Button('mmHg')
              .height(28)
              .fontSize(12)
              .fontColor(this.paco2Unit === 'mmhg' ? '#FFFFFF' : '#2D5440')
              .backgroundColor(this.paco2Unit === 'mmhg' ? '#1F3D2F' : '#F5F5F5')
              .borderRadius(4)
              .onClick(() => { this.paco2Unit = 'mmhg'; this.calculate(); });
            Button('kPa')
              .height(28)
              .fontSize(12)
              .fontColor(this.paco2Unit === 'kpa' ? '#FFFFFF' : '#2D5440')
              .backgroundColor(this.paco2Unit === 'kpa' ? '#1F3D2F' : '#F5F5F5')
              .borderRadius(4)
              .margin({ left: 4 })
              .onClick(() => { this.paco2Unit = 'kpa'; this.calculate(); });
          }
          .margin({ left: 8 });
        }
        .width('100%');
      }
      .width('100%')
      .margin({ bottom: 12 });

      Column() {
        Text('PaO\u2082')
          .fontSize(14)
          .fontColor('#1F2421')
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 6 });
        Row() {
          TextInput({ placeholder: '80-100' }).type(InputType.NUMBER_DECIMAL)
            .height(48)
            .fontSize(16)
            .fontColor('#1F2421')
            .placeholderColor('#999999')
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 })
            .layoutWeight(1)
            .onChange((value: string) => { this.pao2 = value; this.calculate(); });
          Row() {
            Button('mmHg')
              .height(28)
              .fontSize(12)
              .fontColor(this.pao2Unit === 'mmhg' ? '#FFFFFF' : '#2D5440')
              .backgroundColor(this.pao2Unit === 'mmhg' ? '#1F3D2F' : '#F5F5F5')
              .borderRadius(4)
              .onClick(() => { this.pao2Unit = 'mmhg'; this.calculate(); });
            Button('kPa')
              .height(28)
              .fontSize(12)
              .fontColor(this.pao2Unit === 'kpa' ? '#FFFFFF' : '#2D5440')
              .backgroundColor(this.pao2Unit === 'kpa' ? '#1F3D2F' : '#F5F5F5')
              .borderRadius(4)
              .margin({ left: 4 })
              .onClick(() => { this.pao2Unit = 'kpa'; this.calculate(); });
          }
          .margin({ left: 8 });
        }
        .width('100%');
      }
      .width('100%')
      .margin({ bottom: 12 });

      Row() {
        Column() {
          Text('BE 碱剩余 (mmol/L)')
            .fontSize(14)
            .fontColor('#1F2421')
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 6 });
          TextInput({ placeholder: '-3~+3' }).type(InputType.NUMBER_DECIMAL)
            .height(48)
            .fontSize(16)
            .fontColor('#1F2421')
            .placeholderColor('#999999')
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 })
            .width('100%')
            .onChange((value: string) => { this.be = value; this.calculate(); });
        }
        .layoutWeight(1);
        Column() {
          Text('SaO\u2082 (%)')
            .fontSize(14)
            .fontColor('#1F2421')
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 6 });
          TextInput({ placeholder: '95-100' }).type(InputType.NUMBER_DECIMAL)
            .height(48)
            .fontSize(16)
            .fontColor('#1F2421')
            .placeholderColor('#999999')
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 })
            .width('100%')
            .onChange((value: string) => { this.sao2 = value; this.calculate(); });
        }
        .layoutWeight(1)
        .margin({ left: 12 });
      }
      .width('100%')
      .margin({ bottom: 12 });

      Row() {
        Column() {
          Text('Lac 乳酸 (mmol/L)')
            .fontSize(14)
            .fontColor('#1F2421')
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 6 });
          TextInput({ placeholder: '0-2' }).type(InputType.NUMBER_DECIMAL)
            .height(48)
            .fontSize(16)
            .fontColor('#1F2421')
            .placeholderColor('#999999')
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 })
            .width('100%')
            .onChange((value: string) => { this.lac = value; this.calculate(); });
        }
        .layoutWeight(1);
        Column() {
          Text('K\u207A (mmol/L)')
            .fontSize(14)
            .fontColor('#1F2421')
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 6 });
          TextInput({ placeholder: '3.5-5.5' }).type(InputType.NUMBER_DECIMAL)
            .height(48)
            .fontSize(16)
            .fontColor('#1F2421')
            .placeholderColor('#999999')
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 })
            .width('100%')
            .onChange((value: string) => { this.k = value; this.calculate(); });
        }
        .layoutWeight(1)
        .margin({ left: 12 });
      }
      .width('100%')
      .margin({ bottom: 12 });

      Column() {
        Text('Hgb 血红蛋白')
          .fontSize(14)
          .fontColor('#1F2421')
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 6 });
        Row() {
          TextInput({ placeholder: '120-160' }).type(InputType.NUMBER_DECIMAL)
            .height(48)
            .fontSize(16)
            .fontColor('#1F2421')
            .placeholderColor('#999999')
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 })
            .layoutWeight(1)
            .onChange((value: string) => { this.hgb = value; this.calculate(); });
          Row() {
            Button('g/L')
              .height(28)
              .fontSize(12)
              .fontColor(this.hgbUnit === 'gl' ? '#FFFFFF' : '#2D5440')
              .backgroundColor(this.hgbUnit === 'gl' ? '#1F3D2F' : '#F5F5F5')
              .borderRadius(4)
              .onClick(() => { this.hgbUnit = 'gl'; this.calculate(); });
            Button('g/dL')
              .height(28)
              .fontSize(12)
              .fontColor(this.hgbUnit === 'gdl' ? '#FFFFFF' : '#2D5440')
              .backgroundColor(this.hgbUnit === 'gdl' ? '#1F3D2F' : '#F5F5F5')
              .borderRadius(4)
              .margin({ left: 4 })
              .onClick(() => { this.hgbUnit = 'gdl'; this.calculate(); });
          }
          .margin({ left: 8 });
        }
        .width('100%');
      }
      .width('100%')
      .margin({ bottom: 12 });

      Row() {
        Column() {
          Text('Na\u207A (mmol/L)')
            .fontSize(14)
            .fontColor('#1F2421')
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 6 });
          TextInput({ placeholder: '135-145' }).type(InputType.NUMBER_DECIMAL)
            .height(48)
            .fontSize(16)
            .fontColor('#1F2421')
            .placeholderColor('#999999')
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 })
            .width('100%')
            .onChange((value: string) => { this.na = value; this.calculate(); });
        }
        .layoutWeight(1);
        Column() {
          Text('Cl\u207B (可选, 算AG) (mmol/L)')
            .fontSize(14)
            .fontColor('#1F2421')
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 6 });
          TextInput({ placeholder: '98-106' }).type(InputType.NUMBER_DECIMAL)
            .height(48)
            .fontSize(16)
            .fontColor('#1F2421')
            .placeholderColor('#999999')
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 })
            .width('100%')
            .onChange((value: string) => { this.cl = value; this.calculate(); });
        }
        .layoutWeight(1)
        .margin({ left: 12 });
      }
      .width('100%')
      .margin({ bottom: 12 });

      Row() {
        Column() {
          Text('Glu 血糖 (mmol/L)')
            .fontSize(14)
            .fontColor('#1F2421')
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 6 });
          TextInput({ placeholder: '3.9-7.8' }).type(InputType.NUMBER_DECIMAL)
            .height(48)
            .fontSize(16)
            .fontColor('#1F2421')
            .placeholderColor('#999999')
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 })
            .width('100%')
            .onChange((value: string) => { this.glu = value; this.calculate(); });
        }
        .layoutWeight(1);
      }
      .width('100%')
      .margin({ bottom: 12 });

      Column() {
        Text('FiO\u2082')
          .fontSize(14)
          .fontColor('#1F2421')
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 6 });
        Row() {
          TextInput({ placeholder: '0.21-1.0' }).type(InputType.NUMBER_DECIMAL)
            .height(48)
            .fontSize(16)
            .fontColor('#1F2421')
            .placeholderColor('#999999')
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 })
            .layoutWeight(1)
            .onChange((value: string) => { this.fio2 = value; this.calculate(); });
          Row() {
            Button('小数')
              .height(28)
              .fontSize(12)
              .fontColor(this.fio2Mode === 'dec' ? '#FFFFFF' : '#2D5440')
              .backgroundColor(this.fio2Mode === 'dec' ? '#1F3D2F' : '#F5F5F5')
              .borderRadius(4)
              .onClick(() => { this.fio2Mode = 'dec'; this.calculate(); });
            Button('%')
              .height(28)
              .fontSize(12)
              .fontColor(this.fio2Mode === 'pct' ? '#FFFFFF' : '#2D5440')
              .backgroundColor(this.fio2Mode === 'pct' ? '#1F3D2F' : '#F5F5F5')
              .borderRadius(4)
              .margin({ left: 4 })
              .onClick(() => { this.fio2Mode = 'pct'; this.calculate(); });
          }
          .margin({ left: 8 });
        }
        .width('100%');
        Text('吸氧浓度; 鼻导管 \u2248 21 + 4\u00D7流量(L/min)')
          .fontSize(12)
          .fontColor('#5F6654')
          .margin({ top: 4 });
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .margin({ bottom: 12 });

      Button(this.showVenous ? '\u25BE 隐藏静脉血气' : '+ 补充静脉血气分析 (缺氧分型 + 呼吸商 R)')
        .height(44)
        .fontSize(13)
        .fontColor('#1F3D2F')
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .width('100%')
        .onClick(() => { this.showVenous = !this.showVenous; });

      if (this.showVenous) {
        Column() {
          Text('填入同一病人同一时间的静脉血气, 解锁缺氧分型(8种)与呼吸商计算。SaO\u2082 高的为动脉、低的为静脉。')
            .fontSize(12)
            .fontColor('#5F6654')
            .margin({ top: 8, bottom: 12 });

          Column() {
            Text('PvCO\u2082')
              .fontSize(14)
              .fontColor('#1F2421')
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 6 });
            Row() {
              TextInput({ placeholder: '40-50' }).type(InputType.NUMBER_DECIMAL)
                .height(48)
                .fontSize(16)
                .fontColor('#1F2421')
                .placeholderColor('#999999')
                .backgroundColor('#FFFFFF')
                .borderRadius(8)
                .border({ width: 1, color: '#E0E0E0' })
                .padding({ left: 12, right: 12 })
                .layoutWeight(1)
                .onChange((value: string) => { this.pvco2 = value; this.calculate(); });
              Row() {
                Button('mmHg')
                  .height(28)
                  .fontSize(12)
                  .fontColor(this.pvco2Unit === 'mmhg' ? '#FFFFFF' : '#2D5440')
                  .backgroundColor(this.pvco2Unit === 'mmhg' ? '#1F3D2F' : '#F5F5F5')
                  .borderRadius(4)
                  .onClick(() => { this.pvco2Unit = 'mmhg'; this.calculate(); });
                Button('kPa')
                  .height(28)
                  .fontSize(12)
                  .fontColor(this.pvco2Unit === 'kpa' ? '#FFFFFF' : '#2D5440')
                  .backgroundColor(this.pvco2Unit === 'kpa' ? '#1F3D2F' : '#F5F5F5')
                  .borderRadius(4)
                  .margin({ left: 4 })
                  .onClick(() => { this.pvco2Unit = 'kpa'; this.calculate(); });
              }
              .margin({ left: 8 });
            }
            .width('100%');
          }
          .width('100%')
          .margin({ bottom: 12 });

          Column() {
            Text('SvO\u2082 (%)')
              .fontSize(14)
              .fontColor('#1F2421')
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 6 });
            TextInput({ placeholder: '60-80' }).type(InputType.NUMBER_DECIMAL)
              .height(48)
              .fontSize(16)
              .fontColor('#1F2421')
              .placeholderColor('#999999')
              .backgroundColor('#FFFFFF')
              .borderRadius(8)
              .border({ width: 1, color: '#E0E0E0' })
              .padding({ left: 12, right: 12 })
              .width('100%')
              .onChange((value: string) => { this.svo2 = value; this.calculate(); });
          }
          .width('100%')
          .margin({ bottom: 12 });

          Column() {
            Text('PvO\u2082 (可选, 算呼吸商 C(a-v)O\u2082)')
              .fontSize(14)
              .fontColor('#1F2421')
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 6 });
            Row() {
              TextInput({ placeholder: '35-45' }).type(InputType.NUMBER_DECIMAL)
                .height(48)
                .fontSize(16)
                .fontColor('#1F2421')
                .placeholderColor('#999999')
                .backgroundColor('#FFFFFF')
                .borderRadius(8)
                .border({ width: 1, color: '#E0E0E0' })
                .padding({ left: 12, right: 12 })
                .layoutWeight(1)
                .onChange((value: string) => { this.pvo2 = value; this.calculate(); });
              Row() {
                Button('mmHg')
                  .height(28)
                  .fontSize(12)
                  .fontColor(this.pvo2Unit === 'mmhg' ? '#FFFFFF' : '#2D5440')
                  .backgroundColor(this.pvo2Unit === 'mmhg' ? '#1F3D2F' : '#F5F5F5')
                  .borderRadius(4)
                  .onClick(() => { this.pvo2Unit = 'mmhg'; this.calculate(); });
                Button('kPa')
                  .height(28)
                  .fontSize(12)
                  .fontColor(this.pvo2Unit === 'kpa' ? '#FFFFFF' : '#2D5440')
                  .backgroundColor(this.pvo2Unit === 'kpa' ? '#1F3D2F' : '#F5F5F5')
                  .borderRadius(4)
                  .margin({ left: 4 })
                  .onClick(() => { this.pvo2Unit = 'kpa'; this.calculate(); });
              }
              .margin({ left: 4 });
            }
            .width('100%');
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start);
        }
        .width('100%')
        .margin({ top: 8 });
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(12);
  }

  @Builder
  Results() {
    if (this.result) {
      Column() {
        Column() {
          Text('\u2460 酸碱失衡')
            .fontSize(13)
            .fontColor('#E76F2C')
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 8 });
          Text(this.result.ab.conclusion)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getTierColor(this.result.ab.tierCls))
            .width('100%');
          if (this.result.ab.detail.length > 0) {
            Text(this.result.ab.detail)
              .fontSize(12)
              .fontColor('#4A5247')
              .width('100%')
              .margin({ top: 6 });
          }
          Row() {
            Text(this.result.ab.tierText)
              .fontSize(12)
              .fontColor('#FFFFFF')
              .padding({ left: 8, right: 8, top: 2, bottom: 2 })
              .borderRadius(4)
              .backgroundColor(this.getTierColor(this.result.ab.tierCls));
          }
          .margin({ top: 6 });
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .margin({ top: 8 });

        Column() {
          Text('\u2461 氧合状态')
            .fontSize(13)
            .fontColor('#E76F2C')
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 8 });
          Text(this.result.o2.conclusion)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1F2421')
            .width('100%');
          if (this.result.o2.detail.length > 0) {
            Text(this.result.o2.detail)
              .fontSize(12)
              .fontColor('#4A5247')
              .width('100%')
              .margin({ top: 6 });
          }
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .margin({ top: 8 });

        Column() {
          Text('\u2462 缺氧分型 (需静脉血气)')
            .fontSize(13)
            .fontColor('#E76F2C')
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 8 });
          if (this.hypoxiaType.length > 0) {
            Text(this.hypoxiaType)
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.getTierColor(this.hypoxiaCls))
              .width('100%');
            if (this.hypoxiaDetail.length > 0) {
              Text(this.hypoxiaDetail)
                .fontSize(12)
                .fontColor('#4A5247')
                .width('100%')
                .margin({ top: 4 });
            }
            if (this.hypoxiaCalc.length > 0) {
              Text(this.hypoxiaCalc)
                .fontSize(12)
                .fontColor('#5F6654')
                .width('100%')
                .margin({ top: 2 });
            }
            Row() {
              Text(this.hypoxiaTierText)
                .fontSize(12)
                .fontColor('#FFFFFF')
                .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                .borderRadius(4)
                .backgroundColor(this.getTierColor(this.hypoxiaCls));
            }
            .margin({ top: 6 });
          } else {
            Text(this.hypoxiaHtml)
              .fontSize(12)
              .fontColor('#5F6654')
              .width('100%');
          }
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .margin({ top: 8 });

        Column() {
          Text('\u2463 呼吸商 R (需静脉血气 + Hgb)')
            .fontSize(13)
            .fontColor('#E76F2C')
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 8 });
          if (this.rConclusion.length > 0) {
            Text(this.rConclusion)
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.getTierColor(this.rCls))
              .width('100%');
            if (this.rDetail.length > 0) {
              Text(this.rDetail)
                .fontSize(12)
                .fontColor('#4A5247')
                .width('100%')
                .margin({ top: 4 });
            }
            Row() {
              Text(this.rTierText)
                .fontSize(12)
                .fontColor('#FFFFFF')
                .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                .borderRadius(4)
                .backgroundColor(this.getTierColor(this.rCls));
            }
            .margin({ top: 6 });
          } else {
            Text(this.rHtml)
              .fontSize(12)
              .fontColor('#5F6654')
              .width('100%');
          }
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .margin({ top: 8 });

        Column() {
          Text('\u2464 危急值预警')
            .fontSize(13)
            .fontColor('#E76F2C')
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 8 });
          if (this.critLines.length > 0) {
            ForEach(this.critLines, (item: CritLine) => {
              Row() {
                Text(item.text)
                  .fontSize(12)
                  .fontColor(this.getCritItemColor(item.level))
                  .layoutWeight(1);
              }
              .width('100%')
              .padding({ top: 3, bottom: 3 });
            }, (item: CritLine, index: number) => index.toString());
          } else {
            Text(this.critHtml)
              .fontSize(12)
              .fontColor('#5F6654')
              .width('100%');
          }
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .margin({ top: 8 });

        Column() {
          Text('\u2465 异常总览')
            .fontSize(13)
            .fontColor('#E76F2C')
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 8 });
          Text(this.result.summary.conclusion)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F3D2F')
            .width('100%');
          if (this.result.summary.detail.length > 0) {
            Text(this.result.summary.detail)
              .fontSize(12)
              .fontColor('#4A5247')
              .width('100%')
              .margin({ top: 6 });
          }
          Text('\u672C\u680F\u4EC5\u6C47\u603B\u524D 5 \u9879\u4E2D\u8D85\u51FA\u9608\u503C\u7684\u5BA2\u89C2\u6570\u636E, \u4E0D\u542B\u6CBB\u7597\u5EFA\u8BAE\u3002')
            .fontSize(12)
            .fontColor('#5F6654')
            .margin({ top: 8 });
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .margin({ top: 8 });
      }
      .width('100%');
    }
  }
}