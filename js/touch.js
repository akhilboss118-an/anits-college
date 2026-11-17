/* ANITS on-screen controls for phones (loaded last by assets.js; needs js/mobile.js, which sets window.__mobile).

   LEFT  thumb : MOVE joystick (v2). Floating analog stick: it appears under your thumb anywhere in the left
                 zone, any angle, and pushing it to the rim auto-runs. RUN (just above its resting spot) locks running.
   RIGHT thumb : LOOK joystick (turns the camera). You can also just drag anywhere on the 3D view to look.
   Round buttons: contextual talk / use / open and salute, RUN, BAG and full-screen toggle.
   Mini-games  : the controls swap to what the game needs: arrow D-pad (parade drill, fest dance) or one big
                 SHOOT / TAP button (basketball, samosa). Quizzes and Try-again are plain tappable.

   Hooks into js/game.js (unchanged): window.__joy {x,y,run}, window.__lookBy(dx,dy). Buttons send the same key events
   as the keyboard, so every keyboard feature keeps working. Tune the feel with the constants below. */
(function () {
  'use strict';
  var MB = window.__mobile; if (!MB || document.getElementById('tc')) return;

  var LOOK_YAW = 430, LOOK_PITCH = 320;   // look-stick speed at full push (drag-pixels per second)
  var LOOK_DRAG = 1.25;                   // finger-drag look sensitivity
  var STICK_REACH = .8;                   // look-knob travel, as a share of the base radius
  var DEAD = .16;                         // dead zone

  var J = window.__joy = window.__joy || { x: 0, y: 0, run: false };
  var $ = function (id) { return document.getElementById(id) };
  var buzz = function (ms) { try { navigator.vibrate && navigator.vibrate(ms) } catch (e) {} };
  var runLock = false;

  var IC = {
    run: '<svg viewBox="0 0 24 24"><circle cx="16" cy="4" r="2"/><path d="m11 8 3-2 3 2 2 1M14 9l-2 4 4 2-1 5M12 13l-5 2-3 4M9 8l-3 4"/></svg>',
    bag: '<svg viewBox="0 0 24 24"><path d="M8 7V6a4 4 0 018 0v1M5 7h14l1 14H4z"/><path d="M9 13h6"/></svg>',
    talk: '<svg viewBox="0 0 24 24"><path d="M4 5h16v12H9l-5 4z"/><path d="M8 11h8"/></svg>',
    door: '<svg viewBox="0 0 24 24"><path d="M5 21V4l13-2v19M5 21h15M14 12h.01"/></svg>',
    use: '<svg viewBox="0 0 24 24"><rect x="4" y="3" width="16" height="18" rx="2"/><path d="M8 8h8M8 12h8M12 16h.01"/></svg>',
    sit: '<svg viewBox="0 0 24 24"><path d="M5 21v-7h13v7M7 14V7h10v7M5 21h13"/></svg>',
    salute: '<svg viewBox="0 0 24 24"><circle cx="12" cy="5" r="2"/><path d="M9 21v-8l3-3 3 3v8M15 11l5-4M20 7l2 1M6 14l-3 3"/></svg>',
    fs:  '<svg viewBox="0 0 24 24"><path d="M4 9V4h5M20 9V4h-5M4 15v5h5M20 15v5h-5"/></svg>',
    fsx: '<svg viewBox="0 0 24 24"><path d="M9 4v5H4M15 4v5h5M9 20v-5H4M15 20v-5h5"/></svg>'
  };

  /* ---------------- build the DOM ---------------- */
  var root = document.createElement('div'); root.id = 'tc';
  root.innerHTML =
    '<div id="tcz" data-testid="movement-zone"><div id="tcd" role="group" aria-label="Move joystick" data-testid="movement-joystick">' +
      '<span class="tcd-a u" data-testid="move-up-indicator">&#9650;</span><span class="tcd-a l" data-testid="move-left-indicator">&#9664;</span>' +
      '<span class="tcd-a r" data-testid="move-right-indicator">&#9654;</span><span class="tcd-a d" data-testid="move-down-indicator">&#9660;</span>' +
      '<span class="tcd-run" aria-hidden="true">RUN</span><i id="tcd-knob"></i><span class="lbl">MOVE</span></div></div>' +
    '<div class="tcj" id="tcjR" role="group" aria-label="Look around" data-testid="look-control"><span class="lbl">LOOK</span><i class="tck"></i></div>' +
    '<button type="button" class="tcb" id="tcE" data-testid="context-action-button" aria-label="Interact" style="display:none"><span class="act-icon">' + IC.talk + '</span><b>Talk</b></button>' +
    '<button type="button" class="tcb" id="tcG" data-testid="salute-action-button" aria-label="Salute" style="display:none">' + IC.salute + '<small>SALUTE</small></button>' +
    '<button type="button" class="tcb" id="tcR" data-testid="run-button" aria-label="Run" aria-pressed="false">' + IC.run + '<small>RUN</small></button>' +
    '<button type="button" class="tcb" id="tcB" data-testid="bag-button" aria-label="Open bag">' + IC.bag + '<small>BAG</small></button>' +
    '<button type="button" class="tcb tcs" id="tcF" data-testid="fullscreen-button" aria-label="Toggle full screen">' + IC.fs + '</button>';
  document.body.appendChild(root);

  var mp = document.createElement('div'); mp.id = 'tcm';
  mp.innerHTML =
    '<div id="tcdp">' +
    '<button type="button" class="tcb dp" data-k="ArrowUp" data-testid="mini-up-button" style="grid-area:1/2">&#9650;</button>' +
    '<button type="button" class="tcb dp" data-k="ArrowLeft" data-testid="mini-left-button" style="grid-area:2/1">&#9664;</button>' +
    '<button type="button" class="tcb dp" data-k="ArrowRight" data-testid="mini-right-button" style="grid-area:2/3">&#9654;</button>' +
    '<button type="button" class="tcb dp" data-k="ArrowDown" data-testid="mini-down-button" style="grid-area:3/2">&#9660;</button></div>' +
    '<button type="button" class="tcb" id="tcA" data-testid="mini-tap-button"><b>TAP</b></button>';
  document.body.appendChild(mp);

  /* ---------------- helpers ---------------- */
  function key(code, k) {
    var o = { code: code, key: k, bubbles: true, cancelable: true };
    window.dispatchEvent(new KeyboardEvent('keydown', o));
    window.dispatchEvent(new KeyboardEvent('keyup', o));
  }
  function press(el, fn) {
    el.addEventListener('pointerdown', function (e) { e.preventDefault(); e.stopPropagation(); el.classList.add('dn'); buzz(12); fn(e) });
    ['pointerup', 'pointercancel', 'pointerleave'].forEach(function (t) { el.addEventListener(t, function () { el.classList.remove('dn') }) });
  }
  function setKnob(k, dx, dy) { k.style.transform = 'translate(' + dx.toFixed(1) + 'px,' + dy.toFixed(1) + 'px)' }

  /* ---------------- MOVE joystick: floating, analog, auto-run at the rim ---------------- */
  var zone = $('tcz'), pad = $('tcd'), mKnob = $('tcd-knob');
  var mid = null, mcx = 0, mcy = 0, mR = 44, wasRun = false;
  var RUN_AT = .88;                                  // push past this share of the radius to run
  function padRect() { return pad.getBoundingClientRect() }
  function placePad(cx, cy) {                       // centre the stick on a screen point (clamped inside the zone)
    var z = zone.getBoundingClientRect(), r = padRect(), hw = r.width / 2;
    var x = Math.min(Math.max(cx, z.left + hw + 4), z.right - hw - 4), y = Math.min(Math.max(cy, z.top + hw + 4), z.bottom - hw - 4);
    pad.style.transition = 'none'; pad.style.left = (x - hw - z.left) + 'px'; pad.style.top = (y - hw - z.top) + 'px'; pad.style.bottom = 'auto';
    mcx = x; mcy = y;
  }
  function moveMove(e) {
    var dx = e.clientX - mcx, dy = e.clientY - mcy, d = Math.hypot(dx, dy), raw = d / mR;
    if (d > mR) { dx *= mR / d; dy *= mR / d; d = mR }
    setKnob(mKnob, dx, dy);
    var m = d / mR;
    if (m < DEAD) { J.x = 0; J.y = 0; J.run = runLock; wasRun = false; pad.className = 'on'; return }
    var mag = Math.min(1, (m - DEAD) / (1 - DEAD) + .35);
    J.x = dx / d * mag; J.y = -dy / d * mag;        // game.js: x right, y forward
    var run = runLock || raw > RUN_AT;
    J.run = run;
    if (run && !wasRun) buzz(8);
    wasRun = run;
    pad.className = 'on' + (run ? ' run' : '');
    pad.dataset.u = J.y > .38 ? 1 : 0; pad.dataset.d = J.y < -.38 ? 1 : 0; pad.dataset.l = J.x < -.38 ? 1 : 0; pad.dataset.r = J.x > .38 ? 1 : 0;
  }
  function moveEnd() {
    mid = null; J.x = 0; J.y = 0; J.run = runLock; wasRun = false;
    setKnob(mKnob, 0, 0); pad.className = '';
    pad.dataset.u = pad.dataset.d = pad.dataset.l = pad.dataset.r = 0;
    pad.style.transition = 'left .18s ease-out,top .18s ease-out,bottom .18s ease-out';   // glide back to the resting spot
    pad.style.left = ''; pad.style.top = ''; pad.style.bottom = '';
  }
  zone.addEventListener('pointerdown', function (e) {
    if (mid !== null) return; mid = e.pointerId;
    try { zone.setPointerCapture(mid) } catch (_) {}
    var r = padRect(); mR = r.width / 2 * .62;
    placePad(e.clientX, e.clientY); moveMove(e); e.preventDefault(); e.stopPropagation();
  });
  zone.addEventListener('pointermove', function (e) { if (e.pointerId === mid) { moveMove(e); e.preventDefault() } });
  ['pointerup', 'pointercancel', 'lostpointercapture'].forEach(function (t) { zone.addEventListener(t, function (e) { if (e.pointerId === mid) moveEnd() }) });

  /* ---------------- LOOK stick (fixed, turns the camera) ---------------- */
  var lBase = $('tcjR'), lKnob = lBase.querySelector('.tck');
  var lid = null, lcx = 0, lcy = 0, lR = 40, lv = { x: 0, y: 0 };
  function lookMove(e) {
    var dx = e.clientX - lcx, dy = e.clientY - lcy, d = Math.hypot(dx, dy);
    if (d > lR) { dx *= lR / d; dy *= lR / d; d = lR }
    setKnob(lKnob, dx, dy);
    var m = d / lR;
    if (m < DEAD) { lv.x = 0; lv.y = 0 }
    else { var mag = Math.pow((m - DEAD) / (1 - DEAD), 1.5); lv.x = dx / d * mag; lv.y = dy / d * mag }   // eased: fine aim near the centre, fast at the edge
  }
  function lookEnd() { lid = null; lv.x = lv.y = 0; setKnob(lKnob, 0, 0); lBase.classList.remove('on') }
  lBase.addEventListener('pointerdown', function (e) {
    if (lid !== null) return; lid = e.pointerId;
    try { lBase.setPointerCapture(lid) } catch (_) {}
    var b = lBase.getBoundingClientRect(); lcx = b.left + b.width / 2; lcy = b.top + b.height / 2; lR = b.width / 2 * STICK_REACH;
    lBase.classList.add('on'); lookMove(e); e.preventDefault(); e.stopPropagation();
  });
  lBase.addEventListener('pointermove', function (e) { if (e.pointerId === lid) { lookMove(e); e.preventDefault() } });
  ['pointerup', 'pointercancel', 'lostpointercapture'].forEach(function (t) { lBase.addEventListener(t, function (e) { if (e.pointerId === lid) lookEnd() }) });
  var last = performance.now();
  (function lookLoop(t) {
    requestAnimationFrame(lookLoop);
    var dt = Math.min(.05, (t - last) / 1000); last = t;
    if ((lv.x || lv.y) && window.__lookBy) window.__lookBy(lv.x * LOOK_YAW * dt, lv.y * LOOK_PITCH * dt);
  })(last);

  /* ---------------- drag the 3D view to look ---------------- */
  var did = null, dx0 = 0, dy0 = 0;
  document.addEventListener('pointerdown', function (e) {
    var t = e.target; if (e.pointerType === 'mouse' || did !== null || !t || t.tagName !== 'CANVAS' || t.id === 'mc') return;
    did = e.pointerId; dx0 = e.clientX; dy0 = e.clientY;
  }, true);
  document.addEventListener('pointermove', function (e) {
    if (e.pointerId !== did) return;
    var dx = e.clientX - dx0, dy = e.clientY - dy0; dx0 = e.clientX; dy0 = e.clientY;
    if (window.__lookBy) window.__lookBy(dx * LOOK_DRAG, dy * LOOK_DRAG);
  }, true);
  ['pointerup', 'pointercancel'].forEach(function (t) { document.addEventListener(t, function (e) { if (e.pointerId === did) did = null }, true) });

  /* ---------------- round buttons ---------------- */
  press($('tcE'), function () { key('KeyE', 'e') });
  press($('tcG'), function () { key('KeyG', 'g') });
  press($('tcB'), function () { key('KeyB', 'b') });
  function setAuto(on) { runLock = on; J.run = on; J.auto = on; $('tcR').classList.toggle('lock', on); $('tcR').setAttribute('aria-pressed', String(on)) }
  window.__runRelease = function () { if (runLock) setAuto(false) };
  press($('tcR'), function () { setAuto(!runLock) });   // RUN latches: the player keeps running forward by itself; steer with the joystick, tap RUN again to stop
  var fsb = $('tcF');
  if (MB.canFS) {
    press(fsb, function () { MB.toggle() });
    var upFS = function () { fsb.innerHTML = MB.isFS() ? IC.fsx : IC.fs };
    document.addEventListener('fullscreenchange', upFS); document.addEventListener('webkitfullscreenchange', upFS); upFS();
  } else fsb.style.display = 'none';

  /* ---------------- mini-game pad ---------------- */
  [].forEach.call(mp.querySelectorAll('.dp'), function (b) { press(b, function () { key(b.dataset.k, b.dataset.k) }) });
  press($('tcA'), function () { key('Space', ' ') });

  /* ---------------- show / hide ---------------- */
  var wasOn = false, mode = '';
  function miniMode() {
    var b = $('mi-b'); if (!b) return '';
    if (b.querySelector('.mi-shot')) return 'shoot';
    if (b.querySelector('[data-testid="cmd-symbol"]')) return 'cmd';
    if (b.querySelector('[data-testid="mash-count"]')) return 'mash';
    return '';
  }
  function actionInfo(text) {
    if (/sit on|stand up/i.test(text)) return { icon: 'sit', label: /stand up/i.test(text) ? 'Stand' : 'Sit' };
    if (/enter|leave|open|door/i.test(text)) return { icon: 'door', label: /leave/i.test(text) ? 'Leave' : 'Open' };
    if (/shop|canteen|buy/i.test(text)) return { icon: 'use', label: 'Shop' };
    if (/machine|bank|atm|use/i.test(text)) return { icon: 'use', label: 'Use' };
    return { icon: 'talk', label: 'Talk' };
  }
  function sync() {
    var ov = $('ov'), mn = $('menu'), sh = $('shop'), inv = $('inv');
    var mini = !!(window.__mini && window.__mini.active);
    var menuUp = mn && mn.style.display !== 'none' && !mn.classList.contains('gone');
    var live = ov && ov.style.display === 'none' && !menuUp;
    var on = !!(live && !mini && !window.__paused && !(sh && sh.style.display === 'block') && !window.__call && !(inv && inv.style.display === 'flex'));
    if (on !== wasOn) { wasOn = on; root.style.display = on ? 'block' : 'none'; if (!on) { moveEnd(); lookEnd() } }

    // #mh is populated by the game's own proximity checks every frame. Never
    // invent an available action or alter the underlying E/G key behaviour.
    var hints = $('mh') ? Array.from($('mh').querySelectorAll('span')) : [];
    var primary = hints.find(function (h) { return h.querySelector('kbd') && h.querySelector('kbd').textContent === 'E' });
    var secondary = hints.find(function (h) { return h.querySelector('kbd') && h.querySelector('kbd').textContent === 'G' });
    var talking = !!(window.__g && window.__g.dlg && $('dlg') && $('dlg').style.display !== 'none');
    var action = $('tcE'), salute = $('tcG');
    var showAction = on && (!!primary || talking);
    action.style.display = showAction ? 'flex' : 'none';
    if (showAction) {
      var text = talking ? 'Continue conversation' : primary.textContent.replace(/^E\s*/, '').trim();
      var info = talking ? { icon: 'talk', label: 'Next' } : actionInfo(text);
      if (action.dataset.kind !== info.icon) { action.querySelector('.act-icon').innerHTML = IC[info.icon]; action.dataset.kind = info.icon }
      action.querySelector('b').textContent = info.label;
      action.setAttribute('aria-label', text);
      action.title = text;
    }
    salute.style.display = on && !!secondary ? 'flex' : 'none';

    var m = mini ? miniMode() : '';
    if (m !== mode) {
      mode = m;
      mp.style.display = m ? 'block' : 'none';
      $('tcdp').style.display = m === 'cmd' ? 'grid' : 'none';
      var a = $('tcA'); a.style.display = (m === 'shoot' || m === 'mash') ? 'flex' : 'none';
      a.firstChild.textContent = m === 'shoot' ? 'SHOOT' : 'TAP';
    }
    var el = $('mini'); if (el) el.classList.toggle('pad', !!m);
  }
  root.style.display = 'none'; mp.style.display = 'none';
  setInterval(sync, 120);
  document.addEventListener('visibilitychange', function () { if (document.hidden) { moveEnd(); lookEnd() } });

  /* start-screen help text (the keyboard list does not apply on a phone) */
  var keysHelp = document.querySelector('#ov .keys');
  if (keysHelp) keysHelp.innerHTML = '<span>Left thumb: move (push to the rim to run)</span><span>Right stick or drag: look</span><span>Action buttons appear when nearby</span><span>BAG: inventory</span>';
})();
