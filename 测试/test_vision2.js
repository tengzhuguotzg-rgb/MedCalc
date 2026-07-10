const https = require('https');
const fs = require('fs');
const path = require('path');

const IMAGE_PATH = path.join(__dirname, '20260707-221718.jpg');
const API_KEY = 'sk-cp-Hdb0d4PzGsSTqc5DAGWzlFmJ15lB5_RQSxFErxHkLJbCqYxz3Zn40tf0r9lAiGcajM2phQ7_wHaMexKuRQIra6xBOGtZkj9koUKilmMTPNIEFmeEc6X76Kw';

function imageToBase64(filePath) {
  const data = fs.readFileSync(filePath);
  return data.toString('base64');
}

// Use the exact same prompt as the updated buildExtractionPrompt()
const systemPrompt = `你是医学数据提取助手。从用户文字描述或医学检查报告图片中提取所有可识别的医疗参数数值，判断哪些计算器可用。
## 重要规则
- 如果输入是医学检查报告图片（如血气分析、生化检验、血常规等），仔细识别图片中每一项指标及其数值，尽可能多地提取，不要遗漏
- 血气分析报告常见指标：pH、PaCO2、PaO2、HCO3、BE、乳酸(Lac)、FiO2、SpO2、Na、K、Cl、Ca、Glu等
- 生化检验报告常见指标：肌酐(Cr)、尿素氮(BUN)、血钠(Na)、血钾(K)、血糖(Glu)、白蛋白(Alb)、胆红素(TBil)、ALT、AST等
- 数值和单位要按字段定义转换（如肌酐mg/dL需标注crUnit为mgdl，FiO2百分比需转换为小数如40%→0.4并标注fio2Mode为pct）
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
spo2: SpO2(%) 参考:95-100
fio2: FiO2 参考:0.21-1.0

## 计算器ID列表（matched数组必须使用以下准确的calcId！）
注：这些是系统中定义的计算器ID，matched中只能使用这些ID，不要使用拼音、英文翻译或缩写。
pf(氧合指数PF ratio): 必填[pao2,fio2]
na(完整校正血钠): 必填[na,glu]
cag(阴离子间隙): 必填[na,cl,hco3,alb]
sf(SF ratio): 必填[spo2,fio2]
sofa(SOFA评分): 必填[pao2,fio2,platelet,bilirubin,map,vaso,gcs,creatinine,urineOutput]
apache2(APACHE II评分): 必填[temp,sbp,hr,rr,fio2,pao2,paco2,ph,hco3,na,k,creatinine,gcs,age...]
sirs(SIRS评分): 必填[temp,hr,rr,paco2,wbc,bands]

常见别名对应关系（请勿使用别名，统一用左侧calcId）：
pf-ratio(氧合指数)→pf, anion-gap(阴离子间隙)→cag, blood-gas(血气分析)→根据提取字段匹配对应计算器, corrected-calcium(校正钙)→系统中无独立计算器, osmolal-gap(渗透压间隙)→系统中无独立计算器

## 输出格式
严格输出JSON，不要输出任何其他文字：
{"extracted":{"field_key":"value",...},"matched":["calcId1","calcId2",...]}
规则：1.从文字或图片中尽可能多提取明确可识别的数值 2.数值统一为数字字符串单位按字段定义 3.sex字段用male/female 4.布尔字段用0/1 5.matched列出所有至少有1个必填字段的计算器按相关度排序，必须使用上面列表中准确的calcId 6.如确实无法提取任何医疗数据返回{"extracted":{},"matched":[]}`;

const userContent = '请从这张医学检查报告中提取所有可识别的医疗数据参数';
const imageBase64 = imageToBase64(IMAGE_PATH);
const imageUrl = 'data:image/jpeg;base64,' + imageBase64;

console.log('Image:', (imageBase64.length * 3 / 4 / 1024 / 1024).toFixed(2), 'MB');

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

console.log('Body size:', (Buffer.byteLength(body) / 1024 / 1024).toFixed(2), 'MB');

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

console.log('\n=== Sending vision request ===');
const req = https.request(options, (res) => {
  let data = '';
  res.on('data', (chunk) => data += chunk);
  res.on('end', () => {
    console.log('Status:', res.statusCode);
    try {
      const parsed = JSON.parse(data);
      if (parsed.choices && parsed.choices[0] && parsed.choices[0].message) {
        const content = parsed.choices[0].message.content;
        const jsonMatch = content.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          try {
            const parsedJson = JSON.parse(jsonMatch[0]);
            console.log('\n=== PARSED JSON ===\n');
            console.log(JSON.stringify(parsedJson, null, 2));
            console.log('\nExtracted fields:', Object.keys(parsedJson.extracted || {}).length);
            console.log('Matched calc IDs:', parsedJson.matched);
            
            // Verify all matched IDs are valid
            const validIds = ['pf','na','cag','sf','sofa','apache2','sirs','rox','gcs','news2','map','curb65','crcl','gfr','rass','ich','hunthess','wfns','fisher','marshall','mehran','timistemi','timinstemi','wells','childpugh','kcc','clifc','aarc','camicu','pesi','scai','mnutric','fssicu','kdigo','abcd2','nrs2002','nihss'];
            const invalidIds = (parsedJson.matched || []).filter(id => !validIds.includes(id));
            if (invalidIds.length > 0) {
              console.log('\n⚠ INVALID calc IDs that will be filtered out:', invalidIds);
            } else {
              console.log('\n✓ ALL calc IDs are valid!');
            }
          } catch(e) {
            console.log('Content:', content.substring(0, 1000));
          }
        } else {
          console.log('No JSON found in response');
        }
        console.log('\nUsage:', JSON.stringify(parsed.usage));
      } else {
        console.log('Response:', JSON.stringify(parsed, null, 2).substring(0, 1000));
      }
    } catch(e) {
      console.log('Parse error:', e.message);
      console.log('Raw:', data.substring(0, 1000));
    }
  });
});
req.on('timeout', () => { req.destroy(); console.log('TIMEOUT'); });
req.on('error', (e) => console.log('Error:', e.message));
req.write(body);
req.end();
