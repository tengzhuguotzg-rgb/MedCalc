import { CalcResult, getTierClass } from './CalcEngine';

export function calculateGfr(sex: string, age: number, creatinine: number): CalcResult {
  if (age <= 0 || creatinine <= 0) {
    return {
      value: null,
      unit: 'mL/min/1.73m²',
      tier: '请填写必填项',
      tierClass: 'tier-info',
      footnote: ''
    };
  }

  const crMg = creatinine / 88.4;
  const isFemale = sex === 'female';
  const kappa = isFemale ? 0.7 : 0.9;
  const alpha = isFemale ? -0.241 : -0.302;
  const factor = isFemale ? 1.012 : 1.0;
  const scrK = crMg / kappa;
  const termMin = Math.pow(Math.min(scrK, 1), alpha);
  const termMax = Math.pow(Math.max(scrK, 1), -1.200);
  const egfr = 142 * termMin * termMax * Math.pow(0.9938, age) * factor;

  let tier: string;
  let footnote: string;

  if (egfr >= 90) {
    tier = 'G1 正常或偏高';
    footnote = '≥ 90 正常, 无需处理。';
  } else if (egfr >= 60) {
    tier = 'G2 轻度下降';
    footnote = '60-89 轻度下降, 评估有无蛋白尿、高血压。';
  } else if (egfr >= 45) {
    tier = 'G3a 轻-中度';
    footnote = '45-59 监测肾功能 + 蛋白尿, 控制血压。';
  } else if (egfr >= 30) {
    tier = 'G3b 中-重度';
    footnote = '30-44 建议肾科会诊, 评估 CKD 病因。';
  } else if (egfr >= 15) {
    tier = 'G4 重度';
    footnote = '15-29 必须肾科会诊, 准备 RRT 通路。';
  } else {
    tier = 'G5 肾衰竭';
    footnote = '< 15 肾衰竭, 启动 RRT。';
  }

  return {
    value: egfr,
    unit: 'mL/min/1.73m²',
    tier: tier,
    tierClass: getTierClass(tier),
    footnote: footnote
  };
}
