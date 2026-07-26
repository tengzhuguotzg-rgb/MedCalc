import { CalcResult } from './CalcEngine';

export function calculateMehran(
  age: number, chf: boolean, dm: boolean, gfr: number,
  contrast: number, anemia: boolean,
  hypotension: boolean, iabp: boolean
): CalcResult {
  if (age <= 0 || gfr <= 0 || contrast <= 0) {
    return { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
  }

  let score = 0;
  const parts: string[] = [];

  if (age > 75) { score += 4; parts.push('年龄>75→4'); }
  else if (age >= 60) { score += 2; parts.push('年龄60-75→2'); }
  else { parts.push('年龄<60→0'); }

  if (chf) { score += 5; parts.push('心衰→5'); } else { parts.push('心衰✗'); }
  if (dm) { score += 3; parts.push('糖尿病→3'); } else { parts.push('糖尿病✗'); }

  if (gfr < 30) { score += 6; parts.push(`eGFR ${gfr}<30→6`); }
  else if (gfr < 45) { score += 4; parts.push(`eGFR ${gfr} 30-44→4`); }
  else if (gfr < 60) { score += 2; parts.push(`eGFR ${gfr} 45-59→2`); }
  else { parts.push(`eGFR ${gfr}≥60→0`); }

  if (contrast > 100) { score += 6; parts.push(`造影剂 ${contrast}>100mL→6`); }
  else if (contrast > 50) { score += 4; parts.push(`造影剂 ${contrast} 51-100mL→4`); }
  else { score += 2; parts.push(`造影剂 ${contrast}≤50mL→2`); }

  if (anemia) { score += 3; parts.push('贫血→3'); } else { parts.push('贫血✗'); }
  if (hypotension) { score += 5; parts.push('低血压→5'); } else { parts.push('低血压✗'); }
  if (iabp) { score += 5; parts.push('IABP→5'); } else { parts.push('IABP✗'); }

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

  footnote += `\n\n${parts.join('，')} → ${score} 分`;
  footnote += '\nMehran 造影剂肾病风险评分（JACC 2004）：年龄≥60=2/>75=4，心衰=5，糖尿病=3，eGFR<60=2/4/6，造影剂≤50mL=2/51-100=4/>100=6，贫血=3，低血压=5，IABP=5。';

  return { value: score, unit: '分', tier, tierClass, footnote };
}
