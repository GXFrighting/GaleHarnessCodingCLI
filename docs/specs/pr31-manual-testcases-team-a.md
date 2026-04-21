# PR #31 人工测试用例 — `src/knowledge/` 核心库与路径解析组

> **测试范围**: `src/knowledge/types.ts`、`src/knowledge/home.ts`、`src/knowledge/writer.ts`
> **测试团队**: 人工测试团队 A（核心库与路径解析组）

---

## 一、类型与守卫验证（`types.ts`）

### TC-A-001. [types.ts] — VALID_DOC_TYPES 包含全部且仅包含三个有效类型
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 无
- **测试步骤**:
  1. 导入 `VALID_DOC_TYPES`
  2. 断言其长度等于 3
  3. 断言包含 `"brainstorms"`、`"plans"`、`"solutions"`
  4. 断言数组为 readonly（尝试 push 新元素应编译失败或运行时抛出）
- **预期结果**:
  - 长度严格为 3
  - 仅包含上述三个值，顺序固定为 `["brainstorms", "plans", "solutions"]`
  - 任何修改尝试均失败
- **关联代码**: `types.ts:9`

### TC-A-002. [types.ts] — isValidDocType 对三个有效类型返回 true
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `isValidDocType("brainstorms")`
  2. 调用 `isValidDocType("plans")`
  3. 调用 `isValidDocType("solutions")`
- **预期结果**:
  - 三次调用均返回 `true`
  - TypeScript 类型收窄生效：返回 true 后变量类型可推断为 `KnowledgeDocType`
- **关联代码**: `types.ts:12-14`

### TC-A-003. [types.ts] — isValidDocType 对无效类型返回 false
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `isValidDocType("invalid")`
  2. 调用 `isValidDocType("brainstorm")`（拼写近似）
  3. 调用 `isValidDocType("")`
  4. 调用 `isValidDocType(" brainstorm ")`（含首尾空格）
  5. 调用 `isValidDocType("BRAINSTORMS")`（全大写）
  6. 调用 `isValidDocType("brainstorms\x00")`（含空字符）
  7. 调用 `isValidDocType("solutions")` 后调用 `isValidDocType("plans\x01")`（含控制字符）
- **预期结果**:
  - 所有调用均返回 `false`
- **关联代码**: `types.ts:12-14`

### TC-A-004. [types.ts] — isValidDocType 对非字符串输入
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `isValidDocType(undefined as unknown as string)`
  2. 调用 `isValidDocType(null as unknown as string)`
  3. 调用 `isValidDocType(123 as unknown as string)`
- **预期结果**:
  - 运行时返回 `false`（`includes` 对非字符串元素返回 false）
- **关联代码**: `types.ts:12-14`

---

## 二、知识仓库 Home 路径解析（`home.ts`）

### TC-A-005. [home.ts] — 环境变量 GALE_KNOWLEDGE_HOME 最高优先级
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 设置 `process.env.GALE_KNOWLEDGE_HOME = "/custom/knowledge"`
  - 确保 `~/.galeharness/config.json` 和 `config.yaml` 均不存在
- **测试步骤**:
  1. 调用 `resolveKnowledgeHome()`
  2. 清除环境变量后再次调用
- **预期结果**:
  - 第一次返回 `resolve("/custom/knowledge")`（绝对路径）
  - 第二次不返回 `/custom/knowledge`（说明确实是环境变量生效，非缓存）
- **关联代码**: `home.ts:81-86`

### TC-A-006. [home.ts] — 配置文件 JSON 优先级高于 YAML
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 清空 `GALE_KNOWLEDGE_HOME` 环境变量
  - 创建 `~/.galeharness/config.json`，内容 `{"knowledge": {"home": "/json-home"}}`
  - 创建 `~/.galeharness/config.yaml`，内容 `knowledge:\n  home: /yaml-home`
- **测试步骤**:
  1. 调用 `resolveKnowledgeHome()`
- **预期结果**:
  - 返回 `/json-home`（JSON 优先）
- **关联代码**: `home.ts:37-65`

### TC-A-007. [home.ts] — 仅存在 YAML 配置文件时生效
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 清空环境变量
  - 删除 `~/.galeharness/config.json`
  - 保留 `~/.galeharness/config.yaml`，内容 `knowledge:\n  home: /yaml-home`
- **测试步骤**:
  1. 调用 `resolveKnowledgeHome()`
- **预期结果**:
  - 返回 `/yaml-home`
- **关联代码**: `home.ts:52-62`

### TC-A-008. [home.ts] — 配置文件缺失时回退到默认路径
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 清空环境变量
  - 删除 `~/.galeharness/config.json` 和 `config.yaml`
- **测试步骤**:
  1. 调用 `resolveKnowledgeHome()`
- **预期结果**:
  - 返回 `join(homedir(), ".galeharness", "knowledge")`
- **关联代码**: `home.ts:94-96`

### TC-A-009. [home.ts] — JSON 配置文件存在但解析失败时回退到 YAML
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**:
  - 清空环境变量
  - 创建 `~/.galeharness/config.json`，内容为非法 JSON（如 `{broken`）
  - 创建 `~/.galeharness/config.yaml`，内容 `knowledge:\n  home: /yaml-fallback`
- **测试步骤**:
  1. 调用 `resolveKnowledgeHome()`
- **预期结果**:
  - 返回 `/yaml-fallback`（JSON 解析异常被捕获后尝试 YAML）
- **关联代码**: `home.ts:39-49`

### TC-A-010. [home.ts] — JSON 文件存在但缺少 knowledge.home 字段
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**:
  - 清空环境变量
  - 创建 `~/.galeharness/config.json`，内容 `{}`
  - 删除 `config.yaml`
- **测试步骤**:
  1. 调用 `resolveKnowledgeHome()`
- **预期结果**:
  - 返回默认路径（JSON 解析成功但条件不匹配，进入默认分支）
- **关联代码**: `home.ts:42-45`

### TC-A-011. [home.ts] — JSON 中 knowledge.home 非字符串类型
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**:
  - 清空环境变量
  - 创建 `~/.galeharness/config.json`，内容 `{"knowledge": {"home": 123}}`
  - 删除 `config.yaml`
- **测试步骤**:
  1. 调用 `resolveKnowledgeHome()`
- **预期结果**:
  - 返回默认路径（typeof 检查为 number，条件不成立）
- **关联代码**: `home.ts:43`

### TC-A-012. [home.ts] — YAML 文件存在但解析失败时回退到默认路径
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**:
  - 清空环境变量
  - 删除 `config.json`
  - 创建 `~/.galeharness/config.yaml`，内容为非法 YAML（如 `{[`)
- **测试步骤**:
  1. 调用 `resolveKnowledgeHome()`
- **预期结果**:
  - 返回默认路径（YAML 解析异常被捕获后返回 null）
- **关联代码**: `home.ts:52-62`

### TC-A-013. [home.ts] — 环境变量值为相对路径时 resolve 为绝对路径
- **优先级**: P1
- **测试类型**: 功能
- **前置条件**:
  - 设置 `process.env.GALE_KNOWLEDGE_HOME = "./relative/path"`
- **测试步骤**:
  1. 调用 `resolveKnowledgeHome()`
- **预期结果**:
  - 返回当前工作目录下 `./relative/path` 的绝对路径（通过 `resolve(envHome)` 转换）
- **关联代码**: `home.ts:85`

### TC-A-014. [home.ts] — 环境变量值为空字符串时不生效
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**:
  - 设置 `process.env.GALE_KNOWLEDGE_HOME = ""`
  - 确保配置文件不存在
- **测试步骤**:
  1. 调用 `resolveKnowledgeHome()`
