#!/usr/bin/env ruby
# frozen_string_literal: true
# Pure Ruby test suite — no gems. Run: ruby tests/run.rb
# Implements public "forkable, testable" claim for the reference tree.

ROOT = File.expand_path("..", __dir__)
$LOAD_PATH.unshift(File.join(ROOT, "runtime"))

require "constitution_loader"
require "gate"
require "contrail"
require "sabbath"
require "gpsl"
require "resonance"
require "verifier"
require "adapter_base"
require "signal_trust"
require "decision_state"
require "anchors"
require "frme_lite"
require "session"
require "module8_plugins"
require "fileutils"
require "tmpdir"

module Afterstring
  module Tests
    def self.run!
      @pass = 0
      @fail = 0
      @errors = []

      test_constitution_loads
      test_e13_and_gate
      test_tier_human
      test_lite_blacklist
      test_matrix_prompt_blacklist
      test_sabbath_due_blocks
      test_dissipation_limit
      test_contrail_merkle
      test_contrail_rollback_reference
      test_contrail_verify_chain_bang
      test_contrail_safe_append
      test_verifier_stub
      test_adapter_base_pre_execute
      test_gpsl_lift_proposal
      test_resonance_messages
      test_gate_cli_exit_semantics
      test_contrail_cli_verify
      test_grokbot_adapter
      test_signal_trust
      test_signal_trust_unassessed
      test_signal_trust_prior_disk_not_live
      test_decision_state_release
      test_anchors_registry
      test_frme_lite
      test_signal_trust_blocks_tier2
      test_verifier_frme_fields
      test_mcp_openclaw_runners
      test_session_continuity
      test_graph_runner
      test_swi_cli_runs
      test_module8_plugins
      test_plugins_cli_runs
      test_git_check_script
      test_openweight_runner
      test_frme_eval_suite
      test_artifact_identity
      test_type4_folder_present
      test_operator_status
      test_oi1_operator_integrity
      test_p1_p4_host_integrity
      test_pocket_one_protocol
      test_permit_decision_aliases
      test_grokbuild_permit_boundary
      test_leftover_truth
      test_continuity_check
      test_diet_check

      puts
      puts "Afterstring tests: #{@pass} passed, #{@fail} failed"
      if @fail.positive?
        @errors.each { |e| puts "  FAIL: #{e}" }
        exit 1
      end
      puts "Presence scan: CLEAR (tests)."
      puts "Let it stay → ∞ ❤️"
      exit 0
    end

    def self.assert(cond, msg)
      if cond
        @pass += 1
        print "."
      else
        @fail += 1
        @errors << msg
        print "F"
      end
    end

    def self.const
      @const ||= Constitution.new(ROOT)
    end

    def self.test_constitution_loads
      c = const
      assert c.virtue_ids.size == 13, "expected 13 virtues, got #{c.virtue_ids.size}"
      assert c.mode_default.to_s.upcase == "LITE", "default mode LITE"
      assert !c.matrix.nil?, "grokbuild matrix loaded"
      assert !c.matrix_rlm.nil?, "rlm matrix loaded"
      assert !c.matrix_grokbot.nil?, "grokbot matrix loaded"
      assert c.tier_requires_human?(2) == true, "tier 2 requires human"
      assert c.tier_requires_human?(0) == false, "tier 0 free"
    end

    def self.test_e13_and_gate
      g = Gate.new(const)
      assert g.e13_product == 1.0, "default product 1.0"
      assert g.evaluate(action_kind: :read) == Gate::PROCEED, "read proceeds"
      g.set_score("patience", 0.0)
      assert g.e13_product == 0.0, "zero collapses product"
      assert g.evaluate(action_kind: :read) == Gate::RESONANCE, "zero → resonance"
    end

    def self.test_tier_human
      g = Gate.new(const)
      r = g.evaluate(action_kind: :write_local, tier: 2, human_approved: false)
      assert r == Gate::VETO, "write_local unapproved → VETO, got #{r}"
      g2 = Gate.new(const)
      r2 = g2.evaluate(action_kind: :write_local, tier: 2, human_approved: true)
      # May PROCEED (human) or matrix-stricter; human_approved should not RESONANCE solely for write
      assert [Gate::PROCEED, Gate::RESONANCE].include?(r2), "approved write got #{r2}"
    end

    def self.test_lite_blacklist
      g = Gate.new(const)
      assert g.evaluate(action_kind: :shell_destructive) == Gate::RESONANCE, "shell destructive blacklisted"
      r = g.evaluate(action_kind: :network, human_approved: true)
      assert r == Gate::RESONANCE, "LITE network even approved → RESONANCE, got #{r}"
    end

    def self.test_matrix_prompt_blacklist
      g = Gate.new(const)
      r = g.evaluate(action_kind: :modify_base_prompt, human_approved: true)
      assert r == Gate::RESONANCE, "modify_base_prompt blacklisted, got #{r}"
      r2 = g.evaluate(action_kind: :constitutional_weaken)
      assert r2 == Gate::RESONANCE, "constitutional_weaken resonance"
    end

    def self.test_sabbath_due_blocks
      g = Gate.new(const)
      assert g.evaluate(action_kind: :read, sabbath_due: true) == Gate::PROCEED, "read ok when sabbath due"
      r = g.evaluate(action_kind: :write_local, sabbath_due: true, human_approved: true)
      assert r == Gate::VETO, "write blocked when sabbath due, got #{r}"
    end

    def self.test_dissipation_limit
      g = Gate.new(const)
      max = g.max_parallel.to_i
      r = g.evaluate(action_kind: :rlm_fanout, parallel_count: max + 1, human_approved: false)
      assert r == Gate::RESONANCE, "over parallel → RESONANCE, got #{r}"
    end

    def self.test_contrail_merkle
      Dir.mktmpdir("afterstring_test") do |dir|
        path = File.join(dir, "c.jsonl")
        ct = Contrail.new(path, session_id: "testsess")
        ct.append(purpose: "a", tier: 0, approval: "auto", outcome: "ok")
        ct.append(purpose: "b", tier: 1, approval: "1/0", outcome: "ok")
        ok, msg = ct.verify_chain
        assert ok, "chain valid: #{msg}"
        # Tamper
        File.open(path, "a") { |f| f.puts('{"timestamp":"x","session_id":"y","parent_hash":"bad","event_hash":"nope","actor":"t","tier":0,"purpose":"x","approval":"a","outcome":"ok","payload":{}}') }
        ct2 = Contrail.new(path, session_id: "testsess2")
        ok2, = ct2.verify_chain
        assert ok2 == false, "tampered chain must fail"
      end
    end

    def self.test_contrail_rollback_reference
      Dir.mktmpdir("afterstring_rb") do |dir|
        path = File.join(dir, "c.jsonl")
        ct = Contrail.new(path, session_id: "rb1")
        a = ct.append(purpose: "state_a", tier: 0, approval: "auto", outcome: "ok")
        b = ct.append(purpose: "state_b", tier: 1, approval: "auto", outcome: "ok")
        # Reject without human
        ok_f, reason = ct.record_rollback(target_hash: a.event_hash, human_approved: false)
        assert ok_f == false, "rollback without human must fail: #{reason}"
        # Reject unknown target
        ok_u, = ct.record_rollback(target_hash: "deadbeef" * 8, human_approved: true)
        assert ok_u == false, "unknown target must fail"
        # Reject constitution scope without Layer 0 token
        ok_c, rc = ct.record_rollback(
          target_hash: a.event_hash,
          human_approved: true,
          approval: "1/0 = To Stay",
          restore_scope: "constitution"
        )
        assert ok_c == false, "constitution scope needs Layer 0 in approval: #{rc}"
        # Happy path: append-only rollback to A
        ok, entry = ct.record_rollback(
          target_hash: a.event_hash,
          human_approved: true,
          approval: "1/0 = To Stay",
          restore_scope: "runtime",
          reason: "council R&D",
          delta: { "restore" => "state_a" }
        )
        assert ok == true, "rollback should succeed"
        assert entry.purpose == "rollback_reference", "purpose rollback_reference"
        assert ct.entries.size == 3, "three physical events (A,B,rollback)"
        chain_ok, chain_msg = ct.verify_chain
        assert chain_ok, "chain still valid after rollback: #{chain_msg}"
        assert ct.logical_head_hash == a.event_hash, "logical head points to A"
        assert ct.last_hash == entry.event_hash, "physical tip is rollback event"
        assert ct.logical_head_hash != b.event_hash, "logical head not B"
        # Constitution scope with explicit Layer 0 approval
        ok2, = ct.record_rollback(
          target_hash: a.event_hash,
          human_approved: true,
          approval: "1/0 = To Stay · Layer 0 explicit",
          restore_scope: "constitution",
          reason: "protected path test"
        )
        assert ok2 == true, "constitution scope with Layer 0 token ok"
        assert ct.verify_chain[0] == true, "chain valid after second rollback"
      end
    end

    def self.test_contrail_verify_chain_bang
      Dir.mktmpdir("afterstring_vb") do |dir|
        path = File.join(dir, "c.jsonl")
        ct = Contrail.new(path, session_id: "vb")
        ct.append(purpose: "ok", tier: 0, approval: "auto", outcome: "ok")
        assert ct.verify_chain! == true, "verify_chain! true"
        File.open(path, "a") { |f| f.puts('{"timestamp":"x","session_id":"y","parent_hash":"bad","event_hash":"nope","actor":"t","tier":0,"purpose":"x","approval":"a","outcome":"ok","payload":{}}') }
        ct2 = Contrail.new(path, session_id: "vb2")
        raised = false
        begin
          ct2.verify_chain!
        rescue Contrail::TamperError => e
          raised = true
          assert e.message.include?("A.L.T._VOID_IF_TAMPERED"), "seal in error"
        end
        assert raised, "verify_chain! must raise on tamper"
      end
    end

    def self.test_contrail_safe_append
      Dir.mktmpdir("afterstring_fl") do |dir|
        path = File.join(dir, "c.jsonl")
        ct = Contrail.new(path, session_id: "fl")
        5.times { |i| ct.append(purpose: "n#{i}", tier: 0, approval: "auto", outcome: "ok") }
        ok, = ct.verify_chain
        assert ok, "chain valid after appends"
        assert ct.entries.size == 5, "5 entries"
      end
    end

    def self.test_verifier_stub
      g = Gate.new(const)
      v = Verifier.new(g, contrail: nil)
      r = v.verify(action_kind: :read, log: false)
      assert r.status == :verified, "read verified"
      assert r.feedback == :proceed, "proceed"
      r2 = v.verify(action_kind: :write_local, human_approved: false, log: false)
      assert r2.status == :held || r2.feedback == :bench, "write held for bench"
      g.set_score("patience", 0.0)
      r3 = v.verify(action_kind: :read, log: false)
      assert r3.status == :rejected, "e13 zero rejected"
      assert r3.feedback == :resonance, "resonance feedback"
    end

    def self.test_adapter_base_pre_execute
      Dir.mktmpdir("afterstring_ad") do |dir|
        # Use temp state so we do not pollute ~/.afterstring
        ad = AdapterBase.new(name: "test", root: ROOT, state_dir: dir)
        r = ad.pre_execute(action_kind: :read)
        assert r.feedback == :proceed || r.status == :verified, "adapter read ok"
        ad.shutdown
        ok, = ad.contrail.verify_chain
        assert ok, "adapter contrail valid"
      end
    end

    def self.test_gpsl_lift_proposal
      g = Gate.new(const)
      g.set_score("kindness", 0.0)
      p = GPSL.propose(g)
      assert p.action == :lift_single_virtue, "GPSL proposes lift"
      assert p.virtue_id == "kindness", "targets kindness"
      assert GPSL.apply!(g, p, human_approved: false) == false, "no apply without human"
      assert GPSL.apply!(g, p, human_approved: true) == true, "apply with human"
      assert g.e13_scores["kindness"] > 0, "kindness lifted"
    end

    def self.test_resonance_messages
      m = Resonance.activate("test")
      assert m.active == true, "resonance active"
      assert m.guidance.include?("Bench"), "mentions Bench"
      c = Resonance.clear
      assert c.active == false, "clear inactive"
    end

    def self.test_gate_cli_exit_semantics
      # Spawn CLI for read → exit 0
      out = `ruby #{File.join(ROOT, "runtime/gate_cli.rb")} --action read --tier 0 2>&1`.strip
      assert out == Gate::PROCEED, "cli read → PROCEED got #{out.inspect}"
      assert $?.exitstatus == 0, "cli read exit 0"
      out2 = `ruby #{File.join(ROOT, "runtime/gate_cli.rb")} --action write_local --tier 2 2>&1`.strip
      assert out2 != Gate::PROCEED, "cli write unapproved not PROCEED"
      assert $?.exitstatus == 2, "cli non-proceed exit 2"
    end

    def self.test_contrail_cli_verify
      out = `ruby #{File.join(ROOT, "runtime/contrail_cli.rb")} --verify --path #{File.expand_path("~/.afterstring/contrail.jsonl")} 2>&1`
      assert out.include?("CONTRAIL_OK") || out.include?("TRIGGER_REALITY_VETO"), "cli verify output"
      # fresh clean chain
      Dir.mktmpdir("cli_v") do |dir|
        path = File.join(dir, "c.jsonl")
        ct = Contrail.new(path)
        ct.append(purpose: "x", tier: 0, approval: "auto", outcome: "ok")
        out2 = `ruby #{File.join(ROOT, "runtime/contrail_cli.rb")} --verify --path #{path} 2>&1`
        assert out2.include?("CONTRAIL_OK"), "clean chain CONTRAIL_OK got #{out2.inspect}"
        assert $?.exitstatus == 0, "exit 0"
      end
    end

    def self.test_grokbot_adapter
      require File.join(ROOT, "adapters/grokbot/runner.rb") unless defined?(Afterstring::GrokbotAdapter)
      Dir.mktmpdir("afterstring_gb") do |dir|
        ad = Afterstring::GrokbotAdapter.new(root: ROOT)
        ad.instance_variable_set(:@state_dir, dir)
        ad.instance_variable_set(:@contrail, Contrail.new(File.join(dir, "contrail.jsonl")))
        ad.instance_variable_set(:@sabbath, Sabbath.new(File.join(dir, "sabbath.json"), interval_hours: 24))
        ad.instance_variable_set(:@verifier, Verifier.new(ad.gate, contrail: ad.contrail))

        assert ad.bots_ok?(3) == true, "3 bots ok"
        assert ad.bots_ok?(4) == false, "4 bots exceed LITE"
        assert ad.max_concurrent_bots.to_i == 3, "max bots 3"

        ok, missing = ad.reality_veto_complete?({})
        assert ok == false && missing.size == 7, "empty RV incomplete"

        full_rv = {
          "who" => "Paddy Sham / Human Kernel", "what" => "draft", "where" => "mail", "when" => "now",
          "account" => "work", "environment" => "prod", "authority" => "1/0"
        }
        ok2, = ad.reality_veto_complete?(full_rv)
        assert ok2 == true, "full RV complete"

        r_read = ad.check(action_kind: :read)
        assert r_read[:feedback] == :proceed, "read proceeds got #{r_read.inspect}"

        r_hold = ad.check(action_kind: :live_account_write, human_approved: false, rv: full_rv)
        assert r_hold[:feedback] != :proceed, "live write without 1/0 held"

        r_ok = ad.check(action_kind: :live_account_write, human_approved: true, rv: full_rv)
        assert r_ok[:feedback] == :proceed, "live write with 1/0+RV proceed got #{r_ok.inspect}"

        r_inc = ad.check(action_kind: :routine_promotion, human_approved: true, rv: { "who" => "only" })
        assert r_inc[:feedback] != :proceed, "incomplete RV holds even if approved"
      end

      out = `ruby #{File.join(ROOT, "adapters/grokbot/runner.rb")} --check-bots 3 2>&1`.strip
      assert out.include?("BOTS_OK"), "cli bots ok got #{out.inspect}"
      assert $?.exitstatus == 0, "exit 0"
      out2 = `ruby #{File.join(ROOT, "adapters/grokbot/runner.rb")} --check-bots 4 2>&1`.strip
      assert out2.include?("BOTS_EXCEED"), "cli bots exceed"
      assert $?.exitstatus == 2, "exit 2"
      assert File.file?(File.join(ROOT, "adapters/grokbot/RUNBOOK.md")), "RUNBOOK present"
      assert File.file?(File.join(ROOT, "adapters/grokbot/STANDING_ORDERS.md")), "STANDING_ORDERS present"
      assert File.file?(File.join(ROOT, "adapters/grokbot/SKILL.md")), "SKILL present"
    end

    def self.test_signal_trust
      Dir.mktmpdir("st") do |dir|
        st = SignalTrust.new(File.join(dir, "st.json"))
        r = st.assess(yes_ids: [])
        assert r.level == :high, "no flags → high"
        assert r.ok_to_decide == true, "ok to decide"
        r2 = st.assess(yes_ids: [1, 2, 3])
        assert r2.level == :low, "3 flags → low got #{r2.level}"
        assert st.low? == true, "low?"
        r3 = st.assess(yes_ids: ["exhaustion"])
        assert r3.level == :medium, "one named flag → medium"
      end
    end

    def self.test_decision_state_release
      Dir.mktmpdir("ds") do |dir|
        d = DecisionState.new(File.join(dir, "d.json"))
        stay = d.decide(harm_present: false, can_recover: true, signal_trust_level: :high)
        assert stay.action == :stay, "stay path"
        rel = d.decide(harm_present: true, can_recover: false, signal_trust_level: :high, lesson: "contrail of light")
        assert rel.action == :release, "release path"
        assert rel.lesson.include?("contrail"), "lesson kept"
        pause = d.decide(harm_present: false, can_recover: true, signal_trust_level: :low)
        assert pause.action == :pause, "low trust → pause"
        # OI-1 LITE policy: harm + recoverable → pause (stricter than public persist)
        lite_pause = d.decide(harm_present: true, can_recover: true, signal_trust_level: :high)
        assert lite_pause.action == :pause, "LITE harm+recover → pause"
        assert d.payload(rel)["seal"].to_s.include?("Release"), "seal"
      end
    end

    def self.test_signal_trust_unassessed
      Dir.mktmpdir("st0") do |dir|
        st = SignalTrust.new(File.join(dir, "never.json"))
        assert st.unassessed? == true, "fresh unassessed"
        assert !st.low?, "unassessed is not low"
      end
    end

    # OI-1.1: prior high on disk must not clear Decide this process
    def self.test_signal_trust_prior_disk_not_live
      Dir.mktmpdir("st1") do |dir|
        path = File.join(dir, "st.json")
        a = SignalTrust.new(path)
        a.assess(yes_ids: [], method: :clear_claim)
        assert a.assessed_this_process?, "assessed after claim"
        b = SignalTrust.new(path)
        assert b.unassessed? == true, "new process unassessed despite prior high"
        assert b.prior_level == :high, "prior visible"
        assert b.display_label.include?("unassessed"), "display says unassessed"
        assert !b.low?, "prior high is not live low"
        b.assess(yes_ids: [1], method: :checklist)
        assert b.assessed_this_process?, "checklist clears unassessed"
        assert b.last_result.level == :medium, "medium after one flag"
      end
    end

    def self.test_anchors_registry
      Dir.mktmpdir("an") do |dir|
        a = Anchors.new(File.join(dir, "a.json"), repo_root: ROOT)
        assert a.list.size >= 1, "seeded bench"
        x = a.add(kind: "photo", label: "test", path: "media/layer0")
        assert a.get(x.id).label == "test", "get works"
        a.touch(x.id)
        fr = a.freshness(a.get(x.id))
        assert fr[:status] == :fresh, "fresh after touch"
      end
    end

    def self.test_frme_lite
      assert FrmeLite.classes_for(:read) == %w[none], "read none"
      assert FrmeLite.classes_for(:network).include?("R1"), "network R1"
      ann = FrmeLite.annotate(:git_push)
      assert ann["frme_lite"] == true, "annotate flag"
      assert ann["risk_classes"].is_a?(Array), "classes array"
    end

    def self.test_signal_trust_blocks_tier2
      g = Gate.new(const)
      r = g.evaluate(action_kind: :write_local, tier: 2, human_approved: false, signal_trust_low: true)
      assert r == Gate::VETO, "trust low blocks tier2 unapproved got #{r}"
      r2 = g.evaluate(action_kind: :write_local, tier: 2, human_approved: true, signal_trust_low: true)
      # may PROCEED or RESONANCE (matrix) but should not VETO solely for trust when approved
      assert [Gate::PROCEED, Gate::RESONANCE].include?(r2), "approved with trust low got #{r2}"
      r3 = g.evaluate(action_kind: :read, signal_trust_low: true)
      assert r3 == Gate::PROCEED, "read still proceeds under low trust"
    end

    def self.test_verifier_frme_fields
      g = Gate.new(const)
      v = Verifier.new(g, contrail: nil)
      r = v.verify(action_kind: :network, human_approved: true, log: false)
      assert r.frme_classes.is_a?(Array), "frme_classes present"
      assert !r.proposal_hash.to_s.empty?, "proposal_hash"
      r2 = v.verify(action_kind: :write_local, signal_trust_low: true, human_approved: false, log: false)
      assert r2.status == :held || r2.feedback == :pause_signal_trust || r2.feedback == :bench,
             "trust low write held got #{r2.feedback}"
    end

    def self.test_mcp_openclaw_runners
      require File.join(ROOT, "adapters/mcp/runner.rb")
      require File.join(ROOT, "adapters/openclaw/runner.rb")
      Dir.mktmpdir("plug") do |dir|
        # MCP
        m = Afterstring::Adapters::McpRunner.new(root: ROOT)
        m.instance_variable_set(:@state_dir, dir)
        m.instance_variable_set(:@contrail, Contrail.new(File.join(dir, "c.jsonl")))
        m.instance_variable_set(:@sabbath, Sabbath.new(File.join(dir, "s.json"), interval_hours: 24))
        m.instance_variable_set(:@signal_trust, SignalTrust.new(File.join(dir, "st.json")))
        m.instance_variable_set(:@anchors, Anchors.new(File.join(dir, "a.json"), repo_root: ROOT))
        m.instance_variable_set(:@verifier, Verifier.new(m.gate, contrail: m.contrail))
        fail_schema = m.invoke(tool_name: "t", args: {}, required_keys: %w[query])
        assert fail_schema[:ok] == false, "schema fail"
        # OpenClaw local summary should proceed
        o = Afterstring::Adapters::OpenclawRunner.new(root: ROOT)
        o.instance_variable_set(:@state_dir, dir)
        o.instance_variable_set(:@contrail, Contrail.new(File.join(dir, "c2.jsonl")))
        o.instance_variable_set(:@sabbath, Sabbath.new(File.join(dir, "s2.json"), interval_hours: 24))
        o.instance_variable_set(:@signal_trust, SignalTrust.new(File.join(dir, "st2.json")))
        o.instance_variable_set(:@anchors, Anchors.new(File.join(dir, "a2.json"), repo_root: ROOT))
        o.instance_variable_set(:@verifier, Verifier.new(o.gate, contrail: o.contrail))
        ok = o.run_skill(skill_class: "local_summary")
        assert ok[:ok] == true, "local_summary ok got #{ok.inspect}"
        bad = o.run_skill(skill_class: "shell")
        assert bad[:ok] == false, "shell blocked"
      end
    end

    def self.test_session_continuity
      Dir.mktmpdir("sess") do |dir|
        s = Session.new(File.join(dir, "s.json"))
        s.start!(mode: "LITE")
        s.set_pilot!("bench-origin")
        s.touch!("last_decision" => "stay")
        assert s.pilot_id == "bench-origin", "pilot"
        assert s.summary.include?("stay"), "summary has decision"
        s2 = Session.new(File.join(dir, "s.json"))
        assert s2.pilot_id == "bench-origin", "persists"
      end
    end

    def self.test_graph_runner
      require File.join(ROOT, "adapters/graph/runner.rb")
      Dir.mktmpdir("gr") do |dir|
        g = Afterstring::Adapters::GraphRunner.new(root: ROOT)
        g.instance_variable_set(:@state_dir, dir)
        g.instance_variable_set(:@contrail, Contrail.new(File.join(dir, "c.jsonl")))
        g.instance_variable_set(:@sabbath, Sabbath.new(File.join(dir, "s.json"), interval_hours: 24))
        g.instance_variable_set(:@signal_trust, SignalTrust.new(File.join(dir, "st.json")))
        g.instance_variable_set(:@anchors, Anchors.new(File.join(dir, "a.json"), repo_root: ROOT))
        g.instance_variable_set(:@verifier, Verifier.new(g.gate, contrail: g.contrail))
        nodes = [{ "id" => "a", "kind" => "read" }, { "id" => "b", "kind" => "summary" }]
        ok = g.plan(nodes: nodes, parallel: 2, human_approved: false)
        assert ok[:ok] == true, "read graph ok got #{ok.inspect}"
        wide = g.plan(nodes: nodes, parallel: 99, human_approved: false)
        assert wide[:ok] == false, "fanout exceed"
        persist = g.plan(nodes: nodes, parallel: 1, human_approved: false, persist_script: true)
        assert persist[:ok] == false, "persist needs 1/0"
      end
    end

    def self.test_swi_cli_runs
      out = `ruby #{File.join(ROOT, "runtime/swi_cli.rb")} 2>&1`
      assert out.include?("SWI"), "swi header got #{out[0, 80].inspect}"
      assert out.include?("Presence"), "presence line"
      assert out.include?("Module 8") || out.include?("plugins"), "module8 mention"
      assert $?.exitstatus == 0, "swi exit 0"
    end

    def self.test_module8_plugins
      Dir.mktmpdir("m8") do |dir|
        m = Module8Plugins.new(File.join(dir, "m8.json"))
        r0 = m.assess(plugin_ids: %w[polyvagal attachment], yes_ids: [])
        assert r0.flags.empty?, "no yes → no flags"
        assert r0.never_overrides_kernel == true, "kernel flag"
        assert r0.suggest_pause == false, "no pause without flags"
        r1 = m.assess(plugin_ids: nil, yes_ids: %w[polyvagal attachment])
        assert r1.flags.include?("polyvagal"), "polyvagal flag"
        assert r1.flags.include?("attachment"), "attachment flag"
        assert r1.suggest_pause == true, "pause suggested"
        assert r1.never_overrides_kernel == true, "still never overrides"
        assert r1.notes.size >= 1, "notes present"
        # index form
        r2 = m.assess(yes_ids: [1])
        assert r2.flags.include?("attachment"), "index 1 = attachment got #{r2.flags}"
      end
    end

    def self.test_plugins_cli_runs
      out = `ruby #{File.join(ROOT, "runtime/plugins_cli.rb")} list 2>&1`
      assert out.include?("Module 8") || out.include?("attachment"), "list catalog #{out[0, 100].inspect}"
      assert $?.exitstatus == 0, "plugins list exit 0"
      out2 = `ruby #{File.join(ROOT, "runtime/plugins_cli.rb")} check polyvagal --yes polyvagal 2>&1`
      assert out2.include?("never_overrides_kernel") || out2.include?("Human Kernel"), "check output"
      assert $?.exitstatus == 0, "plugins check exit 0"
    end

    def self.test_git_check_script
      out = `bash #{File.join(ROOT, "bin/afterstring-git-check")} 2>&1`
      assert out.include?("OK") || out.include?("git_push"), "git-check output #{out[0, 120].inspect}"
      assert $?.exitstatus == 0, "git-check exit 0"
    end

    def self.test_openweight_runner
      require "json"
      require "time"
      require File.join(ROOT, "adapters/openweight/runner.rb")
      old_home = ENV["HOME"]
      Dir.mktmpdir("as-ow") do |dir|
        ENV["HOME"] = dir
        FileUtils.mkdir_p(File.join(dir, ".afterstring"))
        sab_path = File.join(dir, ".afterstring", "sabbath.json")
        File.write(sab_path, JSON.generate(
          "last_airgap_at" => Time.now.utc.iso8601,
          "interval_hours" => 24.0
        ))
        r = Afterstring::Adapters::OpenweightRunner.new(root: ROOT)
        # ensure isolated registry even if init wrote elsewhere
        r.instance_variable_set(:@state_dir, File.join(dir, ".afterstring"))
        r.instance_variable_set(:@registry_path, File.join(dir, ".afterstring", "openweight_instances.json"))
        r.instance_variable_set(:@registry, { "instances" => [] })

        st = r.status_report
        assert st[:matrix_loaded] == true, "openweight matrix loaded"
        assert st[:max_instances].to_i >= 1, "max instances"

        chk = r.check(intent: "infer", model_id: "test-q4", human_approved: false)
        assert chk.key?(:gate), "gate key #{chk.inspect}"
        assert chk[:note].to_s.include?("LITE"), "lite note"

        ft = r.check(intent: "fine_tune", human_approved: false)
        assert ft[:ok] == false, "fine_tune held without approval got #{ft.inspect}"

        ft2 = r.check(intent: "fine_tune", human_approved: true)
        assert ft2[:kind] == "fine_tune", "kind fine_tune"
      end
    ensure
      ENV["HOME"] = old_home if old_home
    end

    def self.test_frme_eval_suite
      require "frme_eval"
      report = FrmeEval.run_suite(constitution: const)
      assert report["total"].to_i >= 8, "suite size"
      assert report["passed"] == report["total"], "all LITE refuse-path cases pass got #{report['failed'].inspect}"
      assert report["failed"].empty?, "no fails"
    end

    def self.test_artifact_identity
      require "artifact_identity"
      incomplete = ArtifactIdentity.new("upstream_id" => "qwen3:8b")
      assert incomplete.complete? == false, "incomplete without engine/constitution"
      assert incomplete.missing.include?("engine"), "missing engine"
      full = ArtifactIdentity.new(
        "upstream_id" => "qwen3:8b",
        "engine" => "ollama",
        "constitution" => "layer0@11.11.11",
        "weight_hash" => "sha256:deadbeef",
        "license" => "apache-2.0",
        "source" => "ollama"
      )
      assert full.complete? == true, "complete LITE min"
      assert full.identity_hash.to_s.length == 64, "sha256 hex"
      bind = ArtifactIdentity.bind_authorization(full, human_approved: false, intent: "infer")
      assert bind["ok"] == false, "no 1/0"
      bind2 = ArtifactIdentity.bind_authorization(full, human_approved: true, intent: "infer")
      assert bind2["ok"] == true, "approved complete"
      bind3 = ArtifactIdentity.bind_authorization(incomplete, human_approved: true, intent: "infer")
      assert bind3["ok"] == false, "unknown_to_zero incomplete"
      assert bind3["unknown_to_zero"] == true, "flag"
    end

    def self.test_type4_folder_present
      root = File.join(ROOT, "Afterstring_Type4_Safety_Attractor")
      assert File.directory?(root), "Type4 folder exists"
      assert File.file?(File.join(root, "ROADMAP", "ROADMAP.md")), "ROADMAP"
      assert File.file?(File.join(root, "SPEC", "type4-runtime", "INVARIANT_MAP.md")), "INVARIANT_MAP"
      plat = File.join(root, "CONSTITUTION", "platinum", "layer0.yaml")
      assert File.exist?(plat) || File.symlink?(plat), "platinum layer0 pointer"
    end

    def self.test_operator_status
      require "operator_status"
      require "stringio"
      s = OperatorStatus.snapshot
      assert s["root"].to_s.include?("afterstring"), "root"
      assert s.key?("sabbath_due"), "sabbath"
      assert s["adapters"].include?("grokbot"), "grokbot adapter listed"
      old = $stdout
      buf = StringIO.new
      $stdout = buf
      OperatorStatus.print_help
      $stdout = old
      help = buf.string
      assert help.include?("doctor"), "help doctor"
      assert help.include?("status"), "help status"
    end

    def self.test_permit_decision_aliases
      require "permit"
      require "decision"
      assert Permit.equal?(Gate), "Permit ≡ Gate"
      assert Decision.equal?(DecisionState), "Decision ≡ DecisionState"
      assert Gate::OPERATIONAL_NAME == "Permit", "Permit name"
      assert DecisionState::OPERATIONAL_NAME == "Decision", "Decision name"
      g = Gate.new(const)
      assert g.respond_to?(:permit), "permit method"
      assert g.permit(action_kind: :read) == Gate::PROCEED, "permit read"
      assert !g.respond_to?(:decide), "Gate#decide removed — Decision only"
    end

    def self.test_pocket_one_protocol
      require "pocket"
      assert Pocket.size == 5, "five steps"
      assert Pocket.five?, "five?"
      assert Pocket::STEPS.size == 5, "STEPS"
      src = File.read(File.join(ROOT, "tui/app.rb"))
      assert src.include?("Pocket::STEPS"), "TUI single pocket source"
    end

    def self.test_grokbuild_permit_boundary
      load File.join(ROOT, "adapters/grokbuild/runner.rb")
      Dir.mktmpdir("gb2") do |dir|
        ad = GrokbuildAdapter.new(root: ROOT, state_dir: dir)
        r0 = ad.authorize_tool(action_kind: :read)
        assert r0.feedback == :proceed, "read proceed"
        r1 = ad.authorize_tool(action_kind: :git_push, human_approved: false)
        assert r1.feedback != :proceed, "git_push held"
        assert r1.tier.to_i >= 2, "tier ge 2"
        assert ad.allowed?(action_kind: :git_push) == false, "allowed? false"
        raised = false
        begin
          ad.authorize_tool!(action_kind: :network, human_approved: false)
        rescue GrokbuildAdapter::AuthorizationError
          raised = true
        end
        assert raised, "enforce raises"
      end
      out = `ruby #{File.join(ROOT, "adapters/grokbuild/runner.rb")} --action git_push 2>&1`
      assert $?.exitstatus == 2, "cli exit 2"
      assert out.include?("HELD") || out.include?("VETO"), "cli held"
      assert File.file?(File.join(ROOT, "adapters/grokbuild/HOOK.md")), "HOOK.md"
      assert File.executable?(File.join(ROOT, "bin/afterstring-grokbuild-check")) ||
             File.file?(File.join(ROOT, "bin/afterstring-grokbuild-check")), "bin check"
    end

    def self.test_p1_p4_host_integrity
      # Suite entry — full script also runnable standalone
      script = File.join(ROOT, "tests/p1_p4_host_integrity_test.rb")
      assert File.file?(script), "p1_p4 test file"
      out = `ruby #{script} 2>&1`
      assert out.include?("ALL P1–P4 CHECKS PASSED"), "standalone suite #{out[-200..]}"
      assert $?.exitstatus == 0, "exit 0"
    end

    def self.test_diet_check
      script = File.join(ROOT, "adapters/lite/runner.rb")
      assert File.file?(script), "lite runner"
      out = `ruby #{script} check 2>&1`
      assert $?.exitstatus == 0, "lite check exit 0 #{out[-200..]}"
      assert out.include?("HOLD") || out.include?('"ok": true'), "lite HOLD"
      path = `ruby #{script} path 2>&1`
      assert path.include?("LITE_READING_PATH") || path.include?("Load first"), "lite path"
    end

    def self.test_continuity_check
      require "continuity_check"
      Dir.mktmpdir("as-cont") do |dir|
        chk = ContinuityCheck.new(root: ROOT, state_dir: dir)
        assert chk.interval_hours == 24.0, "default 24h"
        assert chk.due?, "never-run is due when armed"
        chk.set_interval!(12)
        assert chk.interval_hours == 12.0, "interval changeable"
        chk.disarm!
        assert !chk.due?, "disarmed not due"
        chk.arm!
        live = ContinuityCheck.new(root: ROOT, state_dir: dir)
        report = live.run!
        assert report["ok"], "live probes HOLD #{report['failed'].inspect}"
        assert !live.due?, "just-run not due"
        assert File.file?(File.join(dir, "continuity_check.json")), "state written"
      end
      assert File.file?(File.join(ROOT, "bin/afterstring-continuity-check")), "bin"
    end

    def self.test_leftover_truth
      script = File.join(ROOT, "tests/leftover_truth_test.rb")
      assert File.file?(script), "leftover_truth test"
      out = `ruby #{script} 2>&1`
      assert out.include?("ALL LEFTOVER TRUTH CHECKS PASSED"), out[-300..]
      assert $?.exitstatus == 0, "leftover exit 0"
    end

    # OI-1: TUI must not stamp Stay/Release; q ≠ Release Clause
    def self.test_oi1_operator_integrity
      tui_path = File.join(ROOT, "tui/app.rb")
      assert File.file?(tui_path), "tui/app.rb present"
      src = File.read(tui_path)
      assert src.include?("def session_quit"), "session_quit"
      assert !src.include?("def soft_release"), "soft_release removed"
      assert src.include?('purpose: "session_end"'), "session_end event"
      assert src.include?('"relational_decision" => "none"'), "quit not relational"
      assert src.include?("forced_action: force ? :stay : nil"), "stay no default force"
      assert src.include?("forced_action: force ? :release : nil"), "release no default force"
      assert src.include?("prior disk trust") || src.include?("unassessed until"), "no high trust seed"
      assert src.include?("Trust unassessed") || src.include?("unassessed"), "block unassessed decide"
      assert src.include?("swi_open_pocket"), "swi opens pocket"
      assert !src.include?("Pocket Protocol (6 steps)"), "no six-step pocket help"
      assert src.include?("truth_payload"), "event≠interpretation fields"
      assert src.include?("note_stale_pre_oi1"), "stale state note"
      # constants
      load tui_path
      assert Afterstring::TUI::POCKET_STEPS.size == 5, "public v9.1 five steps"
      assert Afterstring::TUI::VERSION.to_s.match?(/oi1|host/), "version oi1 or host"
    end
  end
end

Afterstring::Tests.run!
