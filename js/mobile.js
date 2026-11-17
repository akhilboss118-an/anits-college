/* ANITS mobile shell. Loaded first (in <head>) so it also covers the intro, menus and loading screen.
   - auto full screen + landscape lock on the player's first tap (browsers only allow it after a tap)
   - "rotate your phone" screen while held in portrait
   - keeps the screen awake, blocks pull-to-refresh / pinch-zoom / long-press menus
   - rewrites keyboard wording ("press SPACE", "Hold Shift") into touch wording
   Only active on touch devices. Preview on a desktop with ?touch=1, disable with ?touch=0.
   The on-screen joysticks and buttons themselves live in js/touch.js (loaded with the game). */
(function () {
  'use strict';
  var qs = location.search, ua = navigator.userAgent || '';
  var coarse = false; try { coarse = matchMedia('(pointer:coarse)').matches } catch (e) {}
  var on = !/[?&]touch=0/.test(qs) &&
    (/[?&]touch=1/.test(qs) || coarse || (navigator.maxTouchPoints > 1 && /Android|iPhone|iPad|iPod|Mobile|Tablet/i.test(ua)));
  if (!on) return;

  var de = document.documentElement, M = window.__mobile = { on: true };
  de.classList.add('mobile');

  var ios = /iPad|iPhone|iPod/.test(ua) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
  var standalone = !!navigator.standalone;
  try { standalone = standalone || matchMedia('(display-mode: fullscreen)').matches || matchMedia('(display-mode: standalone)').matches } catch (e) {}
  var canFS = !!(de.requestFullscreen || de.webkitRequestFullscreen);
  var wantFS = true;                       // turns false only if the player taps the "exit full screen" button

  function fsEl() { return document.fullscreenElement || document.webkitFullscreenElement || null }
  function lockLandscape() {
    try { var o = screen.orientation; if (o && o.lock) { var p = o.lock('landscape'); if (p && p.catch) p.catch(function () {}) } } catch (e) {}
  }
  var tryAt = 0;
  function enter() {
    if (!canFS || !wantFS || standalone || fsEl()) return;
    var now = Date.now(); if (now - tryAt < 600) return; tryAt = now;   // one attempt per tap (pointerup, touchend and click all fire)
    try {
      var p = de.requestFullscreen ? de.requestFullscreen({ navigationUI: 'hide' }) : de.webkitRequestFullscreen();
      if (p && p.then) p.then(lockLandscape, function () {}); else lockLandscape();
    } catch (e) {}
  }
  var wl = null;
  function wake() {
    try {
      if (navigator.wakeLock && !wl && document.visibilityState === 'visible')
        navigator.wakeLock.request('screen').then(function (s) { wl = s; s.addEventListener('release', function () { wl = null }) }, function () {});
    } catch (e) {}
  }

  M.canFS = canFS && !standalone;
  M.isFS = function () { return !!fsEl() || standalone };
  M.toggle = function () {
    if (fsEl()) { wantFS = false; (document.exitFullscreen || document.webkitExitFullscreen).call(document) }
    else { wantFS = true; enter(); }
  };

  /* every tap is a chance to (re)enter full screen: this is the "auto" part */
  ['pointerup', 'touchend', 'click'].forEach(function (t) {
    addEventListener(t, function () { enter(); lockLandscape(); wake() }, true);
  });
  document.addEventListener('visibilitychange', function () { if (document.visibilityState === 'visible') wake() });
  function fsChange() {
    de.classList.toggle('fs', M.isFS());
    if (fsEl()) lockLandscape();
    try { dispatchEvent(new Event('resize')) } catch (e) {}
  }
  document.addEventListener('fullscreenchange', fsChange);
  document.addEventListener('webkitfullscreenchange', fsChange);

  /* ---- touch wording: the game text talks about keys, a phone has buttons ---- */
  var RULES = [
    [/\(Hold Shift to run\)/g, '(push the stick to the edge, or tap RUN)'],
    [/\b([Pp])ress ([EG])\b/g, function (m, p, k) { return (p === 'P' ? 'Tap ' : 'tap ') + k }],
    [/\(press B\)/g, '(tap the BAG button)'],
    [/with the B key or the BAG button/g, 'with the BAG button'],
    [/with the B key/g, 'with the BAG button'],
    [/\b([Pp])ress (SHOW|Show)\b/g, function (m, p, k) { return (p === 'P' ? 'Tap ' : 'tap ') + k }],
    [/press the arrow keys the Colonel calls out/g, 'tap the arrow buttons the Colonel calls out'],
    [/Press SPACE when the bar is in the green/g, 'Tap SHOOT when the bar is in the green'],
    [/Press SPACE \(or tap the bar\)/g, 'Tap SHOOT (or the bar)'],
    [/Press the arrow key \(or W A S D\) that is called/g, 'Tap the arrow button that is called'],
    [/\b([Tt])ap SPACE (\d+) times/g, '$1ap the big button $2 times'],
    [/\b([Hh])it the arrow keys\b/g, '$1it the arrow buttons'],
    [/SPACE = shoot/g, 'SHOOT button'],
    [/SPACE = tap/g, 'Big button = tap'],
    [/Arrow keys \/ WASD/g, 'Arrow buttons'],
    [/Keys 1-4 or click/g, 'Tap an answer'],
    [/E \/ click: next/g, 'Tap the box or E: next'],
    [/Try again \(Enter\)/g, 'Try again'],
    [/CLICK ANYWHERE TO START/g, 'TAP ANYWHERE TO START']
  ];
  function fixText(s) { for (var i = 0; i < RULES.length; i++) s = s.replace(RULES[i][0], RULES[i][1]); return s }
  function fixNode(n) {
    if (n.nodeType === 3) {
      var v = n.nodeValue; if (v.length < 6) return;
      var t = fixText(v); if (t !== v) n.nodeValue = t;
    } else if (n.nodeType === 1 && n.tagName !== 'SCRIPT' && n.tagName !== 'STYLE' && n.tagName !== 'CANVAS') {
      for (var c = n.firstChild; c; c = c.nextSibling) fixNode(c);
    }
  }

  function ready() {
    var b = document.body; b.classList.add('touch');

    var r = document.createElement('div'); r.id = 'rotate'; r.setAttribute('data-testid', 'rotate-to-landscape'); r.setAttribute('role', 'status');
    r.innerHTML = '<svg viewBox="0 0 64 64" fill="none" stroke="#fff" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">' +
      '<rect x="20" y="6" width="24" height="46" rx="5"/><path d="M29 46h6"/><path d="M8 40c0 10 7 16 16 17M52 24c0-10-7-16-16-17"/><path d="M20 53l4 4-4 4M44 11l-4-4 4-4"/></svg>' +
      '<b>Rotate your phone</b><span>ANITS plays in landscape mode</span>';
    b.appendChild(r);

    // Keep the mission compact while exploring, with the full objective one tap away.
    var mission = document.getElementById('mis');
    if (mission) {
      mission.setAttribute('data-testid', 'mission-panel');
      var more = document.createElement('button');
      more.id = 'mission-expand'; more.type = 'button';
      more.setAttribute('data-testid', 'mission-expand-button');
      more.setAttribute('aria-label', 'Show full mission');
      more.setAttribute('aria-expanded', 'false');
      more.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m7 10 5 5 5-5"/></svg>';
      mission.appendChild(more);
      more.addEventListener('click', function (e) {
        e.stopPropagation();
        var expanded = mission.classList.toggle('expanded');
        more.setAttribute('aria-expanded', String(expanded));
        more.setAttribute('aria-label', expanded ? 'Collapse mission' : 'Show full mission');
      });
    }

    /* no scrolling / zooming / long-press menu while playing (menus and panels that scroll are exempt) */
    var OK = '#menu,#inv,#mini,#shop,#dlg,#set,#pz,input,textarea';
    document.addEventListener('touchmove', function (e) {
      var t = e.target; if (t && t.closest && t.closest(OK)) return;
      e.preventDefault();
    }, { passive: false });
    ['gesturestart', 'gesturechange', 'contextmenu'].forEach(function (t) { document.addEventListener(t, function (e) { e.preventDefault() }) });

    fixNode(b);
    new MutationObserver(function (ms) {
      for (var i = 0; i < ms.length; i++) {
        var m = ms[i];
        if (m.type === 'characterData') { if (m.target.nodeType === 3) fixNode(m.target) }
        else for (var j = 0; j < m.addedNodes.length; j++) fixNode(m.addedNodes[j]);
      }
    }).observe(b, { childList: true, characterData: true, subtree: true });

    /* iPhone Safari has no full-screen API: point people at "Add to Home Screen" once */
    if (ios && !canFS && !standalone) {
      var seen = false; try { seen = localStorage.getItem('anits-a2hs'); localStorage.setItem('anits-a2hs', '1') } catch (e) {}
      if (!seen) {
        var h = document.createElement('div'); h.id = 'a2hs';
        h.innerHTML = 'For true full screen: tap <b>Share</b> &rarr; <b>Add to Home Screen</b>, then open ANITS from your home screen.';
        b.appendChild(h); h.onclick = function () { h.remove() }; setTimeout(function () { h.remove() }, 11000);
      }
    }
    fsChange();
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', ready); else ready();
})();
