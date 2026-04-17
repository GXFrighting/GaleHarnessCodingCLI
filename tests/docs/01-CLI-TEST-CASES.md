# CLI Test Cases - GaleHarnessCLI

**Category**: CLI Functionality
**Total Tests**: 20
**Priority**: P0-P2

---

## TC-CLI-001: Plugin List Command
**Priority**: P0
**Type**: Functional

### Prerequisites
- GaleHarnessCLI installed
- Bun runtime available

### Test Steps
1. Run `bun run src/index.ts list`
2. Verify output contains plugin list
3. Check that galeharness-cli is listed

### Expected Results
- Command executes without error
- Plugin list displayed with names and descriptions
- Exit code 0

---

## TC-CLI-002: Plugin Convert to OpenCode
**Priority**: P0
**Type**: Functional

### Prerequisites
- GaleHarnessCLI installed
- plugins/galeharness-cli/ exists

### Test Steps
1. Run `bun run src/index.ts convert ./plugins/galeharness-cli --to opencode`
2. Verify output directory created
3. Check converted files exist

### Expected Results
- Conversion completes successfully
- opencode.json and .opencode/ directory created
- Skills and agents properly converted

---

## TC-CLI-003: Plugin Convert to Codex
**Priority**: P0
**Type**: Functional

### Prerequisites
- GaleHarnessCLI installed
- plugins/galeharness-cli/ exists

### Test Steps
1. Run `bun run src/index.ts convert ./plugins/galeharness-cli --to codex`
2. Verify prompts and skills directories created
3. Check converted skill format

### Expected Results
- Conversion completes successfully
- ~/.codex/prompts/ and ~/.codex/skills/ populated
- Proper frontmatter in skill files

---

## TC-CLI-004: Release Validation
**Priority**: P0
**Type**: Functional

### Prerequisites
- GaleHarnessCLI installed
- All dependencies installed

### Test Steps
1. Run `bun run release:validate`
2. Verify plugin consistency checks pass
3. Check marketplace.json validity

### Expected Results
- Validation completes without errors
- Plugin and marketplace consistency verified
- Exit code 0

---

## TC-CLI-005: Test Suite Execution
**Priority**: P0
**Type**: Regression

### Prerequisites
- GaleHarnessCLI installed
- bun dependencies installed

### Test Steps
1. Run `bun test`
2. Wait for all tests to complete
3. Check pass/fail counts

### Expected Results
- 658+ tests pass
- 3 or fewer known failures (resolve-base.sh timeouts)
- Exit code 0 (despite some failures)

---

## TC-CLI-006: Cross-Platform Converter - Gemini
**Priority**: P1
**Type**: Compatibility

### Prerequisites
- GaleHarnessCLI installed

### Test Steps
1. Run `bun run src/index.ts convert ./plugins/galeharness-cli --to gemini`
2. Verify .gemini/ directory structure
3. Check skill format compliance

### Expected Results
- Gemini format conversion successful
- .gemini/skills/ populated
- TOML frontmatter correct

---

## TC-CLI-007: Cross-Platform Converter - Copilot
**Priority**: P1
**Type**: Compatibility

### Prerequisites
- GaleHarnessCLI installed

### Test Steps
1. Run `bun run src/index.ts convert ./plugins/galeharness-cli --to copilot`
2. Verify .github/ directory created
3. Check agent.md format

### Expected Results
- Copilot format conversion successful
- .github/ agents created with proper frontmatter
- Commands converted to prompts

---

## TC-CLI-008: Sync Command
**Priority**: P1
**Type**: Functional

### Prerequisites
- GaleHarnessCLI installed
- ~/.claude/ config exists

### Test Steps
1. Run `bun run src/index.ts sync --dry-run`
2. Verify sync preview displayed
3. Check target platforms listed

### Expected Results
- Sync preview shows correctly
- Detected platforms listed
- No errors in dry-run mode

---

## TC-CLI-009: Plugin Path Resolution
**Priority**: P1
**Type**: Functional

### Prerequisites
- GaleHarnessCLI installed

### Test Steps
1. Run `bun run src/index.ts plugin-path galeharness-cli`
2. Verify path returned
3. Check path exists

