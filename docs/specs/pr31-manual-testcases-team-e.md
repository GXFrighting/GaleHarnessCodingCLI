[tool] Grep
[tool] Grep
[tool_result] success
[tool] Glob
[tool_result] success
[tool_result] success
[tool] ReadFile
[tool] ReadFile
[tool_result] success
[tool] ReadFile
[tool_result] success
[tool_result] success
# PR #31 技能迁移与脚本变更 — 人工测试用例（团队 E）

> **测试范围**: 技能迁移一致性、脚本变更、回退机制、端到端场景  
> **测试文件**: `gh-brainstorm`, `gh-plan`, `gh-compound`, `gh-compound-refresh`, `gh-pr-description`, `dev-link.sh`, `dev-unlink.sh`, `dev-sync-skills.sh`, `setup.sh`, `setup.ps1`, `package.json`, `.gitignore`

---

## 一、技能迁移一致性测试

### TC-E-001. [gh-brainstorm] — resolve-path 获取 brainstorms 路径并写入文档
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: `gale-knowledge` 已在 PATH 中，全局知识仓库已初始化
- **测试步骤**:
  1. 在一个已初始化的 git 仓库中运行 `/gh:brainstorm 测试功能`
  2. 模拟技能执行到 Phase 3 (Capture the Requirements)
  3. 验证技能执行了 `gale-knowledge resolve-path --type brainstorms`
  4. 验证文档被写入到 resolve-path 返回的目录下（如 `~/.galeharness/knowledge/<project>/brainstorms/`）
  5. 验证文档写入后执行了 `gale-knowledge commit --project "<project>" --type brainstorm --title "<document-title>"`
- **预期结果**:
  - `resolve-path` 成功返回绝对路径
  - 文档写入路径为全局知识仓库路径，而非 `docs/brainstorms/`
  - `commit` 命令成功执行并返回提交哈希
- **关联文件**: `plugins/galeharness-cli/skills/gh-brainstorm/SKILL.md`

### TC-E-002. [gh-plan] — resolve-path 获取 plans 路径并写入计划文档
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: `gale-knowledge` 已在 PATH 中，全局知识仓库已初始化
- **测试步骤**:
  1. 运行 `/gh:plan 测试计划`
  2. 模拟技能执行到 Phase 5.2 (Write Plan File)
  3. 验证执行了 `gale-knowledge resolve-path --type plans`
  4. 验证计划文档被写入 resolve-path 返回的目录（如 `~/.galeharness/knowledge/<project>/plans/`）
  5. 验证文档写入后执行了 `gale-knowledge commit --project "<project>" --type plan --title "<plan-title>"`
- **预期结果**:
  - 计划文档写入全局知识仓库的 `plans/` 子目录
  - 文件名格式符合 `YYYY-MM-DD-NNN-<type>-<descriptive-name>-plan.md`
  - `commit` 成功，提交消息格式为 `docs(<project>/plan): <title>`
- **关联文件**: `plugins/galeharness-cli/skills/gh-plan/SKILL.md`

### TC-E-003. [gh-compound] — resolve-path 获取 solutions 路径并写入 solution 文档
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: `gale-knowledge` 已在 PATH 中，全局知识仓库已初始化
- **测试步骤**:
  1. 运行 `/gh:compound 测试问题修复`
  2. 模拟技能执行到 Phase 2 (Assembly & Write)
  3. 验证执行了 `gale-knowledge resolve-path --type solutions`
  4. 验证 solution 文档被写入 `<resolved-path>/[category]/` 下
  5. 验证写入后执行了 `gale-knowledge commit --project "<project>" --type solution --title "<frontmatter-title>"`
- **预期结果**:
  - 文档写入全局知识仓库的 `<project>/solutions/<category>/` 路径
  - `commit` 命令成功执行
  - HKTMemory Store (Phase 2.3) 和 knowledge commit 是分开的两个步骤，都执行
- **关联文件**: `plugins/galeharness-cli/skills/gh-compound/SKILL.md`

