# PR #31 人工测试用例 — 团队 B（CLI 命令组）

> 覆盖文件：`cmd/gale-knowledge/init.ts`、`git-ops.ts`、`ci-setup.ts`、`rebuild-index.ts`、`index.ts`

---

## 一、init 子命令

### TC-B-001. init — 首次初始化创建成功
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 系统中不存在 `~/.galeharness/knowledge/.git`（或自定义 `GALE_KNOWLEDGE_HOME` 路径下无 `.git`）
- **测试步骤**:
  1. 执行 `rm -rf ~/.galeharness/knowledge`（确保干净环境，或使用 `export GALE_KNOWLEDGE_HOME=/tmp/gk-test-init`）
  2. 执行 `bun run cmd/gale-knowledge/index.ts init`
- **预期结果**:
  - stdout 输出包含 `Initialized knowledge repo at ...`
  - 目录下存在 `.git/` 子目录
  - `git -C ~/.galeharness/knowledge log --oneline` 可看到一条 commit，message 包含 `init knowledge repo`
- **关联代码**: `init.ts:34-77`

### TC-B-002. init — 幂等性第二次调用返回 false 并跳过
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 已完成 TC-B-001
- **测试步骤**:
  1. 再次执行 `bun run cmd/gale-knowledge/index.ts init`
- **预期结果**:
  - stdout 输出包含 `Knowledge repo already exists at ...`
  - 不修改现有 `.git/` 目录，不生成新的 commit
  - exit code 为 0
- **关联代码**: `init.ts:37-39`, `init.ts:92-97`

### TC-B-003. init — git init 15 秒超时保护
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**: 具备构造 git 命令 hang 的环境（如使用 `LD_PRELOAD` 或网络文件系统延迟）
- **测试步骤**:
  1. 在极端慢速存储上初始化新目录（或 mock `git` 为 `sleep 30 && git` 的 shell wrapper）
  2. 执行 `bun run cmd/gale-knowledge/index.ts init`
- **预期结果**:
  - 15 秒内进程退出
  - stderr 输出包含 `init failed` 或 `git init failed`
  - exit code 为 1
- **关联代码**: `init.ts:45-51`

### TC-B-004. init — .gitignore 内容完整性验证
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 已完成 TC-B-001
- **测试步骤**:
  1. 执行 `cat ~/.galeharness/knowledge/.gitignore`
- **预期结果**:
  - 文件内容精确包含三行：
    ```
    *.db
    vector-index/
    .last-rebuild-commit
    ```
- **关联代码**: `init.ts:20-23`, `init.ts:54`

### TC-B-005. init — 初始空提交验证（允许空提交）
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 干净环境
- **测试步骤**:
  1. 执行 init
  2. 执行 `git -C ~/.galeharness/knowledge log --format=%s -1`
- **预期结果**:
  - commit message 为 `chore: init knowledge repo`
  - 该 commit 是 `--allow-empty` 创建的，即使目录中无文件也能成功
- **关联代码**: `init.ts:70-74`

### TC-B-006. init — git init 失败时的错误处理与退出码
- **优先级**: P1
- **测试类型**: 错误
- **前置条件**: 构造一个 `git init` 必然失败的环境（如在非目录路径上执行，或权限不足）
- **测试步骤**:
  1. 创建普通文件 `touch /tmp/not-a-dir`
  2. 设置 `GALE_KNOWLEDGE_HOME=/tmp/not-a-dir`
  3. 执行 `bun run cmd/gale-knowledge/index.ts init`
- **预期结果**:
  - stderr 输出 `[gale-knowledge] init failed: ...`
  - exit code 为 1
- **关联代码**: `init.ts:48-51`, `init.ts:98-105`

### TC-B-007. init — git config user.email / user.name 失败处理
- **优先级**: P1
- **测试类型**: 错误
- **前置条件**: 已创建目录但 `.git` 被损坏（如 `.git/config` 为只读目录）
- **测试步骤**:
  1. `mkdir -p /tmp/bad-repo/.git && chmod 000 /tmp/bad-repo/.git/config`
  2. 设置 `GALE_KNOWLEDGE_HOME=/tmp/bad-repo`
  3. 执行 init
- **预期结果**:
  - 进程抛出 `git config user.email failed` 或 `git config user.name failed`
  - stderr 输出包含 `init failed`
  - exit code 为 1
- **关联代码**: `init.ts:57-61`

### TC-B-008. init — git add 失败处理
- **优先级**: P1
- **测试类型**: 错误
- **前置条件**: git 仓库已初始化，但 `.git/index` 被损坏或设为只读
- **测试步骤**:
  1. 正常 init 一次
  2. `chmod 000 ~/.galeharness/knowledge/.git/index`
  3. 修改代码临时在 `initKnowledgeRepo` 中跳过 `.git` 存在检查，再次调用（或手动调用 `git add -A` 观察行为）
- **预期结果**:
  - `git add` 失败时抛出 `git add failed: ...`
- **关联代码**: `init.ts:64-68`

