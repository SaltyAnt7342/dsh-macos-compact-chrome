# Verification

Verified against the **real macOS Desktop renderer** (not the browser tab) on
2026-11-07, with DeepSeek Harness `0.2.2-rc.1` (official, stock sidebar) on
macOS arm64.

## Method

1. A throwaway `DSH_HOME` profile was created and the plugin installed as a
   local bundle (`dsh plugin --profile desktop add <checkout>`).
2. The official desktop app was launched against that profile with the renderer
   debugging port enabled; the page under test is the app's own
   `dsh-app://app/` window (the real preload sets `data-platform="darwin"` and
   provides the desktop bridges, so this is the actual target environment).
3. Chrome DevTools Protocol read the live DOM geometry and captured the
   screenshots in this folder; the preference switch was toggled and read back.

The stock app window's sidebar was 280px wide in this run.

## Measured geometry

| Element | Stock (plugin off) | Compact (plugin on) |
| --- | --- | --- |
| Sidebar column display | `flex` | `grid` (rows `46px 32px 1fr 40px`) |
| Brand row | `y=40`, height 60 | `y=0`, height 52 (rides the window strip) |
| New Session button | `256×38` capsule | `32×32` icon button, `y=54` |
| Panel list | stacked, starts `y=148` | one icon row, starts `y=54` |
| Workspace / session region starts | `y=268` | `y=88` |

That moves the workspace and session history **180px higher** at a 280px
sidebar width.

## Behaviour checks

- `data-dsh-compact-chrome` on `<html>`: absent when off, present when on.
- The stylesheet tag is mounted with the plugin and removed with it.
- The Settings → General switch flips the marker **without a reload**; the
  column display changes `grid → flex` and back.
- Settings row renders natively in Simplified Chinese and English:
  “macOS 紧凑侧栏” with its description, between 性能与用量 and the Session Log
  row.
- The collapsed 56px rail keeps the stock layout (the rules only match the
  expanded markup, and the root's `collapsed` class disables them).
- A build or another plugin that already reshapes the sidebar (for example the
  author's patched compact build) does not match the rule's four direct-child
  guards, so the stylesheet stays inert instead of breaking that UI.

## Environment note

The plugin is a macOS **desktop** feature: the rules are gated on
`html[data-platform='darwin']`, which the desktop preload sets. In an ordinary
browser tab the attribute is absent and the plugin does nothing — that is
intentional, not a failure.
