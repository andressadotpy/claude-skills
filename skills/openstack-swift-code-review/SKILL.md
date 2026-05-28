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

**IMPORTANT**: All bash commands in this skill (git, .unittests, swift-init, etc.) are executed by the user inside the SAIO machine, not by Claude. Claude provides guidance and analysis, while the user runs the commands and reports results back.

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

## Review Steps

### Step 1: Fetch and Analyze Patch

**Automatic fetch from Gerrit** - Claude will automatically fetch the patch details when given a change number or URL.

For Gerrit URLs like `https://review.opendev.org/c/openstack/swift/+/966980`, extract the change number (966980).

Claude will fetch:
1. Patch metadata: `gh api https://review.opendev.org/changes/openstack%2Fswift~<change-number>/detail`
2. Commit message and description from the fetched metadata
3. File list: `gh api https://review.opendev.org/changes/openstack%2Fswift~<change-number>/revisions/current/files`
4. Diff for each file: `gh api https://review.opendev.org/changes/openstack%2Fswift~<change-number>/revisions/current/files/<file-path>/diff`

**Note**: Gerrit API responses start with `)]}'` to prevent XSSI attacks - Claude should strip this prefix before parsing JSON.

After fetching, user runs in SAIO:
```bash
git review -d <change-number>
git log --oneline -3
git show HEAD
git diff master --stat
```

Analyze:
1. **Commit message**: Clear? Follows OpenStack guidelines? Explains "why" not just "what"?
2. **Patch description**: Review Gerrit description
3. **Affected code**: Which files/components changed?
4. **Related patches**: Dependencies or related work?

### Step 2: Test Coverage Analysis

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

User runs:
```bash
./.unittests  # Run all unit tests
./.probetests  # Run all probe tests (if applicable)
```

### Step 3: Code Quality Analysis

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

### Step 4: Edge Cases and Error Paths

For new functions/features, verify:
- What if inputs are None/empty/invalid?
- What if filesystem operations fail (ENOENT, EACCES, etc.)?
- What if target already exists?
- What about concurrent access?
- Are cleanup operations idempotent?

### Step 5: Manual Testing in SAIO (when applicable)

User runs:
```bash
sudo swift-init main restart  # Restart affected services
sudo tail -f /var/log/syslog | grep swift  # Monitor logs
```

Test the feature:
- Simulate the scenario the patch addresses
- Verify logs show expected behavior
- Check for errors or warnings
- Verify edge cases work correctly

### Step 6: Generate Review Comment

Structure your Gerrit comment as follows:

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

### Step 7: Gerrit Voting

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
