---
date: 2026-04-25
topic: upstream-brainstorm-ideate-rigor-sync
title: "取长补短融合 upstream brainstorm/ideate 严谨性改进"
category: brainstorm
status: active
---

# 取长补短融合 upstream brainstorm/ideate 严谨性改进

## Problem Frame

GaleHarnessCLI 已经在 PR #66 / commit `a277942` 中融入 Karpathy/工程师提示词 guardrails：需求阶段区分假设、非目标和成功标准，计划阶段要求复杂度有依据，执行阶段形成 execution contract，工作与审查阶段强调 surgical change 和 diff hygiene。这些本地 guardrails 是当前工作流的底座，不能被 upstream prompt 直接覆盖。

upstream `EveryInc/compound-engineering-plugin` 从 `e136d7f` 到 `ea8721e` 的新提交里，有四个 brainstorm/ideate 相关改进值得吸收：

- `494313e fix(ce-brainstorm): enforce Interaction Rules in universal flow (#669)`
- `304a975 feat(ce-brainstorm): probe rigor gaps with prose before Phase 2 (#677)`
- `6514b1f feat(ce-ideate): subject gate, surprise-me, and warrant contract (#671)`
- `f0433d9 fix(ce-ideate): sharpen bug intent, surprise-me dispatch, and drop authoring refs (#672)`

目标不是“同步 upstream 文件”，而是把这些提交中能提高严谨性的语义手工三方融合进 `gh:brainstorm` 和 `gh:ideate`，同时保留 GaleHarnessCLI 的 HKTMemory、Gale knowledge、`gh:` 命名、document-review handoff、Karpathy guardrails、跨平台转换约束。

---

## Actors

- A1. 使用 GaleHarnessCLI 的工程师：希望 brainstorm/ideate 更少发散错题、更能产出可规划的需求或高质量想法。
- A2. `gh:brainstorm` orchestrator：负责把用户想法转成 requirements doc，不能让 unprobed gaps 或未经确认的实现方案进入计划。
- A3. `gh:ideate` orchestrator：负责生成并筛选改进想法，必须先明确 ideation subject，再用 warrant 证明 survivor 值得进一步 brainstorm。
- A4. 后续 planner / worker / reviewer：消费需求与计划，需要继承 Karpathy guardrails，不被 upstream 机械替换破坏。

---

## Key Flows

- F1. Brainstorm universal flow 继承交互规则
  - **Trigger:** `gh:brainstorm` 把非软件主题路由到 `references/universal-brainstorming.md`。
  - **Steps:** universal reference 明确父级 Interaction Rules 仍适用，包括 one-question-per-turn、优先 blocking question tool、只有 genuinely open question 才用 prose。
  - **Outcome:** universal flow 不再绕过主 skill 的交互约束。
  - **Covered by:** R1, R2, R5, R14-R16

- F2. Brainstorm 在 Phase 2 前探测严谨性缺口
  - **Trigger:** 用户给出一个新需求或改进方向。
  - **Steps:** `gh:brainstorm` 在 Phase 1.2 内部扫描 evidence、specificity、counterfactual、attachment；Deep-product 额外扫描 durability。只对实际存在的缺口逐个 prose probe，不把它做成固定问卷。
  - **Outcome:** requirements doc 记录真实观察、具体受益者、现状 workaround、最小可证明版本、关键假设，而不是让 plan 继承模糊 framing。
  - **Covered by:** R4, R6-R8, R17

- F3. Ideate 先确认 subject，再决定 mode
  - **Trigger:** 用户运行 `gh:ideate`，输入为空、过宽、短词、或 “surprise me”。
  - **Steps:** 先判断 subject 是否 identifiable；对 vague prompt 问一个 scope question；把 “Surprise me” 作为一等模式；对 issue-tracker intent 用更窄触发规则；再做 repo/elsewhere/software/non-software mode classification。
  - **Outcome:** Phase 1 和 Phase 2 agents 不会在不同主题上发散，surprise-me 也有明确 dispatch 语义。
  - **Covered by:** R9-R11

- F4. Ideate 用 warrant contract 提高 survivor 质量
  - **Trigger:** Phase 2 生成候选想法，Phase 3 adversarial filtering 选择 survivors。
  - **Steps:** 每个 candidate/survivor 携带 warrant，标为 `direct:`、`external:` 或 `reasoned:`；过滤时拒绝无 warrant、warrant 不支撑结论、替换 subject 的想法；默认要求 meeting-test，tactical scope 可放宽。
  - **Outcome:** ideation artifact 中留下的想法有可检查依据，且下一步应进入 `gh:brainstorm` 而不是直接 plan/work。
  - **Covered by:** R12, R13

