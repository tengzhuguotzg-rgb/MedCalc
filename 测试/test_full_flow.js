const https = require('https');
const fs = require('fs');
const path = require('path');

const IMAGE_PATH = path.join(__dirname, '20260707-221718.jpg');
const API_KEY = 'sk-cp-Hdb0d4PzGsSTqc5DAGWzlFmJ15lB5_RQSxFErxHkLJbCqYxz3Zn40tf0r9lAiGcajM2phQ7_wHaMexKuRQIra6xBOGtZkj9koUKilmMTPNIEFmeEc6X76Kw';

const VALID_FIELD_KEYS = [
  'age','sex','weight','height','sbp','dbp','map','hr','rr','temp','spo2',
  'fio2','fio2Mode','pao2','paco2','ph','hco3','be','lac','creatinine','crUnit',
  'bun','urea','ureaUnit','gfr','na','k','cl','ca','glu','alb','albUnit',
  'bilirubin','bilirubinUnit','alt','ast','platelet','wbc','bands','hct','inr',
  'o2supplement','consciousness','vaso','gcs','gcsEye','gcsVerbal','gcsMotor',
  'urineOutput','peep','confusion','chf','htn','age75','dm','stroke','vasc',
  'age65','female','renal','liver','bleed','inrAbn','drugs','alcohol',
  'bpAbn','clinSym','dur','nihss1a','nihss1b','nihss1c','nihss2','nihss3',
  'nihss4','nihss5a','nihss5b','nihss7','nihss8','nihss9','nihss10','nihss11',
  'arf','chronic','rassScore','ichVol','ichLocation','ichIvh','huntHessGrade',
  'wfnsGrade','fisherGrade','ageCat','dmHtnAngina','sbpLt100','hrGt100',
  'killip','weightLt67','anteriorLbbb','timeToTreat','ageGte65','riskFactorsGte3',
  'knownCAD','priorAspirin','severeAngina','stDevGte05','biomarkerElevated',
  'clinicalPe','hrGt100Pe','surgery','hemoptysis','cancer','ascites',
  'encephalopathy','etiology','hepaticEnceph','acKf','camF1','camF2','camF3',
  'camF4','sexPesi','cancerPesi','chfPesi','cldPesi','ams','osp',
  'perf','resus','comorb','icuDay','roll','situp','sit','standup','stand',
  'cr0','cr1','cr0Unit','cr1Unit','rrt','weightLoss','intake','disease',
  'ageAdj','apache2Score','sofaScore'
];

const FIELD_KEY_ALIASES = {
  'po2': 'pao2',
  'pco2': 'paco2',
  'sao2': 'spo2',
  'so2': 'spo2',
  'tco2': 'hco3',
  'glucose': 'glu',
  'hb': 'hct',
  'k+': 'k',
  'k-plus': 'k',
  'na+': 'na',
  'na-plus': 'na',
  'ca++': 'ca',
  'ica': 'ca',
  'ionized-calcium': 'ca',
  'bicarbonate': 'hco3',
  'lactate': 'lac',
};

const CALC_ID_ALIASES = {
  'pf-ratio': 'pf',
  'anion-gap': 'cag',
  'oxygenation-index': 'pf',
  'pf ratio': 'pf',
  'p/f ratio': 'pf',
  'p/f': 'pf',
  'corrected-sodium': 'na',
  'corrected na': 'na',
  'anion gap': 'cag',
};

const systemPrompt = `你是医学数据提取助手。从图片中提取所有可识别的医疗参数数值，判断哪些计算器可用。
## 重要规则
- 图片中明确标注的数值均可提取
- 提取的字段键名必须使用下方列表中准确的field_key
- 特别注意：PaO2的字段键名是pao2(不是po2)，PaCO2的键名是paco2(不是pco2)，SpO2的键名是spo2(不是sao2)

## 计算器ID列表（matched数组必须使用以下准确的calcId）
pf: 必填[pao2,fio2]
na: 必填[na,glu]
cag: 必填[na,cl,hco3,alb]

## 输出格式
严格输出JSON：
{"extracted":{"field_key":"value",...},"matched":["calcId1","calcId2",...]}
matched必须使用上面列表中准确的calcId。`;

const userContent = '请从这张血气分析报告中提取所有医疗参数';

const imageBase64 = fs.readFileSync(IMAGE_PATH).toString('base64');
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
  hostname: 'api.minimaxi.com', port: 443, path: '/v1/chat/completions',
  method: 'POST',
  headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + API_KEY },
  timeout: 120000
};

