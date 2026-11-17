/* One-time edition reset: preserve the player's name and preferences, but start
   everybody at Day 1 with no old missions, items, parade scores or sign-offs. */
(function () {
  'use strict';
  var edition = 'anits-progress-edition';
  var current = 'mobile-release-1';
  function reset() {
    try {
      Object.keys(localStorage).filter(function (key) {
        return /^anits-(?:save(?::|$)|unlocked$|dev$|items$|parade$|sign$)/.test(key);
      }).forEach(function (key) { localStorage.removeItem(key) });
      localStorage.setItem(edition, current);
      sessionStorage.removeItem('anits-go');
    } catch (e) { console.warn('Progress storage unavailable', e) }
  }
  try { if (localStorage.getItem(edition) !== current) reset() } catch (e) { reset() }
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