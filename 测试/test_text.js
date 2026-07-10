const https = require('https');
const API_KEY = 'sk-cp-Hdb0d4PzGsSTqc5DAGWzlFmJ15lB5_RQSxFErxHkLJbCqYxz3Zn40tf0r9lAiGcajM2phQ7_wHaMexKuRQIra6xBOGtZkj9koUKilmMTPNIEFmeEc6X76Kw';

// Exact same prompt and text as app text-only flow
const prompt = '请从以下医学描述或检查报告图片中列出所有可识别的医疗参数名称和数值。'
  + '列出你能看到的每一项指标。例如：pH 7.35，PaCO2 40mmHg，心率 80次/分。'
  + '同时根据数据判断哪些计算器可能适用：'
  + '氧合指数PF ratio(需pao2和fio2)、完整校正血钠(需na和glu)、阴离子间隙(需na、cl、hco3、alb)'
  + '、SOFA评分(需pao2、fio2、血小板、胆红素、map、vaso、gcs、肌酐、尿量)'
  + '、APACHE II评分(需体温、血压、心率、呼吸、fio2、血气、电解质、肌酐、gcs、年龄)'
  + '、SIRS评分(需体温、心率、呼吸、paco2、wbc、bands)'
  + '、CRCL(需性别、年龄、体重、肌酐)、eGFR(需性别、年龄、肌酐)';

// Text-only case
const text = '血气分析：pH 7.51 PaCO2 28.2 PaO2 148.9 HCO3 22.6 Na 141 K 3.6 Cl 109 Glu 6.9 Lac 1.8';

const body = JSON.stringify({
  model: 'MiniMax-M3', max_tokens: 4096,
  messages: [
    { role: 'system', content: prompt },
    { role: 'user', content: [{ type: 'text', text: text }] }
  ]
});

console.log('=== TEST: Text-only (array format) ===\n');
const req = https.request({
  hostname: 'api.minimaxi.com', port: 443, path: '/v1/chat/completions',
  method: 'POST', timeout: 60000,
  headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + API_KEY }
}, (res) => {
  let data = '';
  res.on('data', (chunk) => data += chunk);
  res.on('end', () => {
    const parsed = JSON.parse(data);
    const raw = parsed.choices[0].message.content;
    console.log('Raw length:', raw.length);
    
    // Strip think tags
    let clean = raw;
    const ts = clean.indexOf('<think>');
    const te = clean.indexOf('</think>');
    if (ts !== -1 && te !== -1) clean = clean.substring(te + 8).trim();
    
    console.log('\n=== AFTER THINK STRIP ===');
    console.log(clean.substring(0, 800));
    console.log('\n... (truncated)');
    
    // Check if it has useful content
    const lower = clean.toLowerCase();
    const keywords = ['ph', 'paco2', 'pao2', 'hco3', 'na', 'glu', 'spo2', 'lac', 'k', 'cl'];
    console.log('\n=== KEYWORD CHECK ===');
    for (const kw of keywords) {
      console.log(`  '${kw}' found: ${lower.indexOf(kw) !== -1}`);
    }
  });
});
req.on('error', (e) => console.log('Error:', e.message));
req.write(body);
req.end();
