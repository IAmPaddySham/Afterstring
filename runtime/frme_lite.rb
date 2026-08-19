# frozen_string_literal: true
# FRME-lite — map runtime action kinds → risk class labels for Contrail literacy.
# Not a full R1–R7 evaluation engine. Labels only; Human Kernel decides.

module Afterstring
  module FrmeLite
    # Risk classes (public FRME Gold abbreviated)
    # R1 Cyber · R2 Bio/Chem · R3 Persuasion · R4 Uncontrolled R&D
    # R5 Deception · R6 Self-replication · R7 Collusion
    # R-INF-* inference hazards (Module 13)
    # R-REL relational harm (local extension label for human Stay/Release)

    MAP = {
      read: %w[none],
      compute: %w[none],
      summary: %w[none],
      scan: %w[none],
      ui: %w[none],
      session_state: %w[R-REL],
      write_local: %w[R4 R6],
      config: %w[R4],
      shell_destructive: %w[R1 R4],
      destroy: %w[R1 R4 R6],
      git_push: %w[R4 R6],
      network: %w[R1 R5 R6],
      external_transmit: %w[R1 R5 R6],
      credential: %w[R1 R5],
      live_account_write: %w[R1 R3 R5],
      refine_constitutional: %w[R4 R5],
      modify_base_prompt: %w[R4 R5],
      constitutional_weaken: %w[R4 R5 R7],
      rlm_fanout: %w[R4 R7],
      multi_bot: %w[R7 R4],
      routine_promotion: %w[R4 R-INF-3],
      behavioral_memory: %w[R4 R5],
      schedule_persistence: %w[R4],
      mcp_tool: %w[R1 R5]
    }.freeze

    def self.classes_for(action_kind)
      MAP[action_kind.to_sym] || %w[unknown]
    end

    def self.annotate(action_kind)
      classes = classes_for(action_kind)
      {
        "frme_lite" => true,
        "action_kind" => action_kind.to_s,
        "risk_classes" => classes,
        "note" => "Label only — not FRME Gold 100/100 eval"
      }
    end

    def self.summary_table
      MAP.map { |k, v| "#{k}: #{v.join(',')}" }.join("\n")
    end
  end
end
