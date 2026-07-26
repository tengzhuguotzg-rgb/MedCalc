import { CalcResult, emptyResult, getTierClass } from './CalcEngine';

/**
 * HEART Score：History / ECG / Age / Risk factors / Troponin 各 0-2 分。
 * history/ecg 直接传入分值 0-2；troponinRatio = 肌钙蛋白 / 本院ULN。
 */
export function calculateHeart(history: number, ecg: number, age: number, riskFactorCount: number, knownAtherosclerosis: boolean, troponinRatio: number): CalcResult {
  if (age <= 0 || troponinRatio <= 0) {
    return emptyResult('');
  }
  const h = history < 0 ? 0 : history > 2 ? 2 : Math.round(history);
  const e = ecg < 0 ? 0 : ecg > 2 ? 2 : Math.round(ecg);
  let a = 0;
  if (age >= 65) a = 2; else if (age >= 45) a = 1;
  let r = 0;
  if (knownAtherosclerosis || riskFactorCount >= 3) r = 2; else if (riskFactorCount >= 1) r = 1;
  let t = 0;
  if (troponinRatio > 3) t = 2; else if (troponinRatio > 1) t = 1;
  const total = h + e + a + r + t;

  let tier: string;
  let footnote: string;
  if (total >= 7) {
    tier = '高风险';
    footnote = '7-10 分，MACE 风险高，建议早期侵入性评估/收住。';
  } else if (total >= 4) {
    tier = '中风险';
    footnote = '4-6 分，建议收住观察、复查肌钙蛋白并请心内科评估。';
  } else {
    tier = '低风险';
    footnote = '0-3 分，短期 MACE 风险低，可结合 hs-cTn 动态变化考虑门诊随访。';
  }
  footnote += `\n\nH${h} + E${e} + A${a} + R${r} + T${t} = ${total}/10`;
  footnote += `\nR 项：危险因素 ${riskFactorCount} 个${knownAtherosclerosis ? '，已知动脉粥样硬化' : ''}；T 项按 肌钙蛋白/ULN = ${troponinRatio.toFixed(2)} 计 ${t} 分（未填病史/心电图按 0 分计，可能低估）。`;
  return { value: total, unit: '/10', tier, tierClass: total >= 7 ? 'tier-danger' : getTierClass(tier), footnote };
}

/**
 * Glasgow-Blatchford Score（上消化道出血）。bunMgDl 为 BUN mg/dL，hgbGdL 为 g/dL。
 */
export function calculateGbs(bunMgDl: number, hgbGdL: number, sex: string, sbp: number, hr: number, melena: boolean, syncope: boolean, liverDisease: boolean, heartFailure: boolean): CalcResult {
  if (bunMgDl <= 0 || hgbGdL <= 0 || sbp <= 0 || hr <= 0) {
    return emptyResult('');
  }
  let total = 0;
  const parts: string[] = [];
  let bunScore = 0;
  if (bunMgDl > 70) bunScore = 6; else if (bunMgDl >= 28.1) bunScore = 4; else if (bunMgDl >= 22.4) bunScore = 3; else if (bunMgDl >= 18.2) bunScore = 2;
  total += bunScore;
  parts.push(`BUN ${bunMgDl.toFixed(1)} mg/dL→${bunScore}`);

  let hgbScore = 0;
  if (sex === 'female') {
    if (hgbGdL < 10) hgbScore = 6; else if (hgbGdL < 12) hgbScore = 1;
  } else {
    if (hgbGdL < 10) hgbScore = 6; else if (hgbGdL < 12) hgbScore = 3; else if (hgbGdL < 13) hgbScore = 1;
  }
  total += hgbScore;
  parts.push(`Hgb ${hgbGdL.toFixed(1)} g/dL(${sex === 'female' ? '女' : '男'})→${hgbScore}`);

  let sbpScore = 0;
  if (sbp < 90) sbpScore = 3; else if (sbp < 100) sbpScore = 2; else if (sbp < 110) sbpScore = 1;
  total += sbpScore;
  parts.push(`SBP ${sbp}→${sbpScore}`);

  const hrScore = hr >= 100 ? 1 : 0;
  total += hrScore;
  parts.push(`HR ${hr}→${hrScore}`);

  if (melena) { total += 1; parts.push('黑便→1'); }
  if (syncope) { total += 2; parts.push('晕厥→2'); }
  if (liverDisease) { total += 2; parts.push('肝病→2'); }
  if (heartFailure) { total += 2; parts.push('心衰→2'); }

  let tier: string;
  let footnote: string;
  if (total === 0) {
    tier = '极低风险';
    footnote = '0 分，死亡/需干预风险极低，部分指南支持门诊处理。';
  } else if (total <= 6) {
    tier = '中风险';
    footnote = '1-6 分，通常需收住评估，内镜时机按出血活动性决定。';
  } else {
    tier = '高风险';
    footnote = '≥7 分，需积极复苏并尽早内镜干预。';
  }
  footnote += `\n\n${parts.join(' + ')} = ${total}/23\nGBS 用于上消化道出血风险分层，不用于下消化道出血；症状项未填按 0 分计。`;
  return { value: total, unit: '/23', tier, tierClass: total >= 7 ? 'tier-danger' : getTierClass(tier), footnote };
}

