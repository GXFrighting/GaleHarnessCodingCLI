# PR #31 Board 集成变更 — 人工测试用例（Team C）

> **测试范围**：`knowledge-reader.ts`、`board-list.ts`、`board-show.ts`、`board-stats.ts`、`board.ts`  
> **测试策略**：覆盖所有分支、边界条件、命令行参数组合及端到端场景。  

---

## 一、`readKnowledgeDocuments` 核心逻辑

### TC-C-001. [knowledge-reader] — 知识仓库目录不存在时返回空数组
- **优先级**: P0
- **测试类型**: 边界
- **前置条件**: 设置 `GALE_KNOWLEDGE_HOME` 指向一个不存在的路径，或传入 `knowledgeHome: "/nonexistent/path"`
- **测试步骤**:
  1. 调用 `readKnowledgeDocuments({ knowledgeHome: "/tmp/does-not-exist-12345" })`
  2. 观察返回值
- **预期结果**: 返回空数组 `[]`，不抛出异常
- **关联代码**: `src/board/knowledge-reader.ts:60-62`

### TC-C-002. [knowledge-reader] — 空知识仓库目录（无项目子目录）
- **优先级**: P0
- **测试类型**: 边界
- **前置条件**: 创建一个空的临时目录作为 knowledge home
- **测试步骤**:
  1. 在该目录下不创建任何子目录或文件
  2. 调用 `readKnowledgeDocuments({ knowledgeHome: tempDir })`
- **预期结果**: 返回空数组 `[]`
- **关联代码**: `src/board/knowledge-reader.ts:64-67`

### TC-C-003. [knowledge-reader] — 递归扫描三层目录结构（project → type → file）
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 在临时 knowledge home 下构造 `<home>/my-project/plans/2026-04-20-test.md`
- **测试步骤**:
  1. 创建 `my-project/plans/` 目录
  2. 写入 Markdown 文件
  3. 调用 `readKnowledgeDocuments()`
- **预期结果**: 返回 1 条记录，`project` 为 `my-project`，`type` 为 `plans`，`path` 为相对路径
- **关联代码**: `src/board/knowledge-reader.ts:67-101`

### TC-C-004. [knowledge-reader] — Frontmatter 完整字段解析（title, date, project, topic）
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 创建带完整 frontmatter 的文档
- **测试步骤**:
  1. 写入文件，frontmatter 包含 `title: "My Solution"`、`date: 2026-04-15`、`project: custom-project`、`topic: auth`
  2. 调用读取函数
- **预期结果**: `title="My Solution"`, `date="2026-04-15"`, `project="custom-project"`, `topic="auth"`
- **关联代码**: `src/board/knowledge-reader.ts:156-201`

### TC-C-005. [knowledge-reader] — Frontmatter date 为 YAML Date 对象（js-yaml 解析为 Date）
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**: frontmatter 中 `date: 2026-04-15`（js-yaml 会解析为 Date 对象）
- **测试步骤**:
  1. 写入带日期 frontmatter 的文件
  2. 调用读取函数
- **预期结果**: `date` 字段为 `"2026-04-15"`（ISO 字符串切片前 10 位）
- **关联代码**: `src/board/knowledge-reader.ts:176-178`

### TC-C-006. [knowledge-reader] — Frontmatter date 为字符串
- **优先级**: P1
- **测试类型**: 功能
- **前置条件**: frontmatter 中 `date: "2026-04-15"`
- **测试步骤**:
  1. 写入文件
  2. 调用读取函数
- **预期结果**: `date` 字段为 `"2026-04-15"`
- **关联代码**: `src/board/knowledge-reader.ts:178-180`

### TC-C-007. [knowledge-reader] — 从文件名前缀提取日期（YYYY-MM-DD-）
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 文件名为 `2026-03-10-ideas.md`，frontmatter 无 date
- **测试步骤**:
  1. 创建文件并写入不含 date 的 frontmatter
  2. 调用读取函数
- **预期结果**: `date="2026-03-10"`, `title="ideas"`
- **关联代码**: `src/board/knowledge-reader.ts:164-166`

### TC-C-008. [knowledge-reader] — 无日期前缀的文件名作为 title
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 文件名为 `my-great-plan.md`，无 frontmatter title
- **测试步骤**:
  1. 创建文件，内容无 frontmatter
  2. 调用读取函数
