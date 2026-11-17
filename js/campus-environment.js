/* Campus-only visual layer. No colliders, mission positions, NPCs, lights or controls are modified.
   The existing map coordinates remain the single source of truth for all seven levels. */
(function () {
  window.__campusEnvironment = function (cfg) {
    const { T, scene, S, wx, wz } = cfg;
    const tiles = {};
    let seed = 61383;
    const rand = () => (seed = seed * 16807 % 2147483647) / 2147483647;
    const canvas = () => { const c = document.createElement('canvas'); c.width = c.height = 256; return c; };

    function tile(kind) {
      if (tiles[kind]) return tiles[kind];
      const c = canvas(), g = c.getContext('2d'), image = g.createImageData(256, 256), d = image.data;
      const base = {
        grass: [82, 122, 68], meadow: [91, 132, 75], soil: [151, 126, 93],
        asphalt: [70, 75, 77], paving: [132, 58, 42], clay: [153, 111, 79], concrete: [170, 167, 158]
      }[kind];
      for (let y = 0; y < 256; y++) for (let x = 0; x < 256; x++) {
        const i = (y * 256 + x) * 4;
        const patches = Math.sin(x * .055 + Math.sin(y * .035) * 2) * Math.cos(y * .047 - x * .025);
        const grain = (rand() - .5) * (kind === 'asphalt' ? 24 : 38);
        const shade = grain + patches * (kind === 'grass' || kind === 'meadow' ? 13 : 6);
        const dry = (kind === 'grass' || kind === 'meadow') && patches > .53 ? 13 : 0;
        d[i] = Math.max(0, Math.min(255, base[0] + shade + dry));
        d[i + 1] = Math.max(0, Math.min(255, base[1] + shade * .87 - dry * .65));
        d[i + 2] = Math.max(0, Math.min(255, base[2] + shade * .72 - dry * .8));
        d[i + 3] = 255;
      }
      g.putImageData(image, 0, 0);
      if (kind === 'grass' || kind === 'meadow') {
        for (let j = 0; j < 3200; j++) {
          const x = rand() * 256, y = rand() * 256;
          g.strokeStyle = rand() < .28 ? 'rgba(217,191,127,.24)' : 'rgba(34,81,41,.23)';
          g.lineWidth = .5 + rand() * .6;
          g.beginPath(); g.moveTo(x, y); g.lineTo(x + (rand() - .5) * 3, y - 2 - rand() * 4); g.stroke();
        }
      } else if (kind === 'asphalt') {
        for (let j = 0; j < 460; j++) {
          g.fillStyle = rand() < .57 ? 'rgba(207,200,175,.17)' : 'rgba(18,23,26,.23)';
          g.fillRect(rand() * 256, rand() * 256, .5 + rand() * 2, .5 + rand() * 1.6);
        }
        for (let j = 0; j < 5; j++) {
          const x = rand() * 256, y = rand() * 256;
          g.strokeStyle = 'rgba(26,32,34,.12)'; g.lineWidth = .4 + rand() * .5;
          g.beginPath(); g.moveTo(x, y); g.lineTo(x + 5 + rand() * 12, y + 2);
          g.lineTo(x + 8 + rand() * 17, y + 5 + rand() * 8); g.stroke();
        }
      } else if (kind === 'paving') {
        // Running-bond brick pavers with dark grout.
        g.fillStyle = '#6f6a62'; g.fillRect(0, 0, 256, 256);
        const bc = [[132,58,42],[120,50,36],[142,68,48],[110,48,34],[128,62,46]];
        for (let row = 0; row < 32; row++) for (let col = 0; col < 16; col++) {
          const x = col * 16 + (row % 2 ? 8 : 0), y = row * 8, c = bc[Math.floor(rand() * bc.length)], v = (rand() - .5) * 14;
          g.fillStyle = `rgb(${c[0]+v|0},${c[1]+v|0},${c[2]+v|0})`;
          for (const ox of [0, -256]) g.fillRect(x + ox + .8, y + .8, 14.4, 6.4);
        }
      } else {
        for (let j = 0; j < 850; j++) {
          g.fillStyle = rand() < .5 ? 'rgba(67,57,44,.13)' : 'rgba(221,201,159,.23)';
          const r = .3 + rand() * 2;
          g.beginPath(); g.arc(rand() * 256, rand() * 256, r, 0, Math.PI * 2); g.fill();
        }
      }
      const tex = new T.CanvasTexture(c);
      tex.wrapS = tex.wrapT = T.RepeatWrapping;
      tex.anisotropy = cfg.lowQuality ? 4 : 6;
      tiles[kind] = tex;
      return tex;
    }

    function material(kind, width, depth, tileSize) {
      const map = tile(kind).clone();
      map.wrapS = map.wrapT = T.RepeatWrapping;
      const size = tileSize || (kind === 'paving' ? 4 : kind === 'asphalt' ? 7 : 8);
      map.repeat.set(Math.max(.4, width / size), Math.max(.4, depth / size));
      map.needsUpdate = true;
      return new T.MeshLambertMaterial({ map, color: 0xffffff });
    }

    function surface(r, kind, y = .05, height = .06) {
      const w = (r[2] - r[0]) * S, d = (r[3] - r[1]) * S;
      const m = new T.Mesh(new T.BoxGeometry(w, height, d), material(kind, w, d));
      m.position.set(wx((r[0] + r[2]) / 2), y, wz((r[1] + r[3]) / 2));
      m.receiveShadow = true;
      scene.add(m);
      return m;
    }

    function roadDetails() {
      // The broad entry drive keeps its original playable footprint. Paved margins make
      // the actual carriageway read as a plausible two-lane road, without moving the gate.
      // Gate margins are built separately as raised, walkable side paths.
      // These narrower strips carry the same tiles beside the academic roads.
      []
        .forEach(r => surface(r, 'paving', .084, .009));
      // Rounded asphalt aprons remove the rigid right angles at the two main T-junctions.
      // Their radius is shallow, with no changes to the underlying walkable map.
      [[234,332,Math.PI / 2], [252,332,0],
        [106,352,Math.PI], [139,352,Math.PI * 1.5]].forEach(([px, pz, start]) => {
        const m = new T.Mesh(new T.CircleGeometry(2.05, 12, start, Math.PI / 2),
          material('asphalt', 4.1, 4.1));
        m.rotation.x = -Math.PI / 2;
        m.position.set(wx(px), .081, wz(pz));
        m.receiveShadow = true;
        scene.add(m);
      });
      const boxes = new Map();
      function mark(x0, z0, x1, z1, color, y = .099) {
        if (!boxes.has(color)) boxes.set(color, []);
        boxes.get(color).push([wx((x0 + x1) / 2), wz((z0 + z1) / 2), (x1 - x0) * S, (z1 - z0) * S, y]);
      }
      // Broken centre lines from the original scene are kept. Add restrained side
      // markings, the entrance lane and crossings where pedestrians actually circulate.
      [[115.4,356,115.65,427], [129.35,356,129.6,427],
        [235.4,105,235.62,237], [250.38,105,250.6,237],
        [235.4,293,235.62,326], [250.38,293,250.6,326]]
        .forEach(q => mark(...q, 0xdfd9c6));
      [[115,353,130,353.25], [115,427,130,427.25], [236,315,250,315.25]]
        .forEach(q => mark(...q, 0xe9e3d0));
      [[234,191,252,194], [234,317,252,320]].forEach(r => {
        for (let z = r[1], n = 0; z < r[3]; z += .58, n++) {
          if (n % 2 === 0) mark(r[0] + 1.4, z, r[2] - 1.4, Math.min(z + .31, r[3]), 0xe8e4d8, .101);
        }
      });
      [[356, 362], [390, 396], [416, 422]].forEach(([a, b]) => {
        for (let x = 111.2; x + .8 < 134; x += 1.7) mark(x, a + .4, x + .8, b - .4, 0xf4f2e8, .102);
      });
      for (const [color, entries] of boxes) {
        const mesh = new T.InstancedMesh(new T.BoxGeometry(1, .011, 1),
          new T.MeshBasicMaterial({ color }), entries.length), mat = new T.Matrix4();
        entries.forEach(([x, z, w, d, y], i) => {
          mat.makeScale(w, 1, d); mat.setPosition(x, y, z); mesh.setMatrixAt(i, mat);
        });
        mesh.frustumCulled = false;
        scene.add(mesh);
      }
    }

    function gateSidepaths() {
      const road = .08, top = .22, north = wz(351), south = wz(439);
      const start = wz(345), end = wz(445), rampLength = (top - road) / Math.tan(12 * Math.PI / 180);
      const crossings = [[356, 362], [390, 396], [416, 422]].map(([a, b]) => [wz(a), wz(b)]);
      const paths = [[107, 109.8, 1], [135.2, 138, -1]].map(([a, b, dir]) => ({
        x0: wx(a), x1: wx(b), dir, inside: wx(dir === 1 ? b : a)
      }));
      const hedgePaths = paths.slice();
      paths.length = 0;
      const grout = new T.MeshLambertMaterial({ color: 0x9a9b94 });
      const tileMap = tile('paving');
      function slope(x0, x1, z0, z1, height) {
        const corners = [[x0,z0], [x0,z1], [x1,z1], [x1,z0]];
        const y = corners.map(([x,z]) => height(x,z));
        const indices = [0,1,2,0,2,3], p = [], uv = [];
        indices.forEach(i => { const [x,z] = corners[i]; p.push(x,y[i]+.003,z); uv.push(x/4,z/4); });
        const geo = new T.BufferGeometry();
        geo.setAttribute('position',new T.Float32BufferAttribute(p,3));
        geo.setAttribute('uv',new T.Float32BufferAttribute(uv,2));
        geo.computeVertexNormals();
        const tread = new T.Mesh(geo,new T.MeshLambertMaterial({ map: tileMap, side: T.DoubleSide }));
        tread.receiveShadow = true; scene.add(tread);
        // Solid-looking concrete cheeks make the gradual rise legible from the road.
        for (const [a,b] of [[0,1],[1,2],[2,3],[3,0]]) {
          if (Math.max(y[a],y[b]) <= road + .001) continue;
          const face = new T.BufferGeometry(), points = [
            ...corners[a].slice(0,1),road,corners[a][1],
            ...corners[b].slice(0,1),road,corners[b][1],
            ...corners[b].slice(0,1),y[b],corners[b][1],
            ...corners[a].slice(0,1),y[a],corners[a][1]
          ];
          face.setAttribute('position',new T.Float32BufferAttribute([
            ...points.slice(0,3),...points.slice(3,6),...points.slice(6,9),
            ...points.slice(0,3),...points.slice(6,9),...points.slice(9,12)
          ],3)); face.computeVertexNormals();
          const cheek = new T.Mesh(face,new T.MeshLambertMaterial({ color: 0x969791, side: T.DoubleSide }));
          cheek.receiveShadow = true; scene.add(cheek);
        }
      }
      function heightAt(x,z) {
        for (const p of paths) {
          if (x >= p.x0 && x <= p.x1 && z >= start && z <= end) {
            if (z < north) return road + (top-road)*(z-start)/(north-start);
            if (z > south) return road + (top-road)*(end-z)/(end-south);
            return top;
          }
          if (z >= north && z <= south && crossings.some(([a,b]) => z >= a && z <= b)) {
            if (p.dir === 1 && x > p.inside && x <= p.inside+rampLength)
              return road+(top-road)*(p.inside+rampLength-x)/rampLength;
            if (p.dir === -1 && x < p.inside && x >= p.inside-rampLength)
              return road+(top-road)*(x-(p.inside-rampLength))/rampLength;
          }
        }
        return null;
      }
      const curbs = [[], []], blockSize = 2.35;
      paths.forEach((p,pi) => {
        const w = p.x1-p.x0, d = south-north;
        const slab = new T.Mesh(new T.BoxGeometry(w,top,d),[
          grout,grout,material('paving',w,d),grout,grout,grout
        ]);
        slab.position.set((p.x0+p.x1)/2,top/2,(north+south)/2);
        slab.receiveShadow = true; scene.add(slab);
        slope(p.x0,p.x1,start,north,(x,z) => heightAt(x,z));
        slope(p.x0,p.x1,south,end,(x,z) => heightAt(x,z));
        crossings.forEach(([a,b]) => slope(
          p.dir === 1 ? p.inside : p.inside-rampLength,
          p.dir === 1 ? p.inside+rampLength : p.inside,
          a,b,(x,z) => heightAt(x,z)
        ));
        for (const [edge, inner] of [[p.x0,p.dir === -1],[p.x1,p.dir === 1]]) {
          for (let z=north,i=0;z+blockSize<=south;z+=blockSize,i++) {
            const mid=z+blockSize/2;
            if (inner && crossings.some(([a,b]) => mid >= a-.2 && mid <= b+.2)) continue;
            const color = (i+pi)%2;
            curbs[color].push([edge,mid,blockSize-.055]);
          }
        }
      });
      [0xf3c32e,0xfaf9ef].forEach((color,ci) => {
        const blocks = curbs[ci], mesh = new T.InstancedMesh(
          new T.BoxGeometry(.14,.1,1),new T.MeshLambertMaterial({ color }),blocks.length
        ), matrix = new T.Matrix4();
        blocks.forEach(([x,z,d],i) => {matrix.makeScale(1,1,d);matrix.setPosition(x,top+.05,z);mesh.setMatrixAt(i,matrix)});
        mesh.frustumCulled = false; mesh.receiveShadow = true; scene.add(mesh);
      });
      const hedge = [[], []];
      hedgePaths.forEach((p, pi) => {
        const hx = p.dir === 1 ? p.x0 - .6 : p.x1 + .6, len = 1.5;
        for (let z = north + .4, i = 0; z + len <= south - .4; z += len, i++) {
          if (crossings.some(([a, b]) => z + len > a - 1.2 && z < b + 1.2)) continue;
          hedge[(i + pi) % 2].push([hx, z + len / 2, len - .05, .5 + ((i * 7 + pi) % 3) * .06]);
        }
      });
      [0x2f6e35, 0x3d7f3f].forEach((color, ci) => {
        const list = hedge[ci], mesh = new T.InstancedMesh(
          new T.BoxGeometry(.7, 1, 1), new T.MeshLambertMaterial({ color }), list.length), m = new T.Matrix4();
        list.forEach(([x, z, d, h], i) => { m.makeScale(1, h, d); m.setPosition(x, h / 2, z); mesh.setMatrixAt(i, m); });
        mesh.frustumCulled = false; mesh.receiveShadow = true; mesh.castShadow = !cfg.lowQuality; scene.add(mesh);
      });
      return { heightAt, paths, crossings, top, road, start, end, rampLength };
    }

    const parts = new Map(), boxGeom = new T.BoxGeometry(1, 1, 1);
    function detailBlock({ x, z, rotation = 0, depth, length, height, name, sign = false, accent = 0xa77463 }) {
      const cs = Math.cos(rotation), sn = Math.sin(rotation);
      function piece(kind, lx, y, lz, w, h, d) {
        const color = ({ stone: 0xd9d4c8, sill: 0xb8b3a6, shadow: 0x736f6a,
          metal: 0x637680, glass: 0x527080, roof: 0xaca99e, accent })[kind];
        if (!parts.has(color)) parts.set(color, []);
        parts.get(color).push([x + lx * cs + lz * sn, y, z - lx * sn + lz * cs, w, h, d, rotation]);
      }
      const front = depth / 2 + .09, rear = -depth / 2 - .09;
      const floors = Math.max(2, Math.min(4, Math.round(height / 3.6)));
      const bays = Math.max(2, Math.floor((length - .6) / 3.15));
      const step = length / bays;
      // Flat concrete roof, a small parapet and actual cast shadows break the toy-box silhouette.
      piece('roof', 0, height + .09, 0, depth + .36, .2, length + .36);
      [front, rear].forEach(px => piece('stone', px, height + .45, 0, .22, .75, length + .55));
      [-length / 2, length / 2].forEach(pz => piece('stone', 0, height + .45, pz, depth + .5, .75, .22));
      for (let f = 1; f < floors; f++) {
        const y = Math.min(height - .55, f * height / floors);
        piece(f === 1 ? 'accent' : 'sill', front, y, 0, .34, .15, length + .26);
      }
      for (let j = 0; j <= bays; j++) {
        const bz = -length / 2 + j * step;
        piece('stone', front, height / 2, bz, .3, height - .65, .2);
      }
      for (let f = 0; f < floors; f++) {
        const y = Math.min(height - 1.1, (f + .52) * height / floors);
        for (let b = 0; b < bays; b++) {
          const bz = -length / 2 + (b + .5) * step;
          if (f === 0 && Math.abs(bz) < 2.1) continue; // preserve the model's door
          const span = Math.min(1.95, step - .65), hh = Math.min(1.45, height / floors - .95);
          if (span <= .4 || hh <= .5) continue;
          [front + .10, rear - .10].forEach((px, face) => {
            const outside = px + (face ? -.06 : .06);
            piece('shadow', outside, y, bz, .12, hh + .16, span + .16);
            piece('glass', outside + (face ? -.08 : .08), y, bz, .09, hh, span);
            piece('metal', outside + (face ? -.14 : .14), y, bz, .055, hh, .045);
            piece('sill', px, y - hh / 2 - .09, bz, .39, .105, span + .27);
            if (f > 0) piece('stone', px, y + hh / 2 + .12, bz, .35, .1, span + .25);
          });
        }
      }
      // Roof drainage reads as part of the building, not as a separate gameplay prop.
      piece('metal', front + .05, height * .42, length / 2 - .22, .11, height * .84, .11);
      if (!sign) return;
      const c = document.createElement('canvas'); c.width = 512; c.height = 96;
      const g = c.getContext('2d'); g.fillStyle = '#264b58'; g.fillRect(0, 0, 512, 96);
      g.fillStyle = '#d0b37b'; g.fillRect(0, 0, 13, 96);
      g.fillStyle = '#e7e2d4'; g.font = 'bold 22px sans-serif'; g.fillText('ANITS  /  ACADEMIC CAMPUS', 27, 29);
      let size = 43; do { g.font = `bold ${size--}px sans-serif`; } while (g.measureText(name.toUpperCase()).width > 460 && size > 23);
      g.fillText(name.toUpperCase(), 27, 75);
      const texture = new T.CanvasTexture(c);
      const plate = new T.Mesh(new T.PlaneGeometry(Math.min(11, length * .7), 1.55),
        new T.MeshBasicMaterial({ map: texture, side: T.DoubleSide }));
      plate.position.set(x + (front + .3) * cs, Math.min(height - .55, 3.95), z - (front + .3) * sn);
      plate.rotation.y = rotation + Math.PI / 2;
      scene.add(plate);
    }

    function flushBuildings() {
      const matrix = new T.Matrix4(), q = new T.Quaternion(), yaxis = new T.Vector3(0, 1, 0);
      for (const [color, entries] of parts) {
        const mesh = new T.InstancedMesh(boxGeom, new T.MeshLambertMaterial({ color }), entries.length);
        entries.forEach(([x, y, z, w, h, d, rot], i) => {
          q.setFromAxisAngle(yaxis, rot);
          matrix.compose(new T.Vector3(x, y, z), q, new T.Vector3(w, h, d));
          mesh.setMatrixAt(i, matrix);
        });
        mesh.castShadow = !cfg.lowQuality;
        mesh.receiveShadow = true;
        // Bounds depend on the whole set of buildings rather than the unit cube.
        mesh.frustumCulled = false;
        scene.add(mesh);
      }
      parts.clear();
    }
    return { material, surface, roadDetails, gateSidepaths, detailBlock, flushBuildings };
  };
})();