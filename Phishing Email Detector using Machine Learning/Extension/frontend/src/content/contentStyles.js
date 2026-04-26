// contentStyles.js — CSS injected into the host page by content.js
// Extracted here to keep content.js clean and this file independently editable.

export const CONTENT_STYLES = `
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
`;
