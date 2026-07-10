const https = require('https');
const API_KEY = 'sk-cp-Hdb0d4PzGsSTqc5DAGWzlFmJ15lB5_RQSxFErxHkLJbCqYxz3Zn40tf0r9lAiGcajM2phQ7_wHaMexKuRQIra6xBOGtZkj9koUKilmMTPNIEFmeEc6X76Kw';

const prompt = '请从以下医学描述中列出所有可识别的医疗参数名称和数值。';
const text = 'pH 7.51 PaCO2 28.2 PaO2 148.9 HCO3 22.6 Na 141 K 3.6 Cl 109 Glu 6.9 Lac 1.8';

// TEST A: Vision-style array format (used by sendVisionRequest)
const bodyA = JSON.stringify({
  model: 'MiniMax-M3', max_tokens: 1024,
  messages: [
    { role: 'system', content: prompt },
    { role: 'user', content: [{ type: 'text', text: text }] }
  ]
});

// TEST B: Plain text format (used by sendLlmRequest)
const bodyB = JSON.stringify({
  model: 'MiniMax-M3', max_tokens: 1024,
  messages: [
    { role: 'system', content: prompt + ' 也列出关联的计算器ID。' },
    { role: 'user', content: text }
  ]
});

function call(body, label) {
  return new Promise((resolve) => {
    const opts = {
      hostname: 'api.minimaxi.com', port: 443, path: '/v1/chat/completions',
      method: 'POST', timeout: 30000,
      headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + API_KEY }
    };
    const req = https.request(opts, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        const parsed = JSON.parse(data);
        const content = parsed.choices?.[0]?.message?.content || '';
        resolve({ label, content });
      });
    });
    req.on('error', (e) => resolve({ label, content: 'ERR: ' + e.message }));
    req.write(body);
    req.end();
  });
}

(async () => {
  const rA = await call(bodyA, 'VISION FORMAT (array)');
  const rB = await call(bodyB, 'TEXT FORMAT (string)');
  console.log('=== ' + rA.label + ' ===');
  const cleanA = rA.content.replace(/<think>[\s\S]*?<\/think>/g, '').trim();
  console.log(cleanA.substring(0, 500));
  console.log('\n=== ' + rB.label + ' ===');
  const cleanB = rB.content.replace(/<think>[\s\S]*?<\/think>/g, '').trim();
  console.log(cleanB.substring(0, 500));
  console.log('\n=== SUMMARY ===');
  console.log('A length:', rA.content.length);
  console.log('B length:', rB.content.length);
})();
