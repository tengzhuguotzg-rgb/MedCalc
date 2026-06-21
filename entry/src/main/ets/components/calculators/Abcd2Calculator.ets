import { CalcResult } from '../../engine/CalcEngine';
import { calculateAbcd2 } from '../../engine/MoreCalculators2';

@Component
export struct Abcd2Calculator {  @State age: boolean = false;
  @State bp: boolean = false;
  @State clin: number = 0;
  @State dur: number = 0;
  @State dm: boolean = false;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateAbcd2(this.age, this.bp, this.clin, this.dur, this.dm); }

  build() {
    Column() {
      Column() { Text('用于评估TIA后短期脑卒中风险').fontSize(14).fontColor('#1F3D2F').fontWeight(FontWeight.Medium); Text('5项：年龄+血压+临床表现+持续时间+糖尿病，总分0-7').fontSize(12).fontColor('#7A8074').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });
      Column() {
        Text('— 输入参数').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });
        this.OptionRow('A 年龄 ≥ 60 岁', this.age, (v: boolean) => { this.age = v; this.calculate(); });
        this.OptionRow('B 血压 ≥ 140/90', this.bp, (v: boolean) => { this.bp = v; this.calculate(); });
        Column() {
          Text('C 临床特征').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 8 });
          Row() {
            Button('其他').fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.clin === 0 ? '#FFFFFF' : '#2D5440').backgroundColor(this.clin === 0 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.clin === 0 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.clin = 0; this.calculate(); });
            Button('言语').fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.clin === 1 ? '#FFFFFF' : '#2D5440').backgroundColor(this.clin === 1 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.clin === 1 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).margin({ left: 8 }).onClick(() => { this.clin = 1; this.calculate(); });
            Button('无力').fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.clin === 2 ? '#FFFFFF' : '#2D5440').backgroundColor(this.clin === 2 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.clin === 2 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).margin({ left: 8 }).onClick(() => { this.clin = 2; this.calculate(); });
          }.width('100%');
        }.width('100%').alignItems(HorizontalAlign.Start).margin({ bottom: 12 });
        Column() {
          Text('D 持续时间').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 8 });
          Row() {
            Button('<10min').fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.dur === 0 ? '#FFFFFF' : '#2D5440').backgroundColor(this.dur === 0 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.dur === 0 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.dur = 0; this.calculate(); });
            Button('10-59min').fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.dur === 1 ? '#FFFFFF' : '#2D5440').backgroundColor(this.dur === 1 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.dur === 1 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).margin({ left: 8 }).onClick(() => { this.dur = 1; this.calculate(); });
            Button('≥60min').fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.dur === 2 ? '#FFFFFF' : '#2D5440').backgroundColor(this.dur === 2 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.dur === 2 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).margin({ left: 8 }).onClick(() => { this.dur = 2; this.calculate(); });
          }.width('100%');
        }.width('100%').alignItems(HorizontalAlign.Start).margin({ bottom: 12 });
        this.OptionRow('D 糖尿病', this.dm, (v: boolean) => { this.dm = v; this.calculate(); });
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });
      if (this.result) { Column() { Row() {
        Column() { Text('ABCD² Total').fontSize(12).fontColor('#7A8074').letterSpacing(1.5).fontWeight(FontWeight.Medium);
          Text(this.result!.value !== null ? `${this.result!.value!.toFixed(0)}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor('#1F3D2F').margin({ top: 8 });
          Text(this.result!.tier).fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.result!.tierClass === 'tier-ok' ? '#3D6B4F' : this.result!.tierClass === 'tier-warn' ? '#C8881A' : '#B1452A')
            .backgroundColor(this.result!.tierClass === 'tier-ok' ? '#3D6B4F' : this.result!.tierClass === 'tier-warn' ? '#C8881A' : '#B1452A').borderRadius(20).padding({ left: 12, right: 12, top: 4, bottom: 4 }).margin({ top: 8 });
        }.alignItems(HorizontalAlign.Start).layoutWeight(1);
        Column() { Text(this.result!.footnote).fontSize(14).fontColor('#4A5247').lineHeight(22); }.layoutWeight(1).alignItems(HorizontalAlign.Start);
      }.width('100%'); }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%'); }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(16).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }

  @Builder OptionRow(label: string, value: boolean, onChange: (v: boolean) => void) {
    Row() { Text(label).fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
      Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!value ? '#FFFFFF' : '#2D5440').backgroundColor(!value ? '#1F3D2F' : '#F5F5F5').border({ width: !value ? 0 : 1, color: '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => onChange(false));
        Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(value ? '#FFFFFF' : '#2D5440').backgroundColor(value ? '#1F3D2F' : '#F5F5F5').border({ width: value ? 0 : 1, color: '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => onChange(true));
      }.width(100);
    }.width('100%').margin({ bottom: 12 });
  }
}
