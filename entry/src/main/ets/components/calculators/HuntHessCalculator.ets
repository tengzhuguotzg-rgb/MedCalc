import { CalcResult } from '../../engine/CalcEngine';
import { calculateHuntHess, calculateWfns, calculateFisher } from '../../engine/HuntHessCalculator';
import { AppColors } from '../../utils/AppColors';
import { AppDimens } from '../../utils/AppDimens';
import { CalcCard, OptionChip, ResultCard } from './widgets/CalcWidgets';

interface GradeInfo {
  grade: number;
  label: string;
  desc: string;
  cls: string;
}

const HH_LEVELS: GradeInfo[] = [
  { grade: 0, label: '0 未破裂', desc: '无症状，偶然发现', cls: 'tier-ok' },
  { grade: 1, label: 'I 级', desc: '轻微头痛，无神经功能缺损', cls: 'tier-ok' },
  { grade: 2, label: 'II 级', desc: '中重度头痛，脑神经麻痹', cls: 'tier-warn' },
  { grade: 3, label: 'III 级', desc: '嗜睡，轻度神经功能缺损', cls: 'tier-warn' },
  { grade: 4, label: 'IV 级', desc: '昏迷，中重度偏瘫', cls: 'tier-danger' },
  { grade: 5, label: 'V 级', desc: '深昏迷，去脑强直', cls: 'tier-danger' },
];

const WFNS_LEVELS: GradeInfo[] = [
  { grade: 1, label: 'I 级', desc: 'GCS 15，无神经功能缺损', cls: 'tier-ok' },
  { grade: 2, label: 'II 级', desc: 'GCS 13-14，无神经功能缺损', cls: 'tier-warn' },
  { grade: 3, label: 'III 级', desc: 'GCS 13-14，有神经功能缺损', cls: 'tier-warn' },
  { grade: 4, label: 'IV 级', desc: 'GCS 7-12', cls: 'tier-danger' },
  { grade: 5, label: 'V 级', desc: 'GCS 3-6', cls: 'tier-danger' },
];

const FISHER_LEVELS: GradeInfo[] = [
  { grade: 1, label: 'I 级', desc: '薄层出血，<1mm厚度', cls: 'tier-ok' },
  { grade: 2, label: 'II 级', desc: '薄层出血，<1mm厚度，范围较广', cls: 'tier-warn' },
  { grade: 3, label: 'III 级', desc: '厚层出血，≥1mm厚度', cls: 'tier-danger' },
  { grade: 4, label: 'IV 级', desc: '脑内血肿或脑室出血', cls: 'tier-danger' },
];

