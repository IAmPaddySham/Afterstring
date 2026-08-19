# ADR-0001 — Permit vs Decide (two gates, one mouth)

**Status:** Accepted (OI-1)  
**Date:** 2026-08-14  

## Context

Operators and agents confused `gate.rb` with the public Zero-Gate / relational Stay·Pause·Release loop.

## Decision

| Operator word | Code | Role |
|---------------|------|------|
| **Permit** | `runtime/gate.rb` · `/gate` · `/permit` | Harness permissions (GrokBuild / RLM / GrokBot / OpenWeight matrices, Sabbath, trust low) |
| **Decide** | `runtime/decision_state.rb` · `/stay` · `/release` | Relational firmware: Stay / Pause / Release |

Public Zero-Gate spirit maps to **Decide**, not Permit.

## Consequences

- Help, status line, and Contrail purposes use distinct vocabulary.  
- Class renames deferred (behavior first); display and CLI aliases first.
