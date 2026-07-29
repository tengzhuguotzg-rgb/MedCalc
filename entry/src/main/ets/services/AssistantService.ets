import { CalcResult } from '../engine/CalcEngine';
import { CalcDispatcher } from './CalcDispatcher';
import { CALCULATORS } from '../model/CalculatorRegistry';
import { ApiServiceConfig, sendVisionRequest, extractJsonPayload } from './LlmService';


import { DataFieldSpec, CalcInputSpec, DATA_FIELDS, CALC_ID_ALIASES, FIELD_KEY_ALIASES, CALC_INPUT_SPECS, normalizeFieldKey, normalizeForSearch } from '../model/FieldSchema';

// Re-export: 保持下游 import 路径不变（PatientService / PatientDetailPage 等仍从 AssistantService 导入）
export { DataFieldSpec, CalcInputSpec };


export class CalcMatch {
  calcId: string = '';
  calcName: string = '';
  icon: string = '📊';
  completeness: number = 0;
  availableFields: string[] = [];
  missingFields: string[] = [];
  result: CalcResult | null = null;
}

export class AssistantMessage {
  id: string = '';
  role: 'user' | 'assistant' = 'user';
  timestamp: number = 0;
  text: string = '';
  imageUri: string = '';
  extractedData: Record<string, string> = {};
  matches: CalcMatch[] = [];
  summaryText: string = '';
}

class ExtractionResult {
  fields: Map<string, string> = new Map();
  matchedCalcIds: string[] = [];
}

let msgIdCounter: number = 0;

function generateMsgId(): string {
  msgIdCounter++;
  return 'msg_' + msgIdCounter;
}

export class AssistantService {
  private static instance: AssistantService;
  private messages: AssistantMessage[] = [];
  private allExtractedData: Map<string, string> = new Map();

  private constructor() {}

  static getInstance(): AssistantService {
    if (!AssistantService.instance) {
      AssistantService.instance = new AssistantService();
    }
    return AssistantService.instance;
  }

  getMessages(): AssistantMessage[] {
    return this.messages;
  }

  getAllExtractedData(): Record<string, string> {
    const result: Record<string, string> = {};
    this.allExtractedData.forEach((val: string, key: string) => {
      result[key] = val;
    });
    return result;
  }

  private getExtractedDataRecord(): Record<string, string> {
    const result: Record<string, string> = {};
    this.allExtractedData.forEach((val: string, key: string) => {
      result[key] = val;
    });
    return result;
  }

  clearSession(): void {
    this.messages = [];
    this.allExtractedData = new Map();
  }

  sendMessage(text: string, imageBase64: string, imageMime: string, config: ApiServiceConfig): Promise<AssistantMessage> {
    const userMsg = new AssistantMessage();
    userMsg.id = generateMsgId();
    userMsg.role = 'user';
    userMsg.timestamp = Date.now();
    userMsg.text = text;
    this.messages = [...this.messages, userMsg];

    const systemPrompt = this.buildExtractionPrompt();
    const hasImage = imageBase64.length > 0 && imageMime.length > 0;
    const userContent = text.length > 0 ? text : '请从这张医学检查报告中提取所有可识别的医疗数据参数';

    const requestPromise = hasImage
      ? sendVisionRequest(config, systemPrompt, userContent, imageBase64, imageMime)
      : sendVisionRequest(config, systemPrompt, text, '', '');

    return requestPromise.then((llmContent: string): AssistantMessage => {
      const parsed = this.parseExtractionResponse(llmContent);
      const newFieldsRecord: Record<string, string> = {};
      parsed.fields.forEach((val: string, key: string) => {
        newFieldsRecord[key] = val;
        this.allExtractedData.set(key, val);
      });

      const mergedRecord = this.getExtractedDataRecord();
      const matches = this.computeAllMatches(mergedRecord, parsed.matchedCalcIds);

      const summary = this.buildSummary(newFieldsRecord, matches);

      const assistantMsg = new AssistantMessage();
      assistantMsg.id = generateMsgId();
      assistantMsg.role = 'assistant';
      assistantMsg.timestamp = Date.now();
      assistantMsg.extractedData = newFieldsRecord;
      assistantMsg.matches = matches;
      assistantMsg.summaryText = summary;
      this.messages = [...this.messages, assistantMsg];
      return assistantMsg;
    });
  }

  getCalcInputSpecs(): CalcInputSpec[] {
    return CALC_INPUT_SPECS;
  }

