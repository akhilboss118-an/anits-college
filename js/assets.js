/* Asset preloader: fetches binary models/textures, exposes them as globals (B_* = ArrayBuffer, or blob: URL for images),
   then loads the game scripts in order. Started by the menu: window.__boot({char,lvl,onProgress}) -> Promise. */
window.__boot=function(opts){
  var CHAR=opts.char==='girl'?'girl':'boy';window.__CHAR=CHAR;window.__YEAR=[2023,2025].indexOf(+opts.year)>=0?+opts.year:2024;window.__LVL=opts.lvl||1;
  var ASSETS={"B_CADETB": ["assets/models/cadet_boy.glb", "bin"], "B_CADETG": ["assets/models/cadet_girl.glb", "bin"], "B_AMY": ["assets/models/cadet_amy.glb", "bin"], "B_HOOP": ["assets/models/basketball_hoop.glb", "bin"], "B_BBALL": ["assets/models/basketball.glb", "bin"], "B_LAKSMI": ["assets/models/laksmi.glb", "bin"], "B_TREE": ["assets/models/tree_gattu.glb", "bin"], "B_OFFICE": ["assets/models/office_desk.glb", "bin"], "B_SOFA": ["assets/models/office_sofa.glb", "bin"], "B_TOILET": ["assets/models/office_toilet.glb", "bin"], "B_ADMIN": ["assets/models/b_admin.glb", "bin"], "B_AUD": ["assets/models/b_aud.bin", "bin"], "B_STAIRAUD": ["assets/models/b_stairaud.bin", "bin"], "B_WORKSHOP": ["assets/models/workshop.glb", "bin"], "B_BANK": ["assets/models/b_bank.bin", "bin"], "B_BENCH": ["assets/models/b_bench.glb", "bin"], "B_BREZ": ["assets/models/b_brez.bin", "bin"], "B_CAFE": ["assets/models/b_cafe.glb", "bin"], "B_CAFETEX": ["assets/img/b_cafetex.png", "img"], "B_COLONEL": ["assets/models/b_colonel.bin", "bin"], "B_DRINK": ["assets/models/b_drink.bin", "bin"], "B_GRASS": ["assets/models/b_grass.bin", "bin"], "B_GRASSTEX": ["assets/img/b_grasstex.png", "img"], "B_GUARD": ["assets/models/b_guard.bin", "bin"], "B_LP": ["assets/models/b_lp.bin", "bin"], "B_PHONE": ["assets/models/b_phone.bin", "bin"], "B_REMY": ["assets/models/b_remy.bin", "bin"], "B_TEMPLE": ["assets/models/b_temple.bin", "bin"], "B_WALK": ["assets/models/b_walk.bin", "bin"]};
  // only fetch the player model that is actually used (saves ~9 MB for Amy, ~2 MB for the boy)
  if(CHAR==='girl'){delete ASSETS.B_WALK;delete ASSETS.B_DRINK}
  var SCRIPTS=["js/core.js", "js/perf.js", "js/consts.js", "js/vendor/fflate.min.js", "js/vendor/FBXLoader.js", "js/prefbx.js", "js/flag.js", "js/save.js", "js/callpool.js", "js/levels.js", "js/girls.js", "js/campus-environment.js", "js/interaction-outline.js", "js/game.js", "js/diag.js", "js/voice.js", "js/story.js", "js/chat.js", "js/buddy.js", "js/touch.js", "js/day2.js", "js/parade.js", "js/fixes.js", "js/nss-chars.js", "js/nss-photo.js", "js/nss.js", "js/guard-booth.js", "js/gate-scene.js", "js/campus-wall.js"];
  var done=0,total=Object.keys(ASSETS).length+SCRIPTS.length+4;
  function tick(){done++;if(opts.onProgress)opts.onProgress(Math.min(1,done/total))}
  function get(name){
    var a=ASSETS[name];
    return fetch(a[0]).then(function(r){if(!r.ok)throw new Error(a[0]+' '+r.status);return r.arrayBuffer()})
      .then(function(buf){window[name]=a[1]==='img'?URL.createObjectURL(new Blob([buf],{type:'image/png'})):buf;tick()});
  }
  function loadScript(src){return new Promise(function(ok,no){
    if(document.querySelector('script[src="'+src+'"]')){tick();return ok()}
    var t=document.createElement('script');t.src=src;t.async=false;t.onload=function(){tick();ok()};
    t.onerror=function(){no(new Error('failed '+src))};document.body.appendChild(t);})}
  var clips=fetch('assets/audio/clips.json').then(function(r){return r.json()}).then(function(j){window.__CLIPS=j;tick()});
  var girl=fetch('assets/audio/clips_girl.json').then(function(r){return r.ok?r.json():null}).then(function(j){if(j)window.__CLIPS_F=j;tick()}).catch(function(){});
  var bb=fetch('assets/anims/bball.json').then(function(r){return r.ok?r.json():null}).then(function(j){if(j)window.__BB=j;tick()}).catch(function(){tick()});
  var sit=fetch('assets/anims/sit.json').then(function(r){return r.ok?r.json():null}).then(function(j){if(j)window.__SIT=j;tick()}).catch(function(){tick()});
  var PRE=['B_ADMIN','B_BENCH','B_CAFE'];
  function preparse(){window.__PRE={};var GL=new THREE.GLTFLoader();
    return Promise.all(PRE.map(function(k){return new Promise(function(ok,no){
      GL.parse(window[k].slice(0),'',function(g){window.__PRE[k]=g;
        var m=new Uint8Array(24);'PRE!'.split('').forEach(function(c,i){m[i]=c.charCodeAt(0)});k.split('').forEach(function(c,i){m[4+i]=c.charCodeAt(0)});window[k]=m.buffer;ok()},no)})}))}
  // A few concurrent requests beat a 30-model burst on mobile radios and avoid a large memory spike.
  var names=Object.keys(ASSETS),cursor=0,workers=window.__mobile?3:6;
  function worker(){var name=names[cursor++];return name?get(name).then(worker):Promise.resolve()}
  return Promise.all(Array.from({length:Math.min(workers,names.length)},worker).concat(clips,girl,sit,bb)).then(preparse).then(function(){
    return SCRIPTS.reduce(function(p,s){return p.then(function(){return loadScript(s)})},Promise.resolve());
  });
};
