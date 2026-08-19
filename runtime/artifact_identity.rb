# frozen_string_literal: true
# Model Artifact Identity (After_OpenWeight 8.1.19) — LITE struct + validation.
# Authorization is non-transferable across artifacts. Unknown fields => incomplete.

require "digest"
require "json"

module Afterstring
  class ArtifactIdentity
    FIELDS = %w[
      upstream_id source license weight_hash tokenizer_hash quant quant_params
      engine runtime adapter_hash constitution tools
    ].freeze

    attr_reader :fields

    def initialize(h = {})
      @fields = {}
      FIELDS.each { |k| @fields[k] = h[k] || h[k.to_sym] }
    end

    def complete?
      # LITE minimum for local infer authorization binding
      %w[upstream_id engine constitution].all? { |k| !@fields[k].to_s.strip.empty? }
    end

    def missing
      FIELDS.select { |k| @fields[k].to_s.strip.empty? }
    end

    def identity_hash
      Digest::SHA256.hexdigest(canonical_json)
    end

    def canonical_json
      FIELDS.map { |k| [k, @fields[k].to_s] }.to_h.sort.to_h.to_json
    end

    def to_h
      @fields.merge(
        "complete" => complete?,
        "identity_hash" => (complete? ? identity_hash : nil),
        "missing" => missing
      )
    end

    # Bind a 1/0 record to this artifact (non-transferable)
    def self.bind_authorization(artifact, human_approved:, intent:)
      a = artifact.is_a?(ArtifactIdentity) ? artifact : ArtifactIdentity.new(artifact)
      {
        "ok" => a.complete? && human_approved,
        "artifact" => a.to_h,
        "intent" => intent.to_s,
        "human_approved" => !!human_approved,
        "note" => a.complete? ? "artifact-bound 1/0 candidate" : "incomplete Artifact Identity — revalidation required",
        "unknown_to_zero" => !a.complete?
      }
    end
  end
end
