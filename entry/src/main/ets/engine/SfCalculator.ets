import { CalcResult, getTierClass } from './CalcEngine';

export function calculateSf(spo2: number, fio2: number, fio2Mode: string): CalcResult {
  const fio2Value = fio2Mode === 'pct' ? fio2 / 100 : fio2;

  if (spo2 <= 0 || fio2Value <= 0) {
    return {
      value: null,
      unit: 'S/F',
      tier: '请填写必填项',
      tierClass: 'tier-info',
      footnote: ''
    };
  }

  const ratio = spo2 / fio2Value;

  let tier: string;
  let footnote: string;

  if (spo2 >= 99) {
    tier = 'SpO₂ 失真';
    footnote = 'SpO₂ ≥ 99% 时公式出现"天花板"效应, 需参考 SpO₂ 100% 时 P/F 至少 200。';
  } else if (ratio >= 315) {
    tier = '无 ARDS';
    footnote = '≥ 315 (≈ P/F ≥ 300) 氧合基本正常。';
  } else if (ratio >= 235) {
    tier = '轻度 ARDS';
    footnote = '235-314 (≈ P/F 200-300) 轻度 ARDS。';
  } else if (ratio >= 148) {
    tier = '中度 ARDS';
    footnote = '148-234 (≈ P/F 100-200) 中度 ARDS, 评估俯卧位。';
  } else {
    tier = '重度 ARDS';
    footnote = '< 148 (≈ P/F < 100) 重度 ARDS, 评估俯卧位、肌松、VV-ECMO。';
  }

  return {
    value: ratio,
    unit: 'S/F',
    tier: tier,
    tierClass: getTierClass(tier),
    footnote: footnote
  };
}
