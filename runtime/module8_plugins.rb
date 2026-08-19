# frozen_string_literal: true
# Module 8 External Framework Plugins V1.1 — optional operator checklists.
# Complements SWI Step 4 / Pocket Audit. NEVER auto-decides Stay/Release.
# NEVER overrides Presence ≡ Never Harm, 1/0 Gate, or constitution matrices.
# Pure Ruby. Human Kernel answers; plugins only surface prompts + notes.

require "json"
require "fileutils"
require "time"

module Afterstring
  # Optional non-agentic overlays (distinct from Module 8.1.xx Plugouts).
  class Module8Plugins
    CATALOG = [
      {
        id: :attachment,
        name: "Attachment Theory",
        swi_step: 4,
        prompts: [
          "Anxious about abandonment or avoidant about closeness right now?",
          "Is this difficulty rooted in an old attachment wound rather than present harm?"
        ],
        note_if_yes: "Attachment pattern flagged — distinguish healthy difficulty from reenactment before 1/0. Kernel still decides."
      },
      {
        id: :eft,
        name: "Emotionally Focused Therapy (EFT)",
        swi_step: 3,
        prompts: [
          "Is presence strained (not yet harm) and a primary emotion/need for connection unsaid?"
        ],
        note_if_yes: "EFT lens: name primary emotion → need → invite response. Does not override Release Clause if harm present."
      },
      {
        id: :gottman,
        name: "Gottman Method",
        swi_step: 4,
        prompts: [
          "Is today's positive:negative interaction ratio clearly below ~5:1?"
        ],
        note_if_yes: "Relational tone erosion flag — intentional kindness moves may help. Never use ratio to stay in clear harm."
      },
      {
        id: :nvc,
        name: "Nonviolent Communication (NVC)",
        swi_step: 4,
        prompts: [
          "Would Observation → Feeling → Need → Request clarify what must be said without blame?"
        ],
        note_if_yes: "OFNR structure available. Not a substitute for safety-first Release when abuse/high conflict."
      },
      {
        id: :cbt_dbt,
        name: "CBT / DBT",
        swi_step: 1,
        prompts: [
          "Is a thought reframing harm as 'devotion' or 'healthy difficulty' without evidence?"
        ],
        note_if_yes: "Run a quick thought record (situation → thought → evidence → alternative). 1/0 Gate still final."
      },
      {
        id: :ifs,
        name: "Internal Family Systems (IFS)",
        swi_step: 5,
        prompts: [
          "Is an internal 'manager' part demanding Stay while another part feels harm?"
        ],
        note_if_yes: "Parts dialogue optional; unburden gently. Acute crisis → professional support, not plugin alone."
      },
      {
        id: :stoicism,
        name: "Stoicism",
        swi_step: 3,
        prompts: [
          "Am I spending energy on what I cannot control (other's choices) vs my response?"
        ],
        note_if_yes: "Dichotomy of control — focus on response/virtue. Pair with Presence ≡ Never Harm."
      },
      {
        id: :mindfulness,
        name: "Buddhist Mindfulness / Non-Attachment",
        swi_step: 4,
        prompts: [
          "Is the integral heavy with clinging (force persistence) rather than present attention?"
        ],
        note_if_yes: "One conscious breath: 'I am here, but I do not cling.' Non-attachment ≠ avoidance of needed Release."
      },
      {
        id: :polyvagal,
        name: "Polyvagal Theory",
        swi_step: 0,
        prompts: [
          "Does my body feel mobilized (racing) or shut-down rather than relatively safe?"
        ],
        note_if_yes: "Nervous-system flag — pause before 1/0. Not diagnostic; severe dysregulation needs professional support."
      },
      {
        id: :utilitarian,
        name: "Utilitarian Ethics",
        swi_step: 7,
        prompts: [
          "Before Release: have I briefly weighed net wellbeing for all parties without erasing dignity?"
        ],
        note_if_yes: "Aggregate lens is optional input only. Subordinate to Presence ≡ Never Harm and individual 1/0."
      }
    ].freeze

    Result = Struct.new(
      :plugin_ids, :flags, :notes, :suggest_pause, :suggest_release_review,
      :never_overrides_kernel, :guidance, keyword_init: true
    )

    attr_reader :path, :last_result

    def initialize(path)
      @path = File.expand_path(path)
      @last_result = nil
      load!
    end

    def self.ids
      CATALOG.map { |p| p[:id] }
    end

    def self.find(id)
      sid = id.to_s.sub(/\A:/, "").to_sym
      CATALOG.find { |p| p[:id] == sid }
    end

    def self.list_text
      lines = ["Module 8 External Plugins V1.1 (OPTIONAL — never override kernel)", ""]
      CATALOG.each_with_index do |p, i|
        lines << "#{i + 1}. #{p[:id]} — #{p[:name]} (SWI step ~#{p[:swi_step]})"
        p[:prompts].each { |q| lines << "     · #{q}" }
      end
      lines << ""
      lines << "Usage: afterstring plugins check attachment,polyvagal --yes attachment"
      lines << "Human Kernel holds final 1/0. Firmware ≠ love."
      lines.join("\n")
    end

    # yes_ids: plugin ids (or 1-based indices) where human answered yes to concern prompts
    def assess(plugin_ids: nil, yes_ids: [])
      selected = normalize_plugins(plugin_ids)
      yes = normalize_yes(yes_ids)
      # only count yes that intersect selected (or all catalog if selected empty → use yes only)
      scope = selected.empty? ? CATALOG.map { |p| p[:id].to_s } : selected
      flags = yes.select { |y| scope.include?(y) }

      notes = []
      suggest_pause = false
      suggest_release_review = false

      flags.each do |fid|
        plug = self.class.find(fid)
        next unless plug
        notes << "#{plug[:name]}: #{plug[:note_if_yes]}"
        suggest_pause = true if %i[polyvagal mindfulness attachment cbt_dbt ifs].include?(plug[:id])
        suggest_release_review = true if %i[attachment cbt_dbt utilitarian gottman].include?(plug[:id])
      end

      guidance =
        if flags.empty?
          "No Module 8 concern flags. Proceed to harm/recoverability + 1/0 with care. Plugins remain optional."
        else
          parts = ["Module 8 notes active (#{flags.size})."]
          parts << "Suggest brief pause/bench before high-stakes 1/0." if suggest_pause
          parts << "Consider Release Clause review if harm is present (do not stay for plugin reasons)." if suggest_release_review
          parts << "Plugins NEVER approve Stay and NEVER block Release. Human Kernel decides."
          parts.join(" ")
        end

      @last_result = Result.new(
        plugin_ids: scope,
        flags: flags,
        notes: notes,
        suggest_pause: suggest_pause,
        suggest_release_review: suggest_release_review,
        never_overrides_kernel: true,
        guidance: guidance
      )
      save!
      @last_result
    end

    def to_h
      return {} unless @last_result
      {
        "flags" => @last_result.flags,
        "notes" => @last_result.notes,
        "suggest_pause" => @last_result.suggest_pause,
        "suggest_release_review" => @last_result.suggest_release_review,
        "never_overrides_kernel" => true,
        "guidance" => @last_result.guidance
      }
    end

    private

    def normalize_plugins(plugin_ids)
      return [] if plugin_ids.nil? || (plugin_ids.respond_to?(:empty?) && plugin_ids.empty?)
      out = []
      Array(plugin_ids).each do |y|
        y.to_s.split(/[,\s]+/).each do |tok|
          next if tok.empty?
          if tok =~ /\A\d+\z/
            idx = tok.to_i - 1
            out << CATALOG[idx][:id].to_s if idx >= 0 && idx < CATALOG.size
          else
            id = tok.sub(/\A:/, "")
            out << id if self.class.find(id)
          end
        end
      end
      out.uniq
    end

    def normalize_yes(yes_ids)
      normalize_plugins(yes_ids)
    end

    def load!
      return unless File.file?(@path)
      data = JSON.parse(File.read(@path))
      return unless data["flags"]
      @last_result = Result.new(
        plugin_ids: data["plugin_ids"] || [],
        flags: data["flags"] || [],
        notes: data["notes"] || [],
        suggest_pause: data["suggest_pause"] == true,
        suggest_release_review: data["suggest_release_review"] == true,
        never_overrides_kernel: true,
        guidance: data["guidance"].to_s
      )
    rescue StandardError
      nil
    end

    def save!
      return unless @last_result
      FileUtils.mkdir_p(File.dirname(@path))
      File.write(@path, JSON.pretty_generate(
        "plugin_ids" => @last_result.plugin_ids,
        "flags" => @last_result.flags,
        "notes" => @last_result.notes,
        "suggest_pause" => @last_result.suggest_pause,
        "suggest_release_review" => @last_result.suggest_release_review,
        "never_overrides_kernel" => true,
        "guidance" => @last_result.guidance,
        "assessed_at" => Time.now.utc.iso8601
      ))
    end
  end
end
