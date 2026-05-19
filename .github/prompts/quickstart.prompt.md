---
name: "Quick Start"
description: "Introduce the Team Agent — what it can do, what prompts to use, and what to expect. Triggers on: /start, /quickstart, what can you do, how do I start, getting started, what agents do you have."
agent: "Team Agent"
---

Greet the user and introduce the full agent system. Present everything in structured Markdown. Be concise — the goal is to get them typing their first real prompt within 2 minutes.

## What to present

### 1. Welcome

Open with a one-paragraph summary: what the Team Agent is, how it works (routes to specialists, follows a full delivery workflow), and what the user should expect.

### 2. What It Can Do — Capability Map

Present a clean table of all the things the agent system handles, organized by domain. Each row must include the capability and 1–2 sample prompts the user can copy and paste directly.

Use exactly these rows (add more if the project has additional agents):

| Domain | What it does | Sample prompt |
|---|---|---|
| 🚀 Feature Development | Builds new features end-to-end: model → service → repository → viewmodel → screen → tests → code review | `"Add a user profile screen, follow Instagram layout, integrate with the API, test and review it"` |
| 🐛 Bug Fix | Diagnoses and fixes bugs across any layer, with tests to confirm the fix | `"Fix the crash when tapping outside the payment popup on Android"` |
| 🎨 UI / Screen | Builds UI screens from a Figma screenshot or a written description | `"Build a checkout summary screen — here's the Figma screenshot: [attach]"` |
| 🔍 Code Review | Reviews code for bugs, security issues (OWASP), architecture violations, and style | `"Review my AuthViewModel and LoginRepository for issues"` |
| 🧪 Tests | Writes unit, widget, and integration tests for any layer | `"Write full tests for the UserProfileViewModel and UserProfilePage"` |
| 🏗️ Architecture | Designs systems, data models, API contracts, and ADRs | `"Design the data model and API contract for a loyalty points system"` |
| 📋 Ticket Analysis | Reads an Azure DevOps work item and extracts requirements and acceptance criteria | `"Read ticket #105595 and summarise what needs to be fixed"` |
| ⚙️ DevOps / CI/CD | Builds and fixes pipelines, Docker configs, deployment stages | `"Add a staging deployment stage to our Azure pipeline that runs after tests pass"` |
| 📦 Refactor | Refactors code while maintaining behaviour, with tests before and after | `"Refactor the LoginRepository to use the new BaseRepository pattern"` |
| 🗂️ Project Audit | Audits the codebase and extracts coding standards, templates, and conventions | `"Audit this project and generate a coding standard document"` |

### 3. How to Talk to It — Prompt Tips

Give the user 4 practical tips:

1. **Be specific about the outcome, not the steps.** Say "add a notification bell icon that shows unread count" — not "modify the AppBar, then add a badge widget, then…". The agent figures out the steps.
2. **Attach design assets when you have them.** Paste a Figma screenshot or describe the UI direction. The agent will not invent UI on its own without either.
3. **Mention the platform when relevant.** Flutter, Web, Backend, Admin Portal. If you don't mention it, the agent will ask.
4. **For tickets, just give the ticket number.** `"Implement ticket #12345"` is enough — the agent reads the full ticket from Azure DevOps.

### 4. Real Example — What Actually Happened

Show this real example from the project to demonstrate depth and quality:

---

**User prompt (verbatim):**
> "add a user profile screen, i don't have ui, but follow how instagram do, create exactly one with api integration, test and code review it"

**What the Team Agent did automatically:**

1. Classified the request as an implementation task
2. Recognised "follow Instagram" as sufficient UI direction — did not block
3. Searched the codebase to understand MVVM architecture, base classes, and patterns before writing any code
4. Implemented 4 layers: `UserRepository.getProfile()` → `UserProfileViewModel` → `UserProfilePage` (Instagram layout) → full registration (provider, barrel exports, GoRouter)
5. Ran `dart analyze` — zero issues before proceeding to tests
6. Wrote 28 tests across 4 files (model, repository, viewmodel, widget)
7. Diagnosed a test failure — identified that `DynamicParsing.parseString()` returns `''` not `null`, fixed the expectation
8. Ran code review — found and fixed 2 critical bugs:
   - `isLoading` permanently stuck when a network exception was thrown
   - Async `expect()` assertions not awaited — silently always passing (false-green tests)
9. Re-ran all 28 tests — all passed ✅
10. Generated a conventional commit message

**Outcome:** 13 files created or modified. Zero critical issues remaining. 28/28 tests green.

---

### 5. Available Slash Commands

List the prompt shortcuts the user can type in chat:

| Command | What it does |
|---|---|
| `/new-feature` | Implement a new feature end-to-end |
| `/bug-fix` | Diagnose and fix a bug |
| `/write-tests` | Write tests for existing code |
| `/code-review` | Review code for quality and security issues |
| `/refactor` | Refactor code while maintaining behaviour |
| `/implement-from-ticket` | Read an ADO ticket and implement it |
| `/read-azure-devops-ticket` | Read and summarise an ADO ticket |
| `/quickstart` | Show this guide again |

### 6. Call to Action

End with a single line inviting the user to type their first prompt:

> You're ready. Describe what you want to build, fix, or review — and the team gets to work.
