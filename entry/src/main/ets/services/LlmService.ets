import http from '@ohos.net.http';
import { CALCULATORS } from '../model/CalculatorRegistry';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0xF000;
const TAG: string = 'LlmService';

export enum LlmFormat {
  OPENAI = 0,
  ANTHROPIC = 1
}

export class LlmModelConfig {
  id: string = '';
  name: string = '';
  provider: string = '';
  format: LlmFormat = LlmFormat.OPENAI;
  baseUrl: string = '';
  apiKey: string = '';
  modelName: string = '';

  constructor(id: string, name: string, provider: string = '', format: LlmFormat = LlmFormat.OPENAI, baseUrl: string = '', apiKey: string = '', modelName: string = '') {
    this.id = id;
    this.name = name;
    this.provider = provider;
    this.format = format;
    this.baseUrl = baseUrl;
    this.apiKey = apiKey;
    this.modelName = modelName;
  }

  toApiServiceConfig(): ApiServiceConfig {
    return {
      id: this.id,
      name: this.name,
      baseUrl: this.baseUrl,
      apiKey: this.apiKey,
      model: this.modelName
    };
  }
}

export interface ApiServiceConfig {
  id: string;
  name: string;
  baseUrl: string;
  apiKey: string;
  model: string;
}

export interface LlmRecommendation {
  id: string;
  name: string;
  reason: string;
}

/**
 * 从 LLM 响应文本中提取 JSON 字符串（三层防护，与原 AssistantService.parseExtractionResponse 等价）。
 * 1. </think> 截断：去掉深度思考模型的思考过程
 * 2. ``` 代码围栏：提取 markdown 代码块内的 JSON
 * 3. {} 花括号兜底：取首个 { 到末个 } 之间内容
 * 返回清洗后但未 JSON.parse 的字符串；调用方自行 parse。全失败返回空串。
 */
export function extractJsonPayload(content: string): string {
  let jsonStr = content.trim();

  const thinkEndTag = '</think>';
  const thinkEndIdx = jsonStr.indexOf(thinkEndTag);
  if (thinkEndIdx !== -1) {
    jsonStr = jsonStr.substring(thinkEndIdx + thinkEndTag.length).trim();
  }

  const fenceMatch = jsonStr.indexOf('```');
  if (fenceMatch !== -1) {
    const afterFence = jsonStr.substring(fenceMatch + 3);
    const fenceEnd = afterFence.indexOf('```');
    if (fenceEnd !== -1) {
      jsonStr = afterFence.substring(0, fenceEnd).trim();
    } else {
      jsonStr = afterFence.trim();
    }
    if (jsonStr.startsWith('json')) {
      jsonStr = jsonStr.substring(4).trim();
    }
  }

  // 先尝试直接 parse，成功则原样返回
  try {
    JSON.parse(jsonStr);
    return jsonStr;
  } catch (_e) {
    // parse 失败，尝试花括号兜底
    const braceStart = jsonStr.indexOf('{');
    const braceEnd = jsonStr.lastIndexOf('}');
    if (braceStart !== -1 && braceEnd > braceStart) {
      const candidate = jsonStr.substring(braceStart, braceEnd + 1);
      try {
        JSON.parse(candidate);
        return candidate;
      } catch (_e2) {
        // 兜底也失败，返回花括号片段（调用方可继续处理）
        return candidate;
      }
    }
    return '';
  }
}

class OpenAiMsg {
  role: string = '';
  content: string = '';
}

class AnthropicMsg {
  role: string = '';
  content: string = '';
}

class VisionTextItem {
  type: string = 'text';
  text: string = '';

  constructor(text: string) {
    this.text = text;
  }
}

class VisionImageSource {
  type: string = 'base64';
  media_type: string = '';
  data: string = '';

  constructor(mime: string, base64: string) {
    this.media_type = mime;
    this.data = base64;
  }
}

class AnthropicVisionImageItem {
  type: string = 'image';
  source: VisionImageSource = new VisionImageSource('', '');

  constructor(mime: string, base64: string) {
    this.source = new VisionImageSource(mime, base64);
  }
}

class OpenAiImageUrlObj {
  url: string = '';

  constructor(url: string) {
    this.url = url;
  }
}

class OpenAiVisionImageItem {
  type: string = 'image_url';
  image_url: OpenAiImageUrlObj = new OpenAiImageUrlObj('');

