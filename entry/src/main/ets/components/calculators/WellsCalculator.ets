import { CalcResult } from '../../engine/CalcEngine';
import { calculateWells } from '../../engine/WellsCalculator';

@Component
export struct WellsCalculator {  @State clinical: boolean = false;
  @State hr: boolean = false;
  @State surgery: boolean = false;
  @State hemoptysis: boolean = false;
  @State cancer: boolean = false;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateWells(this.clinical, this.hr, this.surgery, this.hemoptysis, this.cancer); }

  build() {
    Column() {
      Column() { Text('用于评估肺栓塞临床概率，指导D-二聚体解读').fontSize(14).fontColor('#1F3D2F').fontWeight(FontWeight.Medium); Text('7项：DVT症状+PE主诊断+心率+制动+咯血+肿瘤+其他').fontSize(12).fontColor('#7A8074').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Text('— 输入参数').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });

        Row() { Text('深静脉血栓临床表现').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!this.clinical ? '#FFFFFF' : '#2D5440').backgroundColor(!this.clinical ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.clinical ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.clinical = false; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.clinical ? '#FFFFFF' : '#2D5440').backgroundColor(this.clinical ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.clinical ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.clinical = true; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('心率>100次/分').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!this.hr ? '#FFFFFF' : '#2D5440').backgroundColor(!this.hr ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.hr ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.hr = false; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.hr ? '#FFFFFF' : '#2D5440').backgroundColor(this.hr ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.hr ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.hr = true; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('近期手术或制动').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!this.surgery ? '#FFFFFF' : '#2D5440').backgroundColor(!this.surgery ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.surgery ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.surgery = false; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.surgery ? '#FFFFFF' : '#2D5440').backgroundColor(this.surgery ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.surgery ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.surgery = true; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('咯血').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!this.hemoptysis ? '#FFFFFF' : '#2D5440').backgroundColor(!this.hemoptysis ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.hemoptysis ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.hemoptysis = false; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.hemoptysis ? '#FFFFFF' : '#2D5440').backgroundColor(this.hemoptysis ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.hemoptysis ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.hemoptysis = true; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('活动性癌症').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!this.cancer ? '#FFFFFF' : '#2D5440').backgroundColor(!this.cancer ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.cancer ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.cancer = false; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.cancer ? '#FFFFFF' : '#2D5440').backgroundColor(this.cancer ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.cancer ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.cancer = true; this.calculate(); });
          }.width(100);
        }.width('100%');
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() { Text('WELLS').fontSize(12).fontColor('#7A8074').letterSpacing(1.5).fontWeight(FontWeight.Medium);
              Text(this.result!.value !== null ? `${this.result!.value!.toFixed(1)} ${this.result!.unit}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor('#1F3D2F').margin({ top: 8 });
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
