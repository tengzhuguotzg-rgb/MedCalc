export interface CalcResult {
  value: number | null;
  unit: string;
  tier: string;
  tierClass: string;
  footnote: string;
}

export function formatValue(value: number | null, unit: string): string {
  if (value === null || isNaN(value)) {
    return '—';
  }
  const formatted = value.toFixed(1).replace(/\.0$/, '');
  return unit ? `${formatted} ${unit}` : formatted;
}

export function getTierClass(tier: string): string {
  if (tier.includes('正常') || tier.includes('达标') || tier.includes('G1') || tier.includes('G2')
    || tier.includes('低危') || tier.includes('低风险') || tier.includes('无A')) {
    return 'tier-ok';
  } else if (tier.includes('轻度') || tier.includes('中度') || tier.includes('G3') || tier.includes('G4')
    || tier.includes('中危') || tier.includes('中风险') || tier.includes('中低') || tier.includes('中高') || tier.includes('中重') || tier.includes('数据异常')) {
    return 'tier-warn';
  } else if (tier.includes('重度') || tier.includes('衰竭') || tier.includes('G5') || tier.includes('低于') || tier.includes('危险')
    || tier.includes('高危') || tier.includes('极高危') || tier.includes('高风险') || tier.includes('极高风险') || tier.includes('过高') || tier.includes('ACLF') || tier.includes('危重') || tier.includes('濒危') || tier.includes('极危') || tier.includes('极重度') || tier.includes('高AG') || tier.includes('低钠') || tier.includes('高钠')) {
    return 'tier-danger';
  }
  return 'tier-info';
}

export function getTierColor(tierClass: string): string {
  if (tierClass === 'tier-ok') {
    return '#3D6B4F';
  }
  if (tierClass === 'tier-warn') {
    return '#C8881A';
  }
  if (tierClass === 'tier-danger') {
    return '#B1452A';
  }
  return '#7A8074';
}

export function getTierBgColor(tierClass: string): string {
  if (tierClass === 'tier-ok') {
    return '#E8F5E9';
  }
  if (tierClass === 'tier-warn') {
    return '#FFF8E1';
  }
  if (tierClass === 'tier-danger') {
    return '#FFEBEE';
  }
  return '#F5F5F5';
}
