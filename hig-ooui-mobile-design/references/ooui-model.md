# OOUI Modeling Guide

## Object Inventory
- Identify primary objects (the main things users care about).
- Identify supporting objects (tags, categories, settings, files).
- Identify system objects (account, subscription, notifications).

## Object Model Template
Use this table for each object.

| Object | Role | Key attributes | Primary actions | States | Relationships | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| Example: Habit | Primary | name, schedule, streak | create, edit, complete | active, paused | belongs to Goal | needs reminder setup |

## Interaction Model
- Prefer direct manipulation for primary objects.
- Use detail views for editing, history, and advanced actions.
- Classify actions as: create, read, update, delete, share, favorite, reorder.

## Task Flow Template
Use this format for each primary flow.

1. Entry context
2. Trigger
3. Steps (happy path)
4. Success outcome
5. Failure cases
6. Data created or updated

## Mapping Objects to Screens
- Provide a home or collection view for each primary object.
- Provide a detail view that exposes primary actions.
- Provide creation and edit surfaces with clear confirmation.

## Edge Cases
- Empty state and onboarding
- Error state and retry
- Permission denied or limited access
