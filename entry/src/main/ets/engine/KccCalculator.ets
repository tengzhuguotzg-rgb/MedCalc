import { CalcResult } from './CalcEngine';

/**
 * King's College Criteria (KCC) — 急性肝衰竭紧急肝移植标准
 * O'Grady JG, et al. Gastroenterology 1989;97:439-445.
 *
 * 对乙酰氨基酚(APAP)路径（满足其一）：
 *   1) 动脉 pH < 7.30（充分复苏后，距摄入>24h）
 *   2) 同时满足：INR > 6.5 + 肌酐 > 300 µmol/L (>3.4 mg/dL) + HE III-IV 级
 * 非APAP路径（满足其一）：
 *   1) INR > 6.5
 *   2) 下列5项中满足任意3项：
 *      - 年龄 <10 或 >40 岁
 *      - 病因：非甲非乙型肝炎 / 卤烷 / 特异质药物反应
 *      - 黄疸至脑病间隔 > 7 天
 *      - INR > 3.5
 *      - 胆红素 > 300 µmol/L (>17.5 mg/dL)
 *
 * hepaticEnceph UI 编码：0=无, 1=I-II, 2=III-IV, -1=未填
 * jaundiceDays：黄疸至脑病天数，0=未知/不适用
 */
export function calculateKcc(
  inr: number, bilirubin: number, bilirubinUnit: string,
  age: number, isApap: boolean, adverseEtiology: boolean,
  jaundiceDays: number,
  ph: number, crMgDl: number, hepaticEnceph: number
): CalcResult {
  if (inr <= 0 || bilirubin <= 0 || age <= 0 || hepaticEnceph < 0) {
    return { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
  }

  const bilUmol = bilirubinUnit === 'mgdl' ? bilirubin * 17.1 : bilirubin;
  const he34 = hepaticEnceph >= 2;

  let meetsKcc = false;
  const reasons: string[] = [];
  const notes: string[] = [];

  if (isApap) {
    // APAP 路径
    if (ph > 0 && ph < 7.3) {
      meetsKcc = true;
      reasons.push(`pH ${ph.toFixed(2)} < 7.30`);
    }
    if (ph <= 0) {
      notes.push('pH 未填，APAP 路径 pH<7.30 无法判断');
    }
    if (crMgDl <= 0) {
      notes.push('肌酐未填，APAP 三联标准无法完整判断');
    }
    if (inr > 6.5 && crMgDl > 3.4 && he34) {
      meetsKcc = true;
      reasons.push(`INR ${inr.toFixed(1)}>6.5 + 肌酐 ${crMgDl.toFixed(1)}>3.4 mg/dL + HE III-IV 级`);
    }
  } else {
    // 非 APAP 路径
    if (inr > 6.5) {
      meetsKcc = true;
      reasons.push(`INR ${inr.toFixed(1)} > 6.5`);
    } else {
      let count = 0;
      const hit: string[] = [];
      if (age < 10 || age > 40) {
        count++;
        hit.push(`年龄 ${age} 岁 (<10或>40)`);
      }
      if (adverseEtiology) {
        count++;
        hit.push('病因：非甲非乙/卤烷/特异质药物反应');
      }
      if (jaundiceDays > 7) {
        count++;
        hit.push(`黄疸至脑病 ${jaundiceDays} 天 (>7)`);
      } else if (jaundiceDays <= 0) {
        notes.push('黄疸至脑病天数未填，该项按不满足计');
      }
      if (inr > 3.5) {
        count++;
        hit.push(`INR ${inr.toFixed(1)} > 3.5`);
      }
      if (bilUmol > 300) {
        count++;
        hit.push(`胆红素 ${bilUmol.toFixed(0)} µmol/L > 300`);
      }
      if (count >= 3) {
        meetsKcc = true;
        reasons.push(`5项中满足${count}项（≥3）：${hit.join('；')}`);
      } else {
        notes.push(`5项中仅满足${count}项（需≥3）${count > 0 ? '：' + hit.join('；') : ''}`);
      }
    }
  }

  let tier: string;
  let tierClass: string;
  let footnote: string;

  if (meetsKcc) {
    tier = '符合KCC标准';
    tierClass = 'tier-danger';
    footnote = `${reasons.join('；')}，符合紧急肝移植评估标准。`;
  } else {
    tier = '不符合KCC标准';
    tierClass = 'tier-ok';
    footnote = '目前不符合 KCC 紧急肝移植标准，继续监测。';
  }
  if (notes.length > 0) {
    footnote += `\n${notes.join('；')}。`;
  }

  const extra = `\n\nINR ${inr.toFixed(1)}，胆红素 ${bilUmol.toFixed(0)} µmol/L，年龄 ${age}，路径：${isApap ? '对乙酰氨基酚(APAP)' : '非APAP'}`;
  const extra2 = ph > 0 ? `，pH ${ph.toFixed(2)}` : '';
  const extra3 = crMgDl > 0 ? `，肌酐 ${crMgDl.toFixed(1)} mg/dL` : '';
  const heLabel = hepaticEnceph === 0 ? '无' : hepaticEnceph === 1 ? 'I-II' : 'III-IV';
  footnote += `${extra}${extra2}${extra3}，HE ${heLabel}`;
  footnote += '\nKing\'s College Criteria（O\'Grady 1989）：\nAPAP路径：pH<7.30（复苏后）或 INR>6.5+Cr>300µmol/L+HE III-IV（MDCalc 另列：4h乳酸>3.5 或 12h>3.0 mmol/L 亦可）；\n非APAP路径：INR>6.5，或5选3（年龄<10/>40、非甲非乙/卤烷/药物病因、黄疸至脑病>7天、INR>3.5、胆红素>300µmol/L）。';

  return { value: meetsKcc ? 1 : 0, unit: '', tier, tierClass, footnote };
}