- **预期结果**:
  - 返回默认路径（空字符串为 falsy，进入下一优先级）
- **关联代码**: `home.ts:84`

### TC-A-015. [home.ts] — 环境变量值为 Windows 绝对路径
- **优先级**: P2
- **测试类型**: 兼容性
- **前置条件**:
  - 设置 `process.env.GALE_KNOWLEDGE_HOME = "C:\\Users\\test\\.gale"`
- **测试步骤**:
  1. 调用 `resolveKnowledgeHome()`
- **预期结果**:
  - 返回 `C:\Users\test\.gale`（Node.js `path.resolve` 正确处理）
- **关联代码**: `home.ts:85`

---

## 三、项目名称提取（`home.ts`）

### TC-A-016. [home.ts] — git@github.com:org/repo.git 格式解析
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 在临时目录初始化 git 仓库
  - 执行 `git remote add origin git@github.com:myorg/myrepo.git`
- **测试步骤**:
  1. 调用 `extractProjectName(tempDir)`
- **预期结果**:
  - 返回 `"myrepo"`
- **关联代码**: `home.ts:112-133`

### TC-A-017. [home.ts] — https://github.com/org/repo.git 格式解析
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 在临时目录初始化 git 仓库
  - 执行 `git remote add origin https://github.com/myorg/myrepo.git`
- **测试步骤**:
  1. 调用 `extractProjectName(tempDir)`
- **预期结果**:
  - 返回 `"myrepo"`
- **关联代码**: `home.ts:112-133`

### TC-A-018. [home.ts] — https://github.com/org/repo（无 .git 后缀）格式解析
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 在临时目录初始化 git 仓库
  - 执行 `git remote add origin https://github.com/myorg/myrepo`
- **测试步骤**:
  1. 调用 `extractProjectName(tempDir)`
- **预期结果**:
  - 返回 `"myrepo"`
- **关联代码**: `home.ts:112-133`

### TC-A-019. [home.ts] — ssh://git@github.com/org/repo.git 格式解析
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 在临时目录初始化 git 仓库
  - 执行 `git remote add origin ssh://git@github.com/myorg/myrepo.git`
- **测试步骤**:
  1. 调用 `extractProjectName(tempDir)`
- **预期结果**:
  - 返回 `"myrepo"`
- **关联代码**: `home.ts:112-133`

### TC-A-020. [home.ts] — git remote 命令失败时回退到目录名
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 在临时目录（目录名为 `fallback-project`）中，不初始化 git 仓库
- **测试步骤**:
  1. 调用 `extractProjectName(tempDir)`
- **预期结果**:
  - 返回 `"fallback-project"`（`basename(workDir)`）
- **关联代码**: `home.ts:128-132`

### TC-A-021. [home.ts] — git remote 返回空字符串时回退到目录名
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**:
  - 在临时目录初始化 git 仓库
  - 添加 origin remote 但指向空值（如 `git remote add origin ""` 后再手动编辑 `.git/config` 使 URL 为空）
- **测试步骤**:
  1. 调用 `extractProjectName(tempDir)`
- **预期结果**:
  - 返回目录名（`remoteUrl` 为空字符串时 `last` 为 undefined，进入 fallback）
- **关联代码**: `home.ts:122-127`

### TC-A-022. [home.ts] — 未提供 cwd 时默认使用 process.cwd()
- **优先级**: P1
- **测试类型**: 功能
- **前置条件**:
  - 当前工作目录下存在 git 仓库且 remote 为 `git@github.com:org/cwd-repo.git`
- **测试步骤**:
  1. 调用 `extractProjectName()`（不传入参数）
- **预期结果**:
  - 返回 `"cwd-repo"`
- **关联代码**: `home.ts:113`

### TC-A-023. [home.ts] — 深层嵌套 URL 解析
- **优先级**: P1
- **测试类型**: 功能
- **前置条件**:
  - 设置 remote URL 为 `https://gitlab.example.com/group/subgroup/project.git`
- **测试步骤**:
  1. 调用 `extractProjectName(tempDir)`
- **预期结果**:
  - 返回 `"project"`（split 后取最后一个）
- **关联代码**: `home.ts:124-126`

---

## 四、路径组件净化（`home.ts`）

### TC-A-024. [home.ts] — sanitizePathComponent 拒绝 `/` 字符
- **优先级**: P0
- **测试类型**: 安全
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `sanitizePathComponent("foo/bar")`
- **预期结果**:
  - 抛出 `Error`，message 包含 `"Invalid path component: foo/bar"`
- **关联代码**: `home.ts:147-151`

### TC-A-025. [home.ts] — sanitizePathComponent 拒绝 `\` 字符
- **优先级**: P0
- **测试类型**: 安全
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `sanitizePathComponent("foo\\bar")`
- **预期结果**:
  - 抛出 `Error`，message 包含 `"Invalid path component: foo\\bar"`
- **关联代码**: `home.ts:147-151`

### TC-A-026. [home.ts] — sanitizePathComponent 拒绝 `..` 序列
- **优先级**: P0
- **测试类型**: 安全
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `sanitizePathComponent("..")`
  2. 调用 `sanitizePathComponent("foo..bar")`
  3. 调用 `sanitizePathComponent("foo/../bar")`
  4. 调用 `sanitizePathComponent("...")`（三个点）
- **预期结果**:
  - 第 1、2、3 次调用抛出 `Error`
  - 第 4 次调用抛出 `Error`（正则 `..` 匹配三个点中的前两个）
- **关联代码**: `home.ts:147-151`

### TC-A-027. [home.ts] — sanitizePathComponent 允许单点 `.`
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `sanitizePathComponent(".")`
  2. 调用 `sanitizePathComponent("foo.bar")`
- **预期结果**:
  - 均正常返回原字符串，不抛异常
- **关联代码**: `home.ts:147-151`

### TC-A-028. [home.ts] — sanitizePathComponent 允许合法项目名
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `sanitizePathComponent("my-project")`
  2. 调用 `sanitizePathComponent("my_project")`
  3. 调用 `sanitizePathComponent("project123")`
  4. 调用 `sanitizePathComponent("@scope/package")`（含 @）
- **预期结果**:
  - 均正常返回原字符串
- **关联代码**: `home.ts:147-151`

### TC-A-029. [home.ts] — sanitizePathComponent 对空字符串
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `sanitizePathComponent("")`
- **预期结果**:
  - 正常返回 `""`（空字符串不匹配正则，但后续 join 会产生 `home/` 或 `home//`）
- **关联代码**: `home.ts:147-151`

---

## 五、知识路径组装（`home.ts`）

### TC-A-030. [home.ts] — resolveKnowledgePath 正确组装三层路径
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 设置 `GALE_KNOWLEDGE_HOME = "/tmp/test-knowledge"`
- **测试步骤**:
  1. 调用 `resolveKnowledgePath({ type: "solutions", projectName: "myapp" })`
- **预期结果**:
  - 返回对象包含：
    - `home: "/tmp/test-knowledge"`
    - `projectDir: "/tmp/test-knowledge/myapp"`
    - `docDir: "/tmp/test-knowledge/myapp/solutions"`
    - `projectName: "myapp"`
- **关联代码**: `home.ts:154-166`

### TC-A-031. [home.ts] — resolveKnowledgePath 未提供 projectName 时自动提取
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 当前目录 git remote 为 `git@github.com:org/auto-extracted.git`
- **测试步骤**:
  1. 调用 `resolveKnowledgePath({ type: "plans" })`
- **预期结果**:
  - `projectName` 为 `"auto-extracted"`
  - `docDir` 以 `.../auto-extracted/plans` 结尾
