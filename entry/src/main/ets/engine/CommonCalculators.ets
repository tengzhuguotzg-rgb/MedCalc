import { CalcResult, getTierClass } from './CalcEngine';

export function calculatePf(pao2: number, fio2: number, fio2Mode: string, peep: number | null): CalcResult {
  const fio2Value = fio2Mode === 'pct' ? fio2 / 100 : fio2;

  if (pao2 <= 0 || fio2Value <= 0) {
    return {
      value: null,
      unit: '',
      tier: '请填写必填项',
      tierClass: 'tier-info',
      footnote: ''
    };
  }

  const ratio = pao2 / fio2Value;

  let tier: string;
  let footnote: string;

  if (ratio >= 300) {
    tier = '正常 / 无 ARDS';
    footnote = '≥ 300 氧合基本正常。';
    if (peep !== null && peep >= 5) footnote += '\nPEEP ≥ 5, 如 PaO₂/FiO₂ ≤ 300 则 ARDS 诊断成立。';
  } else if (ratio >= 200) {
    tier = '轻度 ARDS';
    footnote = '200-299 轻度 ARDS (Berlin)。需 PEEP/CPAP ≥ 5 方能诊断。\n建议: 氧疗、监测、寻找病因。';
    if (peep !== null && peep < 5) footnote += '\n⚠ PEEP < 5, 需确认是否满足 ARDS 标准。';
  } else if (ratio >= 100) {
    tier = '中度 ARDS';
    footnote = '100-199 中度 ARDS (Berlin)。\n建议: NIPPV/有创通气、俯卧位评估、肺保护通气 (VT 6 mL/kg, Plat ≤ 30)。';
  } else {
    tier = '重度 ARDS';
    footnote = '< 100 重度 ARDS (Berlin)。\n建议: 有创通气、俯卧位、肌松评估、VV-ECMO 评估。';
  }

  const peepNote = peep !== null ? `PEEP ${peep} cmH₂O` : 'PEEP 未填';
  const peepStatus = peep !== null && peep >= 5 ? '✅ 满足诊断' : peep !== null ? '⚠ 可能不满足' : '—';
  footnote += `\n\n${peepNote} · ${peepStatus}`;
  footnote += '\n\nBerlin ARDS 诊断标准 (2012):\n· 轻度: 200 ≤ P/F ≤ 300 + PEEP/CPAP ≥ 5\n· 中度: 100 ≤ P/F ≤ 200 + PEEP ≥ 5\n· 重度: P/F < 100 + PEEP ≥ 5\n需同时满足: 急性起病(1周内)、胸像/CT双肺浸润、非心源性肺水肿。';

  return {
    value: ratio,
    unit: '',
    tier: tier,
    tierClass: getTierClass(tier),
    footnote: footnote
  };
}

export function calculateNa(na: number, glu: number): CalcResult {
  if (na <= 0 || glu <= 0) {
    return {
      value: null,
      unit: 'mmol/L',
      tier: '请填写必填项',
      tierClass: 'tier-info',
      footnote: ''
    };
  }

  const gluMgDl = glu * 18;
  const corrected = na + 1.6 * (gluMgDl - 100) / 100;
  const delta = corrected - na;

  let tier: string;
  let footnote: string;

  if (corrected < 125) {
    tier = '真性低钠';
    footnote = `校正后 < 125, 真性低钠。需 24h 升高 < 8-10 mmol/L 防脑桥脱髓鞘。`;
  } else if (corrected < 135) {
    tier = '轻度低钠';
    footnote = `校正后 125-134, 轻度低钠。糖尿病控制后真实值会上升。`;
  } else if (corrected <= 145) {
    tier = '正常';
    footnote = `校正后 135-145, 正常。实测 ${na} 因高血糖稀释, 不必按"低钠"补。`;
  } else {
    tier = '高钠';
    footnote = `校正后 > 145, 高钠。逐步降至 145 需 ≥ 48h。`;
  }

  return {
    value: corrected,
    unit: 'mmol/L',
    tier: tier,
    tierClass: getTierClass(tier),
    footnote: footnote + ` Δ = +${delta.toFixed(1)} mmol/L`
  };
}

