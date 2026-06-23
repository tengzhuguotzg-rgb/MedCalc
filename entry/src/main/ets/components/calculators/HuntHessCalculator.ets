import { CalcResult , getTierColor, getTierBgColor } from '../../engine/CalcEngine';
import { calculateHuntHess, calculateWfns, calculateFisher } from '../../engine/HuntHessCalculator';

@Component
export struct HuntHessCalculator {  @State grade: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateHuntHess(this.grade); }

  build() {
    Column() {
      Column() { Text('用于蛛网膜下腔出血手术风险分层').fontSize(14).fontColor('#1F3D2F').fontWeight(FontWeight.Medium); Text('0-5级，基于临床症状严重程度').fontSize(12).fontColor('#7A8074').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Text('— 选择分级').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach([0, 1, 2, 3, 4, 5], (item: number) => {
            Button(`${item}`).fontSize(15).fontWeight(FontWeight.Bold).fontColor(this.grade === item ? '#FFFFFF' : '#2D5440')
              .backgroundColor(this.grade === item ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.grade === item ? '#1F3D2F' : '#E0E0E0' })
              .borderRadius(8).height(40).width(60).margin({ right: 8, bottom: 8 }).onClick(() => { this.grade = item; this.calculate(); });
          });
        }.width('100%');
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() { Text('Hunt-Hess').fontSize(12).fontColor('#7A8074').letterSpacing(1.5).fontWeight(FontWeight.Medium);
              Text(this.result!.value !== null ? `${this.result!.value} ${this.result!.unit}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor('#1F3D2F').margin({ top: 8 });
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

@Component
export struct WfnsCalculator {
  @State grade: number = -1;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateWfns(this.grade); }

  build() {
    Column() {
      Column() { Text('用于蛛网膜下腔出血临床分级及预后评估').fontSize(14).fontColor('#1F3D2F').fontWeight(FontWeight.Medium); Text('I-V级，基于GCS和局灶体征').fontSize(12).fontColor('#7A8074').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Text('— 选择分级').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach([1, 2, 3, 4, 5], (item: number) => {
            Button(`${item}`).fontSize(15).fontWeight(FontWeight.Bold).fontColor(this.grade === item ? '#FFFFFF' : '#2D5440')
              .backgroundColor(this.grade === item ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.grade === item ? '#1F3D2F' : '#E0E0E0' })
              .borderRadius(8).height(40).width(60).margin({ right: 8, bottom: 8 }).onClick(() => { this.grade = item; this.calculate(); });
          });
        }.width('100%');
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() { Text('WFNS').fontSize(12).fontColor('#7A8074').letterSpacing(1.5).fontWeight(FontWeight.Medium);
              Text(this.result!.value !== null ? `${this.result!.value} ${this.result!.unit}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor('#1F3D2F').margin({ top: 8 });
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

@Component
export struct FisherCalculator {
  @State grade: number = -1;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateFisher(this.grade); }

  build() {
    Column() {
      Column() { Text('用于预测蛛网膜下腔出血后脑血管痉挛风险').fontSize(14).fontColor('#1F3D2F').fontWeight(FontWeight.Medium); Text('1-4级，基于CT出血量').fontSize(12).fontColor('#7A8074').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Text('— 选择分级').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach([1, 2, 3, 4], (item: number) => {
            Button(`${item}`).fontSize(15).fontWeight(FontWeight.Bold).fontColor(this.grade === item ? '#FFFFFF' : '#2D5440')
              .backgroundColor(this.grade === item ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.grade === item ? '#1F3D2F' : '#E0E0E0' })
              .borderRadius(8).height(40).width(60).margin({ right: 8, bottom: 8 }).onClick(() => { this.grade = item; this.calculate(); });
          });
        }.width('100%');
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() { Text('Fisher').fontSize(12).fontColor('#7A8074').letterSpacing(1.5).fontWeight(FontWeight.Medium);
              Text(this.result!.value !== null ? `${this.result!.value} ${this.result!.unit}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor('#1F3D2F').margin({ top: 8 });
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
