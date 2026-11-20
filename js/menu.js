/* Front end: intro credits -> character -> name -> welcome -> main menu -> level select -> loading -> game. */
(()=>{
const $=id=>document.getElementById(id),LS=localStorage,INFO=window.__LVINFO;
const QUOTES=["Some places teach you lessons, ANITS teaches you life.","Every campus has a story. Yours starts here.","Friends make the canteen chai taste better.","First bench or last bench, the best memories are made together.","Attendance is temporary, memories are permanent.","A salute to discipline, a smile to friendship.","Study hard, play harder, stay curious.","The best classroom is the one with your friends in it.","Dream big. The campus is big enough for it.","One chai, one samosa, and a thousand stories.","Today a fresher, tomorrow a legend of ANITS.","Pragnanam Brahma: knowledge is supreme."];
const HEART='<svg class="heart" viewBox="0 0 24 24" fill="currentColor"><path d="M12 21s-7.5-4.6-9.6-9.2C.9 8.4 2.7 5 6 5c2 0 3.4 1 4.2 2.4h.1C11.1 6 12.5 5 14.5 5c3.3 0 5.1 3.4 3.6 6.8C19.5 16.4 12 21 12 21z" transform="translate(1.1 .2)"/></svg>';
const ICON={play:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M7 4l13 8-13 8z"/></svg>',gear:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M5 5l2 2M17 17l2 2M19 5l-2 2M7 17l-2 2"/></svg>',download:'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 3v12m0 0 5-5m-5 5-5-5M4 17v4h16v-4"/></svg>',lock:'<svg class="lk" viewBox="0 0 24 24" fill="currentColor"><path d="M6 10V8a6 6 0 0112 0v2h1a1 1 0 011 1v10a1 1 0 01-1 1H5a1 1 0 01-1-1V11a1 1 0 011-1zm2 0h8V8a4 4 0 00-8 0z"/></svg>'};
const M=$('menu');
M.innerHTML=`
<div class="scr" id="s-intro" data-testid="intro-screen"><div>${HEART}<h1 id="lh-name" data-testid="intro-title">LITTLE HEARTS PRODUCTION</h1><p id="lh-sub" data-testid="intro-subtitle"></p></div><span id="lh-skip">CLICK TO SKIP</span></div>
<div class="scr" id="s-year" data-testid="year-screen"><div class="bg blur"></div><div class="shade v"></div>
 <div class="head"><h2>WHICH YEAR DID YOU JOIN?</h2><p>Slide to your joining year. It decides your uniform.</p></div>
 <div class="ysl"><div class="yr" id="ys-yr" data-testid="year-value">2024</div>
  <div class="yslw"><input type="range" id="ys" min="2023" max="2025" step="1" value="2024" data-testid="year-slider"><div class="ticks"><button data-y="2023" data-testid="year-tick-2023">2023</button><button data-y="2024" data-testid="year-tick-2024">2024</button><button data-y="2025" data-testid="year-tick-2025">2025</button></div></div>
  <div class="yinfo"><div class="sw"><i id="ys-c1"></i><i id="ys-c2"></i></div><h3 id="ys-name" data-testid="year-uniform-name"></h3><p id="ys-desc" data-testid="year-uniform-desc"></p></div>
  <button class="pillbtn" id="ys-go" data-testid="year-continue-btn">CONTINUE</button></div></div>
<div class="scr" id="s-char" data-testid="character-screen"><div class="bg blur"></div><div class="shade v"></div>
 <button class="back" id="ch-back" data-testid="character-back-btn">&lsaquo; YEAR <b id="ch-yr"></b></button>
 <div class="head"><h2>CHOOSE YOUR CHARACTER</h2><p>Who will walk into ANITS today?</p></div>
 <div class="cards"><div class="card" id="c-boy" data-testid="select-boy"><span class="tag">SELECTED</span><canvas></canvas><h3>Mike</h3><p>BOY</p></div><div class="card" id="c-girl" data-testid="select-girl"><span class="tag">SELECTED</span><canvas></canvas><h3>Amy</h3><p>GIRL</p></div></div></div>
<div class="scr" id="s-name" data-testid="name-screen"><div class="bg blur"></div><div class="shade v"></div><div class="center"><h2>WHAT SHOULD WE CALL YOU?</h2><p>Type your name to begin your story</p><input id="nm" maxlength="14" placeholder="Your name" autocomplete="off" data-testid="username-input"><button class="pillbtn" id="nm-go" data-testid="username-continue-btn" disabled>CONTINUE</button></div></div>
<div class="scr" id="s-wel" data-testid="welcome-screen"><div class="bg blur"></div><div class="shade v"></div><div class="center"><div id="wel1">WELCOME</div><div id="wel2" data-testid="welcome-username"></div><div id="wel3">TO ANITS COLLEGE</div></div></div>
<div class="scr" id="s-main" data-testid="main-menu"><div class="bg"></div><div class="shade"></div><div class="mm-wrap">
 <div class="logo pop"><b>ANITS</b><i>COLLEGE SIMULATION</i></div>
 <button class="btn pri pop" id="b-start" data-testid="start-game-btn" style="animation-delay:.25s">${ICON.play}<s></s>START GAME</button>
 <button class="btn pop" id="b-att" data-testid="attendance-btn" style="animation-delay:.32s"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M8 3v4M16 3v4M3 10h18M9 15l2 2 4-4"/></svg><s></s>ATTENDANCE</button>
 <button class="btn pop" id="b-set" data-testid="settings-btn" style="animation-delay:.4s">${ICON.gear}<s></s>SETTINGS</button>
 <button class="btn pop" id="b-how" data-testid="how-to-play-btn" style="animation-delay:.48s"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="9"/><path d="M9.5 9.5a2.5 2.5 0 1 1 3.6 2.2c-.8.5-1.1 1-1.1 1.8M12 17h.01"/></svg><s></s>HOW TO PLAY</button>
 <div class="who" id="who" data-testid="current-player"></div><div class="who" id="att" data-testid="attendance-display" style="opacity:1;font-weight:800"></div></div>
 <div id="attm" data-testid="attendance-modal"><div class="box"><h2>ATTENDANCE</h2><div id="att-big" data-testid="attendance-modal-percent"></div><div id="att-note"></div><div class="ar"><label>HISTORY</label><div id="att-hist" data-testid="attendance-history"></div></div><div class="row"><button class="pillbtn" id="att-ok" data-testid="attendance-close-btn">CLOSE</button></div></div></div>
 <div id="set" data-testid="settings-modal"><div class="box"><h2>SETTINGS</h2><label>VOICE VOLUME</label><input type="range" id="vol" min="0" max="100" data-testid="volume-slider">
 <label>GRAPHICS <small style="opacity:.6;letter-spacing:.06em">(applies next time you press Start)</small></label><div class="gq" id="gq" data-testid="graphics-quality"><button data-q="auto" data-testid="graphics-auto-button">AUTO</button><button data-q="low" data-testid="graphics-low-button">LOW</button><button data-q="med" data-testid="graphics-medium-button">MEDIUM</button><button data-q="high" data-testid="graphics-high-button">HIGH</button></div>
 <div class="row"><button class="pillbtn alt" id="st-dev" data-testid="dev-mode-btn">DEV MODE</button><button class="pillbtn alt" id="st-chg" data-testid="change-player-btn">CHANGE PLAYER</button><button class="pillbtn alt" id="st-rst" data-testid="reset-progress-btn">RESET PROGRESS</button><button class="pillbtn" id="st-ok" data-testid="settings-close-btn">DONE</button></div>
 <div id="dev-box" data-testid="dev-mode-panel" style="display:none;margin-top:10px"><label>SECRET KEY</label><div class="row" id="dev-in" style="margin-top:6px"><input type="password" id="dev-key" maxlength="12" placeholder="Enter secret key" autocomplete="off" data-testid="dev-key-input" style="flex:1;min-width:120px;padding:10px 14px;border-radius:999px;border:1.5px solid #4fb0ff;background:rgba(255,255,255,.08);color:#fff;font:700 16px 'Figtree',sans-serif;outline:none"><button class="pillbtn" id="dev-go" data-testid="dev-key-submit-btn">UNLOCK</button></div><button class="pillbtn alt" id="dev-off" data-testid="dev-mode-off-btn" style="display:none;margin-top:6px">TURN DEV MODE OFF</button><div id="dev-msg" data-testid="dev-mode-message" style="margin-top:8px;font-size:13px;font-weight:700;letter-spacing:.06em;min-height:16px"></div></div></div></div></div>
<div class="scr" id="s-levels" data-testid="level-screen"><div class="bg blur" style="filter:brightness(.6)"></div><div class="shade v"></div>
 <button class="back" id="lv-back" data-testid="levels-back-btn">&lsaquo; BACK</button>
 <div class="head"><div class="logo"><b>ANITS</b><i>COLLEGE SIMULATION</i></div></div>
 <div class="lvlquote">&ldquo; Every campus has a story. <br>Yours starts here. &rdquo;</div><div class="lvlbadge">LEVELS</div><div class="grid" id="grid" data-testid="level-grid"></div>
 <div class="foot"><span>&#9829; Powered by <b>Little Hearts</b></span><i></i><span>Developed by <b>AKHILBOSS</b></span></div><div id="toast" role="status" data-testid="locked-level-message"></div></div>
<div class="scr" id="s-load" data-testid="loading-screen"><div class="bg"></div><div class="shade v"></div><div class="logo c"><div class="ldlogo" data-testid="loading-logo"><img alt="ANITS" src="assets/img/anits_logo.png"><i></i></div><i>COLLEGE SIMULATION</i></div>
 <div class="ld"><div id="ld-q" data-testid="loading-quote"></div><div class="ldbar"><div id="ld-f"></div></div><div id="ld-t" data-testid="loading-status">LOADING...</div></div></div>`;
const scr=id=>$(id),show=id=>{[...M.querySelectorAll('.scr')].forEach(s=>{if(s.id!==id){s.classList.remove('show');setTimeout(()=>{if(!s.classList.contains('show'))s.classList.remove('on')},650)}});const s=scr(id);s.classList.add('on');requestAnimationFrame(()=>requestAnimationFrame(()=>s.classList.add('show')))};
const type=(el,txt,ms,cb)=>{el.textContent='';let i=0;const t=setInterval(()=>{el.textContent=txt.slice(0,++i);if(i>=txt.length){clearInterval(t);cb&&cb()}},ms);return t};
const prof=()=>{try{return JSON.parse(LS.getItem('anits-profile'))}catch(e){return null}};
let P=prof(),sel=P&&P.char||'boy',yr=P&&[2023,2025].includes(+P.year)?+P.year:2024,unlocked=window.__progress.unlocked(INFO.length),real=unlocked,dev=LS.getItem('anits-dev')==='1';if(dev)unlocked=INFO.length;
window.__VOL=LS.getItem('anits-vol')==null?1:+LS.getItem('anits-vol');

/* ---- intro ---- */
let introT=[],introDone=false;
function intro(){if(window.LittleHeartIntro&&window.LittleHeartIntro.active){window.LittleHeartIntro.onEnd(endIntro);return}show('s-intro');
 introT.push(setTimeout(()=>introT.push(type($('lh-sub'),'Developed By Boss',85)),3300));
 introT.push(setTimeout(endIntro,7600));scr('s-intro').onclick=endIntro}
function endIntro(){if(introDone)return;introDone=true;introT.forEach(t=>{clearTimeout(t);clearInterval(t)});sessionStorage.setItem('anits-intro','1');
 P=prof();P&&P.name?welcome(true):yearSelect()}

/* ---- live 3D preview of the real player models ---- */
function preview(canvas,url,isAmy){const T=THREE;let ren,sc,cam,mix,obj,dead=false,t0=performance.now(),yr=2024,renderAt=0;const H={setYear(y){yr=y;obj&&window.__UNI.apply(obj,isAmy,y)},dispose(){dead=true;try{ren.dispose();ren.forceContextLoss()}catch(e){}}};
 try{ren=new T.WebGLRenderer({canvas,alpha:true,antialias:!window.__mobile,powerPreference:'low-power'});}catch(e){return H}
 sc=new T.Scene();cam=new T.PerspectiveCamera(28,1,.1,50);sc.add(new T.AmbientLight(0xffffff,1.1));const d=new T.DirectionalLight(0xffffff,1.3);d.position.set(2,4,4);sc.add(d);
 fetch(url).then(r=>r.arrayBuffer()).then(buf=>new T.GLTFLoader().parse(buf,'',gl=>{
  obj=gl.scene;obj.traverse(o=>{if(!o.isMesh)return;o.frustumCulled=false;(Array.isArray(o.material)?o.material:[o.material]).forEach(m=>{if(m.transparent&&m.opacity<=.01||m.alphaMode==='BLEND'||/Eyes|Brows|Mouth/i.test(m.name||'')){o.visible=false;return}m.metalness=0;m.roughness=.9;m.color.setRGB(1,1,1);if(m.map){m.emissiveMap=m.map;m.emissive.setRGB(.4,.4,.4)}m.needsUpdate=true})});
  obj.updateMatrixWorld(true);const bb=new T.Box3().setFromObject(obj),h=bb.max.y-bb.min.y,k=1.8/h;obj.scale.setScalar(k);obj.position.y=-bb.min.y*k;const g=new T.Group();g.add(obj);sc.add(g);obj.userData.g=g;window.__UNI.apply(obj,isAmy,yr);
  const clip=gl.animations.find(c=>c.name==='walk')||gl.animations[0];
  if(clip){clip.tracks.forEach(tr=>{if(/Hips\.position$/.test(tr.name)){const v=tr.values;for(let i=0;i<v.length/3;i++){v[i*3]=v[0];v[i*3+2]=v[2]}}});mix=new T.AnimationMixer(obj);mix.clipAction(clip).play()}
 },()=>{}));
 let last=performance.now();
 (function loop(){if(dead)return;requestAnimationFrame(loop);if(!M.querySelector('#s-char.show')||document.hidden)return;const w=canvas.clientWidth,h=canvas.clientHeight;if(!w||!h)return;
  const now=performance.now();if(window.__mobile&&now-renderAt<33)return;renderAt=now;
  const ppr=Math.min(devicePixelRatio,window.__mobile?1.25:2);if(canvas.width!==Math.round(w*ppr)){ren.setPixelRatio(ppr);ren.setSize(w,h,false);cam.aspect=w/h;cam.updateProjectionMatrix();cam.position.set(0,1.0,5.6);cam.lookAt(0,.92,0)}
  const dt=Math.min(.05,(now-last)/1000);last=now;if(mix)mix.update(dt);if(obj)obj.userData.g.rotation.y=Math.sin((now-t0)/1400)*.55+.25;ren.render(sc,cam)})();return H}
let prevDone=false,PV={};
const saveP=o=>LS.setItem('anits-profile',JSON.stringify(Object.assign({name:(prof()||{}).name||'',char:sel,year:yr},o)));
const YINFO={2023:['Rose Uniform','LIGHT PINK SHIRT \u00B7 BLACK PANTS','#f0a6c4','#16161b'],2024:['Classic Uniform','CREAM SHIRT \u00B7 BROWN PANTS','#e8dfc4','#3b2a1f'],2025:['New Uniform','SKY BLUE SHIRT \u00B7 NAVY PANTS','#87ceeb','#101a4a']};
function yearSelect(){show('s-year');const sl=$('ys');
 const upd=()=>{yr=+sl.value;const i=YINFO[yr];$('ys-yr').textContent=yr;$('ys-name').textContent=i[0];$('ys-desc').textContent=i[1];$('ys-c1').style.background=i[2];$('ys-c2').style.background=i[3];
  sl.style.setProperty('--p',((yr-2023)/2*100)+'%');[...M.querySelectorAll('#s-year .ticks button')].forEach(b=>b.classList.toggle('on',+b.dataset.y===yr))};
 sl.value=yr;upd();sl.oninput=upd;
 M.querySelectorAll('#s-year .ticks button').forEach(b=>b.onclick=()=>{sl.value=b.dataset.y;upd()});
 $('ys-go').onclick=()=>{saveP();charSelect()}}
function charSelect(){show('s-char');$('ch-yr').textContent=yr;$('ch-back').onclick=yearSelect;
 if(!prevDone){prevDone=true;PV.boy=preview($('c-boy').querySelector('canvas'),'assets/models/b_walk.bin');PV.girl=preview($('c-girl').querySelector('canvas'),'assets/models/cadet_amy.glb',true)}
 PV.boy&&PV.boy.setYear(yr);PV.girl&&PV.girl.setYear(yr);
 const mark=()=>{$('c-boy').classList.toggle('sel',sel==='boy');$('c-girl').classList.toggle('sel',sel==='girl')};mark();
 ['boy','girl'].forEach(c=>{$('c-'+c).onclick=()=>{sel=c;mark();saveP({char:c});setTimeout(nameScreen,450)}})}

/* ---- name + welcome ---- */
function nameScreen(){show('s-name');const nm=$('nm'),go=$('nm-go');nm.value=(prof()||{}).name||'';go.disabled=!nm.value.trim();setTimeout(()=>nm.focus(),700);
 nm.oninput=()=>{go.disabled=!nm.value.trim()};nm.onkeydown=e=>{e.stopPropagation();if(e.key==='Enter'&&nm.value.trim())go.click()};
 go.onclick=()=>{const n=nm.value.trim().slice(0,14);if(!n)return;saveP({name:n});P=prof();welcome(false)}}
function welcome(back){show('s-wel');$('wel3').classList.remove('on');$('wel2').textContent='';$('wel1').textContent='';
 type($('wel1'),back?'WELCOME BACK':'WELCOME',70,()=>{type($('wel2'),P.name,90,()=>{setTimeout(()=>$('wel3').classList.add('on'),150);setTimeout(mainMenu,3400)})})}

/* ---- main menu / settings / levels ---- */
const attBlocked=n=>!dev&&n>1&&n>=real&&window.__attendance.get()<window.__attendance.LIMIT;
const histPaint=()=>{const h=window.__attendance.history(),e=$('att-hist');if(!e)return;e.innerHTML=INFO.map((l,i)=>{const n=i+1,x=h[n];let st,c;if(n===8){st='NO CLASS';c='#8aa0c0'}else if(!x){st='NOT ATTENDED YET';c='#8aa0c0'}else if(x.r==='on'){st='ON TIME \u00B7 '+Math.round(x.a)+'%';c='#5dff9a'}else{st='LATE \u00B7 '+Math.round(x.a)+'%';c='#ff6b6b'}return '<div class="ah" data-testid="attendance-history-day-'+n+'"><span>DAY '+n+' \u00B7 '+l.n.toUpperCase()+'</span><b style="color:'+c+'">'+st+'</b></div>'}).join('')};
const attPaint=()=>{const a=window.__attendance.get(),b=$('att-big'),nt=$('att-note');if(b){b.textContent=Math.round(a)+'%';b.style.color=a>=75?'#5dff9a':a>=50?'#ffd54a':'#ff6b6b'}if(nt)nt.textContent=a<window.__attendance.LIMIT?'Below 75%: new levels are locked. Reach class on time to recover (+3% each).':'Reach class on time: +3%. Late: -5%. Keep it at 75% or above.';const e=$('att');if(!e)return;e.textContent='ATTENDANCE '+Math.round(a)+'%'+(a<window.__attendance.LIMIT?' \u00B7 LOW':'');e.style.color=a>=75?'#5dff9a':a>=50?'#ffd54a':'#ff6b6b'};
function mainMenu(){show('s-main');attPaint();$('who').textContent='PLAYING AS '+P.name+' \u00B7 '+(P.char==='girl'?'AMY':'MIKE')+' \u00B7 YEAR '+([2023,2025].includes(+P.year)?+P.year:2024);
 $('b-start').onclick=levels;$('b-how').onclick=()=>window.__tutorial&&window.__tutorial.startMenu(true);$('b-att').onclick=()=>{histPaint();attPaint();$('attm').classList.add('on')};$('att-ok').onclick=()=>$('attm').classList.remove('on');$('b-set').onclick=()=>{histPaint();$('set').classList.add('on')};$('st-ok').onclick=()=>$('set').classList.remove('on');
 const gq=()=>{let q=LS.getItem('anits-quality');return /^(low|med|high)$/.test(q||'')?q:'auto'};
 const gqMark=()=>[...M.querySelectorAll('#gq button')].forEach(x=>x.classList.toggle('on',x.dataset.q===gq()));
 M.querySelectorAll('#gq button').forEach(x=>x.onclick=()=>{x.dataset.q==='auto'?LS.removeItem('anits-quality'):LS.setItem('anits-quality',x.dataset.q);gqMark()});gqMark();
 $('vol').value=Math.round(window.__VOL*100);$('vol').oninput=e=>{window.__VOL=e.target.value/100;LS.setItem('anits-vol',window.__VOL)};
 $('st-dev').onclick=()=>{const b=$('dev-box');b.style.display=b.style.display==='none'?'block':'none';if(b.style.display==='block')$('dev-key').focus()};
 const chime=()=>{try{const C=new(window.AudioContext||window.webkitAudioContext)(),t=C.currentTime;[523.25,659.25,783.99,1046.5].forEach((f,k)=>{const o=C.createOscillator(),g=C.createGain();o.type='triangle';o.frequency.value=f;g.gain.setValueAtTime(0,t+k*.1);g.gain.linearRampToValueAtTime(.18,t+k*.1+.02);g.gain.exponentialRampToValueAtTime(.001,t+k*.1+.35);o.connect(g);g.connect(C.destination);o.start(t+k*.1);o.stop(t+k*.1+.4)});setTimeout(()=>C.close(),1200)}catch(e){}};
 const devUI=()=>{$('st-dev').textContent=dev?'DEV MODE: ON':'DEV MODE';$('dev-off').style.display=dev?'inline-block':'none';$('dev-in').style.display=dev?'none':'flex'};
 const devTry=()=>{const k=$('dev-key'),m=$('dev-msg');if(k.value.trim()==='11708'){dev=true;LS.setItem('anits-dev','1');unlocked=INFO.length;m.style.color='#5dff9a';m.textContent='DEV MODE ON - ALL '+INFO.length+' LEVELS UNLOCKED \u00B7 CLASS COUNTDOWN = 30s';chime();devUI()}else{m.style.color='#ff6b6b';m.textContent='WRONG KEY'}k.value=''};
 $('dev-off').onclick=()=>{dev=false;LS.removeItem('anits-dev');unlocked=real;const m=$('dev-msg');m.style.color='#ffd54a';m.textContent='DEV MODE OFF - PROGRESS KEPT (DAY '+real+' UNLOCKED)';devUI()};devUI();
 $('dev-go').onclick=devTry;$('dev-key').onkeydown=e=>{if(e.key==='Enter')devTry()};
 $('st-chg').onclick=()=>{$('set').classList.remove('on');yearSelect()};
 $('st-rst').onclick=()=>{window.__progress.reset();unlocked=1;real=1;dev=false;devUI();attPaint();histPaint();$('dev-msg').textContent='';$('st-rst').textContent='PROGRESS RESET'}}
function levels(){show('s-levels');const g=$('grid');g.innerHTML='';
 const U=unlocked;
 const positions=['55% 72%','12% 75%','62% 30%','92% 33%','82% 84%','28% 84%','70% 60%','40% 55%'];
 INFO.forEach((l,i)=>{const n=i+1,blk=n<=U&&attBlocked(n),open=n<=U&&!blk,d=document.createElement('div');d.className='lv'+(open?' open':'')+(n<U?' done':'');d.style.animationDelay=i*.05+'s';d.setAttribute('data-testid','level-card-'+n);d.setAttribute('role','button');d.tabIndex=0;d.setAttribute('aria-label','Day '+n+': '+l.n+(open?'':', locked'));d.setAttribute('aria-disabled',String(!open));
  d.innerHTML='<div class="im" style="background-position:'+positions[i]+'"></div>'+(open?'':ICON.lock)+'<div class="lb">DAY '+n+'<small>'+l.n+'</small></div>';
  d.onclick=()=>{if(open)startLevel(n);else{d.classList.remove('shake');void d.offsetWidth;d.classList.add('shake');const t=$('toast');t.textContent=blk?'Attendance below 75%. Replay an earlier day and reach class on time to raise it.':'Complete Day '+(n-1)+' to unlock this level';t.style.opacity=1;setTimeout(()=>t.style.opacity=0,1800)}};d.onkeydown=e=>{if(e.key==='Enter'||e.key===' '){e.preventDefault();d.click()}};g.appendChild(d)});
 $('lv-back').onclick=mainMenu}

/* ---- loading + boot ---- */
function startLevel(n){if(!Number.isInteger(n)||n<1||n>unlocked||n>INFO.length||attBlocked(n)){levels();return}P=P||{name:'Player',char:sel};show('s-load');window.__PROFILE=P;
 Object.values(PV).forEach(h=>h&&h.dispose&&h.dispose());PV={}; // free both preview GPU contexts before creating the main world
 const q=$('ld-q'),f=$('ld-f'),t=$('ld-t');let qi=Math.floor(Math.random()*QUOTES.length);
 const nextQ=()=>{q.style.opacity=0;setTimeout(()=>{q.textContent='\u201C'+QUOTES[qi++%QUOTES.length]+'\u201D';q.style.opacity=1},450)};nextQ();const qt=setInterval(nextQ,3600);
 t.className='';t.textContent='LOADING...  DAY '+n+' \u00B7 '+INFO[n-1].n.toUpperCase();
 window.__boot({char:P.char,year:P.year,lvl:n,onProgress:p=>{f.style.width=Math.round(p*90)+'%'}}).then(()=>new Promise(ok=>{const w=setInterval(()=>{const go=$('go');if(go&&!go.disabled){clearInterval(w);ok()}},120)})).then(()=>{
  f.style.width='100%';clearInterval(qt);t.className='go';t.textContent='CLICK ANYWHERE TO START';
  scr('s-load').onclick=()=>{scr('s-load').onclick=null;$('go').click();window.__inv&&__inv.enable();M.classList.add('gone');setTimeout(()=>M.style.display='none',700)}
 }).catch(e=>{console.error(e);t.textContent='Load error: '+e.message+' (serve over http, see README)'})}

/* ---- level complete hook (called by game.js finish) ---- */
window.__levelDone=n=>{if(!Number.isInteger(n)||n<1||n>unlocked||n>INFO.length||!window.__g||window.__g.lvl!==n)return;
 real=Math.min(INFO.length,Math.max(real,n+1));LS.setItem('anits-unlocked',real);unlocked=dev?INFO.length:real;
 const GIVE={1:'id',2:'fee',4:'lib',7:'lab',8:'nss'},it=GIVE[n];let got=null;if(it&&window.__inv&&__inv.give(it))got=it;const ov=$('ov'),old=$('lvl-btns');if(old)old.remove();const box=document.createElement('div');box.id='lvl-btns';box.style.cssText='display:flex;gap:12px;flex-wrap:wrap;justify-content:center;margin-top:6px';
 const mk=(label,go,tid)=>{const b=document.createElement('button');b.textContent=label;b.setAttribute('data-testid',tid);b.onclick=()=>{sessionStorage.setItem('anits-go',go);location.reload()};box.appendChild(b)};
 if(got){const w=document.createElement('div');w.style.cssText='display:flex;flex-direction:column;align-items:center;gap:8px;margin:6px 0 10px';w.setAttribute('data-testid','item-collected');w.innerHTML='<b style="letter-spacing:.2em;font-size:12px;color:#ffd54a">NEW ITEM COLLECTED: '+__inv.META[got].n.toUpperCase()+'</b>';w.appendChild(__inv.card(got));const s=document.createElement('small');s.style.opacity='.7';s.textContent='Find it in your inventory (press B)';w.appendChild(s);box.parentNode?0:0;ov.appendChild(w)}
 if(n===3)mk('Play Again','lvl3','play-again-btn');if(n<INFO.length)mk('Next Level (Day '+(n+1)+')','lvl'+(n+1),'next-level-btn');mk('Level Select','levels','level-select-btn');ov.appendChild(box)};

/* ---- entry ---- */
const go=sessionStorage.getItem('anits-go');sessionStorage.removeItem('anits-go');
const qs=new URLSearchParams(location.search);
if(qs.has('lvl')){const n=Number(qs.get('lvl'));if(Number.isInteger(n)&&n>=1&&n<=unlocked){P=prof()||{name:'Player',char:'boy'};startLevel(n)}else if(P&&P.name)levels();else intro()}
else if(go==='levels'&&P&&P.name){levels()}
else if(/^lvl\d+$/.test(go||'')&&P&&P.name){const n=Number(go.slice(3));if(n>=1&&n<=unlocked)startLevel(n);else levels()}
else if(qs.get('skip')&&P&&P.name){mainMenu()}
else intro();
})();
