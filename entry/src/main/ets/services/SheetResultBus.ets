/**
 * SheetResultBus
 * --------------------------------------------------------------
 * 类型安全封装散落在 AppStorage 里的 12 个裸键。
 *
 * 三组键的用途：
 *  1. sheetCalc* (7)  —— 当前计算器弹层的结果（ResultCard 写入，
 *                       LlmDialog / Index 通过 @StorageProp/@StorageLink 读取）
 *  2. activeCalcId    —— 标记当前活跃计算器；ResultCard 仅在
 *                       activeCalcId 与自身 calcId 一致时才会写入 sheetCalc*
 *  3. llmRec* (4)     —— LLM 推荐对话框跨页面跳转时的状态暂存
 *
 * 既存代码里的对应位置：
 *   - entry/src/main/ets/components/calculators/widgets/CalcWidgets.ets
 *   - entry/src/main/ets/components/LlmDialog.ets
 *   - entry/src/main/ets/pages/Index.ets
 *
 * 使用方式：所有方法都是 static，直接 SheetResultBus.setSheetCalcValue(...) 调用。
 */

export class SheetResultBus {
  // ---------- 键常量 ----------
  private static readonly KEY_SHEET_CALC_ID: string = 'sheetCalcId';
  private static readonly KEY_SHEET_CALC_VALUE: string = 'sheetCalcValue';
  private static readonly KEY_SHEET_CALC_UNIT: string = 'sheetCalcUnit';
  private static readonly KEY_SHEET_CALC_TIER: string = 'sheetCalcTier';
  private static readonly KEY_SHEET_CALC_TIER_CLASS: string = 'sheetCalcTierClass';
  private static readonly KEY_SHEET_CALC_VALUE_TEXT: string = 'sheetCalcValueText';
  private static readonly KEY_SHEET_CALC_TIMESTAMP: string = 'sheetCalcTimestamp';

  private static readonly KEY_ACTIVE_CALC_ID: string = 'activeCalcId';

  private static readonly KEY_LLM_REC_PHASE: string = 'llmRecPhase';
  private static readonly KEY_LLM_REC_USER_INPUT: string = 'llmRecUserInput';
  private static readonly KEY_LLM_REC_SUMMARY: string = 'llmRecSummary';
  private static readonly KEY_LLM_REC_RESULTS: string = 'llmRecResults';
  private static readonly KEY_LLM_REC_CALC_RESULTS: string = 'llmRecCalcResults';

  // ============================================================
  // sheetCalc* —— 当前计算器弹层结果
  // ============================================================

  static setSheetCalcId(value: string): void {
    AppStorage.setOrCreate(SheetResultBus.KEY_SHEET_CALC_ID, value);
  }

  static getSheetCalcId(): string {
    return AppStorage.get<string>(SheetResultBus.KEY_SHEET_CALC_ID) ?? '';
  }

  static setSheetCalcValue(value: number | null): void {
    AppStorage.setOrCreate(SheetResultBus.KEY_SHEET_CALC_VALUE, value);
  }

  static getSheetCalcValue(): number | null {
    return AppStorage.get<number | null>(SheetResultBus.KEY_SHEET_CALC_VALUE) ?? null;
  }

  static setSheetCalcUnit(value: string): void {
    AppStorage.setOrCreate(SheetResultBus.KEY_SHEET_CALC_UNIT, value);
  }

  static getSheetCalcUnit(): string {
    return AppStorage.get<string>(SheetResultBus.KEY_SHEET_CALC_UNIT) ?? '';
  }

  static setSheetCalcTier(value: string): void {
    AppStorage.setOrCreate(SheetResultBus.KEY_SHEET_CALC_TIER, value);
  }

  static getSheetCalcTier(): string {
    return AppStorage.get<string>(SheetResultBus.KEY_SHEET_CALC_TIER) ?? '';
  }

  static setSheetCalcTierClass(value: string): void {
    AppStorage.setOrCreate(SheetResultBus.KEY_SHEET_CALC_TIER_CLASS, value);
  }

  static getSheetCalcTierClass(): string {
    return AppStorage.get<string>(SheetResultBus.KEY_SHEET_CALC_TIER_CLASS) ?? '';
  }

