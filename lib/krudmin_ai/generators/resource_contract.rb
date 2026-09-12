require "krudmin_ai/generators/file_writer"

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
        writer.create("spec/requests/#{namespace}/#{plural_file_name}_spec.rb", request_spec)
        writer.replace_managed_block("config/routes.rb", marker: "KRUDMIN_AI_#{plural_constant_name.upcase}_ROUTES", contents: routes)
      end

      private

      attr_reader :writer, :name, :namespace

      def singular_file_name
        name.gsub(/([a-z\d])([A-Z])/, "\\1_\\2").downcase
      end

      def plural_file_name
        "#{singular_file_name}s"
      end

      def singular_constant_name
        name.split("_").map(&:capitalize).join
      end

      def plural_constant_name
        "#{singular_constant_name}s"
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
          module #{namespace.capitalize}
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

      def request_spec
        <<~RUBY
          require "rails_helper"

          RSpec.describe "#{namespace}/#{plural_file_name}", type: :request do
            it "requires authentication" do
              get #{namespace}_#{plural_file_name}_path
              expect(response).to have_http_status(:unauthorized)
            end
          end
        RUBY
      end

      def routes
        <<~RUBY.rstrip
          namespace :#{namespace} do
            resources :#{plural_file_name}
          end
        RUBY
      end
    end
  end
end