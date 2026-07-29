/**
 * KnowledgeExpandPrompt.ets
 *
 * 知识库查询词扩展 的 LLM prompt 模块。
 *
 * 包含三组 prompt：
 * 1. 默认 fallback（被 expandQueryWithLlm 缺省时使用）：buildKnowledgeExpandSystemPrompt / buildKnowledgeExpandPrompt。
 * 2. R2 反馈重试（第一轮搜索全部不相关时使用）：buildKnowledgeExpandR2SystemPrompt / buildKnowledgeExpandR2Prompt。
 * 3. V2 五行结构化扩展（expandQueryV2 使用）：buildKnowledgeExpandV2SystemPrompt / buildKnowledgeExpandV2Prompt。
 *
 * 被 KnowledgeSearch.expandQueryWithLlm() 与 KnowledgeSearch.expandQueryV2() 调用。
 */

/**
 * 默认 fallback system prompt：扩查询（3-6 个 ICU 临床术语），强调"临床词 vs 学术分类"。
 * 用于 expandQueryWithLlm() 在调用方未传 customSystemPrompt 时的兜底。
 */
export function buildKnowledgeExpandSystemPrompt(): string {
  return '你是重症医学文献检索专家。用户会给你一个临床诊断及其诊断依据，用于在ICU知识库中搜索相关文献。' +
    '请基于诊断名称和诊断依据，生成3-6个扩展检索词。' +
    '\n\n扩展策略（按优先级）：' +
    '1. 同义词/缩写：如"脓毒症"→"败血症""Sepsis"，"AKI"→"急性肾损伤""急性肾衰竭""ARF"' +
    '2. 核心病因/并发症：如"Ⅰ型呼吸衰竭"→"ARDS""急性呼吸窘迫综合征"，"感染性休克"→"脓毒症休克"' +
    '3. 关键治疗/监测主题：如"呼吸衰竭"→"氧疗""机械通气""呼吸支持"，"AKI"→"肾替代治疗""CRRT"' +
    '4. 常见关联疾病：如"Ⅱ型呼吸衰竭"→"COPD""慢性阻塞性肺病"' +
    '\n只输出扩展词，每行一个，不要编号，不要解释，不要输出原查询词。' +
    '\n\n重要约束：' +
    '1. 扩展词应该是ICU指南和教材中常见的疾病名/综合征名/治疗主题名，而不是学术分类名或病理生理描述。' +
    '2. 例如"代谢性酸中毒"不要扩展为"阴离子间隙""高氯性酸中毒""乳酸性酸中毒"等学术分类，' +
    '而应扩展为"脓毒症""休克""急性肾损伤""液体复苏""碳酸氢钠""CRRT"等能直接匹配到文献主题的临床词。' +
    '3. 严格只输出3-6个词，不要输出超过6个。';
}

/**
 * 默认 fallback user text：传 query 与可选 description（"诊断标准"）。
 * 用于 expandQueryWithLlm() 在调用方未传 customUserText 时的兜底。
 */
export function buildKnowledgeExpandPrompt(query: string, description: string): string {
  return '诊断名称：' + query + (description.length > 0 ? '\n诊断标准：' + description : '');
}

/**
 * R2 反馈重试 system prompt：第一轮搜索全部不相关时，要求重新生成更精准的扩展词。
 */
export function buildKnowledgeExpandR2SystemPrompt(): string {
  return '你是重症医学文献检索专家。用户正在ICU知识库中搜索文献，但第一轮搜索未找到相关结果。' +
    '请根据反馈信息重新生成3-6个扩展检索词。只输出扩展词，每行一个，不要编号，不要解释。' +
    '扩展词必须是ICU指南和教材中常见的疾病名/综合征名/治疗主题名，不要用学术分类名。' +
    '例如不要输出"阴离子间隙""高氯性酸中毒"，而应输出"脓毒症""休克""CRRT"等临床词。';
}

/**
 * R2 反馈重试 user text：把原始 query 与第一轮失败时观察到的"主题列表"反馈给 LLM。
 *
 * @param query          原始查询词。
 * @param feedbackTopics 第一轮 FTS 命中的前若干篇文章的所属主题（按|分隔的中文串，由调用方构造）。
 */
export function buildKnowledgeExpandR2Prompt(query: string, feedbackTopics: string): string {
  return '查询词"' + query + '"的第一轮搜索结果全部不相关。搜索结果主题包括：' +
    feedbackTopics + '。请重新生成3-6个更精准的扩展检索词，覆盖不同方向。';
}

/**
 * V2 五行结构化扩展 system prompt：要求 LLM 输出"搜索词 / 目录 / 病因 / 治疗 / 监测"五行结果。
 *
 * 目录列表来自 KnowledgeSearch.KB_DIRECTORIES，但为了让 prompt 模块与具体目录常量解耦，
 * 调用方需把"中文疾病目录"与"英文指南目录"两段字符串分别传入。
 *
 * @param chineseDirs 过滤后的中文疾病目录段（|分隔）。
 * @param englishDirs 过滤后的英文指南目录段（|分隔，含年份开头）。
 */
export function buildKnowledgeExpandV2SystemPrompt(chineseDirs: string, englishDirs: string): string {
  return '你是重症医学文献检索专家。用户会给你一个ICU临床诊断，你需要为该诊断在知识库中查找相关文献。' +
    '\n\n知识库目录分两类，用|分隔列出：' +
    '\n【中文疾病目录】' + chineseDirs +
    '\n【英文指南目录（非常重要，含最新国际指南，务必优先选择）】' + englishDirs +
    '\n\n请按以下5行格式输出（严格5行）：' +
    '\n第1行：搜索词 — 该诊断的同义词/缩写/别名（3-8个），用空格分隔' +
    '\n第2行：相关目录名 — 从上面目录列表中选择与该诊断直接或间接相关的目录（5-15个），用|分隔，英文指南目录优先' +
    '\n第3行：病因相关词 — 该诊断的常见病因/诱因/关联疾病的临床检索词（3-8个），用空格分隔' +
    '\n第4行：治疗相关词 — 该诊断的关键治疗措施/药物/操作的临床检索词（3-8个），用空格分隔' +
    '\n第5行：监测相关词 — 该诊断的核心监测指标/评估方法/评分工具（3-8个），用空格分隔' +
    '\n\n输出规则：' +
    '\n1. 搜索词必须是ICU指南和教材中常见的临床术语，不要用学术分类名' +
    '\n2. 目录名必须完全照搬上面的目录列表原文（含空格、年份等），不要拆分、缩写或改写目录名，用|分隔多个目录' +
    '\n3. 英文指南目录与中文疾病目录可能指向同一批文件（如"急性呼吸窘迫综合征"和"2023 ESICM ARDS Guidelines"都含ARDS内容），两者都要选' +
    '\n4. 病因/治疗/监测词应覆盖该诊断在ICU场景下的主要临床维度' +
    '\n5. 严格只输出5行，不要编号，不要解释，不要输出原诊断名';
}

/**
 * V2 五行结构化扩展 user text：传 query 与可选 description（"诊断依据"）。
 */
export function buildKnowledgeExpandV2Prompt(query: string, description: string): string {
  return '诊断名称：' + query + (description.length > 0 ? '\n诊断依据：' + description : '');
}
