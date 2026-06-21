import { CalcResult } from './CalcEngine';

export function calculateTimiStemi(age: number, dm: boolean, htn: boolean, smoker: boolean, priorMi: boolean, priorRevasc: boolean, stDev: number, troponin: number): CalcResult {
  if (age <= 0) {
    return { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
  }

  let score = 0;
  if (age >= 65) score += 2;
  else if (age >= 55) score += 1;
  
  if (dm) score += 1;
  if (htn) score += 1;
  if (smoker) score += 1;
  if (priorMi) score += 1;
  if (priorRevasc) score += 1;
  if (stDev > 2) score += 3;
  else if (stDev > 0) score += 2;
  if (troponin > 0.1) score += 3;
  else if (troponin > 0) score += 2;

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

  return { value: score, unit: '分', tier, tierClass, footnote };
}

export function calculateTimiNstemi(age: number, riskFactors: number, priorAspirin: boolean, stDev: number, troponin: number): CalcResult {
  if (age <= 0) {
    return { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
  }

  let score = 0;
  if (age >= 65) score += 2;
  else if (age >= 45) score += 1;
  
  if (riskFactors >= 3) score += 1;
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
