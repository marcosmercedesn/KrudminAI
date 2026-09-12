require "krudmin_ai/generators/file_writer"
require "krudmin_ai/generators/host_manifest"
require "active_support/core_ext/string/inflections"

module KrudminAI
  module Generators
    class ResourceContract
      def initialize(destination_root:, name:, namespace: "admin")
        @writer = FileWriter.new(destination_root)
        @name = name
        @namespace = namespace
      end

      def install
        writer.create("app/resources/#{plural_file_name}_resource.rb", resource)
        writer.create("app/controllers/#{namespace}/#{plural_file_name}_controller.rb", controller)
        writer.create("app/policies/#{singular_file_name}_policy.rb", policy)
        writer.create("test/integration/#{namespace}/#{plural_file_name}_test.rb", request_test)
        writer.replace_managed_block("config/routes.rb", marker: "KRUDMIN_AI_#{plural_constant_name.upcase}_ROUTES", contents: routes, inside_routes: true)
        manifest.enable("resources")
      end

      private

      attr_reader :writer, :name, :namespace

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
            permit

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
              post "actions/:action_name", on: :member, to: "#{plural_file_name}#perform_action", as: :action
            end
          end
        RUBY
      end
    end
  end
end