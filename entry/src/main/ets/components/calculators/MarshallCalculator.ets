import { CalcResult } from '../../engine/CalcEngine';
import { calculateMarshall } from '../../engine/MarshallCalculator';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, ResetButton, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct MarshallCalculator {
  @State resetKey: number = 0;  @State pao2: number = 0;
  @State fio2: number = 0;
  @State crUmol: number = 0;
  @State biliUmol: number = 0;
  @State hr: number = 0;
  @State cvp: number = -1;
  @State map: number = 0;
  @State platelet: number = 0;
  @State gcs: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    const fio2 = this.fio2 / 100;
    this.result = calculateMarshall(this.pao2, fio2, this.crUmol, this.biliUmol, this.hr, this.cvp < 0 ? 0 : this.cvp, this.map, this.platelet, this.gcs);
  }

  reset() {
    this.pao2 = 0;
    this.fio2 = 0;
    this.crUmol = 0;
    this.biliUmol = 0;
    this.hr = 0;
    this.cvp = -1;
    this.map = 0;
    this.platelet = 0;
    this.gcs = 0;
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
      Column() { Text('Marshall MODS 多器官功能障碍评分').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('六器官各0-4分，总分0-24（Marshall 1995）').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '呼吸', resetAction: () => { this.reset(); } })
        Row() {
          InputRow({ label: 'PaO₂ (mmHg)', placeholder: '请输入PaO2', onTextChange: (value: string) => { this.pao2 = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: 'FiO₂ (%)', placeholder: '21-100', inputType: InputType.Number, onTextChange: (value: string) => { this.fio2 = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 16 });

        SectionTitle({ title: '肾 / 肝' })
        Row() {
          InputRow({ label: '肌酐 (µmol/L)', placeholder: '如 150', inputType: InputType.NUMBER_DECIMAL, onTextChange: (value: string) => { this.crUmol = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '胆红素 (µmol/L)', placeholder: '如 25', inputType: InputType.NUMBER_DECIMAL, onTextChange: (value: string) => { this.biliUmol = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 16 });

        SectionTitle({ title: '心血管 (PAR = HR×CVP/MAP)' })
        Row() {
          InputRow({ label: 'HR (次/分)', placeholder: '心率', onTextChange: (value: string) => { this.hr = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: 'CVP (cmH₂O)', placeholder: '无测填0', inputType: InputType.NUMBER_DECIMAL, onTextChange: (value: string) => { this.cvp = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
          InputRow({ label: 'MAP (mmHg)', placeholder: 'MAP', inputType: InputType.NUMBER_DECIMAL, onTextChange: (value: string) => { this.map = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 16 });

        SectionTitle({ title: '血液 / 神经' })
        Row() {
          InputRow({ label: '血小板 (×10⁹/L)', placeholder: '如 150', onTextChange: (value: string) => { this.platelet = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: 'GCS (3-15)', placeholder: '如 15', onTextChange: (value: string) => { this.gcs = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'Marshall MODS', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding({ left: 16, right: 16, top: 8, bottom: 16 }).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
