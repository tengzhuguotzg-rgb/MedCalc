import { CalcResult, getTierClass } from './CalcEngine';

function emptyResult(unit: string): CalcResult {
  return { value: null, unit, tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
}

/**
 * Sgarbossa / Smith 改良 Sgarbossa（LBBB 或起搏心律下 AMI 判断）。
 * discordantMode: 0=无，1=不协调 ST 抬高≥5mm（原始），2=ST/S≤-0.25（Smith 改良）。
 */
export function calculateSgarbossa(concordantSte: boolean, concordantStd: boolean, discordantMode: number): CalcResult {
  if (!concordantSte && !concordantStd && discordantMode === 0) {
    return emptyResult('');
  }
  const stePts = concordantSte ? 5 : 0;
  const stdPts = concordantStd ? 3 : 0;
  const disPts = discordantMode > 0 ? 2 : 0;
  const total = stePts + stdPts + disPts;

  let tier: string;
  let footnote: string;
  if (concordantSte || concordantStd || total >= 3) {
    tier = '高度提示闭塞性心梗';
    footnote = '符合协调性改变（特异性高）或原始 Sgarbossa ≥3 分：按 STEMI 等效处理，紧急心内会诊/造影。';
  } else if (discordantMode === 2) {
    tier = '改良标准阳性';
    footnote = 'ST/S ≤ -0.25（Smith 改良标准）提示闭塞性心梗可能，建议紧急会诊并结合肌钙蛋白动态。';
  } else {
    tier = '不支持';
    footnote = '未达 Sgarbossa 标准，但临床高度怀疑时不能排除，结合肌钙蛋白与复查心电图。';
  }
  const parts: string[] = [];
  if (concordantSte) parts.push('协调性ST抬高≥1mm（5分）');
  if (concordantStd) parts.push('V1-V3协调性ST压低≥1mm（3分）');
  if (discordantMode === 1) parts.push('不协调ST抬高≥5mm（2分）');
  if (discordantMode === 2) parts.push('ST/S≤-0.25（2分，改良）');
  footnote += `\n\n符合项：${parts.join('；')} → ${total} 分\n仅适用于完全性左束支传导阻滞或心室起搏心律；原始口径 ≥3 分特异性高但敏感性有限，阴性不能排除。`;
  return { value: total, unit: '', tier, tierClass: total >= 3 || concordantSte || concordantStd ? 'tier-danger' : getTierClass(tier), footnote };
}

/**
 * 改良 Duke 感染性心内膜炎临床标准核对。
 */
export function calculateDuke(cultureMajor: boolean, echoMajor: boolean, predisposition: boolean, fever: boolean, vascular: boolean, immunological: boolean, microEvidence: boolean): CalcResult {
  if (!cultureMajor && !echoMajor && !predisposition && !fever && !vascular && !immunological && !microEvidence) {
    return emptyResult('');
  }
  const majorCount = (cultureMajor ? 1 : 0) + (echoMajor ? 1 : 0);
  const minorCount = (predisposition ? 1 : 0) + (fever ? 1 : 0) + (vascular ? 1 : 0) + (immunological ? 1 : 0) + (microEvidence ? 1 : 0);

  let tier: string;
  let footnote: string;
  if (majorCount === 2 || (majorCount === 1 && minorCount >= 3) || minorCount === 5) {
    tier = '确诊（临床标准）';
    footnote = '满足改良 Duke 确诊临床标准：按感染性心内膜炎管理（规范血培养后尽早抗菌、评估手术指征）。';
  } else if ((majorCount === 1 && minorCount >= 1) || minorCount === 3) {
    tier = '可能';
    footnote = '符合“可能 IE”：继续完善血培养（3 套）与 TTE/TEE，动态评估。';
  } else {
    tier = '不满足';
    footnote = '未达确诊/可能标准；临床高度怀疑时复查培养与影像。';
  }
  footnote += `\n\n主要标准 ${majorCount}/2（血培养${cultureMajor ? '✓' : '✗'}、心内膜受累${echoMajor ? '✓' : '✗'}）；次要标准 ${minorCount}/5（易感因素${predisposition ? '✓' : '✗'}、发热${fever ? '✓' : '✗'}、血管现象${vascular ? '✓' : '✗'}、免疫现象${immunological ? '✓' : '✗'}、未达主要的微生物证据${microEvidence ? '✓' : '✗'}）\n确诊=2主要 / 1主要+3次要 / 5次要；可能=1主要+1次要 / 3次要。本工具为标准核对，最终诊断结合病理与多学科评估。`;
  return { value: majorCount * 10 + minorCount, unit: '', tier, tierClass: tier === '确诊（临床标准）' ? 'tier-danger' : getTierClass(tier), footnote };
}

/**
 * AWOL 谵妄风险筛查（急诊/住院老年患者）。
 */
export function calculateAwol(age80: boolean, worldBackward: boolean, disoriented: boolean, severeIllness: boolean): CalcResult {
  if (!age80 && !worldBackward && !disoriented && !severeIllness) {
    return emptyResult('');
  }
  let total = 0;
  const parts: string[] = [];
  if (age80) { total += 1; parts.push('年龄≥80'); }
  if (worldBackward) { total += 1; parts.push('不能倒拼WORLD'); }
  if (disoriented) { total += 1; parts.push('地点定向障碍'); }
  if (severeIllness) { total += 1; parts.push('病情较重（护士判断）'); }

  let tier: string;
  let footnote: string;
  if (total >= 3) {
    tier = '高风险';
    footnote = '3-4 分，谵妄风险高：启动非药物预防（定向、睡眠、感官辅助、早期活动、避免诱因药物）并密切观察。';
  } else if (total === 2) {
    tier = '中风险';
    footnote = '2 分，中风险：常规谵妄预防措施并动态观察。';
  } else {
    tier = '低风险';
    footnote = '0-1 分，谵妄风险低。';
  }
  footnote += `\n\n${parts.join('、')} → ${total}/4\nAWOL 为床旁快速筛查（Age≥80 / 倒拼WORLD失败 / disOrientation / iLlness severity），筛查阳性建议用 CAM/CAM-ICU 确认。`;
  return { value: total, unit: '/4', tier, tierClass: total >= 3 ? 'tier-danger' : getTierClass(tier), footnote };
}
