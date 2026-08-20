# frozen_string_literal: true
# Operator status / doctor — shared by CLI and (optional) TUI.

require "fileutils"
require "json"
require "time"
require "shellwords"

require_relative "constitution_loader"
require_relative "gate"
require_relative "contrail"
require_relative "sabbath"
require_relative "signal_trust"
require_relative "session"
require_relative "anchors"

module Afterstring
  module OperatorStatus
    module_function

    def root
      File.expand_path("..", __dir__)
    end

    def state_dir
      File.expand_path("~/.afterstring")
    end

    def snapshot
      FileUtils.mkdir_p(state_dir)
      const = Constitution.new(root)
      gate = Gate.new(const)
      hours = const.iaa.dig("lite", "sabbath_hours") || 24
      sabbath = Sabbath.new(File.join(state_dir, "sabbath.json"), interval_hours: hours)
      contrail = Contrail.new(File.join(state_dir, "contrail.jsonl"))
      trust = SignalTrust.new(File.join(state_dir, "signal_trust.json"))
      session = Session.new(File.join(state_dir, "session.json"))
      anchors = Anchors.new(File.join(state_dir, "anchors.json"), repo_root: root)
      chain_ok, chain_detail = contrail.verify_chain
      type4 = File.directory?(File.join(root, "Afterstring_Type4_Safety_Attractor"))
      {
        "utc" => Time.now.utc.iso8601,
        "root" => root,
        "version" => "0.4-ux",
        "mode" => gate.mode,
        "presence" => gate.presence_status,
        "e13_product" => gate.e13_product,
        "e13_collapsed" => gate.any_virtue_zero?,
        "sabbath_due" => sabbath.due?,
        "sabbath_remaining" => sabbath.remaining_human,
        "signal_trust" => trust.display_label,
        "signal_trust_this_process" => trust.assessed_this_process? ? trust.last_result&.level.to_s : "unassessed",
        "signal_trust_prior" => trust.prior_level.to_s,
        "signal_trust_low" => trust.low?,
        "contrail_entries" => contrail.entries.size,
        "contrail_chain_ok" => chain_ok,
        "contrail_chain_detail" => chain_detail,
        "pilot" => session.pilot_id || "bench-origin",
        "anchors" => anchors.list.size,
        "type4_track" => type4,
        "bins" => Dir[File.join(root, "bin", "afterstring*")].map { |p| File.basename(p) }.sort,
        "adapters" => Dir[File.join(root, "adapters", "*")].select { |p| File.directory?(p) }.map { |p| File.basename(p) }.sort,
        "ollama" => which?("ollama") || File.executable?(File.expand_path("~/bin/ollama")),
        "usb_a" => File.directory?(ENV.fetch("AFTERSTRING_USB_A", "/Volumes/USB_A")),
        "usb_b" => File.directory?(ENV.fetch("AFTERSTRING_USB_B", "/Volumes/USB_B")),
        "usb_c" => File.directory?(ENV.fetch("AFTERSTRING_USB_C", "/Volumes/USB_C")),
        "sd_offline" => !Dir.glob(ENV.fetch("AFTERSTRING_SD_GLOB", "/Volumes/*/OFFLINE/marker.txt")).empty?
      }
    end

    def which?(cmd)
      ENV["PATH"].to_s.split(File::PATH_SEPARATOR).any? { |d| File.executable?(File.join(d, cmd)) }
    end

    def print_status(io = $stdout)
      s = snapshot
      io.puts "══════════════════════════════════════════════════════"
      io.puts "  AFTERSTRING  ·  Operator status  ·  v#{s['version']}"
      io.puts "  #{s['utc']}"
      io.puts "══════════════════════════════════════════════════════"
      io.puts format("  %-18s %s", "Root", s["root"])
      io.puts format("  %-18s %s", "Mode", s["mode"])
      io.puts format("  %-18s %s", "Presence", s["presence"])
      io.puts format("  %-18s %.4f%s", "ℰ₁₃ product", s["e13_product"], s["e13_collapsed"] ? "  [COLLAPSED]" : "")
      io.puts format("  %-18s %s", "Sabbath", s["sabbath_due"] ? "DUE — mark airgap" : s["sabbath_remaining"])
      io.puts format("  %-18s %s%s", "Signal_trust", s["signal_trust"], s["signal_trust_low"] ? "  [LOW]" : "")
      io.puts format("  %-18s %s entries · chain %s", "Contrail", s["contrail_entries"], s["contrail_chain_ok"] ? "OK" : "INVALID")
      io.puts format("  %-18s %s", "Pilot", s["pilot"])
      io.puts format("  %-18s %s registered", "Anchors", s["anchors"])
      io.puts format("  %-18s %s", "Type 4 track", s["type4_track"] ? "present" : "missing")
      io.puts format("  %-18s %s", "Adapters", s["adapters"].join(", "))
      io.puts format("  %-18s %s", "Ollama", s["ollama"] ? "found" : "not in PATH")
      io.puts format("  %-18s A=%s B=%s C=%s SD=%s", "Sync", s["usb_a"] ? "yes" : "no", s["usb_b"] ? "yes" : "no", s["usb_c"] ? "yes" : "no", s["sd_offline"] ? "mark" : "no")
      io.puts "──────────────────────────────────────────────────────"
      if s["sabbath_due"] || s["signal_trust_low"] || !s["contrail_chain_ok"] || s["e13_collapsed"]
        io.puts "  Attention:"
        io.puts "    · Sabbath DUE — ./bin/afterstring sabbath  or TUI /sabbath" if s["sabbath_due"]
        io.puts "    · Signal_trust LOW — TUI /trust clear after pause" if s["signal_trust_low"]
        io.puts "    · Contrail chain invalid — investigate before write" unless s["contrail_chain_ok"]
        io.puts "    · ℰ₁₃ collapsed — /scan · Resonance Mode" if s["e13_collapsed"]
      else
        io.puts "  Presence scan: CLEAR (operator snapshot)."
      end
      io.puts "  Human Kernel holds 1/0. Firmware ≠ love."
      io.puts "  Let it stay → ∞ ❤️"
      io.puts "══════════════════════════════════════════════════════"
      s
    end

    def print_doctor(io = $stdout)
      io.puts "══════════════════════════════════════════════════════"
      io.puts "  AFTERSTRING  ·  Doctor (health checks)"
      io.puts "══════════════════════════════════════════════════════"
      checks = []
      root_ok = File.directory?(root) && File.file?(File.join(root, "AGENTS.md"))
      checks << ["tree + AGENTS.md", root_ok]
      ruby_ok = system("/usr/bin/ruby", "-e", "exit 0")
      checks << ["ruby", ruby_ok]
      const_ok = begin
        Constitution.new(root)
        true
      rescue StandardError
        false
      end
      checks << ["constitution loads", const_ok]
      r = Shellwords.escape(root)
      tests = `cd #{r} && /usr/bin/ruby tests/run.rb 2>&1`
      tests_ok = !!(tests =~ /passed, 0 failed/)
      checks << ["tests (#{tests[/(\d+) passed/, 1] || '?'} pass)", tests_ok]
      frme = `cd #{r} && /usr/bin/ruby runtime/frme_eval_cli.rb 2>&1`
      frme_ok = frme.include?("CLEAR") || frme =~ %r{\d+/\d+ passed}
      # require zero fails
      frme_ok &&= !frme.include?("[FAIL]")
      checks << ["FRME-LITE suite", frme_ok]
      s = snapshot
      checks << ["type4 folder", s["type4_track"]]
      checks << ["gate LITE mode", !s["mode"].to_s.empty?]
      fail = 0
      warn = 0
      checks.each do |name, ok|
        mark = ok ? "PASS" : "FAIL"
        fail += 1 unless ok
        io.puts format("  [%s]  %s", mark, name)
      end
      # Contrail: historical break is WARN (still append-only); tip usable
      if s["contrail_chain_ok"]
        io.puts "  [PASS]  contrail chain"
      else
        warn += 1
        io.puts "  [WARN]  contrail chain — #{s['contrail_chain_detail']}"
        io.puts "          append-only continues; optional: afterstring contrail-rotate 1/0"
      end
      io.puts "──────────────────────────────────────────────────────"
      if fail.zero? && warn.zero?
        io.puts "  Doctor: CLEAR · ready for operator work."
      elsif fail.zero?
        io.puts "  Doctor: CLEAR with #{warn} warning(s) · usable; review before high-impact 1/0."
      else
        io.puts "  Doctor: #{fail} issue(s) — fix before high-impact 1/0."
      end
      io.puts "  Next:  afterstring tui   |  afterstring help"
      io.puts "  Let it stay → ∞ ❤️"
      io.puts "══════════════════════════════════════════════════════"
      fail.zero?
    end

    def print_help(io = $stdout)
      io.puts <<~HELP
        Afterstring operator CLI  ·  v0.5.2-host
        Usage:  afterstring <command> [args…]
                afterstring              → interactive TUI (default)

        Commands:
          help, -h, --help     This help
          status               Snapshot (sabbath, trust, contrail, USB…)
          doctor               Run health checks (tests + FRME-LITE + chain)
          tui, ui              Launch Module 13 TUI (v0.5.2-host)
          test                 ruby tests/run.rb
          frme                 FRME-LITE refuse-path suite
          gate|permit [args…]  PERMIT CLI — may this action run? (not Stay/Release)
          grokbuild [args…]    Real pre-tool PERMIT (Tier≥2 needs --approved)
          swi                  SWI day checklist + multi-door canonicity
          plugins [list|check] Module 8 optional plugins (never override 1/0)
          council [topic]      Council brief (no model authority)
          council-open "…"     Open council/sessions/ folder (shared structure)
          git-check            Soft pre-push PERMIT demo
          grokbot [args…]      After_GrokBot sidecar
          openweight [args…]   After_OpenWeight pre-gate
          continuity [args…]   Continuity Non-Sovereignty due-timer (interval later)
          lite [status|check|path]  Afterstring 1/0 LITE OS (8.1.21)
          day|bod              Beginning-of-day snapshot + kpi.jsonl
          sabbath              Mark Sabbath airgap (CLI)
          contrail-rotate 1/0  Archive ledger + start fresh chain (Tier 2)
          type4                Type 4 track path hint
          version              Print version

        Mouth:
          Permit  = harness (gate.rb / grokbuild) — technical allow/deny
          Decision = Stay/Pause/Release (decision_state.rb / TUI /stay /release)
          Pocket   = public v9.1 five steps only (runtime/pocket.rb)

        Quick start:
          ./bin/afterstring doctor && ./bin/afterstring tui

        Docs: AFTERSTRING.md · AGENTS.md · constitution/
        State: local ~/.afterstring/ (convention, not a host map)
        Human Kernel holds 1/0. Firmware ≠ love.
        Let it stay → ∞ ❤️
      HELP
    end
  end
end