### TC-B-009. init — git commit 失败处理
- **优先级**: P1
- **测试类型**: 错误
- **前置条件**: git 仓库已初始化，但缺少本地 user 配置且无法写入 `.git/config`
- **测试步骤**:
  1. 手动 `git init` 一个目录，不配置 user.name/user.email
  2. 在该目录下放置一个修改后的文件，使 `git add -A` 有内容
  3. 设置 `GIT_CONFIG_GLOBAL=/dev/null` 并尝试 commit（验证底层行为）
- **预期结果**:
  - 在 `initKnowledgeRepo` 的 commit 步骤中，若失败则抛出 `git commit failed: ...`
- **关联代码**: `init.ts:70-74`

---

## 二、git-ops（commit）子命令

### TC-B-010. commit — 正常提交生成正确 commit message
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 知识仓库已初始化，且存在未提交的 `.md` 变更
- **测试步骤**:
  1. `echo "# test" >> ~/.galeharness/knowledge/test.md`
  2. 执行 `bun run cmd/gale-knowledge/index.ts commit --project my-app --type brainstorm --title "auth-design"`
- **预期结果**:
  - stdout 输出 `Committed: <hash> docs(my-app/brainstorm): auth-design`
  - `git log -1 --pretty=%s` 显示 `docs(my-app/brainstorm): auth-design`
- **关联代码**: `git-ops.ts:70-124`, `git-ops.ts:94-95`

### TC-B-011. commit — 无变更时 exit 0 并提示 No changes
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 知识仓库干净，无任何未提交变更
- **测试步骤**:
  1. 确保仓库干净：`git -C ~/.galeharness/knowledge status` 显示 nothing to commit
  2. 执行 `bun run cmd/gale-knowledge/index.ts commit --project x --type plan --title "no-op"`
- **预期结果**:
  - stdout 输出 `No changes to commit`
  - exit code 为 0
  - 不产生新的 commit
- **关联代码**: `git-ops.ts:83-87`, `git-ops.ts:172-174`

### TC-B-012. commit — --project 参数正确拼接到 message
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 存在未提交的变更
- **测试步骤**:
  1. 创建变更文件
  2. 分别执行 `--project foo-bar`、`--project org/repo`
- **预期结果**:
  - commit message 分别包含 `docs(foo-bar/...)` 和 `docs(org/repo/...)`
- **关联代码**: `git-ops.ts:94-95`

### TC-B-013. commit — --type 有效值 brainstorm / plan / solution
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 存在未提交的变更
- **测试步骤**:
  1. 依次执行 `--type brainstorm`、`--type plan`、`--type solution`
- **预期结果**:
  - 三次均成功 commit
  - message 中 type 部分与输入一致
- **关联代码**: `git-ops.ts:152-156`

### TC-B-014. commit — --type 无效值时 exit 1
- **优先级**: P0
- **测试类型**: 边界
- **前置条件**: 任意
- **测试步骤**:
  1. 执行 `bun run cmd/gale-knowledge/index.ts commit --project x --type invalid --title t`
- **预期结果**:
  - stderr 输出 `Invalid document type: invalid. Valid types: brainstorms, plans, solutions`
  - exit code 为 1
- **关联代码**: `git-ops.ts:152-156`

### TC-B-015. commit — --title 参数正确性（含空格）
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 存在未提交的变更
- **测试步骤**:
  1. 执行 `--title "my document title"`
- **预期结果**:
  - commit message 为 `docs(...): my document title`
  - 空格保留，不会被截断
- **关联代码**: `git-ops.ts:94-95`

### TC-B-016. commit — title sanitize 双引号 `"` 替换为单引号
- **优先级**: P0
- **测试类型**: 安全
- **前置条件**: 存在未提交的变更
- **测试步骤**:
  1. 执行 `--title 'say "hello"'`
- **预期结果**:
  - commit message 为 `docs(...): say 'hello'`
  - 不产生 shell 解析错误
- **关联代码**: `git-ops.ts:48-58`, `git-ops.ts:51`

### TC-B-017. commit — title sanitize 反引号 `` ` `` 替换为单引号
- **优先级**: P0
- **测试类型**: 安全
- **前置条件**: 存在未提交的变更
- **测试步骤**:
  1. 执行 `` --title 'use `fetch` api' ``
- **预期结果**:
  - commit message 为 `docs(...): use 'fetch' api`
- **关联代码**: `git-ops.ts:48-58`, `git-ops.ts:52`

### TC-B-018. commit — title sanitize 美元符号 `$` 被移除
- **优先级**: P0
- **测试类型**: 安全
- **前置条件**: 存在未提交的变更
- **测试步骤**:
  1. 执行 `--title 'cost $100'`
- **预期结果**:
  - commit message 为 `docs(...): cost 100`
  - 无 shell 变量展开风险
- **关联代码**: `git-ops.ts:48-58`, `git-ops.ts:53`

