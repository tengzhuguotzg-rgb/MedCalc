import { DiagnosisRule, DiagnosisCriterion, DIAGNOSIS_RULES } from '../model/DiagnosisRules';
import { CalcResult } from '../engine/CalcEngine';

export class DiagnosisMatch {
  rule: DiagnosisRule = new DiagnosisRule();
  matchedCriteria: string[] = [];
}

export class PartialMatch {
  rule: DiagnosisRule = new DiagnosisRule();
  matchedCount: number = 0;
  totalCount: number = 0;
  matchedCriteria: string[] = [];
  missingCriteria: string[] = [];
}

export class DiagnosisResult {
  confirmed: DiagnosisMatch[] = [];
  partial: PartialMatch[] = [];
  labAlerts: DiagnosisMatch[] = [];
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
    const result = this.evaluate(latestData, alertResults);
    return result.confirmed;
  }

  evaluate(latestData: Map<string, string>, alertResults: Map<string, CalcResult>): DiagnosisResult {
    const result = new DiagnosisResult();

    for (let i = 0; i < DIAGNOSIS_RULES.length; i++) {
      const rule = DIAGNOSIS_RULES[i];
      const matchedCriteria: string[] = [];
      const missingCriteria: string[] = [];
      let allMet = true;

      for (let j = 0; j < rule.criteria.length; j++) {
        const criterion = rule.criteria[j];
        const met = this.checkCriterion(criterion, latestData, alertResults);
        if (met) {
          matchedCriteria.push(criterion.field + ' ' + criterion.operator + ' ' + criterion.value);
        } else {
          allMet = false;
          missingCriteria.push(criterion.field + ' ' + criterion.operator + ' ' + criterion.value);
        }
      }

      if (allMet && matchedCriteria.length > 0) {
        const match = new DiagnosisMatch();
        match.rule = rule;
        match.matchedCriteria = matchedCriteria;
        if (rule.ruleType === 'alert') {
          result.labAlerts.push(match);
        } else {
          result.confirmed.push(match);
        }
      } else if (matchedCriteria.length > 0 && matchedCriteria.length >= rule.criteria.length * 0.5) {
        const partial = new PartialMatch();
        partial.rule = rule;
        partial.matchedCount = matchedCriteria.length;
        partial.totalCount = rule.criteria.length;
        partial.matchedCriteria = matchedCriteria;
        partial.missingCriteria = missingCriteria;
        result.partial.push(partial);
      }
    }

    result.partial.sort((a: PartialMatch, b: PartialMatch): number => {
      const ratioA = a.matchedCount / a.totalCount;
      const ratioB = b.matchedCount / b.totalCount;
      if (ratioB !== ratioA) {
        return ratioB - ratioA;
      }
      return b.matchedCount - a.matchedCount;
    });

    return result;
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
