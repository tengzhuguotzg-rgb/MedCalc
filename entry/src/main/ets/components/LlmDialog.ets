import { CALCULATORS } from '../model/CalculatorRegistry';
import { PreferencesService } from '../services/PreferencesService';
import {
  ApiServiceConfig, LlmRecommendation, sendClarifyRound,
  ClarifyQuestion, ChatMessage, CLARIFY_DIMENSIONS, ClarifyDimension,
  LlmModelConfig
} from '../services/LlmService';
import { AppColors } from '../utils/AppColors';
import { display } from '@kit.ArkUI';

@Component
export struct LlmDialog {
  @Link currentCalc: string;
  @Prop pageMode: boolean = false;
  onPickCalc: (calcId: string) => void = () => {};
  onCalculate: (calcId: string) => void = () => {};
  @State isOpen: boolean = false;
  @State userInput: string = '';
  @State errorMsg: string = '';
  @State fabRight: number = 24;
  @State fabBottom: number = 24;
  private fabSize: number = 48;
  private maxRight: number = 400;
  private maxBottom: number = 800;

  // 状态机: input -> questionnaire -> thinking -> clarify(可选) -> result
  @State phase: string = 'input';
  @State results: LlmRecommendation[] = [];
  @State recommendSummary: string = '';

  // R1 问卷状态
  @State r1Selections: Record<string, string[]> = {}; // multi 维度存数组
  @State r1SingleSelections: Record<string, string> = {}; // single 维度存字符串

  // R2 LLM 追问状态
  @State r2Questions: ClarifyQuestion[] = [];
  @State r2Selections: Record<string, string[]> = {}; // multi
  @State r2SingleSelections: Record<string, string> = {}; // single
  @State chatMessages: ChatMessage[] = [];

  // LLM 切换
  @State llmModels: LlmModelConfig[] = [];
  @State selectedLlmId: string = '';

  // 计算结果回填（监听 bindSheet 中计算器的结果）
  @StorageProp('activeCalcId') activeCalcId: string = '';
  @Watch('onSheetResultChange') @StorageLink('sheetCalcTimestamp') sheetCalcTimestamp: number = 0;
  @StorageProp('sheetCalcId') sheetCalcId: string = '';
  @StorageProp('sheetCalcValue') sheetCalcValue: number | null = null;
  @StorageProp('sheetCalcTier') sheetCalcTier: string = '';
  @StorageProp('sheetCalcTierClass') sheetCalcTierClass: string = '';
  @StorageProp('sheetCalcValueText') sheetCalcValueText: string = '';
  // 存储每个推荐计算器的计算结果 { calcId: "value||tier||tierClass||valueText" }
  @State calcResults: Record<string, string> = {};

  // bindSheet 中计算器结果变化时，存到 calcResults
  onSheetResultChange(): void {
    const calcId = this.sheetCalcId;
    if (calcId.length > 0 && this.sheetCalcTimestamp > 0) {
      // 优先用格式化后的 valueText，fallback 对 value 做一位小数格式化
      const valStr = this.sheetCalcValueText.length > 0
        ? this.sheetCalcValueText
        : (this.sheetCalcValue !== null ? this.sheetCalcValue.toFixed(1) : '');
      const data = `${valStr}||${this.sheetCalcTier}||${this.sheetCalcTierClass}||${this.sheetCalcValueText}`;
      const newResults: Record<string, string> = {};
      const keys = Object.keys(this.calcResults);
      for (let i = 0; i < keys.length; i++) {
        newResults[keys[i]] = this.calcResults[keys[i]];
      }
      newResults[calcId] = data;
      this.calcResults = newResults;
    }
  }

  // 获取某计算器的计算结果，返回 {value, tier, tierClass} 或 null
  getCalcResult(calcId: string): string {
    const data = this.calcResults[calcId];
    return data ? data : '';
  }

  // 格式化计算结果为紧凑显示文本
  formatCalcResult(calcId: string): string {
    const data = this.getCalcResult(calcId);
    if (data.length === 0) {
      return '';
    }
    const parts = data.split('||');
    const valStr = parts[0] || '';
    const tier = parts[1] || '';
    if (valStr.length > 0 && tier.length > 0) {
      return `${valStr} · ${tier}`;
    }
    return valStr.length > 0 ? valStr : tier;
  }

