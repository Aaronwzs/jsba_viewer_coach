---
name: "Read Azure DevOps Ticket"
description: "Read an Azure DevOps work item, prompt for PAT if needed, and extract implementation-ready ticket details. Use when: Azure DevOps ticket, Boards work item, user story, bug, task, acceptance criteria, repro steps."
argument-hint: "Provide a work item ID, or include project plus search text if the ID is unknown"
agent: "azure-devops-ticket"
model: "GPT-5 (copilot)"
---
Read and extract the Azure DevOps work item requested by the user.

Requirements:
- If a PAT token is not already available in chat context, prompt the user to provide it before attempting to read the ticket.
- Do not echo or persist the PAT token.
- If a work item ID is provided, use it directly.
- If no work item ID is provided, ask for the minimum missing identifiers needed to find it, such as project and search text.
- Extract the key work item details needed for implementation.
- Derive codebase discovery hints from the work item so implementation agents can locate the right files faster.
- Propose candidate files only as suggestions, then ask the user to confirm the exact file path or paths before any implementation work begins.

Return the result using this structure:

### Extracted Work Item
- ID:
- Title:
- Type:
- State:
- Priority/Severity:
- Assignee:
- Area/Iteration:

### Details
- Problem Statement:
- Acceptance Criteria:
- Repro Steps:
- Dependencies/Links:
- Latest Updates:

### Implementation Notes
- Scope:
- Risks/Unknowns:
- Suggested Next Actions:

### Codebase Discovery Hints
- Candidate Search Terms:
- Likely Layers:
- Likely Existing Files to Inspect:
- Likely Tests to Inspect:

### Confirmation Needed
- Proposed Files to Review:
- Ask the user to confirm the exact file path or paths to modify.

### Missing Information
- List any fields or identifiers that were unavailable
