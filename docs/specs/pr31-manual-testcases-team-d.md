以下是针对 PR #31 安全机制变更的完整点对点人工测试用例，覆盖路径穿越、Shell 注入、符号链接、Commit hash 校验、超时保护、增量索引回退、输入边界、并发竞态、权限边界及回退链完整性。

---

# PR #31 安全加固与边界条件 — 人工测试用例（团队 D）

## 测试说明
- **测试目标**: `src/knowledge/home.ts`、`src/knowledge/writer.ts`、`cmd/gale-knowledge/git-ops.ts`、`cmd/gale-knowledge/rebuild-index.ts`、`cmd/gale-knowledge/init.ts`、`cmd/gale-knowledge/index.ts`
- **测试环境**: macOS / Linux（路径分隔符为 `/`），使用临时目录隔离
- **测试工具**: `bun test` 手动验证 + 终端命令直接注入

---

## 一、路径穿越防护

### TC-D-001. [路径穿越] — filename 使用 `../etc/passwd` 穿越到系统敏感目录
- **优先级**: P0
- **测试类型**: 安全/渗透
- **前置条件**: 设置 `GALE_KNOWLEDGE_HOME` 指向临时目录，确保知识仓库可写
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "solutions", filename: "../etc/passwd", content: "# test", projectName: "test-project" })`
  2. 观察是否抛出异常或写入到非预期路径
  3. 检查文件系统是否未在 `GALE_KNOWLEDGE_HOME/etc/passwd` 创建文件
- **预期结果**:
  - 抛出 `Error: Invalid filename: path traversal detected`
  - 文件系统未在 `GALE_KNOWLEDGE_HOME` 父级目录创建任何文件
- **关联代码**: `src/knowledge/writer.ts:60-65`
- **风险等级**: 高

### TC-D-002. [路径穿越] — filename 使用 `../../.ssh/id_rsa` 多级穿越
- **优先级**: P0
- **测试类型**: 安全/渗透
- **前置条件**: 同 TC-D-001
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "plans", filename: "../../.ssh/id_rsa", content: "ssh-key", projectName: "test-project" })`
  2. 检查是否成功阻止写入到 `~/.ssh/id_rsa` 或系统 `/.ssh/id_rsa`
  3. 验证 `resolve()` 后的路径与 `safeBase` 前缀比较逻辑生效
- **预期结果**:
  - 抛出 `Error: Invalid filename: path traversal detected`
  - 系统 `~/.ssh/` 目录无新增文件
- **关联代码**: `src/knowledge/writer.ts:60-65`
- **风险等级**: 高

### TC-D-003. [路径穿越] — projectName 使用 `../other-project` 穿越出知识仓库根目录
- **优先级**: P0
- **测试类型**: 安全/渗透
- **前置条件**: 设置 `GALE_KNOWLEDGE_HOME` 指向临时目录
- **测试步骤**:
  1. 调用 `resolveKnowledgePath({ type: "solutions", projectName: "../other-project" })`
  2. 观察 `sanitizePathComponent` 是否拦截
  3. 另在 CLI 中执行 `bun cmd/gale-knowledge/index.ts resolve-path --type solutions --project ../other-project`
- **预期结果**:
  - 函数调用抛出 `Error: Invalid path component: ../other-project`
  - CLI 进程以非零退出码退出并打印错误信息
  - 返回的 `projectDir` 不包含 `..` 穿越片段
- **关联代码**: `src/knowledge/home.ts:147-152`、`cmd/gale-knowledge/index.ts:73-76`
- **风险等级**: 高

