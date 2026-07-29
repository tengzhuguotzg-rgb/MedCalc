import { Sidebar } from '../components/Sidebar';
import { CalcRouter } from '../components/CalcRouter';
import { LlmDialog } from '../components/LlmDialog';
import { AssistantPage } from '../components/AssistantPage';
import { SettingsPage } from '../components/SettingsPage';
import { PatientListPage } from '../components/PatientListPage';
import { PatientDetailPage } from '../components/PatientDetailPage';
import { KnowledgeSearchPage } from '../components/KnowledgeSearchPage';
import { CalcKbLinks } from '../components/CalcKbLinks';
import { CALCULATORS, Calculator } from '../model/CalculatorRegistry';
import { PreferencesService } from '../services/PreferencesService';
import { AppColors } from '../utils/AppColors';
import { TabIndex, CalcMode } from '../model/Enums';
import { showToast } from '../utils/ToastUtil';

@Entry
@Component
struct Index {
  @State currentCalc: string = 'crcl';
  @State favorites: string[] = [];
  @State sidebarCollapsed: boolean = true;
  @State currentTab: TabIndex = TabIndex.Calculator;
  @State calcMode: CalcMode = CalcMode.Normal;
  @State showCalcSheet: boolean = false;
  @State sheetCalcId: string = '';
  @StorageProp('sheetCalcValue') sheetCalcValue: number | null = null;
  @StorageProp('sheetCalcValueText') sheetCalcValueText: string = '';
  @Watch('onKbNavigate') @StorageProp('kbNavigatePath') kbNavigatePath: string = '';
  @State kbNavDepth: number = 0;
  @State kbBackAction: number = 0;
  @State patientBackFlag: number = 0;
  patientStack: NavPathStack = new NavPathStack();
  kbStack: NavPathStack = new NavPathStack();

  aboutToAppear() {
    const prefsService = PreferencesService.getInstance();
    this.favorites = prefsService.getFavorites();
    this.currentCalc = prefsService.getLastCalculator();
    this.calcMode = prefsService.getCalcMode() as CalcMode;
  }

  onKbNavigate() {
    if (this.kbNavigatePath.length > 0) {
      this.currentTab = TabIndex.Knowledge;
    }
  }

  onBackPress(): boolean | void {
    if (this.currentTab === TabIndex.Knowledge && this.kbNavDepth > 0) {
      this.kbBackAction++;
      return true;
    }
    return false;
  }

  aboutToDisappear() {
    const prefsService = PreferencesService.getInstance();
    prefsService.saveFavorites(this.favorites);
    prefsService.saveLastCalculator(this.currentCalc);
  }

  build() {
    Tabs({ barPosition: BarPosition.End, index: this.currentTab }) {
      TabContent() {
        this.CalcModeView();
      }
      .tabBar(this.TabBarBuilder($r('app.string.tab_calculator'), TabIndex.Calculator))

      TabContent() {
        Navigation(this.patientStack) {
          PatientListPage({ patientStack: this.patientStack });
        }
        .hideTitleBar(true)
        .navDestination(this.PatientRouteMap)
      }
      .tabBar(this.TabBarBuilder($r('app.string.tab_patient'), TabIndex.Patient))

      TabContent() {
        Navigation(this.kbStack) {
          KnowledgeSearchPage({
            onNavDepthChanged: (depth: number) => { this.kbNavDepth = depth; },
            backAction: this.kbBackAction,
          });
        }
        .hideTitleBar(true)
      }
      .tabBar(this.TabBarBuilder($r('app.string.tab_knowledge'), TabIndex.Knowledge))

      TabContent() {
        SettingsPage();
      }
      .tabBar(this.TabBarBuilder($r('app.string.tab_settings'), TabIndex.Settings))
    }
    .barBackgroundColor(AppColors.card)
    .barMode(BarMode.Fixed)
    .scrollable(false)
    .onChange((index: number) => { this.currentTab = index; })
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }

  @Builder
  PatientRouteMap(name: string) {
    if (name === 'PatientDetail') {
      NavDestination() {
        PatientDetailPage({ patientStack: this.patientStack, backFlag: this.patientBackFlag });
      }
      .hideTitleBar(true)
      .onBackPressed(() => {
        this.patientBackFlag++;
        return true;
      })
    }
  }

