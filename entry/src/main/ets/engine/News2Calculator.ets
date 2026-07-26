import { CalcResult } from './CalcEngine';

function news2ScoreResp(r: number): number {
  if (r <= 8) return 3;
  if (r <= 11) return 1;
  if (r <= 20) return 0;
  if (r <= 24) return 2;
  return 3;
}

function news2ScoreSpo2(s: number, onO2: boolean): number {
  if (onO2) {
    // Scale 2（高碳酸血症呼吸衰竭，COPD 等）：88-92 为目标区间
    if (s <= 83) return 3;
    if (s <= 85) return 2;
    if (s <= 87) return 1;
    if (s <= 92) return 0;
    if (s <= 94) return 1;
    if (s <= 96) return 2;
    return 3;
  }
  if (s <= 91) return 3;
  if (s <= 93) return 2;
  if (s <= 95) return 1;
  return 0;
}

function news2ScoreTemp(t: number): number {
  if (t <= 35.0) return 3;
  if (t <= 36.0) return 1;
  if (t <= 38.0) return 0;
  if (t <= 39.0) return 1;
  return 2;
}

function news2ScoreSbp(s: number): number {
  if (s <= 90) return 3;
  if (s <= 100) return 2;
  if (s <= 110) return 1;
  if (s <= 219) return 0;
  return 3;
}

function news2ScoreHr(h: number): number {
  if (h <= 40) return 3;
  if (h <= 50) return 1;
  if (h <= 90) return 0;
  if (h <= 110) return 1;
  if (h <= 130) return 2;
  return 3;
}

export function calculateNews2(
  rr: number, spo2: number, o2supplement: string,
  temp: number, sbp: number, hr: number, consciousness: string
): CalcResult {
  if (rr <= 0 || spo2 <= 0 || o2supplement === '' || temp <= 0 || sbp <= 0 || hr <= 0 || consciousness === '') {
    return {
      value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: ''
    };
  }

  const onO2 = o2supplement === 'yes';
  const rScore = news2ScoreResp(rr);
  const sScore = news2ScoreSpo2(spo2, onO2);
  const o2Pts = onO2 ? 2 : 0;
  const tScore = news2ScoreTemp(temp);
  const sbpScore = news2ScoreSbp(sbp);
  const hrScore = news2ScoreHr(hr);
  const cScore = consciousness !== 'alert' ? 3 : 0;

  let total = rScore + sScore + o2Pts + tScore + sbpScore + hrScore + cScore;

  let tier: string;
  let tierClass: string;
  let footnote: string;

  if (total >= 7) {
    tier = '高风险';
    tierClass = 'tier-danger';
    footnote = '≥7 临床紧急风险, 需立即评估, 考虑 ICU 转入。';
  } else if (total >= 5) {
    tier = '中风险';
    tierClass = 'tier-warn';
    footnote = '5-6 中风险, 需住院或密切监测。';
  } else if (total >= 1) {
    tier = '低风险';
    tierClass = 'tier-warn';
    footnote = '1-4 低风险, 可在病房监测。';
  } else {
    tier = '正常';
    tierClass = 'tier-ok';
    footnote = '0 分各项指标正常。';
  }

  return { value: total, unit: '', tier, tierClass, footnote };
}
