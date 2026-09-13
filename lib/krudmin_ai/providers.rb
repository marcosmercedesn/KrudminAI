module KrudminAI
  class ProviderConfigurationError < StandardError; end

  module Providers
    CONTRACTS = {
      authentication_provider: [ :authenticate ],
      authorization_provider: [ :scope, :authorize? ],
      tenant_provider: [ :resolve ],
      audit_provider: [ :record ],
      notification_provider: [ :deliver ]
    }.freeze

    def self.validate!(configuration)
      CONTRACTS.each do |name, methods|
        provider = configuration.public_send(name)
        raise ProviderConfigurationError, "#{name} must be configured" unless provider

        missing = methods.reject { |method| provider.respond_to?(method) }
        next if missing.empty?

        raise ProviderConfigurationError, "#{name} must respond to #{missing.join(', ')}"
      end

      true
    end

    module TestAdapters
      class Authentication
        def initialize(actor = nil)
          @actor = actor
        end

        def authenticate(controller:)
          @actor
        end
      end

      class Authorization
        def initialize(allowed: true)
          @allowed = allowed
        end

        def scope(relation:, resource:, context:)
          @allowed ? relation : nil
        end

        def authorize?(action:, record:, resource:, context:)
          @allowed
        end
      end

      class Tenant
        def initialize(tenant = nil)
          @tenant = tenant
        end

        def resolve(controller:, actor:)
          @tenant
        end
      end

      class Audit
        attr_reader :events

        def initialize
          @events = []
        end

        def record(event)
          events << event
        end
      end

      class Notification
        attr_reader :notifications

        def initialize
          @notifications = []
        end

        def deliver(notification:)
          notifications << notification
          true
        end
      end
    end
  end
end