  static setSheetCalcValueText(value: string): void {
    AppStorage.setOrCreate(SheetResultBus.KEY_SHEET_CALC_VALUE_TEXT, value);
  }

  static getSheetCalcValueText(): string {
    return AppStorage.get<string>(SheetResultBus.KEY_SHEET_CALC_VALUE_TEXT) ?? '';
  }

  static setSheetCalcTimestamp(value: number): void {
    AppStorage.setOrCreate(SheetResultBus.KEY_SHEET_CALC_TIMESTAMP, value);
  }

  static getSheetCalcTimestamp(): number {
    return AppStorage.get<number>(SheetResultBus.KEY_SHEET_CALC_TIMESTAMP) ?? 0;
  }

  // ============================================================
  // activeCalcId —— 当前活跃计算器（控制 ResultCard 是否写入）
  // ============================================================

  static setActiveCalcId(id: string): void {
    AppStorage.setOrCreate(SheetResultBus.KEY_ACTIVE_CALC_ID, id);
  }

  static getActiveCalcId(): string {
    return AppStorage.get<string>(SheetResultBus.KEY_ACTIVE_CALC_ID) ?? '';
  }

  static clearActiveCalcId(): void {
    AppStorage.setOrCreate(SheetResultBus.KEY_ACTIVE_CALC_ID, '');
  }

  // ============================================================
  // llmRec* —— LLM 推荐对话框跨页状态
  // ============================================================

  static setLlmRecPhase(value: string): void {
    AppStorage.setOrCreate(SheetResultBus.KEY_LLM_REC_PHASE, value);
  }

  static getLlmRecPhase(): string {
    return AppStorage.get<string>(SheetResultBus.KEY_LLM_REC_PHASE) ?? '';
  }

  static setLlmRecUserInput(value: string): void {
    AppStorage.setOrCreate(SheetResultBus.KEY_LLM_REC_USER_INPUT, value);
  }

  static getLlmRecUserInput(): string {
    return AppStorage.get<string>(SheetResultBus.KEY_LLM_REC_USER_INPUT) ?? '';
  }

  static setLlmRecSummary(value: string): void {
    AppStorage.setOrCreate(SheetResultBus.KEY_LLM_REC_SUMMARY, value);
  }

  static getLlmRecSummary(): string {
    return AppStorage.get<string>(SheetResultBus.KEY_LLM_REC_SUMMARY) ?? '';
  }

  static setLlmRecResults(value: string[]): void {
    AppStorage.setOrCreate(SheetResultBus.KEY_LLM_REC_RESULTS, value);
  }

  static getLlmRecResults(): string[] {
    return AppStorage.get<string[]>(SheetResultBus.KEY_LLM_REC_RESULTS) ?? [];
  }

  // ============================================================
  // 批量清空
  // ============================================================

  /**
   * 清空全部 7 个 sheetCalc* 键。
   * 保留 activeCalcId 与 llmRec* 不动。
   */
  static clearSheetResult(): void {
    AppStorage.setOrCreate(SheetResultBus.KEY_SHEET_CALC_ID, '');
    AppStorage.setOrCreate(SheetResultBus.KEY_SHEET_CALC_VALUE, null);
    AppStorage.setOrCreate(SheetResultBus.KEY_SHEET_CALC_UNIT, '');
    AppStorage.setOrCreate(SheetResultBus.KEY_SHEET_CALC_TIER, '');
    AppStorage.setOrCreate(SheetResultBus.KEY_SHEET_CALC_TIER_CLASS, '');
    AppStorage.setOrCreate(SheetResultBus.KEY_SHEET_CALC_VALUE_TEXT, '');
    AppStorage.setOrCreate(SheetResultBus.KEY_SHEET_CALC_TIMESTAMP, 0);
  }

  /**
   * 清空全部 4 个 llmRec* 键。
   * 保留 sheetCalc* 与 activeCalcId 不动。
   */
  static clearLlmRecState(): void {
    AppStorage.setOrCreate(SheetResultBus.KEY_LLM_REC_PHASE, '');
    AppStorage.setOrCreate(SheetResultBus.KEY_LLM_REC_USER_INPUT, '');
    AppStorage.setOrCreate(SheetResultBus.KEY_LLM_REC_SUMMARY, '');
    AppStorage.setOrCreate(SheetResultBus.KEY_LLM_REC_RESULTS, []);
  }
}
