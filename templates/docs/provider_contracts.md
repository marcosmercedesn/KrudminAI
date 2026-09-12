# Provider Contracts

Configure authentication, tenant, authorization, audit, and notification provider objects in `config/initializers/krudmin_ai.rb`. The host fails during boot if any provider is missing or lacks its required methods.

- `authenticate(controller:)` returns an actor or `nil`.
- `resolve(controller:, actor:)` returns one tenant or `nil`.
- `scope(relation:, resource:, context:)` returns a restricted relation; `authorize?(action:, record:, resource:, context:)` returns `true` only when allowed.
- `record(event)` persists audit events.
- `deliver(notification:)` accepts a notification without changing authorization.

Use encrypted, `httponly`, same-site session cookies, production HTTPS, CSRF protection, restrictive headers, and Rails parameter filtering. Never resolve tenancy from an unverified browser parameter. See the engine's `docs/provider_contracts.md` for the complete security baseline and adapter conformance requirements.