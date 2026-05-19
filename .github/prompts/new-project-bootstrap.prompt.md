---
name: "New Project Bootstrap"
description: "Bootstrap a new project with a complete template system. Triggers on: new project, start from scratch, greenfield project, project setup, project template, scaffold project."
argument-hint: "Describe the project: platform, tech stack (if known), type of app, and any constraints"
agent: "Team Agent"
model: "GPT-4o (copilot)"
---
A new project needs to be bootstrapped with a complete, reusable template system. Follow this sequence:

1. **Consult `tech-lead`** — agree on: platform, framework, state management, navigation, service layer pattern, error handling strategy, and testing approach. Produce an ADR before any code or template is written.
2. **Invoke `template-auditor`** — design the full template system:
   - Layer map (what each layer is responsible for)
   - Naming and folder conventions
   - Base class hierarchy (base page, base viewmodel, base service, base repository)
   - Complete template set: model, service, repository, viewmodel, page, widget, route, provider wiring, test fixture, unit test, widget test
   - Developer quick-start guide
3. **Validate** — trace a hypothetical feature end-to-end using only the templates to confirm they are complete and consistent.
4. **Output** — produce the template skill files under `.github/skills/` and a reference guide.

Project description:
${{ input:project_description }}

Platform / Tech stack (if decided):
${{ input:tech_stack }}

Any constraints or requirements (timeline, team size, existing standards):
${{ input:constraints }}
