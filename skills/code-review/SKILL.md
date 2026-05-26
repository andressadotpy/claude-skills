---
name: code-review
description: Perform a thorough code review of the current changes or specified files. Checks for correctness, security issues, performance, readability, and adherence to best practices. Use when you want a detailed review before merging, submitting a PR, or finalizing implementation.
version: 1.0.0
user-invocable: true
argument-hint: "[file or directory to review]"
---

# Code Review

Perform a thorough, structured code review focused on correctness, security, maintainability, and best practices.

## Step 1: Understand the Context

Before reviewing, gather context:
- What is this code doing? What problem does it solve?
- Is this a new feature, a bug fix, a refactor, or performance improvement?
- What is the technology stack in use?
- Are there existing tests or documentation to cross-check against?

If reviewing a diff or PR, focus only on the changed lines unless a broader change clearly affects surrounding code.

## Step 2: Review Checklist

Systematically check each category below. Flag every issue with a severity tag.

**Severity levels:**
- **P0 Blocker**: Must fix before merging — crashes, data loss, security vulnerabilities, broken core logic
- **P1 Major**: Significant defect or risk — likely bugs, missing error handling, major performance issues
- **P2 Minor**: Worth fixing — code smells, unclear naming, suboptimal patterns, missing tests
- **P3 Nit**: Optional polish — style inconsistencies, minor naming preferences, cosmetic issues

### Correctness
- Does the code do what it's supposed to do?
- Are edge cases handled? (empty inputs, nulls, boundary values, concurrent access)
- Are error conditions handled gracefully? Do errors propagate correctly?
- Are return values and side effects consistent with expectations?
- Is mutable state managed safely?

### Security
- Is user input validated and sanitized before use?
- Are there SQL injection, XSS, SSRF, or path traversal risks?
- Are secrets or sensitive data ever logged or exposed?
- Is authentication/authorization applied where needed?
- Are dependencies using known-vulnerable versions?
- Is cryptography used correctly (never roll your own crypto)?

### Performance
- Are there N+1 query patterns or unnecessary database calls in loops?
- Are expensive operations (network calls, heavy computation) cached where appropriate?
- Are large collections iterated efficiently?
- Are resources (connections, file handles, memory) properly released?

### Readability & Maintainability
- Is the code self-explanatory, or are complex parts documented?
- Are variable and function names descriptive and consistent with the codebase?
- Are functions doing one thing (single responsibility)?
- Is there repeated logic that should be extracted into a shared helper?
- Is dead code present (unreachable branches, unused variables)?

### Tests
- Are new behaviors covered by tests?
- Do existing tests still pass with these changes?
- Are edge cases and failure paths tested?
- Are test assertions meaningful (not just "no exception thrown")?

### API & Interface Design
- Are public APIs backward-compatible, or is a breaking change documented?
- Are function signatures clear and minimal?
- Are types used correctly and precisely (avoid `any`, overly broad types)?

## Step 3: Generate the Review Report

Structure the output as follows:

---

### Summary

A 2-3 sentence summary of what the code does and your overall impression.

**Overall verdict:** ✅ Approve / ⚠️ Approve with suggestions / ❌ Request changes

---

### Issues Found

List every issue in priority order (P0 first). For each:

```
**[P?] Short title**
- **Location:** `file.py:42` or component/function name
- **Issue:** What is wrong and why it matters
- **Suggestion:** How to fix it (include a short code snippet if helpful)
```

If there are no issues in a category, skip it.

---

### Positive Observations

Call out 2-5 things done well. Good code deserves acknowledgment and reinforces patterns worth keeping.

---

### Summary Table

| Severity | Count |
|----------|-------|
| P0 Blocker | ? |
| P1 Major | ? |
| P2 Minor | ? |
| P3 Nit | ? |
| **Total** | **?** |

---

## Step 4: Follow-up

After presenting the review:
- If there are P0/P1 issues, offer to help fix them.
- If the review is clean, confirm it is ready to merge/submit.
- If asked to re-review after fixes, repeat the checklist on the updated code only.

**NEVER:**
- Give vague feedback without actionable suggestions ("this could be better")
- Only flag problems — always acknowledge what works
- Miss security issues (treat these as P0/P1 by default)
- Be pedantic about style when no style guide exists
- Request changes for P3 nits unless explicitly asked
