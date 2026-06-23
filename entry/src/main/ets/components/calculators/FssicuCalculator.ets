import { CalcResult, getTierColor, getTierBgColor } from '../../engine/CalcEngine';
import { calculateFssicu } from '../../engine/FssicuCalculator';

@Component
export struct FssicuCalculator {
  @State roll: number = 1;
  @State situp: number = 1;
  @State sit: number = 1;
  @State standup: number = 1;
  @State stand: number = 1;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateFssicu(this.roll, this.situp, this.sit, this.standup, this.stand); }

  itemLabel(val: number): string {
    const labels = ['0 无法', '1 完全帮助', '2 最大帮助', '3 中度帮助', '4 最小帮助', '5 监护', '6 独立(需辅)', '7 完全独立'];
    return labels[val] || '';
  }

  build() {
    Column() {
      Column() { Text('用于 ICU 患者功能状态评估').fontSize(14).fontColor('#1F3D2F').fontWeight(FontWeight.Medium); Text('5 项各 0-7, 总分 0-35 (Thrush 2012)').fontSize(12).fontColor('#7A8074').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Text('— 评分标准: 0=无法 · 1=完全帮助 · 2=最大帮助 · 3=中度帮助 · 4=最小帮助 · 5=监护 · 6=独立(需辅) · 7=完全独立').fontSize(10).fontColor('#7A8074').margin({ bottom: 12 });

        this.FssItem('① 翻身 (仰卧→侧卧)', this.roll, (v: number) => { this.roll = v; this.calculate(); });
        this.FssItem('② 卧位→坐位', this.situp, (v: number) => { this.situp = v; this.calculate(); });
        this.FssItem('③ 床缘静坐平衡', this.sit, (v: number) => { this.sit = v; this.calculate(); });
        this.FssItem('④ 坐位→站立', this.standup, (v: number) => { this.standup = v; this.calculate(); });
        this.FssItem('⑤ 站立平衡', this.stand, (v: number) => { this.stand = v; this.calculate(); });
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() {
              Text('FSS-ICU').fontSize(10).fontColor('#7A8074').letterSpacing(1.5);
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

  @Builder
  FssItem(label: string, value: number, onChange: (v: number) => void) {
    Column() {
      Text(label).fontSize(13).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
      Row() {
        ForEach([0, 1, 2, 3, 4, 5, 6, 7], (item: number) => {
          Button(`${item}`).fontSize(12).fontWeight(FontWeight.Bold).fontColor(value === item ? '#FFFFFF' : '#2D5440')
            .backgroundColor(value === item ? '#1F3D2F' : '#F5F5F5')
            .border({ width: 1, color: value === item ? '#1F3D2F' : '#E0E0E0' })
            .borderRadius(6).height(32).width(32).margin({ right: 3, bottom: 4 })
            .onClick(() => { onChange(item); });
        }, (item: number) => item.toString());
      }.width('100%');
    }.width('100%').margin({ bottom: 10 });
  }
}
