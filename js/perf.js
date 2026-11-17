/* Phone sharpness + smoothness helpers (loaded before game.js).
   1) every texture gets anisotropic filtering -> ground / walls stay sharp at glancing angles instead of smearing
   2) __PERF.prewarm(renderer, scene, camera) uploads every texture + compiles every shader ONCE while the loading
      screen / first frame is up, so big textures never hitch the moment they come on screen
      (that hitch used to trip the auto-resolution drop, which is what made the whole picture go blurry). */
(function () {
  var T = window.THREE; if (!T) return;
  var ua = navigator.userAgent || '';
  var MOB = (function () { try { return matchMedia('(pointer:coarse)').matches } catch (e) { return false } })() || /Android|iPhone|iPad|Mobi/i.test(ua);
  /* quality tier: low (<=4 GB phones) / med (other phones) / high (desktop). Override: ?q=low|med|high or Settings > Graphics */
  var tier = 'high';
  (function () {
    var want = (/[?&]q=(low|med|high)/.exec(location.search) || [])[1], saved = null;
    try { saved = localStorage.getItem('anits-quality') } catch (e) {}
    if (!want && /^(low|med|high)$/.test(saved || '')) want = saved;
    if (want) { tier = want; return }
    if (!MOB) return;
    var mem = navigator.deviceMemory;           // 0.5..8 on Android Chrome; undefined on iPhone/Firefox
    tier = (mem && mem >= 6) ? 'med' : 'low';   // conservative phone geometry/shadow tier; render resolution has its own readable floor
  })();
  var LOW = tier === 'low';
  var MAXTEX = LOW ? ((navigator.deviceMemory && navigator.deviceMemory <= 2) ? 512 : 1024) : (tier === 'med' ? 1024 : 2048);
  var ANISO = LOW ? 4 : (MOB ? 6 : 8);          // the GPU clamps this to its own maximum

  /* low tier: shrink big textures once (a 1024 texture + mipmaps = ~5 MB of GPU memory each; 4 GB phones choke on dozens of them) */
  var shrunk = new WeakMap();
  function shrink(t) {
    var im = t.image; if (!im || t.isCompressedTexture || t.isDataTexture || t.isCanvasTexture) return;
    var w = im.width || im.naturalWidth, h = im.height || im.naturalHeight;
    if (!w || !h || Math.max(w, h) <= MAXTEX) return;
    if (!(im instanceof HTMLImageElement || (typeof ImageBitmap !== 'undefined' && im instanceof ImageBitmap))) return;
    var c = shrunk.get(im);
    if (!c) {
      var k = MAXTEX / Math.max(w, h); c = document.createElement('canvas');
      c.width = Math.max(1, Math.round(w * k)); c.height = Math.max(1, Math.round(h * k));
      var x = c.getContext('2d'); x.imageSmoothingQuality = 'high'; x.drawImage(im, 0, 0, c.width, c.height);
      shrunk.set(im, c);
    }
    t.image = c;
  }

  var d = Object.getOwnPropertyDescriptor(T.Texture.prototype, 'needsUpdate');
  if (d && d.set) {
    Object.defineProperty(T.Texture.prototype, 'needsUpdate', {
      configurable: true, enumerable: d.enumerable, get: d.get,
      set: function (v) {
        if (v === true) {
          if (this.anisotropy < ANISO && this.magFilter !== T.NearestFilter) this.anisotropy = ANISO;
          if (MAXTEX < 2048) { try { shrink(this) } catch (e) {} }
        }
        d.set.call(this, v);
      }
    });
  }

  /* add ?perf=1 to the URL: tiny corner readout of FPS, draw calls and triangles (to find what is still heavy on a phone) */
  if (/[?&]perf=1/.test(location.search)) {
    var hd = null, fr = 0, t0 = performance.now(), fps = 0;
    window.__perfHud = function (ren) {
      if (!hd) { hd = document.createElement('div'); hd.style.cssText = 'position:fixed;left:50%;bottom:4px;transform:translateX(-50%);z-index:99999;padding:2px 8px;border-radius:6px;background:rgba(0,0,0,.6);color:#9f9;font:11px monospace;pointer-events:none;white-space:nowrap'; document.body.appendChild(hd) }
      fr++; var n = performance.now();
      if (n - t0 > 500) { fps = Math.round(fr * 1000 / (n - t0)); fr = 0; t0 = n; var i = ren.info; hd.textContent = fps + ' fps | ' + i.render.calls + ' draws | ' + Math.round(i.render.triangles / 1000) + 'k tris | ' + i.memory.textures + ' tex | q=' + tier }
    };
  }
  var MAPS = ['map', 'emissiveMap', 'normalMap', 'roughnessMap', 'metalnessMap', 'aoMap', 'alphaMap', 'bumpMap'];
  window.__PERF = {
    MOB: MOB, ANISO: ANISO, tier: tier, LOW: LOW,
    prewarm: function (ren, sc, cam) {
      return new Promise(function (resolve) {
       try {
        var seen = new Set(), list = [];
        sc.traverse(function (o) {
          var ms = o.material; if (!ms) return;
          (Array.isArray(ms) ? ms : [ms]).forEach(function (m) {
            MAPS.forEach(function (k) { var t = m[k]; if (t && t.isTexture && !seen.has(t)) { seen.add(t); list.push(t) } });
          });
        });
        // spread the uploads over a few frames so the loading screen never freezes for a long time
        var i = 0;
        (function step() {
          var t0 = performance.now();
          while (i < list.length && performance.now() - t0 < 6) {
            var t = list[i++];
            if (t.image && (t.image.width || t.image.videoWidth || t.image.data)) { try { ren.initTexture(t) } catch (e) {} }
          }
          if (i < list.length) requestAnimationFrame(step);
          else { try { if (!MOB && ren.compile) ren.compile(sc, cam) } catch (e) { console.warn('shader prewarm', e) } resolve() }
        })();
      } catch (e) { console.warn('prewarm', e); resolve() }
      });
    }
  };
})();
