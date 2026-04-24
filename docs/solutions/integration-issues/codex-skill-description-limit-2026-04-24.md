---
title: "Codex copied skill descriptions must be truncated at install time"
date: 2026-04-24
category: integration-issues
module: src/utils/codex-content.ts
problem_type: integration_issue
component: tooling
symptoms:
  - "Copied Codex skills could preserve upstream descriptions longer than Codex's 1024-character frontmatter limit"
  - "Generated Codex skills already handled description limits, but pass-through skill directories did not"
  - "The writer transformed copied skill bodies without normalizing their YAML frontmatter"
root_cause: config_error
resolution_type: code_fix
severity: medium
related_components:
  - src/targets/codex.ts
  - tests/codex-writer.test.ts
tags:
  - codex
  - frontmatter
  - skill-description
  - converter
  - target-writer
---

# Codex copied skill descriptions must be truncated at install time

## Problem

Codex skills accept only a small frontmatter surface, and `description` has a 1024-character limit. The converter already truncated descriptions for generated Codex skills, but copied skill directories kept their original `SKILL.md` frontmatter, so long upstream descriptions could produce invalid Codex output during install or conversion.

## Symptoms

- `writeCodexBundle` copied a skill directory and transformed invocation syntax in the body, but left an overlong `description` unchanged.
- The failure affected pass-through skills such as `proof`, where the source skill owns its own `SKILL.md`.
- The behavior was asymmetric: generated skills were safe, copied skills were not.

## What Didn't Work

- **Only transforming the body**: copied skill content already passed through `transformContentForCodex`, but the function treated the input as plain body text. That preserved invalid frontmatter even though the same file's body was being rewritten for Codex.
- **Relying on generated-skill truncation**: generated skills and copied skill directories travel through different paths. Fixing only generated metadata does not protect pass-through `SKILL.md` files.
- **Dropping the description entirely**: this would avoid the limit but lose useful activation text. Truncating keeps the field useful while satisfying Codex's constraint.

## Solution

Make `transformContentForCodex` frontmatter-aware. When the content starts with YAML frontmatter, parse it, transform only the body text as before, then truncate `description` before formatting the frontmatter back onto the transformed body.

```typescript
const CODEX_DESCRIPTION_MAX_LENGTH = 1024

export function transformContentForCodex(
  content: string,
  targets?: CodexInvocationTargets,
  options: CodexTransformOptions = {},
): string {
  const hasFrontmatter = content.startsWith("---\n") || content.startsWith("---\r\n")
  const parsed = hasFrontmatter ? parseFrontmatter(content) : null

  let result = parsed ? parsed.body : content

  // Existing Codex body rewrites still run here:
  // Task calls, slash references, .claude paths, and @agent refs.

  if (!parsed) {
    return result
  }

  const frontmatter = { ...parsed.data }
  if (typeof frontmatter.description === "string") {
    frontmatter.description = truncateCodexDescription(frontmatter.description)
  }

  return formatFrontmatter(frontmatter, result)
}
```

The truncation helper reserves 3 characters for an ellipsis and trims trailing whitespace before appending it:

```typescript
function truncateCodexDescription(description: string): string {
  if (description.length <= CODEX_DESCRIPTION_MAX_LENGTH) {
    return description
  }

  return `${description.slice(0, CODEX_DESCRIPTION_MAX_LENGTH - 3).trimEnd()}...`
}
```

The regression test writes a copied skill with an 1100-character description, runs `writeCodexBundle`, parses the installed `.codex/skills/proof/SKILL.md`, and asserts that:

- the installed `description` length is at most 1024 characters
- the body content is still present after frontmatter parsing and reformatting

## Why This Works

Copied skill directories are the boundary where source-platform metadata enters Codex unchanged. Moving the truncation into `transformContentForCodex` protects every copied `SKILL.md` that already flows through the Codex body transformer, instead of requiring each writer call site to remember a separate metadata cleanup step.

The fix also keeps concerns aligned:

| Concern | Location |
|---|---|
| Codex invocation/body rewrites | `transformContentForCodex` |
| Codex copied skill frontmatter normalization | `transformContentForCodex` |
| Bundle filesystem writes | `writeCodexBundle` |

That matters because the writer's job is to copy and place files, while the transformer owns Codex compatibility.

## Prevention

- When a target platform has frontmatter limits, enforce them at the conversion boundary that handles copied files, not only when synthesizing generated skills.
- Regression tests should exercise copied skill directories, because generated skill tests do not cover pass-through `SKILL.md` behavior.
- Preserve the body during metadata normalization. Any fix that parses frontmatter should assert that transformed body content still survives.
- Treat target-platform constraints as output contracts. If Codex changes accepted frontmatter fields or limits, update both generated-skill and copied-skill paths together.

## Related Issues

- PR: https://github.com/wangrenzhu-ola/GaleHarnessCodingCLI/pull/53
- `docs/solutions/integrations/cross-platform-model-field-normalization-2026-03-29.md` — related Codex frontmatter constraint: Codex skills support only `name` and `description`, not `model`.
- `docs/solutions/integrations/colon-namespaced-names-break-windows-paths-2026-03-26.md` — related boundary-normalization pattern for target writers.