/**
 * BISAP（急性胰腺炎严重度床旁评分）。bunMgDl 为 BUN mg/dL。
 */
export function calculateBisap(bunMgDl: number, gcs: number, sirsCount: number, age: number, pleuralEffusion: boolean): CalcResult {
  if (bunMgDl <= 0 || age <= 0) {
    return emptyResult('');
  }
  let total = 0;
  const parts: string[] = [];
  if (bunMgDl > 25) { total += 1; parts.push('BUN>25✓'); } else { parts.push('BUN>25✗'); }
  if (gcs > 0 && gcs < 15) { total += 1; parts.push('意识障碍✓'); } else { parts.push('意识障碍✗'); }
  if (sirsCount >= 2) { total += 1; parts.push(`SIRS ${sirsCount}≥2✓`); } else { parts.push(`SIRS ${sirsCount}✗`); }
  if (age > 60) { total += 1; parts.push('年龄>60✓'); } else { parts.push('年龄>60✗'); }
  if (pleuralEffusion) { total += 1; parts.push('胸腔积液✓'); } else { parts.push('胸腔积液✗'); }

  let tier: string;
  let footnote: string;
  if (total >= 3) {
    tier = '高风险';
    footnote = '≥3 分，胰腺坏死/器官衰竭/死亡风险显著升高，建议 ICU 级监护。';
  } else if (total === 2) {
    tier = '中风险';
    footnote = '2 分，需密切监测容量、氧合和器官功能变化。';
  } else {
    tier = '低风险';
    footnote = '0-1 分，死亡风险较低，按常规胰腺炎管理并动态复查。';
  }
  footnote += `\n\n${parts.join('，')} → ${total}/5\nBISAP 用于急性胰腺炎 48h 内严重度分层，不替代 APACHE II/CT 严重度评估。`;
  return { value: total, unit: '/5', tier, tierClass: total >= 3 ? 'tier-danger' : getTierClass(tier), footnote };
}

/**
 * Ranson 评分：入院 5 项（glu 用 mmol/L，内部按 >11.1 mmol/L 判定）；48h 6 项手动补充。
 */
