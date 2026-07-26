import { CalcResult, getTierClass } from './CalcEngine';

function emptyResult(unit: string): CalcResult {
  return { value: null, unit, tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
}

/**
 * Parkland 烧伤补液公式：4 mL × kg × %TBSA，前 8h 输一半（自受伤时刻起算）。
 */
export function calculateParkland(weight: number, tbsa: number): CalcResult {
  if (weight <= 0 || tbsa <= 0) {
    return emptyResult('mL');
  }
  const total = 4 * weight * tbsa;
  const first8 = total / 2;
  const rate8 = first8 / 8;
  const rate16 = first8 / 16;

  let tier: string;
  if (tbsa >= 20) {
    tier = '大面积烧伤';
  } else if (tbsa >= 10) {
    tier = '中等面积';
  } else {
    tier = '小面积';
  }
  const footnote = `总量 = 4 mL × ${weight} kg × ${tbsa}% = ${total.toFixed(0)} mL 乳酸林格液\n前 8h（自受伤时刻起算，非入院时刻）：${first8.toFixed(0)} mL，约 ${rate8.toFixed(0)} mL/h\n随后 16h：${first8.toFixed(0)} mL，约 ${rate16.toFixed(0)} mL/h\n\nParkland 为起始估计，必须按尿量滴定（成人目标 ≥0.5 mL/kg/h）；吸入伤、电烧伤、儿童需上调。TBSA 估法：九分法（头颈9%、每上肢9%、躯干前后各18%、每下肢18%、会阴1%）。`;
  return { value: total, unit: 'mL/24h', tier, tierClass: tbsa >= 20 ? 'tier-danger' : getTierClass(tier), footnote };
}

/**
 * QTc 校正：Bazett 主显示，Fridericia/Framingham/Hodges 见脚注。
 */
export function calculateQtc(qtMs: number, hr: number): CalcResult {
  if (qtMs <= 0 || hr <= 0) {
    return emptyResult('ms');
  }
  const rr = 60 / hr;
  const bazett = qtMs / Math.sqrt(rr);
  const fridericia = qtMs / Math.cbrt(rr);
  const framingham = qtMs + 154 * (1 - rr);
  const hodges = qtMs + 1.75 * (hr - 60);

  let tier: string;
  let footnote: string;
  if (bazett >= 500) {
    tier = '显著延长';
    footnote = 'QTc ≥500 ms，尖端扭转型室速风险显著升高：停用延长 QT 药物、纠正电解质（K/Mg）、心电监护。';
  } else if (bazett > 450) {
    tier = '延长';
    footnote = 'QTc >450 ms（男性界值；女性常用 >470），提示延长，核查药物与电解质。';
  } else {
    tier = '正常范围';
    footnote = 'QTc ≤450 ms，大致正常（女性 >470 才计延长）。';
  }
  footnote += `\n\nBazett = QT/√RR = ${qtMs}/√${rr.toFixed(2)} = ${bazett.toFixed(0)} ms（HR ${hr}）\n其他公式：Fridericia ${fridericia.toFixed(0)} ms，Framingham ${framingham.toFixed(0)} ms，Hodges ${hodges.toFixed(0)} ms\nBazett 在心率过快/过慢时误差大，心率<60 或>100 建议参考 Fridericia/Framingham。`;
  return { value: bazett, unit: 'ms', tier, tierClass: bazett >= 500 ? 'tier-danger' : getTierClass(tier), footnote };
}

/**
 * Alvarado 阑尾炎评分（MANTRELS）。neutPct>75 计左移。
 */
export function calculateAlvarado(temp: number, wbc: number, neutPct: number, migratory: boolean, anorexia: boolean, nauseaVomit: boolean, rlqTender: boolean, rebound: boolean): CalcResult {
  if (temp <= 0 || wbc <= 0) {
    return emptyResult('');
  }
  let total = 0;
  const parts: string[] = [];
  if (migratory) { total += 1; parts.push('转移性右下腹痛1'); }
  if (anorexia) { total += 1; parts.push('厌食1'); }
  if (nauseaVomit) { total += 1; parts.push('恶心呕吐1'); }
  if (rlqTender) { total += 2; parts.push('右下腹压痛2'); }
  if (rebound) { total += 1; parts.push('反跳痛1'); }
  if (temp >= 37.3) { total += 1; parts.push('发热1'); }
  if (wbc > 10) { total += 2; parts.push('WBC>10✓2'); } else { parts.push('WBC>10✗'); }
  if (neutPct > 75) { total += 1; parts.push('左移1'); }

  let tier: string;
  let footnote: string;
  if (total >= 7) {
    tier = '高概率';
    footnote = '7-10 分，阑尾炎可能性大，建议外科会诊并考虑手术。';
  } else if (total >= 5) {
    tier = '中间区';
    footnote = '5-6 分，不能确定，建议腹部 CT/超声或留观复查。';
  } else {
    tier = '低概率';
    footnote = '0-4 分，阑尾炎可能性低，寻找其他诊断。';
  }
  footnote += `\n\n${parts.length > 0 ? parts.join('，') : '无符合项'} → ${total}/10\nAlvarado 用于成人急腹症筛查；儿童与妊娠解释需谨慎，必要时配合超声/CT。`;
  return { value: total, unit: '/10', tier, tierClass: total >= 7 ? 'tier-danger' : getTierClass(tier), footnote };
}

/**
 * RIPASA 阑尾炎评分（亚洲人群优化，去 Foreign NRIC 项）。
 */
export function calculateRipasa(age: number, sex: string, rlqPain: boolean, migratory: boolean, anorexia: boolean, nauseaVomit: boolean, durLt48h: boolean, rlqTender: boolean, guarding: boolean, rebound: boolean, rovsing: boolean, temp: number, wbc: number, urineNeg: boolean): CalcResult {
  if (age <= 0 || temp <= 0 || wbc <= 0) {
    return emptyResult('');
  }
  let total = 0;
  const parts: string[] = [];
  if (sex === 'male') { total += 1; parts.push('男性1'); }
  if (age < 40) { total += 1; parts.push('年龄<40✓1'); } else { parts.push('年龄<40✗'); }
  if (rlqPain) { total += 0.5; parts.push('右下腹痛0.5'); }
  if (migratory) { total += 0.5; parts.push('转移痛0.5'); }
  if (anorexia) { total += 1; parts.push('厌食1'); }
  if (nauseaVomit) { total += 1; parts.push('恶心呕吐1'); }
  if (durLt48h) { total += 1; parts.push('病程<48h1'); }
  if (rlqTender) { total += 1; parts.push('右下腹压痛1'); }
  if (guarding) { total += 2; parts.push('肌紧张2'); }
  if (rebound) { total += 1; parts.push('反跳痛1'); }
  if (rovsing) { total += 2; parts.push('Rovsing征2'); }
  if (temp >= 37.5) { total += 1; parts.push('发热1'); }
  if (wbc > 10) { total += 1; parts.push('WBC升高✓1'); } else { parts.push('WBC升高✗'); }
  if (urineNeg) { total += 1; parts.push('尿检阴性1'); }

  let tier: string;
  let footnote: string;
  if (total > 12) {
    tier = '高概率';
    footnote = '>12 分，阑尾炎高概率，外科会诊。';
  } else if (total >= 8) {
    tier = '中间区';
    footnote = '8-12 分，中概率，建议影像或留观。';
  } else if (total >= 5) {
    tier = '低概率';
    footnote = '5-7.5 分，低概率，结合影像。';
  } else {
    tier = '不太可能';
    footnote = '<5 分，阑尾炎不太可能。';
  }
  footnote += `\n\n${parts.length > 0 ? parts.join('，') : '无符合项'} → ${total.toFixed(1)}/15.5\nRIPASA 在亚洲人群验证优于 Alvarado；本实现不含新加坡 Foreign NRIC 项（满分 15.5）。`;
  return { value: total, unit: '/15.5', tier, tierClass: total > 12 ? 'tier-danger' : getTierClass(tier), footnote };
}

/**
 * CSF 脑脊液解读：细菌性 vs 病毒性倾向核对。protein g/L，glu 均 mmol/L。
 */
export function calculateCsf(csfWbc: number, csfNeutPct: number, csfProtein: number, csfGlu: number, serumGlu: number, csfRbc: number): CalcResult {
  if (csfWbc <= 0) {
    return emptyResult('');
  }
  let correctedWbc = csfWbc;
  let traumaNote = '';
  if (csfRbc > 1000) {
    correctedWbc = Math.max(0, csfWbc - csfRbc / 700);
    traumaNote = `（损伤性穿刺校正：${csfWbc} - ${csfRbc}/700 ≈ ${correctedWbc.toFixed(0)}）`;
  }

  let bactCount = 0;
  const parts: string[] = [];
  if (correctedWbc >= 1000) { bactCount += 1; parts.push('WBC≥1000✓'); } else { parts.push(`WBC ${correctedWbc.toFixed(0)}${correctedWbc >= 500 ? '（偏高）' : ''}`); }
  if (csfNeutPct >= 80) { bactCount += 1; parts.push('中性粒≥80%✓'); } else if (csfNeutPct > 0) { parts.push(`中性粒 ${csfNeutPct}%`); }
  if (csfProtein >= 1.5) { bactCount += 1; parts.push('蛋白≥1.5 g/L✓'); } else if (csfProtein > 0) { parts.push(`蛋白 ${csfProtein} g/L`); }
  let ratio = 0;
  if (csfGlu > 0 && serumGlu > 0) {
    ratio = csfGlu / serumGlu;
    if (ratio < 0.4) { bactCount += 1; parts.push(`糖比值 ${ratio.toFixed(2)}<0.4✓`); } else { parts.push(`糖比值 ${ratio.toFixed(2)}`); }
  }

  let tier: string;
  let footnote: string;
  if (bactCount >= 2) {
    tier = '支持细菌性';
    footnote = '≥2 项细菌性特征，高度警惕细菌性脑膜炎：立即血培养+经验性抗菌（勿因腰穿延误），查革兰染色/培养/PCR。';
  } else if (bactCount === 1) {
    tier = '不典型';
    footnote = '1 项细菌性特征，不典型：病毒性、部分治疗后细菌性、结核/真菌均需考虑，结合临床与病原学。';
  } else {
    tier = '倾向病毒性/非细菌性';
    footnote = '无明确细菌性特征，倾向病毒性或非感染；淋巴细胞为主支持病毒性，但早期细菌性可类似。';
  }
  footnote += `\n\n${parts.join('，')} → 细菌性特征 ${bactCount}/4${traumaNote}\n本工具为模式核对，不能单独诊断脑膜炎；免疫抑制、新生儿、部分治疗病例不典型，最终依赖培养/PCR 与临床。`;
  return { value: bactCount, unit: '/4', tier, tierClass: bactCount >= 2 ? 'tier-danger' : getTierClass(tier), footnote };
}

/**
 * Padua 住院患者 VTE 风险评分，≥4 分高危。
 */
export function calculatePadua(age: number, cancer: boolean, prevVte: boolean, immobility: boolean, thrombophilia: boolean, traumaSurg: boolean, hfRespFail: boolean, miStroke: boolean, infection: boolean, bmi: number, hormoneRx: boolean): CalcResult {
  if (age <= 0) {
    return emptyResult('');
  }
  let total = 0;
  const parts: string[] = [];
  if (cancer) { total += 3; parts.push('活动性肿瘤3'); }
  if (prevVte) { total += 3; parts.push('既往VTE3'); }
  if (immobility) { total += 3; parts.push('制动≥3天3'); }
  if (thrombophilia) { total += 3; parts.push('易栓症3'); }
  if (traumaSurg) { total += 2; parts.push('近期创伤/手术2'); }
  if (age >= 70) { total += 1; parts.push('年龄≥70✓1'); } else { parts.push('年龄≥70✗'); }
  if (hfRespFail) { total += 1; parts.push('心衰/呼衰1'); }
  if (miStroke) { total += 1; parts.push('急性心梗/卒中1'); }
  if (infection) { total += 1; parts.push('急性感染/风湿1'); }
  if (bmi >= 30) { total += 1; parts.push('BMI≥30✓1'); } else { parts.push('BMI≥30✗'); }
  if (hormoneRx) { total += 1; parts.push('激素治疗1'); }

  let tier: string;
  let footnote: string;
  if (total >= 4) {
    tier = '高危';
    footnote = '≥4 分，VTE 高危：无禁忌时建议药物预防（LMWH/磺达肝癸钠），出血高危者机械预防。';
  } else {
    tier = '低危';
    footnote = '<4 分，低危：早期活动即可，不建议常规药物预防。';
  }
  footnote += `\n\n${parts.length > 0 ? parts.join('，') : '无符合项'} → ${total} 分\nPadua 用于内科住院患者 VTE 风险评估，预防决策需结合出血风险（可配合 IMPROVE 出血评估）。`;
  return { value: total, unit: '', tier, tierClass: total >= 4 ? 'tier-danger' : getTierClass(tier), footnote };
}

/**
 * MME 口服吗啡当量换算（CDC 2022 转换因子）。fentanylPatch 单位 mcg/hr。
 */
export function calculateMme(morphine: number, oxycodone: number, hydrocodone: number, hydromorphone: number, tramadol: number, fentanylPatch: number): CalcResult {
  const any = morphine > 0 || oxycodone > 0 || hydrocodone > 0 || hydromorphone > 0 || tramadol > 0 || fentanylPatch > 0;
  if (!any) {
    return emptyResult('MME/日');
  }
  const parts: string[] = [];
  let total = 0;
  if (morphine > 0) { total += morphine; parts.push(`吗啡 ${morphine}×1`); }
  if (oxycodone > 0) { total += oxycodone * 1.5; parts.push(`羟考酮 ${oxycodone}×1.5`); }
  if (hydrocodone > 0) { total += hydrocodone; parts.push(`氢可酮 ${hydrocodone}×1`); }
  if (hydromorphone > 0) { total += hydromorphone * 5; parts.push(`氢吗啡酮 ${hydromorphone}×5`); }
  if (tramadol > 0) { total += tramadol * 0.2; parts.push(`曲马多 ${tramadol}×0.2`); }
  if (fentanylPatch > 0) { total += fentanylPatch * 2.4; parts.push(`芬太尼贴剂 ${fentanylPatch} mcg/hr×2.4`); }

  let tier: string;
  let footnote: string;
  if (total >= 90) {
    tier = '高剂量';
    footnote = '≥90 MME/日，过量/呼吸抑制风险高：尽量避免继续加量，评估纳洛酮备药与降阶梯方案。';
  } else if (total >= 50) {
    tier = '需谨慎';
    footnote = '50-89 MME/日，加量需谨慎并加强随访监测。';
  } else {
    tier = '常规范围';
    footnote = '<50 MME/日，常规监测。';
  }
  footnote += `\n\n${parts.join(' + ')} = ${total.toFixed(0)} MME/日\n转换因子（CDC 2022）：吗啡1、氢可酮1、羟考酮1.5、氢吗啡酮5、曲马多0.2、芬太尼贴剂(mcg/hr)2.4。不同指南因子略有差异；美沙酮转换为非线性，未纳入。MME 用于风险量化，不用于患者间直接剂量转换（需减量 25-50% 交叉滴定）。`;
  return { value: total, unit: 'MME/日', tier, tierClass: total >= 90 ? 'tier-danger' : getTierClass(tier), footnote };
}

/**
 * 糖皮质激素等效剂量换算（抗炎效价）。drug 为药名键，dose 为该药日剂量 mg。
 */
export function calculateSteroid(drug: string, dose: number): CalcResult {
  if (dose <= 0) {
    return emptyResult('mg');
  }
  const equiv: Record<string, number> = {
    'hydrocortisone': 20,
    'cortisone': 25,
    'prednisone': 5,
    'prednisolone': 5,
    'methylpred': 4,
    'triamcinolone': 4,
    'dexamethasone': 0.75,
    'betamethasone': 0.75
  };
  const names: Record<string, string> = {
    'hydrocortisone': '氢化可的松',
    'cortisone': '可的松',
    'prednisone': '泼尼松',
    'prednisolone': '泼尼松龙',
    'methylpred': '甲泼尼龙',
    'triamcinolone': '曲安西龙',
    'dexamethasone': '地塞米松',
    'betamethasone': '倍他米松'
  };
  const base = equiv[drug];
  if (base === undefined || base <= 0) {
    return emptyResult('mg');
  }
  const predEquiv = dose * 5 / base;

  const keys: string[] = ['hydrocortisone', 'cortisone', 'prednisone', 'prednisolone', 'methylpred', 'triamcinolone', 'dexamethasone', 'betamethasone'];
  const lines: string[] = [];
  for (let i = 0; i < keys.length; i++) {
    const k = keys[i];
    lines.push(`${names[k]} ${(predEquiv * equiv[k] / 5).toFixed(2)} mg`);
  }
  const footnote = `${names[drug]} ${dose} mg ≈ 泼尼松当量 ${predEquiv.toFixed(1)} mg\n\n各药等效剂量：\n${lines.join('\n')}\n\n按抗炎效价换算；盐皮质激素活性不同（氢化可的松/可的松高，地塞米松/倍他米松几乎无），换药需结合疗程、HPA 轴抑制与病情个体化。`;
  return { value: predEquiv, unit: 'mg 泼尼松当量', tier: '等效换算', tierClass: 'tier-info', footnote };
}

/**
 * Fick 心排量：CO = VO₂ / (CaO₂ - CvO₂)。hgb g/L，sao2/svo2 %，vo2 mL/min（可空，按 125×BSA 估计）。
 */
export function calculateFick(hgb: number, sao2: number, svo2: number, vo2: number, height: number, weight: number): CalcResult {
  if (hgb <= 0 || sao2 <= 0 || svo2 <= 0 || svo2 >= sao2) {
    return emptyResult('L/min');
  }
  let vo2Use = vo2;
  let bsa = 0;
  let vo2Note = `VO₂ 录入 ${vo2Use.toFixed(0)} mL/min`;
  if (vo2Use <= 0) {
    if (height > 0 && weight > 0) {
      bsa = Math.sqrt(height * weight / 3600);
      vo2Use = 125 * bsa;
      vo2Note = `VO₂ 估计 = 125 × BSA ${bsa.toFixed(2)} m² = ${vo2Use.toFixed(0)} mL/min`;
    } else {
      return emptyResult('L/min');
    }
  } else if (height > 0 && weight > 0) {
    bsa = Math.sqrt(height * weight / 3600);
  }
  const hgbGdL = hgb / 10;
  const diff = 1.34 * hgbGdL * (sao2 - svo2) / 100;
  const co = vo2Use / (diff * 10);

  let tier: string;
  let footnote: string;
  if (co < 2.5) {
    tier = '低心排';
    footnote = 'CO <2.5 L/min，提示低心排，结合灌注指标评估。';
  } else if (co > 6.5) {
    tier = '高心排';
    footnote = 'CO >6.5 L/min，高动力状态（脓毒症早期/贫血/甲亢等）。';
  } else {
    tier = '正常范围';
    footnote = 'CO 2.5-6.5 L/min，大致正常。';
  }
  footnote += `\n\n${vo2Note}\nCa-vO₂ 差 = 1.34 × Hgb ${hgbGdL.toFixed(1)} g/dL × (SaO₂ ${sao2}% - SvO₂ ${svo2}%) = ${diff.toFixed(2)} mL/dL（忽略溶解氧）\nCO = ${vo2Use.toFixed(0)} / (${diff.toFixed(2)} × 10) = ${co.toFixed(2)} L/min`;
  if (bsa > 0) {
    footnote += `\nCI = CO/BSA = ${(co / bsa).toFixed(2)} L/min/m²（正常 2.5-4.0）`;
  }
  footnote += '\n估计 VO₂ 假设静息代谢，发热/寒战/机械通气时偏差大；SvO₂ 需混合静脉血（肺动脉导管）。';
  return { value: co, unit: 'L/min', tier, tierClass: co < 2.5 ? 'tier-danger' : getTierClass(tier), footnote };
}

/**
 * 对乙酰氨基酚 Rumack-Matthew 列线图核对。hours 为摄入后小时数，level 为血药浓度 mg/L。
 */
export function calculateApapNomogram(hours: number, level: number): CalcResult {
  if (hours <= 0 || level <= 0) {
    return emptyResult('mg/L');
  }
  if (hours < 4) {
    const footnote = '摄入 <4h，血药浓度尚未达峰，无法用列线图解释：4h 后复测；大量摄入或缓释剂型需延长监测。\n本工具仅适用于单次急性摄入后 4-24h。';
    return { value: level, unit: 'mg/L', tier: '过早，4h 后复测', tierClass: 'tier-warn', footnote };
  }
  if (hours > 24) {
    const footnote = '摄入 >24h，超出列线图适用范围：按临床表现、肝酶/INR 与残余浓度综合评估，疑肝损即给 NAC。\n本工具仅适用于单次急性摄入后 4-24h。';
    return { value: level, unit: 'mg/L', tier: '超出适用范围', tierClass: 'tier-warn', footnote };
  }
  const threshold = 150 / Math.pow(2, (hours - 4) / 4);
  const above = level >= threshold;

  let tier: string;
  let footnote: string;
  if (above) {
    tier = '≥治疗线：给 NAC';
    footnote = '浓度在 Rumack-Matthew 治疗线或以上，立即启动 N-乙酰半胱氨酸（NAC）并监测肝酶/INR。';
  } else {
    tier = '低于治疗线';
    footnote = '浓度低于治疗线，单次急性摄入通常无需 NAC；缓释剂型/反复超量/时间不确定者按高危处理。';
  }
  footnote += `\n\n治疗线（150 线）：${hours.toFixed(1)}h 时阈值 = 150/2^((${hours.toFixed(1)}-4)/4) = ${threshold.toFixed(1)} mg/L；实测 ${level} mg/L\n仅适用于摄入时间明确的单次急性摄入（4-24h）；不同地区另有用 100 线的保守口径，本工具按 150 线。`;
  return { value: level, unit: 'mg/L', tier, tierClass: above ? 'tier-danger' : 'tier-ok', footnote };
}
