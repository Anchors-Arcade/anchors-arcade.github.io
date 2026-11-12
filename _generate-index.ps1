# Regenerates index.html for "Julmust Arcade V67" - game portal + Scramjet web proxy.
# Re-run any time you add/remove game files (run _generate-covers.ps1 first for new covers).
# Placeholders: __GAMES__ (game array), __LOGO_HEADER__ / __LOGO_HERO__ (inlined theme-aware logo.svg)

$ErrorActionPreference = 'Stop'
$dir = $PSScriptRoot
$coversDir = Join-Path $dir 'covers'

$template = @'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<script>
/* Minimal mode is applied before first paint (no flash). The Fredoka web font is only requested when it is off. */
(function(){
  var d=document.documentElement, on=false;
  try{ var v=localStorage.getItem("gn_minimal"); if(v!==null){ try{ v=JSON.parse(v); }catch(e){} on=(v===true||v===1||v==="true"||v==="1"); } }catch(e){}
  if(on) d.classList.add("minimal");
  window.gnFonts=function(){
    if(window.gnFontsOn) return; window.gnFontsOn=1;
    try{
      var h=document.head, u=["https://fonts.googleapis.com","https://fonts.gstatic.com"], l, i;
      for(i=0;i<2;i++){ l=document.createElement("link"); l.rel="preconnect"; l.href=u[i]; if(i) l.setAttribute("crossorigin",""); h.appendChild(l); }
      l=document.createElement("link"); l.rel="stylesheet"; l.href="https://fonts.googleapis.com/css2?family=Fredoka:wght@400;500;600;700&display=swap"; h.appendChild(l);
    }catch(e){}
  };
  if(!on) window.gnFonts();
})();
</script>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="theme-color" content="#0a0507">
<title>Julmust Arcade V67</title>
<link rel="icon" type="image/png" href="favicon.png">
<noscript><link href="https://fonts.googleapis.com/css2?family=Fredoka:wght@400;500;600;700&display=swap" rel="stylesheet"></noscript>

<!-- proxy stack -->
<script src="scram/scramjet.all.js"></script>
<script src="baremux/index.js"></script>
<script src="wisp-config.js"></script>
<script src="register-sw.js"></script>
<script src="search.js"></script>

<style>
/* =====================================================================
   Julmust Arcade - "cherry cola" soda theme: red + black, fizzy + bubbly
   default theme = data-theme="red"    (cherry cola)
   alt theme     = data-theme="purple" (blueberry soda)
   ===================================================================== */
:root{
  color-scheme:dark;
  --bg:#0a0507; --bg2:#120709; --panel:#160a0e; --card:#1c0d12; --card2:#2b1219;
  --line:#3d1a22; --text:#fff4ee; --muted:#c4a3a5;
  --gold:#ffc46b; --caramel:#e8a85a; --foam:#fff4ee;
  --disp:"Fredoka","Baloo 2","Nunito","Arial Rounded MT Bold","Segoe UI",system-ui,sans-serif;
  --body:"Segoe UI",system-ui,-apple-system,Roboto,sans-serif;
  --spring:cubic-bezier(.34,1.56,.64,1);
  --acc:#ff3b4e; --acc2:#ff6b7a; --acc-hi:#f0283a; --acc-mid:#e11d2e; --acc-deep:#b30f1e;
  --glow:rgba(255,59,78,.45);
  --glow-soft:rgba(255,59,78,.14);
  --tint:rgba(255,59,78,.2);
  --ring:rgba(255,59,78,.32);
  --ring2:rgba(255,59,78,.55);
  --err:#ff9aa6;
  --wash:rgba(225,29,46,.26); --wash2:rgba(255,196,107,.07);
  --bub:rgba(255,80,96,.3);
  --bar:rgba(10,5,7,.86);
  --liquid-top:#a50f1d; --liquid-back:#6b0a14;
  --gel:linear-gradient(180deg,rgba(255,255,255,.26) 0,rgba(255,255,255,.05) 48%,rgba(255,255,255,0) 50%),linear-gradient(180deg,var(--acc-hi),var(--acc-mid) 55%,var(--acc-deep));
  --gelsh:inset 0 1px 0 rgba(255,255,255,.55),inset 0 -3px 0 rgba(0,0,0,.25),0 6px 18px var(--glow);
  --glass:linear-gradient(180deg,rgba(255,255,255,.09),rgba(255,255,255,0) 52%);
}
body[data-theme="purple"]{
  --bg:#07060f; --bg2:#0d0a1c; --panel:#0f0d20; --card:#15122c; --card2:#201b40;
  --line:#2f2a5a; --text:#f4f2ff; --muted:#aaa6d0;
  --acc:#9d8cff; --acc2:#c4baff; --acc-hi:#7b66ff; --acc-mid:#5e46e8; --acc-deep:#3d27b0;
  --glow:rgba(124,102,255,.45);
  --glow-soft:rgba(124,102,255,.15);
  --tint:rgba(124,102,255,.2);
  --ring:rgba(157,140,255,.32);
  --ring2:rgba(157,140,255,.55);
  --err:#ff9fb4;
  --wash:rgba(94,70,232,.28); --wash2:rgba(157,140,255,.08);
  --bub:rgba(157,140,255,.3);
  --bar:rgba(7,6,15,.86);
  --liquid-top:#3d27b0; --liquid-back:#26187a;
}
*{box-sizing:border-box;margin:0;padding:0}
html{scroll-behavior:smooth;background:#0a0507}
body{
  min-height:100vh; color:var(--text); font-family:var(--body); background-color:var(--bg);
  background-image:
    radial-gradient(1000px 600px at 50% -14%, var(--wash), transparent 62%),
    radial-gradient(640px 460px at 104% 30%, var(--wash2), transparent 62%),
    radial-gradient(760px 520px at -8% 78%, var(--wash), transparent 64%),
    linear-gradient(180deg, var(--bg2), var(--bg) 520px);
  background-attachment:fixed;
}
button{font-family:inherit}
::selection{background:var(--glow); color:#fff}
:focus-visible{outline:3px solid var(--foam); outline-offset:2px}
main,footer{position:relative; z-index:1}

/* ---------------- fizz layer (rising bubbles) ---------------- */
#fizz{position:fixed; inset:0; z-index:0; overflow:hidden; pointer-events:none; contain:strict}
#fizz i{
  position:absolute; bottom:-90px; left:var(--x); width:var(--s); height:var(--s);
  border-radius:50%; opacity:0; will-change:transform,opacity;
  border:1px solid rgba(255,255,255,.22);
  background:
    radial-gradient(circle at 32% 28%, rgba(255,255,255,.75) 0 7%, rgba(255,255,255,.16) 8% 22%, transparent 24%),
    radial-gradient(circle at 50% 50%, transparent 52%, var(--bub) 100%);
  animation:fizzRise var(--t) linear var(--dl) infinite;
}
@keyframes fizzRise{
  0%{transform:translate3d(0,0,0) scale(.7); opacity:0}
  8%{opacity:.85}
  25%{transform:translate3d(var(--dx),-28vh,0) scale(.9)}
  50%{transform:translate3d(calc(var(--dx) * -.5),-58vh,0) scale(1)}
  75%{transform:translate3d(calc(var(--dx) * .7),-88vh,0) scale(1.05)}
  92%{opacity:.7}
  100%{transform:translate3d(calc(var(--dx) * -.3),-118vh,0) scale(1.1); opacity:0}
}
body.ovl #fizz, body.ovl #pops, body[data-fv] #fizz, body.no-anim #fizz, body.no-anim #pops{display:none}
/* while a game or the proxy browser is open, freeze every animation behind it */
body.ovl *, body.ovl *::before, body.ovl *::after{animation-play-state:paused !important}

/* click pops */
#pops{position:fixed; inset:0; z-index:45; pointer-events:none; overflow:hidden}
#pops i{
  position:absolute; width:var(--s); height:var(--s); margin:calc(var(--s) / -2) 0 0 calc(var(--s) / -2);
  border-radius:50%; border:1.5px solid rgba(255,255,255,.85);
  background:radial-gradient(circle at 30% 30%, rgba(255,255,255,.85), var(--bub));
  animation:popOut .6s cubic-bezier(.2,.7,.3,1) forwards;
}
@keyframes popOut{
  0%{transform:translate(0,0) scale(.4); opacity:1}
  70%{opacity:1}
  100%{transform:translate(var(--dx),var(--dy)) scale(1.6); opacity:0}
}

