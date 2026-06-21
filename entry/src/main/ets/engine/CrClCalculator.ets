import { CalcResult, formatValue, getTierClass } from './CalcEngine';

export function calculateCrCl(sex: string, age: number, weight: number, creatinine: number): CalcResult {
  if (age <= 0 || weight <= 0 || creatinine <= 0) {
    return {
      value: null,
      unit: 'mL/min',
      tier: '请填写必填项',
      tierClass: 'tier-info',
      footnote: ''
    };
  }

  const crMg = creatinine / 88.4;
  let crcl = ((140 - age) * weight) / (72 * crMg);
  if (sex === 'female') {
    crcl *= 0.85;
  }

  let tier: string;
  let footnote: string;

  if (crcl >= 90) {
    tier = '正常';
    footnote = '≥ 90 肾功能正常, 多数药物无需调整剂量。';
  } else if (crcl >= 60) {
    tier = '轻度下降';
    footnote = '60-89 CKD G2 期, 大多数药物无需调整, 注意监测。';
  } else if (crcl >= 30) {
    tier = '中度下降';
    footnote = '30-59 CKD G3 期, 经肾药物需调整剂量。';
  } else if (crcl >= 15) {
    tier = '重度下降';
    footnote = '15-29 CKD G4 期, 多数药物需减量 50%+ 或停用。';
  } else {
    tier = '肾衰竭';
    footnote = '< 15 CKD G5 期, 评估 RRT; 剂量调整需个体化。';
  }

  return {
    value: crcl,
    unit: 'mL/min',
    tier: tier,
    tierClass: getTierClass(tier),
    footnote: footnote
  };
}
