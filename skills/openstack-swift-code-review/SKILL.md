---
name: openstack-swift-code-review
description: Perform a thorough code review for OpenStack Swift Gerrit patches. Inherits OpenStack/OpenInfra policies from openstack-engineer and Swift-specific guidelines from openstack-swift-engineer. Uses empathic commenting framework (Questions, Preferences, Suggestions, Conventions, Requirements).
version: 2.0.0
user-invocable: true
argument-hint: "[Gerrit change number or URL]"
inherits: 
  - openstack-engineer
  - openstack-swift-engineer
permission_hints:
  - tool: Bash
    patterns:
      - "curl.*review.opendev.org.*"
      - "curl.*https://review.opendev.org/changes/.*"
  - tool: WebFetch
    patterns:
      - "https://review.opendev.org/.*"
---

# OpenStack Swift Code Review (Gerrit)

Perform a thorough, empathic code review for OpenStack Swift patches on Gerrit.

**CRITICAL INSTRUCTIONS FOR CLAUDE**:

1. **INTERACTIVE MODE**: This skill uses a **step-by-step, checkpoint-based** review process
2. **ALWAYS ASK BEFORE PROCEEDING**: After each phase, ASK the user if they want to continue
3. **NEVER DUMP ALL OUTPUT AT ONCE**: Break the review into manageable phases
4. **WAIT FOR USER CONFIRMATION**: Don't proceed to the next phase without explicit confirmation
5. **User executes commands**: All bash commands (git, .unittests, swift-init, etc.) are executed by the user inside the SAIO machine, not by Claude

**Why this approach?**
- Keeps output focused and manageable
- Lets the reviewer direct the depth of analysis
- Allows questions and clarifications at each step
- Prevents overwhelming output from full reviews

## Empathic Comment Framework

