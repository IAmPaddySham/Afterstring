#!/usr/bin/env ruby
# frozen_string_literal: true
# After_Silicon 8.1.20 — LITE refuse-path. No CIM array. No analog writes.
#
#   ruby adapters/silicon/runner.rb status
#   ruby adapters/silicon/runner.rb analog-pass
#   ruby adapters/silicon/runner.rb mapping-example

ROOT = File.expand_path("../..", __dir__)
$LOAD_PATH.unshift(File.join(ROOT, "runtime"))
require "adapter_base"
require "json"

module Afterstring
  class SiliconAdapter < AdapterBase
    BANNER = "After_Silicon LITE. No analog fabric. Substrate ≠ kernel."

    def initialize(root: ROOT)
      super(name: "silicon", root: root)
    end

    def status
      {
        ok: true,
        banner: BANNER,
        slot: "8.1.20",
        ladder: "LITE",
        live_analog: false,
        invariant_13: "plugout_only",
        analogy_boundary: true,
        divine_authority_non_inference: true,
        seat: "empty_until_human_fills_04",
        mythic: "motivating_reference_not_dependency"
      }
    end

    def analog_pass
      log_contrail(
        purpose: "silicon_analog_pass_refused",
        tier: 3,
        outcome: "RESONANCE",
        payload: {
          "kind" => "host_event",
          "fallback_state" => "LITE",
          "human_auth_state" => "seat_empty",
          "reason" => "no_analog_array"
        }
      )
      {
        ok: false,
        error: "analog_pass_blacklisted",
        gate: "LITE_FALLBACK",
        banner: BANNER,
        note: "No CIM on this host. Efficiency is not authorization."
      }
    end

    def mapping_example
      log_contrail(
        purpose: "silicon_mapping_example",
        tier: 1,
        outcome: "ok",
        payload: {
          "hardware" => "conductance_drift_demo",
          "not" => "virtue_decay",
          "move" => "GPSL-H pause_and_recalibrate",
          "persist" => false,
          "fallback_state" => "LITE"
        }
      )
      {
        ok: true,
        example: "drift → analog_trust↓ → GPSL-H → persist withheld",
        identity_claim: false,
        banner: BANNER
      }
    end
  end
end

if $PROGRAM_NAME == __FILE__
  ad = Afterstring::SiliconAdapter.new
  cmd = ARGV.shift || "status"
  out = case cmd
        when "status" then ad.status
        when "analog-pass" then ad.analog_pass
        when "mapping-example" then ad.mapping_example
        else { ok: false, error: "unknown_cmd", note: "status|analog-pass|mapping-example" }
        end
  puts JSON.pretty_generate(out)
  exit(out[:ok] || out["ok"] ? 0 : 2)
end
