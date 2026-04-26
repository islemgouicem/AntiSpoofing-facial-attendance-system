// utils/storage.js — thin wrappers around chrome.storage.local

/**
 * Get one or more keys from local storage.
 * Returns a Promise that resolves to the result object.
 */
export function storageGet(keys) {
  return new Promise((resolve) => {
    chrome.storage.local.get(keys, resolve);
  });
}

/**
 * Set one or more key/value pairs in local storage.
 * Returns a Promise that resolves when done.
 */
export function storageSet(items) {
  return new Promise((resolve) => {
    chrome.storage.local.set(items, resolve);
  });
}

/**
 * Send a SET_ENABLED message to all open Gmail / Outlook tabs.
 */
export function sendToggleToTabs(enabled) {
  const prefixes = [
    "https://mail.google.com/",
    "https://outlook.cloud.microsoft/",
    "https://outlook.office.com/",
    "https://outlook.office365.com/",
  ];
  chrome.tabs.query({}, (tabs) => {
    tabs.forEach((tab) => {
      if (prefixes.some((p) => (tab.url || "").startsWith(p))) {
        chrome.tabs
          .sendMessage(tab.id, { type: "SET_ENABLED", enabled })
          .catch(() => {});
      }
    });
  });
}