export function calculateRanson(age: number, wbc: number, gluMmol: number, ldh: number, ast: number, hctDropPct: number, bunRiseMgDl: number, caMmol: number, pao2: number, baseDeficit: number, fluidSeqL: number): CalcResult {
  if (age <= 0 || wbc <= 0 || gluMmol <= 0 || ldh <= 0 || ast <= 0) {
    return emptyResult('');
  }
  let admission = 0;
  const aParts: string[] = [];
  if (age > 55) { admission += 1; aParts.push('年龄>55✓'); } else { aParts.push('年龄>55✗'); }
  if (wbc > 16) { admission += 1; aParts.push('WBC>16✓'); } else { aParts.push('WBC>16✗'); }
  if (gluMmol > 11.1) { admission += 1; aParts.push('血糖>11.1✓'); } else { aParts.push('血糖>11.1✗'); }
  if (ldh > 350) { admission += 1; aParts.push('LDH>350✓'); } else { aParts.push('LDH>350✗'); }
  if (ast > 250) { admission += 1; aParts.push('AST>250✓'); } else { aParts.push('AST>250✗'); }

  let footnote = `入院 5 项：${aParts.join('，')} → ${admission}/5`;
  let total = admission;
  let has48h = false;
  const hParts: string[] = [];
  if (hctDropPct > 0) { has48h = true; if (hctDropPct > 10) { total += 1; hParts.push('Hct下降>10%✓'); } else { hParts.push('Hct下降✗'); } }
  if (bunRiseMgDl > 0) { has48h = true; if (bunRiseMgDl > 5) { total += 1; hParts.push('BUN上升>5✓'); } else { hParts.push('BUN上升✗'); } }
  if (caMmol > 0) { has48h = true; if (caMmol < 2) { total += 1; hParts.push('Ca<2.0✓'); } else { hParts.push('Ca✗'); } }
  if (pao2 > 0) { has48h = true; if (pao2 < 60) { total += 1; hParts.push('PaO2<60✓'); } else { hParts.push('PaO2✗'); } }
  if (baseDeficit > 0) { has48h = true; if (baseDeficit > 4) { total += 1; hParts.push('碱缺失>4✓'); } else { hParts.push('碱缺失✗'); } }
  if (fluidSeqL > 0) { has48h = true; if (fluidSeqL > 6) { total += 1; hParts.push('液体隔离>6L✓'); } else { hParts.push('液体隔离✗'); } }
  footnote += has48h ? `\n48h 项（已填部分）：${hParts.join('，')}` : '\n48h 项未填，总分仅为入院 5 项';

  let tier: string;
  if (total >= 3) {
    tier = '重症倾向';
    footnote += '\n\n≥3 分提示重症急性胰腺炎倾向，死亡率随分值升高，建议 ICU 评估。';
  } else {
    tier = '轻症倾向';
    footnote += '\n\n<3 分多为轻症，但 Ranson 需 48h 才完整，早期不能排除进展。';
  }
  footnote += '\nRanson 为 48h 完整评分，本工具支持入院项即时计算 + 48h 项手动补录。';
  return { value: total, unit: '/11', tier, tierClass: total >= 3 ? 'tier-danger' : getTierClass(tier), footnote };
}

/**
 * Cairo-Bishop 肿瘤溶解综合征分级。uricAcid μmol/L、phos/cr 用 SI 单位，crUlnRatio = 肌酐/ULN。
 */
