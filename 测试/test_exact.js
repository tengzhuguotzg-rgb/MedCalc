const https = require('https');
const fs = require('fs');
const path = require('path');
const IMAGE_PATH = path.join('E:\\ai\\MedCalc\\测试\\20260707-221718.jpg');
const API_KEY = 'sk-cp-Hdb0d4PzGsSTqc5DAGWzlFmJ15lB5_RQSxFErxHkLJbCqYxz3Zn40tf0r9lAiGcajM2phQ7_wHaMexKuRQIra6xBOGtZkj9koUKilmMTPNIEFmeEc6X76Kw';

// Exact same prompt as the app
const prompt = '请从以下医学描述或检查报告图片中列出所有可识别的医疗参数名称和数值。'
  + '列出你能看到的每一项指标。例如：pH 7.35，PaCO2 40mmHg，心率 80次/分。'
  + '同时根据数据判断哪些计算器可能适用：'
  + '氧合指数PF ratio(需pao2和fio2)、完整校正血钠(需na和glu)、阴离子间隙(需na、cl、hco3、alb)'
  + '、SOFA评分(需pao2、fio2、血小板、胆红素、map、vaso、gcs、肌酐、尿量)'
  + '、APACHE II评分(需体温、血压、心率、呼吸、fio2、血气、电解质、肌酐、gcs、年龄)'
  + '、SIRS评分(需体温、心率、呼吸、paco2、wbc、bands)'
  + '、CRCL(需性别、年龄、体重、肌酐)、eGFR(需性别、年龄、肌酐)';

const userContent = '请描述这张检查报告图片中的所有医疗参数数值';
const imageBase64 = fs.readFileSync(IMAGE_PATH).toString('base64');

const body = JSON.stringify({
  model: 'MiniMax-M3', max_tokens: 4096,
  messages: [
    { role: 'system', content: prompt },
    { role: 'user', content: [
      { type: 'text', text: userContent },
      { type: 'image_url', image_url: { url: 'data:image/jpeg;base64,' + imageBase64 } }
    ]}
  ]
});

console.log('Calling API...');
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
    
    // Simulate exact app flow
    // Step 1: fallbackParse
    let clean = raw;
    const ts = clean.indexOf('<think>');
    const te = clean.indexOf('</think>');
    if (ts !== -1 && te !== -1) clean = clean.substring(te + 8);
    
    const lower = clean.toLowerCase();
    
    // Find calc IDs
    const VALID_CALC_IDS = ['map','sf','gcs','news2','sofa','pf','na','curb65','sirs','rox','cag','chadsvasc','hasbled','abcd2','nihss','crcl','gfr','apache2','rass','ich','hunthess','wfns','fisher','marshall','mehran','timistemi','timinstemi','wells','childpugh','kcc','clifc','aarc','camicu','pesi','scai','mnutric','fssicu','kdigo','nrs2002'];
    
    const matched = [];
    for (const id of VALID_CALC_IDS) {
      if (lower.indexOf(id) !== -1 && !matched.includes(id)) {
        matched.push(id);
      }
    }
    
    // Also check aliases
    const ALIASES = {
      'pf-ratio': 'pf', 'anion-gap': 'cag', 'pf ratio': 'pf',
      'corrected-sodium': 'na', 'anion gap': 'cag', 'oxygenation-index': 'pf',
    };
    for (const [alias, target] of Object.entries(ALIASES)) {
      if (lower.indexOf(alias) !== -1 && !matched.includes(target)) {
        matched.push(target);
      }
    }
    
    // Extract field values
    const numberPatterns = [
      ['age', '年龄', '岁'], ['sbp', '收缩压', 'sbp'], ['hr', '心率', 'hr'],
      ['rr', '呼吸', 'rr'], ['temp', '体温', '温度'],
      ['pao2', 'pao2', 'po2', '氧分压'], ['paco2', 'paco2', 'pco2', '二氧化碳分压'],
      ['ph', 'ph', '酸碱度'], ['hco3', 'hco3', '碳酸氢根'],
      ['be', 'be', '剩余碱'], ['spo2', 'spo2', 'sao2', '血氧饱和度'],
      ['na', '血钠', '钠', 'na+'], ['k', '血钾', '钾', 'k+'],
      ['cl', '血氯', '氯'], ['ca', '血钙', '钙'],
      ['glu', '血糖', 'glu', 'glucose'], ['lac', '乳酸'],
      ['creatinine', '肌酐', 'cr'], ['fio2', 'fio2', '吸氧浓度'],
      ['wbc', '白细胞', 'wbc'], ['hct', '红细胞压积', 'hct', 'hb'],
      ['weight', '体重', 'kg'], ['gcs', 'gcs', '格拉斯哥'],
      ['platelet', '血小板'], ['bilirubin', '胆红素'],
      ['alb', '白蛋白', 'alb'], ['inr', 'inr'],
    ];
    
    const fields = {};
    for (const pat of numberPatterns) {
      for (const keyword of pat) {
        const idx = lower.indexOf(keyword);
        if (idx !== -1) {
          const after = clean.substring(idx + keyword.length);
          const m = after.match(/[\s:=：|]*([0-9]+\.?[0-9]*)/);
          if (m && m[1]) {
            fields[pat[0]] = m[1];
            break;
          }
        }
      }
    }
    
    if (lower.indexOf('女') !== -1 || lower.indexOf('女性') !== -1) fields['sex'] = 'female';
    if (lower.indexOf('男') !== -1 || lower.indexOf('男性') !== -1) fields['sex'] = 'male';
    
    console.log('\n=== EXTRACTED FIELDS ===');
    console.log(JSON.stringify(fields, null, 2));
    console.log('\nNumber of fields:', Object.keys(fields).length);
    
    console.log('\n=== MATCHED CALC IDS ===');
    console.log(matched);
    
    // Simulate computeAllMatches
    const CALC_SPECS = [
      { id: 'pf', req: ['pao2','fio2'], name: '氧合指数PF ratio' },
      { id: 'na', req: ['na','glu'], name: '完整校正血钠' },
      { id: 'cag', req: ['na','cl','hco3','alb'], name: '阴离子间隙' },
      { id: 'crcl', req: ['sex','age','weight','creatinine'], name: 'CRCL' },
      { id: 'gfr', req: ['sex','age','creatinine'], name: 'eGFR' },
      { id: 'sirs', req: ['temp','hr','rr','paco2','wbc','bands'], name: 'SIRS' },
    ];
    
    console.log('\n=== MATCH RESULTS ===');
    for (const spec of CALC_SPECS) {
      let avail = 0;
      const missing = [];
      for (const f of spec.req) {
        if (fields[f] !== undefined) avail++;
        else missing.push(f);
      }
      if (avail === 0 && !matched.includes(spec.id)) continue;
      const pct = Math.round(avail / spec.req.length * 100);
      console.log(`${spec.id}(${spec.name}): ${pct}% [${missing.join(',')}]`);
    }
  });
});
req.on('error', (e) => console.log('Error:', e.message));
req.write(body);
req.end();