### TC-B-019. commit — title sanitize 反斜杠 `\` 被移除
- **优先级**: P0
- **测试类型**: 安全
- **前置条件**: 存在未提交的变更
- **测试步骤**:
  1. 执行 `--title 'path\\to\\file'`
- **预期结果**:
  - commit message 为 `docs(...): pathtofile`
- **关联代码**: `git-ops.ts:48-58`, `git-ops.ts:54`

### TC-B-020. commit — title sanitize 换行符 `\n` / 回车符 `\r` 替换为空格
- **优先级**: P1
- **测试类型**: 安全
- **前置条件**: 存在未提交的变更
- **测试步骤**:
  1. 在 shell 中构造含换行的 title：`printf '%s' '--title "line1
line2"'`
- **预期结果**:
  - commit message 为 `docs(...): line1 line2`
- **关联代码**: `git-ops.ts:48-58`, `git-ops.ts:55-56`

### TC-B-021. commit — title sanitize 后 trim 首尾空格
- **优先级**: P1
- **测试类型**: 功能
- **前置条件**: 存在未提交的变更
- **测试步骤**:
  1. 执行 `--title '  spaced-title  '`
- **预期结果**:
  - commit message 为 `docs(...): spaced-title`（无首尾空格）
- **关联代码**: `git-ops.ts:48-58`, `git-ops.ts:57`

### TC-B-022. commit — 批量提交多个文件
- **优先级**: P0
- **测试类型**: 集成
- **前置条件**: 知识仓库已初始化
- **测试步骤**:
  1. 创建 `a.md`、`b.md`、`sub/c.md`
  2. 执行一次 commit
- **预期结果**:
  - 仅生成一个 commit
  - `git diff-tree --no-commit-id --name-only -r HEAD` 显示三个文件都在同一 commit 中
- **关联代码**: `git-ops.ts:76`, `git-ops.ts:98`

### TC-B-023. commit — spawnSync 数组参数防注入验证
- **优先级**: P0
- **测试类型**: 安全
- **前置条件**: 存在未提交的变更
- **测试步骤**:
  1. 执行 `--title 'evil"; touch /tmp/pwned; "'`
- **预期结果**:
  - 双引号被 sanitize 为单引号
  - `/tmp/pwned` **不会被创建**
  - commit message 为 `docs(...): evil'; touch /tmp/pwned; '`（单引号）
- **关联代码**: `git-ops.ts:98`

### TC-B-024. commit — 15 秒超时保护
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**: 可构造 git commit hang 的环境
- **测试步骤**:
  1. 用 wrapper 脚本替换 git，使 `git commit` 阻塞 60 秒
  2. 执行 commit
- **预期结果**:
  - 15 秒内进程返回错误（非无限等待）
  - stderr 包含 `Commit failed`
- **关联代码**: `git-ops.ts:72`, `git-ops.ts:98`

### TC-B-025. commit — git add 失败处理
- **优先级**: P1
- **测试类型**: 错误
- **前置条件**: 知识仓库 `.git/index` 损坏
- **测试步骤**:
  1. 损坏 index：`chmod 000 ~/.galeharness/knowledge/.git/index`
  2. 执行 commit
- **预期结果**:
  - stderr 输出 `Commit failed: git add failed: ...`
  - exit code 为 1
- **关联代码**: `git-ops.ts:76-80`, `git-ops.ts:169-171`

### TC-B-026. commit — git commit 失败处理
- **优先级**: P1
- **测试类型**: 错误
- **前置条件**: 知识仓库无 user 配置且无法自动设置
- **测试步骤**:
  1. 删除本地 git config 中的 user.name / user.email
  2. 将 `.git/config` 设为只读
  3. 执行 commit
- **预期结果**:
  - stderr 输出 `Commit failed: ...`
  - exit code 为 1
- **关联代码**: `git-ops.ts:98-102`, `git-ops.ts:169-171`

---

## 三、ci-setup 子命令

### TC-B-027. setup-ci — 首次生成 workflow 文件
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 知识仓库已初始化，且无 `.github/workflows/knowledge-index.yml`
- **测试步骤**:
  1. 执行 `bun run cmd/gale-knowledge/index.ts setup-ci`
- **预期结果**:
  - stdout 输出 `Created workflow: .../.github/workflows/knowledge-index.yml`
  - 文件存在且内容非空
  - stderr 末尾输出提醒添加 `HKT_MEMORY_API_KEY` secret
- **关联代码**: `ci-setup.ts:80-96`, `ci-setup.ts:107-137`

### TC-B-028. setup-ci — 幂等覆盖已有文件
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 已完成 TC-B-027
- **测试步骤**:
  1. 再次执行 `setup-ci`
- **预期结果**:
  - stdout 输出 `Updated workflow: ...`
  - `overwritten` 为 true
  - 文件内容被完整覆盖，无残留旧内容
- **关联代码**: `ci-setup.ts:85`, `ci-setup.ts:111-114`

