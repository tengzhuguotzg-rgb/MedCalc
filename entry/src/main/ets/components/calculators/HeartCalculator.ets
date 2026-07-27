import { CalcResult } from '../../engine/CalcEngine';
import { calculateHeart } from '../../engine/Batch1bCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct HeartCalculator {
  @State resetKey: number = 0;
  @State history: number = 0;
  @State ecg: number = 0;
  @State age: number = 0;
  @State riskFactorCount: number = 0;
  @State knownAtherosclerosis: boolean = false;
  @State troponin: number = 0;
  @State tropUln: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    const ratio = this.troponin > 0 && this.tropUln > 0 ? this.troponin / this.tropUln : 0;
    this.result = calculateHeart(this.history, this.ecg, this.age, this.riskFactorCount, this.knownAtherosclerosis, ratio);
  }

  reset() {
    this.history = 0;
    this.ecg = 0;
    this.age = 0;
    this.riskFactorCount = 0;
    this.knownAtherosclerosis = false;
    this.troponin = 0;
    this.tropUln = 0;
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
        Text('HEART 评分：急诊胸痛 MACE 风险分层').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('History / ECG / Age / Risk factors / Troponin 各 0-2 分').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '输入参数', resetAction: () => { this.reset(); } })

        Text('病史可疑程度').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row({ space: 8 }) {
          OptionChip({ label: '轻度 0', selected: this.history === 0, onChipClick: () => { this.history = 0; this.calculate(); } });
          OptionChip({ label: '中度 1', selected: this.history === 1, onChipClick: () => { this.history = 1; this.calculate(); } });
          OptionChip({ label: '高度 2', selected: this.history === 2, onChipClick: () => { this.history = 2; this.calculate(); } });
        }.width('100%').margin({ bottom: 8 });

        Text('心电图').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row({ space: 8 }) {
          OptionChip({ label: '正常 0', selected: this.ecg === 0, onChipClick: () => { this.ecg = 0; this.calculate(); } });
          OptionChip({ label: '非特异改变 1', selected: this.ecg === 1, onChipClick: () => { this.ecg = 1; this.calculate(); } });
          OptionChip({ label: 'ST压低 2', selected: this.ecg === 2, onChipClick: () => { this.ecg = 2; this.calculate(); } });
        }.width('100%').margin({ bottom: 8 });

        Row() {
          InputRow({ label: '年龄 (岁)', placeholder: '年龄', onTextChange: (value: string) => { this.age = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '危险因素个数', placeholder: '0-5', onTextChange: (value: string) => { this.riskFactorCount = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });

        Text('已知动脉粥样硬化疾病').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row({ space: 8 }) {
          OptionChip({ label: '无/未填', selected: !this.knownAtherosclerosis, onChipClick: () => { this.knownAtherosclerosis = false; this.calculate(); } });
          OptionChip({ label: '有', selected: this.knownAtherosclerosis, onChipClick: () => { this.knownAtherosclerosis = true; this.calculate(); } });
        }.width('100%').margin({ bottom: 8 });

        Row() {
          InputRow({ label: '肌钙蛋白', placeholder: 'cTn', onTextChange: (value: string) => { this.troponin = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '本院 ULN', placeholder: 'ULN', onTextChange: (value: string) => { this.tropUln = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%');
        Text('危险因素：高血压/糖尿病/高脂血症/吸烟/肥胖/早发冠心病家族史；肌钙蛋白与 ULN 需同单位').fontSize(11).fontColor(AppColors.textSecondary).margin({ top: 6 });
      }

      if (this.result) {
        ResultCard({ title: 'HEART 评分', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding({ left: 16, right: 16, top: 8, bottom: 16 }).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
