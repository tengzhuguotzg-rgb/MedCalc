import { CalcResult } from '../../engine/CalcEngine';
import { calculateHuntHess, calculateWfns, calculateFisher } from '../../engine/HuntHessCalculator';

@Component
export struct HuntHessCalculator {
  @State grade: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateHuntHess(this.grade); }

  build() {
    Column() {
      Column() { Text('Hunt-Hess 分级').fontSize(17).fontWeight(FontWeight.Bold).fontColor('#1F3D2F'); Text('SAH 手术风险分层 (Hunt 1968)').fontSize(11.5).fontColor('#4A5247').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

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
              Text(this.result!.tier).fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.result!.tierClass === 'tier-ok' ? '#3D6B4F' : this.result!.tierClass === 'tier-warn' ? '#C8881A' : '#B1452A')
                .backgroundColor(this.result!.tierClass === 'tier-ok' ? '#E8F0EC' : this.result!.tierClass === 'tier-warn' ? '#F5EFE0' : '#F5E4E0').borderRadius(20).padding({ left: 12, right: 12, top: 4, bottom: 4 }).margin({ top: 8 });
            }.alignItems(HorizontalAlign.Start).layoutWeight(1);
            Column() { Text(this.result!.footnote).fontSize(14).fontColor('#4A5247').lineHeight(22); }.layoutWeight(1).alignItems(HorizontalAlign.Start);
          }.width('100%');
        }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%');
      }
    }.width('100%').padding(16);
  }
}

@Component
export struct WfnsCalculator {
  @State grade: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateWfns(this.grade); }

  build() {
    Column() {
      Column() { Text('WFNS 分级').fontSize(17).fontWeight(FontWeight.Bold).fontColor('#1F3D2F'); Text('SAH 临床分级 · GCS + 运动缺陷 (WFNS 1988)').fontSize(11.5).fontColor('#4A5247').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

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
            Column() { Text('WFNS').fontSize(12).fontColor('#7A8074').letterSpacing(1.5).fontWeight(FontWeight.Medium);
              Text(this.result!.value !== null ? `${this.result!.value} ${this.result!.unit}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor('#1F3D2F').margin({ top: 8 });
              Text(this.result!.tier).fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.result!.tierClass === 'tier-ok' ? '#3D6B4F' : this.result!.tierClass === 'tier-warn' ? '#C8881A' : '#B1452A')
                .backgroundColor(this.result!.tierClass === 'tier-ok' ? '#E8F0EC' : this.result!.tierClass === 'tier-warn' ? '#F5EFE0' : '#F5E4E0').borderRadius(20).padding({ left: 12, right: 12, top: 4, bottom: 4 }).margin({ top: 8 });
            }.alignItems(HorizontalAlign.Start).layoutWeight(1);
            Column() { Text(this.result!.footnote).fontSize(14).fontColor('#4A5247').lineHeight(22); }.layoutWeight(1).alignItems(HorizontalAlign.Start);
          }.width('100%');
        }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%');
      }
    }.width('100%').padding(16);
  }
}

@Component
export struct FisherCalculator {
  @State grade: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateFisher(this.grade); }

  build() {
    Column() {
      Column() { Text('Fisher 分级').fontSize(17).fontWeight(FontWeight.Bold).fontColor('#1F3D2F'); Text('SAH 蛛血 CT 分级 · 预测血管痉挛风险 (Fisher 1980)').fontSize(11.5).fontColor('#4A5247').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Text('— 选择分级').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach([0, 1, 2, 3, 4], (item: number) => {
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
              Text(this.result!.tier).fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.result!.tierClass === 'tier-ok' ? '#3D6B4F' : this.result!.tierClass === 'tier-warn' ? '#C8881A' : '#B1452A')
                .backgroundColor(this.result!.tierClass === 'tier-ok' ? '#E8F0EC' : this.result!.tierClass === 'tier-warn' ? '#F5EFE0' : '#F5E4E0').borderRadius(20).padding({ left: 12, right: 12, top: 4, bottom: 4 }).margin({ top: 8 });
            }.alignItems(HorizontalAlign.Start).layoutWeight(1);
            Column() { Text(this.result!.footnote).fontSize(14).fontColor('#4A5247').lineHeight(22); }.layoutWeight(1).alignItems(HorizontalAlign.Start);
          }.width('100%');
        }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%');
      }
    }.width('100%').padding(16);
  }
}
