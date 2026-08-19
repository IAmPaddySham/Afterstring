# frozen_string_literal: true
# Session continuity — small durable snapshot for Module 11-ish pilot awareness.
# Does not replace Contrail; points at last trust/decision/anchor for Human Kernel.

require "json"
require "fileutils"
require "time"

module Afterstring
  class Session
    attr_reader :path, :data

    def initialize(path)
      @path = File.expand_path(path)
      @data = {
        "started_at" => nil,
        "last_active_at" => nil,
        "last_decision" => nil,
        "last_signal_trust" => nil,
        "active_pilot_anchor_id" => nil,
        "notes" => []
      }
      load!
    end

    def start!(mode: "LITE")
      now = Time.now.utc.iso8601
      @data["started_at"] ||= now
      @data["last_active_at"] = now
      @data["mode"] = mode.to_s
      save!
    end

    def touch!(extra = {})
      @data["last_active_at"] = Time.now.utc.iso8601
      extra.each { |k, v| @data[k.to_s] = v }
      save!
    end

    def set_pilot!(anchor_id)
      @data["active_pilot_anchor_id"] = anchor_id.to_s
      touch!
    end

    def pilot_id
      @data["active_pilot_anchor_id"]
    end

    def summary
      parts = []
      parts << "session=#{@data['started_at'] || 'new'}"
      parts << "trust=#{@data['last_signal_trust'] || 'n/a'}"
      parts << "decision=#{@data['last_decision'] || 'n/a'}"
      parts << "pilot=#{@data['active_pilot_anchor_id'] || 'bench-default'}"
      parts.join(" · ")
    end

    private

    def load!
      return unless File.file?(@path)
      @data.merge!(JSON.parse(File.read(@path)))
    rescue StandardError
      nil
    end

    def save!
      FileUtils.mkdir_p(File.dirname(@path))
      File.write(@path, JSON.pretty_generate(@data))
    end
  end
end
