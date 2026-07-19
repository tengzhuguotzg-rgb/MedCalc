import { Sidebar } from '../components/Sidebar';
import { CrClCalculator } from '../components/calculators/CrClCalculator';
import { GfrCalculator } from '../components/calculators/GfrCalculator';
import { MapCalculator } from '../components/calculators/MapCalculator';
import { SfCalculator } from '../components/calculators/SfCalculator';
import { GcsCalculator } from '../components/calculators/GcsCalculator';
import { News2Calculator } from '../components/calculators/News2Calculator';
import { SofaCalculator } from '../components/calculators/SofaCalculator';
import { PfCalculator } from '../components/calculators/PfCalculator';
import { NaCalculator } from '../components/calculators/NaCalculator';
import { RoxCalculator } from '../components/calculators/RoxCalculator';
import { CagCalculator } from '../components/calculators/CagCalculator';
import { ChadsvascCalculator } from '../components/calculators/ChadsvascCalculator';
import { HasbledCalculator } from '../components/calculators/HasbledCalculator';
import { Curb65Calculator } from '../components/calculators/Curb65Calculator';
import { SirsCalculator } from '../components/calculators/SirsCalculator';
import { Abcd2Calculator } from '../components/calculators/Abcd2Calculator';
import { NihssCalculator } from '../components/calculators/NihssCalculator';
import { RassCalculator } from '../components/calculators/RassCalculator';
import { IchCalculator } from '../components/calculators/IchCalculator';
import { HuntHessCalculator, WfnsCalculator, FisherCalculator } from '../components/calculators/HuntHessCalculator';
import { MarshallCalculator } from '../components/calculators/MarshallCalculator';
import { MehranCalculator } from '../components/calculators/MehranCalculator';
import { TimiStemiCalculator, TimiNstemiCalculator } from '../components/calculators/TimiCalculator';
import { WellsCalculator } from '../components/calculators/WellsCalculator';
import { ChildPughCalculator } from '../components/calculators/ChildPughCalculator';
import { KccCalculator } from '../components/calculators/KccCalculator';
import { Nrs2002Calculator } from '../components/calculators/Nrs2002Calculator';
import { Apache2Calculator } from '../components/calculators/Apache2Calculator';
import { ClifCCalculator } from '../components/calculators/ClifCCalculator';
import { AarcCalculator } from '../components/calculators/AarcCalculator';
import { BloodGasCalculator } from '../components/calculators/BloodGasCalculator';
import { CamicuCalculator } from '../components/calculators/CamicuCalculator';
import { PesiCalculator } from '../components/calculators/PesiCalculator';
import { ScaiCalculator } from '../components/calculators/ScaiCalculator';
import { MnutricCalculator } from '../components/calculators/MnutricCalculator';
import { FssicuCalculator } from '../components/calculators/FssicuCalculator';
import { KdigoCalculator } from '../components/calculators/KdigoCalculator';
import { VasopressorCalculator } from '../components/calculators/VasopressorCalculator';
import { NaDeficitCalculator } from '../components/calculators/NaDeficitCalculator';
import { NaCorrectionRateCalculator } from '../components/calculators/NaCorrectionRateCalculator';
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

