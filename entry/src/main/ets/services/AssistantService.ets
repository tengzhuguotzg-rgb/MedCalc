import { CalcResult } from '../engine/CalcEngine';
import { calculateMap } from '../engine/MapCalculator';
import { calculateSf } from '../engine/SfCalculator';
import { calculateGcs } from '../engine/GcsCalculator';
import { calculateNews2 } from '../engine/News2Calculator';
import { calculateBg, BgInput, BgResult } from '../engine/BloodGasCalculator';
import { calculateSofa } from '../engine/SofaCalculator';
import { calculatePf, calculateNa, calculateCurb65, calculateSirs } from '../engine/CommonCalculators';
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
import { CALCULATORS } from '../model/CalculatorRegistry';
import { ApiServiceConfig, sendVisionRequest } from './LlmService';

export interface DataFieldSpec {
  key: string;
  label: string;
  unit: string;
  type: 'number' | 'select' | 'text';
  options?: string[];
  normalRange?: string;
}

export interface CalcInputSpec {
  calcId: string;
  requiredFields: string[];
  optionalFields: string[];
}

export class CalcMatch {
  calcId: string = '';
  calcName: string = '';
  icon: string = '📊';
  completeness: number = 0;
  availableFields: string[] = [];
  missingFields: string[] = [];
  result: CalcResult | null = null;
}

export class AssistantMessage {
  id: string = '';
  role: 'user' | 'assistant' = 'user';
  timestamp: number = 0;
  text: string = '';
  imageUri: string = '';
  extractedData: Record<string, string> = {};
  matches: CalcMatch[] = [];
  summaryText: string = '';
}

class ExtractionResult {
  fields: Map<string, string> = new Map();
  matchedCalcIds: string[] = [];
}

