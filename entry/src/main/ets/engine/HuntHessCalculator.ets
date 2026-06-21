import { CalcResult } from './CalcEngine';

export function calculateHuntHess(grade: number): CalcResult {
  let tier: string;
  let tierClass: string;
  let footnote: string;

  if (grade === 0) {
    tier = '未破裂';
    tierClass = 'tier-ok';
    footnote = '无症状，偶然发现';
  } else if (grade === 1) {
    tier = 'I 级';
    tierClass = 'tier-ok';
    footnote = '轻微头痛，无神经功能缺损';
  } else if (grade === 2) {
    tier = 'II 级';
    tierClass = 'tier-warn';
    footnote = '中重度头痛，脑神经麻痹';
  } else if (grade === 3) {
    tier = 'III 级';
    tierClass = 'tier-warn';
    footnote = '嗜睡，轻度神经功能缺损';
  } else if (grade === 4) {
    tier = 'IV 级';
    tierClass = 'tier-danger';
    footnote = '昏迷，中重度偏瘫';
  } else if (grade === 5) {
    tier = 'V 级';
    tierClass = 'tier-danger';
    footnote = '深昏迷，去脑强直';
  } else {
    tier = '请选择分级';
    tierClass = 'tier-info';
    footnote = '';
  }

  return { value: grade, unit: '级', tier, tierClass, footnote };
}

export function calculateWfns(grade: number): CalcResult {
  let tier: string;
  let tierClass: string;
  let footnote: string;

  if (grade === 0) {
    tier = '未破裂';
    tierClass = 'tier-ok';
    footnote = 'GCS 15，无神经功能缺损';
  } else if (grade === 1) {
    tier = 'I 级';
    tierClass = 'tier-ok';
    footnote = 'GCS 15，无神经功能缺损';
  } else if (grade === 2) {
    tier = 'II 级';
    tierClass = 'tier-warn';
    footnote = 'GCS 13-14，无神经功能缺损';
  } else if (grade === 3) {
    tier = 'III 级';
    tierClass = 'tier-warn';
    footnote = 'GCS 13-14，有神经功能缺损';
  } else if (grade === 4) {
    tier = 'IV 级';
    tierClass = 'tier-danger';
    footnote = 'GCS 7-12';
  } else if (grade === 5) {
    tier = 'V 级';
    tierClass = 'tier-danger';
    footnote = 'GCS 3-6';
  } else {
    tier = '请选择分级';
    tierClass = 'tier-info';
    footnote = '';
  }

  return { value: grade, unit: '级', tier, tierClass, footnote };
}

export function calculateFisher(grade: number): CalcResult {
  let tier: string;
  let tierClass: string;
  let footnote: string;

  if (grade === 0) {
    tier = '未破裂';
    tierClass = 'tier-ok';
    footnote = 'CT未见出血';
  } else if (grade === 1) {
    tier = 'I 级';
    tierClass = 'tier-ok';
    footnote = '薄层出血，<1mm厚度';
  } else if (grade === 2) {
    tier = 'II 级';
    tierClass = 'tier-warn';
    footnote = '薄层出血，<1mm厚度，但范围较广';
  } else if (grade === 3) {
    tier = 'III 级';
    tierClass = 'tier-danger';
    footnote = '厚层出血，≥1mm厚度';
  } else if (grade === 4) {
    tier = 'IV 级';
    tierClass = 'tier-danger';
    footnote = '脑内血肿或脑室出血';
  } else {
    tier = '请选择分级';
    tierClass = 'tier-info';
    footnote = '';
  }

  return { value: grade, unit: '级', tier, tierClass, footnote };
}