  computeAllMatchesFromRecord(data: Record<string, string>): CalcMatch[] {
    return this.computeAllMatches(data, []);
  }

  getDataFieldSpecs(): DataFieldSpec[] {
    return DATA_FIELDS;
  }

  getFieldLabel(key: string): string {
    for (let i = 0; i < DATA_FIELDS.length; i++) {
      if (DATA_FIELDS[i].key === key) {
        return DATA_FIELDS[i].label;
      }
    }
    return key;
  }

  getFieldSpec(key: string): DataFieldSpec | null {
    for (let i = 0; i < DATA_FIELDS.length; i++) {
      if (DATA_FIELDS[i].key === key) {
        return DATA_FIELDS[i];
      }
    }
    return null;
  }

  supplementData(fields: Record<string, string>): AssistantMessage {
    const entries = Object.entries(fields);
    for (let i = 0; i < entries.length; i++) {
      this.allExtractedData.set(entries[i][0], entries[i][1]);
    }

    const mergedRecord = this.getExtractedDataRecord();
    const matches = this.computeAllMatches(mergedRecord, []);

    for (let i = 0; i < this.messages.length; i++) {
      if (this.messages[i].role === 'assistant' && this.messages[i].matches.length > 0) {
        this.messages[i].matches = matches;
        this.messages[i].summaryText = this.buildSummaryFromMatches(matches);
        this.messages[i].id = generateMsgId();
      }
    }

    this.messages = [...this.messages];
    const lastAssistant = this.findLastAssistantWithMatches();
    if (lastAssistant !== null) {
      return lastAssistant;
    }
    const fallback = new AssistantMessage();
    fallback.id = generateMsgId();
    fallback.role = 'assistant';
    fallback.timestamp = Date.now();
    fallback.matches = matches;
    return fallback;
  }

  private findLastAssistantWithMatches(): AssistantMessage | null {
    for (let i = this.messages.length - 1; i >= 0; i--) {
      if (this.messages[i].role === 'assistant' && this.messages[i].matches.length > 0) {
        return this.messages[i];
      }
    }
    return null;
  }

  getExtractionPrompt(): string {
    return this.buildExtractionPrompt();
  }

  private buildExtractionPrompt(): string {
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
    prompt += '规则：1.从文字或图片中尽可能多提取明确可识别的数值 2.数值统一为数字字符串单位按字段定义 3.sex字段用male/female 4.布尔字段用0/1 5.matched列出所有至少有1个必填字段的计算器按相关度排序，必须使用上面列表中准确的calcId 6.如确实无法提取任何医疗数据返回{"extracted":{},"matched":[]}\n';
    return prompt;
  }