/* ---------------- header ---------------- */
#topbar{
  position:sticky; top:0; z-index:40;
  display:flex; align-items:center; gap:10px 16px; flex-wrap:wrap;
  padding:10px 22px 11px;
  background:linear-gradient(180deg,rgba(48,10,18,.94),var(--bar));
  backdrop-filter:blur(14px) saturate(1.2); -webkit-backdrop-filter:blur(14px) saturate(1.2);
  border-bottom:3px solid var(--acc-mid);
}
/* dripping cola edge under the header */
#topbar::after{
  content:""; position:absolute; left:0; right:0; top:100%; height:14px; pointer-events:none;
  background:linear-gradient(var(--acc-mid),var(--acc-deep));
  -webkit-mask:url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='160' height='14' viewBox='0 0 160 14'><path d='M0 0H160V4C150 4 148 12 140 12C132 12 130 4 120 4C108 4 106 9 98 9C90 9 88 4 76 4C68 4 66 14 58 14C50 14 48 4 36 4C28 4 26 8 20 8C12 8 10 4 0 4Z'/></svg>") repeat-x 0 0/160px 14px;
  mask:url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='160' height='14' viewBox='0 0 160 14'><path d='M0 0H160V4C150 4 148 12 140 12C132 12 130 4 120 4C108 4 106 9 98 9C90 9 88 4 76 4C68 4 66 14 58 14C50 14 48 4 36 4C28 4 26 8 20 8C12 8 10 4 0 4Z'/></svg>") repeat-x 0 0/160px 14px;
}
body[data-fv] #topbar::after{display:none}
.brand{display:flex; align-items:center; gap:12px; margin-right:auto; cursor:pointer; border-radius:999px}
.brand:hover .cap{transform:rotate(-14deg) scale(1.08)}
/* bottle cap around the rum-bottle logo */
.cap{
  flex:0 0 auto; width:52px; height:52px; border-radius:50%; display:grid; place-items:center;
  background:
    radial-gradient(circle at 50% 50%, #1b0a0f 0 55%, transparent 57%),
    repeating-conic-gradient(var(--gold) 0 9deg, var(--caramel) 9deg 18deg);
  box-shadow:0 4px 16px var(--glow), inset 0 0 0 2px rgba(255,255,255,.25);
  transition:transform .35s var(--spring);
}
.logo-img{width:40px; height:40px; display:block}
.cap .logo-img{width:32px; height:32px}
.brand h1{
  font-family:var(--disp); font-weight:700; font-size:1.34rem; letter-spacing:.2px; line-height:1.05; white-space:nowrap;
  text-shadow:0 2px 0 rgba(0,0,0,.45);
}
.brand h1 span{color:var(--acc2)}
.vchip{
  font-family:var(--disp); font-weight:600; font-size:.7rem; color:#fff; letter-spacing:.6px;
  background:var(--gel); padding:3px 10px; border-radius:999px; box-shadow:var(--gelsh);
  text-shadow:0 1px 2px rgba(60,0,8,.6); translate:0 -7px;
}
#tagline{font-size:.78rem; color:var(--muted); margin-top:3px}
.nav{
  display:flex; gap:4px; padding:5px; border-radius:999px; max-width:100%; overflow-x:auto; scrollbar-width:none;
  background:rgba(0,0,0,.45); border:2px solid var(--line);
  box-shadow:inset 0 2px 8px rgba(0,0,0,.65);
}
.nav::-webkit-scrollbar{display:none}
.nico{font-size:.95em; line-height:1}
.navlink{
  position:relative; display:inline-flex; align-items:center; gap:7px; flex:0 0 auto; white-space:nowrap;
  padding:8px 18px; border:none; background:transparent; color:var(--muted);
  font-family:var(--disp); font-size:.98rem; font-weight:600; letter-spacing:.2px; border-radius:999px; cursor:pointer;
  transition:transform .3s var(--spring), color .15s, background .15s;
}
.navlink:hover{color:var(--text); transform:translateY(-2px) scale(1.05)}
.navlink:active{transform:scale(.92)}
.navlink.active{background:var(--gel); color:#fff; box-shadow:var(--gelsh); text-shadow:0 1px 2px rgba(60,0,8,.6)}
.navlink.active::before{
  content:""; width:9px; height:9px; border-radius:50%; flex:0 0 auto;
  background:radial-gradient(circle at 32% 30%, #fff 0 22%, rgba(255,255,255,.35) 24% 60%, rgba(255,255,255,.1) 62%);
  box-shadow:0 0 0 1.5px rgba(255,255,255,.7);
}
.spark{display:inline-block; color:var(--gold); font-size:.95em; animation:twinkle 2.2s ease-in-out infinite}
.navlink.active .spark{color:#fff}
@keyframes twinkle{0%,100%{transform:scale(1) rotate(0); opacity:1}50%{transform:scale(1.35) rotate(24deg); opacity:.7}}
#settingsBtn{font-size:1.05rem; padding:0; width:44px; height:44px; border-radius:50%; display:grid; place-items:center}
#libTools{display:flex; align-items:center; gap:10px; flex-wrap:wrap}
body[data-view="home"] #libTools,
body[data-fv] #libTools{display:none}
/* iframe views (AI, Movies, Music): the frame fills everything under the header */
body[data-fv]{overflow:hidden}
#view-ai{position:relative}
#aiFrame{display:block; width:100%; height:calc(100vh - var(--topH,70px)); height:calc(100dvh - var(--topH,70px)); border:0; background:var(--bg)}
.aiload{
  position:absolute; inset:0; z-index:1; display:flex; flex-direction:column; align-items:center; justify-content:center; gap:16px;
  background:radial-gradient(600px 400px at 50% 40%, var(--wash), transparent 70%), var(--bg);
  font-family:var(--disp); font-size:1.1rem; color:var(--muted); pointer-events:none; transition:opacity .35s, visibility .35s;
}
.aiload.done{opacity:0; visibility:hidden}
.aiload.err{pointer-events:auto; padding:24px; text-align:center}
.aiload.err h2{margin:0; font-size:1.3rem; color:var(--text)}
.aiload.err p{margin:0; max-width:480px; font-family:system-ui,"Segoe UI",sans-serif; font-size:.95rem; line-height:1.55}
.aiload.err code{background:rgba(0,0,0,.4); padding:2px 9px; border-radius:999px; color:var(--acc2); font-size:.92em}
.ptbig{font-size:3rem; line-height:1}
.ptbtns{display:flex; flex-wrap:wrap; gap:12px; justify-content:center}
.ptbtns .cta{padding:11px 24px; font-size:1rem; text-decoration:none}
/* proxied tabs (Movies, Music): loader/error panel on top of the mounted proxy frame */
.ptwrap{position:relative; height:calc(100vh - var(--topH,70px)); height:calc(100dvh - var(--topH,70px))}
.ptmount{position:absolute; inset:0}
.ptmount iframe{display:block; width:100%; height:100%; border:0; background:#fff}
.aibub{
  width:54px; height:54px; border-radius:50%; border:2px solid rgba(255,255,255,.5);
  background:radial-gradient(circle at 30% 26%, #fff 0 8%, rgba(255,255,255,.25) 9% 22%, transparent 24%), radial-gradient(circle, var(--acc), var(--acc-deep));
  box-shadow:0 0 30px var(--glow); animation:bob 1.2s ease-in-out infinite;
}
.searchwrap{position:relative; flex:1 1 220px; max-width:400px}
.searchwrap svg{position:absolute; left:16px; top:50%; translate:0 -50%; width:16px; height:16px; stroke:var(--acc2); fill:none; stroke-width:2.4; stroke-linecap:round}
#search{
  width:100%; padding:11px 18px 11px 42px; border-radius:999px;
  border:2px solid var(--line); background:var(--glass),var(--panel); color:var(--text);
  box-shadow:inset 0 2px 6px rgba(0,0,0,.5);
  font-size:.95rem; outline:none; transition:border-color .15s, box-shadow .2s;
}
#search:focus{border-color:var(--acc); box-shadow:inset 0 2px 6px rgba(0,0,0,.5), 0 0 0 4px var(--glow-soft), 0 0 22px var(--glow-soft)}
#search::placeholder{color:#a8888b}
select#sort{
  appearance:none; -webkit-appearance:none;
  padding:11px 36px 11px 18px; border-radius:999px; border:2px solid var(--line);
  background:var(--glass),var(--panel) url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="10" height="6" viewBox="0 0 10 6"><path d="M1 1l4 4 4-4" stroke="%23ff6b7a" stroke-width="1.8" fill="none" stroke-linecap="round"/></svg>') no-repeat right 15px center;
  color:var(--text); font-size:.9rem; cursor:pointer; outline:none; transition:border-color .15s, transform .25s var(--spring);
}
select#sort:hover{border-color:var(--ring2); transform:translateY(-1px)}
select#sort:focus{border-color:var(--acc)}
select option{background:#1c0d12; color:#fff4ee}
.tool{
  padding:10px 16px; border-radius:999px; border:2px solid var(--line);
  background:var(--glass),var(--panel); color:var(--text); cursor:pointer; font-size:.92rem;
  transition:border-color .15s, background .15s, transform .3s var(--spring), box-shadow .2s; white-space:nowrap;
}
.tool:hover{border-color:var(--ring2); transform:translateY(-2px) scale(1.06); box-shadow:0 6px 16px var(--glow-soft)}
.tool:active{transform:scale(.9)}
.tool.on{border-color:transparent; color:#fff; background:var(--gel); box-shadow:var(--gelsh)}
.tool b{color:var(--acc2)}
.tool.on b{color:#fff}

/* ---------------- views ---------------- */
.view{display:none}
.view.active{display:block; animation:fadeUp .35s ease}
@keyframes fadeUp{from{opacity:0; transform:translateY(12px)}to{opacity:1; transform:none}}
.wrap{max-width:1280px; margin:0 auto; padding:26px 22px 80px}

/* ---------------- home / hero ---------------- */
#view-home .hero{
  position:relative; max-width:900px; margin:0 auto; padding:46px 22px 44px;
  display:flex; flex-direction:column; align-items:center; text-align:center;
}
.hero-bubbles{position:absolute; inset:0; pointer-events:none}
.hero-bubbles i{
  position:absolute; left:var(--x); top:var(--y); width:var(--s); height:var(--s); border-radius:50%;
  border:1.5px solid rgba(255,255,255,.3);
  background:
    radial-gradient(circle at 32% 28%, rgba(255,255,255,.8) 0 8%, rgba(255,255,255,.18) 9% 24%, transparent 26%),
    radial-gradient(circle at 50% 50%, transparent 50%, var(--bub) 100%);
  animation:bob var(--d) ease-in-out infinite;
}
.hero > *:not(.hero-bubbles){position:relative}
.hero-logo{width:min(150px,36vw); margin-bottom:14px; animation:bob 3.4s ease-in-out infinite}
.hero-logo .logo-img{width:100%; height:auto; aspect-ratio:1/1; filter:drop-shadow(0 10px 30px var(--glow))}
@keyframes bob{0%,100%{transform:translateY(0)}50%{transform:translateY(-10px)}}
.eyebrow{
  display:inline-flex; align-items:center; gap:10px; margin-bottom:10px;
  padding:6px 18px; border-radius:999px; font-family:var(--disp); font-weight:600; font-size:.95rem; letter-spacing:.4px;
  color:var(--gold); background:rgba(255,196,107,.09); border:1.5px dashed rgba(255,196,107,.5);
}
.eyebrow .spark{font-size:.8em}
.hero h2{
  font-family:var(--disp); font-weight:700; line-height:.98; letter-spacing:.02em;
  font-size:clamp(2.7rem,10.5vw,6rem); margin-bottom:12px;
  display:flex; flex-wrap:wrap; justify-content:center; gap:0 .26em;
}
.hero h2 span{
  display:inline-block;
  background:linear-gradient(180deg,#fff4ee 0 7%,#ff8f9b 15%,#ff3b4e 42%,#e11d2e 63%,#9d0c1a 100%);
  -webkit-background-clip:text; background-clip:text; -webkit-text-fill-color:transparent; color:transparent;
  filter:drop-shadow(0 5px 0 #4b050e) drop-shadow(0 0 22px var(--glow));
  transition:transform .4s var(--spring);
}
body[data-theme="purple"] .hero h2 span{
  background:linear-gradient(180deg,#f4f2ff 0 7%,#c4baff 15%,#9d8cff 42%,#5e46e8 63%,#2c1a8c 100%);
  -webkit-background-clip:text; background-clip:text;
  filter:drop-shadow(0 5px 0 #170b52) drop-shadow(0 0 22px var(--glow));
}
.hero h2 span:hover{transform:translateY(-5px) rotate(-2deg) scale(1.04)}
.hero-tag{color:var(--muted); font-size:1.02rem; margin-bottom:28px; max-width:520px; line-height:1.5}
.hero-tag b{color:var(--foam)}

.psearch{
  display:flex; align-items:center; gap:8px; width:min(680px,100%);
  padding:8px 8px 8px 22px; border-radius:999px;
  background:var(--glass),var(--panel); border:2.5px solid var(--ring2);
  box-shadow:inset 0 2px 0 rgba(255,255,255,.14), inset 0 -4px 10px rgba(0,0,0,.45), 0 12px 40px var(--glow-soft);
  transition:border-color .15s, box-shadow .2s, transform .3s var(--spring);
}
.psearch:focus-within{border-color:var(--acc); transform:scale(1.015); box-shadow:inset 0 2px 0 rgba(255,255,255,.14), inset 0 -4px 10px rgba(0,0,0,.45), 0 0 0 5px var(--glow-soft), 0 14px 46px var(--glow)}
.psearch svg{width:20px; height:20px; stroke:var(--acc2); fill:none; stroke-width:2.4; stroke-linecap:round; flex:0 0 auto}
#pInput{
  flex:1; min-width:0; background:none; border:none; outline:none;
  color:var(--text); font-size:1.08rem; padding:13px 0;
}
#pInput::placeholder{color:#a8888b}
.enginesel{
  appearance:none; -webkit-appearance:none; flex:0 0 auto;
  padding:10px 30px 10px 15px; border-radius:999px; border:2px solid var(--line);
  background:var(--card) url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="10" height="6" viewBox="0 0 10 6"><path d="M1 1l4 4 4-4" stroke="%23ff6b7a" stroke-width="1.8" fill="none" stroke-linecap="round"/></svg>') no-repeat right 12px center;
  color:var(--text); font-size:.82rem; cursor:pointer; outline:none;
}
.enginesel:focus-visible{border-color:var(--acc)}
.gobtn{
  flex:0 0 auto; width:54px; height:54px; border-radius:50%; border:none; cursor:pointer;
  background:var(--gel); color:#fff; font-size:1.3rem; font-weight:700;
  box-shadow:var(--gelsh); text-shadow:0 1px 2px rgba(60,0,8,.6);
  transition:transform .3s var(--spring), filter .13s;
}
.gobtn:hover{filter:brightness(1.1); transform:scale(1.1) rotate(-6deg)}
.gobtn:active{transform:scale(.88)}
.gobtn:disabled{opacity:.5; cursor:wait}

.pstatus{min-height:22px; margin-top:14px; font-size:.88rem; color:var(--acc2); display:flex; align-items:center; justify-content:center; gap:8px}
.pstatus:not(:empty)::before{
  content:""; width:10px; height:10px; border-radius:50%; flex:0 0 auto;
  background:radial-gradient(circle at 32% 30%, #fff 0 20%, var(--acc) 22%);
  animation:pulseB 1s ease-in-out infinite;
}
@keyframes pulseB{0%,100%{transform:scale(.7); opacity:.6}50%{transform:scale(1.25); opacity:1}}
.bar-track{width:min(440px,80%); height:12px; border-radius:99px; background:rgba(0,0,0,.5); border:1.5px solid var(--line); overflow:hidden; opacity:0; transition:opacity .2s; margin:8px auto 0}
.bar-track.on{opacity:1}
#pBar{
  height:100%; width:0%; border-radius:99px; transition:width .3s;
  background:
    radial-gradient(circle at 8px 50%, rgba(255,255,255,.55) 0 2px, transparent 3px) 0 0/22px 100%,
    linear-gradient(90deg,var(--acc-deep),var(--acc),var(--acc2));
  animation:fizzBar 1.2s linear infinite;
}
@keyframes fizzBar{to{background-position:22px 0,0 0}}
.perror{max-width:560px; margin:10px auto 0; font-size:.88rem; color:var(--err); word-break:break-word}

.chips{display:flex; flex-wrap:wrap; gap:12px; justify-content:center; margin-top:28px}
.chip{
  display:inline-flex; align-items:center; gap:8px;
  padding:10px 20px; border-radius:999px; border:2px solid var(--ring);
  background:
    radial-gradient(circle at 22% 18%, rgba(255,255,255,.3) 0 9%, transparent 10%),
    linear-gradient(180deg,var(--card2),var(--card));
  color:var(--text); font-family:var(--disp); font-weight:500; font-size:.96rem; cursor:pointer;
  box-shadow:inset 0 -3px 0 rgba(0,0,0,.3), 0 4px 12px rgba(0,0,0,.35);
  transition:border-color .15s, transform .3s var(--spring), background .15s, box-shadow .2s;
}
.chip:hover{border-color:var(--acc); transform:translateY(-4px) rotate(-3deg) scale(1.07); box-shadow:inset 0 -3px 0 rgba(0,0,0,.3), 0 10px 22px var(--glow-soft)}
.chip:nth-child(even):hover{transform:translateY(-4px) rotate(3deg) scale(1.07)}
.chip:active{transform:scale(.9)}
.homeCtas{display:flex; gap:12px; flex-wrap:wrap; justify-content:center; margin-top:32px}
.cta{
  position:relative; overflow:hidden; isolation:isolate;
  display:inline-flex; align-items:center; gap:10px;
  padding:15px 34px; border-radius:999px; border:2px solid var(--line);
  background:var(--glass),var(--panel); color:var(--text); font-family:var(--disp); font-size:1.15rem; font-weight:700; letter-spacing:.3px; cursor:pointer;
  transition:border-color .15s, transform .3s var(--spring), box-shadow .2s;
}
.cta:hover{border-color:var(--acc); transform:translateY(-4px) scale(1.06)}
.cta:active{transform:scale(.93)}
.cta.red{background:var(--gel); border-color:transparent; color:#fff; box-shadow:var(--gelsh), 0 0 0 0 var(--glow); text-shadow:0 1px 3px rgba(60,0,8,.65); animation:ctaPulse 2.4s ease-in-out infinite}
.cta.red:hover{filter:brightness(1.08)}
@keyframes ctaPulse{0%,100%{box-shadow:var(--gelsh), 0 0 0 0 var(--glow)}50%{box-shadow:var(--gelsh), 0 0 0 10px rgba(255,59,78,0)}}
/* fizz inside the CTA */
.cta.red::before{
  content:""; position:absolute; left:0; right:0; top:0; height:200%; z-index:-1; pointer-events:none;
  background-image:
    radial-gradient(circle at 12% 60%, rgba(255,255,255,.75) 0 2px, transparent 3px),
    radial-gradient(circle at 30% 25%, rgba(255,255,255,.55) 0 1.5px, transparent 2.5px),
    radial-gradient(circle at 52% 80%, rgba(255,255,255,.7) 0 2.5px, transparent 3.5px),
    radial-gradient(circle at 70% 40%, rgba(255,255,255,.5) 0 1.5px, transparent 2.5px),
    radial-gradient(circle at 88% 70%, rgba(255,255,255,.7) 0 2px, transparent 3px);
  background-size:100% 50%; background-repeat:repeat-y;
  animation:sparkUp 2.6s linear infinite;
}
@keyframes sparkUp{from{transform:translateY(0)}to{transform:translateY(-50%)}}
.homeStats{display:flex; gap:10px; flex-wrap:wrap; justify-content:center; margin-top:28px}
.stat{
  font-size:.82rem; color:var(--muted);
  background:linear-gradient(180deg,rgba(255,196,107,.16),rgba(255,196,107,.04));
  border:1.5px solid rgba(255,196,107,.38); padding:6px 15px; border-radius:999px;
  box-shadow:inset 0 1px 0 rgba(255,255,255,.12);
}
.stat b{color:var(--gold); font-family:var(--disp); font-size:.95rem}

/* liquid wave + cola pool below the hero */
.liquid{position:relative; margin-top:6px}
.wave{position:relative; height:64px; overflow:hidden; line-height:0; margin-bottom:-1px}
.wave svg{position:absolute; left:0; top:0; display:block; width:200%; height:100%; animation:slosh 14s linear infinite}
.wave svg.back{animation-duration:22s; animation-direction:reverse}
.wave path{fill:var(--liquid-top)}
.wave .back path{fill:var(--liquid-back)}
@keyframes slosh{to{transform:translateX(-50%)}}
.pool{background:linear-gradient(180deg,var(--liquid-top),rgba(0,0,0,0) 380px); padding:6px 0 30px}
.featured{max-width:1280px; margin:0 auto; padding:6px 22px 0; width:100%}

/* ---------------- sections / cards ---------------- */
#recentSec{margin-bottom:28px}
.sechead{display:flex; align-items:center; gap:12px; margin-bottom:12px}
.sechead h2{display:flex; align-items:center; gap:10px; font-family:var(--disp); font-size:1.35rem; font-weight:700; letter-spacing:.3px; white-space:nowrap}
.sechead .accent{
  display:inline-grid; place-items:center; width:32px; height:32px; border-radius:50%; flex:0 0 auto;
  font-size:.85rem; color:#fff;
  background:
    radial-gradient(circle at 30% 26%, #fff 0 7%, rgba(255,255,255,.28) 8% 19%, transparent 21%),
    radial-gradient(circle at 50% 50%, var(--acc), var(--acc-deep));
  box-shadow:0 3px 12px var(--glow), inset 0 -3px 5px rgba(0,0,0,.28);
}
.sechead::after{
  content:""; flex:1; height:10px; opacity:.6; order:1;
  background:url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="24" height="10" viewBox="0 0 24 10"><path d="M0 5Q6 0 12 5T24 5" stroke="%23ff6b7a" stroke-width="2" fill="none" stroke-linecap="round"/></svg>') repeat-x 0 50%/24px 10px;
}
#clearRecent{order:2; background:none; border:1.5px solid var(--line); color:var(--muted); font-size:.8rem; cursor:pointer; padding:5px 14px; border-radius:999px; transition:all .25s var(--spring)}
#clearRecent:hover{color:var(--text); border-color:var(--ring2); transform:scale(1.07)}
#allCount{
  font-family:var(--disp); font-size:.8rem; font-weight:600; color:var(--gold);
  background:rgba(255,196,107,.1); border:1.5px solid rgba(255,196,107,.38); border-radius:999px; padding:2px 12px;
}
.row{display:flex; gap:16px; overflow-x:auto; padding:14px 6px 18px; scrollbar-width:thin; scrollbar-color:var(--acc-deep) transparent}
.row .game{flex:0 0 156px; width:156px}

.grid{display:grid; gap:20px; grid-template-columns:repeat(auto-fill,minmax(164px,1fr))}
body[data-cards="s"] .grid{grid-template-columns:repeat(auto-fill,minmax(122px,1fr)); gap:14px}
body[data-cards="s"] .row .game{flex-basis:122px; width:122px}
body[data-cards="l"] .grid{grid-template-columns:repeat(auto-fill,minmax(214px,1fr))}
body[data-cards="l"] .row .game{flex-basis:196px; width:196px}
.game{
  position:relative; border-radius:26px; overflow:hidden; cursor:pointer;
  background:linear-gradient(180deg,var(--card2),var(--card)); border:2px solid var(--line);
  box-shadow:0 6px 16px rgba(0,0,0,.4), inset 0 1px 0 rgba(255,255,255,.08);
  opacity:0; translate:0 18px;
  transition:opacity .5s ease, translate .6s var(--spring), transform .3s var(--spring), border-color .2s ease, box-shadow .25s ease;
}
.game.in{opacity:1; translate:0 0}
.game:hover{
  transform:translateY(-6px) scale(1.035); border-color:var(--acc);
  box-shadow:0 0 0 2px var(--ring2), 0 18px 40px rgba(0,0,0,.6), 0 0 36px var(--glow);
  animation:wobble .6s ease-out;
}
.game:active{transform:scale(.97)}
@keyframes wobble{
  0%{transform:translateY(0) scale(1) rotate(0)}
  30%{transform:translateY(-8px) scale(1.05) rotate(-2.2deg)}
  60%{transform:translateY(-6px) scale(1.04) rotate(1.6deg)}
  100%{transform:translateY(-6px) scale(1.035) rotate(0)}
}
.game.own{border-color:rgba(255,196,107,.5)}
.thumb{position:relative; aspect-ratio:1/1; overflow:hidden; background:radial-gradient(circle at 30% 20%, rgba(255,255,255,.08), transparent 55%), linear-gradient(160deg,#2a1218,#14080b)}
/* shimmer while a cover is loading (only for cards near the viewport) */
.game.in .thumb.ld{background:linear-gradient(110deg,#1c0d12 30%,#3a1820 50%,#1c0d12 70%); background-size:220% 100%; animation:shimmer 1.3s linear infinite}
@keyframes shimmer{from{background-position:120% 0}to{background-position:-120% 0}}
.thumb img{
  position:absolute; inset:0; width:100%; height:100%; object-fit:cover;
  opacity:0; transition:opacity .4s ease, transform .35s var(--spring); z-index:1;
}
.thumb img.ok{opacity:1}
.game:hover .thumb img.ok{transform:scale(1.08)}
/* glossy highlight */
.thumb::before{
  content:""; position:absolute; left:-10%; right:-10%; top:-6%; height:46%; z-index:2; pointer-events:none;
  border-radius:0 0 50% 50% / 0 0 100% 100%;
  background:linear-gradient(180deg,rgba(255,255,255,.2),rgba(255,255,255,0));
}
/* fizz sparkle on hover */
.thumb::after{
  content:""; position:absolute; left:0; right:0; top:0; height:200%; z-index:2; pointer-events:none; opacity:0;
  background-image:
    radial-gradient(circle at 16% 78%, rgba(255,255,255,.9) 0 1.5px, rgba(255,255,255,.25) 2.5px, transparent 4px),
    radial-gradient(circle at 38% 40%, rgba(255,255,255,.8) 0 1px, rgba(255,255,255,.2) 2px, transparent 3.5px),
    radial-gradient(circle at 62% 90%, rgba(255,255,255,.9) 0 2px, rgba(255,255,255,.25) 3px, transparent 5px),
    radial-gradient(circle at 82% 55%, rgba(255,255,255,.8) 0 1.5px, rgba(255,255,255,.2) 2.5px, transparent 4px),
    radial-gradient(circle at 50% 18%, rgba(255,255,255,.7) 0 1px, transparent 3px);
  background-size:100% 50%; background-repeat:repeat-y;
  transition:opacity .2s;
}
.game:hover .thumb::after{opacity:1; animation:sparkUp 1.8s linear infinite}
.fallback{
  position:absolute; inset:0; display:flex; flex-direction:column; gap:4px;
  align-items:center; justify-content:center; color:#8a5a62;
}
.fallback .fe{font-size:2.1rem}
.fallback .fn{
  font-family:var(--disp); font-weight:600; font-size:1.02rem; color:#c79aa2; max-width:90%; line-height:1.25;
  display:-webkit-box; -webkit-line-clamp:2; -webkit-box-orient:vertical; overflow:hidden;
}
/* home-made games: no cover art - big emoji tile instead */
.game.own .thumb{background:radial-gradient(circle at 50% 42%, var(--glow), transparent 72%), linear-gradient(160deg,#3a1520,#14080b)}
.game.own .fallback .fe{font-size:3.5rem}
.game.own .fallback .fn{font-size:1.06rem; color:var(--gold)}
/* bottle-cap badge for home-made games */
.own-badge{
  position:absolute; top:8px; right:8px; z-index:3; width:32px; height:32px; border-radius:50%;
  display:grid; place-items:center; font-size:.8rem; pointer-events:none;
  background:
    radial-gradient(circle at 50% 50%, var(--acc-mid) 0 56%, transparent 58%),
    repeating-conic-gradient(#ffd98f 0 9deg, #d99a45 9deg 18deg);
  box-shadow:0 3px 10px rgba(0,0,0,.5), 0 0 12px var(--glow);
  transition:transform .4s var(--spring);
}
.game:hover .own-badge{transform:rotate(40deg) scale(1.12)}
.play{
  position:absolute; inset:0; z-index:2; display:flex; align-items:center; justify-content:center;
  background:linear-gradient(180deg, rgba(10,3,6,0) 30%, rgba(10,3,6,.8));
  opacity:0; transition:opacity .18s ease;
}
.game:hover .play{opacity:1}
.play span{
  background:var(--gel); color:#fff; font-family:var(--disp); font-weight:700; font-size:.95rem; letter-spacing:.3px;
  padding:9px 22px; border-radius:999px; translate:0 12px; transition:translate .3s var(--spring);
  box-shadow:var(--gelsh); text-shadow:0 1px 2px rgba(60,0,8,.6);
}
.game:hover .play span{translate:0 0}
.meta{display:flex; align-items:center; justify-content:space-between; gap:6px; padding:11px 14px 13px}
.num{font-family:var(--disp); font-weight:600; font-size:1rem; flex:1 1 auto; min-width:0; overflow:hidden; text-overflow:ellipsis; white-space:nowrap}
.suffix{
  flex:0 0 auto; font-size:.68rem; color:var(--gold); background:rgba(255,196,107,.09);
  border:1px solid rgba(255,196,107,.34); padding:2px 9px; border-radius:999px;
  overflow:hidden; text-overflow:ellipsis; white-space:nowrap; max-width:70%;
}
/* bubbly favourite heart */
.favbtn{
  position:absolute; top:8px; left:8px; z-index:3;
  width:34px; height:34px; border-radius:50%; font-size:1rem; line-height:1;
  border:1.5px solid rgba(255,255,255,.4); color:var(--foam); cursor:pointer;
  background:
    radial-gradient(circle at 30% 26%, rgba(255,255,255,.55) 0 10%, rgba(255,255,255,.12) 11% 30%, transparent 32%),
    rgba(20,6,10,.55);
  backdrop-filter:blur(6px); -webkit-backdrop-filter:blur(6px);
  opacity:0; transition:opacity .15s, color .15s, border-color .15s, transform .3s var(--spring), background .15s;
}
.game:hover .favbtn, .favbtn.on, .favbtn:focus-visible{opacity:1}
.favbtn:hover{transform:scale(1.2)}
.favbtn:active{transform:scale(.85)}
.favbtn.on{
  color:#fff; border-color:rgba(255,255,255,.7); text-shadow:0 1px 2px rgba(60,0,8,.7);
  background:
    radial-gradient(circle at 30% 26%, rgba(255,255,255,.7) 0 10%, rgba(255,255,255,.14) 11% 30%, transparent 32%),
    radial-gradient(circle at 50% 50%, var(--acc), var(--acc-deep));
  box-shadow:0 0 14px var(--glow);
  animation:heartPop .45s var(--spring);
}
@keyframes heartPop{0%{transform:scale(.6)}60%{transform:scale(1.35)}100%{transform:scale(1)}}

#empty{display:none; text-align:center; color:var(--muted); margin-top:56px; font-size:1.05rem; line-height:1.7}
#empty::before{content:"\1F964"; display:block; font-size:3.4rem; margin-bottom:8px; animation:bob 3s ease-in-out infinite}
#empty b{color:var(--foam)}

/* ---------------- game player ---------------- */
#player{position:fixed; inset:0; z-index:100; display:none; flex-direction:column; background:#070304}
#player.active{display:flex}
.pbar, .bbar{
  display:flex; align-items:center; gap:8px; flex-wrap:wrap;
  padding:10px 14px; background:linear-gradient(180deg,#2a0c14,#16070b);
  border-bottom:3px solid var(--acc-mid);
}
.pbar button, .pbar a{
  padding:8px 16px; border-radius:999px; border:2px solid var(--line);
  background:var(--glass),var(--card); color:var(--text); cursor:pointer; font-size:.9rem; text-decoration:none;
  display:inline-flex; align-items:center; justify-content:center;
  transition:border-color .15s, background .15s, transform .3s var(--spring); white-space:nowrap;
}
.pbar button:hover, .pbar a:hover{border-color:var(--acc); transform:translateY(-2px) scale(1.06)}
.pbar button:active{transform:scale(.92)}
.pbar button:disabled{opacity:.32; cursor:default}
.pbar button:disabled:hover{border-color:var(--line); transform:none}
.pbar #closeBtn:hover{background:var(--gel); border-color:transparent}
#pTitle{flex:1 1 140px; text-align:center; font-family:var(--disp); font-weight:600; font-size:1.05rem; min-width:100px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis}
#pTitle .suffix{font-family:var(--body); font-size:.7rem; font-weight:400; margin-left:8px}
#favBtn.on{color:#fff; background:var(--gel); border-color:transparent; box-shadow:var(--gelsh)}
#frame{flex:1; width:100%; border:0; background:#000}

/* ---------------- proxy browser ---------------- */
#browse{position:fixed; inset:0; z-index:90; display:none; flex-direction:column; background:#0b0507}
#browse.active{display:flex}
.bbar{gap:7px; padding:9px 12px}
.bbar button{
  width:40px; height:40px; border-radius:50%; border:2px solid var(--line);
  background:var(--glass),var(--card); color:var(--text); cursor:pointer; font-size:.98rem;
  transition:border-color .15s, background .15s, transform .3s var(--spring); flex:0 0 auto;
}
.bbar button:hover{border-color:var(--acc); transform:translateY(-2px) scale(1.1)}
.bbar button:active{transform:scale(.88)}
.baddrwrap{
  flex:1 1 220px; display:flex; align-items:center; gap:8px; min-width:160px;
  background:var(--glass),var(--panel); border:2px solid var(--ring); border-radius:999px; padding:4px 5px 4px 16px;
  box-shadow:inset 0 2px 6px rgba(0,0,0,.5);
}
.baddrwrap:focus-within{border-color:var(--acc); box-shadow:inset 0 2px 6px rgba(0,0,0,.5), 0 0 0 4px var(--glow-soft)}
.baddrwrap .lock{font-size:.78rem; opacity:.85}
#bAddr{flex:1; min-width:0; background:none; border:none; outline:none; color:var(--text); font-size:.92rem; padding:7px 0}
#bGo{width:auto !important; height:34px !important; padding:0 18px !important; border-radius:999px !important; font-family:var(--disp); font-size:.88rem !important; font-weight:700; background:var(--gel) !important; border-color:transparent !important; color:#fff !important; box-shadow:var(--gelsh); text-shadow:0 1px 2px rgba(60,0,8,.6)}
#bFrameWrap{flex:1; position:relative; background:#fff}
#bFrameWrap iframe{position:absolute; inset:0; width:100%; height:100%; border:0; background:#fff}

/* ---------------- settings modal ---------------- */
#settingsModal{position:fixed; inset:0; z-index:150; display:none; align-items:center; justify-content:center; padding:20px}
#settingsModal.active{display:flex}
.sback{position:absolute; inset:0; background:rgba(8,2,4,.74); backdrop-filter:blur(6px); -webkit-backdrop-filter:blur(6px)}
.spanel{
  position:relative; width:min(580px,100%); max-height:min(88vh,740px);
  display:flex; flex-direction:column; overflow:hidden;
  background:var(--glass),var(--panel); border:2.5px solid var(--ring2); border-radius:32px;
  box-shadow:0 30px 80px rgba(0,0,0,.65), 0 0 50px var(--glow-soft), inset 0 1px 0 rgba(255,255,255,.12);
  animation:pop .4s var(--spring);
}
@keyframes pop{from{opacity:0; transform:scale(.88) translateY(14px)}to{opacity:1; transform:none}}
.shead{display:flex; align-items:center; justify-content:space-between; padding:16px 22px; background:linear-gradient(180deg,#2e0d16,rgba(0,0,0,0)); border-bottom:2px dashed var(--ring)}
.shead h2{font-family:var(--disp); font-size:1.3rem; font-weight:700}
.shead h2 .accent{color:var(--acc2)}
#sClose{
  width:38px; height:38px; border-radius:50%; border:2px solid var(--line);
  background:var(--glass),var(--card); color:var(--text); cursor:pointer; font-size:.9rem;
  transition:transform .3s var(--spring), border-color .15s, color .15s;
}
#sClose:hover{border-color:var(--err); color:var(--err); transform:rotate(90deg) scale(1.1)}
.sbody{overflow-y:auto; padding:4px 22px 22px}
.ssec{padding:16px 0; border-bottom:2px dashed var(--line)}
.ssec:last-child{border-bottom:none; padding-bottom:6px}
.ssec h3{font-family:var(--disp); font-size:.82rem; font-weight:600; letter-spacing:1.6px; text-transform:uppercase; color:var(--gold); margin-bottom:12px}
.srow{display:flex; align-items:center; justify-content:space-between; gap:14px; padding:7px 0}
.srow .lab{font-size:.95rem}
.srow .sub{display:block; font-size:.78rem; color:var(--muted); margin-top:2px; font-weight:400}
.srow.minrow{padding:12px 14px; margin-bottom:12px; background:var(--card); border:2px solid var(--ring); border-radius:18px}
.srow.minrow .lab{font-weight:600}
.sbody select{
  appearance:none; -webkit-appearance:none;
  padding:9px 34px 9px 16px; border-radius:999px; border:2px solid var(--line);
  background:var(--card) url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="10" height="6" viewBox="0 0 10 6"><path d="M1 1l4 4 4-4" stroke="%23ff6b7a" stroke-width="1.8" fill="none" stroke-linecap="round"/></svg>') no-repeat right 13px center;
  color:var(--text); font-size:.88rem; cursor:pointer; outline:none;
}
.sbody select:focus{border-color:var(--acc)}
.swatches{display:flex; gap:10px; flex-wrap:wrap}
.swatch{
  display:flex; align-items:center; gap:10px; padding:10px 18px 10px 12px; border-radius:999px;
  border:2px solid var(--line); background:var(--card); color:var(--text);
  cursor:pointer; font-family:var(--disp); font-weight:500; font-size:.95rem; transition:border-color .15s, box-shadow .15s, transform .3s var(--spring);
}
.swatch:hover{border-color:var(--ring2); transform:translateY(-2px) scale(1.04)}
.swatch .dot{
  width:22px; height:22px; border-radius:50%; flex:0 0 auto; box-shadow:inset 0 -3px 4px rgba(0,0,0,.3);
}
.swatch[data-t="purple"] .dot{background:radial-gradient(circle at 30% 26%, #fff 0 10%, transparent 12%), linear-gradient(135deg,#9d8cff,#3d27b0)}
.swatch[data-t="red"] .dot{background:radial-gradient(circle at 30% 26%, #fff 0 10%, transparent 12%), linear-gradient(135deg,#ff3b4e,#b30f1e)}
.swatch.on{border-color:var(--acc); box-shadow:0 0 0 4px var(--tint)}
.tgl{
  position:relative; width:54px; height:30px; border-radius:99px; flex:0 0 auto;
  background:rgba(0,0,0,.5); border:2px solid var(--line); box-shadow:inset 0 2px 5px rgba(0,0,0,.6); cursor:pointer; transition:background .2s, border-color .2s;
}
.tgl::after{
  content:""; position:absolute; top:2px; left:2px; width:22px; height:22px; border-radius:50%;
  background:radial-gradient(circle at 32% 28%, #fff 0 12%, #c9a3a6 14%); transition:left .35s var(--spring);
}
.tgl.on{background:var(--gel); border-color:transparent}
.tgl.on::after{left:26px; background:radial-gradient(circle at 32% 28%, #fff 0 14%, #ffe3e6 16%)}
.wrow{display:flex; gap:8px; width:100%}
.wrow input{
  flex:1; min-width:0; padding:9px 16px; border-radius:999px; border:2px solid var(--line);
  background:var(--card); color:var(--text); font-size:.88rem; outline:none;
}
.wrow input:focus{border-color:var(--acc)}
.wout{display:block; min-height:18px; font-size:.82rem; color:var(--muted); margin-top:8px; word-break:break-all}
.wout.good{color:#8cf0a0}
.wout.bad{color:var(--err)}
.sbtn{
  padding:9px 18px; border-radius:999px; border:2px solid var(--line);
  background:var(--glass),var(--card); color:var(--text); font-size:.88rem; cursor:pointer;
  transition:border-color .15s, background .15s, transform .3s var(--spring);
}
.sbtn:hover{border-color:var(--acc); transform:translateY(-2px) scale(1.04)}
.sbtn:active{transform:scale(.93)}
.sbtn.danger{color:var(--err); border-color:rgba(255,120,135,.4)}
.sbtn.danger:hover{background:rgba(255,90,110,.1); border-color:var(--err)}
.sbtnrow{display:flex; gap:8px; flex-wrap:wrap}
.about{font-size:.88rem; color:var(--muted); line-height:1.85}
.about a{color:var(--acc2); text-decoration:none}
.about a:hover{text-decoration:underline}
.about b{color:var(--text)}

/* ---------------- misc ---------------- */
footer{
  position:relative; margin-top:18px; padding:44px 22px 32px; text-align:center;
  color:var(--muted); font-size:.84rem; line-height:1.9; background:linear-gradient(180deg,rgba(0,0,0,0),rgba(0,0,0,.45));
}
footer::before{
  content:""; position:absolute; left:0; right:0; top:0; height:14px; opacity:.85;
  background:linear-gradient(var(--acc-deep),var(--liquid-back));
  -webkit-mask:url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='40' height='14' viewBox='0 0 40 14'><path d='M0 14V7Q10 0 20 7T40 7V14Z'/></svg>") repeat-x 0 0/40px 14px;
  mask:url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='40' height='14' viewBox='0 0 40 14'><path d='M0 14V7Q10 0 20 7T40 7V14Z'/></svg>") repeat-x 0 0/40px 14px;
}
footer b{color:var(--foam); font-family:var(--disp)}
footer a{color:var(--acc2); text-decoration:none}
footer a:hover{text-decoration:underline}
#toTop{
  position:fixed; right:22px; bottom:22px; z-index:60;
  width:48px; height:48px; border-radius:50%; border:none; color:#5a0610; font-size:1.2rem; font-weight:700; cursor:pointer;
  background:
    radial-gradient(circle at 50% 50%, var(--foam) 0 58%, transparent 60%),
    repeating-conic-gradient(var(--gold) 0 9deg, var(--caramel) 9deg 18deg);
  box-shadow:0 6px 18px rgba(0,0,0,.5), 0 0 16px var(--glow-soft);
  opacity:0; pointer-events:none; transform:scale(.6); transition:opacity .2s, transform .35s var(--spring);
}
#toTop.show{opacity:1; pointer-events:auto; transform:none}
#toTop.show:hover{transform:translateY(-4px) rotate(-12deg) scale(1.1)}
#toast{
  position:fixed; left:50%; bottom:26px; translate:-50% 24px; z-index:200;
  padding:11px 24px; border-radius:999px; border:2px solid rgba(255,255,255,.35);
  background:var(--gel); color:#fff; font-family:var(--disp); font-weight:500; font-size:.95rem; text-shadow:0 1px 2px rgba(60,0,8,.6);
  box-shadow:var(--gelsh), 0 14px 34px rgba(0,0,0,.5); max-width:calc(100vw - 32px);
  opacity:0; pointer-events:none; transition:opacity .2s, translate .4s var(--spring);
}
#toast.show{opacity:1; translate:-50% 0}
::-webkit-scrollbar{width:11px; height:11px}
::-webkit-scrollbar-thumb{background:var(--acc-deep); border-radius:8px; border:2px solid var(--bg)}
::-webkit-scrollbar-thumb:hover{background:var(--acc-mid)}
::-webkit-scrollbar-track{background:transparent}
body.no-anim *, body.no-anim *::before, body.no-anim *::after{animation:none !important; transition:none !important}
@media (max-width:760px){
  #topbar{padding:10px 14px 11px; gap:10px}
  #tagline{display:none}
  .brand h1{font-size:1.15rem}
  #settingsBtn{order:2}
  .nav{order:3; width:100%; justify-content:center}
  .navlink{flex:1 0 auto; justify-content:center; padding:8px 10px}
  #libTools{order:4; width:100%}
  .searchwrap{max-width:none; flex:1 1 100%}
  .wrap{padding:20px 14px 70px}
  .featured{padding:6px 14px 0}
  #view-home .hero{padding:30px 16px 36px}
  .grid{gap:14px}
  .game{border-radius:22px}
  .sechead h2{font-size:1.15rem}
  .wave{height:44px}
}
@media (max-width:520px){
  .nav{gap:2px; padding:4px}
  .navlink{padding:8px 9px; gap:4px; font-size:.86rem}
  .navlink.active::before{display:none}
  .psearch{padding:7px 7px 7px 16px; gap:6px}
  .psearch svg{display:none}
  .enginesel{max-width:38%; padding:9px 26px 9px 12px}
  .gobtn{width:48px; height:48px}
  .srow{flex-wrap:wrap}
  .spanel{border-radius:26px}
  .cta{padding:14px 28px}
}
@media (max-width:380px){
  .navlink{padding:8px 7px; font-size:.8rem; gap:3px}
}
@media (hover:none){
  .favbtn{opacity:1}
}
@media (prefers-reduced-motion: reduce){
  html{scroll-behavior:auto}
  *, *::before, *::after{animation:none !important; transition:none !important}
  #fizz, #pops{display:none}
}

/* =====================================================================
   Minimalistic Site (Less LAG): html.minimal
   Flat solid colours, 1px borders, small radii, system font, no animation,
   no gradients/glows/shadows/blur/masks and no decorative layers.
   ===================================================================== */
html.minimal{
  scroll-behavior:auto;
  --sys:system-ui,-apple-system,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
  --disp:var(--sys); --body:var(--sys);
  --gel:var(--acc-mid); --gelsh:none; --glass:none;
}
html.minimal *, html.minimal *::before, html.minimal *::after{
  animation:none !important; transition:none !important;
  box-shadow:none !important; text-shadow:none !important;
  filter:none !important; backdrop-filter:none !important; -webkit-backdrop-filter:none !important;
  -webkit-mask:none !important; mask:none !important;
}
html.minimal *:hover, html.minimal *:active{transform:none !important}
/* decorative layers */
html.minimal #fizz, html.minimal #pops, html.minimal .hero-bubbles, html.minimal .wave, html.minimal .spark,
html.minimal .aibub, html.minimal #topbar::after, html.minimal footer::before, html.minimal .sechead::after,
html.minimal .cta.red::before, html.minimal .navlink.active::before, html.minimal .thumb::before, html.minimal .thumb::after,
html.minimal .pstatus:not(:empty)::before, html.minimal #empty::before{display:none !important}
/* background and header */
html.minimal body{background:var(--bg); background-image:none; background-attachment:scroll}
html.minimal #topbar{background:var(--bg2); border-bottom:1px solid var(--acc-mid)}
html.minimal .cap{background:none; width:40px; height:40px; border-radius:0}
html.minimal .vchip{background:var(--acc-mid); translate:none}
html.minimal .nav{background:var(--bg); border:1px solid var(--line)}
html.minimal .navlink.active, html.minimal .tool.on, html.minimal #favBtn.on, html.minimal .cta.red{background:var(--acc-mid); border-color:var(--acc-mid); color:#fff}
html.minimal .pool, html.minimal footer, html.minimal .shead{background:none}
html.minimal .play{background:rgba(10,3,6,.55)}
html.minimal .aiload{background:var(--bg)}
html.minimal .aiload.err code{border-radius:6px}
/* hero */
html.minimal .hero-logo .logo-img{filter:none}
html.minimal .hero h2 span, html.minimal body[data-theme="purple"] .hero h2 span{
  background:none; -webkit-background-clip:border-box; background-clip:border-box;
  -webkit-text-fill-color:currentColor; color:var(--acc2);
}
html.minimal #pBar{background:var(--acc)}
html.minimal .gobtn, html.minimal #bGo{background:var(--acc-mid) !important}
/* flat controls: small radii, 1px borders */
html.minimal .nav, html.minimal .navlink, html.minimal #search, html.minimal select#sort, html.minimal .tool,
html.minimal #settingsBtn, html.minimal .psearch, html.minimal .enginesel, html.minimal .gobtn, html.minimal .chip,
html.minimal .cta, html.minimal .stat, html.minimal .eyebrow, html.minimal .suffix, html.minimal #allCount,
html.minimal #clearRecent, html.minimal .pbar button, html.minimal .pbar a, html.minimal .bbar button,
html.minimal .baddrwrap, html.minimal .sbtn, html.minimal .swatch, html.minimal .wrow input, html.minimal .sbody select,
html.minimal .vchip, html.minimal .favbtn, html.minimal .play span, html.minimal #sClose, html.minimal #toast,
html.minimal .bar-track, html.minimal #pBar{border-radius:8px}
html.minimal #bGo{border-radius:8px !important}
html.minimal .nav, html.minimal #search, html.minimal select#sort, html.minimal .tool, html.minimal .psearch,
html.minimal .enginesel, html.minimal .cta, html.minimal .chip, html.minimal .pbar button, html.minimal .pbar a,
html.minimal .bbar button, html.minimal .baddrwrap, html.minimal .sbtn, html.minimal .swatch, html.minimal .wrow input,
html.minimal .sbody select, html.minimal #sClose, html.minimal #toast, html.minimal .game, html.minimal .spanel{border-width:1px}
html.minimal .psearch{border-color:var(--ring2)}
html.minimal .chip, html.minimal .stat, html.minimal .eyebrow{background:var(--card)}
html.minimal .stat, html.minimal .eyebrow, html.minimal .suffix, html.minimal #allCount{border-style:solid; border-width:1px}
html.minimal .navlink{font-weight:500}
html.minimal .sechead .accent{background:var(--acc-mid); border-radius:6px; width:28px; height:28px}
html.minimal .sechead h2, html.minimal .brand h1{font-weight:600}
/* library cards: cheap to render and to lay out */
html.minimal .game{
  border-radius:8px; background:var(--card); opacity:1; translate:none;
  content-visibility:auto; contain-intrinsic-size:auto 164px auto 210px;
}
html.minimal body[data-cards="s"] .game{contain-intrinsic-size:auto 122px auto 168px}
html.minimal body[data-cards="l"] .game{contain-intrinsic-size:auto 214px auto 262px}
html.minimal .game:hover{border-color:var(--acc)}
html.minimal .thumb, html.minimal .game.own .thumb, html.minimal .game.in .thumb.ld{background:var(--card2)}
html.minimal .game:hover .thumb img.ok{transform:none}
html.minimal .own-badge{background:var(--acc-mid); border-radius:6px}
html.minimal .favbtn{background:rgba(20,6,10,.82); border-width:1px; border-radius:8px}
html.minimal .favbtn.on{background:var(--acc-mid)}
/* overlays, modal */
html.minimal .pbar, html.minimal .bbar{background:var(--panel); border-bottom:1px solid var(--acc-mid)}
html.minimal .spanel{background:var(--panel); border:1px solid var(--ring2); border-radius:10px}
html.minimal .ssec, html.minimal .shead{border-bottom:1px solid var(--line)}
html.minimal .ssec:last-child{border-bottom:none}
html.minimal .sback{background:rgba(8,2,4,.82)}
html.minimal .srow.minrow{border:1px solid var(--ring); border-radius:8px; background:var(--card)}
html.minimal .tgl{border-radius:99px; border-width:1px; background:var(--bg)}
html.minimal .tgl::after{background:#c9a3a6}
html.minimal .tgl.on{background:var(--acc-mid); border-color:var(--acc-mid)}
html.minimal .tgl.on::after{background:#fff}
html.minimal .swatch .dot{background:var(--acc-mid)}
html.minimal .swatch[data-t="purple"] .dot{background:#5e46e8}
html.minimal .swatch[data-t="red"] .dot{background:#e11d2e}
html.minimal .swatch.on{border-color:var(--acc)}
html.minimal #toast{background:var(--acc-mid)}
html.minimal #toTop{background:var(--acc-mid); color:#fff; border-radius:8px; transform:none}
html.minimal #toTop:not(.show){display:none}
html.minimal ::-webkit-scrollbar-thumb{border-radius:4px}
</style>
</head>
<body data-view="home">

<div id="fizz" aria-hidden="true"></div>
<div id="pops" aria-hidden="true"></div>

<header id="topbar">
  <div class="brand" id="brandHome">
    <span class="cap">__LOGO_HEADER__</span>
    <div class="brandtext">
      <h1>Julmust <span>Arcade</span></h1>
      <p id="tagline"></p>
    </div>
    <span class="vchip">V67</span>
  </div>
  <nav class="nav" aria-label="Sections">
    <button class="navlink active" data-nav="home">Home</button>
    <button class="navlink" data-nav="library">Library</button>
    <button class="navlink" data-nav="ai">AI <span class="spark" aria-hidden="true">&#10022;</span></button>
    <button class="navlink" data-nav="movies"><span class="nico" aria-hidden="true">&#127916;</span>Movies</button>
    <button class="navlink" data-nav="music"><span class="nico" aria-hidden="true">&#127925;</span>Music</button>
  </nav>
  <button id="settingsBtn" class="tool" title="Settings" aria-label="Settings">&#9881;&#65039;</button>
  <div class="tools" id="libTools">
    <div class="searchwrap">
      <svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/></svg>
      <input id="search" type="search" placeholder="Search games&#8230;" aria-label="Search games" autocomplete="off">
    </div>
    <select id="sort" title="Sort games" aria-label="Sort games">
      <option value="new">Newest first</option>
      <option value="old">Oldest first</option>
      <option value="az">A &#8594; Z</option>
      <option value="za">Z &#8594; A</option>
      <option value="rnd">Shuffle</option>
    </select>
    <button id="favToggle" class="tool" title="Show favorites only">&#9829; <b id="favCount">0</b></button>
    <button id="randomBtn" class="tool" title="Play a random game">&#127922;</button>
  </div>
</header>

<main>
  <!-- ============ HOME (greeting + proxy) ============ -->
  <section id="view-home" class="view active">
    <div class="hero">
      <div class="hero-bubbles" aria-hidden="true">
      <i style="--x:6%;--y:14%;--s:20px;--d:3.6s"></i>
      <i style="--x:88%;--y:10%;--s:14px;--d:4.4s"></i>
      <i style="--x:14%;--y:46%;--s:10px;--d:3.1s"></i>
      <i style="--x:82%;--y:40%;--s:24px;--d:5.2s"></i>
      <i style="--x:4%;--y:78%;--s:16px;--d:4.0s"></i>
      <i style="--x:93%;--y:72%;--s:12px;--d:3.4s"></i>
      <i style="--x:24%;--y:8%;--s:8px;--d:2.9s"></i>
      <i style="--x:72%;--y:6%;--s:9px;--d:3.8s"></i>
      </div>
      <div class="hero-logo">__LOGO_HERO__</div>
      <div class="eyebrow"><span class="spark" aria-hidden="true">&#10022;</span> Crack open a cold one <span class="spark" aria-hidden="true">&#10022;</span></div>
      <h2><span>JULMUST</span> <span>ARCADE</span></h2>
      <p class="hero-tag">Play <b id="heroCount">&#8230;</b> games, or surf the web &#8212; unblocked. No games gone flat.</p>

      <form id="pForm" style="width:100%;display:flex;justify-content:center">
        <div class="psearch">
          <svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/></svg>
          <input id="pInput" type="text" placeholder="Search the web or enter a URL" aria-label="Search the web or enter a URL" autocomplete="off" spellcheck="false">
          <select id="pEngine" class="enginesel" title="Search engine" aria-label="Search engine">
            <option value="https://html.duckduckgo.com/html/?q=%s">DuckDuckGo</option>
            <option value="https://search.brave.com/search?q=%s">Brave</option>
            <option value="https://www.bing.com/search?q=%s">Bing</option>
            <option value="https://www.mojeek.com/search?q=%s">Mojeek</option>
          </select>
          <button id="pGo" type="submit" class="gobtn" title="Go" aria-label="Go">&#8599;</button>
        </div>
      </form>

      <div id="pStatus" class="pstatus" role="status"></div>
      <div class="bar-track" id="pBarTrack"><div id="pBar"></div></div>
      <p id="pError" class="perror"></p>

      <div class="chips">
        <button type="button" class="chip" data-url="https://www.youtube.com">&#9654;&#65039; YouTube</button>
        <button type="button" class="chip" data-url="https://www.tiktok.com">&#127925; TikTok</button>
        <button type="button" class="chip" data-url="https://www.instagram.com">&#128247; Instagram</button>
        <button type="button" class="chip" data-url="https://discord.com">&#127918; Discord</button>
        <button type="button" class="chip" data-url="https://www.reddit.com">&#128126; Reddit</button>
        <button type="button" class="chip" data-url="https://www.wikipedia.org">&#128218; Wikipedia</button>
      </div>

      <div class="homeCtas">
        <button id="enterLib" class="cta red">&#129380; Enter the Library</button>
      </div>

      <div class="homeStats">
        <span class="stat"><b id="statGames">0</b> games</span>
        <span class="stat"><b id="statCovers">0</b> with covers</span>
        <span class="stat"><b id="statFavs">0</b> favorites</span>
        <span class="stat">proxy: <b>Scramjet</b></span>
      </div>
    </div>

    <div class="liquid">
      <div class="wave" aria-hidden="true">
        <svg class="back" viewBox="0 0 1440 64" preserveAspectRatio="none"><path d="M0 32Q90 0 180 32T360 32T540 32T720 32T900 32T1080 32T1260 32T1440 32V64H0Z"/></svg>
        <svg viewBox="0 0 1440 64" preserveAspectRatio="none"><path d="M0 32Q90 0 180 32T360 32T540 32T720 32T900 32T1080 32T1260 32T1440 32V64H0Z"/></svg>
      </div>
      <div class="pool">
        <div class="featured" id="featSec">
          <div class="sechead"><h2><span class="accent">&#9733;</span> Home made games</h2></div>
          <div id="featRow" class="row"></div>
        </div>
      </div>
    </div>
  </section>

  <!-- ============ LIBRARY ============ -->
  <section id="view-library" class="view">
    <div class="wrap">
      <section id="recentSec" hidden>
        <div class="sechead">
          <h2><span class="accent">&#9654;</span> Continue playing</h2>
          <button id="clearRecent">Clear</button>
        </div>
        <div id="recentRow" class="row"></div>
      </section>
      <section id="ownSec" hidden>
        <div class="sechead">
          <h2><span class="accent">&#127968;</span> Home made games</h2>
        </div>
        <div id="ownRow" class="row"></div>
      </section>
      <div class="sechead" id="allHead">
        <h2><span class="accent">&#127918;</span> All games <span id="allCount"></span></h2>
      </div>
      <div id="grid" class="grid"></div>
      <p id="empty"></p>
    </div>
  </section>

  <!-- ============ AI (Jarvis) ============ -->
  <section id="view-ai" class="view">
    <div class="aiload" id="aiLoad"><div class="aibub"></div><div>Pouring Jarvis&#8230;</div></div>
    <iframe id="aiFrame" title="Jarvis AI" allow="clipboard-write; microphone; fullscreen"></iframe>
  </section>

  <section id="view-movies" class="view">
    <div class="ptwrap">
      <div class="ptmount" id="ptMount-movies"></div>
      <div class="aiload" id="ptLoad-movies" data-pt="movies"><div class="aibub"></div><div>Pouring Movies&#8230;</div></div>
    </div>
  </section>

  <section id="view-music" class="view">
    <div class="ptwrap">
      <div class="ptmount" id="ptMount-music"></div>
      <div class="aiload" id="ptLoad-music" data-pt="music"><div class="aibub"></div><div>Pouring Music&#8230;</div></div>
    </div>
  </section>
</main>

<!-- ============ PROXY BROWSER ============ -->
<div id="browse">
  <div class="bbar">
    <button id="bBack" title="Back">&#8592;</button>
    <button id="bFwd" title="Forward">&#8594;</button>
    <button id="bReload" title="Reload">&#10227;</button>
    <button id="bHome" title="Julmust Arcade home">&#9875;</button>
    <form id="bForm" class="baddrwrap">
      <span class="lock">&#128274;</span>
      <input id="bAddr" type="text" placeholder="Search or enter address" autocomplete="off" spellcheck="false">
      <button id="bGo" type="submit">Go</button>
    </form>
    <button id="bNew" title="Open for real (without proxy)">&#8599;</button>
    <button id="bFs" title="Fullscreen">&#9974;</button>
    <button id="bExit" title="Close browser (Esc)">&#10005;</button>
  </div>
  <div id="bFrameWrap"></div>
</div>

<!-- ============ GAME PLAYER ============ -->
<div id="player">
  <div class="pbar">
    <button id="backBtn">&#8592; Library</button>
    <button id="prevBtn" title="Previous (left arrow)">&#8249;</button>
    <div id="pTitle"></div>
    <button id="nextBtn" title="Next (right arrow)">&#8250;</button>
    <span style="flex:1"></span>
    <button id="favBtn" title="Toggle favorite (star)">&#9734;</button>
    <button id="fsBtn" title="Fullscreen (F)">&#9974;</button>
    <a id="newTabBtn" href="#" target="_blank" title="Open in new tab">&#8599;</a>
    <button id="copyBtn" title="Copy link to this game">&#8904;</button>
    <button id="closeBtn" title="Close (Esc)">&#10005;</button>
  </div>
  <iframe id="frame" allow="fullscreen; autoplay; gamepad; pointer-lock; clipboard-write"></iframe>
</div>

<!-- ============ SETTINGS ============ -->
<div id="settingsModal" role="dialog" aria-modal="true" aria-label="Settings">
  <div class="sback"></div>
  <div class="spanel">
    <div class="shead">
      <h2><span class="accent">&#9881;</span> Settings</h2>
      <button id="sClose" title="Close (Esc)" aria-label="Close settings">&#10005;</button>
    </div>
    <div class="sbody">
      <section class="ssec">
        <h3>Appearance</h3>
        <div class="srow minrow">
          <span class="lab">Minimalistic Site (Less LAG) <span class="sub">Strips bubbles, gradients, glows and animations for maximum speed</span></span>
          <button id="sMinimal" class="tgl" type="button" role="switch" aria-checked="false" aria-label="Toggle minimalistic site"></button>
        </div>
        <div class="swatches">
          <button type="button" class="swatch" data-t="red"><span class="dot"></span>Cherry Cola</button>
          <button type="button" class="swatch" data-t="purple"><span class="dot"></span>Blueberry Soda</button>
        </div>
      </section>
      <section class="ssec">
        <h3>Library</h3>
        <div class="srow">
          <span class="lab">Card size</span>
          <select id="sCards">
            <option value="s">Small</option>
            <option value="m">Medium</option>
            <option value="l">Large</option>
          </select>
        </div>
        <div class="srow">
          <span class="lab">Animations <span class="sub">Bubbles, wobbles, fades and the floating logo</span></span>
          <button id="sAnim" class="tgl" type="button" aria-label="Toggle animations"></button>
        </div>
        <div class="srow">
          <span class="lab">Open on <span class="sub">Which page the site starts on</span></span>
          <select id="sLanding">
            <option value="home">Home</option>
            <option value="library">Library</option>
          </select>
        </div>
      </section>
      <section class="ssec">
        <h3>Proxy</h3>
        <div class="srow">
          <span class="lab">Search engine</span>
          <select id="sEngine">
            <option value="https://html.duckduckgo.com/html/?q=%s">DuckDuckGo</option>
            <option value="https://search.brave.com/search?q=%s">Brave</option>
            <option value="https://www.bing.com/search?q=%s">Bing</option>
            <option value="https://www.mojeek.com/search?q=%s">Mojeek</option>
          </select>
        </div>
        <div class="srow" style="flex-direction:column;align-items:stretch;gap:8px">
          <span class="lab">Wisp server <span class="sub">Leave empty to use the built-in server</span></span>
          <div class="wrow">
            <input id="wispInput" type="text" placeholder="wss://your-server.example/wisp/" spellcheck="false" autocomplete="off">
            <button id="wispTest" class="sbtn" type="button">Test</button>
          </div>
          <span id="wispNow" class="wout"></span>
          <span id="wispTestOut" class="wout"></span>
        </div>
      </section>
      <section class="ssec">
        <h3>Data</h3>
        <div class="sbtnrow">
          <button id="sClearRecent" class="sbtn" type="button">Clear recently played</button>
          <button id="sClearFavs" class="sbtn" type="button">Clear favorites</button>
          <button id="sReset" class="sbtn danger" type="button">Reset everything</button>
        </div>
      </section>
      <section class="ssec">
        <h3>About</h3>
        <p class="about">
          &#9875; <b>Julmust Arcade V67</b> &#8212; <span id="sCount"></span> games and an unblocked browser, all in one place.<br>
          Shortcuts: <b>/</b> search &#183; <b>Esc</b> close &#183; <b>&#8592;/&#8594;</b> switch game &#183; <b>F</b> fullscreen.<br>
          Proxy powered by <a href="https://github.com/MercuryWorkshop/scramjet" target="_blank" rel="noopener">Scramjet</a> (Mercury Workshop).
        </p>
      </section>
    </div>
  </div>
</div>

<footer>
  <div>&#129380; Julmust Arcade <b>V67</b> &#8212; <span id="footCount"></span> games on ice &#183; stay fizzy</div>
  <div>Proxy powered by <a href="https://github.com/MercuryWorkshop/scramjet" target="_blank" rel="noopener">Scramjet</a> (Mercury Workshop) &#183; covers &#38; games &#169; their respective owners</div>
</footer>

<button id="toTop" title="Back to top" aria-label="Back to top">&#8593;</button>
<div id="toast"></div>

<script>
"use strict";

/* ============================== DATA ============================== */
const GAMES = __GAMES__;

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
/* accepts true/false, "true", 1 and friends (store.set JSON-encodes booleans) */
const asBool=v=>v===true||v===1||v==="true"||v==="1";
const DEFAULT_WISP = (typeof WISP_URL==="string" && WISP_URL) ? WISP_URL : "wss://anura.pro/wisp/";
const settings={
  theme:   store.get("gn_theme","red"),
  cards:   store.get("gn_cards","m"),
  anim:    store.get("gn_anim",true),
  minimal: asBool(store.get("gn_minimal",false)),
  landing: store.get("gn_landing","home"),
  wisp:    store.get("aa_wisp",""),
};
/* "red" = Cherry Cola (default), "purple" = Blueberry Soda; anything else falls back to the default */
if(!["purple","red"].includes(settings.theme)) settings.theme="red";
if(!["s","m","l"].includes(settings.cards)) settings.cards="m";
if(!["home","library"].includes(settings.landing)) settings.landing="home";

/* effective wisp server: user override or built-in */
function effWisp(){ const w=(settings.wisp||"").trim(); return w||DEFAULT_WISP; }
let activeWisp=effWisp();

function applySettings(){
  document.body.dataset.theme=settings.theme;
  document.body.dataset.cards=settings.cards;
  document.body.classList.toggle("no-anim",!settings.anim);
  applyMinimal();
}

/* Minimal mode: html.minimal does the CSS slimming; here the JS side (no bubbles, no pop listener, fonts, Jarvis) */
let minimalApplied=null;
function applyMinimal(){
  const on=!!settings.minimal;
  document.documentElement.classList.toggle("minimal",on);
  document.body.classList.toggle("minimal",on);
  if(on===minimalApplied) return;
  const first=minimalApplied===null;
  minimalApplied=on;
  if(on){ clearFizz(); }
  else { buildFizz(); if(typeof window.gnFonts==="function") window.gnFonts(); }
  syncPops();
  if(!first) notifyJarvis();
}
function notifyJarvis(){
  const af=document.getElementById("aiFrame");
  if(!af||!af.getAttribute("src")||!af.contentWindow) return;
  let o="*"; try{ if(location.origin&&location.origin!=="null") o=location.origin; }catch(e){}
  try{ af.contentWindow.postMessage({type:"gn_minimal",on:!!settings.minimal},o); }catch(e){}
}

/* ============================== STATE ============================== */
let sort = store.get("gn_sort", "new");
let favsOnly = false;
let query = "";
if(!["new","old","az","za","rnd"].includes(sort)) sort = "new";

const $ = id => document.getElementById(id);
const esc=s=>String(s).replace(/[&<>"']/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
const grid=$("grid"), searchBox=$("search"), frame=$("frame");

const EMOJI=["\uD83C\uDFAE","\uD83D\uDC7E","\uD83D\uDD79\uFE0F","\uD83C\uDFB2","\uD83D\uDE80","\u2B50","\uD83D\uDD25","\uD83C\uDFAF","\uD83C\uDFC6","\u26A1","\uD83E\uDDE9","\u2693"];
const emojiFor=n=>{let h=0;for(const c of n)h=(h*31+c.charCodeAt(0))>>>0;return EMOJI[h%EMOJI.length];};

/* ============================== CARD FACTORY ============================== */
const io = new IntersectionObserver(es=>{
  for(const e of es) if(e.isIntersecting){ e.target.classList.add("in"); io.unobserve(e.target); }
},{rootMargin:"200px"});

function makeCard(g){
  const el=document.createElement("div");
  el.className="game"+(g.o?" own":"");
  el.dataset.f=g.f;
  const label=g.o?esc(g.t):(g.t?esc(g.t):"#"+g.n);
  const chip=g.o?"":(g.t?"#"+g.n+(g.s?"&#183;"+esc(g.s):""):(g.s?esc(g.s):""));
  el.title=(g.o?esc(g.t):(g.t?g.t+" \u00B7 #"+g.n:"#"+g.n+(g.s?" \u00B7 "+g.s:"")))+"\u2014 click to play";
  el.innerHTML =
    '<div class="thumb">'+
      (g.c?'<img loading="lazy" decoding="async" src="'+g.c+'" alt="">':'')+
      '<div class="fallback"><span class="fe">'+(g.e||emojiFor(g.f))+'</span><span class="fn">'+label+'</span></div>'+
      (g.o?'<span class="own-badge">&#127968;</span>':'')+
      '<div class="play"><span>\u25B6 Play</span></div>'+
    '</div>'+
    '<div class="meta"><span class="num">'+label+'</span>'+
      (chip?'<span class="suffix">'+chip+'</span>':'')+
    '</div>'+
    '<button class="favbtn'+(favs.has(g.f)?" on":"")+'" title="Toggle favorite" aria-label="Toggle favorite">\u2665</button>';

  const img=el.querySelector("img");
  if(img){
    const th=el.querySelector(".thumb");
    th.classList.add("ld");
    img.addEventListener("load", ()=>{ img.classList.add("ok"); th.classList.remove("ld"); });
    img.addEventListener("error", ()=>{ img.remove(); th.classList.remove("ld"); });
  }
  el.addEventListener("click", ()=>openGame(g.f));
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
      ? "No favorites yet.<br>Tap the <b>\u2665</b> on any game to keep it on ice."
      : "No bubbles for <b>"+query.replace(/[<>&]/g,"")+"</b>.<br>Try a number like <b>842</b> or a name like <b>pizza</b>.";
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
  if(recent.length===0){ sec.hidden=true; return; }
  sec.hidden=false;
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
  else{ favs.add(f); toast("Added to favorites \u2665"); }
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
  movies:{url:"https://redflix.st",label:"Movies"},
  music:{url:"https://www.dusktune.com",label:"Music"}
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

/* keep every iframe view (AI, Movies, Music) exactly as tall as the space under the (wrapping) header */
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

/* fizz + pops are paused/hidden (CSS body.ovl) while a game or the browser overlay is open */
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
      +'background:radial-gradient(700px 400px at 50% 0,rgba(225,29,46,.28),transparent 70%),#0a0507;color:#fff4ee;font-family:system-ui,\u0022Segoe UI\u0022,sans-serif;text-align:center;padding:20px;box-sizing:border-box}'
      +'.card{max-width:540px;padding:34px 38px;background:#1c0d12;border:2.5px solid #e11d2e;border-radius:30px;'
      +'box-shadow:0 18px 50px rgba(0,0,0,.55),0 0 40px rgba(255,59,78,.25)}'
      +'h2{margin:2px 0 10px;font-size:1.3rem}p{margin:9px 0;color:#c4a3a5;line-height:1.55;font-size:.95rem}'
      +'code{background:#2b1219;padding:2px 9px;border-radius:999px;color:#ff8f9b;font-size:.92em}'
      +'.big{font-size:3.2rem}.btn{display:inline-block;margin-top:14px;padding:10px 22px;border-radius:999px;'
      +'background:linear-gradient(180deg,#f0283a,#b30f1e);box-shadow:inset 0 1px 0 rgba(255,255,255,.5);color:#fff;font-weight:700;text-decoration:none}code.wide{display:inline-block;margin-top:6px}'
      +'</style></head><body>'
      +'<div class="card"><div class="big">\uD83C\uDFE0</div>'
      +'<h2>'+esc(g.t||"This game")+' needs the local server</h2>'
      +'<p>Home-made games cannot run while the arcade is opened by double-clicking its file<br>(browsers block game files on <code>file://</code> pages).</p>'
      +'<p>Double-click <code>Start Julmust Arcade.bat</code> in the arcade folder,<br>then open <code class="wide">http://localhost:8765/</code></p>'
      +'<a class="btn" href="http://localhost:8765/">\uD83D\uDD17 Open localhost:8765</a>'
      +'<p style="margin-top:14px;font-size:.85rem">(the other 800+ games work fine right where you are)</p>'
      +'</div></body></html>';
  }else{
    frame.removeAttribute("srcdoc");
    frame.src=g.f;
  }
  const chip=g.o?"":(g.t?"#"+g.n+(g.s?"&#183;"+esc(g.s):""):(g.s?esc(g.s):""));
  $("pTitle").innerHTML=(g.o?esc(g.t):(g.t?esc(g.t):"#"+g.n))+(chip?'<span class="suffix">'+chip+"</span>":(g.o?'<span class="suffix own">&#127968; home-made</span>':""));
  $("newTabBtn").href=g.f;
  syncPlayerFavBtn();
  const i=NAV.indexOf(g);
  $("prevBtn").disabled=i<=0;
  $("nextBtn").disabled=i<0||i>=NAV.length-1;
  $("player").classList.add("active");
  syncOvl();
  document.body.style.overflow="hidden";
  document.title="\u25B6 "+(g.t||("#"+g.n))+" \u00B7 Julmust Arcade";
  addRecent(g.f);
}

function closePlayer(){
  current=null;
  $("player").classList.remove("active");
  syncOvl();
  frame.removeAttribute("srcdoc");
  frame.src="about:blank";
  document.body.style.overflow="";
  document.title="Julmust Arcade V67";
}

function syncPlayerFavBtn(){
  const b=$("favBtn");
  b.innerHTML=favs.has(current.f)?"\u2665":"\u2661";
  b.classList.toggle("on", favs.has(current.f));
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
    if(!w) throw new Error("No wisp server configured \u2014 set one in Settings \u2699.");
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

/* mode: loading | done | error | file - drives the soda loader / error panel of a tab */
function ptShow(k, mode, msg){
  const el=$("ptLoad-"+k), label=PROXY_TABS[k].label;
  el.classList.remove("done","err");
  if(mode==="done"){ el.classList.add("done"); return; }
  if(mode==="loading"){ el.innerHTML='<div class="aibub"></div><div>Pouring '+esc(label)+"\u2026</div>"; return; }
  el.classList.add("err");
  if(mode==="file"){
    el.innerHTML='<div class="ptbig">\uD83C\uDFE0</div><h2>'+esc(label)+' needs the local server</h2>'
      +'<p>The proxy cannot run while the arcade is opened by double-clicking its file<br>(browsers block it on <code>file://</code> pages).</p>'
      +'<p>Double-click <code>Start Julmust Arcade.bat</code> in the arcade folder,<br>then open <code>http://localhost:8765/</code></p>'
      +'<div class="ptbtns"><a class="cta red" href="http://localhost:8765/">\uD83D\uDD17 Open localhost:8765</a></div>';
    return;
  }
  el.innerHTML='<div class="ptbig">\u26A0\uFE0F</div><h2>'+esc(label)+" could not be loaded</h2><p>"+esc(msg||"The proxy failed to start.")+"</p>"
    +'<div class="ptbtns"><button class="cta red" type="button" data-act="retry">Retry</button>'
    +'<button class="cta" type="button" data-act="browse">Open in proxy browser</button></div>';
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

document.querySelectorAll(".aiload[data-pt]").forEach(el=>el.addEventListener("click",e=>{
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
    toast("Proxy connected \u2693");
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

function openSettings(){
  settingsModal.classList.add("active");
  syncSettingsUI();
  document.body.style.overflow="hidden";
}
function closeSettings(){
  settingsModal.classList.remove("active");
  document.body.style.overflow="";
}
function syncSettingsUI(){
  document.querySelectorAll(".swatch").forEach(b=>b.classList.toggle("on",b.dataset.t===settings.theme));
  $("sCards").value=settings.cards;
  $("sAnim").classList.toggle("on",!!settings.anim);
  $("sMinimal").classList.toggle("on",!!settings.minimal);
  $("sMinimal").setAttribute("aria-checked",settings.minimal?"true":"false");
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

document.querySelectorAll(".swatch").forEach(b=>b.addEventListener("click",()=>{
  settings.theme=b.dataset.t;
  store.set("gn_theme",settings.theme);
  applySettings(); syncSettingsUI();
  toast("Theme: "+(settings.theme==="red"?"Cherry Cola":"Blueberry Soda"));
}));

$("sCards").addEventListener("change",e=>{
  settings.cards=e.target.value;
  store.set("gn_cards",settings.cards);
  applySettings();
});

$("sAnim").addEventListener("click",()=>{
  settings.anim=!settings.anim;
  store.set("gn_anim",settings.anim);
  applySettings(); syncSettingsUI();
});

$("sMinimal").addEventListener("click",()=>{
  settings.minimal=!settings.minimal;
  store.set("gn_minimal",settings.minimal);
  applySettings(); syncSettingsUI();
  toast(settings.minimal?"Minimal mode on - lighter and faster":"Minimal mode off");
});

$("sLanding").addEventListener("change",e=>{
  settings.landing=e.target.value;
  store.set("gn_landing",settings.landing);
  toast("Starts on "+(settings.landing==="library"?"the Library":"Home")+" next visit");
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
  if(!confirm("Reset ALL site data?\n(theme, favorites, history, proxy settings \u2014 everything)")) return;
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
  renderGrid();
});

$("randomBtn").addEventListener("click",()=>{
  openGame(NAV[Math.floor(Math.random()*NAV.length)].f);
});

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
    if(location.hash!=="#library") history.pushState(null,"","#library"); /* keeps the back button working from any view */
    showView("library"); searchBox.focus();
  }
});

/* ============================== INIT ============================== */
applySettings();
$("tagline").textContent=GAMES.length+" games \u00B7 stay fizzy";
$("heroCount").textContent=GAMES.length;
$("statGames").textContent=GAMES.length;
$("statCovers").textContent=[...cardCache.values()].filter(c=>c.querySelector("img")).length;
$("footCount").textContent=GAMES.length;
$("sCount").textContent=GAMES.length;
renderFavCount();
renderRecent();
renderFeatured();
renderOwn();

/* AI view: hide the bubble loader once Jarvis has loaded */
$("aiFrame").addEventListener("load",()=>{ if($("aiFrame").getAttribute("src")) $("aiLoad").classList.add("done"); });

/* fizz: a small, fixed number of CSS-animated bubbles (no JS per frame); never created in minimal mode */
function buildFizz(){
  const layer=$("fizz");
  if(settings.minimal||layer.childElementCount) return;
  const n=innerWidth<700?9:16, r=(a,b)=>a+Math.random()*(b-a);
  const frag=document.createDocumentFragment();
  for(let i=0;i<n;i++){
    const b=document.createElement("i");
    b.style.cssText="--x:"+r(2,97).toFixed(1)+"%;--s:"+r(6,30).toFixed(0)+"px;--t:"+r(11,24).toFixed(1)+"s;--dl:-"+r(0,24).toFixed(1)+"s;--dx:"+r(-46,46).toFixed(0)+"px";
    frag.appendChild(b);
  }
  layer.appendChild(frag);
}
function clearFizz(){ $("fizz").textContent=""; $("pops").textContent=""; }

/* bubbles pop where you click (max ~30 nodes alive, skipped when animations are off); the listener only exists while minimal mode is off */
const popMQ=window.matchMedia("(prefers-reduced-motion: reduce)");
function popHandler(e){
  const layer=$("pops");
  if(settings.minimal || popMQ.matches || !settings.anim || document.body.classList.contains("ovl") || e.button>0) return;
  if(layer.childElementCount>24) return;
  const k=e.target.closest?e.target.closest("button,.game,.chip,.cta,.navlink,.tool"):null;
  if(!k) return;
  for(let i=0;i<5;i++){
    const b=document.createElement("i"), a=Math.random()*Math.PI*2, d=16+Math.random()*30;
    b.style.cssText="left:"+e.clientX+"px;top:"+e.clientY+"px;--s:"+(5+Math.random()*9).toFixed(0)+"px;--dx:"+(Math.cos(a)*d).toFixed(0)+"px;--dy:"+(Math.sin(a)*d-14).toFixed(0)+"px";
    b.addEventListener("animationend",()=>b.remove());
    layer.appendChild(b);
  }
}
function syncPops(){
  if(settings.minimal) document.removeEventListener("pointerdown",popHandler);
  else document.addEventListener("pointerdown",popHandler,{passive:true});
}

/* wake the effective wisp server early so it is (mostly) awake when needed */
try{
  const w=effWisp();
  if(w) fetch(w.replace("wss://","https://").replace(/\/wisp\/?$/,"/"),{mode:"no-cors"}).catch(()=>{});
}catch(e){}

route(true);
if(isFile()) setStatus("\u26A0 Arcade opened via file:// \u2014 double-click \u201CStart Julmust Arcade.bat\u201D for the full experience (home-made Unity games need it).");
</script>
</body>
</html>
'@

# ---- real game names, extracted from <base href> / CDN repo URLs ----
$genericRepos = @('web-ports','web-port','gameports','games','game','brainrot','assets','asset','ugss','ugs-assets','elitecomposite','selenite','selenite-old','google-class','google-classic','cc3d-mobile','poki-sdk','poki','whatver','cg-rip','unblocked-games','unblockedgames','some-repo','gstore','flashgames','youtube','youtube-playables','playables','fnaf','ports','game-webports-onawebsite','interstellar-3','interstellar','ugs-file-encryption','emujs','emu','emu-updated','seraph','ruffle-embedded','unknown')
$containers   = @('play','dist','build','game','games','files','file','web','www','misc','unity','swfs','roms','dos','out','public','html','bin','src','projects','new','final','demo','versions','version','main','master','cdn','static','dl','dl2','dl3','dl4','flash','storage','emulatorjs','data')
$overrides = @{
    # known proper titles for slugs that title-casing gets wrong
    'sm64'='Super Mario 64'; 'ucn'='Ultimate Custom Night'; 'iwbtg'='I Wanna Be The Guy'
    'henry-stickman'='Henry Stickmin'; 'cookieclicker'='Cookie Clicker'; 'buildnow-gg'='BuildNow GG'
    'justfalllol'='JustFall.LOL'; 'gdlite'='Geometry Dash Lite'; 'off'='OFF'
    's.p.l.i.t'='SPLIT'; 'imposter-bside'='Imposter B-Side'; 'bside'='B-Side'; 'd-sides'='D-Sides'
    'fnaw'="Five Nights at Wario's"; 'rigbmx'='Rig BMX'; 'rigbmx2'='Rig BMX 2'
    'fnaf-world-refreshed'='FNaF World: Refreshed'; 'fnaf-into-the-pit'='FNaF: Into The Pit'
    # repo/subdir combos (generic repo whose subdir is a variant)
    'fnaf-1'="Five Nights at Freddy's"; 'fnaf-2'="Five Nights at Freddy's 2"
    'fnaf-3'="Five Nights at Freddy's 3"; 'fnaf-4'="Five Nights at Freddy's 4"
    'fnaf-4-halloween'="FNaF 4: Halloween Edition"; 'fnaf-sl'="FNaF: Sister Location"
    'fnaf-w'="FNaF World"; 'fnaf-ps'="FNaF: Pizzeria Simulator"; 'fnaf-ucn'="Ultimate Custom Night"
    'x3m'='X3M'; 'x3m-2'='X3M 2'; 'ovo'='OvO'; 'gladihoppper'='Gladihopper'
    'feed-and-grow'='Feed and Grow: Fish'; 'tf2'='Team Fortress 2'; 'tf-2'='Team Fortress 2'
    'helltakerweb'='Helltaker'; 'omori'='OMORI'
    'pokemon-heart-gold-version'='Pokémon HeartGold'
    'fnf'="Friday Night Funkin'"; 'fridayfunk'="Friday Night Funkin'"; 'fnfmods'='FNF Mods'
    'osu'='osu!'
    'bloonstd1'="Bloons Tower Defense 1"; 'bloonstd2'="Bloons Tower Defense 2"; 'bloonstd3'="Bloons Tower Defense 3"
    'learn-2-fly-2'="Learn To Fly 2"; 'learn2fly2'="Learn To Fly 2"
    'ducklife2'="Duck Life 2"; 'ducklife2worldchampion'="Duck Life 2"; 'ducklife3game'="Duck Life 3"
    'an_ordinary_sonic_rom_hack_cinossu_shc2013'="Sonic.Exe"
    'tosstheturtle'="Toss the Turtle"; 'mad2'='MAD 2'
    'redball1'="Red Ball 1"; 'redball2'="Red Ball 2"
    'red ball - definitive edition'="Red Ball 1"; 'red ball 2 - definitive edition'="Red Ball 2"
    'fpaworld4p1'='FPA World 4 Part 1'
    # junk repo/slug names -> leave the game unnamed
    'new'=''; 'test'=''; 'files'=''; 'file'=''; 'sdk'=''; 'swf'=''; 'j'=''; 'bl'=''; 'cl'=''
    'draw-cl'=''; 'port'=''; 'repo'=''; 'untitled'=''; 'flash-games'=''; 'html5games'=''
    'html-5-games'=''; 'unblocked-games'=''; 'unblockedgames'=''   # also in $genericRepos (subdir wins)
    'poki-sdk'=''; 'portsv'=''; 'lumassets'=''; 'portsv-4'=''; 'loader'=''; 'loaderjs'=''; 'js'=''; 'cloak'=''
}
# per-file name fixes (no slug to extract from)
$fileOverrides = @{
    '777-fix2.html'='Outhold'
    '107-fix2.html'='This Is The Only Level 2'
    '592-fix3.html'="Pac Man World"
}

function ConvertTo-GameTitle([string]$slug) {
    if (-not $slug) { return '' }
    $slug = ($slug -replace '@[^/]*$','')          # strip jsdelivr @branch/@commit
    $s = $slug
    $s = $s -creplace '\.(swf|html?|js|data|wasm|unityweb|bin|rom|gba|gbc|gb|nds|smc|sfc|nes|zip|chd|iso|cue|md|7z)$',''
    $s = $s -creplace '^\d+_+',''                  # 593275_FPAWorld3 -> FPAWorld3
    $s = $s -creplace '^[-_ ]+',''                 # -3 -> 3 (then digits-only -> unnamed)
    $s = $s -ireplace '[-_ ]+(main|port|web|build|html|copy|fixed|offline|full|secure|updated|update|upd3)$','' # junk tails
    $s = $s -creplace '^[-_ ]+',''
    $s = $s -creplace '^(secure|new)[-_ ]+',''
    if (-not $s -or $s -cmatch '^\d+$') { return '' }
    $key = $s.ToLower()
    if ($overrides.ContainsKey($key)) { return $overrides[$key] }
    $s = $s -replace '[-_+]+',' '
    $s = $s -creplace '(?<=[a-z0-9])(?=[A-Z])',' '   # camelCase split
    $s = $s -creplace '(?<=[A-Z])(?=[A-Z][a-z])',' ' # FPAWorld -> FPA World
    $s = $s -creplace '(?<=[A-Za-z])(?=\d)|(?<=\d)(?=[A-Za-z])',' ' # World3 -> World 3
    $s = ($s -split '\s+' | Where-Object { $_ }) -join ' '
    if (-not $s) { return '' }
    $s = $s -ireplace ' (main|port|web|build|html|copy|fixed|offline|full|secure|updated|update|upd3)$',''  # post-split junk tails
    $s = $s -ireplace '\b(\d+) D\b','$1D'                                       # 3 D -> 3D
    $words = @($s -split '\s+' | Where-Object { $_ })
    if ($words.Count -ge 6) {                                                   # hash-like slug -> unnamed
        $short = @($words | Where-Object { $_.Length -le 2 }).Count
        if ($short * 2 -ge $words.Count) { return '' }
    }
    $res = New-Object System.Collections.Generic.List[string]
    foreach ($w in ($s -split '\s+')) {
        if ($w -ieq 'io' -and $res.Count -gt 0) { $res[$res.Count-1] += '.io' }   # slime io -> Slime.io
        elseif ($w -cmatch "^[A-Z0-9.&'/]{1,4}$") { $res.Add($w) }                # keep short acronyms
        else { $res.Add((Get-Culture).TextInfo.ToTitleCase($w.ToLower())) }
    }
    return ($res -join ' ').Trim()
}

function Get-SlugFromUrl([string]$url) {
    if (-not $url) { return '' }
    try { $u = [uri]::UnescapeDataString($url) } catch { $u = $url }
    $u = ($u -replace '[?#].*$','').TrimEnd('/')
    $segs = @(($u -replace '^https?://[^/]+/?','') -split '/' | Where-Object { $_ })
    if ($segs.Count -eq 0) { return '' }
    if ($segs[0] -ieq 'gh') { $segs = @($segs | Select-Object -Skip 1) }
    if ($segs.Count -eq 0) { return '' }
    if ($segs.Count -eq 1) { return ConvertTo-GameTitle $segs[0] }
    $repo = ($segs[1] -replace '@.*$','').ToLower()
    $rest = @($segs | Select-Object -Skip 2)
    # githack-style branch/commit marker
    if ($rest.Count -gt 0 -and ($rest[0] -ieq 'main' -or $rest[0] -ieq 'master' -or $rest[0] -cmatch '^[0-9a-f]{40}$')) {
        $rest = @($rest | Select-Object -Skip 1)
    }
    if ($genericRepos -cnotcontains $repo) { return ConvertTo-GameTitle $repo }
    foreach ($sg in $rest) {                        # generic repo -> use first non-container subdir
        if ($containers -cnotcontains $sg.ToLower()) {
            $key = ($repo + '-' + ($sg -replace '@.*$','')).ToLower()
            if ($overrides.ContainsKey($key)) { return $overrides[$key] }   # fnaf/2 -> Five Nights at Freddy's 2
            $t = ConvertTo-GameTitle $sg
            if ($t) { return $t }                   # skip junk segs, keep scanning
        }
    }
    return ''
    return ''
}

function Get-GameTitleFromHtml([string]$content) {
    $urls = [regex]::Matches($content, 'https?://(?:[a-z0-9.-]*jsdelivr\.net|[a-z0-9.-]*githack\.com|raw\.githubusercontent\.com)/[^\s"''<>\\]+') | ForEach-Object { $_.Value }
    # EmuJS / emulator loaders carry the real game name in their config
    $m = [regex]::Match($content, 'EJS_gameName\s*=\s*"([^"]{2,80})"')
    if ($m.Success) {
        $t = $m.Groups[1].Value.Trim()
        while ($t -cmatch '\s*\([^)]+\)$') { $t = $t -creplace '\s*\([^)]+\)$','' }   # strip region/disc tags
        $t = ($t -replace '\.(gba|gbc|gb|nds|smc|sfc|nes|zip|chd|bin|iso|cue|md)$','').Trim()
        if ($t) { return $t.Trim() }
    }
    $m = [regex]::Match($content, 'gameconfig\s*=\s*\{[^}]*?name\s*:\s*"([^"]{2,80})"')
    if ($m.Success) {
        $t = $m.Groups[1].Value.Trim()
        while ($t -cmatch '\s*\([^)]+\)$') { $t = $t -creplace '\s*\([^)]+\)$','' }
        $t = ($t -replace '\.(gba|gbc|gb|nds|smc|sfc|nes|zip|chd|bin|iso|cue|md)$','').Trim()
        if ($t) { return $t.Trim() }
    }
    # emulator rom archives — the filename is the game
    foreach ($u in $urls) {
        if ($u -imatch '\.(zip|chd|bin|gba|gbc|gb|nds|smc|sfc|nes|iso|cue|md|7z)([?#]|$)') {
            try { $t = [uri]::UnescapeDataString([io.path]::GetFileName(($u -replace '\\','/'))) } catch { $t = '' }
            $t = ($t -ireplace '\.(zip|chd|bin|gba|gbc|gb|nds|smc|sfc|nes|iso|cue|md|7z)$','').Trim()
            while ($t -cmatch '\s*\([^)]+\)$') { $t = $t -creplace '\s*\([^)]+\)$','' }   # strip region/disc tags
            $t = $t.Trim()
            if ($t -and $t.Length -ge 3) { return $t.Trim() }
        }
    }
    $m = [regex]::Match($content, '<base\s+href\s*=\s*"([^"]+)"')
    if ($m.Success) { $t = Get-SlugFromUrl $m.Groups[1].Value; if ($t) { return $t } }
    $urls = [regex]::Matches($content, 'https?://(?:[a-z0-9.-]*jsdelivr\.net|rawcdn\.githack\.com|raw\.githubusercontent\.com)/[^\s"''<>()\\]+') | ForEach-Object { $_.Value }
    foreach ($u in $urls) { $t = Get-SlugFromUrl $u; if ($t) { return $t } }
    # last resort: SWF filename (ruffle/flash wrappers) — the basename is the real game
    foreach ($u in $urls) {
        if ($u -imatch '\.swf($|[?&#])') {
            try { $dec = [uri]::UnescapeDataString($u) } catch { $dec = $u }
            $b = (($dec -replace '[?#].*$','').Split('/')[-1]) -ireplace '\.swf$',''
            if ($b -and $b.Length -ge 3) {
                $t = ConvertTo-GameTitle $b
                if ($t -and $t -cnotmatch '^(Game|Swf|Loader|Preloader|File|Test|Untitled)$') { return $t }
            }
        }
    }
    $m = [regex]::Match($content, 'eaglercraft\.dev/downloads/([^/''"\s]+?)\.html')
    if ($m.Success) { $t = ConvertTo-GameTitle $m.Groups[1].Value; if ($t) { return $t } }
    return ''
}

# ---- collect game files (skip the launcher itself) ----
$set = @{}
if (Test-Path $coversDir) {
    Get-ChildItem $coversDir -File | ForEach-Object { $set[$_.Name] = $true }
}

$games = Get-ChildItem -Path $dir -File |
    Where-Object { $_.Name -cne 'index.html' -and $_.Name -cmatch '\.html' }

$items = foreach ($f in $games) {
    $base = $f.Name -replace '\.html$',''
    $n = 999999; $s = ''
    if ($base -cmatch '^(\d+)[-.](.+)$') { $n = [int]$matches[1]; $s = $matches[2] }
    elseif ($base -cmatch '^(\d+)$')     { $n = [int]$matches[1] }
    if ($s -cmatch '^html[-.]?(.*)$') { $s = $Matches[1] }   # 615.html-a -> variant 'a'

    # cover resolution: exact number+suffix jpg, then plain number jpg, then any other format (png/gif/webp/avif)
    $c = $null
    if ($s -ne '' -and $set.ContainsKey(("{0}-{1}.jpg" -f $n, $s))) { $c = "covers/{0}-{1}.jpg" -f $n, $s }
    elseif ($set.ContainsKey(("{0}.jpg" -f $n))) { $c = "covers/{0}.jpg" -f $n }
    else {
        $alt = $set.Keys |
            Where-Object { $_ -cmatch ('^' + [regex]::Escape([string]$n) + '\.(png|gif|webp|avif|jpe?g|bmp)$') } |
            Sort-Object | Select-Object -First 1
        if ($alt) { $c = "covers/$alt" }
    }
    $content = Get-Content $f.FullName -Raw
    $title = if ($fileOverrides.ContainsKey($f.Name)) { $fileOverrides[$f.Name] } else { Get-GameTitleFromHtml $content }
    [pscustomobject]@{ F = $f.Name; N = $n; S = $s; C = $c; T = $title }
}
$sorted = $items | Sort-Object N, F

# ---- home-made games (own Unity/web builds copied from Downloads\GAMES) ----
$ownSrc = 'C:\Users\alveb\Downloads\GAMES'
$ownDefs = @(
    @{ folder='anchorsworld'; name='Anchors World';        je='\uD83C\uDF0D' }  # globe
    @{ folder='fort';         name='Fort';                 je='\uD83C\uDFF0' }  # castle
    @{ folder='ironknights';  name='Iron Knights';         je='\u2694\uFE0F' }  # crossed swords
    @{ folder='mobilegame';   name='Mobilegame';           je='\uD83D\uDCF1' }  # phone
    @{ folder='musspel';      name='Mouse Quest Ultimate'; je='\uD83D\uDC2D' }  # mouse
)
$ownReady = @()
foreach ($o in $ownDefs) {
    $src = Join-Path $ownSrc $o.folder
    if (-not (Test-Path (Join-Path $src 'index.html'))) { Write-Output ("skip (no source): {0}" -f $o.folder); continue }
    $dst = Join-Path $dir ('mygames\' + $o.folder)
    if (-not (Test-Path (Join-Path $dst 'index.html'))) {
        robocopy $src $dst /E /XD .git /NFL /NDL /NJH /NJS /NP | Out-Null
    }
    if (Test-Path (Join-Path $dst 'index.html')) { $ownReady += $o }
    else { Write-Output ("skip (copy failed): {0}" -f $o.folder) }
}
$ownLines = foreach ($o in $ownReady) {
    '  {{f:"mygames/{0}/index.html",n:null,s:"",t:"{1}",c:null,e:"{2}",o:1}}' -f $o.folder, $o.name, $o.je
}

# ---- build the JS array ----
$nl = [Environment]::NewLine
$lines = foreach ($g in $sorted) {
    $f = $g.F -replace '\\','\\\\' -replace '"','\"'
    $s = $g.S -replace '\\','\\\\' -replace '"','\"'
    $t = $g.T -replace '\\','\\\\' -replace '"','\"'
    $c = if ($g.C) { '"' + $g.C + '"' } else { 'null' }
    '  {{f:"{0}",n:{1},s:"{2}",t:"{3}",c:{4}}}' -f $f, $g.N, $s, $t, $c
}
$arr = '[' + $nl + (($lines + $ownLines) -join (',' + $nl)) + $nl + ']'

# ---- inline the theme-aware logo (CSS vars inside cascade into inline SVG only) ----
$logoSvg = ''
$logoPath = Join-Path $dir 'logo.svg'
if (Test-Path $logoPath) {
    $logoSvg = (Get-Content $logoPath -Raw).Trim()
    $logoSvg = $logoSvg.Replace('<svg ', '<svg class="logo-img" aria-hidden="true" ')
} else {
    $logoSvg = '<img class="logo-img" src="favicon.png" alt="" aria-hidden="true">'
}

$html = $template.Replace('__GAMES__', $arr).Replace('__LOGO_HEADER__', $logoSvg).Replace('__LOGO_HERO__', $logoSvg)
Set-Content -Path (Join-Path $dir 'index.html') -Value $html -Encoding UTF8 -NoNewline

$withCovers = @($sorted | Where-Object { $_.C }).Count
$named = @($sorted | Where-Object { $_.T }).Count
Write-Output ("index.html generated: {0} games, {1} with covers, {2} named" -f $sorted.Count, $withCovers, $named)

# full mapping for inspection (not part of the site)
$prev = $sorted | ForEach-Object { "{0,-4}  {1}" -f $_.N, $_.T }
$prev | Set-Content -Path (Join-Path $env:TEMP 'opencode\names-preview.txt') -Encoding UTF8
$sorted | ForEach-Object { "{0}`t{1}" -f $_.F, $_.T } |
    Set-Content -Path (Join-Path $env:TEMP 'opencode\file-titles.txt') -Encoding UTF8
Write-Output "sample:"
$sorted | Where-Object { $_.T } | Select-Object -First 12 | ForEach-Object { Write-Output ("  {0} -> {1}" -f $_.F, $_.T) }
