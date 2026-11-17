/* Shared helpers (loaded first by assets.js).
   - window.__paused      : true while the pause menu is open (js/pause.js)
   - window.__after(ms,f) : setTimeout that only counts un-paused time -> {cancel()}
   - window.__sleep(ms)   : promise version of __after
   - window.__subs        : single-line subtitle helper: chunks(text, el, prefix) splits a line so every
                            piece fits ONE line of the strip `el`; dur(chunk) = how long to show a piece. */
(function () {
  window.__paused = false;
  var timers = new Set(), last = performance.now();
  setInterval(function () {
    var n = performance.now(), d = n - last; last = n;
    if (window.__paused) return;
    timers.forEach(function (t) {
      t.left -= d;
      if (t.left <= 0) { timers.delete(t); try { t.fn() } catch (e) { console.error(e) } }
    });
  }, 40);
  window.__after = function (ms, fn) { var t = { left: ms, fn: fn }; timers.add(t); return { cancel: function () { timers.delete(t) } } };
  window.__sleep = function (ms) { return new Promise(function (r) { window.__after(ms, r) }) };

  var ctx = document.createElement('canvas').getContext('2d');
  function stripWidth(el) {
    var cs = getComputedStyle(el), keep = null;
    if (cs.display === 'none') { keep = [el.style.display, el.style.visibility]; el.style.visibility = 'hidden'; el.style.display = 'block' }
    var w = el.clientWidth;
    if (keep) { el.style.display = keep[0]; el.style.visibility = keep[1] }
    return w;
  }
  function chunks(text, el, prefix) {
    text = String(text || '').replace(/\s+/g, ' ').trim();
    if (!text) return [''];
    var cs = getComputedStyle(el), px = parseFloat(cs.paddingLeft) + parseFloat(cs.paddingRight) + 6;
    ctx.font = '600 ' + cs.fontSize + ' ' + cs.fontFamily;
    var room = (stripWidth(el) || 360) - px - (prefix ? ctx.measureText(prefix + ' ').width + 8 : 0);
    room = Math.max(120, room * .96);
    var words = text.split(' '), out = [], line = [];
    var wd = function (a) { return ctx.measureText(a.join(' ')).width };
    for (var i = 0; i < words.length; i++) {
      var w = words[i];
      if (line.length && wd(line.concat(w)) > room) {
        // prefer to break after punctuation if it is late enough in the line
        var p = -1;
        for (var k = line.length - 1; k >= 0; k--) { if (/[.,!?;:\u2014-]$/.test(line[k])) { p = k; break } }
        if (p >= 0 && p + 1 >= line.length * .5 && p + 1 < line.length) {
          out.push(line.slice(0, p + 1).join(' ')); line = line.slice(p + 1);
        } else { out.push(line.join(' ')); line = [] }
      }
      line.push(w);
    }
    if (line.length) out.push(line.join(' '));
    return out;
  }
  window.__subs = {
    chunks: chunks,
    dur: function (c) { return Math.max(1500, Math.min(5200, String(c).length * 68 + 500)) }
  };
})();