console.log('=== STEP 1: Call MiniMax API ===\n');
const req = https.request(options, (res) => {
  let data = '';
  res.on('data', (chunk) => data += chunk);
  res.on('end', () => {
    console.log('API Status:', res.statusCode);
    const parsed = JSON.parse(data);
    const rawContent = parsed.choices[0].message.content;
    console.log('\n=== STEP 2: Raw LLM response (first 200 chars) ===');
    console.log(rawContent.substring(0, 200) + '...');
    
    // STEP 3: Simulate parseExtractionResponse with <think> stripping
    console.log('\n=== STEP 3: Strip <think> tags ===');
    let jsonStr = rawContent.trim();
    const thinkStart = jsonStr.indexOf('<think>');
    const thinkEnd = jsonStr.indexOf('</think>');
    if (thinkStart !== -1 && thinkEnd !== -1) {
      jsonStr = jsonStr.substring(thinkEnd + 8).trim();
      console.log('Stripped <think> block. Remaining text (first 200 chars):');
      console.log(jsonStr.substring(0, 200));
    }
    
    // Also strip markdown fences
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
    
    // STEP 4: Parse JSON
    console.log('\n=== STEP 4: Parse JSON ===');
    const jsonData = JSON.parse(jsonStr);
    const extracted = jsonData.extracted || {};
    const matched = jsonData.matched || [];
    console.log('Matched (raw):', matched);
    
    // STEP 5: Apply FIELD_KEY_ALIASES
    console.log('\n=== STEP 5: Apply field key aliases ===');
    const resolvedFields = {};
    const extractionKeys = Object.keys(extracted);
    console.log('Raw field keys:', extractionKeys);
    for (const key of extractionKeys) {
      const keyLower = key.toLowerCase().trim();
      const aliasKey = FIELD_KEY_ALIASES[keyLower];
      const resolvedKey = aliasKey !== undefined ? aliasKey : keyLower;
      resolvedFields[resolvedKey] = extracted[key];
      if (resolvedKey !== keyLower) {
        console.log(`  ${key} → ${resolvedKey}`);
      }
    }
    console.log('Resolved field keys:', Object.keys(resolvedFields));
    
    // Check for blood gas fields
    const bgFields = ['pao2','paco2','ph','hco3','be','spo2','lac','na','k','cl','glu','fio2','ca'];
    const present = bgFields.filter(f => resolvedFields[f] !== undefined);
    const missing = bgFields.filter(f => resolvedFields[f] === undefined);
    console.log('Present BG fields:', present);
    console.log('Missing BG fields:', missing);
    
    // STEP 6: Apply CALC_ID_ALIASES to matched
    console.log('\n=== STEP 6: Apply calc ID aliases ===');
    const resolvedMatched = [];
    for (const id of matched) {
      const lowerId = id.toLowerCase().trim();
      const aliasId = CALC_ID_ALIASES[lowerId] || lowerId;
      resolvedMatched.push(aliasId);
      if (aliasId !== lowerId) {
        console.log(`  ${id} → ${aliasId}`);
      }
    }
    console.log('Resolved matched:', resolvedMatched);
    
    // STEP 7: Simulate computeAllMatches
    console.log('\n=== STEP 7: computeAllMatches ===');
    const CALC_INPUT_SPECS = [
      { calcId: 'pf', requiredFields: ['pao2','fio2'], name: '氧合指数PF ratio' },
      { calcId: 'na', requiredFields: ['na','glu'], name: '完整校正血钠' },
      { calcId: 'cag', requiredFields: ['na','cl','hco3','alb','albUnit'], name: '阴离子间隙' },
    ];
    
    for (const spec of CALC_INPUT_SPECS) {
      let availableCount = 0;
      const missingFields = [];
      for (const field of spec.requiredFields) {
        if (resolvedFields[field] !== undefined) {
          availableCount++;
        } else {
          missingFields.push(field);
        }
      }
      const completeness = Math.round((availableCount / spec.requiredFields.length) * 100);
      const inMatched = resolvedMatched.includes(spec.calcId);
      
      if (availableCount === 0 && !inMatched) {
        console.log(`  ${spec.calcId}(${spec.name}): SKIPPED (no data, not in matched)`);
      } else {
        console.log(`  ${spec.calcId}(${spec.name}): ${completeness}% complete, missing: [${missingFields.join(',')}]`);
        if (completeness === 100) {
          console.log('    ✓ Can calculate result!');
        } else {
          console.log('    ⚠ Partial match - shows as "待补全"');
        }
      }
    }
    
    console.log('\n=== VERDICT ===');
    if (present.includes('pao2') && present.includes('na') && present.includes('glu')) {
      console.log('✓ Blood gas fields extracted correctly (pao2, na, glu, etc.)');
      const partials = CALC_INPUT_SPECS.filter(s => {
        let count = 0;
        for (const f of s.requiredFields) {
          if (resolvedFields[f] !== undefined) count++;
        }
        return count > 0 && count < s.requiredFields.length;
      });
      if (partials.length > 0) {
        console.log(`✓ ${partials.length} partial match(es) should appear as "待补全"`);
        console.log('FIX IS WORKING');
      } else {
        console.log('✗ No partial matches - fix may not be working');
      }
    } else {
      console.log('✗ Blood gas fields NOT found - fix not working');
    }
  });
});
req.on('error', (e) => console.log('Error:', e.message));
req.write(body);
req.end();
