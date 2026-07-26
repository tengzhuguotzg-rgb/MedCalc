import { CalcResult } from '../../engine/CalcEngine';
import { calculateBwps } from '../../engine/Batch1bCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct BwpsCalculator {
  @State resetKey: number = 0;
  @State temp: number = 0;
  @State hr: number = 0;
  @State cns: number = 0;
  @State gi: number = 0;
  @State chf: number = 0;
  @State afib: boolean = false;
  @State precipitant: boolean = false;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateBwps(this.temp, this.hr, this.cns, this.gi, this.chf, this.afib, this.precipitant); }

  reset() {
    this.temp = 0;
    this.hr = 0;
    this.cns = 0;
    this.gi = 0;
    this.chf = 0;
    this.afib = false;
    this.precipitant = false;
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
        Text('Burch-Wartofsky：甲状腺危象评分（BWPS）').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('≥45 高度提示危象；25-44 危象前期').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '输入参数', resetAction: () => { this.reset(); } })
        Row() {
          InputRow({ label: '体温 (°C)', placeholder: 'Temp', onTextChange: (value: string) => { this.temp = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '心率 HR (次/分)', placeholder: 'HR', onTextChange: (value: string) => { this.hr = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });

        Text('中枢神经系统').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row({ space: 8 }) {
          OptionChip({ label: '无 0', selected: this.cns === 0, onChipClick: () => { this.cns = 0; this.calculate(); } });
          OptionChip({ label: '轻度躁动 10', selected: this.cns === 10, onChipClick: () => { this.cns = 10; this.calculate(); } });
          OptionChip({ label: '谵妄/嗜睡 20', selected: this.cns === 20, onChipClick: () => { this.cns = 20; this.calculate(); } });
          OptionChip({ label: '抽搐/昏迷 30', selected: this.cns === 30, onChipClick: () => { this.cns = 30; this.calculate(); } });
        }.width('100%').margin({ bottom: 8 });

        Text('消化/肝（腹泻呕吐腹痛/黄疸）').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row({ space: 8 }) {
          OptionChip({ label: '无 0', selected: this.gi === 0, onChipClick: () => { this.gi = 0; this.calculate(); } });
          OptionChip({ label: '中度 10', selected: this.gi === 10, onChipClick: () => { this.gi = 10; this.calculate(); } });
          OptionChip({ label: '黄疸 20', selected: this.gi === 20, onChipClick: () => { this.gi = 20; this.calculate(); } });
        }.width('100%').margin({ bottom: 8 });

        Text('心衰').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row({ space: 8 }) {
          OptionChip({ label: '无 0', selected: this.chf === 0, onChipClick: () => { this.chf = 0; this.calculate(); } });
          OptionChip({ label: '轻度 5', selected: this.chf === 5, onChipClick: () => { this.chf = 5; this.calculate(); } });
          OptionChip({ label: '中度 10', selected: this.chf === 10, onChipClick: () => { this.chf = 10; this.calculate(); } });
          OptionChip({ label: '肺水肿 15', selected: this.chf === 15, onChipClick: () => { this.chf = 15; this.calculate(); } });
        }.width('100%').margin({ bottom: 8 });

        Row({ space: 8 }) {
          OptionChip({ label: '房颤 +10', selected: this.afib, onChipClick: () => { this.afib = !this.afib; this.calculate(); } });
          OptionChip({ label: '诱因 +10', selected: this.precipitant, onChipClick: () => { this.precipitant = !this.precipitant; this.calculate(); } });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'BWPS', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
