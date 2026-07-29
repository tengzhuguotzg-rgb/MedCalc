/**
 * DiagnosisSuggestPrompt.ets
 *
 * 提取 PatientService.suggestDiagnosesWithLlm() 中的 LLM 系统提示词。
 * 该提示词用于在规则引擎未匹配到确定性诊断时，让 LLM 分析患者数据
 * 给出最可能的诊断提示（最多 5 个）。
 *
 * 静态部分（角色、说明、JSON 输出格式）作为常量字符串。
 * dataSummary 参数保留在签名中以便后续扩展。
 */

/**
 * 构建诊断建议 LLM 系统提示词。
 * @param dataSummary 患者数据摘要（label=value 空格分隔）
 * @returns 用于 sendVisionRequest 的 systemPrompt 字符串
 */
export function buildDiagnosisSuggestPrompt(dataSummary: string): string {
  // 保留参数以便后续在系统提示词中注入上下文
  void dataSummary;

  const systemPrompt = '你是一名ICU主治医师。根据患者数据，系统未能完全匹配任何确定性诊断规则。' +
    '请分析患者数据，给出最可能的诊断提示（最多5个）。' +
    '每个提示说明：1)诊断名 2)可能性(高/中/低) 3)已有支持数据 4)还需要什么检查来确认。' +
    '注意：仅给出提示，不做确诊。' +
    '严格按JSON格式回复：{"suggestions":[{"name":"诊断名","category":"感染|呼吸|肾脏|心血管|神经|血液|肝|代谢|营养","likelihood":"高|中|低","supportingData":"已有支持","missingChecks":"需要补充的检查"}]}';
  return systemPrompt;
}
