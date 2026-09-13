require "ripper"

module KrudminAI
  module Migration
    MigrationReport = Data.define(:source, :mappings, :classifications, :warnings, :blockers) do
      def success?
        blockers.empty?
      end

      def to_h
        { source:, mappings:, classifications:, warnings:, blockers:, success: success? }
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

      SCALAR_FIELD_TYPES = {
        "String" => :string,
        "Text" => :text,
        "Email" => :email,
        "Password" => :password,
        "Hidden" => :hidden,
        "Number" => :number,
        "Decimal" => :decimal,
        "Currency" => :currency,
        "Percentage" => :percentage,
        "Boolean" => :boolean,
        "Date" => :date,
        "Time" => :time,
        "DateTime" => :datetime,
        "Json" => :json,
        "EnumType" => :enum,
        "Identifier" => :identifier
      }.freeze
      ASSISTED_FIELD_TYPES = {
        "BelongsTo" => "belongs_to with target-resource, tenant, policy, and label-read declarations",
        "HasMany" => "has_many with child tenant, policy, field, and row-limit declarations",
        "HasOne" => "has_one with child tenant, policy, and field declarations"
      }.freeze
      BLOCKED_FIELD_TYPES = {
        "BelongsToOne" => "BelongsToOne is not supported by the current generic relationship editor",
        "StateMachine" => "StateMachine requires explicit resource actions or transitions",
        "Polymorphic" => "Polymorphic and arbitrary-depth nested editing are unsupported",
        "HasManyThrough" => "Polymorphic and arbitrary-depth nested editing are unsupported"
      }.freeze

      def call(path)
        source = File.read(path)
        raise ArgumentError, "Legacy resource is not valid Ruby" unless Ripper.sexp(source)

        constants = source.scan(/^\s*([A-Z][A-Z0-9_]*)\s*=/).flatten
        mappings = constants.filter_map { |constant| [ constant, CONSTANT_MAPPINGS[constant] ] if CONSTANT_MAPPINGS.key?(constant) }.to_h
        classifications = constant_classifications(constants) + attribute_type_classifications(source)
        warnings = []
        blockers = []

        warnings << "SEARCHABLE_ATTRIBUTES requires explicit allowlisted filter blocks" if constants.include?("SEARCHABLE_ATTRIBUTES")
        warnings << "ATTRIBUTE_TYPES maps scalar fields automatically; associations require assisted target-resource and field-policy review" if constants.include?("ATTRIBUTE_TYPES")
        warnings << "PRESENTATION_METADATA requires manual section/layout redesign" if constants.include?("PRESENTATION_METADATA")
        warnings << "RESOURCE_INSTANCE_LABEL_ATTRIBUTE requires a host presentation decision" if constants.include?("RESOURCE_INSTANCE_LABEL_ATTRIBUTE")
        warnings << "LISTABLE_ACTIONS requires explicit action authorization and presentation decisions" if constants.include?("LISTABLE_ACTIONS")
        warnings << "PAGINATOR_POSITION requires an engine pagination presentation decision" if constants.include?("PAGINATOR_POSITION")
        warnings << "HasMany maps to has_many with child tenant, policy, field, and row-limit declarations" if source.match?(/:\s*HasMany\b/)
        warnings << "HasOne maps to has_one with child tenant, policy, and field declarations" if source.match?(/:\s*HasOne\b/)
        warnings << "INLINE_EDITABLE_ATTRIBUTES maps to assisted inline_edit declarations for supported adapters" if constants.include?("INLINE_EDITABLE_ATTRIBUTES")
        warnings << "BULK_ACTIONS maps to assisted declared action plus bulk_action declarations" if constants.include?("BULK_ACTIONS")

        blockers.concat(classifications.filter_map { |classification| classification[:reason] if classification[:classification] == :blocked }.uniq)

        MigrationReport.new(path, mappings, classifications, warnings, blockers)
      end

      private

      def constant_classifications(constants)
        constants.filter_map do |constant|
          case constant
          when *CONSTANT_MAPPINGS.keys
            { source: constant, target: CONSTANT_MAPPINGS.fetch(constant), classification: :automatic, reason: "Deterministic resource declaration" }
          when "SEARCHABLE_ATTRIBUTES", "PRESENTATION_METADATA", "RESOURCE_INSTANCE_LABEL_ATTRIBUTE", "PAGINATOR_POSITION"
            { source: constant, target: "host review", classification: :manual, reason: "Requires an explicit host presentation or query decision" }
          when "LISTABLE_ACTIONS", "INLINE_EDITABLE_ATTRIBUTES", "BULK_ACTIONS"
            { source: constant, target: "declared resource actions", classification: :assisted, reason: "Requires explicit authorization, field policy, and audit review" }
          end
        end
      end

      def attribute_type_classifications(source)
        source.scan(/\b([a-zA-Z_]\w*):\s*(?:\{\s*)?(?:type:\s*)?:(\w+)/).filter_map do |field_name, type|
          if SCALAR_FIELD_TYPES.key?(type)
            { source: "ATTRIBUTE_TYPES.#{field_name}", target: "field :#{field_name}, :#{SCALAR_FIELD_TYPES.fetch(type)}", classification: :automatic, reason: "Supported scalar adapter" }
          elsif ASSISTED_FIELD_TYPES.key?(type)
            { source: "ATTRIBUTE_TYPES.#{field_name}", target: ASSISTED_FIELD_TYPES.fetch(type), classification: :assisted, reason: "Requires protected relationship declarations" }
          elsif BLOCKED_FIELD_TYPES.key?(type)
            { source: "ATTRIBUTE_TYPES.#{field_name}", target: "no automatic mapping", classification: :blocked, reason: BLOCKED_FIELD_TYPES.fetch(type) }
          end
        end
      end
    end
  end
end
