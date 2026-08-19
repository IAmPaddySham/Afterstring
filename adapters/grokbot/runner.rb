#!/usr/bin/env ruby
# frozen_string_literal: true
# After_GrokBot adapter (Module 8.1.18) — local gate + verifier sidecar.
# Does NOT control xAI Grok Bot cloud. Operator-native / Phase B only.
#
# Usage:
#   ruby adapters/grokbot/runner.rb --action read
#   ruby adapters/grokbot/runner.rb --action live_account_write --approved
#   ruby adapters/grokbot/runner.rb --action routine_promotion --approved \
#        --who "Paddy Sham / Human Kernel" --what "send weekly digest" --where "email" \
#        --when "now" --account "work" --environment "prod" --authority "1/0"
#   ruby adapters/grokbot/runner.rb --check-bots 4
#   ruby adapters/grokbot/runner.rb --verify-contrail
#   ruby adapters/grokbot/runner.rb --standing-orders

GROKBOT_ROOT = File.expand_path("../..", __dir__)
$LOAD_PATH.unshift(File.join(GROKBOT_ROOT, "runtime"))
require "adapter_base"

module Afterstring
  class GrokbotAdapter < AdapterBase
    REALITY_VETO_KEYS = %w[who what where when account environment authority].freeze

    def initialize(root: GROKBOT_ROOT)
      super(name: "grokbot", root: root)
    end

    def matrix
      @constitution.matrix_grokbot
    end

    def max_concurrent_bots
      matrix&.dig("lite_bounds", "max_concurrent_active_bots") || 3
    end

    def max_delegation_depth
      matrix&.dig("lite_bounds", "max_delegation_depth") || 1
    end

    def bots_ok?(count)
      count.to_i <= max_concurrent_bots.to_i
    end

    def depth_ok?(depth)
      depth.to_i <= max_delegation_depth.to_i
    end

    # Future Agency Invariant (text for operators / skills)
    def future_agency_invariant
      matrix&.dig("future_agency_invariant") ||
        "No present authorization may silently become indefinite future authority."
    end

    # Reality Veto 7-part diagnostic (Tier 2/3). Returns [ok, missing_keys]
    def reality_veto_complete?(fields)
      fields = stringify_keys(fields)
      missing = REALITY_VETO_KEYS.reject { |k| present?(fields[k]) }
      [missing.empty?, missing]
    end

    def tier2_or_3?(action_kind)
      t = @gate.infer_tier(action_kind)
      t >= 2
    end

    # Full pre-check: optional RV fields + gate + optional bot count
    def check(action_kind:, human_approved: false, target_ambiguous: false,
              parallel_count: nil, bot_count: nil, rv: {})
      reasons = []
      status_bits = []

      if bot_count && !bots_ok?(bot_count)
        reasons << "bots_exceed_lite:#{bot_count}>#{max_concurrent_bots}"
        status_bits << "TRIGGER_RESONANCE_MODE"
      end

      if tier2_or_3?(action_kind)
        ok, missing = reality_veto_complete?(rv)
        unless ok
          reasons << "reality_veto_incomplete:#{missing.join(',')}"
          # Incomplete diagnostic → treat as ambiguous target (Reality Veto path)
          target_ambiguous = true unless human_approved && missing.empty?
          # Even with approval, incomplete RV is a hold for LITE operator discipline
          unless ok
            res = pre_execute(
              action_kind: action_kind,
              human_approved: false,
              target_ambiguous: true,
              embodied_proof: false,
              parallel_count: parallel_count || bot_count
            )
            return wrap_result(res, reasons, bot_count)
          end
        end
      end

      res = pre_execute(
        action_kind: action_kind,
        human_approved: human_approved,
        target_ambiguous: target_ambiguous,
        embodied_proof: human_approved,
        parallel_count: parallel_count || bot_count
      )
      wrap_result(res, reasons, bot_count)
    end

    def log_authorization!(action_kind:, approved:, rv: {}, note: nil)
      log_contrail(
        purpose: "grokbot_auth:#{action_kind}",
        tier: @gate.infer_tier(action_kind),
        approval: approved ? "1/0 = To Stay" : "hold",
        outcome: approved ? "authorized" : "denied",
        payload: {
          "rv" => stringify_keys(rv),
          "note" => note.to_s[0, 200],
          "future_agency" => future_agency_invariant.to_s[0, 240]
        }
      )
    end

    def standing_orders_path
      File.join(@root, "adapters", "grokbot", "STANDING_ORDERS.md")
    end

    private

    def wrap_result(res, reasons, bot_count)
      {
        status: res.status,
        gate_result: res.gate_result,
        feedback: res.feedback,
        reasons: (res.reasons || []) + reasons,
        bot_count: bot_count,
        max_bots: max_concurrent_bots
      }
    end

    def stringify_keys(h)
      return {} if h.nil?
      h.each_with_object({}) { |(k, v), o| o[k.to_s] = v }
    end

    def present?(v)
      !v.nil? && !v.to_s.strip.empty?
    end
  end
