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
  footnote += '\n\nBerlin ARDS 诊断标准 (2012):\n· 轻度: 200 ≤ P/F ≤ 300 + PEEP/CPAP ≥ 5\n· 中度: 100 ≤ P/F ≤ 200 + PEEP ≥ 5\n· 重度: P/F < 100 + PEEP ≥ 5\n需同时满足: 急性起病(1周内)、胸片/CT双肺浸润、非心源性肺水肿。';

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

  const corrected = na + 1.6 * (glu - 100) / 100;
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

export function calculateCurb65(confusion: boolean, urea: number, ureaUnit: string, rr: number, sbp: number, dbp: number, age: number): CalcResult {
  if (rr <= 0 || sbp <= 0 || age <= 0) {
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

  const ureaMmol = ureaUnit === 'mgdl' ? urea / 2.14 : urea;
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