  aboutToAppear() {
    if (!this.pageMode) {
      try {
        const d = display.getDefaultDisplaySync();
        this.maxRight = Math.max(100, d.width / 160 - this.fabSize);
        this.maxBottom = Math.max(100, d.height / 160 - this.fabSize);
      } catch (e) {
      }
    }
    this.refreshLlmModels();
    if (this.pageMode) {
      this.restoreState();
    }
  }

  aboutToDisappear() {
    if (this.pageMode) {
      this.saveState();
    }
  }

  // 保存推荐状态到 AppStorage（pageMode 跳转计算器前调用）
  saveState(): void {
    if (!this.pageMode) {
      return;
    }
    try {
      AppStorage.setOrCreate('llmRecPhase', this.phase);
      AppStorage.setOrCreate('llmRecUserInput', this.userInput);
      AppStorage.setOrCreate('llmRecSummary', this.recommendSummary);
      // 序列化 results
      const recsData: string[] = [];
      for (let i = 0; i < this.results.length; i++) {
        recsData.push(`${this.results[i].id}||${this.results[i].name}||${this.results[i].reason}`);
      }
      AppStorage.setOrCreate('llmRecResults', recsData);
      const crData: string[] = [];
      const crKeys = Object.keys(this.calcResults);
      for (let i = 0; i < crKeys.length; i++) {
        crData.push(`${crKeys[i]}||${this.calcResults[crKeys[i]]}`);
      }
      AppStorage.setOrCreate('llmRecCalcResults', crData);
    } catch (e) {
    }
  }

  // 从 AppStorage 恢复推荐状态
  restoreState(): void {
    try {
      const savedPhase = AppStorage.get<string>('llmRecPhase');
      if (savedPhase && savedPhase.length > 0) {
        this.phase = savedPhase;
        this.userInput = AppStorage.get<string>('llmRecUserInput') ?? '';
        this.recommendSummary = AppStorage.get<string>('llmRecSummary') ?? '';
        const recsData = AppStorage.get<string[]>('llmRecResults');
        if (recsData && recsData.length > 0) {
          const recs: LlmRecommendation[] = [];
          for (let i = 0; i < recsData.length; i++) {
            const parts = recsData[i].split('||');
            if (parts.length >= 3) {
              recs.push({ id: parts[0], name: parts[1], reason: parts[2] });
            }
          }
          this.results = recs;
        }
        const crData = AppStorage.get<string[]>('llmRecCalcResults');
        if (crData && crData.length > 0) {
          const cr: Record<string, string> = {};
          for (let i = 0; i < crData.length; i++) {
            const sepIdx = crData[i].indexOf('||');
            if (sepIdx > 0) {
              cr[crData[i].substring(0, sepIdx)] = crData[i].substring(sepIdx + 2);
            }
          }
          this.calcResults = cr;
        }
      }
    } catch (e) {
    }
  }
  private touchDownX: number = 0;
  private touchDownY: number = 0;
  private isMoving: boolean = false;

  private prefsService = PreferencesService.getInstance();

  getActiveService(): ApiServiceConfig | null {
    return this.prefsService.getActiveLlmConfig();
  }

  getActiveServiceName(): string {
    const s = this.getActiveService();
    return s ? s.name : '未配置';
  }

  refreshLlmModels(): void {
    this.llmModels = this.prefsService.getLlmModels();
    this.selectedLlmId = this.prefsService.getSelectedLlmId();
  }

  switchLlm(id: string): void {
    this.prefsService.saveSelectedLlmId(id);
    this.selectedLlmId = id;
  }

  getCalcDescription(calcId: string): string {
    const calc = CALCULATORS.find((c): boolean => c.id === calcId);
    return calc ? calc.description : '';
  }

  // 发送初始查询 -> 进入 R1 问卷
  sendQuery(): void {
    const trimmedInput = this.userInput.trim();
    if (!trimmedInput) {
      return;
    }
    const active = this.getActiveService();
    if (!active) {
      this.errorMsg = '请先在设置中配置 API 服务';
      return;
    }

    this.errorMsg = '';
    this.results = [];
    this.recommendSummary = '';
    this.r1Selections = {};
    this.r1SingleSelections = {};
    this.r2Questions = [];
    this.r2Selections = {};
    this.r2SingleSelections = {};
    this.chatMessages = [];
    this.phase = 'questionnaire';
  }

