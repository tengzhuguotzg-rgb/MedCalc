import { CalcResult } from '../../engine/CalcEngine';
import { calculateApache2 } from '../../engine/Apache2Calculator';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard } from './widgets/CalcWidgets';

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
        ResultCard({ title: 'APACHE II', value: this.result!.value, unit: this.result!.unit, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }
    .width('100%')
    .constraintSize({ minHeight: '100%' })
    .padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
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
    CalcCard() {
      Row() { Text('— 生命体征')
        .fontSize(12)
        .fontColor(AppColors.warning)
        .fontWeight(FontWeight.Bold)
        .letterSpacing(1.5)
        ; Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });

      Row() {
        InputRow({ label: '体温 (°C)', placeholder: '37.0', inputType: InputType.NUMBER_DECIMAL, onTextChange: (value: string) => { this.temp = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
        InputRow({ label: '心率 (次/分)', placeholder: '80', onTextChange: (value: string) => { this.hr = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
      }
      .width('100%')
      .margin({ bottom: 16 });

      Row() {
        InputRow({ label: '收缩压 (mmHg)', placeholder: '120', onTextChange: (value: string) => { this.sbp = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
        InputRow({ label: '舒张压 (mmHg)', placeholder: '80', onTextChange: (value: string) => { this.dbp = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
      }
      .width('100%')
      .margin({ bottom: 16 });

      InputRow({ label: '呼吸频率 (次/分)', placeholder: '16', onTextChange: (value: string) => { this.rr = parseFloat(value) || 0; this.calculate(); } })
        .width('100%')
        .margin({ bottom: 16 });

      Text('— 氧合参数')
        .fontSize(12)
        .fontColor(AppColors.warning)
        .fontWeight(FontWeight.Bold)
        .letterSpacing(1.5)
        .margin({ bottom: 12 });

      InputRow({ label: 'FiO₂', placeholder: this.fio2Mode === 'dec' ? '小数(0.21-1.0)' : '百分比(21-100)', inputType: InputType.NUMBER_DECIMAL, onTextChange: (value: string) => { this.fio2 = parseFloat(value) || 0; this.calculate(); } })
        .width('100%')
        .margin({ bottom: 16 });

      Row() {
        OptionChip({ label: '小数', selected: this.fio2Mode === 'dec', fontSize: 12, bold: true, onChipClick: () => { this.fio2Mode = 'dec'; this.calculate(); } }).layoutWeight(1);
        OptionChip({ label: '百分比', selected: this.fio2Mode === 'pct', fontSize: 12, bold: true, onChipClick: () => { this.fio2Mode = 'pct'; this.calculate(); } }).layoutWeight(1);
      }
      .width('100%')
      .margin({ bottom: 16 });

      Row() {
        InputRow({ label: 'PaO₂ (mmHg)', placeholder: '80', onTextChange: (value: string) => { this.pao2 = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
        InputRow({ label: 'PaCO₂ (mmHg)', placeholder: '40', inputEnabled: this.paco2Filled, onTextChange: (value: string) => { this.paco2 = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
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
        OptionChip({ label: 'pH (首选)', selected: this.phFilled, fontSize: 13, bold: true, onChipClick: () => { this.phFilled = true; this.hco3Filled = false; this.calculate(); } }).layoutWeight(1).margin({ right: 4 });
        OptionChip({ label: 'HCO₃⁻ (备选)', selected: this.hco3Filled, fontSize: 13, bold: true, onChipClick: () => { this.hco3Filled = true; this.phFilled = false; this.calculate(); } }).layoutWeight(1).margin({ left: 4 });
      }.width('100%').margin({ bottom: 10 });

      Row() {
        InputRow({ label: 'pH', placeholder: '7.40', inputType: InputType.NUMBER_DECIMAL, inputEnabled: this.phFilled, onTextChange: (value: string) => { this.ph = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
        InputRow({ label: 'HCO₃⁻ (mmol/L)', placeholder: '24', inputType: InputType.NUMBER_DECIMAL, inputEnabled: this.hco3Filled, onTextChange: (value: string) => { this.hco3 = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
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
        InputRow({ label: 'Na⁺ (mmol/L)', placeholder: '140', onTextChange: (value: string) => { this.na = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
        InputRow({ label: 'K⁺ (mmol/L)', placeholder: '4.0', inputType: InputType.NUMBER_DECIMAL, onTextChange: (value: string) => { this.k = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
      }
      .width('100%')
      .margin({ bottom: 16 });

      Row() {
        Column() {
          InputRow({ label: '肌酐', placeholder: '80', inputType: InputType.NUMBER_DECIMAL, onTextChange: (value: string) => { this.cr = parseFloat(value) || 0; this.calculate(); } });
          Row() {
            OptionChip({ label: 'µmol/L', selected: this.crUnit === 'umol', fontSize: 12, bold: true, chipHeight: 28, chipRadius: 6, onChipClick: () => { this.crUnit = 'umol'; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: 'mg/dL', selected: this.crUnit === 'mgdl', fontSize: 12, bold: true, chipHeight: 28, chipRadius: 6, onChipClick: () => { this.crUnit = 'mgdl'; this.calculate(); } }).layoutWeight(1).margin({ left: 4 });
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
          .fontColor(AppColors.textPrimary)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 6 });
        Row() {
          OptionChip({ label: '否', selected: this.arf === 0, fontSize: 15, bold: true, chipHeight: AppDimens.inputHeight, onChipClick: () => { this.arf = 0; this.calculate(); } }).layoutWeight(1);
          OptionChip({ label: '是', selected: this.arf === 1, fontSize: 15, bold: true, chipHeight: AppDimens.inputHeight, onChipClick: () => { this.arf = 1; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
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
        InputRow({ label: 'HCT (%)', placeholder: '40', inputType: InputType.NUMBER_DECIMAL, onTextChange: (value: string) => { this.hct = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
        InputRow({ label: 'WBC (×10⁹/L)', placeholder: '8', inputType: InputType.NUMBER_DECIMAL, onTextChange: (value: string) => { this.wbc = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
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
        InputRow({ label: 'GCS (3-15)', placeholder: '15', onTextChange: (value: string) => { this.gcs = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
        InputRow({ label: '年龄 (岁)', placeholder: '50', onTextChange: (value: string) => { this.age = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
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
        OptionChip({ label: '无', selected: this.chronic === 'none', fontSize: 12, bold: true, onChipClick: () => { this.chronic = 'none'; this.calculate(); } }).layoutWeight(1);
        OptionChip({ label: '择期术后', selected: this.chronic === 'elective', fontSize: 12, bold: true, onChipClick: () => { this.chronic = 'elective'; this.calculate(); } }).layoutWeight(1).margin({ left: 4 });
        OptionChip({ label: '非手术/急诊', selected: this.chronic === 'nonop', fontSize: 12, bold: true, onChipClick: () => { this.chronic = 'nonop'; this.calculate(); } }).layoutWeight(1).margin({ left: 4 });
      }
      .width('100%')
      .margin({ bottom: 16 });
    }
  }
}
