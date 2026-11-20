
(()=>{
const SS=window.speechSynthesis;let curA=null,vs=[],profiles=new Map(),nM=0,nF=0,nCad=0,tm=0,tok=0;
const load=()=>{try{vs=SS?SS.getVoices():[]}catch(e){vs=[]}};load();if(SS)SS.onvoiceschanged=load;
const GTE={"Jai Hind! Sir is watching, I cannot talk now!":"జై హింద్! సర్ చూస్తున్నారు, ఇప్పుడు మాట్లాడలేను!","Jai Hind!":"జై హింద్!"};   // girl cadets: Telugu line for the built-in te-IN voice
const FEM=/female|zira|samantha|susan|hazel|heera|veena|karen|moira|tessa|fiona|aria|jenny|libby|sonia|victoria|allison|ava|serena|kalpana|neerja|priya|swara|lekha|raveena|google uk english female|natasha|catherine|linda|joanna|salli/i;
const MALE=/male|david|mark|george|ravi|hemant|prabhat|daniel|alex|fred|rishi|guy|ryan|james|richard|thomas|oliver|aaron|rocko|google uk english male|christopher|eric|roger|brian|matthew|arthur/i;
const pool=g=>{let en=vs.filter(v=>/^en/i.test(v.lang));if(!en.length)en=vs.slice();
 let p=en.filter(v=>g==='f'?FEM.test(v.name)&&!/\bmale\b(?!.*female)/i.test(v.name.replace(/female/ig,'')):(MALE.test(v.name)&&!/female/i.test(v.name)));
 if(!p.length)p=en;p=p.slice().sort((a,b)=>(/en-IN/i.test(b.lang)-/en-IN/i.test(a.lang))||(/en-GB/i.test(b.lang)-/en-GB/i.test(a.lang)));return p};
const CFG={you:['m',1.28,1.02],youF:['f',1.14,1.0],sushma:['f',.98,1.02],arjun:['m',1.12,1.08],guard:['m',.72,.92],clerk:['f',1.0,.95],prof:['m',.82,.9],suresh:['m',1.05,1.0],colonel:['m',.55,.85],nss:['m',.8,.95]};
function profile(key,name){let p=profiles.get(key);if(p&&p.vs===vs.length)return p;
 let c=typeof key==='string'&&CFG[key];
 if(!c){const gk=key&&typeof key==='object'&&key.gender,f=gk?gk==='f':((nCad+=1)%2===0||/mrs|ms\.|miss/i.test(name||''));c=[f?'f':'m',f?.95+((nCad*37)%30)/100:.7+((nCad*29)%45)/100,.9+((nCad*13)%25)/100]}
 const pl=pool(c[0]),idx=c[0]==='f'?nF++:nM++;
 p={vs:vs.length,voice:pl.length?pl[idx%pl.length]:null,pitch:c[1],rate:c[2]};profiles.set(key,p);return p}
function stop(){tok++;clearTimeout(tm);if(curA){const a=curA;curA=null;try{a.onended=a.onerror=null;a.pause();a.removeAttribute('src');a.load()}catch(e){}}try{SS&&SS.cancel()}catch(e){}}
function speak(key,name,text,done){stop();const my=tok;let fin=false;
 const end=()=>{if(fin||my!==tok)return;fin=true;clearTimeout(tm);done&&done()};
 const fem=(key&&typeof key==='object'&&key.gender==='f')||key==='youF'||key==='sushma';   // girl cadets: ElevenLabs clips (clips_girl.json) or a female browser voice, never the male clip
 const C=fem?(window.__CLIPS_F&&window.__CLIPS_F[text]):(window.__CLIPS&&window.__CLIPS[text]);if(C&&(typeof C==='string'||C[1])){try{const a=new Audio(typeof C==='string'?C:C[1]);a.volume=window.__VOL==null?1:window.__VOL;curA=a;a.onended=end;a.onerror=end;tm=setTimeout(end,45000);const pr=a.play();if(pr&&pr.catch)pr.catch(()=>{curA=null;clearTimeout(tm);tm=setTimeout(end,Math.max(1500,text.length*70))});return}catch(e){}}
 load();const ok=SS&&typeof SpeechSynthesisUtterance!=='undefined'&&vs.length>0;
 if(!ok){tm=setTimeout(end,Math.max(1200,text.length*58+600));return}
 const p=profile(key,name),teT=Array.isArray(C)&&C[0]?C[0]:(fem&&GTE[text]),tv=teT?vs.find(v=>/^te/i.test(v.lang)):null,u=new SpeechSynthesisUtterance(tv?teT:text);
 if(tv){u.voice=tv;u.lang=tv.lang}else if(p.voice){u.voice=p.voice;u.lang=p.voice.lang}else u.lang='en-IN';
 u.pitch=tv?1.1:Math.min(2,Math.max(.1,p.pitch));u.rate=tv?.88:p.rate;u.volume=1;u.onend=end;u.onerror=end;
 tm=setTimeout(end,text.length*120+4000);
 setTimeout(()=>{if(my!==tok)return;try{SS.resume();SS.speak(u)}catch(e){end()}},50)}
window.__cap=(t,n)=>{const g=window.__CHAR==='girl',fem=(n&&n.gender==='f')||(g&&(!n||n.id==='arjun')),f=fem&&window.__CLIPS_F&&window.__CLIPS_F[t],c=Array.isArray(f)?f:(window.__CLIPS&&window.__CLIPS[t]);return c&&c[0]?c[0]+'<small style="display:block;opacity:.78;font-size:.82em;margin-top:3px;font-weight:500">'+t+'</small>':t};

/* one-line subtitle text: English by default, the Telugu caption (when the line has one) if the player chose Telugu in the pause settings */
window.__sub=(t,n)=>{if(window.__SUBLANG!=='te')return t;const g=window.__CHAR==='girl',fem=(n&&n.gender==='f')||(g&&(!n||n.id==='arjun')),f=fem&&window.__CLIPS_F&&window.__CLIPS_F[t],c=Array.isArray(f)?f:(window.__CLIPS&&window.__CLIPS[t]);return c&&c[0]?c[0]:t};

/* Jai Hind chorus: every cadet shouts the clip in his / her own voice (stable per cadet: pitch + speed), slightly staggered, quieter when far. Girls use clips_girl.json if present, otherwise the clip pitched up. Independent of speak(), so it never cuts dialogue. */
let nCh=0;
function chorus(list,pl){
 const real=!!(window.__CLIPS_F&&window.__CLIPS_F['Jai Hind!']);
 list.forEach(n=>{
  const f=n.gender==='f',c=(f&&real?window.__CLIPS_F['Jai Hind!']:(window.__CLIPS&&window.__CLIPS['Jai Hind!'])),src=c?(typeof c==='string'?c:c[1]):null;if(!src)return;
  if(n.vi==null)n.vi=nCh++;const k=n.vi;
  const rate=f?(real?.96+((k*29)%13)/100:1.26+((k*31)%15)/100):.88+((k*37)%21)/100;
  const d=Math.hypot(n.x-pl.x,n.z-pl.z),vol=Math.max(.25,Math.min(1,1.15-d/20))*.6;
  setTimeout(()=>{try{const a=new Audio(src);a.preservesPitch=false;a.mozPreservesPitch=false;a.webkitPreservesPitch=false;a.playbackRate=rate;a.volume=vol*(window.__VOL==null?1:window.__VOL);const p=a.play();if(p&&p.catch)p.catch(()=>{})}catch(e){}},850+Math.random()*450)})}
const pauseV=()=>{try{if(curA&&!curA.paused){curA._p=1;curA.pause()}}catch(e){}try{SS&&SS.speaking&&SS.pause()}catch(e){}};
const resumeV=()=>{try{if(curA&&curA._p){curA._p=0;curA.play()}}catch(e){}try{SS&&SS.paused&&SS.resume()}catch(e){}};
addEventListener('anits-pause',pauseV);addEventListener('anits-resume',resumeV);
window.__voice={chorus,speak,stop,say:(n,t)=>speak(n.id==='stu'||n.id==='cadet'?n:(n.id==='arjun'&&window.__CHAR==='girl'?'sushma':n.id),n.name,t)};
})();
