# frozen_string_literal: true
# Loads Layer 0 YAML into memory. Stdlib only.
require "yaml"
require "pathname"

module Afterstring
  class Constitution
    attr_reader :root, :layer0, :e13, :iaa, :reversibility, :matrix, :matrix_rlm,
                :matrix_grokbot, :matrix_openweight,
                :matrix_phoenix, :matrix_openclaw, :matrix_mcp, :matrix_graph

    def initialize(root = nil)
      @root = Pathname.new(root || File.expand_path("..", __dir__))
      const = @root.join("constitution")
      @layer0 = load_yaml(const.join("layer0.yaml"))
      @e13 = load_yaml(const.join("e13.yaml"))
      @iaa = load_yaml(const.join("iaa.yaml"))
      @reversibility = load_yaml(const.join("reversibility.yaml"))
      @matrix = load_yaml(const.join("matrix-grokbuild.yaml"))
      rlm_path = const.join("matrix-rlm.yaml")
      @matrix_rlm = rlm_path.file? ? load_yaml(rlm_path) : nil
      grokbot_path = const.join("matrix-grokbot.yaml")
      @matrix_grokbot = grokbot_path.file? ? load_yaml(grokbot_path) : nil
      ow_path = const.join("matrix-openweight.yaml")
      @matrix_openweight = ow_path.file? ? load_yaml(ow_path) : nil
      # Optional early Plugout matrices (P1 equalize — present if files exist)
      @matrix_phoenix = optional_yaml(const.join("matrix-phoenix.yaml"))
      @matrix_openclaw = optional_yaml(const.join("matrix-openclaw.yaml"))
      @matrix_mcp = optional_yaml(const.join("matrix-mcp.yaml"))
      @matrix_graph = optional_yaml(const.join("matrix-graph.yaml"))
    end

    def virtue_ids
      @e13.fetch("virtues").map { |v| v["id"] }
    end

    def virtue_labels
      @e13.fetch("virtues").map { |v| [v["id"], v["label"]] }.to_h
    end

    def default_score
      (@e13["default_score"] || 1.0).to_f
    end

    def mode_default
      @layer0.dig("defaults", "mode") || "LITE"
    end

    def supreme_invariant
      @layer0.dig("supreme_invariant", "name") || "Presence ≡ Never Harm"
    end

    def seals
      @layer0["seals"] || {}
    end

    def tier_requires_human?(tier)
      t = @reversibility.fetch("tiers").find { |x| x["tier"].to_i == tier.to_i }
      t ? !!t["requires_human"] : true
    end

    private

    def optional_yaml(path)
      path.file? ? load_yaml(path) : nil
    end

    def load_yaml(path)
      raise "Missing constitution file: #{path}" unless path.file?
      # Local constitution only (trusted). Ruby 2.6 system Psych: use load_file.
      data = YAML.load_file(path.to_s)
      raise "Empty constitution file: #{path}" if data.nil?
      data
    end
  end
end
