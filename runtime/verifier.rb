# frozen_string_literal: true
# Module 5 — Verifier Loop v1 (executable).
# Proposal → ℰ₁₃ → Signal_trust → Gate → FRME-lite labels → Embodied Proof → Contrail.
# Does not replace Human Kernel; routes high impact to 1/0.

require "digest"
require_relative "frme_lite"

module Afterstring
  class Verifier
    Result = Struct.new(
      :status, :gate_result, :e13_product, :tier, :zeros, :reasons, :feedback,
      :frme_classes, :proposal_hash, :signal_trust_low,
      keyword_init: true
    )

    # status: :verified | :held | :rejected
    # feedback: :proceed | :bench | :resonance | :veto | :release_suggested | :pause_signal_trust

    def initialize(gate, contrail: nil)
      @gate = gate
      @contrail = contrail
    end

    def verify(action_kind:, tier: nil, human_approved: false, target_ambiguous: false,
               sabbath_due: false, parallel_count: nil, exit_path: nil,
               embodied_proof: false, signal_trust_low: false, log: true)
      reasons = []
      zeros = @gate.e13_scores.select { |_, v| v.to_f <= 0.0 }.keys
      product = @gate.e13_product
      frme = FrmeLite.classes_for(action_kind)
      t_guess = (tier || @gate.infer_tier(action_kind)).to_i
      proposal_hash = Digest::SHA256.hexdigest(
        [action_kind.to_s, t_guess, human_approved, signal_trust_low, Time.now.to_i / 60].join("|")
      )[0, 16]

      reasons << "e13_zero:#{zeros.join(',')}" if zeros.any?
      reasons << "e13_product_collapsed" if product.to_f <= 0.0
      reasons << "signal_trust_low" if signal_trust_low

      if zeros.any? || product.to_f <= 0.0
        @gate.enter_resonance!("verifier:e13") if @gate.respond_to?(:enter_resonance!)
        res = build_result(
          status: :rejected, gate_result: Gate::RESONANCE, product: product, tier: t_guess,
          zeros: zeros, reasons: reasons, feedback: :resonance, frme: frme,
          proposal_hash: proposal_hash, signal_trust_low: signal_trust_low
        )
        log_result(res, action_kind) if log
        return res
      end

      gate_r = @gate.evaluate(
        action_kind: action_kind,
        tier: tier,
        human_approved: human_approved || embodied_proof,
        target_ambiguous: target_ambiguous,
        sabbath_due: sabbath_due,
        parallel_count: parallel_count,
        exit_path: exit_path,
        signal_trust_low: signal_trust_low
      )
      t = (tier || @gate.infer_tier(action_kind)).to_i
      reasons << "gate:#{gate_r}"
      reasons.concat(Array(FrmeLite.annotate(action_kind)["risk_classes"]).map { |c| "frme:#{c}" })

      res = if gate_r == Gate::RESONANCE
              build_result(
                status: :rejected, gate_result: gate_r, product: product, tier: t,
                zeros: zeros, reasons: reasons, feedback: :resonance, frme: frme,
                proposal_hash: proposal_hash, signal_trust_low: signal_trust_low
              )
            elsif gate_r == Gate::VETO
              fb = if signal_trust_low && !human_approved && !embodied_proof
                     :pause_signal_trust
                   else
                     :bench
                   end
              extra = if embodied_proof || human_approved
                        ["held_despite_proof"]
                      else
                        ["needs_embodied_proof_or_1_0"]
                      end
              build_result(
                status: :held, gate_result: gate_r, product: product, tier: t,
                zeros: zeros, reasons: reasons + extra, feedback: fb, frme: frme,
                proposal_hash: proposal_hash, signal_trust_low: signal_trust_low
              )
            elsif t >= 2 && !embodied_proof && !human_approved
              build_result(
                status: :held, gate_result: gate_r, product: product, tier: t,
                zeros: zeros, reasons: reasons + ["tier_ge_2_without_proof"],
                feedback: :bench, frme: frme,
                proposal_hash: proposal_hash, signal_trust_low: signal_trust_low
              )
            else
              build_result(
                status: :verified, gate_result: gate_r, product: product, tier: t,
                zeros: zeros, reasons: reasons, feedback: :proceed, frme: frme,
                proposal_hash: proposal_hash, signal_trust_low: signal_trust_low
              )
            end

      log_result(res, action_kind) if log
      res
    end

    private

    def build_result(status:, gate_result:, product:, tier:, zeros:, reasons:, feedback:, frme:,
                     proposal_hash:, signal_trust_low:)
      Result.new(
        status: status,
        gate_result: gate_result,
        e13_product: product,
        tier: tier,
        zeros: zeros,
        reasons: reasons,
        feedback: feedback,
        frme_classes: frme,
        proposal_hash: proposal_hash,
        signal_trust_low: signal_trust_low
      )
    end

    def log_result(res, action_kind)
      return unless @contrail
      @contrail.append(
        purpose: "verifier:#{action_kind}",
        tier: res.tier.to_i,
        approval: res.status == :verified ? "verifier" : "hold",
        outcome: res.gate_result.to_s,
        actor: "verifier",
        payload: {
          "status" => res.status.to_s,
          "feedback" => res.feedback.to_s,
          "e13_product" => res.e13_product,
          "zeros" => res.zeros,
          "reasons" => res.reasons,
          "frme_classes" => res.frme_classes,
          "proposal_hash" => res.proposal_hash,
          "signal_trust_low" => res.signal_trust_low
        }
      )
    rescue StandardError
      nil
    end
  end
end
