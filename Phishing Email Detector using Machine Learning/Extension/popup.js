// popup.js — PhishGuard

const API_HEALTH = "http://127.0.0.1:8000/health";

const toggleBtn   = document.getElementById("toggle-btn");
const toggleLabel = document.getElementById("toggle-label");
const toggleDesc  = document.getElementById("toggle-desc");
const statusDot   = document.getElementById("status-dot");
const statusText  = document.getElementById("status-text");
const shieldCheck = document.getElementById("shield-check");
const shieldOff   = document.getElementById("shield-off");
const phishCount  = document.getElementById("phish-count");
const resetBtn    = document.getElementById("reset-btn");
const apiDot      = document.getElementById("api-dot");
const apiText     = document.getElementById("api-text");
const apiRetry    = document.getElementById("api-retry");

// ─── API health check ─────────────────────────────────────────────────
async function checkApiHealth() {
  apiDot.className  = "api-dot checking";
  apiText.textContent = "Checking local API…";
  try {
    const res = await fetch(API_HEALTH, { method: "GET" });
    if (res.ok) {
      apiDot.className    = "api-dot online";
      apiText.textContent = "Local API online ✓";
    } else {
      throw new Error("not ok");
    }
  } catch {
    apiDot.className    = "api-dot offline";
    apiText.textContent = "API offline — run uvicorn";
  }
}

// ─── Counter animation ────────────────────────────────────────────────
function animateCount(el, from, to, duration = 500) {
  if (from === to) { el.textContent = to; return; }
  const start = performance.now();
  function step(now) {
    const t    = Math.min((now - start) / duration, 1);
    const ease = 1 - Math.pow(1 - t, 3);
    el.textContent = Math.round(from + (to - from) * ease);
    if (t < 1) requestAnimationFrame(step);
  }
  requestAnimationFrame(step);
}

function updateCounterStyle(count) {
  document.getElementById("counter-card")
    .classList.toggle("counter-has-threats", count > 0);
}

// ─── Toggle UI ────────────────────────────────────────────────────────
function applyState(enabled) {
  if (enabled) {
    document.body.classList.remove("disabled");
    toggleBtn.classList.remove("off");
    toggleLabel.textContent = "Protection Active";
    toggleDesc.textContent  = "Monitoring your emails";
    statusDot.classList.remove("off");
    statusText.classList.remove("off");
    statusText.textContent  = "Active on Gmail & Outlook";
    if (shieldCheck) shieldCheck.removeAttribute("display");
    if (shieldOff)   shieldOff.setAttribute("display", "none");
  } else {
    document.body.classList.add("disabled");
    toggleBtn.classList.add("off");
    toggleLabel.textContent = "Protection Disabled";
    toggleDesc.textContent  = "Click to re-enable";
    statusDot.classList.add("off");
    statusText.classList.add("off");
    statusText.textContent  = "Detection paused";
    if (shieldCheck) shieldCheck.setAttribute("display", "none");
    if (shieldOff)   shieldOff.removeAttribute("display");
  }
}

function sendToggleToTabs(enabled) {
  const prefixes = [
    "https://mail.google.com/",
    "https://outlook.cloud.microsoft/",
    "https://outlook.office.com/",
    "https://outlook.office365.com/",
  ];
  chrome.tabs.query({}, (tabs) => {
    tabs.forEach((tab) => {
      if (prefixes.some((p) => (tab.url || "").startsWith(p))) {
        chrome.tabs.sendMessage(tab.id, { type: "SET_ENABLED", enabled }).catch(() => {});
      }
    });
  });
}

// ─── Init ─────────────────────────────────────────────────────────────
chrome.storage.local.get(["enabled", "phishCount"], (result) => {
  applyState(result.enabled !== false);
  const count = result.phishCount || 0;
  animateCount(phishCount, 0, count, 700);
  updateCounterStyle(count);
});

checkApiHealth();

// ─── Toggle click ─────────────────────────────────────────────────────
toggleBtn.addEventListener("click", () => {
  chrome.storage.local.get(["enabled"], (result) => {
    const next = !(result.enabled !== false);
    chrome.storage.local.set({ enabled: next }, () => {
      applyState(next);
      sendToggleToTabs(next);
    });
  });
});

// ─── Reset counter ────────────────────────────────────────────────────
resetBtn.addEventListener("click", () => {
  const prev = parseInt(phishCount.textContent) || 0;
  chrome.storage.local.set({ phishCount: 0 }, () => {
    animateCount(phishCount, prev, 0, 400);
    updateCounterStyle(0);
  });
});

// ─── API retry button ─────────────────────────────────────────────────
apiRetry.addEventListener("click", () => checkApiHealth());

// ─── Live counter update ──────────────────────────────────────────────
chrome.storage.onChanged.addListener((changes) => {
  if (changes.phishCount) {
    const prev = parseInt(phishCount.textContent) || 0;
    const next = changes.phishCount.newValue || 0;
    animateCount(phishCount, prev, next, 500);
    updateCounterStyle(next);
  }
});