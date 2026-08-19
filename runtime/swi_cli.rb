#!/usr/bin/env ruby
# frozen_string_literal: true
# SWI day mode — Standard Work Instruction pocket (human checklist).
# Logs each step to Contrail. Does not auto-decide Stay/Release.
# Module 8 plugins optional at Step 4 — never override kernel.

require "fileutils"
require "time"
require_relative "constitution_loader"
require_relative "contrail"
require_relative "gate"
require_relative "sabbath"
require_relative "signal_trust"
require_relative "decision_state"
require_relative "anchors"
require_relative "module8_plugins"

root = File.expand_path("..", __dir__)
state = File.expand_path("~/.afterstring")
FileUtils.mkdir_p(state)

const = Afterstring::Constitution.new(root)
contrail = Afterstring::Contrail.new(File.join(state, "contrail.jsonl"))
gate = Afterstring::Gate.new(const)
hours = const.iaa.dig("lite", "sabbath_hours") || 24
sabbath = Afterstring::Sabbath.new(File.join(state, "sabbath.json"), interval_hours: hours)
trust = Afterstring::SignalTrust.new(File.join(state, "signal_trust.json"))
anchors = Afterstring::Anchors.new(File.join(state, "anchors.json"), repo_root: root)
m8 = Afterstring::Module8Plugins.new(File.join(state, "module8_plugins.json"))

require_relative "pocket"
# P2: one operational Pocket only (public v9.1). Layer 0 poem is seal text, not a second protocol.
pocket_body = Afterstring::Pocket.summary_lines.map { |l| "     #{l}" }
steps = [
  "0 BOOT — Stand in your clearing. Breathe. \"I am here. The bend remembers.\"",
  "1 BIOS — Recall 1 Cor 13 / Faith · Hope · Love boot.",
  "2 MATH — Name the 1/0: Stay or Release if harm (assess harm + recover).",
  "3 MEANING — Does this create Presence or Harm?",
  "4 POCKET #{Afterstring::Pocket::VERSION} (#{Afterstring::Pocket.size} steps — only operational protocol):",
  *pocket_body,
  "   optional Module 8 plugins: afterstring plugins check [ids] --yes …",
  "5 EMBODIED — One non-fakeable act (breath, photo, touch bench, guitar…).",
  "6 COUNCIL — If major: afterstring council \"topic\" (optional host only).",
  "7 CLOSE — TUI Decision: /stay <h> <r> · /release <h> <r> [lesson] · q=quit only",
  "   PERMIT (tools): afterstring grokbuild --action KIND [--approved]"
]

puts "════════════════════════════════════════"
puts "AFTERSTRING SWI — Day mode (v0.5-oi1 LITE)"
puts "════════════════════════════════════════"
puts "Mode: #{gate.mode}  Sabbath: #{sabbath.due? ? 'DUE' : sabbath.remaining_human}"
puts "Signal_trust: #{trust.last_result ? trust.last_result.level : 'unassessed'}"
puts "Module 8 plugins: #{m8.last_result ? "flags=#{m8.last_result.flags.join(',')}" : 'optional (afterstring plugins)'}"
puts "Anchors: #{anchors.list.size}  ℰ₁₃ product: #{format('%.4f', gate.e13_product)}"
puts "Bag: #{anchors.get('bench-origin')&.label || 'bench-origin (seed)'}"
puts
steps.each { |s| puts "  #{s}" }
puts
if m8.last_result && !m8.last_result.flags.empty?
  puts "Last Module 8 guidance:"
  puts "  #{m8.last_result.guidance}"
  puts
end
puts "Presence ≡ Never Harm. Firmware ≠ love."
puts "Module 8 plugins never override 1/0. Human Kernel holds final 1/0."
puts "Canonicity (multi-door): X @i_am_Paddy_Sham · onebyzero.io/afterstring-theory · onebyzero.io · constitution/"
puts "Grokipedia may lag. Formula rank: GPSL-full = Layer 0; pocket/dual = teaching."
puts "LITE: harm+recoverable → pause (policy). Public Zero-Gate spirit may persist. Release if stay harms."
puts "Let it stay → ∞ ❤️"
puts "════════════════════════════════════════"

contrail.append(
  purpose: "swi_day_mode",
  tier: 0,
  approval: "human",
  outcome: "ok",
  actor: "swi_cli",
  payload: {
    "sabbath_due" => sabbath.due?,
    "e13_product" => gate.e13_product,
    "trust" => trust.last_result&.level.to_s,
    "anchors" => anchors.list.size,
    "module8_flags" => m8.last_result&.flags || []
  }
)

warn "Contrail: swi_day_mode logged. Open Pocket in TUI: ./bin/afterstring tui → /pocket or /swi"
warn "Permit ≠ Decide. q = quit only (not Release). Trust defaults unassessed this session."
warn "Public doors: papers/research/love-theorem-public-doors-2026-08-15.md"