### TC-B-029. setup-ci — `.github/workflows` 目录自动创建
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 知识仓库根目录下无 `.github/` 目录
- **测试步骤**:
  1. 确保 `~/.galeharness/knowledge/.github` 不存在
  2. 执行 `setup-ci`
- **预期结果**:
  - `.github/workflows/` 被递归创建
  - `knowledge-index.yml` 成功写入
- **关联代码**: `ci-setup.ts:88-90`

### TC-B-030. setup-ci — workflow 包含 `actions/checkout@v4`
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 已生成 workflow
- **测试步骤**:
  1. `grep 'actions/checkout@v4' ~/.galeharness/knowledge/.github/workflows/knowledge-index.yml`
- **预期结果**:
  - 匹配成功
- **关联代码**: `ci-setup.ts:28`

### TC-B-031. setup-ci — workflow 包含 `fetch-depth: 0`
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 已生成 workflow
- **测试步骤**:
  1. `grep 'fetch-depth: 0' ~/.galeharness/knowledge/.github/workflows/knowledge-index.yml`
- **预期结果**:
  - 匹配成功
- **关联代码**: `ci-setup.ts:30`

### TC-B-032. setup-ci — workflow 包含 `github.event.before`
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 已生成 workflow
- **测试步骤**:
  1. `grep 'github.event.before' ~/.galeharness/knowledge/.github/workflows/knowledge-index.yml`
- **预期结果**:
  - 匹配成功
- **关联代码**: `ci-setup.ts:38`

### TC-B-033. setup-ci — workflow 包含 `astral-sh/setup-uv@v3`
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 已生成 workflow
- **测试步骤**:
  1. `grep 'astral-sh/setup-uv@v3' ~/.galeharness/knowledge/.github/workflows/knowledge-index.yml`
- **预期结果**:
  - 匹配成功
- **关联代码**: `ci-setup.ts:33`

### TC-B-034. setup-ci — workflow 包含 `HKT_MEMORY_API_KEY` 环境变量引用
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 已生成 workflow
- **测试步骤**:
  1. `grep 'HKT_MEMORY_API_KEY' ~/.galeharness/knowledge/.github/workflows/knowledge-index.yml`
- **预期结果**:
  - 匹配成功，且格式为 `HKT_MEMORY_API_KEY: ${{ secrets.HKT_MEMORY_API_KEY }}`
- **关联代码**: `ci-setup.ts:43`

### TC-B-035. setup-ci — workflow 包含 `hkt_memory_v5.py ingest-artifact`
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 已生成 workflow
- **测试步骤**:
  1. `grep 'hkt_memory_v5.py ingest-artifact' ~/.galeharness/knowledge/.github/workflows/knowledge-index.yml`
- **预期结果**:
  - 匹配成功
- **关联代码**: `ci-setup.ts:50`

### TC-B-036. setup-ci — workflow 包含 `.last-rebuild-commit` 写入步骤
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 已生成 workflow
- **测试步骤**:
  1. `grep '.last-rebuild-commit' ~/.galeharness/knowledge/.github/workflows/knowledge-index.yml`
- **预期结果**:
  - 匹配成功，且包含 `git rev-parse HEAD > .last-rebuild-commit`
- **关联代码**: `ci-setup.ts:55`

---

## 四、rebuild-index 子命令

### TC-B-037. rebuild-index — 增量模式读取 `.last-rebuild-commit` 并仅处理变更文件
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 知识仓库为 git 仓库，已存在 `.last-rebuild-commit` 指向历史 commit
- **测试步骤**:
  1. 记录当前 HEAD：`git rev-parse HEAD > ~/.galeharness/knowledge/.last-rebuild-commit`
  2. 新增或修改一个 `.md` 文件
  3. 执行 `git add -A && git commit -m "add doc"`
  4. 执行 `bun run cmd/gale-knowledge/index.ts rebuild-index`
- **预期结果**:
  - stdout 显示 `(incremental mode)`
  - `Processed` 计数为新增/修改的 `.md` 文件数（若 uv 不可用则可能为 0，但 mode 仍为 incremental）
- **关联代码**: `rebuild-index.ts:278-295`, `rebuild-index.ts:382-416`

### TC-B-038. rebuild-index — `--full` 全量模式扫描所有 `.md`
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 知识仓库存在多个 `.md` 文件
- **测试步骤**:
  1. 执行 `bun run cmd/gale-knowledge/index.ts rebuild-index --full`
- **预期结果**:
  - stdout 显示 `(full mode)`
  - 所有 `.md` 文件都被纳入 `filesToProcess`
- **关联代码**: `rebuild-index.ts:301-304`

### TC-B-039. rebuild-index — 无 `.last-rebuild-commit` 时自动回退 full
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 知识仓库已初始化，但不存在 `.last-rebuild-commit`
- **测试步骤**:
  1. `rm -f ~/.galeharness/knowledge/.last-rebuild-commit`
  2. 执行 `rebuild-index`（不带 `--full`）
- **预期结果**:
  - stdout 显示 `(full mode)`
- **关联代码**: `rebuild-index.ts:296-300`

