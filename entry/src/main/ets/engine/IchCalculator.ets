import { CalcResult } from './CalcEngine';

export function calculateIch(vol: number, location: number, ivh: boolean, age: number, gcs: number): CalcResult {
  if (vol <= 0 || location < 0 || age <= 0 || gcs <= 0) {
    return { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
  }

  let score = 0;
  const parts: string[] = [];
  if (vol > 30) { score += 1; parts.push('体积>30mL✓'); } else { parts.push('体积≤30mL✗'); }
  if (location === 1) { score += 1; parts.push('幕下✓'); } else { parts.push('幕上✗'); }
  if (ivh) { score += 1; parts.push('IVH✓'); } else { parts.push('IVH✗'); }
  if (age >= 80) { score += 1; parts.push('年龄≥80✓'); } else { parts.push('年龄<80✗'); }
  let gcsPts = 0;
  if (gcs < 5) gcsPts = 2; else if (gcs >= 5 && gcs <= 12) gcsPts = 1;
  score += gcsPts;
  parts.push(`GCS ${gcs}${gcsPts === 2 ? ' 3-4→2' : gcsPts === 1 ? ' 5-12→1' : ' 13-15→0'}`);

  let tier: string;
  let tierClass: string;
  let footnote: string;

  const mortMap: string[] = ['0%', '13%', '26%', '40%', '67%', '93%', '97%'];
  const mort = mortMap[score] || '97%';

  if (score === 0) { tier = '低风险 (0分)'; tierClass = 'tier-ok'; }
  else if (score <= 2) { tier = '中风险'; tierClass = 'tier-warn'; }
  else if (score <= 4) { tier = '高风险'; tierClass = 'tier-danger'; }
  else { tier = '极高风险'; tierClass = 'tier-danger'; }

  footnote = `${parts.join('，')} → ${score}/6\n30天死亡率约${mort}`;
  footnote += '\nICH Score: GCS 3-4=2分/5-12=1分/13-15=0分, 体积>30mL=1分, 幕下=1分, IVH=1分, 年龄≥80=1分。';

  return { value: score, unit: '/6', tier, tierClass, footnote };
}
