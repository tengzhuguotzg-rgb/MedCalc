export interface VpConfig {
  drugName: string;
  mg: number;
  ml: number;
  weight: number;
}

export interface VpResult {
  mlh: number | null;
  doseUgkgn: number | null;
}

export function vasopressorMlhToDose(concMg: number, concMl: number, weight: number, mlh: number): number | null {
  if (concMg <= 0 || concMl <= 0 || weight <= 0) {
    return null;
  }
  const concUgPerMl = concMg * 1000 / concMl;
  return (mlh / 60) * concUgPerMl / weight;
}

export function vasopressorDoseToMlh(concMg: number, concMl: number, weight: number, dose: number): number | null {
  if (concMg <= 0 || concMl <= 0 || weight <= 0) {
    return null;
  }
  const concUgPerMl = concMg * 1000 / concMl;
  return (dose * weight * 60) / concUgPerMl;
}
