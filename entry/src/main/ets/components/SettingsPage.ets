import { LlmModelConfig, LlmFormat, ApiServiceConfig, sendVisionRequest } from '../services/LlmService';
import { PreferencesService } from '../services/PreferencesService';
import { AppColors } from '../utils/AppColors';
import { AppDimens } from '../utils/AppDimens';

let settingsLlmIdCounter: number = 0;

function settingsGenerateLlmId(): string {
  settingsLlmIdCounter++;
  return `llm_${settingsLlmIdCounter}`;
}

@Component
export struct SettingsPage {
  @State llmModels: LlmModelConfig[] = [];
  @State selectedLlmId: string = '';
  @State showLlmDialog: boolean = false;
  @State llmDialogMode: string = '';
  @State editLlmId: string = '';
  @State editLlmName: string = '';
  @State editLlmProvider: string = '';
  @State editLlmFormat: LlmFormat = LlmFormat.OPENAI;
  @State editLlmBaseUrl: string = '';
  @State editLlmApiKey: string = '';
  @State editLlmModelNames: string = '';
  @State addToProviderName: string = '';
  @State addToProviderModelName: string = '';
  @State testingLlmId: string = '';
  @State testResultId: string = '';
  @State testResultOk: boolean = false;
  @State testResultMsg: string = '';

  private prefsService = PreferencesService.getInstance();

  aboutToAppear() {
    this.llmModels = this.prefsService.getLlmModels();
    this.selectedLlmId = this.prefsService.getSelectedLlmId();
  }

  persistLlm(): void {
    this.prefsService.saveLlmModels(this.llmModels, this.selectedLlmId);
  }

  getGroupedProviders(): string[] {
    const providers: string[] = [];
    const seen: Map<string, boolean> = new Map();
    for (let i = 0; i < this.llmModels.length; i++) {
      const p: string = this.llmModels[i].provider.length > 0 ? this.llmModels[i].provider : '其他';
      if (!seen.has(p)) {
        seen.set(p, true);
        providers.push(p);
      }
    }
    return providers;
  }

  getLlmsByProvider(provider: string): LlmModelConfig[] {
    const result: LlmModelConfig[] = [];
    for (let i = 0; i < this.llmModels.length; i++) {
      const p: string = this.llmModels[i].provider.length > 0 ? this.llmModels[i].provider : '其他';
      if (p === provider) {
        result.push(this.llmModels[i]);
      }
    }
    return result;
  }

  getFirstLlmOfProvider(provider: string): LlmModelConfig | null {
    for (let i = 0; i < this.llmModels.length; i++) {
      const p: string = this.llmModels[i].provider.length > 0 ? this.llmModels[i].provider : '其他';
      if (p === provider) {
        return this.llmModels[i];
      }
    }
    return null;
  }

  selectLlm(id: string): void {
    this.selectedLlmId = id;
    this.persistLlm();
  }

  openAddLlm(): void {
    this.llmDialogMode = 'add';
    this.editLlmId = '';
    this.editLlmName = '';
    this.editLlmProvider = '';
    this.editLlmFormat = LlmFormat.OPENAI;
    this.editLlmBaseUrl = '';
    this.editLlmApiKey = '';
    this.editLlmModelNames = '';
    this.showLlmDialog = true;
  }

  openAddToProvider(provider: string): void {
    this.llmDialogMode = 'addToProvider';
    this.addToProviderName = provider;
    this.addToProviderModelName = '';
    this.showLlmDialog = true;
  }

  openEditLlm(llm: LlmModelConfig): void {
    this.llmDialogMode = 'edit';
    this.editLlmId = llm.id;
    this.editLlmName = llm.name;
    this.editLlmProvider = llm.provider;
    this.editLlmFormat = llm.format;
    this.editLlmBaseUrl = llm.baseUrl;
    this.editLlmApiKey = llm.apiKey;
    this.editLlmModelNames = llm.modelName;
    this.showLlmDialog = true;
  }

