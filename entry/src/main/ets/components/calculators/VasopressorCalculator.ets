import { vasopressorMlhToDose, vasopressorDoseToMlh, vasopressinMlhToDose, vasopressinDoseToMlh } from '../../engine/VasopressorCalculator';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';

const VP_DRUGS: string[][] = [
  ['norepinephrine', '去甲肾上腺素 (NE)'],
  ['dopamine', '多巴胺 (DA)'],
  ['dobutamine', '多巴酚丁胺 (DOB)'],
  ['epinephrine', '肾上腺素 (EPI)'],
  ['phenylephrine', '去氧肾上腺素 (PE)'],
  ['vasopressin', '垂体后叶素 (VP)'],
];

@Component
export struct VasopressorCalculator {
  @State resetKey: number = 0;
  @State weight: number = 0;
  @State drug: string = 'norepinephrine';
  @State concA: number = 0;
  @State concB: number = 0;
  @State mlhText: string = '';
  @State doseText: string = '';
  @State resultMlh: number = 0;
  @State resultDose: number = 0;
  @State resultUnit: string = '';
  @State calculated: boolean = false;
  @State inputMode: string = 'mlh';

  isVp(): boolean {
    return this.drug === 'vasopressin';
  }

  getConcLabel(): string {
    return this.isVp() ? '药物 (U)' : '药物 (mg)';
  }

  getDoseLabel(): string {
    return this.isVp() ? '剂量 (U/min)' : '剂量 (μg/kg/min)';
  }

  getConcValue(): string {
    if (this.concA > 0 && this.concB > 0) {
      if (this.isVp()) {
        return `浓度: ${(this.concA / this.concB).toFixed(2)} U/mL`;
      }
      return `浓度: ${(this.concA * 1000 / this.concB).toFixed(1)} μg/mL`;
    }
    return '';
  }

  onMlhChange(value: string): void {
    this.mlhText = value;
    this.inputMode = 'mlh';
    this.calculated = false;
  }

  onDoseChange(value: string): void {
    this.doseText = value;
    this.inputMode = 'dose';
    this.calculated = false;
  }

  onWeightChange(value: string): void {
    this.weight = parseFloat(value) || 0;
    this.calculated = false;
  }

  onConcAChange(value: string): void {
    this.concA = parseFloat(value) || 0;
    this.calculated = false;
  }

  onConcBChange(value: string): void {
    this.concB = parseFloat(value) || 0;
    this.calculated = false;
  }

  onCalculate(): void {
    const mlh = parseFloat(this.mlhText) || 0;
    if (this.inputMode === 'mlh' && mlh > 0) {
      this.resultMlh = mlh;
      if (this.isVp()) {
        if (this.concA > 0 && this.concB > 0) {
          const dose = vasopressinMlhToDose(this.concA, this.concB, mlh) || 0;
          this.resultDose = dose;
          this.resultUnit = 'U/min';
          this.calculated = true;
        }
      } else {
        if (this.concA > 0 && this.concB > 0 && this.weight > 0) {
          const dose = vasopressorMlhToDose(this.concA, this.concB, this.weight, mlh) || 0;
          this.resultDose = dose;
          this.resultUnit = 'μg/kg/min';
          this.calculated = true;
        }
      }
    }
    const dose = parseFloat(this.doseText) || 0;
    if (this.inputMode === 'dose' && dose > 0) {
      this.resultDose = dose;
      if (this.isVp()) {
        if (this.concA > 0 && this.concB > 0) {
          const mlhVal = vasopressinDoseToMlh(this.concA, this.concB, dose) || 0;
          this.resultMlh = mlhVal;
          this.resultUnit = 'U/min';
          this.calculated = true;
        }
      } else {
        if (this.concA > 0 && this.concB > 0 && this.weight > 0) {
          const mlhVal = vasopressorDoseToMlh(this.concA, this.concB, this.weight, dose) || 0;
          this.resultMlh = mlhVal;
          this.resultUnit = 'μg/kg/min';
          this.calculated = true;
        }
      }
    }
  }

  canCalculate(): boolean {
    if (this.inputMode === 'mlh') {
      return this.mlhText.trim() !== '' && parseFloat(this.mlhText) > 0;
    }
    return this.doseText.trim() !== '' && parseFloat(this.doseText) > 0;
  }

  getDrugName(): string {
    for (const d of VP_DRUGS) {
      if (d[0] === this.drug) {
        return d[1];
      }
    }
    return '';
  }

