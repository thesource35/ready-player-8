---
name: add-or-expand-navigation-tab
description: Workflow command scaffold for add-or-expand-navigation-tab in ready-player-8.
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /add-or-expand-navigation-tab

Use this workflow when working on **add-or-expand-navigation-tab** in `ready-player-8`.

## Goal

Adds a new major feature area or expands the app's navigation with a new tab, often with sub-tabs and associated view files.

## Common Files

- `ready player 8/ContentView.swift`
- `ready player 8/*View.swift`

## Suggested Sequence

1. Understand the current state and failure mode before editing.
2. Make the smallest coherent change that satisfies the workflow goal.
3. Run the most relevant verification for touched files.
4. Summarize what changed and what still needs review.

## Typical Commit Signals

- Edit or expand ready player 8/ContentView.swift to add the new tab and navigation logic.
- Create a new View file for the tab (e.g., ready player 8/FieldOpsView.swift, ready player 8/FinanceHubView.swift, etc.).
- Implement sub-tabs or features within the new View file.
- Update related models or helpers if needed.

## Notes

- Treat this as a scaffold, not a hard-coded script.
- Update the command if the workflow evolves materially.