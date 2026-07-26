import { CalcResult } from './CalcEngine';

/**
 * Wells 肺栓塞评分（Wells PS, et al. Thromb Haemost 2000;83:416-420）
 * 7 项满分 12.5：
 *   DVT 临床体征 +3；PE 可能性≥其他诊断 +3；HR>100 +1.5；
 *   制动≥3天或4周内手术 +1.5；既往 DVT/PE +1.5；咯血 +1；活动性肿瘤 +1
 */
export function calculateWells(
  clinical: boolean, peLikely: boolean, hr: boolean,
  surgery: boolean, prevVte: boolean, hemoptysis: boolean, cancer: boolean
): CalcResult {
  let score = 0;
  if (clinical) score += 3;
  if (peLikely) score += 3;
  if (hr) score += 1.5;
  if (surgery) score += 1.5;
  if (prevVte) score += 1.5;
  if (hemoptysis) score += 1;
  if (cancer) score += 1;

  let tier: string;
  let tierClass: string;
  let footnote: string;

  if (score < 2) {
    tier = '低概率';
    tierClass = 'tier-ok';
    footnote = 'PE 可能性低（<2 分，约 3.6%）；两分法：≤4 分为"PE 不太可能"';
  } else if (score <= 6) {
    tier = '中概率';
    tierClass = 'tier-warn';
    footnote = 'PE 可能性中等（2-6 分，约 20.5%）；两分法：≤4 分为"PE 不太可能"';
  } else {
    tier = '高概率';
    tierClass = 'tier-danger';
    footnote = 'PE 可能性高（>6 分，约 66.7%）；两分法：>4 分为"PE 可能"';
  }

  footnote += '\n本实现为 MDCalc 七分项原版 Wells PE（Wells 2000/2001，最高 12.5 分），非简化/改良版。';
  return { value: score, unit: '分', tier, tierClass, footnote };
}
