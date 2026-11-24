/* Security-gate scene: guard whistle (generated sound) + a dog (assets/models/dog/Dog_model.fbx) that roams and sits around the guard.
   The dog FBX has no skeleton and no animation clips, so the mesh is split into body / head / tail / 4 legs and animated by script.
   Hooks: window.__guardAnim.whistle (guard arm, game.js) and window.__gateScene.whistle(cb) (called from gateCheck in game.js). */
(function () {
  var T = window.THREE;
  if (!T) return;

  /* ---------- whistle sound: synthesised, no audio file ---------- */
  var actx = null;
  function ctx() {
    if (actx) return actx;
    var AC = window.AudioContext || window.webkitAudioContext;
    if (AC) { try { actx = new AC() } catch (e) {} }
    return actx;
  }
  function blast(c, t0, dur, f0, f1) {
    var osc = c.createOscillator(), gain = c.createGain(), trem = c.createGain(), lfo = c.createOscillator(), lfoAmt = c.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(f0, t0);
    osc.frequency.linearRampToValueAtTime(f1, t0 + dur * 0.35);
    osc.frequency.linearRampToValueAtTime(f0 * 1.02, t0 + dur);
    lfo.type = 'sine'; lfo.frequency.value = 38; lfoAmt.gain.value = 0.35;
    trem.gain.value = 0.65;
    lfo.connect(lfoAmt); lfoAmt.connect(trem.gain);
    gain.gain.setValueAtTime(0.0001, t0);
    gain.gain.exponentialRampToValueAtTime(0.42, t0 + 0.03);
    gain.gain.setValueAtTime(0.42, t0 + dur - 0.06);
    gain.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
    osc.connect(trem); trem.connect(gain);
    var n = c.createBufferSource(), len = Math.floor(c.sampleRate * dur), buf = c.createBuffer(1, len, c.sampleRate), d = buf.getChannelData(0);
    for (var i = 0; i < len; i++) d[i] = Math.random() * 2 - 1;
    n.buffer = buf;
    var bp = c.createBiquadFilter(); bp.type = 'bandpass'; bp.frequency.value = 3600; bp.Q.value = 6;
    var ng = c.createGain(); ng.gain.setValueAtTime(0.0001, t0); ng.gain.exponentialRampToValueAtTime(0.07, t0 + 0.03); ng.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
    n.connect(bp); bp.connect(ng); ng.connect(c.destination);
    gain.connect(c.destination);
    osc.start(t0); lfo.start(t0); n.start(t0);
    osc.stop(t0 + dur + 0.05); lfo.stop(t0 + dur + 0.05); n.stop(t0 + dur + 0.05);
  }
  function playWhistle() {
    var c = ctx(); if (!c) return;
    if (c.state === 'suspended' && c.resume) c.resume();
    var t = c.currentTime + 0.02;
    blast(c, t, 0.28, 2650, 2950);
    blast(c, t + 0.4, 0.85, 2700, 3150);
  }

  function bark(c, t0, f0, dur, vol) {
    var osc = c.createOscillator(), g = c.createGain(), f1 = c.createBiquadFilter(), f2 = c.createBiquadFilter();
    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(f0, t0);
    osc.frequency.exponentialRampToValueAtTime(f0 * 0.55, t0 + dur);
    f1.type = 'bandpass'; f1.frequency.value = 700; f1.Q.value = 2.5;
    f2.type = 'lowpass'; f2.frequency.value = 2200;
    g.gain.setValueAtTime(0.0001, t0);
    g.gain.exponentialRampToValueAtTime(vol, t0 + 0.012);
    g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
    osc.connect(f1); f1.connect(f2); f2.connect(g); g.connect(c.destination);
    var n = c.createBufferSource(), len = Math.floor(c.sampleRate * dur), buf = c.createBuffer(1, len, c.sampleRate), d = buf.getChannelData(0);
    for (var i = 0; i < len; i++) d[i] = Math.random() * 2 - 1;
    n.buffer = buf;
    var nb = c.createBiquadFilter(); nb.type = 'bandpass'; nb.frequency.value = 1200; nb.Q.value = 1.2;
    var ng = c.createGain(); ng.gain.setValueAtTime(0.0001, t0); ng.gain.exponentialRampToValueAtTime(vol * 0.5, t0 + 0.01); ng.gain.exponentialRampToValueAtTime(0.0001, t0 + dur * 0.8);
    n.connect(nb); nb.connect(ng); ng.connect(c.destination);
    osc.start(t0); n.start(t0); osc.stop(t0 + dur + 0.05); n.stop(t0 + dur + 0.05);
  }
  function playBark(times) {
    var c = ctx(); if (!c) return;
    if (c.state === 'suspended' && c.resume) c.resume();
    var t = c.currentTime + 0.02;
    for (var i = 0; i < (times || 2); i++) bark(c, t + i * 0.32, 520 - i * 25, 0.16, 0.5);
  }
  function playYip() {
    var c = ctx(); if (!c) return;
    if (c.state === 'suspended' && c.resume) c.resume();
    bark(c, c.currentTime + 0.02, 820, 0.12, 0.28);
  }

  /* ---------- whistle caption ---------- */
  var css = document.createElement('style');
  css.textContent =
    '#gate-whistle{position:fixed;left:50%;top:26%;transform:translateX(-50%) scale(.6);z-index:48;display:none;pointer-events:none;color:#ffe27a;font:900 clamp(26px,5.5vw,54px)/1 Figtree,system-ui,sans-serif;letter-spacing:.12em;text-shadow:0 3px 0 #7a4a00,0 0 22px rgba(255,200,60,.8);opacity:0}' +
    '#gate-whistle.on{display:block;animation:gwPop 1.6s ease-out forwards}' +
    '@keyframes gwPop{0%{opacity:0;transform:translateX(-50%) scale(.5) rotate(-4deg)}12%{opacity:1;transform:translateX(-50%) scale(1.15) rotate(2deg)}25%{transform:translateX(-50%) scale(1) rotate(-1deg)}80%{opacity:1}100%{opacity:0;transform:translateX(-50%) scale(1.05)}}';
  css.textContent +=
    '#dog-pet-btn{position:fixed;left:50%;bottom:150px;transform:translateX(-50%);z-index:46;display:none;padding:12px 26px;border-radius:999px;border:0;background:#ffb347;color:#3a2000;font:800 15px Figtree,system-ui,sans-serif;letter-spacing:.08em;cursor:pointer;box-shadow:0 0 18px rgba(255,179,71,.55);touch-action:manipulation}' +
    'body.touch #dog-pet-btn{bottom:110px}' +
    '.dog-heart{position:fixed;z-index:48;pointer-events:none;font:900 26px/1 Figtree,system-ui,sans-serif;color:#ff5c7a;text-shadow:0 2px 6px rgba(0,0,0,.4);animation:dogHeart 1.6s ease-out forwards}' +
    '@keyframes dogHeart{0%{opacity:0;transform:translateY(0) scale(.5)}15%{opacity:1}100%{opacity:0;transform:translateY(-90px) scale(1.2)}}';
  document.head.appendChild(css);
  var cap = document.createElement('div');
  cap.id = 'gate-whistle'; cap.setAttribute('data-testid', 'gate-whistle-caption'); cap.textContent = 'PHWEEEET!';
  document.body.appendChild(cap);
  var petBtn = document.createElement('button');
  petBtn.id = 'dog-pet-btn'; petBtn.setAttribute('data-testid', 'pet-dog-btn'); petBtn.textContent = window.__mobile ? 'PET DOG' : 'PET DOG (E)';
  document.body.appendChild(petBtn);
  petBtn.addEventListener('pointerdown', function (e) { e.stopPropagation() });
  petBtn.addEventListener('click', function (e) { e.stopPropagation(); petDog() });
  var petHint = document.createElement('div');
  petHint.setAttribute('data-testid', 'pet-dog-prompt');
  petHint.textContent = 'Press E to pet the dog';
  petHint.style.cssText = 'position:fixed;left:50%;bottom:210px;transform:translateX(-50%);z-index:46;display:none;padding:8px 18px;border-radius:12px;background:rgba(8,14,26,.9);border:1.5px solid #ffb347;color:#fff;font:700 14px Figtree,system-ui,sans-serif;pointer-events:none';
  document.body.appendChild(petHint);
  function hearts() {
    for (var i = 0; i < 5; i++) (function (i) {
      setTimeout(function () {
        var h = document.createElement('div'); h.className = 'dog-heart'; h.textContent = '\u2665';
        h.style.left = (46 + Math.random() * 8) + '%'; h.style.top = (46 + Math.random() * 6) + '%';
        h.style.fontSize = (20 + Math.random() * 16) + 'px';
        document.body.appendChild(h); setTimeout(function () { h.remove() }, 1700);
      }, i * 180);
    })(i);
  }

  /* ---------- dog rig ---------- */
  var P0 = new T.Vector3(0, 3.4, -3.2);
  var PIV = {
    head: [0, 4.5, 2.0], tail: [0, 4.3, -4.0],
    fl: [0.5, 3.3, 1.3], fr: [-0.5, 3.3, 1.3], rl: [0.5, 3.3, -3.2], rr: [-0.5, 3.3, -3.2]
  };

  function classify(cx, cy, cz) {
    if (cy > 4.3 && cz < -3.9) return 'tail';
    if (cy > 4.6 && cz > 1.8) return 'head';
    if (cy < 3.3) return (cz > -1 ? 'f' : 'r') + (cx > 0 ? 'l' : 'r');
    return 'body';
  }

  function buildRig(src, map) {
    var geo = src.geometry, pos = geo.attributes.position.array, nor = geo.attributes.normal ? geo.attributes.normal.array : null, uv = geo.attributes.uv ? geo.attributes.uv.array : null;
    var B = {};
    function bucket(k) { return B[k] || (B[k] = { p: [], n: [], u: [] }) }
    for (var i = 0; i < pos.length; i += 9) {
      var cx = (pos[i] + pos[i + 3] + pos[i + 6]) / 3, cy = (pos[i + 1] + pos[i + 4] + pos[i + 7]) / 3, cz = (pos[i + 2] + pos[i + 5] + pos[i + 8]) / 3;
      var b = bucket(classify(cx, cy, cz));
      for (var v = 0; v < 3; v++) {
        var o = i + v * 3, uo = (i / 3 + v) * 2;
        b.p.push(pos[o], pos[o + 1], pos[o + 2]);
        if (nor) b.n.push(nor[o], nor[o + 1], nor[o + 2]);
        if (uv) b.u.push(uv[uo], uv[uo + 1]);
      }
    }
    var mat = new T.MeshLambertMaterial({ map: map, color: 0xffffff });
    var root = new T.Group(), pitch = new T.Group();
    pitch.position.copy(P0); root.add(pitch);
    var parts = {};
    function mk(k, piv) {
      var b = B[k]; if (!b) return null;
      var g = new T.BufferGeometry();
      var org = piv ? new T.Vector3(piv[0], piv[1], piv[2]) : new T.Vector3();
      var pp = new Float32Array(b.p.length);
      for (var j = 0; j < pp.length; j += 3) { pp[j] = b.p[j] - org.x; pp[j + 1] = b.p[j + 1] - org.y; pp[j + 2] = b.p[j + 2] - org.z }
      g.setAttribute('position', new T.BufferAttribute(pp, 3));
      if (b.n.length) g.setAttribute('normal', new T.BufferAttribute(new Float32Array(b.n), 3)); else g.computeVertexNormals();
      if (b.u.length) g.setAttribute('uv', new T.BufferAttribute(new Float32Array(b.u), 2));
      var m = new T.Mesh(g, mat); m.castShadow = true; m.frustumCulled = false;
      var holder = new T.Group();
      holder.position.copy(org).sub(P0);
      holder.add(m); pitch.add(holder);
      parts[k] = holder;
      return holder;
    }
    mk('body', null);
    ['head', 'tail', 'fl', 'fr', 'rl', 'rr'].forEach(function (k) { mk(k, PIV[k]) });
    var s = 0.115;
    root.scale.setScalar(s);
    var wrap = new T.Group(); wrap.add(root);
    return { obj: wrap, root: root, pitch: pitch, parts: parts, scale: s };
  }

  var ease = function (x) { return x < 0 ? 0 : x > 1 ? 1 : x * x * (3 - 2 * x) };
  function setPose(rig, p) {
    var P = rig.parts, s = p.sit;
    var drop = 2.3 * s;
    rig.pitch.position.y = P0.y - drop + (p.bob || 0);
    rig.pitch.rotation.x = -0.55 * s + (p.lean || 0);
    var sw = Math.sin(p.walk) * p.amp, sw2 = Math.sin(p.walk + Math.PI) * p.amp;
    var comp = 0.55 * s;
    if (P.fl) P.fl.rotation.x = sw * (1 - s) + comp - (p.paw ? 0.9 * p.paw : 0);
    if (P.fr) P.fr.rotation.x = sw2 * (1 - s) + comp;
    if (P.rl) P.rl.rotation.x = sw2 * (1 - s) - 1.0 * s;
    if (P.rr) P.rr.rotation.x = sw * (1 - s) - 1.0 * s;
    if (P.tail) { P.tail.rotation.y = Math.sin(p.wag) * p.wagAmp; P.tail.rotation.x = (p.tailUp || 0) + 0.25 * s }
    if (P.head) { P.head.rotation.y = p.headYaw || 0; P.head.rotation.x = (p.headPitch || 0) - 0.25 * s * 0 }
  }

  window.__DogRig = { build: buildRig, setPose: setPose };

  /* ---------- scene logic ---------- */
  var dog = null, G = null, state = null;
  var last = performance.now();

  function guard() { return G && G.NPC && G.NPC.guard }
  function blocked(x, z) {
    var cs = G.colliders || [];
    for (var i = 0; i < cs.length; i++) { var c = cs[i]; if (x > c.x0 - 0.3 && x < c.x1 + 0.3 && z > c.z0 - 0.3 && z < c.z1 + 0.3 && (c.h === undefined || c.h > 0.5)) return true }
    return false;
  }
  function pickWaypoint() {
    var g = guard();
    for (var tries = 0; tries < 14; tries++) {
      state.ang += (0.7 + Math.random() * 1.2) * state.dir;
      var r = 1.7 + Math.random() * 1.4, x = g.x + Math.sin(state.ang) * r, z = g.z + Math.cos(state.ang) * r;
      if (!blocked(x, z) && Math.hypot(x - G.pl.x, z - G.pl.z) > 1.1) return { x: x, z: z };
    }
    state.dir *= -1;
    return { x: g.x + 1.6, z: g.z + 1.6 };
  }
  function turnTo(a) {
    var d = a - state.yaw; d = Math.atan2(Math.sin(d), Math.cos(d));
    return d;
  }

  function startDog(src, map) {
    var rig = buildRig(src, map);
    G.sc.add(rig.obj);
    var g = guard();
    dog = rig;
    state = { mode: 'walk', x: g.x + 2, z: g.z + 1.5, yaw: 0, tx: 0, tz: 0, speed: 1.2, walk: 0, amp: 0, sit: 0, sitTarget: 0, timer: 0, wag: 0, wagAmp: 0.25, ang: Math.PI * 0.3, dir: 1, headYaw: 0, headPitch: 0, bob: 0, react: 0, lean: 0, paw: 0, tailUp: 0 };
    var w = pickWaypoint(); state.tx = w.x; state.tz = w.z;
    requestAnimationFrame(loop);
  }

  function nextAction() {
    var r = Math.random();
    var bed = window.__guardBooth && window.__guardBooth.bed;
    if (bed && r < 0.3 && !state.atBed) { state.tx = bed.x; state.tz = bed.z; state.mode = 'walk'; state.atBed = true; state.sitTarget = 0 }
    else if (r < 0.55) { state.mode = 'sit'; state.timer = 3 + Math.random() * 3.5; state.sitTarget = 1 }
    else if (r < 0.7) { state.mode = 'sniff'; state.timer = 1 + Math.random() * 1.2 }
    else { var w = pickWaypoint(); state.tx = w.x; state.tz = w.z; state.mode = 'walk' }
  }

  function update(dt) {
    var g = guard(); if (!g) return;
    var S = state, pl = G.pl;
    var dp = Math.hypot(pl.x - S.x, pl.z - S.z);
    dog.obj.visible = dp < 80;
    if (!dog.obj.visible) return;

    var moving = false, spd = 0;
    if (S.mode === 'walk' || S.mode === 'trot') {
      S.sitTarget = 0;
      var dx = S.tx - S.x, dz = S.tz - S.z, d = Math.hypot(dx, dz);
      if (S.sit > 0.15) { moving = false } else if (d < 0.12) {
        if (S.mode === 'trot') { S.mode = 'sit'; S.sitTarget = 1; S.timer = 5.5; S.react = 5.5; S.atBed = false; playBark(2) } else if (S.atBed) { S.atBed = false; S.mode = 'sit'; S.sitTarget = 1; S.timer = 6 + Math.random() * 4 } else nextAction();
      } else {
        spd = S.mode === 'trot' ? 3.2 : 1.15; moving = true;
        var da = turnTo(Math.atan2(dx, dz));
        S.yaw += da * Math.min(1, dt * 7);
        var step = Math.min(d, spd * dt);
        S.x += dx / d * step; S.z += dz / d * step;
      }
    } else if (S.mode === 'sit') {
      S.sitTarget = 1; S.timer -= dt;
      var look = Math.atan2(pl.x - S.x, pl.z - S.z), la = turnTo(look);
      if (dp < 14) S.yaw += la * Math.min(1, dt * 1.5) * 0.6;
      if (S.timer <= 0) { S.sitTarget = 0; if (S.sit < 0.2) { S.react = 0; var w = pickWaypoint(); S.tx = w.x; S.tz = w.z; S.mode = 'walk' } }
    } else if (S.mode === 'pet') {
      S.sitTarget = 1; S.timer -= dt;
      S.yaw += turnTo(Math.atan2(pl.x - S.x, pl.z - S.z)) * Math.min(1, dt * 5);
      if (S.timer <= 0) { S.react = 0; S.mode = 'sit'; S.timer = 2.5 }
    } else if (S.mode === 'sniff') {
      S.sitTarget = 0; S.timer -= dt;
      if (S.timer <= 0) { var w2 = pickWaypoint(); S.tx = w2.x; S.tz = w2.z; S.mode = 'walk' }
    }

    S.sit += (S.sitTarget - S.sit) * Math.min(1, dt * (S.mode === 'trot' ? 9 : 3.2));
    if (Math.abs(S.sitTarget - S.sit) < 0.01) S.sit = S.sitTarget;

    var swingRate = S.mode === 'trot' ? 15 : 9;
    if (moving) S.walk += dt * swingRate;
    var tAmp = moving ? (S.mode === 'trot' ? 0.75 : 0.5) : 0;
    S.amp += (tAmp - S.amp) * Math.min(1, dt * 8);

    var excited = S.react > 0 || S.mode === 'trot' || S.mode === 'pet';
    S.wag += dt * (excited ? 20 : S.mode === 'sit' ? 8 : 5);
    S.wagAmp += ((excited ? 0.9 : S.mode === 'sit' ? 0.5 : 0.28) - S.wagAmp) * Math.min(1, dt * 5);
    if (S.react > 0) S.react -= dt;

    var headT = 0, pitchT = 0;
    if (S.mode === 'sniff') { pitchT = 0.7 + Math.sin(performance.now() / 120) * 0.08; headT = Math.sin(performance.now() / 700) * 0.4 }
    else if (S.mode === 'pet') { pitchT = -0.15; headT = Math.sin(performance.now() / 260) * 0.15 }
    else if (excited) { pitchT = -0.35; headT = 0 }
    else if (S.mode === 'sit' && dp < 14) { headT = Math.max(-0.7, Math.min(0.7, turnTo(Math.atan2(pl.x - S.x, pl.z - S.z)) * 0.5)) }
    S.headYaw += (headT - S.headYaw) * Math.min(1, dt * 5);
    S.headPitch += (pitchT - S.headPitch) * Math.min(1, dt * 6);

    var gy = G.groundHeightAt ? G.groundHeightAt(S.x, S.z) : 0;
    S.bob = moving ? Math.abs(Math.sin(S.walk)) * 0.18 : 0;
    dog.obj.position.set(S.x, gy, S.z);
    dog.obj.rotation.y = S.yaw;
    setPose(dog, { walk: S.walk, amp: S.amp, sit: S.sit, bob: S.bob, wag: S.wag, wagAmp: S.wagAmp, headYaw: S.headYaw, headPitch: S.headPitch, tailUp: excited ? -0.3 : 0 });
  }

  function loop(now) {
    requestAnimationFrame(loop);
    var dt = Math.min(0.05, (now - last) / 1000); last = now;
    if (window.__paused || document.hidden || !dog || !guard()) return;
    try { update(dt) } catch (e) { console.warn('dog update failed', e); dog.obj.visible = false; dog = null }
  }

  function reactToWhistle() {
    if (!dog || !state) return;
    var g = guard();
    var fx = Math.sin(g.g ? g.g.rotation.y : 0), fz = Math.cos(g.g ? g.g.rotation.y : 0);
    state.tx = g.x + fx * 1.2 + fz * 0.9; state.tz = g.z + fz * 1.2 - fx * 0.9;
    if (blocked(state.tx, state.tz)) { state.tx = g.x + 1; state.tz = g.z }
    state.mode = 'trot'; state.sitTarget = 0; state.react = 6;
  }

  function petBlocked() {
    return !G || window.__paused || window.__call || G.dlg || G.saluting || (window.__gateFlow && window.__gateFlow.state === 'checking') ||
      (window.__inv && window.__inv.isOpen && window.__inv.isOpen()) || (window.__mini && window.__mini.active) || (window.__chat && window.__chat.active);
  }
  function nearDog() {
    if (!dog || !state || !dog.obj.visible || !G.pl) return false;
    return Math.hypot(G.pl.x - state.x, G.pl.z - state.z) < 2.2 && state.mode !== 'trot';
  }
  function petDog() {
    if (petBlocked() || !nearDog()) return false;
    state.atBed = false; state.mode = 'pet'; state.timer = 2.8; state.react = 2.8; state.sitTarget = 1;
    playYip(); hearts();
    return true;
  }
  addEventListener('keydown', function (e) {
    if (e.code !== 'KeyE' || e.repeat || (e.target && e.target.tagName === 'INPUT')) return;
    if (!nearDog() || petBlocked()) return;
    var gd = guard(), dd = Math.hypot(G.pl.x - state.x, G.pl.z - state.z);
    if (gd && Math.hypot(G.pl.x - gd.x, G.pl.z - gd.z) < dd) return;
    if (petDog()) { e.preventDefault(); e.stopImmediatePropagation() }
  }, true);
  setInterval(function () {
    var show = !!(G && G.started !== false && nearDog() && !petBlocked());
    var idb = document.getElementById('idcard-btn');
    if (show && idb && idb.style.display === 'block') show = false;
    petBtn.style.display = show && window.__mobile ? 'block' : 'none';
    petHint.style.display = show && !window.__mobile ? 'block' : 'none';
  }, 250);

  /* ---------- public API ---------- */
  var scene = window.__gateScene = {
    ready: true,
    get dog() { return dog },
    get state() { return state },
    whistle: function (done) {
      var A = window.__guardAnim;
      if (A && A.whistle) A.whistle();
      setTimeout(function () {
        playWhistle();
        cap.classList.remove('on'); void cap.offsetWidth; cap.classList.add('on');
        reactToWhistle();
      }, 450);
      setTimeout(function () { cap.classList.remove('on'); if (done) done() }, 2100);
    },
    playWhistle: playWhistle,
    playBark: playBark,
    pet: petDog
  };

  /* ---------- load dog ---------- */
  function load() {
    G = window.__g;
    if (!G || !G.sc || !G.NPC || !T.FBXLoader) {
      setTimeout(load, 150);
      return;
    }
    if (dog) return;
    var mgr = new T.LoadingManager();
    mgr.setURLModifier(function () { return 'assets/models/dog/textures/dog_uv.png' });
    var tex = new T.TextureLoader(mgr).load('assets/models/dog/textures/dog_uv.png');
    fetch('assets/models/dog/source/Dog_model.fbx').then(function (r) {
      if (!r.ok) throw new Error('dog model ' + r.status);
      return r.arrayBuffer();
    }).then(function (buf) {
      var root = new T.FBXLoader(mgr).parse(buf, '');
      var mesh = null; root.traverse(function (o) { if (o.isMesh && !mesh) mesh = o });
      if (!mesh) throw new Error('dog mesh missing');
      mesh.updateMatrixWorld(true);
      var geo = mesh.geometry;
      startDog({ geometry: geo }, tex);
    }).catch(function (e) { console.warn('Dog model unavailable, gate scene continues without dog', e) });
  }
  load();
})();
