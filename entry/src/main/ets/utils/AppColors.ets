/**
 * AppColors —— 全局色彩设计 token
 *
 * 全 App 色值的唯一定义处。调色只改 color.json (base/dark)。
 * 命名按语义用途而非色相；注释标注用途。
 *
 * 品牌色板：手术青主色 + 冷调浅青灰背景 + 白卡片 + 灰青辅助色；
 * 分级色（tier）与 CalcEngine.getTierColor/getTierBgColor 共用本组常量，
 * 禁止在其他文件中重新字面量定义。
 *
 * 色值迁移到 resources/base/element/color.json + resources/dark/element/color.json，
 * 本文件仅作 $r() 语义别名层，调用方改动最小。
 */
export class AppColors {
  /** 品牌主色·手术青：标题、主按钮、选中态、强调文字 */
  static readonly primary: ResourceStr = $r('app.color.app_color_primary');
  static readonly onPrimary: ResourceStr = $r('app.color.app_color_on_primary');
  /** 页面背景·冷调浅青灰：根级页面底色 */
  static readonly background: ResourceStr = $r('app.color.app_color_background');
  /** 卡片白：卡片/输入框底色、深色底上的反白文字 */
  static readonly card: ResourceStr = $r('app.color.app_color_card');
  /** 辅助灰青：说明文字、次要信息（取值同 tierInfo） */
  static readonly textSecondary: ResourceStr = $r('app.color.app_color_text_secondary');
  /** 危险红：删除等危险操作（取值同 tierDanger） */
  static readonly danger: ResourceStr = $r('app.color.app_color_danger');
  /** 预警琥珀：分节标记、警示强调 */
  static readonly warning: ResourceStr = $r('app.color.app_color_warning');
  /** 中性填充·冷灰：未选中按钮/标签底色 */
  static readonly fillNeutral: ResourceStr = $r('app.color.app_color_fill_neutral');

  /** 分级色·正常/低危·绿 */
  static readonly tierOk: ResourceStr = $r('app.color.app_color_tier_ok');
  /** 分级色·轻中度/中危·琥珀 */
  static readonly tierWarn: ResourceStr = $r('app.color.app_color_tier_warn');
  /** 分级色·重度/高危·红 */
  static readonly tierDanger: ResourceStr = $r('app.color.app_color_tier_danger');
  /** 分级色·信息/中性·灰青 */
  static readonly tierInfo: ResourceStr = $r('app.color.app_color_tier_info');

  /** 分级底色·正常·浅绿 */
  static readonly tierOkBg: ResourceStr = $r('app.color.app_color_tier_ok_bg');
  /** 分级底色·预警·浅琥珀 */
  static readonly tierWarnBg: ResourceStr = $r('app.color.app_color_tier_warn_bg');
  /** 分级底色·危险·浅红 */
  static readonly tierDangerBg: ResourceStr = $r('app.color.app_color_tier_danger_bg');
  /** 分级底色·信息·浅灰 */
  static readonly tierInfoBg: ResourceStr = $r('app.color.app_color_tier_info_bg');

  // ─── 中性色 ───
  /** 正文深色：字段标签、输入文字、主要正文 */
  static readonly textPrimary: ResourceStr = $r('app.color.app_color_text_primary');
  /** 正文灰青：脚注、描述段落、表格正文 */
  static readonly textBody: ResourceStr = $r('app.color.app_color_text_body');
  /** 未选中选项文字灰青：切换/选项按钮未选态文字（=textSecondary） */
  static readonly textOption: ResourceStr = $r('app.color.app_color_text_option');
  /** 输入占位灰 */
  static readonly placeholder: ResourceStr = $r('app.color.app_color_placeholder');
  /** 极浅提示灰：分隔符、来源标注、极次要信息 */
  static readonly textFaint: ResourceStr = $r('app.color.app_color_text_faint');
  /** 描边冷灰：输入框/卡片描边 */
  static readonly border: ResourceStr = $r('app.color.app_color_border');
  /** 冷灰分隔线：Divider、细边（与 border 统一） */
  static readonly divider: ResourceStr = $r('app.color.app_color_divider');
  /** 冷灰填充：次级按钮/标签底色（与 fillNeutral 同值） */
  static readonly fillBeige: ResourceStr = $r('app.color.app_color_fill_beige');
  /** 浅冷区块底：区块/代码块/徽章底 */
  static readonly surfaceMuted: ResourceStr = $r('app.color.app_color_surface_muted');
  /** 近白浅底：弱化卡片底、编辑区底 */
  static readonly surfaceSubtle: ResourceStr = $r('app.color.app_color_surface_subtle');

