import { CalcResult } from '../../engine/CalcEngine';
import { calculateNrs2002 } from '../../engine/Nrs2002Calculator';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard } from './widgets/CalcWidgets';

@Component
export struct Nrs2002Calculator {
  @State resetKey: number = 0;  @State patientHeight: number = 0;
  @State patientWeight: number = 0;
  @State weightLoss: string = '';
  @State intake: string = '';
  @State disease: string = '';
  @State ageAdj: number = -1;
  @State result: CalcResult | null = null;

  aboutToAppear() {
    this.calculate();
  }

  calculate() {
    if (this.ageAdj < 0) {
      this.result = { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
      return;
    }
    this.result = calculateNrs2002(this.patientHeight, this.patientWeight, this.weightLoss, this.intake, this.disease, this.ageAdj === 1);
  }

  reset() {
    this.patientHeight = 0;
    this.patientWeight = 0;
    this.weightLoss = '';
    this.intake = '';
    this.disease = '';
    this.ageAdj = -1;
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
        ResultCard({ title: 'NRS-2002', value: this.result!.value, unit: this.result!.unit, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }
    .width('100%')
    .constraintSize({ minHeight: '100%' })
    .padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }

  @Builder
  Header() {
    Column() {
      Text('用于住院患者营养风险筛查')
          .fontSize(14)
          .fontColor(AppColors.primary)
          .fontWeight(FontWeight.Medium);
        Text('4项：BMI+体重下降+摄食减少+疾病严重度，≥3有营养风险')
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
      Row() { Text('— 输入参数')
        .fontSize(12)
        .fontColor(AppColors.warning)
        .fontWeight(FontWeight.Bold)
        .letterSpacing(1.5)
        ; Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });

      Row() {
        InputRow({ label: '身高 (cm)', placeholder: '请输入身高', inputType: InputType.NUMBER_DECIMAL, onTextChange: (value: string) => { this.patientHeight = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1);
        InputRow({ label: '体重 (kg)', placeholder: '请输入体重', inputType: InputType.NUMBER_DECIMAL, onTextChange: (value: string) => { this.patientWeight = parseFloat(value) || 0; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
      }
      .width('100%')
      .margin({ bottom: 16 });

      Column() {
        Text('体重下降程度')
          .fontSize(14)
          .fontColor(AppColors.textPrimary)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 6 });
        Row() {
          OptionChip({ label: '无', selected: this.weightLoss === 'none', fontSize: 12, bold: true, onChipClick: () => { this.weightLoss = 'none'; this.calculate(); } }).layoutWeight(1);
          OptionChip({ label: '>5%', selected: this.weightLoss === 'mild', fontSize: 12, bold: true, onChipClick: () => { this.weightLoss = 'mild'; this.calculate(); } }).layoutWeight(1).margin({ left: 4 });
          OptionChip({ label: '>10%', selected: this.weightLoss === 'mod', fontSize: 12, bold: true, onChipClick: () => { this.weightLoss = 'mod'; this.calculate(); } }).layoutWeight(1).margin({ left: 4 });
          OptionChip({ label: '>15%', selected: this.weightLoss === 'severe', fontSize: 12, bold: true, onChipClick: () => { this.weightLoss = 'severe'; this.calculate(); } }).layoutWeight(1).margin({ left: 4 });
        }
        .width('100%');
      }
      .width('100%')
      .margin({ bottom: 16 });

      Column() {
        Text('进食量 (占正常饮食比例)')
          .fontSize(14)
          .fontColor(AppColors.textPrimary)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 6 });
        Row() {
          OptionChip({ label: '正常', selected: this.intake === 'none', fontSize: 12, bold: true, onChipClick: () => { this.intake = 'none'; this.calculate(); } }).layoutWeight(1);
          OptionChip({ label: '>50%', selected: this.intake === 'mild', fontSize: 12, bold: true, onChipClick: () => { this.intake = 'mild'; this.calculate(); } }).layoutWeight(1).margin({ left: 4 });
          OptionChip({ label: '25-50%', selected: this.intake === 'mod', fontSize: 12, bold: true, onChipClick: () => { this.intake = 'mod'; this.calculate(); } }).layoutWeight(1).margin({ left: 4 });
          OptionChip({ label: '<25%', selected: this.intake === 'severe', fontSize: 12, bold: true, onChipClick: () => { this.intake = 'severe'; this.calculate(); } }).layoutWeight(1).margin({ left: 4 });
        }
        .width('100%');
      }
      .width('100%')
      .margin({ bottom: 16 });

      Column() {
        Text('疾病严重度')
          .fontSize(14)
          .fontColor(AppColors.textPrimary)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 6 });
        Row() {
          OptionChip({ label: '无/轻', selected: this.disease === 'none', fontSize: 12, bold: true, onChipClick: () => { this.disease = 'none'; this.calculate(); } }).layoutWeight(1);
          OptionChip({ label: '中度', selected: this.disease === 'moderate', fontSize: 12, bold: true, onChipClick: () => { this.disease = 'moderate'; this.calculate(); } }).layoutWeight(1).margin({ left: 6 });
          OptionChip({ label: '重度', selected: this.disease === 'severe', fontSize: 12, bold: true, onChipClick: () => { this.disease = 'severe'; this.calculate(); } }).layoutWeight(1).margin({ left: 6 });
        }
        .width('100%');
      }
      .width('100%')
      .margin({ bottom: 16 });

      Column() {
        Text('年龄 ≥ 70 岁')
          .fontSize(14)
          .fontColor(AppColors.textPrimary)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 6 });
        Row() {
          OptionChip({ label: '否', selected: this.ageAdj === 0, fontSize: 15, bold: true, chipHeight: AppDimens.inputHeight, onChipClick: () => { this.ageAdj = 0; this.calculate(); } }).layoutWeight(1);
          OptionChip({ label: '是', selected: this.ageAdj === 1, fontSize: 15, bold: true, chipHeight: AppDimens.inputHeight, onChipClick: () => { this.ageAdj = 1; this.calculate(); } }).layoutWeight(1).margin({ left: 12 });
        }
        .width('100%');
      }
      .width('100%')
      .margin({ bottom: 16 });
    }
  }
}
