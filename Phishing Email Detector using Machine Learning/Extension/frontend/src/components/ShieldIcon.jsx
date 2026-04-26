import React from "react";

/**
 * ShieldIcon — renders the animated SVG shield.
 * Shows a checkmark when enabled, an X when disabled.
 * Identical visual to the original popup.html SVG.
 */
export default function ShieldIcon({ enabled }) {
  return (
    <svg
      className="shield-icon"
      viewBox="0 0 48 56"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path
        d="M24 2L4 10V26C4 38.15 12.95 49.48 24 52C35.05 49.48 44 38.15 44 26V10L24 2Z"
        fill="url(#sg)"
        stroke="rgba(100,120,255,0.4)"
        strokeWidth="1"
      />
      {enabled ? (
        <path
          d="M15 28l6 6 12-12"
          stroke="#aab4ff"
          strokeWidth="2.5"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      ) : (
        <path
          d="M18 22l12 12M30 22L18 34"
          stroke="#555"
          strokeWidth="2.5"
          strokeLinecap="round"
        />
      )}
      <defs>
        <linearGradient
          id="sg"
          x1="4"
          y1="2"
          x2="44"
          y2="52"
          gradientUnits="userSpaceOnUse"
        >
          <stop stopColor="#1a1a3a" />
          <stop offset="1" stopColor="#0d0d20" />
        </linearGradient>
      </defs>
    </svg>
  );
}
