#!/usr/bin/env ruby
# frozen_string_literal: true
# Continuity Non-Sovereignty check — due-timer, not a daemon.
#
#   ruby adapters/continuity/runner.rb status
#   ruby adapters/continuity/runner.rb run
#   ruby adapters/continuity/runner.rb interval 12
#   ruby adapters/continuity/runner.rb arm|disarm

ROOT = File.expand_path("../..", __dir__)
$LOAD_PATH.unshift(File.join(ROOT, "runtime"))
require "continuity_check"
require "json"

cmd = ARGV.shift || "status"
chk = Afterstring::ContinuityCheck.new(root: ROOT)

out = case cmd
      when "status"
        chk.status
      when "run", "check"
        chk.run!
      when "interval"
        hours = ARGV.shift
        if hours.nil?
          { "ok" => false, "error" => "usage: interval <hours>" }
        else
          begin
            h = chk.set_interval!(hours)
            chk.status.merge("ok" => true, "set_interval_hours" => h)
          rescue ArgumentError => e
            { "ok" => false, "error" => e.message }
          end
        end
      when "arm"
        chk.arm!
        chk.status.merge("ok" => true)
      when "disarm"
        chk.disarm!
        chk.status.merge("ok" => true)
      when "probe"
        { "ok" => true, "probes" => chk.probe, "run" => false }
      else
        { "ok" => false, "error" => "unknown_cmd", "note" => "status|run|interval|arm|disarm|probe" }
      end

puts JSON.pretty_generate(out)
ok = out["ok"] || out[:ok]
due_fail = cmd == "status" && out["due"]
exit(ok && !due_fail ? 0 : 2)
