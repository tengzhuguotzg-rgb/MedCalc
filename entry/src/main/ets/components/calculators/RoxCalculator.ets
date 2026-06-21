import { CalcResult } from '../../engine/CalcEngine';
import { calculateRox } from '../../engine/MoreCalculators';

@Component
export struct RoxCalculator {  @State spo2: number = 0;
  @State fio2: number = 0;
  @State fio2Mode: string = 'dec';
  @State rr: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateRox(this.spo2, this.fio2, this.fio2Mode, this.rr); }

  build() {
    Column() {
      Column() { Text('用于预测高流量氧疗(HFNC)失败风险').fontSize(14).fontColor('#1F3D2F').fontWeight(FontWeight.Medium); Text('ROX = SpO₂/(FiO₂×RR)，Roca 2016').fontSize(12).fontColor('#7A8074').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Text('— 输入参数').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });
        Row() {
          Column() {
            Text('SpO₂ (%)').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
            TextInput({ placeholder: 'SpO2' }).type(InputType.Number).height(40).fontSize(16).backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).placeholderColor('#999999')
              .onChange((value: string) => { this.spo2 = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1);
          Column() {
            Text('FiO₂').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
            TextInput({ placeholder: 'FiO2' }).height(40).fontSize(16).backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).placeholderColor('#999999')
              .onChange((value: string) => { this.fio2 = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 8 });
        
        Column() {
          Text('呼吸频率 RR (次/分)').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
          TextInput({ placeholder: 'RR' }).type(InputType.Number).height(40).fontSize(16).backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).placeholderColor('#999999')
            .onChange((value: string) => { this.rr = parseFloat(value) || 0; this.calculate(); });
        }.width('100%');
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() {
              Text('ROX').fontSize(10).fontColor('#7A8074').letterSpacing(1.5);
              Text(this.result!.value !== null ? `${this.result!.value!.toFixed(2)}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor('#1F3D2F').margin({ top: 4 });
              Text(this.result!.tier).fontSize(13).fontWeight(FontWeight.Bold)
                .fontColor(this.result!.tierClass === 'tier-ok' ? '#3D6B4F' : this.result!.tierClass === 'tier-warn' ? '#C8881A' : '#B1452A')
                .backgroundColor(this.result!.tierClass === 'tier-ok' ? '#3D6B4F' : this.result!.tierClass === 'tier-warn' ? '#C8881A' : '#B1452A')
                .borderRadius(20).padding({ left: 12, right: 12, top: 4, bottom: 4 }).margin({ top: 4 });
            }.alignItems(HorizontalAlign.Start).layoutWeight(1);
            
          }.width('100%');
        }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%');
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(16).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
