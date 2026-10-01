require "krudmin_ai/fields/scalar"

module KrudminAI
  module Fields
    class StateMachine < Enum
      BADGE_VARIANTS = %i[default warning success info danger].freeze

      def initialize(resource:, attribute:, options: {})
        values = options[:states] || options[:values] || machine_states(resource.model_class, options)
        super(resource:, attribute:, options: options.merge(values: normalize_states(values)))
      end

      def form_control(form, writable:, **options)
        super(form, writable: writable && direct_write?, **options)
      end

      def parameter(value)
        raise ArgumentError, "#{attribute} must be changed through a declared transition" unless direct_write?

        super
      end

      def validation_projectable? = direct_write?

      def list_value(record) = label_for(value(record))
      alias show_value list_value

      def permitted_events(record)
        machine = machine_for(record)
        return [] unless machine.respond_to?(:events)

        machine.events(permitted: true).map { |event| event.respond_to?(:name) ? event.name.to_sym : event.to_sym }
      rescue StandardError
        []
      end

      def transition_label(event)
        options.fetch(:transition_labels, {}).transform_keys(&:to_sym).fetch(event.to_sym) do
          event.to_s.tr("_", " ").split.map(&:capitalize).join(" ")
        end
      end

      def badge_variant(record)
        configured = options.fetch(:colors, {}).transform_keys(&:to_sym)[value(record).to_s.to_sym]
        variant = configured&.to_sym
        BADGE_VARIANTS.include?(variant) ? variant : :default
      end

      def direct_write? = options.fetch(:allow_direct_write, false)

      private

      def machine_states(model_class, configuration)
        machine = machine_for(model_class, configuration)
        raise Resources::ConfigurationError, "State machine field #{attribute} requires states or a compatible model machine" unless machine.respond_to?(:states)

        machine.states.map { |state| state.respond_to?(:name) ? state.name : state }
      rescue NoMethodError
        raise Resources::ConfigurationError, "State machine field #{attribute} requires states or a compatible model machine"
      end

      def machine_for(owner, configuration = options)
        method_name = configuration.fetch(:machine_method, :aasm)
        machine_name = configuration.fetch(:machine, :default).to_sym
        arguments = machine_name == :default ? [] : [ machine_name ]
        owner.public_send(method_name, *arguments)
      end

      def normalize_states(states)
        return states.transform_values { |value| value.is_a?(Hash) ? value.fetch(:label, value.fetch("label", value.to_s.humanize)) : value } if states.is_a?(Hash)

        states
      end

      def label_for(state)
        option = send(:enum_options).find { |entry| (entry.is_a?(Array) ? entry.last : entry).to_s == state.to_s }
        option.is_a?(Array) ? option.first : state
      end
    end
  end
end