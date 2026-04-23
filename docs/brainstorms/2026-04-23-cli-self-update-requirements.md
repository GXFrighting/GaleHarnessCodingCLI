---
date: 2026-04-23
topic: cli-self-update
---

# CLI 自更新能力

## Problem Frame

GaleHarnessCLI 不具备自更新能力。用户获取新版本的唯一方式是手动 `git pull` 或重新运行 `setup.sh`，无法通过 CLI 命令行直接更新。具体问题：

- **gh:update skill 指向错误仓库**：当前指向 `EveryInc/compound-engineering-plugin`，而非 `wangrenzhu-ola/GaleHarnessCLI`；release tag 过滤规则也不匹配（上游用 `compound-engineering-v*`，我们用 `galeharness-cli-v*`）
- **gh:update 只更新 Claude Code 插件缓存**：清除缓存后依赖 Claude Code 重新拉取，不更新 CLI 本身
- **CLI 无 update 子命令**：`gale-harness` 只有 `convert`、`install`、`list`、`plugin-path`、`sync`、`board` 六个子命令
- **GitHub Release 无构建产物**：有 release tag 但 assets 为空，无可下载的二进制文件
- **package.json 标记 private**：已移除 npm publish，无 registry 分发

## Requirements

### Release 产物构建

- R1. CI 在 release PR 合入 main 时自动编译三个二进制入口为独立可执行文件：
  - `gale-harness`（src/index.ts）
  - `compound-plugin`（src/index.ts，同入口不同名称）
  - `gale-knowledge`（cmd/gale-knowledge/index.ts）
- R2. 使用 `bun build --compile` 编译，目标平台为 macOS arm64
- R3. 编译产物以 `tar.gz` 形式上传到对应 GitHub Release 的 assets，命名格式：`galeharness-cli-{version}-darwin-arm64.tar.gz`
- R4. tar.gz 内部包含三个二进制文件 + 一个 `VERSION` 文本文件（内容为版本号）

### CLI update 子命令

- R5. 新增 `gale-harness update` 子命令，执行以下流程：
  1. 查询 GitHub Release API 获取最新版本号（`wangrenzhu-ola/GaleHarnessCLI` 仓库，tag 前缀 `galeharness-cli-v`）
  2. 对比当前 CLI 版本（从 `package.json` 的 `version` 字段或 `--version` 输出获取）
  3. 若已是最新，输出 "Already up to date" 并退出
  4. 若有新版本，下载对应平台的 tar.gz 到临时目录
  5. 校验下载完整性（文件大小 > 0，tar 可解压）
  6. 备份当前二进制到 `~/.galeharness/backup/{version}/`（包含三个二进制）
  7. 解压新版本，替换 `~/.bun/bin/` 下的三个二进制
  8. 输出更新结果（旧版本 -> 新版本）

- R6. `gale-harness update --check` 仅检查是否有新版本，不执行更新
- R7. `gale-harness update --rollback` 回滚到备份的上一版本
- R8. 更新失败时（下载中断、解压失败、替换失败），自动尝试回滚到备份版本
- R9. 支持 `COMPOUND_PLUGIN_GITHUB_SOURCE` 环境变量覆盖仓库地址（与 install 命令一致），用于内网镜像或测试

### gh:update skill 修复

- R10. 修改 `plugins/galeharness-cli/skills/gh-update/SKILL.md`：
  - 将 `--repo EveryInc/compound-engineering-plugin` 改为 `--repo wangrenzhu-ola/GaleHarnessCLI`
  - 将 tag 过滤条件从 `startswith("compound-engineering-v")` 改为 `startswith("galeharness-cli-v")`
  - 将 tag 版本提取从 `sub("compound-engineering-v";"")` 改为 `sub("galeharness-cli-v";"")`
  - 将缓存路径从 `compound-engineering-plugin/compound-engineering/` 改为正确的 marketplace 名称
- R11. gh:update skill 增加提示：告知用户可通过 `gale-harness update` 更新 CLI 本身

## Scope Boundaries

**包含在本次需求内：**
- Release CI 产物构建和上传
- CLI update 子命令（含 check 和 rollback）
- gh:update skill 修复
- macOS arm64 平台支持

**延后到后续迭代：**
- Linux x64 和 Windows x64 平台的编译产物和更新支持
- 自动检查更新提醒（如启动时提示有新版本）
- 增量更新（仅下载变更部分）
- 版本锁定/版本范围约束

**不在本项目范围内：**
- npm registry 发布
- Homebrew tap 维护
- 非开发者用户的一键安装体验

## Success Criteria

- SC1. `gale-harness update --check` 能正确查询 GitHub Release 并报告当前/最新版本
- SC2. `gale-harness update` 能从 GitHub Release 下载编译产物并替换本地二进制，更新成功后 `gale-harness --version` 显示新版本
- SC3. 更新失败时自动回滚，回滚后 `gale-harness --version` 显示旧版本
- SC4. `gale-harness update --rollback` 能回滚到上一版本
- SC5. gh:update skill 指向正确的仓库和 tag 格式
- SC6. GitHub Release 包含可下载的 tar.gz 产物

## Dependencies

- GitHub Release 需要先有编译产物（R1-R4），update 子命令（R5-R9）才能工作
- gh:update skill 修复（R10-R11）可独立于 update 子命令先行完成

## Key Files

- `src/commands/update.ts` — 新增 update 子命令
- `src/index.ts` — 注册 update 子命令
- `plugins/galeharness-cli/skills/gh-update/SKILL.md` — 修复仓库指向
- `.github/workflows/release-pr.yml` — 添加编译和上传步骤
- `scripts/release/` — 可能需要新增编译脚本
