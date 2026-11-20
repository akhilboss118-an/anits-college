/* Friend (Arjun / Sushma) sometimes waits beside the gate (Day 2+), walks in with you, calls you by name and chats on the way. */
(()=>{
const LVL=window.__LVL||1,qs=new URLSearchParams(location.search),girl=window.__CHAR==='girl';
const POOL=window.__POOL&&window.__POOL[girl?'girl':'boy'];
if(LVL<2||LVL===8||!POOL||!POOL.buddy||qs.get('buddy')==='0')return;
if(!(qs.get('buddy')==='1'||Math.random()<.6))return;
window.__buddyDay=true;   // the friend already chats with you today, so no phone call on top of it
const css=document.createElement('style');css.textContent=`#bd-cap{position:fixed;left:50%;bottom:18px;transform:translate(-50%,6px);z-index:11;width:min(620px,calc(100vw - 440px));padding:6px 16px;border-radius:999px;background:rgba(8,14,26,.74);border:1px solid rgba(120,190,255,.6);box-shadow:0 4px 14px rgba(0,0,0,.3);color:#fff;font:600 14px/1.35 'Figtree',sans-serif;text-align:center;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;opacity:0;transition:opacity .3s,transform .3s;pointer-events:none}#bd-cap.on{opacity:1;transform:translate(-50%,0)}#bd-cap b{display:inline;font:800 inherit;font-size:inherit;color:#ffd54a;margin-right:7px}@media(max-width:900px){#bd-cap{width:min(620px,94vw)}}body.touch #bd-cap,body.touch #bd-cap.on{left:calc(var(--sl) + var(--jr) + 14px);right:calc(var(--sr) + var(--jr) + var(--u)*1.3 + 30px);width:auto;transform:none;bottom:calc(var(--sb) - 4px);font-size:13px;padding:5px 12px}`;document.head.appendChild(css);
const cap=document.createElement('div');cap.id='bd-cap';cap.setAttribute('data-testid','buddy-caption');document.body.appendChild(cap);
const UK='anits-buddyused2-'+(girl?'g':'b'),used=(()=>{try{return JSON.parse(localStorage.getItem(UK))||{}}catch(e){return{}}})();
const pickU=(k,a)=>{const u=used[k]||(used[k]=[]);let c=a.map((_,i)=>i).filter(i=>!u.includes(i));if(!c.length){u.length=0;c=a.map((_,i)=>i)}const i=c[Math.floor(Math.random()*c.length)];u.push(i);try{localStorage.setItem(UK,JSON.stringify(used))}catch(e){}return a[i]};
const pick=a=>a[Math.floor(Math.random()*a.length)],sleep=ms=>window.__sleep(ms);
const pname=()=>((window.__PROFILE&&window.__PROFILE.name)||(girl?'Amy':'Mike')).trim();
const nkey=()=>pname().toLowerCase().split(/\s+/)[0].replace(/[^a-z]/g,'');
let capT=null;
function hide(){if(capT)capT.cancel();cap.classList.remove('on')}
function show(who,text,ms){if(capT)capT.cancel();const nm=who?who.replace(/\s*\(.*$/,'')+':':'';cap.classList.add('on');
 const ch=window.__subs.chunks(text,cap,nm),per=ms?ms/ch.length:0;let k=0;   // one small line at a time
 const tick=()=>{cap.innerHTML='<b></b><span></span>';cap.firstChild.textContent=nm;cap.lastChild.textContent=ch[k];
  capT=window.__after(per||window.__subs.dur(ch[k]),()=>{if(++k<ch.length)tick();else if(ms)hide()})};tick()}
function nameCall(n){return new Promise(res=>{const T=window[girl?'__CLIPS_F':'__CLIPS'],c=T&&T['nm:'+nkey()],src=c&&(typeof c==='string'?c:c[1]);
 if(src){window.__voice.speak(girl?'sushma':'arjun',n.name,'nm:'+nkey(),res);return}
 try{const SS=window.speechSynthesis,u=new SpeechSynthesisUtterance(pname()+'!');u.rate=.95;u.pitch=girl?1.5:.9;u.onend=res;u.onerror=res;setTimeout(res,2500);SS.speak(u)}catch(e){res()}})}
function line(n,speaker,text,withName){return new Promise(async res=>{
 const me=speaker==='me',who=me?pname():n.name,c=window.__sub?window.__sub(text,me?null:n):text,pre='';
 const dur=Math.max(3200,Math.min(8000,text.length*75+(withName?900:0)));   // on-screen time, independent of the voice callback
 show(who,pre+c,dur);
 const t0=performance.now();
 if(withName)await Promise.race([nameCall(n),sleep(2600)]);
 window.__voice.speak(me?(girl?'youF':'you'):(girl?'sushma':'arjun'),who,text);
 await sleep(Math.max(600,dur-(performance.now()-t0)));
 hide();await sleep(500);res()})}
// the friend's box must never sit on screen while another dialogue / call / mini-game / chat is open
setInterval(()=>{const g=window.__g;if(cap.classList.contains('on')&&g&&(g.dlg||window.__call||(window.__mini&&window.__mini.active)||(window.__chat&&window.__chat.active)))hide()},250);
(async()=>{
 while(!window.__g||!window.__g.NPC||!window.__g.NPC.arjun||window.__g.si<0)await sleep(150);
 const g=window.__g,n=g.NPC.arjun;if(g.si>0)return;
 const home={x:n.x,z:n.z,yaw:n.yaw},pl=g.pl;
 n.x=pl.x-9;n.z=pl.z-7;n.yaw=0;n.route=null;
 show('',n.name+' is waiting for you beside the gate!',4500);
 while(g.si<1)await sleep(200);
 // walking together
 let last=performance.now(),on=true;
 const follow=()=>{if(!on)return;requestAnimationFrame(follow);const now=performance.now(),dt=Math.min(.25,(now-last)/1000);last=now;if(g.dlg&&g.dlg.n===n)return;
  const f=[Math.sin(pl.yaw),Math.cos(pl.yaw)],tx=pl.x-f[0]*1.1+f[1]*1.5,tz=pl.z-f[1]*1.1-f[0]*1.5,dx=tx-n.x,dz=tz-n.z,d=Math.hypot(dx,dz),sp=Math.min(9,d*2.4+1.2),st=d>14?d:Math.min(d,sp*dt);
  if(d>.15&&st>.012){n.x+=dx/d*st;n.z+=dz/d*st;n.yaw=Math.atan2(dx,dz);n.ri=0;n.dir=1;n.route=[[n.x,n.z],[n.x,n.z]]}else{n.route=null}};
 follow();
 const free=()=>!g.dlg&&!window.__call&&!(window.__mini&&window.__mini.active)&&((document.getElementById('inv')||{style:{}}).style.display!=='flex')&&!(g.story[g.si]&&g.story[g.si].npc==='arjun');
 const wait=async()=>{while(!free()){if(g.story[g.si]&&g.story[g.si].npc==='arjun'&&g.si>1)return false;await sleep(300)}return true};
 const say=async(sp,t,nm)=>{if(!await wait())return false;await line(n,sp,t,nm);return true};
 await sleep(900);
 let ok=await say('f',pickU('g',POOL.buddy.greets),true);
 const pairs=[pickU('p',POOL.buddy.pairs)];   // one short exchange, that's it
 for(const [f,y] of pairs){if(!ok)break;hide();await sleep(5000+Math.random()*3000);ok=await say('f',f,Math.random()<.45)&&await say('me',y,false)}
 if(ok){hide();await sleep(4500);await say('f',pickU('b',POOL.buddy.byes),Math.random()<.5)}
 hide();await sleep(1800);
 on=false;n.route=null;n.x=home.x;n.z=home.z;n.yaw=home.yaw})();
})();
