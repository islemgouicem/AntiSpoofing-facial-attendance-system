// content.js — PhishGuard
// Logic is IDENTICAL to the original. Only change: styles are imported
// from contentStyles.js instead of being defined inline.

import { CONTENT_STYLES } from "./contentStyles.js";

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

// ─── Inject styles into the host page ────────────────────────────────
function injectStyles() {
  if (document.getElementById("phish-styles")) return;
  const style = document.createElement("style");
  style.id = "phish-styles";
  style.textContent = CONTENT_STYLES;
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
  if (alertTimeout) clearTimeout(alertTimeout);
  alertTimeout = setTimeout(removeAlert, 6000);
}

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
  if (alertTimeout) clearTimeout(alertTimeout);
  alertTimeout = setTimeout(removeAlert, 4000);
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
      showSafe();
    }
  } catch (err) {
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
