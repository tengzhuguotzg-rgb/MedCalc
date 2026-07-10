const https = require('https');
const body = JSON.stringify({
  model: 'MiniMax-M3',
  messages: [{ role: 'user', content: 'Hi, output JSON: {"greeting":"hello"}' }],
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
      console.log('Content first 80 chars:');
      console.log(c.substring(0, 80));
      console.log('Char codes 0-10:');
      for (let i = 0; i < Math.min(20, c.length); i++) {
        console.log(i + ': U+' + c.charCodeAt(i).toString(16).padStart(4, '0') + ' ' + JSON.stringify(c[i]));
      }
    } catch (e) {
      console.log('Parse error:', e.message);
      console.log('Raw first 300:', d.substring(0, 300));
    }
  });
});
req.write(body);
req.end();
