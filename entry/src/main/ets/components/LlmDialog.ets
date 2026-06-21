import { CALCULATORS } from '../model/CalculatorRegistry';
import { PreferencesService } from '../services/PreferencesService';
import { ApiServiceConfig, sendLlmRequest } from '../services/LlmService';

let svcIdCounter: number = 0;

function generateServiceId(): string {
  svcIdCounter++;
  return `svc_${svcIdCounter}`;
}

@Component
export struct LlmDialog {
  @Link isOpen: boolean;
  @Link currentCalc: string;
  @State userInput: string = '';
  @State loading: boolean = false;
  @State resultCalcId: string = '';
  @State resultCalcName: string = '';
  @State errorMsg: string = '';
  @State showSettings: boolean = false;

  @State apiServices: ApiServiceConfig[] = [];
  @State activeServiceId: string = '';
  @State showForm: boolean = false;
  @State editIndex: number = -1;
  @State formName: string = '';
  @State formUrl: string = '';
  @State formKey: string = '';
  @State formModel: string = '';

  private prefsService = PreferencesService.getInstance();

  aboutToAppear() {
    this.apiServices = this.prefsService.getApiServices();
    this.activeServiceId = this.prefsService.getActiveServiceId();
  }

  persistServices(): void {
    this.prefsService.saveApiServices(this.apiServices);
    this.prefsService.saveActiveServiceId(this.activeServiceId);
  }

  getActiveService(): ApiServiceConfig | null {
    for (let i = 0; i < this.apiServices.length; i++) {
      if (this.apiServices[i].id === this.activeServiceId) {
        return this.apiServices[i];
      }
    }
    return null;
  }

  sendQuery(): void {
    const trimmedInput = this.userInput.trim();
    if (!trimmedInput) {
      return;
    }
    const active = this.getActiveService();
    if (!active) {
      this.errorMsg = '请先配置并选择 API 服务（点击右上角 ⚙）';
      return;
    }

    this.errorMsg = '';
    this.resultCalcId = '';
    this.resultCalcName = '';
    this.loading = true;

    sendLlmRequest(active, trimmedInput).then((calcId: string) => {
      this.loading = false;
      this.resultCalcId = calcId;
      const calc = CALCULATORS.find((c): boolean => c.id === calcId);
      this.resultCalcName = calc ? calc.name : calcId;
    }).catch((err: Error) => {
      this.loading = false;
      this.errorMsg = err.message;
    });
  }

  selectService(id: string): void {
    this.activeServiceId = id;
    this.persistServices();
  }

  startAdd(): void {
    this.editIndex = -1;
    this.formName = '';
    this.formUrl = '';
    this.formKey = '';
    this.formModel = '';
    this.showForm = true;
  }

  startEdit(index: number): void {
    this.editIndex = index;
    const s = this.apiServices[index];
    this.formName = s.name;
    this.formUrl = s.baseUrl;
    this.formKey = s.apiKey;
    this.formModel = s.model;
    this.showForm = true;
  }

  cancelForm(): void {
    this.showForm = false;
  }

  saveForm(): void {
    if (!this.formName.trim() || !this.formUrl.trim()) {
      return;
    }
    if (this.editIndex === -1) {
      const svc: ApiServiceConfig = {
        id: generateServiceId(),
        name: this.formName,
        baseUrl: this.formUrl,
        apiKey: this.formKey,
        model: this.formModel
      };
      const updated: ApiServiceConfig[] = [...this.apiServices, svc];
      this.apiServices = updated;
      if (updated.length === 1) {
        this.activeServiceId = svc.id;
      }
    } else {
      const s = this.apiServices[this.editIndex];
      const updated: ApiServiceConfig[] = [...this.apiServices];
      updated[this.editIndex] = {
        id: s.id,
        name: this.formName,
        baseUrl: this.formUrl,
        apiKey: this.formKey,
        model: this.formModel
      };
      this.apiServices = updated;
    }
    this.showForm = false;
    this.persistServices();
  }

  deleteService(index: number): void {
    const deletedId = this.apiServices[index].id;
    const updated: ApiServiceConfig[] = [...this.apiServices];
    updated.splice(index, 1);
    this.apiServices = updated;
    if (this.activeServiceId === deletedId) {
      if (updated.length > 0) {
        this.activeServiceId = updated[0].id;
      } else {
        this.activeServiceId = '';
      }
    }
    if (this.editIndex === index) {
      this.showForm = false;
    }
    this.persistServices();
  }

  getCalcDescription(calcId: string): string {
    const calc = CALCULATORS.find((c): boolean => c.id === calcId);
    return calc ? calc.description : '';
  }

  getActiveServiceName(): string {
    const s = this.getActiveService();
    return s ? s.name : '未选择';
  }

  jumpToCalculator(): void {
    if (this.resultCalcId) {
      this.currentCalc = this.resultCalcId;
      this.closeDialog();
    }
  }