- **关联代码**: `home.ts:156`

### TC-A-032. [home.ts] — resolveKnowledgePath 对非法 projectName 抛出异常
- **优先级**: P0
- **测试类型**: 安全
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `resolveKnowledgePath({ type: "brainstorms", projectName: "../etc" })`
- **预期结果**:
  - 抛出 `Error`，message 为 `"Invalid path component: ../etc"`
- **关联代码**: `home.ts:156`

---

## 六、路径穿越防护（`home.ts` + `writer.ts`）

### TC-A-033. [writer.ts] — filename 包含 `../` 触发路径穿越拦截
- **优先级**: P0
- **测试类型**: 安全
- **前置条件**:
  - 设置 `GALE_KNOWLEDGE_HOME` 指向可写临时目录
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "solutions", filename: "../../../etc/passwd", content: "x" })`
- **预期结果**:
  - 抛出 `Error`，message 为 `"Invalid filename: path traversal detected"`
- **关联代码**: `writer.ts:61-65`

### TC-A-034. [writer.ts] — filename 为绝对路径尝试穿越
- **优先级**: P0
- **测试类型**: 安全
- **前置条件**:
  - 设置 `GALE_KNOWLEDGE_HOME` 指向可写临时目录
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "solutions", filename: "/etc/passwd", content: "x" })`
- **预期结果**:
  - 抛出 `Error`，message 为 `"Invalid filename: path traversal detected"`
- **关联代码**: `writer.ts:61-65`

### TC-A-035. [writer.ts] — 正常子目录 filename 不触发拦截
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 设置 `GALE_KNOWLEDGE_HOME` 指向可写临时目录
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "solutions", filename: "sub/deep/doc.md", content: "# Test" })`
- **预期结果**:
  - 正常写入，返回 `{ usedFallback: false }`
  - 文件实际存在于 `.../solutions/sub/deep/doc.md`
- **关联代码**: `writer.ts:61-65`

### TC-A-036. [writer.ts] — filename 为 `..` 单文件名触发拦截
- **优先级**: P0
- **测试类型**: 安全
- **前置条件**:
  - 设置 `GALE_KNOWLEDGE_HOME` 指向可写临时目录
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "plans", filename: "..", content: "x" })`
- **预期结果**:
  - 抛出 `Error`，message 为 `"Invalid filename: path traversal detected"`
- **关联代码**: `writer.ts:61-65`

### TC-A-037. [writer.ts] — filename 为空字符串时的路径穿越边界
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**:
  - 设置 `GALE_KNOWLEDGE_HOME` 指向可写临时目录
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "plans", filename: "", content: "x" })`
- **预期结果**:
  - `finalPath === safeBase`（空字符串 resolve 后等于 docDir 本身）
  - 条件 `finalPath !== safeBase` 为 false，不抛 traversal 错误
  - 但 `writeFileSync(primaryPath, ...)` 会失败（无法写入目录），触发 fallback
- **关联代码**: `writer.ts:58-69`

### TC-A-038. [home.ts] — resolveKnowledgePath 的 sanitizePathComponent 拦截 projectName 中的 traversal
- **优先级**: P0
- **测试类型**: 安全
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `resolveKnowledgePath({ type: "solutions", projectName: "foo/../bar" })`
  2. 调用 `resolveKnowledgePath({ type: "solutions", projectName: "foo\\bar" })`
  3. 调用 `resolveKnowledgePath({ type: "solutions", projectName: "foo/bar" })`
- **预期结果**:
  - 均抛出 `Error: Invalid path component: ...`
- **关联代码**: `home.ts:147-151,156`

---

## 七、知识文档写入（`writer.ts`）

### TC-A-039. [writer.ts] — 成功写入主路径（知识仓库）
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 设置 `GALE_KNOWLEDGE_HOME` 指向可写临时目录
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "brainstorms", filename: "idea.md", content: "# Idea\n\nDetails" })`
  2. 读取返回的 `path` 指向的文件内容
- **预期结果**:
  - 返回 `{ usedFallback: false, path: "..." }`
  - 文件存在且内容包含注入的 frontmatter
- **关联代码**: `writer.ts:48-70`

### TC-A-040. [writer.ts] — 主路径不可写时降级到 docs/ fallback
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 设置 `GALE_KNOWLEDGE_HOME` 指向只读/不存在的父目录（如 `/root/...` 或无权限目录）
  - 当前工作目录可写
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "solutions", filename: "doc.md", content: "# Fallback", cwd: tempCwd })`
  2. 检查返回结果和文件位置
- **预期结果**:
  - 返回 `{ usedFallback: true, path: "<tempCwd>/docs/solutions/doc.md", warning: "Knowledge repo write failed (...), falling back to ..." }`
  - 文件存在于 fallback 路径
  - console.warn 被调用并输出 warning
- **关联代码**: `writer.ts:71-84`

### TC-A-041. [writer.ts] — 主路径和 fallback 均失败时抛出聚合错误
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 设置 `GALE_KNOWLEDGE_HOME` 指向不可写目录
  - 当前工作目录下的 `docs/` 也设置为不可写
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "plans", filename: "plan.md", content: "# Plan" })`
- **预期结果**:
  - 抛出 `Error`，message 以 `"Failed to write knowledge document to both primary and fallback paths:"` 开头
- **关联代码**: `writer.ts:85-88`

### TC-A-042. [writer.ts] — 写入时自动创建多级目录
- **优先级**: P1
- **测试类型**: 功能
- **前置条件**:
  - 设置 `GALE_KNOWLEDGE_HOME` 指向全新的空临时目录
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "solutions", filename: "a/b/c/nested.md", content: "deep" })`
- **预期结果**:
  - 成功写入
  - 目录 `home/<project>/solutions/a/b/c/` 被自动创建
- **关联代码**: `writer.ts:68,81`

---

## 八、Frontmatter 注入（`writer.ts`）

### TC-A-043. [writer.ts] — 无 frontmatter 的内容自动注入 project
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `injectProjectFrontmatter("# Hello\n\nWorld", "myproject")`
- **预期结果**:
  - 返回字符串以 `---\nproject: myproject\n---\n\n# Hello\n\nWorld` 开头
  - 原文内容完整保留
- **关联代码**: `writer.ts:103-116`

### TC-A-044. [writer.ts] — 已有 frontmatter 但无 project 字段时注入
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `injectProjectFrontmatter("---\ntitle: Plan\n---\n\nBody", "myproject")`
- **预期结果**:
  - 返回包含 `project: myproject`
  - 原有 `title: Plan` 保留
  - body 部分保留为 `\n\nBody`（含前导换行）
- **关联代码**: `writer.ts:108-115`

### TC-A-045. [writer.ts] — 已有 frontmatter 且已有 project 字段时不覆盖
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `injectProjectFrontmatter("---\nproject: existing\n---\n\nBody", "myproject")`
- **预期结果**:
  - 返回包含 `project: existing`（原值保留）
  - 不注入 `myproject`
- **关联代码**: `writer.ts:111-113`

### TC-A-046. [writer.ts] — 空内容处理
- **优先级**: P0
- **测试类型**: 边界
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `injectProjectFrontmatter("", "myproject")`
  2. 调用 `injectProjectFrontmatter("", "myproject")` 后检查结果
- **预期结果**:
  - 返回 `"---\nproject: myproject\n---\n\n"`（空 body，formatFrontmatter 会添加 `---` 和尾部换行）
- **关联代码**: `writer.ts:104-106`

