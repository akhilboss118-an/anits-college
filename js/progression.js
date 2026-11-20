/* One-time edition reset: preserve the player's name and preferences, but start
   everybody at Day 1 with no old missions, items, parade scores or sign-offs. */
(function () {
  'use strict';
  var edition = 'anits-progress-edition';
  var current = 'mobile-release-1';
  function reset() {
    try {
      Object.keys(localStorage).filter(function (key) {
        return /^anits-(?:save(?::|$)|unlocked$|dev$|attendance$|atthist$|items$|parade$|sign$)/.test(key);
      }).forEach(function (key) { localStorage.removeItem(key) });
      localStorage.setItem(edition, current);
      sessionStorage.removeItem('anits-go');
    } catch (e) { console.warn('Progress storage unavailable', e) }
  }
  try { if (localStorage.getItem(edition) !== current) reset() } catch (e) { reset() }
  var AK = 'anits-attendance';
  function attGet() { try { var v = localStorage.getItem(AK); if (v === null) return 100; var n = Number(v); return isFinite(n) ? Math.max(0, Math.min(100, n)) : 100 } catch (e) { return 100 } }
  function attSet(n) { n = Math.max(0, Math.min(100, n)); try { localStorage.setItem(AK, String(n)) } catch (e) {} return n }
  window.__attendance = {
    get: attGet,
    attend: function () { return attSet(attGet() + 3) },
    miss: function () { return attSet(attGet() - 5) },
    LIMIT: 75,
    log: function (day, result) { try { var h = JSON.parse(localStorage.getItem('anits-atthist') || '{}'); h[day] = { r: result, a: attGet() }; localStorage.setItem('anits-atthist', JSON.stringify(h)) } catch (e) {} },
    history: function () { try { return JSON.parse(localStorage.getItem('anits-atthist') || '{}') } catch (e) { return {} } }
  };
  window.__progress = {
    reset: reset,
    unlocked: function (maximum) {
      try {
        var n = Number(localStorage.getItem('anits-unlocked'));
        return Number.isInteger(n) ? Math.max(1, Math.min(maximum, n)) : 1;
      } catch (e) { return 1 }
    }
  };
})();