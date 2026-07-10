const fs = require('fs');
const path = 'E:\\ai\\MedCalc\\entry\\src\\main\\ets\\services\\AssistantService.ets';
let content = fs.readFileSync(path, 'utf8');

// The file contains Unicode chars U+1438 and U+1439 as think tags
// We need to find lines that use indexOf with these chars and replace them
// with ASCII '<think>' and '</think>'

// First, let's see what's actually in the file
const lines = content.split('\n');
for (let i = 0; i < lines.length; i++) {
  const line = lines[i];
  if (line.includes('indexOf(') && (line.includes('\u1438') || line.includes('\u1439') || line.includes('<think') || line.includes('think'))) {
    console.log(`Line ${i+1}: ${JSON.stringify(line)}`);
  }
}

// Replace the Unicode think tags with ASCII HTML-style tags
// U+1438 -> <think>
// U+1439 -> </think>
content = content.replace(/\u1438/g, '<think>');
content = content.replace(/\u1439/g, '</think>');

// Also check if there are any indexOf('halluci') or similar
const lines2 = content.split('\n');
for (let i = 0; i < lines2.length; i++) {
  const line = lines2[i];
  if (line.includes('indexOf(') && line.includes('think')) {
    console.log(`AFTER Line ${i+1}: ${JSON.stringify(line)}`);
  }
}

fs.writeFileSync(path, content, 'utf8');
console.log('Done!');
