#!/usr/bin/env ruby
# frozen_string_literal: true
# After_LITE 8.1.21 — Afterstring 1/0 LITE OS. Context diet. Not analog.
#
#   ruby adapters/lite/runner.rb status|check|path

ROOT = File.expand_path("../..", __dir__)
require "json"

module Afterstring
  class LiteAdapter
    LITE = File.join(ROOT, "papers/LITE_READING_PATH.md")
    MOD = File.join(ROOT, "papers/module-8.1.21-after-lite.md")
    MATRIX = File.join(ROOT, "constitution/matrix-lite.yaml")
    AGENTS = File.join(ROOT, "AGENTS.md")
    LAYER0 = File.join(ROOT, "constitution/layer0.yaml")
    ALLOW = File.join(ROOT, "adapters/grokbot/agent/ALLOWLIST.json")
    CONSOLIDATED = File.join(ROOT, "AFTERSTRING_CONSOLIDATED.md")

    def status
      {
        "ok" => true,
        "slot" => "8.1.21",
        "plugout" => "After_LITE",
        "public_name" => "Afterstring 1/0 LITE OS",
        "status" => "GOLD",
        "layer0" => false,
        "not" => "8.1.20A",
        "lite_path" => "papers/LITE_READING_PATH.md",
        "banner" => "Archive stays. Context is LITE. Persistence of a file ⇏ load it."
      }
    end

    def path
      text = File.file?(LITE) ? File.read(LITE) : "(missing LITE_READING_PATH.md)"
      status.merge("ok" => File.file?(LITE), "text" => text)
    end

    def check
      probes = [
        ok(File.file?(LITE), "lite_path", LITE),
        ok(File.file?(MOD), "module_8_1_21", MOD),
        ok(File.file?(MATRIX), "matrix_lite", MATRIX),
        probe_agents,
        probe_layer0,
        probe_allowlist,
        ok(File.file?(CONSOLIDATED), "consolidated_on_disk", "present — do not load unless named")
      ]
      failed = probes.reject { |p| p[:ok] }
      {
        "ok" => failed.empty?,
        "result" => failed.empty? ? "HOLD" : "FAIL",
        "slot" => "8.1.21",
        "public_name" => "Afterstring 1/0 LITE OS",
        "failed" => failed.map { |p| p[:id] },
        "probes" => probes
      }
    end

    private

    def probe_agents
      t = File.file?(AGENTS) ? File.read(AGENTS) : ""
      ok(
        t.include?("LITE_READING_PATH") && t.include?("8.1.21 After_LITE"),
        "agents_lite_rule",
        "Operating Rule present"
      )
    end

    def probe_layer0
      t = File.file?(LAYER0) ? File.read(LAYER0) : ""
      ids = t.scan(/^\s*- id:\s*(\d+)/).flatten
      ok(ids == %w[1 2 3 4 5 6 7 8 9 10 11 12], "layer0_still_12", "ids=#{ids.join(',')}")
    end

    def probe_allowlist
      t = File.file?(ALLOW) ? File.read(ALLOW) : ""
      ok(!t.include?("AFTERSTRING_CONSOLIDATED") && !t.include?("notes-archive/bodies"),
         "allowlist_not_archive", "CONSOLIDATED and notes bodies not on diet")
    end

    def ok(cond, id, detail)
      { id: id, ok: !!cond, detail: detail }
    end
  end
end

if $PROGRAM_NAME == __FILE__
  ad = Afterstring::LiteAdapter.new
  cmd = ARGV.shift || "status"
  out = case cmd
        when "status" then ad.status
        when "check", "run" then ad.check
        when "path" then ad.path
        else { "ok" => false, "error" => "unknown_cmd", "note" => "status|check|path" }
        end
  puts JSON.pretty_generate(out)
  exit(out["ok"] || out[:ok] ? 0 : 2)
end