  constructor(url: string) {
    this.image_url = new OpenAiImageUrlObj(url);
  }
}

class AnthropicVisionMsg {
  role: string = '';
  content: Object[] = [];
}

class OpenAiVisionSysMsg {
  role: string = '';
  content: string = '';
}

class OpenAiVisionUserMsg {
  role: string = '';
  content: Object[] = [];
}

class BearerHeadersObj {
  contentType: string = 'application/json';
  authorization: string = '';

  constructor(authValue: string) {
    this.authorization = authValue;
  }

  toJson(): string {
    const parts: string[] = [];
    parts.push(`"Content-Type":${JSON.stringify(this.contentType)}`);
    parts.push(`"Authorization":${JSON.stringify(this.authorization)}`);
    return `{${parts.join(',')}}`;
  }
}

class ApiKeyHeadersObj {
  contentType: string = 'application/json';
  xApiKey: string = '';
  anthropicVersion: string = '2023-06-01';

  constructor(apiKey: string) {
    this.xApiKey = apiKey;
  }

  toJson(): string {
    const parts: string[] = [];
    parts.push(`"Content-Type":${JSON.stringify(this.contentType)}`);
    parts.push(`"x-api-key":${JSON.stringify(this.xApiKey)}`);
    parts.push(`"anthropic-version":${JSON.stringify(this.anthropicVersion)}`);
    return `{${parts.join(',')}}`;
  }
}

class BlankObj {
}

function jsonToObject(json: string): Object {
  const result: Object | null = JSON.parse(json);
  if (result === null) {
    return new BlankObj();
  }
  return result;
}

function isAnthropicProvider(baseUrl: string): boolean {
  const lower = baseUrl.toLowerCase();
  if (lower.includes('/anthropic')) {
    return true;
  }
  if (lower.includes('anthropic.com')) {
    return true;
  }
  return false;
}

function isMiniMaxProvider(baseUrl: string): boolean {
  const lower = baseUrl.toLowerCase();
  if (!lower.includes('minimaxi')) {
    return false;
  }
  if (lower.includes('/anthropic')) {
    return false;
  }
  return true;
}

function buildUrlPath(baseUrl: string, path: string): string {
  let base = baseUrl.replace(/\/+$/, '');
  if (path.startsWith('/')) {
    path = path.substring(1);
  }
  if (base.endsWith('/v1') && path.startsWith('v1/')) {
    path = path.substring(3);
  }
  return base + '/' + path;
}

function buildUrl(config: ApiServiceConfig): string {
  if (isAnthropicProvider(config.baseUrl)) {
    return buildUrlPath(config.baseUrl, 'v1/messages');
  }
  if (isMiniMaxProvider(config.baseUrl)) {
    return buildUrlPath(config.baseUrl, 'v1/text/chatcompletion_v2');
  }
  return buildUrlPath(config.baseUrl, 'v1/chat/completions');
}

function buildSystemPrompt(): string {
  let prompt = '你是一个临床医学计算器推荐助手。从下面列表中选择最匹配用户场景的计算器。\n';
  prompt += '规则：\n';
  prompt += '1. 仅输出计算器ID，多个ID用英文逗号分隔，按匹配度从高到低排列，最多8个。\n';
  prompt += '2. 不要输出任何其他文字、标点或解释。\n';
  prompt += '3. 如果没有任何计算器能合理匹配，只输出 unknown\n\n';
  prompt += '计算器列表（ID: 名称 - 用途 - 适用场景）：\n';
  for (const calc of CALCULATORS) {
    prompt += `${calc.id}: ${calc.name} - ${calc.description}。适用: ${calc.whenToUse}\n`;
  }
  prompt += '\n示例：\n用户：肾功能评估\n你：crcl,gfr\n\n用户：今天天气不错\n你：unknown\n';
  return prompt;
}

function buildHeaders(config: ApiServiceConfig): Object {
  if (isAnthropicProvider(config.baseUrl)) {
    const h = new ApiKeyHeadersObj(config.apiKey);
    return jsonToObject(h.toJson());
  }
  const h = new BearerHeadersObj(`Bearer ${config.apiKey}`);
  return jsonToObject(h.toJson());
}

