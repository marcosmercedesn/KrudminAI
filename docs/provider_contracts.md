# Provider Contracts

Every KrudminAI host must configure five provider objects before its protected resources can boot. `KrudminAI.config.validate_providers!` runs after Rails initialization and raises `KrudminAI::ProviderConfigurationError` for absent or malformed adapters. Do not use lambdas: named provider objects make the security boundary testable.

```ruby
KrudminAI.configure do |config|
	config.authentication_provider = HostAuthenticationProvider.new
	config.tenant_provider = HostTenantProvider.new
	config.authorization_provider = HostAuthorizationProvider.new
	config.audit_provider = HostAuditProvider.new
	config.notification_provider = HostNotificationProvider.new
end
```

## Interfaces

| Provider | Required methods | Safe result |
| --- | --- | --- |
| Authentication | `authenticate(controller:)` | Authenticated actor, or `nil` to deny. |
| Tenant | `resolve(controller:, actor:)` | One tenant, or `nil` to deny. |
| Authorization | `scope(relation:, resource:, context:)`, `authorize?(action:, record:, resource:, context:)` | A further-restricted relation and `true`. |
| Audit | `record(event)` | Records the event or raises; mutation handling stops safely. |
| Notification | `deliver(notification:)` | `true` only after accepted delivery. Never use it to authorize. |

Authentication, tenant, and authorization exceptions fail closed. A `nil` actor, tenant, scope, or authorization decision is a denial. Authorization is composed with resource policy predicates; it cannot make a resource action available when the resource policy denies it. Providers must neither expose a broader tenant relation nor bypass the required tenant then policy scope order.

`KrudminAI::Providers::TestAdapters` supplies deterministic adapters for unit and host conformance tests. Each custom adapter should test valid output, `nil`/`false`, malformed interface, and raised exception behavior.

## Host Security Baseline

Generated resources require `ActionController::Base` CSRF protection. Do not disable request forgery protection for admin controllers. Use encrypted, `httponly`, `same_site: :lax` (or stricter), and production `secure: true` session cookies; set an explicit idle timeout and force reauthentication after it. Account recovery and future MFA enrollment must revoke or rotate active sessions.

Production hosts must enforce HTTPS, HSTS, `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, a restrictive `Content-Security-Policy`, and clickjacking protection (`frame-ancestors 'none'` or an approved allowlist). Configure Rails parameter filtering for passwords, tokens, credentials, OTP values, session identifiers, government identifiers, and payment data. Do not render those values in admin UI, audit metadata, notifications, logs, AI prompts, or exports without a field-level authorization and redaction policy.

Tenant resolution must come from a verified authenticated identity or trusted server-side request context, never from a browser-supplied tenant parameter, subdomain, or header without host verification. Super-admin access is opt-in: it needs an explicit resource policy, a requested and authorized target tenant, and an audit event naming both the actor tenant and target tenant. A missing, ambiguous, or exception-producing tenant decision denies access.

Provider documentation and companion tests are not independent generated-host proof. The provider/security beta exit evidence is assigned in [beta_release_decision.md](beta_release_decision.md).