### TC-D-003a. [路径穿越补充] — filename 使用绝对路径 `/etc/passwd`
- **优先级**: P1
- **测试类型**: 安全/渗透
- **前置条件**: 同 TC-D-001
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "brainstorms", filename: "/etc/passwd", content: "# x", projectName: "test-project" })`
  2. 验证 `join(docDir, "/etc/passwd")` 被 `resolve()` 后是否被 `startsWith` 拦截
- **预期结果**:
  - 抛出 `Error: Invalid filename: path traversal detected`
  - `resolve("/etc/passwd")` 不以 `safeBase + sep` 开头，拦截成功
- **关联代码**: `src/knowledge/writer.ts:60-65`
- **风险等级**: 高

---

## 二、Shell 注入防护

### TC-D-004. [Shell 注入] — title 包含分号命令分隔符 `; rm -rf /;`
- **优先级**: P0
- **测试类型**: 安全/渗透
- **前置条件**: 使用临时目录初始化知识仓库，存在待提交变更
- **测试步骤**:
  1. 在知识仓库中创建一个新文件
  2. 调用 `commitKnowledgeChanges({ project: "test", type: "brainstorm", title: "; rm -rf /;" })`
  3. 检查生成的 commit message 及 git log
  4. 验证系统根目录未被删除（使用 Docker 容器或临时沙箱环境）
- **预期结果**:
  - `sanitizeTitle` 不会过滤分号，但 `spawnSync("git", ["commit", "-m", commitMessage], ...)` 使用**数组参数**，git 将整个字符串作为单个消息参数处理
  - 最终 commit message 为 `docs(test/brainstorm): ; rm -rf /;`
  - 未执行任何系统命令，目录完好
- **关联代码**: `cmd/gale-knowledge/git-ops.ts:48-58`、`cmd/gale-knowledge/git-ops.ts:94-98`
- **风险等级**: 高

### TC-D-005. [Shell 注入] — title 包含 `$()` 命令替换 `$(whoami)`
- **优先级**: P0
- **测试类型**: 安全/渗透
- **前置条件**: 同 TC-D-004
- **测试步骤**:
  1. 创建待提交文件
  2. 调用 `commitKnowledgeChanges({ project: "test", type: "plan", title: "$(whoami)" })`
  3. 查看生成的 commit message
- **预期结果**:
  - `sanitizeTitle` 移除 `$` 符号，title 变为 `(whoami)`
  - commit message 为 `docs(test/plan): (whoami)`
  - 无命令执行，数组参数进一步兜底
- **关联代码**: `cmd/gale-knowledge/git-ops.ts:48-58`
- **风险等级**: 高

### TC-D-006. [Shell 注入] — title 包含反引号命令替换 `` `date` ``
- **优先级**: P0
- **测试类型**: 安全/渗透
- **前置条件**: 同 TC-D-004
- **测试步骤**:
  1. 创建待提交文件
  2. 调用 `commitKnowledgeChanges({ project: "test", type: "solution", title: "`date`" })`
  3. 查看 commit message 及系统日志
- **预期结果**:
  - `sanitizeTitle` 将反引号替换为单引号，title 变为 `'date'`
  - commit message 为 `docs(test/solution): 'date'`
  - 未执行 `date` 命令
- **关联代码**: `cmd/gale-knowledge/git-ops.ts:48-58`
- **风险等级**: 高

### TC-D-006a. [Shell 注入补充] — title 包含双引号与反斜杠组合 `"\"; whoami; \""`
- **优先级**: P1
- **测试类型**: 安全/渗透
- **前置条件**: 同 TC-D-004
- **测试步骤**:
  1. 调用 `commitKnowledgeChanges` 使用上述 payload
  2. 检查 `sanitizeTitle` 是否同时处理双引号、反斜杠
- **预期结果**:
  - 双引号被替换为单引号，反斜杠被移除
  - 最终 title 无恶意拼接能力
- **关联代码**: `cmd/gale-knowledge/git-ops.ts:48-58`
- **风险等级**: 中

---

## 三、符号链接穿越防护

### TC-D-007. [符号链接穿越] — 知识仓库内存在指向 /etc 的 symlink，运行 rebuild-index
- **优先级**: P0
- **测试类型**: 安全/渗透
- **前置条件**: 已初始化知识仓库，至少有一个正常 .md 文件；运行环境为类 Unix 系统
- **测试步骤**:
  1. 在知识仓库根目录执行 `ln -s /etc etc-link`
  2. 确保 `etc-link` 目录下有文件（如 `passwd`）
  3. 运行 `rebuildIndex({ knowledgeHome: repoDir, full: true })`
  4. 观察收集到的文件列表及 stderr 输出
  5. 检查是否有 `/etc/passwd` 内容被传入 HKTMemory 索引
- **预期结果**:
  - `collectMarkdownFiles` 遇到 `entry.isSymbolicLink()` 时直接 `continue`
  - `etc-link` 下的文件不会被收集
  - `processed` 计数仅包含正常 .md 文件
  - 未发生符号链接穿越，未读取系统文件
- **关联代码**: `cmd/gale-knowledge/rebuild-index.ts:86-110`（第 99 行 `isSymbolicLink()`）
- **风险等级**: 高

### TC-D-007a. [符号链接补充] — symlink 指向仓库外其他项目的敏感目录
- **优先级**: P1
- **测试类型**: 安全/渗透
- **前置条件**: 同 TC-D-007
- **测试步骤**:
  1. 创建 `ln -s ~/.ssh ssh-link` 在知识仓库内
  2. 运行 `rebuildIndex({ full: true })`
- **预期结果**:
  - `.ssh` 下的文件不会被索引
  - 无敏感文件路径进入 `filesToProcess` 数组
- **关联代码**: `cmd/gale-knowledge/rebuild-index.ts:99`
- **风险等级**: 高

---

## 四、Commit Hash 注入防护

### TC-D-008. [Commit hash 注入] — hash 包含 Shell 元字符 `"; cat /etc/passwd"`
- **优先级**: P0
- **测试类型**: 安全/渗透
- **前置条件**: 已初始化知识仓库，存在至少两个 commit
- **测试步骤**:
  1. 在 `.last-rebuild-commit` 文件中写入 `"; cat /etc/passwd"`
  2. 运行 `rebuildIndex({ knowledgeHome: repoDir })`
  3. 观察 `getChangedFiles` 的返回值及 stderr
- **预期结果**:
  - `getChangedFiles` 中 `/^[0-9a-f]{7,40}$/i.test(lastCommit)` 返回 `false`
  - 函数直接返回 `[]`（空数组）
  - 不会调用 `spawnSync("git", ["diff", ...], ...)`，无 Shell 注入风险
  - 回退到 `full` 模式或保持增量但无文件变化
- **关联代码**: `cmd/gale-knowledge/rebuild-index.ts:130-148`（第 134 行正则校验）
- **风险等级**: 高

### TC-D-009. [Commit hash 注入] — hash 为 `HEAD`（不通过正则校验）
- **优先级**: P0
- **测试类型**: 安全/边界
- **前置条件**: 同 TC-D-008
- **测试步骤**:
  1. 在 `.last-rebuild-commit` 中写入 `HEAD`
  2. 运行 `rebuildIndex({ knowledgeHome: repoDir })`
- **预期结果**:
  - 正则 `/^[0-9a-f]{7,40}$/i` 拒绝 `HEAD`（含非十六进制字符）
  - `getChangedFiles` 返回 `[]`
  - 增量模式下进入 `filesToProcess.length === 0` 分支
  - `git cat-file -t HEAD` 虽可被 git 识别，但因前面正则拦截，此路径不会被执行
- **关联代码**: `cmd/gale-knowledge/rebuild-index.ts:134`
- **风险等级**: 高

### TC-D-010. [Commit hash 注入] — hash 为 41 位字符 `"g" * 41`
- **优先级**: P0
- **测试类型**: 安全/边界
- **前置条件**: 同 TC-D-008
- **测试步骤**:
  1. 在 `.last-rebuild-commit` 中写入 41 个 `g`（`gggg...gg`，41 次）
  2. 运行 `rebuildIndex({ knowledgeHome: repoDir })`
- **预期结果**:
  - 正则 `{7,40}` 限制最大 40 字符，41 字符不匹配
  - `getChangedFiles` 返回 `[]`
  - 不会将超长字符串传入 git diff
- **关联代码**: `cmd/gale-knowledge/rebuild-index.ts:134`
- **风险等级**: 高

### TC-D-010a. [Commit hash 补充] — hash 为 6 位字符（低于最小长度 7）
- **优先级**: P1
- **测试类型**: 安全/边界
- **前置条件**: 同 TC-D-008
- **测试步骤**:
  1. 写入 `abcdef`（6 位）到 `.last-rebuild-commit`
  2. 运行 `rebuildIndex`
- **预期结果**:
  - 正则要求最少 7 位，6 位不匹配
  - 返回 `[]`，不执行 git diff
- **关联代码**: `cmd/gale-knowledge/rebuild-index.ts:134`
- **风险等级**: 中

---

## 五、进程挂起与超时保护

### TC-D-011. [进程挂起] — git remote get-url 命令挂起，验证 15s 超时触发
- **优先级**: P0
- **测试类型**: 安全/异常恢复
- **前置条件**: 类 Unix 环境，可设置 `GIT_SSH_COMMAND` 或拦截 `git` 命令
- **测试步骤**:
  1. 创建一个包含 `.git` 目录的项目文件夹
  2. 设置 `GIT_SSH_COMMAND="sleep 300"` 或构造一个指向无限等待 remote 的仓库
  3. 调用 `extractProjectName(cwd)`（内部使用 `execSync("git remote get-url origin", { timeout: 15000 })`）
  4. 使用秒表计时，观察异常抛出时间
- **预期结果**:
  - 约 15 秒后抛出异常（实际因操作系统调度可能略长，但不超过 20 秒）
  - 异常信息包含 `ETIMEDOUT` 或 `timeout` 字样
  - 进程不会永久挂起
- **关联代码**: `src/knowledge/home.ts:115-120`
- **风险等级**: 高

### TC-D-012. [进程挂起] — git init / git commit 在 init.ts 中挂起，验证 15s 超时
- **优先级**: P0
- **测试类型**: 安全/异常恢复
- **前置条件**: 可替换系统 `git` 为 wrapper 脚本
- **测试步骤**:
  1. 创建临时目录并在 PATH 最前面放置 `git` wrapper：
     ```bash
     #!/bin/bash
     sleep 300
     ```
  2. 调用 `initKnowledgeRepo(tempDir)`
  3. 观察超时行为
  4. 对 `commitKnowledgeChanges` 重复上述步骤，验证所有 `spawnSync` 调用均有 timeout
- **预期结果**:
  - `initKnowledgeRepo` 在 `git init` 阶段约 15 秒后抛出 `git init failed` 或进程异常
  - `commitKnowledgeChanges` 在 `git add` 阶段约 15 秒后返回 `committed: false`
- **关联代码**: `cmd/gale-knowledge/init.ts:45-51`、`cmd/gale-knowledge/git-ops.ts:72-79`
- **风险等级**: 高

### TC-D-012a. [进程挂起补充] — uv run store 在 rebuild-index 中挂起，验证 30s 超时
- **优先级**: P1
- **测试类型**: 安全/异常恢复
- **前置条件**: uv 已安装，可 mock `uv` 命令
- **测试步骤**:
  1. 在 PATH 中放置 `uv` wrapper 使其 `sleep 300`
  2. 运行 `rebuildIndex({ full: true })`（确保有文件待处理）
  3. 观察 `storeToHktMemory` 是否 30 秒后失败并进入 stdin fallback
  4. fallback 的 `spawnSync` 同样应有 30s 超时
- **预期结果**:
  - 第一次 `uv run` 约 30 秒后超时
  - 重试 stdin 方式同样约 30 秒后超时
  - `errors` 计数增加，不阻塞后续文件
- **关联代码**: `cmd/gale-knowledge/rebuild-index.ts:188-234`
- **风险等级**: 中

### TC-D-012b. [超时覆盖检查] — 所有 execSync/spawnSync 调用均已声明 timeout
- **优先级**: P1
- **测试类型**: 安全/审计
- **前置条件**: 代码静态审查
- **测试步骤**:
  1. 全局搜索 `execSync` 和 `spawnSync`
  2. 逐条核对是否包含 `timeout:` 属性
- **预期结果**:
  - `src/knowledge/home.ts:115` — `timeout: 15000` ✓
  - `cmd/gale-knowledge/init.ts:47,57,60,64,70` — 均有 `timeout: 15000` ✓
  - `cmd/gale-knowledge/git-ops.ts:76,83,90,91,98,105` — 均有 `timeout: 15000` ✓
  - `cmd/gale-knowledge/rebuild-index.ts:59,136,155,188,213,285` — 均有 timeout（git 15s，uv 30s）✓
- **关联代码**: 全文件 grep 结果
- **风险等级**: 中

---

## 六、增量索引丢失与回退

### TC-D-013. [增量索引丢失] — 删除 `.last-rebuild-commit` 文件后重建
- **优先级**: P0
- **测试类型**: 边界/异常恢复
- **前置条件**: 知识仓库已有历史 commit 且上次重建后存在 `.last-rebuild-commit`
- **测试步骤**:
  1. 确认 `.last-rebuild-commit` 存在且包含有效 hash
  2. 删除该文件：`rm .last-rebuild-commit`
  3. 运行 `rebuildIndex({ knowledgeHome: repoDir })`（不指定 full）
- **预期结果**:
  - `getLastRebuildCommit` 返回 `null`
  - 进入 `mode = "full"` 分支
  - `filesToProcess = collectMarkdownFiles(knowledgeHome)`
  - 所有 .md 文件被重新扫描（而非仅变更文件）
- **关联代码**: `cmd/gale-knowledge/rebuild-index.ts:278-300`
- **风险等级**: 中

### TC-D-014. [增量索引丢失] — 向 `.last-rebuild-commit` 写入无效 hash
- **优先级**: P0
- **测试类型**: 边界/异常恢复
- **前置条件**: 同 TC-D-013
- **测试步骤**:
  1. 写入 `deadbeef0000`（有效正则但不存在于 git 历史）到 `.last-rebuild-commit`
  2. 运行 `rebuildIndex({ knowledgeHome: repoDir })`
- **预期结果**:
  - `getChangedFiles` 中正则通过（10 位十六进制）
  - `spawnSync("git", ["diff", "--name-only", "deadbeef0000", "HEAD", "--", "*.md"])` 执行
  - git 返回非零状态（无效 commit），catch 返回 `[]`
  - `filesToProcess.length === 0`
  - 进入 `git cat-file -t` 验证分支
  - `verify.status !== 0`，hash 不可达
  - stderr 打印 `[gale-knowledge] Last rebuild commit unreachable, falling back to full mode.`
  - `mode = "full"`，全量重建
- **关联代码**: `cmd/gale-knowledge/rebuild-index.ts:134-148`、`cmd/gale-knowledge/rebuild-index.ts:284-293`
- **风险等级**: 中

### TC-D-015. [增量索引丢失] — force-push 后历史 hash 不可达
- **优先级**: P0
- **测试类型**: 边界/异常恢复
- **前置条件**: 知识仓库为本地 git 仓库，可执行 force-push 模拟（如 `git commit --amend` 后 `git reflog expire` 或新建 orphan branch）
- **测试步骤**:
  1. 创建初始 commit 并记录 hash1
  2. 运行 `rebuildIndex`，保存 `.last-rebuild-commit` = hash1
  3. 执行 `git commit --amend --no-edit` 生成新 hash2，使 hash1 不可达
  4. 运行 `git reflog expire --expire=now --all && git gc --prune=now`（彻底清理）
  5. 再次运行 `rebuildIndex({ knowledgeHome: repoDir })`
- **预期结果**:
  - `getChangedFiles` 中 git diff 失败或返回空
  - `git cat-file -t hash1` 返回非零
  - 自动降级为 full 模式
  - `.last-rebuild-commit` 不会被旧 hash1 阻塞，最终更新为新的 HEAD
- **关联代码**: `cmd/gale-knowledge/rebuild-index.ts:284-293`
- **风险等级**: 中

---

## 七、空值与超长输入边界

### TC-D-016. [空输入边界] — title 为空字符串
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**: 知识仓库已初始化，有待提交文件
- **测试步骤**:
  1. 调用 `commitKnowledgeChanges({ project: "test", type: "brainstorm", title: "" })`
  2. 查看 commit message
- **预期结果**:
  - `sanitizeTitle("")` 返回 `""`
  - commit message 为 `docs(test/brainstorm): `
  - git commit 成功创建（空 message 在 `-m` 下被允许，即消息体为空）
- **关联代码**: `cmd/gale-knowledge/git-ops.ts:48-58`、`cmd/gale-knowledge/git-ops.ts:94-98`
- **风险等级**: 低

### TC-D-017. [空输入边界] — projectName 为空字符串
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**: 设置 `GALE_KNOWLEDGE_HOME` 指向临时目录
- **测试步骤**:
  1. 调用 `resolveKnowledgePath({ type: "solutions", projectName: "" })`
  2. 调用 `writeKnowledgeDocument({ type: "solutions", filename: "x.md", content: "# x", projectName: "" })`
- **预期结果**:
  - `sanitizePathComponent("")` 通过（无非法字符）
  - `projectDir = join(home, "")` 等价于 `home`
  - 文档写入到知识仓库根目录下的 `solutions/x.md`
  - 不抛出异常，但行为需谨慎评估（空 projectName 可能导致项目文档混杂在根目录）
- **关联代码**: `src/knowledge/home.ts:147-152`、`src/knowledge/home.ts:154-166`
- **风险等级**: 中

### TC-D-018. [超长输入边界] — title 超过 1000 字符
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**: 同 TC-D-016
- **测试步骤**:
  1. 构造长度 2000 的 title（无特殊字符，仅 `a` 重复）
  2. 调用 `commitKnowledgeChanges` 并提交
- **预期结果**:
  - `sanitizeTitle` 不过滤长度，完整保留
  - `spawnSync` 数组参数传递完整 title
  - git commit 成功（git 对 message 长度无硬性限制）
  - 无缓冲区溢出或截断
- **关联代码**: `cmd/gale-knowledge/git-ops.ts:48-58`
- **风险等级**: 低

### TC-D-019. [超长输入边界] — filename 超过 255 字节（操作系统文件名极限）
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**: 同 TC-D-001
- **测试步骤**:
  1. 构造长度 300 的 filename（如 `a...a.md`，300 个 a）
  2. 调用 `writeKnowledgeDocument`
- **预期结果**:
  - 路径穿越检查通过（无 `..` 或分隔符）
  - `writeFileSync` 因操作系统限制（macOS HFS+/APFS 约 255 字节）抛出 `ENAMETOOLONG`
  - 进入 fallback 逻辑，尝试写入 `<cwd>/docs/<type>/<超长文件名>`
  - fallback 同样失败，最终抛出 `Failed to write knowledge document to both primary and fallback paths: ENAMETOOLONG`
- **关联代码**: `src/knowledge/writer.ts:48-90`
- **风险等级**: 低

### TC-D-019a. [空输入补充] — content 为空字符串
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**: 同 TC-D-001
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "plans", filename: "empty.md", content: "", projectName: "test" })`
  2. 读取写入的文件
