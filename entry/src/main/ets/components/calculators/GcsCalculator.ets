import { CalcResult , getTierColor, getTierBgColor } from '../../engine/CalcEngine';
import { calculateGcs } from '../../engine/GcsCalculator';

@Component
export struct GcsCalculator {  @State eye: number = 0;
  @State verbal: number = 0;
  @State motor: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateGcs(this.eye, this.verbal, this.motor); }

  build() {
    Column() {
      Column() { Text('用于评估意识障碍程度').fontSize(14).fontColor('#1F3D2F').fontWeight(FontWeight.Medium); Text('3维度：睁眼(E)+语言(V)+运动(M)，总分3-15，≤8重度').fontSize(12).fontColor('#7A8074').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Text('— 输入参数').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });

        Column() {
          Text('睁眼反应 E').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 8 });
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(['4自动', '3呼唤', '2刺激', '1无'], (item: string) => {
              Button(item).fontSize(13).fontWeight(FontWeight.Medium).fontColor(this.eye === parseInt(item[0]) ? '#FFFFFF' : '#2D5440')
                .backgroundColor(this.eye === parseInt(item[0]) ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.eye === parseInt(item[0]) ? '#1F3D2F' : '#E0E0E0' })
                .borderRadius(8).height(36).margin({ right: 8, bottom: 8 }).onClick(() => { this.eye = parseInt(item[0]); this.calculate(); });
            });
          }.width('100%');
        }.width('100%').margin({ bottom: 16 });

        Column() {
          Text('语言反应 V').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 8 });
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(['5正常', '4含糊', '3吐词', '2发音', '1无'], (item: string) => {
              Button(item).fontSize(13).fontWeight(FontWeight.Medium).fontColor(this.verbal === parseInt(item[0]) ? '#FFFFFF' : '#2D5440')
                .backgroundColor(this.verbal === parseInt(item[0]) ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.verbal === parseInt(item[0]) ? '#1F3D2F' : '#E0E0E0' })
                .borderRadius(8).height(36).margin({ right: 8, bottom: 8 }).onClick(() => { this.verbal = parseInt(item[0]); this.calculate(); });
            });
          }.width('100%');
        }.width('100%').margin({ bottom: 16 });

        Column() {
          Text('运动反应 M').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 8 });
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(['6遵嘱', '5定位', '4退缩', '3屈曲', '2伸直', '1无'], (item: string) => {
              Button(item).fontSize(13).fontWeight(FontWeight.Medium).fontColor(this.motor === parseInt(item[0]) ? '#FFFFFF' : '#2D5440')
                .backgroundColor(this.motor === parseInt(item[0]) ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.motor === parseInt(item[0]) ? '#1F3D2F' : '#E0E0E0' })
                .borderRadius(8).height(36).margin({ right: 8, bottom: 8 }).onClick(() => { this.motor = parseInt(item[0]); this.calculate(); });
            });
          }.width('100%');
        }.width('100%');
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() {
              Text('GCS').fontSize(12).fontColor('#7A8074').letterSpacing(1.5).fontWeight(FontWeight.Medium);
              Text(this.result!.value !== null ? `${this.result!.value!.toFixed(0)} ${this.result!.unit}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor('#1F3D2F').margin({ top: 8 });
              Text(this.result!.tier).fontSize(13).fontWeight(FontWeight.Bold).fontColor(getTierColor(this.result!.tierClass))
                .backgroundColor(getTierBgColor(this.result!.tierClass)).borderRadius(20).padding({ left: 12, right: 12, top: 4, bottom: 4 }).margin({ top: 8 });
            }.alignItems(HorizontalAlign.Start).layoutWeight(1);
            Column() { Text(this.result!.footnote).fontSize(14).fontColor('#4A5247').lineHeight(22); }.layoutWeight(1).alignItems(HorizontalAlign.Start);
          }.width('100%');
        }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%');
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(16).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
