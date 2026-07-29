/**
 * ClarifyPrompt.ets
 *
 * 多轮卡片式澄清推荐 的 LLM prompt 构建模块。
 *
 * 内容包括：
 * 1. CLARIFY_DIMENSIONS：R1 固定问卷维度（代码控制，不由 LLM 选择）。
 * 2. buildClarifySystemPrompt()：发给 LLM 的 system prompt，描述推荐/追问逻辑与计算器列表。
 *
 * 被 LlmService.sendClarifyRound() 调用；CLARIFY_DIMENSIONS 同时被 LlmDialog
 * 经由 LlmService 的 re-export 引用，避免改动外部消费者。
 */

import { CALCULATORS } from '../../model/CalculatorRegistry';

// ClarifyDimension 接口与问卷维度数据同源，集中在此模块声明以便 LlmDialog 通过 LlmService re-export 引用。
// 放在 ClarifyPrompt.ets 而非 LlmService.ets 是为了避免 ClarifyPrompt 与 LlmService 之间的循环依赖。
export interface ClarifyDimension {
  key: string;
  label: string;
  prompt: string;
  options: string[];
  multi: boolean; // 是否多选
}

// R1 固定问卷维度（代码控制，不由 LLM 选择）
export const CLARIFY_DIMENSIONS: ClarifyDimension[] = [
  { key: 'symptom', label: '主诉', prompt: '主要症状/主诉是什么？', multi: true, options: ['胸痛/胸闷', '呼吸困难/低氧', '意识障碍/昏迷', '休克/低血压', '下肢肿痛', '腹痛/恶心呕吐', '出血/凝血异常', '发热/感染', '电解质/代谢紊乱', '药物过量/中毒', '无明显症状'] },
  { key: 'system', label: '系统', prompt: '关注哪个器官系统？', multi: true, options: ['心血管', '呼吸', '神经', '肝肾', '消化/腹部', '血液/凝血', '感染/脓毒症', '代谢/电解质', '暂无特定方向'] },
  { key: 'setting', label: '场景', prompt: '当前在什么场景？', multi: false, options: ['ICU', '急诊', '病房', '门诊'] },
  { key: 'acuity', label: '急慢性', prompt: '病情是急性还是慢性？', multi: false, options: ['急性发作', '慢性/持续', '不确定'] },
];

export function buildClarifySystemPrompt(): string {
  let prompt = '你是一个临床医学计算器推荐助手。用户已通过固定问卷提供了基本信息（主诉、器官系统、场景、急慢性），你需要基于这些信息决定是否需要进一步追问，还是直接推荐计算器。\n';
  prompt += '推荐逻辑：根据用户的临床问题方向推荐，而非根据用户已有什么检查/数据推荐。计算器是用来辅助诊断/评估/排查的工具，"有什么数据"只决定能不能填表单，不决定该不该推荐。\n';
  prompt += '规则：\n';
  prompt += '1. 严格输出JSON，不要输出任何其他文字。\n';
  prompt += '2. 如果问卷信息已足够推荐，action 设为 "recommend"，返回 recommendations（最多8个，按相关性排序，仅推荐真正相关的，不凑数）。每个 recommendation 必须包含 id 和 reason 两个字段，reason 是一句话说明为什么推荐这个计算器（结合用户的问卷信息），不能省略、不能为空。同时返回 summary 字段，一句话说明为什么推荐这几个。\n';
  prompt += '3. 如果需要进一步追问才能定位（如区分同类计算器、排查矛盾信息），action 设为 "clarify"，返回 1-2 个自由设计的追问问题。每个问题含 dimension（自定义标识）、prompt（问题文本）、options（选项数组）、multi（是否多选，true/false）。当追问涉及"有哪些症状/表现"类可叠加信息时设 multi:true，当追问是"选一个方向"类互斥选择时设 multi:false。\n';
  prompt += '4. 追问应聚焦于能区分候选计算器的关键信息，如"是评估意识深度还是筛查谵妄""是右下腹痛还是上腹痛""需要快速筛查还是器官衰竭评估"等。\n';
  prompt += '5. 同类计算器不必强行区分，一起推荐，让用户自行选择。同类分组如下：\n';
  prompt += '   - 氧合指数：bg/sf/pf\n';
  prompt += '   - 肾功能：crcl/gfr\n';
  prompt += '   - SAH分级：hunthess/wfns/fisher\n';
  prompt += '   - 心梗评分：timistemi/timinstemi\n';
  prompt += '   - 阑尾炎：alvarado/ripasa\n';
  prompt += '   - 脓毒症评分：sofa/qsofa/sirs/lacclear\n';
  prompt += '   - 意识评估：gcs/gcsp/four\n';
  prompt += '   - 肝衰竭分级：childpugh/clifc/aarc\n';
  prompt += '   - 房颤评估：chadsvasc/hasbled\n';
  prompt += '   - 升压药：vis/vasopressor\n';
  prompt += '   - 血压/休克：map/shocki\n\n';
  prompt += '计算器列表（ID: 名称(英文名) - 关键词 - 用途 - 适用场景）：\n';
  for (const calc of CALCULATORS) {
    prompt += `${calc.id}: ${calc.name}(${calc.enName}) - ${calc.kw} - ${calc.description}。适用: ${calc.whenToUse}\n`;
  }
  prompt += '\n示例1（信息充分，直接推荐）：\n';
  prompt += '问卷结果：主诉=无明显症状, 系统=肝肾, 场景=病房, 急慢性=慢性\n';
  prompt += '{"confidence":0.85,"action":"recommend","summary":"根据慢性肾功能评估的需求，推荐CrCl和eGFR用于肾功能分期与药物剂量调整","recommendations":[{"id":"crcl","reason":"肌酐清除率，药物剂量调整"},{"id":"gfr","reason":"eGFR，CKD分期评估"}]}\n';
  prompt += '\n示例2（需追问区分候选，单选）：\n';
  prompt += '问卷结果：主诉=意识障碍, 系统=神经, 场景=ICU, 急慢性=急性\n';
  prompt += '{"confidence":0.4,"action":"clarify","questions":[{"dimension":"purpose","prompt":"目的是评估意识深度还是筛查谵妄还是排查卒中？","options":["评估意识深度","筛查谵妄","排查卒中"],"multi":false}]}\n';
  prompt += '\n示例3（需追问区分同类，单选）：\n';
  prompt += '问卷结果：主诉=发热, 系统=感染, 场景=急诊, 急慢性=急性\n';
  prompt += '{"confidence":0.4,"action":"clarify","questions":[{"dimension":"purpose","prompt":"需要哪种感染评估？","options":["快速筛查","器官衰竭评估","乳酸达标追踪","病房预警"],"multi":false}]}\n';
  prompt += '\n示例4（需追问且多选，如多症状/多系统受累时追问具体表现）：\n';
  prompt += '问卷结果：主诉=胸痛+呼吸困难, 系统=心血管, 场景=急诊, 急慢性=急性\n';
  prompt += '{"confidence":0.4,"action":"clarify","questions":[{"dimension":"symptom_detail","prompt":"胸痛的特征是什么？可多选","options":["撕裂样剧痛(夹层)","压榨样(心梗)","胸膜性(PE/胸膜)","钝痛"],"multi":true}]}\n';
  return prompt;
}
