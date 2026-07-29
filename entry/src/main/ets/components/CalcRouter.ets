import { CrClCalculator } from './calculators/CrClCalculator';
import { GfrCalculator } from './calculators/GfrCalculator';
import { MapCalculator } from './calculators/MapCalculator';
import { SfCalculator } from './calculators/SfCalculator';
import { GcsCalculator } from './calculators/GcsCalculator';
import { News2Calculator } from './calculators/News2Calculator';
import { SofaCalculator } from './calculators/SofaCalculator';
import { PfCalculator } from './calculators/PfCalculator';
import { NaCalculator } from './calculators/NaCalculator';
import { RoxCalculator } from './calculators/RoxCalculator';
import { CagCalculator } from './calculators/CagCalculator';
import { ChadsvascCalculator } from './calculators/ChadsvascCalculator';
import { HasbledCalculator } from './calculators/HasbledCalculator';
import { Curb65Calculator } from './calculators/Curb65Calculator';
import { SirsCalculator } from './calculators/SirsCalculator';
import { Abcd2Calculator } from './calculators/Abcd2Calculator';
import { NihssCalculator } from './calculators/NihssCalculator';
import { RassCalculator } from './calculators/RassCalculator';
import { IchCalculator } from './calculators/IchCalculator';
import { HuntHessCalculator, WfnsCalculator, FisherCalculator } from './calculators/HuntHessCalculator';
import { MarshallCalculator } from './calculators/MarshallCalculator';
import { MehranCalculator } from './calculators/MehranCalculator';
import { TimiStemiCalculator, TimiNstemiCalculator } from './calculators/TimiCalculator';
import { WellsCalculator } from './calculators/WellsCalculator';
import { ChildPughCalculator } from './calculators/ChildPughCalculator';
import { KccCalculator } from './calculators/KccCalculator';
import { Nrs2002Calculator } from './calculators/Nrs2002Calculator';
import { Apache2Calculator } from './calculators/Apache2Calculator';
import { ClifCCalculator } from './calculators/ClifCCalculator';
import { AarcCalculator } from './calculators/AarcCalculator';
import { BloodGasCalculator } from './calculators/BloodGasCalculator';
import { CamicuCalculator } from './calculators/CamicuCalculator';
import { PesiCalculator } from './calculators/PesiCalculator';
import { ScaiCalculator } from './calculators/ScaiCalculator';
import { MnutricCalculator } from './calculators/MnutricCalculator';
import { FssicuCalculator } from './calculators/FssicuCalculator';
import { KdigoCalculator } from './calculators/KdigoCalculator';
import { VasopressorCalculator } from './calculators/VasopressorCalculator';
import { NaDeficitCalculator } from './calculators/NaDeficitCalculator';
import { NaCorrectionRateCalculator } from './calculators/NaCorrectionRateCalculator';
import { ShockIndexCalculator } from './calculators/ShockIndexCalculator';
import { QsofaCalculator } from './calculators/QsofaCalculator';
import { RtsCalculator } from './calculators/RtsCalculator';
import { RsbiCalculator } from './calculators/RsbiCalculator';
import { HellpCalculator } from './calculators/HellpCalculator';
import { MetabolicCalculator } from './calculators/MetabolicCalculator';
import { HeartCalculator } from './calculators/HeartCalculator';
import { GbsCalculator } from './calculators/GbsCalculator';
import { BisapCalculator } from './calculators/BisapCalculator';
import { TlsCalculator } from './calculators/TlsCalculator';
import { BwpsCalculator } from './calculators/BwpsCalculator';
import { WellsDvtCalculator } from './calculators/WellsDvtCalculator';
import { CpisCalculator } from './calculators/CpisCalculator';
import { AncMasccCalculator } from './calculators/AncMasccCalculator';
import { AdhereCalculator } from './calculators/AdhereCalculator';
import { StessCalculator } from './calculators/StessCalculator';
import { McmahonCalculator } from './calculators/McmahonCalculator';
import { IsthCalculator } from './calculators/IsthCalculator';
import { PlasmicCalculator } from './calculators/PlasmicCalculator';
import { VisCalculator } from './calculators/VisCalculator';
import { LactateClearanceCalculator } from './calculators/LactateClearanceCalculator';
import { Abc2Calculator } from './calculators/Abc2Calculator';
import { DdimerAgeCalculator } from './calculators/DdimerAgeCalculator';
import { AddrsCalculator } from './calculators/AddrsCalculator';
import { AsthmaCalculator } from './calculators/AsthmaCalculator';
import { GoldAbeCalculator } from './calculators/GoldAbeCalculator';
import { Bap65Calculator } from './calculators/Bap65Calculator';
import { GcsPCalculator } from './calculators/GcsPCalculator';
import { FourCalculator } from './calculators/FourCalculator';
import { CrusadeCalculator } from './calculators/CrusadeCalculator';
import { RemsCalculator } from './calculators/RemsCalculator';
import { AspirationCalculator } from './calculators/AspirationCalculator';
import { ParklandCalculator } from './calculators/ParklandCalculator';
import { QtcCalculator } from './calculators/QtcCalculator';
import { AlvaradoCalculator } from './calculators/AlvaradoCalculator';
import { RipasaCalculator } from './calculators/RipasaCalculator';
import { CsfCalculator } from './calculators/CsfCalculator';
import { PaduaCalculator } from './calculators/PaduaCalculator';
import { MmeCalculator } from './calculators/MmeCalculator';
import { SteroidCalculator } from './calculators/SteroidCalculator';
import { FickCalculator } from './calculators/FickCalculator';
import { ApapCalculator } from './calculators/ApapCalculator';
import { SgarbossaCalculator } from './calculators/SgarbossaCalculator';
import { DukeCalculator } from './calculators/DukeCalculator';
import { AwolCalculator } from './calculators/AwolCalculator';
import { AppColors } from '../utils/AppColors';