- **预期结果**:
  - `injectProjectFrontmatter("")` 返回包含 `project: test` 的 frontmatter
  - 文件成功写入，内容不为空（至少包含 `---\nproject: test\n---\n`）
- **关联代码**: `src/knowledge/writer.ts:103-116`
- **风险等级**: 低

---

## 八、并发与竞态条件

### TC-D-020. [并发竞态] — 同时运行两个 rebuild-index 进程
- **优先级**: P1
- **测试类型**: 安全/异常恢复
- **前置条件**: 知识仓库包含 50+ 个 .md 文件，uv 可用且 HKTMemory 脚本存在
- **测试步骤**:
  1. 准备足够的 .md 文件（模拟真实负载）
  2. 在 Shell 中同时启动两个 rebuild-index：
     ```bash
     bun cmd/gale-knowledge/index.ts rebuild-index &
     PID1=$!
     bun cmd/gale-knowledge/index.ts rebuild-index &
     PID2=$!
     wait $PID1 $PID2
     ```
  3. 检查 `.last-rebuild-commit` 最终内容
  4. 检查 `hkt-store-*` 临时文件是否泄漏在 `/tmp`
- **预期结果**:
  - 两个进程均能完成，不崩溃
  - `.last-rebuild-commit` 最终值为最后一次完成的进程的 HEAD hash
  - `/tmp` 下无残留的 `hkt-store-*.txt` 文件（`finally` 块清理）
  - 可能的重复索引（幂性由 HKTMemory 保证，非本组件问题）
