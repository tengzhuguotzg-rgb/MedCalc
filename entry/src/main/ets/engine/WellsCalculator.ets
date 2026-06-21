import { CalcResult } from './CalcEngine';

export function calculateWells(clinical: boolean, hr: boolean, surgery: boolean, hemoptysis: boolean, cancer: boolean): CalcResult {
  let score = 0;
  if (clinical) score += 3;
  if (hr) score += 1.5;
  if (surgery) score += 1.5;
  if (hemoptysis) score += 1;
  if (cancer) score += 1;

  let tier: string;
  let tierClass: string;
  let footnote: string;

  if (score < 2) {
    tier = '低概率';
    tierClass = 'tier-ok';
    footnote = '肺栓塞可能性约1-3%';
  } else if (score <= 6) {
    tier = '中概率';
    tierClass = 'tier-warn';
    footnote = '肺栓塞可能性约17-37%';
  } else {
    tier = '高概率';
    tierClass = 'tier-danger';
    footnote = '肺栓塞可能性约53-90%';
  }

  return { value: score, unit: '分', tier, tierClass, footnote };
}
