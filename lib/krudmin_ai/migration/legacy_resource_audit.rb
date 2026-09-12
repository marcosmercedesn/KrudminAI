require "ripper"

module KrudminAI
  module Migration
    MigrationReport = Data.define(:source, :mappings, :warnings, :blockers) do
      def success?
        blockers.empty?
      end

      def to_h
        { source:, mappings:, warnings:, blockers:, success: success? }
      end
    end

    class LegacyResourceAudit
      CONSTANT_MAPPINGS = {
        "MODEL_CLASSNAME" => "model ModelClass",
        "RESOURCE_LABEL" => "label",
        "RESOURCES_LABEL" => "plural_label",
        "LISTABLE_ATTRIBUTES" => "list",
        "EDITABLE_ATTRIBUTES" => "form",
        "DISPLAYABLE_ATTRIBUTES" => "show",
        "LISTABLE_INCLUDES" => "preload",
        "ORDER_BY" => "sortable and default_sort_by",
        "DASHBOARD_SCOPES" => "Dashboards::Base relation factory",
        "DASHBOARD_COLUMNS" => "field-authorized dashboard table columns"
      }.freeze

      def call(path)
        source = File.read(path)
        raise ArgumentError, "Legacy resource is not valid Ruby" unless Ripper.sexp(source)

        constants = source.scan(/^\s*([A-Z][A-Z0-9_]*)\s*=/).flatten
        mappings = constants.filter_map { |constant| [constant, CONSTANT_MAPPINGS[constant]] if CONSTANT_MAPPINGS.key?(constant) }.to_h
        warnings = []
        blockers = []

        warnings << "SEARCHABLE_ATTRIBUTES requires explicit allowlisted filter blocks" if constants.include?("SEARCHABLE_ATTRIBUTES")
        warnings << "ATTRIBUTE_TYPES requires manual field-adapter review" if constants.include?("ATTRIBUTE_TYPES")
        warnings << "PRESENTATION_METADATA requires manual section/layout redesign" if constants.include?("PRESENTATION_METADATA")
        warnings << "RESOURCE_INSTANCE_LABEL_ATTRIBUTE requires a host presentation decision" if constants.include?("RESOURCE_INSTANCE_LABEL_ATTRIBUTE")
        warnings << "LISTABLE_ACTIONS requires explicit action authorization and presentation decisions" if constants.include?("LISTABLE_ACTIONS")
        warnings << "PAGINATOR_POSITION requires an engine pagination presentation decision" if constants.include?("PAGINATOR_POSITION")
        warnings << "HasMany maps to has_many with child tenant, policy, field, and row-limit declarations" if source.match?(/:\s*HasMany\b/)

        blockers << "HasOne is not supported by the current generic relationship editor" if source.match?(/:\s*HasOne\b/)
        blockers << "BelongsToOne is not supported by the current generic relationship editor" if source.match?(/:\s*BelongsToOne\b/)
        blockers << "StateMachine requires explicit resource actions or transitions" if source.match?(/:\s*StateMachine\b/)
        blockers << "INLINE_EDITABLE_ATTRIBUTES has no compatibility shim" if constants.include?("INLINE_EDITABLE_ATTRIBUTES")
        blockers << "BULK_ACTIONS has no compatibility shim" if constants.include?("BULK_ACTIONS")

        MigrationReport.new(path, mappings, warnings, blockers)
      end
    end
  end
end