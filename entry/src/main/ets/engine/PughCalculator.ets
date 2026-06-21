import { CalcResult, getTierClass } from './CalcEngine';

export function calculatePugh(
  bil: number,
  bilUnit: string,
  alb: number,
  pt: number,
  ptMode: string,
  ascites: string,
  encephal: string
): CalcResult {
  const bilUmol = bilUnit === 'mgdl' ? bil * 17.1 : bil;

  let bilScore = 0;
  let bilStr = '';
  if (bilUmol < 34) {
    bilScore = 1;
    bilStr = '< 34';
  } else if (bilUmol <= 50) {
    bilScore = 2;
    bilStr = '34-50';
  } else {
    bilScore = 3;
    bilStr = '> 50';
  }

  let albScore = 0;
  let albStr = '';
  if (alb > 35) {
    albScore = 1;
    albStr = '> 35';
  } else if (alb >= 28) {
    albScore = 2;
    albStr = '28-35';
  } else {
    albScore = 3;
    albStr = '< 28';
  }

  let ptScore = 0;
  let ptStr = '';
  if (ptMode === 'sec') {
    if (pt < 4) {
      ptScore = 1;
      ptStr = '< 4';
    } else if (pt <= 6) {
      ptScore = 2;
      ptStr = '4-6';
    } else {
      ptScore = 3;
      ptStr = '> 6';
    }
  } else {
    if (pt < 1.7) {
      ptScore = 1;
      ptStr = '< 1.7';
    } else if (pt <= 2.3) {
      ptScore = 2;
      ptStr = '1.7-2.3';
    } else {
      ptScore = 3;
      ptStr = '> 2.3';
    }
  }

  let ascScore = 0;
  let ascStr = '';
  if (ascites === 'none') {
    ascScore = 1;
    ascStr = '无';
  } else if (ascites === 'mild') {
    ascScore = 2;
    ascStr = '轻-中度';
  } else {
    ascScore = 3;
    ascStr = '重度';
  }

  let encScore = 0;
  let encStr = '';
  if (encephal === 'none') {
    encScore = 1;
    encStr = '无';
  } else if (encephal === 'grade12') {
    encScore = 2;
    encStr = 'I-II 级';
  } else {
    encScore = 3;
    encStr = 'III-IV 级';
  }

  const total = bilScore + albScore + ptScore + ascScore + encScore;

  let grade: string;
  let tier: string;
  let footnote: string;

  if (total <= 6) {
    grade = 'A';
    tier = 'Child A (代偿期)';
    footnote = '5-6 分 · Child A (代偿期) · 肝功能储备良好。1 年生存率 ~100%, 手术风险低。';
  } else if (total <= 9) {
    grade = 'B';
    tier = 'Child B (显著代偿不全)';
    footnote = '7-9 分 · Child B (显著代偿不全) · 1 年生存率 ~80%, 2 年 ~60%。择期手术需谨慎评估。';
  } else {
    grade = 'C';
    tier = 'Child C (失代偿期)';
    footnote = '10-15 分 · Child C (失代偿期) · 1 年生存率 ~45%, 2 年 ~35%。肝移植指征, 手术风险极高。';
  }

  const detail = `胆红素: ${bilStr} µmol/L (${bilScore}分)\n白蛋白: ${albStr} g/L (${albScore}分)\n${ptMode === 'sec' ? 'PT延长' : 'INR'}: ${ptStr} (${ptScore}分)\n腹水: ${ascStr} (${ascScore}分)\n肝性脑病: ${encStr} (${encScore}分)`;

  return {
    value: total,
    unit: '/ 15',
    tier: tier,
    tierClass: getTierClass(tier),
    footnote: footnote + '\n\n' + detail
  };
}
