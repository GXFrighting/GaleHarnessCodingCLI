---
title: Windows 兼容扫描只读运行实现计划
status: active
origin: docs/brainstorms/2026-04-25-windows-compat-scan-side-effect-free-requirements.md
created: 2026-04-25
---

# Windows 兼容扫描只读运行实现计划

## 问题框架

当前 `scripts/windows-compat-scan.ts` 同时承担库函数和 CLI 的角色，但文件末尾无条件执行 `main()`。这使 `tests/windows-compat-scan.test.ts` 导入函数时触发全仓扫描并写入 `docs/async-progress/WINDOWS_COMPAT_SCAN_REPORT.md`。另外默认排除规则缺少 `.worktrees/**`，历史上会扫到其他工作树中的 vendored 文件，降低信号质量。

## 范围边界

- 修改 `scripts/windows-compat-scan.ts`，提供只读/输出路径能力，并避免导入副作用。
- 修改 `scripts/windows-compat-scan-config.json`，补齐默认或配置排除。
- 修改 `tests/windows-compat-scan.test.ts`，覆盖只读、输出路径、默认排除和默认报告写入。
- 不新增扫描规则，不改 release binary，不改 CI 主线。

## 设计决策

- 将扫描主流程拆成可导出的 `runScan` / `renderReport` 形态，测试直接调用 API，避免启动子进程和污染仓库。
- CLI 参数采用简单显式选项：`--no-write`、`--dry-run`、`--output <path>`、`--config <path>`。`--dry-run` 作为 `--no-write` 别名，降低使用成本。
- 默认写入路径保持 `docs/async-progress/WINDOWS_COMPAT_SCAN_REPORT.md`，只在直接执行脚本且未传 `--no-write` 时发生。
- 默认排除放在代码常量中包含 `.worktrees` 和 `vendor`，配置文件保留 `vendor/**` 兼容现有意图。

## 实施单元

### U1: 拆分扫描器执行入口

Files:
- Modify: `scripts/windows-compat-scan.ts`
- Test: `tests/windows-compat-scan.test.ts`

Approach:
- 导出扫描结果类型、默认报告路径、`walkFiles` 或 `scanWorkspace` 等可测试函数。
- 使用直接运行检测保护 `main()`，确保模块导入无副作用。
- 允许扫描根目录作为参数，避免测试依赖真实仓库根。

Test scenarios:
- 导入模块不会创建或改写默认报告。
- 临时目录扫描可以发现普通 `.sh` 文件。

### U2: 增加 CLI 只读和输出路径

Files:
- Modify: `scripts/windows-compat-scan.ts`
- Test: `tests/windows-compat-scan.test.ts`

Approach:
- 添加轻量参数解析，支持 `--no-write` / `--dry-run` / `--output <path>` / `--config <path>`。
- `--output` 写到显式路径；`--no-write` 不写任何报告文件；无参数保持默认报告写入。

Test scenarios:
- 只读模式不写默认报告。
- 显式 output 写入临时路径。
- 默认配置仍写入默认报告路径。

### U3: 补齐默认排除并覆盖噪声场景

Files:
- Modify: `scripts/windows-compat-scan.ts`
- Modify: `scripts/windows-compat-scan-config.json`
- Test: `tests/windows-compat-scan.test.ts`

Approach:
- 默认排除加入 `.worktrees`、`.worktrees/**`、`vendor`、`vendor/**`。
- 继续合并配置中的额外排除，不破坏现有配置。

Test scenarios:
- `.worktrees/review-pr-68/vendor/noisy.sh` 不出现在扫描结果。
- `vendor/noisy.sh` 不出现在扫描结果。
- 普通目录下的 `.sh` 仍会被扫描。

## 验证

- `bun test tests/windows-compat-scan.test.ts`
- 如时间可承受，运行 `bun test`
- `bun run release:validate`
- `git status --short` 确认没有非预期污染 `docs/async-progress/WINDOWS_COMPAT_SCAN_REPORT.md`

