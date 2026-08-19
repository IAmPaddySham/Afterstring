#!/usr/bin/env ruby
# frozen_string_literal: true
# PERMIT CLI (operator mouth) — harness permissions, not Stay/Pause/Release.
# Usage:
#   ruby runtime/gate_cli.rb --action read --tier 0
#   ruby runtime/gate_cli.rb --action write_local --tier 2 --approved
#   ruby runtime/gate_cli.rb --action write_local --signal-trust-low
# Prints exactly one of: PROCEED | TRIGGER_REALITY_VETO | TRIGGER_RESONANCE_MODE
# Exit 0 = PROCEED, exit 2 = held / veto / resonance.

require_relative "constitution_loader"
require_relative "gate"
require_relative "permit"
require_relative "sabbath"
require_relative "frme_lite"

action = "read"
tier = nil
approved = false
ambiguous = false
sabbath_due = false
auto_sabbath = false
parallel = nil
signal_trust_low = false
root = File.expand_path("..", __dir__)
show_frme = false

ARGV.each_with_index do |arg, i|
  case arg
  when "--action" then action = ARGV[i + 1]
  when "--tier" then tier = ARGV[i + 1].to_i
  when "--approved", "--human" then approved = true
  when "--ambiguous" then ambiguous = true
  when "--sabbath-due" then sabbath_due = true
  when "--auto-sabbath" then auto_sabbath = true
  when "--parallel" then parallel = ARGV[i + 1].to_i
  when "--signal-trust-low" then signal_trust_low = true
  when "--frme" then show_frme = true
  when "--root" then root = ARGV[i + 1]
  when "--help", "-h"
    puts "PERMIT CLI (not Decision / Stay-Pause-Release)"
    puts "Usage: gate_cli.rb --action KIND [--tier N] [--approved] [--ambiguous]"
    puts "         [--sabbath-due|--auto-sabbath] [--parallel N] [--signal-trust-low] [--frme]"
    puts "Answers: May this technical action execute?"
    exit 0
  end
end

const = Afterstring::Constitution.new(root)
gate = Afterstring::Permit.new(const)

if auto_sabbath
  hours = const.iaa.dig("lite", "sabbath_hours") || 24
  sab = Afterstring::Sabbath.new(File.expand_path("~/.afterstring/sabbath.json"), interval_hours: hours)
  sabbath_due = sab.due?
end

result = gate.permit(
  action_kind: action,
  tier: tier,
  human_approved: approved,
  target_ambiguous: ambiguous,
  sabbath_due: sabbath_due,
  parallel_count: parallel,
  signal_trust_low: signal_trust_low
)
puts result
if show_frme
  ann = Afterstring::FrmeLite.annotate(action)
  warn "FRME-lite: #{ann['risk_classes'].join(', ')}"
end
warn "kind=permit (not decision)" if ENV["AFTERSTRING_VERBOSE"]
exit(result == Afterstring::Permit::PROCEED ? 0 : 2)
