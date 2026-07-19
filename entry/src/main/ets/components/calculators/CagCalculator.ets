import { CalcResult , getTierColor, getTierBgColor } from '../../engine/CalcEngine';
import { calculateCag } from '../../engine/MoreCalculators';

@Component
export struct CagCalculator {
  @State resetKey: number = 0;  @State na: number = 0;
  @State cl: number = 0;
  @State hco3: number = 0;
  @State alb: number = 0;
  @State albUnit: string = 'gl';
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateCag(this.na, this.cl, this.hco3, this.alb, this.albUnit); }

  reset() {
    this.na = 0;
    this.cl = 0;
    this.hco3 = 0;
    this.alb = 0;
    this.albUnit = 'gl';
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
      Column() { Text('用于校正低蛋白血症时的阴离子间隙').fontSize(14).fontColor('#1F3D2F').fontWeight(FontWeight.Medium); Text('校正AG = 计算AG + 2.5×(4 - 白蛋白g/dL)，低蛋白时必校').fontSize(12).fontColor('#7A8074').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Row() { Text('— 电解质').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor('#7A8074').onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });
        Row() {
          Column() {
            Text('Na⁺ (mmol/L)').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
            TextInput({ placeholder: 'Na' }).type(InputType.Number).height(40).fontSize(16).backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).placeholderColor('#999999')
              .onChange((value: string) => { this.na = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1);
          Column() {
            Text('Cl⁻ (mmol/L)').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
            TextInput({ placeholder: 'Cl' }).type(InputType.Number).height(40).fontSize(16).backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).placeholderColor('#999999')
              .onChange((value: string) => { this.cl = parseFloat(value) || 0; this.calculate(); });
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 8 });
        
        Column() {
          Text('HCO₃⁻ (mmol/L)').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
          TextInput({ placeholder: 'HCO3' }).type(InputType.Number).height(40).fontSize(16).backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).placeholderColor('#999999')
            .onChange((value: string) => { this.hco3 = parseFloat(value) || 0; this.calculate(); });
        }.width('100%').margin({ bottom: 8 });

        Column() {
          Text('血清白蛋白').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
          Row() {
            TextInput({ placeholder: '白蛋白' }).type(InputType.Number).height(40).fontSize(16).backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).placeholderColor('#999999').layoutWeight(1)
              .onChange((value: string) => { this.alb = parseFloat(value) || 0; this.calculate(); });
            Row() {
              Button('g/L').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.albUnit === 'gl' ? '#FFFFFF' : '#2D5440')
                .backgroundColor(this.albUnit === 'gl' ? '#1F3D2F' : '#F5F5F5').borderRadius(8).border({ width: 1, color: this.albUnit === 'gl' ? '#1F3D2F' : '#E0E0E0' })
                .onClick(() => { this.albUnit = 'gl'; this.calculate(); });
              Button('g/dL').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.albUnit === 'gdl' ? '#FFFFFF' : '#2D5440')
                .backgroundColor(this.albUnit === 'gdl' ? '#1F3D2F' : '#F5F5F5').borderRadius(8).border({ width: 1, color: this.albUnit === 'gdl' ? '#1F3D2F' : '#E0E0E0' })
                .onClick(() => { this.albUnit = 'gdl'; this.calculate(); });
            }.margin({ left: 4 });
          }.width('100%');
        }.width('100%');
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() {
              Text('校正 AG').fontSize(10).fontColor('#7A8074').letterSpacing(1.5);
              Text(this.result!.value !== null ? `${this.result!.value!.toFixed(1)} ${this.result!.unit}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor('#1F3D2F').margin({ top: 4 });
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
