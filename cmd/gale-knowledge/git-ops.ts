/**
 * gale-knowledge commit 子命令
 *
 * 在知识仓库中自动批量提交变更文件。
 * - git add -A 暂存所有变更
 * - git diff --cached --quiet 检查是否有变更
 * - 生成规范化 commit message 并提交
 */

import { defineCommand } from "citty"
import { spawnSync } from "node:child_process"
import type { KnowledgeDocType } from "../../src/knowledge/types.js"
import { resolveKnowledgeHome } from "../../src/knowledge/home.js"

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface CommitOptions {
  /** 项目名 */
  project: string
  /** 文档类型 */
  type: KnowledgeDocType
  /** 文档标题（用于 commit message） */
  title: string
  /** 知识仓库路径（可选，默认通过 resolveKnowledgeHome 获取） */
  knowledgeHome?: string
}

export interface CommitResult {
  /** 是否创建了 commit */
  committed: boolean
  /** commit hash（如果创建了） */
  hash?: string
  /** 信息 */
  message: string
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/**
 * 转义 title 中的特殊字符，防止 shell 注入。
 * 移除或替换可能导致 shell 命令异常的字符。
 */
export function sanitizeTitle(title: string): string {
  // 替换双引号为单引号，移除反引号和美元符号等危险字符
  return title
    .replace(/"/g, "'")
    .replace(/`/g, "'")
    .replace(/\$/g, "")
    .replace(/\\/g, "")
    .replace(/\n/g, " ")
    .replace(/\r/g, "")
    .trim()
}

// ---------------------------------------------------------------------------
// Core logic
// ---------------------------------------------------------------------------

/**
 * 在知识仓库中执行 git add -A && git commit
 *
 * @param options - 提交选项
 * @returns 提交结果
 */
export function commitKnowledgeChanges(options: CommitOptions): CommitResult {
  const home = options.knowledgeHome ?? resolveKnowledgeHome()
  const spawnOpts = { cwd: home, stdio: ["ignore", "pipe", "pipe"] as const, timeout: 15000 }

  try {
    // 1. 暂存所有变更
    const addResult = spawnSync("git", ["add", "-A"], spawnOpts)
    if (addResult.status !== 0) {
      const stderr = addResult.stderr ? addResult.stderr.toString().trim() : "unknown error"
      return { committed: false, message: `Commit failed: git add failed: ${stderr}` }
    }

    // 2. 检查是否有暂存变更
    const diffResult = spawnSync("git", ["diff", "--cached", "--quiet"], spawnOpts)
    if (diffResult.status === 0) {
      // exit code 0 -> 无变更
      return { committed: false, message: "No changes to commit" }
    }

    // 3. 生成 commit message
    const safeTitle = sanitizeTitle(options.title)
    const commitMessage = `docs(${options.project}/${options.type}): ${safeTitle}`

    // 4. 执行 commit
    const commitResult = spawnSync("git", ["commit", "-m", commitMessage], spawnOpts)
    if (commitResult.status !== 0) {
      const stderr = commitResult.stderr ? commitResult.stderr.toString().trim() : "unknown error"
      return { committed: false, message: `Commit failed: ${stderr}` }
    }

    // 5. 获取 commit hash
    const hashResult = spawnSync("git", ["rev-parse", "--short", "HEAD"], {
      cwd: home,
      stdio: ["ignore", "pipe", "ignore"],
      timeout: 15000,
    })
    const hash = hashResult.stdout ? hashResult.stdout.toString().trim() : ""

    return {
      committed: true,
      hash,
      message: commitMessage,
    }
  } catch (err) {
    const errMsg = err instanceof Error ? err.message : String(err)
    return {
      committed: false,
      message: `Commit failed: ${errMsg}`,
    }
  }
}

// ---------------------------------------------------------------------------
// Command definition
// ---------------------------------------------------------------------------

const commitCommand = defineCommand({
  meta: {
    name: "commit",
    description: "Commit knowledge changes to the repository",
  },
  args: {
    project: {
      type: "string",
      description: "Project name",
      required: true,
    },
    type: {
      type: "string",
      description: "Document type (brainstorm | plan | solution)",
      required: true,
    },
    title: {
      type: "string",
      description: "Document title for commit message",
      required: true,
    },
  },
  run: async ({ args }) => {
    try {
      const result = commitKnowledgeChanges({
        project: args.project as string,
        type: args.type as KnowledgeDocType,
        title: args.title as string,
      })

      if (result.committed) {
        process.stdout.write(
          `Committed: ${result.hash} ${result.message}\n`,
        )
      } else if (result.message.startsWith("Commit failed")) {
        process.stderr.write(`${result.message}\n`)
        process.exit(1)
      } else {
        process.stdout.write(`${result.message}\n`)
      }
    } catch (err) {
      process.stderr.write(
        "[gale-knowledge] commit failed: " +
        (err instanceof Error ? err.message : String(err)) +
        "\n",
      )
      process.exit(1)
    }
  },
})

export default commitCommand
