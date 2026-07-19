import { CalcResult , getTierColor, getTierBgColor } from '../../engine/CalcEngine';
import { calculateMehran } from '../../engine/MehranCalculator';
import { AppColors } from '../../utils/AppColors';

@Component
export struct MehranCalculator {
  @State resetKey: number = 0;  @State age: number = 0;
  @State chf: number = -1;
  @State dm: number = -1;
  @State gfr: number = 0;
  @State contrastVol: number = 0;
  @State anemia: number = -1;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    if (this.chf < 0 || this.dm < 0 || this.anemia < 0) {
      this.result = { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
      return;
    }
    this.result = calculateMehran(this.age, this.chf === 1, this.dm === 1, this.gfr, this.contrastVol, this.anemia === 1);
  }

  reset() {
    this.age = 0;
    this.chf = -1;
    this.dm = -1;
    this.gfr = 0;
    this.contrastVol = 0;
    this.anemia = -1;
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
      Column() { Text('用于预测冠脉介入后造影剂肾病风险').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('8项：低血压+IABP+心衰+年龄+贫血+糖尿病+造影剂+肌酐/eGFR').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Row() { Text('— 输入参数').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });

        Row() {
          Column() { Text('年龄 (岁)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '请输入年龄' }).type(InputType.Number).height(48).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.age = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1);
          Column() { Text('eGFR (mL/min)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '请输入eGFR' }).type(InputType.Number).height(48).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.gfr = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 16 });

        Column() { Text('造影剂用量 (mL)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '请输入用量' }).type(InputType.Number).height(48).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor(AppColors.card).borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.contrastVol = parseFloat(value) || 0; this.calculate(); }); }.width('100%').margin({ bottom: 16 });

        Row() { Text('心力衰竭').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.chf === 0 ? AppColors.card : '#2D5440').backgroundColor(this.chf === 0 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.chf === 0 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(44).layoutWeight(1).onClick(() => { this.chf = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.chf === 1 ? AppColors.card : '#2D5440').backgroundColor(this.chf === 1 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.chf === 1 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(44).layoutWeight(1).onClick(() => { this.chf = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('糖尿病').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.dm === 0 ? AppColors.card : '#2D5440').backgroundColor(this.dm === 0 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.dm === 0 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(44).layoutWeight(1).onClick(() => { this.dm = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.dm === 1 ? AppColors.card : '#2D5440').backgroundColor(this.dm === 1 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.dm === 1 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(44).layoutWeight(1).onClick(() => { this.dm = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('贫血').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.anemia === 0 ? AppColors.card : '#2D5440').backgroundColor(this.anemia === 0 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.anemia === 0 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(44).layoutWeight(1).onClick(() => { this.anemia = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.anemia === 1 ? AppColors.card : '#2D5440').backgroundColor(this.anemia === 1 ? AppColors.primary : AppColors.fillNeutral).border({ width: 1, color: this.anemia === 1 ? AppColors.primary : '#E0E0E0' }).borderRadius(8).height(44).layoutWeight(1).onClick(() => { this.anemia = 1; this.calculate(); });
          }.width(100);
        }.width('100%');
      }.padding(16).backgroundColor(AppColors.card).borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() { Text('Mehran').fontSize(12).fontColor(AppColors.textSecondary).letterSpacing(1.5).fontWeight(FontWeight.Medium);
              Text(this.result!.value !== null ? `${this.result!.value!.toFixed(0)} ${this.result!.unit}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor(AppColors.primary).margin({ top: 8 });
              Text(this.result!.tier).fontSize(13).fontWeight(FontWeight.Bold).fontColor(getTierColor(this.result!.tierClass))
                .backgroundColor(getTierBgColor(this.result!.tierClass)).borderRadius(20).padding({ left: 12, right: 12, top: 4, bottom: 4 }).margin({ top: 8 });
            }.alignItems(HorizontalAlign.Start).layoutWeight(1);
            Column() { Text(this.result!.footnote).fontSize(14).fontColor('#4A5247').lineHeight(22); }.layoutWeight(1).alignItems(HorizontalAlign.Start);
          }.width('100%');
        }.padding(16).backgroundColor(AppColors.card).borderRadius(12).width('100%');
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(16).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
