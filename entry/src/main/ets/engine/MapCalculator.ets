import { CalcResult, getTierClass } from './CalcEngine';

export function calculateMap(sbp: number, dbp: number): CalcResult {
  if (sbp <= 0 || dbp <= 0) {
    return {
      value: null,
      unit: 'mmHg',
      tier: '请填写必填项',
      tierClass: 'tier-info',
      footnote: ''
    };
  }

  const map = (sbp + 2 * dbp) / 3;

  let tier: string;
  let footnote: string;

  if (map < 65) {
    tier = '低于目标';
    footnote = '< 65 器官灌注不足, 需立即复苏。SSC 2021 初始目标 65。';
  } else if (map < 75) {
    tier = '达标下界';
    footnote = '65-75 多数患者达标。慢性高血压者可能需 80-90。';
  } else if (map < 100) {
    tier = '正常';
    footnote = '75-100 正常范围。';
  } else {
    tier = '过高';
    footnote = '≥ 100 警惕高血压急症, 评估降压。';
  }

  return {
    value: map,
    unit: 'mmHg',
    tier: tier,
    tierClass: getTierClass(tier),
    footnote: footnote
  };
}
