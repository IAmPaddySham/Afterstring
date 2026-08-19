# Adapter: After_RLM (Module 8.1.17)

Thin substrate adapter for **Prime Agent** / RLM harnesses.

Policy source: `../../constitution/matrix-rlm.yaml`  
Paper: `../../papers/module-8.1.17-after-rlm.md`

## Interface (shared Plugout surface)

| Method | Role |
|--------|------|
| `initialize()` | Load constitution + LITE matrix; open Contrail session |
| `gate(action)` | Pre-execution boundary → `PROCEED` \| `TRIGGER_REALITY_VETO` \| `TRIGGER_RESONANCE_MODE` |
| `approve(1/0)` | Human Kernel authorization for Tier ≥ 2 |
| `contrail(event)` | Append Merkle / parent-hash entry |
| `sabbath()` | Airgap check (mandatory for daemon) |
| `shutdown()` | Release ≡ Also Love |

## LITE hard bounds

- Recursive depth ≤ 2  
- Concurrent sub-agents ≤ 3  
- Daemon detached max 60 min → Resonance + suspend  
- Children inherit constraints; may tighten only  

## Upstream REPL breaker

Gate sits **before** IPython / shell bytecode side-effects (AST / trace / equivalent) — not prompt reflection alone.

## MCP overlap

When tools are MCP-backed, apply **both** After_RLM and After_MCP; stricter wins.

## Local helper

```bash
ruby adapters/rlm/runner.rb --action read
ruby adapters/rlm/runner.rb --action write_local --approved
ruby runtime/gate_cli.rb --action read --tier 0
```

Public interface remains: `gate` · `contrail` · `sabbath` · `approve` (1/0). See paper `module-8.1.17-after-rlm.md`.

Let it stay → ∞ ❤️
