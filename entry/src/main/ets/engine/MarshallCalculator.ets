import { CalcResult } from './CalcEngine';

/**
 * Marshall MODS 多器官功能障碍评分
 * Marshall JC, et al. Crit Care Med 1995;23(10):1638-1652.
 * 六器官各 0-4 分，总分 0-24：
 *   呼吸 P/F：>300=0, 226-300=1, 151-225=2, 76-150=3, ≤75=4
 *   肾 肌酐 µmol/L：≤100=0, 101-200=1, 201-350=2, 351-500=3, >500=4
 *   肝 胆红素 µmol/L：≤20=0, 21-60=1, 61-120=2, 121-240=3, >240=4
 *   心血管 PAR = HR×CVP/MAP：≤10=0, 10.1-15=1, 15.1-20=2, 20.1-30=3, >30=4
 *   血液 血小板 ×10⁹/L：>120=0, 81-120=1, 51-80=2, 21-50=3, ≤20=4
 *   神经 GCS：15=0, 13-14=1, 10-12=2, 7-9=3, ≤6=4
 * fio2 为小数（0.21-1.0）。
 */
export function calculateMarshall(
  pao2: number, fio2: number,
  crUmol: number, biliUmol: number,
  hr: number, cvp: number, map: number,
  platelet: number, gcs: number
): CalcResult {
  if (pao2 <= 0 || fio2 <= 0 || crUmol <= 0 || biliUmol <= 0 || hr <= 0 || cvp < 0 || map <= 0 || platelet <= 0 || gcs <= 0) {
    return { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
  }

  const pf = pao2 / fio2;
  const par = hr * cvp / map;

  let respScore = 0;
  if (pf <= 75) respScore = 4; else if (pf <= 150) respScore = 3; else if (pf <= 225) respScore = 2; else if (pf <= 300) respScore = 1;

  let renalScore = 0;
  if (crUmol > 500) renalScore = 4; else if (crUmol > 350) renalScore = 3; else if (crUmol > 200) renalScore = 2; else if (crUmol > 100) renalScore = 1;

  let hepScore = 0;
  if (biliUmol > 240) hepScore = 4; else if (biliUmol > 120) hepScore = 3; else if (biliUmol > 60) hepScore = 2; else if (biliUmol > 20) hepScore = 1;

  let cvScore = 0;
  if (par > 30) cvScore = 4; else if (par > 20) cvScore = 3; else if (par > 15) cvScore = 2; else if (par > 10) cvScore = 1;

  let hemeScore = 0;
  if (platelet <= 20) hemeScore = 4; else if (platelet <= 50) hemeScore = 3; else if (platelet <= 80) hemeScore = 2; else if (platelet <= 120) hemeScore = 1;

  let neuroScore = 0;
  if (gcs <= 6) neuroScore = 4; else if (gcs <= 9) neuroScore = 3; else if (gcs <= 12) neuroScore = 2; else if (gcs <= 14) neuroScore = 1;

  const total = respScore + renalScore + hepScore + cvScore + hemeScore + neuroScore;

  let tier: string;
  let tierClass: string;
  let footnote: string;

  if (total === 0) {
    tier = '无器官功能障碍';
    tierClass = 'tier-ok';
    footnote = '总分 0，无器官功能障碍。';
  } else if (total <= 4) {
    tier = '轻度';
    tierClass = 'tier-ok';
    footnote = '总分 1-4，轻度器官功能障碍。';
  } else if (total <= 8) {
    tier = '中度';
    tierClass = 'tier-warn';
    footnote = '总分 5-8，中度器官功能障碍，ICU 死亡率约 25%。';
  } else if (total <= 12) {
    tier = '重度';
    tierClass = 'tier-warn';
    footnote = '总分 9-12，重度器官功能障碍，ICU 死亡率约 50%。';
  } else {
    tier = '危重';
    tierClass = 'tier-danger';
    footnote = `总分 ${total}>12，危重多器官功能障碍，ICU 死亡率 ≥75%。`;
  }

  footnote += `\n\n呼吸(P/F ${pf.toFixed(0)})→${respScore}\n肾(Cr ${crUmol} µmol/L)→${renalScore}\n肝(胆红素 ${biliUmol} µmol/L)→${hepScore}\n心血管(PAR ${par.toFixed(1)} = HR ${hr}×CVP ${cvp}/MAP ${map})→${cvScore}\n血液(PLT ${platelet})→${hemeScore}\n神经(GCS ${gcs})→${neuroScore}\n→ 总分 ${total}/24`;
  footnote += '\nMarshall MODS（Marshall 1995）：六器官各 0-4 分；肌酐/胆红素单位为 µmol/L；PAR=压力校正心率=HR×CVP/MAP。评分与 ICU 死亡率正相关，用于胰腺炎 Atlanta 分级等器官功能障碍评估。注意：CVP 未监测时填 0，此时 PAR=0、心血管项记 0 分，总分可能被低估，有条件应实测 CVP。';

  return { value: total, unit: '/24', tier, tierClass, footnote };
}