  saveLlm(): void {
    if (this.editLlmBaseUrl.length === 0 || this.editLlmApiKey.length === 0) {
      return;
    }
    if (this.llmDialogMode === 'edit' && this.editLlmId.length > 0) {
      for (let i = 0; i < this.llmModels.length; i++) {
        if (this.llmModels[i].id === this.editLlmId) {
          this.llmModels[i].name = this.editLlmName;
          this.llmModels[i].provider = this.editLlmProvider;
          this.llmModels[i].format = this.editLlmFormat;
          this.llmModels[i].baseUrl = this.editLlmBaseUrl;
          this.llmModels[i].apiKey = this.editLlmApiKey;
          this.llmModels[i].modelName = this.editLlmName;
          break;
        }
      }
      this.llmModels = [...this.llmModels];
    } else if (this.llmDialogMode === 'addToProvider') {
      if (this.addToProviderModelName.length === 0) {
        return;
      }
      const first: LlmModelConfig | null = this.getFirstLlmOfProvider(this.addToProviderName);
      if (first === null) {
        return;
      }
      const realProvider: string = this.addToProviderName === '其他' ? '' : this.addToProviderName;
      const newId: string = settingsGenerateLlmId();
      const newLlm: LlmModelConfig = new LlmModelConfig(
        newId, this.addToProviderModelName, realProvider, first.format, first.baseUrl, first.apiKey, this.addToProviderModelName
      );
      this.llmModels = [...this.llmModels, newLlm];
      this.showLlmDialog = false;
      this.addToProviderModelName = '';
      this.persistLlm();
      return;
    } else {
      const names: string[] = this.editLlmModelNames.split('\n');
      const newModels: LlmModelConfig[] = [];
      for (let i = 0; i < names.length; i++) {
        const n: string = names[i].trim();
        if (n.length > 0) {
          const newId: string = 'llm-' + Date.now().toString() + '-' + i.toString();
          newModels.push(new LlmModelConfig(
            newId, n, this.editLlmProvider, this.editLlmFormat, this.editLlmBaseUrl, this.editLlmApiKey, n
          ));
        }
      }
      if (newModels.length > 0) {
        this.llmModels = [...this.llmModels, ...newModels];
        if (this.selectedLlmId.length === 0) {
          this.selectedLlmId = newModels[0].id;
        }
      }
    }
    this.showLlmDialog = false;
    this.persistLlm();
  }

  removeLlm(id: string): void {
    const models: LlmModelConfig[] = [];
    for (let i = 0; i < this.llmModels.length; i++) {
      if (this.llmModels[i].id !== id) {
        models.push(this.llmModels[i]);
      }
    }
    this.llmModels = models;
    if (this.selectedLlmId === id) {
      if (models.length > 0) {
        this.selectedLlmId = models[0].id;
      } else {
        this.selectedLlmId = '';
      }
    }
    this.persistLlm();
  }

  testLlm(llm: LlmModelConfig): void {
    this.testingLlmId = llm.id;
    this.testResultId = '';
    const config: ApiServiceConfig = llm.toApiServiceConfig();
    sendVisionRequest(config, 'You are a helpful assistant.', 'Say OK', '', '').then((_: string) => {
      this.testingLlmId = '';
      this.testResultId = llm.id;
      this.testResultOk = true;
      this.testResultMsg = '连接正常';
    }).catch((_err: Error) => {
      this.testingLlmId = '';
      this.testResultId = llm.id;
      this.testResultOk = false;
      this.testResultMsg = _err.message.substring(0, 60);
    });
  }