  // R1: 多选维度切换
  toggleMulti(dimKey: string, option: string, isR2: boolean): void {
    const oldStore = isR2 ? this.r2Selections : this.r1Selections;
    const oldArr = oldStore[dimKey] ? oldStore[dimKey] : [];
    // 创建新数组（不修改原数组）
    const newArr: string[] = [];
    for (let i = 0; i < oldArr.length; i++) {
      newArr.push(oldArr[i]);
    }
    const idx = newArr.indexOf(option);
    if (idx >= 0) {
      newArr.splice(idx, 1);
    } else {
      newArr.push(option);
    }
    // 创建新 Record 整体赋值（触发 @State 更新）
    const newStore: Record<string, string[]> = {};
    const keys = Object.keys(oldStore);
    for (let i = 0; i < keys.length; i++) {
      newStore[keys[i]] = oldStore[keys[i]];
    }
    newStore[dimKey] = newArr;
    if (isR2) {
      this.r2Selections = newStore;
    } else {
      this.r1Selections = newStore;
    }
  }

  // R1: 单选维度切换
  toggleSingle(dimKey: string, option: string, isR2: boolean): void {
    const oldStore = isR2 ? this.r2SingleSelections : this.r1SingleSelections;
    const newStore: Record<string, string> = {};
    const keys = Object.keys(oldStore);
    for (let i = 0; i < keys.length; i++) {
      newStore[keys[i]] = oldStore[keys[i]];
    }
    newStore[dimKey] = option;
    if (isR2) {
      this.r2SingleSelections = newStore;
    } else {
      this.r1SingleSelections = newStore;
    }
  }

  // 获取多选维度的已选项
  getMultiSelected(dimKey: string, isR2: boolean): string[] {
    const store = isR2 ? this.r2Selections : this.r1Selections;
    return store[dimKey] ? store[dimKey] : [];
  }

  // 获取单选维度的已选项
  getSingleSelected(dimKey: string, isR2: boolean): string {
    const store = isR2 ? this.r2SingleSelections : this.r1SingleSelections;
    const v = store[dimKey];
    return v ? v : '';
  }

  // 检查 R1 问卷是否全部选完
  r1AllSelected(): boolean {
    for (let i = 0; i < CLARIFY_DIMENSIONS.length; i++) {
      const dim = CLARIFY_DIMENSIONS[i];
      if (dim.multi) {
        if (this.getMultiSelected(dim.key, false).length === 0) {
          return false;
        }
      } else {
        if (this.getSingleSelected(dim.key, false).length === 0) {
          return false;
        }
      }
    }
    return true;
  }

  // 检查 R2 追问是否全部选完
  r2AllSelected(): boolean {
    for (let i = 0; i < this.r2Questions.length; i++) {
      const q = this.r2Questions[i];
      if (q.multi) {
        if (this.getMultiSelected(q.dimension, true).length === 0) {
          return false;
        }
      } else {
        if (this.getSingleSelected(q.dimension, true).length === 0) {
          return false;
        }
      }
    }
    return this.r2Questions.length > 0;
  }

  // 格式化 R1 问卷答案为文本
  formatR1Answers(): string {
    const parts: string[] = [];
    for (let i = 0; i < CLARIFY_DIMENSIONS.length; i++) {
      const dim = CLARIFY_DIMENSIONS[i];
      if (dim.multi) {
        const sel = this.getMultiSelected(dim.key, false);
        if (sel.length > 0) {
          parts.push(`${dim.label}: ${sel.join('+')}`);
        }
      } else {
        const sel = this.getSingleSelected(dim.key, false);
        if (sel.length > 0) {
          parts.push(`${dim.label}: ${sel}`);
        }
      }
    }
    return parts.join('；');
  }

  // 格式化 R2 追问答案为文本
  formatR2Answers(): string {
    const parts: string[] = [];
    for (let i = 0; i < this.r2Questions.length; i++) {
      const q = this.r2Questions[i];
      if (q.multi) {
        const sel = this.getMultiSelected(q.dimension, true);
        if (sel.length > 0) {
          parts.push(`${q.prompt} ${sel.join('+')}`);
        }
      } else {
        const sel = this.getSingleSelected(q.dimension, true);
        if (sel.length > 0) {
          parts.push(`${q.prompt} ${sel}`);
        }
      }
    }
    return parts.join('；');
  }

  // R1 提交问卷 -> 调 LLM (R2)
  submitQuestionnaire(): void {
    const active = this.getActiveService();
    if (!active) {
      this.errorMsg = '请先在设置中配置 API 服务';
      return;
    }

    const r1Text = this.formatR1Answers();
    this.chatMessages = [
      { role: 'user', content: this.userInput.trim() },
      { role: 'user', content: `问卷结果：${r1Text}` }
    ];
    this.phase = 'thinking';
    this.callLlm(active);
  }

