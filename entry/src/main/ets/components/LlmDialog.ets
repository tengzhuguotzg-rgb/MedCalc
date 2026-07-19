import { CALCULATORS } from '../model/CalculatorRegistry';
import { PreferencesService } from '../services/PreferencesService';
import { ApiServiceConfig, LlmRecommendation, sendLlmRequest } from '../services/LlmService';
import { AppColors } from '../utils/AppColors';

@Component
export struct LlmDialog {
  @Link currentCalc: string;
  @State isOpen: boolean = false;
  @State userInput: string = '';
  @State loading: boolean = false;
  @State results: LlmRecommendation[] = [];
  @State errorMsg: string = '';
  @State fabRight: number = 24;
  @State fabBottom: number = 24;
  private touchDownX: number = 0;
  private touchDownY: number = 0;
  private isMoving: boolean = false;

  private prefsService = PreferencesService.getInstance();

  getActiveService(): ApiServiceConfig | null {
    return this.prefsService.getActiveLlmConfig();
  }

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
    this.loading = true;

    sendLlmRequest(active, trimmedInput).then((recs: LlmRecommendation[]) => {
      this.loading = false;
      this.results = recs;
    }).catch((err: Error) => {
      this.loading = false;
      this.errorMsg = err.message;
    });
  }

  getActiveServiceName(): string {
    const s = this.getActiveService();
    return s ? s.name : '未配置';
  }

  getCalcDescription(calcId: string): string {
    const calc = CALCULATORS.find((c): boolean => c.id === calcId);
    return calc ? calc.description : '';
  }

  jumpToCalculator(id: string): void {
    if (id) {
      this.currentCalc = id;
      this.closeDialog();
    }
  }

  closeDialog(): void {
    this.isOpen = false;
    this.userInput = '';
    this.results = [];
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
              this.ActiveServiceBar();
              this.InputArea();
              this.StatusArea();
              this.ResultArea();
            }
            .width('100%')
            .padding(20)
          }
          .width('100%')
          .height('100%')
        }
        .width('88%')
        .constraintSize({ maxHeight: '80%' })
        .backgroundColor(AppColors.card)
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
            this.fabRight = Math.max(0, this.fabRight - dx);
            this.fabBottom = Math.max(0, this.fabBottom - dy);
            this.touchDownX = event.touches[0].x;
            this.touchDownY = event.touches[0].y;
          }
        } else if (event.type === TouchType.Up) {
          if (!this.isMoving) {
            this.isOpen = true;
          }
        }
      })
    }
  }

  @Builder
  DialogHeader() {
    Row() {
      Text('AI 推荐计算器')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.primary)
      Blank()
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
    .width('100%')
    .padding({ bottom: 12 })
  }

  @Builder
  ActiveServiceBar() {
    Row() {
      Text(this.getActiveServiceName())
        .fontSize(11)
        .fontColor(AppColors.textSecondary)
    }
    .width('100%')
    .padding({ bottom: 8 })
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
        if (this.loading) {
          LoadingProgress()
            .width(18)
            .height(18)
            .color(AppColors.card)
        } else {
          Text('发送').fontSize(14).fontColor(AppColors.card)
        }
      }
      .width('100%')
      .height(40)
      .backgroundColor(this.loading ? AppColors.textSecondary : AppColors.primary)
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
          .letterSpacing(1)
          .width('100%')
          .margin({ bottom: 8 })

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
          .fontColor(AppColors.card)
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

      Button('跳转 →')
        .fontSize(12)
        .fontColor(AppColors.primary)
        .backgroundColor(AppColors.fillBeige)
        .borderRadius(6)
        .height(30)
        .width('100%')
        .margin({ top: 6 })
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
