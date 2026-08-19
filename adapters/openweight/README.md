# After_OpenWeight adapter (8.1.19) — LITE

**Does not** download weights, start Ollama/vLLM, or run inference.  
Pre-execution constitutional check for open-weight / local sovereign intents.

## Paper

`papers/module-8.1.19-after-openweight.md` (DRAFT for Council)

## Matrix

`constitution/matrix-openweight.yaml`

## Usage

```bash
# Status (hardware hints + instance registry + sabbath)
./bin/afterstring-openweight-check --status
# or
ruby adapters/openweight/runner.rb --status

# Gate-check an intent
ruby adapters/openweight/runner.rb --intent infer --model "glm-5.2-q4"
ruby adapters/openweight/runner.rb --intent fine_tune --approved
ruby adapters/openweight/runner.rb --intent network_pull   # likely VETO/RESONANCE in LITE

# Register load *intent* only (no weights)
ruby adapters/openweight/runner.rb --register --model "deepseek-v4-flash" --approved
```

## Intents

| Intent | Gate kind | Notes |
|--------|-----------|-------|
| check / list | read | always LITE-safe when sabbath allows read |
| load | load_model | Tier 1 · Contrail |
| infer / chat | local_inference | sabbath-aware |
| fine_tune / lora | fine_tune | human-gated Tier 2 |
| multi_instance | multi_instance | dissipation-limited ≤ 3 |
| spawn | spawn_instance | blacklist |
| network_pull | network | LITE external hold |
| live_side_effect | live_account_write | Tier 3 human |

State: `~/.afterstring/openweight_instances.json`

## Ollama (installed on this Mac)

```bash
export PATH="$HOME/bin:$PATH"
open -a Ollama
ollama list                    # should show qwen3:8b (~5.2 GB)
ollama run qwen3:8b            # interactive

# Gate-then-infer wrapper
./adapters/openweight/infer.sh --approved "What is Presence ≡ Never Harm in one sentence?"
./adapters/openweight/infer.sh --interactive
```

Weights live under `~/.ollama` (outside the afterstring tree).  
If **sabbath is due**, the Ruby pre-gate holds even with `--approved` (I_s). Mark `/sabbath` after real rest, or use `ollama run` directly with eyes open that the constitutional check held.

System constitution text: `SYSTEM_PROMPT_LITE.md`

Presence ≡ Never Harm. Firmware ≠ love.
