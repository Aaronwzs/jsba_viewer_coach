---
name: "New Feature"
description: "Implement a new feature end-to-end. Triggers on: new feature, add screen, add page, add functionality, implement, build, create new."
argument-hint: "Describe the feature: what it does, which platform, and any known acceptance criteria or design specs"
agent: "Team Agent"
model: "GPT-4o (copilot)"
---
A new feature needs to be implemented. Follow the Standard Delivery Workflow:

1. **Understand** — analyse the feature description. Search the codebase for related existing screens, models, routes, and services to understand where this feature fits.
2. **Scope** — decide if `tech-lead` is needed (new architectural layer, new dependency, API contract affecting multiple consumers). If yes, get the plan approved before writing code.
3. **Delegate** — route to the correct implementation agent(s). If the feature spans backend + mobile, do backend first.
4. **Plan** — present proposed new files and files to modify. Wait for user confirmation.
5. **Implement** — write the full feature: model, service, repository, viewmodel, page/screen, route registration, localization strings, and provider wiring.
6. **Test** — write tests for all new layers: unit tests (model, repository, viewmodel) and widget/UI tests. Run and confirm all pass.
7. **Review** — invoke `code-reviewer`. Resolve all Critical and Suggestion findings. Re-run tests after each fix.
8. **Commit** — generate a conventional commit message: `feat: (<Scope>) - <short description>`

Feature description:
${{ input:feature_description }}

Platform (Flutter / Web / Backend / Admin Portal):
${{ input:platform }}

Any known acceptance criteria or design notes:
${{ input:acceptance_criteria }}
