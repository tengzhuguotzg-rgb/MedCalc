export class Patient {
  id: string = '';
  name: string = '';
  bedNo: string = '';
  age: number = 0;
  sex: string = '';
  note: string = '';
  createdAt: number = 0;
  updatedAt: number = 0;
}

export class PatientDataPoint {
  id: number = 0;
  patientId: string = '';
  fieldKey: string = '';
  value: string = '';
  source: string = '';
  timestamp: number = 0;
  examTime: number = 0;
  note: string = '';
}

export class PatientRecord {
  id: string = '';
  patientId: string = '';
  type: string = '';
  filePath: string = '';
  textContent: string = '';
  extractedJson: string = '';
  timestamp: number = 0;
  label: string = '';
}

export class PatientAlert {
  id: number = 0;
  patientId: string = '';
  calcId: string = '';
  calcName: string = '';
  completeness: number = 0;
  resultJson: string = '';
  triggeredAt: number = 0;
  status: string = 'active';
}

export class PatientLabAlert {
  id: number = 0;
  patientId: string = '';
  ruleId: string = '';
  name: string = '';
  category: string = '';
  urgency: string = '';
  fieldKey: string = '';
  fieldLabel: string = '';
  value: string = '';
  threshold: string = '';
  unit: string = '';
  description: string = '';
  triggeredAt: number = 0;
  status: string = 'active';
}

export class PatientDashboard {
  patient: Patient = new Patient();
  latestData: Map<string, string> = new Map();
  alerts: PatientAlert[] = [];
  diagnoses: PatientDiagnosis[] = [];
  labAlerts: PatientLabAlert[] = [];
  records: PatientRecord[] = [];
  alertCount: number = 0;
  diagnosisCount: number = 0;
  labAlertCount: number = 0;
  domainTags: string[] = [];
}

export class PatientDiagnosis {
  id: number = 0;
  patientId: string = '';
  ruleId: string = '';
  name: string = '';
  category: string = '';
  urgency: string = '';
  source: string = 'rule';
  missingCriteria: string = '';
  llmConfirmed: number = 0;
  llmNote: string = '';
  triggeredAt: number = 0;
  sortOrder: number = 0;
  status: string = 'active';
}

export const DATA_DOMAINS: Record<string, string[]> = {
  '人口学': ['age', 'sex', 'weight', 'height', 'bmi'],
  '生命体征': ['sbp', 'dbp', 'map', 'hr', 'rr', 'temp', 'spo2'],
  '血气分析': ['ph', 'paco2', 'paco2Unit', 'pao2', 'pao2Unit', 'hco3', 'be', 'fio2', 'fio2Mode', 'lac'],
  '电解质': ['na', 'k', 'cl', 'ca', 'mg', 'p'],
  '肾功能': ['creatinine', 'crUnit', 'bun', 'urea', 'ureaUnit', 'urineOutput', 'gfr', 'cr0', 'cr1', 'cr0Unit', 'cr1Unit', 'rrt'],
  '肝功能': ['bilirubin', 'bilirubinUnit', 'alb', 'albUnit', 'alt', 'ast', 'alp', 'ggt', 'che', 'ammonia', 'inr', 'dbil', 'ibil', 'ascites', 'encephalopathy', 'hepaticEnceph'],
  '血液学': ['hgb', 'hgbUnit', 'hct', 'rbc', 'mcv', 'mch', 'mchc', 'rdw', 'retic', 'platelet', 'wbc', 'bands'],
  '凝血': ['inr', 'pt', 'pta', 'aptt', 'tt', 'fib', 'fdp', 'dDimer', 'atiii'],
  '炎症标志物': ['crp', 'hsCrp', 'pct', 'saa', 'esr', 'il6'],
  '心肌标志物': ['ctni', 'ckmb', 'myo', 'bnp'],
  '神经': ['gcs', 'gcsEye', 'gcsVerbal', 'gcsMotor', 'rassScore', 'consciousness', 'confusion', 'nihss1a', 'nihss1b', 'nihss1c', 'nihss2', 'nihss3', 'nihss4', 'nihss5a', 'nihss5b', 'nihss6a', 'nihss6b', 'nihss7', 'nihss8', 'nihss9', 'nihss10', 'nihss11'],
  '心脏': ['killip', 'chf', 'htn', 'dm', 'stroke', 'vasc', 'age75', 'age65', 'female'],
  '呼吸': ['peep', 'o2supplement', 'fio2Mode', 'pao2', 'paco2'],
  '营养': ['weightLoss', 'intake', 'disease', 'ageAdj', 'prealbumin', 'tferritin', 'tg'],
  '代谢': ['glu'],
  '内分泌': ['tsh', 'ft3', 'ft4', 'cortisol'],
  '肌肉': ['ck', 'ldh'],
  'ICU评分': ['apache2Score', 'sofaScore', 'icuDay', 'vaso', 'comorb'],
};

export const DOMAIN_COLORS: Record<string, string> = {
  '人口学': '#5F6654',
  '生命体征': '#C8881A',
  '血气分析': '#2B6CB0',
  '电解质': '#6B8E23',
  '肾功能': '#D4760A',
  '肝功能': '#8B6914',
  '血液学': '#B1452A',
  '凝血': '#B1452A',
  '炎症标志物': '#C0392B',
  '心肌标志物': '#E74C3C',
  '神经': '#6B4FA0',
  '心脏': '#B1452A',
  '呼吸': '#2B6CB0',
  '营养': '#3D6B4F',
  '代谢': '#C8881A',
  '内分泌': '#9B59B6',
  '肌肉': '#E67E22',
  'ICU评分': '#4A5247',
};