  private parseExtractionResponse(content: string): ExtractionResult {
    const result = new ExtractionResult();

    const jsonStr = extractJsonPayload(content);
    if (jsonStr.length === 0) {
      return this.fallbackParse(content);
    }

    try {
      const parsedStr: Object | null = JSON.parse(jsonStr);
      if (parsedStr === null || parsedStr === undefined) {
        return this.fallbackParse(content);
      }
      const parsed = parsedStr as Record<string, Object>;
      const extractedStr = parsed['extracted'];
      const matchedStr = parsed['matched'];

      if (extractedStr !== undefined && extractedStr !== null && typeof extractedStr === 'object') {
        if (Array.isArray(extractedStr)) {
          const arr = extractedStr as Object[];
          for (let ai = 0; ai < arr.length; ai++) {
            if (typeof arr[ai] === 'object' && arr[ai] !== null) {
              const itemEntries = Object.entries(arr[ai] as Record<string, string>);
              for (let ei = 0; ei < itemEntries.length; ei++) {
                const k = itemEntries[ei][0];
                const v = itemEntries[ei][1];
                const normalized = normalizeFieldKey(k);
                const aliasKey = FIELD_KEY_ALIASES[normalized];
                const resolvedKey = aliasKey !== undefined ? aliasKey : normalized;
                if (typeof v === 'string' && v.length > 0) {
                  result.fields.set(resolvedKey, v);
                } else if (typeof v === 'number') {
                  result.fields.set(resolvedKey, String(v));
                }
              }
            }
          }
        } else {
          const entries = Object.entries(extractedStr as Record<string, string>);
          for (let i = 0; i < entries.length; i++) {
            const key = entries[i][0];
            const val = entries[i][1];
            const normalized = normalizeFieldKey(key);
            const aliasKey = FIELD_KEY_ALIASES[normalized];
            const resolvedKey = aliasKey !== undefined ? aliasKey : normalized;
            if (typeof val === 'string' && val.length > 0) {
              result.fields.set(resolvedKey, val);
            } else if (typeof val === 'number') {
              result.fields.set(resolvedKey, String(val));
            }
          }
        }
      }

      if (matchedStr !== undefined && matchedStr !== null && Array.isArray(matchedStr)) {
        const matchArr = matchedStr as string[];
        for (let i = 0; i < matchArr.length; i++) {
          const m: string = matchArr[i];
          if (typeof m === 'string' && m.length > 0) {
            const id = m.trim().toLowerCase();
            const aliasId = CALC_ID_ALIASES[id];
            const resolvedId = aliasId !== undefined ? aliasId : id;
            if (CALCULATORS.some(c => c.id === resolvedId)) {
              if (!result.matchedCalcIds.some(existing => existing === resolvedId)) {
                result.matchedCalcIds.push(resolvedId);
              }
            }
          }
        }
      }

      return result;
    } catch (_e) {
      const braceStart = jsonStr.indexOf('{');
      const braceEnd = jsonStr.lastIndexOf('}');
      if (braceStart !== -1 && braceEnd > braceStart) {
        const candidate = jsonStr.substring(braceStart, braceEnd + 1);
        try {
          const parsedCandidate: Object | null = JSON.parse(candidate);
          if (parsedCandidate !== null && parsedCandidate !== undefined) {
            const parsed2 = parsedCandidate as Record<string, Object>;
            const extractedStr2 = parsed2['extracted'];
            const matchedStr2 = parsed2['matched'];
            if (extractedStr2 !== undefined && extractedStr2 !== null && typeof extractedStr2 === 'object') {
              if (Array.isArray(extractedStr2)) {
                const arr2 = extractedStr2 as Object[];
                for (let ai = 0; ai < arr2.length; ai++) {
                  if (typeof arr2[ai] === 'object' && arr2[ai] !== null) {
                    const itemEntries = Object.entries(arr2[ai] as Record<string, string>);
                    for (let ei = 0; ei < itemEntries.length; ei++) {
                      const k = itemEntries[ei][0];
                      const v = itemEntries[ei][1];
                      const normalized2 = normalizeFieldKey(k);
                      const aliasKey2 = FIELD_KEY_ALIASES[normalized2];
                      const resolvedKey2 = aliasKey2 !== undefined ? aliasKey2 : normalized2;
                      if (typeof v === 'string' && v.length > 0) {
                        result.fields.set(resolvedKey2, v);
                      } else if (typeof v === 'number') {
                        result.fields.set(resolvedKey2, String(v));
                      }
                    }
                  }
                }
              } else {
                const entries2 = Object.entries(extractedStr2 as Record<string, string>);
                for (let i = 0; i < entries2.length; i++) {
                  const key2 = entries2[i][0];
                  const val2 = entries2[i][1];
                  const normalized2 = normalizeFieldKey(key2);
                  const aliasKey2 = FIELD_KEY_ALIASES[normalized2];
                  const resolvedKey2 = aliasKey2 !== undefined ? aliasKey2 : normalized2;
                  if (typeof val2 === 'string' && val2.length > 0) {
                    result.fields.set(resolvedKey2, val2);
                  } else if (typeof val2 === 'number') {
                    result.fields.set(resolvedKey2, String(val2));
                  }
                }
              }
            }
            if (matchedStr2 !== undefined && matchedStr2 !== null && Array.isArray(matchedStr2)) {
              const matchArr2 = matchedStr2 as string[];
              for (let i = 0; i < matchArr2.length; i++) {
                const m2: string = matchArr2[i];
                if (typeof m2 === 'string' && m2.length > 0) {
                  const id2 = m2.trim().toLowerCase();
                  const aliasId2 = CALC_ID_ALIASES[id2];
                  const resolvedId2 = aliasId2 !== undefined ? aliasId2 : id2;
                  if (CALCULATORS.some(c => c.id === resolvedId2)) {
                    if (!result.matchedCalcIds.some(existing => existing === resolvedId2)) {
                      result.matchedCalcIds.push(resolvedId2);
                    }
                  }
                }
              }
            }
            return result;
          }
        } catch (_e2) {}
      }
      return this.fallbackParse(content);
    }
  }
  public parseExtractionResponsePublic(content: string): Record<string, string> {
    const result = this.parseExtractionResponse(content);
    const record: Record<string, string> = {};
    result.fields.forEach((value: string, key: string) => {
      record[key] = value;
    });
    return record;
  }
  private fallbackParse(content: string): ExtractionResult {
    const result = new ExtractionResult();

    let cleanContent = content;
    const thinkStart = cleanContent.indexOf('<think>');
    const thinkEnd = cleanContent.indexOf('</think>');
    if (thinkStart !== -1 && thinkEnd !== -1) {
      cleanContent = cleanContent.substring(thinkEnd + 8);
    }

    const contentLower = normalizeForSearch(cleanContent);
    for (const calc of CALCULATORS) {
      if (contentLower.indexOf(calc.id) !== -1) {
        if (!result.matchedCalcIds.some(id => id === calc.id)) {
          result.matchedCalcIds.push(calc.id);
        }
      }
    }

    const aliasEntries = Object.entries(CALC_ID_ALIASES);
    for (let i = 0; i < aliasEntries.length; i++) {
      const aliasKey = aliasEntries[i][0];
      const targetId = aliasEntries[i][1];
      if (contentLower.indexOf(aliasKey) !== -1) {
        if (!result.matchedCalcIds.some(id => id === targetId)) {
          if (CALCULATORS.some(c => c.id === targetId)) {
            result.matchedCalcIds.push(targetId);
          }
        }
      }
    }

    const numberPatterns: string[][] = [
      ['age', '年龄', '岁'],
      ['sbp', '收缩压', 'sbp'],
      ['dbp', '舒张压', 'dbp'],
      ['hr', '心率', 'hr'],
      ['rr', '呼吸', 'rr'],
      ['temp', '体温', '温度'],
      ['pao2', 'pao2', 'po2', '氧分压'],
      ['paco2', 'paco2', 'pco2', '二氧化碳分压'],
      ['ph', 'ph', '酸碱度'],
      ['hco3', 'hco3', '碳酸氢根', 'bicarbonate', '标准碳酸氢根'],
      ['be', 'be', '剩余碱', '碱剩余'],
      ['spo2', 'spo2', 'sao2', '血氧饱和度', '血氧'],
      ['fio2', 'fio2', '吸氧浓度', 'fio2'],
      ['creatinine', '肌酐', 'cr', 'creatinine'],
      ['na', '血钠', '钠', 'na+', 'na'],
      ['k', '血钾', '钾', 'k+', 'k'],
      ['cl', '血氯', '氯', '氯离子'],
      ['ca', '血钙', '钙', '总钙', '离子钙'],
      ['glu', '血糖', 'glu', 'glucose'],
      ['lac', '乳酸', 'lactate', 'lac'],
      ['weight', '体重', 'kg'],
      ['height', '身高', 'cm'],
      ['gcs', 'gcs', '格拉斯哥'],
      ['wbc', '白细胞', 'wbc'],
      ['hct', '红细胞压积', 'hct', 'hb', '血红蛋白'],
      ['platelet', '血小板', 'plt', 'platelet'],
      ['bilirubin', '胆红素', 'bilirubin', 'tbil'],
      ['alb', '白蛋白', 'alb', 'albumin', 'alb'],
      ['inr', 'inr'],
      ['map', '平均动脉压', 'map'],
      ['crp', 'crp', 'c反应蛋白', '反应蛋白'],
      ['pct', 'pct', '降钙素原', 'procalcitonin'],
      ['esr', 'esr', '血沉', '红细胞沉降率'],
      ['il6', 'il-6', '白细胞介素6', 'il6'],
      ['tnt', '肌钙蛋白', 'tnt', 'troponin', '肌钙蛋白i', 'ctni'],
      ['ckmb', 'ck-mb', '肌酸激酶同工酶', 'ckmb'],
      ['myo', '肌红蛋白', 'myoglobin', 'myo'],
      ['bnp', 'bnp', '脑钠肽', 'nt-probnp', 'probnp'],
      ['aptt', 'aptt', '部分凝血活酶', '活化部分'],
      ['pt', '凝血酶原时间', 'pt', 'prothrombintime'],
      ['tta', '凝血酶原活动度', 'pta', '凝血酶原活动'],
      ['tt', '凝血酶时间', 'thrombintime', 'tt'],
      ['fib', '纤维蛋白原', 'fibrinogen', 'fib'],
      ['fdp', 'fdp', '纤维蛋白降解物', '纤维蛋白原降解物'],
      ['dDimer', 'd-二聚体', 'd二聚体', 'ddimer', 'd-dimer'],
      ['atiii', '抗凝血酶', 'atiii', 'at-iii'],
      ['alt', 'alt', '谷丙', '谷丙转氨酶'],
      ['ast', 'ast', '谷草', '谷草转氨酶'],
      ['alp', 'alp', '碱性磷酸酶'],
      ['ggt', 'ggt', '转肽酶', '谷氨酰转肽酶'],
      ['ammonia', '血氨', 'ammonia', 'nh3'],
      ['rbc', '红细胞计数', 'rbc'],
      ['mcv', 'mcv', '平均红细胞体积'],
      ['mch', 'mch', '平均红细胞血红蛋白量'],
      ['mchc', 'mchc', '平均红细胞血红蛋白浓度'],
      ['rdw', 'rdw', '红细胞分布宽度'],
      ['retic', '网织红', 'retic', '网织红细胞'],
      ['mg', '血镁', 'magnesium', 'mg'],
      ['p', '血磷', 'phosphorus', '磷'],
      ['prealbumin', '前白蛋白', 'prealbumin', 'palb'],
      ['bmi', 'bmi', '体重指数', '体质指数'],
      ['tferritin', '铁蛋白', 'ferritin', 'tferritin'],
      ['tg', '甘油三酯', 'triglyceride', 'tg'],
      ['tsh', 'tsh', '促甲状腺激素'],
      ['ft3', 'ft3', '游离t3', '游离三碘'],
      ['ft4', 'ft4', '游离t4', '游离甲状腺素'],
      ['cortisol', '皮质醇', 'cortisol'],
      ['ck', '肌酸激酶', 'creatinekinase', 'cpk', 'ck'],
      ['ldh', '乳酸脱氢酶', 'ldh'],
      ['che', '胆碱酯酶', 'che', 'cholinesterase'],
      ['saa', '淀粉样蛋白a', 'saa', '血清淀粉样'],
      ['dbil', '结合胆红素', 'dbil', '直接胆红素'],
      ['ibil', '未结合胆红素', 'ibil', '间接胆红素'],
      ['hgb', '血红蛋白', 'hgb', 'hemoglobin'],
      ['bands', '杆状核', 'bands', 'band'],
      ['urineOutput', '尿量', 'urineoutput'],
      ['bun', '尿素氮', 'bun', 'bloodureanitrogen'],
      ['urea', '尿素', 'urea'],
    ];
    for (const pat of numberPatterns) {
      for (let p = 0; p < pat.length; p++) {
        const searchTarget = normalizeForSearch(pat[p]);
        const idx = contentLower.indexOf(searchTarget);
        if (idx !== -1) {
          const after = cleanContent.substring(idx + pat[p].length);
          const numMatch = after.match(/[\s:=：|]*([0-9]+\.?[0-9]*)/);
          if (numMatch && numMatch[1]) {
            result.fields.set(pat[0], numMatch[1]);
            break;
          }
        }
      }
    }

    const sexSearch = normalizeForSearch(cleanContent);
    if (sexSearch.indexOf('男') !== -1 || sexSearch.indexOf('男性') !== -1) {
      result.fields.set('sex', 'male');
    } else if (sexSearch.indexOf('女') !== -1 || sexSearch.indexOf('女性') !== -1) {
      result.fields.set('sex', 'female');
    }

    return result;
  }

