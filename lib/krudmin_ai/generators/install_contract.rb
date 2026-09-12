require "json"
require "krudmin_ai/generators/file_writer"
require "krudmin_ai/generators/host_manifest"

module KrudminAI
  module Generators
    class InstallContract
      DOCS_MARKER = "KRUDMIN_AI_GENERATED_INSTRUCTIONS".freeze
      IMPORTMAP_MARKER = "KRUDMIN_AI_IMPORTMAP".freeze

      def initialize(destination_root:, template_root:)
        @writer = FileWriter.new(destination_root)
        @template_root = template_root
      end

      def install
        writer.create("config/initializers/krudmin_ai.rb", initializer)
        sync_importmap
        sync_docs
        writer.create("app/resources/.keep", "# Generated resources live here.\n")
        manifest.enable("install")
      end

      def sync_docs
        writer.replace_managed_block("AGENTS.md", marker: DOCS_MARKER, contents: template("host_app/AGENTS.md"))
        writer.write("docs/krudmin_ai/README.md", template("docs/README.md"))
        writer.write("docs/krudmin_ai/architecture.md", template("docs/architecture.md"))
        writer.write("docs/krudmin_ai/provider_contracts.md", template("docs/provider_contracts.md"))
        manifest.install
      end

      def sync_importmap
        writer.replace_managed_block("config/importmap.rb", marker: IMPORTMAP_MARKER, contents: importmap)
      end

      private

      attr_reader :writer, :template_root

      def manifest
        @manifest ||= HostManifest.new(writer)
      end

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

      def importmap
        <<~RUBY
          pin "krudmin_ai", to: "krudmin_ai/index.js"
          pin "krudmin_ai/controllers/filter_panel_controller", to: "krudmin_ai/controllers/filter_panel_controller.js"
          pin "krudmin_ai/controllers/navigation_controller", to: "krudmin_ai/controllers/navigation_controller.js"
          pin "krudmin_ai/controllers/nested_fields_controller", to: "krudmin_ai/controllers/nested_fields_controller.js"
          pin "krudmin_ai/controllers/theme_controller", to: "krudmin_ai/controllers/theme_controller.js"
          pin "krudmin_ai/theme_mode", to: "krudmin_ai/theme_mode.js"
        RUBY
      end

    end
  end
end