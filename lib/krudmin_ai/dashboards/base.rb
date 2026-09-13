module KrudminAI
  module Dashboards
    WidgetDefinition = Data.define(:name, :label, :widget_class, :resource, :relation, :visible, :query_params, :drill_down_filters, :options)
    WidgetResult = Data.define(:name, :label, :resource, :state, :value, :columns, :rows, :drill_down_params, :error)

    class Base
      class << self
        attr_reader :dashboard_label, :widget_definitions

        def inherited(subclass)
          super
          subclass.instance_variable_set(:@dashboard_label, dashboard_label)
          subclass.instance_variable_set(:@widget_definitions, widget_definitions.dup)
        end

        def label(value = nil)
          return dashboard_label unless value

          @dashboard_label = value.to_s
        end

        def widget(name, widget_class:, resource:, relation:, visible: nil, label: nil, query_params: {}, drill_down_filters: {}, **options)
          normalized_name = name.to_sym
          widget_definitions[normalized_name] = WidgetDefinition.new(
            normalized_name,
            label || normalized_name.to_s.tr("_", " ").capitalize,
            widget_class,
            resource,
            relation,
            visible,
            query_params.freeze,
            drill_down_filters.freeze,
            options.freeze
          )
        end
      end

      def initialize(context:, params: {})
        @context = context
        @params = params
      end

      def label
        self.class.label || self.class.name.demodulize
      end

      def render(loading: false)
        self.class.widget_definitions.values.filter_map do |definition|
          render_widget(definition, loading:)
        end
      end

      private

      attr_reader :context, :params

      def render_widget(definition, loading:)
        return unless visible?(definition)

        return WidgetResult.new(definition.name, definition.label, definition.resource, :loading, nil, [], [], drill_down_params(definition), nil) if loading

        widget = definition.widget_class.new(
          resource: definition.resource,
          context:,
          relation: definition.relation.call(context),
          params: merged_params(definition),
          **definition.options
        )
        result_for(definition, widget)
      rescue AuthorizationDenied, ScopeViolation
        nil
      rescue StandardError => error
        WidgetResult.new(definition.name, definition.label, definition.resource, :error, nil, [], [], drill_down_params(definition), error)
      end

      def result_for(definition, widget)
        if widget.is_a?(Widgets::Table)
          records = widget.records.to_a
          columns = records.flat_map { |record| widget.visible_columns(record) }.uniq
          rows = records.map do |record|
            widget.visible_columns(record).to_h { |field| [ field, widget.value_for(record, field) ] }
          end
          state = rows.empty? ? :empty : :ready
          WidgetResult.new(definition.name, definition.label, definition.resource, state, nil, columns, rows, drill_down_params(definition), nil)
        else
          value = widget.value
          state = value.respond_to?(:empty?) ? (value.empty? ? :empty : :ready) : (value == 0 ? :empty : :ready)
          WidgetResult.new(definition.name, definition.label, definition.resource, state, value, [], [], drill_down_params(definition), nil)
        end
      end

      def visible?(definition)
        definition.visible&.call(context) == true
      rescue StandardError
        false
      end

      def merged_params(definition)
        params.merge(definition.query_params) { |_key, request_value, widget_value| request_value.is_a?(Hash) && widget_value.is_a?(Hash) ? request_value.merge(widget_value) : widget_value }
      end

      def drill_down_params(definition)
        filters = definition.drill_down_filters.transform_keys(&:to_sym).slice(*definition.resource.filters.keys)
        filters.empty? ? {} : { filters: filters }
      end

      @dashboard_label = nil
      @widget_definitions = {}.freeze
    end
  end
end