### TC-B-040. rebuild-index — 无效/不可达 hash 回退 full
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 知识仓库已初始化
- **测试步骤**:
  1. 写入一个不可达的 hash：`echo "deadbeef1234567890" > ~/.galeharness/knowledge/.last-rebuild-commit`
  2. 执行 `rebuild-index`
- **预期结果**:
  - stderr 输出 `Last rebuild commit unreachable, falling back to full mode.`
  - stdout 显示 `(full mode)`
- **关联代码**: `rebuild-index.ts:284-293`

### TC-B-041. rebuild-index — commit hash 格式验证太短（6 位）
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**: 任意
- **测试步骤**:
  1. 写入 `echo "abc123" > ~/.galeharness/knowledge/.last-rebuild-commit`
  2. 执行 `rebuild-index`
- **预期结果**:
  - `getChangedFiles` 返回空数组（因 `/^[0-9a-f]{7,40}$/i` 不匹配）
  - 随后 `git cat-file -t abc123` 验证失败，回退 full mode
- **关联代码**: `rebuild-index.ts:134`, `rebuild-index.ts:284-293`

### TC-B-042. rebuild-index — commit hash 格式验证非十六进制字符
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**: 任意
- **测试步骤**:
  1. 写入 `echo "zzzzzzz" > ~/.galeharness/knowledge/.last-rebuild-commit`
  2. 执行 `rebuild-index`
- **预期结果**:
  - 因 regex 不匹配，回退 full mode
- **关联代码**: `rebuild-index.ts:134`

### TC-B-043. rebuild-index — commit hash 格式验证太长（41 位）
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**: 任意
- **测试步骤**:
  1. 写入 `echo "12345678901234567890123456789012345678901" > ~/.galeharness/knowledge/.last-rebuild-commit`
  2. 执行 `rebuild-index`
- **预期结果**:
  - 因 regex 不匹配（41 > 40），回退 full mode
- **关联代码**: `rebuild-index.ts:134`

### TC-B-044. rebuild-index — symlink 文件/目录被跳过
- **优先级**: P1
- **测试类型**: 功能
- **前置条件**: 知识仓库已初始化
- **测试步骤**:
  1. `ln -s /etc/hosts ~/.galeharness/knowledge/symlink.md`
  2. 执行 `rebuild-index --full`
- **预期结果**:
  - `symlink.md` 不会被 collect 进处理列表
- **关联代码**: `rebuild-index.ts:99`

### TC-B-045. rebuild-index — `.git` 目录被排除
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 知识仓库已初始化
- **测试步骤**:
  1. 在 `.git/hooks/` 下创建一个 `post-update.md`
  2. 执行 `rebuild-index --full`
- **预期结果**:
  - `.git/` 下的任何 `.md` 文件都不出现在处理列表中
- **关联代码**: `rebuild-index.ts:98`

### TC-B-046. rebuild-index — `node_modules` 目录被排除
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 知识仓库已初始化
- **测试步骤**:
  1. `mkdir -p ~/.galeharness/knowledge/node_modules/foo && echo "# bad" > ~/.galeharness/knowledge/node_modules/foo/readme.md`
  2. 执行 `rebuild-index --full`
- **预期结果**:
  - `node_modules/` 下的 `.md` 文件不被处理
- **关联代码**: `rebuild-index.ts:98`

### TC-B-047. rebuild-index — 增量模式中已删除的文件被跳过
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 知识仓库为 git 仓库，`.last-rebuild-commit` 存在
- **测试步骤**:
  1. 创建一个 `.md` 文件并 commit
  2. 记录 HEAD 到 `.last-rebuild-commit`
  3. 删除该 `.md` 文件并 commit
  4. 执行 `rebuild-index`
- **预期结果**:
  - `git diff` 会列出被删除的文件名
  - 但在处理循环中 `existsSync(fullPath)` 为 false，该文件被 `continue` 跳过
  - 不报错，不统计为 error
- **关联代码**: `rebuild-index.ts:330-336`

### TC-B-048. rebuild-index — 错误时不回写 `.last-rebuild-commit` 指针
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 可触发 store 错误（如构造 hkt_memory_v5.py 失败场景，或 mock）
- **测试步骤**:
  1. 记录旧的 `.last-rebuild-commit` 内容（若存在）
  2. 在仓库中新增一个 `.md` 文件并 commit
  3. 临时将 `vendor/hkt-memory/scripts/hkt_memory_v5.py` 重命名为其他名字，或断开 uv
  4. 执行 `rebuild-index --full`
  5. 观察 `.last-rebuild-commit` 内容
- **预期结果**:
  - 若原文件存在，其内容**不发生变化**
  - 若原文件不存在，仍然不存在（不因本次运行而创建）
  - 原因：`errors > 0` 时跳过 `saveLastRebuildCommit`
- **关联代码**: `rebuild-index.ts:360-368`

