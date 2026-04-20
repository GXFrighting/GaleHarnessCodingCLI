---
title: "Global Knowledge Repository Infrastructure: Architecture, Path Resolution, and Skill Integration"
date: 2026-04-20
module: "gale-knowledge CLI / knowledge repository infrastructure"
problem_type: developer_experience
component: development_workflow
severity: high
applies_when:
  - Building global knowledge management systems that serve multiple projects
  - Requiring centralized documentation storage with automatic vector indexing
  - Designing fallback strategies for write failures in distributed environments
  - Integrating CLI tools into AI workflow skills
tags: [knowledge-repo, path-resolution, fallback-strategy, git-ops, vector-indexing, skill-integration]
related_components: [gale-task, hkt-memory, taskboard]
---

# Global Knowledge Repository Infrastructure: Architecture, Path Resolution, and Skill Integration

## Context

全局知识仓库问题源于三个关键痛点：

1. **项目污染**：AI 工作流技能（gh:brainstorm, gh:plan, gh:compound）产出的文档写入项目仓库的 `docs/` 目录，导致版本控制历史被大量自动生成的知识文档噪声淹没，业务代码的变更记录与知识文档混杂在一起，增加了代码审查和历史追溯的难度。

2. **跨项目不可见**：各项目的学习文档、决策记录、解决方案分散存储在各自仓库，缺乏统一的全局检索和浏览入口。团队在不同项目中反复遇到相同问题，却无法从其他项目的历史经验中受益。

3. **团队不可共享**：知识文档无法跨机器迁移，团队成员无法在不同工作环境间共享和复用积累。离线环境下知识积累完全孤立，无法与在线环境同步。

## Guidance

本方案涵盖 6 个核心架构决策，共同构成全局知识仓库的完整基础设施：

### 1. 优先级驱动的路径解析

路径解析采用三级优先级策略，确保灵活性与合理默认值并存：

- **最高优先级**：`GALE_KNOWLEDGE_HOME` 环境变量 -> 适用于 CI/CD 和自定义部署场景
- **中等优先级**：配置文件中的 `home` 字段 -> 适用于持久化的用户偏好
- **默认值**：`~/.galeharness/knowledge/` -> 零配置即可使用

```typescript
export function resolveKnowledgeHome(): string {
  const envHome = process.env.GALE_KNOWLEDGE_HOME
  if (envHome) return resolve(envHome)

  const config = readConfigFile()
  if (config?.home) return resolve(config.home)

  return DEFAULT_HOME_DIR  // ~/.galeharness/knowledge/
}
```

路径解析结果会自动缓存，避免在同一次技能调用中重复读取配置文件和环境变量。

### 2. Fallback 写入策略

写入操作采用优雅降级策略，确保文档绝不丢失：

- **首选路径**：全局知识仓库 `~/.galeharness/knowledge/<project>/<type>/`
- **降级路径**：项目本地 `docs/solutions/<type>/`
- **降级时机**：全局仓库不存在、权限不足、磁盘空间不足等

```typescript
export function writeKnowledgeDocument(options: WriteOptions): WriteResult {
  const { content, project, docType, filename } = options
  const primaryPath = join(resolveKnowledgeHome(), project, docType, filename)
  const fallbackPath = join('docs', 'solutions', docType, filename)

  try {
    mkdirSync(dirname(primaryPath), { recursive: true })
    writeFileSync(primaryPath, content, 'utf-8')
    return { path: primaryPath, usedFallback: false }
  } catch (primaryError) {
    const warning = `全局仓库写入失败 (${primaryError.message})，降级到项目本地`
    mkdirSync(dirname(fallbackPath), { recursive: true })
    writeFileSync(fallbackPath, content, 'utf-8')
    return { path: fallbackPath, usedFallback: true, warning }
  }
}
```

降级写入会在返回结果中携带警告信息，让调用方决定是否向用户展示。

### 3. Git 批量提交

一次技能调用产生的所有文档变更合并为一条 commit，遵循统一格式：

```
docs(<project>/<type>): <title>
```

例如：`docs(galeharness-cli/developer-experience): global knowledge repository infrastructure`

批量提交的实现通过 `gale-knowledge commit` 子命令完成，它会：
- 扫描知识仓库中所有未暂存的变更
- 按项目和类型分组
- 为每组生成一条规范化的 commit 消息
- 使用 `--no-verify` 跳过可能不适用于知识仓库的 Git hooks

### 4. Frontmatter 项目字段注入

文档写入时自动注入 `project` 字段，实现文档与来源项目的绑定：

```yaml
---
title: "某个解决方案"
date: 2026-04-20
project: galeharness-cli  # <- 自动注入
module: "..."
---
```

项目名称通过解析 Git remote URL 自动提取：
- `git@github.com:user/repo.git` -> `repo`
- `https://github.com/user/repo` -> `repo`
- 无 remote 时降级为当前目录名

