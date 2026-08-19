# frozen_string_literal: true
# Continuity Non-Sovereignty real-time check — due-timer, not a daemon.
# Interval lives in ~/.afterstring/continuity_check.json and can be changed later.
# Future Agency: this file never schedules itself. Human invokes run / interval / arm.

require "json"
require "time"
require "fileutils"

module Afterstring
  class ContinuityCheck
    DEFAULT_INTERVAL_HOURS = 24.0
    STATE_NAME = "continuity_check.json"
    INVARIANT = "Stabilizing relational continuity without allowing continuity itself to become the objective."

    attr_reader :root, :state_path, :interval_hours, :last_run_at, :armed, :last_result

    def initialize(root:, state_dir: nil)
      @root = File.expand_path(root)
      dir = File.expand_path(state_dir || File.join(Dir.home, ".afterstring"))
      FileUtils.mkdir_p(dir)
      @state_path = File.join(dir, STATE_NAME)
      @interval_hours = DEFAULT_INTERVAL_HOURS
      @last_run_at = nil
      @armed = true
      @last_result = nil
      load!
    end

    def remaining_seconds
      return nil unless @armed && @last_run_at
      left = (@interval_hours * 3600) - (Time.now - @last_run_at)
      left.positive? ? left : 0
    end

    def due?
      return false unless @armed
      return true if @last_run_at.nil?
      remaining_seconds.to_f <= 0
    end

    def remaining_human
      return "DISARMED" unless @armed
      return "NEVER RUN" if @last_run_at.nil?
      s = remaining_seconds.to_i
      return "DUE NOW" if s <= 0
      h = s / 3600
      m = (s % 3600) / 60
      "#{h}h #{m}m remaining"
    end

    def set_interval!(hours)
      h = hours.to_f
      raise ArgumentError, "interval_hours must be > 0" unless h.positive?
      @interval_hours = h
      save!
      @interval_hours
    end

    def arm!
      @armed = true
      save!
    end

    def disarm!
      @armed = false
      save!
    end

    def run!
      probes = probe
      failed = probes.reject { |p| p[:ok] }
      @last_run_at = Time.now
      @last_result = failed.empty? ? "HOLD" : "FAIL"
      save!
      {
        "ok" => failed.empty?,
        "result" => @last_result,
        "invariant" => INVARIANT,
        "utc" => @last_run_at.utc.iso8601,
        "interval_hours" => @interval_hours,
        "armed" => @armed,
        "due_after" => remaining_human,
        "layer0" => false,
        "daemon" => false,
        "failed" => failed.map { |p| p[:id] },
        "probes" => probes
      }
    end

    def status
      {
        "ok" => true,
        "invariant" => INVARIANT,
        "interval_hours" => @interval_hours,
        "armed" => @armed,
        "due" => due?,
        "remaining" => remaining_human,
        "last_run_at" => @last_run_at && @last_run_at.utc.iso8601,
        "last_result" => @last_result,
        "state_path" => @state_path,
        "daemon" => false,
        "layer0" => false,
        "change_interval" => "afterstring continuity interval <hours>"
      }
    end

    def probe
      [
        probe_no_soul_files,
        probe_agents_anti_propagation,
        probe_layer0_twelve,
        probe_seat_unsigned,
        probe_silicon_notes,
        probe_residual_lock,
        probe_interval_sane
      ]
    end

    private

    def probe_no_soul_files
      hits = Dir.glob(File.join(@root, "**/{SOUL,MEMORY}.md"))
      hits.reject! { |p| p.include?("/.git/") }
      ok(hits.empty?, "no_soul_memory_files", hits.empty? ? "absent" : hits.join(","))
    end

    def probe_agents_anti_propagation
      path = File.join(@root, "AGENTS.md")
      text = File.file?(path) ? File.read(path) : ""
      ok(
        text.include?("self-propagating ideas") && text.include?("Not a 13th Kernel Invariant"),
        "agents_anti_propagation",
        "Operating Rule present, not a 13th invariant"
      )
    end

    def probe_layer0_twelve
      path = File.join(@root, "constitution/layer0.yaml")
      text = File.file?(path) ? File.read(path) : ""
      ids = text.scan(/^\s*- id:\s*(\d+)/).flatten
      ok(ids == %w[1 2 3 4 5 6 7 8 9 10 11 12], "layer0_still_12", "ids=#{ids.join(',')}")
    end

    def probe_seat_unsigned
      files = Dir.glob(File.join(@root, "council/sessions/**/04_human_1_0.md"))
      sealed = files.select { |p| File.read(p).match?(/- \[x\]/i) }
      ok(sealed.empty?, "seat_unsigned", sealed.empty? ? "templates only" : sealed.join(","))
    end

    def probe_silicon_notes
      path = File.join(@root, "papers/module-8.1.20-after-silicon.md")
      text = File.file?(path) ? File.read(path) : ""
      ok(
        text.include?("external signal") && text.include?("Continuity Non-Sovereignty"),
        "silicon_plugout_notes",
        "external signal + continuity notes present"
      )
    end

    def probe_residual_lock
      path = File.join(@root, "papers/research/mind-viruses-residual-2026-08-19.md")
      text = File.file?(path) ? File.read(path) : ""
      down = text.downcase
      ok(
        down.include?("opposite terminals") && down.include?("afterstring predicted mind viruses"),
        "residual_lock",
        "forbidden residuals still named"
      )
    end

    def probe_interval_sane
      ok(@interval_hours.positive? && @interval_hours <= 24 * 30, "interval_sane", "#{@interval_hours}h")
    end

    def ok(cond, id, detail)
      { id: id, ok: !!cond, detail: detail }
    end

    def load!
      return unless File.file?(@state_path)
      data = JSON.parse(File.read(@state_path))
      @interval_hours = data["interval_hours"].to_f if data["interval_hours"]
      @interval_hours = DEFAULT_INTERVAL_HOURS unless @interval_hours.positive?
      @last_run_at = Time.parse(data["last_run_at"]) if data["last_run_at"]
      @armed = data.key?("armed") ? !!data["armed"] : true
      @last_result = data["last_result"]
    rescue StandardError
      nil
    end

    def save!
      File.write(@state_path, JSON.pretty_generate(
        "interval_hours" => @interval_hours,
        "armed" => @armed,
        "last_run_at" => @last_run_at && @last_run_at.utc.iso8601,
        "last_result" => @last_result,
        "invariant" => INVARIANT,
        "daemon" => false,
        "note" => "Due-timer only. Change interval: afterstring continuity interval <hours>. Disarm: afterstring continuity disarm."
      ) + "\n")
    end
  end
end
