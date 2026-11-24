/* Day 8 character kit: re-uses the game's existing Mixamo rigs (Remy, Amy, NCC cadets, Colonel Singh, the player) as distinct,
   properly animated NSS team members, plus a world-space arm/hand/finger pose solver used by the team photo.
   Exposes window.__NSSCH = {proto, make, fromRig, addVest, applyPose, POSES, ...}. */
(()=>{
if(window.__LVL!==8)return;
const T=THREE,rnd=Math.random,clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
const BUF={remy:'B_REMY',amy:'B_AMY',cadetB:'B_CADETB',cadetG:'B_CADETG',boy:'B_WALK',colonel:'B_COLONEL'};
const GLL=new T.GLTFLoader(),cache={};
const parse=b=>new Promise((ok,no)=>GLL.parse(b.slice(0),'',ok,no));
function proto(kind){return cache[kind]||(cache[kind]=(async()=>{const b=window[BUF[kind]];if(!b)throw new Error('no model '+kind);const gl=await parse(b);return{scene:gl.scene,anims:gl.animations}})())}
function cloneSk(src){const cl=src.clone(true),a=[],c=[];src.traverse(o=>a.push(o));cl.traverse(o=>c.push(o));const mp=new Map(a.map((o,i)=>[o,c[i]]));
 a.forEach((o,i)=>{if(o.isSkinnedMesh){const m=c[i];m.skeleton=new T.Skeleton(o.skeleton.bones.map(x=>mp.get(x)),o.skeleton.boneInverses);m.bind(m.skeleton,m.matrixWorld)}});return cl}
const bn=n=>n.replace(/^mixamorig:?/,'');
function boneMap(rig){const m={};rig.traverse(o=>{if(o.isBone)m[bn(o.name)]=o});return m}

/* ---- material prep: matte, readable materials; optional per-material tint (by material name) ---- */
function prep(rig,o){o=o||{};const mats=[];
 rig.traverse(m=>{if(!m.isMesh)return;m.castShadow=true;m.frustumCulled=false;
  m.material=Array.isArray(m.material)?m.material.map(x=>x.clone()):m.material.clone();
  (Array.isArray(m.material)?m.material:[m.material]).forEach(x=>{
   if(o.hideFace&&(x.transparent&&x.opacity<=.01||/Eyes|Brows|Mouth/i.test(x.name||''))){m.visible=false;return}
   x.transparent=false;x.metalness=0;x.roughness=.9;if(x.normalScale)x.normalScale.set(.5,.5);
   if(o.photo){x.emissive.setRGB(0,0,0);x.emissiveMap=null}
   if(x.map){x.map.anisotropy=8;if(o.emis){x.emissiveMap=x.map;x.emissive.setRGB(o.emis,o.emis,o.emis)}}
   if(o.tint&&o.tint[x.name]!=null)x.color.set(o.tint[x.name]);
   if(o.tintAll)x.color.setRGB(o.tintAll[0],o.tintAll[1],o.tintAll[2]);
   if(o.tintAll&&o.emis&&x.map)x.emissive.setRGB(o.emis*o.tintAll[0],o.emis*o.tintAll[1],o.emis*o.tintAll[2]);
   x.needsUpdate=true;mats.push(x)})})}

/* ---- clips ---- */
function lockHips(clip){const c=clip.clone(),tr=c.tracks.find(t=>/Hips\.position$/.test(t.name));let stride=0;
 if(tr){const v=tr.values,n=v.length/3;stride=Math.abs(v[(n-1)*3+2]-v[2]);for(let i=0;i<n;i++){v[i*3]=v[0];v[i*3+2]=v[2]}}return{clip:c,stride}}
function retarget(src,rig){const tr=src.tracks.filter(t=>/\.quaternion$/.test(t.name)&&rig.getObjectByName(t.name.split('.')[0]));
 return tr.length>=20?new T.AnimationClip('walk',src.duration,tr):null}

/* ---- build a character from a (cloned) rig ----
   opts: h (m), clip (walk/base clip), v0 (natural walk speed m/s), base ('walk'|'idle'), emis */
function fromRig(rig,clip,opts){opts=opts||{};
 const root=new T.Group(),h=opts.h||1.75;
 rig.traverse(o=>{if(o.isSkinnedMesh)o.skeleton.pose()});
 rig.scale.setScalar(1);rig.position.set(0,0,0);rig.updateMatrixWorld(true);
 const bb=new T.Box3().setFromObject(rig),k=h/(bb.max.y-bb.min.y);rig.scale.setScalar(k);rig.position.y=-bb.min.y*k;root.add(rig);root.updateMatrixWorld(true);
 const B=boneMap(rig);calibrate({B,root});
 const palmSign=calibrate.last;
 const mix=new T.AnimationMixer(rig),act=mix.clipAction(clip);act.play();const dur=clip.duration;
 /* rest frames = the two "legs passing" instants: used to stand still without a frozen mid-stride */
 let REST=[0,dur/2];
 if(B.LeftFoot&&B.RightFoot&&opts.base!=='idle'){let best=1e9,bt=0;const a=new T.Vector3(),b=new T.Vector3();
  for(let i=0;i<32;i++){const t=dur*i/32;act.time=t;mix.update(0);rig.updateMatrixWorld(true);B.LeftFoot.getWorldPosition(a);B.RightFoot.getWorldPosition(b);const d=Math.hypot(a.x-b.x,a.z-b.z);if(d<best){best=d;bt=t}}
  REST=[bt,(bt+dur/2)%dur]}
 act.time=REST[0];mix.update(0);
 const ch={root,rig,B,mix,act,dur,REST,h,k,palmSign,t:rnd()*dur,sp:1,v0:opts.v0||1.667,bend:0,bendT:0,breath:rnd()*6,x0:null,z0:null,speed:0};
 ch.update=(dt,mv,speed)=>{
  if(dt>0){
   if(mv){const rate=clamp((speed||ch.v0)/ch.v0,.5,3.4);ch.sp+=(rate-ch.sp)*Math.min(1,dt*6);ch.t=(ch.t+dt*ch.sp)%dur}
   else{const r=Math.min(...REST.map(q=>((q-ch.t)%dur+dur)%dur));if(r>.004){ch.sp=Math.max(.4,Math.min(1.2,r*5));ch.t=(ch.t+Math.min(dt*ch.sp,r))%dur}}
   ch.bend+=((ch.bendT||0)-ch.bend)*Math.min(1,dt*9);ch.breath+=dt}
  act.time=ch.t;mix.update(0);
  const s=ch.bend;
  if(s>.01){[['Spine',.42],['Spine1',.34],['Spine2',.24],['Neck',.1]].forEach(([n,a])=>{const b=B[n];if(b)b.quaternion.multiply(new T.Quaternion().setFromAxisAngle(new T.Vector3(1,0,0),a*s))});
   if(B.Hips)B.Hips.position.y-=0;}
  if(!mv&&B.Spine&&s<.05)B.Spine1&&B.Spine1.quaternion.multiply(new T.Quaternion().setFromAxisAngle(new T.Vector3(1,0,0),Math.sin(ch.breath*1.6)*.012))};
 return ch}

/* ---- named looks (existing characters of the game) ---- */
async function make(kind,o){o=o||{};const P=await proto(kind),rig=cloneSk(P.scene);
 const emis=o.emis!=null?o.emis:(o.photo?0:kind==='remy'?.12:.3);
 prep(rig,{emis,tint:o.tint,tintAll:o.tintAll,hideFace:kind==='boy',photo:o.photo});
 let clip=null,v0=1.667,base='walk';
 const find=n=>P.anims.find(a=>a.name===n);
 if(kind==='remy'){clip=P.anims[0]}
 else if(kind==='amy'||kind==='boy'){const w=find('walk')||P.anims[0],l=lockHips(w);clip=l.clip;v0=l.stride>0?clamp(l.stride*(o.h||1.7)/1.75/w.duration,1,2.4):1.667;if(v0<1.2)v0=1.667}
 else{const R=await proto('remy');clip=retarget(R.anims[0],rig);if(!clip){clip=find('idle')||P.anims[0];base='idle'}}
 const ch=fromRig(rig,clip,{h:o.h,v0,base});ch.kind=kind;ch.P=P;
 if(P.anims.find(a=>a.name==='salute')){ch.clips={};P.anims.forEach(a=>ch.clips[a.name]=a)}
 return ch}

/* the player's own rig (uniform, chunni...) cloned from the live game for the team photo */
async function player(srcBoy,girl,h){const P=await proto(girl?'amy':'boy'),rig=cloneSk(srcBoy);prep(rig,{photo:true});
 const w=P.anims.find(a=>a.name==='walk')||P.anims[0];return fromRig(rig,lockHips(w).clip,{h})}

/* ---- NSS volunteer vest (orange bib with a white band) fixed to the spine so it moves with the body ---- */
function addVest(ch,col,band){const b=ch.B.Spine1||ch.B.Spine;if(!b)return;
 b.updateWorldMatrix(true,false);const ws=new T.Vector3();b.getWorldScale(ws);const sw=ch.B.LeftArm&&ch.B.RightArm?ch.B.LeftArm.getWorldPosition(new T.Vector3()).distanceTo(ch.B.RightArm.getWorldPosition(new T.Vector3())):.36;
 const R=clamp(sw*.5*.95,.15,.26);const g=new T.Group();
 const m=new T.MeshLambertMaterial({color:col||0xff7a00,side:T.DoubleSide});
 const v=new T.Mesh(new T.CylinderGeometry(R,R*.97,.4,20,1,true),m);v.scale.z=.78;
 const bd=new T.Mesh(new T.CylinderGeometry(R*1.012,R*.99,.06,20,1,true),new T.MeshLambertMaterial({color:band||0xf4f1e6,side:T.DoubleSide}));bd.scale.z=.78;bd.position.y=-.02;
 g.add(v,bd);g.scale.set(1/ws.x,1/ws.y,1/ws.z);g.position.y=0;b.add(g);ch.vest=g;return g}

/* ================= pose solver (world-space aiming; works on every Mixamo rig) ================= */
const V1=new T.Vector3(),V2=new T.Vector3(),Q1=new T.Quaternion(),Q2=new T.Quaternion(),Q3=new T.Quaternion();
function setWorldQ(b,qw){b.parent.getWorldQuaternion(Q3);b.quaternion.copy(Q3.invert().multiply(qw));b.updateMatrixWorld(true)}
function aim(b,c,dir){if(!b||!c)return;b.updateMatrixWorld(true);b.getWorldPosition(V1);c.getWorldPosition(V2);V2.sub(V1);if(V2.lengthSq()<1e-10)return;V2.normalize();
 Q1.setFromUnitVectors(V2,dir.clone().normalize());b.getWorldQuaternion(Q2);setWorldQ(b,Q1.multiply(Q2))}
function twist(b,axis,ang){b.updateMatrixWorld(true);b.getWorldQuaternion(Q2);Q1.setFromAxisAngle(axis.clone().normalize(),ang);setWorldQ(b,Q1.multiply(Q2))}
const wp=b=>b.getWorldPosition(new T.Vector3());
/* palm normal (pointing out of the palm) of a hand in its current pose; s = calibration sign */
function palmN(ch,side){const B=ch.B,hn=side+'Hand',h=wp(B[hn]),i=wp(B[hn+'Index1']).sub(h),p=wp(B[hn+'Pinky1']).sub(h);return i.cross(p).normalize().multiplyScalar(ch.palmSign[side])}
function calibrate(ch){ch.palmSign={Left:1,Right:1};ch.root.updateMatrixWorld(true);
 ['Left','Right'].forEach(s=>{if(!ch.B[s+'HandIndex1']||!ch.B[s+'HandPinky1'])return;ch.palmSign[s]=1;const n=palmN(ch,s);if(n.y>0)ch.palmSign[s]=-1});calibrate.last=ch.palmSign}
function facePalm(ch,side,want){const B=ch.B,hn=side+'Hand',a=wp(B[hn+'Middle1']).sub(wp(B[hn])).normalize();
 let n=palmN(ch,side);n.addScaledVector(a,-n.dot(a)).normalize();const d=want.clone().addScaledVector(a,-want.dot(a));if(d.lengthSq()<1e-6)return;d.normalize();
 const ang=Math.atan2(a.dot(n.clone().cross(d)),n.dot(d));twist(B[hn],a,ang)}
const FING=['Index','Middle','Ring','Pinky'];
function fingerChain(ch,side,f){const B=ch.B,p=side+'Hand'+f;return[B[p+'1'],B[p+'2'],B[p+'3'],B[p+'4']]}
function curl(ch,side,f,a,n,amount){const c=fingerChain(ch,side,f);if(!c[0]||!c[1]||!c[2])return;
 const ang=[85,175,235].map(x=>x*amount*Math.PI/180);
 for(let j=0;j<3;j++){const nxt=c[j+1]||null;if(!nxt)continue;aim(c[j],nxt,a.clone().multiplyScalar(Math.cos(ang[j])).addScaledVector(n,Math.sin(ang[j])))}}
function fingers(ch,side,mode,fw){const B=ch.B,hn=side+'Hand',a=wp(B[hn+'Middle1']).sub(wp(B[hn])).normalize(),n=palmN(ch,side),lat=wp(B[hn+'Index1']).sub(wp(B[hn+'Pinky1'])).normalize();
 const th=[B[hn+'Thumb1'],B[hn+'Thumb2'],B[hn+'Thumb3'],B[hn+'Thumb4']];
 const straight=(f,spread)=>{const c=fingerChain(ch,side,f);const d=a.clone().applyAxisAngle(n,spread);for(let j=0;j<3;j++)if(c[j]&&c[j+1])aim(c[j],c[j+1],d)};
 if(mode==='flat'){FING.forEach(f=>straight(f,0));if(th[0])for(let j=0;j<3;j++)aim(th[j],th[j+1],a.clone().addScaledVector(lat,.45).normalize())}
 else if(mode==='relax'){FING.forEach(f=>curl(ch,side,f,a,n,.22));if(th[0])for(let j=0;j<3;j++)aim(th[j],th[j+1],a.clone().addScaledVector(n,.55).addScaledVector(lat,.5).normalize())}
 else if(mode==='thumb'){FING.forEach(f=>curl(ch,side,f,a,n,1));if(th[0])for(let j=0;j<3;j++)aim(th[j],th[j+1],fw.thumb.clone())}
 else if(mode==='peace'){straight('Index',.2*(side==='Left'?1:-1)*ch.palmSign[side]);straight('Middle',-.17*(side==='Left'?1:-1)*ch.palmSign[side]);curl(ch,side,'Ring',a,n,1);curl(ch,side,'Pinky',a,n,1);
  if(th[0]){const r=ch.B[hn+'Ring2'];const tgt=r?wp(r):null;for(let j=0;j<3;j++){const d=tgt?tgt.clone().sub(wp(th[j])).normalize():a.clone().addScaledVector(n,.8).normalize();aim(th[j],th[j+1],d)}}}
 else if(mode==='fist'){FING.forEach(f=>curl(ch,side,f,a,n,1));if(th[0])for(let j=0;j<3;j++)aim(th[j],th[j+1],a.clone().addScaledVector(n,.7).addScaledVector(lat,.4).normalize())}}

/* arm poses: dirs are in the arm's own frame: o = outwards from the body (sideways), y = up, z = forward (character faces +z) */
const POSES={
 stand:{R:{u:[.12,-.99,.03],f:[.07,-.96,.24],h:[.05,-.93,.3],palm:[-.6,0,.4],fing:'relax'},L:'R'},
 salute:{R:{u:[.97,.02,.12],f:[-.62,.74,.27],h:[-.62,.74,.27],palm:[0,.1,1],fing:'flat'},L:{u:[.12,-.99,.03],f:[.07,-.96,.24],h:[.05,-.93,.3],palm:[-.6,0,.4],fing:'relax'}},
 thumbs:{R:{u:[.2,-.93,.18],f:[-.1,.38,.9],h:[-.1,.38,.9],palm:[-1,0,.05],fing:'thumb',thumb:[.0,1,.25]},L:'R'},
 victory:{R:{u:[.66,.74,.1],f:[.4,.9,.12],h:[.4,.9,.12],palm:[0,.05,1],fing:'peace'},L:'R'},
 cheer:{R:{u:[.55,.83,.0],f:[.2,.97,.05],h:[.2,.97,.05],palm:[-1,0,.1],fing:'flat'},L:'R'}};
POSES.mixed=null;
function applyPose(ch,name){const sp=POSES[name]||POSES.stand;if(!ch.palmSign)calibrate(ch);
 ch.root.updateMatrixWorld(true);const rq=ch.root.getWorldQuaternion(new T.Quaternion());
 ['Right','Left'].forEach(side=>{const key=side==='Right'?'R':'L';let a=sp[key];if(typeof a==='string')a=sp[a];
  const sx=side==='Left'?1:-1,B=ch.B,loc=v=>new T.Vector3(v[0]*sx,v[1],v[2]).applyQuaternion(rq).normalize();
  const arm=B[side+'Arm'],fore=B[side+'ForeArm'],hand=B[side+'Hand'],m1=B[side+'HandMiddle1'];if(!arm||!fore||!hand)return;
  aim(arm,fore,loc(a.u));aim(fore,hand,loc(a.f));if(m1)aim(hand,m1,loc(a.h));
  if(m1&&B[side+'HandIndex1']&&B[side+'HandPinky1']){facePalm(ch,side,loc(a.palm));
   fingers(ch,side,a.fing,{thumb:a.thumb?loc(a.thumb):new T.Vector3(0,1,0)})}});
 ch.root.updateMatrixWorld(true)}
/* arm bones that a pose can change (arms, hands, all fingers) */
function poseBones(ch){const r=[];['Left','Right'].forEach(s=>{['Arm','ForeArm','Hand'].forEach(n=>ch.B[s+n]&&r.push(ch.B[s+n]));
 ['Thumb','Index','Middle','Ring','Pinky'].forEach(f=>[1,2,3].forEach(j=>{const b=ch.B[s+'Hand'+f+j];b&&r.push(b)}))});return r}
function snapshot(ch){return poseBones(ch).map(b=>b.quaternion.clone())}
function restore(ch,snap){poseBones(ch).forEach((b,i)=>b.quaternion.copy(snap[i]));ch.root.updateMatrixWorld(true)}

window.__NSSCH={player,proto,make,fromRig,cloneSk,prep,addVest,applyPose,calibrate,poseBones,snapshot,restore,POSES,lockHips,retarget};
})();
