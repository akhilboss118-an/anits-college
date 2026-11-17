/* Level list for the menu + mission steps for Day 2-7 (Day 1 = the original first-day story inside game.js).
   Step fields: t text, at [x,z] (+rad), npc, salute, lines {npcId:[...]}, ok(), done(), chk(), mini {kind,...}, say. */
window.__LVINFO=[
 {n:'Explore the College',th:'lv_gate',done:'You toured every corner of ANITS, met the staff, found a friend and saluted the NCC company. Jai Hind!'},
 {n:'Pay the Fees',th:'lv_road',done:'Fees paid, receipt stamped. You are officially an ANITS student!'},
 {n:'Find Your Classroom',th:'lv_campus',done:'After a wrong lab and a lost corridor, you found your classroom!'},
 {n:'Library Card',th:'lv_library',done:'Quiz passed. Your library card is in your pocket!'},
 {n:'Basketball Event',th:'lv_basketball',done:'Nothing but net! The court has a new star.'},
 {n:'NCC Parade',th:'lv_parade',done:'Inspected, drilled, ran 1.4 km, flag hoisted and saluted. Your NCC certificate is in your bag. Jai Hind!'},
 {n:'Lab Manual Run',th:'lv_lab',done:'All signatures collected. The lab is open for you!'}];
window.__LV=function(c){const W=c.W2,P=c.pay,FEE=250;
 const R={
 2:[
  {t:'Go to Laksmi (Admin) in the Admin Block and ask for your fee slip.',npc:'clerk',lines:{clerk:["Fees? Yes, here is your fee slip. The total is Rs. 250."]}},
  {t:'Withdraw at least \u20B9250 from the bank ATM (press E near the bank).',chk:()=>c.wallet()>=FEE},
  {t:'Pay the fees to Laksmi (Admin) at the Admin Block.',npc:'clerk',ok:()=>c.wallet()>=FEE,cine:'pay',fee:FEE,done:()=>P(FEE),lines:{clerk:["Thank you! Rs. 250 received. Here is your receipt."]}},
  {t:'Show the fee receipt to Prof. Rao at the CSE Block.',npc:'prof',lines:{prof:["Ah, the fee receipt. Very good, you are officially a student!"]}}],
 3:[
  {t:'Ask Prof. Rao where your classroom is.',npc:'prof',lines:{prof:["Your classroom? Room 204, second floor of the west wing."]}},
  {t:'Go to the west wing and find Room 204 on the floor with four rooms.',at:W(80,175),rad:6,mini:{kind:'floor',title:'FIND ROOM 204'}},
  {t:'Meet your friend at the Canteen.',npc:'arjun',lines:{arjun:["Hey! Over here! I saved you a seat in the right room!"]}}],
 4:[
  {t:'Get the library form signed by Laksmi (Admin Officer) at the Admin Block.',npc:'clerk',cine:'libsign',fee:'admin',lines:{clerk:["A library card? Fill the application form and I will sign as Admin Officer."]}},
  {t:'Get the HOD signature from Prof. Rao at the CSE Block.',npc:'prof',cine:'libsign',fee:'hod',lines:{prof:["Library card form? Let me see... good. I will sign as HOD of CSE."]}},
  {t:'Get the lab assistant signature from Suresh at the IT Block.',npc:'suresh',cine:'libsign',fee:'lab',lines:{suresh:["Ah, the library form. Here is the lab assistant's signature."]}},
  {t:'Walk to the Civil Block and enter the library.',at:W(262,150),rad:9,say:'You: The Civil Block library... let me submit all three signatures.'},
  {t:'Submit all three signatures at the library to collect your library card.',at:W(262,150),rad:9,cine:'libsign',fee:'submit'}],
 5:[
  {t:'Go to the Basketball Court for the freshers\' match.',at:W(290,275),rad:6,say:'Basketball players: Shoot your shots, fresher!'},
  {t:'Basketball shootout: score 3 of 5. Drag to aim the ring at the hoop, then press SHOOT.',mini:{kind:'shoot',title:'BASKETBALL SHOOTOUT',shots:5,need:3}},
  {t:'Celebrate with your friend at the Canteen.',npc:'arjun',lines:{arjun:["Super shots! You are a proper player!"]}}],
 6:[
  {t:'Report to Colonel Singh at the Open Auditorium grounds.',npc:'colonel',lines:{colonel:["Cadet, today is the NCC parade. Stand straight and report properly!"]}},
  {t:'Uniform check: tap each fault on the cadet and fix it, then stand at attention.',npc:'colonel',cine:'parade',fee:'uniform',lines:{colonel:["Report for uniform inspection. A cadet is judged from cap to boots."]}},
  {t:'Fall in with the company and answer the Colonel\'s drill commands.',at:W(214,396),rad:16,cine:'parade',fee:'drill'},
  {t:'NCC ground run: run 1.4 km in 2 runs within 2:00. Hold SPRINT for speed while the cadets cheer your name.',at:W(214,396),rad:16,cine:'parade',fee:'run'},
  {t:'Walk to the NCC flagpole, hoist the flag at the anthem\'s pace and hold your salute.',at:W(235,377),rad:9,cine:'parade',fee:'flag'},
  {t:'Return to Colonel Singh for the debrief and collect your certificate.',npc:'colonel',cine:'parade',fee:'debrief',lines:{colonel:["Parade complete, cadet. Come, let me tell you how you did."]}}],
 7:[
  {t:'Get the lab manual form from Suresh at the IT Block.',npc:'suresh',cine:'lab',fee:'issue',lines:{suresh:["Lab manual run! Here is your form."]}},
  {t:'Get Prof. Rao\'s signature at the CSE Block.',npc:'prof',cine:'lab',fee:'prof',lines:{prof:["Signature done."]}},
  {t:'Get the stamp from Laksmi (Admin) at the Admin Block.',npc:'clerk',cine:'lab',fee:'stamp',lines:{clerk:["Stamp done."]}},
  {t:'Return the stamped form to Suresh.',npc:'suresh',cine:'lab',fee:'return',lines:{suresh:["Perfect! All signatures are complete. Lab entry unlocked!"]}}]
 };
 const ID=[
  {t:'Show your ID card to Security Guard Bajirao at the main gate (press F near him).',npc:'guard',idcheck:true,lines:{guard:["Stop! Students need to show their ID card at the gate.","Press F to show your ID card."]}},
  {t:'Walk through the main gate and into the college.',at:W(122,396),rad:7}];
 Object.keys(R).forEach(k=>R[k]=ID.concat(R[k]));
 return R};
