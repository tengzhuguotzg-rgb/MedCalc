import http from '@ohos.net.http';
import { CALCULATORS } from '../model/CalculatorRegistry';

export interface ApiServiceConfig {
  id: string;
  name: string;
  baseUrl: string;
  apiKey: string;
  model: string;
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
  let prompt = '你是一个临床医学计算器推荐助手。根据用户的描述，从以下列表中选出最合适的计算器ID，仅返回ID（如 sofa），不要任何额外文字。\n\n计算器列表：\n';
  for (const calc of CALCULATORS) {
    prompt += `- ${calc.id}: ${calc.name}, ${calc.description}, 关键词: ${calc.kw}\n`;
  }
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
    return JSON.stringify({ model: config.model, max_tokens: 256, system: systemPrompt, messages: messages });
  }
  const msg1: OpenAiMsg = { role: 'system', content: systemPrompt };
  const msg2: OpenAiMsg = { role: 'user', content: userMessage };
  const messages: OpenAiMsg[] = [msg1, msg2];
  return JSON.stringify({ model: config.model, messages: messages });
}

function parseResponseText(config: ApiServiceConfig, responseText: string): string {
  if (isAnthropic(config.baseUrl)) {
    const marker = '"text":"';
    const idx = responseText.lastIndexOf(marker);
    if (idx === -1) {
      return '';
    }
    const start = idx + marker.length;
    const end = responseText.indexOf('"', start);
    if (end === -1) {
      return '';
    }
    return responseText.substring(start, end);
  }
  const marker = '"content":"';
  const idx = responseText.lastIndexOf(marker);
  if (idx === -1) {
    return '';
  }
  const start = idx + marker.length;
  const end = responseText.indexOf('"', start);
  if (end === -1) {
    return '';
  }
  return responseText.substring(start, end);
}

function isValidCalculatorId(id: string): boolean {
  return CALCULATORS.some((calc): boolean => calc.id === id);
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

export function sendLlmRequest(config: ApiServiceConfig, userMessage: string): Promise<string> {
  const systemPrompt = buildSystemPrompt();
  const url = buildUrl(config);
  const headers = buildHeaders(config);
  const body = buildRequestBody(config, systemPrompt, userMessage);

  return doHttpPost(url, headers, body).then((response: http.HttpResponse): string => {
    if (response.responseCode !== 200) {
      const responseText = extractResultText(response);
      throw new Error(`API 返回错误 (${response.responseCode}): ${responseText}`);
    }
    const responseText = extractResultText(response);
    const calcId = parseResponseText(config, responseText);
    if (!calcId) {
      throw new Error('无法从 LLM 响应中解析计算器 ID');
    }
    if (!isValidCalculatorId(calcId)) {
      throw new Error(`LLM 返回了无效的计算器 ID: ${calcId}`);
    }
    return calcId;
  });
}
