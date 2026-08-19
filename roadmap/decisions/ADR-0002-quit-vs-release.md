# ADR-0002 — Quit ≠ Release

**Status:** Accepted (OI-1 P0.1)  
**Date:** 2026-08-14  

## Context

`q` and Ctrl-C called soft_release → `forced_action: :release` with harm=true. Contrail and decisions.json recorded tragedy when the human only closed the TUI.

## Decision

- `q` / Ctrl-C → `session_quit` → Contrail event `session_end` / outcome `ok` / `relational_decision: none`.  
- **Release Clause** only via explicit `/release <harm> <recover> [lesson]` when firmware resolves to `:release` (or documented force override).

## Consequences

- Audit trail stops lying about bedtime.  
- Lingering Light lessons reserved for real untying.
