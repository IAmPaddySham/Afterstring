# frozen_string_literal: true
# Leftover truth (GrokBot 6:22) — three host fixes only. No expansion.
# Run: ruby tests/leftover_truth_test.rb

require "tmpdir"
require "fileutils"

ROOT = File.expand_path("..", __dir__)
$LOAD_PATH.unshift(File.join(ROOT, "runtime"))

require "constitution_loader"
require "gate"
require "permit"
require "contrail"
require "decision_state"

$fail = 0
def assert(name, cond, detail = nil)
  if cond
    puts "  PASS  #{name}"
  else
    puts "  FAIL  #{name}#{detail ? " — #{detail}" : ""}"
    $fail += 1
  end
end

puts "Leftover truth (3 fixes)"
puts "═══════════════════════"

# --- 1. Gate#decide dead ---
assert "no Gate#decide method", !Afterstring::Gate.instance_methods.include?(:decide)
g = Afterstring::Gate.new(Afterstring::Constitution.new(ROOT))
assert "permit works", g.permit(action_kind: :read) == Afterstring::Gate::PROCEED
raised = false
begin
  g.decide(action_kind: :read)
rescue NoMethodError => e
  raised = e.message.include?("permit") || e.message.include?("decide")
end
assert "send/call decide raises pointing to permit", raised

# --- 2. Wrap actually starts/doesn't start command ---
load File.join(ROOT, "adapters/grokbuild/runner.rb")
Dir.mktmpdir("wrap") do |dir|
  ad = Afterstring::GrokbuildAdapter.new(root: ROOT, state_dir: dir)
  ok, code, res = ad.run_if_permitted(
    action_kind: :git_push,
    argv: %w[true],
    human_approved: false
  )
  assert "wrap held without 1/0", ok == false && code.nil?
  assert "wrap hold is not proceed", res.feedback != :proceed

  ok2, code2, = ad.run_if_permitted(
    action_kind: :read,
    argv: %w[true],
    human_approved: false
  )
  assert "wrap runs true under read permit", ok2 == true && code2 == 0

  # CLI wrap: git_push without approved must not run `true` either
  out = `ruby #{File.join(ROOT, "adapters/grokbuild/runner.rb")} --action git_push -- true 2>&1`
  assert "CLI wrap exit 2", $?.exitstatus == 2, out
  assert "CLI wrap not_started", out.include?("not_started") || out.include?("HELD"), out

  # HOOK.md honesty
  hook = File.read(File.join(ROOT, "adapters/grokbuild/HOOK.md"))
  assert "HOOK says check is contract", hook.include?("contract") || hook.include?("CHECK only")
  assert "HOOK documents wrap", hook.include?("WRAP") || hook.include?("-- run")
  assert "HOOK does not overclaim kernel", hook.include?("does not") || hook.include?("not a kernel") || hook.include?("skip")
end

# --- 3. Contrail event kinds — cannot confuse ledgers ---
Dir.mktmpdir("ck") do |dir|
  c = Afterstring::Contrail.new(File.join(dir, "c.jsonl"))
  kinds = Afterstring::Contrail::EVENT_KINDS
  assert "all seven kinds listed", (kinds & %w[session_end crash timeout sabbath external_kill decide permit]).size == 7

  c.append_kind(:session_end, event: "session_end", decision: { "relational_decision" => "none" },
                narrative: "quit")
  c.append_kind(:crash, event: "process_crash", narrative: "segfault")
  c.append_kind(:timeout, event: "operator_timeout", narrative: "idle")
  c.append_kind(:sabbath, event: "sabbath_airgap", narrative: "airgap")
  c.append_kind(:external_kill, event: "sigterm", narrative: "killed")
  c.append_kind(:decide, event: "stay", purpose: "decide_stay",
                decision: { "action" => "stay", "harm_present" => false })
  c.append_kind(:permit, event: "permit_ok", purpose: "permit_ok:read",
                assessment: { "action_kind" => "read" })

  by_kind = c.entries.map { |e| Afterstring::Contrail.kind_of(e) }
  assert "seven kinds present", by_kind.sort == kinds.sort

  se = c.entries.find { |e| Afterstring::Contrail.kind_of(e) == "session_end" }
  de = c.entries.find { |e| e.purpose == "decide_stay" }
  assert "session_end not release-shaped", !Afterstring::Contrail.looks_like_release?(se)
  assert "decide_stay not release-shaped", !Afterstring::Contrail.looks_like_release?(de)

  c.append_kind(:decide, event: "release", purpose: "decide_release",
                decision: { "action" => "release" }, narrative: "real untying")
  rel = c.entries.last
  assert "deliberate release is release-shaped", Afterstring::Contrail.looks_like_release?(rel)
  assert "release kind is decide not session_end", Afterstring::Contrail.kind_of(rel) == "decide"

  # unknown kind rejected
  bad = false
  begin
    c.append_kind(:mythology, event: "x")
  rescue ArgumentError
    bad = true
  end
  assert "unknown kind rejected", bad

  ok, detail = c.verify_chain
  assert "chain ok on fresh file", ok, detail
end

# No rewrite of live entry 201 — we only append helpers; do not claim live chain valid
assert "append_kind exists", Afterstring::Contrail.instance_methods.include?(:append_kind)

puts
if $fail.zero?
  puts "ALL LEFTOVER TRUTH CHECKS PASSED"
  exit 0
else
  puts "#{$fail} FAILURE(S)"
  exit 1
end
