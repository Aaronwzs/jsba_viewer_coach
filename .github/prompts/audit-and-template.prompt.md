---
name: "Audit and Template"
description: "Audit existing code architecture or design a new template. Triggers on: audit project, extract template, reverse engineer conventions, coding standard, architecture review, derive template, new project template, starter kit."
argument-hint: "Describe what to audit (existing codebase, a specific layer, or a new project that needs templates designed from scratch)"
agent: "Team Agent"
model: "GPT-4o (copilot)"
---
Invoke the `template-auditor` for one of the two modes below. Identify which mode applies from the description provided.

## Mode A: Existing Project Audit
If auditing an existing codebase, extract and document its conventions so they can be consistently enforced or shared.

1. **Map the architecture** — identify every layer (model, service, repository, viewmodel, page/screen, widget, route, provider). For each layer, describe: responsibility, naming convention, base class used, and data flow rules.
2. **Identify gaps** — find layers with inconsistent patterns, missing base classes, or ad-hoc implementations that bypass conventions.
3. **Extract templates** — produce a complete template for each layer based on the majority/correct pattern in the codebase.
4. **Produce output**:
   - Architecture map
   - Template files (one per layer)
   - Gap report (what is inconsistent and recommended fixes)
   - Developer quick-start guide
5. **Non-breaking rule** — every recommendation must be backward compatible. No "rewrite everything" suggestions unless explicitly requested.

## Mode B: New Project Template Design
If the project is new and needs templates designed from scratch:

1. **Consult `tech-lead`** — agree on architecture, state management, service layer, and testing approach first.
2. **Design templates** — create a complete, reusable template set: model, service, repository, viewmodel, page, widget, route, provider wiring, unit test, widget test.
3. **Validate templates** — trace a hypothetical feature end-to-end through all templates to confirm consistency.
4. **Output skill files** — save templates as `.github/skills/` files for agent use.

What to audit or design:
${{ input:subject }}

Mode (Existing / New / Not sure):
${{ input:mode }}
