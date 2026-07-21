import { CalcResult } from '../../engine/CalcEngine';
import { calculateIch } from '../../engine/IchCalculator';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, OptionChip, ResultCard } from './widgets/CalcWidgets';

@Component
export struct IchCalculator {
  @State resetKey: number = 0;  @State vol: number = 0;
  @State location: number = -1;
  @State ivh: number = -1;
  @State age: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    if (this.ivh < 0) {
      this.result = { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
      return;
    }
    this.result = calculateIch(this.vol, this.location, this.ivh === 1, this.age);
  }

  reset() {
    this.vol = 0;
    this.location = -1;
    this.ivh = -1;
    this.age = 0;
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
      Column() { Text('用于自发性脑出血30天死亡率预测').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('5项：GCS+年龄+幕下+出血量+脑室出血，总分0-6').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        Row() { Text('— 输入参数').fontSize(12).fontColor(AppColors.textSecondary).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });

        InputRow({ label: '血肿体积 (mL)', placeholder: '请输入体积', inputType: InputType.NUMBER_DECIMAL, onTextChange: (value: string) => { this.vol = parseFloat(value) || 0; this.calculate(); } }).width('100%').margin({ bottom: 16 });

        Column() {
          Text('出血部位').fontSize(14).fontColor(AppColors.textPrimary).fontWeight(FontWeight.Medium).margin({ bottom: 8 });
          Row() {
            OptionChip({ label: '幕上', selected: this.location === 0, fontSize: 14, bold: true, onChipClick: () => { this.location = 0; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: '幕下', selected: this.location === 1, fontSize: 14, bold: true, onChipClick: () => { this.location = 1; this.calculate(); } }).layoutWeight(1).margin({ left: 8 });
          }.width('100%');
        }.width('100%').margin({ bottom: 16 });

        Row() { Text('脑室出血').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).layoutWeight(1);
          Row() { OptionChip({ label: '无', selected: this.ivh === 0, fontSize: 14, bold: true, onChipClick: () => { this.ivh = 0; this.calculate(); } }).layoutWeight(1);
            OptionChip({ label: '有', selected: this.ivh === 1, fontSize: 14, bold: true, onChipClick: () => { this.ivh = 1; this.calculate(); } }).layoutWeight(1);
          }.width(100);
        }.width('100%').margin({ bottom: 16 });

        InputRow({ label: '年龄 (岁)', placeholder: '请输入年龄', onTextChange: (value: string) => { this.age = parseFloat(value) || 0; this.calculate(); } }).width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'ICH Score', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
