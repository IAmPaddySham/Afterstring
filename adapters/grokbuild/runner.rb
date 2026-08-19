#!/usr/bin/env ruby
# frozen_string_literal: true
# After_GrokBuild — PERMIT pre-tool + optional command WRAP (leftover truth #2).
#
# Two modes:
#   A) CHECK only (contract): exit 0/2 — agent may skip unless they invoke this.
#   B) WRAP (actual boundary): runs the command ONLY if PERMIT proceeds.
#      afterstring-grokbuild-check --action git_push --approved -- run git status
#
# Without wrapping through this binary, git/shell can still run. That limit is honest
# in HOOK.md. Fail-closed applies to commands launched *via* this process.
#
# Exit codes:
#   0  — check-only PROCEED, or wrap succeeded (child exit 0)
#   2  — PERMIT held (command not started)
#   N  — child process exit status when wrap ran (if child non-zero)

GB_ROOT = File.expand_path("../..", __dir__)
$LOAD_PATH.unshift(File.join(GB_ROOT, "runtime"))
require "adapter_base"
require "permit"

module Afterstring
  class GrokbuildAdapter < AdapterBase
    class AuthorizationError < StandardError
      attr_reader :result

      def initialize(message, result = nil)
        super(message)
        @result = result
      end
    end

    HIGH_IMPACT = %i[
      write_local git_push network external_transmit destroy credential
      shell_destructive refine_constitutional modify_base_prompt
      constitutional_weaken live_account_write fine_tune spawn_instance
      rlm_fanout multi_bot multi_instance
    ].freeze

    def initialize(root: GB_ROOT, state_dir: nil)
      super(name: "grokbuild", root: root, state_dir: state_dir)
    end

    def authorize_tool(action_kind:, human_approved: false, embodied_proof: false,
                       signal_trust_low: nil, tier: nil)
      kind = action_kind.to_sym
      t = (tier || @gate.infer_tier(kind)).to_i
      st_low = signal_trust_low.nil? ? @signal_trust.low? : signal_trust_low

      if t >= 2 && !human_approved && !embodied_proof
        res = Verifier::Result.new(
          status: :held,
          gate_result: Gate::VETO,
          e13_product: @gate.e13_product,
          tier: t,
          zeros: [],
          reasons: ["tier_ge_2_requires_human_1_0", "kind=permit_not_decision"],
          feedback: :bench,
          frme_classes: FrmeLite.classes_for(kind),
          proposal_hash: "hardwall",
          signal_trust_low: st_low
        )
        @contrail.append_kind(
          :permit,
          event: "permit_hold",
          purpose: "permit_hold:grokbuild:#{kind}",
          tier: t,
          approval: "auto",
          outcome: "VETO",
          actor: "adapter:grokbuild",
          assessment: { "action_kind" => kind.to_s, "tier" => t, "human_approved" => false },
          decision: nil,
          narrative: "Tier≥2 without 1/0 — command not started",
          extra: { "feedback" => "bench", "not" => "Decision" }
        )
        return res
      end

      res = pre_execute(
        action_kind: kind,
        tier: t,
        human_approved: human_approved,
        embodied_proof: embodied_proof || human_approved,
        signal_trust_low: st_low
      )

      ok = res.feedback == :proceed
      @contrail.append_kind(
        :permit,
        event: ok ? "permit_ok" : "permit_hold",
        purpose: ok ? "permit_ok:grokbuild:#{kind}" : "permit_hold:grokbuild:#{kind}",
        tier: t,
        approval: human_approved ? "1/0" : "auto",
        outcome: res.gate_result.to_s,
        actor: "adapter:grokbuild",
        assessment: {
          "action_kind" => kind.to_s,
          "tier" => t,
          "status" => res.status.to_s,
          "feedback" => res.feedback.to_s
        },
        decision: nil,
        narrative: ok ? "PERMIT proceed" : "PERMIT held — do not run tool",
        extra: { "frme" => res.frme_classes, "not" => "Decision" }
      )
      res
    end

    def authorize_tool!(**kwargs)
      res = authorize_tool(**kwargs)
      return res if res.feedback == :proceed

      raise AuthorizationError.new(
        "PERMIT HELD: #{kwargs[:action_kind]} tier=#{res.tier} feedback=#{res.feedback} gate=#{res.gate_result}",
        res
      )
    end

    def allowed?(action_kind:, human_approved: false, **opts)
      authorize_tool(action_kind: action_kind, human_approved: human_approved, **opts).feedback == :proceed
    end

    # Fail-closed wrap: run argv only if PERMIT proceeds. Returns [permit_ok, child_status].
    # If held, child is never spawned (status nil).
    def run_if_permitted(action_kind:, argv:, human_approved: false, embodied_proof: false)
      res = authorize_tool(
        action_kind: action_kind,
        human_approved: human_approved,
        embodied_proof: embodied_proof || human_approved
      )
      unless res.feedback == :proceed
        return [false, nil, res]
      end

      cmd = Array(argv).map(&:to_s)
      if cmd.empty?
        @contrail.append_kind(
          :permit,
          event: "permit_wrap_no_command",
          purpose: "permit_wrap:empty",
          tier: res.tier,
          approval: human_approved ? "1/0" : "auto",
          outcome: "ok",
          actor: "adapter:grokbuild",
          narrative: "PERMIT ok but no command after --"
        )
        return [true, 0, res]
      end

      status = system(*cmd)
      code = $?.nil? ? 1 : $?.exitstatus
      @contrail.append_kind(
        :permit,
        event: "permit_wrap_exec",
        purpose: "permit_wrap:grokbuild:#{action_kind}",
        tier: res.tier,
        approval: human_approved ? "1/0" : "auto",
        outcome: code.zero? ? "ok" : "child_nonzero",
        actor: "adapter:grokbuild",
        assessment: { "argv0" => cmd[0], "argc" => cmd.size, "exit" => code },
        decision: nil,
        narrative: "command ran under PERMIT wrap"
      )
      [true, code, res]
    end
  end
