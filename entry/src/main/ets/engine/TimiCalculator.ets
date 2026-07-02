import { CalcResult } from './CalcEngine';

export function calculateTimiStemi(ageCat: number, dmHtnAngina: boolean, sbpLt100: boolean, hrGt100: boolean, killip: number, weightLt67: boolean, anteriorLbbb: boolean, timeToTreat: boolean): CalcResult {
  let score = 0;
  if (ageCat >= 3) score += 3;
  else if (ageCat >= 2) score += 2;
  else if (ageCat >= 1) score += 1;

  if (dmHtnAngina) score += 1;
  if (sbpLt100) score += 3;
  if (hrGt100) score += 2;
  if (killip >= 2) score += 2;
  if (weightLt67) score += 1;
  if (anteriorLbbb) score += 1;
  if (timeToTreat) score += 1;

  let tier: string;
  let tierClass: string;
  let footnote: string;

  if (score <= 3) {
    tier = '低风险';
    tierClass = 'tier-ok';
    footnote = '30天死亡率约0.8%';
  } else if (score <= 5) {
    tier = '中风险';
    tierClass = 'tier-warn';
    footnote = '30天死亡率约2.2%';
  } else if (score <= 7) {
    tier = '高风险';
    tierClass = 'tier-warn';
    footnote = '30天死亡率约5.0%';
  } else {
    tier = '极高风险';
    tierClass = 'tier-danger';
    footnote = '30天死亡率约11.0%';
  }

  return { value: score, unit: '/ 14', tier, tierClass, footnote };
}

export function calculateTimiNstemi(ageGte65: boolean, riskFactorsGte3: boolean, knownCAD: boolean, priorAspirin: boolean, severeAngina: boolean, stDevGte05: boolean, biomarkerElevated: boolean): CalcResult {
  let score = 0;
  if (ageGte65) score += 1;
  if (riskFactorsGte3) score += 1;
  if (knownCAD) score += 1;
  if (priorAspirin) score += 1;
  if (severeAngina) score += 1;
  if (stDevGte05) score += 1;
  if (biomarkerElevated) score += 1;

  let tier: string;
  let tierClass: string;
  let footnote: string;

  if (score <= 1) {
    tier = '低风险';
    tierClass = 'tier-ok';
    footnote = '0-1 分 14天死亡/MI风险约4.7%。';
  } else if (score <= 4) {
    tier = '中风险';
    tierClass = 'tier-warn';
    footnote = '2-4 分 14天死亡/MI风险约8-20%。';
  } else {
    tier = '高风险';
    tierClass = 'tier-danger';
    footnote = '5-7 分 14天死亡/MI风险约26-41%。';
  }

  return { value: score, unit: '/ 7', tier, tierClass, footnote };
}
