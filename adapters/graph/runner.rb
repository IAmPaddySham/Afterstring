#!/usr/bin/env ruby
# frozen_string_literal: true
# After_GraphOrchestration 8.1.16 — LITE dry-run runner.
# Validates graph *intent* (nodes, fan-out, human gates) under Gate + FRME-lite.
# Does not execute Claude Dynamic Workflows or real parallel workers.

require_relative "../../runtime/adapter_base"
require_relative "../../runtime/frme_lite"

module Afterstring
  module Adapters
    class GraphRunner < AdapterBase
      def initialize(root: nil)
        super(name: "graph", root: root)
      end

      # nodes: array of { "id"=>, "kind"=> read|write_local|network|..., "human_gated"=>bool }
      # parallel: fan-out width
      def plan(nodes:, parallel: 1, human_approved: false, persist_script: false)
        nodes = Array(nodes)
        width = parallel.to_i
        width = 1 if width < 1

        unless width_ok?(width, human_approved: human_approved)
          log_contrail(
            purpose: "graph_fanout_exceed",
            tier: 2,
            outcome: "RESONANCE",
            payload: { "parallel" => width, "max" => max_parallel }
          )
          return { ok: false, error: "fanout_exceeds_I_d", parallel: width, max: max_parallel }
        end

        results = []
        nodes.each do |n|
          n = n.transform_keys(&:to_s) if n.respond_to?(:transform_keys)
          kind = (n["kind"] || n[:kind] || "read").to_sym
          need_human = n["human_gated"] || n[:human_gated] ||
                       %i[write_local network git_push destroy live_account_write].include?(kind)
          approved = human_approved || !need_human
          res = pre_execute(
            action_kind: kind,
            human_approved: approved,
            embodied_proof: approved,
            parallel_count: width
          )
          results << {
            "id" => n["id"] || n[:id],
            "kind" => kind.to_s,
            "status" => res.status.to_s,
            "gate" => res.gate_result.to_s,
            "feedback" => res.feedback.to_s,
            "frme" => res.frme_classes
          }
        end

        if persist_script && !human_approved
          return {
            ok: false,
            error: "persist_script_requires_1_0",
            nodes: results,
            note: "Tier 2 persistence of orchestration scripts is human-gated"
          }
        end

        all_ok = results.all? { |r| r["status"] == "verified" || r["feedback"] == "proceed" }
        log_contrail(
          purpose: "graph_plan",
          tier: persist_script ? 2 : 1,
          approval: human_approved ? "1/0" : "auto",
          outcome: all_ok ? "ok" : "held",
          payload: {
            "parallel" => width,
            "node_count" => results.size,
            "persist_script" => !!persist_script,
            "nodes" => results,
            "frme" => FrmeLite.annotate(:rlm_fanout)
          }
        )
        {
          ok: all_ok,
          parallel: width,
          nodes: results,
          note: "LITE dry-run — no real graph execution"
        }
      end

      def max_parallel
        @gate.max_parallel.to_i
      end

      def width_ok?(width, human_approved: false)
        return true if human_approved
        width.to_i <= max_parallel
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  approved = ARGV.include?("--approved") || ARGV.include?("1/0")
  persist = ARGV.include?("--persist")
  parallel = 2
  ARGV.each_with_index { |a, i| parallel = ARGV[i + 1].to_i if a == "--parallel" }

  nodes = [
    { "id" => "n1", "kind" => "read" },
    { "id" => "n2", "kind" => "summary" },
    { "id" => "n3", "kind" => "write_local", "human_gated" => true }
  ]
  r = Afterstring::Adapters::GraphRunner.new
  out = r.plan(nodes: nodes, parallel: parallel, human_approved: approved, persist_script: persist)
  puts out.inspect
  exit(out[:ok] ? 0 : 2)
end