- **关联代码**: `cmd/gale-knowledge/rebuild-index.ts:180-246`（temp file）、`cmd/gale-knowledge/rebuild-index.ts:252-261`（pointer 写入）
- **风险等级**: 中

---

## 九、权限边界

### TC-D-021. [权限边界] — 只读知识仓库目录下调用 writer
- **优先级**: P0
- **测试类型**: 安全/异常恢复
- **前置条件**: 类 Unix 环境，可使用 `chmod 555` 创建只读目录
- **测试步骤**:
  1. 创建知识仓库目录并设为只读：`chmod 555 $HOME/.galeharness/knowledge`
  2. 在项目目录下调用 `writeKnowledgeDocument({ type: "solutions", filename: "test.md", content: "# x" })`
  3. 观察返回值及文件系统状态
- **预期结果**:
  - `mkdirSync` / `writeFileSync` 抛出 `EACCES` 或 `EROFS`
  - 进入 fallback 逻辑，`usedFallback: true`
  - 文件成功写入 `<cwd>/docs/solutions/test.md`
  - stderr 打印 `falling back to` 警告
  - 返回的 `warning` 字段包含原始错误信息
- **关联代码**: `src/knowledge/writer.ts:67-89`
- **风险等级**: 中

### TC-D-022. [权限边界] — 无 git 目录下调用 git-ops 与 extractProjectName
- **优先级**: P0
- **测试类型**: 安全/异常恢复
- **前置条件**: 创建一个不含 `.git` 的普通目录
- **测试步骤**:
  1. 调用 `commitKnowledgeChanges({ knowledgeHome: nonGitDir, ... })`
  2. 调用 `extractProjectName(nonGitDir)`
  3. 调用 `getCurrentHead(nonGitDir)`
  4. 调用 `initKnowledgeRepo` 后再运行 `rebuildIndex`（验证正常路径）
