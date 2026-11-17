/* Inventory: collectible ID card, fee receipt, library card. Key B / bag button. window.__inv */
(()=>{
const LS=localStorage,KEY='anits-items';
const META={
 id:{n:'Student ID Card',from:'Day 1',hint:'Complete Day 1 to collect your ID card.'},
 fee:{n:'Fee Receipt',from:'Day 2',hint:'Complete Day 2 (Pay the Fees) to collect the receipt.'},
 lib:{n:'Library Card',from:'Day 4',hint:'Complete Day 4 (Library Card) to collect it.'},
 lab:{n:'Lab Manual Form',from:'Day 7',hint:'Complete Day 7 (Lab Manual Run) to collect the signed form.'},
 ncc:{n:'NCC Parade Certificate',from:'Day 6',hint:'Complete Day 6 (NCC Parade) to collect your certificate.'}};
const css=document.createElement('style');css.textContent=`
#inv-btn{position:fixed;left:16px;bottom:100px;z-index:12;display:none;align-items:center;gap:8px;padding:10px 14px;border-radius:12px;border:1.5px solid rgba(120,190,255,.8);background:rgba(6,22,56,.78);color:#fff;font:800 13px 'Figtree',sans-serif;letter-spacing:.1em;cursor:pointer;backdrop-filter:blur(6px)}
#inv-btn:hover{background:rgba(30,90,190,.85)}#inv-btn svg{width:20px;height:20px}#inv-btn kbd{font:800 11px 'Figtree';padding:2px 6px;border-radius:5px;background:rgba(255,255,255,.16)}
#inv{position:fixed;inset:0;z-index:31;display:none;align-items:center;justify-content:center;background:rgba(3,10,24,.76);backdrop-filter:blur(7px);color:#fff;font-family:'Figtree',system-ui,sans-serif}
#inv .ib{width:min(900px,95vw);max-height:92vh;overflow:auto;padding:26px 28px;border-radius:20px;border:1.5px solid #3aa0ff;background:linear-gradient(160deg,rgba(10,32,70,.97),rgba(5,14,34,.97));box-shadow:0 0 44px rgba(40,140,255,.35);animation:mpop .35s both}
#inv h2{margin:0;font:800 28px 'Bricolage Grotesque',sans-serif;letter-spacing:.12em}#inv .sub{margin:6px 0 20px;font-size:15px;opacity:.8}#inv .sub.ask{color:#ffd54a;opacity:1;font-weight:700}
#inv .ig{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:18px}
#inv .slot{display:flex;flex-direction:column;align-items:center;gap:10px;padding:14px;border-radius:14px;background:rgba(255,255,255,.05);border:1px solid rgba(120,190,255,.25)}
#inv .slot.empty{opacity:.55;border-style:dashed}#inv .slot b{font-size:15px;letter-spacing:.06em}#inv .slot small{opacity:.7;text-align:center;font-size:12px;min-height:30px}
#inv .x{margin-top:18px;display:flex;justify-content:flex-end;gap:10px}
#inv .show{padding:10px 26px;border-radius:999px;border:0;background:#2fd36b;color:#06210f;font:800 15px 'Figtree';letter-spacing:.08em;cursor:pointer;box-shadow:0 0 18px rgba(47,211,107,.5);animation:ipulse 1.2s infinite}
@keyframes ipulse{50%{transform:scale(1.06)}}#inv .close{padding:10px 24px;border-radius:999px;border:1.5px solid #6cc0ff;background:transparent;color:#fff;font:800 14px 'Figtree';cursor:pointer}
.ic{width:220px;height:140px;border-radius:12px;position:relative;overflow:hidden;color:#fff;box-shadow:0 8px 22px rgba(0,0,0,.45);font-family:'Figtree',sans-serif;flex:none}
.ic.id{background:linear-gradient(135deg,#0d3b8e,#1f7bff)}.ic.lib{background:linear-gradient(135deg,#0d6b3c,#2fbf71)}
.ic .h{padding:7px 10px;font:800 9px 'Figtree';letter-spacing:.16em;background:rgba(0,0,0,.28)}
.ic .ph{position:absolute;left:12px;top:36px;width:48px;height:58px;border-radius:7px;background:#e7f1ff;color:#0d3b8e;font:800 26px/58px 'Bricolage Grotesque',sans-serif;text-align:center}.ic.lib .ph{color:#0d6b3c;background:#e6fff0}
.ic .t{position:absolute;left:70px;top:36px;right:8px;font-size:12px;line-height:1.35}.ic .t strong{display:block;font:800 15px 'Bricolage Grotesque';margin-bottom:2px;word-break:break-word}
.ic .bc{position:absolute;left:12px;right:12px;bottom:9px;height:14px;background:repeating-linear-gradient(90deg,#fff 0 2px,transparent 2px 4px,#fff 4px 5px,transparent 5px 8px);opacity:.85;border-radius:2px}
.ic.fee{background:#fdfaf0;color:#222;border-radius:4px;box-shadow:0 8px 22px rgba(0,0,0,.45);background-image:radial-gradient(circle at 0 50%,transparent 5px,#fdfaf0 6px),repeating-linear-gradient(0deg,transparent 0 17px,#e9e2cc 17px 18px)}
.ic.fee .h{background:#0d3b8e;color:#fff;text-align:center}.ic.fee .t{left:12px;top:34px;font-size:11.5px;color:#333}.ic.fee .t strong{font-size:14px;color:#111}
.ic.fee .sg{position:absolute;left:10px;bottom:6px;width:100px;height:38px;object-fit:contain;mix-blend-mode:multiply}
.ic.fee .st{position:absolute;right:10px;bottom:12px;transform:rotate(-14deg);border:2.5px solid #d3202f;color:#d3202f;font:900 18px 'Bricolage Grotesque';padding:2px 8px;border-radius:5px;letter-spacing:.1em}
#inv-toast{position:fixed;left:50%;top:14%;transform:translateX(-50%);z-index:33;padding:12px 22px;border-radius:999px;background:rgba(47,211,107,.95);color:#06210f;font:800 15px 'Figtree',sans-serif;opacity:0;pointer-events:none;transition:opacity .4s}
`;document.head.appendChild(css);
const items=()=>{try{return JSON.parse(LS.getItem(KEY))||{}}catch(e){return{}}};
const prof=()=>{try{return JSON.parse(LS.getItem('anits-profile'))||{}}catch(e){return{}}};
const nm=()=>(window.__PROFILE&&window.__PROFILE.name)||prof().name||'Student';
const roll=()=>{let h=7;for(const c of nm())h=(h*31+c.charCodeAt(0))%9000;return '24A91A05'+String(10+h%90)};
const sg=()=>{try{return LS.getItem('anits-sign')}catch(e){return null}};
function card(id){const d=document.createElement('div'),n=nm(),R=roll();
 if(id==='id'){d.className='ic id';d.innerHTML='<div class="h">ANITS &middot; STUDENT ID</div><div class="ph">'+n[0].toUpperCase()+'</div><div class="t"><strong>'+n+'</strong>B.Tech CSE &middot; Year 1<br>Roll '+R+'</div><div class="bc"></div>'}
 else if(id==='lib'){d.className='ic lib';d.innerHTML='<div class="h">CENTRAL LIBRARY &middot; ANITS</div><div class="ph">'+n[0].toUpperCase()+'</div><div class="t"><strong>'+n+'</strong>Member LB-'+R.slice(-4)+'<br>Valid: 4 years</div><div class="bc"></div>'}
 else if(id==='ncc'){const P=window.__parade,t=P?P.total():0;d.className='ic ncc';d.innerHTML='<div class="h">NCC &middot; ANITS UNIT</div><div class="t"><strong>'+n+'</strong>Parade certificate<br>Grade: '+(P?P.grade(t):'Cadet')+' ('+t+'/100)</div><div class="st">JAI HIND</div>'}
 else if(id==='lab'){const L=window.__day2&&window.__day2.labData?window.__day2.labData():{};d.className='ic fee';d.innerHTML='<div class="h">LAB MANUAL FORM</div><div class="t"><strong>'+n+'</strong>Roll '+R+'<br>Prof. Rao: signed<br>Admin: stamped</div>'+(L.reg||L.issue?'<img class="sg" src="'+(L.reg||L.issue)+'" alt="signature">':'')+'<div class="st">LAB OPEN</div>'}
 else{d.className='ic fee';d.innerHTML='<div class="h">ANITS &middot; FEE RECEIPT</div><div class="t"><strong>'+n+'</strong>Roll '+R+'<br>Tuition fee (Sem 1): &#8377;250<br>Receipt no. FR-'+R.slice(-4)+'</div><div class="st">PAID</div>'+(sg()?'<img class="sg" src="'+sg()+'" alt="signature">':'')}
 return d}
let el,open=false,cb=null,enabled=false,btn;
function build(){el=document.createElement('div');el.id='inv';el.setAttribute('data-testid','inventory-panel');document.body.appendChild(el);
 el.addEventListener('pointerdown',e=>e.stopPropagation());
 btn=document.createElement('button');btn.id='inv-btn';btn.setAttribute('data-testid','inventory-btn');btn.innerHTML='<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M7 8V6a5 5 0 0110 0v2M5 8h14l1 13H4z"/></svg>BAG <kbd>B</kbd>';btn.onclick=()=>toggle();document.body.appendChild(btn);
 const t=document.createElement('div');t.id='inv-toast';document.body.appendChild(t)}
function render(ask){const have=items();el.innerHTML='<div class="ib"><h2>INVENTORY</h2><div class="sub'+(ask?' ask':'')+'">'+(ask?'Security Bajirao: "Show me your ID card, please." Press SHOW on your ID card.':'Your ANITS documents. Security checks your ID card at the gate every day.')+'</div><div class="ig"></div><div class="x"><button class="close" data-testid="inventory-close-btn">CLOSE (B)</button></div></div>';
 const g=el.querySelector('.ig');
 Object.keys(META).forEach(id=>{const s=document.createElement('div'),m=META[id];s.className='slot'+(have[id]?'':' empty');s.setAttribute('data-testid','inv-item-'+id);
  if(have[id]){s.appendChild(card(id));s.insertAdjacentHTML('beforeend','<b>'+m.n+'</b><small>Collected after '+m.from+'</small>');
   if(ask&&id==='id'){const b=document.createElement('button');b.className='show';b.textContent='SHOW';b.setAttribute('data-testid','inv-show-id-btn');b.onclick=()=>{const f=cb;cb=null;close();f&&f()};s.appendChild(b)}}
  else s.insertAdjacentHTML('beforeend','<div class="ic" style="border:2px dashed rgba(255,255,255,.3);box-shadow:none;display:flex;align-items:center;justify-content:center;font-size:12px;letter-spacing:.2em">EMPTY</div><b>'+m.n+'</b><small>'+m.hint+'</small>');
  g.appendChild(s)});
 el.querySelector('.close').onclick=()=>close()}
function openP(ask){if(!el)build();if(document.exitPointerLock)try{document.exitPointerLock()}catch(e){}open=true;render(ask);el.style.display='flex'}
function close(){open=false;if(el)el.style.display='none'}
function toggle(){if(open)return close();const ov=document.getElementById('ov'),g=window.__g;if(!enabled||window.__call||(window.__mini&&window.__mini.active)||(ov&&ov.style.display!=='none')||(g&&g.dlg))return;openP(false)}
addEventListener('keydown',e=>{if(!open){if(e.code==='KeyB'&&!e.repeat&&(!e.target||e.target.tagName!=='INPUT'))toggle();return}e.preventDefault();e.stopImmediatePropagation();if(e.code==='KeyB'||e.code==='Escape')close()},true);
function give(id){const h=items();if(h[id])return false;h[id]=1;LS.setItem(KEY,JSON.stringify(h));return true}
function toast(t){if(!el)build();const x=document.getElementById('inv-toast');x.textContent=t;x.style.opacity=1;setTimeout(()=>x.style.opacity=0,3200)}
window.__inv={me:()=>({name:nm(),roll:roll()}),has:id=>!!items()[id],give,card,META,
 enable(){if(!el)build();enabled=true;btn.style.display='flex'},
 ask(done){if(!items().id){give('id');toast('Bajirao issued you a temporary ID card')}cb=done;openP(true)},
 toast,isOpen:()=>open,reset(){LS.removeItem(KEY)}};
})();