- **预期结果**: `title="my-great-plan"`, `date` 为 `undefined`
- **关联代码**: `src/board/knowledge-reader.ts:169-171`

### TC-C-009. [knowledge-reader] — Frontmatter title 优先级高于文件名
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 文件名为 `2026-04-20-legacy.md`，frontmatter title 为 `"New Title"`
- **测试步骤**:
  1. 创建文件，frontmatter 指定 title
  2. 调用读取函数
- **预期结果**: `title="New Title"`，而非 `"legacy"`
- **关联代码**: `src/board/knowledge-reader.ts:169-171`

### TC-C-010. [knowledge-reader] — Frontmatter project 覆盖目录名
- **优先级**: P1
- **测试类型**: 功能
- **前置条件**: 文件位于 `proj-a/solutions/` 下，frontmatter `project: override-proj`
- **测试步骤**:
  1. 创建文件并写入 frontmatter
  2. 调用读取函数
- **预期结果**: `project="override-proj"`，而非 `"proj-a"`
- **关联代码**: `src/board/knowledge-reader.ts:184-186`

### TC-C-011. [knowledge-reader] — 无 frontmatter 文件使用 filename-as-title
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 文件无 frontmatter 块（首行不是 `---`）
- **测试步骤**:
  1. 创建纯 Markdown 文件 `# Hello`
  2. 调用读取函数
- **预期结果**: `title` 为文件名（不含 `.md`），`date` 从文件名提取（如有）
- **关联代码**: `src/board/knowledge-reader.ts:156-201`

### TC-C-012. [knowledge-reader] — 按日期降序排序（有日期 > 无日期）
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 创建 4 个文件：日期分别为 `2026-04-20`、`2026-02-15`、`2026-01-01`、无日期
- **测试步骤**:
  1. 在同一 project/plans 下创建上述文件
  2. 调用读取函数
- **预期结果**: 顺序为 `2026-04-20` → `2026-02-15` → `2026-01-01` → 无日期（空字符串 localeCompare 会排在有日期之后）
- **关联代码**: `src/board/knowledge-reader.ts:105-109`

### TC-C-013. [knowledge-reader] — 按 project 过滤
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 创建 `proj-x/plans/doc.md` 和 `proj-y/plans/doc.md`
- **测试步骤**:
  1. 调用 `readKnowledgeDocuments({ project: "proj-x" })`
- **预期结果**: 仅返回 `proj-x` 的文档
- **关联代码**: `src/board/knowledge-reader.ts:74-76`

### TC-C-014. [knowledge-reader] — 按 type 过滤（brainstorms/plans/solutions）
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 同一 project 下创建 `plans/doc.md` 和 `solutions/doc.md`
- **测试步骤**:
  1. 调用 `readKnowledgeDocuments({ type: "solutions" })`
- **预期结果**: 仅返回 `solutions` 类型的文档
- **关联代码**: `src/board/knowledge-reader.ts:81-83`

### TC-C-015. [knowledge-reader] — Project + Type 组合过滤
- **优先级**: P1
- **测试类型**: 功能
- **前置条件**: 多 project、多 type 组合存在文档
- **测试步骤**:
  1. 调用 `readKnowledgeDocuments({ project: "proj-a", type: "brainstorms" })`
- **预期结果**: 仅返回同时满足两个条件的文档
- **关联代码**: `src/board/knowledge-reader.ts:74-83`

### TC-C-016. [knowledge-reader] — 忽略隐藏文件（以 `.` 开头）
- **优先级**: P0
- **测试类型**: 边界
- **前置条件**: 在 `plans/` 下创建 `.hidden.md` 和 `visible.md`
- **测试步骤**:
  1. 调用读取函数
- **预期结果**: 仅返回 `visible.md`，`.hidden.md` 被忽略
- **关联代码**: `src/board/knowledge-reader.ts:137`

### TC-C-017. [knowledge-reader] — 忽略隐藏目录（以 `.` 开头）
- **优先级**: P0
- **测试类型**: 边界
- **前置条件**: 在 knowledge home 下创建 `.git/` 目录并在其内部放 md 文件
- **测试步骤**:
  1. 调用读取函数
