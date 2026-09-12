KrudminAI.configure do |config|
  config.authentication_provider = ->(controller) { DemoUser.find_by(id: controller.session[:demo_user_id]) }
  config.tenant_provider = ->(controller) { DemoUser.find_by(id: controller.session[:demo_user_id])&.tenant }
  config.audit_provider = -> { DemoAuditSink.new }
end