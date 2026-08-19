# frozen_string_literal: true
# Sabbath Airgap timer — rhythmic disconnection (default daily).
require "time"
require "json"
require "fileutils"

module Afterstring
  class Sabbath
    DEFAULT_HOURS = 24

    attr_reader :interval_hours, :last_airgap_at, :path

    def initialize(path, interval_hours: DEFAULT_HOURS)
      @path = File.expand_path(path)
      @interval_hours = interval_hours.to_f
      @last_airgap_at = Time.now
      load!
    end

    def remaining_seconds
      elapsed = Time.now - @last_airgap_at
      left = (@interval_hours * 3600) - elapsed
      left.positive? ? left : 0
    end

    def remaining_human
      s = remaining_seconds.to_i
      return "DUE NOW" if s <= 0
      h = s / 3600
      m = (s % 3600) / 60
      "#{h}h #{m}m remaining"
    end

    def due?
      remaining_seconds <= 0
    end

    def mark_airgap!
      @last_airgap_at = Time.now
      save!
      @last_airgap_at
    end

    private

    def load!
      return unless File.file?(@path)
      data = JSON.parse(File.read(@path))
      @last_airgap_at = Time.parse(data["last_airgap_at"]) if data["last_airgap_at"]
      @interval_hours = data["interval_hours"].to_f if data["interval_hours"]
    rescue StandardError
      nil
    end

    def save!
      FileUtils.mkdir_p(File.dirname(@path))
      File.write(@path, JSON.pretty_generate(
        "last_airgap_at" => @last_airgap_at.utc.iso8601,
        "interval_hours" => @interval_hours
      ))
    end
  end
end
