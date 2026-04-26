(function(){const f=`
  @import url('https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;600&display=swap');

  #phish-alert {
    position: fixed; top: 18px; right: 18px; z-index: 2147483647;
    font-family: 'IBM Plex Mono', monospace;
    display: flex; align-items: center; gap: 12px;
    padding: 14px 20px 14px 16px; border-radius: 12px;
    box-shadow: 0 8px 32px rgba(0,0,0,0.22), 0 2px 8px rgba(0,0,0,0.12);
    min-width: 260px; max-width: 360px; cursor: default;
    transition: transform 0.18s cubic-bezier(.4,2,.6,1), box-shadow 0.18s ease, opacity 0.25s ease;
    animation: phish-slide-in 0.38s cubic-bezier(.4,2,.6,1) forwards;
  }
  #phish-alert:hover {
    transform: translateY(-2px) scale(1.01);
    box-shadow: 0 14px 40px rgba(0,0,0,0.28), 0 2px 8px rgba(0,0,0,0.12);
  }
  #phish-alert.phish-danger {
    background: linear-gradient(135deg, #1a0a0a 0%, #2d1111 100%);
    border: 1.5px solid rgba(255,60,60,0.55);
  }
  #phish-alert.phish-checking {
    background: linear-gradient(135deg, #0d0d18 0%, #141428 100%);
    border: 1.5px solid rgba(100,120,255,0.4);
  }
  #phish-alert.phish-error {
    background: linear-gradient(135deg, #0f0e0a 0%, #1e1a0a 100%);
    border: 1.5px solid rgba(255,180,0,0.4);
  }
  #phish-alert .phish-icon { font-size: 26px; line-height: 1; flex-shrink: 0; }
  #phish-alert .phish-icon-wrap {
    position: relative; display: flex; align-items: center; justify-content: center;
  }
  #phish-alert.phish-danger .phish-icon-wrap::before {
    content: ''; position: absolute; width: 44px; height: 44px;
    border-radius: 50%; border: 2px solid rgba(255,60,60,0.5);
    animation: phish-pulse 1.6s ease-out infinite;
  }
  #phish-alert .phish-body { display: flex; flex-direction: column; gap: 2px; flex: 1; }
  #phish-alert .phish-label {
    font-size: 10px; font-weight: 600; letter-spacing: 0.12em;
    text-transform: uppercase; opacity: 0.65;
  }
  #phish-alert.phish-danger .phish-label   { color: #ff9090; }
  #phish-alert.phish-checking .phish-label { color: #9090ff; }
  #phish-alert.phish-error .phish-label    { color: #ffcc60; }
  #phish-alert .phish-title { font-size: 15px; font-weight: 600; letter-spacing: 0.01em; }
  #phish-alert.phish-danger .phish-title   { color: #ff4444; }
  #phish-alert.phish-checking .phish-title { color: #aab4ff; }
  #phish-alert.phish-error .phish-title    { color: #ffcc00; }
  #phish-alert .phish-sub { font-size: 11px; opacity: 0.55; margin-top: 1px; }
  #phish-alert.phish-danger .phish-sub   { color: #ffaaaa; }
  #phish-alert.phish-checking .phish-sub { color: #aaaaff; }
  #phish-alert.phish-error .phish-sub    { color: #ffddaa; }
  #phish-alert .phish-close {
    font-size: 16px; opacity: 0.35; line-height: 1;
    transition: opacity 0.15s; flex-shrink: 0; color: white; cursor: pointer;
  }
  #phish-alert:hover .phish-close { opacity: 0.7; }
  .phish-dots span {
    display: inline-block; animation: phish-blink 1.2s infinite; color: #aab4ff;
  }
  .phish-dots span:nth-child(2) { animation-delay: 0.2s; }
  .phish-dots span:nth-child(3) { animation-delay: 0.4s; }
  #phish-danger-bar {
    position: fixed; top: 0; left: 0; right: 0; z-index: 2147483646; height: 3px;
    background: linear-gradient(90deg, #ff1a1a, #ff6b00, #ff1a1a);
    background-size: 200% 100%; animation: phish-bar-slide 2s linear infinite;
  }
  #phish-alert.phish-safe {
    background: linear-gradient(135deg, #0a1a0a 0%, #112d11 100%);
    border: 1.5px solid rgba(60,255,60,0.4);
  }
  #phish-alert.phish-safe .phish-label   { color: #90ff90; }
  #phish-alert.phish-safe .phish-title   { color: #44ff44; }
  #phish-alert.phish-safe .phish-sub     { color: #aaffaa; }
  #phish-alert.phish-safe .phish-icon-wrap::before {
    content: ''; position: absolute; width: 44px; height: 44px;
    border-radius: 50%; border: 2px solid rgba(60,255,60,0.5);
    animation: phish-pulse 1.6s ease-out infinite;
  }
  @keyframes phish-slide-in {
    from { transform: translateX(calc(100% + 30px)); opacity: 0; }
    to   { transform: translateX(0); opacity: 1; }
  }
  @keyframes phish-pulse {
    0%   { transform: scale(0.85); opacity: 0.8; }
    70%  { transform: scale(1.5);  opacity: 0; }
    100% { transform: scale(1.5);  opacity: 0; }
  }
  @keyframes phish-blink {
    0%, 80%, 100% { opacity: 0.2; }
    40%           { opacity: 1; }
  }
  @keyframes phish-bar-slide {
    0%   { background-position: 0% 0; }
    100% { background-position: 200% 0; }
  }
  @keyframes phish-fade-out {
    to { opacity: 0; transform: translateX(20px); }
  }
`,u="http://127.0.0.1:8000/predict";let l=null,s=null,n=!1,o=!0,p=null,a=null;const m=location.hostname.includes("mail.google"),g=location.hostname.includes("outlook")||location.hostname.includes("microsoft");function b(){if(m){const e=document.querySelector(".hP"),i=document.querySelector(".ii.gt");return!e||!i?null:e.innerText.trim()+`
`+i.innerText.trim()}if(g){const e=document.querySelector('[aria-label="Message subject"]')||document.querySelector(".SubjectLine")||document.querySelector('[data-testid="subject"]')||document.querySelector("h1.f3"),i=document.querySelector('[aria-label="Message body"]')||document.querySelector(".ReadingPaneContent")||document.querySelector('[data-testid="message-body"]')||document.querySelector("div[class*='messageBody']");return!e||!i?null:e.innerText.trim()+`
`+i.innerText.trim()}return null}function h(){if(document.getElementById("phish-styles"))return;const e=document.createElement("style");e.id="phish-styles",e.textContent=f,document.head.appendChild(e)}function t(){const e=document.getElementById("phish-alert"),i=document.getElementById("phish-danger-bar");e&&(e.style.animation="phish-fade-out 0.25s ease forwards",setTimeout(()=>{const r=document.getElementById("phish-alert");r&&r.remove()},260)),i&&i.remove()}function d(){h();let e=document.getElementById("phish-alert");e||(e=document.createElement("div"),e.id="phish-alert",document.body.appendChild(e)),e.className="phish-checking",e.innerHTML=`
    <div class="phish-icon-wrap"><span class="phish-icon">🔍</span></div>
    <div class="phish-body">
      <span class="phish-label">Analyzing</span>
      <span class="phish-title">Scanning email<span class="phish-dots"><span>.</span><span>.</span><span>.</span></span></span>
      <span class="phish-sub">Checking for phishing signals</span>
    </div>`,e.style.animation="none",e.offsetHeight,e.style.animation=""}function y(){if(h(),!document.getElementById("phish-danger-bar")){const i=document.createElement("div");i.id="phish-danger-bar",document.body.appendChild(i)}let e=document.getElementById("phish-alert");e||(e=document.createElement("div"),e.id="phish-alert",document.body.appendChild(e)),e.className="phish-danger",e.innerHTML=`
    <div class="phish-icon-wrap"><span class="phish-icon">☠️</span></div>
    <div class="phish-body">
      <span class="phish-label">Warning · Threat Detected</span>
      <span class="phish-title">Phishing Email</span>
      <span class="phish-sub">Do not click links or share info</span>
    </div>
    <span class="phish-close">✕</span>`,e.style.animation="none",e.offsetHeight,e.style.animation="",e.querySelector(".phish-close").onclick=i=>{i.stopPropagation(),t()},s&&clearTimeout(s),s=setTimeout(t,12e3)}function x(){h();let e=document.getElementById("phish-alert");e||(e=document.createElement("div"),e.id="phish-alert",document.body.appendChild(e)),e.className="phish-error",e.innerHTML=`
    <div class="phish-icon-wrap"><span class="phish-icon">⚠️</span></div>
    <div class="phish-body">
      <span class="phish-label">Server Offline</span>
      <span class="phish-title">API not reachable</span>
      <span class="phish-sub">Run: uvicorn api:app --port 8000</span>
    </div>
    <span class="phish-close">✕</span>`,e.style.animation="none",e.offsetHeight,e.style.animation="",e.querySelector(".phish-close").onclick=i=>{i.stopPropagation(),t()},s&&clearTimeout(s),s=setTimeout(t,6e3)}function v(){h();let e=document.getElementById("phish-alert");e||(e=document.createElement("div"),e.id="phish-alert",document.body.appendChild(e)),e.className="phish-safe",e.innerHTML=`
    <div class="phish-icon-wrap"><span class="phish-icon">✅</span></div>
    <div class="phish-body">
      <span class="phish-label">Verified</span>
      <span class="phish-title">Email Safe</span>
      <span class="phish-sub">No phishing indicators found</span>
    </div>
    <span class="phish-close">✕</span>`,e.style.animation="none",e.offsetHeight,e.style.animation="",e.querySelector(".phish-close").onclick=i=>{i.stopPropagation(),t()},s&&clearTimeout(s),s=setTimeout(t,4e3)}function k(){if(c())try{chrome.storage.local.get(["phishCount"],e=>{chrome.storage.local.set({phishCount:(e.phishCount||0)+1})})}catch{}}async function E(e){if(!(n||!o)){n=!0,d();try{const i=await fetch(u,{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({text:e})});if(!i.ok)throw new Error(`HTTP ${i.status}`);(await i.json()).prediction===0?(y(),k()):v()}catch(i){i instanceof TypeError&&i.message.includes("fetch")?x():t()}finally{n=!1}}}function c(){try{return typeof chrome<"u"&&!!chrome.runtime&&!!chrome.runtime.id}catch{return!1}}function T(e,i){try{c()?chrome.storage.local.get(e,i):i({})}catch{i({})}}function w(){a||(a=new MutationObserver(()=>{clearTimeout(p),S(),p=setTimeout(()=>{if(!c()){C();return}if(!o)return;const e=b();e&&e!==l&&(l=e,E(e))},600)}),a.observe(document.body,{childList:!0,subtree:!0}))}function S(){if(!n)return;document.getElementById("phish-alert")||d()}function C(){a&&(a.disconnect(),a=null),clearTimeout(p),t()}try{chrome.runtime.onMessage.addListener(e=>{e.type==="SET_ENABLED"&&(o=e.enabled,o||(l=null,n=!1,t()))})}catch{}T(["enabled"],e=>{o=e.enabled!==!1,w()});
})()
