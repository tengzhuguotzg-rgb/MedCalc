import { CalcResult, getTierClass } from './CalcEngine';

export function calculateGcs(eye: number, verbal: number, motor: number): CalcResult {
  if (eye < 1 || verbal < 1 || motor < 1) {
    return {
      value: null,
      unit: '',
      tier: '请填写必填项',
      tierClass: 'tier-info',
      footnote: ''
    };
  }

  const total = eye + verbal + motor;

  let tier: string;
  let footnote: string;

  if (total >= 13) {
    tier = '轻度';
    footnote = '13-15 轻度意识障碍, 对应 E3V4M5 及以上。';
  } else if (total >= 9) {
    tier = '中度';
    footnote = '9-12 中度意识障碍, 需密切监测。';
  } else if (total >= 3) {
    tier = '重度';
    footnote = '3-8 重度意识障碍, ≤8 需考虑气道保护, 评估插管指征。';
  } else {
    tier = '数据异常';
    footnote = 'GCS 总分应在 3-15 之间。';
  }

  return {
    value: total,
    unit: '',
    tier: tier,
    tierClass: getTierClass(tier),
    footnote: footnote
  };
}
