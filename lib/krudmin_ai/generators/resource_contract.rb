require "krudmin_ai/generators/file_writer"
require "krudmin_ai/generators/host_manifest"
require "active_support/core_ext/string/inflections"

module KrudminAI
  module Generators
    class ResourceContract
      SUPPORTED_FIELD_TYPES = %w[string text email number decimal currency percentage boolean date time datetime json enum identifier password hidden].freeze

      def initialize(destination_root:, name:, namespace: "admin", fields: [], associations: [], workflows: [])
        @writer = FileWriter.new(destination_root)
        @name = name
        @namespace = namespace
        @fields = parse_fields(fields)
        @associations = parse_associations(associations)
        @workflows = parse_workflows(workflows)
      end

      def install
        writer.create("app/resources/#{plural_file_name}_resource.rb", resource)
        writer.create("app/controllers/#{namespace}/#{plural_file_name}_controller.rb", controller)
        writer.create("app/policies/#{singular_file_name}_policy.rb", policy)
        writer.create("test/integration/#{namespace}/#{plural_file_name}_test.rb", request_test)
        writer.replace_managed_block("config/routes.rb", marker: "KRUDMIN_AI_#{plural_constant_name.upcase}_ROUTES", contents: routes, inside_routes: true)
        writer.replace_managed_block("config/initializers/krudmin_ai_navigation.rb", marker: "KRUDMIN_AI_#{plural_constant_name.upcase}_NAVIGATION", contents: navigation)
        manifest.enable("resources")
      end

      private

      attr_reader :writer, :name, :namespace, :fields, :associations, :workflows

      def manifest
        @manifest ||= HostManifest.new(writer)
      end

      def singular_file_name
        name.underscore
      end

      def plural_file_name
        singular_file_name.pluralize
      end

      def singular_constant_name
        name.camelize
      end

      def plural_constant_name
        singular_constant_name.pluralize
      end

      def resource
        <<~RUBY
          class #{plural_constant_name}Resource < KrudminAI::Resources::Base
            model #{singular_constant_name}
            routes :#{plural_file_name}
            icon :file_text
            tenant_key :tenant
            label "#{singular_constant_name}"
            plural_label "#{plural_constant_name}"
            permit #{fields.map { |field| ":#{field[:name]}" }.join(", ")}
            #{fields.map { |field| "field :#{field[:name]}, :#{field[:type]}" }.join("\n    ")}
            #{fields.empty? ? "" : "form #{fields.map { |field| ":#{field[:name]}" }.join(", ")}\n    list #{fields.map { |field| ":#{field[:name]}" }.join(", ")}\n    show #{fields.map { |field| ":#{field[:name]}" }.join(", ")}\n    #{fields.map { |field| "authorize_field :#{field[:name]}, read: ->(_record, _context) { true }, write: ->(_record, _context) { true }" }.join("\n    ")}"}
            #{association_declarations}
            #{workflow_declarations}

            tenant_scope { |relation, context| relation.where(tenant: context.tenant) }
            policy_scope { |relation, context| #{singular_constant_name}Policy::Scope.new(context.actor, relation).resolve }
            tenant_record { |record, context| record.tenant == context.tenant }

            authorize(:create) { |record, context| #{singular_constant_name}Policy.new(context.actor, record).create? }
            authorize(:update) { |record, context| #{singular_constant_name}Policy.new(context.actor, record).update? }
            authorize(:destroy) { |record, context| #{singular_constant_name}Policy.new(context.actor, record).destroy? }

            sortable :created_at
            default_sort_by :created_at, direction: :desc
          end
        RUBY
      end

      def parse_fields(values)
        Array(values).map do |value|
          name, type = value.to_s.split(":", 2)
          raise ArgumentError, "Fields must use name:type" if name.to_s.empty? || type.to_s.empty?
          raise ArgumentError, "Unsupported field type: #{type}" unless SUPPORTED_FIELD_TYPES.include?(type)

          { name: name.underscore.to_sym, type: type.to_sym }
        end
      end

      def parse_associations(values)
        Array(values).map do |value|
          name, cardinality, fields = value.to_s.split(":", 3)
          raise ArgumentError, "Associations must use name:has_many:field,field or name:has_one:field" if name.to_s.empty? || fields.to_s.empty? || !%w[has_many has_one].include?(cardinality)

          { name: name.underscore.to_sym, cardinality: cardinality.to_sym, fields: fields.split(",").map { |field| field.strip.underscore.to_sym }.reject(&:empty?) }
        end
      end

      def parse_workflows(values)
        Array(values).map do |value|
          name, from, to = value.to_s.split(":", 3)
          raise ArgumentError, "Workflows must use name:from:to" if name.to_s.empty? || from.to_s.empty? || to.to_s.empty?

          { name: name.underscore.to_sym, from: from, to: to }
        end
      end

      def association_declarations
        associations.map do |association|
          "#{association[:cardinality]} :#{association[:name]}, fields: #{association[:fields].inspect}, authorize: ->(_record, _action, _context) { false }, tenant_record: ->(_record, _context) { false }"
        end.join("\n    ")
      end

      def workflow_declarations
        workflows.map do |workflow|
          "authorize(:#{workflow[:name]}) { |_record, _context| false }\n    transition :#{workflow[:name]}, from: :#{workflow[:from]}, to: :#{workflow[:to]}"
        end.join("\n    ")
      end

      def controller
        <<~RUBY
          module #{namespace.camelize}
            class #{plural_constant_name}Controller < KrudminAI::ResourceController
              resource #{plural_constant_name}Resource
            end
          end
        RUBY
      end

      def policy
        <<~RUBY
          class #{singular_constant_name}Policy < ApplicationPolicy
            def create? = false
            def update? = false
            def destroy? = false

            class Scope < ApplicationPolicy::Scope
              def resolve
                scope.none
              end
            end
          end
        RUBY
      end

      def request_test
        <<~RUBY
          require "test_helper"

          class #{namespace.camelize}::#{plural_constant_name}Test < ActionDispatch::IntegrationTest
            test "requires authentication" do
              get #{namespace}_#{plural_file_name}_path
              assert_response :redirect
            end
          end
        RUBY
      end

      def routes
        <<~RUBY.rstrip
          namespace :#{namespace} do
            resources :#{plural_file_name} do
              get "exports/:profile", on: :collection, to: "#{plural_file_name}#export", as: :export
              post "imports/:profile/preview", on: :collection, to: "#{plural_file_name}#import_preview", as: :import_preview
              post "imports/:profile", on: :collection, to: "#{plural_file_name}#import_commit", as: :import
              get "lookups/:field_name", on: :collection, to: "#{plural_file_name}#lookup_field", as: :lookup_field
              post "actions/:action_name", on: :member, to: "#{plural_file_name}#perform_action", as: :action
              post "bulk_actions/:action_name", on: :collection, to: "#{plural_file_name}#perform_bulk_action", as: :bulk_action
            end
          end
        RUBY
      end

      def navigation
        <<~RUBY.rstrip
          KrudminAI.configure do |config|
            config.navigation_item(
              resource: "#{plural_constant_name}Resource",
              route: :#{namespace}_#{plural_file_name}_path,
              visible: ->(context) do
                resource = "#{plural_constant_name}Resource".constantize
                config.authorization_provider.authorize?(
                  action: :index,
                  record: resource.model_class,
                  resource:,
                  context:
                ) == true
              end
            )
          end
        RUBY
      end
    end
  end
end
