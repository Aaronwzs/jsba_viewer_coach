---
name: project-template-audit
description: "Use when auditing an existing project to extract coding templates, architecture patterns, starter conventions, or reusable standards. Triggers on: audit project structure, extract template, derive coding standard, starter project audit, scaffold template, generate template from source code, reverse engineer project conventions, build skill from existing codebase."
user-invocable: false
---

# Project Template Audit

Use this skill when the codebase already contains established patterns and the goal is to extract them into reusable templates, skills, or standards.

## Objectives

1. Detect the real project structure and architectural layers from source code
2. Find existing reusable patterns before inventing new templates
3. Extract templates from concrete implementations when they exist
4. Generate a new template only when the project does not already provide one
5. Keep generated templates aligned with actual repository conventions, not generic framework defaults

## Audit Order

### 1. Identify the architecture
- Detect the stack, framework, state management, routing, networking, storage, testing, and major folders
- Find the owning abstractions for screens/pages, state, data access, services, and shared UI
- Prefer actual starter implementations over README claims

### 2. Find existing pattern anchors
- Look for one concrete example of each target artifact:
  - screen/page
  - form screen
  - view model / controller / hook / state object
  - repository / service / API client
  - model / DTO / entity
  - reusable widget / component
  - route registration
  - dependency registration / provider wiring
- Choose the smallest real example that clearly represents the house style

### 3. Decide: extract or generate
- **Extract** when the repository already contains a representative implementation
- **Generate** only when:
  - the artifact type is missing, or
  - existing examples are clearly demo-only / inconsistent / obsolete
- If generating, infer naming, layering, imports, and lifecycle rules from adjacent code

### 4. Produce the right output
Depending on the user ask, create one or more of:
- a skill in `.github/skills/<name>/`
- a reference template under `references/`
- a custom agent in `.github/agents/`
- updated agent instructions that reference the new skill/template

## Extraction Rules

- Never define standards that conflict with the actual starter project
- Prefer the repository's real wrappers and utilities over raw framework primitives
- If the project uses barrel files, document and use barrel files
- If the project uses base classes, the template must extend those base classes
- If the project has shared widgets/utilities for forms, navigation, spacing, or errors, the template must use them
- Distinguish between:
  - mandatory project rules
  - recommended conventions
  - optional examples
- Call out demo/stub code clearly and do not treat it as production standard unless confirmed by surrounding code

## Output Structure

When creating a template or skill, include:

1. **What it is for**
2. **When to use it**
3. **Required project rules**
4. **Concrete code template**
5. **Checklist after creation**
6. **Common mistakes / forbidden patterns**

## Validation Checklist

Before finalizing any extracted template:
- Does it use actual project file paths?
- Does it use actual project abstractions and helper utilities?
- Does it avoid introducing raw primitives when wrappers already exist?
- Does it reflect the real error-handling and state-management flow?
- Does it tell the agent when to reuse an existing template vs generate a new one?

## Escalation Rules

If the repository is inconsistent:
- Prefer the most recent, most central, and most reusable implementation pattern
- If two patterns conflict, document the conflict briefly and choose one
- If no stable pattern exists, generate a conservative template and label it as inferred rather than extracted
