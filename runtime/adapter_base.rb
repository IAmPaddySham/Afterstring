# frozen_string_literal: true
# Thin Plugout helper shared by adapters (public surface: gate, contrail, sabbath).
# initialize · pre_execute · log_contrail · rollback · shutdown

require "fileutils"
require_relative "constitution_loader"
require_relative "gate"
require_relative "contrail"
require_relative "verifier"
require_relative "sabbath"
require_relative "resonance"
require_relative "signal_trust"
require_relative "anchors"
require_relative "frme_lite"

module Afterstring
  class AdapterBase
    attr_reader :root, :constitution, :gate, :contrail, :verifier, :sabbath,
                :signal_trust, :anchors, :name

    def initialize(name:, root: nil, state_dir: nil)
      @name = name.to_s
      @root = File.expand_path(root || File.expand_path("..", __dir__))
      @state_dir = File.expand_path(state_dir || File.join(Dir.home, ".afterstring"))
      FileUtils.mkdir_p(@state_dir)
      load_constitution
      @contrail = Contrail.new(File.join(@state_dir, "contrail.jsonl"))
      hours = @constitution.iaa.dig("lite", "sabbath_hours") || 24
      @sabbath = Sabbath.new(File.join(@state_dir, "sabbath.json"), interval_hours: hours)
      @signal_trust = SignalTrust.new(File.join(@state_dir, "signal_trust.json"))
      @anchors = Anchors.new(File.join(@state_dir, "anchors.json"), repo_root: @root)
      @verifier = Verifier.new(@gate, contrail: @contrail)
      log_contrail(purpose: "adapter_init:#{@name}", tier: 0, outcome: "ok")
    end

    def load_constitution
      @constitution = Constitution.new(@root)
      @gate = Gate.new(@constitution)
      @constitution
    end

    # Returns Verifier::Result. Does not execute side effects.
    def pre_execute(action_kind:, tier: nil, human_approved: false, target_ambiguous: false,
                    embodied_proof: false, exit_path: nil, parallel_count: nil,
                    signal_trust_low: nil)
      st_low = signal_trust_low.nil? ? @signal_trust.low? : signal_trust_low
      res = @verifier.verify(
        action_kind: action_kind,
        tier: tier,
        human_approved: human_approved,
        target_ambiguous: target_ambiguous,
        sabbath_due: @sabbath.due?,
        parallel_count: parallel_count,
        exit_path: exit_path,
        embodied_proof: embodied_proof,
        signal_trust_low: st_low,
        log: true
      )
      res
    end

    def post_execute(action_kind:, result:, outcome: "ok")
      log_contrail(
        purpose: "adapter_post:#{@name}:#{action_kind}",
        tier: @gate.infer_tier(action_kind),
        outcome: outcome,
        payload: {
          "result" => result.to_s[0, 200],
          "frme" => FrmeLite.annotate(action_kind)
        }
      )
    end

    def log_contrail(purpose:, tier: 0, approval: "auto", outcome: "ok", payload: {})
      @contrail.append(
        purpose: purpose,
        tier: tier,
        approval: approval,
        outcome: outcome,
        actor: "adapter:#{@name}",
        payload: payload
      )
    end

    def rollback(target_hash:, human_approved:, approval: "1/0 = To Stay", restore_scope: "runtime")
      @contrail.record_rollback(
        target_hash: target_hash,
        human_approved: human_approved,
        approval: approval,
        restore_scope: restore_scope,
        reason: "adapter:#{@name}",
        actor: "adapter:#{@name}"
      )
    end

    def shutdown
      log_contrail(purpose: "adapter_shutdown:#{@name}", tier: 0, approval: "Release ≡ Also Love", outcome: "ok")
      true
    end

    def verify_contrail!
      @contrail.verify_chain!
    end
  end
end
