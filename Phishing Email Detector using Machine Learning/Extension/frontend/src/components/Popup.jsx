import React, { useState, useEffect, useRef, useCallback } from "react";
import "./Popup.css";
import ShieldIcon from "./ShieldIcon.jsx";
import { storageGet, storageSet, sendToggleToTabs } from "../utils/storage.js";

const API_HEALTH = "http://127.0.0.1:8000/health";

// ─── Animated counter hook — mirrors the original animateCount() ──────
function useAnimatedCount(target, duration = 500) {
  const [display, setDisplay] = useState(target);
  const prevRef = useRef(target);
  const rafRef  = useRef(null);

  useEffect(() => {
    const from = prevRef.current;
    const to   = target;
    prevRef.current = to;

    if (from === to) {
      setDisplay(to);
      return;
    }

    const start = performance.now();

    function step(now) {
      const t    = Math.min((now - start) / duration, 1);
      const ease = 1 - Math.pow(1 - t, 3); // cubic ease-out
      setDisplay(Math.round(from + (to - from) * ease));
      if (t < 1) rafRef.current = requestAnimationFrame(step);
    }

    rafRef.current = requestAnimationFrame(step);
    return () => cancelAnimationFrame(rafRef.current);
  }, [target, duration]);

  return display;
}

// ─── ApiRow sub-component ─────────────────────────────────────────────
function ApiRow({ status, onRetry }) {
  const textMap = {
    checking: "Checking local API…",
    online:   "Local API online ✓",
    offline:  "API offline — run uvicorn",
  };

  return (
    <div className="api-row">
      <span className={`api-dot ${status}`}>◉</span>
      <span className={`api-text ${status}`}>{textMap[status]}</span>
      <button className="api-retry" title="Retry connection" onClick={onRetry}>
        ↺
      </button>
    </div>
  );
}

// ─── CounterCard sub-component ────────────────────────────────────────
function CounterCard({ count, onReset }) {
  // Animate from whatever the previous value was → new value
  const displayCount = useAnimatedCount(count);

  return (
    <div className={`counter-card${count > 0 ? " has-threats" : ""}`}>
      <div className="counter-left">
        <span className="counter-icon">☠️</span>
        <div className="counter-text">
          <span className="counter-label">Phishing Emails Caught</span>
          <span className="counter-sub">All-time detections</span>
        </div>
      </div>
      <div className="counter-right">
        <span className="counter-num">{displayCount}</span>
        <button className="counter-reset" title="Reset counter" onClick={onReset}>
          ↺
        </button>
      </div>
    </div>
  );
}

// ─── Main Popup component ─────────────────────────────────────────────
export default function Popup() {
  const [enabled,    setEnabled]    = useState(true);
  const [phishCount, setPhishCount] = useState(0);
  const [apiStatus,  setApiStatus]  = useState("checking"); // "checking" | "online" | "offline"

  // ── Load state from storage on mount ──
  useEffect(() => {
    storageGet(["enabled", "phishCount"]).then((result) => {
      setEnabled(result.enabled !== false);
      setPhishCount(result.phishCount || 0);
    });
    checkApiHealth();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // ── Live counter updates (mirrors chrome.storage.onChanged listener) ──
  useEffect(() => {
    function handleStorageChange(changes) {
      if (changes.phishCount) {
        setPhishCount(changes.phishCount.newValue || 0);
      }
    }
    chrome.storage.onChanged.addListener(handleStorageChange);
    return () => chrome.storage.onChanged.removeListener(handleStorageChange);
  }, []);

  // ── API health check — same logic as original checkApiHealth() ──
  const checkApiHealth = useCallback(async () => {
    setApiStatus("checking");
    try {
      const res = await fetch(API_HEALTH, { method: "GET" });
      setApiStatus(res.ok ? "online" : "offline");
    } catch {
      setApiStatus("offline");
    }
  }, []);

  // ── Toggle handler — same logic as original toggleBtn click ──
  const handleToggle = useCallback(() => {
    storageGet(["enabled"]).then((result) => {
      const next = !(result.enabled !== false);
      storageSet({ enabled: next }).then(() => {
        setEnabled(next);
        sendToggleToTabs(next);
      });
    });
  }, []);

  // ── Reset counter — same logic as original resetBtn click ──
  const handleReset = useCallback(() => {
    storageSet({ phishCount: 0 }).then(() => {
      setPhishCount(0);
    });
  }, []);

  return (
    <div className={`pg-body${enabled ? "" : " disabled"}`}>

      {/* Shield */}
      <div className="shield-wrap">
        <ShieldIcon enabled={enabled} />
      </div>

      <h1 className="pg-title">PhishGuard</h1>
      <p className="pg-subtitle">AI-powered email threat detection</p>

      <div className="pg-divider" />

      {/* Toggle row */}
      <div className="toggle-row">
        <div className="toggle-info">
          <span className="toggle-label">
            {enabled ? "Protection Active" : "Protection Disabled"}
          </span>
          <span className="toggle-desc">
            {enabled ? "Monitoring your emails" : "Click to re-enable"}
          </span>
        </div>
        <button
          className={`toggle-btn${enabled ? "" : " off"}`}
          aria-label="Toggle protection"
          onClick={handleToggle}
        >
          <span className="toggle-knob" />
        </button>
      </div>

      {/* Status row */}
      <div className="status-row">
        <span className={`status-dot${enabled ? "" : " off"}`} />
        <span className={`status-text${enabled ? "" : " off"}`}>
          {enabled ? "Active on Gmail & Outlook" : "Detection paused"}
        </span>
      </div>

      <div className="pg-divider" />

      {/* API status */}
      <ApiRow status={apiStatus} onRetry={checkApiHealth} />

      <div className="pg-divider" />

      {/* Counter card */}
      <CounterCard count={phishCount} onReset={handleReset} />

      <div className="pg-divider" />

      {/* Legend */}
      <div className="legend">
        <div className="legend-item danger">
          <span className="legend-icon">⚠️</span>
          <div>
            <span className="legend-label">Phishing Detected</span>
            <span className="legend-desc">Alert shown — threat found</span>
          </div>
        </div>
        <div className="legend-item safe">
          <span className="legend-icon">🔍</span>
          <div>
            <span className="legend-label">Scanning</span>
            <span className="legend-desc">Brief scan, silent if safe</span>
          </div>
        </div>
      </div>

      {/* Footer */}
      <div className="pg-footer">
        <span>v1.2 · Local API · Gmail &amp; Outlook</span>
      </div>

    </div>
  );
}
