const https = require('https');
const fs = require('fs');
const img = fs.readFileSync('E:/ai/MedCalc/测试/20260707-221718.jpg').toString('base64');
const body = JSON.stringify({
  model: 'MiniMax-M3',
  max_tokens: 4096,
  messages: [
    { role: 'system', content: '你是医学数据提取助手。严格输出JSON，不要输出任何其他文字：\n{"extracted":{"field_key":"value",...},"matched":["calcId1"]}\n字段名：pao2,paco2,ph,hco3,be,spo2,na,k,cl,ca,glu,lac,fio2' },
    { role: 'user', content: [
      { type: 'text', text: '请从这张血气分析报告图片中提取所有医疗数据' },
      { type: 'image_url', image_url: { url: 'data:image/jpeg;base64,' + img } }
    ]}
  ]
});
const req = https.request({
  hostname: 'api.minimaxi.com', port: 443,
  path: '/v1/text/chatcompletion_v2', method: 'POST', timeout: 120000,
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
      console.log('Has think tags:', c.includes('hesitati') || c.includes('think'));
      console.log('First 300 chars:');
      console.log(c.substring(0, 300));
      // Try to extract JSON
      const fm = c.indexOf('```');
      let jsonStr = c;
      if (fm !== -1) {
        const af = c.substring(fm + 3);
        const fe = af.indexOf('```');
        if (fe !== -1) jsonStr = af.substring(0, fe).trim();
        else jsonStr = af.trim();
        if (jsonStr.startsWith('json')) jsonStr = jsonStr.substring(4).trim();
      }
      try {
        const jd = JSON.parse(jsonStr);
        console.log('\nParsed! Keys:', Object.keys(jd.extracted || {}));
        console.log('matched:', jd.matched);
      } catch(e2) {
        console.log('JSON parse failed:', e2.message);
        const bs = jsonStr.indexOf('{');
        const be = jsonStr.lastIndexOf('}');
        if (bs !== -1 && be > bs) {
          try { console.log('Brace extraction:', JSON.stringify(JSON.parse(jsonStr.substring(bs, be+1)), null, 2)); }
          catch(e3) { console.log('Brace also failed'); }
        }
      }
    } catch (e) {
      console.log('Error:', e.message);
      console.log('Raw first 200:', d.substring(0, 200));
    }
  });
});
req.write(body);
req.end();