### TC-E-004. [gh-compound-refresh] — resolve-path 获取 solutions 路径只读扫描，无 commit
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: `gale-knowledge` 已在 PATH 中，全局知识仓库已初始化，且已有若干 solution 文档
- **测试步骤**:
  1. 运行 `/gh:compound-refresh`
  2. 验证技能开头执行了 `gale-knowledge resolve-path --type solutions`
  3. 验证所有扫描、读取、分类操作都基于 `$SOLUTIONS_DIR`（即 resolve-path 返回的路径）
  4. 验证整个 SKILL.md 流程中**不存在** `gale-knowledge commit` 步骤
  5. 验证在 discoverability check 中，当需要编辑 AGENTS.md 时，使用的是 `$SOLUTIONS_DIR` 变量
- **预期结果**:
  - 成功从全局仓库读取并扫描所有 `.md` 文件
  - 流程中**没有任何** knowledge commit 操作
  - Phase 5 (Commit Changes) 仅涉及 git commit，不涉及 `gale-knowledge commit`
- **关联文件**: `plugins/galeharness-cli/skills/gh-compound-refresh/SKILL.md`

---

## 二、回退机制测试

### TC-E-005. [gh-brainstorm] — gale-knowledge 不可用时回退到 docs/brainstorms/
- **优先级**: P0
- **测试类型**: 兼容性/回归
- **前置条件**: `gale-knowledge` **不在** PATH 中（或命令执行失败）
- **测试步骤**:
  1. 临时将 `gale-knowledge` 从 PATH 中移除（或重命名）
  2. 运行 `/gh:brainstorm 测试功能`
  3. 观察 Knowledge Repository Write Path 步骤的行为
  4. 验证技能是否回退到 `docs/brainstorms/` 作为写入路径
  5. 验证知识 commit 步骤被跳过且不阻塞流程
- **预期结果**:
  - `gale-knowledge resolve-path --type brainstorms` 失败后，技能回退到 `docs/brainstorms/`
  - 文档成功写入 `docs/brainstorms/<filename>.md`
  - 后续的 `gale-knowledge commit` 因命令不可用而被跳过，技能继续执行到 Phase 4 Handoff
  - 无报错或阻塞
- **关联文件**: `plugins/galeharness-cli/skills/gh-brainstorm/SKILL.md`

### TC-E-006. [gh-plan] — gale-knowledge 不可用时回退到 docs/plans/
- **优先级**: P0
- **测试类型**: 兼容性/回归
- **前置条件**: `gale-knowledge` **不在** PATH 中
- **测试步骤**:
  1. 临时移除 `gale-knowledge` 命令
  2. 运行 `/gh:plan 测试计划`
  3. 验证 `resolve-path` 失败后回退到 `docs/plans/`
  4. 验证 `commit` 步骤被跳过
- **预期结果**:
  - 文档写入 `docs/plans/YYYY-MM-DD-NNN-<type>-<name>-plan.md`
  - 流程不中断
- **关联文件**: `plugins/galeharness-cli/skills/gh-plan/SKILL.md`

### TC-E-007. [gh-compound] — gale-knowledge 不可用时回退到 docs/solutions/
- **优先级**: P0
- **测试类型**: 兼容性/回归
- **前置条件**: `gale-knowledge` **不在** PATH 中
- **测试步骤**:
  1. 临时移除 `gale-knowledge` 命令
  2. 运行 `/gh:compound 测试问题`
  3. 验证 `resolve-path` 失败后回退到 `docs/solutions/`
  4. 验证 `commit` 步骤被跳过
- **预期结果**:
  - 文档写入 `docs/solutions/[category]/[filename].md`
  - HKTMemory Store 步骤仍然尝试执行（独立逻辑），但 knowledge commit 被跳过
- **关联文件**: `plugins/galeharness-cli/skills/gh-compound/SKILL.md`

### TC-E-008. [gh-compound-refresh] — gale-knowledge 不可用时回退到 docs/solutions/
- **优先级**: P0
- **测试类型**: 兼容性/回归
- **前置条件**: `gale-knowledge` **不在** PATH 中，项目本地存在 `docs/solutions/`
- **测试步骤**:
  1. 临时移除 `gale-knowledge` 命令
  2. 运行 `/gh:compound-refresh`
  3. 验证 `resolve-path` 失败后回退到 `docs/solutions/`
  4. 验证后续所有扫描、读取、分类操作都基于回退路径
- **预期结果**:
  - `$SOLUTIONS_DIR` 被设置为 `docs/solutions/`
  - 所有文件列表、frontmatter 搜索、分类判断均基于 `docs/solutions/`
  - 无异常终止
