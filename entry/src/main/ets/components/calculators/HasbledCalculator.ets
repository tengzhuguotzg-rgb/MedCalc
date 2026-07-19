import { CalcResult , getTierColor, getTierBgColor } from '../../engine/CalcEngine';
import { calculateHasbled } from '../../engine/MoreCalculators';

@Component
export struct HasbledCalculator {  @State htn: number = -1;
  @State renal: number = -1;
  @State liver: number = -1;
  @State stroke: number = -1;
  @State bleed: number = -1;
  @State inr: number = -1;
  @State age: number = -1;
  @State drugs: number = -1;
  @State alcohol: number = -1;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() {
    if (this.htn < 0 || this.renal < 0 || this.liver < 0 || this.stroke < 0 || this.bleed < 0 || this.inr < 0 || this.age < 0 || this.drugs < 0 || this.alcohol < 0) {
      this.result = { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
      return;
    }
    this.result = calculateHasbled(this.htn === 1, this.renal === 1, this.liver === 1, this.stroke === 1, this.bleed === 1, this.inr === 1, this.age === 1, this.drugs === 1, this.alcohol === 1);
  }

  build() {
    Column() {
      Column() { Text('用于评估房颤患者抗凝治疗出血风险').fontSize(14).fontColor('#1F3D2F').fontWeight(FontWeight.Medium); Text('7项：高血压+肾肝+卒中+出血+INR+年龄+药物/酒精，0-9分').fontSize(12).fontColor('#7A8074').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Text('— 输入参数').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });
        
        Row() { Text('H 高血压').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.htn === 0 ? '#FFFFFF' : '#2D5440').backgroundColor(this.htn === 0 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.htn === 0 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.htn = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.htn === 1 ? '#FFFFFF' : '#2D5440').backgroundColor(this.htn === 1 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.htn === 1 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.htn = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('A 肾功能异常').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.renal === 0 ? '#FFFFFF' : '#2D5440').backgroundColor(this.renal === 0 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.renal === 0 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.renal = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.renal === 1 ? '#FFFFFF' : '#2D5440').backgroundColor(this.renal === 1 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.renal === 1 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.renal = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('A 肝功能异常').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.liver === 0 ? '#FFFFFF' : '#2D5440').backgroundColor(this.liver === 0 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.liver === 0 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.liver = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.liver === 1 ? '#FFFFFF' : '#2D5440').backgroundColor(this.liver === 1 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.liver === 1 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.liver = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('S 卒中史').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.stroke === 0 ? '#FFFFFF' : '#2D5440').backgroundColor(this.stroke === 0 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.stroke === 0 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.stroke = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.stroke === 1 ? '#FFFFFF' : '#2D5440').backgroundColor(this.stroke === 1 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.stroke === 1 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.stroke = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('B 出血史').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.bleed === 0 ? '#FFFFFF' : '#2D5440').backgroundColor(this.bleed === 0 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.bleed === 0 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.bleed = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.bleed === 1 ? '#FFFFFF' : '#2D5440').backgroundColor(this.bleed === 1 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.bleed === 1 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.bleed = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('L 不稳定 INR').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.inr === 0 ? '#FFFFFF' : '#2D5440').backgroundColor(this.inr === 0 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.inr === 0 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.inr = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.inr === 1 ? '#FFFFFF' : '#2D5440').backgroundColor(this.inr === 1 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.inr === 1 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.inr = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('E 年龄 ≥ 65 岁').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.age === 0 ? '#FFFFFF' : '#2D5440').backgroundColor(this.age === 0 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.age === 0 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.age = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.age === 1 ? '#FFFFFF' : '#2D5440').backgroundColor(this.age === 1 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.age === 1 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.age = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('D 药物').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.drugs === 0 ? '#FFFFFF' : '#2D5440').backgroundColor(this.drugs === 0 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.drugs === 0 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.drugs = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.drugs === 1 ? '#FFFFFF' : '#2D5440').backgroundColor(this.drugs === 1 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.drugs === 1 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.drugs = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('D 酒精').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.alcohol === 0 ? '#FFFFFF' : '#2D5440').backgroundColor(this.alcohol === 0 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.alcohol === 0 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.alcohol = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.alcohol === 1 ? '#FFFFFF' : '#2D5440').backgroundColor(this.alcohol === 1 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.alcohol === 1 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.alcohol = 1; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() { Text('HAS-BLED 总分').fontSize(12).fontColor('#7A8074').letterSpacing(1.5).fontWeight(FontWeight.Medium);
              Text(this.result!.value !== null ? `${this.result!.value!.toFixed(0)}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor('#1F3D2F').margin({ top: 8 });
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
