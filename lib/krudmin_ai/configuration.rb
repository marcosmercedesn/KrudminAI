require "krudmin_ai/navigation_item"

module KrudminAI
  class Configuration
    attr_accessor :authentication_provider, :authorization_provider, :tenant_provider, :audit_provider,
      :notification_provider, :observability_logger, :metrics_provider, :tracing_provider,
      :operation_store, :ai_trace_store

    def validate_providers!
      Providers.validate!(self)
    end

    def navigation_item(label: nil, route:, icon: nil, resource: nil, visible: nil, active: nil)
      navigation_items << NavigationItem.new(label:, route:, icon:, resource:, visible:, active:)
    end

    def navigation_items
      @navigation_items ||= []
    end
  end
end
