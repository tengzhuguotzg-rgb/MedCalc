import { CalcResult } from '../../engine/CalcEngine';
import { calculateTls } from '../../engine/Batch1bCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct TlsCalculator {
  @State resetKey: number = 0;
  @State uricAcid: number = 0;
  @State k: number = 0;
  @State phos: number = 0;
  @State ca: number = 0;
  @State crUlnRatio: number = 0;
  @State arrhythmia: boolean = false;
  @State seizure: boolean = false;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateTls(this.uricAcid, this.k, this.phos, this.ca, this.crUlnRatio, this.arrhythmia, this.seizure); }

  reset() {
    this.uricAcid = 0;
    this.k = 0;
    this.phos = 0;
    this.ca = 0;
    this.crUlnRatio = 0;
    this.arrhythmia = false;
    this.seizure = false;
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
        Text('Cairo-Bishop 肿瘤溶解综合征（TLS）分级').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('≥2 项实验室异常 = 实验室 TLS；叠加器官表现 = 临床 TLS').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '实验室项', resetAction: () => { this.reset(); } })
        Row() {
          InputRow({ label: '尿酸 (μmol/L)', placeholder: '≥476计1', onTextChange: (value: string) => { this.uricAcid = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '血钾 (mmol/L)', placeholder: '≥6.0计1', onTextChange: (value: string) => { this.k = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        Row() {
          InputRow({ label: '血磷 (mmol/L)', placeholder: '≥1.45计1', onTextChange: (value: string) => { this.phos = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '血钙 (mmol/L)', placeholder: '≤1.75计1', onTextChange: (value: string) => { this.ca = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });

        Text('临床项（判定临床 TLS）').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        InputRow({ label: '肌酐 / ULN 倍数', placeholder: '≥1.5计入', onTextChange: (value: string) => { this.crUlnRatio = parseFloat(value) || 0; this.calculate(); } }).margin({ bottom: 8 });
        Row({ space: 8 }) {
          OptionChip({ label: '心律失常', selected: this.arrhythmia, onChipClick: () => { this.arrhythmia = !this.arrhythmia; this.calculate(); } });
          OptionChip({ label: '抽搐', selected: this.seizure, onChipClick: () => { this.seizure = !this.seizure; this.calculate(); } });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'Cairo-Bishop TLS', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding({ left: 16, right: 16, top: 8, bottom: 16 }).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
