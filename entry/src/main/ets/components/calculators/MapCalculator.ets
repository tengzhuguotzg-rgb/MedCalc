import { CalcResult , getTierColor, getTierBgColor } from '../../engine/CalcEngine';
import { calculateMap } from '../../engine/MapCalculator';

@Component
export struct MapCalculator {  @State sbp: number = 0;
  @State dbp: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateMap(this.sbp, this.dbp); }

  build() {
    Column() {
      Column() { Text('用于计算平均动脉压，指导休克复苏').fontSize(14).fontColor('#1F3D2F').fontWeight(FontWeight.Medium); Text('MAP = 舒张压 + 1/3脉压差，SSC目标≥65mmHg').fontSize(12).fontColor('#7A8074').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Text('— 输入参数').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });
        Row() {
          Column() {
            Text('收缩压 SBP (mmHg)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 });
            TextInput({ placeholder: '请输入SBP' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421')
              .placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' })
              .padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.sbp = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1);
          Column() {
            Text('舒张压 DBP (mmHg)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 });
            TextInput({ placeholder: '请输入DBP' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421')
              .placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' })
              .padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.dbp = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1).margin({ left: 12 });
        }.width('100%');
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() {
              Text('MAP').fontSize(12).fontColor('#7A8074').letterSpacing(1.5).fontWeight(FontWeight.Medium);
              Text(this.result!.value !== null ? `${this.result!.value!.toFixed(1).replace(/\.0$/, '')} ${this.result!.unit}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor('#1F3D2F').margin({ top: 8 });
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
