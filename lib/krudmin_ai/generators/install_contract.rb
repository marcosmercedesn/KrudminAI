require "json"
require "krudmin_ai/generators/file_writer"

module KrudminAI
  module Generators
    class InstallContract
      DOCS_MARKER = "KRUDMIN_AI_GENERATED_INSTRUCTIONS".freeze

      def initialize(destination_root:, template_root:)
        @writer = FileWriter.new(destination_root)
        @template_root = template_root
      end

      def install
        writer.create("config/initializers/krudmin_ai.rb", initializer)
        sync_docs
        writer.create("app/resources/.keep", "# Generated resources live here.\n")
      end

      def sync_docs
        writer.replace_managed_block("AGENTS.md", marker: DOCS_MARKER, contents: template("host_app/AGENTS.md"))
        writer.write("docs/krudmin_ai/README.md", template("docs/README.md"))
        writer.write("docs/krudmin_ai/architecture.md", template("docs/architecture.md"))
        writer.write("docs/krudmin_ai/provider_contracts.md", template("docs/provider_contracts.md"))
        writer.write("docs/krudmin_ai/capability_registry.json", capability_registry)
      end

      private

      attr_reader :writer, :template_root

      def template(path)
        File.read(File.join(template_root, path))
      end

      def initializer
        <<~RUBY
          KrudminAI.configure do |config|
            # Every provider below is required. Missing or malformed adapters stop boot.
            # authenticate(controller:) -> actor or nil
            # resolve(controller:, actor:) -> tenant or nil
            # scope(relation:, resource:, context:) -> restricted relation or nil
            # authorize?(action:, record:, resource:, context:) -> true or false
            # record(event) and deliver(notification:) must be implemented by their adapters.
            # config.authentication_provider = HostAuthenticationProvider.new
            # config.tenant_provider = HostTenantProvider.new
            # config.authorization_provider = HostAuthorizationProvider.new
            # config.audit_provider = HostAuditProvider.new
            # config.notification_provider = HostNotificationProvider.new
            #
            # Register visible navigation using host route helpers. A resource supplies its
            # plural label and configured icon, while the visibility predicate receives the
            # same access context used by resource requests.
            # config.navigation_item resource: OrdersResource, route: :orders_path,
            #   visible: ->(context) { OrderPolicy.new(context.actor, Order).index? }
          end
        RUBY
      end

      def capability_registry
        JSON.pretty_generate(
          schema_version: 1,
          engine: "KrudminAI",
          generated_by: "install generator",
          capabilities: [],
          providers: {},
          feature_flags: {}
        ) + "\n"
      end
    end
  end
end