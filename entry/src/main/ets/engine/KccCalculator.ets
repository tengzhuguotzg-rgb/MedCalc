import { CalcResult } from './CalcEngine';

export function calculateKcc(
  inr: number, bilirubin: number, bilirubinUnit: string,
  age: number, etiology: boolean,
  ph: number, crMgDl: number, hepaticEnceph: number
): CalcResult {
  if (inr <= 0 || bilirubin <= 0 || age <= 0) {
    return { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
  }

  const bilUmol = bilirubinUnit === 'mgdl' ? bilirubin * 17.1 : bilirubin;
  const acuteEtiology = etiology;

  let meetsKcc = false;
  const reasons: string[] = [];

  if (ph > 0 && ph < 7.3) {
    meetsKcc = true;
    reasons.push(`pH ${ph.toFixed(2)} < 7.30`);
  }

  if (crMgDl > 0 && crMgDl >= 3.4) {
    meetsKcc = true;
    reasons.push(`肌酐 ${crMgDl.toFixed(1)} mg/dL ≥ 3.4`);
  }

  if (hepaticEnceph >= 3) {
    meetsKcc = true;
    reasons.push(`HE ${hepaticEnceph} 级 ≥ III`);
  }

  if (inr > 6.5) {
    meetsKcc = true;
    reasons.push(`INR ${inr.toFixed(1)} > 6.5`);
  } else if (bilUmol > 300) {
    meetsKcc = true;
    reasons.push(`胆红素 ${bilUmol.toFixed(0)} µmol/L > 300`);
  } else if (acuteEtiology && age < 18 && inr > 4 && bilUmol > 170) {
    meetsKcc = true;
    reasons.push('年龄<18 + INR>4 + 胆红素>170 µmol/L（Wilson/非甲非乙型肝炎）');
  } else if (acuteEtiology && inr > 2 && (bilUmol > 170 || crMgDl > 0) && hepaticEnceph > 0) {
    const pathA = acuteEtiology && inr > 2.5 && bilUmol > 170 && hepaticEnceph >= 2;
    const pathB = acuteEtiology && inr > 2 && crMgDl > 0 && crMgDl >= 3.4 && hepaticEnceph >= 1;
    if (pathA) {
      meetsKcc = true;
      reasons.push('急性病因 + INR>2.5 + 胆红素>170 + HE≥II');
    } else if (pathB) {
      meetsKcc = true;
      reasons.push('急性病因 + INR>2 + Cr≥3.4 + HE≥I');
    }
  }

  let tier: string;
  let tierClass: string;
  let footnote: string;

  if (meetsKcc) {
    tier = '符合KCC标准';
    tierClass = 'tier-danger';
    footnote = `${reasons.join('；')}，建议紧急肝移植评估。`;
  } else {
    tier = '不符合KCC标准';
    tierClass = 'tier-ok';
    footnote = '暂无紧急肝移植指征，继续监测。';
  }

  const extra = `\n\nINR ${inr.toFixed(1)}，胆红素 ${bilUmol.toFixed(0)} µmol/L，年龄 ${age}，${acuteEtiology ? '急性病因' : '非急性病因'}`;
  const extra2 = ph > 0 ? `，pH ${ph.toFixed(2)}` : '，pH 未填';
  const extra3 = crMgDl > 0 ? `，肌酐 ${crMgDl.toFixed(1)} mg/dL` : '，肌酐未填';
  const extra4 = hepaticEnceph >= 0 ? `，HE ${hepaticEnceph} 级` : '，HE 未填';
  footnote += extra + extra2 + extra3 + extra4;
  footnote += '\nKing\'s College Criteria（KCC）：\n对乙酰氨基酚路径：pH<7.3（入院后24h）或 INR>6.5+Cr≥3.4+HE≥III；\n非对乙酰氨基酚路径：INR>6.5 或 胆红素>300µmol/L（任一）；或 急性病因+INR>2.5+胆红素>170+HE≥II；或 急性病因+INR>2+Cr≥3.4+HE≥I。\npH/肌酐/HE 未填时部分条件无法判断，请补录。';

  return { value: meetsKcc ? 1 : 0, unit: '', tier, tierClass, footnote };
}