### 5. 技能集成的 HKT-PATCH 标记

在现有 SKILL.md 中通过 HTML 注释标记添加全局知识仓库的路径解析逻辑，最小化对技能内容的侵入：

```markdown
<!-- HKT-PATCH:knowledge-path-start -->
在写入文档前，先尝试解析全局知识仓库路径：
1. 运行 `gale-knowledge resolve-home` 获取仓库根目录
2. 如果命令成功，将文档写入该目录下对应的项目/类型子目录
3. 如果命令失败或不可用，静默降级到项目本地 `docs/` 目录
<!-- HKT-PATCH:knowledge-path-end -->
```

这种标记方式的优势：
- 不影响未安装 gale-knowledge 的环境
- 便于自动化工具批量更新或移除
- 技能在任何平台上都能正常运行

### 6. CLI 职责分离

`gale-knowledge` CLI 提供 7 个独立子命令，每个命令职责单一：

| 子命令 | 职责 | 典型调用方 |
| --- | --- | --- |
| `resolve-home` | 输出知识仓库根目录路径 | 技能 SKILL.md |
| `resolve-path` | 输出指定项目/类型的完整路径 | 技能 SKILL.md |
| `extract-project` | 从 Git remote 提取项目名 | 技能 SKILL.md |
| `init` | 初始化知识仓库（创建目录、git init） | 用户首次使用 |
| `commit` | 批量提交知识仓库变更 | gh:compound 等技能 |
| `setup-ci` | 生成 CI/CD workflow 文件 | 仓库管理员 |
| `rebuild-index` | 增量重建向量索引 | CI/CD、手动维护 |

## Why This Matters

- **防止项目污染**：AI 生成的知识文档不再混入业务代码提交历史，项目仓库保持干净的变更记录
- **启用知识复用**：跨项目可见的知识文档库让团队从历史学习中受益，避免在不同项目中重复解决相同问题
- **支持离线-在线混合工作**：Fallback 写入策略 + 本地向量索引确保离线环境也能积累知识，联网后可同步
- **降低集成成本**：HKT-PATCH 标记最小化对现有 SKILL.md 的侵入性修改，技能在无全局仓库时自动降级
- **可审计可追溯**：Git commit 消息和 frontmatter 的 `project` 字段提供完整的文档来源链，支持按项目过滤和追溯

## When to Apply

- 构建跨项目的团队知识管理系统，需要统一的文档存储和检索入口
- 需要将 AI 生成的文档与源项目解耦，保持项目仓库的版本控制历史清洁
- 在全局安装的工具中实现自动文档写入功能，支持多项目共存
- 需要支持写入失败时的优雅降级，确保关键知识不丢失
- 集成第三方路径解析逻辑到多个 gh: 技能中，保持一致的行为

## Examples

### 示例 1: 技能中调用 gale-knowledge 解析路径

```bash
# 在 SKILL.md 的执行步骤中
KNOWLEDGE_HOME=$(gale-knowledge resolve-home 2>/dev/null)
if [ $? -eq 0 ]; then
  DOC_PATH="$KNOWLEDGE_HOME/$(gale-knowledge extract-project)/solutions"
else
  DOC_PATH="docs/solutions"
fi
```

### 示例 2: Frontmatter 自动注入项目字段

写入前的原始 frontmatter：
```yaml
---
title: "解决 TypeScript 类型推断问题"
date: 2026-04-20
problem_type: build_error
---
```

写入后自动注入 `project`：
```yaml
---
title: "解决 TypeScript 类型推断问题"
date: 2026-04-20
problem_type: build_error
project: galeharness-cli
---
```

### 示例 3: 全局仓库初始化

```bash
# 首次使用：初始化知识仓库
gale-knowledge init

# 自定义路径
GALE_KNOWLEDGE_HOME=/data/team-knowledge gale-knowledge init

# 初始化后的目录结构
~/.galeharness/knowledge/
  .git/
  .gitignore
  README.md
```

### 示例 4: TaskBoard 知识文档读取

```bash
# 查看所有知识文档
gale-task board --with-knowledge

# 仅查看知识文档
gale-task board --knowledge-only

# 按类型过滤
gale-task board --knowledge-type developer-experience
```

TaskBoard 集成通过 `knowledge-reader.ts` 模块实现，读取全局仓库中的文档并解析 frontmatter，与项目本地的 board 数据合并展示。

## Related

- `src/knowledge/` - 路径解析和文档写入核心逻辑
- `cmd/gale-knowledge/` - CLI 子命令实现
- `src/board/knowledge-reader.ts` - TaskBoard 知识文档读取集成
- `vendor/hkt-memory/` - HKTMemory v5.0 向量知识库
- `docs/plans/2026-04-20-001-feat-global-knowledge-repo-plan.md` - 原始实施计划
