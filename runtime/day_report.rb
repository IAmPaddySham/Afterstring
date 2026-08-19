# frozen_string_literal: true
# Afterstring 1/0 LITE OS — beginning-of-day host snapshot.
# Invoked. Not a daemon. Future Agency: no silent schedule.
#
#   ruby runtime/day_report.rb
#   ruby runtime/day_report.rb --json

ROOT = File.expand_path("..", __dir__)
$LOAD_PATH.unshift(File.join(ROOT, "runtime"))
require "json"
require "time"
require "fileutils"
require_relative "sabbath"
require_relative "continuity_check"

module Afterstring
  module DayReport
    module_function

    def snapshot
      state = File.expand_path("~/.afterstring")
      sab = Sabbath.new(File.join(state, "sabbath.json"), interval_hours: 24)
      cont = ContinuityCheck.new(root: ROOT, state_dir: state)
      lite = lite_hold?
      layer_ids = layer0_ids
      {
        "utc" => Time.now.utc.iso8601,
        "kind" => "bod",
        "public_name" => "Afterstring 1/0 LITE OS",
        "sabbath_due" => sab.due?,
        "sabbath_remaining" => sab.remaining_human,
        "continuity_hold" => cont.last_result == "HOLD",
        "continuity_due" => cont.due?,
        "continuity_remaining" => cont.remaining_human,
        "lite_hold" => lite,
        "layer0_n" => layer_ids.size,
        "seat_empty" => seat_empty?,
        "soul_absent" => Dir.glob(File.join(ROOT, "**/{SOUL,MEMORY}.md")).none? { |p| !p.include?("/.git/") },
        "freeze" => freeze_flag,
        "last_sync" => last_sync,
        "last_event" => last_event,
        "kpi" => kpi_line(sab, cont, lite, layer_ids)
      }
    end

    def kpi_line(sab, cont, lite, layer_ids)
      {
        "sabbath_due" => sab.due? ? 1 : 0,
        "continuity_hold" => cont.last_result == "HOLD" ? 1 : 0,
        "lite_hold" => lite ? 1 : 0,
        "layer0_n" => layer_ids.size,
        "seat_empty" => seat_empty? ? 1 : 0,
        "soul_absent" => 1
      }
    end

    def print_human(s, io = $stdout)
      io.puts "══════════════════════════════════════"
      io.puts "  Afterstring 1/0 LITE OS · BOD"
      io.puts "  #{s['utc']}"
      io.puts "══════════════════════════════════════"
      io.puts format("  %-18s %s", "Sabbath", s["sabbath_due"] ? "DUE" : s["sabbath_remaining"])
      io.puts format("  %-18s %s", "Continuity", s["continuity_hold"] ? "HOLD" : "FAIL")
      io.puts format("  %-18s %s", "LITE 8.1.21", s["lite_hold"] ? "HOLD" : "FAIL")
      io.puts format("  %-18s %s", "Layer 0", "#{s['layer0_n']} invariants")
      io.puts format("  %-18s %s", "Seat", s["seat_empty"] ? "empty" : "CHECK")
      io.puts format("  %-18s %s", "SOUL.md", s["soul_absent"] ? "absent" : "PRESENT")
      io.puts format("  %-18s %s", "Freeze", s["freeze"])
      io.puts format("  %-18s %s", "Last sync", s["last_sync"] || "—")
      io.puts format("  %-18s %s", "Last event", s["last_event"] || "—")
      io.puts "──────────────────────────────────────"
      io.puts "  Checklist: Sabbath · Seat · LITE path · one named slice · Release possible"
      io.puts "  Not a daemon. Invoke: afterstring day"
      io.puts "  Let it stay → ∞ ❤️"
      io.puts "══════════════════════════════════════"
    end

    def append_kpi!(s)
      dir = File.join(ROOT, "reports")
      FileUtils.mkdir_p(dir)
      path = File.join(dir, "kpi.jsonl")
      line = { "utc" => s["utc"] }.merge(s["kpi"])
      File.open(path, "a") { |f| f.puts JSON.generate(line) }
      path
    end

    def lite_hold?
      out = `/usr/bin/ruby #{File.join(ROOT, "adapters/lite/runner.rb")} check 2>/dev/null`
      $?.success? && out.include?("HOLD")
    rescue StandardError
      false
    end

    def layer0_ids
      t = File.read(File.join(ROOT, "constitution/layer0.yaml"))
      t.scan(/^\s*- id:\s*(\d+)/).flatten
    end

    def seat_empty?
      Dir.glob(File.join(ROOT, "council/sessions/**/04_human_1_0.md")).none? { |p| File.read(p).match?(/- \[x\]/i) }
    end

    def freeze_flag
      p = File.expand_path("~/.afterstring/session.json")
      return "—" unless File.file?(p)
      JSON.parse(File.read(p))["freeze"]
    rescue StandardError
      "—"
    end

    def last_sync
      p = File.join(ROOT, ".last_multi_home_sync")
      File.file?(p) ? File.read(p).strip : nil
    end

    def last_event
      p = File.expand_path("~/.afterstring/session.json")
      return nil unless File.file?(p)
      JSON.parse(File.read(p))["last_event"]
    rescue StandardError
      nil
    end
  end
end

if $PROGRAM_NAME == __FILE__
  s = Afterstring::DayReport.snapshot
  json = ARGV.include?("--json")
  Afterstring::DayReport.append_kpi!(s) unless ARGV.include?("--no-kpi")
  if json
    puts JSON.pretty_generate(s)
  else
    Afterstring::DayReport.print_human(s)
  end
  bad = s["sabbath_due"] || !s["lite_hold"] || !s["continuity_hold"] || s["layer0_n"] != 12 || !s["seat_empty"]
  exit(bad ? 2 : 0)
end