  // R2 提交追问 -> 调 LLM
  submitR2Clarify(): void {
    const active = this.getActiveService();
    if (!active) {
      this.errorMsg = '请先在设置中配置 API 服务';
      return;
    }

    const r2Text = this.formatR2Answers();
    this.chatMessages.push({ role: 'user', content: r2Text });
    this.phase = 'thinking';
    this.callLlm(active);
  }

  // 跳过 R2 追问，直接推荐
  skipR2Clarify(): void {
    const active = this.getActiveService();
    if (!active) {
      this.errorMsg = '请先在设置中配置 API 服务';
      return;
    }
    this.chatMessages.push({ role: 'user', content: '跳过追问，请直接推荐' });
    this.phase = 'thinking';
    this.callLlm(active, true);
  }

  // 调用 LLM
  callLlm(config: ApiServiceConfig, forceRecommend: boolean = false): void {
    let msgs = this.chatMessages;
    if (forceRecommend) {
      msgs = msgs.concat([{ role: 'user', content: '请直接给出推荐' }]);
    }

    sendClarifyRound(config, msgs).then((resp) => {
      if (resp.action === 'recommend' || forceRecommend) {
        this.results = resp.recommendations;
        this.recommendSummary = resp.summary;
        this.phase = 'result';
        if (resp.recommendations.length === 0) {
          this.errorMsg = '未找到匹配的计算器，请尝试更详细的描述';
          setTimeout(() => { this.errorMsg = ''; }, 3000);
        }
      } else if (resp.questions.length > 0) {
        // LLM 返回追问
        this.r2Questions = resp.questions;
        this.r2Selections = {};
        this.r2SingleSelections = {};
        this.phase = 'clarify';
      } else {
        // questions 为空，直接推荐
        this.results = resp.recommendations;
        this.recommendSummary = resp.summary;
        this.phase = 'result';
        if (resp.recommendations.length === 0) {
          this.errorMsg = '未找到匹配的计算器，请尝试更详细的描述';
          setTimeout(() => { this.errorMsg = ''; }, 3000);
        }
      }
    }).catch((_err: Error) => {
      this.phase = 'questionnaire';
      this.errorMsg = '请求失败，请重试';
      setTimeout(() => { this.errorMsg = ''; }, 3000);
    });
  }

  jumpToCalculator(id: string): void {
    if (id) {
      this.currentCalc = id;
      // pageMode 下保存推荐状态，切回来时恢复
      if (this.pageMode) {
        this.saveState();
        this.onPickCalc(id);
      } else {
        this.closeDialog();
      }
    }
  }

  closeDialog(): void {
    // pageMode 下无弹层开合概念，仅重置问诊状态回到 input 阶段
    if (!this.pageMode) {
      this.isOpen = false;
    }
    this.userInput = '';
    this.results = [];
    this.recommendSummary = '';
    this.errorMsg = '';
    this.phase = 'input';
    this.r1Selections = {};
    this.r1SingleSelections = {};
    this.r2Questions = [];
    this.r2Selections = {};
    this.r2SingleSelections = {};
    this.chatMessages = [];
    this.calcResults = {};
  }

  // 重置：清空所有内容回到最初形态
  resetAll(): void {
    this.closeDialog();
    // pageMode 下清除 AppStorage 保存的状态
    if (this.pageMode) {
      try {
        AppStorage.setOrCreate('llmRecPhase', '');
        AppStorage.setOrCreate('llmRecUserInput', '');
        AppStorage.setOrCreate('llmRecSummary', '');
        AppStorage.setOrCreate('llmRecResults', []);
      } catch (e) {
      }
    }
  }

