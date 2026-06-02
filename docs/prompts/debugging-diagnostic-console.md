# Debugging Diagnostic Console

A floating debug diagnostic console for Flutter web apps. Captures all console output, uncaught errors, and promise rejections in a glassmorphism UI overlay.

## Prompt

```
Add a floating debug diagnostic console to web/index.html for a Flutter web app. Requirements:

1. A small floating pill button (fixed, top-right, z-index 999999) showing status indicator dot + "Debugger" label + log count badge
2. Clicking the pill expands a full drawer panel (slides down from top, max 45vh height)
3. The drawer has:
   - Header with title "Diagnostic Engine", stats (Errors | Warnings | Logs), Copy, Clear, and Close buttons
   - Search/filter input bar
   - Filter pill buttons: All, Errors, Warnings, Logs
   - Auto-expand on error checkbox (default: on)
   - Scrollable log container
4. Intercept ALL console methods (log, warn, error, info) and capture to an array (max 300 entries)
5. Capture window 'error' and 'unhandledrejection' events
6. Each log entry shows: timestamp, type badge [LOG/WARN/ERROR/INFO], message
7. Color coding: errors=red, warnings=orange, info=cyan, logs=white
8. Glassmorphism dark theme: dark semi-transparent bg, blur backdrop, subtle borders
9. Status indicator dot pulses green (ok), yellow (warnings), or red (errors)
10. Copy button copies all logs to clipboard as text
11. Auto-expand drawer on first error if auto-expand is enabled
12. Store logs in window.jsbaDebugLogs array
13. Expose window.jsbaDebug object with toggle(), clear(), copy() methods
14. Self-initializing: works whether DOMContentLoaded has fired or not
15. All code wrapped in try/catch to never break the host app
16. Use CSS variables for theming, monospace font for logs, smooth transitions
17. Toast notification for copy success
```

## Usage

Paste the prompt into any coding assistant (Claude Code, Cursor, Copilot) when working on a Flutter web project. The assistant will inject the full HTML/CSS/JS diagnostic console into `web/index.html`.

## Features

- **Console interception**: Captures `console.log`, `console.warn`, `console.error`, `console.info`
- **Error capture**: Catches uncaught exceptions and unhandled promise rejections
- **Filtering**: Search by text, filter by log level
- **Auto-expand**: Drawer opens automatically on first error
- **Clipboard export**: Copy all logs as plain text
- **Non-invasive**: Wrapped in try/catch, never breaks the host app
- **Dark glassmorphism UI**: Semi-transparent, blurred backdrop, monospace logs

## Reference Implementation

See `web/index.html` in this project for the working implementation.
