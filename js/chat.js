/* Talk back to anyone (Bajirao, Laksmi, Prof. Rao, Suresh, Colonel, cadets, students, your friend).
   After an NPC finishes its scripted lines, a reply panel opens: quick-reply chips + a box to type your own question.
   NPCs answer in character (offline, rule based) and sometimes ask YOU a question back. Bye / Esc / E closes it and the
   normal mission flow continues (see interact() in js/game.js, which calls window.__chat.start). */
(()=>{
const $=id=>document.getElementById(id),girl=window.__CHAR==='girl';
const pick=a=>a[Math.floor(Math.random()*a.length)];
const pname=()=>((window.__PROFILE&&window.__PROFILE.name)||(girl?'Amy':'Mike')).trim().split(/\s+/)[0]||(girl?'Amy':'Mike');
const FR=girl?'Sushma':'Arjun';

/* ---------- who is this NPC ---------- */
const keyOf=n=>n.id==='stu'?(/basketball/i.test(n.name)?'hoop':/remy/i.test(n.name)?'remy':'stu'):n.id;

/* ---------- campus facts (kept consistent with the game) ---------- */
const PLACES=[
 {k:'ramu',re:/ramu|guard|security/,self:'guard',t:'Bajirao, the security guard, stands beside the main gate. He checks every student\'s ID card in the morning.'},
 {k:'laksmi',re:/laksmi|lakshmi|clerk/,self:'clerk',t:'Laksmi works at the office in the Admin Block, the big white building with the ANITS sign on its roof.'},
 {k:'rao',re:/\brao\b|prof(essor)?|hod/,self:'prof',t:'Prof. Rao, the HOD, sits in the CSE Block. The labs are on the upper floor.'},
 {k:'suresh',re:/suresh|lab assistant/,self:'suresh',t:'Suresh, the lab assistant, is at the IT Block. He gives out lab manuals and library cards.'},
 {k:'colonel',re:/colonel|singh/,self:'colonel',t:'Colonel Singh is on the open ground in front of the Open Auditorium steps, with his NCC company.'},
 {k:'friend',re:/arjun|sushma|best friend|\bfriend\b/,self:'arjun',t:'Your friend '+FR+' usually waits at the canteen, next to the Civil Block.'},
 {k:'admin',re:/admin|office|fee ?slip|documents?/,t:'The Admin Block is the big white building up the main road with the ANITS sign on its roof. Laksmi is at the office.'},
 {k:'cse',re:/\bcse\b|computer science|hod office/,t:'The CSE Block is where Prof. Rao sits. Walk down the main road, and the labs are on the upper floor.'},
 {k:'it',re:/\bit block\b|it department|stage|fest/,t:'The IT Block is where Suresh gives out lab manuals. The fest stage is on the road near it.'},
 {k:'canteen',re:/canteen|cafeteria|cafe|mess/,t:'The canteen is next to the Civil Block. It has the best chai on campus, and samosas too.'},
 {k:'library',re:/librar/,t:'The library is in the west wing, near the classrooms.'},
 {k:'bank',re:/\batm\b|bank|cash|withdraw/,t:'There is a bank with an ATM on campus. Walk up to it and press E to withdraw cash.'},
 {k:'aud',re:/auditorium|ncc ground|parade|drill/,t:'The Open Auditorium ground is where the NCC company stands in formation, in front of the auditorium steps.'},
 {k:'court',re:/basketball|court|hoop/,t:'The basketball court is where the freshers\' matches happen. Students play there after class.'},
 {k:'gate',re:/main gate|\bgate\b|entrance|exit/,t:'The main gate is where Bajirao stands. The gate stays shut until you show your ID card.'},
 {k:'class',re:/class ?room|room ?204|west wing|lecture hall/,t:'The classrooms are in the west wing. Room 204 is at the north end of the corridor.'},
 {k:'vend',re:/vending|cold drink|soda|energy (drink|machine)/,t:'There are cold-drink vending machines at both canteens: one here, one near the main gate. Press E next to one to buy.'},
 {k:'temple',re:/temple|shikara|mandir/,t:'There is an old 12th-century Bhumija Shikara temple inside the campus. It is well worth a visit.'},
 {k:'power',re:/power (supply )?room|transformer|substation|generator/,t:'The Power Supply Room is the old NCC ground, with transformers and a high-voltage gantry. Stay outside the fence, it is dangerous!'},
 {k:'park',re:/parking|bus|bike/,t:'Parking fills up by 9 AM, so come early. The college buses stop near the main gate.'}
];
const missionText=()=>{try{const g=window.__g,s=g&&g.story&&g.story[g.si];return s?s.t:null}catch(e){return null}};

/* ---------- personalities ---------- */
const sir=girl?'young lady':'young man';
const slang=girl?'yaar':'bro';
const P={
 guard:{
  intro:'I am Bajirao, the security guard here at the main gate. I keep ANITS safe, and I check every student\'s ID card.',
  how:['I am fine, beta, thank you for asking! Standing at the gate all day, but I like it.','Doing well! Nobody asks the guard how he is, so thank you.'],
  greet:['Good morning, '+pname()+'! Welcome to ANITS.','Namaste, '+pname()+'! All good today?'],
  bye:['Okay, beta. Go safely, and keep your ID card with you!','Jai Hind! Come and talk to me anytime.'],
  thanks:['You are welcome, beta!','Most welcome. Stay safe!'],
  id:'Keep your ID card with you every day. Open your bag with the B key and press SHOW when I ask. If you lose it, come to me and I will issue a temporary one.',
  job:'I stand here from early morning. Cars, buses, visitors, everyone comes past me. Nobody gets in without a reason!',
  joke:['What do you call a guard who falls asleep on duty? A security NAP! But I never sleep, ha ha!'],
  fall:['Hmm, I am only a guard, beta. Ask me about the gate, the ID card or where the buildings are.','That I do not know. But ask me about the campus, I know every corner!'],
  tag:['Stay safe!','Keep your ID with you!'],
  Q:[{q:'Do you have your ID card with you?',y:'Very good. Always keep it handy.',n:'Then come to me when you need one. A temporary card is ready, but do not lose it!'},
     {q:'Did you have breakfast?',y:'Good. Studying on an empty stomach is hard.',n:'Arrey, go to the canteen first, beta!'}],
  ask:['Who are you?','Can I show my ID card?','Where is the Admin Block?','Tell me a joke']},
 clerk:{
  intro:'I am Laksmi, the clerk at the Admin Block. Documents, fees and receipts all pass through my desk.',
  how:['I am well, thank you! A little busy with all the new admissions.','Fine, thanks for asking. Fresher season keeps me busy!'],
  greet:['Good morning, '+pname()+'! How can I help you?','Hello, '+pname()+'. Welcome to the Admin Block.'],
  bye:['Take care, '+pname()+'. Come back if you need anything.','All the best! My desk is always open.'],
  thanks:['You are welcome, dear.','Happy to help!'],
  fees:'Fees are paid at my counter in the Admin Block. Get cash from the bank ATM first, and keep the fee receipt. You will need to show it to Prof. Rao.',
  job:'I handle documents, fee slips, stamps and receipts for all students here.',
  joke:['Why did the file go to the office? It wanted to be a document!'],
  fall:['Sorry, that is outside my department. I can help with documents, fees and stamps.','I am not sure about that. For office work, I am your person!'],
  tag:['Keep your receipts safe.'],
  Q:[{q:'Have you kept all your documents safely?',y:'Very good. A lost document means a lot of running around.',n:'Please keep them in one folder. It saves a lot of trouble later.'}],
  ask:['Who are you?','How do I pay the fees?','Where is the bank ATM?','What should I do next?']},
 prof:{
  intro:'I am Prof. Rao, Head of the CSE department. I teach and guide the first-year students here.',
  how:['I am very well, thank you! Teaching fresh minds keeps me young.','Good, good! Exams are near, so the department is busy.'],
  greet:['Good morning, '+pname()+'! Welcome to the CSE department.','Ah, '+pname()+'! Come, come.'],
  bye:['Good luck, '+pname()+'. Study well!','Go on, and do not be late for class!'],
  thanks:['You are welcome. Learn well!','My pleasure, '+pname()+'.'],
  exam:'Consistent practice beats last-night cramming. Attend class, do the lab work, and ask doubts early. That is my formula!',
  job:'I teach, I run the CSE department, and I try to keep everyone out of trouble!',
  joke:['A programmer\'s wife says, "Buy a loaf of bread, and if they have eggs, buy a dozen." He comes home with 12 loaves. "They had eggs!"'],
  fall:['Interesting question, but I would need more time to answer it. Ask me about studies or the department.','Hmm. I am better at computer science than at that, I am afraid.'],
  tag:['Study well!'],
  Q:[{q:'Do you enjoy programming?',y:'Good. Keep that curiosity alive!',n:'It grows on you. Start small and practise daily.'},
     {q:'Are you ready for your first classes?',y:'Excellent attitude!',n:'Do not worry. Everyone starts nervous. We go step by step.'}],
  ask:['Who are you?','How should I study?','Where is my classroom?','What should I do next?']},
 suresh:{
  intro:'I am Suresh, the lab assistant at the IT Block. I look after the computers, lab manuals and library cards.',
  how:['I am good, thanks! Systems are running, so no complaints.','Fine, fine! Just fixing a keyboard or two.'],
  greet:['Hello, '+pname()+'! Welcome to the IT Block.','Hey '+pname()+'! Need something from the lab?'],
  bye:['Okay, see you in the lab. Do not touch the cables!','Bye, '+pname()+'. Take care of your manual!'],
  thanks:['No problem!','Anytime, '+pname()+'.'],
  lab:'The lab manual has all the experiments for this year. Keep it clean, get the faculty sign on each experiment, and do not unplug anything without asking me!',
  job:'I keep the lab machines running, give out lab manuals and library cards, and help with the experiments.',
  joke:['Why did the computer get cold? It left its Windows open!'],
  fall:['Hmm, no idea. Ask me about the lab, computers or manuals.','I am a lab man, not a quiz master! Try a lab question.'],
  tag:['Do not touch the cables!'],
  Q:[{q:'Have you used a computer lab before?',y:'Great, then you will settle in quickly.',n:'No problem. I will show you the basics when you come.'}],
  ask:['Who are you?','What is in the lab manual?','Where is the library?','Tell me a joke']},
 colonel:{
  intro:'Colonel Singh, NCC. I train our cadets in discipline, drill and service to the nation.',
  how:['Fit and fine, thank you! A soldier is always ready.','Excellent, '+pname()+'! Early morning parade does wonders.'],
  greet:['Jai Hind, '+pname()+'!','Good morning, '+pname()+'. Stand tall!'],
  bye:['Jai Hind! Dismissed.','Carry on, '+pname()+'. Jai Hind!'],
  thanks:['Not at all. Jai Hind!','Duty, '+pname()+'. Jai Hind!'],
  ncc:'The NCC teaches discipline, teamwork and leadership. We drill every morning on the open ground in front of the auditorium. Salute the company with G when you pass, and the cadets will answer with a Jai Hind!',
  job:'I command the NCC company. My cadets learn drill, discipline and how to serve the nation.',
  joke:['A soldier never jokes on parade. But after parade? Why did the cadet bring a ladder? To reach the high standards!'],
  fall:['That is not for the parade ground, '+pname()+'. Ask me about the NCC or discipline.','I am a man of few words, and I do not know that one.'],
  tag:['Jai Hind!'],
  Q:[{q:'Are you thinking of joining the NCC?',y:'Splendid! Discipline will serve you well.',n:'No pressure. But always salute the flag with pride.'}],
  ask:['Who are you?','Tell me about the NCC.','Where is the Open Auditorium?','Tell me a joke']},
 cadet:{
  intro:'I am an NCC cadet. We stand here in formation every morning, and Colonel Singh trains us.',
  how:['Standing straight, so I am fine! My legs are tired though.','Good, thanks! Do not make me laugh, Sir is watching!'],
  greet:['Jai Hind, '+pname()+'! Shh, I should not talk on parade.','Jai Hind!'],
  bye:['Jai Hind! Now go before the Colonel looks.','Bye! Salute us with G, we like it.'],
  thanks:['Anytime! Jai Hind!','No problem, quick, before Sir sees!'],
  ncc:'We drill every day. Standing still for an hour is harder than it looks. Press G near us and we all shout Jai Hind!',
  job:'We are NCC cadets: drill, discipline and a lot of standing!',
  joke:['Why did the cadet stand so still? He was auditioning to be a statue!'],
  fall:['I cannot say, I am on parade! Try asking about the NCC.','No idea. We only get to think during the break!'],
  tag:['Jai Hind!'],
  Q:[{q:'Have you ever marched in a parade?',y:'Then you know how tiring it is!',n:'It looks easy, but it really is not!'}],
  ask:['Who are you?','Tell me about the NCC.','Where is Colonel Singh?','Tell me a joke']},
 arjun:{
  intro:'Come on, it is me, '+FR+', your best friend! Same hostel gossip, same canteen table.',
  how:['I am great, '+slang+'! Better now that you are here.','All good! Just hungry, as always. Chai?'],
  greet:['Hey '+pname()+'! Finally!','Arre '+pname()+'! What took you so long?'],
  bye:['Okay '+slang+', see you in a bit!','Bye '+pname()+'! Do not get lost on campus!'],
  thanks:['Arre, no thanks needed '+slang+'!','Anytime! That is what friends are for.'],
  food:'Canteen chai plus a samosa is the best combination on campus. And there are cold-drink machines near the canteens too. Come, I am buying!',
  job:'My job? Eat, study a little, and annoy you!',
  joke:['Why do programmers prefer dark mode? Because light attracts bugs!'],
  fall:['Hmm, no idea '+slang+'! Ask me something else, like where to go or what to eat.','Ha ha, I did not get that. Say it differently?'],
  tag:[slang+'!'],
  Q:[{q:'Did you eat anything yet?',y:'Good! Then we can skip the queue.',n:'Then come to the canteen. Chai and samosa on me!'}],
  ask:['How are you?','What should I do next?','Tell me a joke','Where is the canteen?']},
 stu:{
  intro:'I am just a student here. Come, I will show you around sometime!',
  how:['I am good! Just trying to get to class on time.','Fine, '+slang+'! Exams are near though.'],
  greet:['Hey '+pname()+'! New here?','Hi! First day?'],
  bye:['See you around!','Bye '+slang+', good luck!'],
  thanks:['No problem!','Anytime!'],
  food:'The canteen chai is the best thing on campus. Go there, you will thank me!',
  job:'I study here. Notes, assignments and chai, that is my life!',
  joke:['Why was the math book sad? Too many problems!'],
  fall:['No idea, '+slang+'! Ask a senior, or Bajirao at the gate.','Hmm, I am a fresher too. Try asking the staff.'],
  tag:[''],
  Q:[{q:'Have you tried the canteen chai yet?',y:'Right? Best on campus!',n:'You must! Go today.'}],
  ask:['Who are you?','Where is the canteen?','What should I do next?','Tell me a joke']},
 hoop:{
  intro:'I play for the college basketball team. We practise here whenever we get free time.',
  how:['I am great! Just made three shots in a row!','Good! Warm-up done, ready for a match.'],
  greet:['Hey '+pname()+'! Want to shoot a few?','Yo '+pname()+'! Join us!'],
  bye:['Later! Come play after class!','Bye '+slang+', see you on court!'],
  thanks:['No problem! Come play!','Anytime!'],
  food:'After a match, canteen samosas taste even better!',
  job:'I play ball, and I attend class sometimes!',
  joke:['Why do basketball players love doughnuts? They love to dunk!'],
  fall:['Not sure, I only know basketball! Ask about the game.','Hmm, no clue. Want to shoot some hoops instead?'],
  tag:[''],
  Q:[{q:'Do you play basketball?',y:'Nice! Join our team then.',n:'Come anyway, I will teach you a few shots.'}],
  ask:['Who are you?','Where is the basketball court?','Tell me a joke','What should I do next?']}
};
P.remy=Object.assign({},P.stu,{intro:'I am Remy, a student here. I walk around campus all day, so I know all the shortcuts!'});

/* ---------- intents ---------- */
const has=(s,re)=>re.test(s);
const FACT={
 time:'It is about half past ten in the morning.',
 weather:'It is a bright, sunny late morning, a perfect day for the first day!',
 college:'ANITS is a lively place: labs, a canteen, NCC, basketball, fests and a lot of friendly faces. You will like it here!',
 exam:'Study a little every day, attend class and ask your doubts early. Last-night cramming rarely works!',
 ncc:'The NCC company drills on the open ground in front of the auditorium. Press G near them to salute.',
 fees:'Fees are paid to Laksmi at the Admin Block. Withdraw cash from the bank ATM first.',
 id:'The ID card is checked by Bajirao at the main gate. Open your bag with the B key and press SHOW.',
 lab:'The lab manuals are at the IT Block, with Suresh.',
 food:'The canteen next to the Civil Block has the best chai and samosas. Cold drinks are in the vending machines.',
 fest:'The fest stage is on the road near the IT Block. There will be a dance battle!',
 sport:'Basketball freshers\' matches happen at the court. Join in, it is fun!',
 sorry:'No problem at all!',
 praise:'Thank you, that is kind of you!',
 rude:'Please speak politely, '+pname()+'. Let us keep it friendly.'
};
const TELUGU=/bagunn|ela unn|em chestunn|ela vunn|enti ra|emi ra|sare|avunu|ledu/;

function detect(raw){
 const s=raw.toLowerCase().replace(/[^a-z0-9\u0c00-\u0c7f\s']/g,' ').replace(/\s+/g,' ').trim(),w=s.split(' ').filter(Boolean).length;
 if(!s)return{i:'empty'};
 if(has(s,/\b(bye|goodbye|good bye|see you|see ya|take care|gotta go|got to go|i have to go|i must go|leaving now|tata|cya)\b/))return{i:'bye'};
 if(has(s,/\b(stupid|idiot|shut up|useless|fool|dumb|hate you)\b/))return{i:'rude'};
 if(has(s,/\b(thank|thanks|thx|tq|thankyou|appreciate)\b/))return{i:'thanks'};
 if(has(s,/\b(sorry|excuse me|pardon|my bad)\b/))return{i:'sorry'};
 if(has(s,/(what('| i)?s|do you know|tell me) my name|who am i/))return{i:'myname'};
 if(has(s,/(how are you|how r u|how are u|how is it going|how's it going|how do you do|what's up|whats up|wassup|how have you been)/)||(TELUGU.test(s)&&/ela|bagunn/.test(s)))return{i:'how'};
 if(has(s,/^(hi+|hello+|hey+|yo|namaste|namaskaram|hola|sup|hai|good (morning|afternoon|evening))\b/)&&w<=4)return{i:'greet'};
 if(has(s,/who are you|what('| i)?s your name|your name|introduce yourself|about yourself|tell me about you|who r u/))return{i:'who'};
 if(has(s,/what (do|did) you do|your (job|work|duty|role)|what is your job|why are you here/))return{i:'job'};
 if(has(s,/joke|make me laugh|something funny|funny/))return{i:'joke'};
 if(has(s,/what (should|do|can) i do|what now|what next|what('| i)?s next|next (task|mission|step)|my (task|mission)|i am lost|i'm lost|i am stuck|i'm stuck|where (should|do) i go( next)?$|\bhelp\b|guide me/))return{i:'mission'};
 if(has(s,/what('| i)?s the time|what time|time now|time is it/))return{i:'time'};
 if(has(s,/weather|sunny|rain|\bhot\b|\bcold\b(?! drink)|temperature/))return{i:'weather'};
 const wh=has(s,/\bwhere\b|\bwho is\b|\bwho's\b|how (do|can|to|should) i (get|go|reach|find)|\bway to\b|direction|\bfind\b|locate|take me|show me|which way/);
 let place=null;for(const p of PLACES){if(p.re.test(s)){place=p;break}}
 if(!place&&wh&&has(s,/eat|food|chai|samosa|hungry|drink|tea\b|coffee|snack/))place=PLACES.find(x=>x.k==='canteen');
 if(place&&(wh||w<=3))return{i:'place',p:place};
 if(wh)return{i:'place',p:null};
 if(has(s,/\bid\b|identity card|id card/))return{i:'id'};
 if(has(s,/\bfees?\b|receipt|payment|\bpay\b|money/))return{i:'fees'};
 if(has(s,/exam|study|studies|syllabus|marks|result|subject|homework|assignment|attendance|how (should|do) i (study|prepare)/))return{i:'exam'};
 if(has(s,/\bncc\b|salute|jai hind|cadet|soldier|army|colonel/))return{i:'ncc'};
 if(has(s,/lab manual|\blab\b|computer|experiment|library card/))return{i:'lab'};
 if(has(s,/food|hungry|hunger|chai|tea\b|coffee|samosa|eat|lunch|breakfast|snack|drink|thirsty/))return{i:'food'};
 if(has(s,/\bfest\b|dance|event|party|stage|concert/))return{i:'fest'};
 if(has(s,/basketball|cricket|football|sports?|game|play\b/))return{i:'sport'};
 if(has(s,/college|anits|campus|how is it here|like it here|is it good|freshers?/))return{i:'college'};
 if(has(s,/\b(nice|great|cool|awesome|amazing|good job|well done|love it|brilliant|wonderful)\b/))return{i:'praise'};
 if(has(s,/^(yes|yeah|yep|yup|yea|sure|of course|ya|haan|avunu|ok|okay|alright|fine|definitely|absolutely|i do|i have|i did|correct|right)\b/))return{i:'yes'};
 if(has(s,/^(no|nope|nah|not really|never|ledu|kadu|i don't|i do not|i haven't|i have not|not yet)\b/))return{i:'no'};
 if(has(s,/^(maybe|not sure|i don't know|i do not know|dunno|hmm+)\b/))return{i:'maybe'};
 return{i:'fall'};
}

function respond(key,raw,ctx){
 const p=P[key]||P.stu,d=detect(raw);let t='',end=false,q=null;
 const keep=a=>{const f=Array.isArray(a)?a.filter(x=>x!==ctx.lastReply):[a];return pick(f.length?f:[].concat(a))};
 switch(d.i){
 case 'empty':t=keep(p.fall);break;
 case 'bye':t=keep(p.bye);end=true;break;
 case 'thanks':t=keep(p.thanks);break;
 case 'sorry':t=FACT.sorry;break;
 case 'rude':t=FACT.rude;break;
 case 'praise':t=FACT.praise;break;
 case 'myname':t='Of course I know you. You are '+pname()+'!';break;
 case 'how':t=TELUGU.test(raw.toLowerCase())?'Bagunnanu! Nuvvu ela unnav?':keep(p.how);break;
 case 'greet':t=keep(p.greet);break;
 case 'who':t=((key==='stu'||key==='hoop')&&ctx.nm?'I am '+ctx.nm+'. ':'')+p.intro;break;
 case 'job':t=p.job||p.intro;break;
 case 'joke':t=keep(p.joke);break;
 case 'mission':{t='Your tasks are shown in the task list on your screen.';break}
 case 'time':t=FACT.time;break;
 case 'weather':t=FACT.weather;break;
 case 'place':
  if(!d.p)t='Which place do you mean? I can guide you to the Admin Block, CSE Block, IT Block, canteen, library, bank ATM, auditorium ground or basketball court.';
  else if(d.p.self&&P[d.p.self]&&d.p.self===key)t=key==='arjun'?'That is me, '+FR+'! I am right here.':'That is me! I am standing right here.';
  else t=d.p.t;
  break;
 case 'id':t=p.id||FACT.id;break;
 case 'fees':t=p.fees||FACT.fees;break;
 case 'exam':t=p.exam||FACT.exam;break;
 case 'ncc':t=p.ncc||FACT.ncc;break;
 case 'lab':t=p.lab||FACT.lab;break;
 case 'food':t=p.food||FACT.food;break;
 case 'fest':t=FACT.fest;break;
 case 'sport':t=FACT.sport;break;
 case 'college':t=FACT.college;break;
 case 'yes':case 'no':case 'maybe':
  if(ctx.pendingQ){t=d.i==='yes'?ctx.pendingQ.y:d.i==='no'?ctx.pendingQ.n:'No worries, you will figure it out!'}
  else t=d.i==='yes'?pick(['Good!','Great, glad to hear it!','Nice!']):d.i==='no'?pick(['Oh, okay. No problem!','Alright, that is fine.']):'That is alright. Take your time!';
  ctx.pendingQ=null;break;
 default:t=keep(p.fall);
 }
 /* flavour + a question back */
 if(!end&&d.i!=='fall'&&d.i!=='empty'&&d.i!=='yes'&&d.i!=='no'&&d.i!=='maybe'&&Math.random()<.3&&p.tag&&p.tag.length){const g=pick(p.tag);if(g)t+=' '+g}
 ctx.pendingQ=null;
 if(!end&&d.i!=='yes'&&d.i!=='no'&&d.i!=='maybe'&&Math.random()<.4&&p.Q&&p.Q.length&&!/\?$/.test(t)&&(d.i!=='fall'||Math.random()<.5)){const unused=p.Q.filter(x=>!ctx.askedQ.includes(x.q));if(unused.length){q=pick(unused);ctx.askedQ.push(q.q);t+=' '+q.q;ctx.pendingQ=q}}
 return{text:t,end:end,intent:d.i};
}

/* ---------- AUTO TALK (no reply chips, nothing to pick) ----------
   After the scripted lines, the NPC speaks by itself about the current situation (your mission, where to go next,
   a bit of its own personality), then the box closes and the mission flow continues. E / Esc / click = skip. */
const seen={};   // per NPC: lines already said this session, so a second visit says something new
const fresh=(key,arr)=>{const u=seen[key]||(seen[key]=new Set());let c=arr.filter(x=>x&&!u.has(x));if(!c.length){u.clear();c=arr.filter(Boolean)}const t=pick(c);u.add(t);return t};

function situationLines(n,key,lastLine){
 const p=P[key]||P.stu,out=[],m=missionText(),ns=(n.name||'').replace(/\s*\(.*$/,'').replace(/^(Student|Basketball Player)$/,'');
 /* 2) something in the NPC's own voice */
 const own=[];
 if(ns&&(key==='stu'||key==='hoop'))own.push('By the way, I am '+ns+'.');
 ['job','food','ncc','exam','lab','fees','id'].forEach(k=>{if(typeof p[k]==='string')own.push(p[k])});
 if(p.joke&&p.joke.length)own.push(pick(p.joke));
 if(p.how&&p.how.length)own.push(pick(p.how));
 if(own.length)out.push(fresh(key+':own',own));
 /* 3) a short sign-off */
 const tag=(p.tag||[]).filter(Boolean);
 if(tag.length&&Math.random()<.6)out.push(pick(tag));
 return out.filter(t=>t&&t!==lastLine).slice(0,2);
}

/* ---------- UI ---------- */
let active=false,npc=null,onDone=null,el=null,logEl,timer=0,runId=0;
const css=document.createElement('style');
css.textContent=`#chat{position:fixed;z-index:12;bottom:18px;left:50%;transform:translateX(-50%);width:min(620px,calc(100vw - 440px));display:none;color:#fff;font:600 14px/1.35 'Figtree',sans-serif;background:rgba(8,14,26,.74);border:1px solid rgba(255,213,74,.5);border-radius:999px;box-shadow:0 4px 14px rgba(0,0,0,.3);padding:6px 16px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;text-align:center;cursor:pointer}
#chat .ch-n{display:inline;color:#ffd54a;font:800 inherit;font-size:inherit;margin-right:7px}
#chat .ch-b{display:inline}
#chat .ch-f{display:none}
@media(max-width:900px){#chat{width:min(620px,94vw)}}
body.touch #chat{left:calc(var(--sl) + var(--jr) + 14px);right:calc(var(--sr) + var(--jr) + var(--u)*1.3 + 30px);width:auto;transform:none;bottom:calc(var(--sb) - 4px);font-size:13px;padding:5px 12px}`;
document.head.appendChild(css);

function build(){
 el=document.createElement('div');el.id='chat';el.setAttribute('data-testid','chat-panel');
 el.innerHTML='<span class="ch-n"></span><div class="ch-b" data-testid="chat-log"></div><div class="ch-f">E / click: skip</div>';
 document.body.appendChild(el);logEl=el.querySelector('.ch-b');
 el.addEventListener('click',()=>close());
}
const wait=(ms,id)=>new Promise(r=>{timer=window.__after(ms,r)});
const shortName=n=>String(n.name||'').replace(/\s*\(.*$/,'')+':';
async function run(n,lines,id){
 const nm=shortName(n);
 for(const t of lines){
  if(!active||id!==runId)return;
  try{window.__voice&&window.__voice.say(n,t)}catch(e){}
  for(const c of window.__subs.chunks(window.__sub?window.__sub(t,n):t,el,nm)){   // one small line at a time (timer based, never waits on the voice callback)
   if(!active||id!==runId)return;
   logEl.textContent=c;await wait(window.__subs.dur(c),id);
  }
 }
 if(active&&id===runId)close();
}
function close(){
 if(!active)return;active=false;runId++;if(timer&&timer.cancel)timer.cancel();el.style.display='none';
 try{window.__voice&&window.__voice.stop()}catch(e){}
 const cb=onDone;onDone=null;npc=null;if(cb)cb();
}
function start(n,lastLine,done){
 if(active)return true;if(!el)build();
 const key=keyOf(n),lines=situationLines(n,key,lastLine);
 if(!lines.length)return false;   // nothing to add: let the normal flow continue
 active=true;npc=n;onDone=done;const id=++runId;
 const d=$('dlg');if(d)d.style.display='none';
 el.querySelector('.ch-n').textContent=shortName(n);logEl.textContent='';el.style.display='block';
 run(n,lines,id);return true;
}
addEventListener('keydown',e=>{
 if(!active)return;
 if(e.code==='Escape'||e.code==='KeyE'||e.code==='Enter'||e.code==='Space'){e.preventDefault();e.stopImmediatePropagation();close();return}
 if(/^Key[WASDQZ]$|^Arrow|^ShiftLeft$/.test(e.code))e.stopImmediatePropagation();   // the player stays put while the NPC talks
},true);

window.__chat={start,close,respond,detect,P,get active(){return active}};
})();
