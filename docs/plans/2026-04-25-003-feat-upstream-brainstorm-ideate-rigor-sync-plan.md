---
title: "feat: 融合 upstream brainstorm/ideate 严谨性改进"
type: feat
status: active
date: 2026-04-25
origin: docs/brainstorms/2026-04-25-upstream-brainstorm-ideate-rigor-sync-requirements.md
---

# feat: 融合 upstream brainstorm/ideate 严谨性改进

## Overview

本计划从 upstream `EveryInc/compound-engineering-plugin` 的四个 commit 中吸收 brainstorm/ideate 的严谨性改进，但不机械套 patch。实现应以本地 PR #66 / commit `a277942` 的 Karpathy guardrails 为底座，保留 GaleHarnessCLI 的 HKTMemory、Gale knowledge、`gh:` 命名、document-review handoff、跨平台转换约束。

本轮计划只覆盖 `gh:brainstorm` 和 `gh:ideate` 相关改进。明确排除 `test-browser`、`lfg`、release-only、demo-reel、proof、release version/changelog，以及 upstream 非本轮语义。

后续执行顺序必须是：先对本计划运行 `document-review`，再进入 `gh:work` 实现。不要跳过 document-review。

---

## Problem Frame

当前本地 `gh:brainstorm` 已有 Karpathy guardrails：挑战 framing、区分 explicit assumptions/non-goals/success criteria、避免把 unconfirmed implementation proposal 写成 requirement。`gh:plan`、`gh:work`、`gh:review` 也已有 complexity justification、execution contract、surgical-change、diff hygiene 的 contract tests。

upstream 新增的价值主要在两个方向：

- `ce-brainstorm` 把抽象的 pressure test 变成更可执行的 rigor gap lenses，并修复 universal brainstorming 绕过 Interaction Rules 的问题。
- `ce-ideate` 明确 subject gate、surprise-me、issue intent、warrant contract，解决 vague prompt 发散和 plausible-but-unsupported idea survivor 的问题。

风险在于 upstream 文件结构、命名、Proof/Every references、agent dispatch、web research 和保存流程与 GaleHarnessCLI 不一致。正确做法是只吸收语义，不替换本地 skill。

---

## Requirements Trace

- R1-R4. 手工融合、保留 PR #66 Karpathy guardrails、保留 Gale/HKT 补丁、保持 right-size。
- R5-R8. Brainstorm universal flow 继承 Interaction Rules；Phase 2 前扫描并 prose-probe evidence/specificity/counterfactual/attachment/durability gaps；结果落入现有 requirements 结构。
- R9-R13. Ideate 先 subject gate 再 mode classification；surprise-me 一等模式；issue-tracker intent 收窄；survivors 必须有 articulated warrant；ideation 仍 hand off 到 `gh:brainstorm`。
- R14-R17. 不碰排除范围，不引入平台专属或跨目录引用，补充 tests，运行 `bun test` 和 `bun run release:validate`。

**Origin:** `docs/brainstorms/2026-04-25-upstream-brainstorm-ideate-rigor-sync-requirements.md`

---

## Scope Boundaries

- 不修改 `test-browser`、`lfg`、release-only、release-owned version/changelog。
- 不整文件替换 `plugins/galeharness-cli/skills/gh-brainstorm/SKILL.md` 或 `plugins/galeharness-cli/skills/gh-ideate/SKILL.md`。
- 不引入 upstream `ce:` 命名、Every-specific authoring refs、Proof workflow 重构、demo-reel/proof 非目标改动。
- 不弱化 PR #66 已有 guardrails 和 tests。
- 不新增独立 `karpathy` skill，不改变 `ideate -> brainstorm -> plan -> work` 主链路。

---

## Context & Research

### Upstream Semantics to Absorb

- `494313e`:
  - Parent Interaction Rules apply to universal brainstorming.
  - Universal reference must not relax one-question-per-turn or blocking question tool rules.
  - Numbered overflow should preserve free-form input when blocking tool cannot be used.

- `304a975`:
  - Phase 1.2 should scan for rigor gaps before approaches.
  - Standard gaps: evidence, specificity, counterfactual, attachment.
  - Deep-product extra gap: durability.
  - Probes are agent-internal and selective; only actual gaps fire.
  - Rigor probes are prose, one gap per probe, before Phase 2.
  - Attachment probe is final before Phase 2 when attachment gap exists.

