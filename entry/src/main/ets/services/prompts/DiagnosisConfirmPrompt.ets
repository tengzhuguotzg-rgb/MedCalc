/**
 * DiagnosisConfirmPrompt.ets
 *
 * 提取 PatientService.confirmDiagnosesWithLlm() 中的 LLM 系统提示词。
 * 该提示词用于让 LLM 以 ICU 主治医师身份对系统已自动匹配的疑似诊断
 * 进行确认或驳回，并补充说明。
 *
 * 静态部分（角色、任务说明、JSON 输出格式）作为常量字符串。
 * diagnosisList 与 dataSummary 参数保留在签名中以便后续扩展，
 * 当前系统提示词不直接拼接这些动态数据（动态数据由调用方拼入 userText）。
 */

/**
 * 构建诊断确认 LLM 系统提示词。
 * @param diagnosisList 已匹配的疑似诊断列表（格式由调用方负责组装）
 * @param dataSummary 患者数据摘要（label=value 空格分隔）
 * @returns 用于 sendVisionRequest 的 systemPrompt 字符串
 */
export function buildDiagnosisConfirmPrompt(diagnosisList: string, dataSummary: string): string {
  // 保留参数以便后续在系统提示词中注入上下文
  void diagnosisList;
  void dataSummary;

  const systemPrompt = '你是一名ICU主治医师。根据患者数据和计算器结果，系统已自动匹配以下疑似诊断。' +
    '请对每项诊断确认是否成立，并补充说明。' +
    '严格按以下JSON格式回复，不要添加其他内容：' +
    '{"confirmations":[{"ruleId":"id","status":"confirmed或rejected或uncertain","note":"补充说明"}]}';
  return systemPrompt;
}
