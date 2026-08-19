# frozen_string_literal: true
# Signal_trust — pre-gate integrity of the human "sensor" (Module 4.1 / firmware Zero-Gate).
# Low trust forces pause before Stay/Release/side-effect decisions.
# Pure Ruby. Human Kernel answers; never auto-fabricates clarity.
#
# OI-1.1: assessment is session-scoped for Decide.
# A prior high on disk (from old boot seed or yesterday) is PRIOR, not live clearance.
# unassessed? until assess() runs in this process.

require "json"
require "fileutils"
require "time"

module Afterstring
  class SignalTrust
    HEURISTICS = [
      { id: :exhaustion, prompt: "Exhaustion / sleep debt high enough to distort judgment?" },
      { id: :emotion, prompt: "High emotional activation (flood, panic, rage) right now?" },
      { id: :trauma, prompt: "Old wound / trauma reactivity driving the read?" },
      { id: :certainty, prompt: "Feeling certain-but-exhausted (false clarity)?" },
      { id: :isolation, prompt: "No outside perspective available and stuck looping?" }
    ].freeze

    Result = Struct.new(:level, :score, :flags, :guidance, :ok_to_decide, :method, :assessed_at, keyword_init: true)

    attr_reader :path, :last_result, :prior_result

    def initialize(path)
      @path = File.expand_path(path)
      @last_result = nil
      @prior_result = nil
      @assessed_this_process = false
      load!
    end

    # yes_ids: array of heuristic ids or 1-based indices that are "yes" (risk present)
    # method: :checklist | :clear_claim (empty flags = high is a human claim, not a sensor)
    def assess(yes_ids: [], method: :checklist)
      flags = normalize_yes(yes_ids)
      # Start high; each risk flag lowers trust
      score = 1.0 - (flags.size * 0.2)
      score = 0.0 if score < 0
      score = 1.0 if score > 1

      level = if flags.empty?
                :high
              elsif flags.size == 1
                :medium
              else
                :low
              end

      meth = method.to_sym
      meth = :clear_claim if flags.empty? && %i[clear clear_claim].include?(meth)

      ok = level != :low
      guidance = case level
                 when :high
                   if meth == :clear_claim || (flags.empty? && meth == :checklist && yes_ids.empty?)
                     "Signal_trust HIGH by your claim (no risk flags). That is your word, not a sensor. Proceed with care."
                   else
                     "Signal_trust HIGH. Proceed to harm/recoverability + 1/0 with care."
                   end
                 when :medium
                   "Signal_trust MEDIUM. Pause once: breathe, Pocket, or one outside check before high-tier acts."
                 else
                   "Signal_trust LOW. pause_and_reassess: no Tier≥2 side effects. Sabbath / bench / external input."
                 end

      @last_result = Result.new(
        level: level,
        score: score,
        flags: flags,
        guidance: guidance,
        ok_to_decide: ok,
        method: meth.to_s,
        assessed_at: Time.now.utc.iso8601
      )
      @assessed_this_process = true
      save!
      @last_result
    end

    def low?
      !!@last_result && @assessed_this_process && @last_result.level == :low
    end

    def medium_or_low?
      !!@last_result && @assessed_this_process && %i[low medium].include?(@last_result.level)
    end

    # OI-1.1: never treat prior-disk or never-assessed as live clearance for Decide
    def unassessed?
      !@assessed_this_process
    end

    def assessed?
      !unassessed?
    end

    def assessed_this_process?
      @assessed_this_process
    end

    # Disk prior (may exist while unassessed this session)
    def prior_level
      @prior_result&.level
    end

    def display_label
      if assessed_this_process? && @last_result
        "#{@last_result.level} (this session)"
      elsif @prior_result
        "unassessed · prior #{@prior_result.level}"
      else
        "unassessed"
      end
    end

    # Wipe live clearance (does not invent high). Next assess() required.
    def invalidate!(reason: "session_reset")
      @last_result = nil
      @assessed_this_process = false
      # keep @prior_result for display if we re-load? clear prior too when file removed
      if File.file?(@path)
        FileUtils.mkdir_p(File.dirname(@path))
        bak = "#{@path}.pre_oi1_#{Time.now.utc.strftime('%Y%m%dT%H%M%SZ')}.bak"
        FileUtils.cp(@path, bak)
        File.delete(@path)
      end
      @prior_result = nil
      reason
    end

    def self.checklist_text
      HEURISTICS.each_with_index.map { |h, i| "#{i + 1}. #{h[:prompt]} (#{h[:id]})" }.join("\n")
    end

    private

    def normalize_yes(yes_ids)
      out = []
      Array(yes_ids).each do |y|
        if y.to_s =~ /\A\d+\z/
          idx = y.to_i - 1
          out << HEURISTICS[idx][:id].to_s if idx >= 0 && idx < HEURISTICS.size
        else
          id = y.to_s.sub(/\A:/, "")
          out << id if HEURISTICS.any? { |h| h[:id].to_s == id }
        end
      end
      out.uniq
    end

    def load!
      return unless File.file?(@path)
      data = JSON.parse(File.read(@path))
      return unless data["level"]
      prior = Result.new(
        level: data["level"].to_sym,
        score: data["score"].to_f,
        flags: data["flags"] || [],
        guidance: data["guidance"].to_s,
        ok_to_decide: data["ok_to_decide"] != false,
        method: (data["method"] || "prior_disk").to_s,
        assessed_at: data["assessed_at"]
      )
      @prior_result = prior
      # OI-1.1: do NOT promote prior disk to live last_result for Decide.
      # last_result stays nil until assess() this process.
      @last_result = nil
      @assessed_this_process = false
    rescue StandardError
      nil
    end

    def save!
      return unless @last_result
      FileUtils.mkdir_p(File.dirname(@path))
      File.write(@path, JSON.pretty_generate(
        "level" => @last_result.level.to_s,
        "score" => @last_result.score,
        "flags" => @last_result.flags,
        "guidance" => @last_result.guidance,
        "ok_to_decide" => @last_result.ok_to_decide,
        "method" => @last_result.method.to_s,
        "assessed_at" => @last_result.assessed_at || Time.now.utc.iso8601
      ))
    end
  end
end