function buildRequestBody(config: ApiServiceConfig, systemPrompt: string, userMessage: string): string {
  if (isAnthropicProvider(config.baseUrl)) {
    const msg1: AnthropicMsg = { role: 'user', content: userMessage };
    const messages: AnthropicMsg[] = [msg1];
    return JSON.stringify({ model: config.model, max_tokens: 512, system: systemPrompt, messages: messages });
  }
  const msg1: OpenAiMsg = { role: 'system', content: systemPrompt };
  const msg2: OpenAiMsg = { role: 'user', content: userMessage };
  const messages: OpenAiMsg[] = [msg1, msg2];
  return JSON.stringify({ model: config.model, max_tokens: 512, messages: messages });
}

function buildVisionRequestBody(config: ApiServiceConfig, systemPrompt: string, userText: string, imageBase64: string, imageMime: string): string {
  if (isAnthropicProvider(config.baseUrl)) {
    const contentItems: Object[] = [];
    const textItem = new VisionTextItem(userText);
    contentItems.push(textItem);
    if (imageBase64.length > 0 && imageMime.length > 0) {
      const imageItem = new AnthropicVisionImageItem(imageMime, imageBase64);
      contentItems.push(imageItem);
    }
    const msg = new AnthropicVisionMsg();
    msg.role = 'user';
    msg.content = contentItems;
    const messages: AnthropicVisionMsg[] = [msg];
    const body: Record<string, Object> = {};
    body['model'] = config.model;
    body['max_tokens'] = 4096;
    body['system'] = systemPrompt;
    body['messages'] = messages;
    return JSON.stringify(body);
  }
  const contentItems: Object[] = [];
  const textItem2 = new VisionTextItem(userText);
  contentItems.push(textItem2);
  if (imageBase64.length > 0 && imageMime.length > 0) {
    const urlStr = 'data:' + imageMime + ';base64,' + imageBase64;
    const imageItem = new OpenAiVisionImageItem(urlStr);
    contentItems.push(imageItem);
  }
  const sysMsg = new OpenAiVisionSysMsg();
  sysMsg.role = 'system';
  sysMsg.content = systemPrompt;
  const userMsg = new OpenAiVisionUserMsg();
  userMsg.role = 'user';
  userMsg.content = contentItems;
  const messages: Object[] = [sysMsg, userMsg];
  const body: Record<string, Object> = {};
  body['model'] = config.model;
  body['max_tokens'] = 4096;
  body['messages'] = messages;
  return JSON.stringify(body);
}

function extractFromOpenAI(text: string): string {
  try {
    const parsed: object = JSON.parse(text);
    const choices = (parsed as Record<string, object>)['choices'] as Array<Record<string, object>> | undefined;
    if (choices && choices.length > 0) {
      const content = (choices[0]['message'] as Record<string, object> | undefined)?.['content'];
      if (typeof content === 'string') {
        return content;
      }
    }
    return '';
  } catch (_e) {
    const choicesMarker = '"choices"';
    const choicesIdx = text.indexOf(choicesMarker);
    if (choicesIdx === -1) {
      return '';
    }
    const afterChoices = text.substring(choicesIdx);
    const contentMarker = '"content":"';
    const contentIdx = afterChoices.indexOf(contentMarker);
    if (contentIdx === -1) {
      return '';
    }
    const start = contentIdx + contentMarker.length;
    const remaining = afterChoices.substring(start);
    const end = remaining.indexOf('"');
    if (end === -1) {
      return '';
    }
    return remaining.substring(0, end);
  }
}

function extractFromAnthropic(text: string): string {
  try {
    const parsed: object = JSON.parse(text);
    const contentArr = (parsed as Record<string, object>)['content'] as Array<Record<string, object>> | undefined;
    if (contentArr && contentArr.length > 0) {
      for (const item of contentArr) {
        const itemObj = item as Record<string, Object>;
        const itemType = itemObj['type'] as string;
        if (itemType === 'text') {
          const textVal = itemObj['text'] as string;
          if (typeof textVal === 'string') {
            return textVal;
          }
        }
      }
    }
    return '';
  } catch (_e) {
    const contentMarker = '"content"';
    const contentIdx = text.indexOf(contentMarker);
    if (contentIdx === -1) {
      return '';
    }
    const afterContent = text.substring(contentIdx);
    const textMarker = '"text":"';
    const textIdx = afterContent.indexOf(textMarker);
    if (textIdx === -1) {
      return '';
    }
    const start = textIdx + textMarker.length;
    const remaining = afterContent.substring(start);
    const end = remaining.indexOf('"');
    if (end === -1) {
      return '';
    }
    return remaining.substring(0, end);
  }
}