  // ─── 功能强调色 ───
  /** 浅底上的琥珀警示文字：警示徽章/条件级证据文字 */
  static readonly warningText: ResourceStr = $r('app.color.app_color_warning_text');
  /** 知识库强调青：h2 边条、引用竖条、项目符 */
  static readonly kbAccent: ResourceStr = $r('app.color.app_color_kb_accent');
  /** 知识库品牌青：h3 标题、分类色板 */
  static readonly kbDeepGreen: ResourceStr = $r('app.color.app_color_kb_deep_green');
  /** 知识库暖棕：分类色板 */
  static readonly kbWarmBrown: ResourceStr = $r('app.color.app_color_kb_warm_brown');
  /** AI/LLM 靛蓝：LLM 提示、AI 内容标记 */
  static readonly aiAccent: ResourceStr = $r('app.color.app_color_ai_accent');
  /** AI/LLM 浅靛底 */
  static readonly aiAccentBg: ResourceStr = $r('app.color.app_color_ai_accent_bg');
  /** 信息蓝：证据分级 GPS/良好实践级 */
  static readonly infoAccent: ResourceStr = $r('app.color.app_color_info_accent');
  /** 信息蓝浅底 */
  static readonly infoAccentBg: ResourceStr = $r('app.color.app_color_info_accent_bg');

  // ─── 数据域分组色 ───
  /** 电解质·青蓝 */
  static readonly domainElectrolyte: ResourceStr = $r('app.color.app_color_domain_electrolyte');
  /** 肾功能·蓝 */
  static readonly domainKidney: ResourceStr = $r('app.color.app_color_domain_kidney');
  /** 肝功能·暖棕 */
  static readonly domainLiver: ResourceStr = $r('app.color.app_color_domain_liver');
  /** 炎症标志物·琥珀 */
  static readonly domainInflammation: ResourceStr = $r('app.color.app_color_domain_inflammation');
  /** 心肌标志物·红 */
  static readonly domainCardiacMarker: ResourceStr = $r('app.color.app_color_domain_cardiac_marker');
  /** 神经·紫 */
  static readonly domainNeuro: ResourceStr = $r('app.color.app_color_domain_neuro');
  /** 内分泌·橄榄绿 */
  static readonly domainEndocrine: ResourceStr = $r('app.color.app_color_domain_endocrine');
  /** 肌肉·灰青 */
  static readonly domainMuscle: ResourceStr = $r('app.color.app_color_domain_muscle');

  // ─── 深青顶栏 ───
  /** 顶栏背景·深青：所有页面头部统一底色 */
  static readonly headerBg: ResourceStr = $r('app.color.app_color_header_bg');
  /** 顶栏文字·白：标题、图标、操作文字 */
  static readonly headerText: ResourceStr = $r('app.color.app_color_header_text');

  // ─── Tab ───
  /** Tab 未选中态：灰青图标+文字 */
  static readonly tabInactive: ResourceStr = $r('app.color.app_color_tab_inactive');

  // ─── Sidebar ───
  /** 分组隔线：primary 低透明度独立 token */
  static readonly groupLine: ResourceStr = $r('app.color.app_color_group_line');
}
