#!/usr/bin/env ruby
# frozen_string_literal: true
# After_OpenWeight 8.1.19 — LITE local check runner.
# Does NOT download models, start Ollama/vLLM, or run inference.
# Pre-gates intents under Gate + FRME-lite + optional instance registry.

require_relative "../../runtime/adapter_base"
require_relative "../../runtime/artifact_identity"
require "json"
require "fileutils"
require "time"

module Afterstring
  module Adapters
    class OpenweightRunner < AdapterBase
      # Intent → gate action_kind
      INTENT_MAP = {
        "check" => :read,
        "list" => :read,
        "load" => :load_model,
        "infer" => :local_inference,
        "chat" => :local_inference,
        "fine_tune" => :fine_tune,
        "lora" => :fine_tune,
        "multi_instance" => :multi_instance,
        "spawn" => :spawn_instance,
        "network_pull" => :network,
        "tool_write" => :write_local,
        "live_side_effect" => :live_account_write
      }.freeze

      def initialize(root: nil)
        super(name: "openweight", root: root)
        @registry_path = File.join(@state_dir, "openweight_instances.json")
        @registry = load_registry
      end

      def max_instances
        @constitution.matrix_openweight&.dig("lite_bounds", "max_concurrent_local_instances") || 3
      end

      def instances
        Array(@registry["instances"])
      end

      def active_count
        instances.count { |i| i["status"].to_s == "active" }
      end

      def instances_ok?(extra = 0)
        active_count + extra.to_i <= max_instances.to_i
      end

      # dry-run register of an intended local instance (not a real process)
      def register_intent!(model_id:, human_approved: false)
        unless instances_ok?(1)
          log_contrail(
            purpose: "openweight_instance_cap",
            tier: 2,
            outcome: "RESONANCE",
            payload: { "active" => active_count, "max" => max_instances }
          )
          return { ok: false, error: "instance_cap", active: active_count, max: max_instances }
        end
        res = pre_execute(
          action_kind: :load_model,
          human_approved: human_approved,
          embodied_proof: human_approved,
          parallel_count: active_count + 1
        )
        if res.status != :verified && res.feedback != :proceed
          return {
            ok: false,
            gate: res.gate_result,
            feedback: res.feedback,
            note: "load held — check sabbath / 1/0 / trust"
          }
        end
        entry = {
          "id" => "ow-#{Time.now.to_i}-#{model_id.to_s[0, 24]}",
          "model_id" => model_id.to_s,
          "status" => "intent",
          "registered_at" => Time.now.utc.iso8601,
          "note" => "LITE intent only — no weights loaded by this runner"
        }
        @registry["instances"] = instances + [entry]
        @registry["updated_at"] = Time.now.utc.iso8601
        save_registry!
        log_contrail(
          purpose: "openweight_register_intent",
          tier: 1,
          approval: human_approved ? "1/0" : "auto",
          outcome: "ok",
          payload: entry
        )
        { ok: true, entry: entry, active: active_count, max: max_instances }
      end


      def artifact_bind(model_id:, human_approved:, intent:, engine: "ollama")
        ver = @constitution.layer0.is_a?(Hash) ? (@constitution.layer0["version"] || "11.11.11") : "11.11.11"
        art = ArtifactIdentity.new(
          "upstream_id" => model_id.to_s,
          "engine" => engine.to_s,
          "constitution" => "layer0@#{ver}",
          "source" => "local",
          "license" => "unknown"
        )
        ArtifactIdentity.bind_authorization(art, human_approved: human_approved, intent: intent)
      end

      def check(intent:, model_id: nil, human_approved: false, parallel: nil)
        kind = INTENT_MAP[intent.to_s] || :local_inference
        pc = parallel.nil? ? [active_count, 1].max : parallel.to_i
        res = pre_execute(
          action_kind: kind,
          human_approved: human_approved,
          embodied_proof: human_approved,
          parallel_count: pc
        )
        art = if model_id.to_s.strip.empty?
                nil
              else
                artifact_bind(model_id: model_id, human_approved: human_approved, intent: intent)
              end
        log_contrail(
          purpose: "openweight_check:#{intent}",
          tier: res.tier,
          approval: human_approved ? "1/0" : "auto",
          outcome: res.gate_result.to_s,
          payload: {
            "intent" => intent.to_s,
            "model_id" => model_id.to_s,
            "mapped_kind" => kind.to_s,
            "status" => res.status.to_s,
            "frme" => res.frme_classes,
            "instances_active" => active_count,
            "max_instances" => max_instances,
            "artifact_complete" => art && art["artifact"] && art["artifact"]["complete"]
          }
        )
        {
          ok: res.feedback == :proceed || res.status == :verified,
          intent: intent.to_s,
          kind: kind.to_s,
          gate: res.gate_result,
          feedback: res.feedback,
          frme: res.frme_classes,
          sabbath_due: @sabbath.due?,
          instances: { active: active_count, max: max_instances },
          model_id: model_id,
          artifact: art,
          note: "LITE dry-run — no open-weight runtime started; Artifact Identity partial until weight_hash set"
        }
      end

      def status_report
        {
          plugout: "8.1.19 After_OpenWeight",
          mode: @gate.mode,
          sabbath_due: @sabbath.due?,
          e13_product: @gate.e13_product,
          max_instances: max_instances,
          instances: instances,
          matrix_loaded: !@constitution.matrix_openweight.nil?,
          local_runtimes: {
            ollama: which?("ollama"),
            python3: which?("python3"),
            note: "Presence of binary ≠ authorization to run continuous agents"
          },
          hardware_hint: "M5-class / high RAM supports quantized local models; still LITE-gated",
          seals: "Capability may download. Authority stays at Layer 0."
        }
      end

      private

      def load_registry
        if File.file?(@registry_path)
          JSON.parse(File.read(@registry_path))
        else
          { "instances" => [], "updated_at" => nil }
        end
      rescue StandardError
        { "instances" => [] }
      end

      def save_registry!
        FileUtils.mkdir_p(File.dirname(@registry_path))
        File.write(@registry_path, JSON.pretty_generate(@registry))
      end

      def which?(cmd)
        ENV["PATH"].to_s.split(File::PATH_SEPARATOR).any? do |dir|
          File.executable?(File.join(dir, cmd))
        end
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  approved = ARGV.include?("--approved") || ARGV.include?("1/0")
  runner = Afterstring::Adapters::OpenweightRunner.new

  if ARGV.include?("--status") || ARGV.empty?
    require "pp"
    pp runner.status_report
    exit 0
  end

  if ARGV.include?("--register")
    mid = "unknown"
    ARGV.each_with_index { |a, i| mid = ARGV[i + 1] if a == "--model" && ARGV[i + 1] }
    out = runner.register_intent!(model_id: mid, human_approved: approved)
    puts out.inspect
    exit(out[:ok] ? 0 : 2)
  end

  intent = "check"
  model = nil
  ARGV.each_with_index do |a, i|
    intent = ARGV[i + 1] if a == "--intent" && ARGV[i + 1]
    model = ARGV[i + 1] if a == "--model" && ARGV[i + 1]
  end
  # bare first non-flag token as intent
  bare = ARGV.reject { |a| a.start_with?("-") || %w[1/0].include?(a) }
  intent = bare[0] if bare[0] && !ARGV.include?("--intent")

  out = runner.check(intent: intent, model_id: model, human_approved: approved)
  puts out.inspect
  exit(out[:ok] ? 0 : 2)
end