  private computeAllMatches(data: Record<string, string>, matchedCalcIds: string[]): CalcMatch[] {
    const matches: CalcMatch[] = [];
    const dataMap = new Map<string, string>();
    const dataEntries = Object.entries(data);
    for (let i = 0; i < dataEntries.length; i++) {
      dataMap.set(dataEntries[i][0], dataEntries[i][1]);
    }

    const processedIds = new Set<string>();

    for (const spec of CALC_INPUT_SPECS) {
      let availableCount = 0;
      const availableFields: string[] = [];
      const missingFields: string[] = [];

      for (let i = 0; i < spec.requiredFields.length; i++) {
        const key = spec.requiredFields[i];
        const val = dataMap.get(key);
        if (val !== undefined && val.length > 0) {
          availableCount++;
          availableFields.push(key);
        } else {
          missingFields.push(key);
        }
      }

      // 无必填项的打分类计算器（如 vis/duke）：用可选字段判断有无数据，避免 0/0 = NaN
      if (spec.requiredFields.length === 0) {
        for (let i = 0; i < spec.optionalFields.length; i++) {
          const key = spec.optionalFields[i];
          const val = dataMap.get(key);
          if (val !== undefined && val.length > 0) {
            availableCount++;
            availableFields.push(key);
          }
        }
      }

      if (availableCount === 0 && matchedCalcIds.indexOf(spec.calcId) === -1) {
        continue;
      }

      processedIds.add(spec.calcId);

      const completeness = spec.requiredFields.length === 0
        ? (availableCount > 0 ? 100 : 0)
        : Math.round((availableCount / spec.requiredFields.length) * 100);
      const calc = CALCULATORS.find(c => c.id === spec.calcId);
      const calcName = calc ? calc.name : spec.calcId;
      const icon = calc ? calc.icon : '📊';

      let result: CalcResult | null = null;
      if (completeness === 100) {
        result = CalcDispatcher.dispatch(spec.calcId, data);
      }

      const match = new CalcMatch();
      match.calcId = spec.calcId;
      match.calcName = calcName;
      match.icon = icon;
      match.completeness = completeness;
      match.availableFields = availableFields;
      match.missingFields = missingFields;
      match.result = result;
      matches.push(match);
    }

    for (let i = 0; i < matchedCalcIds.length; i++) {
      const id = matchedCalcIds[i];
      if (processedIds.has(id)) {
        continue;
      }
      const spec = CALC_INPUT_SPECS.find(s => s.calcId === id);
      if (!spec) {
        continue;
      }
      const missingFields: string[] = [];
      for (let j = 0; j < spec.requiredFields.length; j++) {
        missingFields.push(spec.requiredFields[j]);
      }
      const calc = CALCULATORS.find(c => c.id === id);
      const match = new CalcMatch();
      match.calcId = id;
      match.calcName = calc ? calc.name : id;
      match.icon = calc ? calc.icon : '📊';
      match.completeness = 0;
      match.availableFields = [];
      match.missingFields = missingFields;
      match.result = null;
      matches.push(match);
    }

    matches.sort((a: CalcMatch, b: CalcMatch): number => {
      if (a.completeness !== b.completeness) {
        return b.completeness - a.completeness;
      }
      return a.missingFields.length - b.missingFields.length;
    });

    return matches;
  }

