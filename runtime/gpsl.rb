# frozen_string_literal: true
# GPSL — Graceful Pointwise Stabilizing Lift (minimal executable form).
# Restores the smallest local coherence step without weakening Presence ≡ Never Harm.
# Never auto-approves harm; never raises a zero virtue without Human Kernel intent.

module Afterstring
  class GPSL
    Proposal = Struct.new(:action, :virtue_id, :from, :to, :guidance, :safe, keyword_init: true)

    # Given a Gate, propose the minimal recovery step.
    # Human Kernel must still call set_score / clear_resonance! / 1/0.
    def self.propose(gate)
      zeros = gate.e13_scores.select { |_, v| v.to_f <= 0.0 }.keys
      if zeros.any?
        id = zeros.first
        return Proposal.new(
          action: :lift_single_virtue,
          virtue_id: id,
          from: 0.0,
          to: gate.constitution.default_score,
          guidance: "GPSL: lift only #{id} to default after Human Kernel bench. " \
                    "Do not compensate other zeros. Presence ≡ Never Harm remains supreme.",
          safe: true
        )
      end

      if gate.reality_veto_active
        return Proposal.new(
          action: :hold_reality_veto,
          virtue_id: nil,
          from: nil,
          to: nil,
          guidance: "GPSL: Reality Veto holds. Resolve ontological ambiguity before any side effect. " \
                    "Return to Bench. Log Contrail.",
          safe: true
        )
      end

      if gate.resonance_active
        return Proposal.new(
          action: :return_to_bench,
          virtue_id: nil,
          from: nil,
          to: nil,
          guidance: "GPSL: Resonance active with product > 0. Smallest move: /bench, breathe, " \
                    "then explicit clear (0) or /stay. No external side effects.",
          safe: true
        )
      end

      Proposal.new(
        action: :none,
        virtue_id: nil,
        from: nil,
        to: nil,
        guidance: "GPSL: already stable. Continue integral with one small reversible act.",
        safe: true
      )
    end

    # Apply a safe lift only when Human Kernel already approved and proposal is lift_single_virtue.
    def self.apply!(gate, proposal, human_approved: false)
      return false unless human_approved
      return false unless proposal && proposal.safe
      return false unless proposal.action == :lift_single_virtue
      return false unless proposal.virtue_id
      gate.set_score(proposal.virtue_id, proposal.to)
      gate.clear_resonance! unless gate.any_virtue_zero?
      true
    end
  end
end
