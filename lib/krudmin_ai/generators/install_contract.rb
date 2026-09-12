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
            # Configure host authentication, tenancy, authorization, and auditing providers here.
            # Provider omissions fail closed for generated admin resources.
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