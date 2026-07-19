import { CalcResult } from './CalcEngine';

export function calculateRass(score: number): CalcResult {
  let tier: string;
  let tierClass: string;
  let footnote: string;

  if (score === -5) {
    tier = '无法唤醒';
    tierClass = 'tier-danger';
    footnote = '对声音或物理刺激无反应';
  } else if (score === -4) {
    tier = '深度镇静';
    tierClass = 'tier-danger';
    footnote = '对物理刺激无反应';
  } else if (score === -3) {
    tier = '中度镇静';
    tierClass = 'tier-warn';
    footnote = '对声音无反应，对物理刺激有反应';
  } else if (score === -2) {
    tier = '轻度镇静';
    tierClass = 'tier-warn';
    footnote = '对声音有反应，但无法长时间保持觉醒';
  } else if (score === -1) {
    tier = '嗜睡';
    tierClass = 'tier-ok';
    footnote = '对声音有反应，能保持觉醒≥10秒';
  } else if (score === 0) {
    tier = '清醒平静';
    tierClass = 'tier-ok';
    footnote = '完全清醒，无躁动';
  } else if (score === 1) {
    tier = '不安焦虑';
    tierClass = 'tier-warn';
    footnote = '轻度躁动，但无攻击行为';
  } else if (score === 2) {
    tier = '躁动';
    tierClass = 'tier-warn';
    footnote = '频繁无目的动作，可能对抗呼吸机';
  } else if (score === 3) {
    tier = '非常躁动';
    tierClass = 'tier-danger';
    footnote = '极度躁动，拔除输液管或导管';
  } else if (score === 4) {
    tier = '好斗';
    tierClass = 'tier-danger';
    footnote = '暴力行为，对工作人员有直接危险';
  } else {
    return { value: null, unit: '', tier: '请填写必填项', tierClass: 'tier-info', footnote: '' };
  }

  return {
    value: score,
    unit: '分',
    tier,
    tierClass,
    footnote
  };
}
