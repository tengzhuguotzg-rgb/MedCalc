/**
 * CalcExtractionPrompt.ets
 *
 * 提取 AssistantService.buildExtractionPrompt() 中的 LLM 系统提示词。
 * 该提示词用于从用户文字描述或医学检查报告图片中提取医疗参数数值，
 * 并判断哪些计算器可用。
 *
 * 静态部分（角色说明、重要规则、字段定义、输出格式）作为常量字符串，
 * DATA_FIELDS 与 CALC_INPUT_SPECS 动态拼接到提示词中。
 */

import { DATA_FIELDS, CALC_INPUT_SPECS } from '../../model/FieldSchema';
import { CALCULATORS } from '../../model/CalculatorRegistry';

/**
 * 构建医学数据提取助手使用的 LLM 系统提示词。
 * @returns 完整的系统提示词字符串
 */
export function buildExtractionPrompt(): string {
  let prompt = '你是医学数据提取助手。从用户文字描述或医学检查报告图片中提取所有可识别的医疗参数数值，判断哪些计算器可用。\n';
  prompt += '## 重要规则\n';
  prompt += '- 如果输入是医学检查报告图片（如血气分析、生化检验、血常规等），仔细识别图片中每一项指标及其数值，尽可能多地提取，不要遗漏\n';
  prompt += '- 提取的字段键名必须使用下方列表中准确的 field_key，不要自行翻译或缩写\n';
  prompt += '- 特别注意：PaO2的字段键名是pao2(不是po2)，PaCO2的键名是paco2(不是pco2)，SpO2的键名是spo2(不是sao2)\n';
  prompt += '- 数值和单位要按字段定义转换（如肌酐mg/dL需标注crUnit为mgdl，FiO2百分比需转换为小数如40%→0.4并标注fio2Mode为pct）\n';
  prompt += '- 图片中明确标注的数值均可提取，不需要用户逐项提及\n';
  prompt += '- **只提取图片中明确可见/标注的数值，不要推断、猜测或补全任何未标注的参数**（如FiO2未标注则不提取fio2字段，不要推断为0.21或其他值）\n';
  prompt += '- **报告上的检查日期和时间也必须提取**，分别放入reportDate和reportTime字段，格式：reportDate为YYYY-MM-DD（如2025-01-15），reportTime为HH:MM（如14:30）。如果只有日期没有时间，reportTime留空；如果都没有则两个字段都不填\n\n';
  prompt += '## 可提取字段\n';
  for (const f of DATA_FIELDS) {
    let line = f.key + ': ' + f.label + '(' + f.unit + ')';
    if (f.type === 'select' && f.options) {
      line += ' 选项:' + f.options.join('/');
    }
    if (f.normalRange) {
      line += ' 参考:' + f.normalRange;
    }
    prompt += line + '\n';
  }
  prompt += '\n## 计算器ID列表（matched数组必须使用以下准确的calcId！）\n';
  prompt += '注：这些是系统中定义的计算器ID，matched中只能使用这些ID，不要使用拼音、英文翻译或缩写。\n';
  for (const spec of CALC_INPUT_SPECS) {
    const calc = CALCULATORS.find(c => c.id === spec.calcId);
    if (calc) {
      prompt += spec.calcId + '(' + calc.name + '): 必填[' + spec.requiredFields.join(',') + ']';
      if (spec.optionalFields.length > 0) {
        prompt += ' 可选[' + spec.optionalFields.join(',') + ']';
      }
      prompt += '\n';
    }
  }
  prompt += '\n常见别名对应关系（请勿使用别名，统一用左侧calcId）：\n';
  prompt += 'pf-ratio(氧合指数)→pf, anion-gap(阴离子间隙)→cag, blood-gas(血气分析)→bg, corrected-calcium(校正钙)→系统中无独立计算器, osmolal-gap(渗透压间隙)→系统中无独立计算器\n';
  prompt += '\n## 输出格式\n';
  prompt += '严格输出JSON，不要输出任何其他文字：\n';
  prompt += '{"extracted":{"field_key":"value",...},"matched":["calcId1","calcId2",...]}\n';
  prompt += '规则：1.从文字或图片中尽可能多提取明确可识别的数值 2.数值统一为数字字符串单位按字段定义 3.sex字段用male/female 4.布尔字段用0/1 5.matched列出所有至少有1个必填字段的计算器按相关度排序，必须使用上面列表中准确的calcId 6.如确实无法提取任何医疗数据返回{"extracted":{},"matched":[]}';
  return prompt;
}
