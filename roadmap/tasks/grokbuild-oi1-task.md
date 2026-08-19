# GrokBuild Task — Operator Integrity Milestone OI-1 (P0–P1)

**Status:** P0–P1 + OI-1.1 disk honesty (2026-08-14)  
**Scope:** Host truthfulness only. **No new papers, no new modules, no Layer 0 refine.**  
**Principle:** Firmware decides; TUI must not stamp. Source truth ≠ disk truth until lived loop.  
**Test:** `ruby tests/oi1_operator_integrity_test.rb` · `ruby tests/run.rb` · `ruby scripts/oi1-lived-proof.rb`

---

## Done (this cycle)

### P0 — Integrity

| ID | Item | Implementation |
|----|------|----------------|
| P0.1 | `q` = quit only | `session_quit` → Contrail `session_end` / `ok` / `relational_decision: none`. No Release, no harm. |
| P0.2 | `/stay` `/release` assess | Require `<harm y/n> <recover y/n>`; call `DecisionState.decide` **without** `forced_action` unless `/stay force …` / `/release force …` after bench with reason. |
| P0.3 | Trust unassessed | No high seed on boot; block decide until `/trust` (or explicit force with reason). |
| P0.4 | Contrail fidelity | `kind: decide` vs `kind: event_not_decision`; purposes `decide_stay` / `decide_pause` / `decide_release` / `session_end`. |

### P1 — One operator mouth

| ID | Item | Implementation |
|----|------|----------------|
| 4 | One Pocket = public v9.1 five steps | `POCKET_STEPS` in TUI; help text updated |
| 5 | Permit vs Decide | UI labels; `/gate`\|`/permit` = harness; `/stay`\|`/release` = Decide |
| 6 | SWI → Pocket | `/swi` opens Pocket panel (does not print-and-abandon) |
| 7 | Unified CLI | already `./bin/afterstring help\|status\|doctor\|tui` |
| 8 | `/demo` | Virtue 1–9 collapse behind `/demo on` |
| + | `/layers` | One card admitting three maps |

### LITE policy (documented, not smuggled)

`harm_present && can_recover` → **`:pause`** in `decision_state.rb` (stricter than public “persist if recoverable”). Keep as LITE caution until Human Kernel seals alignment with public Zero-Gate.

---

## Explicit non-goals (still)

- No new papers / 8.1.20 / Layer 0 refine / corpus expansion  
- No Platinum claim for 8.1.19 until OI-1 operator path stable in daily use  
- P2 (real GrokBuild pre-tool hook) **not** in this PR  

---

## P2 backlog (next cycle)

1. Wire `adapters/grokbuild/runner.rb` as real pre-tool hook (Tier ≥ 2 → `afterstring-openweight-check` / gate)  
2. Artifact Identity 8.1.19 enforcement  
3. Optional: align harm+recover with public persist **or** leave LITE pause with permanent ADR  
4. PATH install for `afterstring`  
5. CLI SWI checklist text → same five Pocket steps  

---

## First PR proof

```bash
cd ~/afterstring
ruby tests/oi1_operator_integrity_test.rb
# Manual: ./bin/afterstring tui
#   q     → contrail session_end ok
#   /stay → prompts for h/r (no stamp)
#   /trust clear then /stay n y → decide_stay
#   /release y n lesson → Release only if firmware says release
```

Let it stay → ∞ ❤️