const DATA_FIELDS: DataFieldSpec[] = [
  { key: 'reportDate', label: '检查日期', unit: '', type: 'text' },
  { key: 'reportTime', label: '检查时间', unit: '', type: 'text' },
  { key: 'age', label: '年龄', unit: '岁', type: 'number', normalRange: '18-100' },
  { key: 'sex', label: '性别', unit: '', type: 'select', options: ['male', 'female'] },
  { key: 'weight', label: '体重', unit: 'kg', type: 'number', normalRange: '40-120' },
  { key: 'height', label: '身高', unit: 'cm', type: 'number', normalRange: '140-200' },
  { key: 'sbp', label: '收缩压', unit: 'mmHg', type: 'number', normalRange: '90-140' },
  { key: 'dbp', label: '舒张压', unit: 'mmHg', type: 'number', normalRange: '60-90' },
  { key: 'map', label: '平均动脉压', unit: 'mmHg', type: 'number', normalRange: '70-105' },
  { key: 'hr', label: '心率', unit: '次/分', type: 'number', normalRange: '60-100' },
  { key: 'rr', label: '呼吸频率', unit: '次/分', type: 'number', normalRange: '12-20' },
  { key: 'temp', label: '体温', unit: '°C', type: 'number', normalRange: '36.0-38.0' },
  { key: 'spo2', label: 'SpO2', unit: '%', type: 'number', normalRange: '95-100' },
  { key: 'fio2', label: 'FiO2', unit: '', type: 'number', normalRange: '0.21-1.0' },
  { key: 'fio2Mode', label: 'FiO2模式', unit: '', type: 'select', options: ['dec', 'pct'] },
  { key: 'pao2', label: 'PaO2', unit: 'mmHg', type: 'number', normalRange: '80-100' },
  { key: 'pao2Unit', label: 'PaO2单位', unit: '', type: 'select', options: ['mmhg', 'kpa'] },
  { key: 'paco2', label: 'PaCO2', unit: 'mmHg', type: 'number', normalRange: '35-45' },
  { key: 'paco2Unit', label: 'PaCO2单位', unit: '', type: 'select', options: ['mmhg', 'kpa'] },
  { key: 'ph', label: 'pH', unit: '', type: 'number', normalRange: '7.35-7.45' },
  { key: 'hco3', label: 'HCO3', unit: 'mmol/L', type: 'number', normalRange: '22-26' },
  { key: 'be', label: 'BE', unit: 'mmol/L', type: 'number', normalRange: '-2 to +2' },
  { key: 'lac', label: '乳酸', unit: 'mmol/L', type: 'number', normalRange: '0.5-2.0' },
  { key: 'creatinine', label: '血肌酐', unit: 'μmol/L', type: 'number', normalRange: '44-133' },
  { key: 'crUnit', label: '肌酐单位', unit: '', type: 'select', options: ['umol', 'mgdl'] },
  { key: 'bun', label: '尿素氮', unit: 'mmol/L', type: 'number', normalRange: '2.9-8.2' },
  { key: 'urea', label: '尿素', unit: 'mmol/L', type: 'number', normalRange: '2.9-8.2' },
  { key: 'ureaUnit', label: '尿素单位', unit: '', type: 'select', options: ['mmol', 'mgdl'] },
  { key: 'gfr', label: 'eGFR', unit: 'mL/min', type: 'number', normalRange: '>90' },
  { key: 'na', label: '血钠', unit: 'mmol/L', type: 'number', normalRange: '137-147' },
  { key: 'k', label: '血钾', unit: 'mmol/L', type: 'number', normalRange: '3.5-5.3' },
  { key: 'cl', label: '血氯', unit: 'mmol/L', type: 'number', normalRange: '98-106' },
  { key: 'ca', label: '血钙', unit: 'mmol/L', type: 'number', normalRange: '2.11-2.52' },
  { key: 'glu', label: '血糖', unit: 'mmol/L', type: 'number', normalRange: '3.9-6.1' },
  { key: 'alb', label: '白蛋白', unit: 'g/L', type: 'number', normalRange: '35-50' },
  { key: 'albUnit', label: '白蛋白单位', unit: '', type: 'select', options: ['gl', 'gdl'] },
  { key: 'bilirubin', label: '胆红素', unit: 'μmol/L', type: 'number', normalRange: '3.4-17.1' },
  { key: 'bilirubinUnit', label: '胆红素单位', unit: '', type: 'select', options: ['umol', 'mgdl'] },
  { key: 'platelet', label: '血小板', unit: '×10⁹/L', type: 'number', normalRange: '150-400' },
  { key: 'wbc', label: 'WBC', unit: '×10⁹/L', type: 'number', normalRange: '3.5-9.5' },
  { key: 'hgb', label: '血红蛋白', unit: 'g/L', type: 'number', normalRange: '130-175' },
  { key: 'hgbUnit', label: '血红蛋白单位', unit: '', type: 'select', options: ['gl', 'gdl'] },
  { key: 'hct', label: '红细胞比容', unit: '%', type: 'number', normalRange: '37-50' },
  { key: 'acute', label: '急慢性', unit: '', type: 'select', options: ['acute', 'chronic'] },
  { key: 'inr', label: 'INR', unit: '', type: 'number', normalRange: '0.8-1.2' },
  { key: 'sao2', label: 'SaO2', unit: '%', type: 'number', normalRange: '95-100' },
  { key: 'bands', label: '杆状核', unit: '%', type: 'number', normalRange: '0-6' },
  { key: 'urineOutput', label: '尿量', unit: 'mL/d', type: 'number', normalRange: '800-2000' },
  { key: 'contrast', label: '造影剂用量', unit: 'mL', type: 'number' },
  { key: 'peep', label: 'PEEP', unit: 'cmH2O', type: 'number', normalRange: '0-20' },
  { key: 'gcs', label: 'GCS评分', unit: '分', type: 'number', normalRange: '3-15' },
  { key: 'gcsEye', label: 'GCS睁眼', unit: '分', type: 'number', normalRange: '1-4' },
  { key: 'gcsVerbal', label: 'GCS言语', unit: '分', type: 'number', normalRange: '1-5' },
  { key: 'gcsMotor', label: 'GCS运动', unit: '分', type: 'number', normalRange: '1-6' },
  { key: 'rassScore', label: 'RASS评分', unit: '分', type: 'number', normalRange: '-5 to +4' },
  { key: 'ichVol', label: '脑出血量', unit: 'mL', type: 'number' },
  { key: 'ichLocation', label: '出血部位', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'ichIvh', label: '脑室出血', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'huntHessGrade', label: 'Hunt-Hess分级', unit: '级', type: 'number', normalRange: '0-5' },
  { key: 'wfnsGrade', label: 'WFNS分级', unit: '级', type: 'number', normalRange: '1-5' },
  { key: 'fisherGrade', label: 'Fisher分级', unit: '级', type: 'number', normalRange: '1-4' },
  { key: 'vaso', label: '血管活性药', unit: '', type: 'select', options: ['none', 'dopamine_low', 'dopamine_mid', 'dopamine_high', 'norepinephrine', 'epinephrine', 'dobutamine'] },
  { key: 'o2supplement', label: '氧疗', unit: '', type: 'select', options: ['air', 'o2'] },
  { key: 'consciousness', label: '意识状态', unit: '', type: 'select', options: ['alert', 'voice', 'pain', 'unresponsive'] },
  { key: 'confusion', label: '意识模糊', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'chf', label: '心衰', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'htn', label: '高血压', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'dm', label: '糖尿病', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'stroke', label: '卒中史', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'vasc', label: '血管疾病', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'female', label: '女性', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'age75', label: '年龄≥75', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'age65', label: '年龄65-74', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'renal', label: '肾病', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'liver', label: '肝病', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'bleed', label: '出血史', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'inrAbn', label: 'INR异常', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'drugs', label: '用药史', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'alcohol', label: '酗酒', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'bpAbn', label: '血压异常', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'clinSym', label: '临床症状数', unit: '项', type: 'number', normalRange: '0-2' },
  { key: 'dur', label: '持续时间', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'nihss1a', label: '1a意识', unit: '分', type: 'number', normalRange: '0-3' },
  { key: 'nihss1b', label: '1b提问', unit: '分', type: 'number', normalRange: '0-2' },
  { key: 'nihss1c', label: '1c指令', unit: '分', type: 'number', normalRange: '0-2' },
  { key: 'nihss2', label: '2凝视', unit: '分', type: 'number', normalRange: '0-2' },
  { key: 'nihss3', label: '3视野', unit: '分', type: 'number', normalRange: '0-3' },
  { key: 'nihss4', label: '4面瘫', unit: '分', type: 'number', normalRange: '0-3' },
  { key: 'nihss5a', label: '5a左上肢', unit: '分', type: 'number', normalRange: '0-4' },
  { key: 'nihss5b', label: '5b右上肢', unit: '分', type: 'number', normalRange: '0-4' },
  { key: 'nihss7', label: '7共济', unit: '分', type: 'number', normalRange: '0-2' },
  { key: 'nihss8', label: '8感觉', unit: '分', type: 'number', normalRange: '0-2' },
  { key: 'nihss9', label: '9语言', unit: '分', type: 'number', normalRange: '0-3' },
  { key: 'nihss10', label: '10构音', unit: '分', type: 'number', normalRange: '0-2' },
  { key: 'nihss11', label: '11忽视', unit: '分', type: 'number', normalRange: '0-2' },
  { key: 'ascites', label: '腹水', unit: '级', type: 'number', normalRange: '1-3' },
  { key: 'encephalopathy', label: '肝性脑病', unit: '级', type: 'number', normalRange: '1-4' },
  { key: 'hepaticEnceph', label: '肝性脑病CLIF', unit: '级', type: 'number', normalRange: '0-4' },
  { key: 'etiology', label: '病因', unit: '', type: 'select', options: ['acetaminophen', 'other'] },
  { key: 'arf', label: '急性肾衰', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'chronic', label: '慢性健康', unit: '', type: 'select', options: ['none', 'nonSurgical', 'surgical'] },
  { key: 'ageCat', label: 'TIMI年龄组', unit: '', type: 'select', options: ['0', '1', '2', '3'] },
  { key: 'dmHtnAngina', label: 'DM/HTN/心绞痛', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'sbpLt100', label: 'SBP<100', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'hrGt100', label: 'HR>100', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'killip', label: 'Killip分级', unit: '级', type: 'number', normalRange: '1-4' },
  { key: 'weightLt67', label: '体重<67kg', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'anteriorLbbb', label: '前壁/LBBB', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'timeToTreat', label: '就诊延迟', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'ageGte65', label: '年龄≥65', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'riskFactorsGte3', label: '≥3危险因素', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'knownCAD', label: '已知CAD', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'priorAspirin', label: '阿司匹林史', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'severeAngina', label: '严重心绞痛', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'stDevGte05', label: 'ST偏移≥0.5', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'biomarkerElevated', label: '标志物升高', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'clinicalPe', label: 'PE体征', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'hrGt100Pe', label: 'HR>100(PE)', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'surgery', label: '近期手术', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'hemoptysis', label: '咯血', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'cancer', label: '恶性肿瘤', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'anemia', label: '贫血', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'sexPesi', label: '性别PESI', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'cancerPesi', label: '肿瘤PESI', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'chfPesi', label: '心衰PESI', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'cldPesi', label: '肝病PESI', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'ams', label: '意识改变PESI', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'osp', label: '坐位SpO2<90', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'perf', label: '灌注体征', unit: '', type: 'select', options: ['A', 'B', 'C'] },
  { key: 'resus', label: '复苏状态', unit: '', type: 'select', options: ['A', 'B', 'C'] },
  { key: 'comorb', label: '合并症mNUTRIC', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'icuDay', label: 'ICU住院天', unit: '天', type: 'number' },
  { key: 'apache2Score', label: 'APACHEII评分', unit: '分', type: 'number' },
  { key: 'sofaScore', label: 'SOFA评分', unit: '分', type: 'number' },
  { key: 'roll', label: '翻身', unit: '分', type: 'number', normalRange: '0-7' },
  { key: 'situp', label: '坐起', unit: '分', type: 'number', normalRange: '0-7' },
  { key: 'sit', label: '坐位', unit: '分', type: 'number', normalRange: '0-7' },
  { key: 'standup', label: '站起', unit: '分', type: 'number', normalRange: '0-7' },
  { key: 'stand', label: '站立', unit: '分', type: 'number', normalRange: '0-7' },
  { key: 'cr0', label: '基线肌酐', unit: 'μmol/L', type: 'number' },
  { key: 'cr1', label: '当前肌酐', unit: 'μmol/L', type: 'number' },
  { key: 'cr0Unit', label: '基线肌酐单位', unit: '', type: 'select', options: ['umol', 'mgdl'] },
  { key: 'cr1Unit', label: '当前肌酐单位', unit: '', type: 'select', options: ['umol', 'mgdl'] },
  { key: 'rrt', label: 'RRT', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'weightLoss', label: '体重下降', unit: '', type: 'select', options: ['none', 'mild', 'mod', 'severe'] },
  { key: 'intake', label: '进食量', unit: '', type: 'select', options: ['normal', 'mild', 'mod', 'severe'] },
  { key: 'disease', label: '疾病严重度NRS', unit: '', type: 'select', options: ['none', 'moderate', 'severe'] },
  { key: 'ageAdj', label: '年龄≥70(NRS)', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'acKf', label: 'ACLF-KF', unit: '', type: 'select', options: ['0', '1'] },
  { key: 'camF1', label: 'CAM特征1', unit: '分', type: 'number', normalRange: '0-1' },
  { key: 'camF2', label: 'CAM特征2', unit: '分', type: 'number', normalRange: '0-1' },
  { key: 'camF3', label: 'CAM特征3', unit: '分', type: 'number', normalRange: '0-1' },
  { key: 'camF4', label: 'CAM特征4', unit: '分', type: 'number', normalRange: '0-1' },
  { key: 'crp', label: 'C反应蛋白', unit: 'mg/L', type: 'number', normalRange: '0-10' },
  { key: 'pct', label: '降钙素原', unit: 'ng/mL', type: 'number', normalRange: '<0.05' },
  { key: 'hsCrp', label: '超敏CRP', unit: 'mg/L', type: 'number', normalRange: '0-10' },
  { key: 'saa', label: '血清淀粉样蛋白A', unit: 'mg/L', type: 'number', normalRange: '0-10' },
  { key: 'esr', label: '血沉', unit: 'mm/h', type: 'number', normalRange: '0-20' },
  { key: 'il6', label: 'IL-6', unit: 'pg/mL', type: 'number', normalRange: '0-7' },
  { key: 'ctni', label: '肌钙蛋白I', unit: 'ng/mL', type: 'number', normalRange: '<0.018' },
  { key: 'ckmb', label: 'CK-MB', unit: 'ng/mL', type: 'number', normalRange: '<5' },
  { key: 'myo', label: '肌红蛋白', unit: 'ng/mL', type: 'number', normalRange: '16.5-95.2' },
  { key: 'bnp', label: 'BNP', unit: 'pg/mL', type: 'number', normalRange: '<100' },
  { key: 'aptt', label: 'APTT', unit: '秒', type: 'number', normalRange: '24.8-33.8' },
  { key: 'pt', label: 'PT', unit: '秒', type: 'number', normalRange: '10-14.5' },
  { key: 'pta', label: 'PT活动度', unit: '%', type: 'number', normalRange: '70-130' },
  { key: 'inr', label: 'INR', unit: '', type: 'number', normalRange: '0.8-1.3' },
  { key: 'tt', label: 'TT', unit: '秒', type: 'number', normalRange: '14-21' },
  { key: 'fib', label: '纤维蛋白原', unit: 'g/L', type: 'number', normalRange: '2.0-4.0' },
  { key: 'fdp', label: 'FDP', unit: 'μg/mL', type: 'number', normalRange: '<5' },
  { key: 'dDimer', label: 'D-二聚体', unit: 'mg/L', type: 'number', normalRange: '<1.0' },
  { key: 'atiii', label: '抗凝血酶III', unit: '%', type: 'number', normalRange: '80-120' },
  { key: 'alt', label: 'ALT', unit: 'U/L', type: 'number', normalRange: '21-72' },
  { key: 'ast', label: 'AST', unit: 'U/L', type: 'number', normalRange: '17-59' },
  { key: 'alp', label: 'ALP', unit: 'U/L', type: 'number', normalRange: '38-126' },
  { key: 'ggt', label: 'GGT', unit: 'U/L', type: 'number', normalRange: '15-73' },
  { key: 'che', label: '胆碱酯酶', unit: 'U/L', type: 'number', normalRange: '5900-12220' },
  { key: 'ammonia', label: '血氨', unit: 'μmol/L', type: 'number', normalRange: '0-50' },
  { key: 'dbil', label: '结合胆红素', unit: 'μmol/L', type: 'number', normalRange: '0-5' },
  { key: 'ibil', label: '未结合胆红素', unit: 'μmol/L', type: 'number', normalRange: '0-19' },
  { key: 'rbc', label: 'RBC', unit: '×10¹²/L', type: 'number', normalRange: '4.0-5.5' },
  { key: 'mcv', label: 'MCV', unit: 'fL', type: 'number', normalRange: '80-100' },
  { key: 'mch', label: 'MCH', unit: 'pg', type: 'number', normalRange: '27-34' },
  { key: 'mchc', label: 'MCHC', unit: 'g/L', type: 'number', normalRange: '320-360' },
  { key: 'rdw', label: 'RDW', unit: '%', type: 'number', normalRange: '11-15' },
  { key: 'retic', label: '网织红细胞', unit: '%', type: 'number', normalRange: '0.5-1.5' },
  { key: 'mg', label: '血镁', unit: 'mmol/L', type: 'number', normalRange: '0.7-1.0' },
  { key: 'p', label: '血磷', unit: 'mmol/L', type: 'number', normalRange: '0.85-1.51' },
  { key: 'prealbumin', label: '前白蛋白', unit: 'mg/L', type: 'number', normalRange: '200-400' },
  { key: 'bmi', label: 'BMI', unit: 'kg/m²', type: 'number', normalRange: '18.5-24' },
  { key: 'tferritin', label: '铁蛋白', unit: 'μg/L', type: 'number' },
  { key: 'tg', label: '甘油三酯', unit: 'mmol/L', type: 'number', normalRange: '<1.7' },
  { key: 'tsh', label: 'TSH', unit: 'mIU/L', type: 'number', normalRange: '0.3-4.5' },
  { key: 'ft3', label: 'FT3', unit: 'pmol/L', type: 'number', normalRange: '3.1-6.8' },
  { key: 'ft4', label: 'FT4', unit: 'pmol/L', type: 'number', normalRange: '12-22' },
  { key: 'cortisol', label: '皮质醇', unit: 'nmol/L', type: 'number' },
  { key: 'ck', label: 'CK', unit: 'U/L', type: 'number', normalRange: '0-200' },
  { key: 'ldh', label: 'LDH', unit: 'U/L', type: 'number', normalRange: '120-250' },
];

