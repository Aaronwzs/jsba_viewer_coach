---
name: "Code Review"
description: "Review code for quality, security, and correctness. Triggers on: code review, review this, review PR, review my code, check my code, find bugs, security check."
argument-hint: "Paste the code or file paths to review, or describe what was changed"
agent: "Team Agent"
model: "GPT-4o (copilot)"
---
Review the provided code. Enter the delivery workflow at Step 5 (Review):

1. **Invoke `code-reviewer`** — review all changed files for:
   - Correctness (logic errors, edge cases, null safety)
   - Security (OWASP Top 10, input validation, secrets exposure, supply chain risks)
   - Performance (N+1, unnecessary rebuilds, unbounded fetches)
   - Maintainability (SRP, naming, duplication, dead code)
   - Project standards compliance (base classes, wrappers, localization, navigation conventions)

2. **Categorize findings**:
   - **Critical** — must fix before merge (bugs, security issues)
   - **Suggestion** — should improve (design, performance, clarity)
   - **Nit** — minor style only (non-blocking)

3. **For Critical and Suggestion findings** — delegate fixes to the appropriate implementation agent, re-run tests, then re-review to confirm resolution.

4. **Report** — present the final review summary with all findings addressed.

Files or code to review:
${{ input:files_or_code }}

Context (what this change does):
${{ input:context }}