- **预期结果**:
  - `commitKnowledgeChanges`: `committed: false`，`message` 包含 `Commit failed: git add failed`
  - `extractProjectName`: `execSync` 抛异常被 catch，返回 `basename(workDir)`
  - `getCurrentHead`: 返回 `null`
  - 不会崩溃，不会泄露路径信息到异常外
- **关联代码**: `cmd/gale-knowledge/git-ops.ts:74-79`、`src/knowledge/home.ts:114-133`、`cmd/gale-knowledge/rebuild-index.ts:153-166`
- **风险等级**: 中

---

## 十、回退链完整性

### TC-D-023. [回退链完整性] — 主路径失败 → docs/ 回退也失败 → 错误信息完整
- **优先级**: P0
- **测试类型**: 安全/异常恢复
- **前置条件**: 类 Unix 环境，需要同时让主路径和 fallback 路径都失败
- **测试步骤**:
  1. 设置 `resolveKnowledgePath` 返回一个不可能创建的路径（如 `/nonexistent/readonly/path`）
  2. 设置 `cwd` 也为一个只读目录（如 `/` 或 `chmod 555` 的临时目录）
  3. 调用 `writeKnowledgeDocument({ type: "plans", filename: "fail.md", content: "# x", cwd: readonlyDir })`
  4. 捕获抛出的异常，检查错误信息