export function calculateTls(uricAcidUmol: number, k: number, phosMmol: number, caMmol: number, crUlnRatio: number, arrhythmia: boolean, seizure: boolean): CalcResult {
  if (uricAcidUmol <= 0 || k <= 0 || phosMmol <= 0 || caMmol <= 0) {
    return emptyResult('');
  }
  const parts: string[] = [];
  let labCount = 0;
  if (uricAcidUmol >= 476) { labCount += 1; parts.push(`尿酸 ${uricAcidUmol}≥476✓`); } else { parts.push(`尿酸 ${uricAcidUmol}✗`); }
  if (k >= 6.0) { labCount += 1; parts.push(`K ${k}≥6.0✓`); } else { parts.push(`K ${k}✗`); }
  if (phosMmol >= 1.45) { labCount += 1; parts.push(`P ${phosMmol}≥1.45✓`); } else { parts.push(`P ${phosMmol}✗`); }
  if (caMmol <= 1.75) { labCount += 1; parts.push(`Ca ${caMmol}≤1.75✓`); } else { parts.push(`Ca ${caMmol}✗`); }

  const clinical: string[] = [];
  if (crUlnRatio > 1.5) clinical.push(`肌酐 ${crUlnRatio}×ULN>1.5`);
  if (arrhythmia) clinical.push('心律失常');
  if (seizure) clinical.push('抽搐');

  let tier: string;
  let footnote: string;
  if (labCount >= 2 && clinical.length > 0) {
    tier = '临床 TLS';
    footnote = '实验室 TLS + 临床器官表现（' + clinical.join('、') + '），按危急值处理：水化、降尿酸、纠正电解质并请肿瘤/肾内会诊。';
  } else if (labCount >= 2) {
    tier = '实验室 TLS';
    footnote = '≥2 项实验室异常满足 Cairo-Bishop 实验室 TLS 标准，需立即水化、降尿酸并监测尿量/心电图。';
  } else if (labCount === 1) {
    tier = '警惕';
    footnote = '仅 1 项异常，未达实验室 TLS 标准；化疗/溶瘤高危患者建议 8-12h 复查。';
  } else {
    tier = '不满足';
    footnote = '当前未达到实验室 TLS 标准。';
  }
  footnote += `\n\n${parts.join('，')} → ${labCount}/4 项`;
  if (clinical.length > 0) {
    footnote += `\n临床项：${clinical.join('、')}`;
  }
  footnote += '\nCairo-Bishop 标准：实验室 TLS 需 ≥2 项（尿酸≥476 μmol/L、K≥6.0、P≥1.45 mmol/L、Ca≤1.75 mmol/L，较基线变化 25% 亦计入，本工具按绝对值口径）；临床 TLS 需叠加肌酐≥1.5×ULN、心律失常或抽搐。';
  return { value: labCount, unit: '/4', tier, tierClass: tier === '临床 TLS' || tier === '实验室 TLS' ? 'tier-danger' : getTierClass(tier), footnote };
}

/**
 * Burch-Wartofsky 甲状腺危象评分。cns/gi/chf 直接传分值（cns 0/10/20/30，gi 0/10/20，chf 0/5/10/15）。
 */
export function calculateBwps(temp: number, hr: number, cns: number, gi: number, chf: number, afib: boolean, precipitant: boolean): CalcResult {
  if (temp <= 0 || hr <= 0) {
    return emptyResult('');
  }
  let tempScore = 0;
  if (temp >= 40) tempScore = 30; else if (temp >= 39.4) tempScore = 25; else if (temp >= 38.9) tempScore = 20; else if (temp >= 38.3) tempScore = 15; else if (temp >= 37.8) tempScore = 10; else if (temp >= 37.2) tempScore = 5;
  let hrScore = 0;
  if (hr >= 140) hrScore = 25; else if (hr >= 130) hrScore = 20; else if (hr >= 120) hrScore = 15; else if (hr >= 110) hrScore = 10; else if (hr >= 100) hrScore = 5;
  const total = tempScore + hrScore + cns + gi + chf + (afib ? 10 : 0) + (precipitant ? 10 : 0);

  let tier: string;
  let footnote: string;
  if (total >= 45) {
    tier = '高度提示甲状腺危象';
    footnote = '≥45 分，高度提示甲状腺危象，按危象处理（β阻滞剂、抗甲状腺药、碘剂、糖皮质激素、诱因处理）并收住 ICU。';
  } else if (total >= 25) {
    tier = '危象前期';
    footnote = '25-44 分，提示危象前期/即将发生，建议按甲状腺危象流程预处理并密切监护。';
  } else {
    tier = '不太支持';
    footnote = '<25 分，不太支持甲状腺危象，但不能排除早期或部分治疗后的病例。';
  }
  footnote += `\n\n体温 ${temp}°C→${tempScore}，HR ${hr}→${hrScore}，CNS ${cns}，GI ${gi}，CHF ${chf}，房颤 ${afib ? 10 : 0}，诱因 ${precipitant ? 10 : 0} → ${total} 分`;
  footnote += '\nBWPS 为临床评分，需结合 FT3/FT4/TSH；症状项未填按 0 分计可能低估。';
  return { value: total, unit: '', tier, tierClass: total >= 45 ? 'tier-danger' : getTierClass(tier), footnote };
}

