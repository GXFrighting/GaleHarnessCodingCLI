import { readFileSync } from "fs"
import path from "path"
import { describe, expect, test } from "bun:test"

// Regression guard for upstream issue #556.
//
// `CLAUDE_PLUGIN_ROOT` is set by the Claude Code harness to the currently-loaded
// plugin version directory (e.g. `~/.claude/plugins/cache/<marketplace>/galeharness-cli/<version>`).
// It is NOT the plugins cache root. Appending `/cache/<anything>/galeharness-cli/`
// onto it produces a path that never exists, which causes the cache-probe to fail
// and emit the `__CE_UPDATE_CACHE_FAILED__` sentinel on every healthy install.

describe("gh-update SKILL.md", () => {
  const skillPath = path.join(
    process.cwd(),
    "plugins/galeharness-cli/skills/gh-update/SKILL.md",
  )
  const body = readFileSync(skillPath, "utf8")

  test("does not append a /cache/<marketplace>/ suffix onto CLAUDE_PLUGIN_ROOT", () => {
    const antiPattern = /\$\{CLAUDE_PLUGIN_ROOT\}\/cache\//
    expect(
      antiPattern.test(body),
      "gh-update/SKILL.md reintroduced the ${CLAUDE_PLUGIN_ROOT}/cache/... antipattern -- derive the cache dir from dirname \"${CLAUDE_PLUGIN_ROOT}\" instead.",
    ).toBe(false)
  })
})
