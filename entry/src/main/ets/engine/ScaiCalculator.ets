import { CalcResult } from './CalcEngine';

export function calculateScai(
  sbp: number, lac: number,
  vaso: string, perf: string, resus: string
): CalcResult {
  if (sbp <= 0 || lac <= 0) {
    return { value: null, unit: '', tier: '请填写 SBP 和乳酸', tierClass: 'tier-info', footnote: '' };
  }

  let stageNum: number;
  let stageLetter: string;
  let tierClass: string;
  let desc: string;
  let manage: string;

  if (resus === 'yes' || lac > 5 || (sbp < 60 && vaso !== 'none')) {
    stageNum = 5; stageLetter = 'E'; tierClass = 'tier-danger';
    desc = '极端期 (Extremis) — 难治性心脏骤停/深休克';
    manage = 'ECMO/机械循环支持评估, 多学科协作, 讨论生存预期。';
  } else if (vaso === 'high' || lac > 4 || (perf === 'bad' && vaso !== 'none')) {
    stageNum = 4; stageLetter = 'D'; tierClass = 'tier-danger';
    desc = '恶化期 (Deteriorating) — 升压药升级, 器官灌注恶化';
    manage = '考虑 MCS (IABP/Impella/VA-ECMO), 评估冠脉血运重建。';
  } else if (vaso !== 'none' || (sbp < 90 && perf === 'bad')) {
    stageNum = 3; stageLetter = 'C'; tierClass = 'tier-warn';
    desc = '典型期 (Classic) — 需要血管活性药维持灌注';
    manage = '容量评估 · 升压药(首选NE) · 明确病因(冠脉造影/超声) · 目标MAP≥65。';
  } else if (sbp < 90 || lac > 2 || perf === 'bad') {
    stageNum = 2; stageLetter = 'B'; tierClass = 'tier-warn';
    desc = '起始期 (Beginning) — 低血压/低灌注, 对液体有反应';
    manage = '液体复苏(250-500mL晶体) · 寻找病因 · 监测乳酸/尿量。';
  } else {
    stageNum = 1; stageLetter = 'A'; tierClass = 'tier-ok';
    desc = '风险期 (At Risk) — 有休克风险, 目前无休克表现';
    manage = '密切监测生命体征和乳酸。';
  }

  const detail = `SCAI ${stageLetter} 级\n${desc}\n\n管理建议: ${manage}`;

  return { value: stageNum, unit: stageLetter, tier: desc, tierClass, footnote: detail };
}
