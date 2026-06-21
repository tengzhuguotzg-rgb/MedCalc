import { CalcResult } from './CalcEngine';

export function calculateMehran(age: number, chf: boolean, dm: boolean, gfr: number, contrast: number, anemia: boolean): CalcResult {
  if (age <= 0 || gfr <= 0 || contrast <= 0) {
    return { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
  }

  let score = 0;
  
  if (age > 75) score += 4;
  else if (age > 60) score += 2;
  
  if (chf) score += 5;
  if (dm) score += 3;
  
  if (gfr < 30) score += 6;
  else if (gfr < 45) score += 4;
  else if (gfr < 60) score += 2;
  
  if (contrast > 100) score += 6;
  else if (contrast > 50) score += 4;
  else if (contrast > 0) score += 2;
  
  if (anemia) score += 3;

  let tier: string;
  let tierClass: string;
  let footnote: string;

  if (score <= 5) {
    tier = '低风险';
    tierClass = 'tier-ok';
    footnote = '造影剂肾病风险约7.5%';
  } else if (score <= 10) {
    tier = '中风险';
    tierClass = 'tier-warn';
    footnote = '造影剂肾病风险约14%';
  } else if (score <= 15) {
    tier = '高风险';
    tierClass = 'tier-warn';
    footnote = '造影剂肾病风险约26%';
  } else {
    tier = '极高风险';
    tierClass = 'tier-danger';
    footnote = '造影剂肾病风险约57%';
  }

  return { value: score, unit: '分', tier, tierClass, footnote };
}
