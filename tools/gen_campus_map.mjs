// Generates docs/campus_map.svg + docs/_building_table.md from the CURRENT
// Godot layout (src/data/campus_data.json), not the old web-game tables.
//   node tools/gen_campus_map.mjs .
import fs from 'node:fs';
import path from 'node:path';

const ROOT = process.argv[2] || '.';
const campus = JSON.parse(fs.readFileSync(path.join(ROOT, 'src/data/campus_data.json'), 'utf8'));
const npcs = JSON.parse(fs.readFileSync(path.join(ROOT, 'src/data/npcs.json'), 'utf8'));

const S = campus.scale;                 // 0.7 m per plan px
const [OX, OY] = campus.origin;         // 215, 250
const wx = p => (p - OX) * S;
const wz = p => (p - OY) * S;

const W = 1080, H = 1190, SC = 2.15, PADX = 44, PADY = 96;
const mx = p => PADX + (p - 36) * SC;
const my = p => PADY + (p - 36) * SC;
const hex = n => '#' + n.toString(16).padStart(6, '0');
const lum = c => {
  const n = parseInt(c.slice(1), 16);
  const r = (n >> 16) & 255, g = (n >> 8) & 255, b = n & 255;
  return (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255;
};
const esc = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;');

const rect = (r, fill, stroke = 'none', sw = 1, extra = '') =>
  `<rect x="${mx(r[0]).toFixed(1)}" y="${my(r[1]).toFixed(1)}" width="${((r[2] - r[0]) * SC).toFixed(1)}" height="${((r[3] - r[1]) * SC).toFixed(1)}" fill="${fill}" stroke="${stroke}" stroke-width="${sw}" ${extra}/>`;

const txt = (x, y, s, size = 13, col = '#12212e', anchor = 'middle', weight = 700, halo = false) =>
  `<text x="${mx(x).toFixed(1)}" y="${my(y).toFixed(1)}" font-family="Segoe UI, Arial, sans-serif" font-size="${size}" font-weight="${weight}" fill="${col}" text-anchor="${anchor}"${halo ? ' stroke="#ffffff" stroke-width="3" paint-order="stroke" stroke-linejoin="round"' : ''}>${esc(s)}</text>`;

const screenText = (x, y, s, size = 12, col = '#12212e', anchor = 'middle', weight = 700) =>
  `<text x="${x}" y="${y}" font-family="Segoe UI, Arial, sans-serif" font-size="${size}" font-weight="${weight}" fill="${col}" text-anchor="${anchor}">${esc(s)}</text>`;

let g = '';

// ---------------------------------------------------------------- ground
g += `<rect width="${W}" height="${H}" fill="#7fb069"/>`;
for (let i = 0; i < 1100; i++) {
  const x = (i * 97) % W, y = (i * 151) % H;
  g += `<circle cx="${x}" cy="${y}" r="1.2" fill="#6da45a" opacity=".45"/>`;
}
g += rect([36, 36, 392, 458], '#86b86b', '#3f5b33', 2.5);

// ---------------------------------------------------------------- roads
for (const r of campus.roads) g += rect(r, '#949aa1', '#7c828a', 1.4);
// centre dashes on the two main arteries
const dash = (x0, y0, x1, y1) => `<line x1="${mx(x0)}" y1="${my(y0)}" x2="${mx(x1)}" y2="${my(y1)}" stroke="#f4f1e4" stroke-width="1.6" stroke-dasharray="9 11" opacity=".75"/>`;
g += dash(243, 42, 243, 352);
g += dash(106, 240.5, 236, 240.5);
g += dash(106, 286, 236, 286);

// ---------------------------------------------------------------- zones
const z = campus.zones;
g += rect(z.parade_ground, '#d9c491', '#c3ad78', 1.4);
g += txt(197.5, 364, 'SAND FIELD', 11, '#7a673a');
g += txt(197.5, 371.5, 'OPEN AUDITORIUM GROUNDS', 8.5, '#7a673a', 'middle', 600);
g += rect([231, 388, 243, 404], '#b9c2d6', '#6d7893', 1.2);
g += txt(237, 397.5, 'OPEN', 6.5, '#2f3a4d');
g += txt(237, 403, 'AUDITORIUM', 6.5, '#2f3a4d');

g += rect(z.basketball, '#b96a45', '#8f4c2f', 1.4);
g += `<g stroke="#f3e2c8" stroke-width="2" fill="none"><rect x="${mx(268)}" y="${my(259)}" width="${64 * SC}" height="${44 * SC}"/><line x1="${mx(300)}" y1="${my(259)}" x2="${mx(300)}" y2="${my(303)}"/><circle cx="${mx(300)}" cy="${my(281)}" r="${9 * SC}"/></g>`;
g += txt(300, 309.5, 'BASKETBALL COURT', 8, '#f7e9d4', 'middle', 700);

g += rect(z.power_supply, '#9aa06a', '#7c8352', 1.4);
g += txt(307, 344, 'POWER SUPPLY ROOM', 11, '#3f451c');
g += txt(307, 353, 'substation + transformer yard', 8, '#4c5226', 'middle', 500);
g += rect([298, 361, 318, 381], '#b9bf86', '#6d7440', 1.6);
g += txt(308, 374, 'TX', 8, '#3f451c');

g += rect(z.central_lawn, '#79ad5f', '#5c8a45', 1.2);
g += txt(139.5, 341.5, 'LAWN', 7.5, '#2f5b22');

g += rect(z.parking, '#6f747b', '#5d6268', 1.2);
for (let i = 0; i < 9; i++) {
  const y = 166 + i * 13;
  g += `<line x1="${mx(66)}" y1="${my(y)}" x2="${mx(96)}" y2="${my(y)}" stroke="#c9ced4" stroke-width="1" opacity=".55"/>`;
}
g += txt(81, 285, 'PARKING', 9, '#eef2f6');

// ---------------------------------------------------------------- buildings
for (const b of campus.buildings) {
  const r = b.rect, colour = String(b.color);
  const isAdmin = /ADMIN/i.test(b.name);
  const dark = lum(colour) < 0.55;
  const ink = dark ? '#ffffff' : '#17222b';
  g += rect(r, colour, isAdmin ? '#7a2418' : '#4d4d4d', isAdmin ? 2.4 : 1.2);
  const w = (r[2] - r[0]) * S, d = (r[3] - r[1]) * S;
  const label = b.name.replace(' Block', '').replace(' (N)', ' N').replace(' (S)', ' S');
  const cx = (r[0] + r[2]) / 2, cy = (r[1] + r[3]) / 2;

  if (r[0] < 90) {
    // west strip: the blocks are only ~13 m wide, so use a white label plate
    // just east of the building (over the service road) with a leader line.
    const pw = Math.max(label.length * 5.6, 54) + 10;
    const px = mx(r[2]) + 6, py = my(cy) - 12;
    g += `<line x1="${mx(r[2])}" y1="${my(cy)}" x2="${px}" y2="${my(cy)}" stroke="#2c3a46" stroke-width="1"/>`;
    g += `<rect x="${px}" y="${py}" width="${pw.toFixed(1)}" height="24" rx="4" fill="#ffffffee" stroke="#2c3a46" stroke-width="1"/>`;
    g += `<text x="${px + 5}" y="${py + 10.5}" font-family="Segoe UI, Arial, sans-serif" font-size="9" font-weight="700" fill="#17222b">${esc(label)}</text>`;
    g += `<text x="${px + 5}" y="${py + 20}" font-family="Segoe UI, Arial, sans-serif" font-size="7" font-weight="500" fill="#3c4a56">${w.toFixed(0)}×${d.toFixed(0)} m · h${b.height} m</text>`;
    continue;
  }

  if ((r[2] - r[0]) < 30 && (r[3] - r[1]) > 60) {
    // tall + narrow (IT Block): rotate the label so it stays inside the roof
    g += `<g transform="translate(${mx(cx).toFixed(1)},${my(cy).toFixed(1)}) rotate(-90)">` +
      `<text y="0" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="10" font-weight="800" fill="${ink}">${esc(label)}</text>` +
      `<text y="9" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="6.8" font-weight="500" fill="${ink}">${w.toFixed(0)}×${d.toFixed(0)} m · h${b.height} m</text></g>`;
    continue;
  }

  const size = (r[2] - r[0]) > 100 ? 12.5 : (r[2] - r[0]) > 50 ? 11 : 9.2;
  g += txt(cx, cy + (isAdmin ? -2 : 0), label, size, ink, 'middle', 800);
  const dimSize = (r[2] - r[0]) < 30 ? 6.4 : 7.2;
  g += txt(cx, cy + 6.5, `${w.toFixed(0)}×${d.toFixed(0)} m · h${b.height} m`, dimSize, ink, 'middle', 500);
  if (isAdmin) g += txt(cx, cy + 14, 'Admission Office (inside)', 7, ink, 'middle', 600);
}

// ---------------------------------------------------------------- walls + gates
for (const w of campus.walls) {
  g += `<line x1="${mx(w[0])}" y1="${my(w[1])}" x2="${mx(w[2])}" y2="${my(w[3])}" stroke="#22282e" stroke-width="5"/>`;
}
// main gate (yellow, south wall)
g += `<line x1="${mx(100)}" y1="${my(432)}" x2="${mx(145)}" y2="${my(432)}" stroke="#ffd54a" stroke-width="7"/>`;
g += txt(122.5, 448, 'MAIN GATE', 9.5, '#0e2a47', 'middle', 800, true);
// back gate (blue arch across the north road)
g += `<line x1="${mx(214)}" y1="${my(98)}" x2="${mx(258)}" y2="${my(98)}" stroke="#3a5f9a" stroke-width="6"/>`;
g += txt(236, 92, 'BACK GATE', 8.5, '#1d3c6b', 'middle', 800, true);

// ---------------------------------------------------------------- spawn + NPCs
const sp = campus.spawn.pos;
g += `<circle cx="${mx(sp[0])}" cy="${my(sp[1])}" r="9" fill="#ffd54a" stroke="#8a6a00" stroke-width="2"/><circle cx="${mx(sp[0])}" cy="${my(sp[1])}" r="16" fill="none" stroke="#ffd54a" stroke-width="2" opacity=".65"/>`;
g += txt(122, 474, 'PLAYER SPAWN', 9, '#0e2a47', 'middle', 800, true);

for (const n of (npcs.main || [])) {
  const [x, y] = n.pos;
  const name = n.name.replace(/ \(.*\)/, '');
  g += `<circle cx="${mx(x)}" cy="${my(y)}" r="5.5" fill="#e0245e" stroke="#fff" stroke-width="1.4"/>`;
  const right = x > 200 || y > 430;
  const dy = y > 430 ? -8 : -3;
  g += txt(x + (right ? -1.5 : 1.5), y + dy, name, 8.5, '#7a0c2c', right ? 'end' : 'start', 700, true);
}

// ---------------------------------------------------------------- compass, scale, legend
const cxp = W - 62, cyp = 470;
g += `<g transform="translate(${cxp},${cyp})"><circle r="26" fill="#ffffffd9" stroke="#2c3a46" stroke-width="1.5"/><path d="M0,-20 L7,8 L0,3 L-7,8 Z" fill="#c62828"/><text y="-32" text-anchor="middle" font-family="Segoe UI, Arial, sans-serif" font-size="13" font-weight="800" fill="#2c3a46">N</text></g>`;

const lx = 826, ly = 96, lw = 214, lh = 322;
g += `<g transform="translate(${lx},${ly})"><rect width="${lw}" height="${lh}" rx="10" fill="#ffffffea" stroke="#2c3a46" stroke-width="1.4"/>`;
g += screenText(14, 24, 'LEGEND', 13, '#12212e', 'start', 800);
let row = 0;
const item = (draw, label) => {
  const y = 46 + row * 21;
  g += draw(y);
  g += screenText(42, y + 4, label, 10.5, '#12212e', 'start', 600);
  row++;
};
item(y => `<rect x="16" y="${y - 7}" width="16" height="13" rx="2" fill="#d9a07c" stroke="#4d4d4d"/>`, 'building');
item(y => `<rect x="16" y="${y - 6}" width="16" height="11" fill="#949aa1" stroke="#7c828a"/>`, 'road (ring + internal)');
item(y => `<rect x="16" y="${y - 6}" width="16" height="11" fill="#d9c491" stroke="#c3ad78"/>`, 'sand field / auditorium');
item(y => `<rect x="16" y="${y - 6}" width="16" height="11" fill="#b96a45" stroke="#8f4c2f"/>`, 'basketball court');
item(y => `<rect x="16" y="${y - 6}" width="16" height="11" fill="#9aa06a" stroke="#7c8352"/>`, 'power supply room');
item(y => `<rect x="16" y="${y - 6}" width="16" height="11" fill="#6f747b" stroke="#5d6268"/>`, 'parking');
item(y => `<line x1="14" y1="${y}" x2="34" y2="${y}" stroke="#22282e" stroke-width="4"/>`, 'campus wall');
item(y => `<line x1="14" y1="${y}" x2="34" y2="${y}" stroke="#ffd54a" stroke-width="5"/>`, 'main gate');
item(y => `<line x1="14" y1="${y}" x2="34" y2="${y}" stroke="#3a5f9a" stroke-width="5"/>`, 'back gate');
item(y => `<circle cx="24" cy="${y}" r="5.5" fill="#e0245e" stroke="#fff" stroke-width="1.3"/>`, 'main quest NPC');
item(y => `<circle cx="24" cy="${y}" r="7" fill="#ffd54a" stroke="#8a6a00" stroke-width="1.5"/>`, 'player spawn');
g += `</g>`;

// scale bar: 50 m
const barX = PADX, barY = H - 60, barW = 50 / S * SC;
g += `<g><line x1="${barX}" y1="${barY}" x2="${barX + barW}" y2="${barY}" stroke="#12212e" stroke-width="4"/>`;
g += `<line x1="${barX}" y1="${barY - 6}" x2="${barX}" y2="${barY + 6}" stroke="#12212e" stroke-width="3"/>`;
g += `<line x1="${barX + barW}" y1="${barY - 6}" x2="${barX + barW}" y2="${barY + 6}" stroke="#12212e" stroke-width="3"/>`;
g += screenText(barX + barW / 2, barY - 10, '50 m', 12, '#12212e', 'middle', 700);
g += screenText(barX, barY + 24, '1 plan px = 0.7 m  ·  campus 249 × 295 m', 10, '#2c3a46', 'start', 500);
g += `</g>`;

// ---------------------------------------------------------------- title
g += screenText(W / 2, 40, 'ANITS CAMPUS — CURRENT LAYOUT', 24, '#12212e', 'middle', 800);
g += screenText(W / 2, 62, 'Godot 4.7 build  ·  generated from src/data/campus_data.json  ·  X east, Z south  ·  ring road on all four sides', 10.5, '#2c3a46', 'middle', 500);

const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">${g}</svg>`;
fs.writeFileSync(path.join(ROOT, 'docs/campus_map.svg'), svg, 'utf8');

// ---------------------------------------------------------------- building table
let md = '| # | Building | Map rect (x0,y0,x1,y1) | World centre X,Z (m) | Footprint W × D (m) | Height (m) | ~Floors |\n|---|---|---|---|---|---|---|\n';
campus.buildings.forEach((b, i) => {
  const [x0, y0, x1, y1] = b.rect;
  const cx = wx((x0 + x1) / 2), cz = wz((y0 + y1) / 2);
  md += `| ${i + 1} | ${b.name} | ${x0},${y0},${x1},${y1} | ${cx.toFixed(1)}, ${cz.toFixed(1)} | ${((x1 - x0) * S).toFixed(1)} × ${((y1 - y0) * S).toFixed(1)} | ${b.height} | ~${Math.max(1, Math.round(b.height / 3.5))} |\n`;
});
fs.writeFileSync(path.join(ROOT, 'docs/_building_table.md'), md, 'utf8');

console.log('campus extent:', ((392 - 36) * S).toFixed(1) + ' m ×', ((458 - 36) * S).toFixed(1) + ' m');
console.log('written:', path.join(ROOT, 'docs/campus_map.svg'));