### TC-A-047. [writer.ts] — 只有 frontmatter 开始标记无结束标记
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `injectProjectFrontmatter("---\ntitle: Only Start\nNo end marker here", "myproject")`
- **预期结果**:
  - `parseFrontmatter` 返回 `{ data: {}, body: raw }`（无结束标记视为无 frontmatter）
  - 最终输出为以 `---\nproject: myproject\n---\n\n` 开头，后接原字符串
- **关联代码**: `writer.ts:108,frontmatter.ts:14-24`

### TC-A-048. [writer.ts] — frontmatter 后紧跟内容无空行
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `injectProjectFrontmatter("---\ntitle: X\n---\nImmediate", "myproject")`
- **预期结果**:
  - 输出包含 `---\nproject: myproject\ntitle: X\n---\n\nImmediate`
  - `formatFrontmatter` 会在 `---` 和 body 间插入空行
- **关联代码**: `writer.ts:115,frontmatter.ts:49`

### TC-A-049. [writer.ts] — frontmatter 中 project 为 undefined 时注入
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**: 无
- **测试步骤**:
  1. 构造一个 frontmatter 中 project 键存在但值为 undefined 的情况（通过 parseFrontmatter 理论分析）
  2. 实际上直接测试 `injectProjectFrontmatter("---\nproject: \n---\n\nBody", "myproject")`
- **预期结果**:
  - `js-yaml` 解析 `project: ` 为 `null`
  - `!data.project` 为 true（null 为 falsy）
  - 注入 `project: myproject`
- **关联代码**: `writer.ts:111-113`

### TC-A-050. [writer.ts] — frontmatter 中 project 为空字符串时不覆盖
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `injectProjectFrontmatter("---\nproject: \"\"\n---\n\nBody", "myproject")`
- **预期结果**:
  - 空字符串为 falsy，`!data.project` 为 true
  - 注入 `project: myproject`（覆盖空字符串）
- **关联代码**: `writer.ts:111-113`

---

## 九、端到端集成场景

### TC-A-051. [集成] — 完整写入流程验证 frontmatter 注入 + 路径解析
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 设置 `GALE_KNOWLEDGE_HOME` 为可写临时目录
  - 当前目录 git remote 为 `git@github.com:org/endtoend.git`
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "solutions", filename: "test.md", content: "# Problem\n\nSolution here" })`
  2. 读取写入文件的内容
- **预期结果**:
  - 文件路径为 `<home>/endtoend/solutions/test.md`
  - 文件内容以 `---\nproject: endtoend\n---\n\n# Problem\n\nSolution here` 开头
  - `usedFallback` 为 `false`
- **关联代码**: `writer.ts:48-70,home.ts:154-166`

### TC-A-052. [集成] — 显式 projectName 覆盖 git 提取
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 设置 `GALE_KNOWLEDGE_HOME` 为可写临时目录
  - 当前目录 git remote 为 `git@github.com:org/gitname.git`
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "plans", filename: "p.md", content: "c", projectName: "override-name" })`
  2. 检查返回的 path
- **预期结果**:
  - 路径包含 `override-name/plans/p.md`，不包含 `gitname`
  - frontmatter 中 project 为 `override-name`
- **关联代码**: `writer.ts:51,58`

### TC-A-053. [集成] — cwd 参数影响 fallback 路径和项目名提取
- **优先级**: P1
- **测试类型**: 功能
- **前置条件**:
  - 创建临时目录 A（无 git，目录名 `dir-a`）
  - 创建临时目录 B（有 git remote `git@github.com:org/dir-b.git`）
  - 设置 `GALE_KNOWLEDGE_HOME` 为不可写目录以触发 fallback
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "brainstorms", filename: "b.md", content: "c", cwd: dirA })`
  2. 调用 `writeKnowledgeDocument({ type: "brainstorms", filename: "b.md", content: "c", cwd: dirB })`
- **预期结果**:
  - 第一次 fallback 到 `<dirA>/docs/brainstorms/b.md`，projectName 为 `dir-a`
  - 第二次 fallback 到 `<dirB>/docs/brainstorms/b.md`，projectName 为 `dir-b`
- **关联代码**: `writer.ts:50-51,76-77`

### TC-A-054. [集成] — fallback 写入也经过 frontmatter 注入
- **优先级**: P1
- **测试类型**: 功能
- **前置条件**:
  - 设置 `GALE_KNOWLEDGE_HOME` 为不可写目录
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "solutions", filename: "f.md", content: "raw", cwd: tempCwd })`
  2. 读取 fallback 文件内容
- **预期结果**:
  - 文件内容包含 frontmatter（`project: <projectName>`）
  - 不因为 fallback 而跳过 frontmatter 注入
- **关联代码**: `writer.ts:54,82`

---

## 十、兼容性与其他边界

### TC-A-055. [兼容性] — Windows 路径分隔符在 filename 中触发路径穿越
- **优先级**: P1
- **测试类型**: 兼容性/安全
- **前置条件**:
  - 在 macOS/Linux 环境下测试
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "solutions", filename: "sub\\..\\..\\etc\\passwd", content: "x" })`
- **预期结果**:
  - `resolve(primaryPath)` 将 `\\` 视为普通文件名字符（在 POSIX 上）
  - 路径穿越检查可能通过（因为 resolve 不转换 `\\` 为分隔符）
  - **风险点**: 在 Windows 上 `\\` 会被 resolve 解析为路径分隔符，可能导致穿越
  - 建议在 writer 的 sanitizePathComponent 中也对 filename 做检查
- **关联代码**: `writer.ts:58-65`

### TC-A-056. [边界] — content 为超大字符串（1MB Markdown）
- **优先级**: P2
- **测试类型**: 性能/边界
- **前置条件**:
  - 生成 1MB 的 Markdown 内容
- **测试步骤**:
  1. 调用 `injectProjectFrontmatter(bigContent, "project")`
  2. 调用 `writeKnowledgeDocument({ type: "solutions", filename: "big.md", content: bigContent })`
- **预期结果**:
  - 均正常完成，无内存溢出或明显延迟
  - 写入文件大小接近 1MB + frontmatter 头部长度
- **关联代码**: `writer.ts:48-89`

### TC-A-057. [边界] — filename 包含 Unicode 和特殊字符
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**:
  - 设置 `GALE_KNOWLEDGE_HOME` 为可写临时目录
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "plans", filename: "文档-📋.md", content: "测试" })`
  2. 调用 `writeKnowledgeDocument({ type: "plans", filename: "file with spaces.md", content: "test" })`
- **预期结果**:
  - 均正常写入（sanitizePathComponent 和路径穿越检查均不拦截合法 Unicode 和空格）
- **关联代码**: `home.ts:147-151,writer.ts:58-65`

### TC-A-058. [边界] — 并发写入同一目录不同文件
- **优先级**: P2
- **测试类型**: 边界
- **前置条件**:
  - 设置 `GALE_KNOWLEDGE_HOME` 为可写临时目录
- **测试步骤**:
  1. 同时发起 10 次 `writeKnowledgeDocument` 调用，文件名不同，类型和项目名相同
- **预期结果**:
  - 全部成功（`mkdirSync(..., { recursive: true })` 是幂等的）
  - 无竞态条件导致异常
- **关联代码**: `writer.ts:68`

---

> **测试执行建议**:
> 1. 所有 P0 用例必须在合并前全部通过。
> 2. 路径穿越相关用例（TC-A-024~TC-A-038）建议在 POSIX 和 Windows（如可行）双平台执行。
> 3. `home.ts` 中涉及 `~/.galeharness/` 的用例需在隔离临时 home 目录中执行，避免污染用户真实配置。
```[stage] run_soul_finished