- **预期结果**: `.git` 目录及其内部文件完全被忽略
- **关联代码**: `src/board/knowledge-reader.ts:121`

### TC-C-018. [knowledge-reader] — 空类型目录不报错
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**: 某 project 下 `plans/` 为空，`solutions/` 有文件
- **测试步骤**:
  1. 调用读取函数
- **预期结果**: 正常返回 `solutions` 下的文档，不抛出异常
- **关联代码**: `src/board/knowledge-reader.ts:86-88`

### TC-C-019. [knowledge-reader] — 损坏/不可读/无效 YAML 文件被静默跳过
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**: 创建文件权限为 000（不可读），或 frontmatter 为无效 YAML
- **测试步骤**:
  1. 在 `plans/` 下放一个不可读文件和一个正常文件
  2. 调用读取函数
- **预期结果**: 正常文件被返回，损坏文件被忽略，不中断扫描，不抛异常
- **关联代码**: `src/board/knowledge-reader.ts:156-204`

### TC-C-020. [knowledge-reader] — 非 `.md` 文件被忽略
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**: 在 type 目录下放 `.txt`、`.json`、无扩展名文件
- **测试步骤**:
  1. 调用读取函数
- **预期结果**: 仅 `.md` 文件被纳入
- **关联代码**: `src/board/knowledge-reader.ts:137`

### TC-C-021. [knowledge-reader] — 路径分隔符规范化（Windows 反斜杠转斜杠）
- **优先级**: P1
- **测试类型**: 功能
- **前置条件**: 在 Windows 或模拟环境下运行
- **测试步骤**:
  1. 调用读取函数
  2. 检查返回的 `path` 字段
