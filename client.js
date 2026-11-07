/**
 * Browser half of the macOS compact chrome bundle.
 *
 * The shell draws the sidebar as a flex column: a 52px window strip, a 60px
 * brand row, a full-width New Session bar, then one stacked row per global
 * panel. On a laptop that eats most of the column before the session history
 * starts. This module turns the column into a compact arrangement — without
 * touching the shipped component — by:
 *
 * 1. marking the document element while the preference is on and the shell
 *    reports macOS (`data-platform="darwin"`, set by the desktop preload);
 * 2. injecting one scoped stylesheet. The stylesheet keys off stable pieces:
 *    the `topStrip`/`logoRow`/`newSession`/`panelList`/`regionArea`/`footArea`
 *    class tokens (CSS-module builds keep the local name) and the root's own
 *    `collapsed` token, so the collapsed 56px rail keeps its shipped layout;
 * 3. adding a Settings → General switch that flips the marker and persists the
 *    choice in localStorage.
 *
 * No DOM nodes are moved and no shipped component is imported, so a DSH UI
 * change can at worst retire a selector rather than break the shell.
 */
window.__ModuleLoader__.load({
  id: 'dsh-macos-compact-chrome',
  factory(require) {
    const React = require('react')
    const primitives = require('@deepseek-ai/dsh-client-ui-primitives')
    const h = React.createElement
    const Switch = primitives.Switch

    const PREF_KEY = 'dsh-macos-compact-chrome'
    const PREF_ON = 'on'
    const PREF_OFF = 'off'
    const ATTR = 'data-dsh-compact-chrome'
    const NS = 'dsh-macos-compact-chrome'

    /** Copy used when the Client locale service is unavailable. */
    const COPY = {
      en: {
        title: 'Compact macOS sidebar',
        description: 'Fold the brand row, the New Session bar and the panel list into one compact control row under the window strip. Applies inside the macOS desktop app only.',
      },
      zh: {
        title: 'macOS 紧凑侧栏',
        description: '把品牌行、新会话按钮和面板列表合成窗口标题区下方的一行紧凑控制条；仅在 macOS 桌面版生效。',
      },
    }

    /* The selectors below read shipped class *tokens*: production CSS modules
       build names as `<hash>_<localName>` (for example `iACr-W_panelList`), so
       `[class*='panelList']` keeps matching across builds while ignoring the
       hash. Every rule is prefixed by the darwin platform marker and our own
       `data-dsh-compact-chrome` marker, so the stylesheet is inert until the
       profile enables the plugin and the switch is on. */
    /* One compound root condition keeps the stylesheet inert on any markup
       that is not the stock expanded sidebar (for example a build that already
       ships its own compact arrangement): the four direct children plus the
       absence of the rail's `collapsed` token. */
    const ROOT = `div:has(> [class*='topStrip']):has(> [class*='logoRow']):has(> [class*='newSession']):has(> [class*='panelList']):not([class*='collapsed'])`
    const SCOPE = `html[data-platform='darwin'][${ATTR}] ${ROOT}`

    const CSS = `
/* Sidebar column: window strip + one control row + content. */
${SCOPE} {
  display: grid !important;
  grid-template-columns: minmax(0, 1fr) auto;
  grid-template-rows: min-content min-content minmax(0, 1fr) min-content;
  row-gap: 2px;
  position: relative !important;
}

${SCOPE} > [class*='topStrip'] {
  grid-row: 1;
  grid-column: 1 / -1;
}

/* The brand row stops being a 60px band and rides the window strip instead:
   it keeps the official mark and wordmark between the traffic lights and the
   two right-hand controls. It stays a drag surface, so pointer events fall
   through to the strip underneath. */
${SCOPE} > [class*='logoRow'] {
  position: absolute !important;
  top: 0 !important;
  left: 84px !important;
  right: 56px !important;
  height: 52px !important;
  margin: 0 !important;
  padding: 0 !important;
  justify-content: flex-start !important;
  overflow: hidden !important;
  pointer-events: none !important;
  z-index: 1;
}

/* The brand artwork scales down to the strip: the wordmark becomes a 15px
   SVG beside an 18px whale mark instead of the 24px wordmark of the stock
   row. The fallback text (a dev build with no brand plugin) follows the same
   size. */
${SCOPE} > [class*='logoRow'] [class*='brandMark'] svg {
  width: 18px !important;
  height: 18px !important;
}

${SCOPE} > [class*='logoRow'] [class*='brandName'] svg {
  width: auto !important;
  height: 15px !important;
}

${SCOPE} > [class*='logoRow'] [class*='fallbackBrandName'] {
  font-size: 15px !important;
  line-height: 18px !important;
}

${SCOPE} > [class*='logoRow'] [class*='brandIdentity'] {
  gap: 5px !important;
}

/* New Session: the full-width capsule becomes a 32px icon button on the
   control row, left of the panel icons. */
${SCOPE} > [class*='newSession'] {
  grid-row: 2;
  grid-column: 1;
  align-self: center;
  justify-self: start;
  width: 32px !important;
  height: 32px !important;
  min-height: 32px !important;
  margin: 0 !important;
  padding: 0 !important;
  gap: 0 !important;
  border-color: transparent !important;
  background: transparent !important;
  justify-content: center !important;
}

${SCOPE} > [class*='newSession']:hover {
  background-color: var(--dsw-alias-interactive-bg-hover) !important;
}

${SCOPE} > [class*='newSession'] [class*='newSessionContent'] > [class*='newSessionLabel'],
${SCOPE} > [class*='newSession'] > [class*='newSessionShortcut'] {
  display: none !important;
}

${SCOPE} > [class*='newSession'] [class*='newSessionLabelMask'],
${SCOPE} > [class*='newSession'] [class*='newSessionContent'] {
  flex: none !important;
  width: auto !important;
}

/* Panel list: stacked rows become one right-aligned icon row. */
${SCOPE} > [class*='panelList'] {
  grid-row: 2;
  grid-column: 2;
  align-self: center;
  display: flex !important;
  flex-direction: row !important;
  align-items: center !important;
  justify-content: flex-end !important;
  gap: 2px !important;
  margin: 0 !important;
  min-width: 0 !important;
  max-width: 100% !important;
  overflow-x: auto !important;
  overflow-y: hidden !important;
  scrollbar-width: none;
}

${SCOPE} > [class*='panelList']::-webkit-scrollbar {
  display: none;
}

${SCOPE} > [class*='panelList'] [class*='panelRow'] {
  width: 32px !important;
  height: 32px !important;
  min-height: 32px !important;
  padding: 0 !important;
  margin: 0 !important;
  border-inline: 0 !important;
  justify-content: center !important;
  flex: none !important;
}

${SCOPE} > [class*='panelList'] [class*='panelTitle'] {
  display: none !important;
}

${SCOPE} > [class*='panelList'] [class*='moreAnchor'] {
  display: flex !important;
  flex: none !important;
}

/* Content region and foot span both grid columns. */
${SCOPE} > [class*='regionArea'] {
  grid-row: 3;
  grid-column: 1 / -1;
  min-height: 0 !important;
  margin-right: 0 !important;
}

${SCOPE} > [class*='footArea'] {
  grid-row: 4;
  grid-column: 1 / -1;
}
`

    // ---- preference store -------------------------------------------------
    let memory = undefined
    const listeners = new Set()

    function storedValue() {
      try {
        return window.localStorage.getItem(PREF_KEY)
      } catch {
        return null
      }
    }

    function preferred() {
      const raw = storedValue()
      return raw === PREF_OFF ? false : true
    }

    function snapshot() {
      if (memory === undefined) memory = preferred()
      return memory
    }

    function subscribe(listener) {
      listeners.add(listener)
      return () => { listeners.delete(listener) }
    }

    function announce() {
      for (const listener of [...listeners]) listener()
    }

    /** Mirror the preference (and the shell platform) onto the document element. */
    function applyPreference() {
      const root = document.documentElement
      const darwin = root.getAttribute('data-platform') === 'darwin'
      if (darwin && snapshot()) root.setAttribute(ATTR, '')
      else root.removeAttribute(ATTR)
    }

    function setEnabled(next) {
      memory = next !== false
      try {
        window.localStorage.setItem(PREF_KEY, memory ? PREF_ON : PREF_OFF)
      } catch {}
      applyPreference()
      announce()
    }

    function useEnabled() {
      return React.useSyncExternalStore(subscribe, snapshot, snapshot)
    }

    // ---- localized copy ---------------------------------------------------
    /** Locale service captured at apply time; used when the slot's `t` has no dictionary. */
    let localeService

    /** Active language id from the locale service, falling back to the browser. */
    function activeLanguage() {
      try {
        const snapshot = localeService?.getSnapshot?.() ?? localeService?.getLocale?.()
        const active = snapshot && typeof snapshot === 'object' ? snapshot.active : undefined
        if (typeof active === 'string' && active !== '') return active
      } catch {}
      try { return String(navigator.language ?? 'en') } catch { return 'en' }
    }

    /** Fallback translator for the case where the slot-bound `t` looks up an empty dictionary. */
    function fallbackTranslate(key) {
      const table = /^zh/i.test(activeLanguage()) ? COPY.zh : COPY.en
      return table[key] ?? COPY.en[key] ?? key
    }

    /** Translate one key, preferring the slot's `t` but never printing the raw key. */
    function translateWith(props, key) {
      if (typeof props?.t === 'function') {
        try {
          const value = props.t(key)
          if (typeof value === 'string' && value !== key && value !== '') return value
        } catch {}
      }
      return fallbackTranslate(key)
    }

    // ---- Settings → General row ------------------------------------------
    const rowStyle = {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      gap: '24px',
      padding: '16px 0',
      borderBottom: '0.5px solid var(--dsw-alias-border-l2)',
    }
    const titleStyle = { fontSize: '14px', lineHeight: '20px' }
    const descriptionStyle = {
      marginTop: '4px',
      color: 'var(--dsw-alias-label-secondary)',
      fontSize: '12px',
      lineHeight: '18px',
    }

    function CompactChromeRow(props) {
      const enabled = useEnabled()
      const title = translateWith(props, 'title')
      return h('div', { style: rowStyle },
        h('div', null,
          h('div', { style: titleStyle }, title),
          h('div', { style: descriptionStyle }, translateWith(props, 'description')),
        ),
        h(Switch, {
          checked: enabled,
          label: title,
          onChange: (next) => { setEnabled(next) },
        }),
      )
    }

    // ---- plugin entry -----------------------------------------------------
    return {
      inject: ['slots', 'locale'],
      apply(ctx) {
        // The shell sets data-platform before client plugins apply, but re-run
        // the marker whenever the boot state changes so a reload path that
        // marks the platform late still gets the chrome.
        applyPreference()

        const locale = (() => {
          try {
            return ctx.locale ?? (typeof ctx.get === 'function' ? ctx.get('locale') : undefined)
          } catch {
            return undefined
          }
        })()
        localeService = locale

        if (locale !== undefined && locale !== null && typeof locale.register === 'function') {
          ctx.effect(() => locale.register(NS, 'en', COPY.en), 'macos-compact-chrome: en copy')
          ctx.effect(() => locale.register(NS, 'zh', COPY.zh), 'macos-compact-chrome: zh copy')
        }

        // Persisted preference and platform marker.
        ctx.effect(() => {
          const root = document.documentElement
          const onPlatform = () => { applyPreference() }
          const observer = new MutationObserver(onPlatform)
          observer.observe(root, { attributes: true, attributeFilter: ['data-platform'] })
          const onStorage = (event) => {
            if (event.key !== PREF_KEY && event.key !== null) return
            memory = undefined
            applyPreference()
            announce()
          }
          window.addEventListener('storage', onStorage)
          return () => {
            observer.disconnect()
            window.removeEventListener('storage', onStorage)
            root.removeAttribute(ATTR)
          }
        }, 'macos-compact-chrome: preference')

        // The stylesheet is inert without the marker attribute; cleanup removes
        // it with the plugin run.
        ctx.effect(() => {
          const tag = document.createElement('style')
          tag.setAttribute('data-plugin', 'dsh-macos-compact-chrome')
          tag.textContent = CSS
          document.head.append(tag)
          return () => { tag.remove() }
        }, 'macos-compact-chrome: styles')

        // Settings row; the General section may declare its slot after this
        // plugin applies, so inject instead of registering unconditionally.
        ctx.effect(() => ctx.slots.inject('settings.general.item', () => {
          const base = { name: 'settings.general.item', id: 'macos-compact-chrome', order: 35 }
          try {
            return ctx.slots.register({ ...base, locale: NS }, CompactChromeRow)
          } catch {
            return ctx.slots.register(base, CompactChromeRow)
          }
        }))
      },
    }
  },
})
