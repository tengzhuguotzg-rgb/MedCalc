import { CalcResult } from './CalcEngine';

export function calculateIch(vol: number, location: number, ivh: boolean, age: number): CalcResult {
  if (vol <= 0 || location < 0 || age <= 0) {
    return { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
  }

  let score = 0;
  if (vol > 30) score += 1;
  if (location === 1) score += 1;
  if (ivh) score += 1;
  if (age >= 80) score += 1;

  let tier: string;
  let tierClass: string;
  let footnote: string;

  if (score === 0) {
    tier = '低风险 (0分)';
    tierClass = 'tier-ok';
    footnote = '30天死亡率约0%';
  } else if (score === 1) {
    tier = '中风险 (1分)';
    tierClass = 'tier-warn';
    footnote = '30天死亡率约13%';
  } else if (score === 2) {
    tier = '高风险 (2分)';
    tierClass = 'tier-warn';
    footnote = '30天死亡率约26%';
  } else if (score === 3) {
    tier = '极高风险 (3分)';
    tierClass = 'tier-danger';
    footnote = '30天死亡率约40%';
  } else {
    tier = '最高风险 (4分)';
    tierClass = 'tier-danger';
    footnote = '30天死亡率约97%';
  }

  return { value: score, unit: '分', tier, tierClass, footnote };
}
