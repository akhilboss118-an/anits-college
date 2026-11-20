/* Day 8: NSS Cleaning Volunteer. No NPCs, NCC cadets removed, NSS Commander briefing at the basketball ground,
   7-member team (you + 6 friends), 100 pieces of trash to collect before the timer ends, rating, participation certificate.
   Loaded last by assets.js; does nothing on other levels. Uses window.__g (exports from game.js). */
(()=>{
if(window.__LVL!==8)return;
const $=id=>document.getElementById(id),T=THREE;
const TIME=360,PICK_R=1.5,FRIEND_SPEED=2.8,BAG_MAX=10,BIN_R=2.4,BIN_PTS=5;
const ZONES=[{k:'bask',label:'Basketball Ground',short:'Basketball',n:16},{k:'ncc',label:'NCC Ground',short:'NCC Ground',n:22},{k:'blocks',label:'Blocks',short:'Blocks',n:30},{k:'roads',label:'Roads',short:'Roads',n:32}];
const BANTER=["Got it!","One more for ANITS!","Not Me, But You!","Clean campus, green campus!","Team NSS rocks!","Who throws trash here?!","Keep going, team!","Bag it up!"];
const css=document.createElement('style');css.textContent=`
body.nss #mission-pin{display:none!important}
#nss-hud{position:fixed;top:10px;left:50%;transform:translateX(-50%);z-index:9;display:none;flex-direction:column;align-items:center;gap:6px;pointer-events:none;font-family:'Figtree',system-ui,sans-serif;color:#fff}
#nss-hud .r1{display:flex;gap:10px;align-items:center}
#nss-hud .pill{padding:6px 16px;border-radius:999px;background:rgba(8,14,26,.84);border:1.5px solid #ffd54a;font:800 17px 'Figtree',system-ui,sans-serif;letter-spacing:.08em;white-space:nowrap}
#nss-hud .pill.low{color:#ff6b6b;border-color:#ff6b6b}#nss-hud .pill.g{border-color:#3ce678}#nss-hud .pill.b{border-color:#4fc0ff}#nss-hud .pill.b.full{color:#ff9f1a;border-color:#ff9f1a}
#nss-hud .zs{display:flex;gap:6px;flex-wrap:wrap;justify-content:center}
#nss-hud .z{padding:3px 10px;border-radius:999px;background:rgba(8,14,26,.74);border:1px solid rgba(120,190,255,.55);font:700 11px 'Figtree',system-ui,sans-serif;letter-spacing:.05em;white-space:nowrap}
#nss-hud .z.ok{border-color:#3ce678;color:#8dffb0}
#nss-hud .who{font:700 11px 'Figtree',system-ui,sans-serif;letter-spacing:.1em;padding:2px 12px;border-radius:999px;background:rgba(8,14,26,.6)}
body.touch #nss-hud{top:6px}body.touch #nss-hud .pill{font-size:13px;padding:4px 10px}body.touch #nss-hud .z{font-size:9px;padding:2px 7px}
#nss-end{position:fixed;inset:0;z-index:50;display:none;align-items:center;justify-content:center;background:rgba(3,10,24,.84);backdrop-filter:blur(6px);font-family:'Figtree',system-ui,sans-serif;color:#fff;padding:14px}
#nss-end .bx{width:min(560px,94vw);max-height:94vh;overflow:auto;padding:24px 26px;border-radius:20px;text-align:center;background:linear-gradient(160deg,rgba(10,32,70,.97),rgba(5,14,34,.97));border:1.5px solid #3aa0ff;box-shadow:0 0 44px rgba(40,140,255,.35)}
#nss-end h2{margin:0;font:900 30px 'Bricolage Grotesque',sans-serif;letter-spacing:.08em}#nss-end h2.w{color:#6dff9f}#nss-end h2.l{color:#ffd54a}
#nss-end .st{font-size:38px;letter-spacing:.2em;margin:8px 0 2px;color:#ffd54a}#nss-end .st i{font-style:normal;opacity:.25}#nss-end .st i.on{opacity:1}
#nss-end .rl{font:800 15px 'Figtree';letter-spacing:.18em;color:#7cc4ff;margin-bottom:12px}
#nss-end .g{display:grid;grid-template-columns:1fr 1fr;gap:8px;margin:10px 0 16px;text-align:left}
#nss-end .g div{padding:8px 12px;border-radius:10px;background:rgba(255,255,255,.06);border:1px solid rgba(120,190,255,.25);font-size:13px}#nss-end .g b{display:block;font-size:19px;color:#ffd54a}
#nss-end .bt{display:flex;gap:10px;justify-content:center;flex-wrap:wrap}
#nss-end button{padding:12px 26px;border-radius:999px;border:0;background:#ffd54a;color:#111;font:800 15px 'Figtree',sans-serif;letter-spacing:.06em;cursor:pointer}
#nss-end button.o{background:transparent;color:#fff;border:1.5px solid #6cc0ff}#nss-end button.g2{background:#2fd36b;color:#06210f}
#nss-cert{position:fixed;inset:0;z-index:51;display:none;flex-direction:column;align-items:center;justify-content:center;gap:12px;background:rgba(3,10,24,.9);padding:12px}
#nss-cert canvas{max-width:min(94vw,calc((100vh - 90px)*1.414));height:auto;border-radius:6px;box-shadow:0 10px 50px rgba(0,0,0,.6)}
#nss-cert .bt{display:flex;gap:10px}#nss-cert button{padding:11px 24px;border-radius:999px;border:0;background:#ffd54a;color:#111;font:800 15px 'Figtree',sans-serif;cursor:pointer}#nss-cert button.g2{background:#2fd36b;color:#06210f}
`;document.head.appendChild(css);document.body.classList.add('nss');

const boot=setInterval(()=>{if(window.__g&&window.__g.npcs&&window.__g.NPC&&window.__g.NPC.nss&&window.__nssTeam){clearInterval(boot);init(window.__g)}},100);

function init(g){
const pl=g.pl,npcs=g.npcs,sc=g.sc,rnd=Math.random;
const team=window.__nssTeam,cmd=g.NPC.nss,GIRL=window.__CHAR==='girl';
const pname=()=>(window.__PROFILE&&window.__PROFILE.name)||(GIRL?'Amy':'Mike');

/* ---- sounds (synthesised, no files) ---- */
let AX=null,NB=null;
const ax=()=>{try{if(!AX){AX=new(window.AudioContext||window.webkitAudioContext)();const l=AX.sampleRate*.6,b=AX.createBuffer(1,l,AX.sampleRate),d=b.getChannelData(0);for(let i=0;i<l;i++)d[i]=Math.random()*2-1;NB=b}if(AX.state==='suspended')AX.resume();return AX}catch(e){return null}};
const vol=()=>window.__VOL==null?1:window.__VOL;
function noise(t0,dur,type,f0,f1,v,q){const A=ax();if(!A)return;const s=A.createBufferSource();s.buffer=NB;s.loop=true;const fl=A.createBiquadFilter();fl.type=type;fl.Q.value=q||1;fl.frequency.setValueAtTime(f0,t0);fl.frequency.linearRampToValueAtTime(f1,t0+dur);
 const gn=A.createGain();gn.gain.setValueAtTime(0,t0);gn.gain.linearRampToValueAtTime(v*vol(),t0+Math.min(.04,dur/3));gn.gain.exponentialRampToValueAtTime(.0008,t0+dur);s.connect(fl);fl.connect(gn);gn.connect(A.destination);s.start(t0);s.stop(t0+dur+.05)}
function tone(t0,f0,f1,dur,v,type){const A=ax();if(!A)return;const o=A.createOscillator(),gn=A.createGain();o.type=type||'sine';o.frequency.setValueAtTime(f0,t0);o.frequency.exponentialRampToValueAtTime(f1,t0+dur);
 gn.gain.setValueAtTime(v*vol(),t0);gn.gain.exponentialRampToValueAtTime(.0008,t0+dur);o.connect(gn);gn.connect(A.destination);o.start(t0);o.stop(t0+dur+.05)}
function rustle(k){const A=ax();if(!A)return;const t=A.currentTime;noise(t,.2,'bandpass',2600+Math.random()*1800,5200,.22*k,.9);noise(t+.07,.14,'highpass',4200,6500,.1*k,.7)}
function binThunk(){const A=ax();if(!A)return;const t=A.currentTime;tone(t,170,55,.28,.34,'sine');noise(t,.16,'lowpass',1400,500,.3,.8);tone(t+.05,1750,1250,.22,.07,'triangle');tone(t+.11,1180,900,.2,.05,'triangle')}
function cheer(){const A=ax();if(!A)return;const t=A.currentTime;noise(t,2.4,'bandpass',900,1500,.22,.6);noise(t+.2,1.9,'bandpass',1800,2600,.1,.8);
 for(let i=0;i<14;i++){const tt=t+Math.random()*1.4;noise(tt,.07,'highpass',2500,4000,.18,.5)}
 [0,1,2,3,4,5].forEach(i=>tone(t+.05+i*.11,300+i*45,520+i*60,.7,.05,'sawtooth'));
 const c=window.__CLIPS&&window.__CLIPS['Jai Hind!'],src=c?(typeof c==='string'?c:c[1]):null;
 if(src)[0,1,2,3,4,5].forEach(i=>setTimeout(()=>{try{const a=new Audio(src);a.preservesPitch=false;a.mozPreservesPitch=false;a.webkitPreservesPitch=false;a.playbackRate=.88+i*.06;a.volume=.5*vol();const p=a.play();if(p&&p.catch)p.catch(()=>{})}catch(e){}},500+i*130))}

/* ---- no NPCs, no NCC cadets ---- */
npcs.forEach(n=>{if(n===cmd||team.includes(n))return;n.off=true;n.nt=true;if(n.g)n.g.visible=false;if(n.lab)n.lab.visible=false});
g.NCCs.length=0;
team.forEach(n=>{const i=g.circles.indexOf(n);if(i>=0)g.circles.splice(i,1)});

/* ---- team look: caps + vests (NSS volunteers) ---- */
const deco=(n,vc,cc)=>{if(!n.g)return;const vest=new T.Mesh(new T.CylinderGeometry(.2,.19,.42,14,1,true),new T.MeshLambertMaterial({color:vc,side:T.DoubleSide}));vest.position.y=1.2;vest.scale.z=.78;
 const cap=new T.Mesh(new T.SphereGeometry(.125,12,8,0,Math.PI*2,0,Math.PI/2),new T.MeshLambertMaterial({color:cc}));cap.position.y=1.66;n.g.add(vest,cap)};
deco(cmd,0x14306e,0x14306e);team.forEach(n=>deco(n,0xff7a00,0x14306e));

/* ---- start positions at the basketball ground ---- */
const CX=g.wx(300),CZ=g.wz(282.5);
cmd.x=CX+3;cmd.z=CZ;cmd.yaw=-Math.PI/2;
team.forEach((n,i)=>{const a=(-60+i*24)*Math.PI/180;n.x=cmd.x-3.6*Math.cos(a);n.z=cmd.z+3.6*Math.sin(a);n.yaw=Math.atan2(cmd.x-n.x,cmd.z-n.z)});
pl.x=CX-7;pl.z=CZ+.5;pl.yaw=Math.PI/2;g.cy=Math.PI/2;g.cp=.3;

/* ---- start overlay text ---- */
$('h1').textContent='Day 8 - NSS Cleaning Volunteer';
$('ovp').textContent='Join the NSS special camp. Meet the NSS Commander at the basketball ground, then clean the basketball ground, the NCC ground, the blocks and the roads with your team of 7 before time runs out. Every volunteer earns a participation certificate. Walk over trash to pick it up, then drop your bag in the green dustbins for bonus points!';

/* ---- trash ---- */
const inB=(x,z)=>g.BLD.some(b=>x>g.wx(b[1])-.8&&x<g.wx(b[3])+.8&&z>g.wz(b[2])-.8&&z<g.wz(b[4])+.8);
const okPt=(x,z,list)=>{if(x<g.wx(40)||x>g.wx(388)||z<g.wz(44)||z>g.wz(470))return false;if(inB(x,z))return false;
 if(g.localColliders(x,z).some(c=>x>c.x0-.7&&x<c.x1+.7&&z>c.z0-.7&&z<c.z1+.7))return false;
 if(g.groundHeightAt(x,z)>.6)return false;
 if(Math.hypot(x-cmd.x,z-cmd.z)<5)return false;
 return !list.some(t=>Math.hypot(t.x-x,t.z-z)<2.6)};
const rr=(a,b)=>a+rnd()*(b-a);
const sampler={
 bask:()=>[rr(263,337),rr(254,311)],
 ncc:()=>rnd()<.55?[rr(150,246),rr(360,424)]:[rr(253,362),rr(323,412)],
 blocks:()=>{const b=g.BLD[Math.floor(rnd()*g.BLD.length)],m=rr(2,8),s=Math.floor(rnd()*4);
  return s===0?[rr(b[1]-m,b[3]+m),b[2]-m]:s===1?[rr(b[1]-m,b[3]+m),b[4]+m]:s===2?[b[1]-m,rr(b[2]-m,b[4]+m)]:[b[3]+m,rr(b[2]-m,b[4]+m)]},
 roads:()=>{const r=g.ROADS[Math.floor(rnd()*g.ROADS.length)];return[rr(r[0]+2,r[2]-2),rr(r[1]+2,r[3]-2)]}};
const items=[];
ZONES.forEach(z=>{let made=0,tries=0;while(made<z.n&&tries++<1500){const[px,py]=sampler[z.k]();const x=g.wx(px),z2=g.wz(py);
 if(!okPt(x,z2,items))continue;items.push({x,z:z2,y:g.groundHeightAt(x,z2),zone:z.k,type:Math.floor(rnd()*4),alive:true,by:null,rot:rnd()*6.28});made++}});
const N=items.length;
const zoneTot={};ZONES.forEach(z=>zoneTot[z.k]=items.filter(i=>i.zone===z.k).length);
const zoneGot={bask:0,ncc:0,blocks:0,roads:0};
const mat=(c,o)=>new T.MeshLambertMaterial(Object.assign({color:c},o||{}));
const GEO=[new T.IcosahedronGeometry(.19,0),new T.CylinderGeometry(.09,.09,.44,8).rotateZ(Math.PI/2),new T.CylinderGeometry(.1,.1,.22,8),new T.BoxGeometry(.36,.06,.26)];
const MAT=[mat(0xf4f1e6),mat(0x58c8ff,{transparent:true,opacity:.85}),mat(0xb9bec8),mat(0xe0503a)];
const meshes=GEO.map((ge,t)=>{const c=items.filter(i=>i.type===t).length,m=new T.InstancedMesh(ge,MAT[t],Math.max(1,c));m.frustumCulled=false;m.castShadow=false;sc.add(m);return m});
const ringM=new T.InstancedMesh(new T.RingGeometry(.55,.8,22).rotateX(-Math.PI/2),new T.MeshBasicMaterial({color:0xffe14a,transparent:true,opacity:.6,depthWrite:false,polygonOffset:true,polygonOffsetFactor:-3,polygonOffsetUnits:-3}),N);
const beamM=new T.InstancedMesh(new T.CylinderGeometry(.05,.05,3.4,6).translate(0,1.7,0),new T.MeshBasicMaterial({color:0xffd54a,transparent:true,opacity:.4,depthWrite:false}),N);
[ringM,beamM].forEach(m=>{m.frustumCulled=false;sc.add(m)});
const idx=[0,0,0,0],M4=new T.Matrix4(),Q=new T.Quaternion(),S1=new T.Vector3(1,1,1),P=new T.Vector3(),E=new T.Euler(),ZERO=new T.Matrix4().makeScale(0,0,0);
items.forEach((it,i)=>{it.i=i;it.j=idx[it.type]++;E.set(it.type===3?0:rnd()*.6,it.rot,it.type===2?rnd()*1.5:0);Q.setFromEuler(E);
 const sc1=1.7;P.set(it.x,it.y+.16,it.z);S1.set(sc1,sc1,sc1);M4.compose(P,Q,S1);meshes[it.type].setMatrixAt(it.j,M4);
 P.set(it.x,it.y+.07,it.z);S1.set(1,1,1);Q.identity();M4.compose(P,Q,S1);ringM.setMatrixAt(i,M4);
 P.set(it.x,it.y,it.z);beamM.setMatrixAt(i,M4)});
[...meshes,ringM,beamM].forEach(m=>m.instanceMatrix.needsUpdate=true);

let phase='brief',left=TIME,youN=0,teamN=0,lastBanter=0,finished=false,bag=0,dropped=0,lastFull=0;
const total=()=>youN+teamN,score=()=>total()*10+dropped*BIN_PTS;
function remove(it,by){if(!it.alive)return;it.alive=false;it.by=null;meshes[it.type].setMatrixAt(it.j,ZERO);ringM.setMatrixAt(it.i,ZERO);beamM.setMatrixAt(it.i,ZERO);
 meshes[it.type].instanceMatrix.needsUpdate=ringM.instanceMatrix.needsUpdate=beamM.instanceMatrix.needsUpdate=true;
 zoneGot[it.zone]++;if(by==='you'){youN++;bag++;rustle(1);g.snd(1100,.06,'triangle',.03)}else{teamN++;rustle(.3)}
 hud()}

/* ---- dustbins: drop your bag here for bonus points ---- */
const bins=[];
[[268,262],[334,300],[200,372],[300,395],[180,342],[243,200],[170,242],[80,250],[122,400],[243,110]].forEach(([px,py])=>{
 for(let t=0;t<40;t++){const x=g.wx(px+(t?rr(-7,7):0)),z=g.wz(py+(t?rr(-7,7):0));if(okPt(x,z,items.concat(bins))){bins.push({x,z,y:g.groundHeightAt(x,z)});break}}});
{const body=new T.MeshLambertMaterial({color:0x1f9d55}),lid=new T.MeshLambertMaterial({color:0x14683a}),band=new T.MeshLambertMaterial({color:0xf4f1e6});
 bins.forEach(b=>{const gp=new T.Group();
  const c=new T.Mesh(new T.CylinderGeometry(.42,.34,1,14),body);c.position.y=.55;const bd=new T.Mesh(new T.CylinderGeometry(.435,.435,.16,14,1,true),band);bd.position.y=.62;bd.material=new T.MeshLambertMaterial({color:0xf4f1e6,side:T.DoubleSide});
  const l=new T.Mesh(new T.CylinderGeometry(.46,.46,.1,14),lid);l.position.y=1.1;
  const bm=new T.Mesh(new T.CylinderGeometry(.06,.06,4.2,6).translate(0,2.1,0),new T.MeshBasicMaterial({color:0x35e07a,transparent:true,opacity:.42,depthWrite:false}));
  const rg=new T.Mesh(new T.RingGeometry(BIN_R-.35,BIN_R,28).rotateX(-Math.PI/2),new T.MeshBasicMaterial({color:0x35e07a,transparent:true,opacity:.4,depthWrite:false,polygonOffset:true,polygonOffsetFactor:-3,polygonOffsetUnits:-3}));rg.position.y=.07;
  [c,bd,l].forEach(m=>{m.castShadow=true});gp.add(c,bd,l,bm,rg);gp.position.set(b.x,b.y,b.z);sc.add(gp);b.g=gp;b.lid=l})}
function dropBag(b){const n=bag;bag=0;dropped+=n;binThunk();if(b.lid){b.lid.position.y=1.28;setTimeout(()=>{b.lid.position.y=1.1},220)}
 g.say('Dustbin: '+n+' piece'+(n>1?'s':'')+' dropped. Bonus +'+(n*BIN_PTS)+' points!');hud()}

/* ---- HUD ---- */
const hudEl=document.createElement('div');hudEl.id='nss-hud';hudEl.setAttribute('data-testid','nss-hud');
hudEl.innerHTML='<div class="r1"><span class="pill" id="nss-time" data-testid="nss-timer"></span><span class="pill g" id="nss-count" data-testid="nss-trash-counter"></span><span class="pill b" id="nss-bag" data-testid="nss-bag-counter"></span></div><div class="zs" id="nss-zs" data-testid="nss-zones"></div><div class="who" id="nss-who" data-testid="nss-team-score"></div>';
document.body.appendChild(hudEl);
const fmt=s=>Math.floor(s/60)+':'+String(Math.floor(s%60)).padStart(2,'0');
function hud(){$('nss-time').textContent='TIME '+fmt(Math.max(0,left));$('nss-time').classList.toggle('low',left<60);
 $('nss-count').textContent='TRASH '+total()+' / '+N;$('nss-bag').textContent='BAG '+bag+' / '+BAG_MAX;$('nss-bag').classList.toggle('full',bag>=BAG_MAX);
 $('nss-zs').innerHTML=ZONES.map(z=>'<span class="z'+(zoneGot[z.k]>=zoneTot[z.k]?' ok':'')+'" data-testid="nss-zone-'+z.k+'">'+z.short+' '+zoneGot[z.k]+'/'+zoneTot[z.k]+'</span>').join('');
 $('nss-who').textContent='YOU '+youN+'  \u00B7  TEAM OF 6: '+teamN+'  \u00B7  BIN BONUS +'+(dropped*BIN_PTS)+'  \u00B7  SCORE '+score()}

/* ---- friends (team of 6 follow and help) ---- */
const claimed=new Set();
function banter(n){const now=performance.now();if(now-lastBanter<4500||rnd()>.18)return;lastBanter=now;g.say(n.name.replace(/\s*\(.*$/,'')+': '+BANTER[Math.floor(rnd()*BANTER.length)])}
function mkCtl(n,i){n.fs={tgt:null,t:0,pause:0,ban:new Map()};
 n.ctl=dt=>{const f=n.fs;n.mv=false;if(g.done||finished||phase==='brief'){return}
  if(phase!=='clean')return;
  const now=performance.now();
  if(f.tgt&&!f.tgt.alive){f.tgt=null}
  if(!f.tgt){let best=null,bd=1e9;for(const it of items){if(!it.alive||it.by!==null)continue;const b=f.ban.get(it);if(b&&b>now)continue;
    if(Math.hypot(it.x-pl.x,it.z-pl.z)>16)continue;const d=Math.hypot(it.x-n.x,it.z-n.z);if(d<bd&&d<22){bd=d;best=it}}
   if(best){f.tgt=best;best.by=i;f.t=0;f.pause=0}}
  let tx,tz,sp;
  if(f.tgt){tx=f.tgt.x;tz=f.tgt.z;sp=FRIEND_SPEED;f.t+=dt;
   if(Math.hypot(tx-n.x,tz-n.z)<.85){f.pause+=dt;if(f.pause>.55){const it=f.tgt;f.tgt=null;remove(it,'team');banter(n)}return}
   if(f.t>9||Math.hypot(tx-pl.x,tz-pl.z)>24){f.tgt.by=null;f.ban.set(f.tgt,now+20000);f.tgt=null;return}}
  else{const a=(i/6)*Math.PI*2+Math.PI/6,R=2.7;tx=pl.x+Math.cos(a)*R;tz=pl.z+Math.sin(a)*R;const d=Math.hypot(tx-n.x,tz-n.z);sp=d>14?7:d>5?4.6:2.3;if(d<.9)return;
   if(d>45){n.x=tx;n.z=tz;return}}
  const dx=tx-n.x,dz=tz-n.z,d=Math.hypot(dx,dz);if(d<.05)return;const st=Math.min(d,sp*dt);n.x+=dx/d*st;n.z+=dz/d*st;n.yaw=Math.atan2(dx,dz);
  const ox=n.x,oz=n.z;g.push(n,.4,false);if(Math.hypot(n.x-ox,n.z-oz)>st*1.5){n.x=ox;n.z=oz}
  n.mv=true}}
team.forEach((n,i)=>mkCtl(n,i));
function release(f){if(f.tgt){f.tgt.by=null;f.tgt=null}}

/* ---- minimap dots ---- */
window.__nssMini=(mc,k)=>{if(phase==='brief'&&!items.length)return;
 mc.save();for(const it of items){if(!it.alive)continue;const x=(it.x-pl.x)*k+85,z=(it.z-pl.z)*k+85;if(x<2||x>168||z<2||z>168)continue;mc.fillStyle='#ff9f1a';mc.strokeStyle='#000';mc.lineWidth=1;mc.beginPath();mc.arc(x,z,2.6,0,7);mc.fill();mc.stroke()}
 bins.forEach(b=>{const x=(b.x-pl.x)*k+85,z=(b.z-pl.z)*k+85;if(x<4||x>166||z<4||z>166)return;mc.fillStyle='#35e07a';mc.strokeStyle='#000';mc.lineWidth=1.2;mc.fillRect(x-4,z-4,8,8);mc.strokeRect(x-4,z-4,8,8)});
 team.forEach(n=>{const x=(n.x-pl.x)*k+85,z=(n.z-pl.z)*k+85;if(x<3||x>167||z<3||z>167)return;mc.fillStyle='#4fc0ff';mc.strokeStyle='#fff';mc.lineWidth=1;mc.beginPath();mc.arc(x,z,3.4,0,7);mc.fill();mc.stroke()});mc.restore()};

/* ---- end / results / certificate ---- */
const endEl=document.createElement('div');endEl.id='nss-end';endEl.setAttribute('data-testid','nss-results');document.body.appendChild(endEl);
const certEl=document.createElement('div');certEl.id='nss-cert';certEl.setAttribute('data-testid','nss-certificate-screen');document.body.appendChild(certEl);
[endEl,certEl].forEach(e=>e.addEventListener('pointerdown',ev=>ev.stopPropagation()));
let result=null;
function rate(){const p=total()/N;return p>=.85?{s:3,l:'CAMPUS HERO'}:p>=.6?{s:2,l:'GREEN VOLUNTEER'}:p>=.35?{s:1,l:'CAMP MEMBER'}:{s:0,l:'ROOKIE VOLUNTEER'}}
function endCamp(all){if(finished)return;finished=true;phase='end';team.forEach(n=>{release(n.fs);n.mv=false});hudEl.style.display='none';try{document.exitPointerLock()}catch(e){}
 cheer();const r=rate();result={r,total:total(),N,you:youN,team:teamN,dropped,score:score(),left:Math.max(0,left),date:new Date().toLocaleDateString('en-IN',{day:'numeric',month:'long',year:'numeric'})};
 try{localStorage.setItem('anits-nss',JSON.stringify(result))}catch(e){}
 const stars=[1,2,3].map(i=>'<i class="'+(i<=r.s?'on':'')+'">\u2605</i>').join('');
 endEl.innerHTML='<div class="bx"><h2 class="'+(all?'w':'l')+'" data-testid="nss-result-title">'+(all?'CAMPUS CLEANED!':"TIME'S UP!")+'</h2><div class="st" data-testid="nss-stars">'+stars+'</div><div class="rl" data-testid="nss-rating">'+r.l+'</div>'
  +'<div class="g"><div>Trash collected<b data-testid="nss-final-total">'+r.total+' / '+N+'</b></div><div>Time left<b>'+fmt(r.left)+'</b></div><div>You<b>'+youN+'</b></div><div>Your team of 6<b>'+teamN+'</b></div><div>Dustbin bonus<b data-testid="nss-bin-bonus">+'+(dropped*BIN_PTS)+'</b></div><div>Score<b data-testid="nss-score">'+score()+'</b></div>'
  +ZONES.map(z=>'<div>'+z.label+'<b>'+zoneGot[z.k]+' / '+zoneTot[z.k]+'</b></div>').join('')+'</div>'
  +'<div class="bt"><button class="g2" id="nss-cert-btn" data-testid="nss-get-certificate-btn">GET CERTIFICATE</button><button class="o" id="nss-retry-btn" data-testid="nss-retry-btn">RETRY CAMP</button></div></div>';
 endEl.style.display='flex';
 $('nss-cert-btn').onclick=showCert;$('nss-retry-btn').onclick=()=>{sessionStorage.setItem('anits-go','lvl8');location.reload()}}

function drawCert(c){const W=1414,H=1000,x=c.getContext('2d');c.width=W;c.height=H;
 const bg=x.createLinearGradient(0,0,W,H);bg.addColorStop(0,'#fffaf0');bg.addColorStop(1,'#f6ead0');x.fillStyle=bg;x.fillRect(0,0,W,H);
 x.strokeStyle='#14306e';x.lineWidth=14;x.strokeRect(28,28,W-56,H-56);x.strokeStyle='#d4a62a';x.lineWidth=4;x.strokeRect(52,52,W-104,H-104);
 x.textAlign='center';x.fillStyle='#14306e';x.font='700 30px Georgia,serif';x.fillText('NATIONAL SERVICE SCHEME \u00B7 ANITS UNIT',W/2,140);
 x.fillStyle='#d4a62a';x.font='700 22px Georgia,serif';x.fillText('NOT ME, BUT YOU',W/2,178);
 x.fillStyle='#14306e';x.font='900 78px Georgia,serif';x.fillText('CERTIFICATE',W/2,300);x.font='700 36px Georgia,serif';x.fillText('OF PARTICIPATION',W/2,355);
 x.fillStyle='#444';x.font='italic 28px Georgia,serif';x.fillText('This is to certify that',W/2,435);
 const nm=pname();let fs=92;x.font='italic 700 '+fs+'px Georgia,serif';while(x.measureText(nm).width>W-340&&fs>40){fs-=4;x.font='italic 700 '+fs+'px Georgia,serif'}
 x.fillStyle='#8a1c1c';x.fillText(nm,W/2,545);x.strokeStyle='#14306e';x.lineWidth=2;x.beginPath();x.moveTo(300,575);x.lineTo(W-300,575);x.stroke();
 x.fillStyle='#333';x.font='27px Georgia,serif';
 ['has taken part in the NSS Special Camp: Campus Cleaning Drive at ANITS,','working with a team of 7 volunteers to clean the basketball ground, the NCC ground,','the college blocks and the roads, and collected '+result.total+' of '+result.N+' pieces of trash.','Rating: '+result.r.l+(result.r.s?'  '+'\u2605'.repeat(result.r.s):'')].forEach((l,i)=>x.fillText(l,W/2,640+i*44));
 x.font='600 24px Georgia,serif';x.fillStyle='#14306e';x.fillText('Date: '+result.date,260,880);
 x.strokeStyle='#14306e';x.beginPath();x.moveTo(W-470,862);x.lineTo(W-150,862);x.stroke();x.fillText('NSS Commander',W-310,895);
 x.save();x.translate(W/2,850);x.fillStyle='#14306e';x.beginPath();x.arc(0,0,66,0,7);x.fill();x.strokeStyle='#d4a62a';x.lineWidth=5;x.beginPath();x.arc(0,0,56,0,7);x.stroke();x.fillStyle='#fff';x.font='900 40px Georgia,serif';x.fillText('NSS',0,14);x.restore()}
function showCert(){endEl.style.display='none';certEl.innerHTML='<canvas id="nss-cert-canvas" data-testid="nss-certificate"></canvas><div class="bt"><button id="nss-dl" data-testid="nss-download-certificate-btn">DOWNLOAD PNG</button><button class="g2" id="nss-done" data-testid="nss-continue-btn">CONTINUE</button></div>';
 const cv=$('nss-cert-canvas');drawCert(cv);certEl.style.display='flex';
 $('nss-dl').onclick=()=>{const a=document.createElement('a');a.download='NSS-Participation-Certificate-'+pname()+'.png';a.href=cv.toDataURL('image/png');document.body.appendChild(a);a.click();a.remove()};
 $('nss-done').onclick=()=>{certEl.style.display='none';g.next();setTimeout(()=>{const ov=$('ov');if(!ov)return;const b=document.createElement('button');b.textContent='View Certificate';b.setAttribute('data-testid','nss-view-certificate-btn');b.onclick=showCert;const box=$('lvl-btns');(box||ov).appendChild(b)},200)}}

/* ---- main loop ---- */
let last=performance.now(),started=false;
function tick(){requestAnimationFrame(tick);const now=performance.now(),dt=Math.min(.05,(now-last)/1000);last=now;
 if(window.__paused||!g.started||g.done||finished)return;
 const si=g.si;
 if(phase==='brief'&&si>=1){phase='clean';left=TIME;hudEl.style.display='flex';hud();cmd.L.d=["Keep going, volunteers! Every piece of trash counts.","Not Me, But You!"]}
 if(phase!=='clean')return;
 left-=dt;
 for(const it of items){if(!it.alive)continue;if(Math.abs(it.x-pl.x)<PICK_R&&Math.abs(it.z-pl.z)<PICK_R&&Math.hypot(it.x-pl.x,it.z-pl.z)<PICK_R){if(bag>=BAG_MAX){if(now-lastFull>4000){lastFull=now;g.say('Your bag is full! Drop it in a green dustbin first.')}continue}if(it.by!==null&&team[it.by])release(team[it.by].fs);remove(it,'you')}}
 if(bag>0)for(const b of bins){if(Math.hypot(b.x-pl.x,b.z-pl.z)<BIN_R){dropBag(b);break}}
 ringM.material.opacity=.45+.2*Math.sin(now/260);
 hud();
 if(total()>=N)endCamp(true);else if(left<=0){left=0;hud();endCamp(false)}}
hud();tick();
window.__nss={items,team,get state(){return{phase,left,you:youN,team:teamN,total:total(),N}},end:()=>endCamp(total()>=N)};
}
})();