  @Builder
  TabBarBuilder(title: ResourceStr, index: number) {
    Column({ space: 2 }) {
      Image(this.tabIcon(index))
        .width(22)
        .height(22)
        .fillColor(this.currentTab === index ? AppColors.primary : AppColors.tabInactive)
        .objectFit(ImageFit.Contain)
      Text(title)
        .fontSize(11)
        .fontWeight(this.currentTab === index ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.currentTab === index ? AppColors.primary : AppColors.tabInactive)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  private tabIcon(index: number): Resource {
    if (index === 0) {
      return $r('app.media.ic_calculator');
    }
    if (index === 1) {
      return $r('app.media.ic_patient');
    }
    if (index === 2) {
      return $r('app.media.ic_knowledge');
    }
    return $r('app.media.ic_settings');
  }

  @Builder
  CalcModeView() {
    Column() {
      this.Topbar();

      if (this.calcMode === CalcMode.Normal) {
        Stack({ alignContent: Alignment.Start }) {
          Column() {
            Scroll() {
              Column() {
                this.CalcContentHeader();
                CalcRouter({ calcId: this.currentCalc });
            CalcKbLinks({ calcId: this.currentCalc });
          }
          .width('100%');
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Auto);
      }
      .width('100%')
      .height('100%')
      .backgroundColor(AppColors.background);

      if (!this.sidebarCollapsed) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(AppColors.overlay)
          .onClick(() => { this.sidebarCollapsed = true; });

        Sidebar({
          currentCalc: $currentCalc,
          favorites: $favorites,
          sidebarCollapsed: $sidebarCollapsed
        });
      }
    }
    .width('100%')
    .layoutWeight(1);
      } else if (this.calcMode === CalcMode.Recommend) {
        LlmDialog({
          currentCalc: $currentCalc,
          pageMode: true,
          onPickCalc: (id: string) => {
            this.calcMode = CalcMode.Normal;
            PreferencesService.getInstance().saveCalcMode(CalcMode.Normal);
          },
          onCalculate: (id: string) => {
            this.sheetCalcId = id;
            AppStorage.setOrCreate('activeCalcId', id);
            this.showCalcSheet = true;
          }
        })
          .layoutWeight(1);
      } else if (this.calcMode === CalcMode.Recognize) {
        this.RecognizeView();
      }
    }
    .width('100%')
    .height('100%')
    .bindSheet($$this.showCalcSheet, this.CalcSheetBuilder(), {
      height: this.getSheetHeight(),
      dragBar: true,
      showClose: true,
      backgroundColor: AppColors.background,
      onWillDismiss: (dismissAction: DismissSheetAction) => {
        AppStorage.setOrCreate('activeCalcId', '');
        dismissAction.dismiss();
      }
    });
  }

  // 根据计算器 ID 判断复杂度，决定 bindSheet 高度
  // 简单计算器（≤4 个输入项）用 MEDIUM；复杂计算器（>4 个输入项）用 LARGE
  getSheetHeight(): SheetSize {
    // 已知简单计算器列表：常见 ≤4 个输入项的常用量表
    const simpleCalcs: string[] = ['map', 'shocki', 'qtc', 'na', 'crcl', 'gfr', 'rsbi', 'qsofa', 'sirs'];
    return simpleCalcs.indexOf(this.sheetCalcId) >= 0 ? SheetSize.MEDIUM : SheetSize.LARGE;
  }

  @Builder
  RecognizeView() {
    AssistantPage({ currentCalc: $currentCalc, currentTab: $currentTab })
      .layoutWeight(1);
  }

  @Builder
  CalcSheetBuilder() {
    Column() {
      Scroll() {
        Column() {
                CalcRouter({ calcId: this.sheetCalcId });
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 16 })
      }
      .width('100%')
      .layoutWeight(1)

      // 底部固定按钮：有结果时"完成，查看结果"，无结果时灰化提示
      Button() {
        Text(this.hasSheetResult() ? '✅ 完成，查看结果 ->' : '填写参数后自动出分')
          .fontSize(14)
          .fontColor(this.hasSheetResult() ? AppColors.onPrimary : AppColors.textSecondary)
      }
      .width('100%')
      .height(48)
      .backgroundColor(this.hasSheetResult() ? AppColors.primary : AppColors.fillNeutral)
      .borderRadius(8)
      .margin({ top: 8 })
      .enabled(this.hasSheetResult())
      .onClick(() => {
        this.showCalcSheet = false;
        showToast('结果已保存');
      })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, bottom: 8 })
  }

  // 判断 sheet 中计算器是否有结果
  hasSheetResult(): boolean {
    return this.sheetCalcValue !== null || this.sheetCalcValueText.length > 0;
  }

  @Builder
  Topbar() {
    Row() {
      // 左：菜单按钮（仅 normal 模式可点开侧栏；其他模式同尺寸透明占位保持布局）
      Button() {
        this.MenuIcon()
      }
      .width(44)
      .height(44)
      .backgroundColor('transparent')
      .enabled(this.calcMode === CalcMode.Normal)
      .onClick(() => {
        if (this.calcMode === CalcMode.Normal) {
          this.sidebarCollapsed = false;
        }
      });

      // 中：三模式分段切换
      Row({ space: 4 }) {
        this.ModeButton('常规模式', CalcMode.Normal);
        this.ModeButton('LLM推荐', CalcMode.Recommend);
        this.ModeButton('LLM识别', CalcMode.Recognize);
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .padding({ left: 4, right: 4 });

      // 右：44 透明占位（清空会话入口留在 AssistantPage 自身 HeaderBar）
      Column()
        .width(44)
        .height(44);
    }
    .width('100%')
    .height(44)
    .padding({ left: 12, right: 12 })
    .backgroundColor(AppColors.headerBg);
  }

  @Builder
  ModeButton(label: string, mode: CalcMode) {
    Text(label)
      .fontSize(13)
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .fontColor(this.calcMode === mode ? AppColors.onPrimary : AppColors.textBody)
      .backgroundColor(this.calcMode === mode ? AppColors.primary : AppColors.fillNeutral)
      .borderRadius(6)
      .onClick(() => {
        this.calcMode = mode;
        PreferencesService.getInstance().saveCalcMode(mode);
      });
  }

  @Builder
  CalcContentHeader() {
    Row() {
      Row({ space: 8 }) {
        Text(this.getCurrentCalculatorName())
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.headerText);
        if (this.getCurrentGroup().length > 0) {
          Text(this.getCurrentGroup())
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.onPrimary)
            .backgroundColor(AppColors.getCategoryColor(this.getCurrentGroup()))
            .borderRadius(10)
            .padding({ left: 10, right: 10, top: 3, bottom: 3 });
        }
      }
      .alignItems(VerticalAlign.Center)
      .layoutWeight(1);

      Button() {
        Image(this.isFavorite() ? $r('app.media.ic_star_filled') : $r('app.media.ic_star'))
          .width(20)
          .height(20)
          .fillColor(AppColors.headerText)
          .objectFit(ImageFit.Contain)
      }
      .width(44)
      .height(44)
      .backgroundColor('transparent')
      .onClick(() => {
        this.toggleFavorite();
      });
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 0 });
  }

  @Builder
  MenuIcon() {
    Image($r('app.media.ic_menu'))
      .width(22)
      .height(22)
      .fillColor(AppColors.headerText)
      .objectFit(ImageFit.Contain)
  }

  @Builder
  PlaceholderCalculator() {
    Column() {
      Text($r('app.string.calc_placeholder'))
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.primary);
      Text($r('app.string.calc_placeholder_hint'))
        .fontSize(11.5)
        .fontColor(AppColors.textBody)
        .margin({ top: 8 });
    }
    .width('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Center);
  }

  private getCurrentCalculatorName(): string {
    const calc = CALCULATORS.find(c => c.id === this.currentCalc);
    return calc ? calc.name : '未知计算器';
  }

  private getCurrentGroup(): string {
    const calc = CALCULATORS.find(c => c.id === this.currentCalc);
    return calc ? calc.group : '';
  }

  private getCurrentCalculatorDescription(): string {
    const calc = CALCULATORS.find(c => c.id === this.currentCalc);
    return calc ? calc.description : '';
  }

  private isFavorite(): boolean {
    return this.favorites.includes(this.currentCalc);
  }

  private toggleFavorite() {
    if (this.isFavorite()) {
      this.favorites = this.favorites.filter(id => id !== this.currentCalc);
    } else {
      this.favorites = [...this.favorites, this.currentCalc];
    }
  }
}
