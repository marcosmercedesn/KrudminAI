require "active_support/core_ext/string/inflections"
require "krudmin_ai/generators/file_writer"
require "krudmin_ai/generators/host_manifest"

module KrudminAI
  module Generators
    class DashboardContract
      def initialize(destination_root:, name:, resource:)
        @writer = FileWriter.new(destination_root)
        @name = name.underscore
        @resource = resource.underscore.pluralize
      end

      def install
        writer.create("app/dashboards/#{name}_dashboard.rb", dashboard)
        manifest.enable("dashboards")
      end

      private

      attr_reader :writer, :name, :resource

      def manifest
        @manifest ||= HostManifest.new(writer)
      end

      def dashboard
        <<~RUBY
          class #{name.camelize}Dashboard < KrudminAI::Dashboards::Base
            label "#{name.humanize}"

            widget :recent_#{resource},
              widget_class: KrudminAI::Dashboards::Widgets::Table,
              resource: #{resource.camelize}Resource,
              relation: ->(_context) { #{resource.classify}.all },
              visible: ->(_context) { false },
              icon: :table_2,
              color: :blue,
              columns: [],
              limit: 10
          end
        RUBY
      end
    end
  end
end