  getMissingFieldSpecs(calcId: string): DataFieldSpec[] {
    const spec = CALC_INPUT_SPECS.find(s => s.calcId === calcId);
    if (!spec) {
      return [];
    }
    const result: DataFieldSpec[] = [];
    for (let i = 0; i < spec.requiredFields.length; i++) {
      const key = spec.requiredFields[i];
      const val = this.allExtractedData.get(key);
      if (val === undefined || val.length === 0) {
        const fieldSpec = DATA_FIELDS.find(f => f.key === key);
        if (fieldSpec) {
          result.push(fieldSpec);
        }
      }
    }
    return result;
  }


  private buildSummary(newFields: Record<string, string>, matches: CalcMatch[]): string {
    const fieldCount = Object.keys(newFields).length;
    if (fieldCount === 0 && matches.length === 0) {
      return '未能从描述中提取到医疗数据，请提供更详细的病情信息。';
    }
    let summary = '';
    if (fieldCount > 0) {
      summary += '已提取 ' + fieldCount + ' 项数据。';
    }
    const complete = matches.filter(m => m.completeness === 100);
    const partial = matches.filter(m => m.completeness < 100);
    if (complete.length > 0) {
      summary += ' ' + complete.length + ' 个计算器可直接出结果';
    }
    if (partial.length > 0) {
      summary += '，' + partial.length + ' 个缺少部分数据';
    }
    if (complete.length === 0 && partial.length === 0) {
      summary += ' 暂无匹配的计算器。';
    }
    return summary;
  }

  private buildSummaryFromMatches(matches: CalcMatch[]): string {
    const fieldCount = this.allExtractedData.size;
    if (fieldCount === 0 && matches.length === 0) {
      return '未能从描述中提取到医疗数据，请提供更详细的病情信息。';
    }
    let summary = '';
    if (fieldCount > 0) {
      summary += '已提取 ' + fieldCount + ' 项数据。';
    }
    const complete = matches.filter(m => m.completeness === 100);
    const partial = matches.filter(m => m.completeness < 100);
    if (complete.length > 0) {
      summary += ' ' + complete.length + ' 个计算器可直接出结果';
    }
    if (partial.length > 0) {
      summary += '，' + partial.length + ' 个缺少部分数据';
    }
    if (complete.length === 0 && partial.length === 0) {
      summary += ' 暂无匹配的计算器。';
    }
    return summary;
  }
}
