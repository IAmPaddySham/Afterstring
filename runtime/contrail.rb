# frozen_string_literal: true
# Merkle Contrail — append-only parent-hashed audit chain.
# Rollback is a NEW event (rollback_reference), never a history rewrite.
# Schema alignment: Module 8.1.17 — timestamp | session_id | parent | hash | approval | rollback_reference
require "json"
require "digest"
require "fileutils"
require "time"
require "securerandom"

module Afterstring
  class Contrail
    GENESIS = "0" * 64
    VALID_SCOPES = %w[runtime memory all constitution].freeze
    # Layer 0 YAML must not be targeted unless Human Kernel names constitution scope explicitly.
    PROTECTED_SCOPES = %w[constitution all].freeze

    # Host integrity leftover #3 — event kinds that must not collapse into each other.
    # Append-only; never rewrite historical rows (incl. broken hash at entry 201).
    EVENT_KINDS = %w[
      session_end
      crash
      timeout
      sabbath
      external_kill
      decide
      permit
      host_event
      council
    ].freeze
    # host_event = freeze/sync/policy/ledger hygiene (NOT relational quit)
    # council     = council session open/index (NOT session_end quit)
    # session_end = process/TUI quit only — do not use as generic bucket

    Entry = Struct.new(
      :timestamp, :session_id, :parent_hash, :event_hash,
      :actor, :tier, :purpose, :approval, :outcome, :payload,
      keyword_init: true
    )

    attr_reader :path, :session_id, :entries

    def initialize(path, session_id: nil)
      @path = File.expand_path(path)
      FileUtils.mkdir_p(File.dirname(@path))
      @session_id = session_id || SecureRandom.hex(8)
      @entries = []
      load_existing!
    end

    def last_hash
      @entries.empty? ? GENESIS : @entries.last.event_hash
    end

    # Logical head after applying rollback_reference events (append-only).
    # If the physical tip is a rollback_reference, logical head = its target_hash.
    # Otherwise logical head = physical tip. Never mutates prior rows.
    def logical_head_hash
      return GENESIS if @entries.empty?
      e = @entries.last
      if e.purpose.to_s == "rollback_reference"
        target = (e.payload["target_hash"] || e.payload[:target_hash]).to_s
        return target.empty? ? GENESIS : target
      end
      e.event_hash
    end

    def logical_head_entry
      h = logical_head_hash
      return nil if h == GENESIS
      find_by_hash(h)
    end

    def clean?
      @entries.empty? || @entries.none? { |e| e.outcome.to_s.include?("RESONANCE") || e.outcome.to_s.include?("VETO") }
    end

    def find_by_hash(hash)
      needle = hash.to_s
      return nil if needle.empty?
      @entries.find { |e| e.event_hash == needle } ||
        @entries.find { |e| e.event_hash.start_with?(needle) }
    end

    def append(purpose:, tier: 0, approval: "auto", outcome: "ok", actor: "human_kernel", payload: {})
      parent = last_hash
      ts = Time.now.utc.iso8601
      body = {
        timestamp: ts,
        session_id: @session_id,
        parent_hash: parent,
        actor: actor,
        tier: tier.to_i,
        purpose: purpose,
        approval: approval,
        outcome: outcome,
        payload: payload
      }
      event_hash = Digest::SHA256.hexdigest(canonical_json(body))
      entry = Entry.new(
        timestamp: ts,
        session_id: @session_id,
        parent_hash: parent,
        event_hash: event_hash,
        actor: actor,
        tier: tier.to_i,
        purpose: purpose,
        approval: approval,
        outcome: outcome,
        payload: payload
      )
      @entries << entry
      with_exclusive_lock do |f|
        f.puts(entry_to_h(entry).to_json)
      end
      entry
    end

    # Typed append — forces a recognized event kind so ledgers cannot be confused.
    # kind: session_end | crash | timeout | sabbath | external_kill | decide | permit
    # assessment / decision / narrative optional (Event ≠ Interpretation fields)
    def append_kind(kind, event:, purpose: nil, tier: 0, approval: "auto", outcome: "ok",
                    actor: "human_kernel", assessment: nil, decision: nil, narrative: nil, extra: {})
      k = kind.to_s
      unless EVENT_KINDS.include?(k)
        raise ArgumentError, "unknown contrail kind #{k.inspect}; allowed: #{EVENT_KINDS.join(', ')}"
      end
      payload = {
        "kind" => k,
        "event" => event.to_s,
        "assessment" => assessment,
        "decision" => decision,
        "narrative" => narrative
      }.merge(extra.is_a?(Hash) ? extra.transform_keys(&:to_s) : {})
      append(
        purpose: (purpose || k).to_s,
        tier: tier,
        approval: approval,
        outcome: outcome,
        actor: actor,
        payload: payload
      )
    end

    def self.kind_of(entry)
      return nil unless entry
      p = entry.payload.is_a?(Hash) ? entry.payload : {}
      p["kind"] || p[:kind]
    end

    # True if a reader could confuse this entry with a relational Release
    def self.looks_like_release?(entry)
      return false unless entry
      return true if entry.purpose.to_s.include?("release")
      p = entry.payload.is_a?(Hash) ? entry.payload : {}
      d = p["decision"] || p[:decision]
      return true if d.is_a?(Hash) && (d["action"].to_s == "release" || d[:action].to_s == "release")
      false
    end

    # Append-only rollback. Requires Human Kernel approval (Tier 2).
    # Does NOT rewrite, delete, or rehash prior events.
    #
    # Returns [true, entry] or [false, reason_string]
    def record_rollback(target_hash:, human_approved:, approval: "1/0 = To Stay",
                        restore_scope: "runtime", reason: "", delta: {}, actor: "human_kernel")
      return [false, "requires human_approved (Tier 2)"] unless human_approved
      return [false, "approval seal required"] if approval.to_s.strip.empty?

      scope = restore_scope.to_s
      return [false, "invalid restore_scope"] unless VALID_SCOPES.include?(scope)

      # Protect Layer 0: constitution / all scopes need explicit layer0 token in approval
      if PROTECTED_SCOPES.include?(scope)
        unless approval.to_s =~ /layer0|Layer 0|constitution/i
          return [false, "constitution/all scope requires explicit Layer 0 mention in approval"]
        end
      end

      target = find_by_hash(target_hash)
      return [false, "target_hash not found in chain"] if target.nil?

      rb = {
        "target_hash" => target.event_hash,
        "target_event_id" => target.event_hash,
        "restore_scope" => scope,
        "human_1_0" => approval.to_s,
        "reason" => reason.to_s,
        "delta" => delta.is_a?(Hash) ? delta : { "note" => delta.to_s },
        "authorized_at" => Time.now.utc.iso8601
      }

      entry = append(
        purpose: "rollback_reference",
        tier: 2,
        approval: approval,
        outcome: "ok",
        actor: actor,
        payload: {
          "rollback_reference" => rb,
          "target_hash" => target.event_hash,
          "restore_scope" => scope,
          "human_1_0" => approval.to_s,
          "reason" => reason.to_s,
          "delta" => rb["delta"]
        }
      )
      # Stamp contrail_hash inside payload for schema readers (equals event_hash)
      # Note: cannot mutate hash body after append without breaking verify — store alias only in memory display.
      [true, entry]
    end

    def recent(n = 8)
      @entries.last(n)
    end

    def verify_chain
      prev = GENESIS
      @entries.each_with_index do |e, i|
        return [false, "parent mismatch at #{i}"] if e.parent_hash != prev
        body = {
          timestamp: e.timestamp,
          session_id: e.session_id,
          parent_hash: e.parent_hash,
          actor: e.actor,
          tier: e.tier,
          purpose: e.purpose,
          approval: e.approval,
          outcome: e.outcome,
          payload: e.payload
        }
        expected = Digest::SHA256.hexdigest(canonical_json(body))
        return [false, "hash mismatch at #{i}"] if expected != e.event_hash
        prev = e.event_hash
      end
      [true, "ok"]
    end

    # Raise if chain invalid (public seal A.L.T._VOID_IF_TAMPERED).
    def verify_chain!
      ok, detail = verify_chain
      unless ok
        raise TamperError, "A.L.T._VOID_IF_TAMPERED: #{detail}"
      end
      true
    end

    def verify_file!
      @entries = []
      load_existing!
      verify_chain!
    end

    class TamperError < StandardError; end

    def export_text
      lines = ["# Afterstring Merkle Contrail export", "# path=#{@path}",
               "# logical_head=#{logical_head_hash[0, 16]}…", ""]
      @entries.each do |e|
        extra = ""
        if e.purpose.to_s == "rollback_reference"
          th = e.payload["target_hash"] || e.payload[:target_hash]
          extra = " → rollback→#{th.to_s[0, 12]}…"
        end
        lines << "[#{e.timestamp}] tier=#{e.tier} #{e.purpose}#{extra} | #{e.approval} → #{e.outcome} | #{e.event_hash[0, 12]}…"
      end
      lines.join("\n")
    end

    private

    # Safe append (process-safe write). Implementation detail only — not public vocabulary.
    def with_exclusive_lock
      FileUtils.mkdir_p(File.dirname(@path))
      File.open(@path, File::RDWR | File::CREAT) do |f|
        f.flock(File::LOCK_EX)
        f.seek(0, IO::SEEK_END)
        yield f
        f.flush
      ensure
        f.flock(File::LOCK_UN) if f
      end
    end

    def load_existing!
      return unless File.file?(@path)
      File.open(@path, "r") do |f|
        f.flock(File::LOCK_SH) if f.respond_to?(:flock)
        f.each_line do |line|
          line = line.strip
          next if line.empty?
          h = JSON.parse(line)
          @entries << Entry.new(
            timestamp: h["timestamp"],
            session_id: h["session_id"],
            parent_hash: h["parent_hash"],
            event_hash: h["event_hash"],
            actor: h["actor"],
            tier: h["tier"].to_i,
            purpose: h["purpose"],
            approval: h["approval"],
            outcome: h["outcome"],
            payload: h["payload"] || {}
          )
        end
      ensure
        f.flock(File::LOCK_UN) if f && f.respond_to?(:flock)
      end
    rescue JSON::ParserError
      # keep what we have
    end

    def entry_to_h(e)
      {
        "timestamp" => e.timestamp,
        "session_id" => e.session_id,
        "parent_hash" => e.parent_hash,
        "event_hash" => e.event_hash,
        "actor" => e.actor,
        "tier" => e.tier,
        "purpose" => e.purpose,
        "approval" => e.approval,
        "outcome" => e.outcome,
        "payload" => e.payload
      }
    end

    def canonical_json(obj)
      JSON.generate(deep_stringify(obj))
    end

    def deep_stringify(obj)
      case obj
      when Hash
        obj.keys.map(&:to_s).sort.each_with_object({}) { |k, h| h[k] = deep_stringify(obj[k] || obj[k.to_sym]) }
      when Array
        obj.map { |x| deep_stringify(x) }
      else
        obj
      end
    end
  end
end
