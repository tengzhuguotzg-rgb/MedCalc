import { LlmModelConfig, LlmFormat, ApiServiceConfig, sendVisionRequest } from '../services/LlmService';
import { PreferencesService } from '../services/PreferencesService';
import { AppColors } from '../utils/AppColors';
import { AppDimens } from '../utils/AppDimens';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { common } from '@kit.AbilityKit';

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
  @State themeMode: string = 'system';

  private prefsService = PreferencesService.getInstance();

  aboutToAppear() {
    this.llmModels = this.prefsService.getLlmModels();
    this.selectedLlmId = this.prefsService.getSelectedLlmId();
    this.themeMode = this.prefsService.getThemeMode();
  }

  persistLlm(): void {
    this.prefsService.saveLlmModels(this.llmModels, this.selectedLlmId);
  }

  applyTheme(mode: string): void {
    this.themeMode = mode;
    this.prefsService.saveThemeMode(mode);
    const ctx = AppStorage.get<common.UIAbilityContext>('context');
    if (ctx === undefined || ctx === null) {
      return;
    }
    let colorMode: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
    if (mode === 'light') {
      colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
    } else if (mode === 'dark') {
      colorMode = ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    }
    ctx.getApplicationContext().setColorMode(colorMode);
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
        Text($r('app.string.settings_title'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.primary)
      }
      .width('100%')
      .height(AppDimens.touchTarget)
      .padding({ left: 16, right: 16 })
      .backgroundColor(AppColors.card)
      .border({ width: { bottom: 1 }, color: AppColors.divider })

      Scroll() {
        Column({ space: 16 }) {
          Text($r('app.string.settings_llm_config'))
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.primary)
            .width('100%')

          Text($r('app.string.settings_llm_desc'))
            .fontSize(12)
            .fontColor(AppColors.textSecondary)
            .width('100%')

          Column({ space: 8 }) {
            if (this.llmModels.length === 0) {
              Column() {
                Text($r('app.string.settings_llm_empty'))
                  .fontSize(14)
                  .fontColor(AppColors.textSecondary)
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .margin({ top: 12, bottom: 12 })
                Text($r('app.string.settings_llm_empty_hint'))
                  .fontSize(12)
                  .fontColor(AppColors.textSecondary)
                  .width('100%')
                  .textAlign(TextAlign.Center)
              }
              .width('100%')
              .padding(AppDimens.cardPadding)
              .backgroundColor(AppColors.surfaceSubtle)
              .borderRadius(8)
            }

            ForEach(this.getGroupedProviders(), (provider: string) => {
              Column({ space: 4 }) {
                Row() {
                  Text(provider)
                    .fontSize(13)
                    .fontColor(AppColors.primary)
                    .fontWeight(FontWeight.Medium)
                  Row().width(8).height(1).backgroundColor(AppColors.fillBeige).layoutWeight(1)
                  Button('+')
                    .fontSize(14)
                    .fontColor(AppColors.primary)
                    .backgroundColor(AppColors.fillBeige)
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
                        .fontColor(this.selectedLlmId === llm.id ? AppColors.primary : AppColors.textBody)
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
                     .backgroundColor(this.testingLlmId === llm.id ? AppColors.fillBeige : AppColors.surfaceMuted)
                     .fontColor(AppColors.primary)
                     .height(22)
                     .borderRadius(3)
                     .enabled(this.testingLlmId.length === 0)
                     .onClick(() => {
                       this.testLlm(llm);
                     })
                       Button($r('app.string.common_edit'))
                        .fontSize(10)
                        .backgroundColor(AppColors.surfaceMuted)
                        .fontColor(AppColors.primary)
                        .height(22)
                        .borderRadius(3)
                        .margin({ left: 4 })
                        .onClick(() => {
                          this.openEditLlm(llm);
                        })
                       Button($r('app.string.common_delete'))
                        .fontSize(10)
                        .backgroundColor(AppColors.tierDangerBg)
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

            Button($r('app.string.settings_add_provider'))
              .fontSize(14)
              .fontColor(AppColors.primary)
              .backgroundColor(AppColors.fillBeige)
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

          Text($r('app.string.settings_appearance'))
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.primary)
            .width('100%')

          Column({ space: 8 }) {
            Row() {
              Radio({ value: 'system', group: 'themeSelect' })
                .checked(this.themeMode === 'system')
                .onChange((isChecked: boolean) => {
                  if (isChecked) { this.applyTheme('system'); }
                })
                .width(20)
                .height(20)
               Text($r('app.string.settings_theme_system'))
                .fontSize(14)
                .fontColor(AppColors.textPrimary)
                .margin({ left: 8 })
            }
            .width('100%')

            Row() {
              Radio({ value: 'light', group: 'themeSelect' })
                .checked(this.themeMode === 'light')
                .onChange((isChecked: boolean) => {
                  if (isChecked) { this.applyTheme('light'); }
                })
                .width(20)
                .height(20)
               Text($r('app.string.settings_theme_light'))
                .fontSize(14)
                .fontColor(AppColors.textPrimary)
                .margin({ left: 8 })
            }
            .width('100%')

            Row() {
              Radio({ value: 'dark', group: 'themeSelect' })
                .checked(this.themeMode === 'dark')
                .onChange((isChecked: boolean) => {
                  if (isChecked) { this.applyTheme('dark'); }
                })
                .width(20)
                .height(20)
               Text($r('app.string.settings_theme_dark'))
                .fontSize(14)
                .fontColor(AppColors.textPrimary)
                .margin({ left: 8 })
            }
            .width('100%')
          }
          .width('100%')
          .padding(AppDimens.cardPadding)
          .backgroundColor(AppColors.card)
          .borderRadius(AppDimens.cardRadius)

          Text($r('app.string.settings_about'))
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.primary)
            .width('100%')

          Column({ space: 4 }) {
             Text($r('app.string.settings_app_name_version'))
              .fontSize(14)
              .fontColor(AppColors.primary)
             Text($r('app.string.settings_app_subtitle'))
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
      backgroundColor: AppColors.card,
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
           Text($r('app.string.settings_model_name'))
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

         Text($r('app.string.settings_reuse_hint'))
          .fontSize(11)
          .fontColor(AppColors.textSecondary)
          .width('100%')

        Row({ space: 12 }) {
           Button($r('app.string.common_cancel'))
            .fontSize(14)
            .backgroundColor(AppColors.fillBeige)
            .fontColor(AppColors.textSecondary)
            .height(40)
            .borderRadius(8)
            .layoutWeight(1)
            .onClick(() => { this.showLlmDialog = false; })
           Button($r('app.string.common_confirm'))
            .fontSize(14)
            .backgroundColor(AppColors.primary)
            .fontColor(AppColors.onPrimary)
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
             Text($r('app.string.settings_provider'))
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
             Text($r('app.string.settings_api_format'))
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
             Text($r('app.string.settings_api_key'))
              .fontSize(13)
              .fontColor(AppColors.textSecondary)
              .width('100%')
             TextInput({ placeholder: $r('app.string.settings_ph_api_key'), text: this.editLlmApiKey })
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
           Button($r('app.string.common_cancel'))
            .fontSize(14)
            .backgroundColor(AppColors.fillBeige)
            .fontColor(AppColors.textSecondary)
            .height(40)
            .borderRadius(8)
            .layoutWeight(1)
            .onClick(() => { this.showLlmDialog = false; })
           Button($r('app.string.common_confirm'))
            .fontSize(14)
            .backgroundColor(AppColors.primary)
            .fontColor(AppColors.onPrimary)
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