### TC-B-049. rebuild-index — uv 缺失时 graceful 警告（不崩溃）
- **优先级**: P0
- **测试类型**: 兼容性
- **前置条件**: `uv` 不在 PATH 中（或临时 `PATH=/usr/bin:/bin`）
- **测试步骤**:
  1. `PATH=/usr/bin:/bin bun run cmd/gale-knowledge/index.ts rebuild-index --full`
- **预期结果**:
  - stderr 输出 `Warning: uv is not available in PATH. Skipping vector index rebuild.`
  - 进程 exit code 为 0
  - 不抛出未捕获异常
- **关联代码**: `rebuild-index.ts:306-312`, `rebuild-index.ts:57-64`

### TC-B-050. rebuild-index — `hkt_memory_v5.py` 缺失时 graceful 警告
- **优先级**: P0
- **测试类型**: 兼容性
- **前置条件**: uv 可用，但 `vendor/hkt-memory/scripts/hkt_memory_v5.py` 不存在
- **测试步骤**:
  1. 临时重命名 `vendor/hkt-memory/scripts/hkt_memory_v5.py`
  2. 执行 `rebuild-index --full`
- **预期结果**:
  - stderr 输出 `Warning: vendor/hkt-memory/scripts/hkt_memory_v5.py not found. Skipping vector index rebuild.`
  - 进程 exit code 为 0
- **关联代码**: `rebuild-index.ts:315-320`, `rebuild-index.ts:69-81`

### TC-B-051. rebuild-index — 15 秒 git 超时保护
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**: 可构造 git diff / rev-parse hang 的环境
- **测试步骤**:
  1. 用 wrapper 替换 git 使 `git diff --name-only` 阻塞 60 秒
  2. 设置 `.last-rebuild-commit` 为有效 hash
  3. 执行 `rebuild-index`
- **预期结果**:
  - 15 秒内返回（`getChangedFiles` 中的 timeout: 15000）
  - 不会无限阻塞
- **关联代码**: `rebuild-index.ts:136-139`, `rebuild-index.ts:155-159`, `rebuild-index.ts:285-288`

### TC-B-052. rebuild-index — 30 秒 store 超时保护
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**: uv 和 hkt_memory_v5.py 均可用
- **测试步骤**:
  1. 构造一个极大的 `.md` 文件（> 10MB）以触发慢速 store
  2. 执行 `rebuild-index --full`
- **预期结果**:
  - `storeToHktMemory` 中 `spawnSync` 的 timeout 为 30000
  - 超过 30 秒未返回则 kill 子进程，该文件记为 error
- **关联代码**: `rebuild-index.ts:205`, `rebuild-index.ts:229`

### TC-B-053. rebuild-index — store 失败时 stdin 重试机制
- **优先级**: P1
- **测试类型**: 功能
- **前置条件**: uv 和 hkt_memory_v5.py 可用，但 `--content-file` 方式因某种原因失败
- **测试步骤**:
  1. 构造一个场景使第一次 `uv run ... store --content-file <tmp>` 失败（如临时文件被删除）
  2. 观察 stderr 输出
- **预期结果**:
  - stderr 出现 `First store method failed, retrying with stdin...`
  - 第二次尝试通过 stdin 传递 content
- **关联代码**: `rebuild-index.ts:210-233`

### TC-B-054. rebuild-index — 增量模式无变更文件时计数为 0
- **优先级**: P1
- **测试类型**: 功能
- **前置条件**: 知识仓库干净，`.last-rebuild-commit` 等于当前 HEAD
- **测试步骤**:
  1. `git rev-parse HEAD > ~/.galeharness/knowledge/.last-rebuild-commit`
  2. 执行 `rebuild-index`
- **预期结果**:
  - stdout 显示 `(incremental mode)`
  - `Processed: 0`, `Skipped: 0`, `Errors: 0`
  - `.last-rebuild-commit` 被重新写入当前 HEAD（因为 errors === 0）
- **关联代码**: `rebuild-index.ts:278-295`, `rebuild-index.ts:360-368`

### TC-B-055. rebuild-index — `collectMarkdownFiles` 对不存在的目录返回空数组
- **优先级**: P2
- **测试类型**: 边界
- **前置条件**: 任意
- **测试步骤**:
  1. 直接调用 `collectMarkdownFiles("/nonexistent/path-12345")`
- **预期结果**:
  - 返回 `[]`，不抛出异常
- **关联代码**: `rebuild-index.ts:91-95`

### TC-B-056. rebuild-index — 单个文件读取错误不阻塞其他文件
- **优先级**: P1
- **测试类型**: 功能
- **前置条件**: 仓库中存在多个 `.md` 文件，其中一个不可读
- **测试步骤**:
  1. 创建 `good1.md`、`good2.md` 和一个权限为 `000` 的 `bad.md`
  2. 执行 `rebuild-index --full`
- **预期结果**:
  - `Errors` 计数 ≥ 1
  - `Processed` 计数包含成功处理的文件
  - 不抛出未捕获异常，循环继续处理后续文件
- **关联代码**: `rebuild-index.ts:338-357`

