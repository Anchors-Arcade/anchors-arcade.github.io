"use strict";
/* Julmust hub - app logic. Needs games.js (GAMES) loaded first, plus the proxy scripts
   (scram/, baremux/, wisp-config.js, register-sw.js, search.js) loaded in index.html. */

const SITE_TITLE = "Julmust - Games, Movies, Music & AI";

/* stable numeric order, used for prev/next navigation */
const NAV = GAMES.slice().sort((a,b)=> a.n-b.n || a.f.localeCompare(b.f,undefined,{numeric:true}));
const byFile = new Map(GAMES.map(g=>[g.f,g]));

/* ============================== STORAGE ============================== */
const store = {
  get(k,d){ try{ const v=localStorage.getItem(k); return v===null?d:JSON.parse(v); }catch(e){ return d; } },
  set(k,v){ try{ localStorage.setItem(k,JSON.stringify(v)); }catch(e){} }
};
let favs   = new Set(store.get("gn_favs", []));
let recent = store.get("gn_recent", []).filter(f=>byFile.has(f));

/* ============================== SETTINGS ============================== */
/* Legacy keys from the old design (gn_theme, gn_anim, gn_minimal) are intentionally never read or written any more;
   they stay in localStorage untouched and do nothing. */
const DEFAULT_WISP = (typeof WISP_URL==="string" && WISP_URL) ? WISP_URL : "wss://anura.pro/wisp/";
const settings={
  cards:   store.get("gn_cards","m"),
  landing: store.get("gn_landing","home"),
  wisp:    store.get("aa_wisp",""),
};
if(!["s","m","l"].includes(settings.cards)) settings.cards="m";
if(!["home","library"].includes(settings.landing)) settings.landing="home";

/* effective wisp server: user override or built-in */
function effWisp(){ const w=(settings.wisp||"").trim(); return w||DEFAULT_WISP; }
let activeWisp=effWisp();

function applySettings(){
  document.body.dataset.cards=settings.cards;
  document.querySelectorAll("#sizeSeg button").forEach(b=>b.setAttribute("aria-pressed", b.dataset.size===settings.cards?"true":"false"));
}

/* ============================== STATE ============================== */
let sort = store.get("gn_sort", "new");
let favsOnly = false;
let query = "";
if(!["new","old","az","za","rnd"].includes(sort)) sort = "new";

