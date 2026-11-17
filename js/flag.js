
/*
 * NCC Grounds flag for the ANITS campus game.
 * Original procedural code (no third-party assets). Rendering library: Three.js r128 (MIT) already bundled in the game.
 * Flag: saffron / white / green, navy 24-spoke Ashoka Chakra (ratio 3:2, chakra diameter = 3/4 of the white band).
 * Tiers: 'ready' (vertex-shader cloth wave) -> 'fallback' (2D textured plane with light sway) -> 'error' (nothing, game continues).
 */
(function (root) {
  'use strict';

  var LOG = '[NCCFlag]';

  function isCoarse() {
    try { return matchMedia('(pointer:coarse)').matches; } catch (e) { return false; }
  }
  function isLowEnd() {
    var nav = root.navigator || {};
    return isCoarse() || (nav.hardwareConcurrency || 8) <= 4 || (nav.deviceMemory || 8) <= 2;
  }

  /* ---------- texture ---------- */
  function drawFlag(canvas) {
    var c = canvas.getContext('2d'), W = canvas.width, H = canvas.height;
    c.save();
    c.scale(W / 300, H / 200); // logical 300x200 (3:2); non-uniform scale is undone by the 3:2 plane, so circles stay round
    c.fillStyle = '#FF9933'; c.fillRect(0, 0, 300, 200 / 3 + 0.5);
    c.fillStyle = '#FFFFFF'; c.fillRect(0, 200 / 3, 300, 200 / 3 + 0.5);
    c.fillStyle = '#138808'; c.fillRect(0, 400 / 3, 300, 200 / 3);
    var cx = 150, cy = 100, R = 25;
    c.fillStyle = '#000080'; c.strokeStyle = '#000080';
    c.lineWidth = 2.4; c.beginPath(); c.arc(cx, cy, R - 1.2, 0, Math.PI * 2); c.stroke();
    c.beginPath(); c.arc(cx, cy, 3.6, 0, Math.PI * 2); c.fill();
    for (var i = 0; i < 24; i++) {
      var a = i * Math.PI / 12, ca = Math.cos(a), sa = Math.sin(a), px = -sa, py = ca;
      var r0 = 3, r1 = R - 2.2, w0 = 0.35, w1 = 0.9;
      c.beginPath();
      c.moveTo(cx + ca * r0 + px * w0, cy + sa * r0 + py * w0);
      c.lineTo(cx + ca * r1 + px * w1, cy + sa * r1 + py * w1);
      c.lineTo(cx + ca * r1 - px * w1, cy + sa * r1 - py * w1);
      c.lineTo(cx + ca * r0 - px * w0, cy + sa * r0 - py * w0);
      c.closePath(); c.fill();
      var b = a + Math.PI / 24;
      c.beginPath(); c.arc(cx + Math.cos(b) * (R - 4.2), cy + Math.sin(b) * (R - 4.2), 0.85, 0, Math.PI * 2); c.fill();
    }
    c.restore();
  }

  function verifyTexture(canvas) {
    var W = canvas.width, H = canvas.height, d = canvas.getContext('2d').getImageData(0, 0, W, H).data;
    var px = function (lx, ly) { // logical coords -> rgb
      var x = Math.min(W - 1, Math.max(0, Math.round(lx / 300 * W))), y = Math.min(H - 1, Math.max(0, Math.round(ly / 200 * H))), i = (y * W + x) * 4;
      return [d[i], d[i + 1], d[i + 2]];
    };
    var top = px(20, 20), mid = px(20, 100), bot = px(20, 180);
    var saffron = top[0] > 220 && top[1] > 130 && top[1] < 170 && top[2] < 80;
    var white = mid[0] > 240 && mid[1] > 240 && mid[2] > 240;
    var green = bot[0] < 40 && bot[1] > 100 && bot[2] < 40;
    var runs = 0, prev = false, N = 720, first = false;
    for (var k = 0; k < N; k++) {
      var an = k / N * Math.PI * 2, p = px(150 + Math.cos(an) * 15, 100 + Math.sin(an) * 15);
      var dark = p[0] < 120 && p[1] < 120 && p[2] > 60 && p[2] < 200;
      if (k === 0) first = dark; else if (dark && !prev) runs++;
      prev = dark;
    }
    if (first && prev) { /* run wrapped around the seam, counted once already */ } else if (first) runs++;
    var hub = px(150, 100), centreNavy = hub[0] < 40 && hub[1] < 40 && hub[2] > 100;
    var ok = saffron && white && green && runs === 24 && centreNavy;
    return { ok: ok, saffronTop: saffron, whiteMid: white, greenBottom: green, spokes: runs, hubNavy: centreNavy };
  }

  /* ---------- shaders ---------- */
  var WAVE_GLSL = [
    'uniform float uTime; uniform float uAmp; uniform vec2 uSize;',
    'void flagWave(vec2 p, out float z, out vec3 n){',
    '  float u = clamp(p.x / uSize.x, 0.0, 1.0);',
    '  float ramp = u * (0.6 + 0.4 * u);',
    '  float dramp = (0.6 + 0.8 * u) / uSize.x;',
    '  float a1 = p.x * 2.2 - uTime * 2.4 + p.y * 0.6;',
    '  float a2 = p.x * 4.6 - uTime * 3.4 - p.y * 1.1;',
    '  float a3 = p.y * 2.0 + uTime * 1.5;',
    '  float S = sin(a1) + 0.45 * sin(a2) + 0.2 * sin(a3);',
    '  float dSx = 2.2 * cos(a1) + 0.45 * 4.6 * cos(a2);',
    '  float dSy = 0.6 * cos(a1) - 0.45 * 1.1 * cos(a2) + 0.4 * cos(a3);',
    '  z = uAmp * ramp * S;',
    '  n = normalize(vec3(-uAmp * (dramp * S + ramp * dSx), -uAmp * ramp * dSy, 1.0));',
    '}'
  ].join('\n');

  var VERT = [
    WAVE_GLSL,
    'varying vec2 vUv; varying vec3 vN;',
    '#include <fog_pars_vertex>',
    'void main(){',
    '  float z; vec3 n; flagWave(position.xy, z, n);',
    '  vUv = uv; vN = normalize(mat3(modelMatrix) * n);',
    '  vec4 mvPosition = modelViewMatrix * vec4(position.xy, z, 1.0);',
    '  gl_Position = projectionMatrix * mvPosition;',
    '  #include <fog_vertex>',
    '}'
  ].join('\n');

  var FRAG = [
    'uniform sampler2D uMap; uniform vec3 uSunDir; uniform vec3 uSunCol; uniform vec3 uSky; uniform vec3 uGround;',
    'varying vec2 vUv; varying vec3 vN;',
    '#include <fog_pars_fragment>',
    'void main(){',
    '  vec3 n = normalize(vN); if(!gl_FrontFacing) n = -n;',
    '  float d = dot(n, uSunDir);',
    '  vec3 amb = mix(uGround, uSky, n.y * 0.5 + 0.5);',
    '  vec3 lit = amb + uSunCol * (max(d, 0.0) + 0.55 * max(-d, 0.0));',
    '  gl_FragColor = vec4(texture2D(uMap, vUv).rgb * lit, 1.0);',
    '  #include <fog_fragment>',
    '}'
  ].join('\n');

  /* ---------- controller ---------- */
  function create(o) {
    var T = o.THREE, scene = o.scene, ren = o.renderer, sun = o.sun;
    var cfg = {
      x: o.x, z: o.z, poleH: o.poleH || 14, flagW: o.flagW || 4.2, flagH: o.flagH || 2.8,
      enter: o.enter || 85, exit: o.exit || 125, yaw: o.yaw === undefined ? -Math.PI / 2 : o.yaw,
      force: o.force || '' // '', 'fallback' (skip shader), 'fail' (simulate load failure)
    };
    var low = isLowEnd();
    var st = { state: 'idle', reason: '', mounts: 0, unmounts: 0, report: null, frames: 0 };
    var res = null, token = 0, time = 0, slowFrames = 0, lastT = 0, disposed = false, hemi = null;
    var U = {
      uTime: { value: 0 }, uAmp: { value: 0.17 }, uSize: { value: new T.Vector2(cfg.flagW, cfg.flagH) },
      uMap: { value: null }, uSunDir: { value: new T.Vector3(0.3, 0.8, 0.5) }, uSunCol: { value: new T.Color(1, 1, 1) },
      uSky: { value: new T.Color(1, 1, 1) }, uGround: { value: new T.Color(0.4, 0.5, 0.35) }
    };

    if (o.onCollider) o.onCollider(cfg.x, cfg.z, 1.1, 1.1, cfg.poleH);

    function track(list, obj) { list.push(obj); return obj; }

    function buildPole(r) {
      var grey = track(r.mats, new T.MeshLambertMaterial({ color: 0xdddddd }));
      var gold = track(r.mats, new T.MeshLambertMaterial({ color: 0xd4a017 }));
      var stone = track(r.mats, new T.MeshLambertMaterial({ color: 0x9a9a94 }));
      var pole = track(r.geos, new T.CylinderGeometry(0.08, 0.14, cfg.poleH, 10));
      var fin = track(r.geos, new T.SphereGeometry(0.2, 10, 8));
      var base = track(r.geos, new T.CylinderGeometry(0.55, 0.7, 0.5, 12));
      var m1 = new T.Mesh(pole, grey); m1.position.set(cfg.x, cfg.poleH / 2 + 0.25, cfg.z);
      var m2 = new T.Mesh(fin, gold); m2.position.set(cfg.x, cfg.poleH + 0.4, cfg.z);
      var m3 = new T.Mesh(base, stone); m3.position.set(cfg.x, 0.25, cfg.z);
      [m1, m2, m3].forEach(function (m) { m.castShadow = true; m.receiveShadow = true; r.root.add(m); });
    }

    function buildTexture(r) {
      var w = low ? 512 : 1024, cv = document.createElement('canvas');
      cv.width = w; cv.height = w / 2;
      drawFlag(cv);
      st.report = verifyTexture(cv);
      if (!st.report.ok) throw new Error('flag texture check failed ' + JSON.stringify(st.report));
      var tex = track(r.texs, new T.CanvasTexture(cv));
      tex.anisotropy = Math.min(low ? 2 : 4, ren.capabilities.getMaxAnisotropy());
      r.texBytes = w * (w / 2) * 4 * 1.33;
      return tex;
    }

    function addShaderFlag(r, tex) {
      var seg = low ? [16, 10] : [28, 18];
      var geo = track(r.geos, new T.PlaneGeometry(cfg.flagW, cfg.flagH, seg[0], seg[1]));
      geo.translate(cfg.flagW / 2, 0, 0);
      U.uMap.value = tex;
      var mat = track(r.mats, new T.ShaderMaterial({
        uniforms: T.UniformsUtils.merge([T.UniformsLib.fog, U]), vertexShader: VERT, fragmentShader: FRAG,
        side: T.DoubleSide, fog: true
      }));
      Object.keys(U).forEach(function (k) { mat.uniforms[k] = U[k]; });
      var depth = track(r.mats, new T.MeshDepthMaterial({ depthPacking: T.RGBADepthPacking, side: T.DoubleSide }));
      depth.onBeforeCompile = function (sh) {
        sh.uniforms.uTime = U.uTime; sh.uniforms.uAmp = U.uAmp; sh.uniforms.uSize = U.uSize;
        sh.vertexShader = WAVE_GLSL + '\n' + sh.vertexShader.replace('#include <begin_vertex>',
          'float fz; vec3 fn; flagWave(position.xy, fz, fn); vec3 transformed = vec3(position.xy, fz);');
      };
      var mesh = new T.Mesh(geo, mat);
      mesh.customDepthMaterial = depth; mesh.castShadow = true; mesh.receiveShadow = false;
      mesh.position.set(0.1, -cfg.flagH / 2 - 0.25, 0);
      r.flagMat = mat; r.flagMesh = mesh; r.mode = 'shader';
      r.flagGroup.add(mesh);
      r.tris = seg[0] * seg[1] * 2;
    }

    function addPlainFlag(r, tex) {
      var geo = track(r.geos, new T.PlaneGeometry(cfg.flagW, cfg.flagH));
      geo.translate(cfg.flagW / 2, 0, 0);
      var mat = track(r.mats, new T.MeshBasicMaterial({ map: tex, side: T.DoubleSide }));
      var mesh = new T.Mesh(geo, mat);
      mesh.position.set(0.1, -cfg.flagH / 2 - 0.25, 0);
      r.flagMesh = mesh; r.mode = 'plain'; r.tris = 2;
      r.flagGroup.add(mesh);
    }

    function build(mode) {
      var r = { root: new T.Group(), flagGroup: new T.Group(), geos: [], mats: [], texs: [], texBytes: 0, tris: 0, mode: '' };
      r.root.name = 'NCCFlag';
      try {
        if (cfg.force === 'fail') throw new Error('forced failure');
        buildPole(r);
        r.flagGroup.position.set(cfg.x, cfg.poleH, cfg.z);
        r.flagGroup.rotation.y = cfg.yaw;
        r.root.add(r.flagGroup);
        var tex = buildTexture(r);
        if (mode === 'shader') addShaderFlag(r, tex); else addPlainFlag(r, tex);
        scene.add(r.root);
        return r;
      } catch (e) { release(r); throw e; }
    }

    function release(r) {
      if (!r) return;
      if (r.root && r.root.parent) r.root.parent.remove(r.root);
      r.geos.forEach(function (g) { g.dispose(); });
      r.mats.forEach(function (m) { m.dispose(); });
      r.texs.forEach(function (t) { t.dispose(); });
      r.geos.length = r.mats.length = r.texs.length = 0;
    }

    function idle() {
      return new Promise(function (ok) {
        if (root.requestIdleCallback) root.requestIdleCallback(function () { ok(); }, { timeout: 400 }); else setTimeout(ok, 50);
      });
    }

    function mount() {
      if (disposed || st.state !== 'idle') return Promise.resolve(st.state);
      st.state = 'loading';
      var my = ++token;
      return idle().then(function () {
        if (my !== token || disposed) return st.state;
        slowFrames = 0; st.frames = 0; lastT = 0;
        try {
          if (cfg.force === 'fallback') throw new Error('forced fallback');
          res = build('shader'); st.state = 'ready'; st.reason = '';
        } catch (e1) {
          console.warn(LOG, 'shader flag unavailable, using 2D fallback:', e1.message);
          try { res = build('plain'); st.state = 'fallback'; st.reason = e1.message; }
          catch (e2) { console.warn(LOG, 'fallback failed, flag disabled:', e2.message); res = null; st.state = 'error'; st.reason = e2.message; }
        }
        if (res) st.mounts++;
        return st.state;
      }).catch(function (e) { console.warn(LOG, e); st.state = 'error'; st.reason = String(e); return st.state; });
    }

    function unmount() {
      token++;
      if (res) { release(res); res = null; st.unmounts++; }
      if (st.state !== 'error') st.state = 'idle';
    }

    function degrade(why) {
      if (!res || res.mode !== 'shader') return;
      console.warn(LOG, 'switching to 2D fallback:', why);
      release(res); res = null;
      try { res = build('plain'); st.state = 'fallback'; st.reason = why; if (o.onSlow && /slow/.test(why)) o.onSlow(); }
      catch (e) { st.state = 'error'; st.reason = String(e); }
    }

    function syncLights() {
      if (sun) {
        var sx = sun.position.x - (sun.target ? sun.target.position.x : 0), sy = sun.position.y - (sun.target ? sun.target.position.y : 0), sz = sun.position.z - (sun.target ? sun.target.position.z : 0);
        U.uSunDir.value.set(sx, sy, sz).normalize();
        U.uSunCol.value.copy(sun.color).multiplyScalar(sun.intensity);
      }
      if (!hemi) scene.traverse(function (ob) { if (ob.isHemisphereLight && !hemi) hemi = ob; });
      if (hemi) {
        U.uSky.value.copy(hemi.color).multiplyScalar(hemi.intensity);
        U.uGround.value.copy(hemi.groundColor).multiplyScalar(hemi.intensity);
      }
    }

    function update(dt) {
      if (disposed) return;
      try {
        var p = o.getPlayer && o.getPlayer();
        if (p) {
          var d = Math.hypot(p.x - cfg.x, p.z - cfg.z);
          if (st.state === 'idle' && d < cfg.enter) mount();
          else if ((st.state === 'ready' || st.state === 'fallback') && d > cfg.exit) unmount();
        }
        if (!res) return;
        time += dt; st.frames++;
        var wind = cfg.yaw + 0.07 * Math.sin(time * 0.23) + 0.03 * Math.sin(time * 0.61);
        if (res.mode === 'shader') {
          U.uTime.value = time; res.flagGroup.rotation.y = wind; syncLights();
          if (st.frames % 30 === 3) {
            var pr = ren.properties.get(res.flagMat), prog = pr && pr.currentProgram;
            if (prog && prog.diagnostics && prog.diagnostics.runnable === false) return degrade('shader compile error');
          }
        } else {
          res.flagGroup.rotation.y = wind + 0.16 * Math.sin(time * 0.9);
          res.flagMesh.rotation.z = 0.05 * Math.sin(time * 1.3);
        }
        var now = performance.now();
        if (lastT) {
          var raw = now - lastT;
          if (raw < 250) slowFrames = raw > 45 ? slowFrames + 1 : Math.max(0, slowFrames - 2);
        }
        lastT = now;
        if (slowFrames > 90 && res.mode === 'shader') degrade('slow device (frame time > 45ms)');
      } catch (e) {
        console.warn(LOG, 'update error:', e);
        if (res && res.mode === 'shader') degrade('runtime error'); else { release(res); res = null; st.state = 'error'; }
      }
    }

    function dispose() { disposed = true; unmount(); }
    root.addEventListener('pagehide', dispose);

    function stats() {
      return { state: st.state, reason: st.reason, mode: res ? res.mode : null, tris: res ? res.tris : 0, textureMB: res ? +(res.texBytes / 1048576).toFixed(2) : 0,
        mounts: st.mounts, unmounts: st.unmounts, texture: st.report, pixelLow: low };
    }
    return { update: update, mount: mount, unmount: unmount, dispose: dispose, stats: stats, get state() { return st.state; }, get object() { return res && res.root; } };
  }

  root.NCCFlag = { create: create, _drawFlag: drawFlag, _verifyTexture: verifyTexture };
})(window);

