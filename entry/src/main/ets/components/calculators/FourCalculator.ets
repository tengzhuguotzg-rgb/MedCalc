import { CalcResult } from '../../engine/CalcEngine';
import { calculateFour } from '../../engine/Batch2bCalculators';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, OptionChip, ResultCard, SectionTitle } from './widgets/CalcWidgets';

@Component
export struct FourCalculator {
  @State resetKey: number = 0;
  @State eye: number = 0;
  @State motor: number = 0;
  @State brainstem: number = 0;
  @State resp: number = 0;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateFour(this.eye, this.motor, this.brainstem, this.resp); }

  reset() {
    this.eye = 0;
    this.motor = 0;
    this.brainstem = 0;
    this.resp = 0;
    this.result = null;
    this.resetKey = this.resetKey + 1;
    this.calculate();
  }

  build() {
    if (this.resetKey % 2 === 0) {
      this.CalcContent();
    } else {
      this.CalcContent();
    }
  }

  @Builder
  CalcContent() {
    Column() {
      Column() {
        Text('FOUR 评分：插管/不能言语患者意识评估').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium);
        Text('眼/运动/脑干/呼吸各 0-4，总分 0-16').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
      }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        SectionTitle({ title: '眼部反应 (E)', resetAction: () => { this.reset(); } })
        Row({ space: 8 }) {
          OptionChip({ label: 'E4 追踪', selected: this.eye === 4, onChipClick: () => { this.eye = 4; this.calculate(); } });
          OptionChip({ label: 'E3 睁眼不追踪', selected: this.eye === 3, onChipClick: () => { this.eye = 3; this.calculate(); } });
          OptionChip({ label: 'E2 呼唤睁眼', selected: this.eye === 2, onChipClick: () => { this.eye = 2; this.calculate(); } });
        }.width('100%').margin({ bottom: 4 });
        Row({ space: 8 }) {
          OptionChip({ label: 'E1 疼痛睁眼', selected: this.eye === 1, onChipClick: () => { this.eye = 1; this.calculate(); } });
          OptionChip({ label: 'E0 不睁眼', selected: this.eye === 0, onChipClick: () => { this.eye = 0; this.calculate(); } });
        }.width('100%');
      }

      CalcCard() {
        Text('运动反应 (M)').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row({ space: 8 }) {
          OptionChip({ label: 'M4 遵嘱手势', selected: this.motor === 4, onChipClick: () => { this.motor = 4; this.calculate(); } });
          OptionChip({ label: 'M3 疼痛定位', selected: this.motor === 3, onChipClick: () => { this.motor = 3; this.calculate(); } });
          OptionChip({ label: 'M2 疼痛屈曲', selected: this.motor === 2, onChipClick: () => { this.motor = 2; this.calculate(); } });
        }.width('100%').margin({ bottom: 4 });
        Row({ space: 8 }) {
          OptionChip({ label: 'M1 疼痛伸展', selected: this.motor === 1, onChipClick: () => { this.motor = 1; this.calculate(); } });
          OptionChip({ label: 'M0 无反应', selected: this.motor === 0, onChipClick: () => { this.motor = 0; this.calculate(); } });
        }.width('100%');
      }

      CalcCard() {
        Text('脑干反射 (B)').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row({ space: 8 }) {
          OptionChip({ label: 'B4 瞳孔+角膜存在', selected: this.brainstem === 4, onChipClick: () => { this.brainstem = 4; this.calculate(); } });
          OptionChip({ label: 'B3 一侧瞳孔固定', selected: this.brainstem === 3, onChipClick: () => { this.brainstem = 3; this.calculate(); } });
          OptionChip({ label: 'B2 瞳孔或角膜消失', selected: this.brainstem === 2, onChipClick: () => { this.brainstem = 2; this.calculate(); } });
        }.width('100%').margin({ bottom: 4 });
        Row({ space: 8 }) {
          OptionChip({ label: 'B1 瞳孔+角膜消失', selected: this.brainstem === 1, onChipClick: () => { this.brainstem = 1; this.calculate(); } });
          OptionChip({ label: 'B0 +咳嗽反射消失', selected: this.brainstem === 0, onChipClick: () => { this.brainstem = 0; this.calculate(); } });
        }.width('100%');
      }

      CalcCard() {
        Text('呼吸 (R)').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppColors.textPrimary).margin({ bottom: 6 });
        Row({ space: 8 }) {
          OptionChip({ label: 'R4 未插管规律', selected: this.resp === 4, onChipClick: () => { this.resp = 4; this.calculate(); } });
          OptionChip({ label: 'R3 潮式呼吸', selected: this.resp === 3, onChipClick: () => { this.resp = 3; this.calculate(); } });
          OptionChip({ label: 'R2 不规则呼吸', selected: this.resp === 2, onChipClick: () => { this.resp = 2; this.calculate(); } });
        }.width('100%').margin({ bottom: 4 });
        Row({ space: 8 }) {
          OptionChip({ label: 'R1 高于机设频率', selected: this.resp === 1, onChipClick: () => { this.resp = 1; this.calculate(); } });
          OptionChip({ label: 'R0 无自主呼吸', selected: this.resp === 0, onChipClick: () => { this.resp = 0; this.calculate(); } });
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'FOUR 评分', value: this.result!.value, unit: this.result!.unit, decimals: 0, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}