- `6514b1f`:
  - `ce-ideate` adds subject-identification gate before mode classification.
  - “Surprise me” becomes first-class mode.
  - Elsewhere context-substance gate prevents no-substance dispatch.
  - Tactical scope lowers ambition floor.
  - Warrant contract requires direct/external/reasoned basis.
  - Survivors must pass meeting-test unless tactical focus waived it.
  - Artifact template includes warrant and rationale.

- `f0433d9`:
  - Issue-tracker intent requires explicit tracker/report phrasing.
  - `bug in auth` / `top 3 bugs in authentication` remain regular ideation focus.
  - Surprise-me routing is deterministic: repo CWD uses repo-grounded; no-repo uses elsewhere-software and requires substance.
  - Drops some authoring refs; this reinforces not importing upstream AGENTS/plugin authoring wording mechanically.

### Local Constraints to Preserve

- PR #66 / `a277942`:
  - `gh:brainstorm` already has `Challenge framing before committing` and `Separate decisions from guesses`.
  - `requirements-capture.md` already distinguishes confirmed requirements, non-goals, assumptions, success criteria.
  - `gh:plan` already has `Justify complexity from source material` and `Complexity justification gate`.
  - `gh:work` and `gh:work-beta` already share execution contract and surgical-change rules.
  - `gh:review` and reviewers already cover diff hygiene.
  - Tests in `tests/pipeline-review-contract.test.ts` and `tests/review-skill-contract.test.ts` lock these anchors.

- HKT/Gale patches:
  - `gh:brainstorm` and `gh:ideate` include `gale-task` lifecycle and HKTMemory retrieve/store sections.
  - `gh:brainstorm` uses `gale-knowledge resolve-path` and knowledge commit behavior.
  - Agent references must use `galeharness-cli:<agent-name>`.

- Repo standards:
  - Skill files must be self-contained; no cross-skill references by relative traversal or absolute path.
  - File references in generated docs must be repo-relative.
  - Do not hand-bump release-owned versions or changelog.
  - Plugin behavior changes require tests and `bun run release:validate`.

---

## Key Technical Decisions

- **D1. Treat upstream as semantic input, not patch source.** Implementation should inspect upstream snippets while editing, but write text in local `gh:` voice and keep local HKT/Gale sections intact.
- **D2. Brainstorm changes stay narrow.** Add explicit universal Interaction Rules inheritance and refine Phase 1.2 rigor gap lenses; do not restructure Phase 0-4.
- **D3. Ideate gets a targeted Phase 0 rewrite, not upstream full transplant.** Add subject-identification gate, surprise-me routing, issue-intent sharpening, context-substance gate where needed, and tactical scope detection while preserving local HKT and current simpler repo-grounded flow unless a specific unit expands it.
- **D4. Warrant contract belongs in both generation and filtering.** `gh-ideate/SKILL.md` should require candidates to carry warrant; `post-ideation-workflow.md` should reject weak warrant and write warrant to artifact.
- **D5. Tests should lock behavior anchors, not whole prose.** Add stable phrase assertions for subject gate, surprise-me, issue intent, rigor gap probes, warrant contract, and preservation of Karpathy/HKT anchors.
- **D6. Plan quality gate remains document-review before work.** After this plan, run `document-review` on the plan, address P0/P1 findings, then invoke `gh:work`.

---

## Implementation Units

### U1. Strengthen `gh:brainstorm` Interaction Rules and universal flow

**Goal:** Ensure universal brainstorming follows the same parent Interaction Rules as software brainstorming.

**Requirements:** R1-R5, R14-R16; F1; AE1.

**Files:**
- Modify: `plugins/galeharness-cli/skills/gh-brainstorm/SKILL.md`
- Modify: `plugins/galeharness-cli/skills/gh-brainstorm/references/universal-brainstorming.md`
- Test: `tests/pipeline-review-contract.test.ts`

**Approach:**
- In `gh-brainstorm/SKILL.md`, add concise wording that Interaction Rules apply to every brainstorm, including universal flow.
- Adapt upstream's blocking-tool/prose distinction, but keep current platform list and local style.
- In `universal-brainstorming.md`, state it extends parent rules and does not relax them.
- Preserve existing HKT, Gale knowledge, document-review handoff, and Karpathy guardrail text.

**Test scenarios:**
- Assert `gh-brainstorm/SKILL.md` says universal flow still follows Interaction Rules.
- Assert `universal-brainstorming.md` contains parent-rule inheritance and one-question-per-turn/blocking question anchors.
- Assert existing PR #66 anchors still exist: `Challenge framing before committing`, `explicit assumptions, non-goals, and success criteria`, `without bulldozing their intent`.

