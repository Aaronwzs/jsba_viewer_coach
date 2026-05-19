# AI Agent Quick-Start Guide

---

## Step 1 — Configure and Start the DevOps MCP Server

> ⚠️ **Complete this step before anything else.** The agent system uses the MCP server to read Azure DevOps tickets. Without it, ticket-based workflows will not function.

### 1a — Configure `mcp.json`

Open (or create) the `.vscode/mcp.json` file in your project and add the Azure DevOps server entry:

```json
{
  "servers": {
    "azure-devops": {
      "type": "stdio",
      "command": "npx",
      "args": [
        "-y",
        "@azure-devops/mcp",
        "<organization-name>",
        "-d",
        "core"
      ]
    }
  }
}
```

Replace `<organization-name>` with your Azure DevOps organization name (e.g., `agmo`).

### 1b — Authenticate

Ensure your Azure DevOps Personal Access Token (PAT) is available. The MCP server will use it to authenticate requests. Set it as an environment variable if prompted:

```bash
export AZURE_DEVOPS_EXT_PAT=<your-pat-token>
```

### 1c — Start the Server

Start the MCP server by running the following command in your terminal:

```bash
npx -y @azure-devops/mcp <organization-name> -d core
```

Once the server is running and you see a ready signal in the terminal, proceed to Step 2.

---

## Step 2 — Copy the Agent System into Your Project

Add the `.github/` folder to the **root of your project repository**. It must look exactly like this:

```
your-project/
└── .github/
    ├── agents/          ← agent behaviour definitions
    │   ├── team-agent.agent.md
    │   ├── tech-lead.agent.md
    │   ├── mobile-dev.agent.md
    │   ├── mobile-flutter-test.agent.md
    │   ├── backend-dev.agent.md
    │   ├── web-dev.agent.md
    │   ├── admin-portal.agent.md
    │   ├── code-reviewer.agent.md
    │   ├── qa-engineer.agent.md
    │   ├── devops.agent.md
    │   ├── azure-devops-ticket.agent.md
    │   └── template-auditor.agent.md
    │
    ├── prompts/         ← one-click task starters
    │   ├── bug-fix.prompt.md
    │   ├── new-feature.prompt.md
    │   ├── new-project-bootstrap.prompt.md
    │   ├── code-review.prompt.md
    │   ├── implement-from-ticket.prompt.md
    │   ├── audit-and-template.prompt.md
    │   ├── write-tests.prompt.md
    │   ├── refactor.prompt.md
    │   └── quickstart.prompt.md
    │
    ├── skills/          ← coding standards loaded by agents
    │   ├── mobile-flutter-standard/
    │   └── mobile-flutter-test/
    │
    └── hooks/           ← guard script (optional, CI use)
        ├── implementation-guard.sh
        └── implementation-guard.json
```

> **Minimum required**: `agents/` and `prompts/` folders.  
> `skills/` is required if you use Flutter. `hooks/` is only needed for CI pipelines.

---

## Step 3 — Open GitHub Copilot Chat in VS Code

1. Click the **Copilot Chat icon** in the VS Code sidebar (or press `⌃⌘I` / `Ctrl+Alt+I`)
2. At the top of the chat panel, click the **agent/mode selector dropdown**

```
┌──────────────────────────────────────────┐
│  Copilot Chat                            │
│  ┌────────────────────────────────────┐  │
│  │ ▼  Team Agent              ← pick  │  │
│  └────────────────────────────────────┘  │
│                                          │
│  Ask anything...                         │
└──────────────────────────────────────────┘
```

3. Select **"Team Agent"** from the list
4. You are now ready — type your task in plain English

> **Tip:** Type `/quickstart` at any time to bring up this guide inside the chat panel.

---

## Step 4 — What the Team Agent Can Do

The **Team Agent** acts as your AI team lead. It understands your request, routes it to the right specialist, and follows a full delivery workflow: implement → test → review → done. You describe the outcome; the agents handle the steps.

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

---

## Step 5 — Choose How to Start

### Option A — Type freely (for any task)

Select **Team Agent** and just describe what you need:

```
Add a login screen to the Flutter app.
Email + password fields, POST /auth/login, navigate to Home on success.
```

Team Agent handles the rest: searches codebase, plans, delegates to specialists, tests, and reviews.

---

### Option B — Use a prompt template (fastest)

