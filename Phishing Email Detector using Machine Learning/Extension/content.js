const API_URL = "http://127.0.0.1:8000/predict";

let currentEmailText = null;
let alertTimeout     = null;
let isChecking       = false;
let isEnabled        = true;
let debounceTimer    = null;
let domObserver      = null;

// ─── Detect platform ─────────────────────────────────────────────────
const IS_GMAIL   = location.hostname.includes("mail.google");
const IS_OUTLOOK = location.hostname.includes("outlook") ||
                   location.hostname.includes("microsoft");

// ─── Email extractors ────────────────────────────────────────────────
function preprocessEmail() {
  if (IS_GMAIL) {
    const subjectEl = document.querySelector(".hP");
    const bodyEl    = document.querySelector(".ii.gt");
    if (!subjectEl || !bodyEl) return null;
    return subjectEl.innerText.trim() + "\n" + bodyEl.innerText.trim();
  }
  if (IS_OUTLOOK) {
    const subjectEl =
      document.querySelector('[aria-label="Message subject"]') ||
      document.querySelector(".SubjectLine") ||
      document.querySelector('[data-testid="subject"]') ||
      document.querySelector("h1.f3");
    const bodyEl =
      document.querySelector('[aria-label="Message body"]') ||
      document.querySelector(".ReadingPaneContent") ||
      document.querySelector('[data-testid="message-body"]') ||
      document.querySelector("div[class*='messageBody']");
    if (!subjectEl || !bodyEl) return null;
    return subjectEl.innerText.trim() + "\n" + bodyEl.innerText.trim();
  }
  return null;
}

// ─── Styles ──────────────────────────────────────────────────────────
function injectStyles() {
  if (document.getElementById("phish-styles")) return;
  const style = document.createElement("style");
  style.id = "phish-styles";
  style.textContent = `
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
    #phish-alert.phish-danger .phish-icon-wrap {
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
  `;
  document.head.appendChild(style);
}

// ─── Alert helpers ───────────────────────────────────────────────────
function removeAlert() {
  const el  = document.getElementById("phish-alert");
  const bar = document.getElementById("phish-danger-bar");
  if (el) {
    el.style.animation = "phish-fade-out 0.25s ease forwards";
    setTimeout(() => {
      const x = document.getElementById("phish-alert");
      if (x) x.remove();
    }, 260);
  }
  if (bar) bar.remove();
}

function showChecking() {
  injectStyles();
  let d = document.getElementById("phish-alert");
  if (!d) {
    d = document.createElement("div");
    d.id = "phish-alert";
    document.body.appendChild(d);
  }
  d.className = "phish-checking";
  d.innerHTML = `
    <div class="phish-icon-wrap"><span class="phish-icon">🔍</span></div>
    <div class="phish-body">
      <span class="phish-label">Analyzing</span>
      <span class="phish-title">Scanning email<span class="phish-dots"><span>.</span><span>.</span><span>.</span></span></span>
      <span class="phish-sub">Checking for phishing signals</span>
    </div>`;
  d.style.animation = "none";
  d.offsetHeight; // force reflow
  d.style.animation = "";
}

function showDanger() {
  injectStyles();
  if (!document.getElementById("phish-danger-bar")) {
    const bar = document.createElement("div");
    bar.id = "phish-danger-bar";
    document.body.appendChild(bar);
  }
  let d = document.getElementById("phish-alert");
  if (!d) {
    d = document.createElement("div");
    d.id = "phish-alert";
    document.body.appendChild(d);
  }
  d.className = "phish-danger";
  d.innerHTML = `
    <div class="phish-icon-wrap"><span class="phish-icon">☠️</span></div>
    <div class="phish-body">
      <span class="phish-label">Warning · Threat Detected</span>
      <span class="phish-title">Phishing Email</span>
      <span class="phish-sub">Do not click links or share info</span>
    </div>
    <span class="phish-close">✕</span>`;
  d.style.animation = "none";
  d.offsetHeight;
  d.style.animation = "";
  d.querySelector(".phish-close").onclick = (e) => {
    e.stopPropagation();
    removeAlert();
  };
  if (alertTimeout) clearTimeout(alertTimeout);
  alertTimeout = setTimeout(removeAlert, 12000);
}

