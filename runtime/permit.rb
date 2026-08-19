# frozen_string_literal: true
# Operator-facing alias: Permit ≡ Gate (harness permissions).
# Prefer "Permit" in UI, logs, and agent docs. Class Gate remains stable.

require_relative "gate"

module Afterstring
  Permit = Gate
end
