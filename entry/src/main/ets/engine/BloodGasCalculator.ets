export interface BgInput {
  ph: number | null;
  paco2: number | null;
  paco2Unit: string;
  pao2: number | null;
  pao2Unit: string;
  hco3: number | null;
  be: number | null;
  sao2: number | null;
  lac: number | null;
  hgb: number | null;
  hgbUnit: string;
  k: number | null;
  na: number | null;
  cl: number | null;
  glu: number | null;
  fio2: number | null;
  fio2Mode: string;
  acute: string;
  pvco2: number | null;
  pvco2Unit: string;
  svo2: number | null;
  pvo2: number | null;
  pvo2Unit: string;
}

export interface BgAbResult {
  conclusion: string;
  detail: string;
  tierText: string;
  tierCls: string;
  metabolicSubType: string;
}

export interface BgO2Result {
  conclusion: string;
  detail: string;
}

export interface BgHypoxiaResult {
  html: string;
}

export interface BgRResult {
  html: string;
}

export interface BgCriticalResult {
  html: string;
}

export interface BgSummaryResult {
  conclusion: string;
  detail: string;
}

export interface BgResult {
  ab: BgAbResult;
  o2: BgO2Result;
  hypoxia: BgHypoxiaResult;
  r: BgRResult;
  critical: BgCriticalResult;
  summary: BgSummaryResult;
  hhFailed: boolean;
}

function bgGet(val: number | null, unit: string, factor: number): number | null {
  if (val === null) return null;
  return unit === 'kpa' ? val * factor : val;
}

function getCause(diag: string, metabolicSubType: string, na: number | null, cl: number | null, hco3: number): string {
  const CAUSE_SINGLE: Record<string, string> = {
    '呼吸性酸中毒': 'COPD/肺心病(最常见)、哮喘重度、呼吸肌无力、中枢抑制、气道阻塞',
    '呼吸性碱中毒': '癔病/焦虑过度通气、脓毒症早期、肺栓塞/肺炎、机械通气过度',
    '代谢性碱中毒': '呕吐/胃管引流(最常见)、利尿剂、皮质激素、低钾低氯'
  };
  interface CauseMixItem { kw: RegExp; text: string }
  const CAUSE_MIX: CauseMixItem[] = [
    { kw: /TABD|三重/, text: '多脏衰、脓毒症、重症胰腺炎、复杂治疗叠加' },
    { kw: /呼酸.*代酸|代酸.*呼酸/, text: '心肺复苏、肺水肿、COPD 严重缺氧、药物中毒 (pH 显著下降, 危重)' },
    { kw: /呼酸.*代碱|代碱.*呼酸/, text: '肺心病呼酸治疗中(呕吐/激素/利尿/低盐) → 低钾低氯性碱中毒' },
    { kw: /呼碱.*代碱|代碱.*呼碱/, text: '双重碱化, pH>7.60 死亡率 65%, >7.64 达 90% (氧离曲线左移致组织缺氧)' },
    { kw: /呼碱.*代酸|代酸.*呼碱/, text: '脓毒败血症、肺栓塞合并肾衰、肺心病呼吸机不当(排 CO₂ 过多)+缺氧产酸' },
    { kw: /代谢性酸中毒.*代谢性碱中毒|代酸.*代碱|高AG.*代碱/, text: '高 AG 代酸 + 代碱, 血气 pH/HCO₃⁻/PaCO₂ 可看似正常, 必须算 AG 才不漏诊' }
  ];
  for (const m of CAUSE_MIX) {
    if (m.kw.test(diag)) return m.text;
  }
  let causes: string[] = [];
  if (/呼吸性酸中毒/.test(diag)) causes.push(CAUSE_SINGLE['呼吸性酸中毒']);
  else if (/呼吸性碱中毒/.test(diag)) causes.push(CAUSE_SINGLE['呼吸性碱中毒']);
  else if (/代谢性碱中毒/.test(diag)) causes.push(CAUSE_SINGLE['代谢性碱中毒']);
  else if (/代谢性酸中毒|代酸/.test(diag)) {
    if (metabolicSubType === 'highAG') {
      causes.push('高AG型: 乳酸酸中毒(休克/缺氧)、酮症(DKA)、肾衰、中毒(甲醇/乙二醇)');
    } else if (metabolicSubType === 'highCl') {
      causes.push('高氯性: 腹泻(最常见)、肾小管酸中毒、过多含氯液体');
    } else if (metabolicSubType === 'mixed') {
      causes.push('复合型(高AG+高氯): 糖尿病酮症酸中毒伴腹泻、肾功能不全 (教材L1884)');
    } else if (metabolicSubType === 'highAG+alk') {
      causes.push('高AG代酸+代碱: 糖尿病酮症酸中毒不适当补碱、呕吐合并酮症');
    } else if (metabolicSubType === 'unclear') {
      causes.push('分型不明确(AG/Cl均不显著), 需结合临床');
    } else if (na !== null && cl !== null) {
      const agTmp = na - (cl + hco3);
      causes.push(agTmp >= 20
        ? '高AG型: 乳酸酸中毒(休克/缺氧)、酮症(DKA)、肾衰、中毒(甲醇/乙二醇)'
        : '高氯性: 腹泻(最常见)、肾小管酸中毒、过多含氯液体');
    } else {
      causes.push('高AG型或高氯性 (需 Na/Cl 分型)');
    }
  }
  return causes.join('; ');
}

