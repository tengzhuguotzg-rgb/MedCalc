import { CalcResult , getTierColor, getTierBgColor } from '../../engine/CalcEngine';
import { calculateGfr } from '../../engine/GfrCalculator';

@Component
export struct GfrCalculator {
  @State resetKey: number = 0;  @State sex: string = '';
  @State age: number = 0;
  @State creatinine: number = 0;
  @State crUnit: string = 'umol';
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateGfr(this.sex, this.age, this.creatinine, this.crUnit); }

  reset() {
    this.sex = '';
    this.age = 0;
    this.creatinine = 0;
    this.crUnit = 'umol';
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
      Column() { Text('用于评估肾小球滤过率，CKD分期').fontSize(14).fontColor('#1F3D2F').fontWeight(FontWeight.Medium); Text('CKD-EPI 2021 race-free公式，需肌酐+年龄+性别').fontSize(12).fontColor('#7A8074').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Row() { Text('— 输入参数').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor('#7A8074').onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });

        Row() {
          Button('男').fontSize(15).fontWeight(FontWeight.Bold).fontColor(this.sex === 'male' ? '#FFFFFF' : '#2D5440')
            .backgroundColor(this.sex === 'male' ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.sex === 'male' ? '#1F3D2F' : '#E0E0E0' })
            .borderRadius(8).height(40).layoutWeight(1).onClick(() => { this.sex = 'male'; this.calculate(); });
          Button('女').fontSize(15).fontWeight(FontWeight.Bold).fontColor(this.sex === 'female' ? '#FFFFFF' : '#2D5440')
            .backgroundColor(this.sex === 'female' ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.sex === 'female' ? '#1F3D2F' : '#E0E0E0' })
            .borderRadius(8).height(40).layoutWeight(1).onClick(() => { this.sex = 'female'; this.calculate(); });
        }.width('100%').margin({ bottom: 16 });

        Column() {
          Text('年龄 (岁)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 });
          TextInput({ placeholder: '请输入年龄' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421')
            .placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.age = parseFloat(value) || 0; this.calculate(); });
        }.width('100%').margin({ bottom: 12 });

        Column() {
          Text('血肌酐').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 });
          TextInput({ placeholder: '肌酐' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421')
            .placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' })
            .padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.creatinine = parseFloat(value) || 0; this.calculate(); });
          Flex({ wrap: FlexWrap.Wrap }) {
            Button('µmol/L').fontSize(11).fontWeight(FontWeight.Bold).fontColor(this.crUnit === 'umol' ? '#FFFFFF' : '#2D5440').backgroundColor(this.crUnit === 'umol' ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.crUnit === 'umol' ? '#1F3D2F' : '#E0E0E0' }).borderRadius(6).height(28).padding({ left: 6, right: 6 }).margin({ right: 4, bottom: 4 }).onClick(() => { this.crUnit = 'umol'; this.calculate(); });
            Button('mg/dL').fontSize(11).fontWeight(FontWeight.Bold).fontColor(this.crUnit === 'mgdl' ? '#FFFFFF' : '#2D5440').backgroundColor(this.crUnit === 'mgdl' ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.crUnit === 'mgdl' ? '#1F3D2F' : '#E0E0E0' }).borderRadius(6).height(28).padding({ left: 6, right: 6 }).margin({ bottom: 4 }).onClick(() => { this.crUnit = 'mgdl'; this.calculate(); });
          }.width('100%').margin({ top: 4 });
        }.width('100%');
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() {
              Text('eGFR').fontSize(12).fontColor('#7A8074').letterSpacing(1.5).fontWeight(FontWeight.Medium);
              Text(this.result!.value !== null ? `${this.result!.value!.toFixed(1).replace(/\.0$/, '')}` : '—')
                .fontSize(32).fontWeight(FontWeight.Bold).fontColor('#1F3D2F').margin({ top: 4 });
              Text(this.result!.value !== null ? this.result!.unit : '')
                .fontSize(11).fontColor('#7A8074');
              Text(this.result!.tier).fontSize(13).fontWeight(FontWeight.Bold)
                .fontColor(getTierColor(this.result!.tierClass))
                .backgroundColor(getTierBgColor(this.result!.tierClass))
                .borderRadius(20).padding({ left: 12, right: 12, top: 4, bottom: 4 }).margin({ top: 4 });
            }.alignItems(HorizontalAlign.Start).layoutWeight(1);
            Column() { Text(this.result!.footnote).fontSize(14).fontColor('#4A5247').lineHeight(22); }.layoutWeight(1).alignItems(HorizontalAlign.Start);
          }.width('100%');
        }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%');
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(16).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