@Entry
@Component
struct Index {
  @State currentCalc: string = 'crcl';
  @State favorites: string[] = [];
  @State sidebarCollapsed: boolean = true;
  @State currentTab: number = 0;
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
  }

  onKbNavigate() {
    if (this.kbNavigatePath.length > 0) {
      this.currentTab = 3;
    }
  }

  onBackPress(): boolean | void {
    if (this.currentTab === 3 && this.kbNavDepth > 0) {
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
      .tabBar(this.TabBarBuilder('计算器', 0))

      TabContent() {
        AssistantPage({ currentCalc: $currentCalc, currentTab: $currentTab });
      }
      .tabBar(this.TabBarBuilder('助手', 1))

      TabContent() {
        Navigation(this.patientStack) {
          PatientListPage({ patientStack: this.patientStack });
        }
        .hideTitleBar(true)
        .navDestination(this.PatientRouteMap)
      }
      .tabBar(this.TabBarBuilder('病历', 2))

      TabContent() {
        Navigation(this.kbStack) {
          KnowledgeSearchPage({
            kbStack: this.kbStack,
            onNavDepthChanged: (depth: number) => { this.kbNavDepth = depth; },
            backAction: this.kbBackAction,
          });
        }
        .hideTitleBar(true)
        .navDestination(this.KbRouteMap)
      }
      .tabBar(this.TabBarBuilder('知识库', 3))

      TabContent() {
        SettingsPage();
      }
      .tabBar(this.TabBarBuilder('设置', 4))
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
  KbRouteMap(name: string) {
  }

  @Builder
  TabBarBuilder(title: string, index: number) {
    Column({ space: 4 }) {
      Text(title)
        .fontSize(14)
        .fontWeight(this.currentTab === index ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.currentTab === index ? AppColors.primary : AppColors.textSecondary)
      Row()
        .width(24)
        .height(2)
        .borderRadius(1)
        .backgroundColor(this.currentTab === index ? AppColors.primary : 'transparent')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  CalcModeView() {
    Stack({ alignContent: Alignment.Start }) {
      Column() {
        this.Topbar();
        Scroll() {
          Column() {
            if (this.currentCalc === 'crcl') {
              CrClCalculator();
            } else if (this.currentCalc === 'gfr') {
              GfrCalculator();
            } else if (this.currentCalc === 'map') {
              MapCalculator();
            } else if (this.currentCalc === 'sf') {
              SfCalculator();
            } else if (this.currentCalc === 'gcs') {
              GcsCalculator();
            } else if (this.currentCalc === 'news2') {
              News2Calculator();
            } else if (this.currentCalc === 'sofa') {
              SofaCalculator();
            } else if (this.currentCalc === 'pf') {
              PfCalculator();
            } else if (this.currentCalc === 'na') {
              NaCalculator();
            } else if (this.currentCalc === 'rox') {
              RoxCalculator();
            } else if (this.currentCalc === 'cag') {
              CagCalculator();
            } else if (this.currentCalc === 'chadsvasc') {
              ChadsvascCalculator();
            } else if (this.currentCalc === 'hasbled') {
              HasbledCalculator();
            } else if (this.currentCalc === 'curb65') {
              Curb65Calculator();
            } else if (this.currentCalc === 'sirs') {
              SirsCalculator();
            } else if (this.currentCalc === 'abcd2') {
              Abcd2Calculator();
            } else if (this.currentCalc === 'nihss') {
              NihssCalculator();
            } else if (this.currentCalc === 'rass') {
              RassCalculator();
            } else if (this.currentCalc === 'ich') {
              IchCalculator();
            } else if (this.currentCalc === 'hunthess') {
              HuntHessCalculator();
            } else if (this.currentCalc === 'wfns') {
              WfnsCalculator();
            } else if (this.currentCalc === 'fisher') {
              FisherCalculator();
            } else if (this.currentCalc === 'marshall') {
              MarshallCalculator();
            } else if (this.currentCalc === 'mehran') {
              MehranCalculator();
            } else if (this.currentCalc === 'timistemi') {
              TimiStemiCalculator();
            } else if (this.currentCalc === 'timinstemi') {
              TimiNstemiCalculator();
            } else if (this.currentCalc === 'wells') {
              WellsCalculator();
            } else if (this.currentCalc === 'childpugh') {
              ChildPughCalculator();
            } else if (this.currentCalc === 'kcc') {
              KccCalculator();
            } else if (this.currentCalc === 'nrs2002') {
              Nrs2002Calculator();
            } else if (this.currentCalc === 'apache2') {
              Apache2Calculator();
            } else if (this.currentCalc === 'clifc') {
              ClifCCalculator();
            } else if (this.currentCalc === 'aarc') {
              AarcCalculator();
            } else if (this.currentCalc === 'bg') {
              BloodGasCalculator();
            } else if (this.currentCalc === 'camicu') {
              CamicuCalculator();
            } else if (this.currentCalc === 'pesi') {
              PesiCalculator();
            } else if (this.currentCalc === 'scai') {
              ScaiCalculator();
            } else if (this.currentCalc === 'mnutric') {
              MnutricCalculator();
            } else if (this.currentCalc === 'fssicu') {
              FssicuCalculator();
            } else if (this.currentCalc === 'kdigo') {
              KdigoCalculator();
            } else if (this.currentCalc === 'vasopressor') {
              VasopressorCalculator();
            } else if (this.currentCalc === 'nadeficit') {
              NaDeficitCalculator();
            } else if (this.currentCalc === 'nacorrection') {
              NaCorrectionRateCalculator();
            } else {
              this.PlaceholderCalculator();
            }
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
          .backgroundColor('rgba(0,0,0,0.35)')
          .onClick(() => { this.sidebarCollapsed = true; });

        Sidebar({
          currentCalc: $currentCalc,
          favorites: $favorites,
          sidebarCollapsed: $sidebarCollapsed
        });
      }

      LlmDialog({ currentCalc: $currentCalc })
    }
    .width('100%')
    .height('100%');
  }

  @Builder
  Topbar() {
    Row() {
      Button() {
        this.MenuIcon()
      }
      .width(44)
      .height(44)
      .backgroundColor('transparent')
      .onClick(() => {
        this.sidebarCollapsed = false;
      });

      Column() {
        Text(this.getCurrentCalculatorName())
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.primary);
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 4 });

      Button() {
        Text(this.isFavorite() ? '★' : '☆')
          .fontSize(18)
          .fontColor(this.isFavorite() ? AppColors.warning : AppColors.textSecondary)
      }
      .width(44)
      .height(44)
      .backgroundColor('transparent')
      .onClick(() => {
        this.toggleFavorite();
      })
    }
    .width('100%')
    .height(44)
    .padding({ left: 12, right: 12 })
    .backgroundColor(AppColors.card)
    .border({ width: { bottom: 1 }, color: AppColors.divider });
  }

  @Builder
  MenuIcon() {
    Column({ space: 3.5 }) {
      Row().width(18).height(1.5).backgroundColor(AppColors.primary).borderRadius(1)
      Row().width(18).height(1.5).backgroundColor(AppColors.primary).borderRadius(1)
      Row().width(12).height(1.5).backgroundColor(AppColors.primary).borderRadius(1)
    }
    .width(24)
    .height(24)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  PlaceholderCalculator() {
    Column() {
      Text('开发中...')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.primary);
      Text('此计算器正在移植中，敬请期待')
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
