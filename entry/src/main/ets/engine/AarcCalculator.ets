import { CalcResult, getTierClass } from './CalcEngine';

export function calculateAarc(bilirubin: number, bilUnit: string, inr: number, lactate: number, hepaticEnceph: number, age: number, acKf: boolean): CalcResult {
  const bilUmol = bilUnit === 'mgdl' ? bilirubin * 17.1 : bilirubin;

  let score = 0;

  if (bilUmol >= 15) score += 3;
  else if (bilUmol >= 6) score += 2;
  else if (bilUmol >= 2) score += 1;

  if (inr >= 2.5) score += 3;
  else if (inr >= 1.5) score += 2;
  else if (inr >= 1.2) score += 1;

  if (lactate >= 5) score += 3;
  else if (lactate >= 3) score += 2;
  else if (lactate >= 2) score += 1;

  if (hepaticEnceph >= 3) score += 3;
  else if (hepaticEnceph >= 2) score += 2;
  else if (hepaticEnceph === 1) score += 1;

  if (age >= 65) score += 2;
  else if (age >= 45) score += 1;

  if (acKf) score += 2;

  let tier: string;
  let footnote: string;

  if (score <= 3) {
    tier = '低风险';
    footnote = '建议继续内科治疗，密切监测。';
  } else if (score <= 6) {
    tier = '中风险';
    footnote = '考虑评估肝移植，积极脏器支持。';
  } else if (score <= 9) {
    tier = '高风险';
    footnote = '强烈建议紧急肝移植评估。';
  } else {
    tier = '极高风险';
    footnote = '极高死亡率，需紧急肝移植或MARS/人工肝。';
  }

  return { value: score, unit: '/ 17', tier, tierClass: getTierClass(tier), footnote };
}
