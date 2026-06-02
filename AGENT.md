# AGENTS.md

## Project Overview

CycleGuide is a Flutter bicycle route planning application.

## Core Architecture Rules

* Use Provider for state management.
* All APIs must be accessed through service layer.
* UI must not contain business logic.
* Do not duplicate services or controllers.
* Always reuse existing implementations before creating new ones.

## Documentation Rules

Read before coding:

* docs/architecture.md
* docs/validation.md
* docs/coding_style.md
* docs/logging.md

## Before Making Changes

Before creating new code:

1. Search the project for existing implementations.
2. Reuse existing services, repositories, providers, models, and widgets whenever possible.
3. Do not create duplicate functionality.
4. Do not invent APIs, methods, models, services, or controllers that do not already exist without verifying project requirements.
5. Follow existing folder structure and architecture patterns.

## UI Feedback / Notifications

* Use the project's existing SnackBar widgets for user-facing messages: `SuccessSnackBar` and `ErrorSnackBar` (located in `lib/widgets/`).
* Always call them via `ScaffoldMessenger.of(context).showSnackBar(...)` rather than creating ad-hoc `SnackBar` instances.
* Before adding any new UI feedback widgets, search the repo for `SuccessSnackBar` / `ErrorSnackBar` and reuse them.
* Add tests or manual verification steps when changing message wording or durations.



## General Principles

* Keep architecture consistent.
* Prefer modification over duplication.
* Ensure features integrate with existing system design.
* Make the smallest safe change necessary.
* Consistency is more important than creativity.
* Add comment for every class and function,methods 