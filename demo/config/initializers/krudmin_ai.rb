require Rails.root.join("app/services/demo_krudmin_ai_providers")
require Rails.root.join("app/services/demo_audit_sink")

KrudminAI.configure do |config|
  config.authentication_provider = DemoAuthenticationProvider.new
  config.authorization_provider = DemoAuthorizationProvider.new
  config.tenant_provider = DemoTenantProvider.new
  config.audit_provider = DemoAuditSink.new
  config.notification_provider = DemoNotificationProvider.new
end
