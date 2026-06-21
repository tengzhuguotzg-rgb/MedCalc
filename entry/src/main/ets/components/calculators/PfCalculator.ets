import { CalcResult } from '../../engine/CalcEngine';
import { calculatePf } from '../../engine/CommonCalculators';

@Component
export struct PfCalculator {
  @State pao2: number = 0;
  @State fio2: number = 0;
  @State fio2Mode: string = 'dec';
  @State peep: number | null = null;
  @State peepText: string = '';
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculatePf(this.pao2, this.fio2, this.fio2Mode, this.peep); }

  build() {
    Column() {
      Column() { Text('P/F 氧合指数').fontSize(17).fontWeight(FontWeight.Bold).fontColor('#1F3D2F'); Text('PaO₂/FiO₂, ARDS 诊断金标准 (Berlin 2012)').fontSize(11.5).fontColor('#4A5247').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Text('— 输入参数').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });

        Row() {
          Column() { Text('PaO₂ (mmHg)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '请输入PaO2' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.pao2 = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1);
          Column() { Text('FiO₂').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 });           TextInput({ placeholder: this.fio2Mode === 'dec' ? '小数(0.21-1.0)' : '百分比(21-100)' }).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.fio2 = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 16 });

        Row() {
          Button('小数').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.fio2Mode === 'dec' ? '#FFFFFF' : '#2D5440').backgroundColor(this.fio2Mode === 'dec' ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.fio2Mode === 'dec' ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.fio2Mode = 'dec'; this.calculate(); });
          Button('百分比').fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.fio2Mode === 'pct' ? '#FFFFFF' : '#2D5440').backgroundColor(this.fio2Mode === 'pct' ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.fio2Mode === 'pct' ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.fio2Mode = 'pct'; this.calculate(); });
        }.width('100%').margin({ bottom: 16 });

        Column() { Text('PEEP (cmH₂O, 可选)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '建议≥5, 未填则不评估' }).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { const v = parseFloat(value); this.peep = isNaN(v) ? null : v; this.calculate(); }); }.width('100%');
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() { Text('P/F').fontSize(12).fontColor('#7A8074').letterSpacing(1.5).fontWeight(FontWeight.Medium); Text(this.result!.value !== null ? `${this.result!.value!.toFixed(1).replace(/\.0$/, '')} ${this.result!.unit}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor('#1F3D2F').margin({ top: 8 }); Text(this.result!.tier).fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.result!.tierClass === 'tier-ok' ? '#3D6B4F' : this.result!.tierClass === 'tier-warn' ? '#C8881A' : '#B1452A').backgroundColor(this.result!.tierClass === 'tier-ok' ? '#E8F0EC' : this.result!.tierClass === 'tier-warn' ? '#F5EFE0' : '#F5E4E0').borderRadius(20).padding({ left: 12, right: 12, top: 4, bottom: 4 }).margin({ top: 8 }); }.alignItems(HorizontalAlign.Start).layoutWeight(1);
            Column() { Text(this.result!.footnote).fontSize(14).fontColor('#4A5247').lineHeight(22); }.layoutWeight(1).alignItems(HorizontalAlign.Start);
          }.width('100%');
        }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%');
      }
    }.width('100%').padding(16);
  }
}
