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
- 图片中明确标注的数值均可提取，不需要用户逐项提及

## 计算器ID列表（matched数组必须使用以下准确的calcId，不要用别名）
pf(氧合指数PF ratio): 必填[pao2,fio2]
na(完整校正血钠): 必填[na,glu]
cag(阴离子间隙): 必填[na,cl,hco3,alb]

## 输出格式
严格输出以下JSON，不要输出任何其他文字（包括思考过程）：
{"extracted":{"field_key":"value",...},"matched":["calcId1","calcId2",...]}
matched字段必须使用上面列表中准确的calcId。如无法提取任何数据返回{"extracted":{},"matched":[]}`;

const userContent = '请从这张血气分析报告图片中提取所有可识别的医疗参数';

const imageBase64 = imageToBase64(IMAGE_PATH);
const imageUrl = 'data:image/jpeg;base64,' + imageBase64;

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

console.log('=== Full test with system+user vision messages ===\n');
const req = https.request(options, (res) => {
  let data = '';
  res.on('data', (chunk) => data += chunk);
  res.on('end', () => {
    console.log('Status:', res.statusCode);
    try {
      const parsed = JSON.parse(data);
      if (parsed.choices && parsed.choices[0] && parsed.choices[0].message) {
        const content = parsed.choices[0].message.content;
        console.log('=== RAW RESPONSE ===\n');
        console.log(content);
        console.log('\n=== --- END --- ===');
        console.log('\nUsage:', JSON.stringify(parsed.usage));
        
        // Test if our parser would find JSON in this
        let jsonStr = content.trim();
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
        try {
          const parsedJson = JSON.parse(jsonStr);
          console.log('\n=== PARSED JSON ===\n');
          console.log(JSON.stringify(parsedJson, null, 2));
          console.log('\nMatched calc IDs:', parsedJson.matched);
          
          const validIds = ['pf','na','cag','sf','sofa','apache2','sirs','rox','gcs','news2','map','curb65','crcl','gfr','rass','ich','hunthess','wfns','fisher','marshall','mehran','timistemi','timinstemi','wells','childpugh','kcc','clifc','aarc','camicu','pesi','scai','mnutric','fssicu','kdigo','abcd2','nrs2002','nihss'];
          const invalidIds = (parsedJson.matched || []).filter(id => !validIds.includes(id));
          if (invalidIds.length > 0) {
            console.log('\n⚠ INVALID calc IDs:', invalidIds);
          } else {
            console.log('✓ All calc IDs valid');
          }
        } catch(e) {
          console.log('\nJSON parse failed on stripped content:', e.message);
        }
      } else {
        console.log(JSON.stringify(parsed, null, 2));
      }
    } catch(e) {
      console.log('Parse error:', e.message);
      console.log('Raw:', data);
    }
  });
});
req.on('timeout', () => { req.destroy(); console.log('TIMEOUT'); });
req.on('error', (e) => console.log('Error:', e.message));
req.write(body);
req.end();
