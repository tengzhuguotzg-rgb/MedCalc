import { CalcResult } from './CalcEngine';

export function calculateTimiStemi(age: number, dmHtnAngina: boolean, sbp: number, hr: number, killip: number, weight: number, anteriorLbbb: boolean, timeToTreat: boolean): CalcResult {
  if (age <= 0 || sbp <= 0 || hr <= 0 || weight <= 0) {
    return { value: null, unit: '', tier: '请填写年龄、血压、心率和体重', tierClass: 'tier-info', footnote: '' };
  }

  let score = 0;
  if (age >= 75) score += 3;
  else if (age >= 65) score += 2;
  else if (age >= 55) score += 1;

  if (dmHtnAngina) score += 1;
  if (sbp < 100) score += 3;
  if (hr > 100) score += 2;
  if (killip >= 2) score += 2;
  if (weight < 67) score += 1;
  if (anteriorLbbb) score += 1;
  if (timeToTreat) score += 1;

  let tier: string;
  let tierClass: string;
  let footnote: string;

  if (score <= 3) {
    tier = '低风险';
    tierClass = 'tier-ok';
    footnote = '30天死亡率约0.8%';
  } else if (score <= 5) {
    tier = '中风险';
    tierClass = 'tier-warn';
    footnote = '30天死亡率约2.2%';
  } else if (score <= 7) {
    tier = '高风险';
    tierClass = 'tier-warn';
    footnote = '30天死亡率约5.0%';
  } else {
    tier = '极高风险';
    tierClass = 'tier-danger';
    footnote = '30天死亡率约11.0%';
  }

  return { value: score, unit: '/ 14', tier, tierClass, footnote };
}

export function calculateTimiNstemi(age: number, riskFactorsGte3: boolean, priorAspirin: boolean, stDev: number, troponin: number): CalcResult {
  if (age <= 0) {
    return { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
  }

  let score = 0;
  if (age >= 65) score += 2;
  else if (age >= 45) score += 1;
  
  if (riskFactorsGte3) score += 1;
  if (priorAspirin) score += 1;
  if (stDev > 0.5) score += 1;
  if (troponin > 0.01) score += 1;

  let tier: string;
  let tierClass: string;
  let footnote: string;

  if (score <= 2) {
    tier = '低风险';
    tierClass = 'tier-ok';
    footnote = '14天死亡/MI风险约3.1%';
  } else if (score <= 4) {
    tier = '中风险';
    tierClass = 'tier-warn';
    footnote = '14天死亡/MI风险约8.3%';
  } else {
    tier = '高风险';
    tierClass = 'tier-danger';
    footnote = '14天死亡/MI风险约19.9%';
  }

  return { value: score, unit: '分', tier, tierClass, footnote };
}