---

## 五、index.ts CLI 入口

### TC-B-057. index CLI — `resolve-home` 输出纯路径
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 任意
- **测试步骤**:
  1. 执行 `bun run cmd/gale-knowledge/index.ts resolve-home`
- **预期结果**:
  - stdout 仅输出一行绝对路径（如 `~/.galeharness/knowledge` 或环境变量指定的路径）
  - 无多余空行或 JSON 包装
- **关联代码**: `index.ts:31-40`

### TC-B-058. index CLI — `resolve-path` 默认输出 `docDir` 纯路径
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 任意
- **测试步骤**:
  1. 执行 `bun run cmd/gale-knowledge/index.ts resolve-path --type brainstorms`
- **预期结果**:
  - stdout 仅输出一行绝对路径（如 `.../knowledge/<project>/brainstorms`）
  - 无 JSON 包装
- **关联代码**: `index.ts:79-81`

### TC-B-059. index CLI — `resolve-path --json` 输出完整对象
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 任意
- **测试步骤**:
  1. 执行 `bun run cmd/gale-knowledge/index.ts resolve-path --type plans --json`
- **预期结果**:
  - stdout 输出格式化的 JSON，包含 `home`、`projectDir`、`docDir`、`projectName` 四个字段
  - 示例：
    ```json
    {
      "home": "/Users/xxx/.galeharness/knowledge",
      "projectDir": "/Users/xxx/.galeharness/knowledge/...",
      "docDir": "/Users/xxx/.galeharness/knowledge/.../plans",
      "projectName": "..."
    }
    ```
- **关联代码**: `index.ts:77-78`

### TC-B-060. index CLI — `resolve-path --type` 有效值通过
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 任意
- **测试步骤**:
  1. 依次执行 `--type brainstorms`、`--type plans`、`--type solutions`
- **预期结果**:
  - 三次均 exit 0，输出对应路径
- **关联代码**: `index.ts:64-71`

### TC-B-061. index CLI — `resolve-path --type` 无效值 exit 1
- **优先级**: P0
- **测试类型**: 边界
- **前置条件**: 任意
- **测试步骤**:
  1. 执行 `bun run cmd/gale-knowledge/index.ts resolve-path --type invalid`
- **预期结果**:
  - stderr 输出 `Error: --type must be one of: brainstorms, plans, solutions`
  - exit code 为 1
- **关联代码**: `index.ts:65-70`

### TC-B-062. index CLI — `resolve-path --project` 指定项目名
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 任意
- **测试步骤**:
  1. 执行 `bun run cmd/gale-knowledge/index.ts resolve-path --type brainstorms --project my-custom-project`
- **预期结果**:
  - 输出路径中包含 `my-custom-project` 而非自动检测的项目名
- **关联代码**: `index.ts:73-76`

### TC-B-063. index CLI — `extract-project` 输出项目名
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 当前目录为 git 仓库（有 origin remote）
- **测试步骤**:
  1. 在项目根目录执行 `bun run cmd/gale-knowledge/index.ts extract-project`
- **预期结果**:
  - stdout 输出从 git remote URL 提取的 repo 名（不含 `.git` 后缀）
  - 若当前目录无 git remote，则输出当前目录名
- **关联代码**: `index.ts:85-94`

### TC-B-064. index CLI — 无子命令时显示 usage
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 任意
- **测试步骤**:
  1. 执行 `bun run cmd/gale-knowledge/index.ts`
- **预期结果**:
  - stdout 或 stderr 显示 usage 帮助文本
  - 列出所有可用子命令：`resolve-home`、`resolve-path`、`extract-project`、`init`、`commit`、`rebuild-index`、`setup-ci`
  - exit code 为 0
- **关联代码**: `index.ts:117-122`

### TC-B-065. index CLI — `init` 子命令正确路由
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 任意
- **测试步骤**:
  1. 执行 `bun run cmd/gale-knowledge/index.ts init`
- **预期结果**:
  - 调用 `initCommand`，行为与直接测试 `initKnowledgeRepo` 一致
  - 输出 `Initialized knowledge repo at ...` 或 `Knowledge repo already exists at ...`
- **关联代码**: `index.ts:112`

### TC-B-066. index CLI — `commit` 子命令正确路由
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 存在未提交的变更
- **测试步骤**:
  1. 执行 `bun run cmd/gale-knowledge/index.ts commit --project x --type brainstorm --title t`
- **预期结果**:
  - 调用 `commitCommand`，生成 commit 或提示 No changes
- **关联代码**: `index.ts:113`

### TC-B-067. index CLI — `rebuild-index` 子命令正确路由
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 任意
- **测试步骤**:
  1. 执行 `bun run cmd/gale-knowledge/index.ts rebuild-index --full`
- **预期结果**:
  - 调用 `rebuildIndexCommand`，输出 `[gale-knowledge] rebuild-index complete (full mode)`
- **关联代码**: `index.ts:114`

