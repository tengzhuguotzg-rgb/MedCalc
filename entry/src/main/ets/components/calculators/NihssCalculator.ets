import { CalcResult } from '../../engine/CalcEngine';
import { calculateNihss } from '../../engine/MoreCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, InputRow, ResultCard } from './widgets/CalcWidgets';

@Component
export struct NihssCalculator {
  @State resetKey: number = 0;  @State ia: number = -1;
  @State ib: number = -1;
  @State ic: number = -1;
  @State gaze: number = -1;
  @State vis: number = -1;
  @State face: number = -1;
  @State armA: number = -1;
  @State armB: number = -1;
  @State ata: number = -1;
  @State sens: number = -1;
  @State lang: number = -1;
  @State dys: number = -1;
  @State neg: number = -1;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateNihss(this.ia, this.ib, this.ic, this.gaze, this.vis, this.face, this.armA, this.armB, this.ata, this.sens, this.lang, this.dys, this.neg); }

  reset() {
    this.ia = -1;
    this.ib = -1;
    this.ic = -1;
    this.gaze = -1;
    this.vis = -1;
    this.face = -1;
    this.armA = -1;
    this.armB = -1;
    this.ata = -1;
    this.sens = -1;
    this.lang = -1;
    this.dys = -1;
    this.neg = -1;
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
      Column() { Text('用于评估脑卒中神经功能缺损严重程度').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('11项评估，总分0-42，≥6分考虑溶栓/取栓').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });
      CalcCard() {
        Row() { Text('— 输入参数').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });
        Row() {
          InputRow({ label: '1a 意识水平', placeholder: '0-3', onTextChange: (value: string) => { this.ia = value === '' ? -1 : (parseFloat(value) || 0); this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '1b 提问', placeholder: '0-2', onTextChange: (value: string) => { this.ib = value === '' ? -1 : (parseFloat(value) || 0); this.calculate(); } }).layoutWeight(1).margin({ left: 8 });
          InputRow({ label: '1c 指令', placeholder: '0-2', onTextChange: (value: string) => { this.ic = value === '' ? -1 : (parseFloat(value) || 0); this.calculate(); } }).layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 12 });
        Row() {
          InputRow({ label: '2 凝视', placeholder: '0-2', onTextChange: (value: string) => { this.gaze = value === '' ? -1 : (parseFloat(value) || 0); this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '3 视野', placeholder: '0-3', onTextChange: (value: string) => { this.vis = value === '' ? -1 : (parseFloat(value) || 0); this.calculate(); } }).layoutWeight(1).margin({ left: 8 });
          InputRow({ label: '4 面瘫', placeholder: '0-3', onTextChange: (value: string) => { this.face = value === '' ? -1 : (parseFloat(value) || 0); this.calculate(); } }).layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 12 });
        Row() {
          InputRow({ label: '5a 左上肢', placeholder: '0-4', onTextChange: (value: string) => { this.armA = value === '' ? -1 : (parseFloat(value) || 0); this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '5b 右上肢', placeholder: '0-4', onTextChange: (value: string) => { this.armB = value === '' ? -1 : (parseFloat(value) || 0); this.calculate(); } }).layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 12 });
        Row() {
          InputRow({ label: '6 共济失调', placeholder: '0-2', onTextChange: (value: string) => { this.ata = value === '' ? -1 : (parseFloat(value) || 0); this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '7 感觉', placeholder: '0-2', onTextChange: (value: string) => { this.sens = value === '' ? -1 : (parseFloat(value) || 0); this.calculate(); } }).layoutWeight(1).margin({ left: 8 });
          InputRow({ label: '8 语言', placeholder: '0-3', onTextChange: (value: string) => { this.lang = value === '' ? -1 : (parseFloat(value) || 0); this.calculate(); } }).layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 12 });
        Row() {
          InputRow({ label: '9 构音', placeholder: '0-2', onTextChange: (value: string) => { this.dys = value === '' ? -1 : (parseFloat(value) || 0); this.calculate(); } }).layoutWeight(1);
          InputRow({ label: '10 忽视', placeholder: '0-2', onTextChange: (value: string) => { this.neg = value === '' ? -1 : (parseFloat(value) || 0); this.calculate(); } }).layoutWeight(1).margin({ left: 8 });
        }.width('100%');
      }
      if (this.result) {
        ResultCard({ title: 'NIHSS Total', value: this.result!.value, unit: '', decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
