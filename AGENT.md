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
* docs/development_rules.md
* docs/validation.md
* docs/coding_style.md

## General Principles

* Keep architecture consistent.
* Prefer modification over duplication.
* Ensure features integrate with existing system design.
