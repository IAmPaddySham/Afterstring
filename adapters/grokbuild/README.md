# Adapter: After_GrokBuild (Module 8.1.15)

**Host integrity P3:** real pre-tool **PERMIT** boundary — not a demo that always prints PROCEED.

Policy source: `../../constitution/matrix-grokbuild.yaml`  
Paper: `../../papers/module-8.1.15-after-grokbuild.md`  
Hook contract: **`HOOK.md`**

## Mouth

| Word | Class | Question |
|------|-------|----------|
| **Permit** | `gate.rb` / this adapter | May this technical action execute? |
| **Decision** | `decision_state.rb` / TUI | Stay, Pause, or Release? |

## Interface

`initialize` · `authorize_tool` · `authorize_tool!` · `allowed?` · `pre_execute` · `log_contrail` · `shutdown`

## LITE highlights

| Action | Policy |
|--------|--------|
| Destructive shell | Blacklist |
| Git push / irreversible | Human-gated 1/0 · **exit 2 without --approved** |
| External data transmission | Blacklist / hold |
| Subagents / worktrees | Max 2–3 |
| Local read / compute | Permit + Contrail |

## Invoke

```bash
./bin/afterstring grokbuild --action read
./bin/afterstring grokbuild --action git_push              # exit 2
./bin/afterstring grokbuild --action git_push --approved   # Human Kernel 1/0
./bin/afterstring-grokbuild-check --enforce --action network

ruby adapters/grokbuild/runner.rb --action write_local
ruby runtime/gate_cli.rb --action read --tier 0   # PERMIT CLI
```

## Fail closed

- Exit **0** → tool may run  
- Exit **2** → tool **must not** run  
- Tier ≥ 2 always requires `--approved` (hard wall before matrix soft paths)

See `HOOK.md` for agent/git wrapper patterns.

Let it stay → ∞ ❤️