- **预期结果**: `path` 中不含反斜杠 `\`，统一使用正斜杠 `/`
- **关联代码**: `src/board/knowledge-reader.ts:95`

### TC-C-022. [knowledge-reader] — Topic 字段可选（无 topic 时为 undefined）
- **优先级**: P1
- **测试类型**: 功能
- **前置条件**: frontmatter 不含 `topic` 字段
- **测试步骤**:
  1. 创建无 topic 的文档
  2. 调用读取函数
- **预期结果**: `topic` 为 `undefined`，不出现在输出中或显示为空白
- **关联代码**: `src/board/knowledge-reader.ts:189-191`

### TC-C-023. [knowledge-reader] — 空字符串 frontmatter title 回退到文件名
- **优先级**: P2
- **测试类型**: 边界
- **前置条件**: frontmatter 中 `title: ""`
- **测试步骤**:
  1. 创建文件并写入 `title: ""`
  2. 调用读取函数
- **预期结果**: `title` 使用文件名（不含日期前缀），而非空字符串
- **关联代码**: `src/board/knowledge-reader.ts:169-171`

---

## 二、`board-list` 命令集成

### TC-C-024. [board-list] — `--with-knowledge` 在任务列表后追加知识文档
- **优先级**: P0
- **测试类型**: 集成
- **前置条件**: 存在任务数据（DB 有记录）且 knowledge home 有文档
- **测试步骤**:
  1. 执行 `gale-harness board list --with-knowledge`
  2. 观察输出
- **预期结果**: 先输出任务表格（或 JSON/Quiet），随后输出 `📚 Knowledge Documents` 区块及分组文档列表
- **关联代码**: `src/commands/board-list.ts:148-161`

### TC-C-025. [board-list] — `--knowledge-only` 仅显示知识文档，不加载任务
- **优先级**: P0
- **测试类型**: 集成
- **前置条件**: knowledge home 有文档，任务 DB 也有记录
- **测试步骤**:
  1. 执行 `gale-harness board list --knowledge-only`
  2. 观察输出
- **预期结果**: 不输出任务表格，直接输出 `📚 Knowledge Documents` 区块；即使任务 DB 不存在也不报错
- **关联代码**: `src/commands/board-list.ts:89-103`

### TC-C-026. [board-list] — `--knowledge-only` 与 `--with-knowledge` 共存时优先 knowledge-only
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**: 同上
- **测试步骤**:
  1. 执行 `gale-harness board list --knowledge-only --with-knowledge`
- **预期结果**: 按 `--knowledge-only` 处理，仅显示知识文档，`--with-knowledge` 被忽略
- **关联代码**: `src/commands/board-list.ts:89-103`

### TC-C-027. [board-list] — `--knowledge-type` 过滤三种类型
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: knowledge home 下有 `brainstorms`、`plans`、`solutions` 文档
- **测试步骤**:
  1. 执行 `gale-harness board list --knowledge-only --knowledge-type plans`
  2. 分别测试 `brainstorms` 和 `solutions`
- **预期结果**: 仅输出对应类型的知识文档
- **关联代码**: `src/commands/board-list.ts:91-100`

### TC-C-028. [board-list] — `--knowledge-type` 传入无效值时报错退出
- **优先级**: P0
- **测试类型**: 边界
- **前置条件**: 任意状态
- **测试步骤**:
  1. 执行 `gale-harness board list --knowledge-only --knowledge-type invalid`
- **预期结果**: stderr 输出 `Invalid knowledge type: invalid. Valid types: brainstorms, plans, solutions`，进程以非 0 退出码结束
- **关联代码**: `src/commands/board-list.ts:92-95`

### TC-C-029. [board-list] — `--project` 同时过滤任务和知识文档
- **优先级**: P0
- **测试类型**: 集成
- **前置条件**: 多 project 的任务和知识文档同时存在
- **测试步骤**:
  1. 执行 `gale-harness board list --with-knowledge --project my-project`
- **预期结果**: 任务列表仅显示 `my-project` 的任务；知识文档区块仅显示 `my-project` 的知识文档；header 显示 `project: my-project`
- **关联代码**: `src/commands/board-list.ts:115-117,156-160,165-168`

### TC-C-030. [board-list] — `--project ""` 视为无过滤（空字符串处理）
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**: 多 project 数据存在
- **测试步骤**:
  1. 执行 `gale-harness board list --with-knowledge --project ""`
- **预期结果**: 显示所有任务和知识文档，不将空字符串当作 project 名过滤
- **关联代码**: `src/commands/board-list.ts:98,115,156`

### TC-C-031. [board-list] — 无知识文档时 `--with-knowledge` 显示空提示
- **优先级**: P0
- **测试类型**: 边界
- **前置条件**: 任务存在，但 knowledge home 为空或不存在
- **测试步骤**:
  1. 执行 `gale-harness board list --with-knowledge`
- **预期结果**: 任务列表正常输出，随后输出 `📚 Knowledge Documents\n\n  No documents found.`
- **关联代码**: `src/commands/board-list.ts:170-172`

### TC-C-032. [board-list] — 无知识文档时 `--knowledge-only` 显示空提示
- **优先级**: P0
- **测试类型**: 边界
- **前置条件**: knowledge home 为空
- **测试步骤**:
  1. 执行 `gale-harness board list --knowledge-only`
- **预期结果**: 仅输出 `📚 Knowledge Documents\n\n  No documents found.`
- **关联代码**: `src/commands/board-list.ts:170-172`

### TC-C-033. [board-list] — 知识文档按 type 分组显示
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 同一 project 下有多种 type 的知识文档
- **测试步骤**:
  1. 执行 `gale-harness board list --knowledge-only`
- **预期结果**: 输出按 `brainstorms/`、`plans/`、`solutions/` 分组，每组内文档按日期降序排列
- **关联代码**: `src/commands/board-list.ts:177-191`

### TC-C-034. [board-list] — 知识文档条目格式正确（含日期与不含日期）
- **优先级**: P1
- **测试类型**: 功能
- **前置条件**: 知识文档有日期和无日期混合
- **测试步骤**:
  1. 执行 `gale-harness board list --knowledge-only`
- **预期结果**: 有日期文档显示为 `YYYY-MM-DD title`；无日期文档显示为 `    title`（前面 4 空格，无日期前缀）
- **关联代码**: `src/commands/board-list.ts:187-188`

### TC-C-035. [board-list] — `--with-knowledge` + `--format=json` 时整体输出非合法 JSON
- **优先级**: P1
- **测试类型**: 集成
- **前置条件**: 有任务和知识文档
- **测试步骤**:
  1. 执行 `gale-harness board list --with-knowledge --format=json`
  2. 尝试将完整输出用 `JSON.parse()` 解析
- **预期结果**: 前半部分为合法 JSON 数组，后半部分为纯文本知识区块，整体无法被 `JSON.parse()` 解析（需记录此行为作为已知限制）
- **关联代码**: `src/commands/board-list.ts:133-161`

### TC-C-036. [board-list] — `--with-knowledge` + `limit=0` 时任务为空但知识正常追加
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**: 有任务和知识文档
- **测试步骤**:
  1. 执行 `gale-harness board list --with-knowledge --limit 0`
- **预期结果**: 任务部分显示 `No tasks found.`，随后仍追加知识文档区块
- **关联代码**: `src/commands/board-list.ts:39-41,148-161`

### TC-C-037. [board-list] — `limit`/`offset` 不影响知识文档数量
- **优先级**: P1
- **测试类型**: 功能
- **前置条件**: 有大量任务和大量知识文档
- **测试步骤**:
  1. 执行 `gale-harness board list --with-knowledge --limit 2 --offset 0`
  2. 对比 `gale-harness board list --knowledge-only` 的知识文档数量
- **预期结果**: 两次知识文档数量完全一致，`limit`/`offset` 仅作用于任务
- **关联代码**: `src/commands/board-list.ts:125-161`

### TC-C-038. [board-list] — 大量知识文档性能表现（≥1000 篇）
- **优先级**: P2
- **测试类型**: 性能
- **前置条件**: 生成 1000+ 知识文档分布在多个 project/type 下
- **测试步骤**:
  1. 执行 `gale-harness board list --knowledge-only`
  2. 计时
- **预期结果**: 在 2 秒内完成输出，内存占用无明显异常
- **关联代码**: `src/commands/board-list.ts:97-101`

### TC-C-039. [board-list] — `--knowledge-type` 在 `--with-knowledge` 模式下同样生效
- **优先级**: P0
- **测试类型**: 集成
- **前置条件**: knowledge home 有多种 type 文档
- **测试步骤**:
  1. 执行 `gale-harness board list --with-knowledge --knowledge-type solutions`
- **预期结果**: 任务列表正常输出，知识区块仅显示 `solutions` 类型文档
- **关联代码**: `src/commands/board-list.ts:150-161`

### TC-C-040. [board-list] — 知识文档 header 在无 project 参数时不带 project 后缀
- **优先级**: P1
- **测试类型**: 功能
- **前置条件**: 任意知识文档
- **测试步骤**:
  1. 执行 `gale-harness board list --knowledge-only`
- **预期结果**: header 为 `\n📚 Knowledge Documents`（无 `(project: xxx)`）
- **关联代码**: `src/commands/board-list.ts:165-168`

---

## 三、`board-show` 命令（确认变更内容）

### TC-C-041. [board-show] — 确认无知识文档集成，仅显示任务详情
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 任务 DB 中存在指定 task_id，且 knowledge home 也有文档
- **测试步骤**:
  1. 执行 `gale-harness board show <task-id>`
  2. 观察输出内容
- **预期结果**: 输出仅包含 Task、ID、Project、Skill、Status、Started、Completed、Parent Task、PR、Error、Memory Entries 等任务字段；**无任何知识文档相关区块或引用**
- **关联代码**: `src/commands/board-show.ts:1-37`

### TC-C-042. [board-show] — 知识文档存在时不影响任务查找和展示
- **优先级**: P1
- **测试类型**: 集成
- **前置条件**: knowledge home 有大量文档，任务 DB 正常
- **测试步骤**:
  1. 执行 `gale-harness board show <valid-task-id>`
- **预期结果**: 正常返回任务详情，不崩溃、不延迟、不混入知识文档数据
- **关联代码**: `src/commands/board-show.ts:26-35`

---

## 四、`board-stats` 命令（确认变更内容）

### TC-C-043. [board-stats] — 确认无知识文档统计，仅统计任务
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 任务 DB 有记录，knowledge home 有文档
- **测试步骤**:
  1. 执行 `gale-harness board stats`
  2. 观察输出
- **预期结果**: 输出仅包含 Total、Completed、In Progress、Failed、Stale、By Project、By Skill；**无任何 Knowledge Documents 统计行**
- **关联代码**: `src/commands/board-stats.ts:1-15`

### TC-C-044. [board-stats] — 知识文档存在时不影响统计输出
- **优先级**: P1
- **测试类型**: 集成
- **前置条件**: knowledge home 有大量文档
- **测试步骤**:
  1. 执行 `gale-harness board stats`
- **预期结果**: 统计数值与知识文档数量无关，行为与无知识文档时完全一致
- **关联代码**: `src/commands/board-stats.ts:10-14`

---

## 五、`board.ts` 子命令注册

### TC-C-045. [board] — 子命令注册完整性（list/show/stats/serve）
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: CLI 正常构建安装
- **测试步骤**:
  1. 执行 `gale-harness board --help`
  2. 分别执行 `gale-harness board list --help`、`gale-harness board show --help`、`gale-harness board stats --help`、`gale-harness board serve --help`
- **预期结果**: `--help` 中列出 `list`、`show`、`stats`、`serve` 四个子命令；各子命令帮助信息可正常展示
- **关联代码**: `src/commands/board.ts:12-17`

### TC-C-046. [board] — 默认行为（无子命令）调用 board-list
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 有任务数据
- **测试步骤**:
  1. 执行 `gale-harness board`（不带任何子命令）
- **预期结果**: 等价于执行 `gale-harness board list`，输出默认格式（table）和默认 limit（20）的任务列表
- **关联代码**: `src/commands/board.ts:18-21`

### TC-C-047. [board] — 默认行为正确传递 knowledge 参数
- **优先级**: P1
- **测试类型**: 集成
- **前置条件**: 有任务和知识文档
- **测试步骤**:
  1. 执行 `gale-harness board --with-knowledge`
  2. 执行 `gale-harness board --knowledge-only`
- **预期结果**: `--with-knowledge` 时输出任务+知识；`--knowledge-only` 时仅输出知识；参数透传正确
- **关联代码**: `src/commands/board.ts:18-21`

---

## 六、端到端（E2E）场景

### TC-C-048. [E2E] — 完整链路：创建知识文档 → list 查看 → 验证内容
- **优先级**: P0
- **测试类型**: 端到端
- **前置条件**: 本地 knowledge home 可写
- **测试步骤**:
  1. 在 `~/.galeharness/knowledge/e2e-test/plans/` 下创建 `2026-04-20-onboarding.md`，frontmatter 包含 `title: "Onboarding Plan"`、`topic: workflow`
  2. 执行 `gale-harness board list --with-knowledge --project e2e-test`
  3. 记录输出
  4. 清理测试文件
- **预期结果**: 
  - 任务列表按条件过滤展示
  - 知识区块 header 为 `📚 Knowledge Documents (project: e2e-test)`
  - 知识条目显示 `2026-04-20 Onboarding Plan`
  - 分组目录显示 `plans/`
- **关联代码**: `src/board/knowledge-reader.ts:57-112`、`src/commands/board-list.ts:148-194`

### TC-C-049. [E2E] — 多 project 与多 type 混合过滤验证
- **优先级**: P0
- **测试类型**: 端到端
- **前置条件**: 创建 `proj-a/brainstorms/2026-04-18-a.md`、`proj-a/plans/2026-04-19-b.md`、`proj-b/solutions/2026-04-20-c.md`
- **测试步骤**:
  1. 执行 `gale-harness board list --knowledge-only --project proj-a`
  2. 执行 `gale-harness board list --knowledge-only --knowledge-type solutions`
  3. 执行 `gale-harness board list --knowledge-only --project proj-a --knowledge-type brainstorms`
- **预期结果**:
  - 步骤 1：仅 `proj-a` 的 `brainstorms` 和 `plans` 出现
  - 步骤 2：仅 `proj-b` 的 `solutions` 出现（因为只有 proj-b 有 solutions）
  - 步骤 3：仅 `proj-a` 的 `brainstorms` 出现
- **关联代码**: `src/commands/board-list.ts:89-103`

### TC-C-050. [E2E] — 日期排序与 frontmatter 展示验证
- **优先级**: P0
- **测试类型**: 端到端
- **前置条件**: 同一 project/plans 下创建：
  - `2026-04-20-latest.md`（无 frontmatter）
  - `2026-04-15-mid.md`（frontmatter `date: 2026-04-18` — 验证 frontmatter date 优先）
  - `2026-04-10-legacy.md`（frontmatter `title: "Custom Title"`）
- **测试步骤**:
  1. 执行 `gale-harness board list --knowledge-only`
- **预期结果**: 输出顺序为：
  1. `2026-04-20 latest`（文件名日期）
  2. `2026-04-18 mid`（frontmatter date 覆盖文件名日期）
  3. `Custom Title`（frontmatter title 覆盖文件名，日期 `2026-04-10`）
- **关联代码**: `src/board/knowledge-reader.ts:156-201`、`src/commands/board-list.ts:105-109`

### TC-C-051. [E2E] — 任务与知识文档共存场景完整性
- **优先级**: P0
- **测试类型**: 端到端
- **前置条件**: 任务 DB 活跃（有 in_progress/completed 任务），knowledge home 有多个 project/type 文档
- **测试步骤**:
  1. 执行 `gale-harness board list --with-knowledge --limit 5`
  2. 观察任务表格行数
  3. 观察知识文档分组和数量
- **预期结果**: 任务最多 5 行（受 limit 限制），知识文档不受 limit 限制、全部展示；两者内容不互相污染
- **关联代码**: `src/commands/board-list.ts:125-161`

### TC-C-052. [E2E] — 空仓库到非空仓库的动态变化
- **优先级**: P1
- **测试类型**: 端到端
- **前置条件**: knowledge home 初始为空
- **测试步骤**:
  1. 执行 `gale-harness board list --with-knowledge`，确认显示 `No documents found.`
  2. 不重启进程，直接在 knowledge home 下新建 project/type/文档
  3. 再次执行同一命令
- **预期结果**: 第二次执行正确展示新增的知识文档（无缓存问题）
- **关联代码**: `src/board/knowledge-reader.ts:57-112`

### TC-C-053. [E2E] — 隐藏文件/目录在真实目录树中被正确排除
- **优先级**: P1
- **测试类型**: 端到端
- **前置条件**: 在 knowledge home 下初始化 git 仓库，并创建 `.hidden.md`、`visible.md`
- **测试步骤**:
  1. 执行 `gale-harness board list --knowledge-only`
- **预期结果**: `.git` 目录和 `.hidden.md` 均不出现在输出中
- **关联代码**: `src/board/knowledge-reader.ts:121,137`

### TC-C-054. [E2E] — board 默认命令与显式 list 命令行为一致性
- **优先级**: P1
- **测试类型**: 端到端
- **前置条件**: 有任务和知识文档
- **测试步骤**:
  1. 执行 `gale-harness board --with-knowledge`
  2. 执行 `gale-harness board list --with-knowledge`
- **预期结果**: 两次输出完全一致
- **关联代码**: `src/commands/board.ts:18-21`

---

## 七、回归与兼容性

### TC-C-055. [回归] — 原任务列表功能不受知识功能影响
- **优先级**: P0
- **测试类型**: 回归
- **前置条件**: 任务 DB 正常，不使用任何 knowledge 参数
- **测试步骤**:
  1. 执行 `gale-harness board list`
  2. 执行 `gale-harness board list --status completed --project xxx --skill yyy --limit 10 --offset 5 --format table`
- **预期结果**: 输出与 PR #31 之前完全一致，无多余空行或 header
- **关联代码**: `src/commands/board-list.ts:105-147`

### TC-C-056. [回归] — board-show 参数校验与错误提示不变
- **优先级**: P0
- **测试类型**: 回归
- **前置条件**: 无
- **测试步骤**:
  1. 执行 `gale-harness board show`（无 taskId）
  2. 执行 `gale-harness board show nonexistent-id`
- **预期结果**: 分别提示 `Task ID is required` 和 `Task "nonexistent-id" not found`，退出码非 0
- **关联代码**: `src/commands/board-show.ts:20-32`

### TC-C-057. [回归] — board-stats 空任务场景输出不变
- **优先级**: P1
- **测试类型**: 回归
- **前置条件**: 任务 DB 不存在或为空
- **测试步骤**:
  1. 执行 `gale-harness board stats`
- **预期结果**: 输出 `No tasks found.`
