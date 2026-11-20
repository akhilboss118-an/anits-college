/* Interactive first-time tutorial: guided main-menu tour + in-game "how to play" lesson.
   Public API: window.__tutorial.startMenu(force), startGame(force). Flags live in localStorage (anits-tut-*). */
(function () {
  'use strict';
  var LS = window.localStorage, $ = function (id) { return document.getElementById(id) };
  var flag = function (k) { try { return LS.getItem('anits-tut-' + k) === '1' } catch (e) { return false } };
  var setFlag = function (k) { try { LS.setItem('anits-tut-' + k, '1') } catch (e) {} };
  var touch = function () { return document.body.classList.contains('touch') };

  var root = document.createElement('div');
  root.id = 'tut'; root.setAttribute('data-testid', 'tutorial-overlay');
  root.innerHTML = '<div class="tb" data-p="0"></div><div class="tb" data-p="1"></div><div class="tb" data-p="2"></div><div class="tb" data-p="3"></div>' +
    '<div class="tr" data-testid="tutorial-highlight"></div>' +
    '<div class="tc" role="dialog" aria-live="polite" data-testid="tutorial-card"><div class="tn" data-testid="tutorial-step-count"></div><h3 data-testid="tutorial-title"></h3><p data-testid="tutorial-text"></p><div class="th" data-testid="tutorial-hint"></div>' +
    '<div class="tf"><button type="button" class="tx" data-testid="tutorial-skip-btn"></button><button type="button" class="tp" data-testid="tutorial-next-btn"></button></div></div>';
  document.body.appendChild(root);
  ['pointerdown', 'mousedown', 'touchstart', 'click'].forEach(function (ev) { root.addEventListener(ev, function (e) { e.stopPropagation() }) });

  var blockers = [].slice.call(root.querySelectorAll('.tb')), ring = root.querySelector('.tr'), card = root.querySelector('.tc');
  var elN = card.querySelector('.tn'), elT = card.querySelector('h3'), elP = card.querySelector('p'), elH = card.querySelector('.th');
  var btnSkip = card.querySelector('.tx'), btnNext = card.querySelector('.tp');

  var S = null;

  function visibleRect(sel) {
    var el = typeof sel === 'string' ? document.querySelector(sel) : sel;
    if (!el) return null;
    var cs = getComputedStyle(el);
    if (cs.display === 'none' || cs.visibility === 'hidden') return null;
    var r = el.getBoundingClientRect();
    return r.width > 2 && r.height > 2 ? r : null;
  }
  function unionRect(list) {
    var rs = (list || []).map(visibleRect).filter(Boolean);
    if (!rs.length) return null;
    var l = Math.min.apply(0, rs.map(function (r) { return r.left })), t = Math.min.apply(0, rs.map(function (r) { return r.top }));
    var rt = Math.max.apply(0, rs.map(function (r) { return r.right })), b = Math.max.apply(0, rs.map(function (r) { return r.bottom }));
    return { left: l, top: t, right: rt, bottom: b, width: rt - l, height: b - t };
  }
  function box(el, l, t, w, h) { el.style.left = l + 'px'; el.style.top = t + 'px'; el.style.width = Math.max(0, w) + 'px'; el.style.height = Math.max(0, h) + 'px'; el.style.display = w > 0 && h > 0 ? 'block' : 'none' }

  function layout() {
    if (!S) return;
    var st = S.steps[S.i], W = innerWidth, H = innerHeight, pad = 6;
    var r0 = unionRect(st.t), r = r0 && { left: Math.max(0, r0.left - pad), top: Math.max(0, r0.top - pad), right: Math.min(W, r0.right + pad), bottom: Math.min(H, r0.bottom + pad) };
    if (r) { r.width = r.right - r.left; r.height = r.bottom - r.top }
    blockers.forEach(function (b) { b.classList.toggle('clear', !!st.act) });
    if (r) {
      ring.style.display = 'block'; box(ring, r.left, r.top, r.width, r.height); ring.style.display = 'block';
      if (st.act || st.pass) blockers.forEach(function (b) { b.style.display = 'none' });
      else {
        box(blockers[0], 0, 0, W, r.top); box(blockers[1], 0, r.bottom, W, H - r.bottom);
        box(blockers[2], 0, r.top, r.left, r.height); box(blockers[3], r.right, r.top, W - r.right, r.height);
      }
    } else {
      ring.style.display = 'none';
      blockers.forEach(function (b, k) { k === 0 && !st.act ? box(b, 0, 0, W, H) : (b.style.display = 'none') });
    }
    var cw = card.offsetWidth, ch = card.offsetHeight, m = 8, x, y;
    if (!r) { x = (W - cw) / 2; y = (H - ch) / 2 }
    else {
      var cx = Math.min(Math.max(m, (r.left + r.right) / 2 - cw / 2), W - cw - m), cy = Math.min(Math.max(m, (r.top + r.bottom) / 2 - ch / 2), H - ch - m);
      var opts = [[cx, r.bottom + 12], [cx, r.top - ch - 12], [r.right + 12, cy], [r.left - cw - 12, cy]];
      var ok = opts.filter(function (o) { return o[0] >= m && o[1] >= m && o[0] + cw <= W - m && o[1] + ch <= H - m })[0];
      if (ok) { x = ok[0]; y = ok[1] }
      else { x = (W - cw) / 2; y = (r.top + r.bottom) / 2 < H / 2 ? H - ch - m : m }
    }
    card.style.left = Math.round(x) + 'px'; card.style.top = Math.round(y) + 'px';
  }

  function cleanup() {
    if (!S) return;
    S.off.forEach(function (f) { f() }); S.off = [];
    clearTimeout(S.adv);
  }

  function render() {
    var st = S.steps[S.i], last = S.i === S.steps.length - 1;
    cleanup();
    elN.textContent = 'STEP ' + (S.i + 1) + ' OF ' + S.steps.length;
    elT.textContent = st.title;
    elP.innerHTML = typeof st.text === 'function' ? st.text() : st.text;
    btnSkip.textContent = st.act ? 'SKIP STEP' : (last ? '' : 'SKIP TUTORIAL');
    btnSkip.style.visibility = btnSkip.textContent ? 'visible' : 'hidden';
    btnNext.style.display = st.act ? 'none' : '';
    btnNext.textContent = last ? (S.kind === 'game' ? "LET'S PLAY" : 'GOT IT') : 'NEXT';
    elH.className = 'th'; elH.textContent = st.act ? (touch() ? 'TRY IT NOW' : 'TRY IT NOW') : '';
    elH.style.display = st.act ? '' : 'none';
    if (S.kind === 'game' && !st.act && !touch()) { try { document.exitPointerLock() } catch (e) {} }
    if (st.act) st.act(function () { done() });
    card.style.animation = 'none'; void card.offsetWidth; card.style.animation = '';
    layout();
  }

  function done() {
    if (!S || S.waiting) return;
    S.waiting = true; elH.className = 'th ok'; elH.textContent = 'NICE!';
    S.adv = setTimeout(function () { S.waiting = false; go(1) }, 650);
  }
  function go(d) {
    if (!S) return;
    S.waiting = false;
    S.i += d;
    if (S.i >= S.steps.length) return end(true);
    render();
  }
  function end(finished) {
    if (!S) return;
    cleanup();
    var k = S.kind, tl0 = S.tl0;
    if (k === 'game') {
      setFlag('game'); window.__tut = false;
      if (window.__TL && !window.__TL.over && tl0 != null) window.__TL.left = tl0;
    }
    if (k === 'menu') setFlag('menu');
    if (k === 'lvl') setFlag('lvl');
    cancelAnimationFrame(S.raf); S = null; root.classList.remove('on');
  }

  btnNext.onclick = function () { go(1) };
  btnSkip.onclick = function () { S && S.steps[S.i].act ? go(1) : end(false) };

  function listen(target, ev, fn, opts) { target.addEventListener(ev, fn, opts); return function () { target.removeEventListener(ev, fn, opts) } }

  function actKey(codes) {
    return function (finish) {
      var off = listen(document, 'keydown', function (e) { if (codes.indexOf(e.code) >= 0) { off(); finish() } }, true);
      S.off.push(off);
    };
  }
  function actTouchIn(sel, delay) {
    return function (finish) {
      var off = listen(document, 'pointerdown', function (e) {
        if (e.target.closest && e.target.closest(sel)) { off(); setTimeout(finish, delay || 400) }
      }, true);
      S.off.push(off);
    };
  }
  function actLook(finish) {
    var down = false, n = 0, acc = 0;
    var o1 = listen(document, 'pointerdown', function (e) {
      var t = e.target, inLook = t.closest && t.closest('#tcjR');
      down = !!(inLook || (t.tagName === 'CANVAS' && t.id !== 'mc')); n = 0;
    }, true);
    var o2 = listen(document, 'pointermove', function (e) {
      if (touch()) { if (down && ++n > 4) { clean(); finish() } return }
      var mv = Math.abs(e.movementX || 0) + Math.abs(e.movementY || 0);
      if ((document.pointerLockElement || down) && (acc += mv) > 120) { clean(); finish() }
    }, true);
    var o3 = listen(document, 'pointerup', function () { down = false }, true);
    function clean() { o1(); o2(); o3() }
    S.off.push(clean);
  }

  function gameSteps() {
    var t = touch;
    return [
      { title: 'Welcome to ANITS!', t: [], text: function () { return 'A quick hands-on lesson, about a minute. <b>Your class timer is paused</b> while you learn.' } },
      { title: 'Move around', t: ['#tcd'], act: function (f) { (t() ? actTouchIn('#tcz,#tcd,#tcd-knob', 450) : actKey(['KeyW', 'KeyA', 'KeyS', 'KeyD', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight']))(f) },
        text: function () { return t() ? 'Put your thumb on the <b>MOVE</b> pad (bottom left) and drag to walk.' : 'Press <kbd>W</kbd> <kbd>A</kbd> <kbd>S</kbd> <kbd>D</kbd> to walk.' } },
      { title: 'Look around', t: ['#tcjR'], act: actLook,
        text: function () { return t() ? 'Drag your thumb on the <b>LOOK</b> pad (bottom right), or swipe anywhere on the world.' : 'Click the game, then move your mouse to look around.' } },
      { title: 'Run', t: ['#tcR'], act: function (f) { (t() ? actTouchIn('#tcR', 100) : actKey(['ShiftLeft', 'ShiftRight']))(f) },
        text: function () { return t() ? 'Tap <b>RUN</b> to sprint. Running uses energy, so use it wisely.' : 'Press <kbd>Shift</kbd> to sprint. Running uses energy.' } },
      { title: 'Class timer', t: ['#time-hud'], text: 'This is the <b>class timer</b>. Finish your missions and be seated in class before it hits 0:00. It turns <b style="color:#ff6b6b">red</b> in the last minute.' },
      { title: 'Your mission', t: ['#mis'], text: function () { return 'Your current objective is always here.' + (t() ? ' Tap the small arrow on the card to read it in full.' : '') } },
      { title: 'Energy & money', t: ['#en', '#wal'], text: 'Energy drops as you run. Buy drinks at the canteen to refill it. Your wallet shows what you can spend.' },
      { title: 'Minimap', t: ['#mm'], text: 'Shows where you are and where to go. <b>Follow the marker</b> to reach your next mission.' },
      { title: 'Talk & use', t: [], text: function () { return t() ? 'Walk up to a person or object and a <b>TALK / USE</b> button appears on the right. Near NCC cadets a <b>SALUTE</b> button shows up too.' : 'Walk up to a person or object and press <kbd>E</kbd> to talk or use it. Near NCC cadets press <kbd>G</kbd> to salute.' } },
      { title: 'Bag & pause', t: ['#tcB', '#inv-btn', '#pz-btn'], pass: true, text: function () { return (t() ? 'Open your <b>BAG</b> to see items you collect. ' : 'Press <kbd>B</kbd> for your <b>bag</b>. ') + 'The <b>pause</b> button (' + (t() ? 'top' : '<kbd>Esc</kbd> / <kbd>P</kbd>') + ') opens the menu, where <b>HOW TO PLAY</b> replays this lesson.' } }
    ];
  }
  function menuSteps() {
    return [
      { title: 'Start Game', t: ['#b-start'], text: 'Opens the <b>level select</b>. Play each Day of ANITS in order; finishing one unlocks the next.' },
      { title: 'Attendance', t: ['#b-att'], text: 'Your attendance record. Reach class on time to keep it high.' },
      { title: 'Settings', t: ['#b-set'], text: 'Voice volume, graphics quality, change player, and reset progress.' },
      { title: 'How to Play', t: ['#b-how'], text: 'Replay this tour any time. Inside a level, open <b>Pause &rarr; HOW TO PLAY</b> for the hands-on controls lesson.' }
    ];
  }
  function lvlSteps() {
    return [{ title: 'Pick a Day', t: ['#grid'], pass: true, text: 'Tap an <b>unlocked Day</b> card to begin. Locked days open once you finish the previous one.' }];
  }

  function start(kind, steps, extra) {
    if (S) end(false);
    S = { kind: kind, steps: steps, i: 0, off: [], waiting: false, adv: 0, tl0: null, raf: 0 };
    if (kind === 'game') {
      window.__tut = true; try { document.exitPointerLock() } catch (e) {}
      S.tl0 = window.__TL ? window.__TL.left : null;
    }
    if (kind === 'lvl') S.off.push(listen(document, 'click', function (e) { if (e.target.closest && e.target.closest('#grid,#lv-back')) end(false) }, true));
    root.classList.add('on');
    (function tick() {
      if (!S) return;
      if (S.kind === 'game' && S.tl0 != null && window.__TL && !window.__TL.over) window.__TL.left = S.tl0;
      layout();
      S.raf = requestAnimationFrame(tick);
    })();
    render();
  }

  function startMenu(force) {
    var m = $('s-main');
    if (!m || !m.classList.contains('show')) return;
    if (!force && flag('menu')) return;
    setFlag('menu'); start('menu', menuSteps());
  }
  function startGame(force) {
    if ((!force && flag('game')) || window.__LVL === 8) return;
    start('game', gameSteps());
  }
  window.__tutorial = { startMenu: startMenu, startGame: startGame, reset: function () { ['menu', 'lvl', 'game'].forEach(function (k) { try { LS.removeItem('anits-tut-' + k) } catch (e) {} }) } };

  document.addEventListener('keydown', function (e) {
    if (!S) return;
    var st = S.steps[S.i];
    if (e.code === 'Escape') { e.preventDefault(); e.stopImmediatePropagation(); end(false) }
    else if ((e.code === 'Enter' || e.code === 'NumpadEnter') && !st.act) { e.preventDefault(); e.stopImmediatePropagation(); go(1) }
  }, true);

  /* menu hooks: auto-start the tour on the first visit to the main menu / level select */
  function watchMenu() {
    var menu = $('menu'), seenMain = false, seenLvl = false;
    if (!menu) return;
    new MutationObserver(function () {
      var m = $('s-main'), l = $('s-levels');
      var mainOn = m && m.classList.contains('show'), lvlOn = l && l.classList.contains('show');
      if (mainOn && !seenMain) { seenMain = true; if (!flag('menu')) setTimeout(function () { if (!S && !flag('menu')) startMenu(false) }, 1100) }
      if (!mainOn) seenMain = false;
      if (lvlOn && !seenLvl) { seenLvl = true; if (!flag('lvl') && flag('menu')) setTimeout(function () { var ll = $('s-levels'); if (!S && ll && ll.classList.contains('show') && !flag('lvl')) { setFlag('lvl'); start('lvl', lvlSteps()) } }, 900) }
      if (!lvlOn) seenLvl = false;
    }).observe(menu, { attributes: true, attributeFilter: ['class'], subtree: true });
  }
  watchMenu();

  /* in-game: first press of Start / Continue opens the lesson once the world is visible */
  var go0 = $('go');
  if (go0) go0.addEventListener('click', function () {
    if (flag('game') || go0.disabled) return;
    var label = go0.textContent;
    if (label !== 'Start' && label !== 'Continue') return;
    setTimeout(function () { var ov = $('ov'); if (!S && ov && ov.style.display === 'none') startGame(false) }, 900);
  });
})();
