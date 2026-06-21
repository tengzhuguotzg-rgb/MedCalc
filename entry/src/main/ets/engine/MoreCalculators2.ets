import { CalcResult, getTierClass } from './CalcEngine';

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

export function calculatePugh(bil: number, bilUnit: string, ascites: number, enceph: number, inr: number, alb: number, albUnit: string): CalcResult {
  const bilGdl = bilUnit === 'umol' ? bil / 17.1 : bil;
  const albGdl = albUnit === 'gl' ? alb / 10 : alb;
  
  let total = 0;
  if (bilGdl < 2) total += 1;
  else if (bilGdl < 3) total += 2;
  else total += 3;
  
  total += ascites;
  total += enceph;
  
  if (inr < 1.3) total += 1;
  else if (inr < 1.5) total += 2;
  else total += 3;
  
  if (albGdl > 3.5) total += 1;
  else if (albGdl > 2.8) total += 2;
  else total += 3;
  
  let tier: string, footnote: string;
  if (total <= 6) { tier = 'A级'; footnote = '5-6分 肝功能储备良好，1年生存率100%。'; }
  else if (total <= 9) { tier = 'B级'; footnote = '7-9分 肝功能中度受损，1年生存率81%。'; }
  else { tier = 'C级'; footnote = '10-15分 肝功能严重受损，1年生存率45%。'; }
  return { value: total, unit: '', tier, tierClass: getTierClass(tier), footnote };
}

export function calculateRass(score: number): CalcResult {
  let tier: string, footnote: string;
  if (score >= 2) { tier = '躁动'; footnote = '+2至+4 躁动，需镇静干预。'; }
  else if (score >= -1) { tier = '清醒'; footnote = '-1至+1 清醒或轻度镇静。'; }
  else if (score >= -3) { tier = '镇静'; footnote = '-2至-3 中度镇静，可唤醒。'; }
  else { tier = '深镇静'; footnote = '-4至-5 深度镇静，难以唤醒。'; }
  return { value: score, unit: '', tier, tierClass: getTierClass(tier), footnote };
}

export function calculateIch(gcs: number, age: number, location: number, volume: number, ivh: number): CalcResult {
  let total = 0;
  if (gcs >= 13) total += 0;
  else if (gcs >= 5) total += 1;
  else total += 2;
  
  if (age < 45) total += 0;
  else if (age < 65) total += 1;
  else total += 2;
  
  total += location;
  
  if (volume < 30) total += 0;
  else if (volume < 60) total += 1;
  else total += 2;
  
  total += ivh;
  
  let tier: string, footnote: string;
  if (total === 0) { tier = '低风险'; footnote = '0分 30天死亡率0%。'; }
  else if (total <= 2) { tier = '中低风险'; footnote = '1-2分 30天死亡率约10%。'; }
  else if (total <= 4) { tier = '中高风险'; footnote = '3-4分 30天死亡率约40%。'; }
  else { tier = '高风险'; footnote = '≥5分 30天死亡率约75%。'; }
  return { value: total, unit: '', tier, tierClass: getTierClass(tier), footnote };
}

export function calculateHunt(grade: number): CalcResult {
  let tier: string, footnote: string;
  if (grade <= 1) { tier = '低风险'; footnote = '0-1级 手术风险低。'; }
  else if (grade <= 3) { tier = '中风险'; footnote = '2-3级 手术风险中等。'; }
  else { tier = '高风险'; footnote = '4-5级 手术风险高。'; }
  return { value: grade, unit: '', tier, tierClass: getTierClass(tier), footnote };
}

export function calculateWfns(gcs: number, deficit: boolean): CalcResult {
  let grade: number;
  if (gcs === 15) grade = deficit ? 2 : 1;
  else if (gcs >= 13) grade = 3;
  else if (gcs >= 7) grade = 4;
  else grade = 5;
  
  let tier: string, footnote: string;
  if (grade <= 2) { tier = '良好'; footnote = 'I-II级 预后良好。'; }
  else if (grade <= 3) { tier = '中等'; footnote = 'III级 预后中等。'; }
  else { tier = '较差'; footnote = 'IV-V级 预后较差。'; }
  return { value: grade, unit: '', tier, tierClass: getTierClass(tier), footnote };
}

export function calculateFisher(grade: number): CalcResult {
  let tier: string, footnote: string;
  if (grade === 1) { tier = '低风险'; footnote = '1级 无SAH，血管痉挛风险低。'; }
  else if (grade === 2) { tier = '中风险'; footnote = '2级 薄层SAH，血管痉挛风险中等。'; }
  else { tier = '高风险'; footnote = '3-4级 厚层SAH或脑室内出血，血管痉挛风险高。'; }
  return { value: grade, unit: '', tier, tierClass: getTierClass(tier), footnote };
}

export function calculateMarshall(resp: number, renal: number, cardio: number): CalcResult {
  const total = resp + renal + cardio;
  let tier: string, footnote: string;
  if (total >= 2) { tier = '器官衰竭'; footnote = '≥2分 定义器官衰竭，重症胰腺炎。'; }
  else { tier = '无衰竭'; footnote = '<2分 无器官衰竭。'; }
  return { value: total, unit: '', tier, tierClass: getTierClass(tier), footnote };
}
