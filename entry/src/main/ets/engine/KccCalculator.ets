import { CalcResult } from './CalcEngine';

export function calculateKcc(inr: number, bilirubin: number, age: number, etiology: boolean): CalcResult {
  if (inr <= 0 || bilirubin <= 0 || age <= 0) {
    return { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
  }

  let meetsKcc = false;
  let reason: string = '';

  if (inr > 6.5) {
    meetsKcc = true;
    reason = 'INR > 6.5';
  } else if (bilirubin > 300) {
    meetsKcc = true;
    reason = '胆红素 > 300 µmol/L';
  } else if (etiology && age < 18 && inr > 4 && bilirubin > 170) {
    meetsKcc = true;
    reason = '年龄 < 18岁 + INR > 4 + 胆红素 > 170 µmol/L';
  } else if (age < 40 && etiology && inr > 3 && bilirubin > 170) {
    meetsKcc = true;
    reason = '年龄 < 40岁 + INR > 3 + 胆红素 > 170 µmol/L';
  }

  let tier: string;
  let tierClass: string;
  let footnote: string;

  if (meetsKcc) {
    tier = '符合KCC标准';
    tierClass = 'tier-danger';
    footnote = reason + '，建议紧急肝移植';
  } else {
    tier = '不符合KCC标准';
    tierClass = 'tier-ok';
    footnote = '暂无紧急肝移植指征';
  }

  return { value: meetsKcc ? 1 : 0, unit: '', tier, tierClass, footnote };
}
