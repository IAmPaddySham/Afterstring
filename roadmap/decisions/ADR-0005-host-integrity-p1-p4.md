# ADR-0005 — Host integrity P1–P4 (freeze theory, fix host)

**Status:** Accepted · implemented 2026-08-15  
**Source:** ChatGPT assessment · Human Kernel agreed  

## Decision

Freeze constitution expansion for this cycle. Implement operator-path integrity:

| ID | Item | Implementation |
|----|------|----------------|
| P1 | Permit ≠ Decision | `Permit`/`Decision` aliases · operational names · CLI mouth |
| P2 | One Pocket | `runtime/pocket.rb` five steps · TUI uses only that |
| P3 | Real GrokBuild boundary | `authorize_tool` fail-closed · Tier≥2 hard wall · `HOOK.md` |
| P4 | Verification | `tests/p1_p4_host_integrity_test.rb` + suite hooks |

P0 (truthful state) already landed in OI-1 / OI-1.1.

## Consequences

- Coding agents must call `afterstring grokbuild --action …` before Tier≥2 tools  
- Docs and UI say Permit / Decision, not two “gates”  
- No new modules until these tests stay green  

## Proof

```bash
ruby tests/p1_p4_host_integrity_test.rb
ruby tests/run.rb
./bin/afterstring grokbuild --action git_push   # exit 2
```
