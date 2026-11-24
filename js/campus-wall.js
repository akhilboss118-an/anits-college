/* Perimeter wall: a 3.6 m (about twice the player's height) brick compound wall around the whole campus, with buttress pillars and taller corner towers.
   The main gate keeps its own opening on the south side (map-pixel x 100..145). Walls are solid colliders. */
(function () {
  var T = window.THREE, G = window.__g;
  if (!T || !G || !G.sc || !G.colliders || !G.wx || !G.wz) return;
  try {
    var HEIGHT = 3.6, THICK = 0.9, PILLAR = 12;
    var X0 = G.wx(50), X1 = G.wx(374), Z0 = G.wz(50), Z1 = G.wz(432);
    var GX0 = G.wx(100), GX1 = G.wx(145);

    function brickTex() {
      var c = document.createElement('canvas'); c.width = 256; c.height = 128;
      var x = c.getContext('2d');
      x.fillStyle = '#6d6258'; x.fillRect(0, 0, 256, 128);
      var rows = 8, bh = 128 / rows, bw = 64, pal = ['#a8553b', '#9a4a33', '#b4623f', '#8f4430', '#a35a3c'];
      for (var r = 0; r < rows; r++) {
        var off = (r % 2) * (bw / 2);
        for (var i = -1; i < 256 / bw + 1; i++) {
          x.fillStyle = pal[(r * 3 + i * 7 + 50) % pal.length];
          x.fillRect(i * bw + off + 2, r * bh + 2, bw - 4, bh - 4);
        }
      }
      var t = new T.CanvasTexture(c);
      t.wrapS = t.wrapT = T.RepeatWrapping;
      if (T.sRGBEncoding) t.encoding = T.sRGBEncoding;
      return t;
    }
    var base = brickTex();
    var cream = new T.MeshLambertMaterial({ color: 0xe8dcc2 });
    var dark = new T.MeshLambertMaterial({ color: 0x5a2a20 });
    var group = new T.Group(); group.name = 'campus_perimeter_wall';

    function seg(xa, xb, za, zb) {
      var w = Math.abs(xb - xa), d = Math.abs(zb - za), cx = (xa + xb) / 2, cz = (za + zb) / 2;
      var alongX = w >= d, len = alongX ? w : d;
      var tex = base.clone(); tex.needsUpdate = true;
      tex.repeat.set(len / 5, HEIGHT / 3.2);
      var m = new T.Mesh(new T.BoxGeometry(alongX ? len : THICK, HEIGHT, alongX ? THICK : len), new T.MeshLambertMaterial({ map: tex }));
      m.position.set(cx, HEIGHT / 2, cz); m.receiveShadow = true; group.add(m);
      var cop = new T.Mesh(new T.BoxGeometry(alongX ? len + 0.1 : THICK + 0.5, 0.3, alongX ? THICK + 0.5 : len + 0.1), cream);
      cop.position.set(cx, HEIGHT + 0.15, cz); group.add(cop);
      var plinth = new T.Mesh(new T.BoxGeometry(alongX ? len : THICK + 0.3, 0.45, alongX ? THICK + 0.3 : len), dark);
      plinth.position.set(cx, 0.225, cz); group.add(plinth);
      G.colliders.push({ x0: cx - (alongX ? len : THICK) / 2, x1: cx + (alongX ? len : THICK) / 2, z0: cz - (alongX ? THICK : len) / 2, z1: cz + (alongX ? THICK : len) / 2, h: HEIGHT + 0.3 });
    }

    seg(X0, X1, Z0, Z0);
    seg(X0, GX0, Z1, Z1);
    seg(GX1, X1, Z1, Z1);
    seg(X0, X0, Z0, Z1);
    seg(X1, X1, Z0, Z1);

    var pts = [];
    function along(xa, za, xb, zb) {
      var L = Math.hypot(xb - xa, zb - za), n = Math.max(1, Math.round(L / PILLAR));
      for (var i = 1; i < n; i++) pts.push([xa + (xb - xa) * i / n, za + (zb - za) * i / n]);
    }
    along(X0, Z0, X1, Z0); along(X0, Z1, GX0, Z1); along(GX1, Z1, X1, Z1); along(X0, Z0, X0, Z1); along(X1, Z0, X1, Z1);
    var pg = new T.BoxGeometry(1.4, HEIGHT + 1.1, 1.4), cg = new T.BoxGeometry(1.8, 0.35, 1.8);
    var pm = new T.InstancedMesh(pg, new T.MeshLambertMaterial({ color: 0xc9b99a }), pts.length), cm = new T.InstancedMesh(cg, cream, pts.length);
    var mt = new T.Matrix4();
    pts.forEach(function (p, i) {
      mt.makeTranslation(p[0], (HEIGHT + 1.1) / 2, p[1]); pm.setMatrixAt(i, mt);
      mt.makeTranslation(p[0], HEIGHT + 1.1 + 0.175, p[1]); cm.setMatrixAt(i, mt);
    });
    pm.instanceMatrix.needsUpdate = cm.instanceMatrix.needsUpdate = true;
    pm.frustumCulled = cm.frustumCulled = false;
    group.add(pm, cm);

    var corners = [[X0, Z0], [X1, Z0], [X0, Z1], [X1, Z1], [GX0, Z1], [GX1, Z1]], TH = HEIGHT + 2.4;
    corners.forEach(function (p) {
      var t = new T.Mesh(new T.BoxGeometry(2.2, TH, 2.2), new T.MeshLambertMaterial({ color: 0xc9b99a }));
      t.position.set(p[0], TH / 2, p[1]); t.receiveShadow = true; group.add(t);
      var cap = new T.Mesh(new T.BoxGeometry(2.7, 0.4, 2.7), cream); cap.position.set(p[0], TH + 0.2, p[1]); group.add(cap);
      var top = new T.Mesh(new T.ConeGeometry(1.5, 1.2, 4), new T.MeshLambertMaterial({ color: 0x7d1424 }));
      top.rotation.y = Math.PI / 4; top.position.set(p[0], TH + 1, p[1]); group.add(top);
      G.colliders.push({ x0: p[0] - 1.1, x1: p[0] + 1.1, z0: p[1] - 1.1, z1: p[1] + 1.1, h: TH });
    });

    G.sc.add(group);
    window.__campusWall = { group: group, height: HEIGHT };
  } catch (e) { console.warn('Campus wall failed, continuing without it', e) }
})();