---

### U2. Add brainstorm rigor gap probes before approaches

**Goal:** Make Phase 1.2 pressure testing more actionable without turning brainstorm into a fixed questionnaire.

**Requirements:** R1-R8, R14-R17; F2; AE2.

**Files:**
- Modify: `plugins/galeharness-cli/skills/gh-brainstorm/SKILL.md`
- Modify as needed: `plugins/galeharness-cli/skills/gh-brainstorm/references/requirements-capture.md`
- Test: `tests/pipeline-review-contract.test.ts`

**Approach:**
- Refine Phase 1.2 to scan for evidence, specificity, counterfactual, attachment; Deep-product adds durability.
- State that these are agent-internal lenses, not a user-facing checklist.
- State that probes fire selectively as prose, one gap per probe, before Phase 2.
- Ensure probe answers map to existing assumptions/non-goals/success criteria/scope/deferred planning structures.
- Keep the PR #66 separation of confirmed requirements vs unconfirmed implementation proposals.

**Test scenarios:**
- Assert `gh-brainstorm/SKILL.md` mentions evidence, specificity, counterfactual, attachment, durability.
- Assert it says probes are selective/prose and before Phase 2.
- Assert `requirements-capture.md` still requires assumptions/non-goals/success criteria and prevents unconfirmed implementation proposals from becoming requirements.

---

### U3. Add `gh:ideate` subject gate, surprise-me, and issue intent sharpening

**Goal:** Prevent vague ideation prompts from dispatching scattered agents, and make surprise-me / issue analysis routing deterministic.

**Requirements:** R1-R4, R9-R11, R14-R17; F3; AE3, AE4, AE6.

**Files:**
- Modify: `plugins/galeharness-cli/skills/gh-ideate/SKILL.md`
- Test: `tests/pipeline-review-contract.test.ts` or new `tests/ideate-skill-contract.test.ts`

**Approach:**
- Add Phase 0 subject-identification gate before current focus/volume interpretation.
- Define identifiable vs vague subjects by what the words refer to, not phrase length.
- Add scope question with “Specify subject”, “Surprise me”, “Cancel”.
- Make surprise-me deterministic: in repo CWD, repo supplies substance; outside repo, require URL/description/draft/paste before dispatch.
- Narrow issue-tracker intent to explicit tracker/report phrases and explicitly exclude bug focus prompts.
- Add tactical scope detection (`quick wins`, `polish`, `typos`, `small fixes`) for later meeting-test waiver.
- Keep HKTMemory retrieve/store sections and `galeharness-cli:` agent names.

**Test scenarios:**
- Assert `gh-ideate/SKILL.md` contains subject-identification gate before mode/focus dispatch.
- Assert it treats “Surprise me” as first-class and deterministic.
- Assert it excludes `top 3 bugs in authentication` from issue-tracker intent.
- Assert existing HKTMemory retrieve/store anchors remain.

---

### U4. Add `gh:ideate` warrant contract and artifact support

**Goal:** Ensure surviving ideas are grounded by inspectable warrant and can hand off cleanly to `gh:brainstorm`.

**Requirements:** R1-R4, R12-R17; F4; AE5, AE6.

**Files:**
- Modify: `plugins/galeharness-cli/skills/gh-ideate/SKILL.md`
- Modify: `plugins/galeharness-cli/skills/gh-ideate/references/post-ideation-workflow.md`
- Consider add only if needed: `plugins/galeharness-cli/skills/gh-ideate/references/universal-ideation.md`
- Test: `tests/pipeline-review-contract.test.ts` or new `tests/ideate-skill-contract.test.ts`

**Approach:**
- In Phase 2 candidate structure, require warrant tagged `direct:`, `external:`, or `reasoned:`.
- In filtering, reject candidates with missing warrant, warrant that does not support the move, or subject replacement.
- Add meeting-test floor by default, waived for tactical scope signals.
- Update artifact template to include `Warrant` and `Rationale`.
- Keep post-ideation handoff to `gh:brainstorm`; do not allow direct plan/work.

**Test scenarios:**
- Assert Phase 2 asks for `direct:`, `external:`, `reasoned:` warrant.
- Assert filtering rejects unsupported warrant and subject replacement.
- Assert artifact template includes `**Warrant:**`.
- Assert `post-ideation-workflow.md` still routes selected ideas to `gh:brainstorm`, not `gh:plan` or `gh:work`.

