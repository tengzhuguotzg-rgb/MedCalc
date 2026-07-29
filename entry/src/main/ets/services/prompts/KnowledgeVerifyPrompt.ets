/**
 * KnowledgeVerifyPrompt.ets
 *
 * 知识库搜索结果 LLM 校验 的 prompt 模块。
 *
 * 内容包括：
 * 1. buildKnowledgeVerifySystemPrompt()：发给 LLM 的 system prompt，定义 Y/P/N 三级相关度判断标准。
 * 2. buildKnowledgeVerifyPrompt(query, resultsSummary)：构造 user text，传入查询词与候选文章列表。
 *
 * 被 KnowledgeSearch.verifyResultsWithLlm() 调用。
 */

/**
 * 静态 system prompt：定义"重症医学知识库搜索验收"的三级判断标准（Y/P/N）与输出格式。
 * 之所以单独抽出：纯静态内容，可独立单元测试；调用方只关心 system vs user 的拼接。
 */
export function buildKnowledgeVerifySystemPrompt(): string {
  return '你是重症医学知识库搜索验收专家。给定用户查询词和候选文章列表（含文章摘要），对每篇文章判断其与查询词的相关程度。' +
    '\n\n三级判断标准：' +
    'Y(全文相关)：文章的主要主题就是查询词所述的疾病/综合征，或者是该疾病的核心病因疾病/核心治疗措施。' +
    '例如：查询"Ⅰ型呼吸衰竭"，ARDS是核心病因→Y，氧疗/机械通气/无创通气/高流量氧疗是核心治疗→Y，肺炎/肺栓塞是常见病因→Y。' +
    '查询"代谢性酸中毒"，乳酸酸中毒/酮症酸中毒是核心病因→Y，碳酸氢钠/血液透析/CRRT是核心治疗→Y，糖尿病/休克/急性肾损伤是常见病因→Y。' +
    'P(片段相关)：文章主要主题不是查询词疾病，但文章中有独立段落专门讨论查询词疾病的诊断、监测、治疗等临床内容。' +
    'N(不相关)：文章仅顺带提及查询词。' +
    '\n\n关键：宁可多判Y/P，不要漏掉临床相关文献。' +
    '\n\n输出格式：每篇文章输出"编号:Y"或"编号:P"或"编号:N"，用逗号分隔。不要解释。';
}

/**
 * 构造 verify 流程的 user text。
 *
 * @param query          原始查询词。调用方已自行把 description 拼到 query 后（例如 "query（description）"）。
 * @param resultsSummary 候选文章列表的格式化文本（每行形如 "1. [path] 摘要：..."）。
 *                        注意：调用方应自行完成 description 处理与 docList 拼接，本函数只做最终模板化。
 */
export function buildKnowledgeVerifyPrompt(query: string, resultsSummary: string): string {
  return '查询词：' + query + '\n候选文章：\n' + resultsSummary;
}
