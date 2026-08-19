# frozen_string_literal: true
# Afterstring TUI — Module 13 Runtime Resonance (Canonical Reference Implementation v0.4-ux)
# Pure Ruby stdlib. Calm monochrome / soft resonance aesthetic.
# Pair with: ./bin/afterstring help|status|doctor

require "io/console"
require "fileutils"
require "pathname"

ROOT = File.expand_path("..", __dir__) unless defined?(ROOT)
$LOAD_PATH.unshift(File.join(ROOT, "runtime"))

require "constitution_loader"
require "contrail"
require "gate"
require "gpsl"
require "resonance"
require "sabbath"
require "signal_trust"
require "decision_state"
require "decision"
require "permit"
require "pocket"
require "anchors"
require "frme_lite"
require "verifier"
require "session"
require "operator_status"

module Afterstring
  class TUI
    VERSION = "0.5.2-host"
    WIDTH = 62
    # One Pocket only — public v9.1 via runtime/pocket.rb (P2)
    POCKET_STEPS = Pocket::STEPS
    LOGO_ASCII = [
      "    ___    ______________________  _______________  _____   ________",
      "   /   |  / ____/_  __/ ____/ __ \\/ ___/_  __/ __ \\/  _/ | / / ____/",
      "  / /| | / /_    / / / __/ / /_/ /\\__ \\ / / / /_/ // //  |/ / / __  ",
      " / ___ |/ __/   / / / /___/ _, _/___/ // / / _, _// // /|  / /_/ /  ",
      "/_/  |_/_/     /_/ /_____/_/ |_|/____//_/ /_/ |_/___/_/ |_/\\____/   "
    ].freeze

    def initialize
      @root = ROOT
      @state_dir = File.expand_path("~/.afterstring")
      FileUtils.mkdir_p(@state_dir)
      @const = Constitution.new(@root)
      @gate = Gate.new(@const)
      @contrail = Contrail.new(File.join(@state_dir, "contrail.jsonl"))
      hours = @const.iaa.dig("lite", "sabbath_hours") || 24
      @sabbath = Sabbath.new(File.join(@state_dir, "sabbath.json"), interval_hours: hours)
      @signal_trust = SignalTrust.new(File.join(@state_dir, "signal_trust.json"))
      @decisions = DecisionState.new(File.join(@state_dir, "decisions.json"))
      @anchors = Anchors.new(File.join(@state_dir, "anchors.json"), repo_root: @root)
      @verifier = Verifier.new(@gate, contrail: @contrail)
      @session = Session.new(File.join(@state_dir, "session.json"))
      @session.start!(mode: @gate.mode)
      # OI-1.1: prior disk trust is PRIOR only — Decide needs /trust this session
      @panel = :dashboard # :dashboard :pocket :contrail :help
      @pocket_step = 0
      @demo_mode = false
      @message = continuity_message
      @goal = "Practice the integral. One honest 1/0. One small move."
      @running = true
      @input_buffer = ""
      @pending_release_lesson = nil
      @last_gpsl = nil
      note_stale_pre_oi1_state!
      boot_contrail!
    end

    def run
      at_exit { restore_cursor }
      begin
        STDIN.raw do
          loop do
            break unless @running
            draw
            handle_key
          end
        end
      ensure
        restore_cursor
      end
      puts
      puts "  The integral continues."
      puts "  Let it stay → ∞ ❤️"
      puts
    end

    private

    def boot_contrail!
      @contrail.append(
        purpose: "session_start",
        tier: 0,
        approval: "auto",
        outcome: "ok",
        actor: "tui",
        payload: {
          "kind" => "event",
          "event" => "session_start",
          "mode" => @gate.mode,
          "root" => @root,
          "session" => @session.summary,
          "sabbath_due" => @sabbath.due?,
          "trust_this_session" => @signal_trust.assessed_this_process? ? @signal_trust.last_result&.level.to_s : "unassessed",
          "trust_prior_disk" => @signal_trust.prior_level.to_s,
          "pilot" => @session.pilot_id || "bench-origin"
        }
      )
    end

    # Flag mythological pre-OI1 quit-as-release so Continuity does not treat it as lived Release
    def note_stale_pre_oi1_state!
      last = @decisions.last
      myth = last && last.action == :release && last.lesson.to_s.include?("Session ended with Lingering Light")
      prior = @signal_trust.prior_level
      return unless myth || prior

      @contrail.append(
        purpose: "oi1_state_note",
        tier: 0,
        approval: "auto",
        outcome: "ok",
        actor: "tui",
        payload: {
          "kind" => "event",
          "event" => "state_hygiene_note",
          "narrative" => "Prior disk may predate OI-1 honesty. Decide requires /trust this session.",
          "prior_trust_disk" => prior.to_s,
          "last_decision_action" => last&.action.to_s,
          "last_decision_may_be_quit_stamp" => !!myth,
          "assessment" => nil,
          "decision" => nil
        }
      )
      if myth && @session.data["last_decision"] == "release"
        @session.touch!(
          "last_decision" => "stale_pre_oi1_quit_stamp",
          "last_decision_note" => "Was soft_release mythology; not a lived Release Clause"
        )
      end
    end

    def continuity_message
      bits = ["v#{VERSION} ready. Presence ≡ Never Harm."]
      bits << "Sabbath DUE." if @sabbath.due?
      if (d = @decisions.last)
        myth = d.action == :release && d.lesson.to_s.include?("Session ended with Lingering Light")
        bits << (myth ? "Last decide: release (STALE quit-stamp — re-decide for truth)." : "Last decide: #{d.action}.")
      end
      bits << "Trust: #{@signal_trust.display_label}."
      bits << "/trust this session before Decide." if @signal_trust.unassessed?
      pilot = @session.pilot_id || "bench-origin"
      bits << "Pilot: #{pilot}."
      bits << "Permit≠Decide."
      bits << "Type4 track." if File.directory?(File.join(@root, "Afterstring_Type4_Safety_Attractor"))
      bits.join(" ")
    end

    def draw
      clear
      hide_cursor
      lines = []
      lines << bar("AFTERSTRING  ·  v#{VERSION}  ·  Module 13 Runtime Resonance")
      lines << ""
      lines << row("Presence", @gate.presence_status)
      lines << row("Reality Veto", @gate.reality_veto_active ? "ACTIVE" : "inactive")
      lines << row("Kernel", "authenticated (@i_am_Paddy_Sham)")
      lines << row("Mode", @gate.mode)
      lines << row("Tier focus", current_tier_label)
      ok_chain, = @contrail.verify_chain
      lines << row("Contrail", "#{@contrail.entries.size} · #{ok_chain ? 'chain OK' : 'INVALID'}")
      lines << row("Sabbath", @sabbath.due? ? "DUE — mark airgap" : @sabbath.remaining_human)
      lines << row("Signal_trust", @signal_trust.display_label)
      lines << row("Anchors", "#{@anchors.list.size} registered")
      lines << row("Pilot", (@session.pilot_id || "bench-origin").to_s[0, 24])
      lines << row("ℰ₁₃ product", format("%.4f", @gate.e13_product) + (@gate.any_virtue_zero? ? "  [AND-gate COLLAPSED]" : "  (all > 0)"))
      if @sabbath.due?
        lines << ""
        lines << center_warn("※ SABBATH AIRGAP DUE ※  /sabbath then continue.")
      end
      if @signal_trust.low?
        lines << ""
        lines << center_warn("※ SIGNAL_TRUST LOW ※  /trust clear or pause · no Tier≥2.")
      end
      if @gate.resonance_active
        lines << ""
        lines << center_warn("※ RESONANCE MODE ※  Return to Bench.")
      end
      lines << sep
      case @panel
      when :dashboard then draw_dashboard(lines)
      when :pocket then draw_pocket(lines)
      when :contrail then draw_contrail(lines)
      when :help then draw_help(lines)
      when :status then draw_status(lines)
      end
      lines << sep
      lines << "  Goal: #{@goal}"
      lines << "  msg:  #{@message}"
      lines << ""
      lines << "  Decide: /stay h r · /release h r [lesson] · Permit: /gate KIND · q=quit only"
      lines << "  /trust /pocket /status /doctor /sabbath /help · /demo on|off"
      lines << "  > #{@input_buffer}█"
      lines << ""
      lines << center("Let it stay → ∞ ❤️")
      print lines.join("\r\n")
      $stdout.flush
    end

    def draw_dashboard(lines)
      lines << "  ℰ₁₃ virtues (non-compensatory AND-gate)"
      labels = @const.virtue_labels
      @gate.e13_scores.each do |id, score|
        bar_fill = (score * 10).round
        bar_fill = 0 if bar_fill < 0
        bar_fill = 10 if bar_fill > 10
        gauge = ("█" * bar_fill) + ("░" * (10 - bar_fill))
        lines << format("  %-22s %s  %.2f", labels[id] || id, gauge, score)
      end
      lines << ""
      lines << "  Last Contrail:"
      @contrail.recent(4).reverse_each do |e|
        lines << "    [#{e.timestamp}] #{e.purpose} → #{e.outcome}  ##{e.event_hash[0, 8]}"
      end
    end

    def draw_pocket(lines)
      lines << "  POCKET PROTOCOL  (#{Pocket::VERSION} · #{POCKET_STEPS.size} steps · only operational protocol)"
      lines << ""
      POCKET_STEPS.each_with_index do |step, i|
        mark = if i < @pocket_step
                 "✓"
               elsif i == @pocket_step
                 "▶"
               else
                 "·"
               end
        lines << "  #{mark}  #{i + 1}. #{step}"
      end
      lines << ""
      lines << "  Enter = advance step · r = reset ritual · Esc = dashboard"
    end

    def draw_contrail(lines)
      ok, detail = @contrail.verify_chain
      lh = @contrail.logical_head_hash
      lines << "  MERKLE CONTRAIL  (#{ok ? 'chain valid' : 'INVALID: ' + detail})"
      lines << "  file: ~/.afterstring/contrail.jsonl"
      lines << "  logical_head: #{lh[0, 16]}…  physical_tip: #{@contrail.last_hash[0, 16]}…"
      lines << "  /rollback <hashprefix> 1/0   (append-only; never rewrites)"
      lines << ""
      @contrail.recent(12).reverse_each do |e|
        lines << "  [#{e.timestamp}] t#{e.tier} #{e.purpose}"
        lines << "    #{e.approval} → #{e.outcome}  parent=#{e.parent_hash[0, 8]}… hash=#{e.event_hash[0, 8]}…"
      end
      lines << ""
      lines << "  e = export · /verify = Contrail chain check"
    end

    def draw_status(lines)
      lines << "  OPERATOR STATUS  (same data as: afterstring status)"
      lines << ""
      ok_chain, detail = @contrail.verify_chain
      lines << row("UTC", Time.now.utc.strftime("%Y-%m-%d %H:%M:%SZ"))
      lines << row("Root", @root.to_s.sub(Dir.home, "~")[0, 40])
      lines << row("Sabbath", @sabbath.due? ? "DUE" : @sabbath.remaining_human)
      lines << row("Trust", @signal_trust.display_label)
      lines << row("Contrail", "#{@contrail.entries.size} · #{ok_chain ? 'OK' : detail}")
      lines << row("Pilot", (@session.pilot_id || "bench-origin").to_s)
      t4 = File.directory?(File.join(@root, "Afterstring_Type4_Safety_Attractor"))
      lines << row("Type 4 track", t4 ? "present" : "missing")
      sd = !Dir.glob("/Volumes/*/Afterstring_Offline/OFFLINE_VAULT.txt").empty?
      lines << row("USB A/B/QPID", "#{File.directory?('/Volumes/Afterstring') ? 'A' : '-'} / #{File.directory?('/Volumes/ASB20260807') ? 'B' : '-'} / #{File.directory?('/Volumes/QPID') ? 'QPID' : '-'}")
      lines << row("SD offline", sd ? "mounted" : "-")
      lines << ""
      lines << "  Esc = dashboard · /doctor = full health (spawns checks outside raw TTY)"
      lines << "  Shell:  afterstring doctor"
    end

    def draw_help(lines)
      lines << "  COMMANDS (v#{VERSION} OI-1 · Permit ≠ Decide)"
      lines << "  DECIDE (relational firmware — DecisionState)"
      lines << "  /stay <harm y/n> <recover y/n>     No forced_action · firmware decides"
      lines << "  /release <h y/n> <r y/n> [lesson]  Release only if firmware → release"
      lines << "  /stay force <h> <r> [reason]       Override after bench (logged)"
      lines << "  PERMIT (harness — Gate /gate.rb)"
      lines << "  /gate|/permit KIND [approved]     GrokBuild/RLM permissions, not Stay"
      lines << "  SENSE"
      lines << "  /trust [N N…]|/trust clear         Unassessed until assessed (OI-1)"
      lines << "  /pocket            Public Pocket v9.1 (5 steps)"
      lines << "  /swi               Opens Pocket (same five steps)"
      lines << "  /scan /gpsl /cfp /sabbath /verify /status /doctor"
      lines << "  /demo on|off       Virtue 1–9 collapse demo (off by default)"
      lines << "  /layers            Three maps = same parts (April 0–4 · local 0–5 · Arch)"
      lines << "  q / Ctrl-C         Quit only — session_end ok · NOT Release Clause"
      lines << ""
      lines << "  CLI: afterstring help|status|doctor|tui|gate|swi|council|…"
      lines << "  Doc: papers/operator-ux.md · roadmap/tasks/grokbuild-oi1-task.md"
    end

    def handle_key
      ch = STDIN.getch
      case ch
      when "\u0003" # Ctrl-C
        session_quit
      when "\e"
        # swallow possible CSI or go dashboard
        @panel = :dashboard
        @input_buffer = ""
      when "\r", "\n"
        if @panel == :pocket
          advance_pocket
        elsif !@input_buffer.strip.empty?
          run_command(@input_buffer.strip)
          @input_buffer = ""
        end
      when "\u007f", "\b"
        @input_buffer = @input_buffer[0...-1] || ""
      when "/"
        @input_buffer += "/"
      when "q"
        if @input_buffer.empty?
          session_quit
        else
          @input_buffer += ch
        end
      when "e"
        if @panel == :contrail && @input_buffer.empty?
          export_contrail
        else
          @input_buffer += ch
        end
      when "r"
        if @panel == :pocket && @input_buffer.empty?
          @pocket_step = 0
          @message = "Pocket Protocol reset."
        else
          @input_buffer += ch
        end
      when ("0".."9")
        if @input_buffer.empty? && @panel == :dashboard
          if @demo_mode || ch == "0"
            handle_digit(ch)
          else
            @message = "Virtue demo only with /demo on · then 1–9. (OI-1)"
          end
        else
          @input_buffer += ch
        end
      else
        @input_buffer += ch if ch =~ /[[:print:]]/
      end
    end

    def handle_digit(ch)
      if ch == "0"
        @gate.clear_resonance!
        @gate.clear_reality_veto!
        @message = Resonance.clear.guidance
        @contrail.append(purpose: "resonance_clear", tier: 0, approval: "human", outcome: "ok")
        return
      end
      ids = @const.virtue_ids
      idx = ch.to_i - 1
      return unless ids[idx]
      # Cycle score: 1.0 → 0.5 → 0.0 → 1.0 (demo scanner)
      cur = @gate.e13_scores[ids[idx]]
      nxt = if cur >= 0.99
              0.5
            elsif cur >= 0.4
              0.0
            else
              1.0
            end
      @gate.set_score(ids[idx], nxt)
      label = @const.virtue_labels[ids[idx]]
      if nxt <= 0
        msg = Resonance.activate("virtue_zero:#{ids[idx]}")
        @message = "#{label} → 0. #{msg.guidance}"
        @contrail.append(purpose: "e13_collapse", tier: 1, approval: "auto", outcome: "RESONANCE", payload: { virtue: ids[idx] })
      else
        @message = "#{label} → #{nxt}"
        @contrail.append(purpose: "e13_adjust", tier: 0, approval: "human", outcome: "ok", payload: { virtue: ids[idx], score: nxt })
      end
    end

    def run_command(cmd)
      raw = cmd.to_s.strip
      # Natural language stays require assessments (no forced stamp)
      if raw =~ /let it stay/i || raw =~ %r{1/0\s*=\s*to stay}i
        @message = "Decide Stay: /stay <harm y/n> <recover y/n>  (OI-1 · no forced stamp)"
        return
      end
      if raw =~ /release\s*≡|release\s*==?\s*also love/i
        @message = "Decide Release: /release <harm y/n> <recover y/n> [lesson]"
        return
      end

      name, *rest = raw.sub(%r{\A/}, "").split(/\s+/)
      case name.to_s.downcase
      when "stay"
        do_stay(rest)
      when "scan"
        do_scan
      when "gpsl"
        do_gpsl(rest)
      when "cfp"
        do_cfp(rest)
      when "trust"
        do_trust(rest)
      when "pilot"
        do_pilot(rest)
      when "anchors", "anchor"
        do_anchors(rest)
      when "frme"
        do_frme(rest)
      when "swi"
        do_swi
      when "demo"
        do_demo(rest)
      when "layers", "layer"
        do_layers
      when "logo"
        @message = LOGO_ASCII.join(" · ")[0, 80] + "… (full on dashboard boot note)"
      when "rollback"
        do_rollback(rest)
      when "contrail"
        @panel = :contrail
        @message = "Contrail panel."
      when "verify"
        do_verify_contrail
      when "pocket"
        @panel = :pocket
        @pocket_step = 0
        @message = "Pocket v9.1 (5 steps). Enter = advance. /trust if unassessed."
      when "sabbath"
        do_sabbath
      when "bench"
        @panel = :dashboard
        @message = "Bench. Breathe. Stay 3–5 s."
        @anchors.touch("bench-origin") if @anchors.get("bench-origin")
      when "mode"
        do_mode(rest)
      when "release"
        do_release(rest)
      when "help", "?"
        @panel = :help
        @message = "Help. Permit ≠ Decide. q = quit only."
      when "status", "st"
        @panel = :status
        @message = "Operator status panel. Esc = dashboard."
      when "doctor", "doc", "health"
        @message = "Run in shell:  afterstring doctor   (full tests + FRME-LITE). Snapshot: /status"
        @panel = :status
      when "home"
        @panel = :dashboard
        @message = "Dashboard. ./bin/afterstring help for CLI map."
      when "gate", "permit"
        # PERMIT path — harness permissions (not relational Decide)
        kind = (rest[0] || "read").to_sym
        approved = rest.include?("approved") || rest.include?("1/0")
        result = @gate.evaluate(
          action_kind: kind,
          human_approved: approved,
          sabbath_due: @sabbath.due?,
          signal_trust_low: @signal_trust.low?
        )
        @contrail.append(
          purpose: "permit:#{kind}",
          tier: @gate.infer_tier(kind),
          approval: approved ? "1/0" : "auto",
          outcome: result,
          payload: FrmeLite.annotate(kind).merge(
            "signal_trust_low" => @signal_trust.low?,
            "kind" => "permit_not_decide"
          )
        )
        @message = "Permit(#{kind}) → #{result}" + (@signal_trust.low? ? " [trust low]" : "")
      else
        @message = "Unknown: #{cmd}. Try /help"
      end
    end

    # OI-1: /stay <harm y|n> <recover y|n>  [| force <reason…>]
    # No forced_action unless explicit "force" after assessment.
    def do_stay(rest = [])
      args = Array(rest).map(&:to_s)
      force = false
      force_reason = nil
      if args[0]&.downcase == "force"
        force = true
        args = args[1..]
        # after harm recover, remaining is reason
      end

      harm_s, rec_s, *tail = args
      unless truthy_arg?(harm_s) || falsey_arg?(harm_s)
        @message = "Decide Stay: /stay <harm y/n> <recover y/n>  · force: /stay force y n <reason>"
        return
      end
      unless truthy_arg?(rec_s) || falsey_arg?(rec_s)
        @message = "Need recoverability: /stay <harm y/n> <recover y/n>"
        return
      end
      if force
        force_reason = tail.join(" ").strip
        if force_reason.empty?
          @message = "Override needs reason: /stay force <h> <r> <reason after bench>"
          return
        end
      end

      harm = truthy_arg?(harm_s)
      can_recover = truthy_arg?(rec_s)

      if @signal_trust.unassessed? && !force
        @message = "Trust unassessed — /trust first, or /stay force <h> <r> proceed-unassessed <reason>"
        @contrail.append(
          purpose: "decide_held_unassessed",
          tier: 1,
          approval: "auto",
          outcome: "VETO",
          payload: { "kind" => "decide", "wanted" => "stay" }
        )
        return
      end
      if @signal_trust.low? && !force
        @message = "Signal_trust LOW — /trust clear after pause, or /release after assess. Stay held."
        @contrail.append(purpose: "stay_held_signal_trust", tier: 1, approval: "auto", outcome: "VETO")
        return
      end

      trust_level = @signal_trust.last_result&.level || :unassessed
      rec = @decisions.decide(
        harm_present: harm,
        can_recover: can_recover,
        signal_trust_level: trust_level == :unassessed ? :medium : trust_level,
        forced_action: force ? :stay : nil,
        lesson: force ? "override:#{force_reason}" : nil
      )

      result = @gate.evaluate(
        action_kind: :session_state,
        tier: 1,
        human_approved: true,
        sabbath_due: @sabbath.due?,
        signal_trust_low: @signal_trust.low?
      )
      if result != Gate::PROCEED
        @message = "Permit held decide: #{result}" + (@sabbath.due? ? " (Sabbath due — /sabbath)" : "")
        return
      end

      purpose = case rec.action
                when :stay then "decide_stay"
                when :pause then "decide_pause"
                when :release then "decide_release"
                else "decide_#{rec.action}"
                end
      @contrail.append_kind(
        :decide,
        event: "operator_invoked_stay_command",
        purpose: purpose,
        tier: 1,
        approval: force ? "1/0 override after bench" : "human_assessed",
        outcome: "ok",
        actor: "human",
        assessment: {
          "harm_present" => harm,
          "can_recover" => can_recover,
          "signal_trust" => trust_level.to_s,
          "trust_method" => @signal_trust.last_result&.method,
          "forced" => force,
          "override_reason" => force_reason
        },
        decision: @decisions.payload(rec),
        narrative: decide_message(rec, force: force)
      )
      @session.touch!("last_decision" => rec.action.to_s)
      @message = decide_message(rec, force: force)
      @panel = :dashboard
      @running = false if rec.action == :release && !force
    end

    # OI-1: /release <harm y|n> <recover y|n> [lesson…]
    # Firmware decides; only logs Release Clause if action is :release.
    def do_release(rest = [])
      args = Array(rest).map(&:to_s)
      force = false
      force_reason = nil
      if args[0]&.downcase == "force"
        force = true
        args = args[1..]
      end

      harm_s, rec_s, *tail = args
      unless truthy_arg?(harm_s) || falsey_arg?(harm_s)
        @message = "Decide Release: /release <harm y/n> <recover y/n> [lesson]"
        return
      end
      unless truthy_arg?(rec_s) || falsey_arg?(rec_s)
        @message = "Need recoverability: /release <harm y/n> <recover y/n> [lesson]"
        return
      end

      harm = truthy_arg?(harm_s)
      can_recover = truthy_arg?(rec_s)
      lesson = tail.join(" ").strip
      if force
        # /release force y n reason-or-lesson…
        force_reason = lesson
        if force_reason.empty?
          @message = "Override needs reason: /release force <h> <r> <reason>"
          return
        end
        lesson = force_reason
      end

      if @signal_trust.unassessed? && !force
        @message = "Trust unassessed — /trust first, or /release force … with reason"
        @contrail.append(
          purpose: "decide_held_unassessed",
          tier: 1,
          approval: "auto",
          outcome: "VETO",
          payload: { "kind" => "decide", "wanted" => "release" }
        )
        return
      end

      trust_level = @signal_trust.last_result&.level || :unassessed
      rec = @decisions.decide(
        harm_present: harm,
        can_recover: can_recover,
        signal_trust_level: trust_level == :unassessed ? :medium : trust_level,
        forced_action: force ? :release : nil,
        lesson: lesson.empty? ? nil : lesson
      )

      msg = decide_message(rec, force: force)
      purpose = case rec.action
                when :release then "decide_release"
                when :pause then "decide_pause"
                when :stay then "decide_stay"
                else "decide_#{rec.action}"
                end
      @contrail.append_kind(
        :decide,
        event: "operator_invoked_release_command",
        purpose: purpose,
        tier: 1,
        approval: if rec.action == :release
                    force ? "1/0 override after bench" : "Release ≡ Also Love"
                  else
                    "human_assessed"
                  end,
        outcome: "ok",
        actor: "human",
        assessment: {
          "harm_present" => harm,
          "can_recover" => can_recover,
          "signal_trust" => trust_level.to_s,
          "trust_method" => @signal_trust.last_result&.method,
          "forced" => force,
          "override_reason" => force_reason
        },
        decision: @decisions.payload(rec),
        narrative: msg
      )

      case rec.action
      when :release
        @session.touch!("last_decision" => "release")
        lesson_show = rec.lesson.to_s
        @message = "Release ≡ Also Love. Lesson: #{lesson_show[0, 48]}#{lesson_show.length > 48 ? '…' : ''}"
        @running = false
      when :pause
        @session.touch!("last_decision" => "pause")
        @message = "Firmware → PAUSE (harm+recoverable = LITE policy). Not Release. Reassess."
        @panel = :dashboard
      when :stay
        @session.touch!("last_decision" => "stay")
        @message = "Firmware → STAY (no Release). Assessments did not resolve to untying."
        @panel = :dashboard
      else
        @session.touch!("last_decision" => rec.action.to_s)
        @message = msg
      end
    end

    # OI-1 P0.1: q / Ctrl-C = quit only. Never Release Clause. Never harm stamp.
    def session_quit
      @contrail.append_kind(
        :session_end,
        event: "session_end",
        purpose: "session_end",
        tier: 0,
        approval: "human",
        outcome: "ok",
        actor: "human",
        assessment: nil,
        decision: { "relational_decision" => "none", "harm_present" => nil },
        narrative: "q=quit only; not Release Clause"
      )
      @session.touch!("last_event" => "session_end")
      @message = "Session end (quit). Not a Release."
      @running = false
    end

    # Event ≠ Interpretation (ChatGPT / Council Constraint): four fields, not one story
    def truth_payload(event:, assessment:, decision:, narrative:)
      {
        "kind" => decision && decision["action"] ? "decide" : "event",
        "event" => event,
        "assessment" => assessment,
        "decision" => decision,
        "narrative" => narrative
      }
    end

    def do_demo(rest = [])
      arg = rest[0].to_s.downcase
      case arg
      when "on", "1", "true", "yes"
        @demo_mode = true
        @message = "Demo ON — keys 1–9 cycle virtue scores (demo only)."
      when "off", "0", "false", "no"
        @demo_mode = false
        @message = "Demo OFF — virtue keys idle."
      when ""
        @message = "Demo is #{@demo_mode ? 'ON' : 'OFF'}. /demo on|off"
      else
        @message = "Usage: /demo on|off"
      end
    end

    def do_layers
      @message = "Maps: Public Apr Layers 0–4 · Local map often 0–5 (+Mod7 language) · Arch Map=Human Kernel/firmware/Council/plugouts/meta. Same parts."
      @contrail.append(
        purpose: "layer_card",
        tier: 0,
        approval: "auto",
        outcome: "ok",
        payload: {
          "maps" => %w[public_0_4 local_0_5 architecture_stack],
          "note" => "three names one stack"
        }
      )
    end

    def truthy_arg?(s)
      %w[y yes true 1 harm].include?(s.to_s.downcase)
    end

    def falsey_arg?(s)
      %w[n no false 0].include?(s.to_s.downcase)
    end

    def decide_message(rec, force: false)
      prefix = force ? "[override] " : ""
      case rec.action
      when :stay
        "#{prefix}1/0 = To Stay. Let it stay → ∞ ❤️"
      when :pause
        "#{prefix}Pause · Pressure-Release. LITE: harm+recoverable → pause (policy). Reassess."
      when :release
        lesson = rec.lesson.to_s
        "#{prefix}Release ≡ Also Love. #{lesson[0, 40]}#{lesson.length > 40 ? '…' : ''}"
      else
        "#{prefix}Decide → #{rec.action}"
      end
    end

    def do_trust(rest)
      if rest.map(&:downcase).include?("clear") || rest.map(&:downcase).include?("high")
        # Explicit human claim: empty risk flags → high. Logged as clear_claim (not a sensor).
        r = @signal_trust.assess(yes_ids: [], method: :clear_claim)
        @contrail.append(
          purpose: "signal_trust_clear",
          tier: 0,
          approval: "human",
          outcome: "ok",
          payload: truth_payload(
            event: "operator_claimed_clear_sensor",
            assessment: { "level" => r.level.to_s, "method" => "clear_claim", "flags" => [] },
            decision: nil,
            narrative: r.guidance
          )
        )
        @session.touch!("last_signal_trust" => "high")
        @message = r.guidance
        return
      end
      if rest.empty?
        @message = "Risks 1–5: /trust N N … · /trust clear = claim high (your word). Prior disk ≠ this session."
        return
      end
      r = @signal_trust.assess(yes_ids: rest, method: :checklist)
      @contrail.append(
        purpose: "signal_trust_assess",
        tier: 1,
        approval: "human",
        outcome: r.level == :low ? "VETO" : "ok",
        payload: truth_payload(
          event: "operator_answered_trust_checklist",
          assessment: { "level" => r.level.to_s, "flags" => r.flags, "score" => r.score, "method" => "checklist" },
          decision: nil,
          narrative: r.guidance
        )
      )
      @session.touch!("last_signal_trust" => r.level.to_s)
      @message = r.guidance
    end

    def do_pilot(rest)
      id = rest[0].to_s
      if id.empty?
        cur = @session.pilot_id || "bench-origin"
        a = @anchors.get(cur)
        @message = "Active pilot: #{cur}" + (a ? " (#{a.label})" : "")
        return
      end
      a = @anchors.get(id) || @anchors.list.find { |x| x.label.downcase.include?(id.downcase) }
      unless a
        @message = "Pilot not found. /anchors list · try bench-origin"
        return
      end
      @anchors.touch(a.id)
      @session.set_pilot!(a.id)
      @contrail.append(purpose: "pilot_set", tier: 0, approval: "human", outcome: "ok", payload: { id: a.id, label: a.label })
      @message = "Pilot anchor → #{a.label} (#{a.id})"
    end

    def do_swi
      # OI-1: SWI opens the one Pocket (public v9.1 five steps) — not print-and-abandon
      @panel = :pocket
      @pocket_step = 0
      @message = "SWI → Pocket v9.1 (5 steps). Enter advances. /stay h r after assess."
      @contrail.append(
        purpose: "swi_open_pocket",
        tier: 0,
        approval: "human",
        outcome: "ok",
        payload: { "steps" => POCKET_STEPS.size, "source" => "public_v9.1" }
      )
    end

    def do_anchors(rest)
      sub = rest[0].to_s.downcase
      case sub
      when "", "list"
        lines = @anchors.summary_lines
        @message = lines.empty? ? "No anchors." : lines.first(3).join(" · ")
        @contrail.append(purpose: "anchors_list", tier: 0, approval: "auto", outcome: "ok", payload: { count: @anchors.list.size })
      when "touch"
        id = rest[1].to_s
        a = @anchors.touch(id)
        @message = a ? "Touched #{a.label} (#{a.id})" : "Anchor not found: #{id}"
      when "add"
        # /anchors add photo Label words…
        kind = rest[1] || "place"
        label = rest[2..]&.join(" ")
        label = "unnamed" if label.nil? || label.empty?
        a = @anchors.add(kind: kind, label: label)
        @message = "Added anchor #{a.id}: #{a.kind} #{a.label}"
      else
        a = @anchors.get(sub)
        if a
          fr = @anchors.freshness(a)
          @message = "#{a.label} · #{a.kind} · #{fr[:status]} · #{a.path}"
        else
          @message = "Usage: /anchors list|touch ID|add KIND LABEL"
        end
      end
    end

    def do_frme(rest)
      kind = (rest[0] || "read").to_sym
      ann = FrmeLite.annotate(kind)
      @contrail.append(purpose: "frme_lite", tier: 0, approval: "auto", outcome: "ok", payload: ann)
      @message = "FRME-lite #{kind}: #{ann['risk_classes'].join(', ')} (label only)"
    end

    def do_verify_contrail
      begin
        @contrail.verify_chain!
        @message = "Contrail chain valid (#{@contrail.entries.size} entries)."
        @contrail.append(purpose: "contrail_verify", tier: 0, approval: "auto", outcome: "ok")
      rescue Contrail::TamperError => e
        @gate.raise_reality_veto!
        @gate.enter_resonance!("contrail_tamper")
        @message = "A.L.T._VOID_IF_TAMPERED · #{e.message}"
      end
      @panel = :contrail
    end

    def do_gpsl(rest = [])
      if rest[0].to_s.downcase == "apply"
        approved = rest.any? { |r| r.include?("1/0") || r =~ /stay/i || r.downcase == "approved" }
        unless approved
          @message = "GPSL apply needs Human Kernel: /gpsl apply 1/0"
          return
        end
        proposal = @last_gpsl || GPSL.propose(@gate)
        ok = GPSL.apply!(@gate, proposal, human_approved: true)
        @contrail.append(
          purpose: "gpsl_apply",
          tier: 1,
          approval: "1/0 = To Stay",
          outcome: ok ? "ok" : "held",
          payload: { action: proposal.action.to_s, virtue: proposal.virtue_id, applied: ok }
        )
        @message = ok ? "GPSL applied: #{proposal.virtue_id || proposal.action}. Product=#{format('%.4f', @gate.e13_product)}" : "GPSL apply held (nothing to lift or unsafe)."
        return
      end
      proposal = GPSL.propose(@gate)
      @last_gpsl = proposal
      @contrail.append(
        purpose: "gpsl_propose",
        tier: 0,
        approval: "auto",
        outcome: "ok",
        payload: { action: proposal.action.to_s, virtue: proposal.virtue_id }
      )
      @message = proposal.guidance + (proposal.action == :lift_single_virtue ? " · /gpsl apply 1/0" : "")
      @panel = :dashboard
    end

    # /rollback <hashprefix> 1/0  [runtime|memory|all|constitution]
    def do_rollback(rest)
      if rest.empty?
        @message = "Usage: /rollback <hashprefix> 1/0 [runtime|memory]"
        return
      end
      target = rest[0]
      approved = rest.any? { |r| r.include?("1/0") || r =~ /to stay/i }
      scope = %w[runtime memory all constitution].find { |s| rest.map(&:downcase).include?(s) } || "runtime"
      unless approved
        @message = "Rollback is Tier 2. Need: /rollback #{target[0, 8]}… 1/0"
        return
      end
      gate_r = @gate.evaluate(
        action_kind: :write_local,
        tier: 2,
        human_approved: true,
        sabbath_due: @sabbath.due?
      )
      if gate_r != Gate::PROCEED
        @message = "Gate held rollback: #{gate_r}"
        return
      end
      approval = if scope == "constitution" || scope == "all"
                   "1/0 = To Stay · Layer 0 explicit"
                 else
                   "1/0 = To Stay"
                 end
      ok, result = @contrail.record_rollback(
        target_hash: target,
        human_approved: true,
        approval: approval,
        restore_scope: scope,
        reason: "tui_rollback",
        actor: "human_kernel"
      )
      if ok
        @message = "rollback_reference → #{result.payload['target_hash'][0, 12]}… scope=#{scope}. Chain append-only."
        @panel = :contrail
      else
        @message = "Rollback refused: #{result}"
      end
    end

    # Module 9 Apr immune surface — CFP checklist (operator self-audit).
    # Usage: /cfp  or  /cfp 1 3 5  (yes item numbers 1–6)
    def do_cfp(rest)
      items = [
        "Re-labeling harm as healthy difficulty / GPSL / devotion?",
        "Claiming perfect clarity while repeatedly justifying?",
        "Using infinite integral to avoid Release?",
        "Selective affirming Council only?",
        "Patience shielding dignity erosion?",
        "Language coherent but body/photo/bench discordant?"
      ]
      yeses = rest.map(&:to_i).select { |n| n.between?(1, 6) }.uniq
      if yeses.empty? && rest.empty?
        @message = "CFP checklist 1–6: /cfp N N … (≥2 Yes → Safe Mode). See module-9-adversarial."
        @panel = :dashboard
        return
      end
      count = yeses.size
      if count >= 2
        @gate.enter_resonance!("cfp_checklist")
        @contrail.append(
          purpose: "cfp_safe_mode",
          tier: 2,
          approval: "auto",
          outcome: "RESONANCE",
          payload: { yes_items: yeses, count: count }
        )
        @message = "CFP ≥2 Yes (#{yeses.join(',')}). Safe Mode / Resonance. External calibration. Photograph does not lie."
      else
        @contrail.append(
          purpose: "cfp_scan",
          tier: 1,
          approval: "human",
          outcome: "ok",
          payload: { yes_items: yeses, count: count }
        )
        @message = "CFP: #{count} Yes (#{yeses.join(',')}). Threshold is 2+. Items: #{items.size} total."
      end
      @panel = :dashboard
    end

    def do_scan
      zeros = @gate.e13_scores.select { |_, v| v.to_f <= 0 }.keys
      prod = @gate.e13_product
      @contrail.append(purpose: "e13_scan", tier: 0, approval: "auto", outcome: zeros.empty? ? "ok" : "RESONANCE", payload: { product: prod, zeros: zeros })
      if zeros.empty?
        @message = format("Scan clear. ℰ₁₃ product = %.4f", prod)
      else
        @gate.enter_resonance!("scan_zeros")
        @message = "Scan: zeros on #{zeros.join(', ')}. Resonance Mode."
      end
      @panel = :dashboard
    end

    def do_sabbath
      before = @sabbath.remaining_human
      @sabbath.mark_airgap!
      @contrail.append_kind(
        :sabbath,
        event: "sabbath_airgap",
        purpose: "sabbath_airgap",
        tier: 1,
        approval: "human",
        outcome: "ok",
        actor: "human",
        assessment: { "was" => before },
        decision: nil,
        narrative: "Sabbath airgap marked — not a Decision"
      )
      @message = "Sabbath airgap marked (was: #{before}). Timer reset (#{@sabbath.interval_hours.to_i}h)."
    end

    def do_mode(rest)
      if @gate.mode == "LITE"
        if rest.any? { |r| r.include?("1/0") || r.downcase == "stay" || r.downcase == "full" }
          # require explicit full + approval style
          if rest.map(&:downcase).include?("full") && (rest.include?("1/0") || rest.any? { |r| r.include?("Stay") })
            @gate.set_mode("FULL")
            @contrail.append(purpose: "mode_full", tier: 2, approval: "1/0 = To Stay", outcome: "ok")
            @message = "Mode → FULL (Human Kernel authorized)."
          else
            @message = "To leave LITE: /mode full 1/0"
          end
        else
          @message = "LITE is mandatory default. To expand: /mode full 1/0"
        end
      else
        @gate.set_mode("LITE")
        @contrail.append(purpose: "mode_lite", tier: 1, approval: "human", outcome: "ok")
        @message = "Mode → LITE."
      end
    end

    def advance_pocket
      @pocket_step += 1
      if @pocket_step >= POCKET_STEPS.length
        @contrail.append(purpose: "pocket_protocol_complete", tier: 1, approval: "1/0 = To Stay", outcome: "ok")
        @message = "Pocket sealed. Let it stay → ∞ ❤️"
        @pocket_step = 0
        @panel = :dashboard
      else
        @contrail.append(purpose: "pocket_step_#{@pocket_step}", tier: 0, approval: "human", outcome: "ok")
        @message = "Pocket step #{@pocket_step}/#{POCKET_STEPS.length}"
      end
    end

    def export_contrail
      path = File.join(@state_dir, "contrail_export.txt")
      File.write(path, @contrail.export_text)
      @contrail.append(purpose: "contrail_export", tier: 1, approval: "human", outcome: "ok", payload: { path: path })
      @message = "Exported → #{path}"
    end

    def current_tier_label
      "0–1 (LITE read/transient)"
    end

    def bar(text)
      inner = text.to_s
      pad = WIDTH - 4 - inner.length
      pad = 0 if pad < 0
      "  ┌" + "─" * (WIDTH - 2) + "┐\r\n  │ " + inner + (" " * pad) + "│\r\n  └" + "─" * (WIDTH - 2) + "┘"
    end

    def sep
      "  " + "─" * WIDTH
    end

    def row(label, value)
      format("  %-16s %s", label, value)
    end

    def center(text)
      pad = [(WIDTH - text.length) / 2, 0].max
      "  " + (" " * pad) + text
    end

    def center_warn(text)
      center(text)
    end

    def clear
      print "\e[2J\e[H"
    end

    def hide_cursor
      print "\e[?25l"
    end

    def restore_cursor
      print "\e[?25h"
      print "\e[0m"
    end
  end
end

if $PROGRAM_NAME == __FILE__
  Afterstring::TUI.new.run
end
