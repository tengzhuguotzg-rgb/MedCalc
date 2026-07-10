const https = require('https');
const fs = require('fs');
const path = require('path');

const IMAGE_PATH = path.join(__dirname, '20260707-221718.jpg');
const API_KEY = 'sk-cp-Hdb0d4PzGsSTqc5DAGWzlFmJ15lB5_RQSxFErxHkLJbCqYxz3Zn40tf0r9lAiGcajM2phQ7_wHaMexKuRQIra6xBOGtZkj9koUKilmMTPNIEFmeEc6X76Kw';

function imageToBase64(filePath) {
  const data = fs.readFileSync(filePath);
  return data.toString('base64');
}

function callMiniMax(modelServiceId) {
  const imageBase64 = imageToBase64(IMAGE_PATH);
  
  const systemPrompt = `你是医学数据提取助手。从用户文字描述或医学检查报告图片中提取所有可识别的医疗参数数值，判断哪些计算器可用。
## 重要规则
- 如果输入是医学检查报告图片（如血气分析、生化检验、血常规等），仔细识别图片中每一项指标及其数值，尽可能多地提取，不要遗漏
- 血气分析报告常见指标：pH、PaCO2、PaO2、HCO3、BE、乳酸(Lac)、FiO2、SpO2、Na、K、Cl、Ca、Glu等
- 生化检验报告常见指标：肌酐(Cr)、尿素氮(BUN)、血钠(Na)、血钾(K)、血糖(Glu)、白蛋白(Alb)、胆红素(TBil)、ALT、AST等
- 数值和单位要按字段定义转换（如肌酐mg/dL需标注crUnit为mgdl，FiO2百分比需转换为小数如40%→0.4并标注fio2Mode为pct）
- 图片中明确标注的数值均可提取，不需要用户逐项提及

## 可提取字段
age: 年龄(岁) 参考:18-100
sex: 性别 选项:male/female
weight: 体重(kg) 参考:40-120
height: 身高(cm) 参考:140-200
sbp: 收缩压(mmHg) 参考:90-140
dbp: 舒张压(mmHg) 参考:60-90
hr: 心率(次/分) 参考:60-100
rr: 呼吸频率(次/分) 参考:12-20
temp: 体温(°C) 参考:36.0-38.0
spo2: SpO2(%) 参考:95-100
fio2: FiO2 参考:0.21-1.0
fio2Mode: FiO2模式 选项:dec/pct
pao2: PaO2(mmHg) 参考:80-100
paco2: PaCO2(mmHg) 参考:35-45
ph: pH 参考:7.35-7.45
hco3: HCO3(mmol/L) 参考:22-26
be: BE(mmol/L) 参考:-2 to +2
lac: 乳酸(mmol/L) 参考:0.5-2.0
creatinine: 血肌酐(μmol/L) 参考:44-133
na: 血钠(mmol/L) 参考:136-145
k: 血钾(mmol/L) 参考:3.5-5.5
glu: 血糖(mmol/L) 参考:3.9-6.1
cl: 血氯(mmol/L) 参考:96-108
ca: 血钙(mmol/L) 参考:2.1-2.6
alb: 白蛋白(g/L) 参考:35-55
bilirubin: 胆红素(μmol/L) 参考:3-22
alt: ALT(U/L) 参考:10-40
ast: AST(U/L) 参考:10-40
platelet: 血小板(×10^9/L) 参考:100-300
wbc: 白细胞(×10^9/L) 参考:4-10
hct: 红细胞压积(%) 参考:36-50
inr: INR 参考:0.8-1.2
wbc: 白细胞(×10^9/L) 参考:4-10

## 计算器所需字段
map(平均动脉压): 必填[sbp,dbp]
sf(SF ratio): 必填[spo2,fio2]
gcs(格拉斯哥昏迷评分): 必填[gcsEye,gcsVerbal,gcsMotor]
news2(NEWS2评分): 必填[rr,spo2,o2supplement,temp,sbp,hr,consciousness]
sofa(SOFA评分): 必填[pao2,fio2,platelet,bilirubin,map,vaso,gcs,creatinine,urineOutput]
pf(氧合指数PF ratio): 必填[pao2,fio2]
na(完整校正血钠): 必填[na,glu]
sirs(SIRS评分): 必填[temp,hr,rr,paco2,wbc,bands]
rox(ROX指数): 必填[spo2,fio2,rr]
cag(阴离子间隙): 必填[na,cl,hco3,alb]
crcl(Cockcroft-Gault): 必填[sex,age,weight,creatinine]
gfr(eGFR): 必填[sex,age,creatinine]
apache2(APACHE II评分): 必填[temp,sbp,hr,rr,fio2,pao2,paco2,ph,hco3,na,k,creatinine,gcs,age...]

## 输出格式
严格输出JSON，不要输出任何其他文字：
{"extracted":{"field_key":"value",...},"matched":["calcId1","calcId2",...]}
规则：1.从文字或图片中尽可能多提取明确可识别的数值 2.数值统一为数字字符串 3.sex字段用male/female 4.布尔字段用0/1 5.matched列出所有至少有1个必填字段的计算器按相关度排序 6.如确实无法提取任何医疗数据返回{"extracted":{},"matched":[]}`;

  const userContent = '请从这张医学检查报告中提取所有可识别的医疗数据参数';
  
  const body = JSON.stringify({
    model: modelServiceId,
    max_tokens: 4096,
    messages: [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: [
        { type: 'text', text: userContent },
        { type: 'image_url', image_url: { url: 'data:image/jpeg;base64,' + imageBase64 } }
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
    }
  };

  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        console.log('Status:', res.statusCode);
        try {
          const parsed = JSON.parse(data);
          if (parsed.choices && parsed.choices[0] && parsed.choices[0].message) {
            console.log('\n=== LLM RESPONSE CONTENT ===\n');
            console.log(parsed.choices[0].message.content);
            resolve(parsed.choices[0].message.content);
          } else {
            console.log('\n=== FULL RESPONSE ===\n');
            console.log(JSON.stringify(parsed, null, 2));
            resolve(data);
          }
        } catch(e) {
          console.log('\n=== RAW RESPONSE ===\n');
          console.log(data);
          resolve(data);
        }
      });
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

// Try with MiniMax model ID - usually "MiniMax-M3" for the official model
console.log('=== Testing MiniMax M3 with blood gas image ===\n');
callMiniMax('MiniMax-M3').catch(err => console.error('Error:', err.message));
