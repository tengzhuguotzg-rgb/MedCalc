import { CalcResult } from '../../engine/CalcEngine';
import { calculateGbs } from '../../engine/Batch1bCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct GbsCalculator {
  @State resetKey: number = 0;
  @State bun: number = 0;
  @State bunUnit: string = 'mmol';
  @State hgb: number = 0;
  @State sex: string = 'male';
  @State sbp: number = 0;
  @State hr: number = 0;
  @State melena: boolean = false;
  @State syncope: boolean = false;
  @State liverDisease: boolean = false;
  @State heartFailure: boolean = false;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    const bunMgDl = this.bunUnit === 'mmol' ? this.bun * 2.8 : this.bun;
    const hgbGdL = this.hgb / 10;
    this.result = calculateGbs(bunMgDl, hgbGdL, this.sex, this.sbp, this.hr, this.melena, this.syncope, this.liverDisease, this.heartFailure);
  }

  reset() {
    this.bun = 0;
    this.bunUnit = 'mmol';
    this.hgb = 0;
    this.sex = 'male';
    this.sbp = 0;
    this.hr = 0;
    this.melena = false;
    this.syncope = false;
    this.liverDisease = false;
    this.heartFailure = false;
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
        Text('Glasgow-Blatchford：上消化道出血风险分层').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('0 分可考虑门诊处理；≥7 分需积极复苏+尽早内镜').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '输入参数', resetAction: () => { this.reset(); } })
        Row() {
          InputRow({ label: '尿素氮/尿素', placeholder: 'BUN', onTextChange: (value: string) => { this.bun = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          Column() {
            Text('单位').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            Row({ space: 8 }) {
              OptionChip({ label: 'mmol/L(尿素)', selected: this.bunUnit === 'mmol', chipHeight: AppDimens.inputHeight, onChipClick: () => { this.bunUnit = 'mmol'; this.calculate(); } });
              OptionChip({ label: 'mg/dL(BUN)', selected: this.bunUnit === 'mgdl', chipHeight: AppDimens.inputHeight, onChipClick: () => { this.bunUnit = 'mgdl'; this.calculate(); } });
            }
          }.layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });

        Row() {
          InputRow({ label: '血红蛋白 (g/L)', placeholder: 'Hgb', onTextChange: (value: string) => { this.hgb = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          Column() {
            Text('性别').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            Row({ space: 8 }) {
              OptionChip({ label: '男', selected: this.sex === 'male', chipHeight: AppDimens.inputHeight, onChipClick: () => { this.sex = 'male'; this.calculate(); } });
              OptionChip({ label: '女', selected: this.sex === 'female', chipHeight: AppDimens.inputHeight, onChipClick: () => { this.sex = 'female'; this.calculate(); } });
            }
          }.layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });

        Row() {
          InputRow({ label: '收缩压 SBP (mmHg)', placeholder: 'SBP', onTextChange: (value: string) => { this.sbp = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '心率 HR (次/分)', placeholder: 'HR', onTextChange: (value: string) => { this.hr = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });

        Text('临床表现').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row({ space: 8 }) {
          OptionChip({ label: '黑便', selected: this.melena, onChipClick: () => { this.melena = !this.melena; this.calculate(); } });
          OptionChip({ label: '晕厥', selected: this.syncope, onChipClick: () => { this.syncope = !this.syncope; this.calculate(); } });
          OptionChip({ label: '肝病', selected: this.liverDisease, onChipClick: () => { this.liverDisease = !this.liverDisease; this.calculate(); } });
          OptionChip({ label: '心衰', selected: this.heartFailure, onChipClick: () => { this.heartFailure = !this.heartFailure; this.calculate(); } });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'GBS 评分', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding({ left: 16, right: 16, top: 8, bottom: 16 }).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
