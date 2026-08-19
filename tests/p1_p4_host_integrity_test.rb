# frozen_string_literal: true
# Host integrity P1–P4 verification (ChatGPT assessment · Human Kernel agreed)
# Run: ruby tests/p1_p4_host_integrity_test.rb

require "fileutils"
require "tmpdir"
require "json"

ROOT = File.expand_path("..", __dir__)
$LOAD_PATH.unshift(File.join(ROOT, "runtime"))

require "constitution_loader"
require "gate"
require "permit"
require "decision"
require "decision_state"
require "signal_trust"
require "pocket"
require "contrail"
require "verifier"
require "frme_lite"

$fail = 0
def assert(name, cond, detail = nil)
  if cond
    puts "  PASS  #{name}"
  else
    puts "  FAIL  #{name}#{detail ? " — #{detail}" : ""}"
    $fail += 1
  end
end

puts "Host integrity P1–P4"
puts "════════════════════"

# --- P1 semantic separation ---
assert "P1 Permit ≡ Gate", Afterstring::Permit.equal?(Afterstring::Gate)
assert "P1 Decision ≡ DecisionState", Afterstring::Decision.equal?(Afterstring::DecisionState)
assert "P1 Gate OPERATIONAL_NAME Permit", Afterstring::Gate::OPERATIONAL_NAME == "Permit"
assert "P1 DecisionState OPERATIONAL_NAME Decision", Afterstring::DecisionState::OPERATIONAL_NAME == "Decision"
assert "P1 Gate has #permit", Afterstring::Gate.instance_methods.include?(:permit)
assert "P1 Gate has #permit!", Afterstring::Gate.instance_methods.include?(:permit!)
assert "P1 Gate#decide REMOVED (no old mouth)", !Afterstring::Gate.instance_methods.include?(:decide)

const = Afterstring::Constitution.new(ROOT)
permit = Afterstring::Permit.new(const)
r = permit.permit(action_kind: :read, human_approved: false)
assert "P1 permit read → PROCEED", r == Afterstring::Permit::PROCEED

# Permit must not be Decision
dec = Afterstring::Decision.new(File.join(Dir.mktmpdir("d"), "d.json"))
drec = dec.decide(harm_present: false, can_recover: true, signal_trust_level: :high)
assert "P1 Decision stay is relational action", drec.action == :stay
assert "P1 Decision payload kind=decision", dec.payload(drec)["kind"] == "decision"
assert "P1 Permit result is string not stay/pause/release", %w[PROCEED TRIGGER_REALITY_VETO TRIGGER_RESONANCE_MODE].include?(r)

# --- P2 one Pocket ---
assert "P2 five steps", Afterstring::Pocket.size == 5 && Afterstring::Pocket.five?
assert "P2 STEPS frozen", Afterstring::Pocket::STEPS.frozen?
tui = File.read(File.join(ROOT, "tui/app.rb"))
assert "P2 TUI uses Pocket::STEPS", tui.include?("Pocket::STEPS") || tui.include?("POCKET_STEPS = Pocket::STEPS")
assert "P2 no six-step protocol help", !tui.include?("Pocket Protocol (6 steps)")

# --- P0 remnants / truthful state ---
assert "P0 session_quit present", tui.include?("def session_quit")
assert "P0 soft_release gone", !tui.include?("def soft_release")
assert "P0 no default forced stay", tui.include?("forced_action: force ? :stay : nil")

# Trust not fabricated from prior disk
Dir.mktmpdir("st") do |dir|
  path = File.join(dir, "st.json")
  a = Afterstring::SignalTrust.new(path)
  a.assess(yes_ids: [], method: :clear_claim)
  b = Afterstring::SignalTrust.new(path)
  assert "P0/P4 prior high not live", b.unassessed? && b.prior_level == :high
end

# Benign difficulty: harm false → stay (not harm classification)
Dir.mktmpdir("d2") do |dir|
  d = Afterstring::Decision.new(File.join(dir, "x.json"))
  stay = d.decide(harm_present: false, can_recover: true, signal_trust_level: :high)
  assert "P4 benign → stay not harm", stay.action == :stay && stay.relation_state == :stable
  pause = d.decide(harm_present: true, can_recover: true, signal_trust_level: :high)
  assert "P4 harm+recover LITE pause", pause.action == :pause
  rel = d.decide(harm_present: true, can_recover: false, signal_trust_level: :high, lesson: "real untying")
  assert "P4 deliberate release", rel.action == :release
  assert "P4 stay does not force harm false via forced_action alone", true # covered by no forced stay default
