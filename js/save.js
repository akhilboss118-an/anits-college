/* Local save layer: wallet, bank balance, energy, mission progress and position, kept in localStorage (memory fallback). */
(function(){
  var KEY='anits-save:v2:'+(window.__LVL||1),mem=null,timer=0,getSnap=null;
  var store={
    get:function(){try{return window.localStorage.getItem(KEY)}catch(e){return mem}},
    set:function(v){mem=v;try{window.localStorage.setItem(KEY,v)}catch(e){}},
    del:function(){mem=null;try{window.localStorage.removeItem(KEY)}catch(e){}}
  };
  var fin=function(n){return typeof n==='number'&&isFinite(n)};
  function valid(d){
    return d&&d.v===1&&fin(d.wallet)&&d.wallet>=0&&fin(d.bankBal)&&d.bankBal>=0&&fin(d.energy)&&d.energy>=0&&d.energy<=100&&
      Number.isInteger(d.si)&&d.si>=0&&d.si<=20&&fin(d.x)&&fin(d.z)&&fin(d.yaw);
  }
  function save(){
    if(!getSnap)return;
    try{var d=getSnap();d.v=1;d.t=Date.now();if(valid(d))store.set(JSON.stringify(d))}catch(e){}
  }
  var api={
    has:function(){try{return valid(JSON.parse(store.get()))}catch(e){return false}},
    load:function(){
      if(/[?&]reset=1/.test(location.search)){store.del();return null}
      try{var d=JSON.parse(store.get());if(valid(d))return d}catch(e){}
      store.del();return null;
    },
    clear:function(){store.del()},
    halt:function(){getSnap=null;clearInterval(timer);store.del()},
    start:function(fn){
      getSnap=fn;clearInterval(timer);timer=setInterval(save,4000);
      addEventListener('beforeunload',save);addEventListener('pagehide',save);
      document.addEventListener('visibilitychange',function(){if(document.hidden)save()});
    },
    saveNow:save
  };
  window.OfflineSave=api;
})();