  reset() {
    this.weight = 0;
    this.drug = 'norepinephrine';
    this.concA = 0;
    this.concB = 0;
    this.mlhText = '';
    this.doseText = '';
    this.resultMlh = 0;
    this.resultDose = 0;
    this.resultUnit = '';
    this.calculated = false;
    this.inputMode = 'mlh';
    this.resetKey = this.resetKey + 1;
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
        Text('升压药剂量换算 (mL/h ↔ μg/kg/min，垂体后叶素为 U/min)')
          .fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('支持双向换算：调速→剂量 或 剂量→调速')
          .fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Row() { Text('— 患者参数').fontSize(12).fontColor(AppColors.textSecondary).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });
        if (!this.isVp()) {
          Column() {
            Text('体重 (kg)').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            TextInput({ placeholder: '体重' }).type(InputType.NUMBER_DECIMAL).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder)
              .onChange((value: string) => { this.onWeightChange(value); });
          }.width('100%').margin({ bottom: 12 });
        }

        Text('— 药物选择').fontSize(12).fontColor(AppColors.textSecondary).fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(VP_DRUGS, (d: string[]) => {
            Button(d[1]).fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.drug === d[0] ? AppColors.card : AppColors.textOption)
              .backgroundColor(this.drug === d[0] ? AppColors.primary : AppColors.fillNeutral)
              .border({ width: 1, color: this.drug === d[0] ? AppColors.primary : AppColors.border })
              .borderRadius(8).height(32).margin({ right: 6, bottom: 6 })
              .onClick(() => { this.drug = d[0]; this.calculated = false; });
          }, (d: string[]) => d[0]);
        }.width('100%').margin({ bottom: 12 });

        Text(`— 配药浓度`).fontSize(12).fontColor(AppColors.textSecondary).fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });
        Row() {
          Column() {
            Text(this.getConcLabel()).fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            TextInput({ placeholder: this.isVp() ? 'U' : 'mg' })
              .type(InputType.NUMBER_DECIMAL).height(AppDimens.inputHeight).fontSize(16)
              .backgroundColor(AppColors.card).borderRadius(8)
              .border({ width: 1, color: AppColors.border })
              .padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder)
              .onChange((value: string) => { this.onConcAChange(value); });
          }.layoutWeight(1);
          Column() {
            Text('配成 (mL)').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            TextInput({ placeholder: 'mL' }).type(InputType.NUMBER_DECIMAL).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder)
              .onChange((value: string) => { this.onConcBChange(value); });
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 12 });

        if (this.getConcValue()) {
          Text(this.getConcValue()).fontSize(12).fontColor(AppColors.textSecondary).margin({ bottom: 8 });
        }

        Text('— 双向换算').fontSize(12).fontColor(AppColors.textSecondary).fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });
        Row() {
          Column() {
            Text('速度 (mL/h)').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            TextInput({ placeholder: 'mL/h' }).type(InputType.NUMBER_DECIMAL).height(AppDimens.inputHeight).fontSize(16).backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: AppColors.border }).padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder)
              .onChange((value: string) => { this.onMlhChange(value); });
          }.layoutWeight(1);
          Column() {
            Text(this.getDoseLabel()).fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
            TextInput({ placeholder: this.isVp() ? 'U/min' : 'μg/kg/min' })
              .type(InputType.NUMBER_DECIMAL).height(AppDimens.inputHeight).fontSize(16)
              .backgroundColor(AppColors.card).borderRadius(8)
              .border({ width: 1, color: AppColors.border })
              .padding({ left: 12, right: 12 }).placeholderColor(AppColors.placeholder)
              .onChange((value: string) => { this.onDoseChange(value); });
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%');

        Button('计算')
          .fontSize(14)
          .fontColor(AppColors.onPrimary)
          .backgroundColor(AppColors.primary)
          .borderRadius(8)
          .height(AppDimens.inputHeight)
          .width('100%')
          .margin({ top: 12 })
          .enabled(this.canCalculate())
          .onClick(() => { this.onCalculate(); })
      }.padding(AppDimens.cardPadding).backgroundColor(AppColors.card).borderRadius(AppDimens.cardRadius).width('100%').margin({ bottom: 16 });

      if (this.calculated) {
        Column() {
          Row() {
            Column() {
              Text('换算结果').fontSize(12).fontColor(AppColors.textSecondary).letterSpacing(1.5);
              Text(this.getDrugName()).fontSize(22).fontWeight(FontWeight.Bold).fontColor(AppColors.primary).margin({ top: 4 });
              Text(`${this.resultMlh.toFixed(2)} mL/h  =  ${this.resultDose.toFixed(4)} ${this.resultUnit}`)
                .fontSize(20).fontWeight(FontWeight.Bold).fontColor(AppColors.primary).margin({ top: 6 });
              Text(this.inputMode === 'mlh' ? 'mL/h → ' + this.resultUnit : this.resultUnit + ' → mL/h')
                .fontSize(11).fontColor(AppColors.textSecondary).margin({ top: 2 });
            }.alignItems(HorizontalAlign.Start).layoutWeight(1);
          }.width('100%');
        }.padding(AppDimens.cardPadding).backgroundColor(AppColors.card).borderRadius(AppDimens.cardRadius).width('100%');
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
