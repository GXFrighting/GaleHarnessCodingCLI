---
title: "compound-engineering-plugin upstream sync 工作流配置"
date: 2026-04-22
category: workflow-issues
module: upstream-sync
problem_type: workflow_issue
component: development_workflow
severity: medium
applies_when:
  - 首次配置或更新 compound-engineering-plugin 的 upstream sync baseline
  - 需要批量同步 upstream commits 到 GaleHarnessCodingCLI
  - 修复 upstream sync 相关的 Windows CI 失败
tags:
  - upstream-sync
  - compound-engineering
  - generate-batch
  - cross-platform
---

# compound-engineering-plugin upstream sync 工作流配置

## Context

PR #35 (`feat(compound-sync): add per-commit upstream sync workflow`) 合并后，仓库具备了从 `compound-engineering-plugin` upstream 批量同步 commits 的能力。该工作流包含三个核心脚本：

- `scripts/upstream-sync/generate-batch.py` — 生成按 commit 分组的 sync batch（raw patches + adapted patches + metadata）
- `scripts/upstream-sync/adapt-patch.py` — 自动替换 upstream 路径/命名空间为 GaleHarnessCLI 专用名称
- `scripts/upstream-sync/apply-patch-to-worktree.sh` — 在独立 worktree 中安全应用 adapted patch

首次配置时，需要修正 `.upstream-repo` 指向本地 upstream checkout，并更新 `.upstream-ref` 到正确的 baseline commit。此外，Windows CI 因换行符（CRLF vs LF）问题导致测试失败，需要额外修复。

## Guidance

### 1. 配置 upstream 仓库路径

`.upstream-repo` 必须指向**本地文件系统路径**，而非 HTTPS URL。脚本会检查该路径下的 `.git` 目录。

```bash
# 正确
/Users/wangrenzhu/work/compound-engineering-plugin

# 错误（脚本会报 "Upstream repo path is invalid"）
https://github.com/EveryInc/compound-engineering-plugin.git
```

### 2. 设置 baseline commit

`.upstream-ref` 中存放的是 upstream 仓库的 commit SHA，表示"已同步到此处"。generate-batch.py 会基于此 SHA 发现 `baseline..HEAD` 之间的新 commits。

```bash
echo "b104ce46bea4b1b9b0e9cfbdd9203dbc5a0aa510" > .upstream-ref
```

**注意**：baseline 必须是 upstream 仓库历史中的真实 commit，否则 `ensure_commit_exists()` 会抛出错误。

### 3. 运行 generate-batch.py

```bash
python3 scripts/upstream-sync/generate-batch.py \
  --target-repo . \
  --upstream-repo /Users/wangrenzhu/work/compound-engineering-plugin
```

输出目录结构：

```
.context/galeharness-cli/upstream-sync/YYYY-MM-DD/
├── raw/
│   ├── 0001-feat-xxx.patch
│   └── 0002-fix-yyy.patch
├── adapted/
│   ├── 0001-feat-xxx.patch
│   └── 0002-fix-yyy.patch
├── commit-range.txt
└── README.md
```

- `raw/` — 保留 upstream 原始 diff，用于追溯
- `adapted/` — 经过 `adapt-patch.py` 重命名后的 patch，可直接应用到 GaleHarnessCLI
- `commit-range.txt` — 记录 batch 的 commit 范围与 `next_baseline_candidate`

### 4. 应用 patches

按 README.md 中的顺序，为每个 patch 创建独立 worktree 并应用：

```bash
bash scripts/upstream-sync/apply-patch-to-worktree.sh \
  .context/galeharness-cli/upstream-sync/YYYY-MM-DD/adapted/0001-feat-xxx.patch
```

### 5. 更新 baseline

所有 patches 验证并合并后，手动将 `.upstream-ref` 更新为 `commit-range.txt` 中的 `next_baseline_candidate`。

## Why This Matters

- **追溯性**：per-commit 的 raw patch 保留了 upstream 的完整意图，便于 review 时对照
- **隔离性**：在独立 worktree 中应用 patch，避免污染主工作区
- **自动化**：机械性的路径替换（`compound-engineering` → `galeharness-cli`）由脚本完成，减少人工错误
- **跨平台一致性**：显式控制换行符（`newline="\n"`）和 `.gitattributes` 保证 Windows/macOS/Linux 输出一致

## When to Apply

- upstream `compound-engineering-plugin` 发布了需要同步的新 commits
- 需要批量迁移 upstream 的 skill/agent 重命名或结构调整
- 修复 upstream sync 脚本本身的跨平台问题

## Examples

### 修正 `.upstream-repo` 配置

```diff
- https://github.com/wangrenzhu-ola/GaleHarnessCLI
+ /Users/wangrenzhu/work/compound-engineering-plugin
```

### Windows CI 换行符修复（generate-batch.py）

```python
# 写入文件时强制使用 LF，避免 Windows 下生成 CRLF
(batch_dir / "commit-range.txt").write_text(
    "\n".join(lines) + "\n", encoding="utf-8", newline="\n"
)
```

### 测试断言中的换行符规范化

```typescript
const fileContent = (await fs.readFile(path.join(repoRoot, "file.txt"), "utf8"))
  .replace(/\r\n/g, "\n");
expect(fileContent).toBe("line 1\n");
```

## Related

- PR #35: `feat(compound-sync): add per-commit upstream sync workflow`
- `scripts/upstream-sync/generate-batch.py`
- `scripts/upstream-sync/adapt-patch.py`
- `scripts/upstream-sync/apply-patch-to-worktree.sh`
- `scripts/upstream-sync/rename-rules.json`
