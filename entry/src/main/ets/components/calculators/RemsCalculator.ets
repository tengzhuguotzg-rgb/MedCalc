import { CalcResult } from '../../engine/CalcEngine';
import { calculateRems } from '../../engine/Batch2bCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct RemsCalculator {
  @State resetKey: number = 0;
  @State age: number = 0;
  @State map: number = 0;
  @State hr: number = 0;
  @State rr: number = 0;
  @State spo2: number = 0;
  @State gcs: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateRems(this.age, this.map, this.hr, this.rr, this.spo2, this.gcs); }

  reset() {
    this.age = 0;
    this.map = 0;
    this.hr = 0;
    this.rr = 0;
    this.spo2 = 0;
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
      Column() {
        Text('REMS：急诊快速内科评分').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('年龄/MAP/HR/RR/SpO₂/GCS，0-26 分，与 NEWS2 互补').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '输入参数', resetAction: () => { this.reset(); } })
        Row() {
          InputRow({ label: '年龄 (岁)', placeholder: '年龄', onTextChange: (value: string) => { this.age = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: 'MAP (mmHg)', placeholder: 'MAP', onTextChange: (value: string) => { this.map = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        Row() {
          InputRow({ label: '心率 (次/分)', placeholder: 'HR', onTextChange: (value: string) => { this.hr = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '呼吸频率 (次/分)', placeholder: 'RR', onTextChange: (value: string) => { this.rr = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        Row() {
          InputRow({ label: 'SpO₂ (%)', placeholder: 'SpO2', onTextChange: (value: string) => { this.spo2 = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: 'GCS', placeholder: '3-15', onTextChange: (value: string) => { this.gcs = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'REMS', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding({ left: 16, right: 16, top: 8, bottom: 16 }).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
