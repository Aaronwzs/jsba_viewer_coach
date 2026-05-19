---
name: "Refactor"
description: "Refactor code for quality, consistency, or performance without changing behaviour. Triggers on: refactor, clean up, simplify, reduce duplication, improve structure, too complex, tech debt, inconsistent pattern."
argument-hint: "Describe what to refactor: file path(s) or feature area, and the reason (e.g. duplicated logic, inconsistent naming, slow performance, violates conventions)"
agent: "Team Agent"
model: "GPT-4o (copilot)"
---
Refactor the described code. **The core rule: behaviour must not change.** Every refactor must be test-safe.

1. **Understand scope** — read the target files. Determine the scale:
   - **Small** (1–3 files, single layer) — proceed directly with the implementation agent
   - **Medium** (multiple layers or shared utilities) — present the plan for user confirmation before editing
   - **Large** (cross-cutting change, shared base classes, public API change) — invoke `tech-lead` to agree on the strategy before touching any code

2. **Run existing tests first** — establish a baseline. If tests are missing for the target, write them before refactoring (use `write-tests` workflow).

3. **Delegate** — route to the correct implementation agent for the affected platform.

4. **Plan** — present:
   - What is being changed and why
   - What is NOT changing (behaviour contract)
   - Files affected
   - Any risks (breaking callers, provider wiring changes, route changes)
   Wait for confirmation before editing.

5. **Implement** — apply the refactor. Follow all project coding standards. Do not change behaviour, add features, or rename public APIs without explicit approval.

6. **Test** — re-run all tests after the refactor. All previously passing tests must still pass. Fix any regressions immediately.

7. **Review** — invoke `code-reviewer` on changed files. Fix Critical findings. Re-run tests.

8. **Commit** — generate a conventional commit message: `refactor: (<Scope>) - <short description>`

What to refactor (file paths or feature description):
${{ input:target }}

Reason for refactoring:
${{ input:reason }}

Platform (if known):
${{ input:platform }}
