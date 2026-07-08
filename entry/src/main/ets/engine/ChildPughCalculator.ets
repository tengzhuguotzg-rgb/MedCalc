import { CalcResult } from './CalcEngine';

export function calculateChildPugh(bilirubin: number, bilirubinUnit: string, albumin: number, albUnit: string, inr: number, ascites: number, encephalopathy: number): CalcResult {
  if (bilirubin <= 0 || albumin <= 0 || inr <= 0) {
    return { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
  }

  const bilUmol = bilirubinUnit === 'mgdl' ? bilirubin * 17.1 : bilirubin;
  const albGl = albUnit === 'gdl' ? albumin * 10 : albumin;

  let score = 0;

  if (bilUmol < 34) score += 1;
  else if (bilUmol < 51) score += 2;
  else score += 3;

  if (albGl > 35) score += 1;
  else if (albGl > 28) score += 2;
  else score += 3;

  if (inr < 1.7) score += 1;
  else if (inr < 2.3) score += 2;
  else score += 3;

  score += ascites;
  score += encephalopathy;

  let tier: string;
  let tierClass: string;
  let footnote: string;

  if (score <= 6) {
    tier = 'A级 (5-6分)';
    tierClass = 'tier-ok';
    footnote = '1年生存率约100%，围手术期死亡率约0%';
  } else if (score <= 9) {
    tier = 'B级 (7-9分)';
    tierClass = 'tier-warn';
    footnote = '1年生存率约80%，围手术期死亡率约10%';
  } else {
    tier = 'C级 (10-15分)';
    tierClass = 'tier-danger';
    footnote = '1年生存率约45%，围手术期死亡率约30%';
  }

  return { value: score, unit: '分', tier, tierClass, footnote };
}