function isValidCalculatorId(id: string): boolean {
  return CALCULATORS.some((calc): boolean => calc.id === id);
}

function parseRecommendations(content: string): LlmRecommendation[] {
  const trimmed = content.trim();
  if (!trimmed || trimmed.toLowerCase() === 'none' || trimmed.toLowerCase() === 'unknown') {
    return [];
  }

  // Strategy 1: Split by commas (handles "crcl,gfr", "crcl, gfr", etc.)
  const normalized = trimmed.replace(/[\n\r，、\s]+/g, ',');
  const tokens: string[] = normalized.split(',');

  const result: LlmRecommendation[] = [];
  const seen = new Set<string>();

  for (const token of tokens) {
    const id = token.trim().toLowerCase();
    if (!id || seen.has(id)) {
      continue;
    }
    const calc = CALCULATORS.find((c): boolean => c.id === id);
    if (calc) {
      seen.add(id);
      result.push({ id: calc.id, name: calc.name, reason: calc.whenToUse });
    }
  }

  if (result.length > 0) {
    return result;
  }

  // Strategy 2: Fallback — brute-force search for ANY calculator ID or name in text
  for (const calc of CALCULATORS) {
    if (result.length >= 8) {
      break;
    }
    if (result.some((r): boolean => r.id === calc.id)) {
      continue;
    }
    const contentLower = trimmed.toLowerCase();
    if (contentLower.indexOf(calc.id.toLowerCase()) !== -1) {
      result.push({ id: calc.id, name: calc.name, reason: '' });
      continue;
    }
    if (contentLower.indexOf(calc.name.toLowerCase()) !== -1) {
      result.push({ id: calc.id, name: calc.name, reason: '' });
      continue;
    }
    if (calc.enName && contentLower.indexOf(calc.enName.toLowerCase()) !== -1) {
      result.push({ id: calc.id, name: calc.name, reason: '' });
    }
  }

  return result;
}

function parseResponseText(config: ApiServiceConfig, responseText: string): LlmRecommendation[] {
  let content = '';
  if (isAnthropicProvider(config.baseUrl)) {
    content = extractFromAnthropic(responseText);
  } else {
    content = extractFromOpenAI(responseText);
  }

  if (!content) {
    return [];
  }

  return parseRecommendations(content);
}

function doHttpPost(url: string, headers: Object, body: string): Promise<http.HttpResponse> {
  return new Promise<http.HttpResponse>((resolve, reject) => {
    const httpRequest = http.createHttp();
    httpRequest.request(url, {
      method: http.RequestMethod.POST,
      header: headers,
      extraData: body,
      connectTimeout: 30000,
      readTimeout: 60000,
      expectDataType: http.HttpDataType.STRING,
    }, (err: Error | void, data: http.HttpResponse) => {
      httpRequest.destroy();
      if (err) {
        reject(err);
        return;
      }
      resolve(data);
    });
  });
}

function extractResultText(response: http.HttpResponse): string {
  if (typeof response.result === 'string') {
    return response.result;
  }
  return JSON.stringify(response.result);
}

export function sendLlmRequest(config: ApiServiceConfig, userMessage: string): Promise<LlmRecommendation[]> {
  const systemPrompt = buildSystemPrompt();
  const url = buildUrl(config);
  const headers = buildHeaders(config);
  const body = buildRequestBody(config, systemPrompt, userMessage);

  return doHttpPost(url, headers, body).then((response: http.HttpResponse): LlmRecommendation[] => {
    if (response.responseCode !== 200) {
      const responseText = extractResultText(response);
      throw new Error(`API 返回错误 (${response.responseCode}): ${responseText}`);
    }
    const responseText = extractResultText(response);
    const results = parseResponseText(config, responseText);
    if (results.length === 0) {
      throw new Error('LLM 未找到匹配的计算器，请提供更详细的病情描述');
    }
    return results;
  });
}

function extractContentFromResponse(config: ApiServiceConfig, responseText: string): string {
  if (isAnthropicProvider(config.baseUrl)) {
    return extractFromAnthropic(responseText);
  }
  return extractFromOpenAI(responseText);
}