export function calculateNaDeficit(weight: number, na: number, targetNa: number, isFemale: boolean, isChild: boolean): CalcResult {
  if (weight <= 0 || na <= 0 || targetNa <= 0) {
    return { value: null, unit: 'mmol', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
  }

  const tbwFactor = isChild ? 0.6 : (isFemale ? 0.5 : 0.6);
  const deficit = tbwFactor * weight * (targetNa - na);
  const isHyponatremia = na < targetNa;

  let tier: string;
  let footnote: string;

  if (isHyponatremia) {
    if (na < 120) {
      tier = '重度低钠';
      footnote = 'Na⁺ < 120 严重低钠, 脑桥脱髓鞘风险极高。\n24h升高 ≤ 8-10 mmol/L, 48h ≤ 18 mmol/L。\n推荐ICU监测, 严重症状时可用3%高渗盐水。';
    } else if (na < 125) {
      tier = '中度低钠';
      footnote = 'Na⁺ 120-125 中度低钠。\n24h升高 ≤ 8-10 mmol/L 防脑桥脱髓鞘。\n积极查找病因(低容/等容/高容)。';
    } else if (na < 135) {
      tier = '轻度低钠';
      footnote = 'Na⁺ 125-135 轻度低钠。\n一般限制自由水摄入即可。\n注意排除SIADH、甲状腺/肾上腺功能减退。';
    } else {
      tier = '正常范围';
      footnote = 'Na⁺ 135-145 正常范围, 无需补钠。';
    }
    footnote += `\n\n公式: Na缺失 = ${tbwFactor} × ${weight}kg × (${targetNa} - ${na})\n= ${deficit.toFixed(0)} mmol`;
  } else {
    tier = '高钠';
    footnote = `Na⁺ > ${targetNa}, 当前为高钠。请使用高钠纠正速率计算器。\n24h降低 ≤ 10 mmol/L 防脑水肿。`;
  }

  return {
    value: isHyponatremia ? deficit : null,
    unit: 'mmol',
    tier: tier,
    tierClass: getTierClass(tier),
    footnote: footnote
  };
}

export interface FluidOption {
  name: string;
  naContent: number;
  description: string;
}

export function calculateNaCorrectionRate(weight: number, na: number, targetNa: number, rateMmolPerDay: number,
  isFemale: boolean, isChild: boolean, fluidNaContent: number): CalcResult {
  if (weight <= 0 || na <= 0 || targetNa <= 0 || rateMmolPerDay <= 0) {
    return { value: null, unit: 'mL/h', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
  }

  const tbw = (isChild ? 0.6 : (isFemale ? 0.5 : 0.6)) * weight;
  const isHyponatremia = na < targetNa;

  if (!isHyponatremia) {
    const freeWaterDeficit = tbw * (na / targetNa - 1) * 1000;
    // Adrogué-Madias also applies to hypernatremia:
    // ΔNa per 1L infusate = (InfusateNa - SerumNa) / (TBW + 1)
    // For hypernatremia, infusateNa < serumNa → deltaNa is NEGATIVE (lowers serum Na)
    const deltaNaPerLiter = (fluidNaContent - na) / (tbw + 1);
    const safeRate = 10; // 10 mmol/L/24h for hypernatremia

    let tier: string;
    let rateWarning = '';
    if (rateMmolPerDay > safeRate + 0.1) {
      tier = '速率过快';
      rateWarning = '\n\n⚠ 24h降低 > 10 mmol/L, 脑水肿/癫痫风险!\n需ICU严密监测。';
    } else if (rateMmolPerDay > safeRate * 0.8) {
      tier = '速率偏快';
      rateWarning = '\n\n⚠ 接近安全上限 (10 mmol/L/24h)。';
    } else {
      tier = '速率安全';
    }

    let fluidName = '';
    if (fluidNaContent >= 513) {
      fluidName = '3% NaCl';
    } else if (fluidNaContent >= 154) {
      fluidName = '0.9% NaCl';
    } else if (fluidNaContent >= 77) {
      fluidName = '0.45% NaCl';
    } else {
      fluidName = 'D5W';
    }

    // deltaNaPerLiter is negative for hypernatremia correction
    // We want to LOWER na by rateMmolPerDay over 24h
    // volumePerDay = rateMmolPerDay / |deltaNaPerLiter|
    if (deltaNaPerLiter >= 0) {
      const tier2 = '液体不当';
      const footnote2 = `⚠ 所选液体Na⁺含量(${fluidNaContent} mmol/L) ≥ 血清Na⁺(${na} mmol/L)\n` +
        `该液体不能降低血钠, 反而可能进一步升高!\n\n` +
        `高钠纠正推荐: D5W(0) 或 0.45% NaCl(77)`;
      return { value: null, unit: 'mL/h', tier: tier2, tierClass: getTierClass(tier2), footnote: footnote2 };
    }

    const volumeLitersPerDay = rateMmolPerDay / Math.abs(deltaNaPerLiter);
    const rateMlPerH = volumeLitersPerDay * 1000 / 24;
    const deltaNaNeeded = na - targetNa;
    const hoursToTarget = deltaNaNeeded / (rateMmolPerDay / 24);

    const footnote = `高钠纠正计划 (Na⁺ ${na} → ${targetNa})\n\n` +
      `自由水缺失 ≈ ${freeWaterDeficit.toFixed(0)} mL\n` +
      `纠正速率: ${rateMmolPerDay} mmol/L/24h\n` +
      `安全上限: ≤ 10 mmol/L/24h\n` +
      `预计达标: ${hoursToTarget.toFixed(1)} h\n\n` +
      `补液方案: ${fluidName} (${fluidNaContent} mmol/L Na⁺)\n` +
      `每升ΔNa⁺ = (${fluidNaContent} - ${na}) / (${tbw.toFixed(1)} + 1) = ${deltaNaPerLiter.toFixed(2)} mmol/L\n` +
      `24h需输注: ${volumeLitersPerDay.toFixed(2)} L = ${(volumeLitersPerDay * 1000).toFixed(0)} mL\n` +
      `输注速率: ${rateMlPerH.toFixed(0)} mL/h` +
      rateWarning +
      `\n\nAdrogué-Madias公式:\nΔNa⁺ = (InfusateNa⁺ - SerumNa⁺) / (TBW + 1)\n= (${fluidNaContent} - ${na}) / (${tbw.toFixed(1)} + 1)\n= ${deltaNaPerLiter.toFixed(2)} mmol/L per L infused`;

    return { value: rateMlPerH, unit: 'mL/h', tier: tier, tierClass: getTierClass(tier), footnote: footnote };
  }

  // Adrogué-Madias formula:
  // ΔNa per 1L infusate = (InfusateNa + InfusateK - SerumNa) / (TBW + 1)
  // For simplicity, InfusateK = 0 (no KCl added)
  // To raise Na by rateMmolPerDay over 24h:
  //   total Na rise needed = rateMmolPerDay mmol/L
  //   volume needed = rateMmolPerDay / deltaNaPerLiter (in Liters over 24h)
  //   rate in mL/h = volume * 1000 / 24

  const deltaNaPerLiter = (fluidNaContent - na) / (tbw + 1);

  // If fluidNaContent <= na (e.g. D5W for hyponatremia — wrong choice), delta is negative
  if (deltaNaPerLiter <= 0) {
    const tier = '液体不当';
    const footnote = `⚠ 所选液体Na⁺含量(${fluidNaContent} mmol/L) ≤ 血清Na⁺(${na} mmol/L)\n` +
      `该液体不能升高血钠, 反而可能进一步降低!\n\n` +
      `低钠纠正推荐: 0.9% NaCl(154) 或 3% NaCl(513)\n` +
      `严重症状时用3%高渗盐水`;
    return { value: null, unit: 'mL/h', tier: tier, tierClass: getTierClass(tier), footnote: footnote };
  }

  const volumeLitersPerDay = rateMmolPerDay / deltaNaPerLiter;
  const rateMlPerH = volumeLitersPerDay * 1000 / 24;

  const deficit = tbw * (targetNa - na);
  const deltaNaNeeded = targetNa - na;
  const hoursToTarget = deltaNaNeeded / (rateMmolPerDay / 24);
  const safeRate = 8;

  let tier: string;
  let rateWarning = '';
  if (rateMmolPerDay > safeRate + 0.1) {
    rateWarning = '\n\n⚠ 纠正速率 > 8 mmol/L/24h, 脑桥脱髓鞘风险!\n仅严重症状(抽搐/昏迷)时允许快速纠正,\n且需ICU严密监测。';
    tier = '速率过快';
  } else if (rateMmolPerDay > safeRate * 0.8) {
    rateWarning = '\n\n⚠ 接近安全上限 (8 mmol/L/24h), 需严密监测。';
    tier = '速率偏快';
  } else {
    tier = '速率安全';
  }

  let fluidName = '';
  if (fluidNaContent >= 513) {
    fluidName = '3% NaCl';
  } else if (fluidNaContent >= 154) {
    fluidName = '0.9% NaCl';
  } else if (fluidNaContent >= 77) {
    fluidName = '0.45% NaCl';
  } else {
    fluidName = 'D5W';
  }

  const footnote = `低钠纠正计划 (Na⁺ ${na} → ${targetNa})\n\n` +
    `Na缺失量: ${deficit.toFixed(0)} mmol\n` +
    `纠正速率: ${rateMmolPerDay} mmol/L/24h\n` +
    `安全上限: ≤ 8 mmol/L/24h\n` +
    `预计达标: ${hoursToTarget.toFixed(1)} h\n\n` +
    `补液方案: ${fluidName} (${fluidNaContent} mmol/L Na⁺)\n` +
    `每升ΔNa⁺ = (${fluidNaContent} - ${na}) / (${tbw.toFixed(1)} + 1) = ${deltaNaPerLiter.toFixed(2)} mmol/L\n` +
    `24h需输注: ${volumeLitersPerDay.toFixed(2)} L = ${(volumeLitersPerDay * 1000).toFixed(0)} mL\n` +
    `输注速率: ${rateMlPerH.toFixed(0)} mL/h` +
    rateWarning +
    `\n\nAdrogué-Madias公式:\nΔNa⁺ = (InfusateNa⁺ - SerumNa⁺) / (TBW + 1)\n= (${fluidNaContent} - ${na}) / (${tbw.toFixed(1)} + 1)\n= ${deltaNaPerLiter.toFixed(2)} mmol/L per L infused`;

  return {
    value: rateMlPerH,
    unit: 'mL/h',
    tier: tier,
    tierClass: getTierClass(tier),
    footnote: footnote
  };
}

export function calculateCurb65(confusion: boolean, urea: number, ureaUnit: string, rr: number, sbp: number, dbp: number, age: number): CalcResult {
  if (urea <= 0 || rr <= 0 || sbp <= 0 || dbp <= 0 || age <= 0) {
    return {
      value: null,
      unit: '',
      tier: '请填写必填项',
      tierClass: 'tier-info',
      footnote: ''
    };
  }

  let total = 0;

  if (confusion) total += 1;

  const ureaMmol = ureaUnit === 'mgdl' ? urea / 2.8 : urea;
  if (ureaMmol > 7) total += 1;

  if (rr >= 30) total += 1;

  if (sbp < 90 || dbp <= 60) total += 1;

  if (age >= 65) total += 1;

  let tier: string;
  let footnote: string;

  if (total === 0) {
    tier = '低风险';
    footnote = '0分 死亡风险低, 可院外治疗。';
  } else if (total <= 2) {
    tier = '中风险';
    footnote = '1-2分 死亡风险中等, 建议住院。';
  } else {
    tier = '高风险';
    footnote = '≥3分 死亡风险高, 需住院甚至ICU。';
  }

  return {
    value: total,
    unit: '',
    tier: tier,
    tierClass: getTierClass(tier),
    footnote: footnote
  };
}

export function calculateSirs(temp: number, hr: number, rr: number, paco2: number, wbc: number, bands: number): CalcResult {
  if (temp <= 0 || hr <= 0 || rr <= 0 || wbc <= 0) {
    return {
      value: null,
      unit: '',
      tier: '请填写必填项',
      tierClass: 'tier-info',
      footnote: ''
    };
  }

  let total = 0;

  if (temp < 36 || temp > 38) total += 1;
  if (hr > 90) total += 1;
  if (rr > 20 || (paco2 > 0 && paco2 < 32)) total += 1;
  if (wbc < 4 || wbc > 12 || (bands > 0 && bands > 10)) total += 1;

  let tier: string;
  let footnote: string;

  if (total >= 2) {
    tier = 'SIRS 阳性';
    footnote = `≥2项 SIRS阳性。提示全身炎症反应, 脓毒症需结合感染源。`;
  } else {
    tier = 'SIRS 阴性';
    footnote = `<2项 不满足SIRS标准。`;
  }

  return {
    value: total,
    unit: '',
    tier: tier,
    tierClass: total >= 2 ? 'tier-warn' : 'tier-ok',
    footnote: footnote
  };
}