[summary]
```markdown
# PR #31 人工测试用例 — `src/knowledge/` 核心库与路径解析组

> **测试范围**: `src/knowledge/types.ts`、`src/knowledge/home.ts`、`src/knowledge/writer.ts`
> **测试团队**: 人工测试团队 A（核心库与路径解析组）

---

## 一、类型与守卫验证（`types.ts`）

### TC-A-001. [types.ts] — VALID_DOC_TYPES 包含全部且仅包含三个有效类型
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 无
- **测试步骤**:
  1. 导入 `VALID_DOC_TYPES`
  2. 断言其长度等于 3
  3. 断言包含 `"brainstorms"`、`"plans"`、`"solutions"`
  4. 断言数组为 readonly（尝试 push 新元素应编译失败或运行时抛出）
- **预期结果**:
  - 长度严格为 3
  - 仅包含上述三个值，顺序固定为 `["brainstorms", "plans", "solutions"]`
  - 任何修改尝试均失败
- **关联代码**: `types.ts:9`

### TC-A-002. [types.ts] — isValidDocType 对三个有效类型返回 true
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `isValidDocType("brainstorms")`
  2. 调用 `isValidDocType("plans")`
  3. 调用 `isValidDocType("solutions")`
- **预期结果**:
  - 三次调用均返回 `true`
  - TypeScript 类型收窄生效：返回 true 后变量类型可推断为 `KnowledgeDocType`
- **关联代码**: `types.ts:12-14`

### TC-A-003. [types.ts] — isValidDocType 对无效类型返回 false
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `isValidDocType("invalid")`
  2. 调用 `isValidDocType("brainstorm")`（拼写近似）
  3. 调用 `isValidDocType("")`
  4. 调用 `isValidDocType(" brainstorm ")`（含首尾空格）
  5. 调用 `isValidDocType("BRAINSTORMS")`（全大写）
  6. 调用 `isValidDocType("brainstorms\x00")`（含空字符）
  7. 调用 `isValidDocType("solutions")` 后调用 `isValidDocType("plans\x01")`（含控制字符）
- **预期结果**:
  - 所有调用均返回 `false`
- **关联代码**: `types.ts:12-14`

### TC-A-004. [types.ts] — isValidDocType 对非字符串输入
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `isValidDocType(undefined as unknown as string)`
  2. 调用 `isValidDocType(null as unknown as string)`
  3. 调用 `isValidDocType(123 as unknown as string)`
- **预期结果**:
  - 运行时返回 `false`（`includes` 对非字符串元素返回 false）
- **关联代码**: `types.ts:12-14`

---

## 二、知识仓库 Home 路径解析（`home.ts`）

### TC-A-005. [home.ts] — 环境变量 GALE_KNOWLEDGE_HOME 最高优先级
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 设置 `process.env.GALE_KNOWLEDGE_HOME = "/custom/knowledge"`
  - 确保 `~/.galeharness/config.json` 和 `config.yaml` 均不存在
- **测试步骤**:
  1. 调用 `resolveKnowledgeHome()`
  2. 清除环境变量后再次调用
- **预期结果**:
  - 第一次返回 `resolve("/custom/knowledge")`（绝对路径）
  - 第二次不返回 `/custom/knowledge`（说明确实是环境变量生效，非缓存）
- **关联代码**: `home.ts:81-86`

### TC-A-006. [home.ts] — 配置文件 JSON 优先级高于 YAML
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 清空 `GALE_KNOWLEDGE_HOME` 环境变量
  - 创建 `~/.galeharness/config.json`，内容 `{"knowledge": {"home": "/json-home"}}`
  - 创建 `~/.galeharness/config.yaml`，内容 `knowledge:\n  home: /yaml-home`
- **测试步骤**:
  1. 调用 `resolveKnowledgeHome()`
- **预期结果**:
  - 返回 `/json-home`（JSON 优先）
- **关联代码**: `home.ts:37-65`

### TC-A-007. [home.ts] — 仅存在 YAML 配置文件时生效
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 清空环境变量
  - 删除 `~/.galeharness/config.json`
  - 保留 `~/.galeharness/config.yaml`，内容 `knowledge:\n  home: /yaml-home`
- **测试步骤**:
  1. 调用 `resolveKnowledgeHome()`
- **预期结果**:
  - 返回 `/yaml-home`
- **关联代码**: `home.ts:52-62`

### TC-A-008. [home.ts] — 配置文件缺失时回退到默认路径
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 清空环境变量
  - 删除 `~/.galeharness/config.json` 和 `config.yaml`
- **测试步骤**:
  1. 调用 `resolveKnowledgeHome()`
- **预期结果**:
  - 返回 `join(homedir(), ".galeharness", "knowledge")`
- **关联代码**: `home.ts:94-96`

### TC-A-009. [home.ts] — JSON 配置文件存在但解析失败时回退到 YAML
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**:
  - 清空环境变量
  - 创建 `~/.galeharness/config.json`，内容为非法 JSON（如 `{broken`）
  - 创建 `~/.galeharness/config.yaml`，内容 `knowledge:\n  home: /yaml-fallback`
- **测试步骤**:
  1. 调用 `resolveKnowledgeHome()`
- **预期结果**:
  - 返回 `/yaml-fallback`（JSON 解析异常被捕获后尝试 YAML）
- **关联代码**: `home.ts:39-49`

### TC-A-010. [home.ts] — JSON 文件存在但缺少 knowledge.home 字段
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**:
  - 清空环境变量
  - 创建 `~/.galeharness/config.json`，内容 `{}`
  - 删除 `config.yaml`
- **测试步骤**:
  1. 调用 `resolveKnowledgeHome()`
- **预期结果**:
  - 返回默认路径（JSON 解析成功但条件不匹配，进入默认分支）
- **关联代码**: `home.ts:42-45`

### TC-A-011. [home.ts] — JSON 中 knowledge.home 非字符串类型
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**:
  - 清空环境变量
  - 创建 `~/.galeharness/config.json`，内容 `{"knowledge": {"home": 123}}`
  - 删除 `config.yaml`
- **测试步骤**:
  1. 调用 `resolveKnowledgeHome()`
- **预期结果**:
  - 返回默认路径（typeof 检查为 number，条件不成立）
- **关联代码**: `home.ts:43`

### TC-A-012. [home.ts] — YAML 文件存在但解析失败时回退到默认路径
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**:
  - 清空环境变量
  - 删除 `config.json`
  - 创建 `~/.galeharness/config.yaml`，内容为非法 YAML（如 `{[`)
- **测试步骤**:
  1. 调用 `resolveKnowledgeHome()`
- **预期结果**:
  - 返回默认路径（YAML 解析异常被捕获后返回 null）
- **关联代码**: `home.ts:52-62`

### TC-A-013. [home.ts] — 环境变量值为相对路径时 resolve 为绝对路径
- **优先级**: P1
- **测试类型**: 功能
- **前置条件**:
  - 设置 `process.env.GALE_KNOWLEDGE_HOME = "./relative/path"`
- **测试步骤**:
  1. 调用 `resolveKnowledgeHome()`
- **预期结果**:
  - 返回当前工作目录下 `./relative/path` 的绝对路径（通过 `resolve(envHome)` 转换）
- **关联代码**: `home.ts:85`

### TC-A-014. [home.ts] — 环境变量值为空字符串时不生效
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**:
  - 设置 `process.env.GALE_KNOWLEDGE_HOME = ""`
  - 确保配置文件不存在
- **测试步骤**:
  1. 调用 `resolveKnowledgeHome()`
- **预期结果**:
  - 返回默认路径（空字符串为 falsy，进入下一优先级）
- **关联代码**: `home.ts:84`

### TC-A-015. [home.ts] — 环境变量值为 Windows 绝对路径
- **优先级**: P2
- **测试类型**: 兼容性
- **前置条件**:
  - 设置 `process.env.GALE_KNOWLEDGE_HOME = "C:\\Users\\test\\.gale"`
- **测试步骤**:
  1. 调用 `resolveKnowledgeHome()`
- **预期结果**:
  - 返回 `C:\Users\test\.gale`（Node.js `path.resolve` 正确处理）
- **关联代码**: `home.ts:85`

---

## 三、项目名称提取（`home.ts`）

### TC-A-016. [home.ts] — git@github.com:org/repo.git 格式解析
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 在临时目录初始化 git 仓库
  - 执行 `git remote add origin git@github.com:myorg/myrepo.git`
- **测试步骤**:
  1. 调用 `extractProjectName(tempDir)`
- **预期结果**:
  - 返回 `"myrepo"`
- **关联代码**: `home.ts:112-133`

### TC-A-017. [home.ts] — https://github.com/org/repo.git 格式解析
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 在临时目录初始化 git 仓库
  - 执行 `git remote add origin https://github.com/myorg/myrepo.git`
- **测试步骤**:
  1. 调用 `extractProjectName(tempDir)`
- **预期结果**:
  - 返回 `"myrepo"`
- **关联代码**: `home.ts:112-133`

### TC-A-018. [home.ts] — https://github.com/org/repo（无 .git 后缀）格式解析
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 在临时目录初始化 git 仓库
  - 执行 `git remote add origin https://github.com/myorg/myrepo`
- **测试步骤**:
  1. 调用 `extractProjectName(tempDir)`
- **预期结果**:
  - 返回 `"myrepo"`
- **关联代码**: `home.ts:112-133`

### TC-A-019. [home.ts] — ssh://git@github.com/org/repo.git 格式解析
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 在临时目录初始化 git 仓库
  - 执行 `git remote add origin ssh://git@github.com/myorg/myrepo.git`
- **测试步骤**:
  1. 调用 `extractProjectName(tempDir)`
- **预期结果**:
  - 返回 `"myrepo"`
- **关联代码**: `home.ts:112-133`

### TC-A-020. [home.ts] — git remote 命令失败时回退到目录名
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 在临时目录（目录名为 `fallback-project`）中，不初始化 git 仓库
- **测试步骤**:
  1. 调用 `extractProjectName(tempDir)`
- **预期结果**:
  - 返回 `"fallback-project"`（`basename(workDir)`）
- **关联代码**: `home.ts:128-132`

### TC-A-021. [home.ts] — git remote 返回空字符串时回退到目录名
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**:
  - 在临时目录初始化 git 仓库
  - 添加 origin remote 但指向空值（如 `git remote add origin ""` 后再手动编辑 `.git/config` 使 URL 为空）
- **测试步骤**:
  1. 调用 `extractProjectName(tempDir)`
- **预期结果**:
  - 返回目录名（`remoteUrl` 为空字符串时 `last` 为 undefined，进入 fallback）
- **关联代码**: `home.ts:122-127`

### TC-A-022. [home.ts] — 未提供 cwd 时默认使用 process.cwd()
- **优先级**: P1
- **测试类型**: 功能
- **前置条件**:
  - 当前工作目录下存在 git 仓库且 remote 为 `git@github.com:org/cwd-repo.git`
- **测试步骤**:
  1. 调用 `extractProjectName()`（不传入参数）
- **预期结果**:
  - 返回 `"cwd-repo"`
- **关联代码**: `home.ts:113`

### TC-A-023. [home.ts] — 深层嵌套 URL 解析
- **优先级**: P1
- **测试类型**: 功能
- **前置条件**:
  - 设置 remote URL 为 `https://gitlab.example.com/group/subgroup/project.git`
- **测试步骤**:
  1. 调用 `extractProjectName(tempDir)`
- **预期结果**:
  - 返回 `"project"`（split 后取最后一个）
- **关联代码**: `home.ts:124-126`

---

## 四、路径组件净化（`home.ts`）

### TC-A-024. [home.ts] — sanitizePathComponent 拒绝 `/` 字符
- **优先级**: P0
- **测试类型**: 安全
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `sanitizePathComponent("foo/bar")`
- **预期结果**:
  - 抛出 `Error`，message 包含 `"Invalid path component: foo/bar"`
- **关联代码**: `home.ts:147-151`

### TC-A-025. [home.ts] — sanitizePathComponent 拒绝 `\` 字符
- **优先级**: P0
- **测试类型**: 安全
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `sanitizePathComponent("foo\\bar")`
- **预期结果**:
  - 抛出 `Error`，message 包含 `"Invalid path component: foo\\bar"`
- **关联代码**: `home.ts:147-151`

### TC-A-026. [home.ts] — sanitizePathComponent 拒绝 `..` 序列
- **优先级**: P0
- **测试类型**: 安全
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `sanitizePathComponent("..")`
  2. 调用 `sanitizePathComponent("foo..bar")`
  3. 调用 `sanitizePathComponent("foo/../bar")`
  4. 调用 `sanitizePathComponent("...")`（三个点）
- **预期结果**:
  - 第 1、2、3 次调用抛出 `Error`
  - 第 4 次调用抛出 `Error`（正则 `..` 匹配三个点中的前两个）
- **关联代码**: `home.ts:147-151`

### TC-A-027. [home.ts] — sanitizePathComponent 允许单点 `.`
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `sanitizePathComponent(".")`
  2. 调用 `sanitizePathComponent("foo.bar")`
- **预期结果**:
  - 均正常返回原字符串，不抛异常
- **关联代码**: `home.ts:147-151`

### TC-A-028. [home.ts] — sanitizePathComponent 允许合法项目名
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `sanitizePathComponent("my-project")`
  2. 调用 `sanitizePathComponent("my_project")`
  3. 调用 `sanitizePathComponent("project123")`
  4. 调用 `sanitizePathComponent("@scope/package")`（含 @）
- **预期结果**:
  - 均正常返回原字符串
- **关联代码**: `home.ts:147-151`

### TC-A-029. [home.ts] — sanitizePathComponent 对空字符串
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `sanitizePathComponent("")`
- **预期结果**:
  - 正常返回 `""`（空字符串不匹配正则，但后续 join 会产生 `home/` 或 `home//`）
- **关联代码**: `home.ts:147-151`

---

## 五、知识路径组装（`home.ts`）

### TC-A-030. [home.ts] — resolveKnowledgePath 正确组装三层路径
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 设置 `GALE_KNOWLEDGE_HOME = "/tmp/test-knowledge"`
- **测试步骤**:
  1. 调用 `resolveKnowledgePath({ type: "solutions", projectName: "myapp" })`
- **预期结果**:
  - 返回对象包含：
    - `home: "/tmp/test-knowledge"`
    - `projectDir: "/tmp/test-knowledge/myapp"`
    - `docDir: "/tmp/test-knowledge/myapp/solutions"`
    - `projectName: "myapp"`
- **关联代码**: `home.ts:154-166`

### TC-A-031. [home.ts] — resolveKnowledgePath 未提供 projectName 时自动提取
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 当前目录 git remote 为 `git@github.com:org/auto-extracted.git`
- **测试步骤**:
  1. 调用 `resolveKnowledgePath({ type: "plans" })`
- **预期结果**:
  - `projectName` 为 `"auto-extracted"`
  - `docDir` 以 `.../auto-extracted/plans` 结尾
- **关联代码**: `home.ts:156`

### TC-A-032. [home.ts] — resolveKnowledgePath 对非法 projectName 抛出异常
- **优先级**: P0
- **测试类型**: 安全
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `resolveKnowledgePath({ type: "brainstorms", projectName: "../etc" })`
- **预期结果**:
  - 抛出 `Error`，message 为 `"Invalid path component: ../etc"`
- **关联代码**: `home.ts:156`

---

## 六、路径穿越防护（`home.ts` + `writer.ts`）

### TC-A-033. [writer.ts] — filename 包含 `../` 触发路径穿越拦截
- **优先级**: P0
- **测试类型**: 安全
- **前置条件**:
  - 设置 `GALE_KNOWLEDGE_HOME` 指向可写临时目录
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "solutions", filename: "../../../etc/passwd", content: "x" })`
- **预期结果**:
  - 抛出 `Error`，message 为 `"Invalid filename: path traversal detected"`
- **关联代码**: `writer.ts:61-65`

### TC-A-034. [writer.ts] — filename 为绝对路径尝试穿越
- **优先级**: P0
- **测试类型**: 安全
- **前置条件**:
  - 设置 `GALE_KNOWLEDGE_HOME` 指向可写临时目录
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "solutions", filename: "/etc/passwd", content: "x" })`
- **预期结果**:
  - 抛出 `Error`，message 为 `"Invalid filename: path traversal detected"`
- **关联代码**: `writer.ts:61-65`

### TC-A-035. [writer.ts] — 正常子目录 filename 不触发拦截
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 设置 `GALE_KNOWLEDGE_HOME` 指向可写临时目录
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "solutions", filename: "sub/deep/doc.md", content: "# Test" })`
- **预期结果**:
  - 正常写入，返回 `{ usedFallback: false }`
  - 文件实际存在于 `.../solutions/sub/deep/doc.md`
- **关联代码**: `writer.ts:61-65`

### TC-A-036. [writer.ts] — filename 为 `..` 单文件名触发拦截
- **优先级**: P0
- **测试类型**: 安全
- **前置条件**:
  - 设置 `GALE_KNOWLEDGE_HOME` 指向可写临时目录
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "plans", filename: "..", content: "x" })`
- **预期结果**:
  - 抛出 `Error`，message 为 `"Invalid filename: path traversal detected"`
