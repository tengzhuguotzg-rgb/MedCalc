import { CalcResult } from './CalcEngine';

export function calculateMarshall(pao2: number, fio2: number, peep: number): CalcResult {
  if (pao2 <= 0 || fio2 <= 0) {
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