const CALC_ID_ALIASES: Record<string, string> = {
  'blood-gas': 'bg',
  'blood gas': 'bg',
  '血气分析': 'bg',
  'bloodgas': 'bg',
  'pf-ratio': 'pf',
  'anion-gap': 'cag',
  'oxygenation-index': 'pf',
  'pf ratio': 'pf',
  'p/f ratio': 'pf',
  'p/f': 'pf',
  'corrected-sodium': 'na',
  'corrected na': 'na',
  'anion gap': 'cag',
  'wells-criteria': 'wells',
  'wells score': 'wells',
  'child-pugh': 'childpugh',
  'child pugh': 'childpugh',
  'chads-vasc': 'chadsvasc',
  'chadsvasc2': 'chadsvasc',
  'has-bled': 'hasbled',
  'has bled': 'hasbled',
  'timi-stemi': 'timistemi',
  'timi-nstemi': 'timinstemi',
  'timi stemi': 'timistemi',
  'timi nstemi': 'timinstemi',
  'nrs-2002': 'nrs2002',
  'hunt-hess': 'hunthess',
  'hunt hess': 'hunthess',
  'apache ii': 'apache2',
  'apache-ii': 'apache2',
  'pf': 'pf',
  'timistemi': 'timistemi',
  'timinstemi': 'timinstemi',
};

const FIELD_KEY_ALIASES: Record<string, string> = {
  'po2': 'pao2',
  'pco2': 'paco2',
  'sao2': 'spo2',
  'so2': 'spo2',
  'tco2': 'hco3',
  'glucose': 'glu',
  'hb': 'hct',
  'k+': 'k',
  'k-plus': 'k',
  'na+': 'na',
  'na-plus': 'na',
  'ca++': 'ca',
  'ica': 'ca',
  'ionized-calcium': 'ca',
  'bicarbonate': 'hco3',
  'lactate': 'lac',
  'albumin': 'alb',
  'procalcitonin': 'pct',
  'troponin': 'ctni',
  'troponini': 'ctni',
  '肌钙蛋白': 'ctni',
  '肌钙蛋白i': 'ctni',
  'hs-tni': 'ctni',
  'tnt': 'ctni',
  'ntprobnp': 'bnp',
  'nt-probnp': 'bnp',
  'bnp': 'bnp',
  'creatinekinase': 'ck',
  'cpk': 'ck',
  'fibrinogen': 'fib',
  'triglyceride': 'tg',
  'ferritin': 'tferritin',
  'pre-alb': 'prealbumin',
  'creactiveprotein': 'crp',
  'hscrp': 'hsCrp',
  'ddimer': 'dDimer',
  'd-dimer': 'dDimer',
  'antithrombin': 'atiii',
  'atiii': 'atiii',
  'reticulocyte': 'retic',
  'bodymassindex': 'bmi',
  'magnesium': 'mg',
  'phosphorus': 'p',
  'ammonia': 'ammonia',
  'nh3': 'ammonia',
};

