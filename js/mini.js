/* Mini-games for level tasks: shoot (timing bar), cmd (arrow-key commands), mash (tap SPACE), quiz (1-4). window.__mini.run(cfg, onWin) */
(()=>{
let el,act=null,raf=0,tm=0;
const css=document.createElement('style');css.textContent=`
#mini{position:fixed;inset:0;z-index:30;display:none;align-items:center;justify-content:center;background:rgba(3,10,24,.72);backdrop-filter:blur(6px);font-family:'Figtree',system-ui,sans-serif;color:#fff}
#mini .mb{width:min(620px,92vw);padding:26px 28px;border-radius:18px;background:linear-gradient(160deg,rgba(10,32,70,.96),rgba(5,14,34,.96));border:1.5px solid #3aa0ff;box-shadow:0 0 40px rgba(40,140,255,.35);text-align:center;animation:mpop .35s both}
#mini.shootmode{background:none;backdrop-filter:none;align-items:flex-start;justify-content:flex-start;padding:10px 10px 0 max(10px,env(safe-area-inset-left));pointer-events:none}#mini.shootmode .mb{pointer-events:auto;width:min(300px,34vw);min-width:210px;padding:10px 14px;animation:none;text-align:left}#mini.shootmode #mi-t{margin-bottom:6px;font-size:11px}#mini.shootmode .mi-shotbtn{margin-top:4px;width:100%}#mini.pad .mi-shotbtn{display:none}#mini.shootmode #mi-b{min-height:56px}#mini.shootmode #mi-s{font-size:12px;line-height:1.35;margin-bottom:8px;min-height:0}#mini.shootmode #mi-b{align-items:stretch}#mini.shootmode #mi-h{margin-top:6px}
body.shooting #mis,body.shooting #wal,body.shooting #en,body.shooting #mm,body.shooting #mission-pin,body.shooting #mission-say,body.shooting #sub{display:none!important}
body.shooting #mini.shootmode{padding:8px 8px 0 max(8px,env(safe-area-inset-left))}
body.shooting #mini.shootmode .mb{display:flex;align-items:center;gap:10px;width:auto!important;min-width:0!important;max-width:none!important;padding:6px 12px!important;border-radius:999px;background:rgba(8,16,34,.72)}
body.shooting #mini.shootmode #mi-s,body.shooting #mini.shootmode #mi-h{display:none!important}
body.shooting #mini.shootmode #mi-t{margin:0!important;font-size:10px!important;letter-spacing:.18em;white-space:nowrap}
body.shooting #mini.shootmode #mi-b{min-height:0!important;flex-direction:row;gap:8px}
body.shooting #mini.shootmode .mi-dot{width:13px;height:13px}
body.shooting #mini.shootmode .mi-shotbtn{margin:0!important;width:auto!important;padding:6px 16px!important;font-size:13px}
@keyframes mpop{from{opacity:0;transform:scale(.9) translateY(14px)}to{opacity:1;transform:none}}
#mi-t{font:800 13px/1 'Bricolage Grotesque',sans-serif;letter-spacing:.28em;color:#7cc4ff;margin-bottom:10px}
#mi-s{font-size:15px;opacity:.85;margin-bottom:14px;min-height:20px}
#mi-b{min-height:120px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:10px}
#mi-h{font-size:12px;opacity:.6;margin-top:14px;letter-spacing:.06em}
.mi-bar{position:relative;width:100%;height:30px;border-radius:15px;background:#0b1b3a;border:1.5px solid #3aa0ff;overflow:hidden}
.mi-g{position:absolute;top:0;bottom:0;background:rgba(60,230,120,.55);border-left:2px solid #6dff9f;border-right:2px solid #6dff9f}
.mi-p{position:absolute;top:-2px;width:8px;height:34px;background:#ffd54a;border-radius:4px;box-shadow:0 0 12px #ffd54a}
.mi-big{font:900 72px/1 'Bricolage Grotesque',sans-serif;color:#ffd54a;text-shadow:0 0 24px rgba(255,213,74,.5)}
.mi-row{display:flex;gap:8px;flex-wrap:wrap;justify-content:center}.mi-dot{width:16px;height:16px;border-radius:50%;background:#16305c}.mi-dot.ok{background:#3ce678}.mi-dot.no{background:#ff4d5a}
.mi-opt{display:block;width:100%;text-align:left;margin:0;padding:11px 16px;font-size:15px;border-radius:12px;background:#0e2a52;color:#fff;border:1.5px solid #2a6fc0;cursor:pointer;font-weight:600}.mi-opt:hover{background:#ffd54a;color:#111}
.mi-btn{margin-top:6px;padding:11px 26px;font-size:15px;border-radius:999px;background:#ffd54a;color:#111;font-weight:800;border:0;cursor:pointer}
.mi-res{font:800 26px/1.2 'Bricolage Grotesque',sans-serif}.mi-res.w{color:#6dff9f}.mi-res.l{color:#ff7a85}
.mi-doors{display:grid;grid-template-columns:repeat(4,1fr);gap:10px;width:100%}.mi-door{position:relative;padding:34px 6px 12px;border-radius:10px 10px 4px 4px;background:linear-gradient(180deg,#8a5a2b,#4e2f12);border:2px solid #c48a4a;color:#fff;cursor:pointer;font:700 12px 'Figtree',sans-serif;box-shadow:0 6px 14px rgba(0,0,0,.45)}.mi-door:hover{filter:brightness(1.2)}.mi-door .pl{position:absolute;left:8%;right:8%;top:6px;padding:4px 2px;border-radius:4px;background:#e8e2cf;color:#1a1a1a;font:900 15px 'Bricolage Grotesque',sans-serif}.mi-door .kn{display:block;margin-top:2px;opacity:.8}.mi-door.bad{animation:mshake .4s;background:linear-gradient(180deg,#7a2a2a,#401212)}.mi-door.ok{background:linear-gradient(180deg,#1f8a4a,#0f4a26)}
@keyframes mshake{25%{transform:translateX(-6px)}50%{transform:translateX(6px)}75%{transform:translateX(-4px)}}.mi-note{padding:10px 14px;border-radius:10px;background:#fdfaf0;color:#222;font-size:14px;line-height:1.4;text-align:left;width:100%}.mi-msg{min-height:22px;font-weight:700;color:#ffd54a}
`;document.head.appendChild(css);
const $=id=>document.getElementById(id),WASD={KeyW:'ArrowUp',KeyA:'ArrowLeft',KeyS:'ArrowDown',KeyD:'ArrowRight'};
function build(){el=document.createElement('div');el.id='mini';el.setAttribute('data-testid','mini-overlay');
 el.innerHTML='<div class="mb"><div id="mi-t"></div><div id="mi-s"></div><div id="mi-b"></div><div id="mi-h"></div></div>';document.body.appendChild(el);
 el.addEventListener('pointerdown',e=>e.stopPropagation());el.addEventListener('click',e=>{const o=e.target.closest('[data-o]');if(o&&act&&act.pick)act.pick(+o.dataset.o);if(e.target.closest('.mi-leave')&&act&&act.leave){act.leave();return}if(e.target.closest('.mi-btn')&&act&&act.again)act.again();if(e.target.closest('.mi-shot')&&act&&act.shot)act.shot()})}
addEventListener('keydown',e=>{if(!act||window.__paused)return;e.preventDefault();e.stopImmediatePropagation();if(e.repeat&&!/^(Arrow|Key[WASD])/.test(e.code))return;act.key&&act.key(e)},true);
addEventListener('anits-pause',()=>{act&&act.onPause&&act.onPause()});addEventListener('anits-resume',()=>{act&&act.onResume&&act.onResume()});
let shootOn=false;const ev=d=>{try{dispatchEvent(new CustomEvent('anits-shoot',{detail:d}))}catch(e){}};
function stop(){cancelAnimationFrame(raf);clearTimeout(tm);act=null;el.style.display='none';el.classList.remove('shootmode');document.body.classList.remove('shooting');if(shootOn){shootOn=false;ev({type:'end'})}}
function end(win,cfg,cb,again){const b=$('mi-b'),res=cfg.res?'<div style="font-size:17px;font-weight:700;margin:2px 0 6px" data-testid="quiz-score">'+cfg.res+'</div>':'';
 b.innerHTML='<div class="mi-res '+(win?'w':'l')+'">'+(win?(cfg.winText||'Mission complete!'):(cfg.loseText||'Not enough, try again!'))+'</div>'+res+(win?'':'<button class="mi-btn" data-testid="mini-retry-btn">Try again (Enter)</button>'+(cfg.onLeave?' <button class="mi-btn mi-leave" style="background:#2a4a7a;color:#fff" data-testid="mini-leave-btn">Step back (Esc)</button>':''));$('mi-h').textContent='';
 const leave=()=>{stop();cfg.onLeave&&cfg.onLeave()};
 if(win){tm=setTimeout(()=>{stop();cb()},cfg.winText?2200:1300);act={key(){}}}else act={key(e){if(e.code==='Enter'||e.code==='Space')again();else if(e.code==='Escape'&&cfg.onLeave)leave()},again,leave};}
const kinds={
 shoot(cfg,fin){let shot=0,hit=0,busy=0,pAt=0;const touch=document.body.classList.contains('touch');
  el.classList.add('shootmode');document.body.classList.add('shooting');shootOn=true;ev({type:'start',total:cfg.shots});
  $('mi-s').textContent=(touch?'Drag on the screen to aim the ring at the hoop, then tap SHOOT. ':'Drag the mouse (or use arrow keys) to aim the ring at the hoop, then press SHOOT / SPACE. ')+'Score '+cfg.need+' of '+cfg.shots+'.';
  $('mi-b').innerHTML='<div class="mi-row" id="mi-d">'+Array(cfg.shots).fill('<i class="mi-dot"></i>').join('')+'</div><button class="mi-btn mi-shot mi-shotbtn" data-testid="shoot-btn">SHOOT</button>';$('mi-h').textContent=touch?'Drag = aim':'Drag / arrows = aim  |  SPACE = shoot';
  const NUD=.05,K={ArrowLeft:[-NUD,0],ArrowRight:[NUD,0],ArrowUp:[0,NUD],ArrowDown:[0,-NUD]};
  const shoot=()=>{if(busy||window.__paused)return;const A=window.__court&&window.__court.aim;let r=A?A.fire(shot):{ok:Math.random()<.5};
   if(!r){return}                       // ball not in hand yet (still returning): ignore the press
   busy=1;const ok=!!r.ok;if(ok)hit++;const di=shot;shot++;
   if(!A)ev({type:'shot',ok,n:di});
   setTimeout(()=>{const d=$('mi-d');if(d&&d.children[di])d.children[di].className='mi-dot '+(ok?'ok':'no')},2900);
   setTimeout(()=>{busy=0;if(shot>=cfg.shots)fin(hit>=cfg.need)},3500)};
  act={key(e){const k=WASD[e.code]||e.code;if(e.code==='Space'||e.code==='Enter')shoot();else if(K[k]&&window.__court&&window.__court.aim)window.__court.aim.nudge(K[k][0],K[k][1])},shot:shoot,onPause(){pAt=performance.now()},onResume(){pAt=0}}},
 cmd(cfg,fin){let i=0,ok=0,seq=Array.from({length:cfg.n},()=>cfg.keys[Math.floor(Math.random()*cfg.keys.length)]),dl=0;
  $('mi-s').textContent='Press the arrow key (or W A S D) that is called. Get '+cfg.need+' of '+cfg.n+' right.';
  const show=()=>{if(i>=cfg.n){fin(ok>=cfg.need);return}const [s,n]=cfg.names[seq[i]];
   $('mi-b').innerHTML='<div class="mi-big" data-testid="cmd-symbol">'+s+'</div><div style="font-weight:800;letter-spacing:.2em">'+n+'</div><div class="mi-row">'+seq.map((_,k)=>'<i class="mi-dot '+(k<i?(k<i&&res[k]?'ok':'no'):'')+'"></i>').join('')+'</div>';
   clearTimeout(tm);tm=setTimeout(()=>{res[i]=0;i++;show()},cfg.time*1000)};
  const res=[];
  act={onPause(){clearTimeout(tm)},onResume(){if(i<cfg.n)show()},key(e){const k=WASD[e.code]||e.code;if(!/^Arrow/.test(k)||i>=cfg.n)return;if(k===seq[i]){ok++;res[i]=1}else res[i]=0;i++;show()}};show();$('mi-h').textContent='Arrow keys / WASD'},
 mash(cfg,fin){let n=0,t0=0,over=0;$('mi-s').textContent='Tap SPACE '+cfg.hits+' times in '+cfg.secs+' seconds. The timer starts at your first tap!';
  const draw=()=>{$('mi-b').innerHTML='<div class="mi-big" data-testid="mash-count">'+n+' / '+cfg.hits+'</div><div class="mi-bar"><div class="mi-g" style="left:0;width:'+Math.min(100,n/cfg.hits*100)+'%"></div></div>'};draw();
  let pAt=0;
  const tick=()=>{if(over)return;const left=cfg.secs-(performance.now()-t0)/1000;if(left<=0){over=1;fin(n>=cfg.hits);return}$('mi-h').textContent=left.toFixed(1)+'s left';raf=requestAnimationFrame(tick)};
  act={onPause(){pAt=performance.now()},onResume(){if(pAt&&t0)t0+=performance.now()-pAt;pAt=0},key(e){if(over||e.code!=='Space')return;if(!t0){t0=performance.now();tick()}n++;draw();if(n>=cfg.hits){over=1;cancelAnimationFrame(raf);fin(true)}}};$('mi-h').textContent='SPACE = tap'},
 floor(cfg,fin){let stage=0,miss=0,order=[],doors=[{e:'100 + 94',v:194,peek:'A staff room. A teacher sips chai and points: "Not here, beta!"'},{e:'7 \u00D7 30',v:210,peek:'A computer lab full of humming PCs. "First year? Wrong room!"'},{e:'408 \u00F7 2',v:204,peek:''},{e:'250 \u2212 50',v:200,peek:'A storeroom with chairs stacked to the ceiling. Nobody here.'}];
  for(let i=doors.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[doors[i],doors[j]]=[doors[j],doors[i]]}
  const msg=t=>{const m=$('mi-m');if(m)m.textContent=t};
  const s1=()=>{stage=1;$('mi-s').textContent='Puzzle 1 of 3: the lift';$('mi-b').innerHTML='<div class="mi-note">Prof. Rao said <b>Room 204</b>. The first digit of a room number tells you the floor. Which floor button do you press?</div><div class="mi-row">'+[1,2,3,4].map((n,k)=>'<button class="mi-opt" style="width:auto;min-width:70px;text-align:center" data-o="'+k+'" data-testid="floor-'+n+'">Floor '+n+'</button>').join('')+'</div><div class="mi-msg" id="mi-m"></div>';$('mi-h').textContent='Keys 1-4 or click'};
  const s2=()=>{stage=2;$('mi-s').textContent='Puzzle 2 of 3: four doors, no room numbers';$('mi-b').innerHTML='<div class="mi-note">You reach the floor with <b>4 rooms</b>. The number plates are puzzles. Solve each one and find the door that equals <b>204</b>.</div><div class="mi-doors">'+doors.map((d,k)=>'<button class="mi-door" data-o="'+k+'" data-testid="door-'+k+'"><span class="pl">'+d.e+'</span><span class="kn">Door '+(k+1)+'</span></button>').join('')+'</div><div class="mi-msg" id="mi-m"></div>';$('mi-h').textContent='Keys 1-4 or click a door'};
  const s3=()=>{stage=3;$('mi-s').textContent='Puzzle 3 of 3: the door code';$('mi-b').innerHTML='<div class="mi-note">The door is locked. A sticky note from Arjun: <i>"Seat code = the next number in 3, 6, 12, 24, ?"</i></div><div class="mi-row">'+['30','36','48','60'].map((n,k)=>'<button class="mi-opt" style="width:auto;min-width:70px;text-align:center" data-o="'+k+'" data-testid="code-'+n+'">'+n+'</button>').join('')+'</div><div class="mi-msg" id="mi-m"></div>';$('mi-h').textContent='Keys 1-4 or click'};
  const pick=k=>{if(stage===1){if(k===1){msg('Floor 2. The lift hums upward...');setTimeout(s2,900)}else{miss++;msg(k===0?'Floor 1 is the ground floor, which has the library. Try again.':'Not that floor. The first digit of 204 is the clue!')}}
   else if(stage===2){const d=doors[k];if(!d)return;const el=document.querySelectorAll('.mi-door')[k];if(d.v===204){el.classList.add('ok');msg('The plate adds up to 204. This is the room!');setTimeout(s3,1000)}else{miss++;el.classList.add('bad');msg(d.peek)}}
   else if(stage===3){if(k===2){msg('Click! The door opens and Arjun waves at you.');stage=4;setTimeout(()=>fin(true),1100)}else{miss++;msg('The keypad buzzes. Each number is double the one before it.')}}};
  act={key(e){const m=/^(Digit|Numpad)([1-4])$/.exec(e.code);if(m)pick(+m[2]-1)},pick};s1()},
 csequiz(cfg,fin){let i=0,ok=0,lock=0;const Q=cfg.qs,esc=t=>String(t).replace(/&/g,'&amp;').replace(/</g,'&lt;');
  const show=()=>{if(i>=Q.length){const win=ok>=cfg.need;cfg.res='You scored '+ok+' / '+Q.length+' (pass mark '+cfg.need+')';window.__cseQuizResult={score:ok,total:Q.length,need:cfg.need,passed:win};fin(win);return}
   const [q,o]=Q[i];lock=0;$('mi-s').textContent='Question '+(i+1)+' of '+Q.length+' - get '+cfg.need+' right to open the door';
   $('mi-b').innerHTML='<div style="font-size:19px;font-weight:700;margin-bottom:6px" data-testid="quiz-question">'+esc(q)+'</div>'+o.map((x,k)=>'<button class="mi-opt" data-o="'+k+'" data-testid="quiz-opt-'+k+'">'+(k+1)+'. '+esc(x)+'</button>').join('')+'<div class="mi-msg" id="mi-m"></div>'};
  const pick=k=>{if(lock||i>=Q.length||!Q[i][1][k]&&Q[i][1][k]!=='')return;lock=1;const right=Q[i][2],btns=document.querySelectorAll('#mi-b .mi-opt');if(k===right)ok++;
   if(btns[right])btns[right].style.cssText+=';background:#1f9d55;border-color:#6dff9f';if(k!==right&&btns[k])btns[k].style.cssText+=';background:#b3263a;border-color:#ff7a85';
   const m=$('mi-m');if(m)m.textContent=k===right?'Correct!':'Not quite.';setTimeout(()=>{i++;show()},850)};
  act={key(e){const m=/^(Digit|Numpad)([1-4])$/.exec(e.code);if(m)pick(+m[2]-1)},pick};show();$('mi-h').textContent='Keys 1-4 or click'},
 quiz(cfg,fin){let i=0,ok=0;const show=()=>{if(i>=cfg.qs.length){fin(ok>=cfg.need);return}const [q,o]=cfg.qs[i];
   $('mi-s').textContent='Question '+(i+1)+' of '+cfg.qs.length+' - get '+cfg.need+' right';
   $('mi-b').innerHTML='<div style="font-size:19px;font-weight:700;margin-bottom:6px">'+q+'</div>'+o.map((x,k)=>'<button class="mi-opt" data-o="'+k+'" data-testid="quiz-opt-'+k+'">'+(k+1)+'. '+x+'</button>').join('')};
  const pick=k=>{if(i>=cfg.qs.length)return;if(k===cfg.qs[i][2])ok++;i++;show()};
  act={key(e){const m=/^(Digit|Numpad)([1-4])$/.exec(e.code);if(m)pick(+m[2]-1)},pick};show();$('mi-h').textContent='Keys 1-4 or click'}};
function run(cfg,cb){if(!el)build();stop();if(document.exitPointerLock)try{document.exitPointerLock()}catch(e){}
 el.style.display='flex';$('mi-t').textContent=cfg.title;
 const go=()=>{kinds[cfg.kind](cfg,win=>end(win,cfg,cb,go))};go()}
window.__mini={run,get active(){return !!act}};
})();
