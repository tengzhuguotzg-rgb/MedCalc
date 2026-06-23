import { CalcResult, getTierClass } from './CalcEngine';

export function calculateMnutric(
  age: number,
  apache2: number, sofa: number,
  comorb: number, icuDay: number
): CalcResult {
  if (apache2 <= 0 || sofa <= 0) {
    return { value: null, unit: '', tier: '请填写 APACHE II 和 SOFA', tierClass: 'tier-info', footnote: '' };
  }

  let apScore = 0;
  if (apache2 >= 28) apScore = 3;
  else if (apache2 >= 20) apScore = 2;
  else if (apache2 >= 15) apScore = 1;

  let sfScore = 0;
  if (sofa >= 10) sfScore = 2;
  else if (sofa >= 6) sfScore = 1;

  const total = age + apScore + sfScore + comorb + icuDay;

  let tier: string;
  let footnote: string;

  if (total >= 5) {
    tier = '高营养风险';
    footnote = '≥ 5 分 · 建议启动营养支持(肠内优先), 24-48h 内达到目标量。';
  } else {
    tier = '低营养风险';
    footnote = '< 5 分 · 常规营养支持, 动态评估。';
  }

  const detail = `\n\n年龄 ${age === 0 ? '<50' : age === 1 ? '50-74' : '≥75'} (${age})\nAPACHE II ${apache2} (${apScore})\nSOFA ${sofa} (${sfScore})\n合并症≥2: ${comorb === 1 ? '是' : '否'}\nICU前住院≥1d: ${icuDay === 1 ? '是' : '否'}`;

  return { value: total, unit: '/ 9', tier, tierClass: getTierClass(tier), footnote: footnote + detail };
}
