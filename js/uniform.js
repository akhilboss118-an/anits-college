/* global THREE */
/* Year-based uniform: 2024 = original brown look, 2025 = sky blue shirt / navy pants (+ navy chunni for girls). */
(()=>{const T=THREE;
const imgs={},loadImg=u=>imgs[u]||(imgs[u]=new Promise((ok,no)=>{const i=new Image();i.onload=()=>ok(i);i.onerror=no;i.src=u}));
const near=(a,b,t)=>Math.abs(a[0]-b[0])<t&&Math.abs(a[1]-b[1])<t&&Math.abs(a[2]-b[2])<t;
const CFG={2025:{tex:'uni2025',vc:[[[.86,.8,.68],[.22,.45,.68]],[[.3,.21,.15],[.19,.35,.55]],[[.54,.42,.29],[.04,.07,.2]]],ch:[0x0b1544,0x040a28]},
 2023:{tex:'uni2023',vc:[[[.86,.8,.68],[.6,.32,.42]],[[.3,.21,.15],[.48,.24,.33]],[[.54,.42,.29],[.03,.03,.04]]],ch:[0x16161b,0x050507]}};
const findBone=(root,re)=>{let b=null;root.traverse(o=>{if(!b&&o.isBone&&re.test(o.name))b=o});return b};

function chunni(root,ch){
 const sp=findBone(root,/Spine2$/),ne=findBone(root,/Neck$/),la=findBone(root,/LeftArm$/),ra=findBone(root,/RightArm$/),hp=findBone(root,/Hips$/);if(!sp||!ne||!la||!ra||!hp)return null;
 root.updateMatrixWorld(true);const w=b=>b.getWorldPosition(new T.Vector3()),N=w(ne),A=w(la),B=w(ra),H=w(hp),W=A.distanceTo(B),u=N.y-H.y,cx=(A.x+B.x)/2,cz=(A.z+B.z)/2,s=Math.sign(A.x-B.x)||1;
 const P=(x,y,z)=>new T.Vector3(cx+x*W*s,y,cz+z*W);
 const half=[[.2,H.y+.04*u,.44],[.24,H.y+.4*u,.45],[.34,N.y-.08*u,.34],[.44,N.y-.01*u,.12],[.42,N.y+.01*u,-.12],[.27,N.y+.01*u,-.34]];
 const pts=[...half.map(p=>P(p[0],p[1],p[2])),P(0,N.y+.01*u,-.4),...half.slice().reverse().map(p=>P(-p[0],p[1],p[2]))];
 const cv=new T.CatmullRomCurve3(pts,false,'catmullrom',.5),n=90,pos=[],idx=[];
 for(let i=0;i<=n;i++){const t=i/n,p=cv.getPoint(t),tg=cv.getTangent(t),ay=Math.min(p.y,N.y-.3*u),o=new T.Vector3(p.x-cx,p.y-ay,p.z-cz).normalize();
  const sd=new T.Vector3().crossVectors(tg,o).normalize(),ed=Math.sin(Math.PI*t),hw=W*(.17+.05*ed),c=p.clone().addScaledVector(o,.02);
  const a=c.clone().addScaledVector(sd,hw),b=c.clone().addScaledVector(sd,-hw);
  [a,b].forEach(q=>{sp.worldToLocal(q);pos.push(q.x,q.y,q.z)});
  if(i<n){const k=i*2;idx.push(k,k+1,k+2,k+1,k+3,k+2)}}
 const g=new T.BufferGeometry();g.setAttribute('position',new T.Float32BufferAttribute(pos,3));g.setIndex(idx);g.computeVertexNormals();
 const m=new T.MeshStandardMaterial({color:ch[0],side:T.DoubleSide,roughness:.9,metalness:0,emissive:ch[1],emissiveIntensity:.8}),mesh=new T.Mesh(g,m);mesh.frustumCulled=false;mesh.castShadow=true;mesh.name='chunni';sp.add(mesh);return mesh}

async function apply(root,girl,year){
 const st=root.userData.__uni||(root.userData.__uni={maps:[],cols:[],ch:{},cur:2024});
 year=CFG[+year]?+year:2024;if(year===st.cur)return;st.cur=year;
 st.maps.forEach(([t,i])=>{t.image=i;t.needsUpdate=true});st.cols.forEach(([at,arr])=>{at.array.set(arr);at.needsUpdate=true});
 Object.values(st.ch).forEach(m=>m.visible=false);
 const c=CFG[year];if(!c)return;
 const img=await loadImg('assets/models/'+c.tex+(girl?'_amy.jpg':'_boy.jpg')).catch(()=>null);
 if(st.cur!==year)return;
 root.traverse(o=>{if(!o.isMesh)return;(Array.isArray(o.material)?o.material:[o.material]).forEach(m=>{
  if(!m.map||!/body/i.test(m.name||''))return;let e=st.maps.find(x=>x[0]===m.map);if(!e){e=[m.map,m.map.image];st.maps.push(e)}
  if(img){m.map.image=img;m.map.needsUpdate=true}});
  const at=girl&&o.geometry&&o.geometry.attributes.color;if(!at)return;
  if(!st.cols.some(x=>x[0]===at))st.cols.push([at,at.array.slice()]);
  const org=st.cols.find(x=>x[0]===at)[1];
  for(let i=0;i<at.count;i++){const cc=[org[i*3],org[i*3+1],org[i*3+2]];for(const[f,t]of c.vc)if(near(cc,f,.04)){at.setXYZ(i,t[0],t[1],t[2]);break}}at.needsUpdate=true});
 if(girl){if(!st.ch[year])st.ch[year]=chunni(root,c.ch);if(st.ch[year])st.ch[year].visible=true}}
window.__UNI={apply};
})();
