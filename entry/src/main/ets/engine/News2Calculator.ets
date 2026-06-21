import { CalcResult, getTierClass } from './CalcEngine';

export function calculateNews2(
  rr: number,
  spo2: number,
  o2supplement: string,
  temp: number,
  sbp: number,
  hr: number,
  consciousness: string
): CalcResult {
  if (rr <= 0 || spo2 <= 0 || temp <= 0 || sbp <= 0 || hr <= 0) {
    return {
      value: null,
      unit: '',
      tier: '请填写必填项',
      tierClass: 'tier-info',
      footnote: ''
    };
  }

  let total = 0;

  if (rr <= 8) total += 3;
  else if (rr >= 25) total += 3;
  else if (rr >= 21) total += 2;
  else if (rr >= 12) total += 0;
  else total += 1;

  if (o2supplement === 'yes') {
    if (spo2 <= 83) total += 3;
    else if (spo2 <= 85) total += 2;
    else if (spo2 <= 87) total += 1;
    else total += 0;
  } else {
    if (spo2 <= 91) total += 3;
    else if (spo2 <= 93) total += 2;
    else if (spo2 <= 95) total += 1;
    else total += 0;
  }

  if (temp <= 35.0) total += 3;
  else if (temp >= 39.0) total += 2;
  else if (temp >= 38.1) total += 1;
  else total += 0;

  if (sbp <= 90) total += 3;
  else if (sbp <= 100) total += 2;
  else if (sbp <= 110) total += 1;
  else total += 0;

  if (hr <= 40) total += 3;
  else if (hr >= 131) total += 3;
  else if (hr >= 111) total += 2;
  else if (hr >= 91) total += 0;
  else total += 1;

  if (consciousness !== 'A') total += 3;

  let tier: string;
  let footnote: string;

  if (total >= 12) {
    tier = '高风险';
    footnote = '≥12 临床紧急风险, 需立即评估, 考虑 ICU 转入。';
  } else if (total >= 7) {
    tier = '中高风险';
    footnote = '7-11 中高风险, 需紧急医疗评估, 监测频率提高。';
  } else if (total >= 5) {
    tier = '中风险';
    footnote = '5-6 中风险, 需住院或密切监测。';
  } else if (total >= 1) {
    tier = '低风险';
    footnote = '1-4 低风险, 可在病房监测。';
  } else {
    tier = '正常';
    footnote = '0 分各项指标正常。';
  }

  return {
    value: total,
    unit: '',
    tier: tier,
    tierClass: getTierClass(tier),
    footnote: footnote
  };
}
