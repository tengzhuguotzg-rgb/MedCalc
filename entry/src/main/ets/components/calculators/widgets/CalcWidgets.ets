/**
 * CalcWidgets —— 计算器共享 UI 组件库
 *
 * 抽取自各计算器组件中逐字重复的四种结构：
 *  - CalcCard    白色卡片容器（padding/圆角/背景走 token）
 *  - InputRow    标签 + TextInput 输入行（非受控，依赖父组件 resetKey 分支切换强制重建）
 *  - ResultCard  结果卡（大数值 + tier 胶囊 + footnote，数据驱动）
 *  - OptionChip  选项胶囊（选中深绿底白字 / 未选中灰底，默认 44 高）
 *
 * 样式数值与原实现逐字保持一致；禁止在本文件中“顺手优化”任何尺寸/色值。
 */
import { AppColors } from '../../../utils/AppColors';
import { AppDimens } from '../../../utils/AppDimens';
import { getTierColor, getTierBgColor } from '../../../engine/CalcEngine';

/**
 * 白色卡片容器。原样复刻：
 * Column().padding(16).backgroundColor(card).borderRadius(12).width('100%').margin({ bottom: 16 })
 */
@Component
export struct CalcCard {
  /** 卡片底部外边距；输入卡为 16，结果卡场景传 0 */
  bottomMargin: number = 16;

  @Builder
  defaultContent() {
  }

  @BuilderParam
  content: () => void = this.defaultContent;

  build() {
    Column() {
      this.content();
    }
    .padding(AppDimens.cardPadding)
    .backgroundColor(AppColors.card)
    .borderRadius(AppDimens.cardRadius)
    .width('100%')
    .margin({ bottom: this.bottomMargin });
  }
}

/**
 * 标签 + TextInput 输入行。
 *
 * TextInput 为非受控组件：不绑定 text 属性，重置依赖父组件
 * resetKey%2 的 if/else 分支切换销毁并重建整棵子树（本组件随子树一并重建）。
 * 外层尺寸约束（layoutWeight/width/margin）由调用方按原样施加在本组件上。
 */
@Component
export struct InputRow {
  /** 字段标签（多数静态；Child-Pugh 等随单位切换的字段需响应式更新，故用 @Prop） */
  @Prop label: string = '';
  /** 占位文本；FiO₂ 等随模式切换的字段需响应式更新，故用 @Prop */
  @Prop placeholder: string = '';
  /** 键盘类型 */
  @Prop inputType: InputType = InputType.Number;
  /** 是否可编辑（如 APACHE II 的 pH/HCO₃⁻ 互斥启用） */
  @Prop inputEnabled: boolean = true;
  /** 输入回调，等价于原 TextInput 的 onChange */
  onTextChange: (value: string) => void = () => {
  };

  build() {
    Column() {
      Text(this.label)
        .fontSize(14)
        .fontColor(AppColors.textPrimary)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 6 });
      TextInput({ placeholder: this.placeholder })
        .type(this.inputType)
        .height(AppDimens.inputHeight)
        .fontSize(16)
        .fontColor(AppColors.textPrimary)
        .placeholderColor(AppColors.placeholder)
        .backgroundColor(AppColors.card)
        .borderRadius(8)
        .border({ width: 1, color: AppColors.border })
        .padding({ left: 12, right: 12 })
        .width('100%')
        .enabled(this.inputEnabled)
        .onChange((value: string) => {
          this.onTextChange(value);
        });
    }
  }
}

/**
 * 结果卡：左列（标题 + 大数值 + tier 胶囊），右列 footnote。
 *
 * 数值展示规则与原实现逐字一致：
 *  - value 为 null 时显示 '—'（空态）
 *  - 否则按 decimals 位小数格式化；trimZero 时再剥掉末尾 '.0'
 *  - unitInline 时数值后拼接 ' ' + unit；否则单位独占一行（12 号灰字）
 *  - valueText 非空时直接覆盖数值文案（用于 '阳性/阴性'、'Stage X' 等特殊格式）
 */
@Component
export struct ResultCard {
  /** 结果标题（如 'MAP'、'SOFA Total'） */
  title: string = '';
  /** 原始数值；null 显示 '—' */
  @Prop value: number | null = null;
  /** 单位 */
  @Prop unit: string = '';
  /** 小数位数（toFixed 参数） */
  decimals: number = 0;
  /** 是否剥掉格式化后末尾的 '.0'（对应原 toFixed(1).replace(/\.0$/, '')） */
  trimZero: boolean = false;
  /** 非空时直接作为数值文案，覆盖 value/unit 格式化 */
  @Prop valueText: string = '';
  /** tier 文案 */
  @Prop tier: string = '';
  /** tier 分级 class（getTierColor/getTierBgColor 入参） */
  @Prop tierClass: string = '';
  /** 右侧脚注 */
  @Prop footnote: string = '';
  /** 数值字号（默认 32；个别计算器为 28） */
  valueFontSize: number = 32;
  /** 数值上边距（默认 8；个别计算器为 4） */
  valueMarginTop: number = 8;
  /** tier 胶囊字号（默认 13；个别计算器为 12） */
  tierFontSize: number = 12;
  /** tier 胶囊上边距（默认 8；个别计算器为 4） */
  tierMarginTop: number = 8;
  /** 单位是否内联在数值后（默认 true；false 时单位独占一行小字） */
  unitInline: boolean = true;
  /** 标题是否 Medium 字重（默认 true；个别计算器标题无字重设置传 false） */
  titleMedium: boolean = true;
  /** 结果卡底部外边距（默认 0；Hunt-Hess/WFNS/Fisher 为 16） */
  bottomMargin: number = 0;

