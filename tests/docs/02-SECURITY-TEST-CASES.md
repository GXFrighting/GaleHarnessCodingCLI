# Security Test Cases - GaleHarnessCLI

**Category**: OWASP Security Testing
**Total Tests**: 15
**Priority**: P0-P1
**Target Coverage**: 90% (9/10 OWASP categories)

---

## TC-SEC-001: Command Injection in resolve-base.sh
**Priority**: P0
**OWASP**: A03: Injection
**Type**: Security

### Prerequisites
- GaleHarnessCLI repository cloned
- resolve-base.sh script exists

### Test Steps
1. Review resolve-base.sh for command execution
2. Identify user-controlled input to shell commands
3. Test with malicious input: `"; rm -rf /; "`
4. Verify input validation/sanitization

### Expected Results
- Input properly sanitized before shell execution
- No command injection vulnerability
- Special characters escaped or rejected

### Mitigation
- Use parameterized commands
- Input validation whitelist
- Avoid shell execution with user input

---

## TC-SEC-002: Path Traversal in Plugin Installation
**Priority**: P0
**OWASP**: A01: Broken Access Control
**Type**: Security

### Prerequisites
- GaleHarnessCLI installed

### Test Steps
1. Attempt install with path traversal: `../../../etc/passwd`
2. Check if installation path properly validated
3. Verify target directory restrictions

### Expected Results
- Path traversal blocked
- Installation restricted to allowed directories
- Error returned for invalid paths

---

## TC-SEC-003: File Permission on Installed Skills
**Priority**: P1
**OWASP**: A05: Security Misconfiguration
**Type**: Security

### Prerequisites
- GaleHarnessCLI installed

### Test Steps
1. Install plugin to target platform
2. Check file permissions on created files
3. Verify no world-writable files

### Expected Results
- Files created with proper permissions (644/755)
- No world-writable files (777)
- Sensitive files not readable by others

---

## TC-SEC-004: Dependency Vulnerability Audit
**Priority**: P1
**OWASP**: A06: Vulnerable Components
**Type**: Security

### Prerequisites
- GaleHarnessCLI installed
- npm/bun audit available

### Test Steps
1. Run `bun audit` or `npm audit`
2. Check for known vulnerabilities
3. Review dependency tree

### Expected Results
- No critical vulnerabilities
- No high severity vulnerabilities
- Dependencies up to date

---

## TC-SEC-005: Git Operation Safety in resolve-base.sh
**Priority**: P1
**OWASP**: A08: Data Integrity Failures
**Type**: Security

### Prerequisites
- GaleHarnessCLI repository

### Test Steps
1. Review git operations in resolve-base.sh
2. Check for unvalidated remote URLs
3. Verify git fetch/clone safety

### Expected Results
- Git remotes validated
- No arbitrary code execution via git
- Submodules disabled or validated

---

## TC-SEC-006: Temporary File Handling
**Priority**: P2
**OWASP**: A04: Insecure Design
**Type**: Security

### Prerequisites
- GaleHarnessCLI installed

### Test Steps
1. Check for temporary file creation
2. Verify secure temp directory usage
3. Test for race conditions

### Expected Results
- Uses secure temp directory (mktemp)
- Files cleaned up after use
- No predictable temp file names

---

## TC-SEC-007: Environment Variable Exposure
**Priority**: P2
**OWASP**: A05: Security Misconfiguration
**Type**: Security

### Prerequisites
- GaleHarnessCLI installed

### Test Steps
1. Check for sensitive env var logging
2. Review error messages
3. Verify no secrets in output

### Expected Results
- API keys not logged
- Secrets not in error messages
- Sensitive data masked in debug output

---

## TC-SEC-008: Plugin Content Validation
**Priority**: P1
**OWASP**: A03: Injection
**Type**: Security

### Prerequisites
- GaleHarnessCLI installed

### Test Steps
1. Create plugin with malicious skill content
2. Attempt conversion
3. Check if content validated

### Expected Results
- Malicious content detected/blocked
- No code execution during conversion
- Safe parsing of plugin files

---

## TC-SEC-009: Symlink Handling
**Priority**: P2
**OWASP**: A01: Broken Access Control
**Type**: Security

### Prerequisites
- GaleHarnessCLI installed

### Test Steps
1. Create symlinks in plugin directory
2. Run conversion/install
3. Check symlink handling

### Expected Results
- Symlinks handled safely
- No directory traversal via symlinks
- Proper error handling

---

## TC-SEC-010: Output Path Validation
**Priority**: P1
**OWASP**: A01: Broken Access Control
**Type**: Security

### Prerequisites
- GaleHarnessCLI installed

### Test Steps
1. Test conversion with various output paths
2. Check path validation
3. Verify restricted locations

### Expected Results
- Output paths validated
- System directories protected
- User home respected

---

## TC-SEC-011: JSON/YAML Parsing Safety
**Priority**: P2
**OWASP**: A03: Injection
**Type**: Security

### Prerequisites
- GaleHarnessCLI installed

### Test Steps
1. Test with malformed JSON/YAML
2. Check parser error handling
3. Verify no crashes/exploits

### Expected Results
- Safe parsing of untrusted input
- Proper error handling
- No prototype pollution

---

## TC-SEC-012: Regex Denial of Service
**Priority**: P2
**OWASP**: A04: Insecure Design
**Type**: Security

### Prerequisites
- GaleHarnessCLI installed

### Test Steps
1. Identify regex patterns in code
2. Test with ReDoS payloads
3. Check for catastrophic backtracking

### Expected Results
- No ReDoS vulnerabilities
- Regex patterns bounded
- Input length limits

---

## TC-SEC-013: Plugin Marketplace Validation
**Priority**: P1
**OWASP**: A06: Vulnerable Components
**Type**: Security

### Prerequisites
- Marketplace JSON exists

### Test Steps
1. Review marketplace.json schema
2. Check plugin validation
3. Verify download URL safety

### Expected Results
- URLs validated (HTTPS)
- Checksums verified
- No arbitrary download sources

---

## TC-SEC-014: Skill Content Sanitization
**Priority**: P2
**OWASP**: A03: Injection
**Type**: Security

### Prerequisites
- GaleHarnessCLI installed

### Test Steps
1. Create skill with script injection
2. Convert to target platform
3. Check output sanitization

### Expected Results
- Script tags escaped
- No XSS in converted output
- Safe content transfer

---

## TC-SEC-015: Configuration File Permissions
**Priority**: P2
**OWASP**: A05: Security Misconfiguration
**Type**: Security

### Prerequisites
- GaleHarnessCLI installed

### Test Steps
1. Check config file permissions
2. Review .gitignore for secrets
3. Verify sensitive file handling

### Expected Results
- Config files not world-readable
- Secrets in .gitignore
- No hardcoded credentials

---

**End of Security Test Cases**
