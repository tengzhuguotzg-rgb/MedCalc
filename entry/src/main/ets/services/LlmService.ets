import http from '@ohos.net.http';
import { CALCULATORS } from '../model/CalculatorRegistry';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { buildClarifySystemPrompt, CLARIFY_DIMENSIONS, ClarifyDimension } from './prompts/ClarifyPrompt';

// 兼容旧 API：LlmDialog 通过 LlmService 引用 CLARIFY_DIMENSIONS / ClarifyDimension，
// 此处重新导出（import + export）保持外部消费者不变。
export { CLARIFY_DIMENSIONS, ClarifyDimension };

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

// ClarifyDimension 与 CLARIFY_DIMENSIONS 已迁移到 prompts/ClarifyPrompt.ets，
// 下方 re-export 保持对外 API 不变：LlmDialog 仍从 LlmService 引用 ClarifyDimension 与 CLARIFY_DIMENSIONS。

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

// R1 固定问卷维度（代码控制，不由 LLM 选择）的常量定义已迁移到 prompts/ClarifyPrompt.ets。
// 下方 re-export 保持对外 API 不变：LlmDialog 仍从 LlmService 引用 CLARIFY_DIMENSIONS。

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
