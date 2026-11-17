/* Pre-converted models: the heavy FBX buildings (admin block, gate, benches, cafe) are slim GLBs now.
   assets.js parses them once (async) into window.__PRE; the game still calls new THREE.FBXLoader().parse(buf)
   synchronously, so this shim hands back the ready object when it sees a "PRE!<name>" marker buffer. */
(function () {
  var T = window.THREE; if (!T || !T.FBXLoader) return;
  var orig = T.FBXLoader.prototype.parse;
  T.FBXLoader.prototype.parse = function (buf, path) {
    var u = new Uint8Array(buf.buffer ? buf.buffer : buf, buf.byteOffset || 0, Math.min(buf.byteLength || 0, 24));
    if (u[0] === 80 && u[1] === 82 && u[2] === 69 && u[3] === 33) {
      var name = String.fromCharCode.apply(null, Array.prototype.slice.call(u, 4)).replace(/\0+$/, '');
      var p = window.__PRE && window.__PRE[name];
      if (!p) throw new Error('pre-parsed model missing: ' + name);
      p.scene.animations = p.animations || [];
      return p.scene;
    }
    return orig.call(this, buf, path);
  };
})();