function normalizeFieldKey(raw: string): string {
  let key = raw.toLowerCase().trim();
  key = key.replace(/\u2082/g, '2');
  key = key.replace(/\u2083/g, '3');
  key = key.replace(/\u2084/g, '4');
  key = key.replace(/\u207a/g, '+');
  key = key.replace(/\u207b/g, '-');
  key = key.replace(/\u00b2/g, '2');
  key = key.replace(/\u00b3/g, '3');
  let cleaned = '';
  for (let i = 0; i < key.length; i++) {
    const c = key[i];
    if ((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c === '+' || c === '-') {
      cleaned += c;
    }
  }
  if (cleaned.length === 0 && raw.length > 0) {
    for (const f of DATA_FIELDS) {
      if (f.label === raw || normalizeForSearch(f.label) === normalizeForSearch(raw)) {
        return f.key;
      }
    }
  }
  return cleaned;
}

function normalizeForSearch(raw: string): string {
  let s = raw.toLowerCase();
  s = s.replace(/\u2082/g, '2');
  s = s.replace(/\u2083/g, '3');
  s = s.replace(/\u2084/g, '4');
  s = s.replace(/\u207a/g, '+');
  s = s.replace(/\u207b/g, '-');
  s = s.replace(/\u00b2/g, '2');
  s = s.replace(/\u00b3/g, '3');
  return s;
}

const CALC_INPUT_SPECS: CalcInputSpec[] = [
  { calcId: 'map', requiredFields: ['sbp', 'dbp'], optionalFields: [] },
  { calcId: 'bg', requiredFields: ['ph', 'paco2', 'hco3', 'na', 'cl'], optionalFields: ['pao2', 'be', 'spo2', 'lac', 'k', 'glu', 'fio2', 'fio2Mode', 'hgb', 'hct'] },
  { calcId: 'sf', requiredFields: ['spo2', 'fio2'], optionalFields: ['fio2Mode'] },
  { calcId: 'gcs', requiredFields: ['gcsEye', 'gcsVerbal', 'gcsMotor'], optionalFields: [] },
  { calcId: 'news2', requiredFields: ['rr', 'spo2', 'o2supplement', 'temp', 'sbp', 'hr', 'consciousness'], optionalFields: [] },
  { calcId: 'sofa', requiredFields: ['pao2', 'fio2', 'platelet', 'bilirubin', 'bilirubinUnit', 'map', 'vaso', 'gcs', 'creatinine', 'crUnit', 'urineOutput'], optionalFields: ['fio2Mode'] },
  { calcId: 'pf', requiredFields: ['pao2', 'fio2'], optionalFields: ['fio2Mode', 'peep'] },
  { calcId: 'na', requiredFields: ['na', 'glu'], optionalFields: [] },
  { calcId: 'curb65', requiredFields: ['confusion', 'urea', 'ureaUnit', 'rr', 'sbp', 'dbp', 'age'], optionalFields: [] },
  { calcId: 'sirs', requiredFields: ['temp', 'hr', 'rr', 'paco2', 'wbc', 'bands'], optionalFields: [] },
  { calcId: 'rox', requiredFields: ['spo2', 'fio2', 'fio2Mode', 'rr'], optionalFields: [] },
  { calcId: 'cag', requiredFields: ['na', 'cl', 'hco3', 'alb', 'albUnit'], optionalFields: [] },
  { calcId: 'chadsvasc', requiredFields: ['chf', 'htn', 'age75', 'dm', 'stroke', 'vasc', 'age65', 'female'], optionalFields: [] },
  { calcId: 'hasbled', requiredFields: ['htn', 'renal', 'liver', 'stroke', 'bleed', 'inrAbn', 'age', 'drugs', 'alcohol'], optionalFields: [] },
  { calcId: 'abcd2', requiredFields: ['age', 'bpAbn', 'clinSym', 'dur', 'dm'], optionalFields: [] },
  { calcId: 'nihss', requiredFields: ['nihss1a', 'nihss1b', 'nihss1c', 'nihss2', 'nihss3', 'nihss4', 'nihss5a', 'nihss5b', 'nihss7', 'nihss8', 'nihss9', 'nihss10', 'nihss11'], optionalFields: [] },
  { calcId: 'crcl', requiredFields: ['sex', 'age', 'weight', 'creatinine', 'crUnit'], optionalFields: [] },
  { calcId: 'gfr', requiredFields: ['sex', 'age', 'creatinine', 'crUnit'], optionalFields: [] },
  { calcId: 'apache2', requiredFields: ['temp', 'sbp', 'dbp', 'hr', 'rr', 'fio2', 'fio2Mode', 'pao2', 'paco2', 'ph', 'hco3', 'na', 'k', 'creatinine', 'crUnit', 'arf', 'hct', 'wbc', 'gcs', 'age', 'chronic'], optionalFields: [] },
  { calcId: 'rass', requiredFields: ['rassScore'], optionalFields: [] },
  { calcId: 'ich', requiredFields: ['ichVol', 'ichLocation', 'ichIvh', 'age'], optionalFields: [] },
  { calcId: 'hunthess', requiredFields: ['huntHessGrade'], optionalFields: [] },
  { calcId: 'wfns', requiredFields: ['wfnsGrade'], optionalFields: [] },
  { calcId: 'fisher', requiredFields: ['fisherGrade'], optionalFields: [] },
  { calcId: 'marshall', requiredFields: ['pao2', 'fio2', 'peep'], optionalFields: [] },
  { calcId: 'mehran', requiredFields: ['age', 'chf', 'dm', 'gfr', 'contrast', 'anemia'], optionalFields: [] },
  { calcId: 'timistemi', requiredFields: ['ageCat', 'dmHtnAngina', 'sbpLt100', 'hrGt100', 'killip', 'weightLt67', 'anteriorLbbb', 'timeToTreat'], optionalFields: [] },
  { calcId: 'timinstemi', requiredFields: ['ageGte65', 'riskFactorsGte3', 'knownCAD', 'priorAspirin', 'severeAngina', 'stDevGte05', 'biomarkerElevated'], optionalFields: [] },
  { calcId: 'wells', requiredFields: ['clinicalPe', 'hrGt100Pe', 'surgery', 'hemoptysis', 'cancer'], optionalFields: [] },
  { calcId: 'childpugh', requiredFields: ['bilirubin', 'alb', 'inr', 'ascites', 'encephalopathy'], optionalFields: ['bilirubinUnit', 'albUnit'] },
  { calcId: 'kcc', requiredFields: ['inr', 'bilirubin', 'age', 'etiology'], optionalFields: ['bilirubinUnit'] },
  { calcId: 'clifc', requiredFields: ['bilirubin', 'bilirubinUnit', 'creatinine', 'crUnit', 'inr', 'hepaticEnceph', 'map', 'vaso', 'pao2', 'fio2', 'fio2Mode', 'age', 'wbc'], optionalFields: [] },
  { calcId: 'aarc', requiredFields: ['bilirubin', 'bilirubinUnit', 'inr', 'lac', 'hepaticEnceph', 'age', 'acKf'], optionalFields: [] },
  { calcId: 'camicu', requiredFields: ['camF1', 'camF2', 'camF3', 'camF4'], optionalFields: [] },
  { calcId: 'pesi', requiredFields: ['age', 'sexPesi', 'cancerPesi', 'chfPesi', 'cldPesi', 'hr', 'sbp', 'rr', 'temp', 'ams', 'osp'], optionalFields: [] },
  { calcId: 'scai', requiredFields: ['sbp', 'lac', 'vaso', 'perf', 'resus'], optionalFields: [] },
  { calcId: 'mnutric', requiredFields: ['age', 'apache2Score', 'sofaScore', 'comorb', 'icuDay'], optionalFields: [] },
  { calcId: 'fssicu', requiredFields: ['roll', 'situp', 'sit', 'standup', 'stand'], optionalFields: [] },
  { calcId: 'kdigo', requiredFields: ['cr1', 'cr1Unit'], optionalFields: ['cr0', 'cr0Unit', 'urineOutput', 'rrt'] },
  { calcId: 'nrs2002', requiredFields: ['height', 'weight', 'weightLoss', 'intake', 'disease', 'ageAdj'], optionalFields: [] },
];

let msgIdCounter: number = 0;

function generateMsgId(): string {
  msgIdCounter++;
  return 'msg_' + msgIdCounter;
}

export class AssistantService {
  private static instance: AssistantService;
  private messages: AssistantMessage[] = [];
  private allExtractedData: Map<string, string> = new Map();

  private constructor() {}

  static getInstance(): AssistantService {
    if (!AssistantService.instance) {
      AssistantService.instance = new AssistantService();
    }
    return AssistantService.instance;
  }

  getMessages(): AssistantMessage[] {
    return this.messages;
  }

  getAllExtractedData(): Record<string, string> {
    const result: Record<string, string> = {};
    this.allExtractedData.forEach((val: string, key: string) => {
      result[key] = val;
    });
    return result;
  }

  private getExtractedDataRecord(): Record<string, string> {
    const result: Record<string, string> = {};
    this.allExtractedData.forEach((val: string, key: string) => {
      result[key] = val;
    });
    return result;
  }

  clearSession(): void {
    this.messages = [];
    this.allExtractedData = new Map();
  }

  sendMessage(text: string, imageBase64: string, imageMime: string, config: ApiServiceConfig): Promise<AssistantMessage> {
    const userMsg = new AssistantMessage();
    userMsg.id = generateMsgId();
    userMsg.role = 'user';
    userMsg.timestamp = Date.now();
    userMsg.text = text;
    this.messages = [...this.messages, userMsg];

    const systemPrompt = this.buildExtractionPrompt();
    const hasImage = imageBase64.length > 0 && imageMime.length > 0;
    const userContent = text.length > 0 ? text : '请从这张医学检查报告中提取所有可识别的医疗数据参数';

    const requestPromise = hasImage
      ? sendVisionRequest(config, systemPrompt, userContent, imageBase64, imageMime)
      : sendVisionRequest(config, systemPrompt, text, '', '');

    return requestPromise.then((llmContent: string): AssistantMessage => {
      const parsed = this.parseExtractionResponse(llmContent);
      const newFieldsRecord: Record<string, string> = {};
      parsed.fields.forEach((val: string, key: string) => {
        newFieldsRecord[key] = val;
        this.allExtractedData.set(key, val);
      });

      const mergedRecord = this.getExtractedDataRecord();
      const matches = this.computeAllMatches(mergedRecord, parsed.matchedCalcIds);

      const summary = this.buildSummary(newFieldsRecord, matches);

      const assistantMsg = new AssistantMessage();
      assistantMsg.id = generateMsgId();
      assistantMsg.role = 'assistant';
      assistantMsg.timestamp = Date.now();
      assistantMsg.extractedData = newFieldsRecord;
      assistantMsg.matches = matches;
      assistantMsg.summaryText = summary;
      this.messages = [...this.messages, assistantMsg];
      return assistantMsg;
    });
  }

  getCalcInputSpecs(): CalcInputSpec[] {
    return CALC_INPUT_SPECS;
  }

  computeAllMatchesFromRecord(data: Record<string, string>): CalcMatch[] {
    return this.computeAllMatches(data, []);
  }

  getDataFieldSpecs(): DataFieldSpec[] {
    return DATA_FIELDS;
  }

  getFieldLabel(key: string): string {
    for (let i = 0; i < DATA_FIELDS.length; i++) {
      if (DATA_FIELDS[i].key === key) {
        return DATA_FIELDS[i].label;
      }
    }
    return key;
  }

  getFieldSpec(key: string): DataFieldSpec | null {
    for (let i = 0; i < DATA_FIELDS.length; i++) {
      if (DATA_FIELDS[i].key === key) {
        return DATA_FIELDS[i];
      }
    }
    return null;
  }

  supplementData(fields: Record<string, string>): AssistantMessage {
    const entries = Object.entries(fields);
    for (let i = 0; i < entries.length; i++) {
      this.allExtractedData.set(entries[i][0], entries[i][1]);
    }

    const mergedRecord = this.getExtractedDataRecord();
    const matches = this.computeAllMatches(mergedRecord, []);

    for (let i = 0; i < this.messages.length; i++) {
      if (this.messages[i].role === 'assistant' && this.messages[i].matches.length > 0) {
        this.messages[i].matches = matches;
        this.messages[i].summaryText = this.buildSummaryFromMatches(matches);
        this.messages[i].id = generateMsgId();
      }
    }

    this.messages = [...this.messages];
    const lastAssistant = this.findLastAssistantWithMatches();
    if (lastAssistant !== null) {
      return lastAssistant;
    }
    const fallback = new AssistantMessage();
    fallback.id = generateMsgId();
    fallback.role = 'assistant';
    fallback.timestamp = Date.now();
    fallback.matches = matches;
    return fallback;
  }

  private findLastAssistantWithMatches(): AssistantMessage | null {
    for (let i = this.messages.length - 1; i >= 0; i--) {
      if (this.messages[i].role === 'assistant' && this.messages[i].matches.length > 0) {
        return this.messages[i];
      }
    }
    return null;
  }

  getExtractionPrompt(): string {
    return this.buildExtractionPrompt();
  }

  private buildExtractionPrompt(): string {
    let prompt = '你是医学数据提取助手。从用户文字描述或医学检查报告图片中提取所有可识别的医疗参数数值，判断哪些计算器可用。\n';
    prompt += '## 重要规则\n';
    prompt += '- 如果输入是医学检查报告图片（如血气分析、生化检验、血常规等），仔细识别图片中每一项指标及其数值，尽可能多地提取，不要遗漏\n';
    prompt += '- 提取的字段键名必须使用下方列表中准确的 field_key，不要自行翻译或缩写\n';
    prompt += '- 特别注意：PaO2的字段键名是pao2(不是po2)，PaCO2的键名是paco2(不是pco2)，SpO2的键名是spo2(不是sao2)\n';
    prompt += '- 数值和单位要按字段定义转换（如肌酐mg/dL需标注crUnit为mgdl，FiO2百分比需转换为小数如40%→0.4并标注fio2Mode为pct）\n';
    prompt += '- 图片中明确标注的数值均可提取，不需要用户逐项提及\n';
    prompt += '- **只提取图片中明确可见/标注的数值，不要推断、猜测或补全任何未标注的参数**（如FiO2未标注则不提取fio2字段，不要推断为0.21或其他值）\n';
    prompt += '- **报告上的检查日期和时间也必须提取**，分别放入reportDate和reportTime字段，格式：reportDate为YYYY-MM-DD（如2025-01-15），reportTime为HH:MM（如14:30）。如果只有日期没有时间，reportTime留空；如果都没有则两个字段都不填\n\n';
    prompt += '## 可提取字段\n';
    for (const f of DATA_FIELDS) {
      let line = f.key + ': ' + f.label + '(' + f.unit + ')';
      if (f.type === 'select' && f.options) {
        line += ' 选项:' + f.options.join('/');
      }
      if (f.normalRange) {
        line += ' 参考:' + f.normalRange;
      }
      prompt += line + '\n';
    }
    prompt += '\n## 计算器ID列表（matched数组必须使用以下准确的calcId！）\n';
    prompt += '注：这些是系统中定义的计算器ID，matched中只能使用这些ID，不要使用拼音、英文翻译或缩写。\n';
    for (const spec of CALC_INPUT_SPECS) {
      const calc = CALCULATORS.find(c => c.id === spec.calcId);
      if (calc) {
        prompt += spec.calcId + '(' + calc.name + '): 必填[' + spec.requiredFields.join(',') + ']';
        if (spec.optionalFields.length > 0) {
          prompt += ' 可选[' + spec.optionalFields.join(',') + ']';
        }
        prompt += '\n';
      }
    }
    prompt += '\n常见别名对应关系（请勿使用别名，统一用左侧calcId）：\n';
    prompt += 'pf-ratio(氧合指数)→pf, anion-gap(阴离子间隙)→cag, blood-gas(血气分析)→bg, corrected-calcium(校正钙)→系统中无独立计算器, osmolal-gap(渗透压间隙)→系统中无独立计算器\n';
    prompt += '\n## 输出格式\n';
    prompt += '严格输出JSON，不要输出任何其他文字：\n';
    prompt += '{"extracted":{"field_key":"value",...},"matched":["calcId1","calcId2",...]}\n';
    prompt += '规则：1.从文字或图片中尽可能多提取明确可识别的数值 2.数值统一为数字字符串单位按字段定义 3.sex字段用male/female 4.布尔字段用0/1 5.matched列出所有至少有1个必填字段的计算器按相关度排序，必须使用上面列表中准确的calcId 6.如确实无法提取任何医疗数据返回{"extracted":{},"matched":[]}\n';
    return prompt;
  }

  private parseExtractionResponse(content: string): ExtractionResult {
    const result = new ExtractionResult();

    let jsonStr = content.trim();

    const thinkEndTag = '</think>';
    const thinkEndIdx = jsonStr.indexOf(thinkEndTag);
    if (thinkEndIdx !== -1) {
      jsonStr = jsonStr.substring(thinkEndIdx + thinkEndTag.length).trim();
    }

    const fenceMatch = jsonStr.indexOf('```');
    if (fenceMatch !== -1) {
      const afterFence = jsonStr.substring(fenceMatch + 3);
      const fenceEnd = afterFence.indexOf('```');
      if (fenceEnd !== -1) {
        jsonStr = afterFence.substring(0, fenceEnd).trim();
      } else {
        jsonStr = afterFence.trim();
      }
      if (jsonStr.startsWith('json')) {
        jsonStr = jsonStr.substring(4).trim();
      }
    }

    try {
      const parsedStr: Object | null = JSON.parse(jsonStr);
      if (parsedStr === null || parsedStr === undefined) {
        return this.fallbackParse(content);
      }
      const parsed = parsedStr as Record<string, Object>;
      const extractedStr = parsed['extracted'];
      const matchedStr = parsed['matched'];

      if (extractedStr !== undefined && extractedStr !== null && typeof extractedStr === 'object') {
        if (Array.isArray(extractedStr)) {
          const arr = extractedStr as Object[];
          for (let ai = 0; ai < arr.length; ai++) {
            if (typeof arr[ai] === 'object' && arr[ai] !== null) {
              const itemEntries = Object.entries(arr[ai] as Record<string, string>);
              for (let ei = 0; ei < itemEntries.length; ei++) {
                const k = itemEntries[ei][0];
                const v = itemEntries[ei][1];
                const normalized = normalizeFieldKey(k);
                const aliasKey = FIELD_KEY_ALIASES[normalized];
                const resolvedKey = aliasKey !== undefined ? aliasKey : normalized;
                if (typeof v === 'string' && v.length > 0) {
                  result.fields.set(resolvedKey, v);
                } else if (typeof v === 'number') {
                  result.fields.set(resolvedKey, String(v));
                }
              }
            }
          }
        } else {
          const entries = Object.entries(extractedStr as Record<string, string>);
          for (let i = 0; i < entries.length; i++) {
            const key = entries[i][0];
            const val = entries[i][1];
            const normalized = normalizeFieldKey(key);
            const aliasKey = FIELD_KEY_ALIASES[normalized];
            const resolvedKey = aliasKey !== undefined ? aliasKey : normalized;
            if (typeof val === 'string' && val.length > 0) {
              result.fields.set(resolvedKey, val);
            } else if (typeof val === 'number') {
              result.fields.set(resolvedKey, String(val));
            }
          }
        }
      }

      if (matchedStr !== undefined && matchedStr !== null && Array.isArray(matchedStr)) {
        const matchArr = matchedStr as string[];
        for (let i = 0; i < matchArr.length; i++) {
          const m: string = matchArr[i];
          if (typeof m === 'string' && m.length > 0) {
            const id = m.trim().toLowerCase();
            const aliasId = CALC_ID_ALIASES[id];
            const resolvedId = aliasId !== undefined ? aliasId : id;
            if (CALCULATORS.some(c => c.id === resolvedId)) {
              if (!result.matchedCalcIds.some(existing => existing === resolvedId)) {
                result.matchedCalcIds.push(resolvedId);
              }
            }
          }
        }
      }

      return result;
    } catch (_e) {
      const braceStart = jsonStr.indexOf('{');
      const braceEnd = jsonStr.lastIndexOf('}');
      if (braceStart !== -1 && braceEnd > braceStart) {
        const candidate = jsonStr.substring(braceStart, braceEnd + 1);
        try {
          const parsedCandidate: Object | null = JSON.parse(candidate);
          if (parsedCandidate !== null && parsedCandidate !== undefined) {
            const parsed2 = parsedCandidate as Record<string, Object>;
            const extractedStr2 = parsed2['extracted'];
            const matchedStr2 = parsed2['matched'];
            if (extractedStr2 !== undefined && extractedStr2 !== null && typeof extractedStr2 === 'object') {
              if (Array.isArray(extractedStr2)) {
                const arr2 = extractedStr2 as Object[];
                for (let ai = 0; ai < arr2.length; ai++) {
                  if (typeof arr2[ai] === 'object' && arr2[ai] !== null) {
                    const itemEntries = Object.entries(arr2[ai] as Record<string, string>);
                    for (let ei = 0; ei < itemEntries.length; ei++) {
                      const k = itemEntries[ei][0];
                      const v = itemEntries[ei][1];
                      const normalized2 = normalizeFieldKey(k);
                      const aliasKey2 = FIELD_KEY_ALIASES[normalized2];
                      const resolvedKey2 = aliasKey2 !== undefined ? aliasKey2 : normalized2;
                      if (typeof v === 'string' && v.length > 0) {
                        result.fields.set(resolvedKey2, v);
                      } else if (typeof v === 'number') {
                        result.fields.set(resolvedKey2, String(v));
                      }
                    }
                  }
                }
              } else {
                const entries2 = Object.entries(extractedStr2 as Record<string, string>);
                for (let i = 0; i < entries2.length; i++) {
                  const key2 = entries2[i][0];
                  const val2 = entries2[i][1];
                  const normalized2 = normalizeFieldKey(key2);
                  const aliasKey2 = FIELD_KEY_ALIASES[normalized2];
                  const resolvedKey2 = aliasKey2 !== undefined ? aliasKey2 : normalized2;
                  if (typeof val2 === 'string' && val2.length > 0) {
                    result.fields.set(resolvedKey2, val2);
                  } else if (typeof val2 === 'number') {
                    result.fields.set(resolvedKey2, String(val2));
                  }
                }
              }
            }
            if (matchedStr2 !== undefined && matchedStr2 !== null && Array.isArray(matchedStr2)) {
              const matchArr2 = matchedStr2 as string[];
              for (let i = 0; i < matchArr2.length; i++) {
                const m2: string = matchArr2[i];
                if (typeof m2 === 'string' && m2.length > 0) {
                  const id2 = m2.trim().toLowerCase();
                  const aliasId2 = CALC_ID_ALIASES[id2];
                  const resolvedId2 = aliasId2 !== undefined ? aliasId2 : id2;
                  if (CALCULATORS.some(c => c.id === resolvedId2)) {
                    if (!result.matchedCalcIds.some(existing => existing === resolvedId2)) {
                      result.matchedCalcIds.push(resolvedId2);
                    }
                  }
                }
              }
            }
            return result;
          }
        } catch (_e2) {}
      }
      return this.fallbackParse(content);
    }
  }
  public parseExtractionResponsePublic(content: string): Record<string, string> {
    const result = this.parseExtractionResponse(content);
    const record: Record<string, string> = {};
    result.fields.forEach((value: string, key: string) => {
      record[key] = value;
    });
    return record;
  }
  private fallbackParse(content: string): ExtractionResult {
    const result = new ExtractionResult();

    let cleanContent = content;
    const thinkStart = cleanContent.indexOf('<think>');
    const thinkEnd = cleanContent.indexOf('</think>');
    if (thinkStart !== -1 && thinkEnd !== -1) {
      cleanContent = cleanContent.substring(thinkEnd + 8);
    }

    const contentLower = normalizeForSearch(cleanContent);
    for (const calc of CALCULATORS) {
      if (contentLower.indexOf(calc.id) !== -1) {
        if (!result.matchedCalcIds.some(id => id === calc.id)) {
          result.matchedCalcIds.push(calc.id);
        }
      }
    }

    const aliasEntries = Object.entries(CALC_ID_ALIASES);
    for (let i = 0; i < aliasEntries.length; i++) {
      const aliasKey = aliasEntries[i][0];
      const targetId = aliasEntries[i][1];
      if (contentLower.indexOf(aliasKey) !== -1) {
        if (!result.matchedCalcIds.some(id => id === targetId)) {
          if (CALCULATORS.some(c => c.id === targetId)) {
            result.matchedCalcIds.push(targetId);
          }
        }
      }
    }

    const numberPatterns: string[][] = [
      ['age', '年龄', '岁'],
      ['sbp', '收缩压', 'sbp'],
      ['dbp', '舒张压', 'dbp'],
      ['hr', '心率', 'hr'],
      ['rr', '呼吸', 'rr'],
      ['temp', '体温', '温度'],
      ['pao2', 'pao2', 'po2', '氧分压'],
      ['paco2', 'paco2', 'pco2', '二氧化碳分压'],
      ['ph', 'ph', '酸碱度'],
      ['hco3', 'hco3', '碳酸氢根', 'bicarbonate', '标准碳酸氢根'],
      ['be', 'be', '剩余碱', '碱剩余'],
      ['spo2', 'spo2', 'sao2', '血氧饱和度', '血氧'],
      ['fio2', 'fio2', '吸氧浓度', 'fio2'],
      ['creatinine', '肌酐', 'cr', 'creatinine'],
      ['na', '血钠', '钠', 'na+', 'na'],
      ['k', '血钾', '钾', 'k+', 'k'],
      ['cl', '血氯', '氯', '氯离子'],
      ['ca', '血钙', '钙', '总钙', '离子钙'],
      ['glu', '血糖', 'glu', 'glucose'],
      ['lac', '乳酸', 'lactate', 'lac'],
      ['weight', '体重', 'kg'],
      ['height', '身高', 'cm'],
      ['gcs', 'gcs', '格拉斯哥'],
      ['wbc', '白细胞', 'wbc'],
      ['hct', '红细胞压积', 'hct', 'hb', '血红蛋白'],
      ['platelet', '血小板', 'plt', 'platelet'],
      ['bilirubin', '胆红素', 'bilirubin', 'tbil'],
      ['alb', '白蛋白', 'alb', 'albumin', 'alb'],
      ['inr', 'inr'],
      ['map', '平均动脉压', 'map'],
      ['crp', 'crp', 'c反应蛋白', '反应蛋白'],
      ['pct', 'pct', '降钙素原', 'procalcitonin'],
      ['esr', 'esr', '血沉', '红细胞沉降率'],
      ['il6', 'il-6', '白细胞介素6', 'il6'],
      ['tnt', '肌钙蛋白', 'tnt', 'troponin', '肌钙蛋白i', 'ctni'],
      ['ckmb', 'ck-mb', '肌酸激酶同工酶', 'ckmb'],
      ['myo', '肌红蛋白', 'myoglobin', 'myo'],
      ['bnp', 'bnp', '脑钠肽', 'nt-probnp', 'probnp'],
      ['aptt', 'aptt', '部分凝血活酶', '活化部分'],
      ['pt', '凝血酶原时间', 'pt', 'prothrombintime'],
      ['tta', '凝血酶原活动度', 'pta', '凝血酶原活动'],
      ['tt', '凝血酶时间', 'thrombintime', 'tt'],
      ['fib', '纤维蛋白原', 'fibrinogen', 'fib'],
      ['fdp', 'fdp', '纤维蛋白降解物', '纤维蛋白原降解物'],
      ['dDimer', 'd-二聚体', 'd二聚体', 'ddimer', 'd-dimer'],
      ['atiii', '抗凝血酶', 'atiii', 'at-iii'],
      ['alt', 'alt', '谷丙', '谷丙转氨酶'],
      ['ast', 'ast', '谷草', '谷草转氨酶'],
      ['alp', 'alp', '碱性磷酸酶'],
      ['ggt', 'ggt', '转肽酶', '谷氨酰转肽酶'],
      ['ammonia', '血氨', 'ammonia', 'nh3'],
      ['rbc', '红细胞计数', 'rbc'],
      ['mcv', 'mcv', '平均红细胞体积'],
      ['mch', 'mch', '平均红细胞血红蛋白量'],
      ['mchc', 'mchc', '平均红细胞血红蛋白浓度'],
      ['rdw', 'rdw', '红细胞分布宽度'],
      ['retic', '网织红', 'retic', '网织红细胞'],
      ['mg', '血镁', 'magnesium', 'mg'],
      ['p', '血磷', 'phosphorus', '磷'],
      ['prealbumin', '前白蛋白', 'prealbumin', 'palb'],
      ['bmi', 'bmi', '体重指数', '体质指数'],
      ['tferritin', '铁蛋白', 'ferritin', 'tferritin'],
      ['tg', '甘油三酯', 'triglyceride', 'tg'],
      ['tsh', 'tsh', '促甲状腺激素'],
      ['ft3', 'ft3', '游离t3', '游离三碘'],
      ['ft4', 'ft4', '游离t4', '游离甲状腺素'],
      ['cortisol', '皮质醇', 'cortisol'],
      ['ck', '肌酸激酶', 'creatinekinase', 'cpk', 'ck'],
      ['ldh', '乳酸脱氢酶', 'ldh'],
      ['che', '胆碱酯酶', 'che', 'cholinesterase'],
      ['saa', '淀粉样蛋白a', 'saa', '血清淀粉样'],
      ['dbil', '结合胆红素', 'dbil', '直接胆红素'],
      ['ibil', '未结合胆红素', 'ibil', '间接胆红素'],
      ['hgb', '血红蛋白', 'hgb', 'hemoglobin'],
      ['bands', '杆状核', 'bands', 'band'],
      ['urineOutput', '尿量', 'urineoutput'],
      ['bun', '尿素氮', 'bun', 'bloodureanitrogen'],
      ['urea', '尿素', 'urea'],
    ];
    for (const pat of numberPatterns) {
      for (let p = 0; p < pat.length; p++) {
        const searchTarget = normalizeForSearch(pat[p]);
        const idx = contentLower.indexOf(searchTarget);
        if (idx !== -1) {
          const after = cleanContent.substring(idx + pat[p].length);
          const numMatch = after.match(/[\s:=：|]*([0-9]+\.?[0-9]*)/);
          if (numMatch && numMatch[1]) {
            result.fields.set(pat[0], numMatch[1]);
            break;
          }
        }
      }
    }

    const sexSearch = normalizeForSearch(cleanContent);
    if (sexSearch.indexOf('男') !== -1 || sexSearch.indexOf('男性') !== -1) {
      result.fields.set('sex', 'male');
    } else if (sexSearch.indexOf('女') !== -1 || sexSearch.indexOf('女性') !== -1) {
      result.fields.set('sex', 'female');
    }

    return result;
  }

  private computeAllMatches(data: Record<string, string>, matchedCalcIds: string[]): CalcMatch[] {
    const matches: CalcMatch[] = [];
    const dataMap = new Map<string, string>();
    const dataEntries = Object.entries(data);
    for (let i = 0; i < dataEntries.length; i++) {
      dataMap.set(dataEntries[i][0], dataEntries[i][1]);
    }

    const processedIds = new Set<string>();

    for (const spec of CALC_INPUT_SPECS) {
      let availableCount = 0;
      const availableFields: string[] = [];
      const missingFields: string[] = [];

      for (let i = 0; i < spec.requiredFields.length; i++) {
        const key = spec.requiredFields[i];
        const val = dataMap.get(key);
        if (val !== undefined && val.length > 0) {
          availableCount++;
          availableFields.push(key);
        } else {
          missingFields.push(key);
        }
      }

      if (availableCount === 0 && matchedCalcIds.indexOf(spec.calcId) === -1) {
        continue;
      }

      processedIds.add(spec.calcId);

      const completeness = Math.round((availableCount / spec.requiredFields.length) * 100);
      const calc = CALCULATORS.find(c => c.id === spec.calcId);
      const calcName = calc ? calc.name : spec.calcId;
      const icon = calc ? calc.icon : '📊';

      let result: CalcResult | null = null;
      if (completeness === 100) {
        result = this.callEngine(spec.calcId, data);
      }

      const match = new CalcMatch();
      match.calcId = spec.calcId;
      match.calcName = calcName;
      match.icon = icon;
      match.completeness = completeness;
      match.availableFields = availableFields;
      match.missingFields = missingFields;
      match.result = result;
      matches.push(match);
    }

    for (let i = 0; i < matchedCalcIds.length; i++) {
      const id = matchedCalcIds[i];
      if (processedIds.has(id)) {
        continue;
      }
      const spec = CALC_INPUT_SPECS.find(s => s.calcId === id);
      if (!spec) {
        continue;
      }
      const missingFields: string[] = [];
      for (let j = 0; j < spec.requiredFields.length; j++) {
        missingFields.push(spec.requiredFields[j]);
      }
      const calc = CALCULATORS.find(c => c.id === id);
      const match = new CalcMatch();
      match.calcId = id;
      match.calcName = calc ? calc.name : id;
      match.icon = calc ? calc.icon : '📊';
      match.completeness = 0;
      match.availableFields = [];
      match.missingFields = missingFields;
      match.result = null;
      matches.push(match);
    }

    matches.sort((a: CalcMatch, b: CalcMatch): number => {
      if (a.completeness !== b.completeness) {
        return b.completeness - a.completeness;
      }
      return a.missingFields.length - b.missingFields.length;
    });

    return matches;
  }

  getMissingFieldSpecs(calcId: string): DataFieldSpec[] {
    const spec = CALC_INPUT_SPECS.find(s => s.calcId === calcId);
    if (!spec) {
      return [];
    }
    const result: DataFieldSpec[] = [];
    for (let i = 0; i < spec.requiredFields.length; i++) {
      const key = spec.requiredFields[i];
      const val = this.allExtractedData.get(key);
      if (val === undefined || val.length === 0) {
        const fieldSpec = DATA_FIELDS.find(f => f.key === key);
        if (fieldSpec) {
          result.push(fieldSpec);
        }
      }
    }
    return result;
  }

  private callEngine(calcId: string, data: Record<string, string>): CalcResult | null {
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
      return calculateChadsvasc(b('chf'), b('htn'), b('age75'), b('dm'), b('stroke'), b('vasc'), b('age65'), b('female'));
    }
    if (calcId === 'hasbled') {
      return calculateHasbled(b('htn'), b('renal'), b('liver'), b('stroke'), b('bleed'), b('inrAbn'), b('age'), b('drugs'), b('alcohol'));
    }
    if (calcId === 'abcd2') {
      return calculateAbcd2(b('age'), b('bpAbn'), n('clinSym', 0), n('dur', 0), b('dm'));
    }
    if (calcId === 'nihss') {
      return calculateNihss(n('nihss1a', 0), n('nihss1b', 0), n('nihss1c', 0), n('nihss2', 0), n('nihss3', 0), n('nihss4', 0), n('nihss5a', 0), n('nihss5b', 0), n('nihss7', 0), n('nihss8', 0), n('nihss9', 0), n('nihss10', 0), n('nihss11', 0));
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
      return calculateIch(n('ichVol', 0), n('ichLocation', 0), b('ichIvh'), n('age', 0));
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
      return calculateMarshall(n('pao2', 0), n('fio2', 0), n('peep', 0));
    }
    if (calcId === 'mehran') {
      return calculateMehran(n('age', 0), b('chf'), b('dm'), n('gfr', 0), n('contrast', 0), b('anemia'));
    }
    if (calcId === 'timistemi') {
      return calculateTimiStemi(n('ageCat', 0), b('dmHtnAngina'), b('sbpLt100'), b('hrGt100'), n('killip', 0), b('weightLt67'), b('anteriorLbbb'), b('timeToTreat'));
    }
    if (calcId === 'timinstemi') {
      return calculateTimiNstemi(b('ageGte65'), b('riskFactorsGte3'), b('knownCAD'), b('priorAspirin'), b('severeAngina'), b('stDevGte05'), b('biomarkerElevated'));
    }
    if (calcId === 'wells') {
      return calculateWells(b('clinicalPe'), b('hrGt100Pe'), b('surgery'), b('hemoptysis'), b('cancer'));
    }
    if (calcId === 'childpugh') {
      return calculateChildPugh(n('bilirubin', 0), s('bilirubinUnit', 'umol'), n('alb', 0), s('albUnit', 'gl'), n('inr', 0), n('ascites', 1), n('encephalopathy', 1));
    }
    if (calcId === 'kcc') {
      return calculateKcc(n('inr', 0), n('bilirubin', 0), s('bilirubinUnit', 'umol'), n('age', 0), b('etiology'));
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
    return null;
  }

  private buildSummary(newFields: Record<string, string>, matches: CalcMatch[]): string {
    const fieldCount = Object.keys(newFields).length;
    if (fieldCount === 0 && matches.length === 0) {
      return '未能从描述中提取到医疗数据，请提供更详细的病情信息。';
    }
    let summary = '';
    if (fieldCount > 0) {
      summary += '已提取 ' + fieldCount + ' 项数据。';
    }
    const complete = matches.filter(m => m.completeness === 100);
    const partial = matches.filter(m => m.completeness < 100);
    if (complete.length > 0) {
      summary += ' ' + complete.length + ' 个计算器可直接出结果';
    }
    if (partial.length > 0) {
      summary += '，' + partial.length + ' 个缺少部分数据';
    }
    if (complete.length === 0 && partial.length === 0) {
      summary += ' 暂无匹配的计算器。';
    }
    return summary;
  }

  private buildSummaryFromMatches(matches: CalcMatch[]): string {
    const fieldCount = this.allExtractedData.size;
    if (fieldCount === 0 && matches.length === 0) {
      return '未能从描述中提取到医疗数据，请提供更详细的病情信息。';
    }
    let summary = '';
    if (fieldCount > 0) {
      summary += '已提取 ' + fieldCount + ' 项数据。';
    }
    const complete = matches.filter(m => m.completeness === 100);
    const partial = matches.filter(m => m.completeness < 100);
    if (complete.length > 0) {
      summary += ' ' + complete.length + ' 个计算器可直接出结果';
    }
    if (partial.length > 0) {
      summary += '，' + partial.length + ' 个缺少部分数据';
    }
    if (complete.length === 0 && partial.length === 0) {
      summary += ' 暂无匹配的计算器。';
    }
    return summary;
  }
}