const $ = id => document.getElementById(id);
const esc=s=>String(s).replace(/[&<>"']/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
const grid=$("grid"), searchBox=$("search"), frame=$("frame");

/* ============================== CARD FACTORY ============================== */
const io = new IntersectionObserver(es=>{
  for(const e of es) if(e.isIntersecting){ e.target.classList.add("in"); io.unobserve(e.target); }
},{rootMargin:"200px"});

const ICON_PLAY='<svg class="ico fill" aria-hidden="true"><use href="#i-play"/></svg>';
const ICON_HEART='<svg class="ico" aria-hidden="true"><use href="#i-heart"/></svg>';

function gameLabel(g){ return g.o ? g.t : (g.t ? g.t : "#"+g.n); }
function gameSub(g){ return g.o ? "Home-made" : (g.t ? "#"+g.n+(g.s?" \u00B7 "+g.s:"") : (g.s||"")); }

function makeCard(g){
  const el=document.createElement("div");
  el.className="game"+(g.o?" own":"");
  el.dataset.f=g.f;
  const label=esc(gameLabel(g)), sub=esc(gameSub(g));
  const initial=esc(String(gameLabel(g)).replace(/^#/,"").charAt(0)||"#");
  el.innerHTML =
    '<a class="gl" href="#p='+esc(g.f)+'" title="'+label+(g.o?"":" - play")+'">'+
      '<div class="thumb">'+
        (g.c?'<img loading="lazy" decoding="async" src="'+esc(g.c)+'" alt="">':'')+
        '<div class="fallback">'+(g.e?'<span class="fe">'+g.e+'</span>':'<span class="fi">'+initial+'</span>')+'</div>'+
        (g.o?'<span class="badge">Home-made</span>':'')+
        '<div class="play"><span>'+ICON_PLAY+'</span></div>'+
      '</div>'+
      '<div class="meta"><span class="gt">'+label+'</span><span class="gs">'+sub+'</span></div>'+
    '</a>'+
    '<button type="button" class="favbtn'+(favs.has(g.f)?" on":"")+'" title="Toggle favorite" aria-label="Toggle favorite">'+ICON_HEART+'</button>';

  const img=el.querySelector("img");
  if(img){
    img.addEventListener("load", ()=>img.classList.add("ok"));
    img.addEventListener("error", ()=>img.remove());
  }
  el.querySelector(".gl").addEventListener("click", e=>{
    if(e.button>0||e.ctrlKey||e.metaKey||e.shiftKey) return; /* let "open in new tab" work normally */
    e.preventDefault(); openGame(g.f);
  });
  el.querySelector(".favbtn").addEventListener("click", e=>{ e.stopPropagation(); toggleFav(g.f); });
  io.observe(el);
  return el;
}

/* one card node per game, reused across renders */
const cardCache=new Map();
for(const g of GAMES) cardCache.set(g.f, makeCard(g));

/* ============================== RENDERING ============================== */
const CMP={
  new:(a,b)=> b.n-a.n || a.f.localeCompare(b.f,undefined,{numeric:true}),
  old:(a,b)=> a.n-b.n || a.f.localeCompare(b.f,undefined,{numeric:true}),
  az: (a,b)=> (a.t||a.f).localeCompare(b.t||b.f,undefined,{numeric:true}),
  za: (a,b)=> (b.t||b.f).localeCompare(a.t||a.f,undefined,{numeric:true}),
  rnd:(a,b)=> a.r-b.r
};

function renderGrid(){
  renderOwn();
  let list=GAMES.filter(g=>!g.o);
  if(favsOnly) list=list.filter(g=>favs.has(g.f));
  const q=query.trim().toLowerCase();
  if(q) list=list.filter(g=> g.f.toLowerCase().includes(q) || String(g.n).includes(q.replace(/^#/,"")) || g.s.toLowerCase().includes(q) || (g.t&&g.t.toLowerCase().includes(q)));
  list.sort(CMP[sort]||CMP.new);
  return buildGrid(list);
}

function buildGrid(list){
  const frag=document.createDocumentFragment();
  for(const g of list) frag.appendChild(cardCache.get(g.f));
  grid.replaceChildren(frag);
  $("allCount").textContent=list.length;
  const empty=$("empty");
  if(list.length===0){
    empty.style.display="block";
    empty.innerHTML = favsOnly
      ? "No favorites yet.<br>Tap the <b>heart</b> on any game to save it here."
      : "No games match <b>"+esc(query.trim())+"</b>.<br>Try a number like <b>842</b> or a name like <b>pizza</b>.";
  }else empty.style.display="none";
}

/* home-made games live in their own row at the top of the library */
function renderOwn(){
  const sec=$("ownSec"), row=$("ownRow");
  let list=GAMES.filter(g=>g.o);
  if(favsOnly) list=list.filter(g=>favs.has(g.f));
  const q=query.trim().toLowerCase();
  if(q) list=list.filter(g=> g.f.toLowerCase().includes(q) || (g.t&&g.t.toLowerCase().includes(q)));
  sec.hidden=list.length===0;
  for(const el of row.childNodes) io.unobserve(el);
  const frag=document.createDocumentFragment();
  for(const g of list) frag.appendChild(makeCard(g));
  row.replaceChildren(frag);
}

function renderRecent(){
  const sec=$("recentSec"), row=$("recentRow");
  if(recent.length===0){ sec.hidden=true; row.replaceChildren(); return; }
  sec.hidden=false;
  for(const el of row.childNodes) io.unobserve(el);
  const frag=document.createDocumentFragment();
  for(const f of recent){ const g=byFile.get(f); if(g) frag.appendChild(makeCard(g)); }
  row.replaceChildren(frag);
}

function renderFeatured(){
  const list=GAMES.filter(g=>g.o);
  const row=$("featRow");
  for(const el of row.childNodes) io.unobserve(el);
  const frag=document.createDocumentFragment();
  for(const g of list) frag.appendChild(makeCard(g));
  row.replaceChildren(frag);
  $("featSec").hidden=list.length===0;
}

function renderFavCount(){
  $("favCount").textContent=favs.size;
  $("statFavs").textContent=favs.size;
}

/* ============================== FAVORITES / RECENT ============================== */
function toggleFav(f){
  if(favs.has(f)){ favs.delete(f); toast("Removed from favorites"); }
  else{ favs.add(f); toast("Added to favorites"); }
  store.set("gn_favs",[...favs]);
  renderFavCount();
  document.querySelectorAll('.game[data-f]').forEach(el=>{
    if(el.dataset.f!==f) return;
    const b=el.querySelector(".favbtn");
    if(b) b.classList.toggle("on", favs.has(f));
  });
  if($("player").classList.contains("active")) syncPlayerFavBtn();
  if(favsOnly) renderGrid();
}

function addRecent(f){
  recent=[f, ...recent.filter(x=>x!==f)].slice(0,12);
  store.set("gn_recent",recent);
  renderRecent();
}

$("clearRecent").addEventListener("click",()=>{ recent=[]; store.set("gn_recent",recent); renderRecent(); });

/* ============================== VIEWS / ROUTING ============================== */
/* proxied iframe tabs: one row per tab (view id "view-"+key, nav button data-nav=key, route #key,
   containers #ptMount-key / #ptLoad-key). Frames are created lazily through the Scramjet proxy. */
const PROXY_TABS={
  movies:{url:"https://flixer.gd",label:"Movies"},
  music:{url:"https://soundcloud.com",label:"Music"}
};
const isProxyTab=k=>Object.prototype.hasOwnProperty.call(PROXY_TABS,k);
const isFrameView=v=>v==="ai"||isProxyTab(v);

function showView(v){
  document.body.dataset.view=v;
  if(isFrameView(v)) document.body.dataset.fv="1"; else delete document.body.dataset.fv;
  for(const el of document.querySelectorAll(".view")) el.classList.toggle("active", el.id==="view-"+v);
  for(const b of document.querySelectorAll(".navlink")) b.classList.toggle("active", b.dataset.nav===v);
  if(v==="library") renderGrid();
  if(v==="ai"){
    const af=$("aiFrame");
    if(!af.getAttribute("src")) af.src="jarvis.html"; /* lazy-load Jarvis on first visit */
  }
  if(isProxyTab(v)) ensureProxyTab(v);
  if(isFrameView(v)) sizeFrameView();
}

/* keep every iframe view (AI, Movies, Music) exactly as tall as the space under the (possibly wrapping) header */
function sizeFrameView(){ document.documentElement.style.setProperty("--topH", $("topbar").offsetHeight+"px"); }
window.addEventListener("resize",()=>{ if(document.body.dataset.fv) sizeFrameView(); });
if(typeof ResizeObserver==="function") new ResizeObserver(()=>{ if(document.body.dataset.fv) sizeFrameView(); }).observe($("topbar"));

/* route(initial): the landing-page setting only applies to the very first load */
function route(initial){
  const m=location.hash.match(/^#p=(.+)$/);
  const f=m?decodeURIComponent(m[1]):null;
  let v;
  if(f||location.hash==="#library") v="library";
  else if(isFrameView(location.hash.slice(1))) v=location.hash.slice(1);
  else if(initial) v=settings.landing==="library" ? "library" : "home";
  else v="home";
  showView(v);
  if(f&&byFile.has(f)) showPlayer(byFile.get(f));
  else closePlayer();
}
window.addEventListener("hashchange",()=>route(false));

function goHome(){
  hideBrowse();
  if(location.hash===""||location.hash==="#") showView("home");
  else location.hash="";
}

document.querySelectorAll(".navlink").forEach(b=>b.addEventListener("click",()=>{
  if(b.dataset.nav==="library") location.hash="#library";
  else if(isFrameView(b.dataset.nav)) location.hash="#"+b.dataset.nav;
  else goHome();
}));
$("brandHome").addEventListener("click",goHome);
$("enterLib").addEventListener("click",()=>{ location.hash="#library"; });

/* ============================== GAME PLAYER ============================== */
let current=null;

function openGame(f){ location.hash="p="+f; }

/* a game or the browser overlay is open */
function syncOvl(){
  document.body.classList.toggle("ovl", $("player").classList.contains("active") || $("browse").classList.contains("active"));
}

function showPlayer(g){
  current=g;
  if(g.o&&isFile()){
    /* Unity/ES-module builds cannot fetch their files over file:// - show a friendly hint instead of a Unity error */
    frame.removeAttribute("src");
    frame.srcdoc='<!DOCTYPE html><html><head><meta charset="utf-8"><style>'
      +'body{margin:0;min-height:100vh;display:flex;align-items:center;justify-content:center;'
      +'background:radial-gradient(600px 360px at 50% 0,rgba(225,29,46,.22),transparent 70%),#0a0a0b;color:#f4f4f5;font-family:Inter,system-ui,"Segoe UI",sans-serif;text-align:center;padding:20px;box-sizing:border-box}'
      +'.card{max-width:520px;padding:32px 36px;background:#141416;border:1px solid #34343a;border-radius:16px;box-shadow:0 18px 50px rgba(0,0,0,.55)}'
      +'h2{margin:0 0 10px;font-size:1.25rem;letter-spacing:-.02em}p{margin:9px 0;color:#a1a1aa;line-height:1.6;font-size:.94rem}'
      +'code{background:#1a1a1d;border:1px solid #232327;padding:1px 8px;border-radius:6px;color:#ff6b78;font-size:.92em}'
      +'.btn{display:inline-block;margin-top:14px;padding:11px 22px;border-radius:10px;'
      +'background:linear-gradient(180deg,#f12c3d,#cf1a2b);box-shadow:inset 0 1px 0 rgba(255,255,255,.18);color:#fff;font-weight:600;text-decoration:none}code.wide{display:inline-block;margin-top:6px}'
      +'</style></head><body>'
      +'<div class="card">'
      +'<h2>'+esc(g.t||"This game")+' needs the local server</h2>'
      +'<p>Home-made games cannot run while the site is opened by double-clicking its file<br>(browsers block game files on <code>file://</code> pages).</p>'
      +'<p>Double-click <code>Start Julmust Arcade.bat</code> in the site folder,<br>then open <code class="wide">http://localhost:8765/</code></p>'
      +'<a class="btn" href="http://localhost:8765/">Open localhost:8765</a>'
      +'<p style="margin-top:14px;font-size:.85rem">(the other 800+ games work fine right where you are)</p>'
      +'</div></body></html>';
  }else{
    frame.removeAttribute("srcdoc");
    frame.src=g.f;
  }
  const sub=gameSub(g);
  $("pTitle").innerHTML=esc(gameLabel(g))+(sub?'<span class="gs">'+esc(sub)+"</span>":"");
  $("newTabBtn").href=g.f;
  syncPlayerFavBtn();
  const i=NAV.indexOf(g);
  $("prevBtn").disabled=i<=0;
  $("nextBtn").disabled=i<0||i>=NAV.length-1;
  $("player").classList.add("active");
  syncOvl();
  document.body.style.overflow="hidden";
  document.title="\u25B6 "+(g.t||("#"+g.n))+" \u00B7 Julmust";
  addRecent(g.f);
}

function closePlayer(){
  current=null;
  $("player").classList.remove("active");
  syncOvl();
  frame.removeAttribute("srcdoc");
  frame.src="about:blank";
  document.body.style.overflow="";
  document.title=SITE_TITLE;
}

function syncPlayerFavBtn(){
  const b=$("favBtn"), on=favs.has(current.f);
  b.classList.toggle("on", on);
  b.setAttribute("aria-pressed", on?"true":"false");
}

function step(d){
  if(!current) return;
  const i=NAV.indexOf(current), j=i+d;
  if(j>=0&&j<NAV.length) location.hash="p="+NAV[j].f;
}

$("backBtn").addEventListener("click",()=>{ location.hash=""; });
$("closeBtn").addEventListener("click",()=>{ location.hash=""; });
$("prevBtn").addEventListener("click",()=>step(-1));
$("nextBtn").addEventListener("click",()=>step(1));
$("favBtn").addEventListener("click",()=>toggleFav(current.f));
$("fsBtn").addEventListener("click",toggleFullscreen);
$("copyBtn").addEventListener("click",()=>copyLink(current.f));

function toggleFullscreen(){
  if(document.fullscreenElement) document.exitFullscreen();
  else if(frame.requestFullscreen) frame.requestFullscreen();
}

function copyLink(f){
  const url=location.href.split("#")[0]+"#p="+f;
  const done=()=>toast("Link copied to clipboard");
  const fallback=()=>{
    try{
      const t=document.createElement("textarea");
      t.value=url; t.style.position="fixed"; t.style.opacity="0";
      document.body.appendChild(t); t.select();
      document.execCommand("copy"); t.remove(); done();
    }catch(e){ toast("Could not copy link"); }
  };
  if(navigator.clipboard&&navigator.clipboard.writeText)
    navigator.clipboard.writeText(url).then(done).catch(fallback);
  else fallback();
}

/* ============================== PROXY (Scramjet + wisp) ============================== */
let sj=null, sjConn=null, sjBootPromise=null, sjFrameMod=null;
let browsePrevView="home", browseCurrent="";

const abs=p=>new URL(p,location.href).toString();
const setStatus=t=>{ $("pStatus").textContent=t||""; };
const setProg=p=>{ $("pBarTrack").classList.toggle("on",p>0); $("pBar").style.width=p+"%"; };
function proxyError(msg, err){
  $("pError").textContent=msg||"";
  if(err) console.error(err);
  setStatus(""); setProg(0);
}
const isFile=()=>location.protocol==="file:";

/* search engine preference (shared with Settings) */
const engineSel=$("pEngine");
try{
  const saved=localStorage.getItem("aa_engine");
  if(saved && [...engineSel.options].some(o=>o.value===saved)) engineSel.value=saved;
  engineSel.addEventListener("change",()=>localStorage.setItem("aa_engine",engineSel.value));
}catch(e){}

async function waitForWisp(url,maxMs){
  const start=Date.now(); let tries=0;
  while(Date.now()-start<maxMs){
    tries++;
    const ok=await new Promise(resolve=>{
      let ws, done=false;
      const finish=v=>{ if(!done){ done=true; try{ws.close();}catch(e){} resolve(v); } };
      try{ ws=new WebSocket(url); }catch(e){ return resolve(false); }
      ws.onopen=()=>finish(true);
      ws.onerror=()=>finish(false);
      ws.onclose=()=>finish(false);
      setTimeout(()=>finish(false),8000);
    });
    if(ok) return true;
    setStatus("Waking up the server\u2026 (attempt "+tries+")");
    setProg(Math.min(35+tries*4,70));
    await new Promise(r=>setTimeout(r,3000));
  }
  return false;
}

async function ensureProxy(){
  if(sjBootPromise) return sjBootPromise;
  sjBootPromise=(async()=>{
    if(isFile()) throw new Error("The proxy needs the site to be hosted (https) or run from a local web server. Double-click \u201CStart Julmust Arcade.bat\u201D to get both \u2014 games work offline either way.");
    if(!navigator.serviceWorker) throw new Error("This browser does not support service workers (required by the proxy).");
    setStatus("Loading proxy core\u2026"); setProg(15);
    if(!sj){
      const { ScramjetController }=$scramjetLoadController();
      sj=new ScramjetController({files:{
        wasm:abs("scram/engine.txt"),
        all:abs("scram/scramjet.all.js"),
        sync:abs("scram/scramjet.sync.js"),
      }});
    }
    try{ await sj.init(); }
    catch(e){
      setStatus("Repairing proxy data\u2026");
      try{ for(const r of await navigator.serviceWorker.getRegistrations()) await r.unregister(); }catch(_){}
      await new Promise(res=>{ const rq=indexedDB.deleteDatabase("$scramjet"); rq.onsuccess=rq.onerror=rq.onblocked=()=>res(); setTimeout(res,3000); });
      await sj.init();
    }
    setProg(35); setStatus("Registering service worker\u2026");
    await registerSW();
    await navigator.serviceWorker.ready;
    setProg(55); setStatus("Connecting to the server\u2026");
    const w=effWisp();
    if(!w) throw new Error("No wisp server configured \u2014 set one in Settings.");
    if(!(await waitForWisp(w,45000)))
      throw new Error("Could not reach the proxy server. It may be asleep or offline \u2014 try again in a minute.");
    setProg(80); setStatus("Setting up transport\u2026");
    sjConn=sjConn||new BareMux.BareMuxConnection(abs("baremux/worker.js"));
    const cur=await sjConn.getTransport();
    const transportOk = cur===abs("libcurl/index.mjs") || String(cur).startsWith("blob:");
    if(!transportOk || activeWisp!==w){
      try{ await sjConn.setTransport(abs("libcurl/index.mjs"),[{websocket:w}]); }
      catch(err){
        const src=await (await fetch(abs("libcurl/index.mjs"))).text();
        if(!src.includes("LibcurlClient")) throw err;
        await sjConn.setTransport(URL.createObjectURL(new Blob([src],{type:"text/javascript"})),[{websocket:w}]);
      }
      activeWisp=w;
    }
    setProg(100); setStatus("");
    setTimeout(()=>setProg(0),400);
    return sj;
  })().catch(e=>{ sjBootPromise=null; setProg(0); setStatus(""); throw e; });
  return sjBootPromise;
}

/* shared: create a proxied frame (ensureProxy() must have resolved) and mount it into any container */
function mountProxyFrame(container, allow){
  const mod=sj.createFrame();
  if(allow){ mod.frame.setAttribute("allow",allow); mod.frame.setAttribute("allowfullscreen",""); }
  container.appendChild(mod.frame);
  return mod;
}

function ensureBrowseFrame(){
  if(sjFrameMod) return sjFrameMod;
  sjFrameMod=mountProxyFrame($("bFrameWrap"));
  sjFrameMod.frame.id="sjFrame";
  try{
    sjFrameMod.addEventListener("urlchange",e=>{ $("bAddr").value=String(e.url); browseCurrent=String(e.url); });
  }catch(e){}
  return sjFrameMod;
}

function showBrowse(url){
  closePlayer();
  browseCurrent=url;
  document.body.style.overflow="hidden";
  $("browse").classList.add("active");
  syncOvl();
  $("bAddr").value=url;
  const mod=ensureBrowseFrame();
  mod.frame.style.display="";
  try{ mod.go(url); }catch(e){}
}

function hideBrowse(){
  $("browse").classList.remove("active");
  syncOvl();
  if(sjFrameMod) sjFrameMod.frame.style.display="none";
  document.body.style.overflow="";
}

/* ---- proxied tabs (Movies, Music): lazy, created once, kept alive while hidden ---- */
const PROXY_ALLOW="fullscreen; autoplay; encrypted-media; picture-in-picture; clipboard-write";
const PT_BOOT_MS=75000, PT_LOAD_MS=25000;
const ptState={};
for(const k in PROXY_TABS) ptState[k]={mod:null, busy:false};

function withTimeout(p, ms, msg){
  let t;
  return Promise.race([p, new Promise((_,rej)=>{ t=setTimeout(()=>rej(new Error(msg)),ms); })]).finally(()=>clearTimeout(t));
}
const errText=e=>(e&&e.message)||"The proxy failed to start.";

/* mode: loading | done | error | file - drives the loader / error panel of a tab */
function ptShow(k, mode, msg){
  const el=$("ptLoad-"+k), label=PROXY_TABS[k].label;
  el.classList.remove("done","err");
  if(mode==="done"){ el.classList.add("done"); return; }
  if(mode==="loading"){ el.innerHTML='<div class="spin"></div><div>Loading '+esc(label)+"\u2026</div>"; return; }
  el.classList.add("err");
  if(mode==="file"){
    el.innerHTML='<div class="pt-ico">!</div><h2>'+esc(label)+' needs the local server</h2>'
      +'<p>The proxy cannot run while the site is opened by double-clicking its file<br>(browsers block it on <code>file://</code> pages).</p>'
      +'<p>Double-click <code>Start Julmust Arcade.bat</code> in the site folder,<br>then open <code>http://localhost:8765/</code></p>'
      +'<div class="ptbtns"><a class="btn btn-primary" href="http://localhost:8765/">Open localhost:8765</a></div>';
    return;
  }
  el.innerHTML='<div class="pt-ico">!</div><h2>'+esc(label)+" could not be loaded</h2><p>"+esc(msg||"The proxy failed to start.")+"</p>"
    +'<div class="ptbtns"><button class="btn btn-primary" type="button" data-act="retry">Retry</button>'
    +'<button class="btn" type="button" data-act="browse">Open in proxy browser</button></div>';
}

async function ensureProxyTab(k){
  const st=ptState[k], cfg=PROXY_TABS[k];
  if(st.mod||st.busy) return;
  if(isFile()){ ptShow(k,"file"); return; }
  st.busy=true; ptShow(k,"loading");
  let mod=null;
  try{
    await withTimeout(ensureProxy(),PT_BOOT_MS,"The proxy took too long to start. The proxy server may be asleep or unreachable \u2014 try again in a minute.");
    mod=mountProxyFrame($("ptMount-"+k),PROXY_ALLOW);
    const fr=mod.frame;
    fr.title=cfg.label;
    fr.addEventListener("load",()=>{
      try{ if(fr.contentWindow.location.href==="about:blank") return; }catch(e){}
      ptShow(k,"done");
    });
    mod.go(cfg.url);
    st.mod=mod;
    setTimeout(()=>ptShow(k,"done"),PT_LOAD_MS); /* never keep the loader over a page that is already visible */
  }catch(err){
    if(mod&&!st.mod) mod.frame.remove();
    ptShow(k,"error",errText(err));
    console.error(err);
  }finally{
    st.busy=false;
  }
}

async function openTabInBrowser(k){
  try{
    await withTimeout(ensureProxy(),PT_BOOT_MS,"The proxy took too long to start.");
    browsePrevView=k;
    showBrowse(PROXY_TABS[k].url);
  }catch(err){
    ptShow(k,"error",errText(err));
    toast("Proxy still unavailable");
  }
}

document.querySelectorAll(".fload[data-pt]").forEach(el=>el.addEventListener("click",e=>{
  const btn=e.target.closest("button[data-act]");
  if(!btn) return;
  if(btn.dataset.act==="retry") ensureProxyTab(el.dataset.pt);
  else if(btn.dataset.act==="browse") openTabInBrowser(el.dataset.pt);
}));

async function browseTo(input){
  const q=(input||"").trim();
  if(!q) return;
  $("pError").textContent="";
  const btn=$("pGo"); btn.disabled=true;
  try{
    setStatus("Booting proxy\u2026"); setProg(8);
    await ensureProxy();
    setStatus(""); setProg(0);
    browsePrevView=document.body.dataset.view==="library"?"library":"home";
    showBrowse(search(q,engineSel.value));
    toast("Proxy connected");
  }catch(err){
    proxyError(err.message||"The proxy failed to start.", err);
  }finally{
    btn.disabled=false;
  }
}

$("pForm").addEventListener("submit",e=>{ e.preventDefault(); browseTo($("pInput").value); });
document.querySelectorAll(".chip").forEach(c=>c.addEventListener("click",()=>browseTo(c.dataset.url)));

$("bBack").addEventListener("click",()=>{ try{ sjFrameMod.back(); }catch(e){} });
$("bFwd").addEventListener("click",()=>{ try{ sjFrameMod.forward(); }catch(e){} });
$("bReload").addEventListener("click",()=>{ try{ sjFrameMod.reload(); }catch(e){} });
$("bHome").addEventListener("click",()=>{ hideBrowse(); goHome(); });
$("bExit").addEventListener("click",()=>{ hideBrowse(); showView(browsePrevView); });
$("bNew").addEventListener("click",()=>{ if(browseCurrent) window.open(browseCurrent,"_blank"); });
$("bFs").addEventListener("click",()=>{
  const el=$("browse");
  if(document.fullscreenElement) document.exitFullscreen();
  else if(el.requestFullscreen) el.requestFullscreen();
});
$("bForm").addEventListener("submit",e=>{
  e.preventDefault();
  const q=$("bAddr").value.trim();
  if(q&&sjFrameMod){ try{ sjFrameMod.go(search(q,engineSel.value)); }catch(err){} }
});

/* ============================== SETTINGS UI ============================== */
const settingsModal=$("settingsModal");
let settingsOpener=null;

function openSettings(){
  settingsOpener=document.activeElement;
  settingsModal.classList.add("active");
  syncSettingsUI();
  document.body.style.overflow="hidden";
  $("sClose").focus();
}
function closeSettings(){
  settingsModal.classList.remove("active");
  /* an open game / browser overlay keeps the page locked */
  document.body.style.overflow=(document.body.classList.contains("ovl")||document.body.dataset.fv)?"hidden":"";
  if(settingsOpener&&settingsOpener.focus) try{ settingsOpener.focus(); }catch(e){}
  settingsOpener=null;
}
function syncSettingsUI(){
  $("sCards").value=settings.cards;
  $("sLanding").value=settings.landing;
  $("sEngine").value=engineSel.value;
  $("wispInput").value=settings.wisp;
  $("wispNow").textContent="In use: "+effWisp();
  const out=$("wispTestOut");
  out.textContent=""; out.className="wout";
}

$("settingsBtn").addEventListener("click",openSettings);
$("sClose").addEventListener("click",closeSettings);
settingsModal.querySelector(".sback").addEventListener("click",closeSettings);

function setCards(v){
  settings.cards=v;
  store.set("gn_cards",settings.cards);
  applySettings();
  $("sCards").value=settings.cards;
}
$("sCards").addEventListener("change",e=>setCards(e.target.value));
document.querySelectorAll("#sizeSeg button").forEach(b=>b.addEventListener("click",()=>setCards(b.dataset.size)));

$("sLanding").addEventListener("change",e=>{
  settings.landing=e.target.value;
  store.set("gn_landing",settings.landing);
  toast("Starts on "+(settings.landing==="library"?"Games":"Home")+" next visit");
});

/* engine: sync home select + storage */
$("sEngine").addEventListener("change",e=>{
  localStorage.setItem("aa_engine",e.target.value);
  engineSel.value=e.target.value;
});

/* wisp server override */
$("wispInput").addEventListener("change",e=>{
  settings.wisp=e.target.value.trim();
  store.set("aa_wisp",settings.wisp);
  $("wispNow").textContent="In use: "+effWisp();
  toast(settings.wisp ? "Custom server saved \u2014 applies on next browse" : "Using the built-in server");
});

$("wispTest").addEventListener("click",async()=>{
  const url=$("wispInput").value.trim();
  const out=$("wispTestOut");
  if(!url){
    out.textContent="Enter a server URL first \u2014 or clear the field to use the built-in one.";
    out.className="wout";
    return;
  }
  out.textContent="Testing\u2026"; out.className="wout";
  const ok=await new Promise(res=>{
    let ws, done=false;
    const fin=v=>{ if(!done){ done=true; try{ws.close();}catch(e){} res(v); } };
    try{ ws=new WebSocket(url); }catch(e){ return res(false); }
    ws.onopen=()=>fin(true);
    ws.onerror=()=>fin(false);
    ws.onclose=()=>fin(false);
    setTimeout(()=>fin(false),6000);
  });
  out.textContent = ok ? "\u2713 Connected \u2014 server is awake" : "\u2717 Could not connect within 6s";
  out.className="wout "+(ok?"good":"bad");
});

/* data management */
$("sClearRecent").addEventListener("click",()=>{
  recent=[]; store.set("gn_recent",recent); renderRecent();
  toast("Recently played cleared");
});

$("sClearFavs").addEventListener("click",()=>{
  if(favs.size===0){ toast("No favorites to clear"); return; }
  if(!confirm("Remove all favorites?")) return;
  favs.clear(); store.set("gn_favs",[]);
  renderFavCount(); renderGrid();
  document.querySelectorAll(".favbtn.on").forEach(b=>b.classList.remove("on"));
  toast("Favorites cleared");
});

$("sReset").addEventListener("click",()=>{
  if(!confirm("Reset ALL site data?\n(favorites, history, proxy settings \u2014 everything)")) return;
  try{ localStorage.clear(); }catch(e){}
  location.reload();
});

/* ============================== TOOLBAR ============================== */
let raf=null;
searchBox.addEventListener("input",()=>{
  if(raf) cancelAnimationFrame(raf);
  raf=requestAnimationFrame(()=>{ query=searchBox.value; renderGrid(); raf=null; });
});

const sortSel=$("sort");
sortSel.value=sort;
sortSel.addEventListener("change",()=>{
  sort=sortSel.value; store.set("gn_sort",sort);
  if(sort==="rnd") for(const g of GAMES) g.r=Math.random();
  renderGrid();
});
if(sort==="rnd") for(const g of GAMES) g.r=Math.random();

$("favToggle").addEventListener("click",()=>{
  favsOnly=!favsOnly;
  $("favToggle").classList.toggle("on",favsOnly);
  $("favToggle").setAttribute("aria-pressed",favsOnly?"true":"false");
  renderGrid();
});

const randomGame=()=>openGame(NAV[Math.floor(Math.random()*NAV.length)].f);
$("randomBtn").addEventListener("click",randomGame);
$("heroRandom").addEventListener("click",randomGame);

/* jump to the library search box (keeps the browser back button working from any view) */
function focusSearch(){
  if(location.hash!=="#library") history.pushState(null,"","#library");
  showView("library"); searchBox.focus();
}
$("searchBtn").addEventListener("click",focusSearch);

/* ============================== MISC UI ============================== */
let toastTimer=null;
function toast(msg){
  const t=$("toast");
  t.textContent=msg; t.classList.add("show");
  clearTimeout(toastTimer);
  toastTimer=setTimeout(()=>t.classList.remove("show"),1700);
}

const toTop=$("toTop");
addEventListener("scroll",()=>toTop.classList.toggle("show",scrollY>700),{passive:true});
toTop.addEventListener("click",()=>scrollTo({top:0,behavior:"smooth"}));

document.addEventListener("keydown",e=>{
  if(settingsModal.classList.contains("active")){
    if(e.key==="Escape") closeSettings();
    return;
  }
  if($("browse").classList.contains("active")){
    if(e.key==="Escape") hideBrowse();
    return;
  }
  if($("player").classList.contains("active")){
    if(e.key==="Escape") location.hash="";
    else if(e.key==="ArrowLeft") step(-1);
    else if(e.key==="ArrowRight") step(1);
    else if(e.key==="f"||e.key==="F") toggleFullscreen();
    return;
  }
  const typing=/INPUT|SELECT|TEXTAREA/.test(document.activeElement.tagName);
  if(!typing&&e.key==="/"){
    e.preventDefault();
    focusSearch();
  }
});

/* ============================== INIT ============================== */
applySettings();
$("heroCount").textContent=GAMES.length;
$("statGames").textContent=GAMES.length;
$("tileGames").textContent=GAMES.length;
$("statCovers").textContent=GAMES.filter(g=>g.c).length;
$("footCount").textContent=GAMES.length;
$("sCount").textContent=GAMES.length;
renderFavCount();
renderRecent();
renderFeatured();
renderOwn();

/* AI view: hide the loader once Jarvis has loaded */
$("aiFrame").addEventListener("load",()=>{ if($("aiFrame").getAttribute("src")) $("aiLoad").classList.add("done"); });

/* wake the effective wisp server early so it is (mostly) awake when needed */
try{
  const w=effWisp();
  if(w) fetch(w.replace("wss://","https://").replace(/\/wisp\/?$/,"/"),{mode:"no-cors"}).catch(()=>{});
}catch(e){}

route(true);
if(isFile()) setStatus("\u26A0 Opened via file:// \u2014 double-click \u201CStart Julmust Arcade.bat\u201D for the full experience (home-made Unity games and the proxy need it).");
