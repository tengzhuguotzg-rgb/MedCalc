import { CalcResult } from './CalcEngine';

export function calculateFssicu(roll: number, situp: number, sit: number, standup: number, stand: number): CalcResult {
  if (roll < 0 || situp < 0 || sit < 0 || standup < 0 || stand < 0) {
    return { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
  }

  const total = roll + situp + sit + standup + stand;

  let tier: string;
  let tierClass: string;
  let footnote: string;

  if (total >= 30) {
    tier = '功能良好';
    tierClass = 'tier-ok';
    footnote = '≥ 30 功能状态良好, 可考虑转出 ICU 或普通病房。';
  } else if (total >= 20) {
    tier = '功能中等';
    tierClass = 'tier-warn';
    footnote = '20-29 功能中等, 继续每日康复治疗, 评估转出可能。';
  } else if (total >= 10) {
    tier = '功能较差';
    tierClass = 'tier-danger';
    footnote = '10-19 功能较差, 需持续康复介入, 每日评估进展。';
  } else {
    tier = '功能极差';
    tierClass = 'tier-danger';
    footnote = '< 10 功能极差, 卧床/依赖状态, 建议康复科会诊, 被动+主动活动。';
  }

  const labels = ['无法', '完全帮助', '最大帮助', '中度帮助', '最小帮助', '监护', '独立(需辅)', '完全独立'];
  const detail = `\n\n翻身: ${roll} (${labels[roll]})\n卧→坐: ${situp} (${labels[situp]})\n坐位平衡: ${sit} (${labels[sit]})\n坐→站: ${standup} (${labels[standup]})\n站立平衡: ${stand} (${labels[stand]})`;

  return { value: total, unit: '/ 35', tier, tierClass, footnote: footnote + detail };
}
