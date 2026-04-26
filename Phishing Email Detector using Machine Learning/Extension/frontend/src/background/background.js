// background.js — PhishGuard service worker
//
// Currently no background logic is needed — all state is managed via
// chrome.storage.local which is accessible from both content scripts
// and the popup directly.
//
// This file is registered in manifest.json as the MV3 service worker.
// Add any future background tasks (alarms, idle detection, etc.) here.
