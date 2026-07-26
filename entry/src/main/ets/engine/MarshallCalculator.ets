import { CalcResult } from './CalcEngine';

export function calculateMarshall(pao2: number, fio2: number, peep: number): CalcResult {
  if (pao2 <= 0 || fio2 <= 0 || peep <= 0) {
    return { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
  }

  const pf = pao2 / fio2;
  let score = 0;

  if (pf < 100) score += 4;
  else if (pf < 200) score += 3;
  else if (pf < 300) score += 2;
  else if (pf < 400) score += 1;

  if (peep >= 10) score += 2;
  else if (peep >= 5) score += 1;

  let tier: string;
  let tierClass: string;
  let footnote: string;

  if (score === 0) {
    tier = '无ARDS';
    tierClass = 'tier-ok';
    footnote = 'P/F ≥ 400, PEEP < 5';
  } else if (score <= 2) {
    tier = '轻度ARDS';
    tierClass = 'tier-warn';
    footnote = '评分 1-2';
  } else if (score <= 4) {
    tier = '中度ARDS';
    tierClass = 'tier-warn';
    footnote = '评分 3-4';
  } else {
    tier = '重度ARDS';
    tierClass = 'tier-danger';
    footnote = '评分 5-6';
  }

  return { value: score, unit: '分', tier, tierClass, footnote };
}

export function calculateMurray(pao2: number, fio2: number, fio2Mode: string, peep: number, compliance: number, cxrQuad: number): CalcResult {
  const fio2Val = fio2Mode === 'pct' ? fio2 / 100 : fio2;
  if (pao2 <= 0 || fio2Val <= 0 || peep <= 0) {
    return { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
  }

  const pf = pao2 / fio2Val;
  const parts: string[] = [];
  let total = 0;
  let count = 0;

  let pfPts = 0;
  if (pf < 100) pfPts = 4; else if (pf < 200) pfPts = 3; else if (pf < 300) pfPts = 2; else if (pf < 400) pfPts = 1;
  total += pfPts; count++;
  parts.push(`P/F ${pf.toFixed(0)}→${pfPts}`);

  let peepPts = 0;
  if (peep >= 15) peepPts = 4; else if (peep >= 10) peepPts = 3; else if (peep >= 8) peepPts = 2; else if (peep >= 5) peepPts = 1;
  total += peepPts; count++;
  parts.push(`PEEP ${peep}→${peepPts}`);

  if (compliance > 0) {
    let cPts = 0;
    if (compliance < 20) cPts = 4; else if (compliance < 30) cPts = 3; else if (compliance < 40) cPts = 2; else if (compliance < 80) cPts = 1;
    total += cPts; count++;
    parts.push(`顺应性 ${compliance}→${cPts}`);
  }

  if (cxrQuad >= 0) {
    let xPts = 0;
    if (cxrQuad >= 4) xPts = 4; else if (cxrQuad >= 3) xPts = 3; else if (cxrQuad >= 2) xPts = 2; else if (cxrQuad >= 1) xPts = 1;
    total += xPts; count++;
    parts.push(`胸片象限 ${cxrQuad}→${xPts}`);
  }

  const avg = total / count;
  let tier: string;
  let tierClass: string;
  let footnote: string;

  if (avg === 0) {
    tier = '无肺损伤';
    tierClass = 'tier-ok';
    footnote = 'Murray 评分均值 0，无肺损伤。';
  } else if (avg < 1.5) {
    tier = '轻度肺损伤';
    tierClass = 'tier-warn';
    footnote = `Murray 均值 ${avg.toFixed(2)}，轻度肺损伤（0.1-2.4）。`;
  } else if (avg < 2.5) {
    tier = 'ARDS';
    tierClass = 'tier-danger';
    footnote = `Murray 均值 ${avg.toFixed(2)}，符合 ARDS（≥2.5）。`;
  } else {
    tier = '重度 ARDS';
    tierClass = 'tier-danger';
    footnote = `Murray 均值 ${avg.toFixed(2)}，重度 ARDS（≥2.5），评分越高损伤越重。`;
  }

  footnote += `\n\n${parts.join('，')} → 总分 ${total}/${count}×4 = 均值 ${avg.toFixed(2)}`;
  footnote += '\nMurray 肺损伤评分（LIS）：P/F、PEEP、顺应性、胸片象限各 0-4 分，取均值；≥2.5 为 ARDS，0.1-2.4 为轻度肺损伤，0 为无肺损伤。';

  return { value: Math.round(avg * 100) / 100, unit: '', tier, tierClass, footnote };
}