  private mainText(): string {
    if (this.value === null) {
      return '—';
    }
    if (this.valueText !== '') {
      return this.valueText;
    }
    let txt: string = this.value.toFixed(this.decimals);
    if (this.trimZero) {
      txt = txt.replace(/\.0$/, '');
    }
    if (this.unitInline && this.unit !== '') {
      return `${txt} ${this.unit}`;
    }
    return txt;
  }

  build() {
    Column() {
      Row() {
        Column() {
          Text(this.title)
            .fontSize(12)
            .fontColor(AppColors.textSecondary)
            .letterSpacing(1.5)
            .fontWeight(this.titleMedium ? FontWeight.Medium : FontWeight.Regular);
          Text(this.mainText())
            .fontSize(this.valueFontSize)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.tierClass.length > 0 ? getTierColor(this.tierClass) : AppColors.primary)
            .margin({ top: this.valueMarginTop });
          if (!this.unitInline) {
            Text(this.value !== null ? this.unit : '')
              .fontSize(10)
              .fontColor(AppColors.textSecondary);
          }
          Text(this.tier)
            .fontSize(this.tierFontSize)
            .fontWeight(FontWeight.Bold)
            .fontColor(getTierColor(this.tierClass))
            .backgroundColor(getTierBgColor(this.tierClass))
            .borderRadius(20)
            .padding({ left: 12, right: 12, top: 4, bottom: 4 })
            .margin({ top: this.tierMarginTop });
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1);

        Column() {
          Text(this.footnote)
            .fontSize(10)
            .fontColor(AppColors.textBody)
            .lineHeight(22);
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start);
      }
      .width('100%');
    }
    .padding(AppDimens.cardPadding)
    .backgroundColor(AppColors.card)
    .borderRadius(AppDimens.cardRadius)
    .width('100%')
    .margin({ bottom: this.bottomMargin });
  }
}

/**
 * 选项胶囊按钮。
 * 选中：深绿底白字深绿描边；未选中：浅灰底绿字灰描边。
 * 默认 44 高、圆角 8、13 号 Medium；迷你单位切换用 28 高、圆角 6、12 号 Bold。
 * 外层 margin/layoutWeight 由调用方按原样施加。
 */
@Component
export struct OptionChip {
  /** 按钮文案（静态） */
  label: string = '';
  /** 是否选中 */
  @Prop selected: boolean = false;
  /** 字号（默认 13） */
  fontSize: number = 13;
  /** 字重：false=Medium（默认），true=Bold */
  bold: boolean = false;
  /** 高度（默认 44 触控热区；迷你切换为 28；大按钮为 48） */
  chipHeight: number = AppDimens.touchTarget;
  /** 圆角（默认 8；迷你切换为 6） */
  chipRadius: number = 8;
  /** 水平内边距；-1 表示不设置（沿用 Button 默认，与原实现一致） */
  horizontalPadding: number = -1;
  /** 点击回调 */
  onChipClick: () => void = () => {
  };

  build() {
    if (this.horizontalPadding >= 0) {
      Button(this.label)
        .fontSize(this.fontSize)
        .fontWeight(this.bold ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.selected ? AppColors.onPrimary : AppColors.textOption)
        .backgroundColor(this.selected ? AppColors.primary : AppColors.fillNeutral)
        .border({ width: 1, color: this.selected ? AppColors.primary : AppColors.border })
        .borderRadius(this.chipRadius)
        .height(this.chipHeight)
        .padding({ left: this.horizontalPadding, right: this.horizontalPadding })
        .onClick(() => {
          this.onChipClick();
        });
    } else {
      Button(this.label)
        .fontSize(this.fontSize)
        .fontWeight(this.bold ? FontWeight.Bold : FontWeight.Medium)
        .fontColor(this.selected ? AppColors.onPrimary : AppColors.textOption)
        .backgroundColor(this.selected ? AppColors.primary : AppColors.fillNeutral)
        .border({ width: 1, color: this.selected ? AppColors.primary : AppColors.border })
        .borderRadius(this.chipRadius)
        .height(this.chipHeight)
        .onClick(() => {
          this.onChipClick();
        });
    }
  }
}
