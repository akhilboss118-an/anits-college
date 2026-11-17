/* Day 2 (Pay the Fees) upgrade: cinematic ATM cash collection, paying cash to Laksmi, submitting the fee report,
   and signing the receipt by hand (touch / mouse). The signed receipt is saved to the bag (window.__inv).
   API: window.__day2.atm(amount, done?)  window.__day2.pay(fee, done)  window.__day2.signature() */
(()=>{
const LS=localStorage,SIGKEY='anits-sign';
const NOTES={500:['#c9cdb8','#8c917a','#5b5f4e'],200:['#ffb347','#e07b1a','#8a4a0c'],100:['#c3b1f0','#8f78d6','#4b3b8f'],50:['#7fe3f0','#2fb0c4','#106a79'],20:['#d8f07a','#9bc53a','#566f14'],10:['#d9a773','#a8703a','#5e3a17']};
const css=document.createElement('style');css.textContent=`
#d2{position:fixed;inset:0;z-index:45;display:none;overflow:hidden;color:#fff;font-family:'Figtree',system-ui,sans-serif;user-select:none;-webkit-user-select:none;touch-action:none;background:radial-gradient(ellipse at 50% 40%,rgba(14,30,66,.93),rgba(2,6,16,.97))}
#d2 .bar{position:absolute;left:0;right:0;height:9vh;background:#000;z-index:5;transition:transform .8s cubic-bezier(.2,.8,.2,1)}
#d2 .bar.t{top:0;transform:translateY(-100%)}#d2 .bar.b{bottom:0;transform:translateY(100%)}#d2.on .bar{transform:none}
#d2 .cap{pointer-events:none;position:absolute;left:0;right:0;top:11vh;text-align:center;z-index:6;font:800 12px 'Bricolage Grotesque',sans-serif;letter-spacing:.32em;color:#7cc4ff}
#d2 .hint{pointer-events:none;position:absolute;left:0;right:0;bottom:11vh;text-align:center;z-index:6;font-size:15px;font-weight:700;color:#ffd54a;text-shadow:0 2px 10px #000;animation:d2p 1.3s infinite}
@keyframes d2p{50%{opacity:.55}}
#d2 .stage{position:absolute;inset:9vh 0;display:flex;align-items:center;justify-content:center}
#d2 .wal{position:absolute;right:18px;bottom:calc(9vh + 14px);z-index:7;padding:10px 16px;border-radius:14px;background:rgba(6,22,56,.85);border:1.5px solid #6cc0ff;font:800 18px 'Bricolage Grotesque',sans-serif}
#d2 .wal.bump{animation:d2b .35s}@keyframes d2b{50%{transform:scale(1.25);color:#6dff9f}}
#d2 .btn{padding:12px 30px;border:0;border-radius:999px;background:#ffd54a;color:#111;font:800 16px 'Figtree',sans-serif;letter-spacing:.06em;cursor:pointer;box-shadow:0 0 22px rgba(255,213,74,.45)}
#d2 .btn.g{background:#2fd36b;color:#06210f}#d2 .btn.o{background:transparent;color:#fff;border:1.5px solid #6cc0ff;box-shadow:none}
.nt{position:absolute;width:150px;height:68px;border-radius:7px;color:#fff;font:900 22px/1 'Bricolage Grotesque',sans-serif;display:flex;align-items:center;justify-content:space-between;padding:0 12px;box-shadow:0 6px 16px rgba(0,0,0,.5);border:2px solid rgba(255,255,255,.55);cursor:grab;touch-action:none;text-shadow:0 1px 2px rgba(0,0,0,.45)}
.nt::after{content:'';position:absolute;inset:5px;border:1px dashed rgba(255,255,255,.4);border-radius:4px;pointer-events:none}
.nt small{font:700 8px 'Figtree';letter-spacing:.14em;opacity:.85;text-align:center;line-height:1.3}.nt i{font-style:normal;width:26px;height:26px;border-radius:50%;background:rgba(255,255,255,.35)}
.nt.fly{transition:transform .75s cubic-bezier(.5,-.2,.3,1),opacity .75s;pointer-events:none}
.atm{position:relative;width:min(360px,84vw);padding:18px;border-radius:22px;background:linear-gradient(160deg,#27324a,#0f1626);border:2px solid #4a6aa8;box-shadow:0 0 60px rgba(60,140,255,.35);animation:d2z 6s ease-out both}
@keyframes d2z{from{transform:scale(.8)}to{transform:scale(1)}}
.atm .scr{height:112px;border-radius:10px;background:#07213f;border:2px solid #2a6fc0;padding:12px;font:700 15px/1.5 'Figtree';color:#8fe0ff;text-align:center;display:flex;flex-direction:column;justify-content:center;box-shadow:inset 0 0 24px rgba(60,170,255,.4)}
.atm .slot{position:relative;margin:16px auto 0;width:78%;height:16px;border-radius:8px;background:#000;box-shadow:0 0 14px rgba(255,213,74,.5)}
.atm .card{position:absolute;right:-60px;top:130px;width:80px;height:50px;border-radius:7px;background:linear-gradient(135deg,#0d3b8e,#1f7bff);border:1px solid #9cf;transition:transform .9s}
.atm .card.in{transform:translateX(-70px)}
.tray{position:relative;margin:8px auto 0;width:86%;height:86px}
.desk{position:relative;width:min(640px,94vw);height:min(330px,52vh);border-radius:18px;background:linear-gradient(180deg,#6b4423,#3d2410);border:2px solid #a0703b;box-shadow:0 20px 50px rgba(0,0,0,.6)}
.who{position:absolute;left:50%;top:-58px;transform:translateX(-50%);text-align:center;font:800 13px 'Figtree';letter-spacing:.08em}
.who b{display:block;margin:0 auto 4px;width:64px;height:64px;border-radius:50%;background:linear-gradient(135deg,#ff9ad5,#c43c93);border:3px solid #fff;font:900 30px/58px 'Bricolage Grotesque'}
.who.count b{animation:d2c .35s infinite alternate}@keyframes d2c{to{transform:translateY(-6px) rotate(6deg)}}
.cnt{position:absolute;left:0;right:0;top:34px;text-align:center;font:900 44px 'Bricolage Grotesque';color:#ffd54a;text-shadow:0 0 18px rgba(255,213,74,.5)}
.cnt small{display:block;font:700 12px 'Figtree';letter-spacing:.2em;color:#fff;opacity:.8}
.paper{position:relative;width:min(380px,90vw);padding:18px 20px 20px;background:#fdfaf0;color:#222;border-radius:6px;box-shadow:0 18px 44px rgba(0,0,0,.6);background-image:repeating-linear-gradient(0deg,transparent 0 23px,#e9e2cc 23px 24px);animation:d2in .7s cubic-bezier(.2,.9,.2,1.1) both}
@keyframes d2in{from{transform:translateY(120px) rotate(6deg);opacity:0}to{transform:none;opacity:1}}
.paper h3{margin:0 0 10px;padding:6px;background:#0d3b8e;color:#fff;text-align:center;font:800 12px 'Figtree';letter-spacing:.18em}
.paper p{margin:0;font-size:13.5px;line-height:24px}.paper p b{color:#0d3b8e}
.stamp{position:absolute;right:16px;bottom:56px;transform:rotate(-14deg);border:3px solid #d3202f;color:#d3202f;font:900 24px 'Bricolage Grotesque';padding:3px 12px;border-radius:6px;letter-spacing:.12em;opacity:0}
.stamp.slam{animation:d2s .45s cubic-bezier(.2,2,.4,1) both}@keyframes d2s{0%{transform:rotate(-14deg) scale(3.2);opacity:0}60%{opacity:1}100%{transform:rotate(-14deg) scale(1);opacity:.92}}
.shake{animation:d2k .35s}@keyframes d2k{25%{transform:translate(4px,-3px)}50%{transform:translate(-4px,3px)}75%{transform:translate(3px,2px)}}
.sig{position:relative;margin-top:8px;height:96px;border-radius:6px;background:rgba(255,255,255,.75);border:2px dashed #0d3b8e}
.sig canvas{position:absolute;inset:0;width:100%;height:100%;touch-action:none;cursor:crosshair}
.sig em{position:absolute;left:10px;top:4px;font:700 10px 'Figtree';letter-spacing:.14em;color:#0d3b8e;opacity:.7;font-style:normal;pointer-events:none}
.row{display:flex;gap:10px;justify-content:center;margin-top:12px}
.spk{position:absolute;width:8px;height:8px;border-radius:50%;background:#ffd54a;pointer-events:none;box-shadow:0 0 8px #ffd54a}

@media (max-height:540px){
#d2 .cap{top:10vh;font-size:10px}#d2 .hint{font-size:12px;bottom:10vh}#d2 .wal{font-size:14px;padding:6px 10px;bottom:calc(9vh + 6px)}
.paper{width:min(330px,62vw);padding:8px 14px 10px}.paper h3{padding:4px;margin-bottom:4px;font-size:10px}.paper p{font-size:11.5px;line-height:18px}.paper .stamp{font-size:16px;bottom:40px}
.sig{height:64px}.row{margin-top:6px}#d2 .btn{padding:8px 22px;font-size:13px}
.atm{width:min(300px,60vw);padding:10px}.atm .scr{height:78px;font-size:12px;padding:6px}.atm .slot{margin-top:8px}.tray{height:60px}
.desk{height:44vh}.who{top:-46px}.who b{width:46px;height:46px;font-size:22px;line-height:40px}.cnt{top:20px;font-size:30px}.nt{width:118px;height:54px;font-size:18px}
}
`;document.head.appendChild(css);

let ctx=null;const snd=(f,d,ty,v)=>{try{ctx=ctx||new (window.AudioContext||window.webkitAudioContext)();const o=ctx.createOscillator(),g=ctx.createGain();o.type=ty||'square';o.frequency.value=f;g.gain.value=v||.04;g.gain.exponentialRampToValueAtTime(.0001,ctx.currentTime+d);o.connect(g);g.connect(ctx.destination);o.start();o.stop(ctx.currentTime+d)}catch(e){}};
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
const split=a=>{const out=[];let r=a;[500,200,100,50,20,10].forEach(d=>{while(r>=d&&out.length<14){out.push(d);r-=d}});if(r>0)out.push(r);return out};
const note=d=>{const c=NOTES[d]||NOTES[10],n=document.createElement('div');n.className='nt';n.dataset.v=d;n.style.background='linear-gradient(135deg,'+c[0]+','+c[1]+' 55%,'+c[2]+')';n.innerHTML='<i></i><small>RESERVE BANK<br>OF ANITS</small><span>\u20B9'+d+'</span>';return n};
let root=null,wal=null,active=false;
function open(cap){if(!root){root=document.createElement('div');root.id='d2';root.setAttribute('data-testid','day2-cinematic');document.body.appendChild(root);root.addEventListener('pointerdown',e=>e.stopPropagation());root.addEventListener('click',e=>e.stopPropagation())}
 if(document.exitPointerLock)try{document.exitPointerLock()}catch(e){}
 root.innerHTML='<div class="bar t"></div><div class="bar b"></div><div class="cap"></div><div class="stage"></div><div class="hint"></div><div class="wal"></div>';
 root.querySelector('.cap').textContent=cap;wal=root.querySelector('.wal');root.style.display='block';active=true;requestAnimationFrame(()=>requestAnimationFrame(()=>root.classList.add('on')));
 return{st:root.querySelector('.stage'),hint:t=>root.querySelector('.hint').textContent=t}}
function close(){active=false;keyFn=null;if(root){root.classList.remove('on');root.style.display='none';root.innerHTML=''}}
const walTxt=v=>{wal.textContent='WALLET \u20B9'+v;wal.classList.remove('bump');void wal.offsetWidth;wal.classList.add('bump')};
const sparks=(x,y)=>{for(let i=0;i<14;i++){const s=document.createElement('i');s.className='spk';s.style.left=x+'px';s.style.top=y+'px';root.appendChild(s);const a=Math.random()*6.28,r=40+Math.random()*60;s.animate([{transform:'translate(0,0)',opacity:1},{transform:'translate('+Math.cos(a)*r+'px,'+Math.sin(a)*r+'px)',opacity:0}],{duration:700,easing:'ease-out'}).onfinish=()=>s.remove()}};
const fly=(el,to,dur)=>{const a=el.getBoundingClientRect(),b=to.getBoundingClientRect();el.classList.add('fly');el.style.transition='transform '+(dur||.75)+'s cubic-bezier(.5,-.2,.3,1),opacity '+(dur||.75)+'s';el.style.transform='translate('+(b.left+b.width/2-a.left-a.width/2)+'px,'+(b.top+b.height/2-a.top-a.height/2)+'px) scale(.25) rotate('+(Math.random()*40-20)+'deg)';el.style.opacity='0'};
let keyFn=null;
const waitKey=fn=>{keyFn=fn;return()=>{if(keyFn===fn)keyFn=null}};
addEventListener('keydown',e=>{if(!active)return;e.preventDefault();e.stopImmediatePropagation();if(!e.repeat&&keyFn&&(e.code==='Space'||e.code==='Enter'||e.code==='KeyE'))keyFn()},true);
const press=(el,fn)=>{let off=null;const go=()=>{if(off)off();el.onclick=null;fn()};el.onclick=go;off=waitKey(go)};

/* ---------- 1. ATM: card in, cash dispensed note by note, player takes the cash ---------- */
async function atm(amount,done){if(active)return;const{st,hint}=open('ANITS BANK ATM  \u00B7  CASH WITHDRAWAL');let w0=window.__vm?window.__vm.wallet-amount:0;walTxt(w0);
 st.innerHTML='<div class="atm"><div class="scr" id="d2s">Insert card\u2026</div><div class="card"></div><div class="slot"></div><div class="tray" id="d2t"></div></div>';
 const scr=st.querySelector('#d2s'),card=st.querySelector('.card'),tray=st.querySelector('#d2t');
 await sleep(700);card.classList.add('in');snd(520,.15,'triangle');await sleep(1000);card.style.transition='opacity .4s';card.style.opacity=0;
 scr.innerHTML='Enter PIN<br><span style="letter-spacing:.5em;font-size:22px">\u2022 \u2022 \u2022 \u2022</span>';await sleep(1100);
 scr.innerHTML='Processing\u2026<br>please wait';for(let i=0;i<4;i++){snd(300+i*60,.1,'sawtooth',.03);await sleep(300)}
 scr.innerHTML='Dispensing<br><b style="font-size:30px;color:#ffd54a">\u20B9'+amount+'</b>';
 const ds=split(amount),els=[];
 for(let i=0;i<ds.length;i++){const n=note(ds[i]);n.style.left=(50-75/ (tray.clientWidth||300)*100)+'%';n.style.left='calc(50% - 75px)';n.style.top='-70px';n.style.zIndex=i;tray.appendChild(n);
  n.animate([{transform:'translateY(-30px) rotate('+((i%2?1:-1)*3)+'deg)',opacity:0},{transform:'translateY('+(18+i*2)+'px) rotate('+((i%3-1)*5)+'deg)',opacity:1}],{duration:420,fill:'forwards',easing:'ease-out'});
  snd(180+Math.random()*60,.12,'sawtooth',.05);els.push(n);await sleep(Math.min(520,3200/ds.length))}
 snd(1040,.1,'square',.04);await sleep(300);
 hint('Take your cash: tap the notes (or press SPACE)');
 await new Promise(res=>{const take=async()=>{hint('');for(const n of els){const f=n.style.transform;fly(n,wal,.7);w0+=Math.min(+n.dataset.v,amount);walTxt(w0);snd(900+Math.random()*300,.07,'square',.04);await sleep(Math.min(180,1300/els.length))}await sleep(700);res()};
  tray.style.cursor='pointer';tray.onclick=take;els.forEach(n=>n.onclick=take);const off=waitKey(()=>{off();take()});scr.insertAdjacentHTML('beforeend','<small style="opacity:.8">Please take your cash</small>')});
 walTxt(window.__vm?window.__vm.wallet:w0);sparks(innerWidth-80,innerHeight-80);snd(1568,.25,'triangle',.05);await sleep(600);close();done&&done()}

/* ---------- 2. Pay Laksmi in cash, submit the fee report, sign the receipt ---------- */
const me=()=>window.__inv&&window.__inv.me?window.__inv.me():{name:'Student',roll:'24A91A0500'};
function sigPad(host,onInk){const c=document.createElement('canvas');host.appendChild(c);const dpr=Math.min(devicePixelRatio||1,2);let g,ink=0,last=null,drawing=false,paths=[];
 const size=()=>{const r=host.getBoundingClientRect();c.width=r.width*dpr;c.height=r.height*dpr;g=c.getContext('2d');g.scale(dpr,dpr);g.lineWidth=2.6;g.lineCap=g.lineJoin='round';g.strokeStyle='#0b2a8a'};size();
 const pt=e=>{const r=c.getBoundingClientRect();return[e.clientX-r.left,e.clientY-r.top]};
 c.addEventListener('pointerdown',e=>{e.preventDefault();c.setPointerCapture(e.pointerId);drawing=true;last=pt(e);g.beginPath();g.arc(last[0],last[1],1.3,0,6.28);g.fill()});
 c.addEventListener('pointermove',e=>{if(!drawing)return;e.preventDefault();const p=pt(e);g.beginPath();g.moveTo(last[0],last[1]);g.lineTo(p[0],p[1]);g.stroke();ink+=Math.hypot(p[0]-last[0],p[1]-last[1]);last=p;onInk&&onInk(ink)});
 ['pointerup','pointercancel','pointerleave'].forEach(t=>c.addEventListener(t,()=>{drawing=false}));
 return{clear(){g.clearRect(0,0,c.width,c.height);ink=0;onInk&&onInk(0)},ink:()=>ink,data(){return c.toDataURL('image/png')}}}
async function pay(fee,done){if(active)return;const P=me(),{st,hint}=open('ADMIN BLOCK  \u00B7  FEE COUNTER');let w=window.__vm?window.__vm.wallet:fee;walTxt(w);
 /* stage 1: give the cash */
 st.innerHTML='<div class="desk"><div class="who" id="d2w"><b>L</b>Laksmi (Admin)</div><div class="cnt" id="d2c"><small>CASH RECEIVED</small>\u20B9 0 / '+fee+'</div></div>';
 const desk=st.querySelector('.desk'),who=st.querySelector('#d2w'),cnt=st.querySelector('#d2c'),ds=split(fee),sends=[];let paid=0,left=ds.length;
 hint('Hand over the cash: drag each note to the desk (or tap it)');
 await new Promise(res=>{ds.forEach((d,i)=>{const n=note(d);n.style.position='fixed';const gap=Math.min(100,(innerWidth-260)/Math.max(1,ds.length));n.style.left=(innerWidth/2-ds.length*gap/2+i*gap-(75-gap/2))+'px';n.style.top=(innerHeight*(innerHeight<540?.6:.66)+(i%2)*14)+'px';n.style.zIndex=10+i;n.style.transform='rotate('+((i%3-1)*5)+'deg)';root.appendChild(n);
   n.animate([{opacity:0,transform:'translateY(60px)'},{opacity:1,transform:n.style.transform}],{duration:500,delay:i*90,fill:'backwards'});
   let sx,sy,mv=0,drag=false,done1=false;sends.push(()=>{if(done1)return false;send();return true});
   const send=async()=>{if(done1)return;done1=true;const r=desk.getBoundingClientRect(),a=n.getBoundingClientRect();n.style.transition='transform .55s cubic-bezier(.3,1.2,.4,1)';n.style.transform='translate('+(r.left+r.width/2-a.left-a.width/2+(Math.random()*120-60))+'px,'+(r.top+r.height*.6-a.top-a.height/2+(Math.random()*40-20))+'px) rotate('+(Math.random()*30-15)+'deg)';snd(300+Math.random()*80,.1,'triangle',.06);await sleep(560);n.style.pointerEvents='none';paid+=d;w-=d;walTxt(Math.max(0,w));cnt.innerHTML='<small>CASH RECEIVED</small>\u20B9 '+paid+' / '+fee;snd(880,.08,'square',.04);if(--left===0){hint('');res()}};
   n.addEventListener('pointerdown',e=>{n.setPointerCapture(e.pointerId);drag=true;mv=0;sx=e.clientX;sy=e.clientY;n.style.transition='none'});
   n.addEventListener('pointermove',e=>{if(!drag||done1)return;mv=Math.max(mv,Math.hypot(e.clientX-sx,e.clientY-sy));n.style.transform='translate('+(e.clientX-sx)+'px,'+(e.clientY-sy)+'px) rotate(0deg)'});
   n.addEventListener('pointerup',e=>{if(!drag)return;drag=false;const dr=desk.getBoundingClientRect();if(mv<8||(e.clientY<dr.bottom&&e.clientY>dr.top-120))send();else{n.style.transition='transform .3s';n.style.transform='rotate('+((i%3-1)*5)+'deg)'}})});
  waitKey(()=>{for(const f of sends)if(f())break})});
 who.classList.add('count');hint('Laksmi is counting the cash\u2026');for(let i=0;i<6;i++){snd(700+(i%2)*160,.07,'triangle',.04);await sleep(330)}who.classList.remove('count');
 cnt.innerHTML='<small>COUNTED &amp; VERIFIED</small>\u2713 \u20B9'+fee;snd(1318,.25,'triangle',.05);sparks(innerWidth/2,innerHeight/2);root.querySelectorAll('.nt').forEach(n=>{n.style.transition='opacity .5s';n.style.opacity=0});await sleep(900);root.querySelectorAll('.nt').forEach(n=>n.remove());
 /* stage 2: submit the fee report */
 root.querySelector('.cap').textContent='FEE PAYMENT REPORT';hint('');
 const today=new Date().toLocaleDateString('en-IN',{day:'2-digit',month:'short',year:'numeric'});
 st.innerHTML='<div><div class="paper" id="d2p"><h3>ANITS \u00B7 FEE PAYMENT REPORT</h3><p>Student: <b>'+P.name+'</b></p><p>Roll no: <b>'+P.roll+'</b></p><p>Purpose: <b>Tuition fee (Sem 1)</b></p><p>Amount paid: <b>\u20B9'+fee+' (cash)</b></p><p>Date: <b>'+today+'</b></p><div class="stamp" id="d2st">SUBMITTED</div></div><div class="row"><button class="btn g" id="d2sub" data-testid="submit-report-btn">SUBMIT REPORT</button></div></div>';
 hint('Check the details and submit your report to Laksmi');
 await new Promise(res=>press(st.querySelector('#d2sub'),res));
 st.querySelector('#d2sub').style.display='none';hint('');const pp=st.querySelector('#d2p');await sleep(350);st.querySelector('#d2st').classList.add('slam');snd(110,.25,'sawtooth',.09);setTimeout(()=>snd(80,.3,'triangle',.08),120);pp.classList.add('shake');sparks(innerWidth/2,innerHeight/2);await sleep(1500);
 /* stage 3: receive the receipt and sign for it */
 root.querySelector('.cap').textContent='RECEIPT  \u00B7  SIGN TO RECEIVE';
 st.innerHTML='<div><div class="paper" id="d2r"><h3>ANITS \u00B7 FEE RECEIPT</h3><p>Name: <b>'+P.name+'</b> &nbsp; Roll: <b>'+P.roll+'</b></p><p>Tuition fee (Sem 1): <b>\u20B9'+fee+'</b></p><p>Receipt no: <b>FR-'+P.roll.slice(-4)+'</b> &nbsp; Date: <b>'+today+'</b></p><p style="font-size:12px;margin-top:4px">Student signature (received by):</p><div class="sig" id="d2sig"><em>SIGN HERE WITH FINGER / MOUSE</em></div><div class="stamp" id="d2pd">PAID</div></div><div class="row"><button class="btn o" id="d2clr" data-testid="sign-clear-btn">CLEAR</button><button class="btn g" id="d2ok" data-testid="sign-accept-btn" disabled style="opacity:.45">ACCEPT RECEIPT</button></div></div>';
 snd(600,.2,'triangle',.04);hint('Laksmi: "Please sign here to receive your receipt."');
 const host=st.querySelector('#d2sig'),ok=st.querySelector('#d2ok'),pad=sigPad(host,v=>{host.querySelector('em').style.opacity=v?0:.7;const on=v>60;ok.disabled=!on;ok.style.opacity=on?1:.45});
 st.querySelector('#d2clr').onclick=()=>pad.clear();
 await new Promise(res=>{ok.onclick=()=>{if(!ok.disabled)res()}});
 const sig=pad.data();try{LS.setItem(SIGKEY,sig)}catch(e){}hint('');ok.parentNode.style.display='none';
 await sleep(250);st.querySelector('#d2pd').classList.add('slam');snd(110,.25,'sawtooth',.09);await sleep(900);
 /* receipt flies into the bag */
 const bag=document.getElementById('inv-btn'),rc=st.querySelector('#d2r');window.__inv&&window.__inv.give('fee');
 if(bag&&bag.getBoundingClientRect().width){fly(rc,bag,.9)}else{rc.style.transition='all .8s';rc.style.transform='translateY(200px) scale(.2)';rc.style.opacity=0}
 snd(520,.12,'triangle');setTimeout(()=>snd(780,.15,'triangle'),120);await sleep(950);
 window.__inv&&window.__inv.toast&&window.__inv.toast('Signed receipt saved to your BAG (press B)');close();done&&done()}

window.__day2={atm,pay,signature:()=>{try{return LS.getItem(SIGKEY)}catch(e){return null}},get active(){return active}};

/* ---------- Day 7: lab manual run. stages: issue (Suresh) / prof (Prof. Rao signs) / stamp (Laksmi, you stamp it) / return (Suresh, you sign the lab register) ---------- */
const LABK='anits-lab',labGet=()=>{try{return JSON.parse(LS.getItem(LABK))||{}}catch(e){return{}}},labSet=o=>{try{LS.setItem(LABK,JSON.stringify(o))}catch(e){}};
const PSIG=off=>'<svg viewBox="0 0 120 40" width="110" height="36"><path id="d2ps" d="M4 30 C14 4 22 4 24 22 C26 34 34 8 44 18 C52 26 60 10 70 20 L74 30 C86 14 96 12 116 22" fill="none" stroke="#0b2a8a" stroke-width="2.4" stroke-linecap="round" stroke-dasharray="260" stroke-dashoffset="'+off+'"/></svg>';
function labPaper(P,L,extra){return '<div class="paper" id="d2lp"><h3>ANITS \u00B7 LAB MANUAL FORM</h3><p>Student: <b>'+P.name+'</b> &nbsp; Roll: <b>'+P.roll+'</b></p><p>Subject: <b>Computer Lab \u00B7 Sem 1</b></p>'+
 '<p style="font-size:12px">Received by: '+(L.issue?'<img src="'+L.issue+'" style="height:26px;vertical-align:middle">':'<span style="opacity:.4">pending</span>')+'</p>'+
 '<p style="font-size:12px">Prof. Rao: '+(L.prof?'<span id="d2pr">'+PSIG(0)+'</span>':'<span style="opacity:.4">pending</span>')+'</p>'+
 '<p style="font-size:12px">Admin stamp: '+(L.stamp?'<b style="color:#d3202f">APPROVED \u2713</b>':'<span style="opacity:.4">pending</span>')+'</p>'+(extra||'')+'</div>'}
async function lab(stage,done){if(active)return;const P=me(),L=labGet(),{st,hint}=open('LAB MANUAL RUN  \u00B7  '+({issue:'IT BLOCK',prof:'CSE BLOCK',stamp:'ADMIN BLOCK',return:'IT BLOCK'}[stage]||''));if(wal)wal.style.display='none';
 const finish=async()=>{await sleep(300);close();done&&done()};
 if(stage==='issue'||stage==='return'){
  const ret=stage==='return';
  st.innerHTML='<div>'+labPaper(P,L,'<p style="font-size:12px;margin-top:4px">'+(ret?'Lab register entry. Sign to collect your lab pass:':'Sign to receive the form:')+'</p><div class="sig" id="d2sig"><em>SIGN HERE WITH FINGER / MOUSE</em></div><div class="stamp" id="d2pd">'+(ret?'LAB OPEN':'ISSUED')+'</div>')+'<div class="row"><button class="btn o" id="d2clr">CLEAR</button><button class="btn g" id="d2ok" disabled style="opacity:.45" data-testid="lab-sign-btn">'+(ret?'SUBMIT FORM':'TAKE FORM')+'</button></div></div>';
  hint(ret?'Suresh: "Sign the lab register and I will unlock the lab."':'Suresh: "Sign here to take your lab manual form."');snd(600,.2,'triangle',.04);
  const host=st.querySelector('#d2sig'),ok=st.querySelector('#d2ok'),pad=sigPad(host,v=>{host.querySelector('em').style.opacity=v?0:.7;const on=v>60;ok.disabled=!on;ok.style.opacity=on?1:.45});
  st.querySelector('#d2clr').onclick=()=>pad.clear();
  await new Promise(res=>{ok.onclick=()=>{if(!ok.disabled)res()}});
  const sg=pad.data();hint('');ok.parentNode.style.display='none';
  if(ret){try{LS.setItem(SIGKEY,LS.getItem(SIGKEY)||sg)}catch(e){}L.reg=sg;L.issue=L.issue||sg;labSet(L)}else{L.issue=sg;labSet(L)}
  await sleep(250);st.querySelector('#d2pd').classList.add('slam');snd(110,.25,'sawtooth',.09);sparks(innerWidth/2,innerHeight/2);await sleep(900);
  if(ret){const bag=document.getElementById('inv-btn'),rc=st.querySelector('#d2lp');window.__inv&&window.__inv.give('lab');if(bag&&bag.getBoundingClientRect().width)fly(rc,bag,.9);await sleep(950);window.__inv&&window.__inv.toast&&window.__inv.toast('Signed lab form saved to your BAG (press B)')}
  return finish()}
 if(stage==='prof'){
  st.innerHTML='<div>'+labPaper(P,L)+'<div class="row"><button class="btn g" id="d2ok">TAP TO WATCH PROF. RAO SIGN</button></div></div>';hint('');
  await new Promise(res=>press(st.querySelector('#d2ok'),res));st.querySelector('#d2ok').style.display='none';
  L.prof=1;labSet(L);const pr=st.querySelector('#d2lp p:nth-of-type(4)');pr.innerHTML='Prof. Rao: <span id="d2pr">'+PSIG(260)+'</span>';const path=pr.querySelector('#d2ps');
  for(let i=0;i<=20;i++){path.style.strokeDashoffset=260-13*i;if(i%2)snd(500+Math.random()*200,.04,'triangle',.02);await sleep(70)}
  snd(1318,.25,'triangle',.05);hint('Prof. Rao: "Signature done. Now take the stamp from Laksmi."');await sleep(1800);return finish()}
 if(stage==='stamp'){
  st.innerHTML='<div>'+labPaper(P,L,'<div style="position:relative;height:60px"><div class="stamp" id="d2pd" style="left:40%;right:auto;bottom:6px">APPROVED</div></div>')+'</div>';
  hint('Press the stamp onto the form: tap or click on the paper (or press SPACE)');
  const pp=st.querySelector('#d2lp'),sp=st.querySelector('#d2pd');
  await new Promise(res=>{let used=0;const hit=(x,y)=>{if(used)return;used=1;const r=pp.getBoundingClientRect();if(x!=null){sp.style.left=Math.max(4,Math.min(r.width-170,x-r.left-70))+'px';sp.style.bottom=Math.max(0,Math.min(50,r.bottom-y-20))+'px'}sp.classList.add('slam');snd(110,.25,'sawtooth',.09);setTimeout(()=>snd(80,.3,'triangle',.08),120);pp.classList.add('shake');sparks(innerWidth/2,innerHeight/2);res()};
   pp.addEventListener('pointerdown',e=>hit(e.clientX,e.clientY));waitKey(()=>hit())});
  L.stamp=1;labSet(L);hint('');await sleep(1300);hint('Laksmi: "Stamp done. Take it back to Suresh quickly!"');await sleep(1500);return finish()}
 close();done&&done()}
window.__day2.lab=lab;window.__day2.labData=labGet;

/* ---------- Day 4: library card. stages: admin (Laksmi) / hod (Prof. Rao) / lab (Suresh) / submit (Civil Block library) ---------- */
const LIBK='anits-lib',libGet=()=>{try{return JSON.parse(LS.getItem(LIBK))||{}}catch(e){return{}}},libSet=o=>{try{LS.setItem(LIBK,JSON.stringify(o))}catch(e){}};
const SGP={admin:'M4 28 C10 6 20 6 22 24 C24 36 30 10 40 20 L46 30 C58 8 70 12 78 26 C90 36 102 14 116 18',hod:'M4 30 C14 4 22 4 24 22 C26 34 34 8 44 18 C52 26 60 10 70 20 L74 30 C86 14 96 12 116 22',lab:'M4 20 L16 8 L24 32 L36 8 L46 32 C60 12 70 32 84 14 C96 4 104 30 116 24'};
const sgSvg=(k,off)=>'<svg viewBox="0 0 120 40" width="96" height="32" style="vertical-align:middle"><path class="sgp" d="'+SGP[k]+'" fill="none" stroke="#0b2a8a" stroke-width="2.4" stroke-linecap="round" stroke-dasharray="300" stroke-dashoffset="'+off+'"/></svg>';
function libPaper(P,L,extra,hl){const row=(k,t)=>'<p style="font-size:12px'+(hl===k?';background:rgba(255,213,74,.35)':'')+'" data-k="'+k+'">'+t+': '+(L[k]?'<span class="sgw">'+sgSvg(k,0)+'</span><b class="ck" style="color:#1f8a4a;opacity:0"> \u2713</b>':'<span style="opacity:.4">pending</span>')+'</p>';
 return '<div class="paper" id="d2lb"><h3>ANITS \u00B7 LIBRARY CARD APPLICATION</h3><p>Student: <b>'+P.name+'</b> &nbsp; Roll: <b>'+P.roll+'</b></p><p style="font-size:12px">Applicant: '+(L.me?'<img src="'+L.me+'" style="height:24px;vertical-align:middle">':'<span style="opacity:.4">pending</span>')+'</p>'+
 row('admin','Admin Officer (Laksmi)')+row('hod','HOD CSE (Prof. Rao)')+row('lab','Lab Assistant (Suresh)')+(extra||'')+'</div>'}
async function drawSig(st,k){const p=st.querySelector('[data-k="'+k+'"]');p.innerHTML=({admin:'Admin Officer (Laksmi)',hod:'HOD CSE (Prof. Rao)',lab:'Lab Assistant (Suresh)'})[k]+': <span class="sgw">'+sgSvg(k,300)+'</span>';const path=p.querySelector('.sgp');
 for(let i=0;i<=20;i++){path.style.strokeDashoffset=300-15*i;if(i%2)snd(500+Math.random()*200,.04,'triangle',.02);await sleep(70)}snd(1318,.25,'triangle',.05)}
async function libsign(stage,done){if(active)return;const P=me(),L=libGet(),loc={admin:'ADMIN BLOCK',hod:'CSE BLOCK',lab:'IT BLOCK',submit:'CIVIL BLOCK \u00B7 LIBRARY'}[stage]||'';const{st,hint}=open('LIBRARY CARD  \u00B7  '+loc);if(wal)wal.style.display='none';
 const finish=async()=>{await sleep(300);close();done&&done()};
 if(stage==='admin'){
  st.innerHTML='<div>'+libPaper(P,L,'<p style="font-size:12px;margin-top:4px">Sign as the applicant:</p><div class="sig" id="d2sig"><em>SIGN HERE WITH FINGER / MOUSE</em></div>','admin')+'<div class="row"><button class="btn o" id="d2clr">CLEAR</button><button class="btn g" id="d2ok" disabled style="opacity:.45" data-testid="lib-sign-btn">SUBMIT TO LAKSMI</button></div></div>';
  hint('Laksmi: "Sign the form first, then I will sign as Admin Officer."');snd(600,.2,'triangle',.04);
  const host=st.querySelector('#d2sig'),ok=st.querySelector('#d2ok'),pad=sigPad(host,v=>{host.querySelector('em').style.opacity=v?0:.7;const on=v>60;ok.disabled=!on;ok.style.opacity=on?1:.45});
  st.querySelector('#d2clr').onclick=()=>pad.clear();await new Promise(res=>{ok.onclick=()=>{if(!ok.disabled)res()}});
  L.me=pad.data();hint('');st.querySelector('.row').style.display='none';host.parentNode.querySelector('.sig').style.display='none';st.querySelector('#d2lb p:nth-of-type(4)').innerHTML='Applicant: <img src="'+L.me+'" style="height:24px;vertical-align:middle">';
  await sleep(500);await drawSig(st,'admin');L.admin=1;libSet(L);hint('Laksmi: "Signed! Now get the HOD\'s signature at the CSE Block."');await sleep(1800);return finish()}
 if(stage==='hod'||stage==='lab'){
  const who=stage==='hod'?'Prof. Rao':'Suresh';
  st.innerHTML='<div>'+libPaper(P,L,'',stage)+'<div class="row"><button class="btn g" id="d2ok" data-testid="lib-watch-btn">HAND THE FORM TO '+who.toUpperCase()+'</button></div></div>';hint('');
  await new Promise(res=>press(st.querySelector('#d2ok'),res));st.querySelector('#d2ok').style.display='none';
  await drawSig(st,stage);L[stage]=1;libSet(L);hint(stage==='hod'?'Prof. Rao: "Approved. Now the lab assistant must sign too."':'Suresh: "Signed! Now go to the library in the Civil Block."');await sleep(1800);return finish()}
 if(stage==='submit'){
  st.innerHTML='<div>'+libPaper(P,L,'<div class="stamp" id="d2pd">VERIFIED</div>')+'<div class="row"><button class="btn g" id="d2ok" data-testid="lib-submit-btn">SUBMIT ALL SIGNATURES</button></div></div>';
  hint('Librarian: "Hand over the form with all three signatures."');
  await new Promise(res=>press(st.querySelector('#d2ok'),res));st.querySelector('#d2ok').style.display='none';hint('Librarian is checking each signature...');
  for(const k of ['admin','hod','lab']){const p=st.querySelector('[data-k="'+k+'"] .ck');if(p){p.style.transition='opacity .3s';p.style.opacity=1}snd(880,.1,'square',.04);await sleep(800)}
  st.querySelector('#d2pd').classList.add('slam');snd(110,.25,'sawtooth',.09);sparks(innerWidth/2,innerHeight/2);await sleep(1300);
  root.querySelector('.cap').textContent='LIBRARY CARD ISSUED';hint('');st.innerHTML='<div style="text-align:center"><div id="d2lc" style="display:inline-block;transform:scale(1.5);margin:30px 0 30px"></div></div>';
  const c=window.__inv&&window.__inv.card?window.__inv.card('lib'):document.createElement('div');c.style.animation='d2in .7s both';st.querySelector('#d2lc').appendChild(c);snd(1046,.3,'triangle',.05);sparks(innerWidth/2,innerHeight/2);hint('Librarian: "Here is your library card. Enjoy reading!"');await sleep(2600);
  window.__inv&&window.__inv.give('lib');const bag=document.getElementById('inv-btn');if(bag&&bag.getBoundingClientRect().width)fly(c,bag,.9);await sleep(950);window.__inv&&window.__inv.toast&&window.__inv.toast('Library card saved to your BAG (press B)');return finish()}
 close();done&&done()}
window.__day2.libsign=libsign;
})();