- **关联文件**: `plugins/galeharness-cli/skills/gh-compound-refresh/SKILL.md`

---

## 三、技能步骤拆分规范测试

### TC-E-009. [所有迁移技能] — 知识仓库操作拆分为顺序步骤，无 action chaining
- **优先级**: P0
- **测试类型**: 回归
- **前置条件**: 已阅读 SKILL.md 中知识仓库相关段落
- **测试步骤**:
  1. 检查 `gh-brainstorm` 的 Knowledge Repository Write Path 和 Knowledge Repository Commit 段落
  2. 检查 `gh-plan` 的对应段落
  3. 检查 `gh-compound` 的对应段落
  4. 确认每个操作都是独立的顺序步骤，而非使用 `&&` 或 `;` 链式命令
  5. 确认没有使用 `2>/dev/null` 等错误抑制来掩盖 `gale-knowledge` 的失败
- **预期结果**:
  - `resolve-path`、文档写入、`commit` 是**三个独立步骤**
  - 每个步骤单独说明失败时的处理方式（如 "If the command fails... fall back to..."）
  - 无 `cmd1 && cmd2 && cmd3` 或 `cmd1; cmd2` 的 chaining 模式
  - 无 `2>/dev/null` 隐藏错误
- **关联文件**: `plugins/galeharness-cli/skills/gh-brainstorm/SKILL.md`, `gh-plan/SKILL.md`, `gh-compound/SKILL.md`

---

## 四、gh-pr-description 未迁移确认

### TC-E-010. [gh-pr-description] — 确认无知识仓库相关变更
- **优先级**: P1
- **测试类型**: 回归
- **前置条件**: 已阅读 `gh-pr-description` 的 SKILL.md
- **测试步骤**:
  1. 全文搜索 `gale-knowledge`、`resolve-path`、`commit`、`knowledge` 等关键词
  2. 确认 SKILL.md 中**不存在**任何知识仓库相关的命令或路径解析逻辑
  3. 确认输出仍然使用 `mktemp` 创建 OS 临时文件作为 `body_file`
  4. 确认 PR 描述仍然返回 `{title, body_file}`，不涉及文档持久化
- **预期结果**:
  - `gh-pr-description` 完全未引入 `gale-knowledge` 相关逻辑
  - 仍保持纯内存/临时文件输出，不写入知识仓库
- **关联文件**: `plugins/galeharness-cli/skills/gh-pr-description/SKILL.md`

---

## 五、dev-link.sh 测试

### TC-E-011. [dev-link.sh] — gale-knowledge 正确加入 dev-link 循环
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 在 GaleHarnessCLI 仓库根目录执行
- **测试步骤**:
  1. 运行 `bash scripts/dev-link.sh`
  2. 检查 `$HOME/.bun/bin/` 下是否生成了 `gale-knowledge` 的 wrapper 脚本
  3. 检查循环变量 `for bin in gale-harness compound-plugin gale-knowledge` 包含 `gale-knowledge`
  4. 检查 `gale-knowledge` 的 wrapper 内容，`import` 的路径是否为 `cmd/gale-knowledge/index.ts`
- **预期结果**:
  - `$HOME/.bun/bin/gale-knowledge` 文件存在且可执行
  - wrapper 内容包含 `import "<repo-root>/cmd/gale-knowledge/index.ts"`
  - 终端输出包含 `Linked gale-knowledge -> wrapper -> <path>/cmd/gale-knowledge/index.ts`
- **关联文件**: `scripts/dev-link.sh`

### TC-E-012. [dev-link.sh] — 入口文件映射正确性
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: `cmd/gale-knowledge/index.ts` 存在
- **测试步骤**:
  1. 检查脚本中 `if [ "$bin" = "gale-knowledge" ]; then ENTRY="$REPO_ROOT/cmd/gale-knowledge/index.ts"` 逻辑
  2. 运行 dev-link.sh
  3. 直接执行 `$HOME/.bun/bin/gale-knowledge resolve-path --type solutions`
- **预期结果**:
  - `gale-knowledge` 使用独立入口文件，而非默认的 `src/index.ts`
  - 命令能正常输出全局知识仓库路径
- **关联文件**: `scripts/dev-link.sh`, `cmd/gale-knowledge/index.ts`

---

## 六、dev-unlink.sh 测试

