import { CalcResult } from '../../engine/CalcEngine';
import { calculateChadsvasc } from '../../engine/MoreCalculators';

@Component
export struct ChadsvascCalculator {  @State chf: boolean = false;
  @State htn: boolean = false;
  @State age75: boolean = false;
  @State dm: boolean = false;
  @State stroke: boolean = false;
  @State vasc: boolean = false;
  @State age65: boolean = false;
  @State female: boolean = false;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateChadsvasc(this.chf, this.htn, this.age75, this.dm, this.stroke, this.vasc, this.age65, this.female); }

  build() {
    Column() {
      Column() { Text('用于评估房颤患者脑卒中风险，指导抗凝决策').fontSize(14).fontColor('#1F3D2F').fontWeight(FontWeight.Medium); Text('8项：心衰+高血压+年龄+糖尿病+卒中+血管病+性别，总分0-9').fontSize(12).fontColor('#7A8074').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Text('— 输入参数').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });
        
        Row() { Text('C 心衰').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!this.chf ? '#FFFFFF' : '#2D5440').backgroundColor(!this.chf ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.chf ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.chf = false; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.chf ? '#FFFFFF' : '#2D5440').backgroundColor(this.chf ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.chf ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.chf = true; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('H 高血压').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!this.htn ? '#FFFFFF' : '#2D5440').backgroundColor(!this.htn ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.htn ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.htn = false; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.htn ? '#FFFFFF' : '#2D5440').backgroundColor(this.htn ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.htn ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.htn = true; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('A₂ 年龄 ≥ 75 岁').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!this.age75 ? '#FFFFFF' : '#2D5440').backgroundColor(!this.age75 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.age75 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.age75 = false; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.age75 ? '#FFFFFF' : '#2D5440').backgroundColor(this.age75 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.age75 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.age75 = true; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('D 糖尿病').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!this.dm ? '#FFFFFF' : '#2D5440').backgroundColor(!this.dm ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.dm ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.dm = false; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.dm ? '#FFFFFF' : '#2D5440').backgroundColor(this.dm ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.dm ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.dm = true; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('S₂ 卒中/TIA/血栓史').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!this.stroke ? '#FFFFFF' : '#2D5440').backgroundColor(!this.stroke ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.stroke ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.stroke = false; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.stroke ? '#FFFFFF' : '#2D5440').backgroundColor(this.stroke ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.stroke ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.stroke = true; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('V 血管疾病').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!this.vasc ? '#FFFFFF' : '#2D5440').backgroundColor(!this.vasc ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.vasc ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.vasc = false; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.vasc ? '#FFFFFF' : '#2D5440').backgroundColor(this.vasc ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.vasc ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.vasc = true; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('A 年龄 65-74 岁').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!this.age65 ? '#FFFFFF' : '#2D5440').backgroundColor(!this.age65 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.age65 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.age65 = false; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.age65 ? '#FFFFFF' : '#2D5440').backgroundColor(this.age65 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.age65 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.age65 = true; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
        
        Row() { Text('Sc 女性').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!this.female ? '#FFFFFF' : '#2D5440').backgroundColor(!this.female ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.female ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.female = false; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.female ? '#FFFFFF' : '#2D5440').backgroundColor(this.female ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.female ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.female = true; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() { Text('CHADS₂-VASc 总分').fontSize(12).fontColor('#7A8074').letterSpacing(1.5).fontWeight(FontWeight.Medium); Text(this.result!.value !== null ? `${this.result!.value!.toFixed(0)}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor('#1F3D2F').margin({ top: 8 }); Text(this.result!.tier).fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.result!.tierClass === 'tier-ok' ? '#3D6B4F' : this.result!.tierClass === 'tier-warn' ? '#C8881A' : '#B1452A').backgroundColor(this.result!.tierClass === 'tier-ok' ? '#3D6B4F' : this.result!.tierClass === 'tier-warn' ? '#C8881A' : '#B1452A').borderRadius(20).padding({ left: 12, right: 12, top: 4, bottom: 4 }).margin({ top: 8 }); }.alignItems(HorizontalAlign.Start).layoutWeight(1);
            Column() { Text(this.result!.footnote).fontSize(14).fontColor('#4A5247').lineHeight(22); }.layoutWeight(1).alignItems(HorizontalAlign.Start);
          }.width('100%');
        }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%');
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(16).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
