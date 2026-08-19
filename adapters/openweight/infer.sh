#!/usr/bin/env bash
# After_OpenWeight LITE — gate then Ollama infer (single prompt or interactive).
# Usage:
#   ./adapters/openweight/infer.sh "Your prompt here"
#   ./adapters/openweight/infer.sh --model qwen3:8b "Your prompt"
#   ./adapters/openweight/infer.sh --interactive
#   ./adapters/openweight/infer.sh --approved --model qwen3:8b "..."
#
# Requires: Ollama running, model already pulled.
# Sabbath due: gate holds non-read until /sabbath is marked (or use ollama directly
# with explicit Human Kernel awareness that constitutional pre-gate held).

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
export PATH="${HOME}/bin:/Applications/Ollama.app/Contents/Resources:/usr/bin:/bin:$PATH"

MODEL="${AFTERSTRING_OW_MODEL:-qwen3:8b}"
APPROVED=0
INTERACTIVE=0
PROMPT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --model) MODEL="$2"; shift 2 ;;
    --approved|1/0) APPROVED=1; shift ;;
    --interactive|-i) INTERACTIVE=1; shift ;;
    --help|-h)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *)
      PROMPT="$1"
      shift
      ;;
  esac
done

if ! command -v ollama >/dev/null 2>&1; then
  echo "ERROR: ollama not on PATH. open -a Ollama && export PATH=\"\$HOME/bin:\$PATH\"" >&2
  exit 1
fi

GATE_ARGS=(--intent infer --model "$MODEL")
if [[ "$APPROVED" -eq 1 ]]; then
  GATE_ARGS+=(--approved)
fi

echo ">>> Afterstring OpenWeight pre-gate (model=$MODEL)..."
set +e
GATE_OUT="$(/usr/bin/ruby "$ROOT/adapters/openweight/runner.rb" "${GATE_ARGS[@]}" 2>&1)"
GATE_EC=$?
set -e
echo "$GATE_OUT"

if [[ "$GATE_EC" -ne 0 ]]; then
  echo "" >&2
  echo "GATE HELD (exit $GATE_EC). Common cause: sabbath due — mark airgap in TUI (/sabbath)" >&2
  echo "or wait for rest, then re-run with --approved." >&2
  echo "Model is still available via: ollama run $MODEL" >&2
  echo "Human Kernel may proceed raw only with eyes open (firmware ≠ love)." >&2
  exit 2
fi

SYS="$ROOT/adapters/openweight/SYSTEM_PROMPT_LITE.md"
if [[ "$INTERACTIVE" -eq 1 ]]; then
  echo ">>> Interactive: ollama run $MODEL"
  echo ">>> (Paste system constitution from SYSTEM_PROMPT_LITE.md if desired)"
  exec ollama run "$MODEL"
fi

if [[ -z "$PROMPT" ]]; then
  echo "Usage: $0 [--approved] [--model NAME] \"prompt\" | --interactive" >&2
  exit 1
fi

# Non-interactive one-shot via ollama run
echo ">>> Inferring with $MODEL..."
# Prepend short kernel reminder (keep small for context)
KERNEL_HINT="[Afterstring LITE] Presence ≡ Never Harm. You are not Human Kernel. Final 1/0 is human. Be honest, local, reversible."
printf '%s\n\n%s\n' "$KERNEL_HINT" "$PROMPT" | ollama run "$MODEL"