/**
 * Wells DVT 深静脉血栓评分：9 项各 +1，替代诊断更可能 -2。
 */
export function calculateWellsDvt(activeCancer: boolean, immobilization: boolean, bedriddenSurgery: boolean, tenderness: boolean, legSwollen: boolean, calfDiff3cm: boolean, pittingEdema: boolean, collateralVeins: boolean, priorDvt: boolean, altDiagnosis: boolean): CalcResult {
  let total = 0;
  const items: boolean[] = [activeCancer, immobilization, bedriddenSurgery, tenderness, legSwollen, calfDiff3cm, pittingEdema, collateralVeins, priorDvt];
  const labels: string[] = ['活动性肿瘤', '下肢制动/石膏', '卧床>3天或12周内大手术', '深静脉走行压痛', '整条腿肿胀', '小腿周径差≥3cm', '凹陷性水肿（患侧）', '浅表侧支静脉', '既往DVT'];
  const parts: string[] = [];
  for (let i = 0; i < items.length; i++) {
    if (items[i]) { total += 1; parts.push(labels[i]); }
  }
  if (altDiagnosis) total -= 2;

  let tier: string;
  let footnote: string;
  if (total >= 3) {
    tier = '高概率';
    footnote = '≥3 分高概率（二分法：≥2 为 likely），建议直接加压超声，必要时抗凝桥接。';
  } else if (total >= 1) {
    tier = '中概率';
    footnote = '1-2 分中概率（二分法：≥2 为 likely），建议 D-二聚体或超声。';
  } else {
    tier = '低概率';
    footnote = '≤0 分低概率（unlikely），可先用 D-二聚体排除。';
  }
  footnote += parts.length > 0 ? `\n\n符合项：${parts.join('、')}` : '\n\n无符合项';
  footnote += (altDiagnosis ? '；替代诊断更可能 -2' : '') + ` → ${total} 分\nWells DVT 用于下肢 DVT 验前概率分层，与 Wells PE 不混用。`;
  return { value: total, unit: '', tier, tierClass: total >= 3 ? 'tier-danger' : getTierClass(tier), footnote };
}

/**
 * CPIS 临床肺部感染评分（VAP 辅助）。secretions 0/1/2，culture 0/1/2，cxr 0/1/2。
 * bandsAbs：杆状核粒细胞绝对计数 (cells/mm³)，≥500 时 WBC 项加至 2 分。
 * ards：合并 ARDS 时 P/F≤240 不加 2 分。
 */
export function calculateCpis(temp: number, wbc: number, bandsAbs: number, secretions: number, pfRatio: number, cxr: number, culture: number, ards: boolean): CalcResult {
  if (temp <= 0 || wbc <= 0 || secretions < 0 || cxr < 0 || culture < 0 || (pfRatio <= 0 && !ards)) {
    return emptyResult('');
  }
  let tempScore = 0;
  if (temp >= 39 || temp <= 36) tempScore = 2; else if (temp >= 38.5) tempScore = 1;
  let wbcScore = 0;
  if (wbc < 4 || wbc > 11) wbcScore = 1;
  if (wbcScore === 1 && bandsAbs >= 500) wbcScore = 2;
  const oxyScore = pfRatio > 0 && pfRatio <= 240 && !ards ? 2 : 0;
  const total = tempScore + wbcScore + secretions + oxyScore + cxr + culture;

  let tier: string;
  let footnote: string;
  if (total > 6) {
    tier = 'VAP 可能性高';
    footnote = '>6 分提示 VAP 可能性高，建议留取下呼吸道标本并评估抗菌方案。CPIS 为辅助工具，不能单独诊断 VAP。';
  } else {
    tier = '低分';
    footnote = '≤6 分 VAP 可能性较低，但免疫抑制/早期病例可假阴性，需结合影像与培养动态评估。';
  }
  footnote += `\n\n体温→${tempScore}，WBC→${wbcScore}，分泌物→${secretions}，氧合(P/F${pfRatio > 0 ? ' ' + pfRatio.toFixed(0) : ' 未填'}${ards ? '，ARDS' : ''})→${oxyScore}，胸片→${cxr}，培养→${culture} → ${total}/12`;
  footnote += '\nCPIS 原始版本用于 VAP 初筛；未填项按 0 分计可能低估，培养/胸片项建议手动补录。P/F≤240 且合并 ARDS 时氧合项不计分。';
  return { value: total, unit: '/12', tier, tierClass: total > 6 ? 'tier-danger' : getTierClass(tier), footnote };
}

