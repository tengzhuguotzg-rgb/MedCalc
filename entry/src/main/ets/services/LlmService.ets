import http from '@ohos.net.http';
import { CALCULATORS } from '../model/CalculatorRegistry';

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

class OpenAiMsg {
  role: string = '';
  content: string = '';
}

class AnthropicMsg {
  role: string = '';
  content: string = '';
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

function isAnthropic(baseUrl: string): boolean {
  return baseUrl.includes('anthropic');
}

function buildSystemPrompt(): string {
  let prompt = '你是一个临床医学计算器推荐助手。从下面列表中选择最匹配用户场景的计算器。\n';
  prompt += '规则：\n';
  prompt += '1. 仅输出计算器ID，多个ID用英文逗号分隔，按匹配度从高到低排列，最多4个。\n';
  prompt += '2. 不要输出任何其他文字、标点或解释。\n';
  prompt += '3. 如果没有任何计算器能合理匹配，只输出 unknown\n\n';
  prompt += '计算器列表（ID: 名称 - 用途）：\n';
  for (const calc of CALCULATORS) {
    prompt += `${calc.id}: ${calc.name} - ${calc.description}\n`;
  }
  prompt += '\n示例：\n用户：肾功能评估\n你：crcl,gfr\n\n用户：今天天气不错\n你：unknown\n';
  return prompt;
}

function buildUrl(config: ApiServiceConfig): string {
  const base = config.baseUrl.replace(/\/+$/, '');
  if (isAnthropic(config.baseUrl)) {
    return `${base}/v1/messages`;
  }
  return `${base}/v1/chat/completions`;
}

function buildHeaders(config: ApiServiceConfig): Object {
  if (isAnthropic(config.baseUrl)) {
    const h = new ApiKeyHeadersObj(config.apiKey);
    return jsonToObject(h.toJson());
  }
  const h = new BearerHeadersObj(`Bearer ${config.apiKey}`);
  return jsonToObject(h.toJson());
}

function buildRequestBody(config: ApiServiceConfig, systemPrompt: string, userMessage: string): string {
  if (isAnthropic(config.baseUrl)) {
    const msg1: AnthropicMsg = { role: 'user', content: userMessage };
    const messages: AnthropicMsg[] = [msg1];
    return JSON.stringify({ model: config.model, max_tokens: 512, system: systemPrompt, messages: messages });
  }
  const msg1: OpenAiMsg = { role: 'system', content: systemPrompt };
  const msg2: OpenAiMsg = { role: 'user', content: userMessage };
  const messages: OpenAiMsg[] = [msg1, msg2];
  return JSON.stringify({ model: config.model, max_tokens: 512, messages: messages });
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
      result.push({ id: calc.id, name: calc.name, reason: '' });
    }
  }

  if (result.length > 0) {
    return result;
  }

  // Strategy 2: Fallback — brute-force search for ANY calculator ID or name in text
  for (const calc of CALCULATORS) {
    if (result.length >= 4) {
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
  if (isAnthropic(config.baseUrl)) {
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
      connectTimeout: 15000,
      readTimeout: 15000,
      expectDataType: http.HttpDataType.STRING,
    }, (err: Error, data: http.HttpResponse) => {
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