@Component
export struct HuntHessCalculator {
  @State resetKey: number = 0;
  @State grade: number = -1;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateHuntHess(this.grade); }

  reset() {
    this.grade = -1;
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
      Column() { Text('用于蛛网膜下腔出血手术风险分层').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('0-5级，基于临床症状严重程度').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        Row() { Text('— 选择分级').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach([0, 1, 2, 3, 4, 5], (item: number) => {
            OptionChip({ label: `${item}`, selected: this.grade === item, fontSize: 15, bold: true, chipHeight: AppDimens.inputHeight, onChipClick: () => { this.grade = item; this.calculate(); } }).width(60).margin({ right: 8, bottom: 8 });
          }, (item: number) => item.toString() + '-' + this.grade.toString());
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'Hunt-Hess', value: this.result!.value, valueText: `${this.result!.value} ${this.result!.unit}`, bottomMargin: 16, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }

      CalcCard({ bottomMargin: 0 }) {
        Text('完整分级参考').fontSize(12).fontColor(AppColors.textSecondary).letterSpacing(1.5).fontWeight(FontWeight.Medium).margin({ bottom: 8 });
        GradeTable({ levels: HH_LEVELS, current: this.grade });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}

@Component
export struct WfnsCalculator {
  @State resetKey: number = 0;
  @State grade: number = -1;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateWfns(this.grade); }

  reset() {
    this.grade = -1;
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
      Column() { Text('用于蛛网膜下腔出血临床分级及预后评估').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('I-V级，基于GCS和局灶体征').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        Row() { Text('— 选择分级').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach([1, 2, 3, 4, 5], (item: number) => {
            OptionChip({ label: `${item}`, selected: this.grade === item, fontSize: 15, bold: true, chipHeight: AppDimens.inputHeight, onChipClick: () => { this.grade = item; this.calculate(); } }).width(60).margin({ right: 8, bottom: 8 });
          }, (item: number) => item.toString() + '-' + this.grade.toString());
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'WFNS', value: this.result!.value, valueText: `${this.result!.value} ${this.result!.unit}`, bottomMargin: 16, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }

      CalcCard({ bottomMargin: 0 }) {
        Text('完整分级参考').fontSize(12).fontColor(AppColors.textSecondary).letterSpacing(1.5).fontWeight(FontWeight.Medium).margin({ bottom: 8 });
        GradeTable({ levels: WFNS_LEVELS, current: this.grade });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}

@Component
export struct FisherCalculator {
  @State resetKey: number = 0;
  @State grade: number = -1;
  @State result: CalcResult | null = null;

  aboutToAppear() { this.calculate(); }
  calculate() { this.result = calculateFisher(this.grade); }

  reset() {
    this.grade = -1;
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
      Column() { Text('用于预测蛛网膜下腔出血后脑血管痉挛风险').fontSize(14).fontColor(AppColors.primary).fontWeight(FontWeight.Medium); Text('1-4级，基于CT出血量').fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 }); }.alignItems(HorizontalAlign.Start).width('100%').margin({ bottom: 12 });

      CalcCard() {
        Row() { Text('— 选择分级').fontSize(12).fontColor(AppColors.warning).fontWeight(FontWeight.Bold).letterSpacing(1.5); Blank(); Text('重置').fontSize(12).fontColor(AppColors.textSecondary).onClick(() => { this.reset(); }); }.width('100%').margin({ bottom: 12 });
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach([1, 2, 3, 4], (item: number) => {
            OptionChip({ label: `${item}`, selected: this.grade === item, fontSize: 15, bold: true, chipHeight: AppDimens.inputHeight, onChipClick: () => { this.grade = item; this.calculate(); } }).width(60).margin({ right: 8, bottom: 8 });
          }, (item: number) => item.toString() + '-' + this.grade.toString());
        }.width('100%');
      }

      if (this.result) {
        ResultCard({ title: 'Fisher', value: this.result!.value, valueText: `${this.result!.value} ${this.result!.unit}`, bottomMargin: 16, tier: this.result!.tier, tierClass: this.result!.tierClass, footnote: this.result!.footnote });
      }

      CalcCard({ bottomMargin: 0 }) {
        Text('完整分级参考').fontSize(12).fontColor(AppColors.textSecondary).letterSpacing(1.5).fontWeight(FontWeight.Medium).margin({ bottom: 8 });
        GradeTable({ levels: FISHER_LEVELS, current: this.grade });
      }
    }.width('100%').constraintSize({ minHeight: '100%' }).padding(AppDimens.cardPadding).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start);
  }
}

@Component
struct GradeTable {
  @Prop levels: GradeInfo[] = [];
  @Prop current: number = -1;

  build() {
    ForEach(this.levels, (level: GradeInfo) => {
      Row() {
        Column() {
          Text(level.label).fontSize(13).fontWeight(FontWeight.Bold).fontColor(AppColors.textPrimary);
          Text(level.desc).fontSize(12).fontColor(AppColors.textSecondary).margin({ top: 2 });
        }.layoutWeight(1).alignItems(HorizontalAlign.Start);
        Column() {
          Text(level.grade === this.current ? '✓ 当前' : '').fontSize(12).fontWeight(FontWeight.Bold).fontColor(AppColors.primary);
        }.width(60).alignItems(HorizontalAlign.End);
      }.padding({ top: 6, bottom: 6, left: 8, right: 8 }).borderRadius(6).margin({ bottom: 2 });
    }, (level: GradeInfo) => level.grade.toString() + '-' + this.current.toString());
  }
}