- **预期结果**:
  - 主路径失败：`Knowledge repo write failed (ENOENT or EACCES)`
  - fallback 路径同样失败：`Failed to write knowledge document to both primary and fallback paths: ENOENT...`
  - 错误信息中**同时包含**主路径的失败原因和 fallback 路径的失败原因
  - 不丢失任何一层错误上下文
- **关联代码**: `src/knowledge/writer.ts:67-89`（第 73、78、87 行）
- **风险等级**: 中

---

## 十一、补充安全审计用例

### TC-D-024. [临时文件安全] — storeToHktMemory 崩溃时临时文件不泄漏
- **优先级**: P1
- **测试类型**: 安全/审计
- **前置条件**: uv 可用，可触发 `writeFileSync` 异常（如磁盘满）或手动 kill 进程
- **测试步骤**:
  1. 运行 `rebuildIndex` 处理文件
  2. 在处理过程中向进程发送 `SIGKILL`（模拟崩溃）
  3. 检查 `/tmp/hkt-store-*.txt` 残留
  4. 或在代码中临时注入 `throw new Error("mock")` 在 `writeFileSync(tmpFile, ...)` 之后、`spawnSync` 之前
- **预期结果**:
  - 正常完成时：`finally` 块执行 `unlinkSync`，无残留
  - 异常退出时： unfortunately `finally` 不会执行，但进程结束后 OS 清理 `/tmp`（非安全漏洞，但建议文档说明）
  - 代码内异常（throw）时：`finally` 执行，文件被删除
