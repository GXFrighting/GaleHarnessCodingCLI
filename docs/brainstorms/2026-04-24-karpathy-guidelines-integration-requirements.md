---
date: 2026-04-24
topic: karpathy-guidelines-integration
title: "Karpathy Guidelines 融入 GaleHarnessCLI 全流程 Guardrails"
category: brainstorm
status: active
---

# Karpathy Guidelines 融入 GaleHarnessCLI 全流程 Guardrails

## Problem Frame

GaleHarnessCLI 已经通过 `gh:brainstorm`、`gh:plan`、`gh:work`、`gh:review` 把软件工作拆成需求、计划、执行、审查四个阶段。但每个阶段仍可能出现 LLM 常见失败模式：在 brainstorm 阶段默认接受错误问题框架，在 plan 阶段为了未来可能性过度设计，在 work 阶段扩大改动范围，在 review 阶段漏掉无关重构或 speculative abstraction。

`forrestchang/andrej-karpathy-skills` 的价值不在于可复用的代码或插件结构，而在于把这些失败模式压缩成四条清晰行为准则：显式假设、简单优先、手术式改动、验证闭环。本需求要把这些准则转译为 GaleHarnessCLI 自己的全流程 guardrails，融入现有 workflow，而不是新增一个需要用户手动调用的独立 `karpathy-guidelines` skill。

目标是让每个阶段在不显著增加流程负担的前提下，提前暴露假设、压住范围膨胀、保持改动可追溯，并让后续阶段能继承前一阶段的边界与成功标准。

---

## Source References

后续 `gh:plan` 和 `gh:work` 应参考原版 Markdown，确保转译时不跑偏；但这些链接是设计输入，不是要逐字复制到 GaleHarnessCLI。

- 原版项目 README：`https://github.com/forrestchang/andrej-karpathy-skills/blob/main/README.md`
- 原版 `CLAUDE.md`：`https://github.com/forrestchang/andrej-karpathy-skills/blob/main/CLAUDE.md`
- 原版 skill：`https://github.com/forrestchang/andrej-karpathy-skills/blob/main/skills/karpathy-guidelines/SKILL.md`
- 原版示例：`https://github.com/forrestchang/andrej-karpathy-skills/blob/main/EXAMPLES.md`

---

## Actors

- A1. 使用 GaleHarnessCLI 的工程师：通过 `gh:` workflow 驱动需求、计划、执行、审查，希望代理更少跑偏、更少过度实现。
- A2. Workflow orchestrator：执行 `gh:brainstorm`、`gh:plan`、`gh:work`、`gh:review` 的主代理，需要在合适阶段应用 guardrails。
- A3. Reviewer personas：在 `gh:review` 中检查 diff，需要识别无关改动、过度抽象、需求不可追溯的变更。
- A4. 后续 planner / worker：消费 brainstorm 或 plan 文档，需要看到明确假设、非目标、成功标准和范围边界。

---

## Key Flows

- F1. Brainstorm 阶段防错题
  - **Trigger:** 用户用 `gh:brainstorm` 探索一个新需求或改进方向。
  - **Actors:** A1, A2, A4
  - **Steps:** 代理先挑战问题框架，区分真实用户目标和用户原始表述；记录关键假设、非目标、成功标准；避免把未经确认的实现方案写成产品需求。
  - **Outcome:** 需求文档能告诉 planner “解决什么、不解决什么、为什么值得做”，而不是只复述用户最初的方案。
  - **Covered by:** R1, R2, R3, R11

- F2. Plan 阶段防过度设计
  - **Trigger:** 用户用 `gh:plan` 从需求文档或直接描述生成实施计划。
  - **Actors:** A2, A4
  - **Steps:** 代理检查每个复杂度来源是否有需求依据；把不确定性标为 blocking question、assumption 或 deferred technical question；禁止为了“未来可能”引入未证明的抽象、配置、target、agent 或 pipeline。
  - **Outcome:** 计划中的每个 implementation unit 都能追溯到 requirement 或 success criteria，复杂度有明确理由。
  - **Covered by:** R4, R5, R6, R11

- F3. Work 阶段防跑偏实现
  - **Trigger:** 用户用 `gh:work` 执行 plan 或 bare prompt。
  - **Actors:** A1, A2, A4
  - **Steps:** 代理在非 trivial 任务开工前形成轻量执行契约：当前假设、最小可行改动、不会触碰的范围、验证标准；执行中用该契约约束 diff。
  - **Outcome:** 实现只覆盖被要求的行为，避免 drive-by refactor、无关格式化和隐式 scope creep。
  - **Covered by:** R7, R8, R11

