# frozen_string_literal: true
# Anchor registry — Layer 0 reference pointers (photos, bench, places).
# Not sacred objects; replaceable living pointers for Reality Veto demos.
# Freshness: stale anchors warn; never auto-block without Human Kernel.

require "json"
require "fileutils"
require "time"
require "securerandom"

module Afterstring
  class Anchors
    Anchor = Struct.new(:id, :kind, :label, :path, :note, :created_at, :last_touched_at, keyword_init: true)

    DEFAULT_KINDS = %w[bench photo place breath sonic virtual].freeze
    # Soft freshness default: 14 days for photo pointers (warn only)
    DEFAULT_FRESH_DAYS = 14

    attr_reader :path, :items, :fresh_days

    def initialize(path, repo_root: nil, fresh_days: DEFAULT_FRESH_DAYS)
      @path = File.expand_path(path)
      @repo_root = repo_root && File.expand_path(repo_root)
      @fresh_days = fresh_days.to_i
      @items = []
      load!
      seed_defaults! if @items.empty?
    end

    def list
      @items
    end

    def get(id)
      @items.find { |a| a.id == id.to_s || a.id.start_with?(id.to_s) }
    end

    def add(kind:, label:, path: nil, note: "", id: nil)
      kind_s = kind.to_s
      kind_s = "place" unless DEFAULT_KINDS.include?(kind_s)
      aid = id.to_s.empty? ? SecureRandom.hex(4) : id.to_s
      now = Time.now.utc.iso8601
      a = Anchor.new(
        id: aid,
        kind: kind_s,
        label: label.to_s,
        path: path.to_s,
        note: note.to_s,
        created_at: now,
        last_touched_at: now
      )
      @items << a
      save!
      a
    end

    def touch(id)
      a = get(id)
      return nil unless a
      a.last_touched_at = Time.now.utc.iso8601
      save!
      a
    end

    def remove(id)
      before = @items.size
      @items.reject! { |a| a.id == id.to_s }
      save! if @items.size != before
      before != @items.size
    end

    def freshness(a)
      return { status: :unknown, days: nil } unless a&.last_touched_at
      t = Time.parse(a.last_touched_at)
      days = ((Time.now - t) / 86_400.0)
      status = days > @fresh_days ? :stale : :fresh
      { status: status, days: days.round(1) }
    rescue StandardError
      { status: :unknown, days: nil }
    end

    def path_exists?(a)
      return false if a.nil? || a.path.to_s.empty?
      p = a.path
      p = File.join(@repo_root, p) if @repo_root && !p.start_with?("/")
      File.file?(p) || File.directory?(p)
    end

    def summary_lines
      @items.map do |a|
        fr = freshness(a)
        exists = path_exists?(a) ? "ok" : (a.path.to_s.empty? ? "n/a" : "missing-file")
        "#{a.id[0, 8]} #{a.kind} #{a.label} [#{fr[:status]}] file=#{exists}"
      end
    end

    private

    def seed_defaults!
      # Pointers into repo media if present — not required to exist for registry validity
      add(kind: "bench", label: "Layer 0 bench (May 17 2024 coast)", note: "sit instead of accelerate", id: "bench-origin")
      if @repo_root
        coast = "media/layer0/coast-2026-08-10-grokbot.jpg"
        add(kind: "photo", label: "Coast GrokBot seal", path: coast, id: "photo-coast-grokbot") if File.file?(File.join(@repo_root, coast))
        jp = "media/layer0/japan-2026"
        add(kind: "place", label: "Japan 2026 anchors dir", path: jp, id: "place-japan-2026") if File.directory?(File.join(@repo_root, jp))
      end
    end

    def load!
      return unless File.file?(@path)
      data = JSON.parse(File.read(@path))
      @fresh_days = data["fresh_days"].to_i if data["fresh_days"]
      Array(data["anchors"]).each do |h|
        @items << Anchor.new(
          id: h["id"],
          kind: h["kind"],
          label: h["label"],
          path: h["path"],
          note: h["note"],
          created_at: h["created_at"],
          last_touched_at: h["last_touched_at"]
        )
      end
    rescue StandardError
      nil
    end

    def save!
      FileUtils.mkdir_p(File.dirname(@path))
      File.write(@path, JSON.pretty_generate(
        "fresh_days" => @fresh_days,
        "anchors" => @items.map do |a|
          {
            "id" => a.id,
            "kind" => a.kind,
            "label" => a.label,
            "path" => a.path,
            "note" => a.note,
            "created_at" => a.created_at,
            "last_touched_at" => a.last_touched_at
          }
        end,
        "updated_at" => Time.now.utc.iso8601
      ))
    end
  end
end
