require "json"
require "krudmin_ai/version"

module KrudminAI
  module Generators
    class HostManifest
      PATH = "docs/krudmin_ai/capability_registry.json".freeze

      def initialize(writer)
        @writer = writer
      end

      def install
        write(deep_merge(default_manifest, read_existing))
      end

      def enable(module_name)
        manifest = read
        manifest["enabled_modules"] = (manifest.fetch("enabled_modules", []) + [module_name]).uniq.sort
        write(manifest)
      end

      private

      attr_reader :writer

      def read
        path = File.join(writer.destination_root, PATH)
        return default_manifest unless File.exist?(path)

        JSON.parse(File.read(path))
      rescue JSON::ParserError
        default_manifest
      end

      def write(manifest)
        writer.write(PATH, JSON.pretty_generate(manifest) + "\n")
      end

      def read_existing
        path = File.join(writer.destination_root, PATH)
        return {} unless File.exist?(path)

        JSON.parse(File.read(path))
      rescue JSON::ParserError
        {}
      end

      def deep_merge(defaults, existing)
        defaults.merge(existing) do |_key, default_value, existing_value|
          default_value.is_a?(Hash) && existing_value.is_a?(Hash) ? deep_merge(default_value, existing_value) : existing_value
        end
      end

      def default_manifest
        {
          "schema_version" => 1,
          "engine" => "KrudminAI",
          "generated_by" => "KrudminAI generators",
          "release" => { "engine_version" => KrudminAI::VERSION, "host_release" => nil },
          "enabled_modules" => [],
          "provider_bindings" => {
            "authentication" => nil,
            "tenant" => nil,
            "authorization" => nil,
            "audit" => nil,
            "notification" => nil
          },
          "feature_flags" => {}
        }
      end
    end
  end
end