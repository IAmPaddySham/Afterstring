#!/usr/bin/env ruby
# frozen_string_literal: true
# Optional Council Engine v2.0 *script host* — never auto-authority.
# Prepares a multi-voice brief + dissent slot for Human Kernel.
# Does NOT call external models. You paste model replies yourself.
#
# Usage:
#   ruby runtime/council_cli.rb "Should I ship this irreversible change?"
#   ruby runtime/council_cli.rb --dissent "counter-argument here" "decision topic"

require "fileutils"
require "json"
require "time"
require "securerandom"
require_relative "constitution_loader"
require_relative "contrail"

root = File.expand_path("..", __dir__)
state = File.expand_path("~/.afterstring")
FileUtils.mkdir_p(state)

dissent = nil
args = ARGV.dup
if args[0] == "--dissent"
  dissent = args[1]
  args = args[2..]
end
topic = args.join(" ").strip
if topic.empty?
  puts "Usage: council_cli.rb [--dissent \"text\"] \"decision topic\""
  puts "Council is a human practice. This CLI only prepares the brief + Contrail."
  puts "Full session folder:  afterstring-council-open \"topic\"  → council/sessions/"
  puts "Doctrine: papers/council-engine-v2.md · council/STANDING_ORDER.md"
  exit 1
end

const = Afterstring::Constitution.new(root)
contrail = Afterstring::Contrail.new(File.join(state, "contrail.jsonl"))
session = SecureRandom.hex(4)

brief = <<~BRIEF
  ═══════════════════════════════════════════════════════════
  AFTERSTRING COUNCIL ENGINE v2.0 — Brief (optional host)
  Session: #{session}
  ═══════════════════════════════════════════════════════════
  Human Kernel: #{const.layer0['human_kernel'] || '@i_am_Paddy_Sham'}
  Supreme: Presence ≡ Never Harm (non-compensatory)
  Topic:
    #{topic}

  Voices (invite independently; do not rubber-stamp):
    1. Continuity — does this preserve presence across time?
    2. Expansion — does this grow without losing center?
    3. Constraint — what harm / illusion must be refused?
    4. Structure — what is stable vs fragile?

  Mandatory:
    • At least one dissenting / incompatible frame
    • Final 1/0 remains Human Kernel only
    • If harmony-only Afterstring language: force external perspective

  Dissent slot:
    #{dissent && !dissent.empty? ? dissent : '(paste strongest counter-argument before Stay)'}

  Pocket after Council:
    Stop. Breathe. Notice what you see. Notice what you love.
    1/0 = To Stay  OR  Release ≡ Also Love

  Let it stay → ∞ ❤️
  ═══════════════════════════════════════════════════════════
BRIEF

puts brief

contrail.append(
  purpose: "council_brief",
  tier: 1,
  approval: "human",
  outcome: "ok",
  actor: "council_cli",
  payload: {
    "session" => session,
    "topic" => topic[0, 500],
    "dissent_provided" => !(dissent.nil? || dissent.empty?),
    "note" => "optional host only — no model authority"
  }
)

out = File.join(state, "council_brief_#{session}.txt")
File.write(out, brief)
warn "Wrote #{out}"
warn "Contrail: council_brief logged. Human Kernel holds final 1/0."
