---
title: Upstream brainstorm/ideate rigor changes should be fused semantically
date: 2026-04-25
category: workflow-issues
module: GaleHarnessCLI workflow skills
problem_type: workflow_issue
component: development_workflow
severity: medium
applies_when:
  - Syncing upstream compound-engineering-plugin workflow prompt changes into GaleHarnessCLI
  - Upstream prompt improvements overlap with local Karpathy, HKTMemory, or Gale guardrails
  - Brainstorm or ideate behavior needs stricter routing without replacing local skill structure
tags: [upstream-sync, brainstorm, ideate, workflow-guardrails, prompt-contract-tests]
---

# Upstream brainstorm/ideate rigor changes should be fused semantically

## Context

本次同步从 upstream `EveryInc/compound-engineering-plugin` 的 brainstorm/ideate 相关提交中吸收严谨性改进：

- `494313e fix(ce-brainstorm): enforce Interaction Rules in universal flow (#669)`
- `304a975 feat(ce-brainstorm): probe rigor gaps with prose before Phase 2 (#677)`
- `6514b1f feat(ce-ideate): subject gate, surprise-me, and warrant contract (#671)`
- `f0433d9 fix(ce-ideate): sharpen bug intent, surprise-me dispatch, and drop authoring refs (#672)`

GaleHarnessCLI 本地已经有 PR #66 / commit `a277942` 引入的 Karpathy guardrails：brainstorm 要分离 confirmed requirements、explicit assumptions、non-goals、success criteria；plan 要证明复杂度；work 要有 execution contract 和 surgical-change 边界；review 要检查 diff hygiene。同步 upstream 时，目标不是覆盖本地 prompt，而是把 upstream 的有用行为翻译进这些已有阶段。

## Guidance

同步 workflow prompt 时，把 upstream 当作语义输入，而不是 patch source。具体做法：

- 先列出本地不能丢的 guardrails：Karpathy guardrails、HKTMemory retrieve/store、Gale knowledge 输出、`gale-task` lifecycle、`gh:` skill 命名、`galeharness-cli:` agent namespace、跨平台 fallback。
- 再提取 upstream 的最小行为增量：universal brainstorm 继承 Interaction Rules、rigor gap probes、ideate subject-identification gate、surprise-me routing、issue intent 收窄、warrant contract。
- 最后把行为落到本地对应阶段，而不是复制 upstream 文件结构、`ce:` 命名、Proof/Every-specific wording 或 authoring references。

本次落点是：

- `gh:brainstorm` 的 Interaction Rules 明确适用于 universal non-software flow；`references/universal-brainstorming.md` 只扩展父规则，不放松 one-question-per-turn 或 blocking question tool fallback。
- `gh:brainstorm` 的 Phase 1.2 把 pressure test 变成 selective rigor probes：evidence、specificity、counterfactual、attachment，Deep-product 额外 durability。它们是 prose probe，不是固定问卷；只对真实缺口逐个触发。
- `gh:ideate` 在 focus/volume/mode routing 前增加 subject-identification gate。显式 `surprise me` / `pick for me` / `you decide` 直接进入 surprise-me mode，不重复确认。
- `gh:ideate` 把 issue-tracker intent 收窄到 explicit tracker/report phrasing，避免 `top 3 bugs in authentication` 这类普通 bug focus 误触发 issue intelligence。
- `gh:ideate` 要求每个 candidate/survivor 带 warrant，且标为 `direct:`、`external:` 或 `reasoned:`；post-ideation filtering 拒绝无 warrant、unsupported warrant、subject replacement 和低于 meeting-test 的想法。

测试应该保护行为锚点，而不是锁死整段 prose。本次把 assertions 放在 `tests/pipeline-review-contract.test.ts`，覆盖：

- brainstorm universal flow 继承父级 Interaction Rules；
- brainstorm rigor gap lenses 和 prose/selective/before Phase 2 约束；
- ideate subject gate、surprise-me、issue intent sharpening；
- warrant contract、post-ideation artifact 字段和 rejection criteria；
- 本地 HKT/Gale anchors、PR #66 plan/work/review guardrails 仍存在。

## Why This Matters

Workflow skill 是 agent 的默认行为入口。机械同步 upstream prompt 很容易引入三类回归：

- 本地 guardrail 被覆盖，导致 brainstorm 又把假设写成需求，plan 又把复杂度写成主观判断。
- 平台或插件身份漂移，例如把 `ce:`、Proof、Every authoring references 带进 GaleHarnessCLI。
- 新行为缺少测试锚点，后续同步时不知道哪些是刻意融合、哪些只是临时文字。

语义融合能同时得到 upstream 的好处和本地系统的连续性：brainstorm 更会追问真实证据与边界，ideate 更少对 vague prompt 发散，survivor idea 更有可检查依据，同时不破坏 HKTMemory、Gale knowledge 和已有 workflow quality gates。

## When to Apply

- upstream 修改的是 prompt/workflow behavior，而本地已有同类但不同结构的 guardrails。
- upstream 变更跨多个阶段，不能通过单文件 patch 保持语义正确。
- 同步对象包含平台特定命名、authoring refs、外部产品 references 或本地没有的 workflow surface。
- 需要让后续 reviewers 和 tests 能区分“保留本地行为”与“吸收 upstream 行为”。

## Examples

不推荐：

```text
直接把 upstream ce-brainstorm 或 ce-ideate 的完整 SKILL.md 覆盖到本地 gh-* skill。
```

这种做法会丢掉 GaleHarnessCLI 的 HKT/Gale sections、`gh:` naming、agent namespace、本地 document-review handoff 和 PR #66 guardrails。

推荐：

```text
1. 记录 upstream commit 的行为意图。
2. 标出本地必须保留的 anchors。
3. 在本地相同决策阶段补最小文字。
4. 用 prompt contract tests 锁住行为锚点和本地 anchors。
5. 验证 bun test、release:validate、git diff --check。
```

## Related

- `docs/brainstorms/2026-04-25-upstream-brainstorm-ideate-rigor-sync-requirements.md`
- `docs/plans/2026-04-25-003-feat-upstream-brainstorm-ideate-rigor-sync-plan.md`
- `docs/solutions/workflow-issues/karpathy-guidelines-workflow-guardrails-2026-04-24.md`
- `plugins/galeharness-cli/skills/gh-brainstorm/SKILL.md`
- `plugins/galeharness-cli/skills/gh-ideate/SKILL.md`
- `tests/pipeline-review-contract.test.ts`

## Future Sync Notes

- 继续同步 upstream brainstorm/ideate 时，先检查是否有新的 Proof/web-cache/demo-reel/authoring surface；除非本地已有对应需求，否则不要顺手带入。
- 对每个 upstream commit 保持“语义、落点、保留本地 anchors、测试锚点”四列表，而不是按文件逐行追 patch。
- 如果 upstream 后续扩大 surprise-me、elsewhere research 或 issue intelligence 的工作流，本地应先走 brainstorm/plan/document-review，再决定是否引入，不应直接在 ideate 中扩张执行面。
- Contract tests 应继续检查 HKTMemory、Gale knowledge、`galeharness-cli:` agent namespace 和 PR #66 guardrails，避免下一轮同步把本地底座冲掉。