Use these comment types from [Detangling Code Review](https://dev.to/endangeredmassa/detangling-the-code-review-questions-preferences-suggestions-conventions-requirements-4nm9):

**QUESTIONS**: When you need clarification
```
Question: Is there a reason we're using Exception here instead of (OSError, IOError)?
```

**PREFERENCES**: Personal preference, not critical
```
Preference: I'd extract this into a helper method for readability
```

**SUGGESTIONS**: Improvements that would make code better
```
Suggestion: Consider caching this value instead of recalculating each time
```

**CONVENTIONS**: Project standards and Swift conventions
```
Convention: Swift style guide prefers explicit error handling here
```

**REQUIREMENTS**: Must be addressed before merge
```
Requirement: This will break existing deployments - needs a migration path
```

**POSITIVE COMMENTS**: Always acknowledge good work
```
Great test coverage here - I especially like the edge case handling
This refactoring makes the code much clearer
Well-documented - the docstring really helps understand the intent
```

## Interactive Review Flow

**IMPORTANT**: This is an interactive, multi-step review process. Claude will pause at checkpoints to ask if you want to continue. This keeps output manageable and lets you direct the review.

### Review Phases Overview

```
Phase 1: Patch Overview
├─ Fetch metadata, commit message, files, diff
├─ Summarize what the patch does
└─ ASK: Continue to discussions? Skip to analysis? Ask questions?

Phase 2: Review Discussions (optional)
├─ User checks out patch in SAIO (git review -d <number>)
├─ Fetch and analyze existing Gerrit comments
├─ Summarize open questions, debates, suggestions
└─ ASK: Dive into discussions? Proceed to analysis?

Phase 3: Code Analysis
├─ Analyze commit message quality
├─ Test coverage (unit/probe/functional)
└─ ASK: See test commands? Continue to quality analysis?

Phase 4: Code Quality
├─ Swift-specific patterns
├─ General code quality
└─ ASK: Continue to edge cases? Skip to testing? Generate summary?

Phase 5: Edge Cases
├─ Error handling analysis
├─ Boundary conditions
└─ ASK: Get testing instructions? Generate summary?

Phase 6: SAIO Testing (optional)
├─ Provide testing commands
└─ ASK: Wait for results? Generate summary? Questions?

Phase 7: Final Review Summary
├─ Generate complete Gerrit comment
├─ Include all findings (Requirements, Suggestions, Questions)
├─ Positive observations
└─ Recommended vote
```

**Key Principle**: Claude MUST ask before moving between phases. Never dump all analysis at once.

---

## Review Steps

### Step 1: Fetch Patch Overview and Summarize Changes

**FIRST STEP - Always start here when the skill is invoked.**

**Claude will automatically fetch from Gerrit:**

1. **Patch metadata**:
   ```bash
   curl -s 'https://review.opendev.org/changes/openstack%2Fswift~<change-number>/detail' | sed '1d' | jq '{subject, status, owner, created, updated, insertions, deletions}'
   ```

2. **Commit message**:
   ```bash
   curl -s 'https://review.opendev.org/changes/openstack%2Fswift~<change-number>/revisions/current/commit' | sed '1d' | jq -r '.message'
   ```

3. **Files changed**:
   ```bash
   curl -s 'https://review.opendev.org/changes/openstack%2Fswift~<change-number>/revisions/current/files/' | sed '1d' | jq -r 'keys[]'
   ```

4. **Diff content**:
   ```bash
   curl -s 'https://review.opendev.org/changes/openstack%2Fswift~<change-number>/revisions/current/patch' | base64 -d
   ```

**Note**: Gerrit API responses start with `)]}'` (XSSI protection) - strip with `sed '1d'` before parsing.

**Claude will then present a concise summary:**

```
=== PATCH OVERVIEW: <change-number> ===

METADATA:
- Author: <name>
- Status: <NEW/MERGED/ABANDONED>
- Lines: +<insertions> / -<deletions>
- Created: <date>
- Updated: <date>

WHAT IT DOES:
[2-3 sentence summary of the change in plain language]

FILES CHANGED:
- <file1> - <component>
- <file2> - <component>
...

KEY CHANGES:
[Brief bullets highlighting main changes from diff]
```

**After presenting the overview, Claude MUST ask:**

```
=== CHECKPOINT: Review Direction ===

I've fetched and summarized patch <number>. What would you like to do next?

A. Ask questions about the change before proceeding
B. Proceed to review existing Gerrit comments and discussions
C. Skip discussion review and go straight to code analysis

Your choice (A/B/C):
```

**⛔ STOP HERE - Wait for user response before proceeding.**

---

### Step 2: Fetch and Summarize Existing Review Comments (if user chose B)

**Only proceed if user wants to review discussions.**

**User runs in SAIO first:**
```bash
# Checkout the patch to examine it locally
git review -d <change-number>
git log --oneline -3
git show HEAD
git diff master --stat
```

**Claude will then fetch review comments:**

```bash
# Fetch all review comments
curl -s 'https://review.opendev.org/changes/openstack%2Fswift~<change-number>/comments' | sed '1d'

# Fetch review messages
curl -s 'https://review.opendev.org/changes/openstack%2Fswift~<change-number>/detail' | sed '1d' | jq -r '.messages[]'
```

**Claude will analyze and summarize:**
1. **Open Questions**: Questions from reviewers awaiting answers
2. **Unresolved Requirements**: Must-fix issues not yet addressed
3. **Ongoing Debates**: Technical discussions between reviewers
4. **Pending Suggestions**: Improvements suggested but not implemented
5. **Test Coverage Gaps**: Areas where reviewers requested tests

Present this summary in a structured format:

```
=== EXISTING REVIEW DISCUSSIONS ===

OPEN QUESTIONS (X):
- [Reviewer Name, Line X, File Y]: Question text
  Status: Awaiting response from author

UNRESOLVED REQUIREMENTS (X):
- [Reviewer Name]: Requirement description
  Status: Not addressed in current patchset

ONGOING DEBATES (X):
- Topic: [Brief description]
  Participants: [Reviewer 1, Reviewer 2]
  Summary: [Key points from both sides]
  Status: No consensus reached

PENDING SUGGESTIONS (X):
- [Reviewer Name, Line X]: Suggestion text
  Status: Not implemented

TEST COVERAGE GAPS (X):
- [Area]: Requested test coverage
  Status: Tests not added
```

**After presenting discussion summary, Claude MUST ask:**

```
=== CHECKPOINT: After Discussion Review ===

I've summarized the existing review discussions. What would you like to do next?

A. Ask about a specific discussion thread in detail
B. Contribute to these discussions in your review
C. Proceed to code analysis and testing
D. Get SAIO testing commands for any discussion points

Your choice (A/B/C/D):
```

**⛔ STOP HERE - Wait for user response before proceeding.**

---

### Step 3: Code Analysis (only after user confirms to proceed)

**Only proceed if user wants code analysis.**

**Before starting analysis, Claude MUST ask:**

```
=== CHECKPOINT: Before Code Analysis ===

Ready to start code analysis. This will cover:
- Commit message quality
- Affected code components
- Related patches and dependencies

Should I proceed? (yes/no)
```

**⛔ STOP HERE - Wait for user confirmation.**

**If yes, analyze:**

1. **Commit message**: Clear? Follows OpenStack guidelines? Explains "why" not just "what"?
2. **Patch description**: Review Gerrit description
3. **Affected code**: Which files/components changed?
4. **Related patches**: Dependencies or related work?

### Step 4: Test Coverage Analysis

**Follow the test pyramid** - verify proper test coverage:

**Unit tests** (test/unit/):
- Do they exist for new/changed code?
- Are they comprehensive? Do they test edge cases?
- Are they well-written (clear, isolated, focused)?
- Red flags: Missing tests, tests that don't test the change, missing edge cases

**Probe tests** (test/probe/):
- For behavioral changes, are there probe tests?
- Do they test actual behavior, not just code paths?

**Functional tests** (test/functional/):
- For API changes, are there functional tests?
- Do they cover the happy path and error cases?

**After test coverage analysis, Claude MUST ask:**

```
=== CHECKPOINT: After Test Coverage Analysis ===

Test coverage analysis complete. What would you like to do next?

A. See specific test commands to run in SAIO
B. Continue to code quality analysis
C. Skip to manual testing instructions

Your choice (A/B/C):
```

**If user wants test commands (A), provide:**

```bash
# Run all unit tests
./.unittests

# Run specific test module (if applicable)
cd test/unit/<component> && pytest test_<module>.py -v

# Run probe tests (if behavioral changes)
./.probetests
```

**⛔ STOP HERE - Wait for user response before proceeding.**

### Step 5: Code Quality Analysis

**Only proceed after user confirms.**

Check for:

**Swift-specific patterns:**
- Error handling: Appropriate exception types? (OSError, IOError, DiskFileError, etc.)
- Quarantine operations: Correct use of quarantine_renamer/quarantine_dir_renamer?
- Database operations: Proper locking? (lock_path, with statements)
- Ring operations: Correct partition/suffix/hash calculations?
- WSGI/swob: Proper Request/Response handling?
- Eventlet: Non-blocking I/O where needed?

**General quality:**
- Clear variable/function names that express intent?
- Logical code organization?
- Comments only where WHY is non-obvious (constraints, invariants, workarounds)?
- Appropriate error handling (not too broad, not suppressing legitimate errors)?
- No obvious performance issues?
- No security vulnerabilities?
- Follows existing patterns in the codebase?

**After code quality analysis, Claude MUST ask:**

```
=== CHECKPOINT: After Code Quality Analysis ===

Code quality analysis complete. What would you like to do next?

A. Continue to edge case analysis
B. Skip to manual SAIO testing instructions
C. Generate the final review summary now

Your choice (A/B/C):
```

**⛔ STOP HERE - Wait for user response before proceeding.**

### Step 6: Edge Cases and Error Paths

**Only proceed after user confirms.**

For new functions/features, verify:
- What if inputs are None/empty/invalid?
- What if filesystem operations fail (ENOENT, EACCES, etc.)?
- What if target already exists?
- What about concurrent access?
- Are cleanup operations idempotent?

**After edge case analysis, Claude MUST ask:**

```
=== CHECKPOINT: After Edge Case Analysis ===

Edge case analysis complete. What would you like to do next?

A. Get manual SAIO testing instructions
B. Skip to final review summary generation

Your choice (A/B):
```

**⛔ STOP HERE - Wait for user response before proceeding.**

### Step 7: Manual Testing in SAIO (when applicable)

**Only provide if user requests testing instructions.**

Provide user with SAIO testing commands:

```bash
# Restart affected services
sudo swift-init main restart

# Monitor logs
sudo tail -f /var/log/syslog | grep swift

# Or check specific service logs
sudo tail -f /var/log/swift/<service>.log
```

Test the feature:
- Simulate the scenario the patch addresses
- Verify logs show expected behavior
- Check for errors or warnings
- Verify edge cases work correctly

**After providing testing commands, Claude MUST ask:**

```
=== CHECKPOINT: After Testing Instructions ===

SAIO testing instructions provided. What would you like to do next?

A. Wait for you to run tests and report results back
B. Proceed to generate final review summary
C. Ask questions about how to test specific scenarios

Your choice (A/B/C):
```

**⛔ STOP HERE - Wait for user response before proceeding.**

### Step 8: Generate Final Review Summary

**Only proceed after user confirms they want the final summary.**

**Before generating, Claude MUST ask:**

```
=== CHECKPOINT: Final Review Summary ===

Ready to generate your final review summary. This will include:
- All findings (Requirements, Suggestions, Questions, Conventions, Preferences)
- Positive observations
- Recommended vote (+1, 0, -1)
- Complete review comment formatted for Gerrit

Should I generate the final review summary now? (yes/no)
```

**⛔ STOP HERE - Wait for user confirmation.**

**If yes, structure your Gerrit comment as follows:**

---

**Review Summary Template:**

```
I reviewed this patch and tested the following:

ANALYSIS COMPLETED:
- Analyzed patch description and commit message
- Verified test coverage (unit tests + probe/functional tests)
- Ran .unittests - [Result: passing/failing]
- Ran .probetests - [Result: passing/failing] (if applicable)
- Code quality analysis
- Edge case analysis (if applicable)
- Tested in SAIO (if applicable)

FINDINGS:

[Use empathic comment types here - organize by severity]

REQUIREMENT: [Must-fix issues]
Line X: [Specific issue and why it must be fixed]

SUGGESTION: [Improvements that would strengthen the code]
Line Y: [What could be improved and why]

QUESTION: [Clarifications needed]
Line Z: [What needs clarification]

CONVENTION: [Style/convention notes]
[Reference to Swift conventions or project standards]

PREFERENCE: [Personal preferences, optional]
[Nice-to-have improvements]

POSITIVE OBSERVATIONS:

[Call out 2-5 things done well - be specific]
- [What was done well - reference specific code/approach]
- [Good patterns to highlight]
- [Effective test coverage, clear code, etc.]

SUMMARY:
[1-2 sentence overall assessment of the patch]

[Vote: +1, 0, or -1]
```

---

### Step 9: Gerrit Voting

After commenting, suggest appropriate vote:

- **+2**: Looks good to me, approved (core reviewers only)
- **+1**: Looks good to me, but you're not a core reviewer
- **0**: No score, just comments
- **-1**: I would prefer you didn't submit this (issues to address)
- **-2**: Do not submit (core reviewers only, serious issues)

As a non-core reviewer working towards core:
- **+1** when the patch looks good and tests pass
- **-1** when there are issues that should be addressed

## Common Review Checklist

Before approving any patch:

- [ ] Commit message is clear and follows OpenStack guidelines
- [ ] Code changes match the described purpose
- [ ] Unit tests exist and cover new/changed code
- [ ] Probe/functional tests exist for behavioral changes
- [ ] All tests pass (ran .unittests and .probetests)
- [ ] Code follows Swift conventions and style
- [ ] Error handling is appropriate (not too broad, not suppressing)
- [ ] No obvious security issues
- [ ] No performance regressions
- [ ] Documentation/config samples updated if needed
- [ ] Tested in SAIO (if applicable)
- [ ] Logs are clean (no new errors/warnings)
- [ ] Comments are constructive and helpful
- [ ] Positive observations included

## Review Philosophy

**Be thorough but timely:**
- Don't rush, but don't take weeks
- Aim to review within 1-2 days

**Be constructive:**
- Explain the "why" behind your comments
- Suggest solutions, not just problems
- Recognize good work when you see it
- Use the empathic comment framework

**Be consistent:**
- Apply the same standards to all patches
- Reference Swift conventions and best practices

**Build expertise:**
- Review code in areas you want to learn
- Ask questions when you don't understand
- Share knowledge in your comments

## What Makes a Great Review

A great review:
1. **Identifies real issues** with clear explanations
2. **Suggests concrete improvements** with code examples when helpful
3. **Acknowledges what works well** to reinforce good patterns
4. **Asks clarifying questions** to understand intent
5. **Distinguishes between** must-fix requirements and nice-to-have preferences
6. **Provides context** from Swift conventions and past decisions
7. **Is respectful and collaborative** in tone

Remember: The goal is to improve the code AND help the contributor grow. Every review is a teaching opportunity.
