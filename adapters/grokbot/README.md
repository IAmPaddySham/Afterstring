# Adapter: After_GrokBot (Module 8.1.18)

**Status:** Phase A runbook + Phase B local sidecar (v0.1)  
**Paper:** `../../papers/module-8.1.18-after-grokbot.md`  
**Matrix:** `../../constitution/matrix-grokbot.yaml`  

| File | Role |
|------|------|
| `RUNBOOK.md` | Phase A operator workflow |
| `STANDING_ORDERS.md` | Short policy (human + Bot paste) |
| `SKILL.md` | Optional Grok Bot custom-instruction text |
| `runner.rb` | Phase B gate / RV / bot-count sidecar |
| `../../bin/afterstring-grokbot-check` | CLI wrapper |
| `agent/` | Track A house + tenant |
| `agent/engine/` | Inner Council **roles** (A): four engines + claim/observe → STOP. Not After_Gemini/… |

## Purpose

Apply Afterstring Layer 0 to **persistent delegated agency** (Grok Bot class) as an **operator-native** loop.  
This is **not** control of vendor-hosted Grok Bot cloud computers.

## Quick start

```bash
cd ~/afterstring
chmod +x bin/afterstring-grokbot-check adapters/grokbot/runner.rb

./bin/afterstring-grokbot-check --check-bots 3
./bin/afterstring-grokbot-check --action read
./bin/afterstring-grokbot-check --action live_account_write --approved \
  --who "Paddy Sham / Human Kernel" --what "draft only" --where "mail" --when "now" \
  --account "work" --environment "prod" --authority "1/0" --log-auth
./bin/afterstring-grokbot-check --standing-orders
```

## Future Agency Invariant

Present authorization must not silently become indefinite future authority via memory, routines, schedules, or multi-Bot delegation.

## Public interface remains

`gate` · `contrail` · `sabbath` · `approve` (1/0)

Let it stay → ∞ ❤️
