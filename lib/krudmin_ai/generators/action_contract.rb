require "active_support/core_ext/string/inflections"
require "krudmin_ai/generators/file_writer"
require "krudmin_ai/generators/host_manifest"

module KrudminAI
  module Generators
    class ActionContract
      def initialize(destination_root:, name:, resource:)
        @writer = FileWriter.new(destination_root)
        @name = name.underscore
        @resource = resource.underscore.pluralize
      end

      def install
        writer.create(action_path, declaration)
        writer.replace_managed_block(resource_path, marker:, contents: "require_relative \"#{action_require_path}\"")
        manifest.enable("resource_actions")
      end

      private

      attr_reader :writer, :name, :resource

      def manifest
        @manifest ||= HostManifest.new(writer)
      end

      def resource_path
        "app/resources/#{resource}_resource.rb"
      end

      def marker
        "KRUDMIN_AI_#{resource.upcase}_#{name.upcase}_ACTION_REQUIRE"
      end

      def action_path
        "app/resources/#{resource}_resource_actions/#{name}.rb"
      end

      def action_require_path
        "#{resource}_resource_actions/#{name}"
      end

      def declaration
        <<~RUBY.rstrip
          class #{resource.camelize}Resource
            authorize(:#{name}) { |_record, _context| false }
            action :#{name}, label: "#{name.humanize}", writes: [] do |_record, _context|
              false
            end
          end
        RUBY
      end
    end
  end
end