/**
 * ANC 中性粒细胞绝对值 + MASCC 发热性中性粒细胞减少风险指数。
 * anc 直接传入优先；否则 wbc × neutPct/100 推算。MASCC 各项传分值。
 */
export function calculateAncMascc(anc: number, wbc: number, neutPct: number, masccBurden: number, noHypotension: boolean, noCopd: boolean, solidTumorNoFungal: boolean, noDehydration: boolean, outpatient: boolean, age: number): CalcResult {
  let ancVal = anc;
  let ancNote = '';
  if (ancVal <= 0 && wbc > 0 && neutPct > 0) {
    ancVal = wbc * neutPct / 100;
    ancNote = `ANC = WBC ${wbc} × 中性粒 ${neutPct}% = ${ancVal.toFixed(2)}`;
  } else if (ancVal > 0) {
    ancNote = `ANC 直接录入 ${ancVal.toFixed(2)}`;
  }
  if (ancVal <= 0) {
    return emptyResult('×10⁹/L');
  }

  let ancTier: string;
  let ancNote2: string;
  if (ancVal < 0.5) {
    ancTier = '重度粒缺';
    ancNote2 = 'ANC <0.5 ×10⁹/L，重度中性粒细胞减少，发热即按粒缺发热处理。';
  } else if (ancVal < 1.0) {
    ancTier = '中度粒缺';
    ancNote2 = 'ANC 0.5-1.0 ×10⁹/L，中度减少。';
  } else if (ancVal < 1.5) {
    ancTier = '轻度粒缺';
    ancNote2 = 'ANC 1.0-1.5 ×10⁹/L，轻度减少。';
  } else {
    ancTier = '正常';
    ancNote2 = 'ANC ≥1.5 ×10⁹/L，无粒细胞减少。';
  }

  let footnote = `${ancNote} ×10⁹/L\n${ancNote2}`;
  let value = ancVal;
  let unit = '×10⁹/L';
  let tier = ancTier;

  if (masccBurden > 0) {
    let mascc = masccBurden;
    const parts: string[] = [`疾病负担 ${masccBurden}`];
    if (noHypotension) { mascc += 5; parts.push('无低血压 5'); }
    if (noCopd) { mascc += 4; parts.push('无COPD 4'); }
    if (solidTumorNoFungal) { mascc += 4; parts.push('实体瘤或无真菌感染 4'); }
    if (noDehydration) { mascc += 3; parts.push('无脱水 3'); }
    if (outpatient) { mascc += 3; parts.push('门诊状态 3'); }
    if (age > 0 && age < 60) { mascc += 2; parts.push('年龄<60 2'); }
    footnote += `\n\nMASCC：${parts.join(' + ')} = ${mascc}/26`;
    footnote += mascc >= 21 ? '\n≥21 分低危，符合条件者可考虑口服/门诊抗菌。' : '\n<21 分高危，需住院静脉抗菌。';
    footnote += '\nMASCC 仅用于发热性中性粒细胞减少患者分层。';
  } else {
    footnote += '\n\nMASCC 未填写；如需粒缺发热风险分层请补录 MASCC 项。';
  }
  return { value, unit, tier, tierClass: ancVal < 0.5 ? 'tier-danger' : getTierClass(tier), footnote };
}