### TC-E-013. [dev-unlink.sh] — gale-knowledge 正确加入 restore 循环
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 已运行过 `dev-link.sh`，备份文件存在
- **测试步骤**:
  1. 运行 `bash scripts/dev-unlink.sh`
  2. 检查 `$HOME/.bun/bin/gale-knowledge` 是否被恢复为 release 版本的 symlink
  3. 检查循环变量 `for bin in gale-harness compound-plugin gale-knowledge` 包含 `gale-knowledge`
  4. 检查备份文件 `gale-knowledge.release-target` 是否被读取并删除
- **预期结果**:
  - `$HOME/.bun/bin/gale-knowledge` 恢复为原来的 symlink 或全局安装路径
  - 终端输出包含 `Restored gale-knowledge -> ... (from backup)` 或对应的 fallback 信息
  - 备份文件被清理
- **关联文件**: `scripts/dev-unlink.sh`

### TC-E-014. [dev-unlink.sh] — fallback 路径对 gale-knowledge 有效
- **优先级**: P1
- **测试类型**: 兼容性
- **前置条件**: 无备份文件存在，但全局安装存在
- **测试步骤**:
  1. 手动删除 `gale-knowledge.release-target` 备份
  2. 运行 `bash scripts/dev-unlink.sh`
  3. 检查是否 fallback 到 `../install/global/node_modules/@gale/harness-cli/src/index.ts`
- **预期结果**:
  - 无备份时，symlink 指向全局安装路径
  - 输出 `Restored gale-knowledge -> ... (from global install)`
- **关联文件**: `scripts/dev-unlink.sh`

---

## 七、dev-sync-skills.sh 测试

### TC-E-015. [dev-sync-skills.sh] — rsync 参数 `-a --delete` 正确生效
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: `~/.qoder` 或 `~/.claude` 已安装环境存在
- **测试步骤**:
  1. 在某个 skill 目录（如 `gh-brainstorm`）中删除一个文件
  2. 运行 `bash scripts/dev-sync-skills.sh`
  3. 检查目标环境中对应 skill 目录是否同步删除了该文件
- **预期结果**:
  - 目标环境中该文件被删除
  - rsync 使用了 `-a --delete` 参数
- **关联文件**: `scripts/dev-sync-skills.sh`

### TC-E-016. [dev-sync-skills.sh] — agent 扁平化逻辑正确
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: `plugins/galeharness-cli/agents/` 下存在分类子目录（如 `review/`, `research/`）
- **测试步骤**:
  1. 运行 `bash scripts/dev-sync-skills.sh`
  2. 检查目标环境的 `agents/` 目录
  3. 验证所有 agent `.md` 文件都被直接复制到 `target/agents/` 下，而不是保留分类子目录
- **预期结果**:
  - `target/agents/` 下只有扁平的 `.md` 文件，无子目录
  - 所有源目录中的 agent 文件都被复制
- **关联文件**: `scripts/dev-sync-skills.sh`

### TC-E-017. [dev-sync-skills.sh] — 旧 agent 清理仅清理含 galeharness-cli 签名的文件
- **优先级**: P0
- **测试类型**: 回归
- **前置条件**: 目标 `agents/` 目录中混有本插件的 agent 和其他插件的 agent
- **测试步骤**:
  1. 在目标 `agents/` 目录中手动创建一个不含 `galeharness-cli` 签名的 `.md` 文件（模拟其他插件的 agent）
  2. 从源目录中删除一个本插件的 agent 文件
  3. 运行 `bash scripts/dev-sync-skills.sh`
  4. 检查目标目录
- **预期结果**:
  - 被删除的本插件 agent 在目标目录中被移除（因为 head -5 包含 `galeharness-cli`）
  - 其他插件的 agent 文件保留（因为 grep 不匹配）
- **关联文件**: `scripts/dev-sync-skills.sh`

### TC-E-018. [dev-sync-skills.sh] — 无安装环境时优雅退出
- **优先级**: P1
- **测试类型**: 错误处理
- **前置条件**: `~/.qoder` 和 `~/.claude` 均不存在
- **测试步骤**:
  1. 临时重命名 `~/.qoder` 和 `~/.claude`
  2. 运行 `bash scripts/dev-sync-skills.sh`
- **预期结果**:
  - 脚本输出 `ERROR: No installed environments found`
  - 退出码非 0