- **关联代码**: `cmd/gale-knowledge/rebuild-index.ts:179-246`
- **风险等级**: 低

### TC-D-025. [输入消毒遗漏] — projectName 仅包含反斜杠 `foo\bar`
- **优先级**: P1
- **测试类型**: 安全/边界
- **前置条件**: 同 TC-D-003
- **测试步骤**:
  1. 调用 `resolveKnowledgePath({ type: "solutions", projectName: "foo\\bar" })`
- **预期结果**:
  - `sanitizePathComponent` 中 `/[\/\\]/` 匹配反斜杠
  - 抛出 `Invalid path component: foo\bar`
- **关联代码**: `src/knowledge/home.ts:147-152`
- **风险等级**: 中

---

## 安全测试矩阵总览

| 防护措施 | 攻击向量 | 测试用例 | 状态 |
|---------|---------|---------|------|
| 路径穿越 | `filename="../etc/passwd"` | TC-D-001 | ✅ 已覆盖 |
| 路径穿越 | `filename="../../.ssh/id_rsa"` | TC-D-002 | ✅ 已覆盖 |
| 路径穿越 | `projectName="../other-project"` | TC-D-003 | ✅ 已覆盖 |
| 路径穿越 | `filename="/etc/passwd"` | TC-D-003a | ✅ 已覆盖 |
| Shell 注入 | `title="; rm -rf /;"` | TC-D-004 | ✅ 已覆盖 |
| Shell 注入 | `title="$(whoami)"` | TC-D-005 | ✅ 已覆盖 |
| Shell 注入 | `title="\`date\`"` | TC-D-006 | ✅ 已覆盖 |
| 符号链接穿越 | symlink 指向 /etc | TC-D-007 | ✅ 已覆盖 |
| Commit hash 注入 | `hash="; cat /etc/passwd"` | TC-D-008 | ✅ 已覆盖 |
| Commit hash 注入 | `hash="HEAD"`（不通过正则） | TC-D-009 | ✅ 已覆盖 |
| Commit hash 注入 | `hash="g" * 41` | TC-D-010 | ✅ 已覆盖 |
| 进程挂起 | git remote get-url 挂起 | TC-D-011 | ✅ 已覆盖 |
| 进程挂起 | git init/commit 挂起 | TC-D-012 | ✅ 已覆盖 |
| 进程挂起 | uv run store 挂起 | TC-D-012a | ✅ 已覆盖 |
| 超时审计 | 全局 execSync/spawnSync timeout 检查 | TC-D-012b | ✅ 已覆盖 |
| 增量索引丢失 | 删除 `.last-rebuild-commit` | TC-D-013 | ✅ 已覆盖 |
| 增量索引丢失 | 写入无效 hash | TC-D-014 | ✅ 已覆盖 |
| 增量索引丢失 | force-push 后 hash 不可达 | TC-D-015 | ✅ 已覆盖 |
| 空/超长边界 | 空 title | TC-D-016 | ✅ 已覆盖 |
| 空/超长边界 | 空 project | TC-D-017 | ✅ 已覆盖 |
| 空/超长边界 | 超长 title(>1000字符) | TC-D-018 | ✅ 已覆盖 |
| 空/超长边界 | 超长 filename | TC-D-019 | ✅ 已覆盖 |
| 并发/竞态 | 同时运行两个 rebuild-index | TC-D-020 | ✅ 已覆盖 |
| 权限边界 | 只读知识仓库目录下调用 writer | TC-D-021 | ✅ 已覆盖 |
| 权限边界 | 无 git 目录下调用 git-ops | TC-D-022 | ✅ 已覆盖 |
| 回退链完整性 | 主路径失败 → docs/失败 → 完整错误 | TC-D-023 | ✅ 已覆盖 |
| 临时文件泄漏 | storeToHktMemory 崩溃 | TC-D-024 | ✅ 已覆盖 |
| 反斜杠消毒 | `projectName="foo\bar"` | TC-D-025 | ✅ 已覆盖 |

---

**测试执行建议**: 
1. 在 Docker 容器或一次性虚拟机中执行 P0 渗透用例（TC-D-001~012），避免污染宿主环境。
2. TC-D-007、TC-D-015 需要类 Unix 权限和 git 操作，建议在 Linux 容器内执行。
