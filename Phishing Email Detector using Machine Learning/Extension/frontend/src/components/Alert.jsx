/**
 * Alert.jsx
 *
 * This file exists for completeness of the component structure.
 * The actual alert UI is rendered imperatively by content.js into
 * the host page's DOM (not via React) because content scripts
 * cannot use React without injecting a full React runtime into
 * every page — which would be heavyweight and unnecessary.
 *
 * If you later want to refactor content.js to use a React shadow-DOM
 * approach, you would render <Alert /> from here.
 *
 * For now the alert variants and their markup are defined in
 * src/content/content.js (showChecking, showDanger, showSafe, showApiError).
 */

export const ALERT_TYPES = {
  CHECKING: "phish-checking",
  DANGER:   "phish-danger",
  SAFE:     "phish-safe",
  ERROR:    "phish-error",
};

export const ALERT_CONTENT = {
  checking: {
    icon:     "🔍",
    label:    "Analyzing",
    title:    "Scanning email",
    sub:      "Checking for phishing signals",
    hasClose: false,
    hasDots:  true,
  },
  danger: {
    icon:     "☠️",
    label:    "Warning · Threat Detected",
    title:    "Phishing Email",
    sub:      "Do not click links or share info",
    hasClose: true,
    hasDots:  false,
  },
  safe: {
    icon:     "✅",
    label:    "Verified",
    title:    "Email Safe",
    sub:      "No phishing indicators found",
    hasClose: true,
    hasDots:  false,
  },
  error: {
    icon:     "⚠️",
    label:    "Server Offline",
    title:    "API not reachable",
    sub:      "Run: uvicorn api:app --port 8000",
    hasClose: true,
    hasDots:  false,
  },
};
