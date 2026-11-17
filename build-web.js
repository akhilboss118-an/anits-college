const fs = require('fs');
const path = require('path');

const srcDir = __dirname;
const outDir = path.join(__dirname, 'www');

if (fs.existsSync(outDir)) {
  fs.rmSync(outDir, { recursive: true, force: true });
}
fs.mkdirSync(outDir, { recursive: true });

const itemsToCopy = ['index.html', 'manifest.webmanifest', 'assets', 'css', 'js'];

for (const item of itemsToCopy) {
  const src = path.join(srcDir, item);
  const dest = path.join(outDir, item);
  if (fs.existsSync(src)) {
    fs.cpSync(src, dest, { recursive: true });
    console.log(`Copied ${item} -> www/${item}`);
  }
}
console.log('Web build prepared in www/');