  closeDialog(): void {
    this.isOpen = false;
    this.userInput = '';
    this.resultCalcId = '';
    this.resultCalcName = '';
    this.errorMsg = '';
  }

  build() {
    if (this.isOpen) {
      Stack() {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0,0,0,0.4)')
          .onClick(() => {
            this.closeDialog();
          })

        Column() {
          Scroll() {
            Column() {
              this.DialogHeader();
              if (this.showSettings) {
                this.SettingsPanel();
              } else {
                this.ActiveServiceBar();
                this.InputArea();
                this.StatusArea();
                this.ResultArea();
              }
            }
            .width('100%')
            .padding(20)
          }
          .width('100%')
          .height('100%')
        }
        .width('88%')
        .constraintSize({ maxHeight: '80%' })
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .shadow({ radius: 16, color: 'rgba(0,0,0,0.15)', offsetY: 8 })
      }
      .width('100%')
      .height('100%')
    } else {
      Button() {
        Text('💬').fontSize(22)
      }
      .width(52)
      .height(52)
      .borderRadius(26)
      .backgroundColor('#1F3D2F')
      .shadow({ radius: 8, color: 'rgba(0,0,0,0.25)', offsetY: 4 })
      .position({ bottom: 24, right: 24 })
      .onClick(() => {
        this.isOpen = true;
      })
    }
  }

  @Builder
  DialogHeader() {
    Row() {
      Text('AI 推荐计算器')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1F3D2F')
      Blank()
      Button() {
        Text('⚙')
          .fontSize(16)
          .fontColor(this.showSettings ? '#1F3D2F' : '#7A8074')
      }
      .width(32)
      .height(32)
      .backgroundColor('transparent')
      .onClick(() => {
        this.showSettings = !this.showSettings;
      })
      Button() {
        Text('✕')
          .fontSize(16)
          .fontColor('#7A8074')
      }
      .width(32)
      .height(32)
      .backgroundColor('transparent')
      .margin({ left: 4 })
      .onClick(() => {
        this.closeDialog();
      })
    }
    .width('100%')
    .padding({ bottom: 12 })
  }

  @Builder
  ActiveServiceBar() {
    Row() {
      Text(this.getActiveServiceName())
        .fontSize(11)
        .fontColor('#7A8074')
    }
    .width('100%')
    .padding({ bottom: 8 })
  }

  @Builder
  SettingsPanel() {
    Column() {
      Text('API 服务配置')
        .fontSize(13)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1F3D2F')
        .width('100%')
        .margin({ bottom: 8 })

      if (this.showForm) {
        this.FormPanel();
      } else {
        if (this.apiServices.length === 0) {
          Text('暂无 API 服务，请添加')
            .fontSize(12)
            .fontColor('#7A8074')
            .margin({ top: 4, bottom: 8 })
            .width('100%')
        }
        ForEach(this.apiServices, (svc: ApiServiceConfig) => {
          this.ServiceCard(svc);
        }, (svc: ApiServiceConfig) => svc.id)

        Button('+ 添加服务')
          .fontSize(13)
          .fontColor('#1F3D2F')
          .backgroundColor('#E8E5D8')
          .borderRadius(8)
          .height(36)
          .width('100%')
          .margin({ top: 6 })
          .onClick(() => {
            this.startAdd();
          })
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#F9F8F3')
    .borderRadius(8)
    .margin({ bottom: 12 })
  }

  @Builder
  ServiceCard(svc: ApiServiceConfig) {
    Column() {
      Row() {
        Button() {
          Text(this.activeServiceId === svc.id ? '●' : '○')
            .fontSize(14)
            .fontColor(this.activeServiceId === svc.id ? '#1F3D2F' : '#7A8074')
        }
        .width(24)
        .height(24)
        .backgroundColor('transparent')
        .onClick(() => {
          this.selectService(svc.id);
        })

        Column() {
          Text(svc.name)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F3D2F')
          Text(`${svc.baseUrl.replace(/^https?:\/\//, '')} · ${svc.model}`)
            .fontSize(10)
            .fontColor('#7A8074')
            .margin({ top: 1 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 4 })

        Button('✎')
          .fontSize(13)
          .fontColor('#7A8074')
          .backgroundColor('transparent')
          .width(28)
          .height(28)
          .onClick(() => {
            const idx = this.findServiceIndex(svc.id);
            if (idx >= 0) {
              this.startEdit(idx);
            }
          })
      }
      .width('100%')
      .padding(8)
      .backgroundColor(this.activeServiceId === svc.id ? '#FFFFFF' : 'transparent')
      .borderRadius(6)
    }
    .width('100%')
    .margin({ bottom: 4 })
  }

  findServiceIndex(id: string): number {
    for (let i = 0; i < this.apiServices.length; i++) {
      if (this.apiServices[i].id === id) {
        return i;
      }
    }
    return -1;
  }

  @Builder
  FormPanel() {
    Column() {
      Text(this.editIndex === -1 ? '添加服务' : '编辑服务')
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1F3D2F')
        .width('100%')
        .margin({ bottom: 8 })

      TextInput({ text: this.formName, placeholder: '服务名称（如 我的MiniMax）' })
        .height(36)
        .backgroundColor('#FFFFFF')
        .borderRadius(6)
        .fontSize(12)
        .onChange((value: string) => {
          this.formName = value;
        })

      TextInput({ text: this.formUrl, placeholder: 'Base URL（如 https://api.minimax.chat）' })
        .height(36)
        .backgroundColor('#FFFFFF')
        .borderRadius(6)
        .fontSize(12)
        .margin({ top: 6 })
        .onChange((value: string) => {
          this.formUrl = value;
        })

      TextInput({ text: this.formKey, placeholder: 'API Key' })
        .height(36)
        .backgroundColor('#FFFFFF')
        .borderRadius(6)
        .fontSize(12)
        .type(InputType.Password)
        .margin({ top: 6 })
        .onChange((value: string) => {
          this.formKey = value;
        })

      TextInput({ text: this.formModel, placeholder: '模型名（如 abab6.5s, gpt-4o-mini）' })
        .height(36)
        .backgroundColor('#FFFFFF')
        .borderRadius(6)
        .fontSize(12)
        .margin({ top: 6 })
        .onChange((value: string) => {
          this.formModel = value;
        })

      Row() {
        Button('保存')
          .fontSize(13)
          .fontColor('#FFFFFF')
          .backgroundColor('#1F3D2F')
          .borderRadius(6)
          .height(32)
          .layoutWeight(1)
          .enabled(this.formName.trim().length > 0 && this.formUrl.trim().length > 0)
          .onClick(() => {
            this.saveForm();
          })

        if (this.editIndex >= 0) {
          Button('删除')
            .fontSize(13)
            .fontColor('#B1452A')
            .backgroundColor('#FFF0F0')
            .borderRadius(6)
            .height(32)
            .layoutWeight(1)
            .margin({ left: 6 })
            .onClick(() => {
              this.deleteService(this.editIndex);
            })
        }

        Button('取消')
          .fontSize(13)
          .fontColor('#7A8074')
          .backgroundColor('#E8E5D8')
          .borderRadius(6)
          .height(32)
          .layoutWeight(1)
          .margin({ left: 6 })
          .onClick(() => {
            this.cancelForm();
          })
      }
      .width('100%')
      .margin({ top: 8 })
    }
    .width('100%')
    .padding(10)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
  }

  @Builder
  InputArea() {
    Column() {
      TextArea({ text: this.userInput, placeholder: '描述病情，如：评估脑出血病人的预后' })
        .height(80)
        .backgroundColor('#F4F1EA')
        .borderRadius(8)
        .fontSize(13)
        .onChange((value: string) => {
          this.userInput = value;
        })

      Button() {
        if (this.loading) {
          LoadingProgress()
            .width(18)
            .height(18)
            .color('#FFFFFF')
        } else {
          Text('发送').fontSize(14).fontColor('#FFFFFF')
        }
      }
      .width('100%')
      .height(40)
      .backgroundColor(this.loading ? '#7A8074' : '#1F3D2F')
      .borderRadius(8)
      .margin({ top: 8 })
      .enabled(!this.loading && this.userInput.trim().length > 0)
      .onClick(() => {
        this.sendQuery();
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
          .fontColor('#E76F2C')
        Text(this.errorMsg)
          .fontSize(12)
          .fontColor('#E76F2C')
      }
      .width('100%')
      .padding(8)
      .backgroundColor('#FFF4E0')
      .borderRadius(6)
      .margin({ bottom: 12 })
    }
  }

  @Builder
  ResultArea() {
    if (this.resultCalcId) {
      Column() {
        Text('✅ 推荐结果')
          .fontSize(11)
          .fontColor('#7A8074')
          .letterSpacing(1)
          .width('100%')

        Text(this.resultCalcName)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F3D2F')
          .width('100%')
          .margin({ top: 4 })

        if (this.resultCalcId) {
          Text(this.getCalcDescription(this.resultCalcId))
            .fontSize(12)
            .fontColor('#4A5247')
            .width('100%')
            .margin({ top: 4 })
        }

        Button() {
          Text('跳转到此计算器 →')
            .fontSize(14)
            .fontColor('#FFFFFF')
        }
        .width('100%')
        .height(40)
        .backgroundColor('#1F3D2F')
        .borderRadius(8)
        .margin({ top: 12 })
        .onClick(() => {
          this.jumpToCalculator();
        })
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#F0F7F0')
      .borderRadius(8)
    }
  }
}
