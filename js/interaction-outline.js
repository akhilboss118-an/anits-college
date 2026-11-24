/* Soft white look-at glow for NPCs. Two depth-tested inverted-hull passes (tight rim + soft halo)
   rendered on an isolated outline scene, perfectly synchronised with animated SkinnedMeshes and static Meshes.
   Zero scene graph re-traversal, no T-pose glitch, and ultra-optimised for low-end mobile & laptop GPUs. */
(function () {
  window.__makeInteractionOutline = function (T) {
    var FADE_IN = 7, FADE_OUT = 10;
    var active = null, group = null, entries = [], alpha = 0;
    var rimW = { value: 0.028 }, haloW = { value: 0.065 };
    var outlineScene = new T.Scene();

    function createMat(isSkinned, widthRef, tag) {
      var m = new T.MeshBasicMaterial({
        color: 0xffffff,
        side: T.BackSide,
        transparent: true,
        opacity: 0,
        depthTest: true,
        depthWrite: false,
        fog: false,
        skinning: isSkinned,
        polygonOffset: true,
        polygonOffsetFactor: 1,
        polygonOffsetUnits: 1
      });

      m.onBeforeCompile = function (shader) {
        shader.uniforms.uGlowW = widthRef;
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

      m.customProgramCacheKey = function () {
        return 'npc-glow-' + tag;
      };

      return m;
    }

    // Separate materials for SkinnedMesh and static Mesh prevent Three.js program cache collisions
    var haloMatSkinned = createMat(true, haloW, 'halo-skin');
    var haloMatStatic = createMat(false, haloW, 'halo-stat');
    var rimMatSkinned = createMat(true, rimW, 'rim-skin');
    var rimMatStatic = createMat(false, rimW, 'rim-stat');

    function clear() {
      while (outlineScene.children.length > 0) {
        outlineScene.remove(outlineScene.children[0]);
      }
      entries = [];
      active = group = null;
      alpha = 0;
    }

    function attach(npc) {
      if (!npc || !npc.g) return;
      clear();
      npc.g.updateMatrixWorld(true);

      if (!npc.g.__outlineEntries) {
        var list = [];
        npc.g.traverse(function (mesh) {
          if (!mesh.isMesh || !mesh.visible || !mesh.geometry) return;
          if (mesh.isSprite || (mesh.name && mesh.name.indexOf('label') !== -1)) return;
          if (!mesh.geometry.attributes.normal) {
            try { mesh.geometry.computeVertexNormals(); } catch (e) {}
          }
          if (!mesh.geometry.attributes.normal) return;

          var oMesh;
          if (mesh.isSkinnedMesh && mesh.skeleton) {
            oMesh = new T.SkinnedMesh(mesh.geometry, haloMatSkinned);
            oMesh.bind(mesh.skeleton, mesh.bindMatrix);
            oMesh.matrixAutoUpdate = false;
            oMesh.frustumCulled = false;
            list.push({ orig: mesh, outline: oMesh, isSkinned: true });
          } else {
            oMesh = new T.Mesh(mesh.geometry, haloMatStatic);
            oMesh.matrixAutoUpdate = false;
            oMesh.frustumCulled = false;
            list.push({ orig: mesh, outline: oMesh, isSkinned: false });
          }
        });
        npc.g.__outlineEntries = list;
      }

      entries = npc.g.__outlineEntries;
      if (!entries || !entries.length) return;

      for (var i = 0; i < entries.length; i++) {
        outlineScene.add(entries[i].outline);
      }
      active = npc;
      group = npc.g;
      alpha = 0;
    }

    function update(target, dt, hard) {
      if (target && (!target.g || target.g.visible === false)) target = null;
      if (hard || (active && (active.g !== group || active.g.visible === false))) {
        clear();
        if (hard) return;
      }
      dt = Math.min(dt || 0, 0.1);
      if (active && target !== active) {
        alpha -= dt * FADE_OUT;
        if (alpha <= 0) clear();
      }
      if (!active && target) attach(target);
      if (active && target === active) {
        alpha = Math.min(1, alpha + dt * FADE_IN);
      }
    }

    function render(renderer, scene, camera) {
      if (!active || alpha <= 0.01 || !entries.length) return;

      // Keep outline mesh world transforms strictly aligned with source NPC meshes
      for (var i = 0; i < entries.length; i++) {
        var e = entries[i];
        if (e.orig && e.orig.matrixWorld) {
          e.outline.matrixWorld.copy(e.orig.matrixWorld);
        }
      }

      var autoClear = renderer.autoClear;
      try {
        renderer.autoClear = false;

        // 1. Soft wide halo pass
        haloMatSkinned.opacity = 0.28 * alpha;
        haloMatStatic.opacity = 0.28 * alpha;
        for (var i = 0; i < entries.length; i++) {
          entries[i].outline.material = entries[i].isSkinned ? haloMatSkinned : haloMatStatic;
        }
        renderer.render(outlineScene, camera);

        // 2. Crisp bright rim pass
        rimMatSkinned.opacity = 0.95 * alpha;
        rimMatStatic.opacity = 0.95 * alpha;
        for (var i = 0; i < entries.length; i++) {
          entries[i].outline.material = entries[i].isSkinned ? rimMatSkinned : rimMatStatic;
        }
        renderer.render(outlineScene, camera);
      } finally {
        renderer.autoClear = autoClear;
      }
    }

    var api = { update: update, render: render, clear: clear };
    Object.defineProperties(api, {
      current: { get: function () { return active ? active.name : null; } },
      alpha: { get: function () { return alpha; } },
      meshCount: { get: function () { return entries.length; } }
    });
    window.__outline = api;
    return api;
  };
})();