  build() {
    Column() {
      Row() {
        Text('设置')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.primary)
      }
      .width('100%')
      .height(AppDimens.touchTarget)
      .padding({ left: 16, right: 16 })
      .backgroundColor(AppColors.card)
      .border({ width: { bottom: 1 }, color: '#E0DCC8' })

      Scroll() {
        Column({ space: 16 }) {
          Text('LLM 服务配置')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.primary)
            .width('100%')

          Text('配置 AI 服务的 API 地址和密钥，计算器和智能助手共用')
            .fontSize(12)
            .fontColor(AppColors.textSecondary)
            .width('100%')

          Column({ space: 8 }) {
            if (this.llmModels.length === 0) {
              Column() {
                Text('暂无 LLM 服务')
                  .fontSize(14)
                  .fontColor(AppColors.textSecondary)
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .margin({ top: 12, bottom: 12 })
                Text('请点击下方按钮添加')
                  .fontSize(12)
                  .fontColor(AppColors.textSecondary)
                  .width('100%')
                  .textAlign(TextAlign.Center)
              }
              .width('100%')
              .padding(AppDimens.cardPadding)
              .backgroundColor('#F9F8F3')
              .borderRadius(8)
            }

            ForEach(this.getGroupedProviders(), (provider: string) => {
              Column({ space: 4 }) {
                Row() {
                  Text(provider)
                    .fontSize(13)
                    .fontColor(AppColors.primary)
                    .fontWeight(FontWeight.Medium)
                  Row().width(8).height(1).backgroundColor('#E8E5D8').layoutWeight(1)
                  Button('+')
                    .fontSize(14)
                    .fontColor(AppColors.primary)
                    .backgroundColor('#E8E5D8')
                    .width(28)
                    .height(28)
                    .borderRadius(14)
                    .padding(0)
                    .onClick(() => {
                      this.openAddToProvider(provider);
                    })
                }
                .width('100%')

                ForEach(this.getLlmsByProvider(provider), (llm: LlmModelConfig) => {
                  Row() {
                    Radio({ value: llm.id, group: 'llmSelect' })
                      .checked(llm.id === this.selectedLlmId)
                      .onChange((isChecked: boolean) => {
                        if (isChecked) {
                          this.selectLlm(llm.id);
                        }
                      })
                      .width(20)
                      .height(20)
                    Column({ space: 2 }) {
                      Text(llm.name)
                        .fontSize(14)
                        .fontColor(this.selectedLlmId === llm.id ? AppColors.primary : '#4A5247')
                      Text(llm.baseUrl.replace(/^https?:\/\//, '') + (llm.modelName.length > 0 ? ' · ' + llm.modelName : ''))
                        .fontSize(10)
                        .fontColor(AppColors.textSecondary)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                      if (this.testResultId === llm.id) {
                        Text(this.testResultOk ? '连接成功: ' + this.testResultMsg : '连接失败: ' + this.testResultMsg)
                          .fontSize(10)
                          .fontColor(this.testResultOk ? AppColors.tierOk : AppColors.danger)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                      }
                    }
                    .layoutWeight(1)
                    .margin({ left: 6 })
                    .alignItems(HorizontalAlign.Start)

                    Row({ space: 4 }) {
                      Button(this.testingLlmId === llm.id ? '...' : '测试')
                        .fontSize(10)
                        .backgroundColor(this.testingLlmId === llm.id ? '#E8E5D8' : '#F0EDE3')
                        .fontColor(AppColors.primary)
                        .height(22)
                        .borderRadius(3)
                        .enabled(this.testingLlmId.length === 0)
                        .onClick(() => {
                          this.testLlm(llm);
                        })
                      Button('编辑')
                        .fontSize(10)
                        .backgroundColor('#F0EDE3')
                        .fontColor(AppColors.primary)
                        .height(22)
                        .borderRadius(3)
                        .margin({ left: 4 })
                        .onClick(() => {
                          this.openEditLlm(llm);
                        })
                      Button('删除')
                        .fontSize(10)
                        .backgroundColor('#FFF0F0')
                        .fontColor(AppColors.danger)
                        .height(22)
                        .borderRadius(3)
                        .margin({ left: 4 })
                        .onClick(() => {
                          this.removeLlm(llm.id);
                        })
                    }
                  }
                  .width('100%')
                  .padding(8)
                  .margin({ left: 16 })
                }, (llm: LlmModelConfig) => llm.id)
              }
              .width('100%')
            }, (provider: string) => provider)

            Button('+ 添加服务商')
              .fontSize(14)
              .fontColor(AppColors.primary)
              .backgroundColor('#E8E5D8')
              .borderRadius(8)
              .height(40)
              .width('100%')
              .margin({ top: 4 })
              .onClick(() => {
                this.openAddLlm();
              })
          }
          .width('100%')
          .padding(AppDimens.cardPadding)
          .backgroundColor(AppColors.card)
          .borderRadius(AppDimens.cardRadius)

          Text('关于')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.primary)
            .width('100%')

          Column({ space: 4 }) {
            Text('重症智算 v1.0')
              .fontSize(14)
              .fontColor(AppColors.primary)
            Text('智能医学评分计算器')
              .fontSize(12)
              .fontColor(AppColors.textSecondary)
          }
          .width('100%')
          .padding(AppDimens.cardPadding)
          .backgroundColor(AppColors.card)
          .borderRadius(AppDimens.cardRadius)
        }
        .padding(AppDimens.cardPadding)
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.background)
    .bindSheet($$this.showLlmDialog, this.LlmDialogBuilder(), {
      height: SheetSize.FIT_CONTENT,
      dragBar: true,
      backgroundColor: Color.White,
      onWillDisappear: () => { this.showLlmDialog = false; }
    })
  }

