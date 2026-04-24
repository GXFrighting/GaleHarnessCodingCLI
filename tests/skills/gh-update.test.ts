import { readFileSync } from "fs"
import path from "path"
import { describe, expect, test } from "bun:test"

// gh-update should use Claude Code's plugin update command rather than manually
// deleting marketplace cache directories.

describe("gh-update SKILL.md", () => {
  const skillPath = path.join(
    process.cwd(),
    "plugins/galeharness-cli/skills/gh-update/SKILL.md",
  )
  const body = readFileSync(skillPath, "utf8")

  test("uses claude plugin update instead of cache deletion", () => {
    expect(body).toContain("claude plugin update galeharness-cli@{marketplace-name}")
    expect(body).toContain("${CLAUDE_SKILL_DIR}")
    expect(body).not.toContain("rm -rf")
    expect(body).not.toContain("${CLAUDE_PLUGIN_ROOT}")
  })
})
