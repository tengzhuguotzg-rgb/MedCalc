import { CalcResult } from './CalcEngine';

export function calculateClifC(
  bilirubin: number, bilUnit: string,
  creatinine: number, crUnit: string,
  inr: number, hepaticEnceph: number,
  map: number, vaso: string,
  pao2: number, fio2: number, fio2Mode: string,
  age: number, wbc: number
): CalcResult {
  if (bilirubin <= 0 || creatinine <= 0 || inr <= 0 || hepaticEnceph < 0 || map <= 0 || vaso === '' || pao2 <= 0 || fio2 <= 0 || age <= 0 || wbc <= 0) {
    return { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
  }

  const bilMg = bilUnit === 'umol' ? bilirubin / 17.1 : bilirubin;
  const crMg = crUnit === 'umol' ? creatinine / 88.4 : creatinine;
  const fio2Val = fio2Mode === 'pct' ? fio2 / 100 : fio2;
  const pf = pao2 / fio2Val;

  // CLIF-OF 每器官 1-3 分（Jalan 2014 / MDCalc）
  let bScore = 1;
  if (bilMg >= 12) bScore = 3;
  else if (bilMg >= 6) bScore = 2;

  let cScore = 1;
  if (crMg >= 3.5) cScore = 3;
  else if (crMg >= 2.0) cScore = 2;

  // UI 编码：0=无, 1=I-II, 2=III-IV → 1/2/3 分
  const hScore = hepaticEnceph + 1;

  let iScore = 1;
  if (inr >= 2.5) iScore = 3;
  else if (inr >= 2.0) iScore = 2;

  let vScore = 1;
  if (vaso === 'low' || vaso === 'high') vScore = 3;
  else if (map < 70) vScore = 2;

  let rScore = 1;
  if (pf <= 200) rScore = 3;
  else if (pf <= 300) rScore = 2;

  const clifOf = bScore + cScore + hScore + iScore + vScore + rScore;
  const score = 10 * (0.33 * clifOf + 0.04 * age + 0.63 * Math.log(wbc) - 2);
  const scoreRounded = Math.round(score * 10) / 10;

  let tier: string;
  let tierClass: string;
  let footnote: string;

  if (scoreRounded <= 30) {
    tier = '低风险';
    tierClass = 'tier-ok';
    footnote = '≤ 30  28天死亡率 ~5%, 90天 ~10%。';
  } else if (scoreRounded <= 40) {
    tier = '中风险';
    tierClass = 'tier-warn';
    footnote = '31-40  28天死亡率 ~15%, 90天 ~30%。';
  } else if (scoreRounded <= 50) {
    tier = '高风险';
    tierClass = 'tier-danger';
    footnote = '41-50  28天死亡率 ~35%, 90天 ~55%。';
  } else if (scoreRounded <= 60) {
    tier = '极高风险';
    tierClass = 'tier-danger';
    footnote = '51-60  28天死亡率 ~60%, 90天 ~80%。';
  } else {
    tier = '濒危';
    tierClass = 'tier-danger';
    footnote = '> 60  28天死亡率 > 80%, 90天 > 90%。';
  }

  const heLabel = hepaticEnceph === 0 ? '无' : hepaticEnceph === 1 ? 'I-II' : 'III-IV';
  const detail = `\n\n肝脏(胆红素 ${bilMg.toFixed(1)} mg/dL): ${bScore}\n肾脏(肌酐 ${crMg.toFixed(2)} mg/dL): ${cScore}\n脑(HE ${heLabel}): ${hScore}\n凝血(INR ${inr}): ${iScore}\n循环(MAP ${map} ${vaso === 'none' ? '无血管活性药' : vaso === 'low' ? '低剂量血管活性药' : '高剂量血管活性药'}): ${vScore}\n呼吸(P/F ${pf.toFixed(0)}): ${rScore}\n\nCLIF-OF: ${clifOf}/18（每器官1-3分）\n年龄: ${age}\nWBC: ${wbc} (×10⁹/L)\n注：因HE插管者脑项按3分计；P/F≤200或机械通气者呼吸项按3分计（本实现未单独采集插管状态）。`;

  return { value: scoreRounded, unit: '分', tier, tierClass, footnote: footnote + detail };
}