- **关联文件**: `scripts/dev-sync-skills.sh`

---

## 八、setup.sh 测试

### TC-E-019. [setup.sh] — 全局知识仓库初始化步骤执行
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: macOS 环境，`gale-knowledge` 尚未初始化过
- **测试步骤**:
  1. 全新 clone 仓库或清理 `~/.galeharness/knowledge/`
  2. 运行 `bash scripts/setup.sh`
  3. 在脚本执行到 Step 7 时，观察 `gale-knowledge init` 的执行
  4. 检查 `~/.galeharness/knowledge/` 目录是否被创建并包含 `.git`
- **预期结果**:
  - 终端输出 `→ 初始化全局知识仓库...`
  - 若 `gale-knowledge` 在 PATH 中，输出 `✓ 全局知识仓库已初始化 (~/.galeharness/knowledge/)`
  - `~/.galeharness/knowledge/.git` 存在
- **关联文件**: `scripts/setup.sh`

### TC-E-020. [setup.sh] — ok/warn 反馈机制正确
- **优先级**: P1
- **测试类型**: 功能
- **前置条件**: macOS 环境
- **测试步骤**:
  1. 运行 `bash scripts/setup.sh`
  2. 观察每一步的输出前缀
  3. 故意制造一个失败场景（如在无网络环境下触发 bun install 失败）
- **预期结果**:
  - 成功步骤显示绿色 `✓`（ok 函数）
  - 警告/失败步骤显示黄色 `⚠`（warn 函数）
  - 错误步骤显示红色 `✗`（err 函数）
- **关联文件**: `scripts/setup.sh`

### TC-E-021. [setup.sh] — gale-knowledge resolve-path 自检在 summary 中列出
- **优先级**: P1
- **测试类型**: 功能
- **前置条件**: setup.sh 已执行完毕
- **测试步骤**:
  1. 查看脚本末尾的 `自检清单` 输出
  2. 确认包含 `gale-knowledge resolve-path --type solutions` 条目
  3. 手动执行该命令验证
- **预期结果**:
  - 自检清单包含 `gale-knowledge resolve-path --type solutions`
  - 期望输出: `输出全局知识仓库路径`
  - 命令实际能返回路径字符串
- **关联文件**: `scripts/setup.sh`

### TC-E-022. [setup.sh] — gale-knowledge 不在 PATH 时的警告
- **优先级**: P1
- **测试类型**: 错误处理
- **前置条件**: `gale-knowledge` 不在 PATH 中（模拟 bun link 未成功）
- **测试步骤**:
  1. 临时从 PATH 中移除 `~/.bun/bin`
  2. 运行 `bash scripts/setup.sh`
  3. 观察 Step 7 的行为
- **预期结果**:
  - 输出 `⚠ gale-knowledge 不在 PATH 中，请先确保 bun link 成功后重试`
  - 脚本继续执行，不中断
- **关联文件**: `scripts/setup.sh`

---

## 九、setup.ps1 测试

