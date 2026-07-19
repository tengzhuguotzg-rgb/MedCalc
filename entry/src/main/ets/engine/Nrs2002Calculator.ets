import { CalcResult } from './CalcEngine';

export function calculateNrs2002(
  height: number,
  weight: number,
  weightLoss: string,
  intake: string,
  disease: string,
  ageAdj: boolean
): CalcResult {
  if (weightLoss === '' || intake === '' || disease === '') {
    return { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
  }

  const bmi = height > 0 && weight > 0 ? weight / Math.pow(height / 100, 2) : null;

  let nutrScore = 0;
  let nutrReason = '正常';
  
  if (bmi !== null && bmi < 18.5) {
    nutrScore = 3;
    nutrReason = 'BMI < 18.5';
  } else if (weightLoss === 'severe' || intake === 'severe') {
    nutrScore = 3;
    nutrReason = weightLoss === 'severe' ? '体重降 >15%' : '进食 <25%';
  } else if (weightLoss === 'mod' || intake === 'mod') {
    nutrScore = 2;
    nutrReason = weightLoss === 'mod' ? '体重降 >10%' : '进食 25-50%';
  } else if (weightLoss === 'mild' || intake === 'mild') {
    nutrScore = 1;
    nutrReason = weightLoss === 'mild' ? '体重降 >5%' : '进食 >50%';
  }

  let disScore = 0;
  let disReason = '无 / 轻';
  
  if (disease === 'severe') {
    disScore = 3;
    disReason = '重度 (颅脑损伤/骨髓移植/ICU)';
  } else if (disease === 'moderate') {
    disScore = 2;
    disReason = '中度 (腹部大手术/卒中/重症肺炎)';
  }

  const ageScore = ageAdj ? 1 : 0;
  const total = nutrScore + disScore + ageScore;

  let tier: string;
  let tierClass: string;
  let footnote: string;

  if (total >= 3) {
    tier = '有营养风险';
    tierClass = 'tier-danger';
    footnote = '≥ 3 分 · 有营养风险 · 建议营养支持 (制定营养计划, 考虑管饲/PN)。';
  } else {
    tier = '无营养风险';
    tierClass = 'tier-ok';
    footnote = '< 3 分 · 无营养风险 · 住院期间每周复查。';
  }

  const detail = `营养状态: ${nutrReason} (${nutrScore}分)\n疾病严重度: ${disReason} (${disScore}分)\n年龄调整: ${ageAdj ? '≥ 70岁' : '< 70岁'} (${ageScore}分)`;

  return {
    value: total,
    unit: '/ 7',
    tier: tier,
    tierClass: tierClass,
    footnote: footnote + '\n\n' + detail
  };
}