  build() {
    if (this.pageMode) {
      // 页面模式：HeaderBar固定 + 中间内容滚动 + 底部输入栏（对齐 AssistantPage 布局）
      Column() {
        this.DialogHeader();

        Scroll() {
          Column() {
            this.ActiveServiceBar();
            if (this.phase === 'questionnaire') {
              this.QuestionnaireArea();
            }
            if (this.phase === 'thinking') {
              this.ThinkingArea();
            }
            if (this.phase === 'clarify') {
              this.ClarifyArea();
            }
            this.StatusArea();
            if (this.phase === 'result') {
              this.ResultArea();
            }
            if (this.phase === 'input') {
              this.WelcomeCard();
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .align(Alignment.Top)

        this.PageInputBar();
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.background)
    } else if (this.isOpen) {
      Stack() {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(AppColors.overlay)
          .onClick(() => {
            this.closeDialog();
          })

        Column() {
          Scroll() {
            Column() {
              this.DialogHeader();
              this.ActiveServiceBar();
              this.InputArea();
              if (this.phase === 'questionnaire') {
                this.QuestionnaireArea();
              }
              if (this.phase === 'thinking') {
                this.ThinkingArea();
              }
              if (this.phase === 'clarify') {
                this.ClarifyArea();
              }
              this.StatusArea();
              if (this.phase === 'result') {
                this.ResultArea();
              }
            }
            .width('100%')
            .padding(20)
          }
          .width('100%')
          .height('100%')
          .align(Alignment.Top)
        }
        .width('95%')
        .constraintSize({ maxHeight: '92%' })
        .backgroundColor(AppColors.card)
        .borderRadius(16)
        .shadow({ radius: 16, color: 'rgba(0,0,0,0.15)', offsetY: 8 })
      }
      .width('100%')
      .height('100%')
    } else {
      Button() {
        Text('💬').fontSize(22).fontColor(AppColors.onPrimary)
      }
      .width(52)
      .height(52)
      .borderRadius(26)
      .backgroundColor(AppColors.primary)
      .shadow({ radius: 8, color: 'rgba(0,0,0,0.25)', offsetY: 4 })
      .position({ bottom: this.fabBottom, right: this.fabRight })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.touchDownX = event.touches[0].x;
          this.touchDownY = event.touches[0].y;
          this.isMoving = false;
        } else if (event.type === TouchType.Move) {
          const dx = event.touches[0].x - this.touchDownX;
          const dy = event.touches[0].y - this.touchDownY;
          if (Math.abs(dx) > 10 || Math.abs(dy) > 10) {
            this.isMoving = true;
          }
          if (this.isMoving) {
            this.fabRight = Math.max(0, Math.min(this.maxRight, this.fabRight - dx));
            this.fabBottom = Math.max(0, Math.min(this.maxBottom, this.fabBottom - dy));
            this.touchDownX = event.touches[0].x;
            this.touchDownY = event.touches[0].y;
          }
        } else if (event.type === TouchType.Up) {
          if (!this.isMoving) {
            this.refreshLlmModels();
            this.isOpen = true;
          }
        }
      })
    }
  }

