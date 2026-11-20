/* Pause menu + in-game settings (loaded from index.html BEFORE the game, so Esc / P reach it first).
   Button (top corner) or Esc / P  ->  RESUME, RESTART LEVEL, LEVEL SELECT, SETTINGS (voice, effects, look speed).
   Pausing sets window.__paused (game.js frame loops, mini-games, subtitle timers and voices all check / listen to it)
   and fires 'anits-pause' / 'anits-resume' events. Restart and Level Select reload the page through the existing
   sessionStorage 'anits-go' hand-off that js/menu.js already understands. */
(function () {
  'use strict';
  var $ = function (id) { return document.getElementById(id) }, LS = window.localStorage;
  var num = function (k, d) { var v = LS.getItem(k); return v == null ? d : +v };
  window.__SUBLANG = LS.getItem('anits-sublang') === 'te' ? 'te' : 'en';
  window.__VOL = num('anits-vol', 1); window.__SFX = num('anits-sfx', 1); window.__LOOK = num('anits-look', 1);

  var SHOW = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round"><path d="M8 5v14M16 5v14"/></svg>';
  var btn = document.createElement('button');
  btn.id = 'pz-btn'; btn.setAttribute('data-testid', 'pause-btn'); btn.setAttribute('aria-label', 'Pause'); btn.innerHTML = SHOW;
  var pz = document.createElement('div');
  pz.id = 'pz'; pz.setAttribute('data-testid', 'pause-menu');
  pz.innerHTML =
    '<div class="pzb" id="pz-main" data-testid="pause-main">' +
      '<div class="pzh"><b>PAUSED</b><small id="pz-lv" data-testid="pause-level-name"></small></div>' +
      '<div class="pzg">' +
        '<button class="pzp" id="pz-resume" data-testid="pause-resume-btn">RESUME</button>' +
        '<button id="pz-restart" data-testid="pause-restart-btn">RESTART LEVEL</button>' +
        '<button id="pz-levels" data-testid="pause-level-select-btn">LEVEL SELECT</button>' +
        '<button class="pzw" id="pz-how" data-testid="pause-how-to-play-btn">HOW TO PLAY</button>' +
        '<button class="pzw" id="pz-set" data-testid="pause-settings-btn">SETTINGS</button>' +
      '</div>' +
      '<div class="pzk" id="pz-keys"><kbd>W</kbd><kbd>A</kbd><kbd>S</kbd><kbd>D</kbd> move &middot; <kbd>Shift</kbd> run &middot; <kbd>E</kbd> talk / use &middot; <kbd>G</kbd> salute &middot; <kbd>B</kbd> bag &middot; <kbd>Esc</kbd> / <kbd>P</kbd> pause</div>' +
    '</div>' +
    '<div class="pzb" id="pz-settings" data-testid="pause-settings" hidden>' +
      '<div class="pzh"><b>SETTINGS</b></div>' +
      '<label>VOICE VOLUME<input type="range" min="0" max="100" id="pz-vol" data-testid="pause-voice-slider"></label>' +
      '<label>EFFECTS VOLUME<input type="range" min="0" max="100" id="pz-sfx" data-testid="pause-effects-slider"></label>' +
      '<label>LOOK SPEED<input type="range" min="40" max="200" id="pz-look" data-testid="pause-look-slider"></label>' +
      '<label>SUBTITLES<span class="pzl"><button id="pz-en" data-testid="pause-subs-english-btn">ENGLISH</button><button id="pz-te" data-testid="pause-subs-telugu-btn">\u0C24\u0C46\u0C32\u0C41\u0C17\u0C41 TELUGU</button></span></label>' +
      '<div class="pzg one"><button class="pzp" id="pz-back" data-testid="pause-settings-back-btn">DONE</button></div>' +
    '</div>' +
    '<div class="pzb" id="pz-confirm" data-testid="pause-confirm" hidden>' +
      '<div class="pzh"><b id="pz-ct"></b></div><p id="pz-cq"></p>' +
      '<div class="pzg"><button id="pz-no" data-testid="pause-confirm-cancel-btn">CANCEL</button><button class="pzp" id="pz-yes" data-testid="pause-confirm-yes-btn">YES</button></div>' +
    '</div>';

  var wasLocked = false, pending = null;
  function view(name) {
    ['main', 'settings', 'confirm'].forEach(function (v) { $('pz-' + v).hidden = v !== name });
    pz.setAttribute('data-view', name);
  }
  var gameOn = function () {
    var ov = $('ov'), mn = $('menu');
    return !!(window.__g && ov && ov.style.display === 'none' && mn && mn.style.display === 'none' && !window.__call && !window.__tut);
  };
  var invOpen = function () { var i = $('inv'); return !!(i && i.style.display === 'flex') };
  var shopOpen = function () { return !!(window.__g && window.__g.shopOpen) };

  function open() {
    if (window.__paused || !gameOn()) return;
    window.__paused = true; document.body.classList.add('paused');
    var g = window.__g, info = window.__LVINFO && window.__LVINFO[g.lvl - 1];
    $('pz-lv').textContent = 'DAY ' + g.lvl + (info ? ' \u00B7 ' + info.n.toUpperCase() : '');
    view('main'); pz.classList.add('on');
    try { document.exitPointerLock && document.exitPointerLock() } catch (e) {}
    dispatchEvent(new Event('anits-pause'));
    setTimeout(function () { $('pz-resume').focus({ preventScroll: true }) }, 30);
  }
  function close() {
    if (!window.__paused) return;
    window.__paused = false; document.body.classList.remove('paused'); pz.classList.remove('on');
    document.activeElement && document.activeElement.blur && document.activeElement.blur();
    dispatchEvent(new Event('anits-resume'));
  }
  window.__pause = { open: open, close: close, get on() { return window.__paused } };

  function go(hand, keepLvl) {
    if (!LS.getItem('anits-profile')) { try { LS.setItem('anits-profile', JSON.stringify({ name: (window.__PROFILE && window.__PROFILE.name) || 'Player', char: window.__CHAR || 'boy', year: window.__YEAR || 2024 })) } catch (e) {} }   // started from a ?lvl= link: no saved player yet
    sessionStorage.setItem('anits-go', hand);
    var u = new URL(location.href);
    if (!keepLvl) u.searchParams.delete('lvl');
    location.replace(u.toString());
  }
  function ask(kind) {
    pending = kind;
    var lv = window.__g.lvl;
    $('pz-ct').textContent = kind === 'restart' ? 'RESTART DAY ' + lv + '?' : 'LEAVE TO LEVEL SELECT?';
    $('pz-cq').textContent = kind === 'restart' ? 'You will start this level again from the beginning.' : 'Your progress in this level is saved. You can continue it later.';
    $('pz-yes').textContent = kind === 'restart' ? 'RESTART' : 'LEAVE';
    view('confirm');
  }

  function slider(id, get, set, key, scale) {
    var el = $(id); el.value = Math.round(get() * scale);
    el.oninput = function () { var v = el.value / scale; set(v); try { LS.setItem(key, v) } catch (e) {} };
  }

  function build() {
    document.body.appendChild(btn); document.body.appendChild(pz);
    btn.onclick = function () { window.__paused ? close() : open() };
    $('pz-resume').onclick = close;
    $('pz-how').onclick = function () { close(); window.__tutorial && window.__tutorial.startGame(true) };
    $('pz-set').onclick = function () { view('settings') };
    $('pz-back').onclick = function () { view('main') };
    $('pz-restart').onclick = function () { ask('restart') };
    $('pz-levels').onclick = function () { ask('levels') };
    $('pz-no').onclick = function () { view('main') };
    $('pz-yes').onclick = function () {
      var lv = window.__g.lvl;
      if (pending === 'restart') { try { window.OfflineSave && window.OfflineSave.halt() } catch (e) {} go('lvl' + lv, true) }
      else { try { window.OfflineSave && window.OfflineSave.saveNow() } catch (e) {} go('levels', false) }
    };
    slider('pz-vol', function () { return window.__VOL }, function (v) { window.__VOL = v }, 'anits-vol', 100);
    slider('pz-sfx', function () { return window.__SFX }, function (v) { window.__SFX = v }, 'anits-sfx', 100);
    slider('pz-look', function () { return window.__LOOK }, function (v) { window.__LOOK = v }, 'anits-look', 100);
    var lang = function () { $('pz-en').classList.toggle('on', window.__SUBLANG === 'en'); $('pz-te').classList.toggle('on', window.__SUBLANG === 'te') };
    ['en', 'te'].forEach(function (l) { $('pz-' + l).onclick = function () { window.__SUBLANG = l; try { LS.setItem('anits-sublang', l) } catch (e) {} lang() } });
    lang();
    pz.addEventListener('pointerdown', function (e) { e.stopPropagation() });
    setInterval(function () { btn.style.display = (gameOn() || window.__paused) && !invOpen() ? 'flex' : 'none' }, 250);
  }
  if (document.body) build(); else document.addEventListener('DOMContentLoaded', build);

  /* Esc / P (capture phase, runs before every game handler) */
  addEventListener('keydown', function (e) {
    var t = e.target, typing = t && /^(INPUT|TEXTAREA)$/.test(t.tagName) && t.type !== 'range';
    if (window.__paused) {
      if (typing) return;
      if (e.code === 'Escape' || e.code === 'KeyP') {
        e.preventDefault();
        if (pz.getAttribute('data-view') !== 'main') view('main'); else close();
      }
      e.stopImmediatePropagation(); return;   // the game must not react while paused
    }
    if (typing || (e.code !== 'Escape' && e.code !== 'KeyP')) return;
    if (e.code === 'Escape' && (shopOpen() || invOpen())) return;   // Esc closes those first
    if (!gameOn() || e.repeat) return;
    e.preventDefault(); e.stopImmediatePropagation(); open();
  }, true);

  /* the browser frees the mouse on Esc (no key event reaches the page): treat that as "pause" */
  document.addEventListener('pointerlockchange', function () {
    if (document.pointerLockElement) { wasLocked = true; return }
    if (!wasLocked) return; wasLocked = false;
    setTimeout(function () {
      if (!window.__paused && gameOn() && !shopOpen() && !invOpen() && !(window.__mini && window.__mini.active)) open();
    }, 80);
  });
  /* leaving the tab / app also pauses */
  document.addEventListener('visibilitychange', function () { if (document.hidden && gameOn() && !shopOpen()) open() });
})();
