import { CalcResult , getTierColor, getTierBgColor } from '../../engine/CalcEngine';
import { calculateCurb65 } from '../../engine/CommonCalculators';

@Component
export struct Curb65Calculator {
  @State resetKey: number = 0;  @State confusion: number = -1;
  @State urea: number = 0;
  @State ureaUnit: string = 'mmol';
  @State rr: number = 0;
  @State sbp: number = 0;
  @State dbp: number = 0;
  @State age: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    if (this.confusion < 0) {
      this.result = { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
      return;
    }
    this.result = calculateCurb65(this.confusion === 1, this.urea, this.ureaUnit, this.rr, this.sbp, this.dbp, this.age);
  }

  reset() {
    this.confusion = -1;
    this.urea = 0;
    this.ureaUnit = 'mmol';
    this.rr = 0;
    this.sbp = 0;
    this.dbp = 0;
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
      Column() { Text('用于评估社区获得性肺炎严重程度及住院决策').fontSize(14).fontColor('#1F3D2F').fontWeight(FontWeight.Medium); Text('5项：意识+BUN+呼吸+血压+年龄≥65，0-5分').fontSize(12).fontColor('#7A8074').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Row() { Text('— 输入参数').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor('#7A8074').onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });
        
        Row() {
          Text('C 意识混乱').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() {
            Button('否').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.confusion === 0 ? '#FFFFFF' : '#2D5440')
              .backgroundColor(this.confusion === 0 ? '#1F3D2F' : '#F5F5F5').borderRadius(8).border({ width: 1, color: this.confusion === 0 ? '#1F3D2F' : '#E0E0E0' }).layoutWeight(1)
              .onClick(() => { this.confusion = 0; this.calculate(); });
            Button('是').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.confusion === 1 ? '#FFFFFF' : '#2D5440')
              .backgroundColor(this.confusion === 1 ? '#1F3D2F' : '#F5F5F5').borderRadius(8).border({ width: 1, color: this.confusion === 1 ? '#1F3D2F' : '#E0E0E0' }).layoutWeight(1)
              .onClick(() => { this.confusion = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 8 });

        Row() {
          Column() {
            Text('尿素氮').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
            TextInput({ placeholder: 'Urea' }).type(InputType.Number).height(40).fontSize(16).backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).placeholderColor('#999999')
              .onChange((value: string) => { this.urea = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1);
          Column() {
            Text('呼吸频率').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
            TextInput({ placeholder: 'RR' }).type(InputType.Number).height(40).fontSize(16).backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).placeholderColor('#999999')
              .onChange((value: string) => { this.rr = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 8 });

        Row() {
          Column() {
            Text('收缩压 SBP').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
            TextInput({ placeholder: 'SBP' }).type(InputType.Number).height(40).fontSize(16).backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).placeholderColor('#999999')
              .onChange((value: string) => { this.sbp = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1);
          Column() {
            Text('舒张压 DBP').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
            TextInput({ placeholder: 'DBP' }).type(InputType.Number).height(40).fontSize(16).backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).placeholderColor('#999999')
              .onChange((value: string) => { this.dbp = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 8 });

        Column() {
          Text('年龄').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
          TextInput({ placeholder: '年龄' }).type(InputType.Number).height(40).fontSize(16).backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).placeholderColor('#999999')
            .onChange((value: string) => { this.age = parseFloat(value) || 0; this.calculate(); });
        }.width('100%');
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() {
              Text('CURB-65 Total').fontSize(10).fontColor('#7A8074').letterSpacing(1.5);
              Text(this.result!.value !== null ? `${this.result!.value!.toFixed(0)}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor('#1F3D2F').margin({ top: 4 });
              Text(this.result!.tier).fontSize(13).fontWeight(FontWeight.Bold)
                .fontColor(getTierColor(this.result!.tierClass))
                .backgroundColor(getTierBgColor(this.result!.tierClass))
                .borderRadius(20).padding({ left: 12, right: 12, top: 4, bottom: 4 }).margin({ top: 4 });
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
