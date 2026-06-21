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
  if (tier.includes('正常') || tier.includes('达标') || tier.includes('G1') || tier.includes('G2')) {
    return 'tier-ok';
  } else if (tier.includes('轻度') || tier.includes('中度') || tier.includes('G3') || tier.includes('G4')) {
    return 'tier-warn';
  } else if (tier.includes('重度') || tier.includes('衰竭') || tier.includes('G5') || tier.includes('低于') || tier.includes('危险')) {
    return 'tier-danger';
  }
  return 'tier-info';
}