  @Builder
  DialogHeader() {
    Row() {
      Text('LLM 推荐计算器')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.primary)
        .layoutWeight(1)

      if (this.pageMode) {
        // pageMode: 垃圾桶重置按钮
        Button() {
          Text('🗑')
            .fontSize(16)
            .fontColor(AppColors.textSecondary)
        }
        .width(44)
        .height(44)
        .backgroundColor('transparent')
        .onClick(() => {
          this.resetAll();
        })
      } else {
        // 弹窗模式: ✕ 关闭按钮
        Button() {
          Text('✕')
            .fontSize(16)
            .fontColor(AppColors.textSecondary)
        }
        .width(32)
        .height(32)
        .backgroundColor('transparent')
        .onClick(() => {
          this.closeDialog();
        })
      }
    }
    .width('100%')
    .height(44)
    .padding({ left: 16, right: 16 })
    .backgroundColor(AppColors.card)
    .border({ width: { bottom: 1 }, color: AppColors.divider })
  }

  // 获取当前选中模型的显示名（含供应商）
  getActiveDisplayName(): string {
    for (let i = 0; i < this.llmModels.length; i++) {
      if (this.llmModels[i].id === this.selectedLlmId) {
        const m = this.llmModels[i];
        const provider = m.provider.length > 0 ? m.provider : '默认';
        return `${provider} - ${m.name}`;
      }
    }
    return '未配置';
  }

  // 构建 LLM 菜单项
  buildLlmMenuItems(): MenuElement[] {
    const items: MenuElement[] = [];
    for (let i = 0; i < this.llmModels.length; i++) {
      const m = this.llmModels[i];
      const provider = m.provider.length > 0 ? m.provider : '默认';
      const prefix = m.id === this.selectedLlmId ? '✓ ' : '  ';
      items.push({
        value: `${prefix}${provider} - ${m.name}`,
        action: () => {
          this.switchLlm(m.id);
        }
      });
    }
    return items;
  }

  @Builder
  ActiveServiceBar() {
    Row() {
      Text('模型：')
        .fontSize(11)
        .fontColor(AppColors.textSecondary)
      Text(this.getActiveDisplayName())
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor(AppColors.primary)
      if (this.llmModels.length > 1) {
        Text(' ▼')
          .fontSize(11)
          .fontColor(AppColors.primary)
      }
      Blank()
    }
    .width('100%')
    .padding({ bottom: 8 })
    .bindMenu(this.llmModels.length > 1 ? this.buildLlmMenuItems() : [])
  }

  @Builder
  InputArea() {
    Column() {
      TextArea({ text: this.userInput, placeholder: '描述病情，如：评估脑出血病人的预后' })
        .height(80)
        .backgroundColor(AppColors.background)
        .borderRadius(8)
        .fontSize(13)
        .onChange((value: string) => {
          this.userInput = value;
        })

      Button() {
        Text('开始问诊').fontSize(14).fontColor(AppColors.onPrimary)
      }
      .width('100%')
      .height(40)
      .backgroundColor(AppColors.primary)
      .borderRadius(8)
      .margin({ top: 8 })
      .enabled(this.userInput.trim().length > 0 && this.phase === 'input')
      .onClick(() => {
        this.sendQuery();
      })
    }
    .width('100%')
    .margin({ bottom: 12 })
  }

  // pageMode 专用底部输入栏（对齐 AssistantPage InputBar 样式）
  @Builder
  PageInputBar() {
    Column() {
      Row() {
        TextArea({ text: this.userInput, placeholder: '描述病情，如：评估脑出血病人的预后' })
          .height(48)
          .fontSize(14)
          .layoutWeight(1)
          .backgroundColor(AppColors.background)
          .borderRadius(8)
          .padding({ left: 10, right: 10, top: 8, bottom: 8 })
          .onChange((value: string) => {
            this.userInput = value;
          })

        Button() {
          if (this.phase === 'thinking') {
            LoadingProgress()
              .width(18)
              .height(18)
              .color(AppColors.onPrimary)
          } else {
            Text('➤')
              .fontSize(18)
              .fontColor(AppColors.onPrimary)
          }
        }
        .width(40)
        .height(48)
        .backgroundColor(this.phase === 'thinking' ? AppColors.textSecondary : AppColors.primary)
        .borderRadius(20)
        .margin({ left: 8 })
        .enabled(this.userInput.trim().length > 0 && this.phase === 'input')
        .onClick(() => {
          this.sendQuery();
        })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .backgroundColor(AppColors.card)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .backgroundColor(AppColors.card)
  }

  // pageMode 专用欢迎卡（input 阶段显示，对齐 AssistantPage WelcomeCard 方框样式）
  @Builder
  WelcomeCard() {
    Column() {
      Text('LLM 推荐计算器')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.primary)
      Text('描述病情或临床问题，通过问诊推荐最匹配的计算器')
        .fontSize(12)
        .fontColor(AppColors.textSecondary)
        .margin({ top: 4 })
        .textAlign(TextAlign.Center)
      Column() {
        Text('示例输入：').fontSize(12).fontColor(AppColors.textSecondary).margin({ bottom: 4 })
        Text('• 恶心呕吐').fontSize(12).fontColor(AppColors.textBody)
        Text('• 评估脑出血病人预后').fontSize(12).fontColor(AppColors.textBody)
        Text('• 胸痛').fontSize(12).fontColor(AppColors.textBody)
      }
      .margin({ top: 8 })
      .padding(8)
      .backgroundColor(AppColors.surfaceSubtle)
      .borderRadius(8)
    }
    .width('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(AppColors.card)
    .borderRadius(12)
    .margin({ top: 24 })
  }

  @Builder
  QuestionnaireArea() {
    Column() {
      Text('📋 基本信息问卷')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.primary)
        .width('100%')
        .margin({ bottom: 4 })

      Text('请选择以下信息，帮助精准定位计算器')
        .fontSize(11)
        .fontColor(AppColors.textSecondary)
        .width('100%')
        .margin({ bottom: 16 })

      ForEach(CLARIFY_DIMENSIONS, (dim: ClarifyDimension) => {
        Column() {
          Row() {
            Text(dim.label)
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.textPrimary)
            Text(dim.multi ? '（可多选）' : '')
              .fontSize(10)
              .fontColor(AppColors.textSecondary)
          }
          .width('100%')
          .margin({ bottom: 6 })

          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(dim.options, (opt: string) => {
              Text(opt)
                .fontSize(12)
                .fontColor(dim.multi
                  ? (this.getMultiSelected(dim.key, false).indexOf(opt) >= 0 ? AppColors.onPrimary : AppColors.textPrimary)
                  : (this.getSingleSelected(dim.key, false) === opt ? AppColors.onPrimary : AppColors.textPrimary))
                .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                .margin({ right: 6, bottom: 6 })
                .borderRadius(14)
                .backgroundColor(dim.multi
                  ? (this.getMultiSelected(dim.key, false).indexOf(opt) >= 0 ? AppColors.primary : AppColors.fillBeige)
                  : (this.getSingleSelected(dim.key, false) === opt ? AppColors.primary : AppColors.fillBeige))
                .onClick(() => {
                  if (dim.multi) {
                    this.toggleMulti(dim.key, opt, false);
                  } else {
                    this.toggleSingle(dim.key, opt, false);
                  }
                })
            }, (opt: string) => `${dim.key}-${opt}`)
          }
          .width('100%')
        }
        .width('100%')
        .margin({ bottom: 14 })
      }, (dim: ClarifyDimension) => dim.key)

      Button('提交问卷，开始分析 ->')
        .fontSize(13)
        .fontColor(AppColors.onPrimary)
        .backgroundColor(this.r1AllSelected() ? AppColors.primary : AppColors.textSecondary)
        .borderRadius(8)
        .height(40)
        .width('100%')
        .enabled(this.r1AllSelected())
        .onClick(() => {
          this.submitQuestionnaire();
        })
    }
    .width('100%')
    .margin({ bottom: 12 })
  }

  @Builder
  ThinkingArea() {
    Row() {
      LoadingProgress()
        .width(16)
        .height(16)
        .color(AppColors.primary)
      Text('分析中...')
        .fontSize(12)
        .fontColor(AppColors.textSecondary)
        .margin({ left: 8 })
    }
    .width('100%')
    .padding(12)
    .margin({ bottom: 12 })
  }

  @Builder
  ClarifyArea() {
    Column() {
      // 显示已收集的 R1 信息
      Row() {
        Text(this.formatR1Answers())
          .fontSize(11)
          .fontColor(AppColors.textSecondary)
      }
      .width('100%')
      .padding(8)
      .backgroundColor(AppColors.surfaceSubtle)
      .borderRadius(6)
      .margin({ bottom: 12 })

      Text('🔍 进一步追问')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.primary)
        .width('100%')
        .margin({ bottom: 12 })

      ForEach(this.r2Questions, (q: ClarifyQuestion) => {
        Column() {
          Row() {
            Text(q.prompt)
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.textPrimary)
            Text(q.multi ? '（可多选）' : '')
              .fontSize(10)
              .fontColor(AppColors.textSecondary)
          }
          .width('100%')
          .margin({ bottom: 6 })

          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(q.options, (opt: string) => {
              Text(opt)
                .fontSize(12)
                .fontColor(q.multi
                  ? (this.getMultiSelected(q.dimension, true).indexOf(opt) >= 0 ? AppColors.onPrimary : AppColors.textPrimary)
                  : (this.getSingleSelected(q.dimension, true) === opt ? AppColors.onPrimary : AppColors.textPrimary))
                .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                .margin({ right: 6, bottom: 6 })
                .borderRadius(14)
                .backgroundColor(q.multi
                  ? (this.getMultiSelected(q.dimension, true).indexOf(opt) >= 0 ? AppColors.primary : AppColors.fillBeige)
                  : (this.getSingleSelected(q.dimension, true) === opt ? AppColors.primary : AppColors.fillBeige))
                .onClick(() => {
                  if (q.multi) {
                    this.toggleMulti(q.dimension, opt, true);
                  } else {
                    this.toggleSingle(q.dimension, opt, true);
                  }
                })
            }, (opt: string) => `${q.dimension}-${opt}`)
          }
          .width('100%')
        }
        .width('100%')
        .margin({ bottom: 12 })
      }, (q: ClarifyQuestion) => q.dimension)

      Button('确认，获取推荐 ->')
        .fontSize(13)
        .fontColor(AppColors.onPrimary)
        .backgroundColor(this.r2AllSelected() ? AppColors.primary : AppColors.textSecondary)
        .borderRadius(8)
        .height(40)
        .width('100%')
        .margin({ bottom: 6 })
        .enabled(this.r2AllSelected())
        .onClick(() => {
          this.submitR2Clarify();
        })

      Button('跳过，直接推荐')
        .fontSize(12)
        .fontColor(AppColors.primary)
        .backgroundColor(AppColors.fillBeige)
        .borderRadius(8)
        .height(34)
        .width('100%')
        .onClick(() => {
          this.skipR2Clarify();
        })
    }
    .width('100%')
    .margin({ bottom: 12 })
  }

  @Builder
  StatusArea() {
    if (this.errorMsg) {
      Row() {
        Text('⚠ ')
          .fontSize(12)
          .fontColor(AppColors.warning)
        Text(this.errorMsg)
          .fontSize(12)
          .fontColor(AppColors.warning)
      }
      .width('100%')
      .padding(8)
      .backgroundColor(AppColors.tierWarnBg)
      .borderRadius(6)
      .margin({ bottom: 12 })
    }
  }

  @Builder
  ResultArea() {
    if (this.results.length > 0) {
      Column() {
        Text('✅ 推荐结果')
          .fontSize(11)
          .fontColor(AppColors.textSecondary)
          .width('100%')
          .margin({ bottom: 8 })

        if (this.recommendSummary.length > 0) {
          Row() {
            Text('💡 ')
              .fontSize(12)
            Text(this.recommendSummary)
              .fontSize(12)
              .fontColor(AppColors.textBody)
              .layoutWeight(1)
          }
          .width('100%')
          .padding(10)
          .backgroundColor(AppColors.surfaceSubtle)
          .borderRadius(8)
          .margin({ bottom: 10 })
        }

        ForEach(this.results, (rec: LlmRecommendation, index: number) => {
          this.RecommendationCard(rec, index + 1);
        }, (rec: LlmRecommendation) => rec.id)
      }
      .width('100%')
    }
  }

  @Builder
  RecommendationCard(rec: LlmRecommendation, rank: number) {
    Column() {
      Row() {
        Text(`${rank}`)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.onPrimary)
          .width(20)
          .height(20)
          .borderRadius(10)
          .backgroundColor(AppColors.primary)
          .textAlign(TextAlign.Center)
          .margin({ right: 8 })

        Column() {
          Text(rec.name)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.primary)
            .width('100%')

          if (rec.reason && rec.reason.length > 0) {
            Row() {
              Text('💬')
                .fontSize(11)
                .margin({ right: 4 })
              Text(rec.reason)
                .fontSize(11)
                .fontColor(AppColors.textBody)
                .layoutWeight(1)
            }
            .width('100%')
            .margin({ top: 2 })
          }

          Text(this.getCalcDescription(rec.id))
            .fontSize(11)
            .fontColor(AppColors.textBody)
            .width('100%')
            .margin({ top: 2 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      // 计算按钮 + 结果显示框
      Row() {
        Button(this.getCalcResult(rec.id).length > 0 ? '重算' : '计算')
          .fontSize(11)
          .fontColor(this.getCalcResult(rec.id).length > 0 ? AppColors.primary : AppColors.onPrimary)
          .backgroundColor(this.getCalcResult(rec.id).length > 0 ? AppColors.fillBeige : AppColors.primary)
          .borderRadius(6)
          .height(28)
          .padding({ left: 10, right: 10 })
          .onClick(() => {
            this.onCalculate(rec.id);
          })
        Row() {
          Text(this.getCalcResult(rec.id).length > 0 ? this.formatCalcResult(rec.id) : '')
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.primary)
            .layoutWeight(1)
        }
        .height(28)
        .layoutWeight(1)
        .padding({ left: 10, right: 10 })
        .margin({ left: 6 })
        .backgroundColor(AppColors.card)
        .borderRadius(6)
        .border({ width: 1, color: AppColors.border })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .margin({ top: 6 })

      // 跳转按钮（保留，去常规模式看完整计算器）
      Button('跳转 ->')
        .fontSize(12)
        .fontColor(AppColors.primary)
        .backgroundColor(AppColors.fillBeige)
        .borderRadius(6)
        .height(28)
        .width('100%')
        .margin({ top: 4 })
        .onClick(() => {
          this.jumpToCalculator(rec.id);
        })
    }
    .width('100%')
    .padding(12)
    .backgroundColor(AppColors.surfaceSubtle)
    .borderRadius(8)
    .margin({ bottom: 8 })
  }
}
