---
title: "Windows compatibility scan should be import-safe and side-effect-free"
date: 2026-04-25
category: developer-experience
module: developer-tooling
problem_type: developer_experience
component: tooling
severity: medium
applies_when:
  - "脚本既要能作为 CLI 执行，也要能被测试或其他工具导入复用"
  - "扫描或报告生成工具默认会写入仓库文件"
  - "工作区包含 .worktrees/ 或 vendor/ 这类会放大扫描噪音的目录"
tags:
  - windows-compat
  - side-effects
  - cli
  - testing
  - developer-experience
---

# Windows compatibility scan should be import-safe and side-effect-free

## Context

`scripts/windows-compat-scan.ts` 原本在模块顶层直接执行扫描并写入 `docs/async-progress/WINDOWS_COMPAT_SCAN_REPORT.md`。这让它可以直接作为脚本运行，但也让任何测试导入、工具复用或类型检查都可能触发写报告的副作用。

这类脚本在开发流程里很常见：同一份逻辑既需要 CLI 入口，也需要可测试的纯函数。关键约束是默认命令行为不能破坏既有工作流，但导入模块和 dry-run 必须不写文件。

## Guidance

把扫描脚本拆成三层：

- **纯扫描层**：`runScan` 只读取文件并返回 `{ findings, shFiles }`。
- **渲染层**：`renderReport` 只把扫描结果转成 Markdown 字符串。
- **CLI 层**：`runCli` 负责解析参数、决定是否写文件，并只在 `import.meta.main` 时执行。

CLI 仍保留无参数默认行为：写入 `docs/async-progress/WINDOWS_COMPAT_SCAN_REPORT.md`。新增显式的无写入路径用于测试和人工检查：

```bash
bun run scripts/windows-compat-scan.ts --no-write
bun run scripts/windows-compat-scan.ts --dry-run
bun run scripts/windows-compat-scan.ts --output tmp/windows-report.md
bun run scripts/windows-compat-scan.ts --config scripts/windows-compat-scan-config.json
```

目录排除要用路径语义，而不是简单字符串前缀。默认排除 `.worktrees/**` 和 `vendor/**`，同时要保证仓库根目录下的普通文件名如 `vendor.sh` 不会被误排除。

## Why This Matters

导入即执行的脚本会让测试变脆：只要测试文件 import 了被测函数，就可能改写真实报告文件。它还会污染 review diff，让开发者难以区分真正的代码改动和扫描时间戳造成的报告 churn。

把副作用限制在 CLI 入口后，脚本可以同时满足三个场景：

- 作为日常命令运行时，继续生成默认报告。
- 作为库导入时，不写任何文件。
- 作为验证步骤运行时，可以用 `--no-write` 检查扫描逻辑而不制造 diff。

## When to Apply

- CLI 脚本需要被测试直接导入函数时。
- 报告生成脚本默认会写入仓库内的 Markdown、JSON 或缓存文件时。
- 扫描工具需要在 worktree、vendored dependency 或 release workspace 中运行时。
- 需要保留旧的默认命令行为，但新增 side-effect-free 验证入口时。

## Examples

推荐结构：

```ts
export async function runScan(options: RunScanOptions = {}): Promise<ScanResult> {
  // 只负责扫描和返回结构化结果
}

export function renderReport(result: ScanResult): string {
  // 只负责渲染字符串
}

export async function runCli(args = process.argv.slice(2)): Promise<ScanResult> {
  // 只在这里决定是否 writeFile
}

if (import.meta.main) {
  runCli().catch((err) => {
    console.error("Scan failed:", err)
    process.exit(1)
  })
}
```

对应测试应该覆盖：

- `await import(scriptPath)` 不会创建默认报告。
- `--no-write` 和 `--dry-run` 不会写报告。
- `--output <path>` 写到指定路径，不写默认路径。
- 无参数仍写默认报告，保护旧工作流。
- `.worktrees/` 和 `vendor/` 目录被排除，但 `vendor.sh` 这类普通文件仍会被扫描。

## Related

- [docs/solutions/integrations/windows-gbk-emoji-and-file-mode-fix-2026-04-23.md](../integrations/windows-gbk-emoji-and-file-mode-fix-2026-04-23.md)
- [docs/solutions/agent-friendly-cli-principles.md](../agent-friendly-cli-principles.md)
