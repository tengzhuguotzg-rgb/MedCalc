import { CalcResult, getTierClass } from './CalcEngine';

export function calculateClifC(bilirubin: number, bilUnit: string, inr: number, hepaticEnceph: number, map: number, vasoNorepi: boolean, vasoDopamine: boolean, vasoEpi: boolean, creatinine: number, crUnit: string, rr: number, spo2: number, fio2: number, fio2Mode: string): CalcResult {
  const bilUmol = bilUnit === 'mgdl' ? bilirubin * 17.1 : bilirubin;
  const crMg = crUnit === 'umol' ? creatinine / 88.4 : creatinine;
  const fio2Val = fio2Mode === 'pct' ? fio2 / 100 : fio2;

  let hepFail = 0;
  if (bilUmol >= 204 && inr >= 1.5) hepFail = 3;
  else if (bilUmol >= 102 || inr >= 1.5 || hepaticEnceph >= 2) hepFail = 2;
  else if (bilUmol >= 34 || inr >= 1.2 || hepaticEnceph === 1) hepFail = 1;

  let circFail = 0;
  if (vasoNorepi || vasoDopamine || vasoEpi) circFail = 3;
  else if (map < 70) circFail = 2;
  else if (map >= 70 && map < 80) circFail = 1;

  let renFail = 0;
  if (crMg >= 2.0) renFail = 3;
  else if (crMg >= 1.5) renFail = 2;
  else if (crMg >= 1.2) renFail = 1;

  let respFail = 0;
  const pf = fio2Val > 0 ? spo2 / fio2Val : 999;
  if (rr > 30 && pf <= 200) respFail = 3;
  else if (pf <= 315) respFail = 2;
  else if (pf <= 400 || rr > 20) respFail = 1;

  const organFails = [hepFail, circFail, renFail, respFail].filter(v => v >= 2).length;

  let aclfGrade: string;
  if (organFails === 0) aclfGrade = '无ACLF';
  else if (organFails === 1) aclfGrade = 'ACLF-1';
  else if (organFails === 2) aclfGrade = 'ACLF-2';
  else aclfGrade = 'ACLF-3';

  const clifScore = hepFail + circFail + renFail + respFail;

  let tier: string;
  let footnote: string;

  if (aclfGrade === '无ACLF') {
    tier = '无ACLF';
    footnote = '28天死亡率约5%，90天死亡率约12%';
  } else if (aclfGrade === 'ACLF-1') {
    tier = 'ACLF-1';
    footnote = '28天死亡率约22%，90天死亡率约28%';
  } else if (aclfGrade === 'ACLF-2') {
    tier = 'ACLF-2';
    footnote = '28天死亡率约32%，90天死亡率约46%';
  } else {
    tier = 'ACLF-3';
    footnote = '28天死亡率约77%，90天死亡率约83%';
  }

  const detail = `肝衰竭: ${hepFail} | 循环衰竭: ${circFail} | 肾衰竭: ${renFail} | 呼吸衰竭: ${respFail}\n器官衰竭数: ${organFails}`;

  return { value: clifScore, unit: '分', tier, tierClass: getTierClass(tier), footnote: footnote + '\n\n' + detail };
}
