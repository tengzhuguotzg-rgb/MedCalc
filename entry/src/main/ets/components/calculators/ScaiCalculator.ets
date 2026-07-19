import { CalcResult, getTierColor, getTierBgColor } from '../../engine/CalcEngine';
import { calculateScai } from '../../engine/ScaiCalculator';

@Component
export struct ScaiCalculator {
  @State sbp: number = 0;
  @State lac: number = 0;
  @State vaso: string = '';
  @State perf: string = '';
  @State resus: string = '';
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateScai(this.sbp, this.lac, this.vaso, this.perf, this.resus); }

  build() {
    Column() {
      Column() { Text('用于心源性休克分层 (SCAI 2019/2024)').fontSize(14).fontColor('#1F3D2F').fontWeight(FontWeight.Medium); Text('A-E 五级, 基于血压/乳酸/血管活性药/灌注/CPR').fontSize(12).fontColor('#7A8074').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Text('— 输入参数').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });

        Row() {
          Column() {
            Text('收缩压 SBP (mmHg)').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
            TextInput({ placeholder: 'SBP' }).type(InputType.NUMBER_DECIMAL).height(40).fontSize(16).backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).placeholderColor('#999999').onChange((v: string) => { this.sbp = parseFloat(v) || 0; this.calculate(); });
          }.layoutWeight(1);
          Column() {
            Text('乳酸 (mmol/L)').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
            TextInput({ placeholder: '乳酸' }).type(InputType.NUMBER_DECIMAL).height(40).fontSize(16).backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).placeholderColor('#999999').onChange((v: string) => { this.lac = parseFloat(v) || 0; this.calculate(); });
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 8 });

        Column() {
          Text('血管活性药').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
          Flex({ wrap: FlexWrap.Wrap }) {
            Button('无').fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.vaso === 'none' ? '#FFFFFF' : '#2D5440').backgroundColor(this.vaso === 'none' ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.vaso === 'none' ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(34).padding({ left: 8, right: 8 }).margin({ right: 6, bottom: 4 }).onClick(() => { this.vaso = 'none'; this.calculate(); });
            Button('1种低剂量').fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.vaso === 'low' ? '#FFFFFF' : '#2D5440').backgroundColor(this.vaso === 'low' ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.vaso === 'low' ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(34).padding({ left: 8, right: 8 }).margin({ right: 6, bottom: 4 }).onClick(() => { this.vaso = 'low'; this.calculate(); });
            Button('≥2种/高剂量').fontSize(13).fontWeight(FontWeight.Bold).fontColor(this.vaso === 'high' ? '#FFFFFF' : '#2D5440').backgroundColor(this.vaso === 'high' ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.vaso === 'high' ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(34).padding({ left: 8, right: 8 }).margin({ bottom: 4 }).onClick(() => { this.vaso = 'high'; this.calculate(); });
          }.width('100%');
        }.width('100%').margin({ bottom: 8 });

        Column() {
          Text('末梢灌注').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
          Row() {
            Button('正常').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.perf === 'ok' ? '#FFFFFF' : '#2D5440').backgroundColor(this.perf === 'ok' ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.perf === 'ok' ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).layoutWeight(1).onClick(() => { this.perf = 'ok'; this.calculate(); });
            Button('差 (冷/紫/少尿)').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.perf === 'bad' ? '#FFFFFF' : '#2D5440').backgroundColor(this.perf === 'bad' ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.perf === 'bad' ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).layoutWeight(1).margin({ left: 4 }).onClick(() => { this.perf = 'bad'; this.calculate(); });
          }.width('100%');
        }.width('100%').margin({ bottom: 8 });

        Column() {
          Text('CPR / ECMO / 机械循环支持?').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
          Row() {
            Button('否').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.resus === 'no' ? '#FFFFFF' : '#2D5440').backgroundColor(this.resus === 'no' ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.resus === 'no' ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).layoutWeight(1).onClick(() => { this.resus = 'no'; this.calculate(); });
            Button('是').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.resus === 'yes' ? '#FFFFFF' : '#2D5440').backgroundColor(this.resus === 'yes' ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.resus === 'yes' ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).layoutWeight(1).margin({ left: 4 }).onClick(() => { this.resus = 'yes'; this.calculate(); });
          }.width('100%');
        }.width('100%');
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() {
              Text('SCAI 休克').fontSize(10).fontColor('#7A8074').letterSpacing(1.5);
              Text(this.result!.value !== null ? `Stage ${this.result!.unit}` : '—').fontSize(28).fontWeight(FontWeight.Bold).fontColor('#1F3D2F').margin({ top: 4 });
              Text(this.result!.tier).fontSize(12).fontWeight(FontWeight.Bold).fontColor(getTierColor(this.result!.tierClass)).backgroundColor(getTierBgColor(this.result!.tierClass)).borderRadius(20).padding({ left: 12, right: 12, top: 4, bottom: 4 }).margin({ top: 4 });
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
