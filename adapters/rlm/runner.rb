#!/usr/bin/env ruby
# frozen_string_literal: true
# After_RLM adapter wrapper — invokes shared gate + verifier (not Prime Agent itself).
# Usage:
#   ruby adapters/rlm/runner.rb --action read
#   ruby adapters/rlm/runner.rb --action write_local --approved
#   ruby adapters/rlm/runner.rb --verify-contrail

ROOT = File.expand_path("../..", __dir__)
$LOAD_PATH.unshift(File.join(ROOT, "runtime"))
require "adapter_base"
require "fileutils"

require "json"
require "fileutils"
require "time"

module Afterstring
  class RlmAdapter < AdapterBase
    def initialize(root: ROOT)
      super(name: "rlm", root: root)
      @bounds_path = File.join(@state_dir, "rlm_bounds.json")
      @bounds = load_bounds
    end

    # LITE bounds from matrix-rlm (depth/width) — advisory check helpers
    def depth_ok?(depth)
      max = @constitution.matrix_rlm.dig("lite_bounds", "max_recursive_depth") || 2
      depth.to_i <= max.to_i
    end

    def width_ok?(width)
      max = @constitution.matrix_rlm.dig("lite_bounds", "max_concurrent_subagents") || 3
      width.to_i <= max.to_i
    end

    def enter_depth!(delta = 1)
      @bounds["depth"] = @bounds["depth"].to_i + delta.to_i
      save_bounds!
      @bounds["depth"]
    end

    def leave_depth!(delta = 1)
      @bounds["depth"] = [@bounds["depth"].to_i - delta.to_i, 0].max
      save_bounds!
      @bounds["depth"]
    end

    def current_depth
      @bounds["depth"].to_i
    end

    def daemon_ok?(minutes_running)
      max_m = @constitution.matrix_rlm.dig("lite_bounds", "daemon_max_minutes") || 60
      minutes_running.to_i <= max_m.to_i
    end

    private

    def load_bounds
      if File.file?(@bounds_path)
        JSON.parse(File.read(@bounds_path))
      else
        { "depth" => 0, "updated_at" => Time.now.utc.iso8601 }
      end
    rescue StandardError
      { "depth" => 0 }
    end

    def save_bounds!
      FileUtils.mkdir_p(File.dirname(@bounds_path))
      @bounds["updated_at"] = Time.now.utc.iso8601
      File.write(@bounds_path, JSON.pretty_generate(@bounds))
    end
  end
end

if $PROGRAM_NAME == __FILE__
  action = "read"
  approved = false
  verify_only = false
  ARGV.each_with_index do |arg, i|
    case arg
    when "--action" then action = ARGV[i + 1]
    when "--approved", "--human", "1/0" then approved = true
    when "--verify-contrail" then verify_only = true
    when "--help", "-h"
      puts "Usage: runner.rb --action KIND [--approved] | --verify-contrail"
      exit 0
    end
  end

  adapter = Afterstring::RlmAdapter.new
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

  res = adapter.pre_execute(
    action_kind: action,
    human_approved: approved,
    embodied_proof: approved
  )
  puts "#{res.status}|#{res.gate_result}|#{res.feedback}"
  exit(res.feedback == :proceed ? 0 : 2)
end