export function sendVisionRequest(config: ApiServiceConfig, systemPrompt: string, userText: string, imageBase64: string, imageMime: string): Promise<string> {
  const url = buildUrl(config);
  const headers = buildHeaders(config);
  const body = buildVisionRequestBody(config, systemPrompt, userText, imageBase64, imageMime);
  hilog.info(DOMAIN, TAG, `sendVision url=${url} model=${config.model} hasImage=${imageBase64.length > 0}`);

  return doHttpPost(url, headers, body).then((response: http.HttpResponse): string => {
    if (response.responseCode !== 200) {
      const responseText = extractResultText(response);
      hilog.error(DOMAIN, TAG, `Vision HTTP ${response.responseCode}: ${responseText.substring(0, 300)}`);
      throw new Error('API 错误 (' + response.responseCode + '): ' + responseText);
    }
    const responseText = extractResultText(response);
    const content = extractContentFromResponse(config, responseText);
    hilog.info(DOMAIN, TAG, `Vision response content len=${content.length} first200=${content.substring(0, 200)}`);
    if (content.length === 0) {
      throw new Error('LLM 返回内容为空');
    }
    return content;
  });
}

// ========== 多轮卡片式澄清推荐 ==========

export interface ClarifyDimension {
  key: string;
  label: string;
  prompt: string;
  options: string[];
  multi: boolean; // 是否多选
}

export interface ClarifyQuestion {
  dimension: string;
  prompt: string;
  options: string[];
  multi: boolean; // 是否多选
}

export interface ClarifyAnswer {
  dimension: string;
  label: string;
  answers: string[]; // 支持多选
}

export interface ClarifyResponse {
  confidence: number;
  action: string; // 'clarify' | 'recommend'
  questions: ClarifyQuestion[];
  recommendations: LlmRecommendation[];
  summary: string; // 推荐理由汇总说明
}

export interface ChatMessage {
  role: string;
  content: string;
}

// R1 固定问卷维度（代码控制，不由 LLM 选择）
export const CLARIFY_DIMENSIONS: ClarifyDimension[] = [
  { key: 'symptom', label: '主诉', prompt: '主要症状/主诉是什么？', multi: true, options: ['胸痛/胸闷', '呼吸困难/低氧', '意识障碍/昏迷', '休克/低血压', '下肢肿痛', '腹痛/恶心呕吐', '出血/凝血异常', '发热/感染', '电解质/代谢紊乱', '药物过量/中毒', '无明显症状'] },
  { key: 'system', label: '系统', prompt: '关注哪个器官系统？', multi: true, options: ['心血管', '呼吸', '神经', '肝肾', '消化/腹部', '血液/凝血', '感染/脓毒症', '代谢/电解质', '暂无特定方向'] },
  { key: 'setting', label: '场景', prompt: '当前在什么场景？', multi: false, options: ['ICU', '急诊', '病房', '门诊'] },
  { key: 'acuity', label: '急慢性', prompt: '病情是急性还是慢性？', multi: false, options: ['急性发作', '慢性/持续', '不确定'] },
];

