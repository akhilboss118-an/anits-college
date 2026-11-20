/* Soft white look-at glow for NPCs. Two depth-tested inverted-hull passes (tight rim + soft halo)
   re-render only the targeted NPC meshes on a private layer, so animation, collision and the
   normal render are never touched. Alpha fades in/out; switching NPCs fades out, then in. */
(function () {
  window.__makeInteractionOutline = function (T) {
    var LAYER = 3, FADE_IN = 7, FADE_OUT = 10;
    var active = null, group = null, meshes = [], alpha = 0;
    var rim = { value: 0 }, halo = { value: 0 };

    function mat(width, tag) {
      var m = new T.MeshBasicMaterial({
        color: 0xffffff, side: T.BackSide, transparent: true, opacity: 0,
        depthTest: true, depthWrite: false, fog: false, skinning: true,
        polygonOffset: true, polygonOffsetFactor: 1, polygonOffsetUnits: 1
      });
      m.onBeforeCompile = function (shader) {
        shader.uniforms.uGlowW = width;
        shader.vertexShader = shader.vertexShader
          .replace('#include <common>', '#include <common>\nuniform float uGlowW;')
          .replace('#include <project_vertex>', [
            'vec3 gN = normal;',
            '#ifdef USE_SKINNING',
            'mat4 gS = bindMatrixInverse * (boneMatX * skinWeight.x + boneMatY * skinWeight.y + boneMatZ * skinWeight.z + boneMatW * skinWeight.w) * bindMatrix;',
            'gN = (gS * vec4(normal, 0.0)).xyz;',
            '#endif',
            'vec4 mvPosition = modelViewMatrix * vec4(transformed, 1.0);',
            'vec3 gV = normalize(normalMatrix * gN);',
            'mvPosition.xyz += gV * uGlowW * clamp(0.6 + (-mvPosition.z) * 0.08, 1.0, 3.5);',
            'gl_Position = projectionMatrix * mvPosition;'
          ].join('\n'));
      };
      m.customProgramCacheKey = function () { return 'npc-glow'; };
      return m;
    }
    var rimMat = mat(rim), haloMat = mat(halo);

    function restore() {
      meshes.forEach(function (e) { e.mesh.layers.mask = e.mask; });
      meshes = [];
    }

    function clear() {
      restore();
      active = group = null;
      alpha = 0;
    }

    function attach(npc) {
      var found = [];
      npc.g.updateMatrixWorld(true);
      npc.g.traverse(function (mesh) {
        if (!mesh.isMesh || !mesh.visible || !mesh.geometry || !mesh.geometry.attributes.normal) return;
        found.push(mesh);
      });
      if (!found.length) return;
      found.forEach(function (mesh) {
        meshes.push({ mesh: mesh, mask: mesh.layers.mask });
        mesh.layers.enable(LAYER);
      });
      rim.value = .03;
      halo.value = .07;
      active = npc; group = npc.g; alpha = 0;
    }

    function update(target, dt, hard) {
      if (target && (!target.g || target.g.visible === false)) target = null;
      if (hard || (active && (active.g !== group || active.g.visible === false))) {
        clear();
        if (hard) return;
      }
      dt = Math.min(dt || 0, .1);
      if (active && target !== active) {
        alpha -= dt * FADE_OUT;
        if (alpha <= 0) clear();
      }
      if (!active && target) attach(target);
      if (active && target === active) alpha = Math.min(1, alpha + dt * FADE_IN);
    }

    function render(renderer, scene, camera) {
      if (!active || alpha <= .01 || !meshes.length) return;
      var background = scene.background, previousMaterial = scene.overrideMaterial;
      var autoClear = renderer.autoClear, cameraMask = camera.layers.mask;
      var fog = scene.fog;
      try {
        renderer.autoClear = false;
        scene.background = null;
        scene.fog = null;
        camera.layers.set(LAYER);
        haloMat.opacity = .28 * alpha;
        scene.overrideMaterial = haloMat;
        renderer.render(scene, camera);
        rimMat.opacity = .95 * alpha;
        scene.overrideMaterial = rimMat;
        renderer.render(scene, camera);
      } finally {
        camera.layers.mask = cameraMask;
        scene.overrideMaterial = previousMaterial;
        scene.background = background;
        scene.fog = fog;
        renderer.autoClear = autoClear;
      }
    }

    var api = { update: update, render: render, clear: clear };
    Object.defineProperties(api, {
      current: { get: function () { return active ? active.name : null; } },
      alpha: { get: function () { return alpha; } },
      meshCount: { get: function () { return meshes.length; } }
    });
    window.__outline = api;
    return api;
  };
})();