export function calculateBg(input: BgInput): BgResult {
  const ph = input.ph;
  const paco2 = bgGet(input.paco2, input.paco2Unit, 7.5);
  const pao2 = bgGet(input.pao2, input.pao2Unit, 7.5);
  const hco3 = input.hco3;
  const be = input.be;
  const sao2 = input.sao2;
  const lac = input.lac;
  const hgbRaw = input.hgb;
  const hgbUnit = input.hgbUnit;
  const hgb = (hgbRaw === null) ? null : (hgbUnit === 'gdl' ? hgbRaw * 10 : hgbRaw);
  const k = input.k;
  const na = input.na;
  const cl = input.cl;
  const glu = input.glu;
  const fio2Raw = input.fio2;
  const fio2Mode = input.fio2Mode;
  const fio2 = fio2Mode === 'pct' ? (fio2Raw !== null ? fio2Raw / 100 : null) : fio2Raw;
  const acute = input.acute || 'chronic';
  const pvco2 = bgGet(input.pvco2, input.pvco2Unit, 7.5);
  const svo2 = input.svo2;
  const pvo2 = bgGet(input.pvo2, input.pvo2Unit, 7.5);
  const hasVenous = (pvco2 !== null || svo2 !== null || pvo2 !== null);

  const needVenousHypoxia = '补充静脉血气(SvO\u2082、PvCO\u2082)后, 按 乳酸+SvO\u2082+GAP 三联分 8 种缺氧类型。';
  const needVenousR = '补充静脉血气(SvO\u2082、PvCO\u2082)与血红蛋白后, 计算 R = GAP / C(a-v)O\u2082。';

  if (ph === null || paco2 === null || hco3 === null || na === null || cl === null) {
    return {
      ab: { conclusion: '请填写必填项', detail: '', tierText: '需要 pH、PaCO\u2082、HCO\u2083\u207B', tierCls: 'tier-info', metabolicSubType: '' },
      o2: { conclusion: '\u2014', detail: '' },
      hypoxia: { html: needVenousHypoxia },
      r: { html: needVenousR },
      critical: { html: '输入参数后评估。' },
      summary: { conclusion: '输入参数后汇总异常。', detail: '' },
      hhFailed: false
    };
  }

  let primary = '';
  let tierCls = 'tier-ok';
  let metabolicSubType = '';
  let compText = '';
  let tabdText = '';

  const expHco3HH = 0.03 * paco2 * Math.pow(10, ph - 6.1);
  const hhDiff = Math.abs(hco3 - expHco3HH);

  if (hhDiff > 3) {
    const hhDetail = 'pH/PaCO\u2082/HCO\u2083\u207B 三者不自洽: 按 H-H 公式 pH ' + ph + ' + PaCO\u2082 ' + paco2 + ' 时 HCO\u2083\u207B 理论应为 ' + expHco3HH.toFixed(1) + ', 但实测 ' + hco3 + ' (差 ' + hhDiff.toFixed(1) + ')。\n请核对录入(常见: pH 或 HCO\u2083\u207B 填反)。\n\n数据不自洽时后续所有分析(氧合/缺氧分型/呼吸商/危急值/异常总览)均不可信, 已停止计算。';
    return {
      ab: { conclusion: '\u26A0 数据一致性校验未通过', detail: hhDetail, tierText: '数据校验', tierCls: 'tier-warn', metabolicSubType: '' },
      o2: { conclusion: '\u2014', detail: '数据一致性校验未通过, 氧合分析已停止。请先修正 pH/PaCO\u2082/HCO\u2083\u207B 录入。' },
      hypoxia: { html: '数据一致性校验未通过, 缺氧分型已停止。' },
      r: { html: '数据一致性校验未通过, 呼吸商计算已停止。' },
      critical: { html: '数据一致性校验未通过, 危急值评估已停止。' },
      summary: { conclusion: '数据校验未通过', detail: 'pH/PaCO\u2082/HCO\u2083\u207B 三者不自洽, 所有分析已停止。请核对录入后重算。' },
      hhFailed: true
    };
  }

  const isAcid = ph < 7.40;
  const isAlk = ph > 7.40;
  const paco2Dir = paco2 > 45 ? 'high' : paco2 < 35 ? 'low' : 'normal';
  const hco3Dir = hco3 > 27 ? 'high' : hco3 < 22 ? 'low' : 'normal';

  if (isAcid) {
    tierCls = 'tier-danger';
    if (paco2Dir === 'high' && hco3Dir === 'low') {
      primary = '混合性酸中毒 (呼吸性酸中毒 + 代谢性酸中毒)';
      compText = 'PaCO\u2082\u2191与HCO\u2083\u207B\u2193方向相反但都致酸 \u2192 无需代偿公式, 直接判定混合性酸中毒。';
    } else if (hco3Dir === 'low') {
      const expPaco2 = 1.5 * hco3 + 8;
      compText = '原发代酸(HCO\u2083\u207B' + hco3 + '<22)。代偿公式(Winter): 预计 PaCO\u2082 = 1.5\u00D7' + hco3 + '+8 = ' + expPaco2.toFixed(1) + ' \u00B12 mmHg (极限 10)。实际 PaCO\u2082 ' + paco2.toFixed(1) + ' \u2192 ';
      const diff = paco2 - expPaco2;
      if (paco2 < 10) {
        primary = '代谢性酸中毒 (已达呼吸代偿极限 PaCO\u2082<10, 仍代偿不足)';
        compText += '低于代偿极限 \u2192 呼吸代偿已达极限, 仍无法纠正。';
      } else if (Math.abs(diff) <= 2) {
        primary = '代谢性酸中毒 (单纯性, 代偿充分)';
        compText += '在预计范围内 \u2192 呼吸代偿恰当, 单纯性代酸。';
      } else if (diff > 2) {
        primary = '代谢性酸中毒 合并 呼吸性酸中毒';
        compText += '高于预计 \u2192 合并呼吸性酸中毒(通气不足)。';
      } else {
        primary = '代谢性酸中毒 合并 呼吸性碱中毒';
        compText += '低于预计 \u2192 合并呼吸性碱中毒(代偿过度/独立呼碱)。';
      }
    } else if (paco2Dir === 'high') {
      const isAcuteRacid = acute === 'acute';
      const coef = isAcuteRacid ? 0.1 : 0.35;
      const tol = isAcuteRacid ? 0 : 5.58;
      const limit = isAcuteRacid ? 30 : 45;
      const expHco3 = 24 + (paco2 - 40) * coef;
      const expHigh = expHco3 + tol;
      compText = '原发呼酸(PaCO\u2082' + paco2 + '>45)。代偿公式(' + (isAcuteRacid ? '急性' : '慢性') + '): \u25B3HCO\u2083\u207B=' + coef + '\u00D7\u25B3PaCO\u2082' + (isAcuteRacid ? '' : '\u00B15.58') + ', 预计 HCO\u2083\u207B \u2248 ' + expHco3.toFixed(1) + (isAcuteRacid ? '' : ' \u00B1 5.58') + ' (极限 ' + limit + ')。实际 HCO\u2083\u207B ' + hco3.toFixed(1) + ' \u2192 ';
      if (hco3 > limit) {
        primary = '呼吸性酸中毒 合并 代谢性碱中毒';
        compText += '超过代偿极限 ' + limit + ' \u2192 合并代谢性碱中毒。';
      } else if (!isAcuteRacid && Math.abs(hco3 - expHco3) <= tol) {
        primary = '呼吸性酸中毒 (单纯性, 代偿充分)';
        compText += '在预计范围内 \u2192 单纯性呼酸。';
      } else if (isAcuteRacid && hco3 <= expHigh + 0.5) {
        primary = '呼吸性酸中毒 (单纯性, 急性代偿微弱)';
        compText += '急性代偿微弱(HCO\u2083\u207B 仅升 ' + (hco3 - 24).toFixed(1) + '), 在极限内 \u2192 单纯性急呼酸。';
      } else if (hco3 > expHigh) {
        primary = '呼吸性酸中毒 合并 代谢性碱中毒';
        compText += '高于预计上限 \u2192 合并代谢性碱中毒。';
      } else {
        primary = '呼吸性酸中毒 合并 代谢性酸中毒';
        compText += '低于预计 \u2192 合并代谢性酸中毒。';
      }
    } else {
      tierCls = 'tier-warn';
      primary = '酸碱平衡 (pH 偏酸, PaCO\u2082/HCO\u2083\u207B 在正常范围, 轻度酸倾向)';
      compText = 'pH ' + ph + ' < 7.40 偏酸, 但 PaCO\u2082 ' + paco2 + '、HCO\u2083\u207B ' + hco3 + ' 均在正常范围, 提示轻度酸倾向或测量波动, 需结合临床动态监测。';
    }
  } else if (isAlk) {
    tierCls = 'tier-warn';
    if (paco2Dir === 'low' && hco3Dir === 'high') {
      primary = '混合性碱中毒 (呼吸性碱中毒 + 代谢性碱中毒)';
      compText = 'PaCO\u2082\u2193与HCO\u2083\u207B\u2191方向相反但都致碱 \u2192 无需代偿公式, 直接判定混合性碱中毒。';
      tierCls = 'tier-danger';
    } else if (hco3Dir === 'high') {
      const expPaco2 = 40 + 0.9 * (hco3 - 24);
      const effHigh = Math.min(expPaco2 + 5, 55);
      const effHighNote = effHigh < expPaco2 + 5 ? ', 有效上限取极限 55' : '';
      compText = '原发代碱(HCO\u2083\u207B' + hco3 + '>27)。代偿公式: \u25B3PaCO\u2082=0.9\u00D7\u25B3HCO\u2083\u207B, 预计 PaCO\u2082 = ' + expPaco2.toFixed(1) + ' \u00B1 5 mmHg (极限 55)' + effHighNote + '。实际 PaCO\u2082 ' + paco2.toFixed(1) + ' \u2192 ';
      if (paco2 > effHigh) {
        primary = '代谢性碱中毒 合并 呼吸性酸中毒';
        const extra = paco2 > 55 ? ' (超过代偿极限55, 通气不足显著)' : ' (公式范围内但超代偿极限)';
        compText += '高于有效上限' + effHigh.toFixed(1) + ' \u2192 合并呼吸性酸中毒' + extra + '。';
        tierCls = 'tier-danger';
      } else if (paco2 >= expPaco2 - 5) {
        primary = '代谢性碱中毒 (单纯性, 代偿充分)';
        compText += '在预计范围内 \u2192 呼吸代偿恰当, 单纯性代碱。';
      } else {
        primary = '代谢性碱中毒 合并 呼吸性碱中毒';
        compText += '低于预计 \u2192 合并呼吸性碱中毒。';
      }
    } else if (paco2Dir === 'low') {
      const isAcuteRalk = acute === 'acute';
      const coef = isAcuteRalk ? 0.2 : 0.49;
      const tol = isAcuteRalk ? 2.5 : 1.72;
      const limit = isAcuteRalk ? 18 : 15;
      const expHco3 = 24 - (40 - paco2) * coef;
      compText = '原发呼碱(PaCO\u2082' + paco2 + '<35)。代偿公式(' + (isAcuteRalk ? '急性' : '慢性') + '): \u25B3HCO\u2083\u207B=' + coef + '\u00D7\u25B3PaCO\u2082\u00B1' + tol + ', 预计 HCO\u2083\u207B = ' + expHco3.toFixed(1) + ' \u00B1 ' + tol + ' (极限 ' + limit + ')。实际 HCO\u2083\u207B ' + hco3.toFixed(1) + ' \u2192 ';
      if (hco3 < limit) {
        primary = '呼吸性碱中毒 合并 代谢性酸中毒';
        compText += '低于代偿极限 ' + limit + ' \u2192 合并代谢性酸中毒。';
        tierCls = 'tier-danger';
      } else if (Math.abs(hco3 - expHco3) <= tol) {
        primary = '呼吸性碱中毒 (单纯性, 代偿充分)';
        compText += '在预计范围内 \u2192 单纯性呼碱。';
      } else if (hco3 > expHco3 + tol) {
        primary = '呼吸性碱中毒 合并 代谢性碱中毒';
        compText += '高于预计上限 \u2192 合并代谢性碱中毒。';
        tierCls = 'tier-danger';
      } else {
        primary = '呼吸性碱中毒 合并 代谢性酸中毒';
        compText += '低于预计下限 \u2192 合并代谢性酸中毒。';
      }
    } else {
      primary = '酸碱平衡 (pH 偏碱, PaCO\u2082/HCO\u2083\u207B 在正常范围, 轻度碱倾向)';
      compText = 'pH ' + ph + ' > 7.40 偏碱, 但 PaCO\u2082 ' + paco2 + '、HCO\u2083\u207B ' + hco3 + ' 均在正常范围, 提示轻度碱倾向或测量波动, 需结合临床动态监测。';
    }
  } else {
    tierCls = 'tier-warn';
    if (paco2Dir === 'high' && hco3Dir === 'high') {
      primary = '呼吸性酸中毒 合并 代谢性碱中毒 (pH 7.40, 酸碱精确抵消)';
      compText = 'pH 严格 = 7.40, PaCO\u2082 ' + paco2 + '\u2191 + HCO\u2083\u207B ' + hco3 + '\u2191 同向偏离 \u2192 呼酸 + 代碱相互抵消致 pH 正好 7.40。需套代偿公式判断何者为主: ';
      const isAcuteRacid = acute === 'acute';
      const coef = isAcuteRacid ? 0.1 : 0.35;
      const tol = isAcuteRacid ? 0 : 5.58;
      const expHco3 = 24 + (paco2 - 40) * coef;
      compText += '呼酸公式预计 HCO\u2083\u207B \u2248 ' + expHco3.toFixed(1) + (isAcuteRacid ? '' : ' \u00B1 5.58') + ', 实测 ' + hco3.toFixed(1) + '。';
      if (hco3 > expHco3 + tol) compText += ' 实测高于代偿范围 \u2192 以代碱为主。';
      else if (hco3 < expHco3 - tol) compText += ' 实测低于代偿范围 \u2192 提示另有代酸因素。';
      else compText += ' 实测在代偿范围内 \u2192 呼酸与代碱程度相当。';
      tierCls = 'tier-danger';
    } else if (paco2Dir === 'low' && hco3Dir === 'low') {
      primary = '呼吸性碱中毒 合并 代谢性酸中毒 (pH 7.40, 酸碱精确抵消)';
      compText = 'pH 严格 = 7.40, PaCO\u2082 ' + paco2 + '\u2193 + HCO\u2083\u207B ' + hco3 + '\u2193 同向偏离 \u2192 呼碱 + 代酸相互抵消致 pH 正好 7.40。需套代偿公式判断何者为主: ';
      const isAcuteRalk = acute === 'acute';
      const coef = isAcuteRalk ? 0.2 : 0.49;
      const tol = isAcuteRalk ? 2.5 : 1.72;
      const expHco3 = 24 - (40 - paco2) * coef;
      compText += '呼碱公式预计 HCO\u2083\u207B \u2248 ' + expHco3.toFixed(1) + ' \u00B1 ' + tol + ', 实测 ' + hco3.toFixed(1) + '。';
      if (hco3 < expHco3 - tol) compText += ' 实测低于代偿范围 \u2192 以代酸为主。';
      else if (hco3 > expHco3 + tol) compText += ' 实测高于代偿范围 \u2192 提示另有代碱因素。';
      else compText += ' 实测在代偿范围内 \u2192 呼碱与代酸程度相当。';
      tierCls = 'tier-danger';
    } else {
      primary = '酸碱平衡正常';
      tierCls = 'tier-ok';
      compText = 'pH ' + ph + ', PaCO\u2082 ' + paco2 + ', HCO\u2083\u207B ' + hco3 + ' 均正常。';
    }
  }

  if (na !== null && cl !== null) {
    const ag = na - (cl + hco3);
    if (ag >= 20) {
      const deltaAG = ag - 16;
      const latentHco3 = hco3 + deltaAG;
      let upperLimit = 24;
      if (primary.includes('呼吸性酸中毒')) {
        const coef = acute === 'acute' ? 0.1 : 0.35;
        const tol = acute === 'acute' ? 0 : 5.58;
        upperLimit = 24 + coef * (paco2 - 40) + tol;
      } else if (primary.includes('呼吸性碱中毒')) {
        const coef = acute === 'acute' ? 0.2 : 0.49;
        const tol = acute === 'acute' ? 2.5 : 1.72;
        upperLimit = 24 - coef * (40 - paco2) + tol;
      }
      if (latentHco3 > upperLimit) {
        let diagType = '';
        let primaryLabel = '';
        let prelimLabel = '';
        let misdxLabel = '';
        if (paco2Dir === 'high') {
          diagType = '呼酸型 TABD';
          primaryLabel = '呼酸型 TABD (高AG型代谢性酸中毒 + 代谢性碱中毒 + 呼吸性酸中毒)';
          prelimLabel = '呼吸性酸中毒';
          misdxLabel = '呼吸性酸中毒';
        } else if (paco2Dir === 'low') {
          diagType = '呼碱型 TABD';
          primaryLabel = '呼碱型 TABD (高AG型代谢性酸中毒 + 代谢性碱中毒 + 呼吸性碱中毒)';
          prelimLabel = '呼吸性碱中毒';
          misdxLabel = '呼吸性碱中毒';
        } else {
          diagType = '代谢性酸中毒 + 代谢性碱中毒';
          primaryLabel = '高AG型代谢性酸中毒 + 代谢性碱中毒';
          prelimLabel = '酸碱平衡正常';
          misdxLabel = '无酸碱失衡(正常)';
        }
        primary = primaryLabel;
        tierCls = 'tier-danger';
        const prelim = compText.split(' \u2192 ')[0];
        compText = prelim + ' \u2192 初步判断为' + prelimLabel + '。但 AG=' + ag.toFixed(0) + '(\u2191, \u226520)' + (ag > 30 ? ' (确诊' : ' (提示') + '高 AG 型代酸), 计算潜在 HCO\u2083\u207B=' + latentHco3.toFixed(0) + ' > 代偿上限' + upperLimit.toFixed(1) + ' \u2192 高 AG 代酸消耗部分 HCO\u2083\u207B, 排除其掩盖作用后潜在 HCO\u2083\u207B 仍超上限 \u2192 合并代谢性碱中毒。综合为 ' + diagType + '。\n若不计算 AG 和潜在 HCO\u2083\u207B, 易误诊为\u300C' + misdxLabel + '\u300D。';
        tabdText = '';
      } else {
        tabdText = '\nAG=' + ag.toFixed(0) + '(\u2191), 潜在 HCO\u2083\u207B=' + latentHco3.toFixed(0) + ' \u2264 上限' + upperLimit.toFixed(1) + ', 无合并代碱。';
      }
    } else if (ag > 16) {
      tabdText = '\nAG=' + ag.toFixed(0) + ' (正常 8-16, 临界区 16-20, 仅 20% 有酸中毒), 建议结合临床动态观察, 不轻易诊断高 AG 代酸。';
    }
  }

  if (na !== null && cl !== null) {
    const ag = na - (cl + hco3);
    const acidRegex = /代酸|代谢性酸中毒/;
    if (acidRegex.test(primary)) {
      const dAG = ag - 16;
      const dCl = cl - 102;
      const absDHCO3 = Math.abs(24 - hco3);
      const agPart = dAG >= 2;
      const clPart = dCl >= 2;
      const tol2 = 2;
      let acidType = '';
      if (agPart && clPart) {
        const agNote = ag >= 20 ? (ag > 30 ? 'AG确诊高AG' : 'AG提示高AG') : (ag > 16 ? 'AG临界区' : 'AG正常');
        acidType = '复合型代酸 (高AG + 高氯性), |\u25B3HCO\u2083\u207B|=' + absDHCO3.toFixed(0) + ' > \u25B3AG=' + dAG.toFixed(0) + ' 且 > \u25B3Cl\u207B=' + dCl.toFixed(0) + ' (' + agNote + ')';
        metabolicSubType = 'mixed';
      } else if (agPart && !clPart) {
        if (absDHCO3 < dAG - tol2) {
          acidType = '高AG型代酸 + 代碱, AG升高数(\u25B3AG=' + dAG.toFixed(0) + ') > HCO\u2083\u207B下降数(|\u25B3HCO\u2083\u207B|=' + absDHCO3.toFixed(0) + '), \u25B3Cl\u207B=' + dCl.toFixed(0) + '(无高氯)';
          metabolicSubType = 'highAG+alk';
        } else {
          acidType = '高AG型代酸, AG=' + ag.toFixed(0) + '(\u226520' + (ag > 30 ? ', 确诊' : ', 提示') + '), |\u25B3HCO\u2083\u207B|=' + absDHCO3.toFixed(0) + ' \u2248 \u25B3AG=' + dAG.toFixed(0);
          metabolicSubType = 'highAG';
        }
      } else if (!agPart && clPart) {
        acidType = '高氯性代酸 (正常AG型), Cl=' + cl.toFixed(0) + '(\u2191), |\u25B3HCO\u2083\u207B|=' + absDHCO3.toFixed(0) + ' \u2248 \u25B3Cl\u207B=' + dCl.toFixed(0);
        metabolicSubType = 'highCl';
      } else {
        acidType = '代酸分型不明确, AG=' + ag.toFixed(0) + '(\u25B3AG=' + dAG.toFixed(0) + '<2) 且 Cl=' + cl.toFixed(0) + '(\u25B3Cl\u207B=' + dCl.toFixed(0) + '<2) 均不显著, 需结合临床';
        metabolicSubType = 'unclear';
      }
      tabdText += '\n代酸分型: AG=' + ag.toFixed(0) + ', ' + acidType + '。\n\u25B3AG=' + dAG.toFixed(0) + ' (基准AG\u221216), \u25B3Cl\u207B=' + dCl.toFixed(0) + ' (基准Cl\u2212102), |\u25B3HCO\u2083\u207B|=' + absDHCO3.toFixed(0) + '; 高AG成分' + (agPart ? '有' : '无') + ', 高氯成分' + (clPart ? '有' : '无') + '。';
    }
  }

  const abConclusion = primary;
  let abDetail = 'pH ' + ph.toFixed(2) + ' \u00B7 PaCO\u2082 ' + paco2.toFixed(1) + ' mmHg \u00B7 HCO\u2083\u207B ' + hco3.toFixed(1) + ' mmol/L';
  if (be !== null) abDetail += ' \u00B7 BE ' + (be > 0 ? '+' : '') + be.toFixed(1);
  if (compText) abDetail += '\n\n' + compText;
  if (tabdText) abDetail += tabdText;
  const abTierText = ph < 7.35 ? '酸血症' : ph > 7.45 ? '碱血症' : '代偿/正常';

  let o2Conclusion = '\u2014';
  let o2Detail = '';
  if (pao2 !== null && fio2 !== null) {
    const pf = pao2 / fio2;
    let pfTier = '';
    let pfTierCls = 'tier-ok';
    if (pf <= 100) { pfTier = '重度低氧合 (P/F \u2264 100, 达 ARDS 重度氧合界值)'; pfTierCls = 'tier-danger'; }
    else if (pf <= 200) { pfTier = '中度低氧合 (P/F 101-200, 达 ARDS 中度氧合界值)'; pfTierCls = 'tier-danger'; }
    else if (pf <= 300) { pfTier = '轻度低氧合 (P/F 201-300, 达 ARDS 轻度氧合界值)'; pfTierCls = 'tier-warn'; }
    else if (pf < 400) { pfTier = '氧合轻度受损 (P/F 300-400, 未达 ARDS 界值)'; pfTierCls = 'tier-warn'; }
    else { pfTier = '氧合正常 (P/F \u2265 400)'; pfTierCls = 'tier-ok'; }

    let respFail = '';
    if (pao2 < 60) {
      respFail = paco2 > 50 ? 'II 型呼吸衰竭 (PaO\u2082<60 + PaCO\u2082>50)' : 'I 型呼吸衰竭 (PaO\u2082<60, PaCO\u2082 正常/低)';
    }
    o2Conclusion = 'P/F = ' + pao2.toFixed(0) + '/' + fio2 + ' = ' + pf.toFixed(0) + ' \u00B7 ' + pfTier;
    if (respFail) o2Conclusion += ' \u00B7 ' + respFail;
    o2Detail = 'P/F = PaO\u2082/FiO\u2082, 正常 400-500。柏林/Matthay 2024 氧合分级: 轻 201-300 / 中 101-200 / 重 \u2264100, 插管患者需 PEEP \u2265 5。\u26A0 ARDS 诊断需临床排除心源性肺水肿/液体过负荷/肺不张\u2014\u2014本计算器仅报告氧合指数与分级, 不替代 ARDS 诊断。';

    let pao2Note = '';
    if (pao2 < 60) pao2Note = '低氧血症';
    else if (pao2 < 80) pao2Note = '轻度低氧';
    else pao2Note = '正常';
    o2Detail += '\nPaO\u2082 ' + pao2.toFixed(0) + ' mmHg (' + pao2Note + ')';

    const pao2Alv = fio2 * (760 - 47) - paco2 / 0.8;
    const aado2 = pao2Alv - pao2;
    let aado2Tier = aado2 < 15 ? '正常' : aado2 < 25 ? '轻度升高' : aado2 < 35 ? '中度升高' : '显著升高';
    o2Detail += '\n肺泡气方程: PAO\u2082 = ' + fio2 + '\u00D7713 \u2212 ' + paco2.toFixed(0) + '/0.8 = ' + pao2Alv.toFixed(0) + ' mmHg\nA-aDO\u2082 = ' + pao2Alv.toFixed(0) + ' \u2212 ' + pao2.toFixed(0) + ' = ' + aado2.toFixed(0) + ' mmHg (' + aado2Tier + ')';
    if (aado2 > 25) o2Detail += '\n\u26A0 A-aDO\u2082 增大提示肺换气障碍(V/Q 失调、分流、弥散障碍)。';
  } else if (pao2 !== null) {
    let pao2Note = pao2 < 60 ? '低氧血症' : pao2 < 80 ? '轻度低氧' : '正常';
    o2Conclusion = 'PaO\u2082 ' + pao2.toFixed(0) + ' mmHg (' + pao2Note + ')';
    o2Detail = '请填 FiO\u2082 计算 P/F 氧合指数与 A-aDO\u2082。';
  } else {
    o2Detail = '请填 PaO\u2082 和 FiO\u2082 评估氧合。';
  }

  let hypoxiaHtml = needVenousHypoxia;
  if (hasVenous && svo2 !== null && pvco2 !== null && lac !== null) {
    const gap = pvco2 - paco2;
    const lacHigh = lac > 2;
    const svo2Low = svo2 < 70;
    const gapHigh = gap > 6;
    let hypoxiaType = '';
    let hypoxiaCls = 'tier-ok';
    if (lacHigh && svo2Low && !gapHigh) { hypoxiaType = '低CO性缺氧'; hypoxiaCls = 'tier-danger'; }
    else if (lacHigh && svo2Low && gapHigh) { hypoxiaType = '低CO性缺氧(脓毒症)'; hypoxiaCls = 'tier-danger'; }
    else if (lacHigh && !svo2Low && gapHigh) { hypoxiaType = '微循环障碍性缺氧'; hypoxiaCls = 'tier-danger'; }
    else if (lacHigh && !svo2Low && !gapHigh) { hypoxiaType = '高CO性缺氧(脓毒症)'; hypoxiaCls = 'tier-warn'; }
    else if (!lacHigh && svo2Low && gapHigh) { hypoxiaType = '微循环障碍性缺氧'; hypoxiaCls = 'tier-warn'; }
    else if (!lacHigh && svo2Low && !gapHigh) { hypoxiaType = '低CO性缺氧(贫血)'; hypoxiaCls = 'tier-warn'; }
    else if (!lacHigh && !svo2Low && gapHigh) { hypoxiaType = '微循环障碍(无明显缺氧)'; hypoxiaCls = 'tier-warn'; }
    else { hypoxiaType = '正常'; hypoxiaCls = 'tier-ok'; }
    hypoxiaHtml = hypoxiaType + '|' + '三联指标: 乳酸 ' + lac + ' ' + (lacHigh ? '>2\u2191' : '\u22642\u2713') + ' \u00B7 SvO\u2082 ' + svo2 + '% ' + (svo2Low ? '<70\u2193' : '\u226570') + ' \u00B7 GAP ' + gap.toFixed(0) + ' mmHg ' + (gapHigh ? '>6\u2191' : '\u22646\u2713') + '|GAP = PvCO\u2082(' + pvco2.toFixed(0) + ') \u2212 PaCO\u2082(' + paco2.toFixed(0) + ') = ' + gap.toFixed(0) + '|' + hypoxiaCls + '|' + hypoxiaType;
  }

  let rHtml = needVenousR;
  if (hasVenous && svo2 !== null && pvco2 !== null && hgb !== null && pao2 !== null) {
    const gap = pvco2 - paco2;
    const hgbGdl = hgb / 10;
    const cao2 = 1.34 * hgbGdl * (sao2 !== null ? sao2 / 100 : 0.97) + 0.0031 * pao2;
    const cvo2 = 1.34 * hgbGdl * (svo2 / 100) + (pvo2 !== null ? 0.0031 * pvo2 : 0);
    const cavO2 = cao2 - cvo2;
    if (cavO2 > 0.01) {
      const R = gap / cavO2;
      let rTier = R < 0.8 ? '\u6B63\u5E38(\u6709\u6C27\u4EE3\u8C22)' : R <= 1.0 ? '\u8FB9\u7F18' : R <= 1.4 ? '\u65E0\u6C27\u4EE3\u8C22/\u7EC4\u7EC7\u7F3A\u6C27' : R <= 1.6 ? '\u65E0\u6C27\u4EE3\u8C22' : '\u5371\u91CD\u75C7\u5FAE\u5FAA\u73AF\u969C\u788D';
      let rCls = R < 0.8 ? 'tier-ok' : R <= 1.0 ? 'tier-warn' : 'tier-danger';
      rHtml = 'R = ' + R.toFixed(2) + ' \u00B7 ' + rTier + '|CaO\u2082 = 1.34\u00D7' + hgbGdl.toFixed(1) + '\u00D7' + (sao2 !== null ? sao2 : 97) + '% + 0.0031\u00D7' + pao2.toFixed(0) + ' = ' + cao2.toFixed(2) + ' mL/dL\nCvO\u2082 = 1.34\u00D7' + hgbGdl.toFixed(1) + '\u00D7' + svo2 + '%' + (pvo2 !== null ? ' + 0.0031\u00D7' + pvo2.toFixed(0) : '') + ' = ' + cvo2.toFixed(2) + ' mL/dL\nC(a-v)O\u2082 = ' + cao2.toFixed(2) + ' \u2212 ' + cvo2.toFixed(2) + ' = ' + cavO2.toFixed(2) + ' mL/dL\nR = GAP(' + gap.toFixed(0) + ') / C(a-v)O\u2082(' + cavO2.toFixed(2) + ') = ' + R.toFixed(2) + '\nR<0.8 \u6B63\u5E38 / >1.0 \u65E0\u6C27\u4EE3\u8C22 / >1.4-1.6 \u5371\u91CD\u75C7\u5FAE\u5FAA\u73AF\u969C\u788D|' + rCls + '|' + rTier;
    } else {
      rHtml = 'C(a-v)O\u2082 \u2248 0(\u52A8\u9759\u8109\u6C27\u9971\u548C\u5EA6\u5DEE\u8FC7\u5C0F), \u65E0\u6CD5\u8BA1\u7B97\u547C\u5438\u5546\u3002';
    }
  }

  let critHtml = '';
  if (lac !== null) {
    if (lac < 2) critHtml += 'ok|乳酸 ' + lac + ' mmol/L \u00B7 正常\n';
    else if (lac <= 4) critHtml += 'warn|\u26A0 乳酸 ' + lac + ' mmol/L \u00B7 中度升高 (死亡率\u224813.4%)\n';
    else if (lac <= 10) critHtml += 'danger|\u26A0 乳酸 ' + lac + ' mmol/L \u00B7 显著升高 (死亡率\u224840.9%, 危急值)\n';
    else critHtml += 'danger|\u26A0 乳酸 ' + lac + ' mmol/L \u00B7 极高 (脓毒症/脓毒性休克特征)\n';
  }
  if (hgb !== null) {
    if (hgb < 60) critHtml += 'danger|\u26A0 血红蛋白 ' + hgb + ' g/L \u00B7 严重贫血 (危急值 <60)\n';
    else critHtml += 'ok|\u2713 血红蛋白 ' + hgb + ' g/L 正常\n';
  }
  if (k !== null) {
    if (k < 3.5) critHtml += 'danger|\u26A0 K\u207A ' + k + ' mmol/L \u00B7 低钾血症\n';
    else if (k > 5.5) critHtml += 'danger|\u26A0 K\u207A ' + k + ' mmol/L \u00B7 高钾血症 (危急值 >5.5)\n';
    else critHtml += 'ok|\u2713 K\u207A ' + k + ' mmol/L 正常\n';
  }
  if (glu !== null) {
    if (glu > 12) critHtml += 'danger|\u26A0 血糖 ' + glu + ' mmol/L \u00B7 高血糖 (危急值 >12)\n';
    else if (glu < 3.9) critHtml += 'warn|\u26A0 血糖 ' + glu + ' mmol/L \u00B7 低血糖\n';
    else if (glu > 7.8) critHtml += 'warn|血糖 ' + glu + ' mmol/L \u00B7 偏高\n';
    else critHtml += 'ok|\u2713 血糖 ' + glu + ' mmol/L 正常\n';
  }
  if (na !== null) {
    if (na < 125) critHtml += 'danger|\u26A0 Na\u207A ' + na + ' mmol/L \u00B7 重度低钠 (危急值 <125)\n';
    else if (na < 135) critHtml += 'warn|Na\u207A ' + na + ' mmol/L \u00B7 低钠血症\n';
    else if (na > 155) critHtml += 'danger|\u26A0 Na\u207A ' + na + ' mmol/L \u00B7 重度高钠 (危急值 >155)\n';
    else if (na > 145) critHtml += 'warn|Na\u207A ' + na + ' mmol/L \u00B7 高钠血症\n';
    else critHtml += 'ok|\u2713 Na\u207A ' + na + ' mmol/L 正常\n';
  }
  if (cl !== null) {
    if (cl < 90) critHtml += 'danger|\u26A0 Cl\u207B ' + cl + ' mmol/L \u00B7 重度低氯 (危急值 <90, 易致代碱)\n';
    else if (cl < 98) critHtml += 'warn|Cl\u207B ' + cl + ' mmol/L \u00B7 低氯 (易致代碱, 警惕)\n';
    else if (cl > 115) critHtml += 'danger|\u26A0 Cl\u207B ' + cl + ' mmol/L \u00B7 重度高氯 (危急值 >115, 易致高氯性代酸)\n';
    else if (cl > 106) critHtml += 'warn|Cl\u207B ' + cl + ' mmol/L \u00B7 高氯 (易致高氯性代酸, 警惕)\n';
    else critHtml += 'ok|\u2713 Cl\u207B ' + cl + ' mmol/L 正常 (98-106)\n';
  }
  if (na !== null && cl !== null) {
    const agTmp = na - (cl + hco3);
    if (agTmp > 30) critHtml += 'danger|\u26A0 AG ' + agTmp.toFixed(0) + ' \u2191\u2191 确诊高 AG 代酸 (>30, 乳酸/酮症/肾衰/中毒)\n';
    else if (agTmp >= 20) critHtml += 'warn|AG ' + agTmp.toFixed(0) + ' \u2191 提示高 AG 代酸 (\u226520, 需结合临床)\n';
    else if (agTmp > 16) critHtml += 'warn|AG ' + agTmp.toFixed(0) + ' 临界 (16-20 仅 20% 有酸中毒, 动态观察)\n';
    else critHtml += 'ok|\u2713 AG ' + agTmp.toFixed(0) + ' 正常 (8-16)\n';
  }

  interface AbnormalItem { text: string; cls: string; sub: string }
  const abnormals: AbnormalItem[] = [];

  if (primary && !/正常|代偿$|代偿完全|无酸碱/.test(primary)) {
    abnormals.push({ text: '酸碱: ' + primary, cls: 'tier-danger', sub: '常见原因: ' + getCause(primary, metabolicSubType, na, cl, hco3) });
  }
  if (ph < 7.35) abnormals.push({ text: 'pH ' + ph + ' \u2193 (酸血症)', cls: 'tier-danger', sub: '' });
  else if (ph > 7.45) abnormals.push({ text: 'pH ' + ph + ' \u2191 (碱血症)', cls: 'tier-warn', sub: '' });

  if (pao2 !== null && fio2 !== null) {
    const pf = pao2 / fio2;
    if (pf <= 100) abnormals.push({ text: 'P/F ' + pf.toFixed(0) + ' (重度低氧合, 达 ARDS 重度氧合界值)', cls: 'tier-danger', sub: '' });
    else if (pf <= 200) abnormals.push({ text: 'P/F ' + pf.toFixed(0) + ' (中度低氧合, 达 ARDS 中度氧合界值)', cls: 'tier-danger', sub: '' });
    else if (pf <= 300) abnormals.push({ text: 'P/F ' + pf.toFixed(0) + ' (轻度低氧合, 达 ARDS 轻度氧合界值)', cls: 'tier-warn', sub: '' });
    const pao2Alv = fio2 * (760 - 47) - paco2 / 0.8;
    const aado2 = pao2Alv - pao2;
    if (aado2 > 25) abnormals.push({ text: 'A-aDO\u2082 ' + aado2.toFixed(0) + ' \u2191 (换气障碍)', cls: 'tier-warn', sub: '' });
  }
  if (pao2 !== null && pao2 < 60) abnormals.push({ text: 'PaO\u2082 ' + pao2.toFixed(0) + ' \u2193 (低氧血症)', cls: 'tier-danger', sub: '' });
  if (paco2 > 50) abnormals.push({ text: 'PaCO\u2082 ' + paco2.toFixed(0) + ' \u2191 (II 型呼衰/通气不足)', cls: 'tier-warn', sub: '' });
  else if (paco2 < 30) abnormals.push({ text: 'PaCO\u2082 ' + paco2.toFixed(0) + ' \u2193 (过度通气)', cls: 'tier-warn', sub: '' });

  if (hasVenous && svo2 !== null && pvco2 !== null && lac !== null) {
    const gap = pvco2 - paco2;
    const lacHigh = lac > 2;
    const svo2Low = svo2 < 70;
    const gapHigh = gap > 6;
    let hypoxiaType = '';
    if (lacHigh && svo2Low && !gapHigh) hypoxiaType = '低CO性缺氧';
    else if (lacHigh && svo2Low && gapHigh) hypoxiaType = '低CO性缺氧(脓毒症)';
    else if (lacHigh && !svo2Low && gapHigh) hypoxiaType = '微循环障碍性缺氧';
    else if (lacHigh && !svo2Low && !gapHigh) hypoxiaType = '高CO性缺氧(脓毒症)';
    else if (!lacHigh && svo2Low && gapHigh) hypoxiaType = '微循环障碍性缺氧';
    else if (!lacHigh && svo2Low && !gapHigh) hypoxiaType = '低CO性缺氧(贫血)';
    else if (!lacHigh && !svo2Low && gapHigh) hypoxiaType = '微循环障碍(无明显缺氧)';
    else hypoxiaType = '正常';
    if (hypoxiaType && hypoxiaType !== '正常') {
      abnormals.push({ text: '缺氧: ' + hypoxiaType, cls: 'tier-warn', sub: '' });
    }
  }

  if (hasVenous && svo2 !== null && pvco2 !== null && hgb !== null && pao2 !== null) {
    const gap = pvco2 - paco2;
    const hgbGdl = hgb / 10;
    const cao2 = 1.34 * hgbGdl * (sao2 !== null ? sao2 / 100 : 0.97) + 0.0031 * pao2;
    const cvo2 = 1.34 * hgbGdl * (svo2 / 100) + (pvo2 !== null ? 0.0031 * pvo2 : 0);
    const cavO2 = cao2 - cvo2;
    if (cavO2 > 0.01) {
      const R = gap / cavO2;
      if (R > 1.0) {
        abnormals.push({ text: '\u547C\u5438\u5546 R=' + R.toFixed(2) + ' \u2191 (>1.0 \u65E0\u6C27\u4EE3\u8C22)', cls: 'tier-danger', sub: '' });
      }
    }
    }

  if (k !== null && (k < 3.5 || k > 5.5)) abnormals.push({ text: 'K\u207A ' + k + ' mmol/L ' + (k < 3.5 ? '\u2193' : '\u2191') + ' (危急值)', cls: 'tier-danger', sub: '' });
  if (na !== null && (na < 135 || na > 145)) abnormals.push({ text: 'Na\u207A ' + na + ' mmol/L ' + (na < 135 ? '\u2193' : '\u2191'), cls: (na < 125 || na > 155) ? 'tier-danger' : 'tier-warn', sub: '' });
  if (cl !== null && (cl < 98 || cl > 106)) abnormals.push({ text: 'Cl\u207B ' + cl + ' mmol/L ' + (cl < 98 ? '\u2193' : '\u2191') + ' (正常 98-106, 中位 102)', cls: 'tier-warn', sub: '' });
  if (lac !== null && lac > 2) abnormals.push({ text: '乳酸 ' + lac + ' \u2191 ' + (lac > 4 ? '(显著, 死亡率\u224840.9%)' : '(组织缺氧/低灌注)'), cls: lac > 4 ? 'tier-danger' : 'tier-warn', sub: '' });
  if (na !== null && cl !== null) {
    const ag = na - (cl + hco3);
    if (ag >= 20) abnormals.push({ text: 'AG ' + ag.toFixed(0) + ' \u2191 (\u226520 提示高 AG 代酸, >30 确诊)', cls: 'tier-warn', sub: '' });
  }

  let sumConclusion = '';
  let sumDetail = '';
  if (abnormals.length === 0) {
    const checked: string[] = [];
    const unchecked: string[] = [];
    checked.push('酸碱');
    if (pao2 !== null || paco2 !== null) checked.push('氧合'); else unchecked.push('氧合');
    if (k !== null || na !== null || cl !== null) checked.push('电解质'); else unchecked.push('电解质');
    if (lac !== null) checked.push('乳酸'); else unchecked.push('乳酸');
    if (hgb !== null) checked.push('血红蛋白'); else unchecked.push('血红蛋白');
    const checkedStr = checked.join('\u3001');
    sumConclusion = unchecked.length === 0
      ? checkedStr + '均在正常范围'
      : checkedStr + '在正常范围 (其余未查)';
    sumDetail = unchecked.length === 0
      ? '未见超出阈值的异常项。'
      : '未见超出阈值的异常项。\n\u26A0 未查: ' + unchecked.join('\u3001');
  } else {
    const dangerCount = abnormals.filter(a => a.cls === 'tier-danger').length;
    sumConclusion = '共 ' + abnormals.length + ' 项异常' + (dangerCount > 0 ? ' (其中 ' + dangerCount + ' 项危急)' : '');
    const detailLines: string[] = [];
    for (const a of abnormals) {
      const main = a.cls === 'tier-danger' ? '\u2022 ' + a.text : '\u2022 ' + a.text;
      const sub = a.sub ? '\n  ' + a.sub : '';
      detailLines.push(main + sub);
    }
    sumDetail = detailLines.join('\n');
  }
  if (na !== null && cl !== null) {
    sumDetail += '\n\n\u26A0 本结果基于实测 AG / 实测 Na 计算。若白蛋白 < 25 g/L (2.5 g/dL), 实测 AG 可能被低估 (校正 AG = 实测 + 2.5 \u00D7 (4 \u2212 白蛋白 g/dL)); 若血糖 > 22 mmol/L (400 mg/dL), 实测 Na 被稀释, AG 假性升高 (校正 Na = 实测 + 1.6 \u00D7 (Glu mg/dL \u2212 100) / 100)。建议结合临床校正后判断。';
  }

  return {
    ab: { conclusion: abConclusion, detail: abDetail, tierText: abTierText, tierCls: tierCls, metabolicSubType: metabolicSubType },
    o2: { conclusion: o2Conclusion, detail: o2Detail },
    hypoxia: { html: hypoxiaHtml },
    r: { html: rHtml },
    critical: { html: critHtml || '输入参数后评估。' },
    summary: { conclusion: sumConclusion, detail: sumDetail },
    hhFailed: false
  };
}
