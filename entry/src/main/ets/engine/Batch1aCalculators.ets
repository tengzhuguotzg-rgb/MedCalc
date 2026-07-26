import { CalcResult, getTierClass } from './CalcEngine';

function emptyResult(unit: string): CalcResult {
  return { value: null, unit, tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
}

export function calculateShockIndex(hr: number, sbp: number): CalcResult {
  if (hr <= 0 || sbp <= 0) {
    return emptyResult('');
  }
  const si = hr / sbp;
  let tier: string;
  let footnote: string;
  if (si >= 1.0) {
    tier = '高危';
    footnote = 'SI ≥ 1.0，提示隐匿性休克/失代偿风险高，需立即评估容量、出血、感染源和灌注。';
  } else if (si >= 0.9) {
    tier = '高风险';
    footnote = 'SI 0.9-0.99，提示循环代偿边缘，建议结合乳酸、尿量、毛细血管再充盈动态复查。';
  } else if (si >= 0.7) {
    tier = '正常偏高';
    footnote = 'SI 0.7-0.89，大致可接受，但创伤/脓毒症早期仍建议动态监测。';
  } else if (si >= 0.5) {
    tier = '正常';
    footnote = 'SI 0.5-0.69，常见正常范围。';
  } else {
    tier = '偏低';
    footnote = 'SI < 0.5，可见于低心率、高血压或测量误差，需结合临床。';
  }
  return { value: si, unit: '', tier, tierClass: getTierClass(tier), footnote: `${footnote}\nShock Index = HR/SBP = ${hr}/${sbp} = ${si.toFixed(2)}` };
}

export function calculateQsofa(rr: number, sbp: number, gcs: number, consciousness: string): CalcResult {
  const hasMental = gcs > 0 || consciousness.length > 0;
  if (rr <= 0 || sbp <= 0 || !hasMental) {
    return emptyResult('');
  }
  const altered = (gcs > 0 && gcs < 15) || (consciousness.length > 0 && consciousness !== 'alert');
  let total = 0;
  if (rr >= 22) total += 1;
  if (sbp <= 100) total += 1;
  if (altered) total += 1;

  let tier: string;
  let footnote: string;
  if (total >= 2) {
    tier = 'qSOFA 阳性';
    footnote = '≥2 分提示脓毒症不良结局风险增加，应立即评估感染源、乳酸、SOFA 和复苏指征。qSOFA 是筛查工具，不单独诊断脓毒症。';
  } else if (total === 1) {
    tier = '警惕';
    footnote = '1 分不能排除重症感染，若临床怀疑脓毒症仍需查乳酸并完成 SOFA。';
  } else {
    tier = '低风险';
    footnote = '0 分短期内不良结局风险较低，但不能排除早期脓毒症。';
  }
  return { value: total, unit: '', tier, tierClass: total >= 2 ? 'tier-danger' : getTierClass(tier), footnote };
}

function rtsGcsCode(gcs: number): number {
  if (gcs >= 13) return 4;
  if (gcs >= 9) return 3;
  if (gcs >= 6) return 2;
  if (gcs >= 4) return 1;
  return 0;
}

function rtsSbpCode(sbp: number): number {
  if (sbp > 89) return 4;
  if (sbp >= 76) return 3;
  if (sbp >= 50) return 2;
  if (sbp >= 1) return 1;
  return 0;
}

function rtsRrCode(rr: number): number {
  if (rr >= 10 && rr <= 29) return 4;
  if (rr > 29) return 3;
  if (rr >= 6) return 2;
  if (rr >= 1) return 1;
  return 0;
}

export function calculateRts(gcs: number, sbp: number, rr: number): CalcResult {
  if (gcs <= 0 || sbp < 0 || rr < 0) {
    return emptyResult('');
  }
  const gc = rtsGcsCode(gcs);
  const sc = rtsSbpCode(sbp);
  const rc = rtsRrCode(rr);
  const coded = gc + sc + rc;
  const weighted = 0.9368 * gc + 0.7326 * sc + 0.2908 * rc;

  let tier: string;
  let footnote: string;
  if (coded >= 11) {
    tier = '轻伤';
    footnote = 'coded RTS 11-12，创伤严重度较低，但仍需按创伤机制完成评估。';
  } else if (coded >= 8) {
    tier = '中度创伤';
    footnote = 'coded RTS 8-10，需创伤团队评估并动态复查 GCS/血压/呼吸。';
  } else if (coded >= 5) {
    tier = '重度创伤';
    footnote = 'coded RTS 5-7，提示高死亡风险，应启动创伤复苏流程。';
  } else {
    tier = '危重';
    footnote = 'coded RTS ≤4，极高危，按高级创伤生命支持处理。';
  }
  footnote += `\n\ncoded RTS = GCS码${gc} + SBP码${sc} + RR码${rc} = ${coded}/12\nweighted RTS = 0.9368×${gc} + 0.7326×${sc} + 0.2908×${rc} = ${weighted.toFixed(2)}\nRTS 用于创伤分诊/严重度评估，非 ICU 通用预后评分。`;
  return { value: coded, unit: '/12', tier, tierClass: getTierClass(tier), footnote };
}

export function calculateRsbi(rr: number, vtMl: number, sbtStatus: string): CalcResult {
  if (rr <= 0 || vtMl <= 0) {
    return emptyResult('breaths/min/L');
  }
  const rsbi = rr * 1000 / vtMl;
  let tier: string;
  let footnote: string;
  if (rsbi > 105) {
    tier = '撤机失败风险高';
    footnote = '>105 breaths/min/L，经典 Yang-Tobin 阈值提示撤机失败风险增加。';
  } else if (rsbi >= 80) {
    tier = '灰区';
    footnote = '80-105 breaths/min/L，需结合血气、肌力、分泌物、心功能和 SBT 耐受性。';
  } else {
    tier = '撤机成功可能性高';
    footnote = '<80 breaths/min/L，浅快呼吸指数较低，支持继续 SBT/撤机评估。';
  }
  if (sbtStatus !== 'sbt' && sbtStatus !== 'spont') {
    footnote += '\n⚠ 当前未标记为自主呼吸/SBT，RSBI 仅应在自主呼吸或 SBT 条件下解释。';
  }
  footnote += `\nRSBI = RR/VT(L) = ${rr}/(${(vtMl / 1000).toFixed(3)}) = ${rsbi.toFixed(0)} breaths/min/L`;
  return { value: rsbi, unit: 'breaths/min/L', tier, tierClass: getTierClass(tier), footnote };
}

export function calculateHellp(platelet: number, ast: number, alt: number, ldh: number, bilirubin: number, bilirubinUnit: string, hemolysis: boolean, pregnancyStatus: string): CalcResult {
  if (platelet <= 0 || (ast <= 0 && alt <= 0) || ldh <= 0) {
    return emptyResult('');
  }
  const biliMgDl = bilirubinUnit === 'umol' ? bilirubin / 17.1 : bilirubin;
  const lowPlatelet = platelet < 100;
  const liverEnzymes = ast >= 70 || alt >= 70;
  const hemolysisEvidence = hemolysis || ldh >= 600 || (bilirubin > 0 && biliMgDl >= 1.2);
  const count = (lowPlatelet ? 1 : 0) + (liverEnzymes ? 1 : 0) + (hemolysisEvidence ? 1 : 0);

  let tier: string;
  let footnote: string;
  if (count === 3) {
    tier = '满足 HELLP 标准';
    footnote = '三项均满足：血小板减少 + 肝酶升高 + 溶血证据。按危急值处理并立即请产科/重症/血液会诊。';
  } else if (count === 2) {
    tier = '部分满足';
    footnote = '两项满足，需高度警惕部分性 HELLP 或早期演变，建议短间隔复查血小板、LDH、胆红素、肝酶和血压/尿蛋白。';
  } else {
    tier = '不支持';
    footnote = '当前未达到本核对口径，但不能排除早期或不典型病例。';
  }

  const pregNote = pregnancyStatus === 'pregnant' ? '妊娠期' : pregnancyStatus === 'postpartum' ? '产后' : pregnancyStatus === 'no' ? '非妊娠/产后' : '妊娠状态未填';
  footnote += `\n\n核对项：血小板 ${platelet} ×10⁹/L ${lowPlatelet ? '✓' : '✗'}；AST ${ast}/ALT ${alt} U/L ${liverEnzymes ? '✓' : '✗'}；溶血证据 ${hemolysisEvidence ? '✓' : '✗'}（hemolysis=${hemolysis ? '1' : '0'}，LDH ${ldh}，TBil ${bilirubin > 0 ? biliMgDl.toFixed(1) + ' mg/dL' : '未填'}）。`;
  footnote += `\n状态：${pregNote}。本工具为标准核对/分层，不是最终诊断；需结合血压、蛋白尿、右上腹痛、神经系统症状，并鉴别 TTP/HUS/aHUS、妊娠期急性脂肪肝、ITP 等。肝酶阈值按 Tennessee 标准 ≥70 U/L，未按本院 ULN 校正。`;
  return { value: count, unit: '/3', tier, tierClass: count === 3 ? 'tier-danger' : getTierClass(tier), footnote };
}

export function calculateMetabolic(ca: number, alb: number, albUnit: string, na: number, glu: number, bun: number, measuredOsm: number): CalcResult {
  if (ca <= 0 || alb <= 0) {
    return emptyResult('mmol/L');
  }
  const albGl = albUnit === 'gdl' ? alb * 10 : alb;
  const correctedCa = ca + 0.02 * (40 - albGl);

  let tier: string;
  let footnote: string;
  if (correctedCa < 2.11) {
    tier = '低钙';
    footnote = '校正钙 <2.11 mmol/L，提示低钙血症；危重患者建议同时看离子钙。';
  } else if (correctedCa > 2.52) {
    tier = '高钙';
    footnote = '校正钙 >2.52 mmol/L，提示高钙血症；需结合 PTH、维生素D、恶性肿瘤和容量状态。';
  } else {
    tier = '正常';
    footnote = '校正钙 2.11-2.52 mmol/L，大致正常。';
  }
  footnote += `\n校正钙 = Ca + 0.02×(40 - Alb) = ${ca} + 0.02×(40 - ${albGl.toFixed(0)}) = ${correctedCa.toFixed(2)} mmol/L`;

  if (na > 0 && glu > 0 && bun > 0) {
    const calcOsm = 2 * na + glu + bun;
    footnote += `\n\n计算渗透压 = 2×Na + Glu + BUN = 2×${na} + ${glu} + ${bun} = ${calcOsm.toFixed(0)} mOsm/kg`;
    if (measuredOsm > 0) {
      const gap = measuredOsm - calcOsm;
      footnote += `\n渗透间隙 = ${measuredOsm} - ${calcOsm.toFixed(0)} = ${gap.toFixed(0)} mOsm/kg`;
      footnote += gap > 10 ? '，>10 提示甲醇/乙二醇/丙酮/甘露醇等渗透活性物质或严重高渗状态。' : '，≤10 大致无明显渗透间隙。';
    }
  }
  footnote += '\n阴离子间隙请使用现有“白蛋白校准 AG”；本卡用于校正钙与渗透间隙快速核对。';
  return { value: correctedCa, unit: 'mmol/L', tier, tierClass: getTierClass(tier), footnote };
}
