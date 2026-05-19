---
name: "Bug Fix"
description: "Fix a bug in any platform. Triggers on: bug fix, something is broken, wrong behaviour, crash, error, not working, unexpected result."
argument-hint: "Describe the bug: what screen/feature, what the actual behaviour is, and what the expected behaviour should be"
agent: "Team Agent"
model: "GPT-4o (copilot)"
---
A bug has been reported. Follow the Standard Delivery Workflow:

1. **Understand** — search the codebase for the affected screen, feature, or layer based on the description below. Identify the root cause before touching any code.
2. **Delegate** — route to the correct implementation agent for the affected platform.
3. **Plan** — present the affected files and the proposed fix. Wait for user confirmation before editing.
4. **Implement** — apply the fix. Explain both what changed and *why* the bug occurred (root cause theory).
5. **Test** — run the relevant test suite. If no test covers this bug, write a regression test first.
6. **Review** — invoke `code-reviewer` on the changed files. Resolve all Critical findings before marking done.
7. **Commit** — generate a conventional commit message: `fix: (<Scope>) - <short description>`

Bug details:
${{ input:bug_description }}

Affected platform (if known):
${{ input:platform }}
