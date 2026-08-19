# frozen_string_literal: true
# PERMIT path (operator mouth) — harness pre-execution boundary.
# Class name remains Gate for stability; operator-facing name is Permit.
#
# Answers: "May this technical action execute?"
# Does NOT answer Stay / Pause / Release — that is Decision (decision_state.rb).
#
# Returns exactly one of:
#   PROCEED | TRIGGER_REALITY_VETO | TRIGGER_RESONANCE_MODE
# Consults constitution matrices (GrokBuild + RLM + GrokBot); stricter wins.
# Optional sabbath_due / parallel_count implement I_s and I_d.
# Optional signal_trust_low: Module 4.1 pre-gate — blocks Tier≥2 without human bench.

module Afterstring
  class Gate
    # Operator-facing semantic name (ChatGPT / OI host integrity P1)
    OPERATIONAL_NAME = "Permit"
    ROLE = "May this technical action execute?"

    PROCEED = "PROCEED"
    VETO = "TRIGGER_REALITY_VETO"
    RESONANCE = "TRIGGER_RESONANCE_MODE"

    # Map runtime action kinds → matrix action ids (8.1.15 / 8.1.17 / 8.1.18)
    MATRIX_ALIASES = {
      shell_destructive: %w[uncontrolled_or_destructive_shell destructive_shell_or_filesystem],
      destroy: %w[destructive_shell_or_filesystem irreversible_file_or_git_push_or_history_rewrite],
      git_push: %w[irreversible_file_or_git_push_or_history_rewrite],
      network: %w[external_data_transmission external_side_effects_or_network live_account_write_or_external_side_effect],
      external_transmit: %w[external_data_transmission external_side_effects_or_network live_account_write_or_external_side_effect],
      credential: %w[external_data_transmission live_account_write_or_external_side_effect],
      write_local: %w[irreversible_file_or_git_push_or_history_rewrite],
      refine_constitutional: %w[refine_touching_constitutional_elements],
      modify_base_prompt: %w[direct_modification_of_base_system_prompt],
      rlm_fanout: %w[uncontrolled_recursive_rlm_fanout multi_bot_coordination],
      mcp_tool: %w[mcp_or_external_tools],
      constitutional_weaken: %w[constitutional_weakening],
      live_account_write: %w[live_account_write_or_external_side_effect],
      routine_promotion: %w[routine_promotion],
      behavioral_memory: %w[behavioral_memory_update],
      schedule_persistence: %w[schedule_persistence_or_autonomous_trajectory],
      multi_bot: %w[multi_bot_coordination multi_instance_orchestration],
      read: %w[local_read_summary_computation local_read_summary_inspection],
      compute: %w[local_read_summary_computation local_read_summary_inspection],
      summary: %w[local_read_summary_computation local_read_summary_inspection],
      scan: %w[local_read_summary_computation local_read_summary_inspection],
      # After_OpenWeight 8.1.19 — open-weight / local sovereign substrates
      load_model: %w[load_open_weight_model],
      local_inference: %w[local_inference],
      fine_tune: %w[fine_tune_or_lora],
      multi_instance: %w[multi_instance_orchestration],
      fine_tune_weaken: %w[fine_tune_weakening_layer0 constitutional_weakening],
      spawn_instance: %w[autonomous_instance_spawn]
    }.freeze

    attr_reader :constitution, :mode, :e13_scores, :resonance_active, :reality_veto_active

    def initialize(constitution, mode: nil)
      @constitution = constitution
      @mode = (mode || constitution.mode_default).to_s.upcase
      @e13_scores = {}
      constitution.virtue_ids.each { |id| @e13_scores[id] = constitution.default_score }
      @resonance_active = false
      @reality_veto_active = false
      @presence_clear = true
      @parallel_depth = 0
    end

    def presence_status
      @presence_clear && !@resonance_active ? "CLEAR" : "ATTENTION"
    end

    def set_score(virtue_id, value)
      return false unless @e13_scores.key?(virtue_id.to_s)
      v = value.to_f
      v = 0.0 if v < 0
      v = 1.0 if v > 1
      @e13_scores[virtue_id.to_s] = v
      if v <= 0.0
        @resonance_active = true
        @presence_clear = false
      end
      true
    end

    def e13_product
      # Non-compensatory AND-gate: product of all scores.
      prod = 1.0
      @e13_scores.each_value do |s|
        return 0.0 if s.to_f <= 0.0
        prod *= s.to_f
      end
      prod
    end

    def any_virtue_zero?
      @e13_scores.values.any? { |s| s.to_f <= 0.0 }
    end

    def set_mode(mode)
      m = mode.to_s.upcase
      return false unless %w[LITE FULL].include?(m)
      # Expanding from LITE → FULL is Human Kernel only; caller must approve.
      @mode = m
      true
    end

    def enter_resonance!(reason = nil)
      @resonance_active = true
      @presence_clear = false
      reason
    end

    def clear_resonance!
      @resonance_active = false
      @presence_clear = true unless any_virtue_zero?
    end

    def raise_reality_veto!
      @reality_veto_active = true
    end

    def clear_reality_veto!
      @reality_veto_active = false
    end

    # I_d: track concurrent work units (subagents / parallel fan-out).
    def parallel_depth
      @parallel_depth
    end

    def enter_parallel!
      @parallel_depth += 1
      @parallel_depth
    end

    def leave_parallel!
      @parallel_depth -= 1 if @parallel_depth.positive?
      @parallel_depth
    end

    def max_parallel
      @constitution.iaa.dig("lite", "max_parallel") ||
        @constitution.matrix_rlm&.dig("lite_bounds", "max_concurrent_subagents") ||
        @constitution.matrix_grokbot&.dig("lite_bounds", "max_concurrent_active_bots") ||
        @constitution.layer0.dig("defaults", "max_subagents") ||
        3
    end

    # PERMIT evaluation — not relational Stay/Pause/Release.
    # action_kind examples: :read, :compute, :write_local, :shell, :network, :destroy, :git_push, :credential
    # sabbath_due: when true (I_s), block non-read actions until Human Kernel marks airgap
    # parallel_count: optional override for I_d check
    # signal_trust_low: when true, Tier≥2 blocked unless human_approved (pause_and_reassess)
    def evaluate(action_kind:, tier: nil, human_approved: false, target_ambiguous: false,
                 sabbath_due: false, parallel_count: nil, exit_path: nil, signal_trust_low: false)
      return RESONANCE if @resonance_active
      return RESONANCE if any_virtue_zero?
      return VETO if @reality_veto_active
      return VETO if target_ambiguous

      kind = action_kind.to_sym
      tier = infer_tier(kind) if tier.nil?
      tier = tier.to_i

      # I_s — Sabbath Airgap: when due, only pure inspection may proceed
      if sabbath_due && !read_only_kind?(kind)
        return VETO
      end

      # Signal_trust LOW — no high-tier side effects without explicit 1/0 after pause
      if signal_trust_low && tier >= 2 && !human_approved
        return VETO
      end
      if signal_trust_low && !read_only_kind?(kind) && !human_approved && @mode == "LITE"
        return VETO
      end

      # I_d — Passive Dissipation Limit
      depth = parallel_count.nil? ? @parallel_depth : parallel_count.to_i
      if depth > max_parallel.to_i && !human_approved
        return RESONANCE
      end

      # I_a — Autonomy Verification: high tier needs exit path or human bench
      if tier >= 2 && exit_path == false && !human_approved
        return VETO
      end

      # Matrix policies (GrokBuild + RLM); stricter wins
      matrix_result = evaluate_matrices(kind, human_approved: human_approved)
      return matrix_result if matrix_result

      # Fallback hard rules (substrate-agnostic floor)
      case kind
      when :destroy, :git_push, :credential, :network, :external_transmit
        return VETO if @mode == "LITE" && !human_approved
        return RESONANCE if @mode == "LITE" # LITE blacklists uncontrolled external/irreversible
      when :shell_destructive
        return RESONANCE # blacklisted
      when :constitutional_weaken, :modify_base_prompt
        return RESONANCE
      end

      if @constitution.tier_requires_human?(tier) && !human_approved
        return VETO # treat missing human bench as Reality Veto / hold for Human Kernel
      end

      PROCEED
    end

    # Operator mouth: #permit / #permit! only. There is no Gate#decide (removed).
    alias_method :permit, :evaluate

    # Apply permit result with side effects (resonance / reality veto flags).
    def permit!(action_kind:, tier: nil, human_approved: false, target_ambiguous: false,
                sabbath_due: false, parallel_count: nil, exit_path: nil, signal_trust_low: false)
      result = evaluate(
        action_kind: action_kind,
        tier: tier,
        human_approved: human_approved,
        target_ambiguous: target_ambiguous,
        sabbath_due: sabbath_due,
        parallel_count: parallel_count,
        exit_path: exit_path,
        signal_trust_low: signal_trust_low
      )
      if result == RESONANCE
        enter_resonance!("permit:#{action_kind}")
      elsif result == VETO
        raise_reality_veto!
      end
      result
    end

    def operational_name
      OPERATIONAL_NAME
    end

    # Hard refusal if anything still calls the old mouth (incl. send(:decide, ...)).
    def method_missing(name, *args, **kwargs, &block)
      if name.to_sym == :decide
        raise NoMethodError,
              "Gate#decide is gone. Harness = #permit / #permit!. " \
              "Stay/Pause/Release = DecisionState#decide only."
      end
      super
    end

    def respond_to_missing?(name, include_private = false)
      return false if name.to_sym == :decide
      super
    end

    def infer_tier(action_kind)
      case action_kind.to_sym
      when :read, :compute, :summary, :scan then 0
      when :session_state, :ui then 1
      when :write_local, :config, :routine_promotion, :behavioral_memory,
           :schedule_persistence, :multi_bot, :fine_tune, :multi_instance then 2
      when :load_model, :local_inference then 1
      when :shell_destructive, :network, :git_push, :destroy, :credential,
           :external_transmit, :refine_constitutional, :modify_base_prompt,
           :constitutional_weaken, :rlm_fanout, :live_account_write,
           :fine_tune_weaken, :spawn_instance then 3
      else 2
      end
    end

    private

    def read_only_kind?(kind)
      # Inspection + local session seals allowed during Sabbath due window
      %i[read compute summary scan ui session_state].include?(kind.to_sym)
    end

    def evaluate_matrices(kind, human_approved:)
      aliases = MATRIX_ALIASES[kind.to_sym] || []
      policies = []
      policies.concat(policies_for(@constitution.matrix, aliases))
      policies.concat(policies_for(@constitution.matrix_rlm, aliases))
      policies.concat(policies_for(@constitution.matrix_grokbot, aliases))
      policies.concat(policies_for(@constitution.matrix_openweight, aliases))
      return nil if policies.empty?

      # Stricter wins: blacklist > human_gated* > dissipation > restricted > permit
      ranks = {
        "blacklist" => 100,
        "auto_reject_resonance" => 100,
        "human_gated_or_blacklist_lite" => 80,
        "human_gated" => 70,
        "continuity_risk" => 60,
        "dissipation_limited" => 50,
        "restricted" => 40,
        "provenance_tiered" => 40,
        "sandboxed_schema_validation" => 30,
        "permit_with_mandatory_sabbath" => 20,
        "contrail_plus_optional_bench" => 15,
        "permit" => 10
      }
      strictest = policies.max_by { |p| ranks[p.to_s] || 0 }
      policy = strictest.to_s

      case policy
      when "blacklist", "auto_reject_resonance"
        RESONANCE
      when "human_gated_or_blacklist_lite"
        return RESONANCE if @mode == "LITE" && !human_approved
        return VETO unless human_approved
        @mode == "LITE" ? RESONANCE : PROCEED
      when "human_gated", "continuity_risk"
        human_approved ? PROCEED : VETO
      when "dissipation_limited", "restricted", "provenance_tiered"
        # Bound, not ban — human may expand; without approval hold at VETO if LITE high-impact
        return PROCEED if human_approved || read_only_kind?(kind)
        @mode == "LITE" ? VETO : PROCEED
      when "sandboxed_schema_validation", "permit_with_mandatory_sabbath",
           "contrail_plus_optional_bench", "permit"
        PROCEED
      else
        nil
      end
    end

    def policies_for(matrix_doc, aliases)
      return [] if matrix_doc.nil?
      rows = matrix_doc["matrix"] || []
      rows.select { |r| aliases.include?(r["action"].to_s) }.map { |r| r["policy"] }
    end
  end
end
