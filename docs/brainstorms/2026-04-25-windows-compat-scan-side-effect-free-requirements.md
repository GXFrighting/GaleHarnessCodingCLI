# Windows 兼容扫描只读运行需求

Created: 2026-04-25
Mode: Lightweight

## 背景

`scripts/windows-compat-scan.ts` 负责扫描仓库中的 Windows 兼容性风险。当前扫描器在被测试导入时会执行主流程，并默认写入 `docs/async-progress/WINDOWS_COMPAT_SCAN_REPORT.md`，导致 `bun test` 产生文档污染。同时默认排除规则不完整，历史上曾扫描到 `.worktrees/review-pr-68/vendor/...`，带来大量与当前分支无关的噪声。

## 目标

- 让扫描器支持在 CI 和测试中只读运行，不写仓库报告。
- 保持人工运行 `bun run scripts/windows-compat-scan.ts` 时仍生成既有默认报告。
- 默认排除 `.worktrees/**` 和 `vendor/**`，避免扫描其他工作树或 vendored 依赖。
- 增加测试覆盖，确保只读、显式输出和默认报告生成语义清晰。

## 范围

本次只改 Windows 兼容扫描器、配置和相关测试。不做大规模重构，不改 release binary 主线，不改变扫描规则的核心匹配语义。

## 需求

- R1: 导入 `scripts/windows-compat-scan.ts` 不应触发扫描或写文件。
- R2: CLI 应支持等价只读模式，例如 `--no-write` 或 `--dry-run`，该模式打印报告但不写默认报告文件。
- R3: CLI 应支持显式输出路径，例如 `--output <path>`，用于测试或 CI 将报告写到临时目录。
- R4: 无参数人工运行仍写入 `docs/async-progress/WINDOWS_COMPAT_SCAN_REPORT.md`。
- R5: 默认排除应包含 `.worktrees/**` 与 `vendor/**`，配置额外排除仍可叠加。
- R6: 测试不得污染 `docs/async-progress/WINDOWS_COMPAT_SCAN_REPORT.md`。

## 验收标准

- AE1: `bun test tests/windows-compat-scan.test.ts` 不修改 `docs/async-progress/WINDOWS_COMPAT_SCAN_REPORT.md`。
- AE2: 针对临时仓库结构的测试证明 `.worktrees/.../vendor/...` 不会被扫描。
- AE3: 只读模式运行扫描后不会创建默认报告文件。
- AE4: 显式 `--output` 或等价 API 可将报告写入临时路径。
- AE5: 默认写报告路径仍可用，保持既有人工运行体验。

## 非目标

- 不新增 Windows 兼容规则。
- 不改变现有报告内容结构，除非为路径或 CLI 输出说明做最小调整。
- 不接入新的 CI workflow。
- 不处理 release binary 或发布流程。