### TC-B-068. index CLI — `setup-ci` 子命令正确路由
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 任意
- **测试步骤**:
  1. 执行 `bun run cmd/gale-knowledge/index.ts setup-ci`
- **预期结果**:
  - 调用 `setupCiCommand`，输出 `Created workflow: ...` 或 `Updated workflow: ...`
- **关联代码**: `index.ts:115`

### TC-B-069. index CLI — `resolve-path` 对非法 path component 抛出异常
- **优先级**: P1
- **测试类型**: 安全
- **前置条件**: 任意
- **测试步骤**:
  1. 执行 `bun run cmd/gale-knowledge/index.ts resolve-path --type brainstorms --project "../etc"`
- **预期结果**:
  - 进程抛出 `Invalid path component: ../etc`
  - 或 stderr 输出对应错误并 exit 1（取决于异常是否被 citty 捕获）
- **关联代码**: `src/knowledge/home.ts:147-152`, `index.ts:73-76`

---

## 六、跨命令集成

### TC-B-070. 集成 — `init → write → commit → rebuild-index` 完整流程
- **优先级**: P0
- **测试类型**: 集成
- **前置条件**: 干净环境（无知识仓库）
- **测试步骤**:
  1. `export GALE_KNOWLEDGE_HOME=/tmp/gk-integration`
  2. `bun run cmd/gale-knowledge/index.ts init`
  3. `mkdir -p /tmp/gk-integration/my-project/plans`
  4. `echo "# Plan" > /tmp/gk-integration/my-project/plans/api-design.md`
  5. `bun run cmd/gale-knowledge/index.ts commit --project my-project --type plan --title "api-design"`
  6. `bun run cmd/gale-knowledge/index.ts rebuild-index --full`
- **预期结果**:
  - init 成功创建仓库
  - commit 成功，输出包含 hash 和 `docs(my-project/plan): api-design`
  - rebuild-index 成功，输出 `(full mode)`，`.last-rebuild-commit` 被写入最新 HEAD
- **关联代码**: 全链路

### TC-B-071. 集成 — `commit → rebuild-index` 增量流程
- **优先级**: P0
- **测试类型**: 集成
- **前置条件**: 已完成 TC-B-070，且 `.last-rebuild-commit` 已写入
- **测试步骤**:
  1. 新增文件：`echo "# New" > /tmp/gk-integration/my-project/plans/feature.md`
  2. `bun run cmd/gale-knowledge/index.ts commit --project my-project --type plan --title "feature"`
  3. `bun run cmd/gale-knowledge/index.ts rebuild-index`
- **预期结果**:
  - commit 成功
  - rebuild-index 进入 incremental mode
  - 仅处理新增/变更的 `.md` 文件
  - 无 errors 时 `.last-rebuild-commit` 更新为新 HEAD
- **关联代码**: `git-ops.ts:70-124`, `rebuild-index.ts:278-368`

### TC-B-072. 集成 — 多项目多类型文档批量提交与索引
- **优先级**: P1
- **测试类型**: 集成
- **前置条件**: 知识仓库已初始化
- **测试步骤**:
  1. 创建以下文件：
     - `project-a/brainstorms/idea.md`
     - `project-a/solutions/fix.md`
     - `project-b/plans/roadmap.md`
  2. 执行 commit（一次提交所有变更）
  3. 执行 `rebuild-index --full`
- **预期结果**:
  - 一次 commit 包含所有三个文件
  - rebuild-index 处理所有三个 `.md` 文件
  - 统计中的 `Processed` / `Skipped` / `Errors` 之和等于文件总数
- **关联代码**: `git-ops.ts:76`, `rebuild-index.ts:270-376`

### TC-B-073. 集成 — force push 后增量模式自动回退 full
- **优先级**: P1
- **测试类型**: 集成
- **前置条件**: 知识仓库有历史 commit，且 `.last-rebuild-commit` 指向旧历史
- **测试步骤**:
  1. 记录旧 HEAD：`git rev-parse HEAD > /tmp/gk-integration/.last-rebuild-commit`
  2. 在仓库中执行 `git reset --hard HEAD~1` 或重写历史
  3. 新增一个 `.md` 文件并 commit
  4. 执行 `rebuild-index`
- **预期结果**:
  - 旧 hash 不可达，`git cat-file -t` 失败
  - stderr 提示 `Last rebuild commit unreachable, falling back to full mode.`
  - 最终按 full mode 处理所有现存 `.md` 文件
  - 无未捕获异常
- **关联代码**: `rebuild-index.ts:284-293`

---

## 附录：测试环境快速准备脚本

```bash
# 1. 隔离测试目录
export GALE_KNOWLEDGE_HOME="/tmp/gk-test-$(date +%s)"

# 2. 进入项目根目录
cd /path/to/GaleHarnessCodingCLI

# 3. 运行 init
bun run cmd/gale-knowledge/index.ts init

# 4. 验证
ls -la "$GALE_KNOWLEDGE_HOME"
git -C "$GALE_KNOWLEDGE_HOME" log --oneline
```
