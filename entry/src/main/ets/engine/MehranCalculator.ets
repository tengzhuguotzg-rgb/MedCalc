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
  else { parts.push('年龄≤75→0'); }

  if (chf) { score += 5; parts.push('心衰(NYHA III/IV或肺水肿史)→5'); } else { parts.push('心衰✗'); }
  if (dm) { score += 3; parts.push('糖尿病→3'); } else { parts.push('糖尿病✗'); }

  if (gfr < 20) { score += 6; parts.push(`eGFR ${gfr}<20→6`); }
  else if (gfr < 40) { score += 4; parts.push(`eGFR ${gfr} 20-<40→4`); }
  else if (gfr < 60) { score += 2; parts.push(`eGFR ${gfr} 40-<60→2`); }
  else { parts.push(`eGFR ${gfr}≥60→0`); }

  const contrastScore = Math.ceil(contrast / 100);
  score += contrastScore;
  parts.push(`造影剂 ${contrast}mL→${contrastScore}(每100mL+1)`);

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
  footnote += '\nMehran 造影剂肾病风险评分（Mehran R, JACC 2004;44:1393）：低血压=5，IABP=5，心衰=5，年龄>75=4，贫血=3，糖尿病=3，造影剂每100mL=1，eGFR ≥60=0 / 40-<60=2 / 20-<40=4 / <20=6。≤5分：CIN 7.5%/透析0.04%；6-10：14%/0.12%；11-15：26.1%/1.09%；≥16：57.3%/12.6%。';

  return { value: score, unit: '分', tier, tierClass, footnote };
}
