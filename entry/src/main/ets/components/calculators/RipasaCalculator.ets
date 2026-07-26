import { CalcResult } from '../../engine/CalcEngine';
import { calculateRipasa } from '../../engine/Batch3aCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct RipasaCalculator {
  @State resetKey: number = 0;
  @State age: number = 0;
  @State sex: string = 'male';
  @State temp: number = 0;
  @State wbc: number = 0;
  @State rlqPain: boolean = false;
  @State migratory: boolean = false;
  @State anorexia: boolean = false;
  @State nauseaVomit: boolean = false;
  @State durLt48h: boolean = false;
  @State rlqTender: boolean = false;
  @State guarding: boolean = false;
  @State rebound: boolean = false;
  @State rovsing: boolean = false;
  @State urineNeg: boolean = false;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    this.result = calculateRipasa(this.age, this.sex, this.rlqPain, this.migratory, this.anorexia, this.nauseaVomit, this.durLt48h, this.rlqTender, this.guarding, this.rebound, this.rovsing, this.temp, this.wbc, this.urineNeg);
  }

  reset() {
    this.age = 0;
    this.sex = 'male';
    this.temp = 0;
    this.wbc = 0;
    this.rlqPain = false;
    this.migratory = false;
    this.anorexia = false;
    this.nauseaVomit = false;
    this.durLt48h = false;
    this.rlqTender = false;
    this.guarding = false;
    this.rebound = false;
    this.rovsing = false;
    this.urineNeg = false;
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
        Text('RIPASA 阑尾炎评分（亚洲人群优化）').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('>12 高概率；8-12 中间区；满分 15.5（不含 NRIC 项）').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '客观项', resetAction: () => { this.reset(); } })
        Row() {
          InputRow({ label: '年龄 (岁)', placeholder: '年龄', onTextChange: (value: string) => { this.age = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          Column() {
            Text('性别').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            Row({ space: 8 }) {
              OptionChip({ label: '男', selected: this.sex === 'male', chipHeight: AppDimens.inputHeight, onChipClick: () => { this.sex = 'male'; this.calculate(); } });
              OptionChip({ label: '女', selected: this.sex === 'female', chipHeight: AppDimens.inputHeight, onChipClick: () => { this.sex = 'female'; this.calculate(); } });
            }
          }.layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });
        Row() {
          InputRow({ label: '体温 (°C)', placeholder: 'Temp', onTextChange: (value: string) => { this.temp = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
          InputRow({ label: 'WBC (×10⁹/L)', placeholder: 'WBC', onTextChange: (value: string) => { this.wbc = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 8 });

        Text('症状/体征').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row({ space: 8 }) {
          OptionChip({ label: '右下腹痛', selected: this.rlqPain, onChipClick: () => { this.rlqPain = !this.rlqPain; this.calculate(); } });
          OptionChip({ label: '转移痛', selected: this.migratory, onChipClick: () => { this.migratory = !this.migratory; this.calculate(); } });
          OptionChip({ label: '厌食', selected: this.anorexia, onChipClick: () => { this.anorexia = !this.anorexia; this.calculate(); } });
          OptionChip({ label: '恶心呕吐', selected: this.nauseaVomit, onChipClick: () => { this.nauseaVomit = !this.nauseaVomit; this.calculate(); } });
        }.width('100%').margin({ bottom: 8 });
        Row({ space: 8 }) {
          OptionChip({ label: '病程<48h', selected: this.durLt48h, onChipClick: () => { this.durLt48h = !this.durLt48h; this.calculate(); } });
          OptionChip({ label: '右下腹压痛', selected: this.rlqTender, onChipClick: () => { this.rlqTender = !this.rlqTender; this.calculate(); } });
          OptionChip({ label: '肌紧张 +2', selected: this.guarding, onChipClick: () => { this.guarding = !this.guarding; this.calculate(); } });
        }.width('100%').margin({ bottom: 8 });
        Row({ space: 8 }) {
          OptionChip({ label: '反跳痛', selected: this.rebound, onChipClick: () => { this.rebound = !this.rebound; this.calculate(); } });
          OptionChip({ label: 'Rovsing征 +2', selected: this.rovsing, onChipClick: () => { this.rovsing = !this.rovsing; this.calculate(); } });
          OptionChip({ label: '尿检阴性', selected: this.urineNeg, onChipClick: () => { this.urineNeg = !this.urineNeg; this.calculate(); } });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'RIPASA', value: this.result!.value, unit: this.result!.unit, decimals: 1, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