### Expected Results
- Plugin path correctly resolved
- Path points to plugins/galeharness-cli/
- Exit code 0

---

## TC-CLI-010: Help Command
**Priority**: P2
**Type**: Usability

### Prerequisites
- GaleHarnessCLI installed

### Test Steps
1. Run `bun run src/index.ts --help`
2. Verify all commands listed
3. Check descriptions clear

### Expected Results
- Help text displayed
- All subcommands documented
- Usage examples provided

---

## TC-CLI-011: Invalid Platform Error Handling
**Priority**: P1
**Type**: Error Handling

### Prerequisites
- GaleHarnessCLI installed

### Test Steps
1. Run `bun run src/index.ts convert ./plugins/galeharness-cli --to invalid-platform`
2. Verify error message
3. Check exit code

### Expected Results
- Clear error message about invalid platform
- Exit code non-zero
- Suggested valid platforms listed

---

## TC-CLI-012: Missing Plugin Directory
**Priority**: P1
**Type**: Error Handling

### Prerequisites
- GaleHarnessCLI installed

### Test Steps
1. Run `bun run src/index.ts convert ./nonexistent --to opencode`
2. Verify error message
3. Check exit code

### Expected Results
- Error about missing directory
- Exit code non-zero
- Helpful suggestion provided

---

## TC-CLI-013: Install Command - Claude
**Priority**: P1
**Type**: Integration

### Prerequisites
- GaleHarnessCLI installed
- Claude Code installed (optional)

### Test Steps
1. Run `bun run src/index.ts install ./plugins/galeharness-cli --to claude --dry-run`
2. Verify installation preview
3. Check target paths

### Expected Results
- Installation preview displayed
- Target paths correct
- No errors in dry-run

---

## TC-CLI-014: Converter Preserves Skill Content
**Priority**: P0
**Type**: Data Integrity

### Prerequisites
- GaleHarnessCLI installed

### Test Steps
1. Convert plugin to multiple formats
2. Compare skill content across formats
3. Verify no data loss

### Expected Results
- Skill instructions preserved
- Agent references maintained
- No truncation or corruption

---

## TC-CLI-015: Namespace Agent References
**Priority**: P1
**Type**: Functional

### Prerequisites
- GaleHarnessCLI installed

### Test Steps
1. Check skill files for agent references
2. Verify FQ names (galeharness-cli:category:agent)
3. Convert and verify references handled

### Expected Results
- FQ agent names preserved in conversion
- Short names not used in skills
- References work after conversion

---

## TC-CLI-016: MCP Server Configuration
**Priority**: P2
**Type**: Configuration

### Prerequisites
- GaleHarnessCLI installed

### Test Steps
1. Check plugin.json for MCP servers
2. Convert to target platform
3. Verify MCP config preserved

### Expected Results
- MCP server definitions preserved
- Proper format for target platform
- No configuration loss

---

## TC-CLI-017: Release Please Config Validation
**Priority**: P1
**Type**: Configuration

### Prerequisites
- GaleHarnessCLI installed

### Test Steps
1. Check release-please-config.json
2. Verify linked-versions configuration
3. Validate component paths

### Expected Results
- Config valid JSON
- All components defined
- Paths correct

---

## TC-CLI-018: Marketplace JSON Generation
**Priority**: P1
**Type**: Functional

### Prerequisites
- GaleHarnessCLI installed

### Test Steps
1. Check .claude-plugin/marketplace.json
2. Verify plugin metadata
3. Validate JSON schema

### Expected Results
- Valid JSON
- All required fields present
- Version matches package.json

---

## TC-CLI-019: Multi-Target Conversion
**Priority**: P2
**Type**: Functional

### Prerequisites
- GaleHarnessCLI installed

### Test Steps
1. Run conversion with --also flag
2. Verify multiple targets created
3. Check each target format

### Expected Results
- Primary target created
- Additional targets created
- All formats valid

---

## TC-CLI-020: Tool Detection
**Priority**: P2
**Type**: Functional

### Prerequisites
- GaleHarnessCLI installed

### Test Steps
1. Run tool detection logic
2. Verify detected tools list
3. Check accuracy

### Expected Results
- Installed tools detected
- No false positives
- Missing tools reported

---

**End of CLI Test Cases**
