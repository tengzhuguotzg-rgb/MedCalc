import { CalcResult } from './CalcEngine';

export function calculateCamicu(f1: number, f2: number, f3: number, f4: number): CalcResult {
  const positive = f1 === 1 && f2 === 1 && (f3 === 1 || f4 === 1);

  let tier: string;
  let tierClass: string;
  let footnote: string;

  if (positive) {
    tier = '谵妄阳性';
    tierClass = 'tier-danger';
    footnote = '特征① + ② + (③ 或 ④) 均满足。\n处理: 去除诱因(感染/药物/代谢) · 非药物干预(早期活动/睡眠/眼镜/助听器) · 避免苯二氮卓类\n躁动型: 右美托嘧啶/氟哌啶醇 · 低活动型: 首先去除诱因';
  } else {
    tier = '谵妄阴性';
    tierClass = 'tier-ok';
    footnote = '不符合 CAM-ICU 谵妄标准。\n继续常规监测, 尤其高危患者(COS/高龄/镇静后)。';
  }

  const detailText = f3 === 1 && f4 === 1 ? '③+④' : (f3 === 1 ? '③' : '④');
  const detail = `\n\n① 急性波动: ${f1 === 1 ? '有' : '无'}\n② 注意力缺损: ${f2 === 1 ? '有' : '无'}\n③ 意识改变: ${f3 === 1 ? '有' : '无'}\n④ 思维紊乱: ${f4 === 1 ? '有' : '无'}\n判定: ①+②+${detailText} = ${positive ? '阳性' : '阴性'}`;

  return { value: positive ? 1 : 0, unit: '', tier, tierClass, footnote: footnote + detail };
}
