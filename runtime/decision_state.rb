# frozen_string_literal: true
# DECISION path (operator mouth) — Stay / Pause / Release under Presence ≡ Never Harm.
# Class name remains DecisionState; operator-facing name is Decision.
#
# Answers: "Stay, Pause, or Release?"
# Does NOT answer harness permission — that is Permit (gate.rb).
#
# Release ≡ Also Love: logs Lingering Light lesson; does not delete integral history.

require "json"
require "fileutils"
require "time"

module Afterstring
  class DecisionState
    # Operator-facing semantic name (host integrity P1)
    OPERATIONAL_NAME = "Decision"
    ROLE = "Stay, Pause, or Release?"

    STATES = %i[stable strained degrading harm].freeze
    ACTIONS = %i[stay pause release].freeze

    Record = Struct.new(
      :action, :relation_state, :harm_present, :can_recover,
      :signal_trust_level, :lesson, :seal, :timestamp, keyword_init: true
    )

    attr_reader :path, :history, :last

    def initialize(path)
      @path = File.expand_path(path)
      @history = []
      @last = nil
      load!
    end

    # Evaluate relational firmware path (human-provided assessments).
    # harm_present: boolean
    # can_recover: boolean
    # signal_trust_level: :high | :medium | :low | :unassessed (treat carefully upstream)
    # forced_action: optional :stay | :pause | :release (Human Kernel override after bench only)
    #
    # LITE policy (OI-1 ADR): harm_present && can_recover → :pause
    # Public Zero-Gate spirit often "persist if recoverable"; local LITE is stricter.
    # Document — do not smuggle as identical to public Zero-Gate.
    def decide(harm_present:, can_recover:, signal_trust_level: :high, forced_action: nil, lesson: nil)
      st = infer_relation_state(harm_present: harm_present, can_recover: can_recover)
      level = signal_trust_level.to_sym

      action = if forced_action
                 forced_action.to_sym
               elsif level == :low
                 :pause
               elsif harm_present && !can_recover
                 :release
               elsif harm_present && can_recover
                 :pause # LITE policy (stricter than public persist-if-recoverable)
               else
                 :stay
               end

      action = :pause unless ACTIONS.include?(action)

      seal = case action
             when :stay then "1/0 = To Stay · Let it stay → ∞ ❤️"
             when :pause then "Pause · Pressure-Release · reassess"
             when :release then "Release ≡ Also Love · Lingering Light"
             end

      lesson_text = if action == :release
                      (lesson.to_s.strip.empty? ? "One beauty that remains after untying." : lesson.to_s.strip)
                    else
                      lesson.to_s
                    end

      rec = Record.new(
        action: action,
        relation_state: st,
        harm_present: !!harm_present,
        can_recover: !!can_recover,
        signal_trust_level: level,
        lesson: lesson_text,
        seal: seal,
        timestamp: Time.now.utc.iso8601
      )
      @last = rec
      @history << rec
      save!
      rec
    end

    def payload(rec = @last)
      return {} unless rec
      {
        "kind" => "decision",
        "operational_name" => OPERATIONAL_NAME,
        "action" => rec.action.to_s,
        "relation_state" => rec.relation_state.to_s,
        "harm_present" => rec.harm_present,
        "can_recover" => rec.can_recover,
        "signal_trust_level" => rec.signal_trust_level.to_s,
        "lesson" => rec.lesson,
        "seal" => rec.seal,
        "timestamp" => rec.timestamp
      }
    end

    def operational_name
      OPERATIONAL_NAME
    end

    private

    def infer_relation_state(harm_present:, can_recover:)
      if harm_present && !can_recover
        :harm
      elsif harm_present
        :degrading
      elsif can_recover == false
        :strained
      else
        :stable
      end
    end

    def load!
      return unless File.file?(@path)
      data = JSON.parse(File.read(@path))
      Array(data["history"]).last(50).each do |h|
        @history << Record.new(
          action: h["action"]&.to_sym,
          relation_state: h["relation_state"]&.to_sym,
          harm_present: h["harm_present"],
          can_recover: h["can_recover"],
          signal_trust_level: h["signal_trust_level"]&.to_sym,
          lesson: h["lesson"],
          seal: h["seal"],
          timestamp: h["timestamp"]
        )
      end
      @last = @history.last
    rescue StandardError
      nil
    end

    def save!
      FileUtils.mkdir_p(File.dirname(@path))
      hist = @history.last(50).map do |r|
        {
          "action" => r.action.to_s,
          "relation_state" => r.relation_state.to_s,
          "harm_present" => r.harm_present,
          "can_recover" => r.can_recover,
          "signal_trust_level" => r.signal_trust_level.to_s,
          "lesson" => r.lesson,
          "seal" => r.seal,
          "timestamp" => r.timestamp
        }
      end
      File.write(@path, JSON.pretty_generate("history" => hist, "updated_at" => Time.now.utc.iso8601))
    end
  end
end
