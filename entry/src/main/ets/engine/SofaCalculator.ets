import { CalcResult, getTierClass } from './CalcEngine';

export function calculateSofa(
  pao2: number,
  fio2: number,
  fio2Mode: string,
  platelet: number,
  bilirubin: number,
  bilirubinUnit: string,
  map: number,
  vaso: string,
  gcs: number,
  creatinine: number,
  creatinineUnit: string,
  urineOutput: number
): CalcResult {
  const fio2Value = fio2Mode === 'pct' ? fio2 / 100 : fio2;

  if (pao2 <= 0 || fio2Value <= 0) {
    return {
      value: null,
      unit: '',
      tier: '请填写必填项',
      tierClass: 'tier-info',
      footnote: ''
    };
  }

  let total = 0;

  const pfRatio = pao2 / fio2Value;
  if (pfRatio < 100) total += 4;
  else if (pfRatio < 200) total += 3;
  else if (pfRatio < 300) total += 2;
  else if (pfRatio < 400) total += 1;

  if (platelet < 20) total += 4;
  else if (platelet < 50) total += 3;
  else if (platelet < 100) total += 2;
  else if (platelet < 150) total += 1;

  const bilMg = bilirubinUnit === 'mgdl' ? bilirubin : bilirubin / 17.1;
  if (bilMg >= 12.0) total += 4;
  else if (bilMg >= 6.0) total += 3;
  else if (bilMg >= 2.0) total += 2;
  else if (bilMg >= 1.2) total += 1;

  if (vaso === 'dopa15') total += 4;
  else if (vaso === 'noreHi') total += 4;
  else if (vaso === 'dopaMid') total += 3;
  else if (vaso === 'nore') total += 3;
  else if (vaso === 'dopaLo') total += 2;
  else if (map < 70) total += 1;

  if (gcs < 6) total += 4;
  else if (gcs < 10) total += 3;
  else if (gcs < 13) total += 2;
  else if (gcs < 15) total += 1;

  const crMg = creatinineUnit === 'mgdl' ? creatinine : creatinine / 88.4;
  let renalCrScore = 0;
  if (crMg >= 5.0) renalCrScore = 4;
  else if (crMg >= 3.5) renalCrScore = 3;
  else if (crMg >= 2.0) renalCrScore = 2;
  else if (crMg >= 1.2) renalCrScore = 1;

  let renalUrineScore = 0;
  if (urineOutput > 0) {
    if (urineOutput < 200) renalUrineScore = 4;
    else if (urineOutput < 500) renalUrineScore = 3;
  }

  total += Math.max(renalCrScore, renalUrineScore);

  let tier: string;
  let footnote: string;

  if (total >= 10) {
    tier = '极高危';
    footnote = '≥10 器官衰竭严重, 死亡风险 > 50%, 需ICU强化治疗。';
  } else if (total >= 6) {
    tier = '高危';
    footnote = '6-9 器官功能障碍明显, 死亡风险 15-20%, 需ICU监测。';
  } else if (total >= 2) {
    tier = '中危';
    footnote = '2-5 器官功能受损, 需密切监测。';
  } else {
    tier = '低危';
    footnote = '0-1 器官功能基本正常。';
  }

  return {
    value: total,
    unit: '',
    tier: tier,
    tierClass: getTierClass(tier),
    footnote: footnote
  };
}
