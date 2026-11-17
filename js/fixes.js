/* Gate / mission / voice hardening (levels 2-7). Loaded last by assets.js.
   - window.__gateFlow : gateState machine (idle | checking | passed | denied) + hasID
   - window.__mission  : persistent mission store + HUD pin + debounced re-announce
   - window.__voice    : wrapped with a single voice manager (NPC channel / mission channel, audio unlock, text fallback) */
(function () {
  var LVL = window.__LVL || 1, MKEY = 'anits-mission:v1:' + LVL, GKEY = 'anits-gate:v1:' + LVL;
  var $ = function (id) { return document.getElementById(id) };
  var ls = {
    get: function (k) { try { return JSON.parse(localStorage.getItem(k)) } catch (e) { return null } },
    set: function (k, v) { try { localStorage.setItem(k, JSON.stringify(v)) } catch (e) {} }
  };
  var G = function () { return window.__g || null };
  var invOpen = function () { return !!(window.__inv && window.__inv.isOpen && window.__inv.isOpen()) };
  var chatOn = function () { return !!(window.__chat && window.__chat.active) };
  var miniOn = function () { return !!(window.__mini && window.__mini.active) };

  /* ---------- CSS ---------- */
  var css = document.createElement('style');
  css.textContent =
    '#inv{z-index:46!important}#inv-toast{z-index:47!important}' +
    '#mission-pin{position:fixed;top:10px;left:50%;transform:translateX(-50%);z-index:44;max-width:min(560px,44vw);display:none;align-items:center;gap:8px;padding:6px 14px;border-radius:999px;background:rgba(8,14,26,.78);border:1.5px solid rgba(255,213,74,.75);color:#fff;font:700 13px/1.3 Figtree,system-ui,sans-serif;pointer-events:none;white-space:nowrap;overflow:hidden;transition:box-shadow .3s,background-color .3s}' +
    '#mission-pin b{color:#ffd54a;font-size:11px;letter-spacing:.12em;flex:none}#mission-pin span{overflow:hidden;text-overflow:ellipsis}' +
    '#mission-pin.flash{background:rgba(60,48,8,.92);box-shadow:0 0 18px rgba(255,213,74,.7)}' +
    '#mission-say{position:fixed;left:50%;top:52px;transform:translateX(-50%);z-index:44;max-width:min(640px,92vw);display:none;padding:9px 18px;border-radius:14px;background:rgba(8,14,26,.88);border:1.5px solid #ffd54a;color:#fff;font:700 15px/1.35 Figtree,system-ui,sans-serif;text-align:center;pointer-events:none}' +
    '#idcard-btn{position:fixed;left:50%;bottom:150px;transform:translateX(-50%);z-index:46;display:none;padding:12px 26px;border-radius:999px;border:0;background:#2fd36b;color:#06210f;font:800 15px Figtree,system-ui,sans-serif;letter-spacing:.08em;cursor:pointer;box-shadow:0 0 18px rgba(47,211,107,.55);touch-action:manipulation}' +
    'body.touch #mission-pin{max-width:36vw;font-size:11px;padding:4px 10px;top:6px}body.touch #mission-say{top:40px;font-size:13px}body.touch #idcard-btn{bottom:110px}';
  document.head.appendChild(css);

  var pin = document.createElement('div');
  pin.id = 'mission-pin'; pin.setAttribute('data-testid', 'mission-hud-pin');
  pin.innerHTML = '<b></b><span></span>';
  var say = document.createElement('div');
  say.id = 'mission-say'; say.setAttribute('data-testid', 'mission-announce-text');
  var idb = document.createElement('button');
  idb.id = 'idcard-btn'; idb.setAttribute('data-testid', 'show-id-card-btn'); idb.textContent = window.__mobile ? 'SHOW ID' : 'SHOW ID CARD (F)';
  document.body.appendChild(pin); document.body.appendChild(say); document.body.appendChild(idb);
  idb.addEventListener('pointerdown', function (e) { e.stopPropagation() });
  idb.addEventListener('click', function (e) { e.stopPropagation(); var g = G(); if (g && g.gateCheck) g.gateCheck() });

  var fp = document.createElement('div');
  fp.id = 'id-prompt'; fp.setAttribute('data-testid', 'show-id-prompt');
  fp.textContent = 'Press F to show your ID card';
  fp.style.cssText = 'position:fixed;left:50%;bottom:210px;transform:translateX(-50%);z-index:46;display:none;padding:8px 18px;border-radius:12px;background:rgba(8,14,26,.9);border:1.5px solid #2fd36b;color:#fff;font:700 14px Figtree,system-ui,sans-serif;pointer-events:none';
  document.body.appendChild(fp);
  function nearGuard() {
    var g = G(); if (!g || !g.NPC || !g.NPC.guard) return false;
    var s = g.story && g.story[g.si];
    return !!(s && s.idcheck && Math.hypot(g.pl.x - g.NPC.guard.x, g.pl.z - g.NPC.guard.z) < 9);
  }
  addEventListener('keydown', function (e) {
    if (e.code !== 'KeyF' || e.repeat || (e.target && e.target.tagName === 'INPUT')) return;
    if (!nearGuard() || window.__call || window.__paused || miniOn() || invOpen()) return;
    e.preventDefault(); e.stopImmediatePropagation();
    if (chatOn()) { window.__chat.close(); return }
    var g = G(); if (g && g.gateCheck) g.gateCheck();
  }, true);

  /* ---------- gate state machine ---------- */
  var gate = { state: 'idle' };
  function setGate(s) {
    if (gate.state === s) return; gate.state = s;
    ls.set(GKEY, { state: s, si: G() ? G().si : -1, hasID: gateFlow.hasID(), t: Date.now() });
  }
  var gateFlow = window.__gateFlow = {
    get state() { return gate.state },
    hasID: function () { return !!(window.__inv && window.__inv.has('id')) },
    check: function (onPass) {
      if (invOpen()) return;
      setGate('checking');
      window.__inv.ask(function () { setGate('passed'); onPass() });
    },
    passed: function () { setGate('passed') }
  };

  /* ---------- mission store + HUD ---------- */
  function missionNow() {
    var t = $('mt') ? $('mt').textContent : '', n = $('mn') ? $('mn').textContent : '';
    return { text: t, label: n };
  }
  function renderPin() {
    var m = missionNow();
    if (!m.text) { var st = ls.get(MKEY); if (st) m = st }
    pin.firstChild.textContent = m.label || 'MISSION';
    pin.lastChild.textContent = m.text || '';
    pin.title = m.text || '';
  }
  function persist() {
    var m = missionNow(), g = G();
    if (!m.text || !g) return;
    ls.set(MKEY, { text: m.text, label: m.label, si: g.si, t: Date.now() });
    if (window.OfflineSave && window.OfflineSave.saveNow) window.OfflineSave.saveNow();
  }
  var firstPaint = ls.get(MKEY);
  if (firstPaint && $('mt') && !$('mt').textContent) renderPin();
  if ($('mt') && window.MutationObserver) {
    new MutationObserver(function () { renderPin(); persist(); M.last = 0 }).observe($('mt'), { childList: true, characterData: true, subtree: true });
  }

  /* ---------- voice manager ---------- */
  var V = window.__voice, SS = window.speechSynthesis;
  var M = { unlocked: false, npcActive: false, speaking: false, interrupted: false, last: 0, lastText: '', timer: 0, sayT: 0, started: false };

  function unlock() {
    if (M.unlocked) return; M.unlocked = true;
    ['pointerdown', 'keydown', 'touchend', 'click'].forEach(function (ev) { removeEventListener(ev, unlock, true) });
    try {
      var AC = window.AudioContext || window.webkitAudioContext;
      if (AC) {
        var c = new AC(); if (c.resume) c.resume();
        var s = c.createBufferSource(); s.buffer = c.createBuffer(1, 1, 22050); s.connect(c.destination); s.start(0);
        setTimeout(function () { try { c.close() } catch (e) {} }, 400);
      }
    } catch (e) {}
    try {
      var a = new Audio('data:audio/wav;base64,UklGRiQAAABXQVZFZm10IBAAAAABAAEAESsAABErAAABAAgAZGF0YQAAAAA=');
      a.volume = 0; var p = a.play(); if (p && p.catch) p.catch(function () {});
    } catch (e) {}
    try { if (SS) { if (SS.resume) SS.resume(); var u = new SpeechSynthesisUtterance(' '); u.volume = 0; SS.speak(u) } } catch (e) {}
    schedule(900);
  }
  ['pointerdown', 'keydown', 'touchend', 'click'].forEach(function (ev) { addEventListener(ev, unlock, true) });

  function speakMission(text) {
    if (!SS || typeof SpeechSynthesisUtterance === 'undefined' || !M.unlocked) return false;
    var clean = String(text).replace(/\([^)]*\)/g, '').replace(/\s+/g, ' ').trim();
    var u = new SpeechSynthesisUtterance('Mission. ' + clean);
    var vs = []; try { vs = SS.getVoices() } catch (e) {}
    var en = vs.filter(function (v) { return /^en/i.test(v.lang) })[0];
    if (en) { u.voice = en; u.lang = en.lang } else u.lang = 'en-IN';
    u.rate = 1; u.volume = window.__VOL == null ? 1 : window.__VOL;
    u.onstart = function () { M.speaking = true };
    u.onend = u.onerror = function () { M.speaking = false };
    try { if (SS.resume) SS.resume(); SS.speak(u); return true } catch (e) { return false }
  }

  function showText(text, long) {
    say.textContent = text; say.style.display = 'block';
    pin.classList.add('flash');
    clearTimeout(M.sayT);
    M.sayT = setTimeout(function () { say.style.display = 'none'; pin.classList.remove('flash') }, long ? 8000 : 5000);
  }

  function ready() {
    var g = G();
    if (!g || g.si < 0 || !M.started) return false;
    if (g.dlg || chatOn() || window.__call || window.__paused || invOpen() || miniOn() || g.saluting || M.npcActive) return false;
    var ov = $('ov'); if (ov && ov.style.display !== 'none') return false;
    return true;
  }

  function announce(force) {
    return;
    if (!ready()) return;
    var m = missionNow(), now = Date.now();
    if (!m.text) return;
    if (!force && !M.interrupted && m.text === M.lastText && now - M.last < 6000) return;
    M.last = now; M.lastText = m.text; M.interrupted = false;
    var ok = speakMission(m.text);
    showText(m.text, !ok);
    if (ok) setTimeout(function () { if (!M.speaking && ready()) showText(m.text, true) }, 3000);
  }

  function schedule(ms) {
    clearTimeout(M.timer);
    M.timer = setTimeout(function () { announce(false) }, ms == null ? 700 : ms);
  }

  function npcBegin() {
    clearTimeout(M.timer);
    if (M.speaking) { M.interrupted = true; M.speaking = false }
    M.npcActive = true;
    say.style.display = 'none';
  }

  if (V) {
    var oSay = V.say, oSpeak = V.speak, oStop = V.stop;
    V.say = function () { npcBegin(); return oSay.apply(V, arguments) };
    V.speak = function () { npcBegin(); return oSpeak.apply(V, arguments) };
    V.stop = function () { try { oStop.call(V) } catch (e) {} M.npcActive = false; M.speaking = false; schedule(700) };
  }
  window.__mission = {
    get text() { return missionNow().text },
    announce: function () { announce(true) },
    get unlocked() { return M.unlocked }
  };

  document.addEventListener('visibilitychange', function () {
    try {
      if (document.hidden) { if (SS && SS.speaking) SS.pause() }
      else if (SS && !window.__paused) { SS.resume(); schedule(500) }
    } catch (e) {}
  });
  addEventListener('anits-resume', function () { schedule(600) });

  /* ---------- watchdog: UI never stays stuck ---------- */
  var stuck = 0, orphan = 0, firstTick = true;
  setInterval(function () {
    var g = G(); if (!g) return;
    var started = $('menu') && getComputedStyle($('menu')).display === 'none' && $('ov') && $('ov').style.display === 'none';
    if (started && !M.started) { M.started = true; schedule(1500) }
    if (!started) return;
    var s = g.story && g.story[g.si];

    if (g.si >= 1) gate.state !== 'passed' && setGate('passed');
    else if (gate.state === 'checking' && !invOpen()) setGate('idle');
    else if (gate.state === 'denied' || (gate.state === 'passed' && g.si === 0)) setGate('idle');

    var dlgEl = $('dlg'), dlgVisible = dlgEl && dlgEl.style.display !== 'none';
    if (g.dlg && !dlgVisible && !chatOn() && !invOpen() && !window.__call && !miniOn() && !g.saluting) {
      if (++stuck >= 6 && g.resetDialogue) { g.resetDialogue(); stuck = 0 }
    } else stuck = 0;
    if (!g.dlg && dlgVisible && !window.__call) {
      if (++orphan >= 6) { dlgEl.style.display = 'none'; orphan = 0 }
    } else orphan = 0;

    var show = false;
    if (s && s.idcheck && gate.state !== 'checking' && !g.dlg && !chatOn() && !invOpen() && !window.__paused && !window.__call && g.NPC && g.NPC.guard) {
      var d = Math.hypot(g.pl.x - g.NPC.guard.x, g.pl.z - g.NPC.guard.z);
      show = d < 9;
    }
    idb.style.display = show ? 'block' : 'none';
    fp.style.display = show ? 'block' : 'none';
    pin.style.display = (g.si >= 0 && pin.lastChild.textContent) ? 'flex' : 'none';
    if (pin.style.display === 'flex') renderPin();
  }, 250);
})();
