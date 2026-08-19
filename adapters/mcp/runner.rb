#!/usr/bin/env ruby
# frozen_string_literal: true
# After_MCP 8.1.13 — LITE runner (schema-lite + gate).
# Does not speak MCP wire protocol; validates tool call *intent* before side effects.

require_relative "../../runtime/adapter_base"
require_relative "../../runtime/frme_lite"

module Afterstring
  module Adapters
    class McpRunner < AdapterBase
      def initialize(root: nil)
        super(name: "mcp", root: root)
      end

      # tool_name + args hash — schema-lite required keys
      def invoke(tool_name:, args: {}, human_approved: false, required_keys: [])
        args = args.transform_keys(&:to_s) if args.respond_to?(:transform_keys)
        missing = Array(required_keys).map(&:to_s) - args.keys.map(&:to_s)
        unless missing.empty?
          log_contrail(
            purpose: "mcp_schema_fail:#{tool_name}",
            tier: 2,
            outcome: "RESONANCE",
            payload: { "missing" => missing }
          )
          return { ok: false, error: "schema_missing:#{missing.join(',')}", gate: "TRIGGER_RESONANCE_MODE" }
        end

        # MCP tools treated as external-capable by default
        kind = :mcp_tool
        res = pre_execute(
          action_kind: kind,
          human_approved: human_approved,
          embodied_proof: human_approved
        )
        log_contrail(
          purpose: "mcp_pre:#{tool_name}",
          tier: res.tier,
          approval: human_approved ? "1/0" : "auto",
          outcome: res.gate_result.to_s,
          payload: {
            "status" => res.status.to_s,
            "frme" => res.frme_classes,
            "tool" => tool_name.to_s
          }
        )
        if res.status != :verified
          return { ok: false, error: res.feedback.to_s, gate: res.gate_result, reasons: res.reasons }
        end

        # LITE: no real network — success means "would proceed under constitution"
        post_execute(action_kind: kind, result: "schema_ok:#{tool_name}", outcome: "ok")
        { ok: true, gate: res.gate_result, tool: tool_name, note: "LITE dry-run — no wire call" }
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  tool = "demo_tool"
  approved = false
  ARGV.each_with_index do |a, i|
    tool = ARGV[i + 1] if a == "--tool"
    approved = true if a == "--approved" || a == "1/0"
  end
  r = Afterstring::Adapters::McpRunner.new
  out = r.invoke(tool_name: tool, args: { "query" => "ping" }, human_approved: approved, required_keys: %w[query])
  puts out.inspect
  exit(out[:ok] ? 0 : 2)
end