function buildClarifySystemPrompt(): string {
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

function buildClarifyRequestBody(config: ApiServiceConfig, systemPrompt: string, messages: ChatMessage[]): string {
  if (isAnthropicProvider(config.baseUrl)) {
    const anthropicMsgs: AnthropicMsg[] = [];
    for (let i = 0; i < messages.length; i++) {
      anthropicMsgs.push({ role: messages[i].role, content: messages[i].content });
    }
    return JSON.stringify({ model: config.model, max_tokens: 800, system: systemPrompt, messages: anthropicMsgs });
  }
  const openaiMsgs: OpenAiMsg[] = [];
  openaiMsgs.push({ role: 'system', content: systemPrompt });
  for (let i = 0; i < messages.length; i++) {
    openaiMsgs.push({ role: messages[i].role, content: messages[i].content });
  }
  return JSON.stringify({ model: config.model, max_tokens: 800, messages: openaiMsgs });
}

function parseClarifyResponse(content: string): ClarifyResponse {
  const jsonStr = extractJsonPayload(content);
  if (jsonStr.length === 0) {
    // 降级：暴力搜索 id
    const recs = parseRecommendations(content);
    return { confidence: 0.5, action: 'recommend', questions: [], recommendations: recs, summary: '' };
  }

  try {
    const parsed: Object | null = JSON.parse(jsonStr);
    if (parsed === null || parsed === undefined) {
      const recs = parseRecommendations(content);
      return { confidence: 0.5, action: 'recommend', questions: [], recommendations: recs, summary: '' };
    }
    const obj = parsed as Record<string, Object>;
    const confidence = typeof obj['confidence'] === 'number' ? (obj['confidence'] as number) : 0.5;
    const action = typeof obj['action'] === 'string' ? (obj['action'] as string) : 'recommend';

    const questions: ClarifyQuestion[] = [];
    const questionsRaw = obj['questions'];
    if (Array.isArray(questionsRaw)) {
      const qArr = questionsRaw as Object[];
      for (let i = 0; i < qArr.length; i++) {
        const q = qArr[i] as Record<string, Object>;
        const dimension = typeof q['dimension'] === 'string' ? (q['dimension'] as string) : '';
        const prompt = typeof q['prompt'] === 'string' ? (q['prompt'] as string) : '';
        const multi = q['multi'] === true;
        const optionsRaw = q['options'];
        const options: string[] = [];
        if (Array.isArray(optionsRaw)) {
          const optArr = optionsRaw as string[];
          for (let j = 0; j < optArr.length; j++) {
            if (typeof optArr[j] === 'string') {
              options.push(optArr[j]);
            }
          }
        }
        if (dimension.length > 0 && options.length > 0) {
          questions.push({ dimension, prompt, options, multi });
        }
      }
    }

    const recommendations: LlmRecommendation[] = [];
    const recsRaw = obj['recommendations'];
    if (Array.isArray(recsRaw)) {
      const recArr = recsRaw as Object[];
      for (let i = 0; i < recArr.length; i++) {
        const rec = recArr[i] as Record<string, Object>;
        const id = typeof rec['id'] === 'string' ? (rec['id'] as string).trim().toLowerCase() : '';
        let reason = typeof rec['reason'] === 'string' ? (rec['reason'] as string) : '';
        const calc = CALCULATORS.find((c): boolean => c.id === id);
        if (calc) {
          // 兜底：LLM 没返回 reason 时用 whenToUse 替代
          if (reason.length === 0) {
            reason = calc.whenToUse;
          }
          recommendations.push({ id: calc.id, name: calc.name, reason });
        }
      }
    }

    const summary = typeof obj['summary'] === 'string' ? (obj['summary'] as string) : '';

    // 如果 action=recommend 但 recommendations 为空，降级暴力搜索
    if (action === 'recommend' && recommendations.length === 0) {
      const fallbackRecs = parseRecommendations(content);
      return { confidence, action: 'recommend', questions: [], recommendations: fallbackRecs, summary };
    }

    return { confidence, action, questions, recommendations, summary };
  } catch (_e) {
    // 降级：暴力搜索 id
    const recs = parseRecommendations(content);
    return { confidence: 0.5, action: 'recommend', questions: [], recommendations: recs, summary: '' };
  }
}

export function sendClarifyRound(config: ApiServiceConfig, messages: ChatMessage[]): Promise<ClarifyResponse> {
  const systemPrompt = buildClarifySystemPrompt();
  const url = buildUrl(config);
  const headers = buildHeaders(config);
  const body = buildClarifyRequestBody(config, systemPrompt, messages);
  hilog.info(DOMAIN, TAG, `sendClarifyRound url=${url} model=${config.model} msgs=${messages.length}`);

  return doHttpPost(url, headers, body).then((response: http.HttpResponse): ClarifyResponse => {
    if (response.responseCode !== 200) {
      const responseText = extractResultText(response);
      hilog.error(DOMAIN, TAG, `Clarify HTTP ${response.responseCode}: ${responseText.substring(0, 300)}`);
      throw new Error('API 错误 (' + response.responseCode + '): ' + responseText);
    }
    const responseText = extractResultText(response);
    const content = extractContentFromResponse(config, responseText);
    hilog.info(DOMAIN, TAG, `Clarify response content len=${content.length} first200=${content.substring(0, 200)}`);
    if (content.length === 0) {
      throw new Error('LLM 返回内容为空');
    }
    return parseClarifyResponse(content);
  });
}