---

## Requirements

### Fusion model

- R1. 必须手工三方融合 upstream 语义，不能机械应用 patch、不能整文件替换 `plugins/galeharness-cli/skills/gh-brainstorm/` 或 `plugins/galeharness-cli/skills/gh-ideate/`。
- R2. 必须保留本地 PR #66 / commit `a277942` 的 Karpathy guardrails，包括 assumption / non-goals / success criteria separation、complexity justification、execution contract、surgical-change、diff hygiene。
- R3. 必须保留 Gale/HKT 补丁，包括 HKTMemory retrieve/store、Gale knowledge 输出路径、`gale-task` lifecycle、`gh:` 命名、`galeharness-cli:` agent namespace。
- R4. 变更必须沿用现有 right-size 原则：明确、轻量任务不被固定问卷拖慢；标准或深度任务必须显式处理真实严谨性缺口。

### Brainstorm rigor

- R5. `gh:brainstorm` 的 universal flow 必须继承父级 Interaction Rules，而不是用 universal reference 放松 one-question-per-turn 或 blocking question tool 规则。
- R6. `gh:brainstorm` 必须在进入 approaches / Phase 2 前扫描 scope-appropriate rigor gaps：evidence、specificity、counterfactual、attachment；Deep-product 额外包含 durability。
- R7. Rigor probes 必须是 prose probes，并且只对实际存在的 gap 逐个触发；不能改成固定菜单、批量问题、或所有 brainstorm 强制跑满的问题清单。
- R8. Rigor probes 的结果必须进入 requirements doc 的 assumptions、non-goals、success criteria、scope boundaries、deferred planning questions 等现有结构，不能新增和本地模板冲突的 parallel taxonomy。

### Ideate rigor

- R9. `gh:ideate` 必须先判断 ideation subject 是否 identifiable，再做 mode classification；repo presence 只能作为 grounding 来源，不能把 vague prompt 默认为“当前 repo improvements”。
- R10. “Surprise me” 必须作为明确模式处理：在 repo 内可让代码库供应素材；不在 repo 时必须先获得 URL、描述、draft 或 paste 等 substance。
- R11. Issue-tracker intent 必须收窄到 explicit tracker/report phrasing；`bug in auth`、`top 3 bugs in authentication` 这类 bug focus 不能误触发 issue intelligence。
- R12. 每个 surviving idea 必须有 articulated warrant，且 filtering 必须拒绝无 warrant、warrant 不支撑结论、或替换 subject 的想法。
- R13. Ideation artifact 必须能记录 warrant，并保持 “ideate -> brainstorm -> plan” 链路；不允许从 ideation output 直接跳到 implementation plan。

### Compatibility and scope

- R14. 不修改 `test-browser`、`lfg`、release-only 文件或 release-owned version/changelog。
- R15. 不新增平台专属变量、跨 skill 相对路径、绝对路径、或只在 Claude Code 生效且无 fallback 的指令。
- R16. 不把 upstream 的 `ce-proof`、Proof-specific authoring refs、Every-specific phrasing机械带入 GaleHarnessCLI；已有 Proof/HITL 语义只在本地已有 reference 中按现状保留。
- R17. 如果修改 plugin skill 行为，必须补充 prompt contract tests，并运行 `bun test` 与 `bun run release:validate`。

---

## Acceptance Examples

- AE1. **Covers R5.** Given `gh:brainstorm` 检测到非软件 brainstorm，when 它加载 `references/universal-brainstorming.md`，then universal reference 明确父级 Interaction Rules 仍适用，并禁止 silently skipping questions。
- AE2. **Covers R6-R8.** Given 用户说“给 ideate 加更多 agents 让它更聪明”，when `gh:brainstorm` 进入 Phase 1，then 它应 prose-probe 具体使用者、现状成本、最小可证明版本，而不是直接把“更多 agents”写成 requirement。
- AE3. **Covers R9-R11.** Given 用户运行 `gh:ideate quick wins`，when subject 不可识别，then workflow 先问要 ideate 什么，并提供 “Surprise me” 选项；不直接 dispatch repo-wide agents。
- AE4. **Covers R11.** Given 用户运行 `gh:ideate top 3 bugs in authentication`，when 没有 explicit tracker/report phrasing，then 它被视为普通 bug-focused ideation，而不是 issue-tracker analysis。
- AE5. **Covers R12-R13.** Given Phase 2 产生一个 plausible 但没有 direct/external/reasoned warrant 的想法，when Phase 3 filtering 执行，then 该想法被拒绝或补足 warrant；survivor 文档中展示 warrant 和 rationale。
- AE6. **Covers R1-R4, R14-R16.** Given upstream diff 想替换 `ce-ideate` 整个 Phase 0-6，when 实现本需求，then 只提取 subject gate、surprise-me、issue intent、warrant contract 等语义并适配到本地 `gh:` / HKT / Gale 结构。