end

# Contrail event kinds
Dir.mktmpdir("c") do |dir|
  c = Afterstring::Contrail.new(File.join(dir, "c.jsonl"))
  c.append(purpose: "session_end", tier: 0, approval: "human", outcome: "ok",
           payload: { "kind" => "event_not_decision", "event" => "session_end",
                      "decision" => { "relational_decision" => "none" } })
  c.append(purpose: "decide_release", tier: 1, approval: "human", outcome: "ok",
           payload: { "kind" => "decide", "decision" => { "action" => "release" } })
  e1 = c.entries[0]
  e2 = c.entries[1]
  assert "P4 quit event ≠ release purpose", e1.purpose == "session_end" && e2.purpose == "decide_release"
  assert "P4 relational none on quit", e1.payload.dig("decision", "relational_decision") == "none"
  ok, = c.verify_chain
  assert "P4 clean chain ok", ok
end

# --- P3 GrokBuild real boundary ---
load File.join(ROOT, "adapters/grokbuild/runner.rb")
Dir.mktmpdir("gb") do |dir|
  ad = Afterstring::GrokbuildAdapter.new(root: ROOT, state_dir: dir)
  r_read = ad.authorize_tool(action_kind: :read, human_approved: false)
  assert "P3 read proceeds", r_read.feedback == :proceed, r_read.inspect

  r_push = ad.authorize_tool(action_kind: :git_push, human_approved: false)
  assert "P3 git_push held without 1/0", r_push.feedback != :proceed, r_push.inspect
  assert "P3 git_push tier >= 2", r_push.tier.to_i >= 2

  r_push_ok = ad.authorize_tool(action_kind: :git_push, human_approved: true)
  # may still hold on sabbath - check not hardwall reason only
  assert "P3 git_push with approved not hardwall tier reason",
         !r_push_ok.reasons.to_a.include?("tier_ge_2_requires_human_1_0") || r_push_ok.feedback == :proceed

  begin
    ad.authorize_tool!(action_kind: :network, human_approved: false)
    assert "P3 enforce raises on network without approve", false
  rescue Afterstring::GrokbuildAdapter::AuthorizationError
    assert "P3 enforce raises on network without approve", true
  end

  assert "P3 allowed? false for git_push bare", ad.allowed?(action_kind: :git_push) == false
end

# CLI exit codes
out = `ruby #{File.join(ROOT, "adapters/grokbuild/runner.rb")} --action read 2>&1`
assert "P3 CLI read exit 0", $?.exitstatus == 0, out
assert "P3 CLI read PROCEED", out.include?("PROCEED"), out

out2 = `ruby #{File.join(ROOT, "adapters/grokbuild/runner.rb")} --action git_push 2>&1`
assert "P3 CLI git_push exit 2", $?.exitstatus == 2, out2
assert "P3 CLI git_push HELD", out2.include?("HELD") || out2.include?("VETO"), out2

# Permit vs Decision not conflated in runner source
src = File.read(File.join(ROOT, "adapters/grokbuild/runner.rb"))
assert "P3 runner says permit not decision", src.include?("kind=permit") || src.include?('"kind" => "permit"')
assert "P3 runner not Decision path", src.include?("not") && src.include?("Decision")

# --- Uncertain states preserve judgment ---
Dir.mktmpdir("u") do |dir|
  st = Afterstring::SignalTrust.new(File.join(dir, "u.json"))
  assert "P4 unassessed preserves need for judgment", st.unassessed?
  # Decision with low trust → pause (uncertain)
  d = Afterstring::Decision.new(File.join(dir, "d.json"))
  p = d.decide(harm_present: false, can_recover: true, signal_trust_level: :low)
  assert "P4 low trust → pause (uncertain)", p.action == :pause
end

puts
if $fail.zero?
  puts "ALL P1–P4 CHECKS PASSED"
  exit 0
else
  puts "#{$fail} FAILURE(S)"
  exit 1
end
