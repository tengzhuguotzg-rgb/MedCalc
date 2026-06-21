import { CalcResult, getTierClass } from './CalcEngine';

export function calculateRox(spo2: number, fio2: number, fio2Mode: string, rr: number): CalcResult {
  const fio2Value = fio2Mode === 'pct' ? fio2 / 100 : fio2;
  if (spo2 <= 0 || fio2Value <= 0 || rr <= 0) {
    return { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
  }
  const rox = spo2 / (fio2Value * rr);
  let tier: string, footnote: string;
  if (rox >= 4.88) { tier = '低风险'; footnote = '≥4.88 HFNC成功率高，可继续HFNC。'; }
  else if (rox >= 2.85) { tier = '中风险'; footnote = '2.85-4.88 需密切监测，可能需升级呼吸支持。'; }
  else { tier = '高风险'; footnote = '<2.85 HFNC失败风险高，建议评估插管。'; }
  return { value: rox, unit: '', tier, tierClass: getTierClass(tier), footnote };
}

export function calculateCag(na: number, cl: number, hco3: number, alb: number, albUnit: string): CalcResult {
  if (na <= 0 || cl <= 0 || hco3 <= 0 || alb <= 0) {
    return { value: null, unit: 'mmol/L', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
  }
  const ag = na - cl - hco3;
  const albGdl = albUnit === 'gl' ? alb / 10 : alb;
  const corrected = ag + 2.5 * (4 - albGdl);
  let tier: string, footnote: string;
  if (corrected > 16) { tier = '高AG代酸'; footnote = `校正AG > 16，提示高AG代酸（M代酸）。常见：酮症酸中毒、乳酸酸中毒、肾衰、摄入中毒。`; }
  else if (corrected >= 8) { tier = '正常偏高'; footnote = `校正AG 8-16，正常范围偏高。需结合临床。`; }
  else { tier = '正常'; footnote = `校正AG < 8，正常。`; }
  return { value: corrected, unit: 'mmol/L', tier, tierClass: getTierClass(tier), footnote };
}

export function calculateChadsvasc(chf: boolean, htn: boolean, age75: boolean, dm: boolean, stroke: boolean, vasc: boolean, age65: boolean, female: boolean): CalcResult {
  let total = 0;
  if (chf) total += 1;
  if (htn) total += 1;
  if (age75) total += 2;
  if (dm) total += 1;
  if (stroke) total += 2;
  if (vasc) total += 1;
  if (age65) total += 1;
  if (female) total += 1;
  
  let tier: string, footnote: string;
  if (total === 0) { tier = '低风险'; footnote = '0分 卒中风险低，可不予抗凝。'; }
  else if (total === 1) { tier = '中低风险'; footnote = '1分 可考虑抗凝。'; }
  else { tier = '高风险'; footnote = '≥2分 需抗凝治疗（NOAC或华法林）。'; }
  return { value: total, unit: '', tier, tierClass: getTierClass(tier), footnote };
}

export function calculateHasbled(htn: boolean, renal: boolean, liver: boolean, stroke: boolean, bleed: boolean, inr: boolean, age: boolean, drugs: boolean, alcohol: boolean): CalcResult {
  let total = 0;
  if (htn) total += 1;
  if (renal) total += 1;
  if (liver) total += 1;
  if (stroke) total += 1;
  if (bleed) total += 1;
  if (inr) total += 1;
  if (age) total += 1;
  if (drugs) total += 1;
  if (alcohol) total += 1;
  
  let tier: string, footnote: string;
  if (total >= 3) { tier = '高风险'; footnote = '≥3分 出血风险高，需谨慎抗凝，纠正可逆因素。'; }
  else if (total >= 1) { tier = '中风险'; footnote = '1-2分 出血风险中等，可抗凝但需监测。'; }
  else { tier = '低风险'; footnote = '0分 出血风险低。'; }
  return { value: total, unit: '', tier, tierClass: getTierClass(tier), footnote };
}

export function calculateAbcd2(age: boolean, bp: boolean, clin: number, dur: number, dm: boolean): CalcResult {
  let total = 0;
  if (age) total += 1;
  if (bp) total += 1;
  total += clin;
  total += dur;
  if (dm) total += 1;
  
  let tier: string, footnote: string;
  if (total >= 6) { tier = '高风险'; footnote = '≥6分 7天卒中风险8.1%，需住院。'; }
  else if (total >= 4) { tier = '中风险'; footnote = '4-5分 7天卒中风险4.1%，考虑住院。'; }
  else { tier = '低风险'; footnote = '0-3分 7天卒中风险1.2%，可门诊随访。'; }
  return { value: total, unit: '', tier, tierClass: getTierClass(tier), footnote };
}

export function calculateNihss(ia: number, ib: number, ic: number, gaze: number, vis: number, face: number, armA: number, armB: number, ata: number, sens: number, lang: number, dys: number, neg: number): CalcResult {
  const total = ia + ib + ic + gaze + vis + face + armA + armB + ata + sens + lang + dys + neg;
  let tier: string, footnote: string;
  if (total === 0) { tier = '正常'; footnote = '0分 无神经功能缺损。'; }
  else if (total <= 4) { tier = '轻度'; footnote = '1-4分 轻度卒中。'; }
  else if (total <= 15) { tier = '中度'; footnote = '5-15分 中度卒中。'; }
  else if (total <= 20) { tier = '中重度'; footnote = '16-20分 中重度卒中。'; }
  else { tier = '重度'; footnote = '21-42分 重度卒中。'; }
  return { value: total, unit: '', tier, tierClass: getTierClass(tier), footnote };
}

export function calculateNrs2002(bmi: number, wl: number, intake: number, severity: number): CalcResult {
  const total = bmi + wl + intake + severity;
  let tier: string, footnote: string;
  if (total >= 3) { tier = '营养风险'; footnote = '≥3分 存在营养风险，需营养支持。'; }
  else { tier = '无风险'; footnote = '<3分 暂无营养风险，1周后复评。'; }
  return { value: total, unit: '', tier, tierClass: getTierClass(tier), footnote };
}
