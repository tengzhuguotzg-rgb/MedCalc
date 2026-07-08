import { DiagnosisRule, DiagnosisCriterion, DIAGNOSIS_RULES } from '../model/DiagnosisRules';
import { CalcResult } from '../engine/CalcEngine';

export class DiagnosisMatch {
  rule: DiagnosisRule = new DiagnosisRule();
  matchedCriteria: string[] = [];
}

export class DiagnosisEngine {
  private static instance: DiagnosisEngine | null = null;

  private constructor() {}

  static getInstance(): DiagnosisEngine {
    if (!DiagnosisEngine.instance) {
      DiagnosisEngine.instance = new DiagnosisEngine();
    }
    return DiagnosisEngine.instance;
  }

  matchDiagnoses(latestData: Map<string, string>, alertResults: Map<string, CalcResult>): DiagnosisMatch[] {
    const matches: DiagnosisMatch[] = [];

    for (let i = 0; i < DIAGNOSIS_RULES.length; i++) {
      const rule = DIAGNOSIS_RULES[i];
      const matchedCriteria: string[] = [];
      let allMet = true;

      for (let j = 0; j < rule.criteria.length; j++) {
        const criterion = rule.criteria[j];
        const met = this.checkCriterion(criterion, latestData, alertResults);
        if (!met) {
          allMet = false;
          break;
        }
        matchedCriteria.push(criterion.field + ' ' + criterion.operator + ' ' + criterion.value);
      }

      if (allMet && matchedCriteria.length > 0) {
        const match = new DiagnosisMatch();
        match.rule = rule;
        match.matchedCriteria = matchedCriteria;
        matches.push(match);
      }
    }

    return matches;
  }

  private checkCriterion(
    criterion: DiagnosisCriterion,
    latestData: Map<string, string>,
    alertResults: Map<string, CalcResult>
  ): boolean {
    if (criterion.field.startsWith('calcResult:')) {
      const calcId: string = criterion.field.substring('calcResult:'.length);
      const result: CalcResult | undefined = alertResults.get(calcId);
      if (result === undefined || result === null || result.value === null) {
        return false;
      }
      return this.checkCalcCriterion(criterion, result);
    }

    const dataValue: string | undefined = latestData.get(criterion.field);
    if (dataValue === undefined || dataValue.length === 0) {
      return false;
    }

    return this.checkDataCriterion(criterion, dataValue);
  }

  private checkCalcCriterion(
    criterion: DiagnosisCriterion,
    result: CalcResult
  ): boolean {
    const op: string = criterion.operator;
    const val: string = criterion.value;

    if (op === 'gte') {
      return result.value !== null && result.value >= parseFloat(val);
    }
    if (op === 'gt') {
      return result.value !== null && result.value > parseFloat(val);
    }
    if (op === 'lte') {
      return result.value !== null && result.value <= parseFloat(val);
    }
    if (op === 'lt') {
      return result.value !== null && result.value < parseFloat(val);
    }
    if (op === 'eq') {
      if (result.value !== null) {
        return result.value.toString() === val;
      }
      return false;
    }
    if (op === 'neq') {
      if (result.value !== null) {
        return result.value.toString() !== val;
      }
      return true;
    }
    if (op === 'has_tier') {
      return result.tier === val;
    }
    if (op === 'has_tier_containing') {
      return result.tier.indexOf(val) >= 0;
    }
    if (op === 'has_bilirubin_score') {
      if (result.tier.indexOf('危') >= 0 || result.tier.indexOf('高') >= 0 || result.tier.indexOf('中') >= 0) {
        return true;
      }
      return false;
    }

    return false;
  }

  private checkDataCriterion(
    criterion: DiagnosisCriterion,
    dataValue: string
  ): boolean {
    const op: string = criterion.operator;
    const val: string = criterion.value;
    const numVal: number = parseFloat(dataValue);

    if (op === 'gte') {
      return !isNaN(numVal) && numVal >= parseFloat(val);
    }
    if (op === 'gt') {
      return !isNaN(numVal) && numVal > parseFloat(val);
    }
    if (op === 'lte') {
      return !isNaN(numVal) && numVal <= parseFloat(val);
    }
    if (op === 'lt') {
      return !isNaN(numVal) && numVal < parseFloat(val);
    }
    if (op === 'eq') {
      return dataValue === val;
    }
    if (op === 'neq') {
      return dataValue !== val;
    }
    if (op === 'in') {
      const options: string[] = val.split(',');
      for (let i = 0; i < options.length; i++) {
        if (dataValue === options[i].trim()) {
          return true;
        }
      }
      return false;
    }

    return false;
  }

  getDiagnosisRules(): DiagnosisRule[] {
    return DIAGNOSIS_RULES;
  }
}
