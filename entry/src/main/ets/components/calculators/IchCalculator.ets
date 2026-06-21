import { CalcResult } from '../../engine/CalcEngine';
import { calculateIch } from '../../engine/IchCalculator';

@Component
export struct IchCalculator {
  @State vol: number = 0;
  @State location: number = 0;
  @State ivh: boolean = false;
  @State age: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateIch(this.vol, this.location, this.ivh, this.age); }

  build() {
    Column() {
      Column() { Text('ICH 脑出血评分').fontSize(17).fontWeight(FontWeight.Bold).fontColor('#1F3D2F'); Text('脑出血预后评分 · 总分 0-6 (Hemphill 2001)').fontSize(11.5).fontColor('#4A5247').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Text('— 输入参数').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });

        Column() { Text('血肿体积 (mL)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '请输入体积' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.vol = parseFloat(value) || 0; this.calculate(); }); }.width('100%').margin({ bottom: 16 });

        Column() {
          Text('出血部位').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 8 });
          Row() {
            Button('幕上').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.location === 0 ? '#FFFFFF' : '#2D5440').backgroundColor(this.location === 0 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.location === 0 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.location = 0; this.calculate(); });
            Button('幕下').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.location === 1 ? '#FFFFFF' : '#2D5440').backgroundColor(this.location === 1 ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.location === 1 ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).margin({ left: 8 }).onClick(() => { this.location = 1; this.calculate(); });
          }.width('100%');
        }.width('100%').margin({ bottom: 16 });

        Row() { Text('脑室出血').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!this.ivh ? '#FFFFFF' : '#2D5440').backgroundColor(!this.ivh ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.ivh ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.ivh = false; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.ivh ? '#FFFFFF' : '#2D5440').backgroundColor(this.ivh ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.ivh ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.ivh = true; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 16 });

        Column() { Text('年龄 (岁)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '请输入年龄' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.age = parseFloat(value) || 0; this.calculate(); }); }.width('100%');
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() { Text('ICH Score').fontSize(12).fontColor('#7A8074').letterSpacing(1.5).fontWeight(FontWeight.Medium);
              Text(this.result!.value !== null ? `${this.result!.value!.toFixed(0)} ${this.result!.unit}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor('#1F3D2F').margin({ top: 8 });
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
