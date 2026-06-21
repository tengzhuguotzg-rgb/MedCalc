import { CalcResult } from '../../engine/CalcEngine';
import { calculateHasbled } from '../../engine/MoreCalculators';

@Component
export struct HasbledCalculator {  @State htn: boolean = false;
  @State renal: boolean = false;
  @State liver: boolean = false;
  @State stroke: boolean = false;
  @State bleed: boolean = false;
  @State inr: boolean = false;
  @State age: boolean = false;
  @State drugs: boolean = false;
  @State alcohol: boolean = false;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateHasbled(this.htn, this.renal, this.liver, this.stroke, this.bleed, this.inr, this.age, this.drugs, this.alcohol); }

  build() {
    Column() {
      Column() { Text('用于评估房颤患者抗凝治疗出血风险').fontSize(14).fontColor('#1F3D2F').fontWeight(FontWeight.Medium); Text('7项：高血压+肾肝+卒中+出血+INR+年龄+药物/酒精，0-9分').fontSize(12).fontColor('#7A8074').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Text('— 输入参数').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });
        
        Row() { Text('H 高血压').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!this.htn ? '#FFFFFF' : '#2D5440').backgroundColor(!this.htn ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.htn ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.htn = false; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.htn ? '#FFFFFF' : '#2D5440').backgroundColor(this.htn ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.htn ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.htn = true; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('A 肾功能异常').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!this.renal ? '#FFFFFF' : '#2D5440').backgroundColor(!this.renal ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.renal ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.renal = false; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.renal ? '#FFFFFF' : '#2D5440').backgroundColor(this.renal ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.renal ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.renal = true; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('A 肝功能异常').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!this.liver ? '#FFFFFF' : '#2D5440').backgroundColor(!this.liver ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.liver ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.liver = false; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.liver ? '#FFFFFF' : '#2D5440').backgroundColor(this.liver ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.liver ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.liver = true; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('S 卒中史').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!this.stroke ? '#FFFFFF' : '#2D5440').backgroundColor(!this.stroke ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.stroke ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.stroke = false; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.stroke ? '#FFFFFF' : '#2D5440').backgroundColor(this.stroke ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.stroke ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.stroke = true; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('B 出血史').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!this.bleed ? '#FFFFFF' : '#2D5440').backgroundColor(!this.bleed ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.bleed ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.bleed = false; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.bleed ? '#FFFFFF' : '#2D5440').backgroundColor(this.bleed ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.bleed ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.bleed = true; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('L 不稳定 INR').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!this.inr ? '#FFFFFF' : '#2D5440').backgroundColor(!this.inr ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.inr ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.inr = false; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.inr ? '#FFFFFF' : '#2D5440').backgroundColor(this.inr ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.inr ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.inr = true; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('E 年龄 ≥ 65 岁').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!this.age ? '#FFFFFF' : '#2D5440').backgroundColor(!this.age ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.age ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.age = false; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.age ? '#FFFFFF' : '#2D5440').backgroundColor(this.age ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.age ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.age = true; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('D 药物').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!this.drugs ? '#FFFFFF' : '#2D5440').backgroundColor(!this.drugs ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.drugs ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.drugs = false; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.drugs ? '#FFFFFF' : '#2D5440').backgroundColor(this.drugs ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.drugs ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.drugs = true; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('D 酒精').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!this.alcohol ? '#FFFFFF' : '#2D5440').backgroundColor(!this.alcohol ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.alcohol ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.alcohol = false; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.alcohol ? '#FFFFFF' : '#2D5440').backgroundColor(this.alcohol ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.alcohol ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.alcohol = true; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() { Text('HAS-BLED 总分').fontSize(12).fontColor('#7A8074').letterSpacing(1.5).fontWeight(FontWeight.Medium);
              Text(this.result!.value !== null ? `${this.result!.value!.toFixed(0)}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor('#1F3D2F').margin({ top: 8 });
              Text(this.result!.tier).fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.result!.tierClass === 'tier-ok' ? '#3D6B4F' : this.result!.tierClass === 'tier-warn' ? '#C8881A' : '#B1452A')
                .backgroundColor(this.result!.tierClass === 'tier-ok' ? '#3D6B4F' : this.result!.tierClass === 'tier-warn' ? '#C8881A' : '#B1452A').borderRadius(20).padding({ left: 12, right: 12, top: 4, bottom: 4 }).margin({ top: 8 });
            }.alignItems(HorizontalAlign.Start).layoutWeight(1);
            Column() { Text(this.result!.footnote).fontSize(14).fontColor('#4A5247').lineHeight(22); }.layoutWeight(1).alignItems(HorizontalAlign.Start);
          }.width('100%');
        }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%');
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(16).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
