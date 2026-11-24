/* Security booth beside the main gate, a dog bed + water bowl next to it. Exposes window.__guardBooth = { x, z, bed:{x,z} } for the dog. */
(function () {
  var T = window.THREE, G = window.__g;
  if (!T || !G || !G.sc || !G.NPC || !G.NPC.guard || !G.colliders) return;
  try {
    var gd = G.NPC.guard;
    var bx = gd.x + 3.6, bz = gd.z + 0.2, S = 2.8, H = 2.7;
    var gy = G.groundHeightAt ? G.groundHeightAt(bx, bz) : 0;
    var M = function (c, o) { var m = new T.MeshLambertMaterial({ color: c }); if (o) { m.transparent = true; m.opacity = o; m.depthWrite = false } return m };
    var white = M(0xf2f4f7), blue = M(0x1b3f9e), dark = M(0x2b2f36), concrete = M(0xb9bcc0), glass = M(0x9fd3ee, 0.4), wood = M(0x7a5230);
    var g = new T.Group(); g.name = 'guard_booth'; g.position.set(bx, gy, bz);
    function box(w, h, d, mat, x, y, z) { var m = new T.Mesh(new T.BoxGeometry(w, h, d), mat); m.position.set(x, y, z); m.castShadow = true; m.receiveShadow = true; g.add(m); return m }

    box(S + 0.5, 0.18, S + 0.5, concrete, 0, 0.09, 0);
    var half = S / 2;
    [[-half, -half], [half, -half], [-half, half], [half, half]].forEach(function (p) { box(0.16, H, 0.16, white, p[0], H / 2 + 0.18, p[1]) });
    box(S, 1.0, 0.1, blue, 0, 0.68, -half);
    box(0.1, 1.0, S, blue, half, 0.68, 0);
    box(S, 1.0, 0.1, blue, 0, 0.68, half);
    box(0.1, 1.0, 0.9, blue, -half, 0.68, -half * 0.55);
    box(0.1, 1.0, 0.9, blue, -half, 0.68, half * 0.55);
    box(S - 0.2, 1.3, 0.04, glass, 0, 1.83, -half);
    box(0.04, 1.3, S - 0.2, glass, half, 1.83, 0);
    box(S - 0.2, 1.3, 0.04, glass, 0, 1.83, half);
    box(0.04, 1.3, 0.9, glass, -half, 1.83, -half * 0.55);
    box(0.04, 1.3, 0.9, glass, -half, 1.83, half * 0.55);
    var door = box(0.06, 1.9, 0.8, dark, -half + 0.02, 1.13, 0);
    var hnd = box(0.1, 0.06, 0.06, M(0xd8b24a), -half - 0.02, 1.1, 0.25); hnd.castShadow = false;

    box(S + 0.9, 0.2, S + 0.9, dark, 0, H + 0.28, 0);
    box(S + 0.9, 0.12, S + 0.9, white, 0, H + 0.14, 0);
    var beacon = new T.Mesh(new T.SphereGeometry(0.17, 12, 8), new T.MeshBasicMaterial({ color: 0xff3b30 }));
    beacon.position.set(0, H + 0.55, 0); g.add(beacon);

    var cv = document.createElement('canvas'); cv.width = 512; cv.height = 128;
    var x = cv.getContext('2d');
    x.fillStyle = '#1b3f9e'; x.fillRect(0, 0, 512, 128);
    x.strokeStyle = '#ffd54a'; x.lineWidth = 6; x.strokeRect(6, 6, 500, 116);
    x.fillStyle = '#fff'; x.font = '900 64px sans-serif'; x.textAlign = 'center'; x.textBaseline = 'middle'; x.fillText('SECURITY', 256, 68);
    var tex = new T.CanvasTexture(cv); if (T.sRGBEncoding) tex.encoding = T.sRGBEncoding;
    var sign = new T.Mesh(new T.PlaneGeometry(2.2, 0.55), new T.MeshBasicMaterial({ map: tex }));
    sign.position.set(0, H + 0.12, half + 0.5); g.add(sign);

    box(1.9, 0.08, 0.6, wood, 0.25, 1.0, -half + 0.45);
    box(0.08, 0.8, 0.5, wood, -0.6, 0.6, -half + 0.45);
    box(0.08, 0.8, 0.5, wood, 1.1, 0.6, -half + 0.45);
    box(0.5, 0.08, 0.5, dark, -0.1, 0.62, -half + 1.2);

    G.sc.add(g);
    G.colliders.push({ x0: bx - half - 0.25, x1: bx + half + 0.25, z0: bz - half - 0.25, z1: bz + half + 0.25, h: H + 0.4 });

    var ax = gd.x - 1.9, az = gd.z + 1.0, ay = G.groundHeightAt ? G.groundHeightAt(ax, az) : 0;
    var bed = new T.Group(); bed.position.set(ax, ay, az);
    var rim = new T.Mesh(new T.CylinderGeometry(0.62, 0.66, 0.14, 20), M(0x8b3a2e)); rim.position.y = 0.07; rim.receiveShadow = true;
    var pad = new T.Mesh(new T.CylinderGeometry(0.5, 0.5, 0.17, 20), M(0xe3c79a)); pad.position.y = 0.09;
    var bowl = new T.Mesh(new T.CylinderGeometry(0.17, 0.12, 0.1, 14), M(0xc8ccd2)); bowl.position.set(0.95, 0.05, 0.1);
    var water = new T.Mesh(new T.CylinderGeometry(0.14, 0.14, 0.02, 14), M(0x4fa8e8)); water.position.set(0.95, 0.09, 0.1);
    bed.add(rim, pad, bowl, water); G.sc.add(bed);

    window.__guardBooth = { x: bx, z: bz, group: g, bed: { x: ax, z: az } };
  } catch (e) { console.warn('Guard booth failed, continuing without it', e) }
})();
