#!/usr/bin/env ruby
# frozen_string_literal: true
# After_OpenClaw 8.1.12 — LITE runner (skill class + gate).
# Does not host Node gateway; classifies skill intents under IAA.

require_relative "../../runtime/adapter_base"

module Afterstring
  module Adapters
    class OpenclawRunner < AdapterBase
      # Map skill categories → action kinds (aligned with paper matrix)
      SKILL_MAP = {
        "local_summary" => :summary,
        "file_io" => :write_local,
        "calendar" => :write_local,
        "web_scrape" => :network,
        "shell" => :shell_destructive,
        "outbound_message" => :live_account_write,
        "payment" => :credential,
        "read" => :read
      }.freeze

      def initialize(root: nil)
        super(name: "openclaw", root: root)
      end

      def run_skill(skill_class:, human_approved: false)
        kind = SKILL_MAP[skill_class.to_s] || :mcp_tool
        res = pre_execute(
          action_kind: kind,
          human_approved: human_approved,
          embodied_proof: human_approved
        )
        log_contrail(
          purpose: "openclaw_skill:#{skill_class}",
          tier: res.tier,
          approval: human_approved ? "1/0" : "auto",
          outcome: res.gate_result.to_s,
          payload: {
            "status" => res.status.to_s,
            "skill" => skill_class.to_s,
            "mapped_kind" => kind.to_s,
            "frme" => res.frme_classes
          }
        )
        if res.status != :verified
          return { ok: false, gate: res.gate_result, feedback: res.feedback, skill: skill_class }
        end
        post_execute(action_kind: kind, result: "skill_ok:#{skill_class}", outcome: "ok")
        { ok: true, gate: res.gate_result, skill: skill_class, note: "LITE dry-run — no gateway" }
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  skill = "local_summary"
  approved = false
  ARGV.each_with_index do |a, i|
    skill = ARGV[i + 1] if a == "--skill"
    approved = true if a == "--approved" || a == "1/0"
  end
  r = Afterstring::Adapters::OpenclawRunner.new
  out = r.run_skill(skill_class: skill, human_approved: approved)
  puts out.inspect
  exit(out[:ok] ? 0 : 2)
end
