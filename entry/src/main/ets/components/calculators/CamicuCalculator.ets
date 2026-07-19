import { CalcResult, getTierColor, getTierBgColor } from '../../engine/CalcEngine';
import { calculateCamicu } from '../../engine/CamicuCalculator';

@Component
export struct CamicuCalculator {
  @State f1: number = -1;
  @State f2: number = -1;
  @State f3: number = -1;
  @State f4: number = -1;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateCamicu(this.f1, this.f2, this.f3, this.f4); }

  build() {
    Column() {
      Column() { Text('用于ICU谵妄筛查金标准').fontSize(14).fontColor('#1F3D2F').fontWeight(FontWeight.Medium); Text('4 步法 · 特征①+②+(③或④) (Ely 2001)').fontSize(12).fontColor('#7A8074').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Text('— 评估特征').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });

        Column() {
          Text('① 意识状态急性改变或波动').fontSize(13).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
          Row() {
            Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.f1 === 0 ? '#FFFFFF' : '#2D5440').backgroundColor(this.f1 === 0 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.f1 === 0 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).layoutWeight(1).onClick(() => { this.f1 = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.f1 === 1 ? '#FFFFFF' : '#2D5440').backgroundColor(this.f1 === 1 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.f1 === 1 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).layoutWeight(1).margin({ left: 4 }).onClick(() => { this.f1 = 1; this.calculate(); });
          }.width('100%');
          Text('基线GCS与当前不同? 或过去24h内意识波动?').fontSize(10).fontColor('#7A8074').margin({ top: 2, bottom: 8 });
        }.width('100%');

        Column() {
          Text('② 注意力缺损').fontSize(13).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
          Row() {
            Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.f2 === 0 ? '#FFFFFF' : '#2D5440').backgroundColor(this.f2 === 0 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.f2 === 0 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).layoutWeight(1).onClick(() => { this.f2 = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.f2 === 1 ? '#FFFFFF' : '#2D5440').backgroundColor(this.f2 === 1 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.f2 === 1 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).layoutWeight(1).margin({ left: 4 }).onClick(() => { this.f2 = 1; this.calculate(); });
          }.width('100%');
          Text('ASE法: 说"S-A-V-E-A-H-A-R-T", 听到"A"握手, ≥3次误答=异常').fontSize(10).fontColor('#7A8074').margin({ top: 2, bottom: 8 });
        }.width('100%');

        Column() {
          Text('③ 意识水平改变 (RASS ≠ 0)').fontSize(13).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
          Row() {
            Button('RASS=0 (清醒)').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.f3 === 0 ? '#FFFFFF' : '#2D5440').backgroundColor(this.f3 === 0 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.f3 === 0 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).layoutWeight(1).onClick(() => { this.f3 = 0; this.calculate(); });
            Button('RASS≠0').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.f3 === 1 ? '#FFFFFF' : '#2D5440').backgroundColor(this.f3 === 1 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.f3 === 1 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).layoutWeight(1).margin({ left: 4 }).onClick(() => { this.f3 = 1; this.calculate(); });
          }.width('100%').margin({ bottom: 8 });
        }.width('100%');

        Column() {
          Text('④ 思维紊乱').fontSize(13).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
          Row() {
            Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.f4 === 0 ? '#FFFFFF' : '#2D5440').backgroundColor(this.f4 === 0 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.f4 === 0 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).layoutWeight(1).onClick(() => { this.f4 = 0; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.f4 === 1 ? '#FFFFFF' : '#2D5440').backgroundColor(this.f4 === 1 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.f4 === 1 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).layoutWeight(1).margin({ left: 4 }).onClick(() => { this.f4 = 1; this.calculate(); });
          }.width('100%');
          Text('是非题(石头会浮吗?) + 指令评估').fontSize(10).fontColor('#7A8074').margin({ top: 2 });
        }.width('100%');
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() {
              Text('CAM-ICU').fontSize(10).fontColor('#7A8074').letterSpacing(1.5);
              Text(this.result!.value !== null ? (this.result!.value === 1 ? '阳性' : '阴性') : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor('#1F3D2F').margin({ top: 8 });
              Text(this.result!.tier).fontSize(13).fontWeight(FontWeight.Bold).fontColor(getTierColor(this.result!.tierClass)).backgroundColor(getTierBgColor(this.result!.tierClass)).borderRadius(20).padding({ left: 12, right: 12, top: 4, bottom: 4 }).margin({ top: 8 });
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
