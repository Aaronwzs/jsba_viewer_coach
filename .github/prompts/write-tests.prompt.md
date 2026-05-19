---
name: "Write Tests"
description: "Write tests for an existing feature or layer. Triggers on: write tests, add tests, unit test, widget test, test coverage, no tests, untested code, missing tests, test this, test plan."
argument-hint: "Describe what to test: file path(s), feature name, or layer (model / service / repository / viewmodel / page)"
agent: "Team Agent"
model: "GPT-4o (copilot)"
---
Write tests for the described code. Follow this approach:

1. **Identify the platform** — Flutter, Web, Backend, or Admin Portal — and delegate to the correct test agent:
   - Flutter → `mobile-flutter-test`
   - Web / Admin Portal → `qa-engineer`
   - Backend → `qa-engineer`

2. **Discover the code** — read the target files to understand what already exists. Check whether any tests already exist for this target.

3. **Write the tests** — for each layer identified:
   - **Model** — test serialization/deserialization, null safety, edge cases
   - **Repository** — mock service, assert mapping logic, test error paths
   - **ViewModel** — mock repository, test each method: state transitions (idle → loading → success/error), and that no exception leaks to the UI
   - **Page/Screen** — widget tests for: initial render, user interactions, navigation, loading state, error state
   - **Service** — unit tests for request construction and response parsing

4. **Run the tests** — confirm all tests pass. Fix any failures (with explanation of root cause) before reporting done.

5. **Report** — list each test file created and the count of tests added.

What to test (file paths or feature/layer description):
${{ input:target }}

Platform (if known):
${{ input:platform }}