end

if $PROGRAM_NAME == __FILE__
  action = "read"
  approved = false
  verify_only = false
  enforce = false
  wrap_cmd = nil

  # Split on bare "--" / "run" for wrap mode: ... -- run git status
  if (idx = ARGV.index("--")) || (idx = ARGV.index("run"))
    wrap_cmd = ARGV[(idx + 1)..]
    args = ARGV[0...idx]
  else
    args = ARGV.dup
  end

  args.each_with_index do |arg, i|
    case arg
    when "--action", "--pre-tool", "--intent" then action = args[i + 1]
    when "--approved", "--human", "1/0", "--1/0" then approved = true
    when "--verify-contrail" then verify_only = true
    when "--enforce", "--fail-closed" then enforce = true
    when "--help", "-h"
      puts "After_GrokBuild PERMIT (not Decision)"
      puts "Check only:  runner.rb --action KIND [--approved]"
      puts "Wrap (real): runner.rb --action KIND [--approved] -- run <command...>"
      puts "             runner.rb --action git_push --approved -- git status"
      puts "Exit 0 = proceed / wrap ok · Exit 2 = PERMIT held (command not started)"
      puts "Without wrap, this is a contract check only — see HOOK.md"
      exit 0
    end
  end

  adapter = Afterstring::GrokbuildAdapter.new
  if verify_only
    begin
      adapter.verify_contrail!
      puts "CONTRAIL_OK"
      exit 0
    rescue Afterstring::Contrail::TamperError => e
      puts "TRIGGER_REALITY_VETO"
      warn e.message
      exit 2
    end
  end

  # WRAP mode — only path where fail-closed prevents the tool from running
  if wrap_cmd
    ok, code, res = adapter.run_if_permitted(
      action_kind: action,
      argv: wrap_cmd,
      human_approved: approved,
      embodied_proof: approved
    )
    unless ok
      puts "HELD|#{res.gate_result}|#{res.feedback}|tier=#{res.tier}|wrap=not_started"
      warn "PERMIT held — command not executed: #{wrap_cmd.join(' ')}"
      exit 2
    end
    puts "PROCEED|#{res.gate_result}|wrap_ok|tier=#{res.tier}|child_exit=#{code}"
    exit(code.to_i)
  end

  if enforce
    begin
      res = adapter.authorize_tool!(
        action_kind: action,
        human_approved: approved,
        embodied_proof: approved
      )
      puts "PROCEED|#{res.gate_result}|permit_ok|tier=#{res.tier}|mode=check_only"
      warn "CHECK only — no command wrapped. Use: ... -- run <cmd> for fail-closed exec."
      exit 0
    rescue Afterstring::GrokbuildAdapter::AuthorizationError => e
      r = e.result
      puts "HELD|#{r&.gate_result}|#{r&.feedback}|tier=#{r&.tier}"
      warn e.message
      exit 2
    end
  end

  res = adapter.authorize_tool(
    action_kind: action,
    human_approved: approved,
    embodied_proof: approved
  )
  line = if res.feedback == :proceed
           "PROCEED|#{res.gate_result}|permit_ok|tier=#{res.tier}|mode=check_only"
         else
           "HELD|#{res.gate_result}|#{res.feedback}|tier=#{res.tier}|mode=check_only"
         end
  puts line
  if res.feedback == :proceed
    warn "CHECK only (contract). Fail-closed wrap: add -- run <command>"
  end
  exit(res.feedback == :proceed ? 0 : 2)
end