/**
 * CalcRouter - 88 个计算器组件的统一路由。
 * ArkUI 的 @Component struct 不能当值传递/动态实例化，
 * if-else 是当前框架限制下唯一可行的路由方式。
 * 本组件集中路由到一处，消除 Index.ets 中的两份重复 if-else。
 */
@Component
export struct CalcRouter {
  @Prop calcId: string = '';

  build() {
    if (this.calcId === 'crcl') {
      CrClCalculator();
    } else if (this.calcId === 'gfr') {
      GfrCalculator();
    } else if (this.calcId === 'map') {
      MapCalculator();
    } else if (this.calcId === 'sf') {
      SfCalculator();
    } else if (this.calcId === 'gcs') {
      GcsCalculator();
    } else if (this.calcId === 'news2') {
      News2Calculator();
    } else if (this.calcId === 'sofa') {
      SofaCalculator();
    } else if (this.calcId === 'pf') {
      PfCalculator();
    } else if (this.calcId === 'na') {
      NaCalculator();
    } else if (this.calcId === 'rox') {
      RoxCalculator();
    } else if (this.calcId === 'cag') {
      CagCalculator();
    } else if (this.calcId === 'chadsvasc') {
      ChadsvascCalculator();
    } else if (this.calcId === 'hasbled') {
      HasbledCalculator();
    } else if (this.calcId === 'curb65') {
      Curb65Calculator();
    } else if (this.calcId === 'sirs') {
      SirsCalculator();
    } else if (this.calcId === 'abcd2') {
      Abcd2Calculator();
    } else if (this.calcId === 'nihss') {
      NihssCalculator();
    } else if (this.calcId === 'rass') {
      RassCalculator();
    } else if (this.calcId === 'ich') {
      IchCalculator();
    } else if (this.calcId === 'hunthess') {
      HuntHessCalculator();
    } else if (this.calcId === 'wfns') {
      WfnsCalculator();
    } else if (this.calcId === 'fisher') {
      FisherCalculator();
    } else if (this.calcId === 'marshall') {
      MarshallCalculator();
    } else if (this.calcId === 'mehran') {
      MehranCalculator();
    } else if (this.calcId === 'timistemi') {
      TimiStemiCalculator();
    } else if (this.calcId === 'timinstemi') {
      TimiNstemiCalculator();
    } else if (this.calcId === 'wells') {
      WellsCalculator();
    } else if (this.calcId === 'childpugh') {
      ChildPughCalculator();
    } else if (this.calcId === 'kcc') {
      KccCalculator();
    } else if (this.calcId === 'nrs2002') {
      Nrs2002Calculator();
    } else if (this.calcId === 'apache2') {
      Apache2Calculator();
    } else if (this.calcId === 'clifc') {
      ClifCCalculator();
    } else if (this.calcId === 'aarc') {
      AarcCalculator();
    } else if (this.calcId === 'bg') {
      BloodGasCalculator();
    } else if (this.calcId === 'camicu') {
      CamicuCalculator();
    } else if (this.calcId === 'pesi') {
      PesiCalculator();
    } else if (this.calcId === 'scai') {
      ScaiCalculator();
    } else if (this.calcId === 'mnutric') {
      MnutricCalculator();
    } else if (this.calcId === 'fssicu') {
      FssicuCalculator();
    } else if (this.calcId === 'kdigo') {
      KdigoCalculator();
    } else if (this.calcId === 'vasopressor') {
      VasopressorCalculator();
    } else if (this.calcId === 'nadeficit') {
      NaDeficitCalculator();
    } else if (this.calcId === 'nacorrection') {
      NaCorrectionRateCalculator();
    } else if (this.calcId === 'shocki') {
      ShockIndexCalculator();
    } else if (this.calcId === 'qsofa') {
      QsofaCalculator();
    } else if (this.calcId === 'rts') {
      RtsCalculator();
    } else if (this.calcId === 'rsbi') {
      RsbiCalculator();
    } else if (this.calcId === 'hellp') {
      HellpCalculator();
    } else if (this.calcId === 'metab') {
      MetabolicCalculator();
    } else if (this.calcId === 'heart') {
      HeartCalculator();
    } else if (this.calcId === 'gbs') {
      GbsCalculator();
    } else if (this.calcId === 'bisap') {
      BisapCalculator();
    } else if (this.calcId === 'tls') {
      TlsCalculator();
    } else if (this.calcId === 'bwps') {
      BwpsCalculator();
    } else if (this.calcId === 'wellsdvt') {
      WellsDvtCalculator();
    } else if (this.calcId === 'cpis') {
      CpisCalculator();
    } else if (this.calcId === 'anc') {
      AncMasccCalculator();
    } else if (this.calcId === 'adhere') {
      AdhereCalculator();
    } else if (this.calcId === 'stess') {
      StessCalculator();
    } else if (this.calcId === 'rhabdo') {
      McmahonCalculator();
    } else if (this.calcId === 'isth') {
      IsthCalculator();
    } else if (this.calcId === 'plasmic') {
      PlasmicCalculator();
    } else if (this.calcId === 'vis') {
      VisCalculator();
    } else if (this.calcId === 'lacclear') {
      LactateClearanceCalculator();
    } else if (this.calcId === 'abc2') {
      Abc2Calculator();
    } else if (this.calcId === 'ddage') {
      DdimerAgeCalculator();
    } else if (this.calcId === 'addrs') {
      AddrsCalculator();
    } else if (this.calcId === 'asthma') {
      AsthmaCalculator();
    } else if (this.calcId === 'goldabe') {
      GoldAbeCalculator();
    } else if (this.calcId === 'bap65') {
      Bap65Calculator();
    } else if (this.calcId === 'gcsp') {
      GcsPCalculator();
    } else if (this.calcId === 'four') {
      FourCalculator();
    } else if (this.calcId === 'crusade') {
      CrusadeCalculator();
    } else if (this.calcId === 'rems') {
      RemsCalculator();
    } else if (this.calcId === 'aspir') {
      AspirationCalculator();
    } else if (this.calcId === 'parkland') {
      ParklandCalculator();
    } else if (this.calcId === 'qtc') {
      QtcCalculator();
    } else if (this.calcId === 'alvarado') {
      AlvaradoCalculator();
    } else if (this.calcId === 'ripasa') {
      RipasaCalculator();
    } else if (this.calcId === 'csf') {
      CsfCalculator();
    } else if (this.calcId === 'padua') {
      PaduaCalculator();
    } else if (this.calcId === 'mme') {
      MmeCalculator();
    } else if (this.calcId === 'steroid') {
      SteroidCalculator();
    } else if (this.calcId === 'fick') {
      FickCalculator();
    } else if (this.calcId === 'apap') {
      ApapCalculator();
    } else if (this.calcId === 'sgarbossa') {
      SgarbossaCalculator();
    } else if (this.calcId === 'duke') {
      DukeCalculator();
    } else if (this.calcId === 'awol') {
      AwolCalculator();
    } else {
      Column() {
        Text('计算器未找到: ' + this.calcId)
          .fontSize(14)
          .fontColor(AppColors.textSecondary)
          .margin({ top: 40 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
  }
}