- **关联代码**: `writer.ts:61-65`

### TC-A-037. [writer.ts] — filename 为空字符串时的路径穿越边界
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**:
  - 设置 `GALE_KNOWLEDGE_HOME` 指向可写临时目录
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "plans", filename: "", content: "x" })`
- **预期结果**:
  - `finalPath === safeBase`（空字符串 resolve 后等于 docDir 本身）
  - 条件 `finalPath !== safeBase` 为 false，不抛 traversal 错误
  - 但 `writeFileSync(primaryPath, ...)` 会失败（无法写入目录），触发 fallback
- **关联代码**: `writer.ts:58-69`

### TC-A-038. [home.ts] — resolveKnowledgePath 的 sanitizePathComponent 拦截 projectName 中的 traversal
- **优先级**: P0
- **测试类型**: 安全
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `resolveKnowledgePath({ type: "solutions", projectName: "foo/../bar" })`
  2. 调用 `resolveKnowledgePath({ type: "solutions", projectName: "foo\\bar" })`
  3. 调用 `resolveKnowledgePath({ type: "solutions", projectName: "foo/bar" })`
- **预期结果**:
  - 均抛出 `Error: Invalid path component: ...`
- **关联代码**: `home.ts:147-151,156`

---

## 七、知识文档写入（`writer.ts`）

### TC-A-039. [writer.ts] — 成功写入主路径（知识仓库）
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 设置 `GALE_KNOWLEDGE_HOME` 指向可写临时目录
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "brainstorms", filename: "idea.md", content: "# Idea\n\nDetails" })`
  2. 读取返回的 `path` 指向的文件内容
