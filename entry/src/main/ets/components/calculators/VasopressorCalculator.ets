import { vasopressorMlhToDose, vasopressorDoseToMlh } from '../../engine/VasopressorCalculator';

const VP_DRUGS: string[][] = [
  ['norepinephrine', '去甲肾上腺素 (NE)'],
  ['dopamine', '多巴胺 (DA)'],
  ['dobutamine', '多巴酚丁胺 (DOB)'],
  ['epinephrine', '肾上腺素 (EPI)'],
  ['phenylephrine', '去氧肾上腺素 (PE)'],
  ['vasopressin', '垂体后叶素 (VP)'],
];

@Component
export struct VasopressorCalculator {
  @State weight: number = 0;
  @State drug: string = 'norepinephrine';
  @State concMg: number = 0;
  @State concMl: number = 0;
  @State mlh: number = 0;
  @State doseUg: number = 0;
  @State inputMode: string = 'mlh';

  getConcUgMl(): number {
    if (this.concMg > 0 && this.concMl > 0) {
      return this.concMg * 1000 / this.concMl;
    }
    return 0;
  }

  onMlhChange(value: string): void {
    this.inputMode = 'mlh';
    this.mlh = parseFloat(value) || 0;
    if (this.mlh > 0 && this.weight > 0 && this.concMg > 0 && this.concMl > 0) {
      this.doseUg = vasopressorMlhToDose(this.concMg, this.concMl, this.weight, this.mlh) || 0;
    } else {
      this.doseUg = 0;
    }
  }

  onDoseChange(value: string): void {
    this.inputMode = 'dose';
    this.doseUg = parseFloat(value) || 0;
    if (this.doseUg > 0 && this.weight > 0 && this.concMg > 0 && this.concMl > 0) {
      this.mlh = vasopressorDoseToMlh(this.concMg, this.concMl, this.weight, this.doseUg) || 0;
    } else {
      this.mlh = 0;
    }
  }

  getDrugName(): string {
    for (const d of VP_DRUGS) {
      if (d[0] === this.drug) {
        return d[1];
      }
    }
    return '';
  }

  build() {
    Column() {
      Column() { Text('升压药剂量换算 (mL/h ↔ μg/kg/min)').fontSize(14).fontColor('#1F3D2F').fontWeight(FontWeight.Medium); Text('支持双向换算：调速→剂量 或 剂量→调速').fontSize(12).fontColor('#7A8074').margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      Column() {
        Text('— 患者参数').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });
        Column() {
          Text('体重 (kg)').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
          TextInput({ placeholder: '体重' }).type(InputType.Number).height(40).fontSize(16).backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).placeholderColor('#999999')
            .onChange((value: string) => {
              this.weight = parseFloat(value) || 0;
              if (this.inputMode === 'mlh' && this.mlh > 0) {
                this.onMlhChange(String(this.mlh));
              } else if (this.doseUg > 0) {
                this.onDoseChange(String(this.doseUg));
              }
            });
        }.width('100%').margin({ bottom: 12 });

        Text('— 药物选择').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(VP_DRUGS, (d: string[]) => {
            Button(d[1]).fontSize(12).fontWeight(FontWeight.Bold).fontColor(this.drug === d[0] ? '#FFFFFF' : '#2D5440')
              .backgroundColor(this.drug === d[0] ? '#1F3D2F' : '#F5F5F5')
              .border({ width: 1, color: this.drug === d[0] ? '#1F3D2F' : '#E0E0E0' })
              .borderRadius(8).height(32).margin({ right: 6, bottom: 6 })
              .onClick(() => { this.drug = d[0]; });
          }, (d: string[]) => d[0]);
        }.width('100%').margin({ bottom: 12 });

        Text('— 配药浓度').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });
        Row() {
          Column() {
            Text('药物 (mg)').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
            TextInput({ placeholder: 'mg' }).type(InputType.Number).height(40).fontSize(16).backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).placeholderColor('#999999')
              .onChange((value: string) => {
                this.concMg = parseFloat(value) || 0;
                if (this.inputMode === 'mlh' && this.mlh > 0) { this.onMlhChange(String(this.mlh)); }
                else if (this.doseUg > 0) { this.onDoseChange(String(this.doseUg)); }
              });
          }.layoutWeight(1);
          Column() {
            Text('配成 (mL)').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
            TextInput({ placeholder: 'mL' }).type(InputType.Number).height(40).fontSize(16).backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).placeholderColor('#999999')
              .onChange((value: string) => {
                this.concMl = parseFloat(value) || 0;
                if (this.inputMode === 'mlh' && this.mlh > 0) { this.onMlhChange(String(this.mlh)); }
                else if (this.doseUg > 0) { this.onDoseChange(String(this.doseUg)); }
              });
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%').margin({ bottom: 12 });

        if (this.getConcUgMl() > 0) {
          Text(`浓度: ${this.getConcUgMl().toFixed(1)} μg/mL`).fontSize(11).fontColor('#7A8074').margin({ bottom: 8 });
        }

        Text('— 双向换算').fontSize(12).fontColor('#E76F2C').fontWeight(FontWeight.Bold).letterSpacing(1.5).margin({ bottom: 12 });
        Row() {
          Column() {
            Text('速度 (mL/h)').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
            TextInput({ placeholder: 'mL/h' }).type(InputType.Number).height(40).fontSize(16).backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).placeholderColor('#999999')
              .onChange((value: string) => { this.onMlhChange(value); });
          }.layoutWeight(1);
          Column() {
            Text('剂量 (μg/kg/min)').fontSize(14).fontWeight(FontWeight.Medium).fontColor('#1F2421').margin({ bottom: 6 });
            TextInput({ placeholder: 'μg/kg/min' }).type(InputType.Number).height(40).fontSize(16).backgroundColor('#FFFFFF').borderRadius(8).border({ width: 1, color: '#E0E0E0' }).padding({ left: 12, right: 12 }).placeholderColor('#999999')
              .onChange((value: string) => { this.onDoseChange(value); });
          }.layoutWeight(1).margin({ left: 8 });
        }.width('100%');
      }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%').margin({ bottom: 16 });

      if (this.mlh > 0 && this.doseUg > 0 && this.weight > 0) {
        Column() {
          Row() {
            Column() {
              Text('当前结果').fontSize(10).fontColor('#7A8074').letterSpacing(1.5);
              Text(this.getDrugName()).fontSize(22).fontWeight(FontWeight.Bold).fontColor('#1F3D2F').margin({ top: 4 });
              Text(`${this.mlh.toFixed(2)} mL/h  =  ${this.doseUg.toFixed(3)} μg/kg/min`).fontSize(15).fontColor('#4A5247').margin({ top: 4 });
            }.alignItems(HorizontalAlign.Start).layoutWeight(1);
          }.width('100%');
        }.padding(16).backgroundColor('#FFFFFF').borderRadius(12).width('100%');
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(16).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
