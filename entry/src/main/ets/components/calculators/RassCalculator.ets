import { CalcResult } from '../../engine/CalcEngine';
import { calculateRass } from '../../engine/RassCalculator';

interface RassLevel {
  score: number;
  label: string;
  desc: string;
  cls: string;
}

const RASS_LEVELS: RassLevel[] = [
  { score: 4, label: '+4 好斗', desc: '暴力行为，对工作人员有直接危险', cls: 'tier-danger' },
  { score: 3, label: '+3 非常躁动', desc: '极度躁动，拔除输液管或导管', cls: 'tier-danger' },
  { score: 2, label: '+2 躁动', desc: '频繁无目的动作，可能对抗呼吸机', cls: 'tier-warn' },
  { score: 1, label: '+1 不安焦虑', desc: '轻度躁动，但无攻击行为', cls: 'tier-warn' },
  { score: 0, label: '0 清醒平静', desc: '完全清醒，无躁动', cls: 'tier-ok' },
  { score: -1, label: '-1 嗜睡', desc: '对声音有反应，能保持觉醒≥10秒', cls: 'tier-ok' },
  { score: -2, label: '-2 轻度镇静', desc: '对声音有反应，但无法长时间保持觉醒', cls: 'tier-warn' },
  { score: -3, label: '-3 中度镇静', desc: '对声音无反应，对物理刺激有反应', cls: 'tier-warn' },
  { score: -4, label: '-4 深度镇静', desc: '对物理刺激有反应', cls: 'tier-danger' },
  { score: -5, label: '-5 无法唤醒', desc: '对声音或物理刺激无反应', cls: 'tier-danger' },
];

@Component
export struct RassCalculator {  @State score: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateRass(this.score); }

  build() {
    Column() {
      Column() { Text('用于评估ICU患者镇静深度及躁动状态').fontSize(14).fontColor('#1F3D2F').fontWeight(FontWeight.Medium); Text('+4(攻击)至-5(昏迷)，目标-2至0').fontSize(12).fontColor('#7A8074').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Text('— 选择评分').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach([4, 3, 2, 1, 0, -1, -2, -3, -4, -5], (item: number) => {
            Button(`${item >= 0 ? '+' : ''}${item}`).fontSize(15).fontWeight(FontWeight.Bold).fontColor(this.score === item ? '#FFFFFF' : '#2D5440')
              .backgroundColor(this.score === item ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.score === item ? '#1F3D2F' : '#E0E0E0' })
              .borderRadius(8).height(40).width(60).margin({ right: 8, bottom: 8 }).onClick(() => { this.score = item; this.calculate(); });
          });
        }.width('100%');
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.result && this.result.value !== null) {
        Column() {
          Column() {
            Text(this.result!.tier).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#1F3D2F');
            Text(this.result!.footnote).fontSize(13).fontColor('#4A5247').margin({ top: 4 });
          }.alignItems(HorizontalAlign.Start).width('100%').padding({ bottom: 12 }).border({ width: { bottom: 1 }, color: '#E0E0E0' });

          Text('完整评分参考').fontSize(12).fontColor('#7A8074').letterSpacing(1.5).fontWeight(FontWeight.Medium).margin({ top: 8, bottom: 8 });
          ForEach(RASS_LEVELS, (level: RassLevel) => {
            Row() {
              Column() {
                Text(level.label).fontSize(13).fontWeight(FontWeight.Bold).fontColor('#1F2421');
                Text(level.desc).fontSize(11).fontColor('#7A8074').margin({ top: 2 });
              }.layoutWeight(1).alignItems(HorizontalAlign.Start);
              Column() {
                Text(level.score === this.score ? '✓ 当前' : '').fontSize(11).fontWeight(FontWeight.Bold)
                  .fontColor('#1F3D2F');
              }.width(60).alignItems(HorizontalAlign.End);
            }.padding({ top: 6, bottom: 6, left: 8, right: 8 })
              .backgroundColor(level.score === this.score ? '#3D6B4F' : 'transparent')
              .borderRadius(6).margin({ bottom: 2 });
          });
        }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%');
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(16).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
