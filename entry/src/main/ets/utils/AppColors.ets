/**
 * AppColors —— 全局色彩设计 token
 *
 * 全 App 色值的唯一定义处。调色只改本文件。
 * 命名按语义用途而非色相；注释标注对应原色值与用途。
 *
 * 品牌色板：深绿主色 + 米色背景 + 白卡片 + 灰绿辅助色；
 * 分级色（tier）与 CalcEngine.getTierColor/getTierBgColor 共用本组常量，
 * 禁止在其他文件中重新字面量定义。
 */
export class AppColors {
  /** 品牌主色·深绿（原 #1F3D2F）：标题、主按钮、选中态、强调文字 */
  static readonly primary: string = '#1F3D2F';
  /** 页面背景·米（原 #F4F1EA）：根级页面底色 */
  static readonly background: string = '#F4F1EA';
  /** 卡片白（原 #FFFFFF）：卡片/输入框底色、深色底上的反白文字 */
  static readonly card: string = '#FFFFFF';
  /** 辅助灰绿（原 #5F6654）：说明文字、次要信息（取值同 tierInfo） */
  static readonly textSecondary: string = '#5F6654';
  /** 危险红（原 #B1452A）：删除等危险操作（取值同 tierDanger） */
  static readonly danger: string = '#B1452A';
  /** 预警橙（原 #E76F2C）：分节标记、警示强调 */
  static readonly warning: string = '#E76F2C';
  /** 中性填充·浅灰（原 #F5F5F5）：未选中按钮/标签底色（取值同 tierInfoBg） */
  static readonly fillNeutral: string = '#F5F5F5';

  /** 分级色·正常/低危·绿（原 #3D6B4F） */
  static readonly tierOk: string = '#3D6B4F';
  /** 分级色·轻中度/中危·琥珀（原 #C8881A） */
  static readonly tierWarn: string = '#C8881A';
  /** 分级色·重度/高危·红（取值同 danger，原 #B1452A） */
  static readonly tierDanger: string = AppColors.danger;
  /** 分级色·信息/中性·灰绿（取值同 textSecondary，原 #5F6654） */
  static readonly tierInfo: string = AppColors.textSecondary;

  /** 分级底色·正常·浅绿（原 #E8F5E9） */
  static readonly tierOkBg: string = '#E8F5E9';
  /** 分级底色·预警·浅琥珀（原 #FFF8E1） */
  static readonly tierWarnBg: string = '#FFF8E1';
  /** 分级底色·危险·浅红（原 #FFEBEE） */
  static readonly tierDangerBg: string = '#FFEBEE';
  /** 分级底色·信息·浅灰（取值同 fillNeutral，原 #F5F5F5） */
  static readonly tierInfoBg: string = AppColors.fillNeutral;

  // ─── 中性色 ───
  /** 正文深色（原 #1F2421）：字段标签、输入文字、主要正文 */
  static readonly textPrimary: string = '#1F2421';
  /** 正文灰绿（原 #4A5247）：脚注、描述段落、表格正文（并收编 #3A3F35/#5A5F4E） */
  static readonly textBody: string = '#4A5247';
  /** 未选中选项文字绿（原 #2D5440）：切换/选项按钮未选态文字 */
  static readonly textOption: string = '#2D5440';
  /** 输入占位灰（原 #999999）：placeholder */
  static readonly placeholder: string = '#999999';
  /** 极浅提示灰（原 #B0B0A8）：分隔符、来源标注、极次要信息（并收编 #9A9E94/#9B9E8E） */
  static readonly textFaint: string = '#B0B0A8';
  /** 描边灰（原 #E0E0E0）：输入框/卡片描边 */
  static readonly border: string = '#E0E0E0';
  /** 米色分隔线（原 #E0DCC8）：Divider、暖色细边（并收编 #E8DCC8） */
  static readonly divider: string = '#E0DCC8';
  /** 米灰填充（原 #E8E5D8）：次级按钮/标签底色（并收编 #E8E6DA） */
  static readonly fillBeige: string = '#E8E5D8';
  /** 浅米区块底（原 #F5F4EF）：区块/代码块/徽章底（并收编 #F0EDE3/#F0EDE2/#F1EEE2/#F5F5F0） */
  static readonly surfaceMuted: string = '#F5F4EF';
  /** 近白浅底（原 #F9F8F3）：弱化卡片底、编辑区底（并收编 #FAFAF5/#FAFAFA） */
  static readonly surfaceSubtle: string = '#F9F8F3';

  // ─── 功能强调色（保留原值，多色设计） ───
  /** 浅底上的琥珀警示文字（原 #9A6B1E）：警示徽章/条件级证据文字 */
  static readonly warningText: string = '#9A6B1E';
  /** 知识库强调绿（原 #4A7C6F）：h2 边条、引用竖条、项目符（并收编 #4A6B5A） */
  static readonly kbAccent: string = '#4A7C6F';
  /** 知识库墨绿（原 #3A5F4F）：h3 标题、分类色板 */
  static readonly kbDeepGreen: string = '#3A5F4F';
  /** 知识库暖棕（原 #8B6B4A）：分类色板 */
  static readonly kbWarmBrown: string = '#8B6B4A';
  /** AI/LLM 紫（原 #7A6B9D）：LLM 提示、AI 内容标记 */
  static readonly aiAccent: string = '#7A6B9D';
  /** AI/LLM 浅紫底（原 #F0EBF5，并收编 #F8F5FF） */
  static readonly aiAccentBg: string = '#F0EBF5';
  /** 信息蓝（原 #2B5C8A）：证据分级 GPS/良好实践级（并收编 #5B7FA5） */
  static readonly infoAccent: string = '#2B5C8A';
  /** 信息蓝浅底（原 #DBEAFE）：证据 GPS 级底色 */
  static readonly infoAccentBg: string = '#DBEAFE';

  // ─── 数据域分组色（DOMAIN_COLORS 专用，多色设计保留原值） ───
  /** 电解质·橄榄绿（原 #6B8E23） */
  static readonly domainElectrolyte: string = '#6B8E23';
  /** 肾功能·橙棕（原 #D4760A） */
  static readonly domainKidney: string = '#D4760A';
  /** 肝功能·暗黄（原 #8B6914） */
  static readonly domainLiver: string = '#8B6914';
  /** 炎症标志物·红（原 #C0392B） */
  static readonly domainInflammation: string = '#C0392B';
  /** 心肌标志物·亮红（原 #E74C3C） */
  static readonly domainCardiacMarker: string = '#E74C3C';
  /** 神经·紫（原 #6B4FA0） */
  static readonly domainNeuro: string = '#6B4FA0';
  /** 内分泌·亮紫（原 #9B59B6） */
  static readonly domainEndocrine: string = '#9B59B6';
  /** 肌肉·橙（原 #E67E22） */
  static readonly domainMuscle: string = '#E67E22';
}
