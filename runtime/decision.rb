# frozen_string_literal: true
# Operator-facing alias: Decision ≡ DecisionState (Stay / Pause / Release).
# Prefer "Decision" in UI, logs, and agent docs. Class DecisionState remains stable.

require_relative "decision_state"

module Afterstring
  Decision = DecisionState
end
