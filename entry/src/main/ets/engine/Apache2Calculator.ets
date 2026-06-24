import { CalcResult } from './CalcEngine';

export function calculateApache2(
  temp: number,
  sbp: number,
  dbp: number,
  hr: number,
  rr: number,
  fio2: number,
  fio2Mode: string,
  pao2: number,
  paco2: number | null,
  ph: number | null,
  hco3: number | null,
  na: number,
  k: number,
  cr: number,
  crUnit: string,
  arf: boolean,
  hct: number,
  wbc: number,
  gcs: number,
  age: number,
  chronic: string
): CalcResult {
  const map = dbp + (sbp - dbp) / 3;
  const fio2dec = fio2Mode === 'dec' ? fio2 : fio2 / 100;

  let tScore = 0;
  if (temp >= 41) tScore = 4;
  else if (temp >= 39) tScore = 3;
  else if (temp >= 38.5) tScore = 1;
  else if (temp >= 36) tScore = 0;
  else if (temp >= 34) tScore = 1;
  else if (temp >= 32) tScore = 2;
  else if (temp >= 30) tScore = 3;
  else tScore = 4;

  let mScore = 0;
  if (map >= 160) mScore = 4;
  else if (map >= 130) mScore = 3;
  else if (map >= 110) mScore = 2;
  else if (map >= 70) mScore = 0;
  else if (map >= 50) mScore = 2;
  else mScore = 4;

  let hScore = 0;
  if (hr >= 180) hScore = 4;
  else if (hr >= 140) hScore = 3;
  else if (hr >= 110) hScore = 2;
  else if (hr >= 70) hScore = 0;
  else if (hr >= 55) hScore = 2;
  else if (hr >= 40) hScore = 3;
  else hScore = 4;

  let rScore = 0;
  if (rr >= 50) rScore = 4;
  else if (rr >= 35) rScore = 3;
  else if (rr >= 25) rScore = 1;
  else if (rr >= 12) rScore = 0;
  else if (rr >= 10) rScore = 1;
  else if (rr >= 6) rScore = 2;
  else rScore = 4;

  const paCO2 = paco2 !== null ? paco2 : 40;
  let oScore = 0;
  let oLabel = '';
  if (fio2dec >= 0.5) {
    const aado2 = (fio2dec * 713 - paCO2 / 0.8) - pao2;
    oLabel = `A-aDO₂ ${aado2.toFixed(0)}`;
    if (aado2 >= 500) oScore = 4;
    else if (aado2 >= 350) oScore = 3;
    else if (aado2 >= 200) oScore = 1;
    else oScore = 0;
  } else {
    oLabel = `PaO₂ ${pao2}`;
    if (pao2 < 55) oScore = 4;
    else if (pao2 < 60) oScore = 3;
    else if (pao2 < 70) oScore = 1;
    else oScore = 0;
  }

  let phScore = 0;
  let phUsed: number | null = null;
  if (ph !== null) {
    phUsed = ph;
    if (ph >= 7.7) phScore = 4;
    else if (ph >= 7.6) phScore = 3;
    else if (ph >= 7.5) phScore = 1;
    else if (ph >= 7.33) phScore = 0;
    else if (ph >= 7.25) phScore = 2;
    else if (ph >= 7.15) phScore = 3;
    else phScore = 4;
  } else if (hco3 !== null) {
    phUsed = hco3;
    if (hco3 >= 52) phScore = 4;
    else if (hco3 >= 41) phScore = 3;
    else if (hco3 >= 32) phScore = 1;
    else if (hco3 >= 22) phScore = 0;
    else if (hco3 >= 18) phScore = 2;
    else if (hco3 >= 15) phScore = 3;
    else phScore = 4;
  }

  let naScore = 0;
  if (na >= 180) naScore = 4;
  else if (na >= 160) naScore = 3;
  else if (na >= 155) naScore = 2;
  else if (na >= 150) naScore = 1;
  else if (na >= 130) naScore = 0;
  else if (na >= 120) naScore = 2;
  else if (na >= 111) naScore = 3;
  else naScore = 4;

  let kScore = 0;
  if (k >= 7) kScore = 4;
  else if (k >= 6) kScore = 3;
  else if (k >= 5.5) kScore = 1;
  else if (k >= 3.5) kScore = 0;
  else if (k >= 3) kScore = 1;
  else if (k >= 2.5) kScore = 2;
  else kScore = 4;

  const crMg = crUnit === 'umol' ? cr / 88.4 : cr;
  let cScore = 0;
  if (crMg >= 3.5) cScore = 4;
  else if (crMg >= 2.0) cScore = 3;
  else if (crMg >= 1.5) cScore = 2;
  else if (crMg >= 0.6) cScore = 0;
  else cScore = 2;
  if (arf) cScore *= 2;

  let hctScore = 0;
  if (hct >= 60) hctScore = 4;
  else if (hct >= 50) hctScore = 2;
  else if (hct >= 46) hctScore = 1;
  else if (hct >= 30) hctScore = 0;
  else if (hct >= 20) hctScore = 2;
  else hctScore = 4;

  let wScore = 0;
  if (wbc >= 40) wScore = 4;
  else if (wbc >= 20) wScore = 2;
  else if (wbc >= 15) wScore = 1;
  else if (wbc >= 3) wScore = 0;
  else if (wbc >= 1) wScore = 2;
  else wScore = 4;

  const gcsScore = 15 - gcs;

  let ageScore = 0;
  if (age >= 75) ageScore = 6;
  else if (age >= 65) ageScore = 5;
  else if (age >= 55) ageScore = 3;
  else if (age >= 45) ageScore = 2;

  let chrScore = 0;
  if (chronic === 'nonop') chrScore = 5;
  else if (chronic === 'elective') chrScore = 2;

  const physTotal = tScore + mScore + hScore + rScore + oScore + phScore + naScore + kScore + cScore + hctScore + wScore + gcsScore;
  const total = physTotal + ageScore + chrScore;

  let tier: string;
  let tierClass: string;
  let footnote: string;

  if (total <= 4) {
    tier = '轻度';
    tierClass = 'tier-ok';
    footnote = '0-4 预测死亡率 ≈ 4%';
  } else if (total <= 9) {
    tier = '中度';
    tierClass = 'tier-warn';
    footnote = '5-9 预测死亡率 ≈ 8%';
  } else if (total <= 14) {
    tier = '中重度';
    tierClass = 'tier-warn';
    footnote = '10-14 预测死亡率 ≈ 15%';
  } else if (total <= 19) {
    tier = '重度';
    tierClass = 'tier-danger';
    footnote = '15-19 预测死亡率 ≈ 25%';
  } else if (total <= 24) {
    tier = '极重度';
    tierClass = 'tier-danger';
    footnote = '20-24 预测死亡率 ≈ 40%';
  } else if (total <= 29) {
    tier = '危重';
    tierClass = 'tier-danger';
    footnote = '25-29 预测死亡率 ≈ 55%';
  } else if (total <= 34) {
    tier = '濒危';
    tierClass = 'tier-danger';
    footnote = '30-34 预测死亡率 ≈ 75%';
  } else {
    tier = '极危';
    tierClass = 'tier-danger';
    footnote = '> 34 预测死亡率 ≈ 85%+';
  }

  const detail = `生理评分: ${physTotal}\n年龄评分: ${ageScore}\n慢性健康评分: ${chrScore}\n体温: ${tScore} | MAP: ${mScore} | 心率: ${hScore} | 呼吸: ${rScore}\n氧合: ${oLabel} (${oScore}) | pH/HCO₃: ${phUsed !== null ? phUsed.toFixed(2) : '—'} (${phScore})\nNa⁺: ${naScore} | K⁺: ${kScore} | Cr: ${cScore}${arf ? ' (急性肾衰×2)' : ''}\nHCT: ${hctScore} | WBC: ${wScore} | GCS: ${gcsScore}`;

  return {
    value: total,
    unit: '/ 71',
    tier: tier,
    tierClass: tierClass,
    footnote: footnote + '\n\n' + detail
  };
}
