require "i18n"

module KrudminAI
  module Validations
    # Projects server-side validation into a normalized, client-consumable rule descriptor.
    # A rule is only emitted when it can be evaluated in the browser at least as narrowly as
    # the server evaluates it; anything else is left to the authoritative mutation pipeline.
    class Introspector
      EMPTY = {}.freeze

      SUPPORTED_KINDS = %i[presence length numericality format inclusion exclusion acceptance confirmation].freeze
      SERVER_ONLY_KINDS = %i[uniqueness].freeze
      CONDITIONAL_OPTION_KEYS = %i[if unless on].freeze
      COMPARISON_OPTIONS = %i[greater_than greater_than_or_equal_to less_than less_than_or_equal_to].freeze
      NARROWER = { maximum: :min, less_than: :min, less_than_or_equal_to: :min,
                   minimum: :max, greater_than: :max, greater_than_or_equal_to: :max }.freeze
      SKIPPED_COLUMNS = %w[id created_at updated_at].freeze

      def self.call(model_class:, adapter:, attribute:, record:, context:, authorizer:)
        new(model_class:, adapter:, attribute:, record:, context:, authorizer:).call
      end

      def initialize(model_class:, adapter:, attribute:, record:, context:, authorizer:)
        @model_class = model_class
        @adapter = adapter
        @attribute = attribute.to_sym
        @record = record
        @context = context
        @authorizer = authorizer
      end

      def call
        return EMPTY unless projectable?

        rules = {}
        merge(rules, column_constraints)
        merge(rules, validator_constraints)
        merge(rules, adapter&.validation_constraints)
        return EMPTY if rules.empty?

        messages = Messages.new(record:, attribute:, model_class:, rules:).call
        rules[:messages] = messages if messages.any?
        rules.freeze
      end

      private

      attr_reader :model_class, :adapter, :attribute, :record, :context, :authorizer

      # A nested field without a declared adapter still renders a plain text control.
      def projectable?
        return false if record.nil?
        return false if adapter && !adapter.validation_projectable?

        authorizer.field_readable?(attribute, record, context) && authorizer.field_writable?(attribute, record, context)
      end

      def column
        return @column if defined?(@column)

        @column = if model_class.respond_to?(:columns_hash) && !SKIPPED_COLUMNS.include?(attribute.to_s)
          model_class.columns_hash[attribute.to_s]
        end
      end

      def column_constraints
        return {} unless column

        constraints = {}
        # A defaulted column accepts a blank submission, so nullability alone cannot imply required.
        constraints[:required] = true if column.respond_to?(:null) && column.null == false && column_default.nil? && column.type != :boolean
        constraints[:maximum] = column.limit if %i[string text].include?(column.type) && column.respond_to?(:limit) && column.limit.is_a?(Integer)
        constraints[:step] = format("%.#{column.scale}f", 10**-column.scale) if column.respond_to?(:scale) && column.scale.to_i.positive?
        constraints
      end

      def column_default
        column.respond_to?(:default) ? column.default : nil
      end

      def validator_constraints
        return {} unless model_class.respond_to?(:validators_on)

        model_class.validators_on(attribute).each_with_object({}) do |validator, constraints|
          projected = project_validator(validator)
          merge(constraints, projected) if projected
        end
      rescue StandardError
        {}
      end

      # Returns nil when the validator is server-only.
      def project_validator(validator)
        return nil unless validator.respond_to?(:kind)

        kind = validator.kind.to_sym
        return nil unless SUPPORTED_KINDS.include?(kind)

        options = validator.respond_to?(:options) ? validator.options : {}
        return nil if (options.keys.map(&:to_sym) & CONDITIONAL_OPTION_KEYS).any?

        send(:"project_#{kind}", options)
      end

      def project_presence(_options) = { required: true }

      def project_acceptance(_options)
        adapter.is_a?(Fields::Boolean) ? { required: true } : nil
      end

      def project_confirmation(_options) = { confirms: "#{attribute}_confirmation" }

      def project_length(options)
        range = options[:in] || options[:within]
        constraints = {}
        constraints[:minimum] = range.min if range.is_a?(Range)
        constraints[:maximum] = range.max if range.is_a?(Range)
        constraints[:minimum] = options[:minimum] if options[:minimum].is_a?(Integer)
        constraints[:maximum] = options[:maximum] if options[:maximum].is_a?(Integer)
        constraints[:is] = options[:is] if options[:is].is_a?(Integer)
        constraints
      end

      def project_numericality(options)
        constraints = { numeric: true }
        COMPARISON_OPTIONS.each do |name|
          value = options[name]
          constraints[name] = value if value.is_a?(Numeric)
        end
        constraints[:only_integer] = true if options[:only_integer] == true
        constraints[:parity] = :odd if options[:odd] == true
        constraints[:parity] = :even if options[:even] == true
        constraints
      end

      def project_format(options)
        return nil unless options[:with].is_a?(Regexp)

        pattern = javascript_pattern(options[:with])
        pattern ? { pattern: } : nil
      end

      def project_inclusion(options)
        values = literal_values(options)
        values ? { one_of: values } : nil
      end

      def project_exclusion(options)
        values = literal_values(options)
        values ? { none_of: values } : nil
      end

      def literal_values(options)
        candidate = options[:in] || options[:within]
        return nil unless candidate.is_a?(Array)
        return nil unless candidate.all? { |value| value.is_a?(::String) || value.is_a?(Symbol) || value.is_a?(Numeric) }

        candidate.map { |value| value.is_a?(Numeric) ? value : value.to_s }
      end

      # Ruby anchors and JavaScript anchors only agree when the pattern is fully string-anchored,
      # so anything else is dropped rather than translated into a stricter browser rule.
      def javascript_pattern(regexp)
        return nil unless (regexp.options & ::Regexp::MULTILINE).zero?
        return nil unless (regexp.options & ::Regexp::EXTENDED).zero?

        source = regexp.source
        anchored_start = source.start_with?('\A')
        anchored_end = source.end_with?('\z', '\Z')
        body = source.dup
        body = body.delete_prefix('\A') if anchored_start
        body = body.delete_suffix('\z').delete_suffix('\Z') if anchored_end
        return nil if body.match?(/(?<!\\)[\^$]/)
        return nil if body.match?(/\\[AzZhHRpGk]|\(\?<|\[:[a-z]+:\]|\(\?#/)

        "#{anchored_start ? '^' : ''}#{body}#{anchored_end ? '$' : ''}"
      end

      def merge(base, extra)
        return base unless extra

        extra.each do |key, value|
          next if value.nil?

          base[key] = base.key?(key) ? narrower(key, base[key], value) : value
        end
        base
      end

      def narrower(key, current, candidate)
        return current || candidate if key == :required
        return current & candidate if key == :one_of && current.is_a?(Array) && candidate.is_a?(Array)
        return candidate unless current.is_a?(Numeric) && candidate.is_a?(Numeric)

        case NARROWER[key]
        when :min then [ current, candidate ].min
        when :max then [ current, candidate ].max
        else candidate
        end
      end

      # Builds full messages through Rails i18n so client text matches the server byte for byte.
      class Messages
        ERROR_KEYS = {
          required: [ :blank, {} ],
          minimum: [ :too_short, { count: true } ],
          maximum: [ :too_long, { count: true } ],
          is: [ :wrong_length, { count: true } ],
          greater_than: [ :greater_than, { count: true } ],
          greater_than_or_equal_to: [ :greater_than_or_equal_to, { count: true } ],
          less_than: [ :less_than, { count: true } ],
          less_than_or_equal_to: [ :less_than_or_equal_to, { count: true } ],
          only_integer: [ :not_an_integer, {} ],
          numeric: [ :not_a_number, {} ],
          pattern: [ :invalid, {} ],
          one_of: [ :inclusion, {} ],
          none_of: [ :exclusion, {} ],
          confirms: [ :confirmation, {} ]
        }.freeze

        def initialize(record:, attribute:, model_class:, rules:)
          @record = record
          @attribute = attribute
          @model_class = model_class
          @rules = rules
        end

        def call
          messages = {}
          rules.each_key do |key|
            error_key, shape = ERROR_KEYS[key]
            next unless error_key

            message = generated(error_key, shape[:count] ? { count: rules[key] } : {})
            messages[key] = message if message
          end
          messages[:parity] = generated(rules[:parity], {}) if rules[:parity]
          type_message = type_message_for(rules[:type])
          messages[:type] = type_message if type_message
          messages.freeze
        end

        private

        attr_reader :record, :attribute, :model_class, :rules

        def generated(error_key, options)
          return nil unless record.respond_to?(:errors)

          errors = record.errors
          return nil unless errors.respond_to?(:generate_message) && errors.respond_to?(:full_message)

          options = options.merge(attribute: human_attribute_name("#{attribute}_confirmation")) if error_key == :confirmation
          errors.full_message(attribute, errors.generate_message(attribute, error_key, options))
        rescue StandardError
          nil
        end

        def type_message_for(type)
          return nil unless type

          I18n.t("krudmin_ai.validation.#{type}", attribute: human_attribute_name(attribute), default: nil)
        rescue StandardError
          nil
        end

        def human_attribute_name(name)
          return name.to_s.tr("_", " ").capitalize unless model_class.respond_to?(:human_attribute_name)

          model_class.human_attribute_name(name)
        rescue StandardError
          name.to_s.tr("_", " ").capitalize
        end
      end
    end
  end
end
