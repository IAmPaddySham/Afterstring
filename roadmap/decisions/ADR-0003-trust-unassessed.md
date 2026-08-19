# ADR-0003 — Signal trust defaults to unassessed (session-scoped)

**Status:** Accepted (OI-1 P0.3) · Amended OI-1.1  
**Date:** 2026-08-14  

## Context

Seeding trust high on boot made the sensor check theater. After OI-1 shipped, GrokBot found a second leak: `~/.afterstring/signal_trust.json` still held **prior high** from 04:49 UTC; `load!` restored it so the new unassessed block never fired.

## Decision

- **`unassessed?` is process/session-scoped**, not “file missing.”  
- Prior disk level is **PRIOR only** (`prior_level` / display `unassessed · prior high`).  
- `/stay` and `/release` block until `assess()` runs **this process**, unless force + reason.  
- `/trust clear` is an explicit **human claim** (`method: clear_claim`), logged as such — empty flags = your word, not a sensor.  
- Policy (LITE), not public Zero-Gate identity.

## Consequences

- Opening TUI after yesterday’s high still requires `/trust` tonight.  
- Fastest theater path (`/trust clear`) is still possible but Contrail labels it `clear_claim`.  
- Override path remains for emergency after reason is logged.

## Proof

```bash
ruby scripts/oi1-lived-proof.rb           # tmp
ruby scripts/oi1-lived-proof.rb --live    # writes real Contrail
```
