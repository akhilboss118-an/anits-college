/* Day 8 team photo studio: the real 3D characters of the game (you, your 6 teammates and the NSS Commander) pose on the ANITS gate backdrop.
   Pose options (natural, salute, thumbs up, victory, cheer, mixed), download as PNG, share to WhatsApp (phone share sheet, wa.me fallback). */
(()=>{
if(window.__LVL!==8)return;
const T=THREE,$=id=>document.getElementById(id);
const W=1600,H=1000;
const POSE_LIST=[['stand','NATURAL'],['salute','SALUTE'],['thumbs','THUMBS UP'],['victory','VICTORY'],['cheer','CHEER'],['mixed','MIXED']];
const MIX_ORDER=['salute','thumbs','victory','cheer','thumbs','victory','salute','cheer'];
const SLOTS=[ // [who, x, z]; who: 't0'..'t5' teammates, 'you', 'cmd'
 ['t0',-2.2,0],['t1',-1.1,0],['you',0,0],['t2',1.1,0],['t3',2.2,0],['t4',-1.65,-.95],['cmd',0,-.95],['t5',1.65,-.95]];
let S=null,building=null,raf=0,open=false;

const css=document.createElement('style');css.textContent=`
#nss-photo{position:fixed;inset:0;z-index:52;display:none;flex-direction:column;align-items:center;justify-content:center;gap:10px;background:rgba(3,10,24,.94);padding:10px;font-family:'Figtree',system-ui,sans-serif;color:#fff}
#nss-photo .cvw{position:relative;line-height:0}
#nss-photo canvas{max-width:min(96vw,calc((100vh - 170px)*1.6));max-height:calc(100vh - 170px);height:auto;border-radius:8px;box-shadow:0 12px 56px rgba(0,0,0,.7)}
#nss-photo .ld{position:absolute;inset:0;display:flex;align-items:center;justify-content:center;font:800 15px 'Figtree',sans-serif;letter-spacing:.14em;color:#ffd54a;background:rgba(5,12,28,.75);border-radius:8px}
#nss-photo .fl{position:absolute;inset:0;background:#fff;opacity:0;pointer-events:none;border-radius:8px;transition:opacity .35s ease-out}
#nss-photo .poses,#nss-photo .acts{display:flex;gap:8px;flex-wrap:wrap;justify-content:center}
#nss-photo .poses button{padding:9px 16px;border-radius:999px;border:1.5px solid #6cc0ff;background:rgba(10,32,70,.8);color:#fff;font:800 13px 'Figtree',sans-serif;letter-spacing:.08em;cursor:pointer;transition:background-color .15s,transform .15s}
#nss-photo .poses button:hover{transform:translateY(-1px)}
#nss-photo .poses button.on{background:#ffd54a;color:#111;border-color:#ffd54a}
#nss-photo .acts button{padding:11px 22px;border-radius:999px;border:0;background:#ffd54a;color:#111;font:800 14px 'Figtree',sans-serif;letter-spacing:.06em;cursor:pointer}
#nss-photo .acts button.wa{background:#25d366;color:#04230f}#nss-photo .acts button.o{background:transparent;color:#fff;border:1.5px solid #6cc0ff}
#nss-photo .msg{min-height:18px;font:600 13px 'Figtree',sans-serif;color:#9fe7b6;text-align:center;max-width:92vw}
body.touch #nss-photo .poses button{padding:7px 11px;font-size:11px}body.touch #nss-photo .acts button{padding:9px 14px;font-size:12px}
`;document.head.appendChild(css);

const el=document.createElement('div');el.id='nss-photo';el.setAttribute('data-testid','nss-photo-studio');
el.innerHTML='<div class="cvw"><canvas id="nss-pcv" width="'+W+'" height="'+H+'" data-testid="nss-team-photo"></canvas><div class="ld" id="nss-pld" data-testid="nss-photo-loading">SETTING UP THE PHOTO STUDIO...</div><div class="fl" id="nss-pfl"></div></div>'
 +'<div class="poses" data-testid="nss-pose-options">'+POSE_LIST.map(p=>'<button data-pose="'+p[0]+'" data-testid="nss-pose-'+p[0]+'-btn">'+p[1]+'</button>').join('')+'</div>'
 +'<div class="acts"><button id="nss-p-dl" data-testid="nss-download-photo-btn">DOWNLOAD PHOTO</button><button class="wa" id="nss-p-wa" data-testid="nss-share-whatsapp-btn">SHARE TO WHATSAPP</button><button class="o" id="nss-p-back" data-testid="nss-photo-back-btn">BACK TO CERTIFICATE</button></div>'
 +'<div class="msg" id="nss-pmsg" data-testid="nss-photo-message"></div>';
document.body.appendChild(el);el.addEventListener('pointerdown',e=>e.stopPropagation());

const say=t=>{$('nss-pmsg').textContent=t||''};
const ease=t=>t<.5?2*t*t:1-Math.pow(-2*t+2,2)/2;

function loadImg(u){return new Promise(ok=>{const i=new Image();i.onload=()=>ok(i);i.onerror=()=>ok(null);i.src=u})}

async function build(){
 const C=window.__NSSCH,g=window.__g,SP=window.__nssSpec,GIRL=window.__CHAR==='girl';
 const renderer=new T.WebGLRenderer({antialias:true,alpha:true,preserveDrawingBuffer:true});renderer.setPixelRatio(1);renderer.setSize(W,H);renderer.setClearColor(0x000000,0);
 renderer.outputEncoding=T.sRGBEncoding;renderer.shadowMap.enabled=true;renderer.shadowMap.type=T.PCFSoftShadowMap;
 const scene=new T.Scene();
 scene.add(new T.HemisphereLight(0xffffff,0xb9b29a,.95));
 const sun=new T.DirectionalLight(0xfff0d6,1.25);sun.position.set(-3.5,6.5,6);sun.castShadow=true;sun.shadow.mapSize.set(2048,2048);
 const sc=sun.shadow.camera;sc.left=-6;sc.right=6;sc.top=6;sc.bottom=-6;sc.near=1;sc.far=22;sun.shadow.bias=-.0004;sun.shadow.radius=4;scene.add(sun);
 const fill=new T.DirectionalLight(0xcfe4ff,.35);fill.position.set(4,3,5);scene.add(fill);
 const gr=new T.Mesh(new T.PlaneGeometry(40,40).rotateX(-Math.PI/2),new T.ShadowMaterial({opacity:.34}));gr.receiveShadow=true;scene.add(gr);
 const cam=new T.PerspectiveCamera(29,W/H,.1,60);cam.position.set(0,1.3,7.9);cam.lookAt(0,.98,0);cam.updateMatrixWorld(true);
 const bg=document.createElement('canvas');bg.width=W;bg.height=H;{const x=bg.getContext('2d'),im=await loadImg('assets/ui/bg_clean.jpg');
  if(im){const k=Math.max(W/im.width,H/im.height),w=im.width*k,h=im.height*k;x.drawImage(im,(W-w)/2,(H-h)*.72,w,h)}else{x.fillStyle='#9ad';x.fillRect(0,0,W,H)}}
 /* build the roster from the game's real characters */
 const people={};
 const mk=async(spec,photoOpts)=>{const ch=await C.make(spec.kind,Object.assign({h:spec.h,tint:spec.tint,tintAll:spec.tintAll,photo:true},photoOpts||{}));return ch};
 await Promise.all(SP.team.map(async(s,i)=>{const ch=await mk(s);C.addVest(ch,0xff7a00,0xf4f1e6);people['t'+i]={ch,name:s.name}}));
 {const ch=await mk(SP.cmd);C.addVest(ch,0x14306e,0xf4f1e6);people.cmd={ch,name:'NSS Commander'}}
 {const pc=await C.player(g.boy,GIRL,GIRL?1.65:1.75);C.addVest(pc,0xff7a00,0xffd54a);people.you={ch:pc,name:(window.__PROFILE&&window.__PROFILE.name)||(GIRL?'Amy':'Mike'),you:true}}
 const list=[];
 SLOTS.forEach(([who,x,z],i)=>{const p=people[who];if(!p)return;const ch=p.ch;ch.root.position.set(x,0,z);ch.root.rotation.y=-x*.07+(Math.random()-.5)*.05;scene.add(ch.root);
  ch.root.traverse(o=>{if(o.isMesh){o.castShadow=true;o.receiveShadow=false}});
  if(!ch.palmSign)C.calibrate(ch);
  list.push({who,x,z,idx:i,front:z>-.5,ch,name:p.name,you:!!p.you,from:null,to:null,t:1,delay:0,pose:'stand',
   head:ch.B.Head?ch.B.Head.quaternion.clone():null,spine:ch.B.Spine1?ch.B.Spine1.quaternion.clone():null,ph:Math.random()*6})});
 return{renderer,scene,cam,bg,list,C,ctx:$('nss-pcv').getContext('2d'),pose:null,t0:performance.now(),last:performance.now()}}

function poseFor(p,mode,i){return mode==='mixed'?MIX_ORDER[i%MIX_ORDER.length]:mode}
function setPose(mode,instant){
 S.mode=mode;document.querySelectorAll('#nss-photo .poses button').forEach(b=>b.classList.toggle('on',b.dataset.pose===mode));
 S.list.forEach((p,i)=>{const C=S.C,ch=p.ch,from=C.snapshot(ch);C.applyPose(ch,poseFor(p,mode,i));const to=C.snapshot(ch);C.restore(ch,from);p.from=from;p.to=to;p.t=instant?1:0;p.delay=instant?0:.05+Math.abs(p.x)*.06+Math.random()*.12;p.pose=poseFor(p,mode,i)});
}
function stepAnim(dt,now){
 S.list.forEach(p=>{const C=S.C,ch=p.ch;
  if(p.t<1){if(p.delay>0)p.delay-=dt;else{p.t=Math.min(1,p.t+dt/.6);const e=ease(p.t),bones=C.poseBones(ch);bones.forEach((b,i)=>b.quaternion.slerpQuaternions(p.from[i],p.to[i],e))}}
  const tm=now/1000+p.ph;
  if(p.head&&ch.B.Head){ch.B.Head.quaternion.copy(p.head).multiply(new T.Quaternion().setFromEuler(new T.Euler(Math.sin(tm*.9)*.015,Math.sin(tm*.5)*.05,0)))}
  if(p.spine&&ch.B.Spine1){ch.B.Spine1.quaternion.copy(p.spine).multiply(new T.Quaternion().setFromEuler(new T.Euler(Math.sin(tm*1.5)*.012,0,0)))}})}

const V=new T.Vector3();
function proj(p,y){V.set(p.x,y,p.z).project(S.cam);return[(V.x*.5+.5)*W,(-V.y*.5+.5)*H]}
function plate(x,y,txt,you,s){const c=S.ctx;c.font='800 '+Math.round(24*s)+'px Figtree,Georgia,sans-serif';const tw=c.measureText(txt).width+26*s,h=36*s;
 c.fillStyle='rgba(8,14,30,.82)';c.beginPath();c.roundRect(x-tw/2,y,tw,h,h/2);c.fill();c.strokeStyle=you?'#ffd54a':'rgba(255,255,255,.55)';c.lineWidth=2;c.stroke();
 c.fillStyle=you?'#ffd54a':'#fff';c.textAlign='center';c.textBaseline='middle';c.fillText(txt,x,y+h/2+1)}
function compose(){const c=S.ctx;c.clearRect(0,0,W,H);c.drawImage(S.bg,0,0);
 const g1=c.createLinearGradient(0,0,0,H);g1.addColorStop(0,'rgba(255,214,140,.10)');g1.addColorStop(1,'rgba(30,50,20,.12)');c.fillStyle=g1;c.fillRect(0,0,W,H);
 c.drawImage(S.renderer.domElement,0,0);
 const vg=c.createRadialGradient(W/2,H/2,H*.45,W/2,H/2,H*.95);vg.addColorStop(0,'rgba(0,0,0,0)');vg.addColorStop(1,'rgba(0,0,0,.32)');c.fillStyle=vg;c.fillRect(0,0,W,H);
 /* title ribbon */
 c.fillStyle='rgba(8,18,44,.84)';c.fillRect(0,0,W,92);c.fillStyle='#ffd54a';c.fillRect(0,92,W,4);
 c.textAlign='center';c.textBaseline='alphabetic';c.fillStyle='#fff';c.font="900 40px 'Bricolage Grotesque',Georgia,serif";c.fillText('NSS TEAM ANITS  \u00B7  CAMPUS CLEANING DRIVE',W/2,50);
 c.fillStyle='#ffd54a';c.font="italic 700 23px Georgia,serif";c.fillText('Not Me, But You!  \u00B7  '+S.date,W/2,80);
 /* name tags: front row at the feet, back row above the heads */
 S.list.forEach(p=>{const nm=p.name.length>16?p.name.slice(0,15)+'.':p.name;
  if(p.front){const[x,y]=proj(p,0);plate(x,y+12,p.you?nm+'  (YOU)':nm,p.you,1)}
  else{const[x,y]=proj(p,p.ch.h+.28);plate(x,y-34,nm,false,.82)}});
 c.strokeStyle='rgba(255,255,255,.9)';c.lineWidth=10;c.strokeRect(5,5,W-10,H-10)}
function loop(){if(!open)return;raf=requestAnimationFrame(loop);const now=performance.now(),dt=Math.min(.05,(now-S.last)/1000);S.last=now;
 stepAnim(dt,now);S.renderer.render(S.scene,S.cam);compose()}

function toBlob(){return new Promise(ok=>$('nss-pcv').toBlob(ok,'image/png'))}
function flash(){const f=$('nss-pfl');f.style.transition='none';f.style.opacity='.9';requestAnimationFrame(()=>{f.style.transition='opacity .4s ease-out';f.style.opacity='0'});
 try{const A=new(window.AudioContext||window.webkitAudioContext)(),t=A.currentTime,o=A.createOscillator(),gn=A.createGain();o.type='square';o.frequency.setValueAtTime(1500,t);o.frequency.exponentialRampToValueAtTime(300,t+.07);gn.gain.setValueAtTime(.06*(window.__VOL==null?1:window.__VOL),t);gn.gain.exponentialRampToValueAtTime(.001,t+.1);o.connect(gn);gn.connect(A.destination);o.start(t);o.stop(t+.12);setTimeout(()=>A.close(),400)}catch(e){}}
const fname=()=>'NSS-Team-Photo-'+(((window.__PROFILE&&window.__PROFILE.name)||'Player').replace(/[^\w-]+/g,'_'))+'-'+S.mode+'.png';
function saveBlob(b){const a=document.createElement('a');a.download=fname();a.href=URL.createObjectURL(b);document.body.appendChild(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(a.href),4000)}
async function download(){if(!S)return;flash();S.renderer.render(S.scene,S.cam);compose();const b=await toBlob();if(b){saveBlob(b);say('Photo saved to your device.')}}
async function shareWA(){if(!S)return;flash();S.renderer.render(S.scene,S.cam);compose();const b=await toBlob();if(!b)return;
 const text='Our NSS team at ANITS cleaned the whole campus! Not Me, But You! \uD83C\uDDEE\uD83C\uDDF3 Play the ANITS game: '+location.href.split('?')[0].replace(/index\.html$/,'');
 const file=new File([b],fname(),{type:'image/png'});
 if(navigator.canShare&&navigator.canShare({files:[file]})){try{await navigator.share({files:[file],text,title:'NSS Team Photo - ANITS'});say('Shared! Pick WhatsApp in the share sheet.');return}catch(e){if(e&&e.name==='AbortError'){say('Sharing cancelled.');return}}}
 saveBlob(b);const url='https://wa.me/?text='+encodeURIComponent(text);const w=window.open(url,'_blank','noopener');
 say(w?'WhatsApp opened. The photo was saved to your device, attach it to your chat.':'Photo saved. Open WhatsApp and attach it (your browser blocked the WhatsApp tab).');}

async function openStudio(opts){opts=opts||{};if(open)return;open=true;el.style.display='flex';$('nss-pld').style.display='flex';say('');
 try{
  if(!S){if(!building)building=build();S=await building;building=null;S.date=(opts.date)||new Date().toLocaleDateString('en-IN',{day:'numeric',month:'long',year:'numeric'});
   document.querySelectorAll('#nss-photo .poses button').forEach(b=>b.onclick=()=>{setPose(b.dataset.pose);say('')});
   $('nss-p-dl').onclick=download;$('nss-p-wa').onclick=shareWA;$('nss-p-back').onclick=()=>{closeStudio();opts.onBack&&opts.onBack()};
   setPose('stand',true);S.start=true}
  else{S.date=opts.date||S.date}
  S.last=performance.now();$('nss-pld').style.display='none';
  setPose(S.mode&&S.mode!=='stand'?S.mode:'salute');
  window.__nssPhotoReady=true;loop()
 }catch(e){console.error('photo studio failed',e);$('nss-pld').textContent='PHOTO STUDIO FAILED TO LOAD';building=null;window.__nssPhotoErr=String(e&&e.stack||e)}}
function closeStudio(){open=false;cancelAnimationFrame(raf);el.style.display='none'}

window.__NSSPHOTO={open:openStudio,close:closeStudio,get state(){return S},setPose,download,share:shareWA};
})();