- **预期结果**:
  - 返回 `{ usedFallback: false, path: "..." }`
  - 文件存在且内容包含注入的 frontmatter
- **关联代码**: `writer.ts:48-70`

### TC-A-040. [writer.ts] — 主路径不可写时降级到 docs/ fallback
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 设置 `GALE_KNOWLEDGE_HOME` 指向只读/不存在的父目录（如 `/root/...` 或无权限目录）
  - 当前工作目录可写
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "solutions", filename: "doc.md", content: "# Fallback", cwd: tempCwd })`
  2. 检查返回结果和文件位置
- **预期结果**:
  - 返回 `{ usedFallback: true, path: "<tempCwd>/docs/solutions/doc.md", warning: "Knowledge repo write failed (...), falling back to ..." }`
  - 文件存在于 fallback 路径
  - console.warn 被调用并输出 warning
- **关联代码**: `writer.ts:71-84`

### TC-A-041. [writer.ts] — 主路径和 fallback 均失败时抛出聚合错误
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 设置 `GALE_KNOWLEDGE_HOME` 指向不可写目录
  - 当前工作目录下的 `docs/` 也设置为不可写
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "plans", filename: "plan.md", content: "# Plan" })`
- **预期结果**:
  - 抛出 `Error`，message 以 `"Failed to write knowledge document to both primary and fallback paths:"` 开头
- **关联代码**: `writer.ts:85-88`

### TC-A-042. [writer.ts] — 写入时自动创建多级目录
- **优先级**: P1
- **测试类型**: 功能
- **前置条件**:
  - 设置 `GALE_KNOWLEDGE_HOME` 指向全新的空临时目录
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "solutions", filename: "a/b/c/nested.md", content: "deep" })`
- **预期结果**:
  - 成功写入
  - 目录 `home/<project>/solutions/a/b/c/` 被自动创建
- **关联代码**: `writer.ts:68,81`

---

## 八、Frontmatter 注入（`writer.ts`）

### TC-A-043. [writer.ts] — 无 frontmatter 的内容自动注入 project
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `injectProjectFrontmatter("# Hello\n\nWorld", "myproject")`
- **预期结果**:
  - 返回字符串以 `---\nproject: myproject\n---\n\n# Hello\n\nWorld` 开头
  - 原文内容完整保留
- **关联代码**: `writer.ts:103-116`

### TC-A-044. [writer.ts] — 已有 frontmatter 但无 project 字段时注入
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `injectProjectFrontmatter("---\ntitle: Plan\n---\n\nBody", "myproject")`
- **预期结果**:
  - 返回包含 `project: myproject`
  - 原有 `title: Plan` 保留
  - body 部分保留为 `\n\nBody`（含前导换行）
- **关联代码**: `writer.ts:108-115`

### TC-A-045. [writer.ts] — 已有 frontmatter 且已有 project 字段时不覆盖
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `injectProjectFrontmatter("---\nproject: existing\n---\n\nBody", "myproject")`
- **预期结果**:
  - 返回包含 `project: existing`（原值保留）
  - 不注入 `myproject`
- **关联代码**: `writer.ts:111-113`

### TC-A-046. [writer.ts] — 空内容处理
- **优先级**: P0
- **测试类型**: 边界
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `injectProjectFrontmatter("", "myproject")`
  2. 调用 `injectProjectFrontmatter("", "myproject")` 后检查结果
- **预期结果**:
  - 返回 `"---\nproject: myproject\n---\n\n"`（空 body，formatFrontmatter 会添加 `---` 和尾部换行）
- **关联代码**: `writer.ts:104-106`

### TC-A-047. [writer.ts] — 只有 frontmatter 开始标记无结束标记
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `injectProjectFrontmatter("---\ntitle: Only Start\nNo end marker here", "myproject")`
- **预期结果**:
  - `parseFrontmatter` 返回 `{ data: {}, body: raw }`（无结束标记视为无 frontmatter）
  - 最终输出为以 `---\nproject: myproject\n---\n\n` 开头，后接原字符串