In the Copilot Chat input, type `/` to open the prompt picker, then select the matching template:

```
/  ←── type this in the chat input
```

```
┌─────────────────────────────────────────────────────┐
│  PICK A PROMPT                                      │
├────────────────────────┬────────────────────────────┤
│  bug-fix               │  Something is broken       │
│  new-feature           │  Add a screen or feature   │
│  new-project-bootstrap │  Start a brand new project │
│  code-review           │  Review code before merge  │
│  implement-from-ticket │  You have a ticket ID      │
│  audit-and-template    │  Audit architecture        │
│  write-tests           │  Add missing tests         │
│  refactor              │  Clean up code             │
│  quickstart            │  Show this guide in chat   │
└────────────────────────┴────────────────────────────┘
```

Each template asks you to fill in 1–3 short inputs, then runs the full workflow automatically.

---

## Step 6 — How to Talk to It — 4 Tips

1. **Be specific about the outcome, not the steps.** Say `"add a notification bell icon that shows unread count"` — not `"modify the AppBar, then add a badge widget, then…"`. The agent figures out the steps.
2. **Attach design assets when you have them.** Paste a Figma screenshot or describe the UI direction. The agent will not invent UI on its own without either.
3. **Mention the platform when relevant.** Flutter, Web, Backend, Admin Portal. If you don't mention it, the agent will ask.
4. **For tickets, just give the ticket number.** `"Implement ticket #12345"` is enough — the agent reads the full ticket from Azure DevOps.

---

## Step 7 — Follow the Workflow

Every task follows the same 5 steps. Team Agent does all of this — you only act at the ★ points:

```
  1. UNDERSTAND     Agent reads your prompt and searches the codebase
         │
         ▼
  2. SCOPE          Simple task? → go straight to Step 3
                    New pattern / dependency? → Tech Lead called first
         │
         ▼
  3. IMPLEMENT  ★   Agent lists the files it will change
                    YOU confirm the file list before any edits are made
         │
         ▼
  4. TEST           Test agent writes and runs tests automatically
                    All tests must pass before moving on
         │
         ▼
  5. REVIEW         Code Reviewer checks all changed files
                    Critical issues fixed in a loop until clean
         │
         ▼
  DONE              Delivery Summary + copy-paste commit message
```

---

## Step 8 — Copy the Commit Message

When the workflow finishes, Team Agent produces a ready-to-use commit message:

```
feat: (Login) - implement login screen with email and password

Adds LoginModel, LoginServices, LoginRepository, LoginViewModel,
and LoginPage. Uses AppTextField, go_router navigation, and
S.current.* localization strings.

Refs: AB#1042
```

Paste this directly into your `git commit -m` or PR description.

---

## Real Example — What Actually Happened in This Project

**User prompt (verbatim):**
> *"add a user profile screen, i don't have ui, but follow how instagram do, create exactly one with api integration, test and code review it"*

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

## Available Slash Commands

| Command | What it does |
|---|---|
| `/new-feature` | Implement a new feature end-to-end |
| `/bug-fix` | Diagnose and fix a bug |
| `/write-tests` | Write tests for existing code |
| `/code-review` | Review code for quality and security issues |
| `/refactor` | Refactor code while maintaining behaviour |
| `/implement-from-ticket` | Read an ADO ticket and implement it |
| `/read-azure-devops-ticket` | Read and summarise an ADO ticket |
| `/quickstart` | Show this guide inside the chat panel |

---

## Quick Reference Card

| I want to... | Do this |
|---|---|
| Fix a bug | Select Team Agent → use `bug-fix` prompt |
| Build a new feature | Select Team Agent → use `new-feature` prompt |
| Start a new project | Select Team Agent → use `new-project-bootstrap` prompt |
| Review code | Select Team Agent → use `code-review` prompt |
| Implement a ticket | Select Team Agent → use `implement-from-ticket` prompt |
| Add tests | Select Team Agent → use `write-tests` prompt |
| Refactor code | Select Team Agent → use `refactor` prompt |
| Ask a question | Select Team Agent → type freely, no prompt needed |
| See this guide in chat | Type `/quickstart` in Team Agent |

> **One rule to remember**: Always start with **Team Agent**. It routes to the right specialist automatically — you never need to switch agents yourself.

---

You're ready. Describe what you want to build, fix, or review — and the team gets to work.
