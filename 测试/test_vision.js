const https = require('https');
const fs = require('fs');
const path = require('path');

const IMAGE_PATH = path.join(__dirname, '20260707-221718.jpg');
const API_KEY = 'sk-cp-Hdb0d4PzGsSTqc5DAGWzlFmJ15lB5_RQSxFErxHkLJbCqYxz3Zn40tf0r9lAiGcajM2phQ7_wHaMexKuRQIra6xBOGtZkj9koUKilmMTPNIEFmeEc6X76Kw';

function imageToBase64(filePath) {
  const data = fs.readFileSync(filePath);
  return data.toString('base64');
}

const systemPrompt = `你是医学数据提取助手。从用户文字描述或医学检查报告图片中提取所有可识别的医疗参数数值，判断哪些计算器可用。
## 重要规则
- 如果输入是医学检查报告图片（如血气分析、生化检验、血常规等），仔细识别图片中每一项指标及其数值，尽可能多地提取，不要遗漏
- 血气分析报告常见指标：pH、PaCO2、PaO2、HCO3、BE、乳酸(Lac)、FiO2、SpO2、Na、K、Cl、Ca、Glu等
- 数值和单位要按字段定义转换（FiO2百分比需转换为小数如40%→0.4）
- 图片中明确标注的数值均可提取，不需要用户逐项提及

## 可提取字段
pao2: PaO2(mmHg) 参考:80-100
paco2: PaCO2(mmHg) 参考:35-45
ph: pH 参考:7.35-7.45
hco3: HCO3(mmol/L) 参考:22-26
be: BE(mmol/L) 参考:-2 to +2
lac: 乳酸(mmol/L) 参考:0.5-2.0
na: 血钠(mmol/L) 参考:136-145
k: 血钾(mmol/L) 参考:3.5-5.5
cl: 血氯(mmol/L) 参考:96-108
ca: 血钙(mmol/L) 参考:2.1-2.6
glu: 血糖(mmol/L) 参考:3.9-6.1
creatinine: 血肌酐(μmol/L) 参考:44-133
spo2: SpO2(%) 参考:95-100
fio2: FiO2 参考:0.21-1.0
fio2Mode: FiO2模式 选项:dec/pct

## 输出格式
严格输出JSON，不要输出任何其他文字：
{"extracted":{"field_key":"value",...},"matched":["calcId1","calcId2",...]}
规则：1.从图片中尽可能多提取明确可识别的数值 2.数值统一为数字字符串 3.matched列出所有至少有1个必填字段的计算器按相关度排序 4.如确实无法提取任何医疗数据返回{"extracted":{},"matched":[]}`;

const userContent = '请从这张医学检查报告中提取所有可识别的医疗数据参数';

const imageBase64 = imageToBase64(IMAGE_PATH);
const mimeType = 'image/jpeg';
const imageUrl = 'data:' + mimeType + ';base64,' + imageBase64;

console.log('Image size:', (imageBase64.length * 3 / 4 / 1024 / 1024).toFixed(2), 'MB (base64)');

const body = JSON.stringify({
  model: 'MiniMax-M3',
  max_tokens: 4096,
  messages: [
    { role: 'system', content: systemPrompt },
    { role: 'user', content: [
      { type: 'text', text: userContent },
      { type: 'image_url', image_url: { url: imageUrl } }
    ]}
  ]
});

console.log('Request body size:', (Buffer.byteLength(body) / 1024 / 1024).toFixed(2), 'MB');

const options = {
  hostname: 'api.minimaxi.com',
  port: 443,
  path: '/v1/chat/completions',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' + API_KEY,
    'Content-Length': Buffer.byteLength(body)
  },
  timeout: 120000
};

console.log('\n=== Sending vision request ===\n');

const req = https.request(options, (res) => {
  let data = '';
  res.on('data', (chunk) => data += chunk);
  res.on('end', () => {
    console.log('Status:', res.statusCode);
    try {
      const parsed = JSON.parse(data);
      if (parsed.choices && parsed.choices[0] && parsed.choices[0].message) {
        const content = parsed.choices[0].message.content;
        console.log('\n=== LLM RESPONSE ===\n');
        console.log(content);
        
        // Try to parse the JSON from the response
        const jsonMatch = content.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          try {
            const parsedJson = JSON.parse(jsonMatch[0]);
            console.log('\n=== PARSED JSON ===\n');
            console.log(JSON.stringify(parsedJson, null, 2));
          } catch(e) {
            console.log('\n(JSON parsing failed on extracted content)');
          }
        }
        
        console.log('\n=== USAGE ===');
        if (parsed.usage) {
          console.log('Prompt tokens:', parsed.usage.prompt_tokens);
          console.log('Completion tokens:', parsed.usage.completion_tokens);
        }
      } else {
        console.log('\n=== FULL RESPONSE ===');
        console.log(JSON.stringify(parsed, null, 2).substring(0, 2000));
      }
    } catch(e) {
      console.log('\n=== RAW RESPONSE ===');
      console.log(data.substring(0, 2000));
    }
  });
});
req.on('timeout', () => { req.destroy(); console.log('TIMEOUT'); });
req.on('error', (e) => console.log('Error:', e.message));
req.write(body);
req.end();
