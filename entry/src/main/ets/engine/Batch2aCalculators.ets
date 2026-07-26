import { CalcResult, getTierClass } from './CalcEngine';

function emptyResult(unit: string): CalcResult {
  return { value: null, unit, tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
}

/**
 * ADHERE 急性心衰住院死亡风险树：BUN≥43 mg/dL、SBP<115、Cr≥2.75 mg/dL 三个高危因子。
 * bunMgDl / crMgDl 均为 mg/dL（调用方负责换算）。
 */
export function calculateAdhere(bunMgDl: number, sbp: number, crMgDl: number): CalcResult {
  if (bunMgDl <= 0 || sbp <= 0 || crMgDl <= 0) {
    return emptyResult('');
  }
  const bunHigh = bunMgDl >= 43;
  const sbpLow = sbp < 115;
  const crHigh = crMgDl >= 2.75;
  const rf = (bunHigh ? 1 : 0) + (sbpLow ? 1 : 0) + (crHigh ? 1 : 0);

  let tier: string;
  let mort: string;
  if (rf === 0) {
    tier = '低危';
    mort = '约 2%';
  } else if (rf === 1) {
    tier = '中危';
    mort = '约 6%';
  } else if (rf === 2) {
    tier = '高危';
    mort = '约 13%';
  } else {
    tier = '极高危';
    mort = '约 20-40%';
  }
  const footnote = `高危因子：BUN ${bunMgDl.toFixed(1)} mg/dL ${bunHigh ? '≥43 ✓' : '<43 ✗'}；SBP ${sbp} mmHg ${sbpLow ? '<115 ✓' : '≥115 ✗'}；Cr ${crMgDl.toFixed(2)} mg/dL ${crHigh ? '≥2.75 ✓' : '<2.75 ✗'}。\nADHERE 风险树住院死亡率估计：0 因子≈2%，1 因子≈6%，2 因子≈13%，3 因子≈20-40%。\n用于急性失代偿心衰住院死亡风险粗分层，不替代完整临床评估。`;
  return { value: rf, unit: '/3 因子', tier: `${tier}（住院死亡率 ${mort}）`, tierClass: rf >= 2 ? 'tier-danger' : getTierClass(tier), footnote };
}

/**
 * STESS 癫痫持续状态严重度评分（0-6）。
 * consciousness: 0=清醒/嗜睡模糊，1=木僵/昏迷；seizureType: 0=非全面强直阵挛，1=全面强直阵挛，2=昏迷中NCSE。
 */
export function calculateStess(consciousness: number, seizureType: number, age: number, priorSeizures: boolean): CalcResult {
  if (age <= 0) {
    return emptyResult('');
  }
  const c = consciousness >= 1 ? 1 : 0;
  const t = seizureType < 0 ? 0 : seizureType > 2 ? 2 : Math.round(seizureType);
  const a = age >= 65 ? 2 : 0;
  const p = priorSeizures ? 0 : 1;
  const total = c + t + a + p;

  let tier: string;
  let footnote: string;
  if (total <= 2) {
    tier = '低死亡风险';
    footnote = '0-2 分，院内死亡风险低，预后相对好。';
  } else if (total <= 4) {
    tier = '中风险';
    footnote = '3-4 分，死亡风险升高，建议 ICU 监护并积极终止发作。';
  } else {
    tier = '高死亡风险';
    footnote = '5-6 分，死亡风险高，按难治性癫痫持续状态流程处理。';
  }
  footnote += `\n\n意识 ${c} + 发作类型 ${t} + 年龄≥65 ${a} + 无癫痫史 ${p} = ${total}/6\nSTESS 用于癫痫持续状态预后分层，不指导是否终止发作——任何持续发作均应按流程及时处理。`;
  return { value: total, unit: '/6', tier, tierClass: total >= 5 ? 'tier-danger' : getTierClass(tier), footnote };
}

/**
 * McMahon 横纹肌溶解 RRT/死亡风险评分。
 * crUmol μmol/L、phosMmol/calMmol SI 单位，内部换算 mg/dL。
 */
export function calculateMcmahon(age: number, sex: string, ck: number, crUmol: number, phosMmol: number, caMmol: number, hco3: number, lowRiskEtiology: boolean): CalcResult {
  if (age <= 0 || ck <= 0 || crUmol <= 0) {
    return emptyResult('');
  }
  const crMgDl = crUmol / 88.4;
  const phosMgDl = phosMmol * 3.1;
  const caMgDl = caMmol * 4;

  let score = 0;
  const parts: string[] = [];
  let agePts = 0;
  if (age > 80) agePts = 3; else if (age > 70) agePts = 2.5; else if (age > 50) agePts = 1.5;
  score += agePts;
  parts.push(`年龄 ${age}→${agePts}`);
  if (sex === 'female') { score += 1; parts.push('女性→1'); }
  let crPts = 0;
  if (crMgDl > 2.2) crPts = 3; else if (crMgDl >= 1.5) crPts = 1.5;
  score += crPts;
  parts.push(`Cr ${crMgDl.toFixed(2)} mg/dL→${crPts}`);
  if (ck > 40000) { score += 2; parts.push('CK>40000→2'); } else { parts.push(`CK ${ck}→0`); }
  let phosPts = 0;
  if (phosMmol > 0) {
    if (phosMgDl > 5.4) phosPts = 3; else if (phosMgDl >= 4) phosPts = 1.5;
    score += phosPts;
    parts.push(`P ${phosMgDl.toFixed(1)} mg/dL→${phosPts}`);
  }
  if (hco3 > 0 && hco3 < 19) { score += 2; parts.push(`HCO₃ ${hco3}<19→2`); }
  if (caMmol > 0 && caMgDl <= 7.5) { score += 2; parts.push(`Ca ${caMgDl.toFixed(1)}≤7.5→2`); }
  if (!lowRiskEtiology) { score += 3; parts.push('非低危病因→3'); } else { parts.push('低危病因→0'); }

  let tier: string;
  let footnote: string;
  if (score < 5) {
    tier = '低危';
    footnote = '<5 分，RRT/死亡风险约 3%。';
  } else if (score <= 10) {
    tier = '中危';
    footnote = '5-10 分，RRT/死亡风险约 8%，需积极水化并监测肾功能/电解质。';
  } else {
    tier = '高危';
    footnote = '>10 分，RRT/死亡风险 >20%，建议 ICU 级监护并早期肾脏替代评估。';
  }
  footnote += `\n\n${parts.join('，')} → ${score} 分\n低危病因=癫痫发作/晕厥/运动/他汀/肌炎；其余病因（挤压、缺血、中毒等）计 3 分。McMahon 为入院时风险预测，不指导具体补液方案。`;
  return { value: score, unit: '', tier, tierClass: score > 10 ? 'tier-danger' : getTierClass(tier), footnote };
}

/**
 * ISTH 显性 DIC 评分。ddimerGrade 0/2/3（无/中度/重度升高），ptProlong 0/1/2（<3s/3-6s/>6s）。
 */
export function calculateIsth(platelet: number, ddimerGrade: number, ptProlong: number, fib: number): CalcResult {
  if (platelet <= 0 || fib <= 0) {
    return emptyResult('');
  }
  let pltPts = 0;
  if (platelet < 50) pltPts = 2; else if (platelet <= 100) pltPts = 1;
  const dPts = ddimerGrade < 0 ? 0 : ddimerGrade > 3 ? 3 : Math.round(ddimerGrade);
  const ptPts = ptProlong < 0 ? 0 : ptProlong > 2 ? 2 : Math.round(ptProlong);
  const fibPts = fib < 1.0 ? 1 : 0;
  const total = pltPts + dPts + ptPts + fibPts;

  let tier: string;
  let footnote: string;
  if (total >= 5) {
    tier = '符合显性 DIC';
    footnote = '≥5 分，符合 ISTH 显性 DIC 标准，需处理原发病并按出血/血栓倾向支持治疗（血小板、纤维蛋白原、抗凝权衡）。';
  } else {
    tier = '未达显性 DIC';
    footnote = '<5 分，未达显性 DIC；疑诊者 1-2 天复查并考虑非显性 DIC 评分。';
  }
  footnote += `\n\n血小板 ${platelet}→${pltPts}，纤溶标志物→${dPts}，PT延长→${ptPts}，纤维蛋白原 ${fib} g/L→${fibPts} → ${total}/8\n前提是存在已知与 DIC 相关的基础疾病；D-二聚体中度/重度升高的界值各实验室不同，本工具按所选/换算档位计分。`;
  return { value: total, unit: '/8', tier, tierClass: total >= 5 ? 'tier-danger' : getTierClass(tier), footnote };
}

/**
 * PLASMIC TTP（ADAMTS13 重度缺乏）风险评分，7 项各 1 分。
 */
export function calculatePlasmic(platelet: number, hemolysisEvidence: boolean, activeCancer: boolean, transplant: boolean, mcv: number, inr: number, crMgDl: number): CalcResult {
  if (platelet <= 0 || mcv <= 0 || inr <= 0 || crMgDl <= 0) {
    return emptyResult('');
  }
  let total = 0;
  const parts: string[] = [];
  if (platelet < 30) { total += 1; parts.push('PLT<30✓'); } else { parts.push('PLT<30✗'); }
  if (hemolysisEvidence) { total += 1; parts.push('溶血证据✓'); } else { parts.push('溶血证据✗'); }
  if (!activeCancer) { total += 1; parts.push('无活动性肿瘤✓'); } else { parts.push('无活动性肿瘤✗'); }
  if (!transplant) { total += 1; parts.push('无移植史✓'); } else { parts.push('无移植史✗'); }
  if (mcv < 90) { total += 1; parts.push('MCV<90✓'); } else { parts.push('MCV<90✗'); }
  if (inr < 1.5) { total += 1; parts.push('INR<1.5✓'); } else { parts.push('INR<1.5✗'); }
  if (crMgDl < 2.0) { total += 1; parts.push('Cr<2.0✓'); } else { parts.push('Cr<2.0✗'); }

  let tier: string;
  let footnote: string;
  if (total >= 6) {
    tier = '高风险';
    footnote = '6-7 分，ADAMTS13 重度缺乏可能性高（约 62-82%），疑似 TTP：立即血浆置换并查 ADAMTS13 活性，勿输血小板（除非致命出血）。';
  } else if (total === 5) {
    tier = '中风险';
    footnote = '5 分，中风险（约 12%），建议尽快查 ADAMTS13 并请血液会诊。';
  } else {
    tier = '低风险';
    footnote = '0-4 分，低风险（约 0-4%），但仍需结合临床鉴别 DIC/HUS/HELLP/灾难性 APS。';
  }
  footnote += `\n\n${parts.join('，')} → ${total}/7\nPLASMIC 用于成人血小板减少+微血管病性溶血时预测 ADAMTS13 缺乏，不替代 ADAMTS13 活性检测；溶血证据=网织红>2.5%/结合珠蛋白测不出/间接胆红素>2 mg/dL。`;
  return { value: total, unit: '/7', tier, tierClass: total >= 6 ? 'tier-danger' : getTierClass(tier), footnote };
}

/**
 * VIS 血管活性-正性肌力评分。剂量单位：μg/kg/min（vasopressin 为 U/kg/min）。
 */
export function calculateVis(dopamine: number, dobutamine: number, epinephrine: number, norepinephrine: number, milrinone: number, vasopressin: number): CalcResult {
  const any = dopamine > 0 || dobutamine > 0 || epinephrine > 0 || norepinephrine > 0 || milrinone > 0 || vasopressin > 0;
  if (!any) {
    return emptyResult('');
  }
  const vis = dopamine + dobutamine + 100 * epinephrine + 100 * norepinephrine + 10 * milrinone + 10000 * vasopressin;

  let tier: string;
  let footnote: string;
  if (vis > 20) {
    tier = '高剂量支持';
    footnote = 'VIS >20，血管活性药物负荷高，文献中与不良结局相关，建议评估容量/心功能/机械辅助指征。';
  } else if (vis > 10) {
    tier = '中等支持';
    footnote = 'VIS 11-20，中等血管活性支持，动态监测灌注指标。';
  } else {
    tier = '低剂量支持';
    footnote = 'VIS ≤10，低剂量支持。';
  }
  footnote += `\n\nVIS = 多巴胺 ${dopamine} + 多巴酚丁胺 ${dobutamine} + 100×肾上腺素 ${epinephrine} + 100×去甲肾上腺素 ${norepinephrine} + 10×米力农 ${milrinone} + 10000×血管加压素 ${vasopressin} = ${vis.toFixed(1)}`;
  footnote += '\n剂量单位 μg/kg/min（血管加压素 U/kg/min）。VIS 为药物负荷量化指标，非独立预后评分。';
  return { value: vis, unit: '', tier, tierClass: vis > 20 ? 'tier-danger' : getTierClass(tier), footnote };
}

/**
 * 乳酸清除率：(lac0 - lac1) / lac0 × 100%。
 */
export function calculateLactateClearance(lac0: number, lac1: number, hours: number): CalcResult {
  if (lac0 <= 0 || lac1 < 0) {
    return emptyResult('%');
  }
  const clearance = (lac0 - lac1) / lac0 * 100;

  let tier: string;
  let footnote: string;
  if (clearance >= 10) {
    tier = '清除良好';
    footnote = '≥10%，与脓毒症/休克复苏较好的结局相关，继续当前治疗并动态监测。';
  } else if (clearance >= 0) {
    tier = '清除不足';
    footnote = '<10%，乳酸清除不足，需重新评估灌注、感染源控制、容量和心功能。';
  } else {
    tier = '乳酸上升';
    footnote = '复查乳酸高于初始值，提示灌注恶化或持续产生，按恶化处理。';
  }
  const hoursNote = hours > 0 ? `，间隔 ${hours} h` : '';
  footnote += `\n\n清除率 = (${lac0} - ${lac1}) / ${lac0} × 100% = ${clearance.toFixed(1)}%${hoursNote}\n常用界值 10%（6h）；需同一检测体系、注明采血部位（动脉/静脉）。`;
  return { value: clearance, unit: '%', tier, tierClass: getTierClass(tier), footnote };
}

/**
 * ABC/2 脑出血体积：A×B×C/2，C 可直接填出血头尾径（cm）。
 */
export function calculateAbc2(a: number, b: number, c: number): CalcResult {
  if (a <= 0 || b <= 0 || c <= 0) {
    return emptyResult('mL');
  }
  const vol = a * b * c / 2;

  let tier: string;
  let footnote: string;
  if (vol > 60) {
    tier = '大量出血';
    footnote = '>60 mL，死亡/不良预后风险高，常需神经外科评估手术指征。';
  } else if (vol >= 30) {
    tier = '中量出血';
    footnote = '30-60 mL，需密切监测血肿扩大与颅高压。';
  } else {
    tier = '小量出血';
    footnote = '<30 mL，相对小量，仍需按部位和病因管理。';
  }
  footnote += `\n\n体积 = A×B×C/2 = ${a}×${b}×${c}/2 = ${vol.toFixed(1)} mL\nA=血肿最大直径，B=同层垂直直径，C=头尾径（层面数×层厚，cm）。ABC/2 为近似椭球估计，不规则血肿误差较大。`;
  return { value: vol, unit: 'mL', tier, tierClass: vol > 60 ? 'tier-danger' : getTierClass(tier), footnote };
}

/**
 * 年龄校正 D-二聚体：年龄>50 时 FEU 阈值 = 年龄×10 ng/mL（= 年龄/100 mg/L）。
 */
export function calculateAgeAdjustedDdimer(age: number, ddimerMgL: number): CalcResult {
  if (age <= 0 || ddimerMgL < 0) {
    return emptyResult('mg/L FEU');
  }
  const threshold = age >= 50 ? age / 100 : 0.5;
  const below = ddimerMgL < threshold;

  let tier: string;
  let footnote: string;
  if (below) {
    tier = '低于校正阈值';
    footnote = 'D-二聚体低于（年龄校正）阈值；在低/中验前概率下可帮助排除 VTE。';
  } else {
    tier = '高于校正阈值';
    footnote = 'D-二聚体高于（年龄校正）阈值，不能排除 VTE，按验前概率决定影像检查。';
  }
  footnote += `\n\n阈值 = ${age >= 50 ? `年龄×10 ng/mL = ${(threshold * 1000).toFixed(0)} ng/mL FEU` : '0.5 mg/L FEU（年龄<50 用常规阈值）'}；实测 ${ddimerMgL} mg/L FEU`;
  footnote += '\n仅适用于 D-二聚体 FEU 单位且验前概率低/中的患者；妊娠、肿瘤、近期手术/感染时解释需谨慎。';
  return { value: threshold, unit: 'mg/L FEU', tier, tierClass: below ? 'tier-ok' : 'tier-warn', footnote };
}

/**
 * ADD-RS 主动脉夹层检出风险评分：三类高危特征各 1 分；可选结合 D-二聚体。
 */
export function calculateAddrs(condition: boolean, pain: boolean, exam: boolean, ddimerMgL: number): CalcResult {
  const total = (condition ? 1 : 0) + (pain ? 1 : 0) + (exam ? 1 : 0);

  let tier: string;
  let footnote: string;
  if (total === 0) {
    tier = '低风险';
    footnote = '0 分，主动脉夹层验前概率低（<0.5%）。';
  } else if (total === 1) {
    tier = '中风险';
    footnote = '1 分，中风险，可结合 D-二聚体决定影像。';
  } else {
    tier = '高风险';
    footnote = '≥2 分，高风险，建议直接急诊 CTA/经食道超声。';
  }
  footnote += `\n\n高危基础/病史${condition ? '✓' : '✗'} + 高危疼痛特征${pain ? '✓' : '✗'} + 高危查体${exam ? '✓' : '✗'} → ${total}/3`;
  if (ddimerMgL > 0) {
    footnote += `\nD-二聚体 ${ddimerMgL} mg/L FEU：${ddimerMgL < 0.5 ? '<0.5，ADD-RS 0-1 分时支持排除策略（需指南流程确认）' : '≥0.5，不支持排除，按影像路径'}`;
  }
  footnote += '\n高危基础=马凡/结缔组织病、主动脉病家族史、已知主动脉瓣病/胸主动脉瘤、近期主动脉操作；高危疼痛=突发/剧烈/撕裂样；高危查体=灌注缺损（脉搏差/血压差/局灶神经）、舒张期杂音、低血压休克。\nADD-RS 为规则纳入/排除辅助，不单独确诊或排除夹层。';
  return { value: total, unit: '/3', tier, tierClass: total >= 2 ? 'tier-danger' : getTierClass(tier), footnote };
}
