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
    .padding({ left: 16, right: 16, top: 8, bottom: 16 })
    .backgroundColor(AppColors.card)
    .borderRadius(AppDimens.cardRadius)
    .border({ width: 1, color: AppColors.border })
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
 * 结果卡（Hero 布局）：标题 + 大数值 + tier 胶囊 + footnote 通栏。
 *
 * Hero 布局（V2）：
 *  - 左侧 4px tier 色竖条 + 卡底 tier 氛围色
 *  - 标题/数值/tier 胶囊 上方，footnote 下方通栏
 *  - 空态：紧凑 40px 提示条（替代灰化 Hero 卡）
 */
@Component
export struct ResultCard {
  /** 结果标题（如 'MAP'、'SOFA Total'） */
  title: string = '';
  /** 原始数值；null 显示 '-'（空态） */
  @Prop @Watch('onResultChange') value: number | null = null;
  /** 单位 */
  @Prop unit: string = '';
  /** 小数位数（toFixed 参数） */
  decimals: number = 0;
  /** 是否剥掉格式化后末尾的 '.0' */
  trimZero: boolean = false;
  /** 非空时直接作为数值文案，覆盖 value/unit 格式化 */
  @Prop @Watch('onResultChange') valueText: string = '';
  /** tier 文案 */
  @Prop @Watch('onResultChange') tier: string = '';
  /** tier 分级 class（getTierColor/getTierBgColor 入参） */
  @Prop @Watch('onResultChange') tierClass: string = '';
  /** 脚注（通栏显示于数值下方） */
  @Prop footnote: string = '';
  /** 数值字号（默认 Hero 40；SCAI 等传 28） */
  valueFontSize: number = AppDimens.fontHero;
  /** 数值上边距 */
  valueMarginTop: number = 4;
  /** tier 胶囊字号 */
  tierFontSize: number = 12;
  /** tier 胶囊上边距 */
  tierMarginTop: number = 4;
  /** 单位是否内联在数值后（默认 true；false 时单位独占一行小字） */
  unitInline: boolean = true;
  /** 标题是否 Medium 字重（默认 true） */
  titleMedium: boolean = true;
  /** 结果卡底部外边距（默认 0） */
  bottomMargin: number = 0;

  // 监听当前弹出的计算器 id（非空表示有计算器在 bindSheet 中被弹出）
  @StorageProp('activeCalcId') activeCalcId: string = '';

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

  private isEmpty(): boolean {
    return this.value === null && this.valueText === '';
  }

  // 当结果变化且当前有计算器在 bindSheet 中被弹出时，把结果写入 AppStorage
  onResultChange(): void {
    if (this.activeCalcId.length === 0) {
      return;
    }
    const hasValue = this.value !== null || this.valueText.length > 0;
    const isIncomplete = this.tier === '请填写必填项';
    if (hasValue && !isIncomplete) {
      // 写入格式化后的显示文本，而非原始浮点数
      const displayText = this.valueText.length > 0 ? this.valueText : this.mainText();
      AppStorage.setOrCreate('sheetCalcId', this.activeCalcId);
      AppStorage.setOrCreate('sheetCalcValue', this.value);
      AppStorage.setOrCreate('sheetCalcUnit', this.unit);
      AppStorage.setOrCreate('sheetCalcTier', this.tier);
      AppStorage.setOrCreate('sheetCalcTierClass', this.tierClass);
      AppStorage.setOrCreate('sheetCalcValueText', displayText);
      AppStorage.setOrCreate('sheetCalcTimestamp', Date.now());
    }
  }

  private tierIcon(): Resource {
    if (this.tierClass === 'ok') {
      return $r('app.media.ic_check_circle');
    }
    if (this.tierClass === 'warn') {
      return $r('app.media.ic_alert_triangle');
    }
    if (this.tierClass === 'danger') {
      return $r('app.media.ic_alert_octagon');
    }
    return $r('app.media.ic_info');
  }

