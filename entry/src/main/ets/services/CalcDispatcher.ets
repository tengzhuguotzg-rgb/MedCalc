// CalcDispatcher.ets - 计算器引擎调度
// 从 AssistantService.ets 拆出，集中 callEngine 的 84 路路由
// 唯一数据源为 CalculatorRegistry，通过 compute 字段映射

import { CalcResult } from '../engine/CalcEngine';
import { calculateMap } from '../engine/MapCalculator';
import { calculateSf } from '../engine/SfCalculator';
import { calculateGcs } from '../engine/GcsCalculator';
import { calculateNews2 } from '../engine/News2Calculator';
import { calculateBg, BgInput, BgResult } from '../engine/BloodGasCalculator';
import { calculateSofa } from '../engine/SofaCalculator';
import { calculatePf, calculateNa, calculateCurb65, calculateSirs, calculateNaDeficit, calculateNaCorrectionRate } from '../engine/CommonCalculators';
import { calculateRox, calculateCag, calculateChadsvasc, calculateHasbled, calculateAbcd2, calculateNihss } from '../engine/MoreCalculators';
import { calculateCrCl } from '../engine/CrClCalculator';
import { calculateGfr } from '../engine/GfrCalculator';
import { calculateApache2 } from '../engine/Apache2Calculator';
import { calculateRass } from '../engine/RassCalculator';
import { calculateIch } from '../engine/IchCalculator';
import { calculateHuntHess, calculateWfns, calculateFisher } from '../engine/HuntHessCalculator';
import { calculateMarshall } from '../engine/MarshallCalculator';
import { calculateMehran } from '../engine/MehranCalculator';
import { calculateTimiStemi, calculateTimiNstemi } from '../engine/TimiCalculator';
import { calculateWells } from '../engine/WellsCalculator';
import { calculateChildPugh } from '../engine/ChildPughCalculator';
import { calculateKcc } from '../engine/KccCalculator';
import { calculateNrs2002 } from '../engine/Nrs2002Calculator';
import { calculateClifC } from '../engine/ClifCCalculator';
import { calculateAarc } from '../engine/AarcCalculator';
import { calculateCamicu } from '../engine/CamicuCalculator';
import { calculatePesi } from '../engine/PesiCalculator';
import { calculateScai } from '../engine/ScaiCalculator';
import { calculateMnutric } from '../engine/MnutricCalculator';
import { calculateFssicu } from '../engine/FssicuCalculator';
import { calculateKdigo } from '../engine/KdigoCalculator';
import { calculateShockIndex, calculateQsofa, calculateRts, calculateRsbi, calculateHellp, calculateMetabolic } from '../engine/Batch1aCalculators';
import { calculateHeart, calculateGbs, calculateBisap, calculateTls, calculateBwps, calculateCpis, calculateAncMascc, calculateWellsDvt } from '../engine/Batch1bCalculators';
import { calculateAdhere, calculateMcmahon, calculateIsth, calculatePlasmic, calculateLactateClearance, calculateAgeAdjustedDdimer, calculateStess, calculateVis, calculateAbc2, calculateAddrs } from '../engine/Batch2aCalculators';
import { calculateAsthma, calculateGoldAbe, calculateBap65, calculateGcsP, calculateCrusade, calculateRems, calculateFour, calculateAspiration } from '../engine/Batch2bCalculators';
import { calculateParkland, calculateQtc, calculateAlvarado, calculateRipasa, calculateCsf, calculatePadua, calculateFick } from '../engine/Batch3aCalculators';
import { calculateSgarbossa, calculateDuke, calculateAwol } from '../engine/Batch3bCalculators';

