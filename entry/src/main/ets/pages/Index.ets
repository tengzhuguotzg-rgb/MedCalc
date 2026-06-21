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
import { LlmDialog } from '../components/LlmDialog';
import { CALCULATORS, Calculator } from '../model/CalculatorRegistry';
import { PreferencesService } from '../services/PreferencesService';

@Entry
@Component
struct Index {
  @State currentCalc: string = 'crcl';
  @State favorites: string[] = [];
  @State sidebarCollapsed: boolean = true;
  @State showLlmDialog: boolean = false;

  aboutToAppear() {
    const prefsService = PreferencesService.getInstance();
    this.favorites = prefsService.getFavorites();
    this.currentCalc = prefsService.getLastCalculator();
  }

  aboutToDisappear() {
    const prefsService = PreferencesService.getInstance();
    prefsService.saveFavorites(this.favorites);
    prefsService.saveLastCalculator(this.currentCalc);
  }

  build() {
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
            } else {
              this.PlaceholderCalculator();
            }
          }
          .width('100%');
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Auto);
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F4F1EA');

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

      LlmDialog({
        isOpen: $showLlmDialog,
        currentCalc: $currentCalc
      })
    }
    .width('100%')
    .height('100%');
  }

  @Builder
  Topbar() {
    Row() {
      Button('☰')
        .fontSize(18)
        .fontColor('#1F3D2F')
        .backgroundColor('transparent')
        .onClick(() => {
          this.sidebarCollapsed = false;
        });

      Column() {
        Text(this.getCurrentCalculatorName())
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1F3D2F');
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 8 });

      Button(this.isFavorite() ? '★' : '☆')
        .fontSize(18)
        .fontColor(this.isFavorite() ? '#E76F2C' : '#7A8074')
        .backgroundColor('transparent')
        .onClick(() => {
          this.toggleFavorite();
        });
    }
    .width('100%')
    .height(44)
    .padding({ left: 12, right: 12 })
    .backgroundColor('#FFFFFF')
    .border({ width: { bottom: 1 }, color: '#E0DCC8' });
  }

  @Builder
  PlaceholderCalculator() {
    Column() {
      Text('开发中...')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1F3D2F');
      Text('此计算器正在移植中，敬请期待')
        .fontSize(11.5)
        .fontColor('#4A5247')
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
