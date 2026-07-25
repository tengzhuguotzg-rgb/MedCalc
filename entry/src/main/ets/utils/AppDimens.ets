/**
 * AppDimens —— 全局尺寸设计 token
 *
 * 收录代码中高频出现的尺寸字面量；仅迁移精确匹配的场景，
 * 其余局部尺寸仍允许就地书写。
 */
export class AppDimens {
  /** 最小触控热区 44：选项按钮、顶栏按钮高度 */
  static readonly touchTarget: number = 44;
  /** 输入框高度 48 */
  static readonly inputHeight: number = 48;
  /** 卡片圆角 12 */
  static readonly cardRadius: number = 12;
  /** 卡片内边距 16 */
  static readonly cardPadding: number = 16;
  /** 说明/标注字号 12 */
  static readonly fontCaption: number = 12;
  /** 正文字号 14 */
  static readonly fontBody: number = 14;
  /** 分节标题字号 13 Bold */
  static readonly fontSectionTitle: number = 13;
  /** 结果 Hero 字号 40 Bold */
  static readonly fontHero: number = 40;
  /** 页面描述字号 15 */
  static readonly fontDescription: number = 15;
  /** 行内间距 8 */
  static readonly spacing1: number = 8;
  /** 卡内间距 16 */
  static readonly spacing2: number = 16;
  /** 页面级段落间距 24 */
  static readonly spacing3: number = 24;
}
