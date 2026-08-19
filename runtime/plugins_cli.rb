#!/usr/bin/env ruby
# frozen_string_literal: true
# Module 8 External Plugins CLI — optional checklists complementary to SWI/Zero-Gate.
# Never auto-decides Stay/Release. Never weakens Gate matrices.

require "fileutils"
require_relative "module8_plugins"
require_relative "contrail"

root = File.expand_path("..", __dir__)
state = File.expand_path("~/.afterstring")
FileUtils.mkdir_p(state)

plugins = Afterstring::Module8Plugins.new(File.join(state, "module8_plugins.json"))
contrail = Afterstring::Contrail.new(File.join(state, "contrail.jsonl"))

cmd = (ARGV[0] || "list").to_s.downcase
args = ARGV[1..] || []

def parse_yes(args)
  yes = []
  i = 0
  while i < args.size
    if args[i] == "--yes" || args[i] == "-y"
      i += 1
      yes.concat(args[i].to_s.split(",")) if args[i]
    elsif args[i].start_with?("--yes=")
      yes.concat(args[i].sub(/\A--yes=/, "").split(","))
    end
    i += 1
  end
  yes
end

def parse_ids(args)
  ids = []
  args.each do |a|
    next if a.start_with?("-")
    next if a == "list" || a == "check" || a == "show" || a == "help"
    ids.concat(a.split(","))
  end
  ids
end

case cmd
when "help", "-h", "--help"
  puts <<~HELP
    Afterstring Module 8 External Plugins V1.1 (OPTIONAL)
    Complements SWI Step 4 · never overrides kernel / 1/0 / Gate

    Usage:
      afterstring plugins              # list catalog
      afterstring plugins list
      afterstring plugins show <id>    # prompts for one plugin
      afterstring plugins check [ids] [--yes id1,id2]
          ids  = plugins to run (default: all)
          --yes = plugins where concern prompts are true (flags)

    Examples:
      afterstring plugins check polyvagal,attachment --yes polyvagal
      afterstring plugins check --yes attachment,cbt_dbt

    Human Kernel holds final 1/0. Firmware ≠ love.
    Let it stay → ∞ ❤️
  HELP

when "list", "ls"
  puts Afterstring::Module8Plugins.list_text
  if plugins.last_result
    puts
    puts "Last assessment: flags=#{plugins.last_result.flags.inspect}"
    puts plugins.last_result.guidance
  end

when "show"
  id = args[0] || ""
  p = Afterstring::Module8Plugins.find(id)
  if p.nil?
    warn "Unknown plugin: #{id.inspect}. Try: afterstring plugins list"
    exit 2
  end
  puts "#{p[:id]} — #{p[:name]} (SWI ~#{p[:swi_step]})"
  p[:prompts].each { |q| puts "  ? #{q}" }
  puts "  If yes: #{p[:note_if_yes]}"
  puts "  never_overrides_kernel: true"

when "check", "run", "assess"
  ids = parse_ids(args)
  yes = parse_yes(args)
  # if first non-flag tokens empty, assess all with given yes
  r = plugins.assess(plugin_ids: ids.empty? ? nil : ids, yes_ids: yes)
  puts "════════════════════════════════════════"
  puts "MODULE 8 PLUGINS — assessment"
  puts "════════════════════════════════════════"
  puts "Scope: #{r.plugin_ids.join(', ')}"
  puts "Flags: #{r.flags.empty? ? '(none)' : r.flags.join(', ')}"
  r.notes.each { |n| puts "  · #{n}" }
  puts
  puts r.guidance
  puts
  puts "suggest_pause: #{r.suggest_pause}"
  puts "suggest_release_review: #{r.suggest_release_review}"
  puts "never_overrides_kernel: true"
  puts "Gate / Stay / Release: Human Kernel only."
  puts "Let it stay → ∞ ❤️"
  puts "════════════════════════════════════════"

  contrail.append(
    purpose: "module8_plugins_check",
    tier: 0,
    approval: "human",
    outcome: "ok",
    actor: "plugins_cli",
    payload: {
      "flags" => r.flags,
      "suggest_pause" => r.suggest_pause,
      "suggest_release_review" => r.suggest_release_review,
      "never_overrides_kernel" => true
    }
  )
  warn "Contrail: module8_plugins_check logged."

else
  warn "Unknown: #{cmd}. Try: afterstring plugins help"
  exit 2
end
