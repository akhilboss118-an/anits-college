
(()=>{
const T=THREE,$=id=>document.getElementById(id);
const GIRL_P=window.__CHAR==='girl',FRIEND=GIRL_P?'Sushma':'Arjun';   // girl player -> best friend is Sushma
const css=document.createElement('style');
css.textContent=`
#call{position:fixed;inset:0;z-index:20;display:none;align-items:center;justify-content:center;gap:48px;padding:20px;background:radial-gradient(circle at 50% 45%,rgba(14,30,52,.55),rgba(4,8,16,.78));backdrop-filter:blur(5px);opacity:0;transition:opacity .35s}
#call.on{opacity:1}
#cl-stage{position:relative;width:min(340px,80vw);height:min(560px,60vh);flex:none}
#cl-stage canvas{position:absolute;inset:0;width:100%;height:100%;display:block}
.cl-ring{position:absolute;left:50%;top:50%;width:46%;aspect-ratio:1;border-radius:50%;border:2px solid #2fd36b;opacity:0;transform:translate(-50%,-50%) scale(.6);pointer-events:none}
#call.ring .cl-ring{animation:clr 2.2s ease-out infinite}#call.ring .cl-ring:nth-child(2){animation-delay:.7s}#call.ring .cl-ring:nth-child(3){animation-delay:1.4s}
@keyframes clr{0%{opacity:.8;transform:translate(-50%,-50%) scale(.6)}100%{opacity:0;transform:translate(-50%,-50%) scale(2.6)}}
#cl-panel{width:min(420px,92vw);color:#fff;text-align:left}
#cl-status{font-size:12px;letter-spacing:.2em;color:#2fd36b;font-weight:700;text-transform:uppercase}
#cl-name{font-size:40px;font-weight:800;margin:4px 0 2px;letter-spacing:-.01em}
#cl-sub{opacity:.7;font-size:15px;margin-bottom:18px}
#cl-acts{display:flex;gap:14px;margin-top:6px}
#cl-acts button,#cl-opts button,#cl-end{margin:0;font-size:16px;border-radius:999px;font-weight:700;transition:transform .15s,background-color .15s}
#cl-acts button:hover,#cl-opts button:hover,#cl-end:hover{transform:translateY(-2px)}
#cl-dec{background:#ff4d5a;color:#fff;padding:14px 26px}#cl-acc{background:#2fd36b;color:#06210f;padding:14px 32px;animation:claccp 1.1s infinite}
@keyframes claccp{0%,100%{box-shadow:0 0 0 0 rgba(47,211,107,.6)}50%{box-shadow:0 0 0 14px rgba(47,211,107,0)}}
#cl-talk{position:fixed;z-index:15;bottom:18px;left:50%;transform:translateX(-50%) translateY(30px);width:min(620px,calc(100vw - 440px));display:none;opacity:0;transition:opacity .35s,transform .35s;color:#fff;text-align:left}#cl-talk.on{opacity:1;transform:translateX(-50%)}
#cl-chip{position:fixed;z-index:15;top:96px;left:50%;transform:translateX(-50%);display:none;align-items:center;gap:10px;background:rgba(10,15,25,.8);border:1.5px solid #2fd36b;border-radius:999px;padding:7px 16px;font-size:13px;letter-spacing:.08em;color:#fff;white-space:nowrap}#cl-chip i{width:9px;height:9px;border-radius:50%;background:#ff4d5a;animation:clpulse 1s infinite}#cl-chip b{color:#7dff9a}@keyframes clpulse{50%{opacity:.25}}
@media(max-width:900px){#cl-talk{width:min(620px,94vw)}#cl-chip{top:auto;bottom:calc(100% - 100px);display:none!important}}
.cl-bub{background:rgba(10,15,25,.85);border:2px solid #ffd54a;border-radius:12px;padding:10px 14px;font-size:17px;line-height:1.4;min-height:48px;margin-bottom:8px}
.cl-bub.me{background:#2fd36b;border-color:#2fd36b;color:#06210f;margin-left:36px;font-weight:600;font-size:16px;min-height:0}
.cl-bub b{display:block;font-size:12px;letter-spacing:.12em;color:#ffd54a;margin-bottom:4px}
.cl-bub.me b{color:#06210f;opacity:.7}
#cl-opts{display:grid;grid-template-columns:1fr 1fr;gap:8px}@media(max-width:700px){#cl-opts{grid-template-columns:1fr}}
#cl-opts button{background:rgba(10,15,25,.85);color:#fff;border:1.5px solid rgba(255,255,255,.4);padding:10px 14px;text-align:left;font-size:14px;border-radius:12px;animation:clin .4s both;margin:0}
#cl-opts button:hover{background:#ffd54a;color:#222;border-color:#ffd54a}
@keyframes clin{from{opacity:0;transform:translateY(10px)}to{opacity:1;transform:none}}
#cl-caps{display:block;margin:0}
.cap{padding:6px 84px 6px 16px;border-radius:999px;font-size:14px;line-height:1.35;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;background:rgba(8,14,26,.78);border:1px solid #ffd54a;opacity:.5;transition:opacity .3s;animation:clin .35s both}
.cap.on{opacity:1}.cap.y{background:#2fd36b;color:#06210f;border-color:#2fd36b;font-weight:600}
.cap b{display:inline;font-size:11px;letter-spacing:.1em;opacity:.9;margin-right:7px}.cap.f b{color:#ffd54a}.cap.s{background:rgba(255,77,90,.9);border-color:#ff4d5a;text-align:center;font-weight:700}
#cl-end{position:absolute;right:5px;top:50%;transform:translateY(-50%)!important;background:#ff4d5a;color:#fff;padding:3px 14px;margin:0;font-size:11px!important;box-shadow:none;border-radius:999px}
body.touch #cl-talk,body.touch #cl-talk.on{left:calc(var(--sl) + var(--jr) + 14px);right:calc(var(--sr) + var(--jr) + var(--u)*1.3 + 30px);width:auto;transform:none;bottom:calc(var(--sb) - 4px)}body.touch .cap{font-size:13px;padding:5px 78px 5px 12px}
@media(max-width:900px){#call{flex-direction:column;gap:6px;padding:10px;overflow:auto;justify-content:flex-start}#cl-stage{height:min(300px,36vh);width:min(220px,60vw)}#cl-name{font-size:30px}#cl-sub{margin-bottom:8px}}
`;
document.head.appendChild(css);


const ov=document.createElement('div');ov.id='call';ov.setAttribute('data-testid','call-overlay');
ov.innerHTML=`<div id="cl-stage"><i class="cl-ring"></i><i class="cl-ring"></i><i class="cl-ring"></i><canvas id="cl-cv"></canvas></div>
<div id="cl-panel"><div id="cl-status" data-testid="call-status">Incoming call</div><div id="cl-name">${FRIEND}</div><div id="cl-sub">Best friend - mobile</div>
<div id="cl-acts"><button id="cl-dec" data-testid="call-decline-btn">Decline</button><button id="cl-acc" data-testid="call-accept-btn">Accept</button></div>
</div>`;
document.body.appendChild(ov);
const tk=document.createElement('div');tk.id='cl-talk';tk.setAttribute('data-testid','call-talk-panel');
tk.innerHTML='<div id="cl-caps" data-testid="call-captions"></div><button id="cl-end" data-testid="call-end-btn">End call</button>';
document.body.appendChild(tk);
const chip=document.createElement('div');chip.id='cl-chip';chip.setAttribute('data-testid','call-chip');chip.innerHTML='<i></i>ON CALL WITH <b>'+FRIEND.toUpperCase()+'</b><span id="cl-time">00:00</span>';document.body.appendChild(chip);
const el=id=>(ov.querySelector('#'+id)||tk.querySelector('#'+id)||chip.querySelector('#'+id));

/* ---------- audio ---------- */
let AC=null,ringT=0;
function tone(f,t0,d,v=.12,ty='sine'){if(!AC)return;const o=AC.createOscillator(),g=AC.createGain();o.type=ty;o.frequency.value=f;o.connect(g);g.connect(AC.destination);
 g.gain.setValueAtTime(0,t0);g.gain.linearRampToValueAtTime(v*(window.__SFX==null?1:window.__SFX),t0+.02);g.gain.linearRampToValueAtTime(0,t0+d);o.start(t0);o.stop(t0+d+.05)}
const RING=GIRL_P?{w:'sine',d:.22,v:.1,n:[[784,0],[988,.2],[1175,.4],[988,.6],[1319,.9],[1175,1.15],[988,1.4]]}:{w:'triangle',d:.15,v:.14,n:[[523,0],[659,.15],[784,.3],[1047,.45],[784,.75],[659,.9],[784,1.05],[1047,1.2]]};   // each friend has their own ringtone
function ringOnce(){if(!AC)return;const t=AC.currentTime;RING.n.forEach(([f,o])=>{tone(f,t+o,RING.d,RING.v,RING.w);tone(f/2,t+o,RING.d,RING.v*.4,'sine')});if(navigator.vibrate)navigator.vibrate([200,100,200])}
const startRing=()=>{stopRing();ringOnce();ringT=setInterval(ringOnce,2000)};
const stopRing=()=>{clearInterval(ringT);ringT=0;if(navigator.vibrate)navigator.vibrate(0)};
const blip=()=>{if(AC)tone(1200,AC.currentTime,.05,.04)};

/* ---------- 3D phone ---------- */
let R=null,scene,cam,pivot,holder,scrTex,scr,scrCtx,raf=0,state='off',tState=0,callSec=0,declines=0,talkAmp=0,clock=new T.Clock();
function makePhoneModel(){
 let g;
 try{const u=new Uint8Array(B_PHONE.slice(0)),s={length:u.length};g=new T.FBXLoader().parse(u.buffer,'')}catch(e){console.warn('phone fbx failed',e);g=new T.Mesh(new T.BoxGeometry(30,60,5),new T.MeshStandardMaterial({color:0x222222}))}
 g.quaternion.setFromAxisAngle(new T.Vector3(1,0,0),Math.PI/4);g.updateMatrixWorld(true);
 const b=new T.Box3().setFromObject(g,true),c=b.getCenter(new T.Vector3());let cb=null;
 g.traverse(o=>{if(o.isMesh&&o.name==='Phone_Case')cb=new T.Box3().setFromObject(o,true)});if(!cb)cb=b;
 const sz=cb.getSize(new T.Vector3()),faceZ=cb.max.z-c.z;
 g.position.sub(c);const w=new T.Group();w.add(g);
 return{g:w,cb,c,sz,faceZ}}
function buildPhone(){
 const cv=el('cl-cv');R=new T.WebGLRenderer({canvas:cv,alpha:true,antialias:false});R.setPixelRatio(Math.min(devicePixelRatio,1.25));
 scene=new T.Scene();cam=new T.PerspectiveCamera(30,1,.1,100);cam.position.set(0,0,10.5);
 scene.add(new T.AmbientLight(0xffffff,.9));const d1=new T.DirectionalLight(0xffffff,1.1);d1.position.set(3,4,6);scene.add(d1);const d2=new T.DirectionalLight(0x66ccff,.5);d2.position.set(-4,-1,3);scene.add(d2);
 pivot=new T.Group();holder=new T.Group();pivot.add(holder);scene.add(pivot);
 const {g,cb,c,sz,faceZ}=makePhoneModel();
 holder.add(g);holder.scale.setScalar(3.4/sz.y);
 g.traverse(o=>{if(o.isMesh&&o.material){(Array.isArray(o.material)?o.material:[o.material]).forEach(m=>{m.side=T.FrontSide})}});
 const cvs=document.createElement('canvas');cvs.width=256;cvs.height=512;scrCtx=cvs.getContext('2d');scrTex=new T.CanvasTexture(cvs);
 scr=new T.Mesh(new T.PlaneGeometry(sz.x*.88,sz.y*.93),new T.MeshBasicMaterial({map:scrTex}));scr.position.set(cb.getCenter(new T.Vector3()).x-c.x,cb.getCenter(new T.Vector3()).y-c.y,faceZ+.05);holder.add(scr);
}
function drawScreen(t){
 const x=scrCtx,W=256,H=512;const gr=x.createLinearGradient(0,0,0,H);gr.addColorStop(0,'#0e2a47');gr.addColorStop(1,'#050b16');x.fillStyle=gr;x.fillRect(0,0,W,H);
 x.textAlign='center';x.fillStyle='#fff';
 const ring=state==='ring'||state==='in';
 const pul=ring?Math.sin(t*6)*.5+.5:0;
 for(let i=0;i<3;i++){x.strokeStyle='rgba(47,211,107,'+(ring?.35-i*.1:.12)+')';x.lineWidth=3;x.beginPath();x.arc(W/2,170,52+i*20+pul*8*(ring?1:0),0,7);x.stroke()}
 x.fillStyle='#2fd36b';x.beginPath();x.arc(W/2,170,48,0,7);x.fill();x.fillStyle='#06210f';x.font='bold 56px sans-serif';x.textBaseline='middle';x.fillText(FRIEND[0],W/2,174);
 x.fillStyle='#fff';x.font='bold 30px sans-serif';x.fillText(FRIEND,W/2,258);
 x.font='16px sans-serif';x.fillStyle='#9fe8ff';
 const mm=String(Math.floor(callSec/60)).padStart(2,'0'),ss=String(Math.floor(callSec%60)).padStart(2,'0');
 x.fillText(state==='talk'?mm+':'+ss:state==='end'?'Call ended':state==='dec'?'Declined':'incoming call...',W/2,290);
 if(state==='talk'){x.fillStyle='#2fd36b';for(let i=0;i<15;i++){const h=6+Math.abs(Math.sin(t*9+i*1.3))*34*Math.min(1,talkAmp+.2);x.fillRect(30+i*13,340-h/2,7,h)}}
 if(state==='ring'||state==='in'||state==='dec'){x.fillStyle='#ff4d5a';x.beginPath();x.arc(72,430,30,0,7);x.fill();x.fillStyle='#2fd36b';x.beginPath();x.arc(184,430,30,0,7);x.fill();
  x.fillStyle='#fff';x.font='bold 22px sans-serif';x.fillText('✕',72,431);x.fillText('✓',184,431)}
 else{x.fillStyle='#ff4d5a';x.beginPath();x.arc(W/2,430,30,0,7);x.fill();x.fillStyle='#fff';x.font='bold 22px sans-serif';x.fillText('✕',W/2,431)}
 scrTex.needsUpdate=true;
}
function resize(){const s=el('cl-stage'),w=s.clientWidth,h=s.clientHeight;R.setSize(w,h,false);cam.aspect=w/h;cam.updateProjectionMatrix()}
function loop(){raf=requestAnimationFrame(loop);const dt=Math.min(clock.getDelta(),.05),t=clock.elapsedTime;tState+=dt;if(state==='talk')callSec+=dt;
 const e=1-Math.pow(.001,dt);
 if(state==='in'){const k=Math.min(1,tState/.7),ee=1-Math.pow(1-k,3);pivot.position.y=-5*(1-ee);pivot.rotation.y=(1-ee)*Math.PI*3+Math.sin(t)*.05;pivot.rotation.z=0;pivot.scale.setScalar(.5+.5*ee);if(k>=1){state='ring';tState=0}}
 else if(state==='ring'||state==='dec'){const ph=t%2.2,sh=ph<1.1?1:.15;pivot.rotation.z=Math.sin(t*38)*.07*sh;pivot.rotation.y=Math.sin(t*2.2)*.35+Math.sin(t*31)*.03*sh;pivot.rotation.x=Math.sin(t*27)*.04*sh;pivot.position.y=Math.sin(t*3)*.08;pivot.position.x=Math.sin(t*41)*.06*sh}
 else if(state==='talk'){pivot.rotation.z+=(0-pivot.rotation.z)*e;pivot.rotation.x+=(.06-pivot.rotation.x)*e;pivot.rotation.y+=(Math.sin(t*.9)*.18-pivot.rotation.y)*e;pivot.position.x+=(0-pivot.position.x)*e;pivot.position.y=Math.sin(t*1.6)*.1;talkAmp+=(.0-talkAmp)*e}
 else if(state==='end'){const k=Math.min(1,tState/.5);pivot.position.y=-6*k*k;pivot.rotation.y+=dt*8;pivot.scale.setScalar(Math.max(.01,1-k*.6));pivot.rotation.z=0}
 drawScreen(t);R.render(scene,cam)}

/* ---------- typewriter ---------- */
let twT=0;function type(node,txt,done){clearInterval(twT);node.textContent='';let i=0;talkAmp=1;twT=setInterval(()=>{node.textContent=txt.slice(0,++i);if(i%2)blip();talkAmp=1;if(i>=txt.length){clearInterval(twT);done&&done()}},28)}

/* ---------- flow ---------- */
const canCall=()=>!window.__call&&!window.__paused&&!(window.__mini&&window.__mini.active)&&$('ov').style.display==='none'&&$('shop').style.display!=='block'&&$('dlg').style.display!=='block';
function open(){
 if(!canCall())return;window.__call=true;
 try{AC=AC||new(window.AudioContext||window.webkitAudioContext)();AC.resume&&AC.resume()}catch(e){}
 if(!R)buildPhone();
 declines=0;ov.style.display='flex';requestAnimationFrame(()=>ov.classList.add('on'));ov.classList.add('ring');
 el('cl-status').textContent='Incoming call';el('cl-sub').textContent='Best friend - mobile';el('cl-acts').style.display='flex';
 resize();state='in';tState=0;callSec=0;clock.start();cancelAnimationFrame(raf);loop();startRing();
}
function decline(){stopRing();state='dec';tState=0;declines++;ov.classList.remove('ring');el('cl-status').textContent='Declined';el('cl-sub').textContent=FRIEND+' is calling back...';
 setTimeout(()=>{if(state!=='dec')return;state='ring';tState=0;ov.classList.add('ring');el('cl-status').textContent=declines>1?'Calling AGAIN!':'Incoming call';el('cl-sub').textContent=declines>1?FRIEND+' will not stop until you pick up':'Pick up yaar!';startRing()},1500)}
let hand=null,prop=null,timeT=0;
function attachPhone(){const G=window.__g;if(!G||!G.boy)return;
 G.boy.traverse(o=>{if(o.isBone&&/RightHand$/.test(o.name))hand=o});if(!hand)return;
 const m=makePhoneModel(),h=new T.Group();h.add(m.g);const ws=new T.Vector3();hand.getWorldScale(ws);
 const k=PH.size/m.sz.y/ws.x;h.scale.setScalar(k);h.position.set(PH.px,PH.py,PH.pz).multiplyScalar(1/ws.x);h.rotation.set(PH.rx,PH.ry,PH.rz);hand.add(h);prop=h}
function detachPhone(){if(prop&&prop.parent)prop.parent.remove(prop);prop=null}
const PH=window.__PH={size:.2,px:0,py:.07,pz:0,rx:0,ry:0,rz:0};
function accept(){if(state!=='ring'&&state!=='dec'&&state!=='in')return;stopRing();state='talk';callSec=0;ov.classList.remove('ring','on');
  setTimeout(()=>{if(state==='talk'){ov.style.display='none';cancelAnimationFrame(raf)}},380);
  window.__phoneTalk=true;attachPhone();const G=window.__g;if(G){G.cy=G.pl.yaw+Math.PI-.55;G.cp=.28}
  chip.style.display='flex';tk.style.display='block';requestAnimationFrame(()=>tk.classList.add('on'));
  let tsec=0;timeT=setInterval(()=>{tsec++;el('cl-time').textContent=String(Math.floor(tsec/60)).padStart(2,'0')+':'+String(tsec%60).padStart(2,'0')},1000);el('cl-time').textContent='00:00';
  el('cl-caps').innerHTML='';runConvo(buildConvo())}
const pick=a=>a[Math.floor(Math.random()*a.length)];
const POOL=window.__POOL[GIRL_P?'girl':'boy'],UK='anits-callused2-'+(GIRL_P?'g':'b'),used=(()=>{try{return JSON.parse(localStorage.getItem(UK))||{}}catch(e){return{}}})();
const pickN=(k,a)=>{const u=used[k]||(used[k]=[]);let c=a.map((_,i)=>i).filter(i=>!u.includes(i));if(!c.length){u.length=0;c=a.map((_,i)=>i)}const i=pick(c);u.push(i);try{localStorage.setItem(UK,JSON.stringify(used))}catch(e){}return a[i]};
function buildConvo(){const F='f',Y='y',op=pickN('o',POOL.opens),q=pickN('q',POOL.qs),[a,r]=pick(q.o),en=pickN('e',POOL.ends),mids=[];
  for(let i=Math.random()<.5?1:2;i>0;i--)mids.push(pickN('m',POOL.mids));
  return [[F,pickN('h',POOL.hellos)],[F,op[0]],[Y,op[1]],[F,q.q],[Y,a],[F,r],...mids.flatMap(m=>[[F,m[0]],[Y,m[1]],[F,m[2]]]),[Y,en[0]],[F,en[1]],[Y,en[2]]]}
let runTok=0;
let capA=null;
function addCap(who,txt){const c=el('cl-caps'),d=document.createElement('div');d.className='cap '+who+' on';d.setAttribute('data-testid','call-caption-'+(who==='y'?'you':who==='f'?'friend':'system'));
  if(capA)capA.cancel();c.innerHTML='';c.appendChild(d);   // a single small line, shown piece by piece
  if(who==='s'){d.textContent=txt;return}
  const nm=(who==='y'?'YOU':FRIEND.toUpperCase())+':',ch=window.__subs.chunks(window.__sub?window.__sub(txt):txt,d,nm);let k=0;
  const tick=()=>{d.innerHTML='<b></b><span></span>';d.firstChild.textContent=nm;d.lastChild.textContent=ch[k];capA=window.__after(window.__subs.dur(ch[k]),()=>{if(++k<ch.length)tick()})};tick()}
function runConvo(lines){const tok=++runTok;let i=0;
  const step=()=>{if(tok!==runTok||state!=='talk')return;
   if(i>=lines.length){addCap('s',FRIEND+' ended the call');setTimeout(()=>{if(tok===runTok)end()},1400);return}
   const [w,t]=lines[i++];addCap(w,t);talkAmp=1;
   window.__voice.speak(GIRL_P?(w==='y'?'youF':'sushma'):(w==='y'?'you':'arjun'),w==='y'?'You':FRIEND,t,()=>{if(tok===runTok)setTimeout(step,300+Math.random()*250)})};
  setTimeout(step,700)}
function end(){runTok++;window.__voice&&__voice.stop();if(state==='end')return;stopRing();clearInterval(twT);clearInterval(timeT);state='end';tk.classList.remove('on');chip.style.display='none';detachPhone();window.__phoneTalk=false;
 const G=window.__g;if(G){G.cy=G.pl.yaw;G.cp=.3}
 setTimeout(()=>{tk.style.display='none';window.__call=false},400)}
el('cl-acc').onclick=accept;el('cl-dec').onclick=decline;el('cl-end').onclick=end;
addEventListener('resize',()=>{if(R&&window.__call)resize()});
addEventListener('keydown',e=>{if(e.code==='Escape'&&window.__call&&state==='talk'&&tk.style.display==='block')end()});
const G=()=>window.__g;
const initAC=()=>{try{AC=AC||new(window.AudioContext||window.webkitAudioContext)()}catch(e){}};
addEventListener('pointerdown',initAC);addEventListener('keydown',initAC);
const callsLeft=()=>G()&&(G().lvl>1?G().si>=2&&G().si<5:G().si<5);
const canAuto=()=>canCall()&&callsLeft()&&G()&&!G().dlg&&!G().saluting&&!G().shopOpen&&!G().drinking;
let nCalls=0;
function schedule(sec){setTimeout(function tryCall(){if(!callsLeft()||window.__buddyDay)return;if(canAuto()){nCalls++;open()}else setTimeout(tryCall,2000)},sec*1000)}
const q0=+new URLSearchParams(location.search).get('callin');
const startWait=setInterval(()=>{if($('ov').style.display==='none'){clearInterval(startWait);schedule(q0||(18+Math.random()*20))}},500);
window.__nextCall=schedule;
window.__callTest={open,accept,decline,end,get prop(){return prop},get hand(){return hand},reattach(){detachPhone();attachPhone()}};
})();