---

### U5. Validate preservation of local guardrails and plugin consistency

**Goal:** Catch accidental overwrite of PR #66 guardrails or HKT/Gale patches while implementing upstream-derived edits.

**Requirements:** R1-R4, R14-R17; AE6.

**Files:**
- Modify tests only as needed:
  - `tests/pipeline-review-contract.test.ts`
  - `tests/review-skill-contract.test.ts` only if touched by preservation assertions

**Approach:**
- Add preservation assertions for PR #66 anchors in brainstorm/plan/work/review where current tests already cover them.
- Add ideate-specific contract tests for HKTMemory anchors and handoff boundaries.
- Avoid brittle whole-paragraph snapshots.

**Test scenarios:**
- `bun test tests/pipeline-review-contract.test.ts`
- `bun test tests/review-skill-contract.test.ts` if touched.
- Full `bun test`.
- `bun run release:validate`.

---

## Sequencing

1. Run `document-review` on this plan and address P0/P1 findings before implementation.
2. Implement U1 and U2 together, because both touch `gh-brainstorm/SKILL.md`.
3. Implement U3 before U4, because warrant handling depends on subject/mode clarity.
4. Implement U5 tests throughout, not after all prose edits.
5. Run focused tests, then full `bun test`, then `bun run release:validate`.
6. Only after review and tests pass should `gh:work` final output recommend commit/PR.

---

## Testing Strategy

- **Prompt contract tests:** Extend `tests/pipeline-review-contract.test.ts` or create `tests/ideate-skill-contract.test.ts` with stable phrase assertions for the new anchors.
- **Preservation tests:** Keep existing PR #66 Karpathy tests green; add assertions that HKTMemory retrieve/store and `gh:` / `galeharness-cli:` names remain.
- **Regression tests:** Run `bun test tests/pipeline-review-contract.test.ts` after skill edits.
- **Full suite:** Run `bun test` because plugin prompt changes can affect converter/writer expectations.
- **Plugin consistency:** Run `bun run release:validate` because plugin skill behavior and inventory-adjacent docs may be affected.
- **No runtime implementation tests needed:** This plan changes workflow prompt contracts, not TypeScript conversion logic, unless implementation discovers converter output changed.

---

## Risks

- **Prompt bloat:** upstream prose is long; copying it directly could make skills harder to follow. Mitigation: keep behavior anchors concise and move only necessary template changes into references.
- **Guardrail conflict:** new probes could duplicate PR #66 framing guardrails. Mitigation: phrase them as operational lenses under the existing challenge-framing principle.
- **Over-questioning:** rigor probes and subject gate could slow trivial tasks. Mitigation: selective gaps only, right-size rule preserved, “Surprise me” stays first-class.
- **Scope creep from upstream ideate:** upstream also changes web research, Proof, elsewhere modes, caches, and AGENTS wording. Mitigation: explicitly exclude non-rigor workflow rewrites from this plan.
- **Test brittleness:** prompt contract tests can overfit wording. Mitigation: assert short stable anchors, not paragraphs.
- **HKT/Gale regression:** mechanical merge could delete HKTMemory or Gale knowledge sections. Mitigation: preservation tests plus manual review of HKT/Gale anchors.

---

## Open Questions

### Resolved During Planning

- Should upstream patches be applied mechanically? No. Use semantic, manual three-way fusion only.
- Should `test-browser`, `lfg`, release-only files be included? No.
- Should PR #66 Karpathy guardrails be overwritten or reorganized? No; they are constraints to preserve.
- Should plan flow go directly to work? No; run `document-review` first, then `gh:work`.

### Deferred to Implementation

- Whether `gh:ideate` needs a new `references/universal-ideation.md` now, or whether this round can keep non-software ideation out of scope.
- Whether ideate tests stay in `tests/pipeline-review-contract.test.ts` or move to a dedicated test file for readability.
- Exact wording of prose probes and warrant instructions, tuned to surrounding local prompt style.

---

## Handoff

Next required step:

1. Run `document-review docs/plans/2026-04-25-003-feat-upstream-brainstorm-ideate-rigor-sync-plan.md`.
2. Address any P0/P1 findings.
3. Then run `gh:work docs/plans/2026-04-25-003-feat-upstream-brainstorm-ideate-rigor-sync-plan.md`.

Do not implement before document-review.
