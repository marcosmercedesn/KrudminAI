module KrudminAI
  class NavigationGroup
    attr_reader :label, :icon, :visibility, :active, :items

    def initialize(label:, icon: :folder, visible: nil, active: nil)
      @label = label
      @icon = icon.to_sym
      @visibility = visible || ->(_context) { true }
      @active = active
      @items = []
    end

    def navigation_item(label: nil, route:, icon: nil, resource: nil, visible: nil, active: nil)
      items << NavigationItem.new(label:, route:, icon:, resource:, visible:, active:)
    end

    def visible?(context)
      visibility.call(context) == true && visible_items(context).any?
    rescue StandardError
      false
    end

    def visible_items(context)
      items.select { |item| item.visible?(context) }
    end

    def active?(view_context)
      return active.call(view_context) == true if active.respond_to?(:call)

      items.any? { |item| item.active?(view_context) }
    rescue StandardError
      false
    end
  end
end