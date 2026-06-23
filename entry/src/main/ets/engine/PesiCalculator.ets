import { CalcResult, getTierClass } from './CalcEngine';

export function calculatePesi(
  age: number, sex: number,
  cancer: number, chf: number, cld: number,
  hr: number, sbp: number, rr: number, temp: number,
  ams: number, osp: number
): CalcResult {
  if (age <= 0 || hr <= 0 || sbp <= 0 || rr <= 0 || temp <= 0) {
    return { value: null, unit: '', tier: '请填写所有必填项', tierClass: 'tier-info', footnote: '' };
  }

  const total = age + sex + cancer + chf + cld
    + (hr >= 110 ? 20 : 0)
    + (sbp < 100 ? 30 : 0)
    + (rr >= 30 ? 20 : 0)
    + (temp < 36 ? 20 : 0)
    + ams + osp;

  let risk: string;
  let tierClass: string;
  let mort: string;

  if (total <= 65) {
    tierClass = 'tier-ok'; risk = 'I 级 (低)'; mort = '0.6-1.4%';
  } else if (total <= 85) {
    tierClass = 'tier-warn'; risk = 'II 级 (低-中)'; mort = '3.1-3.5%';
  } else if (total <= 105) {
    tierClass = 'tier-warn'; risk = 'III 级 (中)'; mort = '6.5-7.1%';
  } else if (total <= 125) {
    tierClass = 'tier-danger'; risk = 'IV 级 (高)'; mort = '10-12.5%';
  } else {
    tierClass = 'tier-danger'; risk = 'V 级 (极高)'; mort = '21-24.5%';
  }

  const spAge = age > 80 ? 1 : 0;
  const spCancer = cancer > 0 ? 1 : 0;
  const spCP = (chf > 0 || cld > 0) ? 1 : 0;
  const spHR = hr >= 110 ? 1 : 0;
  const spSBP = sbp < 100 ? 1 : 0;
  const spOX = osp > 0 ? 1 : 0;
  const spTotal = spAge + spCancer + spCP + spHR + spSBP + spOX;
  const spRisk = spTotal === 0 ? '低风险 (30d 死亡率 ~1%)' : '高风险 (30d 死亡率 ~8%)';

  const footnote = `PESI ${total} 分 · ${risk}\n30天死亡率 ${mort}\nsPESI ${spTotal}/6 · ${spRisk}\n\n处理: I-II 门诊/短期住院 · III 住院 · IV-V 住院+ICU 评估`;

  return { value: total, unit: '', tier: `${risk} · sPESI: ${spRisk}`, tierClass, footnote };
}
