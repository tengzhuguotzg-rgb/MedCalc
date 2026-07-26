import { CalcResult, getTierClass } from './CalcEngine';

function emptyResult(unit: string): CalcResult {
  return { value: null, unit, tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
}

/**
 * 哮喘急性加重严重度分级（GINA 口径）。speech: ''/'sentences'/'phrases'/'words'。
 * 返回分级 0=轻中度 1=重度 2=危重（取各指标最差）。
 */
export function calculateAsthma(pefPct: number, rr: number, hr: number, speech: string, silentChest: boolean): CalcResult {
  if (pefPct <= 0 && speech.length === 0 && !silentChest) {
    return emptyResult('');
  }
  let level = 0;
  const parts: string[] = [];
  if (pefPct > 0) {
    let pefLevel = 0;
    if (pefPct < 33) pefLevel = 2; else if (pefPct < 50) pefLevel = 1;
    level = Math.max(level, pefLevel);
    parts.push(`PEF ${pefPct}%预计值→${['轻中度', '重度', '危重'][pefLevel]}`);
  }
  if (speech.length > 0) {
    const spLevel = speech === 'words' ? 1 : speech === 'phrases' ? 1 : 0;
    level = Math.max(level, spLevel);
    parts.push(`说话${speech === 'sentences' ? '成句' : speech === 'phrases' ? '成短语' : '单词'}→${spLevel === 0 ? '轻中度' : '重度'}`);
  }
  if (rr >= 30) { level = Math.max(level, 1); parts.push(`RR ${rr}≥30→重度`); }
  if (hr >= 120) { level = Math.max(level, 1); parts.push(`HR ${hr}≥120→重度`); }
  if (silentChest) { level = 2; parts.push('沉默胸→危重'); }

  const tiers: string[] = ['轻中度', '重度', '危重'];
  const notes: string[] = [
    'PEF≥50%预计值、说话成句，可在急诊/门诊处理后随访，规律吸入治疗。',
    'PEF<50%、说话成短语或 RR≥30/HR≥120，需急诊强化治疗（反复 SABA+全身激素+氧疗）并密切复查。',
    'PEF<33%或沉默胸，危及生命，立即抢救：氧疗、雾化β2+抗胆碱、静脉激素、考虑硫酸镁并准备插管。'
  ];
  const footnote = `${notes[level]}\n\n判定项：${parts.join('；')}\nGINA 口径：重度=PEF<50%预计值/说话成短语/RR≥30/HR≥120；危重=PEF<33%、沉默胸、意识障碍或衰竭。本工具取最差项，意识障碍请结合 GCS/NEWS2。`;
  return { value: level, unit: '', tier: tiers[level], tierClass: level === 2 ? 'tier-danger' : level === 1 ? 'tier-warn' : 'tier-ok', footnote };
}

/**
 * GOLD ABE 慢阻肺分组。mmrc/cat 用 -1 表示未填。
 */
export function calculateGoldAbe(mmrc: number, cat: number, exacCount: number, exacHosp: number): CalcResult {
  if ((mmrc < 0 && cat < 0) || exacCount < 0) {
    return emptyResult('');
  }
  const highSymptoms = (mmrc >= 2) || (cat >= 10);
  const highRisk = exacCount >= 2 || exacHosp >= 1;

  let group: string;
  let footnote: string;
  if (highRisk) {
    group = 'E';
    footnote = 'E 组（高急性加重风险）：优先 LABA+LAMA，嗜酸粒细胞≥300 或反复加重考虑三联。';
  } else if (highSymptoms) {
    group = 'B';
    footnote = 'B 组（症状多、加重少）：起始 LABA+LAMA，强化症状管理与康复。';
  } else {
    group = 'A';
    footnote = 'A 组（症状少、加重少）：一种支扩剂即可，按需调整。';
  }
  const symNote = `症状：${mmrc >= 0 ? 'mMRC ' + mmrc : 'mMRC 未填'}${cat >= 0 ? '，CAT ' + cat : ''} → ${highSymptoms ? '多' : '少'}`;
  const riskNote = `加重：${exacCount} 次/年${exacHosp > 0 ? '，其中住院 ' + exacHosp + ' 次' : ''} → ${highRisk ? '高风险（≥2次或≥1次住院）' : '低风险'}`;
  footnote += `\n\n${symNote}\n${riskNote}\nGOLD ABE：A=症状少+加重少；B=症状多+加重少；E=≥2 次中度加重或 ≥1 次住院加重（不论症状）。`;
  return { value: null, unit: '', tier: `GOLD ${group} 组`, tierClass: group === 'E' ? 'tier-warn' : 'tier-ok', footnote };
}

/**
 * BAP-65 慢阻肺急性加重风险：BUN>25 mg/dL、意识改变、脉搏>109、年龄>65 各 1 分。
 */
export function calculateBap65(bunMgDl: number, pulse: number, age: number, altered: boolean): CalcResult {
  if (bunMgDl <= 0 || pulse <= 0 || age <= 0) {
    return emptyResult('');
  }
  let total = 0;
  const parts: string[] = [];
  if (bunMgDl >= 25) { total += 1; parts.push('BUN≥25✓'); } else { parts.push('BUN≥25✗'); }
  if (altered) { total += 1; parts.push('意识改变✓'); } else { parts.push('意识改变✗'); }
  if (pulse >= 109) { total += 1; parts.push('脉搏≥109✓'); } else { parts.push('脉搏≥109✗'); }
  if (age >= 65) { total += 1; parts.push('年龄≥65✓'); } else { parts.push('年龄≥65✗'); }

  let tier: string;
  let footnote: string;
  if (total >= 4) {
    tier = 'V 级（极高危）';
    footnote = '4 分，机械通气/死亡风险很高，建议 ICU 管理。';
  } else if (total === 3) {
    tier = 'IV 级（高危）';
    footnote = '3 分，风险高，建议收住并密切监护。';
  } else if (total === 2) {
    tier = 'III 级（中危）';
    footnote = '2 分，中等风险，按 AECOPD 规范治疗并观察恶化征象。';
  } else {
    tier = 'I-II 级（低危）';
    footnote = '0-1 分，风险低，可急诊处理后视情况门诊随访。';
  }
  footnote += `\n\n${parts.join('，')} → ${total}/4\nBAP-65 用于慢阻肺急性加重（AECOPD）机械通气/死亡风险分层，不用于哮喘。`;
  return { value: total, unit: '/4', tier, tierClass: total >= 3 ? 'tier-danger' : getTierClass(tier), footnote };
}

/**
 * GCS-Pupils：GCS-P = GCS - 瞳孔反应分（双侧=0/一侧=1/均无=2）。
 */
export function calculateGcsP(gcs: number, pupilScore: number): CalcResult {
  if (gcs <= 0) {
    return emptyResult('');
  }
  const p = pupilScore < 0 ? 0 : pupilScore > 2 ? 2 : Math.round(pupilScore);
  const gscp = gcs - p;

  let tier: string;
  let footnote: string;
  if (gscp <= 3) {
    tier = '极重';
    footnote = 'GCS-P ≤3，预后极差风险高，按重型颅脑损伤流程管理。';
  } else if (gscp <= 8) {
    tier = '重型';
    footnote = 'GCS-P 4-8，提示严重脑损伤，需神经监护。';
  } else if (gscp <= 12) {
    tier = '中型';
    footnote = 'GCS-P 9-12，中度损伤，动态复查瞳孔与 GCS。';
  } else {
    tier = '轻型';
    footnote = 'GCS-P 13-15，相对轻。';
  }
  footnote += `\n\nGCS-P = GCS ${gcs} - 瞳孔分 ${p} = ${gscp}（范围 1-15）\n瞳孔分：双侧有反应=0，一侧无反应=1，双侧均无=2。GCS-P 结合瞳孔信息，比单独 GCS 更能反映预后；趋势比单次数值更重要。`;
  return { value: gscp, unit: '', tier, tierClass: gscp <= 3 ? 'tier-danger' : getTierClass(tier), footnote };
}

/**
 * FOUR 评分：眼/运动/脑干/呼吸各 0-4，总分 0-16。
 */
export function calculateFour(eye: number, motor: number, brainstem: number, resp: number): CalcResult {
  const total = eye + motor + brainstem + resp;

  let tier: string;
  let footnote: string;
  if (total <= 4) {
    tier = '极重';
    footnote = '0-4 分，深度昏迷/接近脑死亡标准，需紧急气道与神经重症处理。';
  } else if (total <= 8) {
    tier = '重度意识障碍';
    footnote = '5-8 分，重度意识障碍，建议 ICU 神经监护。';
  } else if (total <= 12) {
    tier = '中度';
    footnote = '9-12 分，中度意识障碍，动态复查。';
  } else {
    tier = '相对轻';
    footnote = '13-16 分，意识水平相对保留。';
  }
  footnote += `\n\n眼 E${eye} + 运动 M${motor} + 脑干 B${brainstem} + 呼吸 R${resp} = ${total}/16\nFOUR 评分包含脑干反射与呼吸模式，适用于插管/不能言语患者，比 GCS 提供更多脑干信息。`;
  return { value: total, unit: '/16', tier, tierClass: total <= 4 ? 'tier-danger' : getTierClass(tier), footnote };
}

/**
 * CRUSADE 出血风险评分（ACS/NSTE-ACS 住院大出血）。
 */
export function calculateCrusade(hct: number, crcl: number, hr: number, female: boolean, chfSigns: boolean, priorVascular: boolean, dm: boolean, sbp: number): CalcResult {
  if (hct <= 0 || crcl <= 0 || hr <= 0 || sbp <= 0) {
    return emptyResult('');
  }
  let total = 0;
  const parts: string[] = [];
  let hctPts = 0;
  if (hct < 31) hctPts = 9; else if (hct < 34) hctPts = 7; else if (hct < 37) hctPts = 3; else if (hct < 40) hctPts = 2;
  total += hctPts; parts.push(`Hct ${hct}→${hctPts}`);
  let crclPts = 0;
  if (crcl <= 15) crclPts = 39; else if (crcl <= 30) crclPts = 35; else if (crcl <= 60) crclPts = 28; else if (crcl <= 90) crclPts = 17; else if (crcl <= 120) crclPts = 7;
  total += crclPts; parts.push(`CrCl ${crcl}→${crclPts}`);
  let hrPts = 0;
  if (hr >= 121) hrPts = 11; else if (hr >= 111) hrPts = 10; else if (hr >= 101) hrPts = 8; else if (hr >= 91) hrPts = 6; else if (hr >= 81) hrPts = 3; else if (hr >= 71) hrPts = 1;
  total += hrPts; parts.push(`HR ${hr}→${hrPts}`);
  if (female) { total += 8; parts.push('女性→8'); }
  if (chfSigns) { total += 7; parts.push('心衰体征→7'); }
  if (priorVascular) { total += 6; parts.push('血管病史→6'); }
  if (dm) { total += 6; parts.push('糖尿病→6'); }
  let sbpPts = 0;
  if (sbp <= 90) sbpPts = 10; else if (sbp <= 100) sbpPts = 8; else if (sbp <= 120) sbpPts = 5; else if (sbp <= 180) sbpPts = 1; else if (sbp <= 200) sbpPts = 3; else sbpPts = 5;
  total += sbpPts; parts.push(`SBP ${sbp}→${sbpPts}`);

  let tier: string;
  let risk: string;
  if (total <= 20) { tier = '极低危'; risk = '约 3.1%'; }
  else if (total <= 30) { tier = '低危'; risk = '约 5.5%'; }
  else if (total <= 40) { tier = '中危'; risk = '约 8.6%'; }
  else if (total <= 50) { tier = '高危'; risk = '约 11.9%'; }
  else { tier = '极高危'; risk = '约 19.5%'; }
  const footnote = `${parts.join('，')} → ${total} 分\nCRUSADE 住院大出血风险：≤20 极低危≈3.1%，21-30 低危≈5.5%，31-40 中危≈8.6%，41-50 高危≈11.9%，>50 极高危≈19.5%。\n用于 ACS 抗栓治疗出血风险评估；CrCl 可用 eGFR 近似（脚注注明），出血高危者优选出血风险低的抗栓方案。`;
  return { value: total, unit: '', tier: `${tier}（大出血 ${risk}）`, tierClass: total > 40 ? 'tier-danger' : getTierClass(tier), footnote };
}

/**
 * REMS 急诊快速内科评分：年龄/MAP/HR/RR/SpO2/GCS，0-26 分。
 */
export function calculateRems(age: number, map: number, hr: number, rr: number, spo2: number, gcs: number): CalcResult {
  if (age <= 0 || map <= 0 || hr <= 0 || rr <= 0 || spo2 <= 0 || gcs <= 0) {
    return emptyResult('');
  }
  let total = 0;
  const parts: string[] = [];
  let agePts = 0;
  if (age > 74) agePts = 6; else if (age >= 65) agePts = 5; else if (age >= 55) agePts = 3; else if (age >= 45) agePts = 2;
  total += agePts; parts.push(`年龄→${agePts}`);
  let mapPts = 0;
  if (map >= 70 && map <= 109) mapPts = 0; else if ((map >= 50 && map <= 69) || (map >= 110 && map <= 129)) mapPts = 2; else if (map >= 130 && map <= 159) mapPts = 3; else mapPts = 4;
  total += mapPts; parts.push(`MAP→${mapPts}`);
  let hrPts = 0;
  if (hr >= 70 && hr <= 109) hrPts = 0; else if ((hr >= 55 && hr <= 69) || (hr >= 110 && hr <= 139)) hrPts = 2; else if ((hr >= 40 && hr <= 54) || (hr >= 140 && hr <= 179)) hrPts = 3; else hrPts = 4;
  total += hrPts; parts.push(`HR→${hrPts}`);
  let rrPts = 0;
  if (rr >= 12 && rr <= 24) rrPts = 0; else if ((rr >= 10 && rr <= 11) || (rr >= 25 && rr <= 34)) rrPts = 1; else if (rr >= 6 && rr <= 9) rrPts = 2; else if (rr >= 35 && rr <= 49) rrPts = 3; else rrPts = 4;
  total += rrPts; parts.push(`RR→${rrPts}`);
  let spo2Pts = 0;
  if (spo2 > 89) spo2Pts = 0; else if (spo2 >= 86) spo2Pts = 1; else if (spo2 >= 75) spo2Pts = 3; else spo2Pts = 4;
  total += spo2Pts; parts.push(`SpO₂→${spo2Pts}`);
  let gcsPts = 0;
  if (gcs >= 14) gcsPts = 0; else if (gcs >= 11) gcsPts = 1; else if (gcs >= 8) gcsPts = 2; else if (gcs >= 5) gcsPts = 3; else gcsPts = 4;
  total += gcsPts; parts.push(`GCS→${gcsPts}`);

  let tier: string;
  let footnote: string;
  if (total <= 5) {
    tier = '低危';
    footnote = '0-5 分，短期死亡风险低。';
  } else if (total <= 10) {
    tier = '中危';
    footnote = '6-10 分，需留观并动态复查。';
  } else if (total <= 15) {
    tier = '高危';
    footnote = '11-15 分，死亡风险高，建议收住监护。';
  } else {
    tier = '极高危';
    footnote = '≥16 分，极高死亡风险，按危重流程处理。';
  }
  footnote += `\n\n${parts.join('，')} → ${total}/26\nREMS 用于急诊非手术患者院内死亡风险分层；与 NEWS2 互补，含年龄与 GCS。`;
  return { value: total, unit: '/26', tier, tierClass: total >= 11 ? 'tier-danger' : getTierClass(tier), footnote };
}

/**
 * 吸入性肺炎风险因素核对清单（非验证评分）。
 */
export function calculateAspiration(dysphagia: boolean, impairedConsciousness: boolean, vomitReflux: boolean, enteralTube: boolean, sedation: boolean, poorOral: boolean): CalcResult {
  const items: boolean[] = [dysphagia, impairedConsciousness, vomitReflux, enteralTube, sedation, poorOral];
  const labels: string[] = ['吞咽困难/误吸史', '意识障碍', '呕吐/胃食管反流', '鼻饲/肠内营养管', '镇静状态', '口腔卫生差'];
  let total = 0;
  const parts: string[] = [];
  for (let i = 0; i < items.length; i++) {
    if (items[i]) { total += 1; parts.push(labels[i]); }
  }

  let tier: string;
  let footnote: string;
  if (total >= 4) {
    tier = '高风险';
    footnote = '≥4 项危险因素，吸入性肺炎风险高：抬高床头 30-45°、吞咽评估、口腔护理、慎用镇静、必要时幽门后喂养。';
  } else if (total >= 2) {
    tier = '中风险';
    footnote = '2-3 项危险因素，建议床旁吞咽筛查与口腔护理。';
  } else {
    tier = '低风险';
    footnote = '0-1 项危险因素，常规预防即可。';
  }
  footnote += parts.length > 0 ? `\n\n危险因素：${parts.join('、')} → ${total}/6` : '\n\n未勾选危险因素 → 0/6';
  footnote += '\n本工具为风险因素核对清单，非验证评分；确诊吸入性肺炎需结合影像、氧合与感染指标（可配合 CPIS）。';
  return { value: total, unit: '/6', tier, tierClass: total >= 4 ? 'tier-danger' : getTierClass(tier), footnote };
}