function showApiError() {
  injectStyles();
  let d = document.getElementById("phish-alert");
  if (!d) {
    d = document.createElement("div");
    d.id = "phish-alert";
    document.body.appendChild(d);
  }
  d.className = "phish-error";
  d.innerHTML = `
    <div class="phish-icon-wrap"><span class="phish-icon">⚠️</span></div>
    <div class="phish-body">
      <span class="phish-label">Server Offline</span>
      <span class="phish-title">API not reachable</span>
      <span class="phish-sub">Run: uvicorn api:app --port 8000</span>
    </div>
    <span class="phish-close">✕</span>`;
  d.style.animation = "none";
  d.offsetHeight;
  d.style.animation = "";
  d.querySelector(".phish-close").onclick = (e) => {
    e.stopPropagation();
    removeAlert();
  };
  // Auto-dismiss error after 6s
  if (alertTimeout) clearTimeout(alertTimeout);
  alertTimeout = setTimeout(removeAlert, 6000);
}

// ─── Increment phishing counter ───────────────────────────────────────
function incrementPhishCount() {
  if (!isContextValid()) return;
  try {
    chrome.storage.local.get(["phishCount"], (result) => {
      chrome.storage.local.set({ phishCount: (result.phishCount || 0) + 1 });
    });
  } catch (e) { /* context gone */ }
}

// ─── Core check ──────────────────────────────────────────────────────
// Add this new function after showApiError()
function showSafe() {
  injectStyles();
  let d = document.getElementById("phish-alert");
  if (!d) {
    d = document.createElement("div");
    d.id = "phish-alert";
    document.body.appendChild(d);
  }
  d.className = "phish-safe";
  d.innerHTML = `
    <div class="phish-icon-wrap"><span class="phish-icon">✅</span></div>
    <div class="phish-body">
      <span class="phish-label">Verified</span>
      <span class="phish-title">Email Safe</span>
      <span class="phish-sub">No phishing indicators found</span>
    </div>
    <span class="phish-close">✕</span>`;
  d.style.animation = "none";
  d.offsetHeight;
  d.style.animation = "";
  d.querySelector(".phish-close").onclick = (e) => {
    e.stopPropagation();
    removeAlert();
  };
  // Auto-dismiss safe notification after 4 seconds
  if (alertTimeout) clearTimeout(alertTimeout);
  alertTimeout = setTimeout(removeAlert, 4000);
}

// Replace your existing checkEmail function with this:
async function checkEmail(emailText) {
  if (isChecking || !isEnabled) return;
  isChecking = true;
  showChecking();
  try {
    const res = await fetch(API_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ text: emailText }),
    });

    if (!res.ok) throw new Error(`HTTP ${res.status}`);

    const data = await res.json();

    if (data.prediction === 0) {
      showDanger();
      incrementPhishCount();
    } else {
      // Show safe notification instead of immediately removing
      showSafe();
    }
  } catch (err) {
    // Only show error if it's a network/connection failure (API not running)
    if (err instanceof TypeError && err.message.includes("fetch")) {
      showApiError();
    } else {
      removeAlert();
    }
  } finally {
    isChecking = false;
  }
}

// ─── Context safety guard ────────────────────────────────────────────
function isContextValid() {
  try {
    return typeof chrome !== "undefined" && !!chrome.runtime && !!chrome.runtime.id;
  } catch (e) {
    return false;
  }
}

function safeStorageGet(keys, cb) {
  try {
    if (isContextValid()) {
      chrome.storage.local.get(keys, cb);
    } else {
      cb({});
    }
  } catch (e) {
    cb({});
  }
}

// ─── Observer ────────────────────────────────────────────────────────
function startObserver() {
  if (domObserver) return;
  domObserver = new MutationObserver(() => {
    clearTimeout(debounceTimer);
    ensureAlertVisible();

    debounceTimer = setTimeout(() => {
      if (!isContextValid()) { stopObserver(); return; }
      if (!isEnabled) return;
      const emailText = preprocessEmail();
      if (emailText && emailText !== currentEmailText) {
        currentEmailText = emailText;
        checkEmail(emailText);
      }
    }, 600);
  });
  domObserver.observe(document.body, { childList: true, subtree: true });
}
function ensureAlertVisible() {
  if (!isChecking) return;

  const alert = document.getElementById("phish-alert");
  if (!alert) {
    showChecking(); // recreate it if Gmail removed it
  }
}
function stopObserver() {
  if (domObserver) { domObserver.disconnect(); domObserver = null; }
  clearTimeout(debounceTimer);
  removeAlert();
}

// ─── Message listener from popup ─────────────────────────────────────
try {
  chrome.runtime.onMessage.addListener((msg) => {
    if (msg.type === "SET_ENABLED") {
      isEnabled = msg.enabled;
      if (!isEnabled) {
        currentEmailText = null;
        isChecking = false;
        removeAlert();
      }
    }
  });
} catch (e) { /* context gone */ }

// ─── Init ─────────────────────────────────────────────────────────────
safeStorageGet(["enabled"], (result) => {
  isEnabled = result.enabled !== false; // default: true
  startObserver();
});