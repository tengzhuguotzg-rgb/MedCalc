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
import { ShockIndexCalculator } from '../components/calculators/ShockIndexCalculator';
import { QsofaCalculator } from '../components/calculators/QsofaCalculator';
import { RtsCalculator } from '../components/calculators/RtsCalculator';
import { RsbiCalculator } from '../components/calculators/RsbiCalculator';
import { HellpCalculator } from '../components/calculators/HellpCalculator';
import { MetabolicCalculator } from '../components/calculators/MetabolicCalculator';
import { HeartCalculator } from '../components/calculators/HeartCalculator';
import { GbsCalculator } from '../components/calculators/GbsCalculator';
import { BisapCalculator } from '../components/calculators/BisapCalculator';
import { TlsCalculator } from '../components/calculators/TlsCalculator';
import { BwpsCalculator } from '../components/calculators/BwpsCalculator';
import { WellsDvtCalculator } from '../components/calculators/WellsDvtCalculator';
import { CpisCalculator } from '../components/calculators/CpisCalculator';
import { AncMasccCalculator } from '../components/calculators/AncMasccCalculator';
import { AdhereCalculator } from '../components/calculators/AdhereCalculator';
import { StessCalculator } from '../components/calculators/StessCalculator';
import { McmahonCalculator } from '../components/calculators/McmahonCalculator';
import { IsthCalculator } from '../components/calculators/IsthCalculator';
import { PlasmicCalculator } from '../components/calculators/PlasmicCalculator';
import { VisCalculator } from '../components/calculators/VisCalculator';
import { LactateClearanceCalculator } from '../components/calculators/LactateClearanceCalculator';
import { Abc2Calculator } from '../components/calculators/Abc2Calculator';
import { DdimerAgeCalculator } from '../components/calculators/DdimerAgeCalculator';
import { AddrsCalculator } from '../components/calculators/AddrsCalculator';
import { AsthmaCalculator } from '../components/calculators/AsthmaCalculator';
import { GoldAbeCalculator } from '../components/calculators/GoldAbeCalculator';
import { Bap65Calculator } from '../components/calculators/Bap65Calculator';
import { GcsPCalculator } from '../components/calculators/GcsPCalculator';
import { FourCalculator } from '../components/calculators/FourCalculator';
import { CrusadeCalculator } from '../components/calculators/CrusadeCalculator';
import { RemsCalculator } from '../components/calculators/RemsCalculator';
import { AspirationCalculator } from '../components/calculators/AspirationCalculator';
import { ParklandCalculator } from '../components/calculators/ParklandCalculator';
import { QtcCalculator } from '../components/calculators/QtcCalculator';
import { AlvaradoCalculator } from '../components/calculators/AlvaradoCalculator';
import { RipasaCalculator } from '../components/calculators/RipasaCalculator';
import { CsfCalculator } from '../components/calculators/CsfCalculator';
import { PaduaCalculator } from '../components/calculators/PaduaCalculator';
import { MmeCalculator } from '../components/calculators/MmeCalculator';
import { SteroidCalculator } from '../components/calculators/SteroidCalculator';
import { FickCalculator } from '../components/calculators/FickCalculator';
import { ApapCalculator } from '../components/calculators/ApapCalculator';
import { SgarbossaCalculator } from '../components/calculators/SgarbossaCalculator';
import { DukeCalculator } from '../components/calculators/DukeCalculator';
import { AwolCalculator } from '../components/calculators/AwolCalculator';
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
  @State calcMode: string = 'normal';
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
    this.calcMode = prefsService.getCalcMode();
  }

  onKbNavigate() {
    if (this.kbNavigatePath.length > 0) {
      this.currentTab = 2;
    }
  }

  onBackPress(): boolean | void {
    if (this.currentTab === 2 && this.kbNavDepth > 0) {
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
      .tabBar(this.TabBarBuilder($r('app.string.tab_calculator'), 0))

      TabContent() {
        Navigation(this.patientStack) {
          PatientListPage({ patientStack: this.patientStack });
        }
        .hideTitleBar(true)
        .navDestination(this.PatientRouteMap)
      }
      .tabBar(this.TabBarBuilder($r('app.string.tab_patient'), 1))

      TabContent() {
        Navigation(this.kbStack) {
          KnowledgeSearchPage({
            onNavDepthChanged: (depth: number) => { this.kbNavDepth = depth; },
            backAction: this.kbBackAction,
          });
        }
        .hideTitleBar(true)
      }
      .tabBar(this.TabBarBuilder($r('app.string.tab_knowledge'), 2))

      TabContent() {
        SettingsPage();
      }
      .tabBar(this.TabBarBuilder($r('app.string.tab_settings'), 3))
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

      if (this.calcMode === 'normal') {
        Stack({ alignContent: Alignment.Start }) {
          Column() {
            Scroll() {
              Column() {
                this.CalcContentHeader();
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
            } else if (this.currentCalc === 'shocki') {
              ShockIndexCalculator();
            } else if (this.currentCalc === 'qsofa') {
              QsofaCalculator();
            } else if (this.currentCalc === 'rts') {
              RtsCalculator();
            } else if (this.currentCalc === 'rsbi') {
              RsbiCalculator();
            } else if (this.currentCalc === 'hellp') {
              HellpCalculator();
            } else if (this.currentCalc === 'metab') {
              MetabolicCalculator();
            } else if (this.currentCalc === 'heart') {
              HeartCalculator();
            } else if (this.currentCalc === 'gbs') {
              GbsCalculator();
            } else if (this.currentCalc === 'bisap') {
              BisapCalculator();
            } else if (this.currentCalc === 'tls') {
              TlsCalculator();
            } else if (this.currentCalc === 'bwps') {
              BwpsCalculator();
            } else if (this.currentCalc === 'wellsdvt') {
              WellsDvtCalculator();
            } else if (this.currentCalc === 'cpis') {
              CpisCalculator();
            } else if (this.currentCalc === 'anc') {
              AncMasccCalculator();
            } else if (this.currentCalc === 'adhere') {
              AdhereCalculator();
            } else if (this.currentCalc === 'stess') {
              StessCalculator();
            } else if (this.currentCalc === 'rhabdo') {
              McmahonCalculator();
            } else if (this.currentCalc === 'isth') {
              IsthCalculator();
            } else if (this.currentCalc === 'plasmic') {
              PlasmicCalculator();
            } else if (this.currentCalc === 'vis') {
              VisCalculator();
            } else if (this.currentCalc === 'lacclear') {
              LactateClearanceCalculator();
            } else if (this.currentCalc === 'abc2') {
              Abc2Calculator();
            } else if (this.currentCalc === 'ddage') {
              DdimerAgeCalculator();
            } else if (this.currentCalc === 'addrs') {
              AddrsCalculator();
            } else if (this.currentCalc === 'asthma') {
              AsthmaCalculator();
            } else if (this.currentCalc === 'goldabe') {
              GoldAbeCalculator();
            } else if (this.currentCalc === 'bap65') {
              Bap65Calculator();
            } else if (this.currentCalc === 'gcsp') {
              GcsPCalculator();
            } else if (this.currentCalc === 'four') {
              FourCalculator();
            } else if (this.currentCalc === 'crusade') {
              CrusadeCalculator();
            } else if (this.currentCalc === 'rems') {
              RemsCalculator();
            } else if (this.currentCalc === 'aspir') {
              AspirationCalculator();
            } else if (this.currentCalc === 'parkland') {
              ParklandCalculator();
            } else if (this.currentCalc === 'qtc') {
              QtcCalculator();
            } else if (this.currentCalc === 'alvarado') {
              AlvaradoCalculator();
            } else if (this.currentCalc === 'ripasa') {
              RipasaCalculator();
            } else if (this.currentCalc === 'csf') {
              CsfCalculator();
            } else if (this.currentCalc === 'padua') {
              PaduaCalculator();
            } else if (this.currentCalc === 'mme') {
              MmeCalculator();
            } else if (this.currentCalc === 'steroid') {
              SteroidCalculator();
            } else if (this.currentCalc === 'fick') {
              FickCalculator();
            } else if (this.currentCalc === 'apap') {
              ApapCalculator();
            } else if (this.currentCalc === 'sgarbossa') {
              SgarbossaCalculator();
            } else if (this.currentCalc === 'duke') {
              DukeCalculator();
            } else if (this.currentCalc === 'awol') {
              AwolCalculator();
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
    }
    .width('100%')
    .layoutWeight(1);
      } else if (this.calcMode === 'recommend') {
        LlmDialog({
          currentCalc: $currentCalc,
          pageMode: true,
          onPickCalc: (id: string) => {
            this.calcMode = 'normal';
            PreferencesService.getInstance().saveCalcMode('normal');
          },
          onCalculate: (id: string) => {
            this.sheetCalcId = id;
            AppStorage.setOrCreate('activeCalcId', id);
            this.showCalcSheet = true;
          }
        })
          .layoutWeight(1);
      } else if (this.calcMode === 'recognize') {
        this.RecognizeView();
      }
    }
    .width('100%')
    .height('100%')
    .bindSheet($$this.showCalcSheet, this.CalcSheetBuilder(), {
      height: SheetSize.LARGE,
      dragBar: true,
      showClose: true,
      backgroundColor: AppColors.background,
      onWillDismiss: (dismissAction: DismissSheetAction) => {
        AppStorage.setOrCreate('activeCalcId', '');
        dismissAction.dismiss();
      }
    });
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
                if (this.sheetCalcId === 'crcl') {
              CrClCalculator();
            } else if (this.sheetCalcId === 'gfr') {
              GfrCalculator();
            } else if (this.sheetCalcId === 'map') {
              MapCalculator();
            } else if (this.sheetCalcId === 'sf') {
              SfCalculator();
            } else if (this.sheetCalcId === 'gcs') {
              GcsCalculator();
            } else if (this.sheetCalcId === 'news2') {
              News2Calculator();
            } else if (this.sheetCalcId === 'sofa') {
              SofaCalculator();
            } else if (this.sheetCalcId === 'pf') {
              PfCalculator();
            } else if (this.sheetCalcId === 'na') {
              NaCalculator();
            } else if (this.sheetCalcId === 'rox') {
              RoxCalculator();
            } else if (this.sheetCalcId === 'cag') {
              CagCalculator();
            } else if (this.sheetCalcId === 'chadsvasc') {
              ChadsvascCalculator();
            } else if (this.sheetCalcId === 'hasbled') {
              HasbledCalculator();
            } else if (this.sheetCalcId === 'curb65') {
              Curb65Calculator();
            } else if (this.sheetCalcId === 'sirs') {
              SirsCalculator();
            } else if (this.sheetCalcId === 'abcd2') {
              Abcd2Calculator();
            } else if (this.sheetCalcId === 'nihss') {
              NihssCalculator();
            } else if (this.sheetCalcId === 'rass') {
              RassCalculator();
            } else if (this.sheetCalcId === 'ich') {
              IchCalculator();
            } else if (this.sheetCalcId === 'hunthess') {
              HuntHessCalculator();
            } else if (this.sheetCalcId === 'wfns') {
              WfnsCalculator();
            } else if (this.sheetCalcId === 'fisher') {
              FisherCalculator();
            } else if (this.sheetCalcId === 'marshall') {
              MarshallCalculator();
            } else if (this.sheetCalcId === 'mehran') {
              MehranCalculator();
            } else if (this.sheetCalcId === 'timistemi') {
              TimiStemiCalculator();
            } else if (this.sheetCalcId === 'timinstemi') {
              TimiNstemiCalculator();
            } else if (this.sheetCalcId === 'wells') {
              WellsCalculator();
            } else if (this.sheetCalcId === 'childpugh') {
              ChildPughCalculator();
            } else if (this.sheetCalcId === 'kcc') {
              KccCalculator();
            } else if (this.sheetCalcId === 'nrs2002') {
              Nrs2002Calculator();
            } else if (this.sheetCalcId === 'apache2') {
              Apache2Calculator();
            } else if (this.sheetCalcId === 'clifc') {
              ClifCCalculator();
            } else if (this.sheetCalcId === 'aarc') {
              AarcCalculator();
            } else if (this.sheetCalcId === 'bg') {
              BloodGasCalculator();
            } else if (this.sheetCalcId === 'camicu') {
              CamicuCalculator();
            } else if (this.sheetCalcId === 'pesi') {
              PesiCalculator();
            } else if (this.sheetCalcId === 'scai') {
              ScaiCalculator();
            } else if (this.sheetCalcId === 'mnutric') {
              MnutricCalculator();
            } else if (this.sheetCalcId === 'fssicu') {
              FssicuCalculator();
            } else if (this.sheetCalcId === 'kdigo') {
              KdigoCalculator();
            } else if (this.sheetCalcId === 'vasopressor') {
              VasopressorCalculator();
            } else if (this.sheetCalcId === 'nadeficit') {
              NaDeficitCalculator();
            } else if (this.sheetCalcId === 'nacorrection') {
              NaCorrectionRateCalculator();
            } else if (this.sheetCalcId === 'shocki') {
              ShockIndexCalculator();
            } else if (this.sheetCalcId === 'qsofa') {
              QsofaCalculator();
            } else if (this.sheetCalcId === 'rts') {
              RtsCalculator();
            } else if (this.sheetCalcId === 'rsbi') {
              RsbiCalculator();
            } else if (this.sheetCalcId === 'hellp') {
              HellpCalculator();
            } else if (this.sheetCalcId === 'metab') {
              MetabolicCalculator();
            } else if (this.sheetCalcId === 'heart') {
              HeartCalculator();
            } else if (this.sheetCalcId === 'gbs') {
              GbsCalculator();
            } else if (this.sheetCalcId === 'bisap') {
              BisapCalculator();
            } else if (this.sheetCalcId === 'tls') {
              TlsCalculator();
            } else if (this.sheetCalcId === 'bwps') {
              BwpsCalculator();
            } else if (this.sheetCalcId === 'wellsdvt') {
              WellsDvtCalculator();
            } else if (this.sheetCalcId === 'cpis') {
              CpisCalculator();
            } else if (this.sheetCalcId === 'anc') {
              AncMasccCalculator();
            } else if (this.sheetCalcId === 'adhere') {
              AdhereCalculator();
            } else if (this.sheetCalcId === 'stess') {
              StessCalculator();
            } else if (this.sheetCalcId === 'rhabdo') {
              McmahonCalculator();
            } else if (this.sheetCalcId === 'isth') {
              IsthCalculator();
            } else if (this.sheetCalcId === 'plasmic') {
              PlasmicCalculator();
            } else if (this.sheetCalcId === 'vis') {
              VisCalculator();
            } else if (this.sheetCalcId === 'lacclear') {
              LactateClearanceCalculator();
            } else if (this.sheetCalcId === 'abc2') {
              Abc2Calculator();
            } else if (this.sheetCalcId === 'ddage') {
              DdimerAgeCalculator();
            } else if (this.sheetCalcId === 'addrs') {
              AddrsCalculator();
            } else if (this.sheetCalcId === 'asthma') {
              AsthmaCalculator();
            } else if (this.sheetCalcId === 'goldabe') {
              GoldAbeCalculator();
            } else if (this.sheetCalcId === 'bap65') {
              Bap65Calculator();
            } else if (this.sheetCalcId === 'gcsp') {
              GcsPCalculator();
            } else if (this.sheetCalcId === 'four') {
              FourCalculator();
            } else if (this.sheetCalcId === 'crusade') {
              CrusadeCalculator();
            } else if (this.sheetCalcId === 'rems') {
              RemsCalculator();
            } else if (this.sheetCalcId === 'aspir') {
              AspirationCalculator();
            } else if (this.sheetCalcId === 'parkland') {
              ParklandCalculator();
            } else if (this.sheetCalcId === 'qtc') {
              QtcCalculator();
            } else if (this.sheetCalcId === 'alvarado') {
              AlvaradoCalculator();
            } else if (this.sheetCalcId === 'ripasa') {
              RipasaCalculator();
            } else if (this.sheetCalcId === 'csf') {
              CsfCalculator();
            } else if (this.sheetCalcId === 'padua') {
              PaduaCalculator();
            } else if (this.sheetCalcId === 'mme') {
              MmeCalculator();
            } else if (this.sheetCalcId === 'steroid') {
              SteroidCalculator();
            } else if (this.sheetCalcId === 'fick') {
              FickCalculator();
            } else if (this.sheetCalcId === 'apap') {
              ApapCalculator();
            } else if (this.sheetCalcId === 'sgarbossa') {
              SgarbossaCalculator();
            } else if (this.sheetCalcId === 'duke') {
              DukeCalculator();
            } else if (this.sheetCalcId === 'awol') {
              AwolCalculator();
            }
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
      .enabled(this.calcMode === 'normal')
      .onClick(() => {
        if (this.calcMode === 'normal') {
          this.sidebarCollapsed = false;
        }
      });

      // 中：三模式分段切换
      Row({ space: 4 }) {
        this.ModeButton('常规模式', 'normal');
        this.ModeButton('LLM推荐', 'recommend');
        this.ModeButton('LLM识别', 'recognize');
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
  ModeButton(label: string, mode: string) {
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
