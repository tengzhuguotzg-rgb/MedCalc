const https = require('https');

const API_KEY = 'sk-cp-Hdb0d4PzGsSTqc5DAGWzlFmJ15lB5_RQSxFErxHkLJbCqYxz3Zn40tf0r9lAiGcajM2phQ7_wHaMexKuRQIra6xBOGtZkj9koUKilmMTPNIEFmeEc6X76Kw';

function call(urlPath, hostname, modelName) {
  const body = JSON.stringify({
    model: modelName,
    max_tokens: 2048,
    messages: [
      { role: 'user', content: 'Say OK and nothing else' }
    ]
  });

  const options = {
    hostname: hostname,
    port: 443,
    path: urlPath,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + API_KEY,
      'Content-Length': Buffer.byteLength(body)
    },
    timeout: 30000
  };

  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        resolve({ status: res.statusCode, body: data });
      });
    });
    req.on('timeout', () => { req.destroy(); reject(new Error('timeout')); });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

async function main() {
  // Try different endpoints
  const endpoints = [
    { host: 'api.minimaxi.com', path: '/v1/chat/completions', model: 'MiniMax-M3' },
    { host: 'api.minimaxi.com', path: '/v1/chat/completions', model: 'minimax-m3' },
    { host: 'api.minimaxi.com', path: '/v1/chat/completions', model: 'MiniMax-M1' },
  ];

  for (const ep of endpoints) {
    try {
      console.log(`\n=== Trying: ${ep.host}${ep.path} model=${ep.model} ===`);
      const r = await call(ep.path, ep.host, ep.model);
      console.log(`Status: ${r.status}`);
      try {
        const parsed = JSON.parse(r.body);
        console.log('Response:', JSON.stringify(parsed, null, 2).substring(0, 500));
      } catch(e) {
        console.log('Raw:', r.body.substring(0, 500));
      }
    } catch(e) {
      console.log(`Error: ${e.message}`);
    }
  }
}

main();
