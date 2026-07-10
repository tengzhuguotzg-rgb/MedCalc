const https = require('https');
const API_KEY = 'sk-cp-Hdb0d4PzGsSTqc5DAGWzlFmJ15lB5_RQSxFErxHkLJbCqYxz3Zn40tf0r9lAiGcajM2phQ7_wHaMexKuRQIra6xBOGtZkj9koUKilmMTPNIEFmeEc6X76Kw';
// EXACT prompt from buildExtractionPrompt()
const prompt = require('fs').readFileSync('E:/ai/MedCalc/测试/20260707-221718.jpg');
const imageBase64 = prompt.toString('base64');

// Build the exact extraction prompt that the app uses
const dataFields = ['pao2: PaO2(mmHg)', 'paco2: PaCO2(mmHg)', 'ph: pH', 'hco3: HCO3(mmol/L)', 'be: BE(mmol/L)', 'spo2: SpO2(%)', 'na: 血钠(mmol/L)', 'k: 血钾(mmol/L)', 'cl: 血氯(mmol/L)', 'ca: 血钙(mmol/L)', 'glu: 血糖(mmol/L)', 'lac: 乳酸(mmol/L)', 'fio2: FiO2', 'creatinine: 血肌酐(μmol/L)'];

const calcSpecs = [
  'pf(氧合指数PF ratio): 必填[pao2,fio2]',
  'na(完整校正血钠): 必填[na,glu]',
  'cag(阴离子间隙): 必填[na,cl,hco3,alb]',
  'sf(SF ratio): 必填[spo2,fio2]',
  'sofa(SOFA评分): 必填[pao2,fio2,platelet,bilirubin,map,vaso,gcs,creatinine,urineOutput]',
  'sirs(SIRS评分): 必填[temp,hr,rr,paco2,wbc,bands]',
  'crcl: 必填[sex,age,weight,creatinine]',
  'gfr: 必填[sex,age,creatinine]',
  'apache2(APACHE II): 必填[temp,sbp,hr,rr,fio2,pao2,paco2,ph,hco3,na,k,creatinine,gcs,age]',
];

const promptText = '你是医学数据提取助手。从图片中提取医疗参数。\n\n## 可提取字段\n' + dataFields.join('\n') + '\n\n## 计算器ID列表\n' + calcSpecs.join('\n') + '\n\n## 输出格式\n{"extracted":{"field_key":"value",...},"matched":["calcId1","calcId2",...]}\n规则：matched必须使用列表中准确的calcId。字段名不是po2,是pao2；不是pco2,是paco2；不是sao2,是spo2。不要使用Unicode下标字符。';

const body = JSON.stringify({
  model: 'MiniMax-M3', max_tokens: 4096,
  messages: [
    { role: 'system', content: promptText },
    { role: 'user', content: [{ type: 'text', text: '请从这张血气分析报告图片中提取所有医疗数据' }, { type: 'image_url', image_url: { url: 'data:image/jpeg;base64,' + imageBase64 } }] }
  ]
});

const req = https.request({
  hostname: 'api.minimaxi.com', port: 443, path: '/v1/chat/completions',
  method: 'POST', timeout: 120000,
  headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + API_KEY }
}, (res) => {
  let data = '';
  res.on('data', (chunk) => data += chunk);
  res.on('end', () => {
    const parsed = JSON.parse(data);
    const raw = parsed.choices[0].message.content;
    console.log('Raw length:', raw.length);
    
    // Strip think tags (this is what parseExtractionResponse does)
    let jsonStr = raw.trim();
    const ts = jsonStr.indexOf('<think>');
    const te = jsonStr.indexOf('</think>');
    if (ts !== -1 && te !== -1) jsonStr = jsonStr.substring(te + 8).trim();
    
    // Strip fences
    const fm = jsonStr.indexOf('```');
    if (fm !== -1) {
      const af = jsonStr.substring(fm + 3);
      const fe = af.indexOf('```');
      if (fe !== -1) jsonStr = af.substring(0, fe).trim();
      else jsonStr = af.trim();
      if (jsonStr.startsWith('json')) jsonStr = jsonStr.substring(4).trim();
    }
    
    console.log('\nAfter stripping (first 300):', jsonStr.substring(0, 300));
    
    // Try JSON parse
    try {
      const jd = JSON.parse(jsonStr);
      console.log('\n=== PARSED JSON ===');
      console.log('extracted keys:', Object.keys(jd.extracted || {}));
      console.log('matched:', jd.matched);
      
      // Check for Unicode in keys
      const keys = Object.keys(jd.extracted || {});
      const unicodeKeys = keys.filter(k => /[^\x00-\x7F]/.test(k));
      if (unicodeKeys.length > 0) {
        console.log('\n⚠ UNICODE IN KEYS:', unicodeKeys);
        console.log('normalizeFieldKey will fix these');
      } else {
        console.log('\n✓ All keys ASCII - no normalization needed');
      }
      
      // Simulate normalizeFieldKey
      const FIELD_KEY_ALIASES = { 'po2': 'pao2', 'pco2': 'paco2', 'sao2': 'spo2', 'so2': 'spo2', 'tco2': 'hco3', 'glucose': 'glu', 'hb': 'hct', 'k+': 'k', 'na+': 'na', 'ca++': 'ca', 'ica': 'ca', 'bicarbonate': 'hco3', 'lactate': 'lac' };
      function norm(k) {
        let key = k.toLowerCase().trim()
          .replace(/\u2082/g,'2').replace(/\u2083/g,'3').replace(/\u2084/g,'4')
          .replace(/\u207a/g,'+').replace(/\u207b/g,'-')
          .replace(/\u00b2/g,'2').replace(/\u00b3/g,'3');
        let cleaned = '';
        for (let i = 0; i < key.length; i++) {
          const c = key[i];
          if ((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c === '+' || c === '-') cleaned += c;
        }
        return FIELD_KEY_ALIASES[cleaned] || cleaned;
      }
      const resolved = {};
      for (const k of keys) {
        const rk = norm(k);
        resolved[rk] = jd.extracted[k];
        if (rk !== k) console.log(`  ${k} → ${rk} = ${jd.extracted[k]}`);
      }
      console.log('\nResolved keys:', Object.keys(resolved));
      
      // Check for pf, cag, na matches
      const bgs = ['pao2','paco2','ph','hco3','be','spo2','na','k','cl','glu','lac','ca','fio2','creatinine'];
      const pf = bgs.filter(f => resolved[f] !== undefined);
      const mf = bgs.filter(f => resolved[f] === undefined);
      console.log('\nPresent:', pf);
      console.log('Missing:', mf);
      console.log('\n✓ pf(pao2=' + (resolved['pao2']||'?') + ') needs fio2 too');
      console.log('✓ na(na=' + resolved['na'] + ', glu=' + resolved['glu'] + ')');
      console.log('✓ cag(na=' + resolved['na'] + ', cl=' + resolved['cl'] + ', hco3=' + resolved['hco3'] + ')');
    } catch(e) {
      console.log('\nJSON parse failed:', e.message);
      // Try brace extraction
      const bs = jsonStr.indexOf('{');
      const be = jsonStr.lastIndexOf('}');
      if (bs !== -1 && be > bs) {
        const candidate = jsonStr.substring(bs, be + 1);
        try { console.log('Brace extraction:', JSON.stringify(JSON.parse(candidate), null, 2)); }
        catch(e2) { console.log('Brace extraction also failed'); }
      }
    }
  });
});
req.on('error', (e) => console.log('Error:', e.message));
req.write(body);
req.end();