- F4. Review 阶段抓无关 diff
  - **Trigger:** 用户用 `gh:review` 审查当前 branch 或 PR。
  - **Actors:** A2, A3
  - **Steps:** review synthesis 或相关 persona 检查 diff 是否包含无需求依据的抽象、相邻重构、无关注释改写、未被 plan/requirements 支持的行为变化；把确定性问题路由到合适的 autofix class。
  - **Outcome:** 审查报告能明确指出“这不是错，但不该在这个变更里出现”的问题，并区分必须修复与人工取舍。
  - **Covered by:** R9, R10, R11

---

## Requirements

**Cross-workflow guardrail model**

- R1. 系统必须把 Karpathy guidelines 转译为 GaleHarnessCLI 分阶段 guardrails，而不是复制外部 `CLAUDE.md` 文案或新增一个默认主流程之外的独立 skill。
- R2. 每个阶段的 guardrail 必须贴合该阶段职责：`gh:brainstorm` 约束问题框架和需求边界，`gh:plan` 约束复杂度与可追溯性，`gh:work` 约束改动范围与验证，`gh:review` 约束 diff hygiene。
- R3. Guardrails 必须继承现有 workflow 的 right-size 原则：trivial 或已清晰的任务不能被强制加入冗长仪式；standard/deep 或高歧义任务必须显式记录假设和边界。

**Brainstorm guardrails**

- R4. `gh:brainstorm` 必须在合适范围下挑战用户原始 framing，明确“真实问题、用户目标、如果不做会怎样、是否有更高杠杆的相邻 framing”。
- R5. `gh:brainstorm` 产出的 requirements doc 必须区分需求、非目标、假设、成功标准，避免把未经确认的技术方案、未来扩展或 speculative polish 写成已决定需求。
- R6. 当 brainstorm 输出进入后续 plan 时，planner 必须能从文档中看到哪些问题已经是产品决策，哪些问题仍是 planning 或 research 阶段问题。

**Plan guardrails**

- R7. `gh:plan` 必须检查计划复杂度是否有需求依据：新增 abstraction、配置项、target、agent、pipeline、后台机制或错误处理层时，必须能追溯到 requirement、success criteria、风险或明确约束。
- R8. `gh:plan` 必须把不确定性显式分类为 blocking question、assumption、deferred technical question 或 implementation-time unknown，不能把关键不确定性静默写成确定设计。
- R9. `gh:plan` 的 implementation units 必须保留 traceability：每个 feature-bearing unit 都要能说明它推进哪些 requirement 或 acceptance example。

**Work guardrails**

- R10. `gh:work` 必须在非 trivial 任务执行前形成轻量执行契约，至少覆盖当前假设、最小可行改动、明确非目标、验证标准。
- R11. `gh:work` 必须要求实现阶段遵守 surgical changes：不主动改相邻代码、注释、格式或架构，除非这些改动直接服务于当前任务或是本次改动产生的必要清理。
- R12. `gh:work` 必须把验证标准和完成判断绑定到 plan 或 bare prompt 的目标，而不是用“看起来可以”替代测试、静态检查或人工可验证条件。

**Review guardrails**

- R13. `gh:review` 必须能识别 diff hygiene 问题：无关重构、speculative abstraction、未要求的行为变化、相邻格式化、无需求依据的文件改动。
- R14. `gh:review` 必须区分“本次实现产生的必要清理”和“pre-existing 或无关清理”，避免把 surgical changes 规则误用为禁止所有整理。
- R15. `gh:review` 必须按现有 review routing 模型输出发现：确定性、本地可修复的问题可进入 `safe_auto`；涉及 scope、行为或设计取舍的问题必须保留为 `gated_auto`、`manual` 或 `advisory`。

**Compatibility and maintainability**

- R16. 变更必须保持 skill 目录自包含，不引入跨 skill 相对路径或绝对路径引用；如需要共享参考内容，应采用适合当前转换器和安装模型的方式。
- R17. 变更必须避免扩大 frontmatter `description` 字段来承载大量行为规则，因为 description 主要用于发现和触发，且跨平台转换存在长度和语义约束。
- R18. 变更必须保持 Claude、Codex、OpenCode、Gemini 等目标平台可转换；不能引入只在 Claude Code 生效、其他平台无降级路径的指令。
- R19. 如果实现修改 `plugins/galeharness-cli/` 的 skills、agents 或 README 中的用户可见行为，必须更新相关文档并运行插件一致性验证。

---

## Acceptance Examples

