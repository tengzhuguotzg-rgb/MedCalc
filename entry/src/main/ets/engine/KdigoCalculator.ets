import { CalcResult } from './CalcEngine';

export function calculateKdigo(
  cr0Raw: number | null, cr0Unit: string,
  cr1Raw: number, cr1Unit: string,
  urine: number | null,
  rrt: boolean
): CalcResult {
  if (cr1Raw <= 0) {
    return { value: null, unit: '', tier: '请填写当前 Cr', tierClass: 'tier-info', footnote: '' };
  }

  const cr0 = cr0Raw !== null && cr0Raw > 0 ? (cr0Unit === 'umol' ? cr0Raw / 88.4 : cr0Raw) : null;
  const cr1 = cr1Unit === 'umol' ? cr1Raw / 88.4 : cr1Raw;

  let stage = 0;
  const reasons: string[] = [];

  if (rrt) {
    stage = 3;
    reasons.push('已启动 RRT');
  }

  if (cr0 !== null && cr0 > 0) {
    const delta = cr1 - cr0;
    const ratio = cr1 / cr0;
    if (cr1 >= 4.0 || delta >= 0.3 || ratio >= 3) {
      stage = Math.max(stage, 3);
      if (cr1 >= 4.0) reasons.push('Cr ≥ 4.0 mg/dL');
      if (delta >= 0.3) reasons.push('Cr 升高 ≥ 0.3 mg/dL (48h)');
      if (ratio >= 3) reasons.push('Cr 较基线升高 ≥ 3 倍');
    } else if (ratio >= 2) {
      stage = Math.max(stage, 2);
      reasons.push('Cr 升高 ≥ 2-2.9 倍');
    } else if (ratio >= 1.5 || delta >= 0.3) {
      stage = Math.max(stage, 1);
      if (ratio >= 1.5) reasons.push('Cr 升高 ≥ 1.5-1.9 倍');
      if (delta >= 0.3) reasons.push('Cr 升高 ≥ 0.3 mg/dL (48h)');
    }
  } else {
    if (cr1 >= 4.0) {
      stage = Math.max(stage, 3);
      reasons.push('Cr ≥ 4.0 mg/dL');
    } else if (cr1 >= 1.5) {
      stage = Math.max(stage, 1);
      reasons.push('Cr ≥ 1.5 mg/dL (无基线, 粗估)');
    }
  }

  if (urine !== null && urine > 0) {
    if (urine < 0.3) {
      stage = Math.max(stage, 3);
      reasons.push('尿量 < 0.3 mL/kg/h × ≥24h');
    } else if (urine < 0.5) {
      stage = Math.max(stage, 2);
      reasons.push('尿量 < 0.5 mL/kg/h × ≥12h');
    }
  }

  let tier: string;
  let tierClass: string;
  let footnote: string;

  if (stage === 0) {
    tier = '无 AKI';
    tierClass = 'tier-ok';
    footnote = '无 AKI · 肌酐无显著变化。';
  } else if (stage === 1) {
    tier = 'AKI 1 期';
    tierClass = 'tier-warn';
    footnote = '早期损伤。寻找诱因, 停用肾毒性药物, 监测尿量+肌酐, 充分灌注。';
  } else if (stage === 2) {
    tier = 'AKI 2 期';
    tierClass = 'tier-danger';
    footnote = '进一步损伤。肾科会诊, 评估 RRT 启动指征, 调整药物剂量。';
  } else {
    tier = 'AKI 3 期';
    tierClass = 'tier-danger';
    footnote = '严重损伤。紧急肾科会诊, 评估 RRT (AKI+无尿/高钾/酸中毒/容量过负荷)。';
  }

  const reasonText = reasons.length > 0 ? reasons.join(' + ') : '无';
  footnote += `\n触发条件: ${reasonText}`;

  return { value: stage, unit: '/ 3', tier, tierClass, footnote };
}
