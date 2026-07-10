const https = require('https');
const body = JSON.stringify({
  model: 'MiniMax-M3',
  max_tokens: 512,
  messages: [
    { role: 'system', content: '你是临床医学计算器推荐助手。仅输出计算器ID，多个用逗号分隔，最多4个。不要输出其他文字。\n计算器列表：pf:氧合指数 na:校正血钠 cag:阴离子间隙\n示例：用户：血气分析\n你：pf,cag,na' },
    { role: 'user', content: '血气分析报告，pH偏低，PaCO2升高' }
  ]
});
const req = https.request({
  hostname: 'api.minimaxi.com', port: 443,
  path: '/v1/text/chatcompletion_v2', method: 'POST', timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer sk-cp-Hdb0d4PzGsSTqc5DAGWzlFmJ15lB5_RQSxFErxHkLJbCqYxz3Zn40tf0r9lAiGcajM2phQ7_wHaMexKuRQIra6xBOGtZkj9koUKilmMTPNIEFmeEc6X76Kw'
  }
}, res => {
  let d = '';
  res.on('data', c => d += c);
  res.on('end', () => {
    try {
      const p = JSON.parse(d);
      const c = p.choices[0].message.content;
      console.log('Has think:', c.includes('think'));
      console.log('Content:', c);
    } catch (e) {
      console.log('Error:', e.message, d.substring(0, 200));
    }
  });
});
req.write(body);
req.end();