- AE1. **Covers R4, R5.** Given 用户在 `gh:brainstorm` 中提出“给 review 加一个新 agent 抓过度抽象”，when 代理探索需求，then 文档应先确认真实目标是减少无关复杂度，并记录“新增 agent”只是一个候选方案，不应直接成为需求。
- AE2. **Covers R7, R9.** Given planner 准备为 guardrails 新增共享 quality bar、fixtures 和多个 persona，when 这些复杂度没有明确 requirement 支撑，then plan 应要求说明依据或把它们降为 deferred follow-up。
- AE3. **Covers R10, R11, R12.** Given worker 执行一个小型 skill 文案改动，when 它准备顺手重排相邻章节或修改无关 wording，then guardrail 应阻止该改动，除非它直接服务于当前 requirement 或修复本次引入的问题。
- AE4. **Covers R13, R14, R15.** Given review 看到 PR 同时修改了 `gh:work` guardrail 和无关 README 段落，when 无关 README 修改没有 requirement 支撑，then review 应报告 diff hygiene 问题，并按是否需要人工判断选择 routing。
- AE5. **Covers R16, R18.** Given 实现想让多个 skills 引用同一个 `../shared/karpathy.md`，when 该引用会破坏 skill 自包含和跨平台转换，then plan 或 review 应阻止这种方案，并要求改用可移植方案。

---

## Success Criteria

- 用户在运行 `gh:brainstorm`、`gh:plan`、`gh:work`、`gh:review` 时能看到更明确的假设、边界和验证闭环，但不会在简单任务中被迫经历冗长流程。
- 后续 `gh:plan` 可以直接从本文档生成实施计划，不需要再发明“Karpathy guidelines 应该作用在哪些阶段、约束什么、不约束什么”。
- 实现后的技能内容能减少四类失败：错题、过度设计、跑偏实现、无关 diff。
- 相关变更能通过现有测试和 `bun run release:validate`，并保持 plugin conversion / installation 语义稳定。

---

## Scope Boundaries

- 不直接 vendor、fork 或同步 `forrestchang/andrej-karpathy-skills` 仓库。
- 不把外部 `CLAUDE.md` 原文追加到本仓库 `AGENTS.md` 或所有 skill prompt。
- 不新增默认主工作流中的独立 `karpathy-guidelines` 命令作为 v1 交付。
- 不在 v1 建完整 fixture suite 或大规模 reviewer prompt 重写；这些可作为后续质量加固。
- 不改变 `gh:` workflow 的阶段顺序，也不把 brainstorm/plan/work/review 合并成单一流程。
- 不要求所有任务都先提问或打印长 checklist；trivial 和已清晰任务必须保留快速路径。
- 不引入平台专属变量、绝对路径或跨 skill 目录引用。

---

## Key Decisions

- 将 Karpathy guidelines 作为全流程 guardrails，而不是单点 `gh:work` 改进：因为错误 framing 和过度设计往往在代码执行前已经发生。
- v1 覆盖 `gh:brainstorm`、`gh:plan`、`gh:work`、`gh:review` 四个阶段的最小规则：这样能形成闭环，同时避免共享体系和 fixtures 把首轮改造做重。
- 不新增独立默认 skill：因为用户不会自然记得在每次编码前手动调用；内嵌到现有高频 workflow 更有效。
- 保留 right-size 快速路径：Karpathy guidelines 的目标是减少高成本错误，不是把简单任务流程化。

---

## Dependencies / Assumptions

- 假设主要实现面会落在 `plugins/galeharness-cli/skills/gh-brainstorm/SKILL.md`、`plugins/galeharness-cli/skills/gh-plan/SKILL.md`、`plugins/galeharness-cli/skills/gh-work/SKILL.md`、`plugins/galeharness-cli/skills/gh-review/SKILL.md` 及必要的 co-located references；具体文件由 planning 阶段验证。
- 假设 `gh:review` 现有 always-on personas 和 synthesis pipeline 足以承载 diff hygiene，不需要 v1 新增 persona。
- 假设 README 或 plugin inventory 需要更新的程度取决于最终实现是否改变用户可见 workflow 行为。
- 假设外部仓库只作为灵感和问题分类来源，不作为运行时依赖或同步源。
- Planning 和 execution 阶段应打开 Source References 中的原版 Markdown，对照其四原则和示例进行转译；任何实现仍必须服从本仓库的 skill 自包含、跨平台转换和 right-size workflow 约束。

---

## Outstanding Questions

### Resolve Before Planning

- 无。

### Deferred to Planning

- [Affects R16, R18][Technical] 共享 guardrail 内容应内联到各 skill，还是放在 co-located reference 并由每个 skill 自包含复制一份？
- [Affects R13, R15][Technical] `gh:review` 的 diff hygiene 应放在 synthesis 阶段、`project-standards-reviewer`、`maintainability-reviewer`，还是组合使用？
- [Affects R19][Technical] 哪些 README、plugin manifest 或 release validation fixtures 需要随技能行为更新？

---

## Next Steps

-> /gh:plan docs/brainstorms/2026-04-24-karpathy-guidelines-integration-requirements.md
