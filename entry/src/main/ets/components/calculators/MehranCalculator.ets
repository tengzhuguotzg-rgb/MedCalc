import { CalcResult } from '../../engine/CalcEngine';
import { calculateMehran } from '../../engine/MehranCalculator';

@Component
export struct MehranCalculator {  @State age: number = 0;
  @State chf: boolean = false;
  @State dm: boolean = false;
  @State gfr: number = 0;
  @State contrastVol: number = 0;
  @State anemia: boolean = false;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateMehran(this.age, this.chf, this.dm, this.gfr, this.contrastVol, this.anemia); }

  build() {
    Column() {
      Column() { Text('用于预测冠脉介入后造影剂肾病风险').fontSize(14).fontColor('#1F3D2F').fontWeight(FontWeight.Medium); Text('8项：低血压+IABP+心衰+年龄+贫血+糖尿病+造影剂+肌酐/eGFR').fontSize(12).fontColor('#7A8074').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Text('— 输入参数').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });

        Row() {
          Column() { Text('年龄 (岁)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '请输入年龄' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.age = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1);
          Column() { Text('eGFR (mL/min)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '请输入eGFR' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.gfr = parseFloat(value) || 0; this.calculate(); }); }.layoutWeight(1).margin({ left: 12 });
        }.width('100%').margin({ bottom: 16 });

        Column() { Text('造影剂用量 (mL)').fontSize(14).fontColor('#1F2421').fontWeight(FontWeight.Medium).margin({ bottom: 6 }); TextInput({ placeholder: '请输入用量' }).type(InputType.Number).height(40).fontSize(16).fontColor('#1F2421').placeholderColor('#999999').backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).width('100%').onChange((value: string) => { this.contrastVol = parseFloat(value) || 0; this.calculate(); }); }.width('100%').margin({ bottom: 16 });

        Row() { Text('心力衰竭').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!this.chf ? '#FFFFFF' : '#2D5440').backgroundColor(!this.chf ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.chf ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.chf = false; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.chf ? '#FFFFFF' : '#2D5440').backgroundColor(this.chf ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.chf ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.chf = true; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('糖尿病').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!this.dm ? '#FFFFFF' : '#2D5440').backgroundColor(!this.dm ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.dm ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.dm = false; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.dm ? '#FFFFFF' : '#2D5440').backgroundColor(this.dm ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.dm ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.dm = true; this.calculate(); });
          }.width(100);
        }.width('100%').margin({ bottom: 12 });

        Row() { Text('贫血').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').layoutWeight(1);
          Row() { Button('无').fontSize(14).fontWeight(FontWeight.Bold).fontColor(!this.anemia ? '#FFFFFF' : '#2D5440').backgroundColor(!this.anemia ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: !this.anemia ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.anemia = false; this.calculate(); });
            Button('有').fontSize(14).fontWeight(FontWeight.Bold).fontColor(this.anemia ? '#FFFFFF' : '#2D5440').backgroundColor(this.anemia ? '#1F3D2F' : '#F5F5F5').border({ width: 1, color: this.anemia ? '#1F3D2F' : '#E0E0E0' }).borderRadius(8).height(36).layoutWeight(1).onClick(() => { this.anemia = true; this.calculate(); });
          }.width(100);
        }.width('100%');
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.result) {
        Column() {
          Row() {
            Column() { Text('Mehran').fontSize(12).fontColor('#7A8074').letterSpacing(1.5).fontWeight(FontWeight.Medium);
              Text(this.result!.value !== null ? `${this.result!.value!.toFixed(0)} ${this.result!.unit}` : '—').fontSize(32).fontWeight(FontWeight.Bold).fontColor('#1F3D2F').margin({ top: 8 });
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
