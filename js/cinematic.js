/* Cinematic studio intro. Self-contained: DOM, CSS and synthesized audio live here. Edit CONFIG to change text and timings. */
(function () {
  'use strict';

  var CONFIG = {
    text: { studio: 'A Little Heart Production', dev: 'Developed by akhilboss', gate: 'Tap to begin', skip: 'Skip' },
    storageKey: 'lhp-cinematic-seen',
    mutedKey: 'lhp-cinematic-muted',
    replay: 'short',
    skipButtonDelay: 1000,
    accent: '#2a8cff',
    logo: 'assets/img/anits_logo.png',
    mark: 'assets/img/little_hearts_logo.png',
    logoAlt: 'ANITS - Pragnanam Brahma',
    grain: true,
    timeline: {
      full:    { bars: { at: 0, dur: 1400 }, logo: { at: 1000, dur: 3300 }, mark: { at: 4100, dur: 2000 }, studio: { at: 5400, dur: 1700 }, dev: { at: 7000, dur: 1600 }, out: { at: 9800, dur: 1200 } },
      short:   { bars: { at: 0, dur: 500 },  logo: { at: 150, dur: 1500 },  mark: { at: 1500, dur: 600 },  studio: { at: 1800, dur: 600 },  dev: { at: 2300, dur: 600 },  out: { at: 3400, dur: 700 } },
      reduced: { bars: { at: 0, dur: 0 },    logo: { at: 0, dur: 2200 },    mark: { at: 2300, dur: 800 },  studio: { at: 2800, dur: 800 },  dev: { at: 3600, dur: 800 },  out: { at: 5000, dur: 800 } }
    },
    audio: { peak: 0.5, attack: 3.5, hum: 0.5, thud: 0.9 }
  };

  var qs = new URLSearchParams(location.search);
  var store = { get: function (k) { try { return localStorage.getItem(k); } catch (e) { return null; } }, set: function (k, v) { try { localStorage.setItem(k, v); } catch (e) {} } };
  var listeners = [];
  var API = { active: false, config: CONFIG, onEnd: function (fn) { API.active ? listeners.push(fn) : fn(); }, skip: function () {} };
  window.LittleHeartIntro = API;

  if (qs.get('intro') === 'reset') { try { localStorage.removeItem(CONFIG.storageKey); } catch (e) {} }
  var forceFull = qs.get('intro') === 'full';
  var seen = !forceFull && store.get(CONFIG.storageKey) === '1';
  var resumeFlow = false;
  try { resumeFlow = !!sessionStorage.getItem('anits-go'); } catch (e) {}
  if (qs.get('nointro') || qs.get('lvl') || qs.get('skip') || resumeFlow) return;
  if (seen && CONFIG.replay === 'skip') return;

  var reduced = !!(window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches);
  var gated = !(seen && CONFIG.replay === 'short');
  var mode = reduced ? 'reduced' : (seen && CONFIG.replay === 'short' ? 'short' : 'full');
  var TL = CONFIG.timeline[mode];
  var TOTAL = TL.out.at + TL.out.dur;
  var CSS = [
    '#lhi{position:fixed;inset:0;z-index:2147483000;background:#050506;color:#f4ece8;overflow:hidden;font-family:"Iowan Old Style","Palatino Linotype",Palatino,"Book Antiqua",Georgia,serif;-webkit-user-select:none;user-select:none;touch-action:manipulation;cursor:default}',
    '#lhi.lhi-fade{opacity:0;pointer-events:none;transition:opacity var(--out-dur) cubic-bezier(.4,0,.2,1)}',
    '#lhi *{box-sizing:border-box}',
    '#lhi button,#lhi button:hover:not(:disabled),#lhi button:active:not(:disabled){box-shadow:none;transform:none;filter:none;text-shadow:none}',
    '#lhi .lhi-gate{border-radius:0;outline:none}',
    '#lhi .lhi-vig{position:absolute;inset:0;background:radial-gradient(ellipse at 50% 48%,rgba(40,120,255,.08) 0%,rgba(0,0,0,0) 45%,rgba(0,0,0,.65) 100%);pointer-events:none}',
    '#lhi .lhi-bar{position:absolute;left:0;right:0;height:var(--bar);background:#000;z-index:3}',
    '#lhi .lhi-top{top:0;transform:translateY(-100%)}#lhi .lhi-bot{bottom:0;transform:translateY(100%)}',
    '#lhi.lhi-play .lhi-top,#lhi.lhi-play .lhi-bot{animation:lhi-bar var(--bars-dur) var(--bars-at) cubic-bezier(.65,0,.25,1) both}',
    '#lhi .lhi-stage{position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center;text-align:center;padding:calc(var(--bar) + 2vh) 6vw;gap:clamp(14px,3.2vmin,30px)}',
    '#lhi .lhi-mark,#lhi .lhi-studio,#lhi .lhi-dev,#lhi .lhi-logo{opacity:0}',
    '#lhi .lhi-logo{position:absolute;left:50%;top:50%;z-index:2;width:min(70vw,calc(66vh - 20px),460px);aspect-ratio:500/499;margin:0;transform:translate(-50%,-50%);pointer-events:none}',
    '#lhi .lhi-logo img{position:absolute;inset:0;width:100%;height:100%;display:block;filter:drop-shadow(0 0 22px rgba(200,225,255,.22))}',
    '#lhi .lhi-logo i{position:absolute;inset:0;display:block;-webkit-mask:var(--logo-url) center/100% 100% no-repeat;mask:var(--logo-url) center/100% 100% no-repeat;background:linear-gradient(105deg,rgba(255,255,255,0) 38%,rgba(255,236,230,.95) 50%,rgba(255,255,255,0) 62%) -140% 0/220% 100% no-repeat}',
    '#lhi.lhi-play .lhi-logo{animation:lhi-logo var(--logo-dur) var(--logo-at) linear both}',
    '#lhi.lhi-play .lhi-logo i{animation:lhi-glint calc(var(--logo-dur) * .5) calc(var(--logo-at) + var(--logo-dur) * .22) ease-in-out both}',
    '#lhi.lhi-rm .lhi-logo{animation-name:lhi-logo-rm!important}#lhi.lhi-rm .lhi-logo i{display:none}',
    '#lhi .lhi-fx{position:absolute;left:-50%;top:-50%;width:200%;height:200%;z-index:4;pointer-events:none;opacity:.07;mix-blend-mode:screen;background-image:url("data:image/svg+xml;utf8,<svg xmlns=\'http://www.w3.org/2000/svg\' width=\'220\' height=\'220\'><filter id=\'n\'><feTurbulence type=\'fractalNoise\' baseFrequency=\'.85\' numOctaves=\'2\' stitchTiles=\'stitch\'/><feColorMatrix values=\'0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 1.4 -.25\'/></filter><rect width=\'100%25\' height=\'100%25\' filter=\'url(%23n)\'/></svg>");animation:lhi-grain .9s steps(1) infinite}',
    '#lhi .lhi-flick{position:absolute;inset:0;z-index:4;pointer-events:none;background:#000;opacity:0;animation:lhi-flick 6.3s linear infinite}',
    '#lhi.lhi-rm .lhi-fx,#lhi.lhi-rm .lhi-flick{display:none}',
    '#lhi .lhi-mark{position:relative;width:clamp(90px,min(26vmin,300px),300px);aspect-ratio:720/644}',
    '#lhi .lhi-mark img{position:absolute;inset:0;width:100%;height:100%;display:block;filter:brightness(1.18) saturate(1.1) drop-shadow(0 0 20px rgba(42,140,255,.55))}',
    '#lhi .lhi-mark i{position:absolute;inset:0;display:block;-webkit-mask:var(--mark-url) center/100% 100% no-repeat;mask:var(--mark-url) center/100% 100% no-repeat;background:linear-gradient(105deg,rgba(255,255,255,0) 38%,rgba(210,235,255,.95) 50%,rgba(255,255,255,0) 62%) -140% 0/220% 100% no-repeat}',
    '#lhi.lhi-play .lhi-mark{animation:lhi-mark var(--mark-dur) var(--mark-at) cubic-bezier(.3,.6,.2,1) both}',
    '#lhi.lhi-play .lhi-mark i{animation:lhi-glint 1.8s calc(var(--mark-at) + var(--mark-dur) + 300ms) ease-in-out both}',
    '#lhi.lhi-rm .lhi-mark i{display:none}',
    '#lhi .lhi-studio{margin:0;font-weight:400;font-size:clamp(15px,min(3.8vw,6vh),38px);letter-spacing:.3em;text-transform:uppercase;line-height:1.5;text-wrap:balance;padding-left:.3em}',
    '#lhi.lhi-play .lhi-studio{animation:lhi-studio var(--studio-dur) var(--studio-at) cubic-bezier(.25,.6,.2,1) both}',
    '#lhi .lhi-dev{margin:0;font-style:italic;font-weight:400;font-size:clamp(12px,min(2.4vw,3.6vh),21px);letter-spacing:.14em;color:rgba(244,236,232,.66)}',
    '#lhi.lhi-play .lhi-dev{animation:lhi-dev var(--dev-dur) var(--dev-at) ease-out both}',
    '#lhi .lhi-gate{position:absolute;inset:0;z-index:5;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:clamp(14px,3vmin,26px);border:0;background:#050506;color:#f4ece8;font:inherit;cursor:pointer;transition:opacity .7s ease;padding:0}',
    '#lhi .lhi-gate span.lhi-gt{font-size:clamp(12px,2.2vmin,18px);letter-spacing:.42em;text-transform:uppercase;padding-left:.42em;animation:lhi-gate 2.8s ease-in-out infinite}',
    '#lhi.lhi-rm .lhi-gate span.lhi-gt{animation:none;opacity:.8}',
    '#lhi.lhi-play .lhi-gate{opacity:0;pointer-events:none}',
    '#lhi .lhi-ctl{position:absolute;z-index:6;right:max(14px,env(safe-area-inset-right));bottom:max(10px,env(safe-area-inset-bottom));display:flex;gap:10px;opacity:0;pointer-events:none;transition:opacity .8s ease}',
    '#lhi .lhi-ctl.lhi-on{opacity:1;pointer-events:auto}',
    '#lhi .lhi-btn{display:inline-flex;align-items:center;justify-content:center;min-height:36px;min-width:36px;padding:0 16px;border-radius:999px;border:1px solid rgba(244,236,232,.28);font-weight:400;background:rgba(0,0,0,.45);color:rgba(244,236,232,.85);font:inherit;font-size:12px;letter-spacing:.24em;text-transform:uppercase;cursor:pointer;transition:background-color .25s ease,border-color .25s ease,color .25s ease}',
    '#lhi .lhi-btn:hover,#lhi .lhi-btn:focus-visible{background:rgba(42,140,255,.2);border-color:var(--accent);color:#fff;outline:none}',
    '#lhi .lhi-mute{padding:0;width:36px}#lhi .lhi-mute svg{width:18px;height:18px}',
    '@keyframes lhi-bar{to{transform:translateY(0)}}',
    '@keyframes lhi-logo{0%{opacity:0;filter:blur(8px);transform:translate(-50%,-50%) scale(1.06)}28%{opacity:1;filter:blur(0)}80%{opacity:1;filter:blur(0)}100%{opacity:0;filter:blur(4px);transform:translate(-50%,-50%) scale(1)}}',
    '@keyframes lhi-mark{from{opacity:0;transform:scale(.92);filter:blur(8px)}to{opacity:1;transform:scale(1);filter:blur(0)}}',
    '@keyframes lhi-logo-rm{0%{opacity:0}25%{opacity:1}80%{opacity:1}100%{opacity:0}}',
    '@keyframes lhi-glint{from{background-position:-140% 0}to{background-position:140% 0}}',
    '@keyframes lhi-grain{0%{transform:translate(0,0)}12%{transform:translate(-7%,5%)}25%{transform:translate(4%,-9%)}37%{transform:translate(-11%,-3%)}50%{transform:translate(9%,8%)}62%{transform:translate(-4%,11%)}75%{transform:translate(12%,-6%)}87%{transform:translate(-9%,-10%)}}',
    '@keyframes lhi-flick{0%,100%{opacity:0}6%{opacity:.05}7%{opacity:0}31%{opacity:0}32%{opacity:.07}34%{opacity:.01}35%{opacity:.05}37%{opacity:0}58%{opacity:.03}59%{opacity:0}81%{opacity:0}82%{opacity:.06}84%{opacity:0}}',
    '@keyframes lhi-studio{from{opacity:0;letter-spacing:.46em}to{opacity:1;letter-spacing:.3em}}',
    '@keyframes lhi-dev{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:translateY(0)}}',
    '@keyframes lhi-gate{0%,100%{opacity:.3}50%{opacity:.9}}',
    '#lhi.lhi-rm .lhi-mark,#lhi.lhi-rm .lhi-studio,#lhi.lhi-rm .lhi-dev{animation-name:lhi-fadeonly!important}',
    '@keyframes lhi-fadeonly{from{opacity:0}to{opacity:1}}'
  ].join('\n');

  var ICON_ON = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M4 9v6h4l5 4V5L8 9z"/><path d="M16.5 8.5a5 5 0 010 7M19 6a8.5 8.5 0 010 12"/></svg>';
  var ICON_OFF = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M4 9v6h4l5 4V5L8 9z"/><path d="M17 9l5 6M22 9l-5 6"/></svg>';

  new Image().src = CONFIG.logo; new Image().src = CONFIG.mark;
  var style = document.createElement('style');
  style.textContent = CSS;
  document.head.appendChild(style);

  var root = document.createElement('div');
  root.id = 'lhi';
  root.setAttribute('role', 'dialog');
  root.setAttribute('aria-label', CONFIG.text.studio);
  root.setAttribute('data-testid', 'cinematic-intro');
  if (reduced) root.classList.add('lhi-rm');
  var vars = { '--accent': CONFIG.accent, '--bar': 'clamp(34px,12vh,150px)', '--out-dur': TL.out.dur + 'ms', '--logo-url': 'url("' + CONFIG.logo + '")', '--mark-url': 'url("' + CONFIG.mark + '")' };
  ['bars', 'logo', 'mark', 'studio', 'dev'].forEach(function (k) { vars['--' + k + '-at'] = TL[k].at + 'ms'; vars['--' + k + '-dur'] = TL[k].dur + 'ms'; });
  Object.keys(vars).forEach(function (k) { root.style.setProperty(k, vars[k]); });
  root.innerHTML =
    '<div class="lhi-vig"></div><div class="lhi-logo" data-testid="cinematic-logo"><img alt="" src="' + CONFIG.logo + '"><i></i></div>' +
    (CONFIG.grain ? '<div class="lhi-fx"></div><div class="lhi-flick"></div>' : '') +
    '<div class="lhi-bar lhi-top"></div><div class="lhi-bar lhi-bot"></div>' +
    '<div class="lhi-stage"><div class="lhi-mark" data-testid="cinematic-mark"><img alt="" src="' + CONFIG.mark + '"><i></i></div>' +
    '<h1 class="lhi-studio" data-testid="cinematic-studio"></h1><p class="lhi-dev" data-testid="cinematic-dev"></p></div>' +
    '<button type="button" class="lhi-gate" data-testid="cinematic-gate"><span class="lhi-gt"></span></button>' +
    '<div class="lhi-ctl"><button type="button" class="lhi-btn lhi-mute" data-testid="cinematic-mute" aria-label="Mute" aria-pressed="false" hidden></button>' +
    '<button type="button" class="lhi-btn lhi-skip" data-testid="cinematic-skip"></button></div>';
  root.querySelector('.lhi-studio').textContent = CONFIG.text.studio;
  root.querySelector('.lhi-dev').textContent = CONFIG.text.dev;
  root.querySelector('.lhi-gt').textContent = CONFIG.text.gate;
  root.querySelector('.lhi-skip').textContent = CONFIG.text.skip;
  document.body.insertBefore(root, document.body.firstChild);
  API.active = true;

  var gate = root.querySelector('.lhi-gate'), ctl = root.querySelector('.lhi-ctl'), muteBtn = root.querySelector('.lhi-mute'), skipBtn = root.querySelector('.lhi-skip');
  var state = gated ? 'gate' : 'idle', beganAt = 0, timers = [], ended = false;
  var audio = null, muted = store.get(CONFIG.mutedKey) === '1';

  function later(fn, ms) { timers.push(setTimeout(fn, ms)); }

  function setMuteUi() {
    muteBtn.innerHTML = muted ? ICON_OFF : ICON_ON;
    muteBtn.setAttribute('aria-pressed', String(muted));
    muteBtn.setAttribute('aria-label', muted ? 'Unmute' : 'Mute');
  }

  function startAudio() {
    var AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return null;
    try {
      var A = CONFIG.audio, ctx = new AC();
      if (ctx.resume) ctx.resume();
      var T = TOTAL / 1000, t0 = ctx.currentTime + 0.05;
      var vol = typeof window.__VOL === 'number' ? Math.max(0, Math.min(1, window.__VOL)) : 1;
      var out = ctx.createGain(); out.gain.value = muted ? 0 : 1; out.connect(ctx.destination);
      var master = ctx.createGain(); master.gain.setValueAtTime(0.0001, t0);
      master.gain.exponentialRampToValueAtTime(Math.max(0.001, A.peak * vol), t0 + A.attack);
      master.gain.setValueAtTime(Math.max(0.001, A.peak * vol), t0 + T - 2.2);
      master.gain.exponentialRampToValueAtTime(0.0001, t0 + T - 0.2);
      master.connect(out);
      var rate = ctx.sampleRate, len = Math.floor(rate * 2.8), buf = ctx.createBuffer(2, len, rate);
      for (var c = 0; c < 2; c++) { var d = buf.getChannelData(c); for (var i = 0; i < len; i++) d[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / len, 2.5); }
      var verb = ctx.createConvolver(); verb.buffer = buf;
      var wet = ctx.createGain(); wet.gain.value = 0.55; verb.connect(wet); wet.connect(master);
      var bus = ctx.createGain(); bus.connect(master); bus.connect(verb);
      var lp = ctx.createBiquadFilter(); lp.type = 'lowpass'; lp.Q.value = 0.5;
      lp.frequency.setValueAtTime(380, t0); lp.frequency.linearRampToValueAtTime(1900, t0 + 6); lp.frequency.linearRampToValueAtTime(700, t0 + T);
      lp.connect(bus);
      var voices = [[110, 'sine', 0.5], [164.81, 'sine', 0.3], [220, 'triangle', 0.16], [261.63, 'sine', 0.15], [329.63, 'sine', 0.13], [493.88, 'sine', 0.06]];
      voices.forEach(function (v, idx) {
        [-5, 5].forEach(function (cents) {
          var o = ctx.createOscillator(), g = ctx.createGain();
          o.type = v[1]; o.frequency.value = v[0]; o.detune.value = cents;
          var s = t0 + 0.4 + idx * 0.55;
          g.gain.setValueAtTime(0.0001, t0); g.gain.setValueAtTime(0.0001, s);
          g.gain.exponentialRampToValueAtTime(v[2] * 0.5, s + 2.6);
          o.connect(g); g.connect(lp); o.start(t0); o.stop(t0 + T + 0.3);
        });
      });
      var fx = ctx.createGain(); fx.gain.value = vol; fx.connect(out);
      var hum = ctx.createGain();
      hum.gain.setValueAtTime(0.0001, t0); hum.gain.exponentialRampToValueAtTime(A.hum, t0 + 1.2);
      hum.gain.setValueAtTime(A.hum, t0 + T - 2); hum.gain.exponentialRampToValueAtTime(0.0001, t0 + T - 0.3);
      hum.connect(fx);
      var nb = ctx.createBuffer(1, rate * 2, rate), nd = nb.getChannelData(0);
      for (var j = 0; j < nd.length; j++) nd[j] = Math.random() * 2 - 1;
      var ns = ctx.createBufferSource(); ns.buffer = nb; ns.loop = true;
      var bp = ctx.createBiquadFilter(); bp.type = 'bandpass'; bp.frequency.value = 1100; bp.Q.value = 0.7;
      var flut = ctx.createGain(); flut.gain.value = 0.012;
      var lfo = ctx.createOscillator(), lfoG = ctx.createGain(); lfo.frequency.value = 24; lfoG.gain.value = 0.009;
      lfo.connect(lfoG); lfoG.connect(flut.gain);
      ns.connect(bp); bp.connect(flut); flut.connect(hum);
      [[50, 0.035], [100, 0.02]].forEach(function (h) {
        var o = ctx.createOscillator(), g = ctx.createGain(); o.type = 'sine'; o.frequency.value = h[0]; g.gain.value = h[1];
        o.connect(g); g.connect(hum); o.start(t0); o.stop(t0 + T + 0.3);
      });
      ns.start(t0); ns.stop(t0 + T + 0.3); lfo.start(t0); lfo.stop(t0 + T + 0.3);
      function bell(sec, freq) {
        var o = ctx.createOscillator(), g = ctx.createGain(), at = t0 + sec;
        o.type = 'sine'; o.frequency.value = freq;
        g.gain.setValueAtTime(0.0001, at); g.gain.exponentialRampToValueAtTime(0.07, at + 0.04); g.gain.exponentialRampToValueAtTime(0.0001, at + 3.2);
        o.connect(g); g.connect(bus); o.start(at); o.stop(at + 3.3);
      }
      function thud(at, amp) {
        var to = ctx.createOscillator(), tg = ctx.createGain();
        to.type = 'sine'; to.frequency.setValueAtTime(64, at); to.frequency.exponentialRampToValueAtTime(30, at + 0.55);
        tg.gain.setValueAtTime(0.0001, at); tg.gain.exponentialRampToValueAtTime(amp, at + 0.03); tg.gain.exponentialRampToValueAtTime(0.0001, at + 0.9);
        to.connect(tg); tg.connect(fx); to.start(at); to.stop(at + 1);
        var ck = ctx.createBufferSource(), cb = ctx.createBuffer(1, Math.floor(rate * 0.12), rate), cd = cb.getChannelData(0);
        for (var q = 0; q < cd.length; q++) cd[q] = (Math.random() * 2 - 1) * Math.pow(1 - q / cd.length, 3);
        ck.buffer = cb;
        var cf = ctx.createBiquadFilter(); cf.type = 'lowpass'; cf.frequency.value = 240; var cg = ctx.createGain(); cg.gain.value = 0.6 * amp / A.thud;
        ck.connect(cf); cf.connect(cg); cg.connect(fx); ck.start(at);
      }
      var thudAt = t0 + (TL.logo.at + TL.logo.dur * 0.2) / 1000;
      thud(thudAt, A.thud);
      thud(t0 + (TL.mark.at + 300) / 1000, A.thud * 0.6);
      bell(thudAt - t0 + 0.15, 440);
      bell((TL.studio.at + 200) / 1000, 880);
      bell((TL.dev.at + 100) / 1000, 659.25);
      return {
        setMuted: function (m) { out.gain.cancelScheduledValues(ctx.currentTime); out.gain.setTargetAtTime(m ? 0 : 1, ctx.currentTime, 0.05); },
        stop: function () {
          try { out.gain.cancelScheduledValues(ctx.currentTime); out.gain.setTargetAtTime(0, ctx.currentTime, 0.12); } catch (e) {}
          setTimeout(function () { try { ctx.close(); } catch (e) {} }, 700);
        }
      };
    } catch (e) { return null; }
  }

  function finish() {
    if (ended) return;
    ended = true;
    timers.forEach(clearTimeout);
    document.removeEventListener('keydown', onKey, true);
    if (audio) audio.stop();
    store.set(CONFIG.storageKey, '1');
    ctl.classList.remove('lhi-on');
    root.classList.add('lhi-fade');
    API.active = false;
    var cbs = listeners.splice(0);
    cbs.forEach(function (fn) { try { fn(); } catch (e) { console.error(e); } });
    try { window.dispatchEvent(new CustomEvent('littleheartintro:end')); } catch (e) {}
    setTimeout(function () { if (root.parentNode) root.parentNode.removeChild(root); if (style.parentNode) style.parentNode.removeChild(style); }, TL.out.dur + 150);
  }

  function begin() {
    if (state === 'playing' || ended) return;
    state = 'playing'; beganAt = Date.now();
    if (gated) {
      audio = startAudio();
      if (audio) { muteBtn.hidden = false; setMuteUi(); }
    }
    root.classList.add('lhi-play');
    later(function () { ctl.classList.add('lhi-on'); }, CONFIG.skipButtonDelay);
    later(finish, TL.out.at);
  }

  function skip() { if (state === 'playing' || state === 'gate') finish(); }
  API.skip = skip;

  function onKey(e) {
    var k = e.code;
    if (k !== 'Escape' && k !== 'Space' && k !== 'Enter' && k !== 'NumpadEnter') return;
    e.preventDefault(); e.stopImmediatePropagation();
    if (e.repeat) return;
    if (k === 'Escape') return skip();
    if (state === 'gate') return begin();
    if (Date.now() - beganAt > 700) skip();
  }

  gate.addEventListener('click', function (e) { e.stopPropagation(); begin(); });
  skipBtn.addEventListener('click', function (e) { e.stopPropagation(); skip(); });
  muteBtn.addEventListener('click', function (e) {
    e.stopPropagation(); muted = !muted; store.set(CONFIG.mutedKey, muted ? '1' : '0'); setMuteUi();
    if (audio) audio.setMuted(muted);
  });
  root.addEventListener('pointerdown', function (e) {
    if (state === 'playing' && Date.now() - beganAt > 700 && !e.target.closest('.lhi-btn')) skip();
  });
  document.addEventListener('keydown', onKey, true);

  setMuteUi();
  if (gated) { gate.focus({ preventScroll: true }); }
  else { gate.style.display = 'none'; begin(); }
})();
