module KrudminAI
  class NavigationItem
    attr_reader :label, :route, :resource, :visibility, :active

    def initialize(label: nil, route:, icon: nil, resource: nil, visible: nil, active: nil)
      raise ArgumentError, "A navigation route is required" unless route
      raise ArgumentError, "A label or resource is required" unless label || resource

      @label = label
      @route = route
      @icon = icon&.to_sym
      @resource = resource
      @visibility = visible || ->(_context) { true }
      @active = active
    end

    def display_label
      return label if label

      resource.model_class.model_name.human(count: 2)
    end

    def icon
      @icon || resource&.icon || :file_text
    end

    def visible?(context)
      visibility.call(context) == true
    rescue StandardError
      false
    end

    def path_for(view_context)
      return route.call(view_context) if route.respond_to?(:call)

      view_context.main_app.public_send(route)
    end

    def active?(view_context)
      return active.call(view_context) == true if active.respond_to?(:call)

      view_context.current_page?(path_for(view_context))
    rescue StandardError
      false
    end
  end
end
