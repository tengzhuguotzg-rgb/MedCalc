const fs = require('fs');
const path = 'E:\\ai\\MedCalc\\entry\\src\\main\\ets\\services\\AssistantService.ets';
const content = fs.readFileSync(path, 'utf8');
const lines = content.split('\n');

// Check what chars are at lines 615-616
for (const li of [614, 615]) {
  const line = lines[li];
  console.log(`Line ${li+1}:`);
  // Find the indexOf call and check what's inside the quotes
  const match = line.match(/indexOf\('([^']*)'\)/g);
  if (match) {
    for (const m of match) {
      const inner = m.match(/indexOf\('([^']*)'\)/);
      if (inner) {
        const str = inner[1];
        console.log(`  String: ${JSON.stringify(str)}`);
        console.log(`  Char codes: ${[...str].map(c => 'U+' + c.charCodeAt(0).toString(16).padStart(4, '0')).join(', ')}`);
      }
    }
  }
}

// Now fix: replace the Unicode chars in indexOf calls with ASCII equivalents
let fixed = content;
// Replace U+1438 with literal string '<think>' (7 chars)
// Replace U+1439 with literal string '</think>' (9 chars)
fixed = fixed.replace(/\u1438/g, '<think>');
fixed = fixed.replace(/\u1439/g, '</think>');

// Also need to fix the substring offset - if code was using thinkEnd + 8 for '</think>' that's correct
// But if it was using thinkEnd + something else for Unicode chars, need to adjust

const lines2 = fixed.split('\n');
for (const li of [614, 615, 616, 617]) {
  console.log(`Fixed line ${li+1}: ${lines2[li]}`);
}

fs.writeFileSync(path, fixed, 'utf8');
console.log('Fixed!');