  build() {
    if (this.isEmpty()) {
      Row({ space: 6 }) {
        Image($r('app.media.ic_info'))
          .width(16)
          .height(16)
          .fillColor(AppColors.textSecondary)
          .objectFit(ImageFit.Contain)
        Text(this.tier.length > 0 ? this.tier : '填写参数后自动出分')
          .fontSize(12)
          .fontColor(AppColors.textSecondary)
      }
      .height(40)
      .width('100%')
      .padding({ left: 12, right: 12 })
      .backgroundColor(AppColors.card)
      .borderRadius(AppDimens.cardRadius)
      .border({ width: 1, color: AppColors.border })
      .margin({ bottom: this.bottomMargin })
      .animation({ duration: 200, curve: Curve.EaseOut });
    } else {
      Flex({ alignItems: ItemAlign.Stretch }) {
        Row()
          .width(4)
          .backgroundColor(this.tierClass.length > 0 ? getTierColor(this.tierClass) : Color.Transparent)
          .borderRadius({ topLeft: 12, bottomLeft: 12 })

        Column() {
          Text(this.title)
            .fontSize(12)
            .fontColor(AppColors.textSecondary)
            .fontWeight(this.titleMedium ? FontWeight.Medium : FontWeight.Regular);
          Text(this.mainText())
            .fontSize(this.valueFontSize)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.tierClass.length > 0 ? getTierColor(this.tierClass) : AppColors.primary)
            .fontFeature('tnum')
            .margin({ top: this.valueMarginTop })
            .animation({ duration: 200, curve: Curve.EaseOut });
          if (!this.unitInline) {
            Text(this.value !== null ? this.unit : '')
              .fontSize(10)
              .fontColor(AppColors.textSecondary);
          }
          if (this.tier.length > 0) {
            Row({ space: 4 }) {
              Image(this.tierIcon())
                .width(14)
                .height(14)
                .fillColor(getTierColor(this.tierClass))
                .objectFit(ImageFit.Contain)
              Text(this.tier)
                .fontSize(this.tierFontSize)
                .fontWeight(FontWeight.Bold)
                .fontColor(getTierColor(this.tierClass))
            }
            .backgroundColor(getTierBgColor(this.tierClass))
            .borderRadius(20)
            .padding({ left: 10, right: 12, top: 4, bottom: 4 })
            .margin({ top: this.tierMarginTop })
            .animation({ duration: 200, curve: Curve.EaseOut });
          }
          if (this.footnote.length > 0) {
            Text(this.footnote)
              .fontSize(12)
              .fontColor(AppColors.textBody)
              .lineHeight(18)
              .margin({ top: 8 });
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .padding({ left: 12 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 16 })
      .backgroundColor(this.tierClass.length > 0 ? getTierBgColor(this.tierClass) : AppColors.card)
      .borderRadius(AppDimens.cardRadius)
      .margin({ bottom: this.bottomMargin });
    }
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
        .animation({ duration: 150, curve: Curve.EaseOut })
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
        .animation({ duration: 150, curve: Curve.EaseOut })
        .onClick(() => {
          this.onChipClick();
        });
    }
  }
}

@Component
export struct ResetButton {
  onReset: () => void = () => {};

  build() {
    Text('🗑')
      .fontSize(16)
      .fontColor(AppColors.textSecondary)
      .padding({ left: 12, right: 12, top: 10, bottom: 10 })
      .borderRadius(8)
      .onClick(() => { this.onReset(); })
  }
}

@Component
export struct IconButton {
  iconResource: Resource = $r('app.media.ic_menu');
  iconColor: ResourceColor = AppColors.textSecondary;
  iconSize: number = 22;
  btnSize: number = AppDimens.touchTarget;
  onIconClick?: () => void;

  build() {
    Row() {
      Image(this.iconResource)
        .width(this.iconSize)
        .height(this.iconSize)
        .fillColor(this.iconColor)
        .objectFit(ImageFit.Contain)
    }
    .width(this.btnSize)
    .height(this.btnSize)
    .backgroundColor(Color.Transparent)
    .justifyContent(FlexAlign.Center)
    .onClick(() => { if (this.onIconClick) { this.onIconClick(); } })
  }
}

@Component
export struct SectionTitle {
  title: string = '';
  resetAction?: () => void;

  build() {
    Row() {
      Text(this.title)
        .fontSize(AppDimens.fontSectionTitle)
        .fontColor(AppColors.textSecondary)
        .fontWeight(FontWeight.Bold)
      Blank()
      if (this.resetAction) {
        ResetButton({ onReset: this.resetAction })
      }
    }
    .width('100%')
    .margin({ bottom: AppDimens.spacing2 })
  }
}