  @Builder
  LlmDialogBuilder() {
    if (this.llmDialogMode === 'addToProvider') {
      Column({ space: 16 }) {
        Text('添加模型到「' + this.addToProviderName + '」')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.primary)
          .width('100%')

        Column({ space: 4 }) {
          Text('模型名称')
            .fontSize(13)
            .fontColor(AppColors.textSecondary)
            .width('100%')
          TextInput({ placeholder: '如 deepseek-chat', text: this.addToProviderModelName })
            .fontSize(14)
            .fontColor(AppColors.primary)
            .backgroundColor(AppColors.background)
            .borderRadius(8)
            .onChange((v: string) => { this.addToProviderModelName = v; })
        }
        .width('100%')

        Text('将复用该服务商下已有模型的 API 格式、URL 和 Key')
          .fontSize(11)
          .fontColor(AppColors.textSecondary)
          .width('100%')

        Row({ space: 12 }) {
          Button('取消')
            .fontSize(14)
            .backgroundColor('#E8E5D8')
            .fontColor(AppColors.textSecondary)
            .height(40)
            .borderRadius(8)
            .layoutWeight(1)
            .onClick(() => { this.showLlmDialog = false; })
          Button('确认')
            .fontSize(14)
            .backgroundColor(AppColors.primary)
            .fontColor(Color.White)
            .height(40)
            .borderRadius(8)
            .layoutWeight(1)
            .onClick(() => { this.saveLlm(); })
        }
        .width('100%')
      }
      .padding(24)
      .width('100%')
    } else {
      Column({ space: 16 }) {
        Text(this.llmDialogMode === 'edit' ? '编辑 LLM' : '添加 LLM')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.primary)
          .width('100%')

        Column({ space: 12 }) {
          Column({ space: 4 }) {
            Text('服务商')
              .fontSize(13)
              .fontColor(AppColors.textSecondary)
              .width('100%')
            TextInput({ placeholder: '如 DeepSeek、OpenAI、MiniMax', text: this.editLlmProvider })
              .fontSize(14)
              .fontColor(AppColors.primary)
              .backgroundColor(AppColors.background)
              .borderRadius(8)
              .onChange((v: string) => { this.editLlmProvider = v; })
          }
          .width('100%')

          Column({ space: 4 }) {
            Text(this.llmDialogMode === 'edit' ? '模型名称' : '模型名称（每行一个，可同时添加多个）')
              .fontSize(13)
              .fontColor(AppColors.textSecondary)
              .width('100%')
            if (this.llmDialogMode === 'edit') {
              TextInput({ placeholder: '如 deepseek-chat', text: this.editLlmName })
                .fontSize(14)
                .fontColor(AppColors.primary)
                .backgroundColor(AppColors.background)
                .borderRadius(8)
                .onChange((v: string) => { this.editLlmName = v; })
            } else {
              TextArea({ placeholder: 'deepseek-chat\ngpt-4o-mini', text: this.editLlmModelNames })
                .fontSize(14)
                .fontColor(AppColors.primary)
                .backgroundColor(AppColors.background)
                .borderRadius(8)
                .height(80)
                .onChange((v: string) => { this.editLlmModelNames = v; })
            }
          }
          .width('100%')

          Row() {
            Text('API 格式')
              .fontSize(14)
              .fontColor(AppColors.primary)
              .layoutWeight(1)
            Row({ space: 16 }) {
              Row() {
                Radio({ value: 'openai', group: 'editLlmFormat' })
                  .checked(this.editLlmFormat === LlmFormat.OPENAI)
                  .onChange((isChecked: boolean) => {
                    if (isChecked) { this.editLlmFormat = LlmFormat.OPENAI; }
                  })
                  .width(20)
                  .height(20)
                Text('OpenAI')
                  .fontSize(14)
                  .fontColor(AppColors.primary)
                  .margin({ left: 4 })
              }
              Row() {
                Radio({ value: 'anthropic', group: 'editLlmFormat' })
                  .checked(this.editLlmFormat === LlmFormat.ANTHROPIC)
                  .onChange((isChecked: boolean) => {
                    if (isChecked) { this.editLlmFormat = LlmFormat.ANTHROPIC; }
                  })
                  .width(20)
                  .height(20)
                Text('Anthropic')
                  .fontSize(14)
                  .fontColor(AppColors.primary)
                  .margin({ left: 4 })
              }
            }
          }
          .width('100%')

          Column({ space: 4 }) {
            Text('API Base URL')
              .fontSize(13)
              .fontColor(AppColors.textSecondary)
              .width('100%')
            TextInput({ placeholder: 'https://api.deepseek.com', text: this.editLlmBaseUrl })
              .fontSize(14)
              .fontColor(AppColors.primary)
              .backgroundColor(AppColors.background)
              .borderRadius(8)
              .onChange((v: string) => { this.editLlmBaseUrl = v; })
          }
          .width('100%')

          Column({ space: 4 }) {
            Text('API Key')
              .fontSize(13)
              .fontColor(AppColors.textSecondary)
              .width('100%')
            TextInput({ placeholder: '请输入 API Key', text: this.editLlmApiKey })
              .fontSize(14)
              .fontColor(AppColors.primary)
              .backgroundColor(AppColors.background)
              .borderRadius(8)
              .type(InputType.Password)
              .onChange((v: string) => { this.editLlmApiKey = v; })
          }
          .width('100%')
        }
        .width('100%')

        Row({ space: 12 }) {
          Button('取消')
            .fontSize(14)
            .backgroundColor('#E8E5D8')
            .fontColor(AppColors.textSecondary)
            .height(40)
            .borderRadius(8)
            .layoutWeight(1)
            .onClick(() => { this.showLlmDialog = false; })
          Button('确认')
            .fontSize(14)
            .backgroundColor(AppColors.primary)
            .fontColor(Color.White)
            .height(40)
            .borderRadius(8)
            .layoutWeight(1)
            .onClick(() => { this.saveLlm(); })
        }
        .width('100%')
      }
      .padding(24)
      .width('100%')
    }
  }
}
