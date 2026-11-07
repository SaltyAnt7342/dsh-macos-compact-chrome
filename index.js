/**
 * Host half of the macOS compact chrome bundle.
 *
 * The whole capability lives in the browser: a small stylesheet that only
 * applies inside the macOS desktop shell, scoped by a `data-*` marker on the
 * document element. Nothing runs on the Host, so this plugin registers no
 * service, tool, or event.
 */
export function apply() {}
