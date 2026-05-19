---
name: "Implement from Azure DevOps Ticket"
description: "Read an Azure DevOps ticket and implement it end-to-end. Triggers on: implement ticket, work item, user story, DevOps ticket, Boards issue, AB#, sprint task."
argument-hint: "Provide the Azure DevOps work item ID, or project name plus search text if the ID is unknown"
agent: "Team Agent"
model: "GPT-4o (copilot)"
---
Implement the work described in an Azure DevOps ticket. Follow this sequence:

1. **Read the ticket** — invoke `azure-devops-ticket` to extract the work item details. If a PAT token is not available in the chat context, prompt the user for it first (never echo it back).

2. **Understand the scope** — from the extracted ticket, identify:
   - Affected platform and layers
   - Acceptance criteria
   - Dependencies or linked tickets
   - Whether architectural changes are needed (if yes, involve `tech-lead` before coding)

3. **Follow the Standard Delivery Workflow** (Steps 2–5):
   - Delegate to the correct implementation agent
   - Plan (confirm files with user before editing)
   - Implement
   - Test (write and run tests, all must pass)
   - Review (code-reviewer, fix loop until no Criticals)

4. **Commit** — generate a conventional commit message referencing the ticket:
   ```
   <type>: (<Scope>) - <short description>

   <body>

   Refs: #<work-item-id>
   ```

Work item ID (or project + search text):
${{ input:ticket_id }}