end

if $PROGRAM_NAME == __FILE__
  action = "read"
  approved = false
  verify_only = false
  standing = false
  check_bots = nil
  log_auth = false
  rv = {}

  ARGV.each_with_index do |arg, i|
    case arg
    when "--action" then action = ARGV[i + 1]
    when "--approved", "--human", "1/0" then approved = true
    when "--verify-contrail" then verify_only = true
    when "--standing-orders" then standing = true
    when "--check-bots" then check_bots = ARGV[i + 1].to_i
    when "--log-auth" then log_auth = true
    when "--who" then rv["who"] = ARGV[i + 1]
    when "--what" then rv["what"] = ARGV[i + 1]
    when "--where" then rv["where"] = ARGV[i + 1]
    when "--when" then rv["when"] = ARGV[i + 1]
    when "--account" then rv["account"] = ARGV[i + 1]
    when "--environment" then rv["environment"] = ARGV[i + 1]
    when "--authority" then rv["authority"] = ARGV[i + 1]
    when "--help", "-h"
      puts <<~HELP
        After_GrokBot local sidecar (does not control xAI cloud)

        Usage:
          runner.rb --action KIND [--approved] [RV fields…]
          runner.rb --check-bots N
          runner.rb --verify-contrail
          runner.rb --standing-orders

        Actions: read | live_account_write | routine_promotion | behavioral_memory
                 multi_bot | schedule_persistence | network | write_local | …

        Reality Veto (Tier 2/3): --who --what --where --when --account --environment --authority
        --log-auth  append authorization attempt to Contrail
      HELP
      exit 0
    end
  end

  adapter = Afterstring::GrokbotAdapter.new

  if standing
    path = adapter.standing_orders_path
    if File.file?(path)
      puts File.read(path)
      exit 0
    else
      warn "Missing #{path}"
      exit 1
    end
  end

  if verify_only
    begin
      adapter.verify_contrail!
      puts "CONTRAIL_OK"
      exit 0
    rescue Afterstring::Contrail::TamperError => e
      puts "TRIGGER_REALITY_VETO"
      warn e.message
      exit 2
    end
  end

  if check_bots
    ok = adapter.bots_ok?(check_bots)
    puts ok ? "BOTS_OK|#{check_bots}|max=#{adapter.max_concurrent_bots}" : "BOTS_EXCEED|#{check_bots}|max=#{adapter.max_concurrent_bots}"
    exit(ok ? 0 : 2)
  end

  out = adapter.check(
    action_kind: action,
    human_approved: approved,
    bot_count: check_bots,
    rv: rv
  )

  if log_auth
    adapter.log_authorization!(
      action_kind: action,
      approved: approved && out[:feedback] == :proceed,
      rv: rv,
      note: out[:reasons]&.join(";")
    )
  end

  puts [
    out[:gate_result],
    out[:feedback],
    out[:status],
    (out[:reasons] || []).join(","),
    "max_bots=#{out[:max_bots]}"
  ].join("|")

  exit(out[:feedback] == :proceed ? 0 : 2)
end