### TC-E-023. [setup.ps1] — 全局知识仓库初始化步骤执行
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: Windows PowerShell 5.1+ 或 PowerShell 7+
- **测试步骤**:
  1. 全新环境或清理 `$env:USERPROFILE\.galeharness\knowledge\`
  2. 运行 `.\scripts\setup.ps1`
  3. 观察 `=== 初始化全局知识仓库 ===` 段落的输出
  4. 检查 `$env:USERPROFILE\.galeharness\knowledge\` 是否被创建
- **预期结果**:
  - 显示 `=== 初始化全局知识仓库 ===`
  - 若成功，显示 `[OK] 全局知识仓库已初始化 (~/.galeharness/knowledge/)`
  - 目录和 `.git` 存在
- **关联文件**: `scripts/setup.ps1`

### TC-E-024. [setup.ps1] — $LASTEXITCODE 检查 gale-knowledge init 结果
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: Windows 环境，`gale-knowledge` 在 PATH 中
- **测试步骤**:
  1. 检查脚本中 `$initResult = & gale-knowledge init 2>&1` 后的 `$LASTEXITCODE -eq 0` 判断
  2. 运行脚本
  3. 验证当 init 成功时输出 `[OK]`，失败时输出 `[WARN]`
- **预期结果**:
  - 使用 `$LASTEXITCODE`（而非仅靠异常捕获）判断命令结果
  - 成功: `[OK] 全局知识仓库已初始化 (~/.galeharness/knowledge/)`
  - 失败: `[WARN] 知识仓库初始化失败，可稍后手动运行 gale-knowledge init`
- **关联文件**: `scripts/setup.ps1`

### TC-E-025. [setup.ps1] — 无 gale-knowledge 时的警告
- **优先级**: P1
- **测试类型**: 错误处理
- **前置条件**: `gale-knowledge` 不在 PATH 中
- **测试步骤**:
  1. 临时移除 `gale-knowledge`
  2. 运行 `.\scripts\setup.ps1`
  3. 观察 Step 7 行为
- **预期结果**:
  - 输出 `[WARN] gale-knowledge 不在 PATH 中，请确保 bun link 成功`
  - 脚本继续执行后续步骤
- **关联文件**: `scripts/setup.ps1`

### TC-E-026. [setup.ps1] — PowerShell 编码修正未导致乱码
- **优先级**: P1
- **测试类型**: 兼容性
- **前置条件**: Windows PowerShell 5.1（非 PowerShell 7）
- **测试步骤**:
  1. 在 Windows PowerShell 5.1 中运行脚本
  2. 观察所有中文字符和特殊符号（如 `→`、`✓`、`⚠`）是否正确显示
- **预期结果**:
  - 无乱码或崩溃
  - UTF-8 编码设置生效
- **关联文件**: `scripts/setup.ps1`

---

## 十、package.json 与 .gitignore 测试

### TC-E-027. [package.json] — bin 字段包含 gale-knowledge
- **优先级**: P0
- **测试类型**: 回归
- **前置条件**: 无
- **测试步骤**:
  1. 打开 `package.json`
  2. 检查 `bin` 对象
  3. 验证 `gale-knowledge` 键存在且值为 `cmd/gale-knowledge/index.ts`
- **预期结果**:
  ```json
  "bin": {
    "gale-harness": "src/index.ts",
    "compound-plugin": "src/index.ts",
    "gale-knowledge": "cmd/gale-knowledge/index.ts"
  }
  ```
- **关联文件**: `package.json`

### TC-E-028. [.gitignore] — .qoder/ 已添加
- **优先级**: P1
- **测试类型**: 回归
- **前置条件**: 无
- **测试步骤**:
  1. 打开 `.gitignore`
  2. 检查末尾是否包含 `.qoder/`
- **预期结果**:
  - `.gitignore` 最后一行（或其中一行）为 `.qoder/`
- **关联文件**: `.gitignore`

---

## 十一、端到端场景测试

### TC-E-029. [E2E] — 新用户完整流程：clone → setup → brainstorm → 全局仓库验证
- **优先级**: P0
- **测试类型**: 端到端/集成
- **前置条件**: 全新 macOS 环境（或干净的 CI 容器），Git、Bun 未安装或已安装
- **测试步骤**:
  1. `git clone <repo-url> GaleHarnessCodingCLI && cd GaleHarnessCodingCLI`
  2. `bash scripts/setup.sh`
  3. 按提示输入 `y` 选择 API 模式，输入任意 API Key
  4. `source ~/.zshrc`（或对应 shell profile）
  5. 验证 `gale-knowledge resolve-path --type brainstorms` 输出路径（如 `~/.galeharness/knowledge/GaleHarnessCodingCLI/brainstorms`）
  6. 验证该路径下目录存在
  7. 运行 `/gh:brainstorm 测试全局知识仓库写入`（通过安装了插件的 agent）
  8. 完成 brainstorm 流程，生成 requirements 文档
  9. 检查全局知识仓库的 `brainstorms/` 目录下是否出现了新文档
  10. 运行 `gale-task board list --with-knowledge`（或对应 board 命令）
- **预期结果**:
  - Step 2: setup.sh 成功完成，无报错
  - Step 5: `resolve-path` 返回非空绝对路径
  - Step 7-8: brainstorm 技能正常执行，未报错
  - Step 9: 全局知识仓库 `brainstorms/` 下出现新生成的 `<topic>-requirements.md`
  - Step 10: `board list --with-knowledge` 能展示该 brainstorm 文档的元信息（标题、类型、路径）
- **关联文件**: `scripts/setup.sh`, `plugins/galeharness-cli/skills/gh-brainstorm/SKILL.md`, `cmd/gale-knowledge/index.ts`

### TC-E-030. [E2E] — 回退路径端到端：无 gale-knowledge 时项目本地 docs 仍可用
- **优先级**: P0
- **测试类型**: 端到端/兼容性
- **前置条件**: 已安装插件，但 `gale-knowledge` 命令被临时移除
- **测试步骤**:
  1. 临时重命名 `$HOME/.bun/bin/gale-knowledge`
  2. 运行 `/gh:brainstorm 测试回退`
  3. 完成 brainstorm 流程
  4. 检查 `docs/brainstorms/` 目录下是否出现了新文档
  5. 恢复 `gale-knowledge` 命令
  6. 运行 `/gh:plan 测试回退计划`
  7. 检查 `docs/plans/` 目录下是否出现了新计划
- **预期结果**:
  - 无 `gale-knowledge` 时，brainstorm 和 plan 均回退到 `docs/` 下对应目录
  - 文档内容完整，格式正确
  - 恢复 `gale-knowledge` 后，后续操作可正常写入全局仓库
- **关联文件**: `plugins/galeharness-cli/skills/gh-brainstorm/SKILL.md`, `gh-plan/SKILL.md`

### TC-E-031. [E2E] — compound + compound-refresh 知识仓库联动
- **优先级**: P1
- **测试类型**: 端到端/集成
- **前置条件**: 全局知识仓库已初始化，已有若干 solution 文档
- **测试步骤**:
  1. 运行 `/gh:compound 测试联动问题`
  2. 选择 Full 模式，完成 solution 文档写入
  3. 记录新生成的文档路径
  4. 运行 `/gh:compound-refresh`（不带参数，全量扫描）
  5. 验证 refresh 能正确读取到步骤 3 生成的文档
  6. 验证 refresh 的扫描范围是全局知识仓库，而非本地 `docs/solutions/`
- **预期结果**:
  - compound 写入的文档在全局仓库中可被 compound-refresh 发现
  - compound-refresh 的 `Scanned: N learnings` 包含新写入的文档
  - 无路径混淆（不会去扫描本地 `docs/solutions/` 除非回退）
- **关联文件**: `plugins/galeharness-cli/skills/gh-compound/SKILL.md`, `gh-compound-refresh/SKILL.md`

---

## 十二、边界条件与异常测试

### TC-E-032. [gh-compound] — extract-project 失败时使用目录名回退
- **优先级**: P1
- **测试类型**: 边界条件
- **前置条件**: 在非 git 目录中运行技能（或 git 命令失败）
- **测试步骤**:
  1. 模拟 `gale-knowledge extract-project` 失败
  2. 观察 `gh-compound` 的 Knowledge Repository Commit 步骤
  3. 验证是否回退到 `$(basename "$(pwd)")` 作为 project name
- **预期结果**:
  - `extract-project` 失败后，使用当前目录 basename
  - `commit` 命令仍然尝试执行，project 参数不为空
- **关联文件**: `plugins/galeharness-cli/skills/gh-compound/SKILL.md`

### TC-E-033. [gh-brainstorm] — extract-project 失败时使用目录名回退
- **优先级**: P1
- **测试类型**: 边界条件
- **前置条件**: 在非 git 目录中运行技能
- **测试步骤**:
  1. 模拟 `gale-knowledge extract-project` 失败
  2. 验证 commit 步骤使用目录 basename 作为 project name
- **预期结果**:
  - 不阻塞流程，project name 有有效值
- **关联文件**: `plugins/galeharness-cli/skills/gh-brainstorm/SKILL.md`

### TC-E-034. [dev-link.sh] — 重复运行 idempotent
- **优先级**: P1
- **测试类型**: 回归
- **前置条件**: 已运行过一次 dev-link.sh
- **测试步骤**:
  1. 再次运行 `bash scripts/dev-link.sh`
  2. 检查 wrapper 文件是否仍然有效
  3. 检查备份文件是否被覆盖（应保存原始 release target，而非上一次的 wrapper）
- **预期结果**:
  - 重复运行不产生错误
  - 备份文件仍然指向原始 release target（不是 dev wrapper）
  - wrapper 文件被重新生成
- **关联文件**: `scripts/dev-link.sh`

### TC-E-035. [setup.sh] — Python 版本过低时正确退出
- **优先级**: P1
- **测试类型**: 错误处理
- **前置条件**: 系统 Python < 3.9
- **测试步骤**:
  1. 在 Python 3.8 环境中运行 `bash scripts/setup.sh`
  2. 观察 Step 3 的行为
- **预期结果**:
  - 输出 `✗ Python 版本过低: 3.8，需要 >= 3.9`
  - 脚本以 exit 1 退出
- **关联文件**: `scripts/setup.sh`

---

## 附录：测试执行清单

| 编号 | 模块 | 优先级 | 自动化可行性 | 备注 |
|------|------|--------|--------------|------|
| TC-E-001 | gh-brainstorm | P0 | 中 | 需模拟 agent 执行环境 |
| TC-E-002 | gh-plan | P0 | 中 | 需模拟 agent 执行环境 |
| TC-E-003 | gh-compound | P0 | 中 | 需模拟 agent 执行环境 |
| TC-E-004 | gh-compound-refresh | P0 | 中 | 需模拟 agent 执行环境 |
| TC-E-005 | gh-brainstorm fallback | P0 | 高 | 可直接修改 PATH 测试 |
| TC-E-006 | gh-plan fallback | P0 | 高 | 可直接修改 PATH 测试 |
| TC-E-007 | gh-compound fallback | P0 | 高 | 可直接修改 PATH 测试 |
| TC-E-008 | gh-compound-refresh fallback | P0 | 高 | 可直接修改 PATH 测试 |
| TC-E-009 | 步骤拆分规范 | P0 | 高 | 纯文本审查 |
| TC-E-010 | gh-pr-description 未迁移 | P1 | 高 | 纯文本审查 |
| TC-E-011 | dev-link.sh 循环 | P0 | 高 | 直接执行脚本 |
| TC-E-012 | dev-link.sh 入口映射 | P0 | 高 | 直接执行脚本 |
| TC-E-013 | dev-unlink.sh restore | P0 | 高 | 直接执行脚本 |
| TC-E-014 | dev-unlink.sh fallback | P1 | 高 | 直接执行脚本 |
| TC-E-015 | dev-sync-skills.sh rsync | P0 | 高 | 直接执行脚本 |
| TC-E-016 | dev-sync-skills.sh 扁平化 | P0 | 高 | 直接执行脚本 |
| TC-E-017 | dev-sync-skills.sh 清理签名 | P0 | 高 | 直接执行脚本 |
| TC-E-018 | dev-sync-skills.sh 无环境退出 | P1 | 高 | 直接执行脚本 |
| TC-E-019 | setup.sh 知识仓库初始化 | P0 | 高 | 直接执行脚本 |
| TC-E-020 | setup.sh ok/warn | P1 | 高 | 直接执行脚本 |
| TC-E-021 | setup.sh 自检清单 | P1 | 高 | 直接执行脚本 |
| TC-E-022 | setup.sh 无 PATH 警告 | P1 | 高 | 直接执行脚本 |
| TC-E-023 | setup.ps1 知识仓库初始化 | P0 | 中 | 需 Windows 环境 |
| TC-E-024 | setup.ps1 $LASTEXITCODE | P0 | 中 | 需 Windows 环境 |
| TC-E-025 | setup.ps1 无 PATH 警告 | P1 | 中 | 需 Windows 环境 |
| TC-E-026 | setup.ps1 编码 | P1 | 中 | 需 Windows PowerShell 5.1 |
| TC-E-027 | package.json bin | P0 | 高 | 纯文本审查 |
| TC-E-028 | .gitignore .qoder | P1 | 高 | 纯文本审查 |
| TC-E-029 | E2E 新用户流程 | P0 | 低 | 需完整环境 |
| TC-E-030 | E2E 回退路径 | P0 | 低 | 需完整环境 |
| TC-E-031 | E2E compound 联动 | P1 | 低 | 需完整环境 |
| TC-E-032 | extract-project 回退 | P1 | 中 | 模拟失败场景 |
| TC-E-033 | extract-project 回退 (brainstorm) | P1 | 中 | 模拟失败场景 |
| TC-E-034 | dev-link.sh idempotent | P1 | 高 | 直接执行脚本 |
| TC-E-035 | setup.sh Python 版本检查 | P1 | 高 | 直接执行脚本 |

---

**测试团队 E 签章**  
*技能迁移与脚本组*  
