import { CalcResult, getTierColor, getTierBgColor } from '../../engine/CalcEngine';
import { calculateMnutric } from '../../engine/MnutricCalculator';

@Component
export struct MnutricCalculator {
  @State age: number = 0;
  @State apache2: number = 0;
  @State sofa: number = 0;
  @State comorb: number = 0;
  @State icuDay: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateMnutric(this.age, this.apache2, this.sofa, this.comorb, this.icuDay); }

  build() {
    Column() {
      Column() { Text('用于 ICU 患者营养风险评估').fontSize(14).fontColor('#1F3D2F').fontWeight(FontWeight.Medium); Text('5 项, 总分 0-9, ≥5 高营养风险 (Heyland 2011)').fontSize(12).fontColor('#7A8074').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Text('— 输入参数').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });

        Row() {
          Column() {
            Text('年龄').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
            Row() {
              Button('< 50').fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.age === 0 ? '#FFFFFF' : '#2D5440').backgroundColor(this.age === 0 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.age === 0 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).layoutWeight(1).onClick(() => { this.age = 0; this.calculate(); });
              Button('50-74').fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.age === 1 ? '#FFFFFF' : '#2D5440').backgroundColor(this.age === 1 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.age === 1 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).layoutWeight(1).margin({ left: 4 }).onClick(() => { this.age = 1; this.calculate(); });
              Button('≥ 75').fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.age === 2 ? '#FFFFFF' : '#2D5440').backgroundColor(this.age === 2 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.age === 2 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).layoutWeight(1).margin({ left: 4 }).onClick(() => { this.age = 2; this.calculate(); });
            }.width('100%');
          }.layoutWeight(1);
          Column() {
            Text('APACHE II').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
            TextInput({ placeholder: '0-71' }).type(InputType.Number).height(40).fontSize(16).backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).placeholderColor('#999999').onChange((v: string) => { this.apache2 = parseFloat(v) || 0; this.calculate(); });
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 8 });

        Row() {
          Column() {
            Text('SOFA 评分').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
            TextInput({ placeholder: '0-24' }).type(InputType.Number).height(40).fontSize(16).backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).placeholderColor('#999999').onChange((v: string) => { this.sofa = parseFloat(v) || 0; this.calculate(); });
          }.layoutWeight(1);
          Column() {
            Text('合并症数量').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
            Row() {
              Button('0-1 种').fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.comorb === 0 ? '#FFFFFF' : '#2D5440').backgroundColor(this.comorb === 0 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.comorb === 0 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).layoutWeight(1).onClick(() => { this.comorb = 0; this.calculate(); });
              Button('≥ 2 种').fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.comorb === 1 ? '#FFFFFF' : '#2D5440').backgroundColor(this.comorb === 1 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.comorb === 1 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).layoutWeight(1).margin({ left: 4 }).onClick(() => { this.comorb = 1; this.calculate(); });
            }.width('100%');
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 8 });

        Column() {
          Text('住院→ICU 天数').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
          Row() {
            Button('直接入ICU').fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.icuDay === 0 ? '#FFFFFF' : '#2D5440').backgroundColor(this.icuDay === 0 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.icuDay === 0 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).layoutWeight(1).onClick(() => { this.icuDay = 0; this.calculate(); });
            Button('≥ 1 天后').fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.icuDay === 1 ? '#FFFFFF' : '#2D5440').backgroundColor(this.icuDay === 1 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.icuDay === 1 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).layoutWeight(1).margin({ left: 4 }).onClick(() => { this.icuDay = 1; this.calculate(); });
          }.width('100%');
        }.width('100%');
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() {
              Text('mNUTRIC').fontSize(10).fontColor('#7A8074').letterSpacing(1.5);
              Text(this.result!.value !== null ? `${this.result!.value!.toFixed(0)} ${this.result!.unit}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor('#1F3D2F').margin({ top: 4 });
              Text(this.result!.tier).fontSize(13).fontWeight(FontWeight.Bold).fontColor(getTierColor(this.result!.tierClass)).backgroundColor(getTierBgColor(this.result!.tierClass)).borderRadius(20).padding({ left: 12, right: 12, top: 4, bottom: 4 }).margin({ top: 4 });
            }.alignItems(HorizontalAlign.Start).layoutWeight(1);
            Column() {
              Text(this.result!.footnote).fontSize(14).fontColor('#4A5247').lineHeight(22);
            }.layoutWeight(1).alignItems(HorizontalAlign.Start);
          }.width('100%');
        }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%');
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(16).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
