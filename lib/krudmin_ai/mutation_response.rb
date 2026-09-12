module KrudminAI
  MutationResponse = Data.define(:format, :status, :payload)

  class MutationResponseAdapter
    STATUS_CODES = {
      success: 200,
      unauthenticated: 401,
      tenant_required: 403,
      forbidden: 403,
      invalid: 422,
      configuration_error: 500,
      audit_failed: 500,
      persistence_failed: 500
    }.freeze

    def self.for(result, format:)
      new(result, format).response
    end

    def initialize(result, format)
      @result = result
      @format = format.to_sym
    end

    def response
      raise ArgumentError, "Unsupported response format: #{format}" unless %i[html json turbo_stream].include?(format)

      MutationResponse.new(format, status, payload)
    end

    private

    attr_reader :result, :format

    def status
      return 201 if result.success? && result.operation == :create && format == :json
      return 303 if result.success? && format == :html

      STATUS_CODES.fetch(result.outcome)
    end

    def payload
      case format
      when :html then html_payload
      when :json then { data: result.record, errors: result.errors, outcome: result.outcome }
      when :turbo_stream then { template: template, errors: result.errors, outcome: result.outcome }
      end
    end

    def html_payload
      return { redirect: :collection, notice: "#{result.operation} succeeded" } if result.success?

      { template: result.operation == :create ? :new : :edit, errors: result.errors }
    end

    def template
      suffix = result.success? ? "success" : "error"
      "krudmin_ai/mutations/#{result.operation}_#{suffix}"
    end
  end
end