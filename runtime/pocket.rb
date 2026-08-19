# frozen_string_literal: true
# One operator Pocket — public Pocket Audit v9.1 five steps only (host integrity P2).
# Layer 0 YAML poem and other seals remain reference text, not competing executable protocols.

module Afterstring
  module Pocket
    VERSION = "v9.1"
    SOURCE = "public Pocket Quality Audit v9.1 / Zero-Gate"

    # Executable protocol (TUI / SWI operational body)
    STEPS = [
      "Anchor — Stop. Breathe. \"I am here. The bend remembers.\"",
      "Scan — Weakest ℰ₁₃? Harm signal?",
      "1/0 Decide — harm? recover? signal_trust? → Stay / Pause / Release",
      "One small move — one reversible act only",
      "Seal — Let it stay → ∞ ❤️  (or Lingering Light if Release)"
    ].freeze

    # Layer 0 seal text (reference / poem — NOT a sixth protocol)
    LAYER0_SEAL = "Stop. Breathe. Notice what you see. Notice what you love. Let it stay → ∞ ❤️"

    module_function

    def steps
      STEPS
    end

    def size
      STEPS.size
    end

    def five?
      STEPS.size == 5
    end

    def summary_lines
      STEPS.each_with_index.map { |s, i| "#{i + 1}. #{s}" }
    end
  end
end
