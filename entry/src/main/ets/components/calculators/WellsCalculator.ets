import { CalcResult } from '../../engine/CalcEngine';
import { calculateWells } from '../../engine/WellsCalculator';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, OptionChip, ResultCard } from './widgets/CalcWidgets';

@Component
export struct WellsCalculator {
  @State resetKey: number = 0;  @State clinical: number = -1;
  @State hr: number = -1;
  @State surgery: number = -1;
  @State hemoptysis: number = -1;
  @State cancer: number = -1;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    if (this.clinical < 0 || this.hr < 0 || this.surgery < 0 || this.hemoptysis < 0 || this.cancer < 0) {
      this.result = { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
      return;
    }
    this.result = calculateWells(this.clinical === 1, this.hr === 1, this.surgery === 1, this.hemoptysis === 1, this.cancer === 1);
  }

  reset() {
    this.clinical = -1;
    this.hr = -1;
    this.surgery = -1;
    this.hemoptysis = -1;
    this.cancer = -1;
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
      Column() { Text('用于评估肺栓塞临床概率，指导D-二聚体解读').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('7项：DVT症状+PE主诊断+心率+制动+咯血+肿瘤+其他').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        Row() { Text('— 输入参数').fontSize(12).fontColor(AppColors.textSecondary).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });

        Row() { Text('深静脉血栓临床表现').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() { OptionChip({ label: '无', selected: this.clinical === 0, fontSize: 14, bold: true, onChipClick: () => { this.clinical = 0; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: '有', selected: this.clinical === 1, fontSize: 14, bold: true, onChipClick: () => { this.clinical = 1; this.calculate(); } }).layoutWeight(1);
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('心率>100次/分').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() { OptionChip({ label: '无', selected: this.hr === 0, fontSize: 14, bold: true, onChipClick: () => { this.hr = 0; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: '有', selected: this.hr === 1, fontSize: 14, bold: true, onChipClick: () => { this.hr = 1; this.calculate(); } }).layoutWeight(1);
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('近期手术或制动').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() { OptionChip({ label: '无', selected: this.surgery === 0, fontSize: 14, bold: true, onChipClick: () => { this.surgery = 0; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: '有', selected: this.surgery === 1, fontSize: 14, bold: true, onChipClick: () => { this.surgery = 1; this.calculate(); } }).layoutWeight(1);
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('咯血').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() { OptionChip({ label: '无', selected: this.hemoptysis === 0, fontSize: 14, bold: true, onChipClick: () => { this.hemoptysis = 0; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: '有', selected: this.hemoptysis === 1, fontSize: 14, bold: true, onChipClick: () => { this.hemoptysis = 1; this.calculate(); } }).layoutWeight(1);
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('活动性癌症').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() { OptionChip({ label: '无', selected: this.cancer === 0, fontSize: 14, bold: true, onChipClick: () => { this.cancer = 0; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: '有', selected: this.cancer === 1, fontSize: 14, bold: true, onChipClick: () => { this.cancer = 1; this.calculate(); } }).layoutWeight(1);
          }.width(100);
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'WELLS', value: this.result!.value, unit: this.result!.unit, decimals: 1, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
