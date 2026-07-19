import { CalcResult } from '../../engine/CalcEngine';
import { calculateSofa } from '../../engine/SofaCalculator';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard } from './widgets/CalcWidgets';

@Component
export struct SofaCalculator {
  @State resetKey: number = 0;  @State pao2: number = 0;
  @State fio2: number = 0;
  @State fio2Mode: string = 'dec';
  @State platelet: number = 0;
  @State bilirubin: number = 0;
  @State bilirubinUnit: string = 'umol';
  @State map: number = 0;
  @State vaso: string = '';
  @State gcs: number = 0;
  @State creatinine: number = 0;
  @State creatinineUnit: string = 'umol';
  @State urineOutput: number = -1;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateSofa(this.pao2, this.fio2, this.fio2Mode, this.platelet, this.bilirubin, this.bilirubinUnit, this.map, this.vaso, this.gcs, this.creatinine, this.creatinineUnit, this.urineOutput); }

  reset() {
    this.pao2 = 0;
    this.fio2 = 0;
    this.fio2Mode = 'dec';
    this.platelet = 0;
    this.bilirubin = 0;
    this.bilirubinUnit = 'umol';
    this.map = 0;
    this.vaso = '';
    this.gcs = 0;
    this.creatinine = 0;
    this.creatinineUnit = 'umol';
    this.urineOutput = -1;
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
      Column() { Text('用于评估器官功能障碍程度，Sepsis-3诊断').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('6系统：呼吸+凝血+肝+循环+神经+肾，0-24分').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        Row() { Text('— 呼吸').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });
        Row() {
          InputRow({ label: 'PaO₂ (mmHg)', placeholder: '请输入PaO2', onTextChange: (value: string) => { this.pao2 = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: 'FiO₂', placeholder: this.fio2Mode === 'dec' ? '小数(0.21-1.0)' : '百分比(21-100)', inputType: InputType.NUMBER_DECIMAL, onTextChange: (value: string) => { this.fio2 = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        Row() {
          OptionChip({ label: '小数', selected: this.fio2Mode === 'dec', fontSize: 12, bold: true, onChipClick: () => { this.fio2Mode = 'dec'; this.calculate(); } }).layoutWeight(1);
          OptionChip({ label: '百分比', selected: this.fio2Mode === 'pct', fontSize: 12, bold: true, onChipClick: () => { this.fio2Mode = 'pct'; this.calculate(); } }).layoutWeight(1);
        }.width('100%').margin({ bottom: 8 });
      }

      CalcCard() {
        Text('— 凝血 / 肝脏').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });
        Row() {
          InputRow({ label: '血小板 PLT (×10⁹/L)', placeholder: '请输入PLT', onTextChange: (value: string) => { this.platelet = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '胆红素 (µmol/L)', placeholder: '请输入胆红素', onTextChange: (value: string) => { this.bilirubin = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%');
      }

      CalcCard() {
        Text('— 心血管 / 神经').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });
        Column() {
          Text('升压药').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 8 });
          Flex({ wrap: FlexWrap.Wrap }) {
            OptionChip({ label: '无', selected: this.vaso === 'none', fontSize: 12, onChipClick: () => { this.vaso = 'none'; this.calculate(); } }).margin({ right: 8, bottom: 8 });
            OptionChip({ label: '多巴胺≤5', selected: this.vaso === 'dopaLo', fontSize: 12, onChipClick: () => { this.vaso = 'dopaLo'; this.calculate(); } }).margin({ right: 8, bottom: 8 });
            OptionChip({ label: 'NE≤0.1', selected: this.vaso === 'nore', fontSize: 12, onChipClick: () => { this.vaso = 'nore'; this.calculate(); } }).margin({ right: 8, bottom: 8 });
            OptionChip({ label: '多巴胺5-15', selected: this.vaso === 'dopaMid', fontSize: 12, onChipClick: () => { this.vaso = 'dopaMid'; this.calculate(); } }).margin({ right: 8, bottom: 8 });
            OptionChip({ label: 'NE>0.1', selected: this.vaso === 'noreHi', fontSize: 12, onChipClick: () => { this.vaso = 'noreHi'; this.calculate(); } }).margin({ right: 8, bottom: 8 });
            OptionChip({ label: '多巴胺>15', selected: this.vaso === 'dopa15', fontSize: 12, onChipClick: () => { this.vaso = 'dopa15'; this.calculate(); } }).margin({ right: 8, bottom: 8 });
          }.width('100%');
        }.width('100%').margin({ bottom: 16 });
        Row() {
          InputRow({ label: 'MAP (mmHg)', placeholder: '请输入MAP', onTextChange: (value: string) => { this.map = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: 'GCS 评分', placeholder: '请输入GCS', onTextChange: (value: string) => { this.gcs = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%');
      }

      CalcCard() {
        Text('— 肾脏').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });
        Row() {
          InputRow({ label: '血肌酐 (µmol/L)', placeholder: '请输入肌酐', onTextChange: (value: string) => { this.creatinine = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '尿量 (mL/d)', placeholder: '请输入尿量', onTextChange: (value: string) => { this.urineOutput = value === '' ? -1 : (parseFloat(value) || 0); this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'SOFA Total', value: this.result!.value, unit: '', decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
