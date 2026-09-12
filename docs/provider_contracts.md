# Provider Contracts

KrudminAI will define adapters for authentication, authorization, tenant resolution, audit logging, and notifications. Custom adapters require contract tests.

Authentication identifies the current operator or fails closed. Authorization provides resource and action predicates plus a relation-level policy scope, and denies when no decision is supplied. Tenant resolution identifies a tenant before resource access; missing or ambiguous tenancy fails closed. Audit logging records sensitive actions without masked fields. Notification failures are observable and never authorize an operation.

Concrete signatures are deferred to the core resource-contract slice so executable tests, rather than prose alone, establish the API.