- **关联代码**: `writer.ts:108,frontmatter.ts:14-24`

### TC-A-048. [writer.ts] — frontmatter 后紧跟内容无空行
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `injectProjectFrontmatter("---\ntitle: X\n---\nImmediate", "myproject")`
- **预期结果**:
  - 输出包含 `---\nproject: myproject\ntitle: X\n---\n\nImmediate`
  - `formatFrontmatter` 会在 `---` 和 body 间插入空行
- **关联代码**: `writer.ts:115,frontmatter.ts:49`

### TC-A-049. [writer.ts] — frontmatter 中 project 为 undefined 时注入
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**: 无
- **测试步骤**:
  1. 构造一个 frontmatter 中 project 键存在但值为 undefined 的情况（通过 parseFrontmatter 理论分析）
  2. 实际上直接测试 `injectProjectFrontmatter("---\nproject: \n---\n\nBody", "myproject")`
- **预期结果**:
  - `js-yaml` 解析 `project: ` 为 `null`
  - `!data.project` 为 true（null 为 falsy）
  - 注入 `project: myproject`
- **关联代码**: `writer.ts:111-113`

### TC-A-050. [writer.ts] — frontmatter 中 project 为空字符串时不覆盖
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**: 无
- **测试步骤**:
  1. 调用 `injectProjectFrontmatter("---\nproject: \"\"\n---\n\nBody", "myproject")`
- **预期结果**:
  - 空字符串为 falsy，`!data.project` 为 true
  - 注入 `project: myproject`（覆盖空字符串）
- **关联代码**: `writer.ts:111-113`

---

## 九、端到端集成场景

### TC-A-051. [集成] — 完整写入流程验证 frontmatter 注入 + 路径解析
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 设置 `GALE_KNOWLEDGE_HOME` 为可写临时目录
  - 当前目录 git remote 为 `git@github.com:org/endtoend.git`
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "solutions", filename: "test.md", content: "# Problem\n\nSolution here" })`
  2. 读取写入文件的内容
- **预期结果**:
  - 文件路径为 `<home>/endtoend/solutions/test.md`
  - 文件内容以 `---\nproject: endtoend\n---\n\n# Problem\n\nSolution here` 开头
  - `usedFallback` 为 `false`
- **关联代码**: `writer.ts:48-70,home.ts:154-166`

### TC-A-052. [集成] — 显式 projectName 覆盖 git 提取
- **优先级**: P0
- **测试类型**: 功能
- **前置条件**:
  - 设置 `GALE_KNOWLEDGE_HOME` 为可写临时目录
  - 当前目录 git remote 为 `git@github.com:org/gitname.git`
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "plans", filename: "p.md", content: "c", projectName: "override-name" })`
  2. 检查返回的 path
- **预期结果**:
  - 路径包含 `override-name/plans/p.md`，不包含 `gitname`
  - frontmatter 中 project 为 `override-name`
- **关联代码**: `writer.ts:51,58`

### TC-A-053. [集成] — cwd 参数影响 fallback 路径和项目名提取
- **优先级**: P1
- **测试类型**: 功能
- **前置条件**:
  - 创建临时目录 A（无 git，目录名 `dir-a`）
  - 创建临时目录 B（有 git remote `git@github.com:org/dir-b.git`）
  - 设置 `GALE_KNOWLEDGE_HOME` 为不可写目录以触发 fallback
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "brainstorms", filename: "b.md", content: "c", cwd: dirA })`
  2. 调用 `writeKnowledgeDocument({ type: "brainstorms", filename: "b.md", content: "c", cwd: dirB })`
- **预期结果**:
  - 第一次 fallback 到 `<dirA>/docs/brainstorms/b.md`，projectName 为 `dir-a`
  - 第二次 fallback 到 `<dirB>/docs/brainstorms/b.md`，projectName 为 `dir-b`
- **关联代码**: `writer.ts:50-51,76-77`

### TC-A-054. [集成] — fallback 写入也经过 frontmatter 注入
- **优先级**: P1
- **测试类型**: 功能
- **前置条件**:
  - 设置 `GALE_KNOWLEDGE_HOME` 为不可写目录
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "solutions", filename: "f.md", content: "raw", cwd: tempCwd })`
  2. 读取 fallback 文件内容
- **预期结果**:
  - 文件内容包含 frontmatter（`project: <projectName>`）
  - 不因为 fallback 而跳过 frontmatter 注入
- **关联代码**: `writer.ts:54,82`

---

## 十、兼容性与其他边界

### TC-A-055. [兼容性] — Windows 路径分隔符在 filename 中触发路径穿越
- **优先级**: P1
- **测试类型**: 兼容性/安全
- **前置条件**:
  - 在 macOS/Linux 环境下测试
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "solutions", filename: "sub\\..\\..\\etc\\passwd", content: "x" })`
- **预期结果**:
  - `resolve(primaryPath)` 将 `\\` 视为普通文件名字符（在 POSIX 上）
  - 路径穿越检查可能通过（因为 resolve 不转换 `\\` 为分隔符）
  - **风险点**: 在 Windows 上 `\\` 会被 resolve 解析为路径分隔符，可能导致穿越
  - 建议在 writer 的 sanitizePathComponent 中也对 filename 做检查
- **关联代码**: `writer.ts:58-65`

### TC-A-056. [边界] — content 为超大字符串（1MB Markdown）
- **优先级**: P2
- **测试类型**: 性能/边界
- **前置条件**:
  - 生成 1MB 的 Markdown 内容
- **测试步骤**:
  1. 调用 `injectProjectFrontmatter(bigContent, "project")`
  2. 调用 `writeKnowledgeDocument({ type: "solutions", filename: "big.md", content: bigContent })`
- **预期结果**:
  - 均正常完成，无内存溢出或明显延迟
  - 写入文件大小接近 1MB + frontmatter 头部长度
- **关联代码**: `writer.ts:48-89`

### TC-A-057. [边界] — filename 包含 Unicode 和特殊字符
- **优先级**: P1
- **测试类型**: 边界
- **前置条件**:
  - 设置 `GALE_KNOWLEDGE_HOME` 为可写临时目录
- **测试步骤**:
  1. 调用 `writeKnowledgeDocument({ type: "plans", filename: "文档-📋.md", content: "测试" })`
  2. 调用 `writeKnowledgeDocument({ type: "plans", filename: "file with spaces.md", content: "test" })`
- **预期结果**:
  - 均正常写入（sanitizePathComponent 和路径穿越检查均不拦截合法 Unicode 和空格）
- **关联代码**: `home.ts:147-151,writer.ts:58-65`

### TC-A-058. [边界] — 并发写入同一目录不同文件
- **优先级**: P2
- **测试类型**: 边界
- **前置条件**:
  - 设置 `GALE_KNOWLEDGE_HOME` 为可写临时目录
- **测试步骤**:
  1. 同时发起 10 次 `writeKnowledgeDocument` 调用，文件名不同，类型和项目名相同
- **预期结果**:
  - 全部成功（`mkdirSync(..., { recursive: true })` 是幂等的）
  - 无竞态条件导致异常
- **关联代码**: `writer.ts:68`

---

> **测试执行建议**:
> 1. 所有 P0 用例必须在合并前全部通过。
> 2. 路径穿越相关用例（TC-A-024~TC-A-038）建议在 POSIX 和 Windows（如可行）双平台执行。
> 3. `home.ts` 中涉及 `~/.galeharness/` 的用例需在隔离临时 home 目录中执行，避免污染用户真实配置。
