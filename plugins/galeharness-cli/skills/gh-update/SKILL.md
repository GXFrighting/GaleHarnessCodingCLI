---
name: gh:update
description: |
  Check if the GaleHarnessCLI plugin is up to date and fix stale cache if not.
  Use when the user says "update gale harness", "check gale harness version",
  "gh update", "is gale harness up to date", "update gh plugin", or reports issues
  that might stem from a stale GaleHarnessCLI plugin version. This skill only works
  in Claude Code — it relies on the plugin harness cache layout.
disable-model-invocation: true
ce_platforms: [claude]
---

# Check & Fix Plugin Version

Verify the installed GaleHarnessCLI plugin version matches the latest released
version, and fix stale marketplace/cache state if it doesn't. Claude Code only.

> **Note:** This skill updates the **plugin cache** only. To update the CLI binary
> itself, run `gale-harness update` from your terminal.

## Pre-resolved context

The sections below contain pre-resolved data. Only the **Plugin root path**
determines whether this session is Claude Code — if it contains an error
sentinel, an empty value, or a literal `${CLAUDE_PLUGIN_ROOT}` string, tell the
user this skill only works in Claude Code and stop. The other sections may
contain error sentinels even in valid Claude Code sessions; the decision logic
below handles those cases.

`CLAUDE_PLUGIN_ROOT` points at the currently-loaded plugin version directory
(e.g. `~/.claude/plugins/cache/<marketplace>/galeharness-cli/<version>`),
so the plugin cache directory that holds every cached version is its parent.

**Plugin root path:**
!`echo "${CLAUDE_PLUGIN_ROOT}" 2>/dev/null || echo '__CE_UPDATE_ROOT_FAILED__'`

**Latest released version:**
!`gh release list --repo wangrenzhu-ola/GaleHarnessCLI --limit 30 --json tagName --jq '[.[] | select(.tagName | startswith("galeharness-cli-v"))][0].tagName | sub("galeharness-cli-v";"")' 2>/dev/null || echo '__CE_UPDATE_VERSION_FAILED__'`

**Plugin cache directory:**
!`case "$(dirname "${CLAUDE_PLUGIN_ROOT:-}")" in */cache/*/galeharness-cli) dirname "${CLAUDE_PLUGIN_ROOT}" ;; *) echo '__CE_UPDATE_CACHE_FAILED__' ;; esac`

**Cached version folder(s):**
!`case "$(dirname "${CLAUDE_PLUGIN_ROOT:-}")" in */cache/*/galeharness-cli) ls "$(dirname "${CLAUDE_PLUGIN_ROOT}")" 2>/dev/null ;; *) echo '__CE_UPDATE_CACHE_FAILED__' ;; esac`

## Decision logic

### 1. Platform gate

If **Plugin root path** contains `__CE_UPDATE_ROOT_FAILED__`, a literal
`${CLAUDE_PLUGIN_ROOT}` string, or is empty: tell the user this skill requires Claude Code
and stop. No further action.

### 2. Compare versions

If **Latest released version** contains `__CE_UPDATE_VERSION_FAILED__`: tell the user the
latest release could not be fetched (gh may be unavailable or rate-limited) and stop.

If **Cached version folder(s)** contains `__CE_UPDATE_CACHE_FAILED__`: no marketplace cache
exists. Tell the user: "No marketplace cache found — this appears to be a local dev checkout
or fresh install." and stop.

Take the **latest released version** and the **cached folder list**.

**Up to date** — exactly one cached folder exists AND its name matches the latest version:
- Tell the user: "GaleHarnessCLI **v{version}** is installed and up to date."

**Out of date or corrupted** — multiple cached folders exist, OR the single folder name
does not match the latest version. Use the **Plugin cache directory** value from above
as the delete path.

**Clear the stale cache:**
```bash
rm -rf "<plugin-cache-directory>"
```

Tell the user:
- "GaleHarnessCLI was on **v{old}** but **v{latest}** is available."
- "Cleared the plugin cache. Now run `/plugin marketplace update` in this session, then restart Claude Code to pick up v{latest}."
- "To also update the CLI binary, run `gale-harness update` from your terminal."
