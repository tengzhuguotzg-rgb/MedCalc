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
}
