import { describe, expect, test } from "bun:test"
import { existsSync } from "fs"
import { mkdir, mkdtemp, readFile, rm, writeFile } from "fs/promises"
import { tmpdir } from "os"
import path from "path"
import {
  buildRules,
  DEFAULT_REPORT_PATH,
  getExclusions,
  loadConfig,
  runCli,
  runScan,
  scanContent,
} from "../scripts/windows-compat-scan"

async function withTempWorkspace(run: (rootDir: string) => Promise<void>) {
  const rootDir = await mkdtemp(path.join(tmpdir(), "windows-compat-scan-"))
  try {
    await run(rootDir)
  } finally {
    await rm(rootDir, { recursive: true, force: true })
  }
}

const quietStdout = {
  log() {},
  error() {},
}

describe("windows-compat-scan", () => {
  describe("rules", () => {
    const rules = buildRules()

    function findRules(lines: string[], ext: string): string[] {
      return scanContent(lines, rules, ext).map((f) => f.rule)
    }

    test("bash-shebang detects #!/bin/bash", () => {
      expect(findRules(["#!/bin/bash"], ".sh")).toEqual(["bash-shebang"])
    })

    test("bash-shebang detects #!/usr/bin/env bash", () => {
      expect(findRules(["#!/usr/bin/env bash"], ".sh")).toEqual(["bash-shebang"])
    })

    test("bash-shebang ignores #!/bin/sh", () => {
      expect(findRules(["#!/bin/sh"], ".sh")).toEqual([])
    })

    test("command-v detects bash builtin", () => {
      expect(findRules(["if command -v node >/dev/null; then"], ".sh")).toEqual(["command-v"])
    })

    test("brew-install detects macOS package manager", () => {
      expect(findRules(["brew install node"], ".sh")).toEqual(["brew-install"])
    })

    test("rm-rf detects recursive removal", () => {
      expect(findRules(["rm -rf dist/"], ".sh")).toEqual(["rm-rf"])
    })

    test("rm-rf ignores rm without flags", () => {
      expect(findRules(["rm file.txt"], ".sh")).toEqual([])
    })

    test("mkdir-p detects recursive mkdir", () => {
      expect(findRules(["mkdir -p dist/assets"], ".sh")).toEqual(["mkdir-p"])
    })

    test("hardcoded-slash detects / in path.join", () => {
      expect(findRules(["path.join('src', '/components')"], ".ts")).toEqual(["hardcoded-slash"])
    })

    test("hardcoded-slash ignores normal path.join", () => {
      expect(findRules(["path.join('src', 'components')"], ".ts")).toEqual([])
    })

    test("process-env-home detects Unix home var", () => {
      expect(findRules(["const home = process.env.HOME"], ".ts")).toEqual(["process-env-home"])
    })

    test("colon-in-path detects colon in path.join", () => {
      expect(findRules(["path.join('dir', 'name:with:colons')"], ".ts")).toEqual(["colon-in-path"])
    })

    test("bash-array detects array assignment", () => {
      expect(findRules(["arr=(one two three)"], ".sh")).toEqual(["bash-array"])
    })

    test("bash-array ignores non-array parentheses", () => {
      expect(findRules(["echo (foo)"], ".sh")).toEqual([])
    })

    test("source-bash detects source command", () => {
      expect(findRules(["source ~/.bashrc"], ".sh")).toEqual(["source-bash"])
    })

    test("source-bash ignores source in comments", () => {
      expect(findRules(["// source of truth"], ".ts")).toEqual([])
    })
  })

  describe("python-subprocess-bash", () => {
    const rules = buildRules()

    function findRules(lines: string[], ext: string): string[] {
      return scanContent(lines, rules, ext).map((f) => f.rule)
    }

    test("detects subprocess.run with bash list", () => {
      expect(findRules(['subprocess.run(["bash", "-c", "echo hi"])'], ".py")).toEqual(["python-subprocess-bash"])
    })

    test("detects subprocess.Popen with sh list", () => {
      expect(findRules(["subprocess.Popen(['sh', '-c', 'echo hi'])"], ".py")).toEqual(["python-subprocess-bash"])
    })

    test("detects subprocess.call with bash string", () => {
      expect(findRules(['subprocess.call("bash -c echo hi")'], ".py")).toEqual(["python-subprocess-bash"])
    })

    test("detects subprocess.check_output with sh", () => {
      expect(findRules(['subprocess.check_output(["sh", "-c", "whoami"])'], ".py")).toEqual(["python-subprocess-bash"])
    })

    test("detects subprocess.check_call with bash", () => {
      expect(findRules(['subprocess.check_call(["bash", "script.sh"])'], ".py")).toEqual(["python-subprocess-bash"])
    })

    test("ignores subprocess.run with python", () => {
      expect(findRules(['subprocess.run(["python", "script.py"])'], ".py")).toEqual([])
    })

    test("ignores subprocess.run with cmd.exe", () => {
      expect(findRules(['subprocess.run(["cmd.exe", "/c", "dir"])'], ".py")).toEqual([])
    })

    test("ignores subprocess in Python comments", () => {
      expect(findRules(["# subprocess.run(['bash', '-c', 'echo hi'])"], ".py")).toEqual([])
    })
  })

  describe("config overrides", () => {
    test("severity override changes finding severity", () => {
      const overridden = buildRules({ rules: { "bash-shebang": { severity: "warn" } } })
      const findings = scanContent(["#!/bin/bash"], overridden, ".sh")
      expect(findings).toHaveLength(1)
      expect(findings[0].severity).toBe("warn")
    })

    test("disabled rule removes finding", () => {
      const overridden = buildRules({ rules: { "bash-shebang": { enabled: false } } })
      const findings = scanContent(["#!/bin/bash"], overridden, ".sh")
      expect(findings).toHaveLength(0)
    })

    test("unknown rule id in config is ignored", () => {
      const overridden = buildRules({ rules: { "unknown-rule": { severity: "info" } } })
      expect(overridden).toHaveLength(buildRules().length)
    })

    test("getExclusions merges defaults and extras", () => {
      const exclusions = getExclusions({ exclude: ["custom/**"] })
      expect(exclusions).toContain("node_modules")
      expect(exclusions).toContain(".worktrees/**")
      expect(exclusions).toContain("vendor/**")
      expect(exclusions).toContain("custom/**")
    })

    test("getExclusions returns defaults when config is empty", () => {
      const exclusions = getExclusions()
      expect(exclusions).toContain("node_modules")
      expect(exclusions).toContain(".git")
      expect(exclusions).toContain(".worktrees")
      expect(exclusions).toContain("vendor")
    })

    test("loadConfig returns undefined for missing file", async () => {
      const config = await loadConfig("/nonexistent/path/config.json")
      expect(config).toBeUndefined()
    })
  })

  describe("scan execution", () => {
    test("importing the module does not write the default report", async () => {
      await withTempWorkspace(async (rootDir) => {
        const scriptPath = path.resolve(import.meta.dir, "../scripts/windows-compat-scan.ts")
        const proc = Bun.spawn({
          cmd: ["bun", "-e", `await import(${JSON.stringify(scriptPath)})`],
          cwd: rootDir,
          stdout: "ignore",
          stderr: "pipe",
        })

        const exitCode = await proc.exited
        const stderr = await new Response(proc.stderr).text()
        expect(stderr).toBe("")
        expect(exitCode).toBe(0)
        expect(existsSync(path.join(rootDir, DEFAULT_REPORT_PATH))).toBe(false)
      })
    })

    test("--no-write does not write the default report", async () => {
      await withTempWorkspace(async (rootDir) => {
        await writeFile(path.join(rootDir, "script.sh"), "#!/bin/bash\n")

        await runCli(["--no-write"], { rootDir, stdout: quietStdout })

        expect(existsSync(path.join(rootDir, DEFAULT_REPORT_PATH))).toBe(false)
      })
    })

    test("--dry-run is an alias for --no-write", async () => {
      await withTempWorkspace(async (rootDir) => {
        await writeFile(path.join(rootDir, "script.sh"), "#!/bin/bash\n")

        await runCli(["--dry-run"], { rootDir, stdout: quietStdout })

        expect(existsSync(path.join(rootDir, DEFAULT_REPORT_PATH))).toBe(false)
      })
    })

    test("--output writes to the requested path", async () => {
      await withTempWorkspace(async (rootDir) => {
        await writeFile(path.join(rootDir, "script.sh"), "#!/bin/bash\n")

        await runCli(["--output", "tmp/report.md"], { rootDir, stdout: quietStdout })

        const reportPath = path.join(rootDir, "tmp/report.md")
        expect(existsSync(reportPath)).toBe(true)
        expect(await readFile(reportPath, "utf8")).toContain("# Windows Compatibility Scan Report")
        expect(existsSync(path.join(rootDir, DEFAULT_REPORT_PATH))).toBe(false)
      })
    })

    test("default run writes the default report", async () => {
      await withTempWorkspace(async (rootDir) => {
        await writeFile(path.join(rootDir, "script.sh"), "#!/bin/bash\n")

        await runCli([], { rootDir, stdout: quietStdout })

        const reportPath = path.join(rootDir, DEFAULT_REPORT_PATH)
        expect(existsSync(reportPath)).toBe(true)
        expect(await readFile(reportPath, "utf8")).toContain("script.sh")
      })
    })

    test("default exclusions skip .worktrees and vendor", async () => {
      await withTempWorkspace(async (rootDir) => {
        await writeFile(path.join(rootDir, "regular.sh"), "#!/bin/bash\n")
        await writeFile(path.join(rootDir, "vendor.sh"), "#!/bin/bash\n")
        await mkdir(path.join(rootDir, ".worktrees/review-pr-68/vendor"), { recursive: true })
        await mkdir(path.join(rootDir, "vendor"), { recursive: true })
        await writeFile(path.join(rootDir, ".worktrees/review-pr-68/vendor/noisy.sh"), "#!/bin/bash\n")
        await writeFile(path.join(rootDir, "vendor/noisy.sh"), "#!/bin/bash\n")

        const result = await runScan({ rootDir })

        expect(result.shFiles).toContain("regular.sh")
        expect(result.shFiles).toContain("vendor.sh")
        expect(result.shFiles).not.toContain(".worktrees/review-pr-68/vendor/noisy.sh")
        expect(result.shFiles).not.toContain("vendor/noisy.sh")
        expect(result.findings.map((finding) => finding.file)).toContain("regular.sh")
      })
    })
  })
})