export class CalcDispatcher {
  static dispatch(calcId: string, data: Record<string, string>): CalcResult | null {
    const dataMap = new Map<string, string>();
    const dataEntries = Object.entries(data);
    for (let i = 0; i < dataEntries.length; i++) {
      dataMap.set(dataEntries[i][0], dataEntries[i][1]);
  }
    const n = (key: string, defaultVal: number): number => {
      const v = dataMap.get(key);
      if (v === undefined || v.length === 0) return defaultVal;
      const parsed = parseFloat(v);
      return isNaN(parsed) ? defaultVal : parsed;
    };
    const s = (key: string, defaultVal: string): string => {
      const v = dataMap.get(key);
      return (v !== undefined && v.length > 0) ? v : defaultVal;
    };
    const b = (key: string): boolean => {
      const v = dataMap.get(key);
      return v === '1' || v === 'true' || v === 'yes';
    };

    if (calcId === 'map') {
      return calculateMap(n('sbp', 0), n('dbp', 0));
    }
    if (calcId === 'bg') {
      const bgInput: BgInput = {
        ph: n('ph', 0) > 0 ? n('ph', 0) : null,
        paco2: n('paco2', 0) > 0 ? n('paco2', 0) : null,
        paco2Unit: s('paco2Unit', 'mmhg'),
        pao2: n('pao2', 0) > 0 ? n('pao2', 0) : null,
        pao2Unit: s('pao2Unit', 'mmhg'),
        hco3: n('hco3', 0) > 0 ? n('hco3', 0) : null,
        be: n('be', -999) !== -999 ? n('be', 0) : null,
        sao2: n('spo2', 0) > 0 ? n('spo2', 0) : null,
        lac: n('lac', 0) > 0 ? n('lac', 0) : null,
        hgb: n('hgb', 0) > 0 ? n('hgb', 0) : null,
        hgbUnit: s('hgbUnit', 'gl'),
        k: n('k', 0) > 0 ? n('k', 0) : null,
        na: n('na', 0) > 0 ? n('na', 0) : null,
        cl: n('cl', 0) > 0 ? n('cl', 0) : null,
        glu: n('glu', 0) > 0 ? n('glu', 0) : null,
        fio2: n('fio2', 0) > 0 ? n('fio2', 0) : null,
        fio2Mode: s('fio2Mode', 'dec'),
        acute: s('acute', 'chronic'),
        pvco2: null,
        pvco2Unit: 'mmhg',
        svo2: null,
        pvo2: null,
        pvo2Unit: 'mmhg',
      };
      const bgResult: BgResult = calculateBg(bgInput);
      const bgResult2: CalcResult = {
        value: null,
        unit: '',
        tier: bgResult.ab.conclusion,
        tierClass: bgResult.ab.tierCls,
        footnote: bgResult.ab.detail + '\n\n' + bgResult.o2.conclusion + '\n' + bgResult.summary.conclusion + '\n' + bgResult.summary.detail
      };
      return bgResult2;
    }
    if (calcId === 'sf') {
      return calculateSf(n('spo2', 0), n('fio2', 0), s('fio2Mode', 'dec'));
    }
    if (calcId === 'gcs') {
      return calculateGcs(n('gcsEye', 4), n('gcsVerbal', 5), n('gcsMotor', 6));
    }
    if (calcId === 'news2') {
      return calculateNews2(n('rr', 0), n('spo2', 0), s('o2supplement', 'air'), n('temp', 0), n('sbp', 0), n('hr', 0), s('consciousness', 'alert'));
    }
    if (calcId === 'sofa') {
      return calculateSofa(n('pao2', 0), n('fio2', 0), s('fio2Mode', 'dec'), n('platelet', 0), n('bilirubin', 0), s('bilirubinUnit', 'umol'), n('map', 0), s('vaso', 'none'), n('gcs', 15), n('creatinine', 0), s('crUnit', 'umol'), n('urineOutput', 0));
    }
    if (calcId === 'pf') {
      return calculatePf(n('pao2', 0), n('fio2', 0), s('fio2Mode', 'dec'), n('peep', 0) > 0 ? n('peep', 0) : null);
    }
    if (calcId === 'na') {
      return calculateNa(n('na', 0), n('glu', 0));
    }
    if (calcId === 'curb65') {
      return calculateCurb65(b('confusion'), n('urea', 0), s('ureaUnit', 'mmol'), n('rr', 0), n('sbp', 0), n('dbp', 0), n('age', 0));
    }
    if (calcId === 'sirs') {
      return calculateSirs(n('temp', 0), n('hr', 0), n('rr', 0), n('paco2', 0), n('wbc', 0), n('bands', 0));
    }
    if (calcId === 'rox') {
      return calculateRox(n('spo2', 0), n('fio2', 0), s('fio2Mode', 'dec'), n('rr', 0));
    }
    if (calcId === 'cag') {
      return calculateCag(n('na', 0), n('cl', 0), n('hco3', 0), n('alb', 0), s('albUnit', 'gl'));
    }
    if (calcId === 'chadsvasc') {
      const a75 = b('age75');
      return calculateChadsvasc(b('chf'), b('htn'), a75, b('dm'), b('stroke'), b('vasc'), !a75 && b('age65'), b('female'));
    }
    if (calcId === 'hasbled') {
      return calculateHasbled(b('htn'), b('renal'), b('liver'), b('stroke'), b('bleed'), b('inrAbn'), b('age'), b('drugs'), b('alcohol'));
    }
    if (calcId === 'abcd2') {
      return calculateAbcd2(b('age'), b('bpAbn'), n('clinSym', 0), n('dur', 0), b('dm'));
    }
    if (calcId === 'nihss') {
      return calculateNihss(n('nihss1a', 0), n('nihss1b', 0), n('nihss1c', 0), n('nihss2', 0), n('nihss3', 0), n('nihss4', 0), n('nihss5a', 0), n('nihss5b', 0), n('nihss6a', 0), n('nihss6b', 0), n('nihss7', 0), n('nihss8', 0), n('nihss9', 0), n('nihss10', 0), n('nihss11', 0));
    }
    if (calcId === 'crcl') {
      return calculateCrCl(s('sex', 'male'), n('age', 0), n('weight', 0), n('creatinine', 0), s('crUnit', 'umol'));
    }
    if (calcId === 'gfr') {
      return calculateGfr(s('sex', 'male'), n('age', 0), n('creatinine', 0), s('crUnit', 'umol'));
    }
    if (calcId === 'apache2') {
      return calculateApache2(n('temp', 0), n('sbp', 0), n('dbp', 0), n('hr', 0), n('rr', 0), n('fio2', 0), s('fio2Mode', 'dec'), n('pao2', 0), n('paco2', 0) > 0 ? n('paco2', 0) : null, n('ph', 0) > 0 ? n('ph', 0) : null, n('hco3', 0) > 0 ? n('hco3', 0) : null, n('na', 0), n('k', 0), n('creatinine', 0), s('crUnit', 'umol'), b('arf'), n('hct', 0), n('wbc', 0), n('gcs', 15), n('age', 0), s('chronic', 'none'));
    }
    if (calcId === 'rass') {
      return calculateRass(n('rassScore', 0));
    }
    if (calcId === 'ich') {
      return calculateIch(n('ichVol', 0), n('ichLocation', 0), b('ichIvh'), n('age', 0), n('gcs', 15));
    }
    if (calcId === 'hunthess') {
      return calculateHuntHess(n('huntHessGrade', 0));
    }
    if (calcId === 'wfns') {
      return calculateWfns(n('wfnsGrade', 0));
    }
    if (calcId === 'fisher') {
      return calculateFisher(n('fisherGrade', 0));
    }
    if (calcId === 'marshall') {
      const fio2Val = s('fio2Mode', 'dec') === 'pct' ? n('fio2', 0) / 100 : n('fio2', 0);
      const crUmol = s('crUnit', 'umol') === 'mgdl' ? n('creatinine', 0) * 88.4 : n('creatinine', 0);
      const biliUmol = s('bilirubinUnit', 'umol') === 'mgdl' ? n('bilirubin', 0) * 17.1 : n('bilirubin', 0);
      return calculateMarshall(n('pao2', 0), fio2Val, crUmol, biliUmol, n('hr', 0), n('cvp', 0), n('map', 0), n('platelet', 0), n('gcs', 0));
    }
    if (calcId === 'mehran') {
      return calculateMehran(n('age', 0), b('chf'), b('dm'), n('gfr', 0), n('contrast', 0), b('anemia'), b('hypotension'), b('iabp'));
    }
    if (calcId === 'timistemi') {
      return calculateTimiStemi(n('ageCat', 0), b('dmHtnAngina'), b('sbpLt100'), b('hrGt100'), n('killip', 0), b('weightLt67'), b('anteriorLbbb'), b('timeToTreat'));
    }
    if (calcId === 'timinstemi') {
      return calculateTimiNstemi(b('ageGte65'), b('riskFactorsGte3'), b('knownCAD'), b('priorAspirin'), b('severeAngina'), b('stDevGte05'), b('biomarkerElevated'));
    }
    if (calcId === 'wells') {
      return calculateWells(b('clinicalPe'), b('peLikely'), b('hrGt100Pe'), b('surgery'), b('prevVte'), b('hemoptysis'), b('cancer'));
    }
    if (calcId === 'childpugh') {
      return calculateChildPugh(n('bilirubin', 0), s('bilirubinUnit', 'umol'), n('alb', 0), s('albUnit', 'gl'), n('inr', 0), n('ascites', 1), n('encephalopathy', 1));
    }
    if (calcId === 'kcc') {
      return calculateKcc(n('inr', 0), n('bilirubin', 0), s('bilirubinUnit', 'umol'), n('age', 0), b('etiology'), b('adverseEtiology'), n('jaundiceDays', 0), n('ph', 0), n('crMgDl', 0), n('hepaticEnceph', -1));
    }
    if (calcId === 'clifc') {
      return calculateClifC(n('bilirubin', 0), s('bilirubinUnit', 'umol'), n('creatinine', 0), s('crUnit', 'umol'), n('inr', 0), n('hepaticEnceph', 0), n('map', 0), s('vaso', 'none'), n('pao2', 0), n('fio2', 0), s('fio2Mode', 'dec'), n('age', 0), n('wbc', 0));
    }
    if (calcId === 'aarc') {
      return calculateAarc(n('bilirubin', 0), s('bilirubinUnit', 'umol'), n('inr', 0), n('lac', 0), n('hepaticEnceph', 0), n('age', 0), b('acKf'));
    }
    if (calcId === 'camicu') {
      return calculateCamicu(n('camF1', 0), n('camF2', 0), n('camF3', 0), n('camF4', 0));
    }
    if (calcId === 'pesi') {
      return calculatePesi(n('age', 0), n('sexPesi', 0), n('cancerPesi', 0), n('chfPesi', 0), n('cldPesi', 0), n('hr', 0), n('sbp', 0), n('rr', 0), n('temp', 0), n('ams', 0), n('osp', 0));
    }
    if (calcId === 'scai') {
      return calculateScai(n('sbp', 0), n('lac', 0), s('vaso', 'none'), s('perf', 'A'), s('resus', 'A'));
    }
    if (calcId === 'mnutric') {
      return calculateMnutric(n('age', 0), n('apache2Score', 0), n('sofaScore', 0), n('comorb', 0), n('icuDay', 0));
    }
    if (calcId === 'fssicu') {
      return calculateFssicu(n('roll', 0), n('situp', 0), n('sit', 0), n('standup', 0), n('stand', 0));
    }
    if (calcId === 'kdigo') {
      const cr0 = n('cr0', 0);
      return calculateKdigo(cr0 > 0 ? cr0 : null, s('cr0Unit', 'umol'), n('cr1', 0), s('cr1Unit', 'umol'), n('urineOutput', 0) > 0 ? n('urineOutput', 0) : null, b('rrt'));
    }
    if (calcId === 'nrs2002') {
      return calculateNrs2002(n('height', 0), n('weight', 0), s('weightLoss', 'none'), s('intake', 'normal'), s('disease', 'none'), b('ageAdj'));
    }
    if (calcId === 'shocki') {
      return calculateShockIndex(n('hr', 0), n('sbp', 0));
    }
    if (calcId === 'qsofa') {
      const qGcs = n('gcs', 0) > 0 ? n('gcs', 0) : n('gcsEye', 0) + n('gcsVerbal', 0) + n('gcsMotor', 0);
      return calculateQsofa(n('rr', 0), n('sbp', 0), qGcs, s('consciousness', ''));
    }
    if (calcId === 'rts') {
      const rtsGcs = n('gcs', 0) > 0 ? n('gcs', 0) : n('gcsEye', 0) + n('gcsVerbal', 0) + n('gcsMotor', 0);
      return calculateRts(rtsGcs, n('sbp', 0), n('rr', 0));
    }
    if (calcId === 'rsbi') {
      return calculateRsbi(n('rr', 0), n('vtMl', 0), s('sbtStatus', 'unknown'));
    }
    if (calcId === 'hellp') {
      return calculateHellp(n('platelet', 0), n('ast', 0), n('alt', 0), n('ldh', 0), n('bilirubin', 0), s('bilirubinUnit', 'umol'), b('hemolysis'), s('pregnancyStatus', 'unknown'));
    }
    if (calcId === 'metab') {
      return calculateMetabolic(n('ca', 0), n('alb', 0), s('albUnit', 'gl'), n('na', 0), n('glu', 0), n('bun', 0), n('measuredOsm', 0));
    }
    if (calcId === 'heart') {
      const uln = n('tropUln', 0);
      const ratio = uln > 0 ? n('ctni', 0) / uln : 0;
      return calculateHeart(n('heartHistory', 0), n('heartEcg', 0), n('age', 0), n('riskFactorCount', 0), b('knownAthero'), ratio);
    }
    if (calcId === 'gbs') {
      return calculateGbs(n('bun', 0) * 2.8, n('hgb', 0) / 10, s('sex', 'male'), n('sbp', 0), n('hr', 0), b('melena'), b('syncope'), b('liverDisease'), b('heartFailure'));
    }
    if (calcId === 'bisap') {
      const bGcs = n('gcs', 0) > 0 ? n('gcs', 0) : n('gcsEye', 0) + n('gcsVerbal', 0) + n('gcsMotor', 0);
      return calculateBisap(n('bun', 0) * 2.8, bGcs, n('sirsCount', 0), n('age', 0), b('pleuralEffusion'));
    }
    if (calcId === 'tls') {
      return calculateTls(n('uricAcid', 0), n('k', 0), n('p', 0), n('ca', 0), n('crUlnRatio', 0), b('arrhythmia'), b('seizure'));
    }
    if (calcId === 'bwps') {
      return calculateBwps(n('temp', 0), n('hr', 0), n('cnsScore', 0), n('giScore', 0), n('chfScore', 0), b('afib'), b('precipitant'));
    }
    if (calcId === 'cpis') {
      const fio2Pct = s('fio2Mode', 'dec') === 'pct' ? n('fio2', 0) : n('fio2', 0) * 100;
      const pf = n('pao2', 0) > 0 && fio2Pct > 0 ? n('pao2', 0) / (fio2Pct / 100) : 0;
      return calculateCpis(n('temp', 0), n('wbc', 0), n('bandsAbs', 0), n('secretions', -1), pf, n('cxrInfiltrate', -1), n('culturePos', -1), b('ards'));
    }
    if (calcId === 'anc') {
      return calculateAncMascc(0, n('wbc', 0), n('neutPct', 0), 0, false, false, false, false, false, n('age', 0));
    }
    if (calcId === 'adhere') {
      const crMgDl = s('crUnit', 'umol') === 'mgdl' ? n('creatinine', 0) : n('creatinine', 0) / 88.4;
      return calculateAdhere(n('bun', 0) * 2.8, n('sbp', 0), crMgDl);
    }
    if (calcId === 'rhabdo') {
      const crUmol = s('crUnit', 'umol') === 'mgdl' ? n('creatinine', 0) * 88.4 : n('creatinine', 0);
      return calculateMcmahon(n('age', 0), s('sex', 'male'), n('ck', 0), crUmol, n('p', 0), n('ca', 0), n('hco3', 0), false);
    }
    if (calcId === 'isth') {
      const dd = n('dDimer', 0);
      const ddGrade = dd > 5 ? 3 : dd >= 1 ? 2 : 0;
      return calculateIsth(n('platelet', 0), ddGrade, n('ptProlong', 0), n('fib', 0));
    }
    if (calcId === 'plasmic') {
      const crMgDl = s('crUnit', 'umol') === 'mgdl' ? n('creatinine', 0) : n('creatinine', 0) / 88.4;
      const hemolysisEvidence = b('hemolysis') || n('retic', 0) > 2.5 || n('ibil', 0) > 34;
      return calculatePlasmic(n('platelet', 0), hemolysisEvidence, b('cancer'), b('transplant'), n('mcv', 0), n('inr', 0), crMgDl);
    }
    if (calcId === 'lacclear') {
      return calculateLactateClearance(n('lac0', 0), n('lac1', 0), 0);
    }
    if (calcId === 'ddage') {
      return calculateAgeAdjustedDdimer(n('age', 0), n('dDimer', 0));
    }
    if (calcId === 'asthma') {
      return calculateAsthma(n('pefPct', 0), n('rr', 0), n('hr', 0), s('speechAbility', ''), b('silentChest'));
    }
    if (calcId === 'goldabe') {
      return calculateGoldAbe(n('mmrc', -1), n('cat', -1), n('exacCount', -1), n('exacHosp', 0));
    }
    if (calcId === 'bap65') {
      const bGcs = n('gcs', 0);
      const altered = (bGcs > 0 && bGcs < 15) || b('confusion');
      return calculateBap65(n('bun', 0) * 2.8, n('hr', 0), n('age', 0), altered);
    }
    if (calcId === 'gcsp') {
      return calculateGcsP(n('gcs', 0), n('pupilReact', 0));
    }
    if (calcId === 'crusade') {
      return calculateCrusade(n('hct', 0), n('gfr', 0), n('hr', 0), s('sex', '') === 'female', b('chf'), b('vasc'), b('dm'), n('sbp', 0));
    }
    if (calcId === 'rems') {
      return calculateRems(n('age', 0), n('map', 0), n('hr', 0), n('rr', 0), n('spo2', 0), n('gcs', 0));
    }
    if (calcId === 'parkland') {
      return calculateParkland(n('weight', 0), n('tbsa', 0));
    }
    if (calcId === 'qtc') {
      return calculateQtc(n('qtMs', 0), n('hr', 0));
    }
    if (calcId === 'alvarado') {
      return calculateAlvarado(n('temp', 0), n('wbc', 0), n('neutPct', 0), b('migratoryPain'), b('anorexia'), b('nauseaVomit'), b('rlqTender'), b('reboundPain'));
    }
    if (calcId === 'ripasa') {
      return calculateRipasa(n('age', 0), s('sex', 'male'), b('rlqPain'), b('migratoryPain'), b('anorexia'), b('nauseaVomit'), b('durLt48h'), b('rlqTender'), b('guardingSign'), b('reboundPain'), b('rovsingSign'), n('temp', 0), n('wbc', 0), b('urineNeg'), b('foreignNational'));
    }
    if (calcId === 'csf') {
      return calculateCsf(n('csfWbc', 0), n('csfNeutPct', 0), n('csfProtein', 0), n('csfGlu', 0), n('glu', 0), n('csfRbc', 0));
    }
    if (calcId === 'padua') {
      return calculatePadua(n('age', 0), b('cancer'), b('prevVte'), b('immobility3d'), b('thrombophilia'), b('traumaSurg1m'), b('hfRespFail'), b('acuteMiStroke'), b('acuteInfection'), n('bmi', 0), b('hormoneRx'));
    }
    if (calcId === 'fick') {
      return calculateFick(n('hgb', 0), n('spo2', 0), n('svo2', 0), n('vo2', 0), n('height', 0), n('weight', 0));
    }
    if (calcId === 'wellsdvt') {
      return calculateWellsDvt(b('cancer'), b('immobilization'), b('bedriddenSurgery'), b('tenderness'), b('legSwollen'), b('calfDiff3cm'), b('pittingEdema'), b('collateralVeins'), b('prevVte'), b('altDiagnosis'));
    }
    if (calcId === 'stess') {
      return calculateStess(n('stessConsciousness', 0), n('seizureType', 0), n('age', 0), b('priorSeizures'));
    }
    if (calcId === 'vis') {
      return calculateVis(n('doseDopamine', 0), n('doseDobutamine', 0), n('doseEpinephrine', 0), n('doseNorepinephrine', 0), n('doseMilrinone', 0), n('doseVasopressin', 0));
    }
    if (calcId === 'addrs') {
      return calculateAddrs(b('addrsCondition'), b('addrsPain'), b('addrsExam'), n('dDimer', 0));
    }
    if (calcId === 'four') {
      return calculateFour(n('fourEye', 0), n('fourMotor', 0), n('fourBrainstem', 0), n('fourResp', 0));
    }
    if (calcId === 'sgarbossa') {
      return calculateSgarbossa(b('concordantSte'), b('concordantStd'), n('discordantMode', 0));
    }
    if (calcId === 'duke') {
      return calculateDuke(b('cultureMajor'), b('echoMajor'), b('predisposition'), b('fever'), b('vascular'), b('immunological'), b('microEvidence'));
    }
    if (calcId === 'awol') {
      return calculateAwol(b('age80'), b('worldBackward'), b('disoriented'), b('severeIllness'));
    }
    if (calcId === 'aspir') {
      return calculateAspiration(b('dysphagia'), b('impairedConsciousness'), b('vomitReflux'), b('enteralTube'), b('sedation'), b('poorOral'));
    }
    if (calcId === 'nadeficit') {
      const isFemale = s('sex', '') === 'female';
      return calculateNaDeficit(n('weight', 0), n('na', 0), n('targetNa', 140), isFemale, b('isChild'));
    }
    if (calcId === 'nacorrection') {
      const isFemale = s('sex', '') === 'female';
      return calculateNaCorrectionRate(n('weight', 0), n('na', 0), n('targetNa', 140), n('rateMmolPerDay', 8), isFemale, b('isChild'), n('fluidNaContent', 154));
    }
    if (calcId === 'abc2') {
      return calculateAbc2(n('abc2A', 0), n('abc2B', 0), n('abc2C', 0));
    }
    return null;
  }
}
