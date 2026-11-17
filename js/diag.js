/* Phone test helper: add ?debug=1 to the address, or tap the top-left corner 5 times, to show FPS and render stats.
   Use it to compare a low-end and a mid-range phone (FPS, 1% low, pixel ratio, draw calls, textures, memory). */
(function(){
  var on=/[?&]debug=1/.test(location.search),el=null,taps=0,tt=0,fr=[],last=performance.now(),acc=0,cnt=0;
  function build(){el=document.createElement('div');el.id='diag';el.setAttribute('data-testid','diag');
    el.style.cssText='position:fixed;left:max(6px,env(safe-area-inset-left));top:6px;z-index:99999;padding:6px 9px;border-radius:8px;background:rgba(0,0,0,.72);color:#9dffb0;font:600 11px/1.45 ui-monospace,Menlo,monospace;white-space:pre;pointer-events:none';document.body.appendChild(el)}
  function show(v){on=v;if(on&&!el)build();if(el)el.style.display=on?'block':'none'}
  addEventListener('pointerdown',function(e){if(e.clientX<70&&e.clientY<70){taps++;clearTimeout(tt);tt=setTimeout(function(){taps=0},1500);if(taps>=5){taps=0;show(!on)}}},true);
  function tick(t){requestAnimationFrame(tick);var d=t-last;last=t;if(d>0&&d<1000){fr.push(d);if(fr.length>240)fr.shift()}acc+=d;
    if(acc<500)return;acc=0;if(!on||!el||!fr.length)return;
    var s=fr.slice().sort(function(a,b){return a-b}),avg=fr.reduce(function(a,b){return a+b},0)/fr.length,low=s[Math.floor(s.length*.99)-1]||s[s.length-1];
    var r=window.__ren,i=r&&r.info,q=''; try{q=localStorage.getItem('anits-quality')||'auto'}catch(e){}
    var mem=performance.memory?Math.round(performance.memory.usedJSHeapSize/1048576)+' MB':'n/a';
    el.textContent='FPS '+Math.round(1000/avg)+'  (1% low '+Math.round(1000/low)+')\n'+'screen '+innerWidth+'x'+innerHeight+'  dpr '+(r?r.getPixelRatio().toFixed(2):'?')+'\n'+'quality '+q+(window.__PERF&&window.__PERF.LOW?' (low device)':'')+'\n'+(i?'draws '+i.render.calls+'  tris '+i.render.triangles+'\ntextures '+i.memory.textures+'  geoms '+i.memory.geometries+'\n':'')+'JS heap '+mem}
  requestAnimationFrame(tick);if(on)show(true);
})();