---

## Success Criteria

- `gh:brainstorm` 更稳定地在 plan 前暴露用户问题 framing 的证据、具体性、反事实、依附方案和耐久性风险。
- `gh:ideate` 不再对 vague prompts 做散射式多 agent 发散，surprise-me 与 issue intent 有明确、可测的 routing。
- Ideation survivors 带有可检查 warrant，质量高于 naive idea list，且自然进入 `gh:brainstorm`。
- PR #66 的 Karpathy guardrails 和本地 HKT/Gale 补丁完整保留。
- 后续实现能通过 contract tests、`bun test`、`bun run release:validate`。

---

## Scope Boundaries

- 不碰 `test-browser`、`lfg`、release-only 变更。
- 不覆盖本地 Karpathy guardrails，不弱化 assumptions/non-goals/success criteria separation、complexity justification、execution contract、surgical-change、diff hygiene。
- 不机械替换整文件，不套 upstream patch，不复制 upstream `ce:` 命名或 Every-specific authoring refs。
- 不新增新的 ideation product surface、Proof integration 重构、issue intelligence agent 重构、web research cache 重构。
- 不把 upstream 的非本轮文件变更纳入范围，如 demo-reel、proof、root AGENTS authoring wording。
- 在 brainstorm / plan / document-review 阶段不实现代码、不改技能正文、不 commit/push/PR；进入已审查通过的 work 阶段后，按计划修改 skill 和 tests。

---

## Key Decisions

- **按语义吸收，不按 diff 吸收。** upstream 与本地 guardrails 互补，但文件结构、命名、HKT/Gale patch、测试状态不同，机械 patch 会破坏本地行为。
- **Brainstorm 只吸收严谨性 probing 和 universal Interaction Rules。** 不改变 PR #66 的 Karpathy structure，只让 pressure test 更有操作性。
- **Ideate 优先吸收 subject gate、surprise-me、issue intent sharpening、warrant contract。** 这些直接提高 idea quality 和 dispatch correctness；Proof/save/web-cache 等大改不属于本轮。
- **Plan 必须显式经过 document-review 再 work。** 这是本地 `gh:plan` 当前质量门的一部分，也是后续实现前保护融合质量的关键步骤。

---

## Dependencies / Assumptions

- 假设本轮只关注 `plugins/galeharness-cli/skills/gh-brainstorm/`、`plugins/galeharness-cli/skills/gh-ideate/` 及相关 prompt contract tests。
- 假设当前 `gh:ideate` 尚未吸收 upstream 的 mode-aware elsewhere/web research/Proof 大结构；本轮只取严谨性核心，不引入更大 workflow 改造。
- 假设 `document-review` 会在后续 plan handoff 后、`gh:work` 前执行；本阶段计划文档必须保留这个顺序。
- 假设 upstream commit 的非 brainstorm/ideate 文件改动本轮都不纳入 scope。

---

## Outstanding Questions

### Resolve Before Planning

- 无。用户已要求轻量自动决策，不反问。

### Deferred to Planning

- [Technical] Warrant contract 的最小落点应只在 `gh-ideate/SKILL.md` 和 `post-ideation-workflow.md`，还是需要新增/复制 `universal-ideation.md`？
- [Technical] Contract tests 应放入现有 `tests/pipeline-review-contract.test.ts`，还是拆出 `tests/ideate-skill-contract.test.ts`？
- [Technical] `gh:brainstorm` rigor probes 如何和 PR #66 的 “Challenge framing before committing” 文案组合，避免重复和过长？

---

## Next Steps

1. `/gh:plan docs/brainstorms/2026-04-25-upstream-brainstorm-ideate-rigor-sync-requirements.md`
2. 后续执行顺序必须是：plan document-review -> `gh:work`。
