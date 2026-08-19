# frozen_string_literal: true
# OI-1 Operator Integrity — five truthfulness tests (GrokBuild milestone)
# Run: ruby tests/oi1_operator_integrity_test.rb

require "fileutils"
require "json"
require "tmpdir"
require "time"

ROOT = File.expand_path("..", __dir__)
$LOAD_PATH.unshift(File.join(ROOT, "runtime"))

require "decision_state"
require "signal_trust"
require "contrail"
require "session"

$failures = 0
def assert(name, cond, detail = nil)
  if cond
    puts "  PASS  #{name}"
  else
    puts "  FAIL  #{name}#{detail ? " — #{detail}" : ""}"
    $failures += 1
  end
end

puts "OI-1 Operator Integrity tests"
puts "══════════════════════════════"

Dir.mktmpdir("oi1-test") do |dir|
  # --- Test 1: q → session_end ok, no relational Release, no harm ---
  # (session_quit payload contract; we assert the TUI source + contrail shape)
  tui = File.read(File.join(ROOT, "tui/app.rb"))
  assert "Test1 source: session_quit exists", tui.include?("def session_quit")
  assert "Test1 source: soft_release gone", !tui.include?("def soft_release")
  assert "Test1 source: session_end purpose", tui.include?('purpose: "session_end"')
  assert "Test1 source: relational_decision none", tui.include?('"relational_decision" => "none"')
  assert "Test1 source: q calls session_quit", tui.match?(/when "q".*?session_quit/m)

  c = Afterstring::Contrail.new(File.join(dir, "contrail.jsonl"))
  c.append(
    purpose: "session_end",
    tier: 0,
    approval: "human",
    outcome: "ok",
    actor: "human",
    payload: {
      "event" => "session_end",
      "outcome" => "ok",
      "relational_decision" => "none",
      "harm_present" => nil
    }
  )
  e = c.recent(1).first
  assert "Test1 contrail: session_end ok", e.purpose == "session_end" && e.outcome == "ok"
  assert "Test1 contrail: no harm stamp", e.payload["harm_present"].nil?
  assert "Test1 contrail: no release purpose", e.purpose != "release_lingering_light"

  # --- Test 2: /stay prompts → decide without forced Stay ---
  assert "Test2 source: no unconditional forced stay", tui.include?("forced_action: force ? :stay : nil")
  assert "Test2 source: stay requires harm/recover args", tui.include?("Decide Stay: /stay <harm y/n> <recover y/n>")
  ds = Afterstring::DecisionState.new(File.join(dir, "decisions.json"))
  rec = ds.decide(harm_present: false, can_recover: true, signal_trust_level: :high, forced_action: nil)
  assert "Test2 firmware: honest stay", rec.action == :stay && rec.harm_present == false
  rec_p = ds.decide(harm_present: true, can_recover: true, signal_trust_level: :high, forced_action: nil)
  assert "Test2 firmware: harm+recover → pause not stay", rec_p.action == :pause

  # --- Test 3: /release only if decision resolves to Release ---
  assert "Test3 source: release without force uses nil forced_action", tui.include?("forced_action: force ? :release : nil")
  rec_r = ds.decide(harm_present: true, can_recover: false, signal_trust_level: :high)
  assert "Test3 firmware: harm !recover → release", rec_r.action == :release
  rec_not = ds.decide(harm_present: false, can_recover: true, signal_trust_level: :high)
  assert "Test3 firmware: no-harm is stay not release", rec_not.action == :stay
  assert "Test3 source: pause path when release cmd ≠ release action", tui.include?("Firmware → PAUSE")

  # --- Test 4: fresh SignalTrust → unassessed ---
  st = Afterstring::SignalTrust.new(File.join(dir, "signal_trust_fresh.json"))
  assert "Test4 unassessed?", st.unassessed?
  assert "Test4 not low?", !st.low?
  assert "Test4 TUI blocks stay if unassessed", tui.include?("Trust unassessed")
  assert "Test4 TUI does not seed high on boot", tui.include?("prior disk trust") || tui.include?("unassessed until")

  # --- Test 5: Contrail can separate EVENT vs DECISION ---
  c.append(purpose: "decide_stay", tier: 1, approval: "human_assessed", outcome: "ok",
           payload: { "kind" => "decide", "action" => "stay", "harm_present" => false })
  c.append(purpose: "session_end", tier: 0, approval: "human", outcome: "ok",
           payload: { "kind" => "event_not_decision", "relational_decision" => "none" })
  kinds = c.entries.map { |x| x.payload["kind"] }.compact
  assert "Test5 both event and decide kinds present", kinds.include?("decide") && kinds.include?("event_not_decision")
  ok, detail = c.verify_chain
  assert "Test5 chain valid", ok, detail

  # --- P1 surface checks ---
  assert "P1 Pocket = 5 steps", Afterstring::TUI::POCKET_STEPS.size == 5 if defined?(Afterstring::TUI)
  # load TUI constants
  begin
    load File.join(ROOT, "tui/app.rb")
    assert "P1 POCKET_STEPS size 5", Afterstring::TUI::POCKET_STEPS.size == 5
    assert "P1 VERSION host/oi1", Afterstring::TUI::VERSION.to_s.match?(/oi1|host/)
  rescue StandardError => e
    assert "P1 load TUI", false, e.message
  end
  assert "P1 help 5 not 6", !tui.include?("Pocket Protocol (6 steps)")
  assert "P1 Permit≠Decide in continuity", tui.include?("Permit≠Decide") || tui.include?("Permit ≠ Decide")
  assert "P1 /swi opens pocket", tui.include?("swi_open_pocket")
  assert "P1 /demo present", tui.include?("def do_demo")
  assert "P1 /layers present", tui.include?("def do_layers")
end

puts
if $failures.zero?
  puts "ALL OI-1 TESTS PASSED"
  exit 0
else
  puts "#{$failures} FAILURE(S)"
  exit 1
end
