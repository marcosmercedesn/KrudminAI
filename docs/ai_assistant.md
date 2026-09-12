# In-App AI Assistant

The assistant supports four authenticated, read-only tasks: `record_summary`, `record_q_and_a`, `document_summary`, and `report_insight`. It receives an `AccessContext`, a resource, and a base relation. The assistant builds provider context only after the same tenant and policy scopes used by the standard UI have completed.

Resources must declare fields that AI may receive. Fields not declared with `ai_field` are omitted from provider context. Field serializers may redact or transform values before they are sent.

```ruby
class OrdersResource < KrudminAI::Resources::Base
  ai_field :number
  ai_field(:customer_email) { |order| order.customer_email.sub(/\A[^@]+/, "[redacted]") }
end
```

Every request records a trace with the actor, prompt template, provider name, scoped-context fingerprint, output, action references, and status. Providers may request only the four read-only tools. A mutation-capable request requires an explicit approval policy and remains a proposal until a future approved execution pipeline handles it.

The `krudmin_ai/ai/assistant` partial provides a Turbo-compatible task selector and prompt form. Host controllers must build the assistant with the current authenticated context, a provider adapter, a trace sink, and the resource relation.

## Production Providers And Traces

`KrudminAI::Ai::ProviderRouter` routes each declared task to a named provider client. Its configuration is an explicit task map, such as `{ record_summary: { name: "primary", client: } }`; a missing or malformed route raises `ProviderUnavailable`. The assistant maps provider exceptions to a safe `provider_failed` result and records a failure trace without exposing provider exception text.

The four V1 tasks stay read-only. A provider-returned tool call is validated by `ToolRouter` after scoped context creation. Only the V1 read-only tool names are accepted. A mutation tool requires an explicit approval policy and remains a proposal; this package does not execute it. Provider output, prompts, tool arguments, and exception messages must never be used as authority or treated as a request to bypass this policy.

`InMemoryTraceStore` is a development/test reference for retained traces. Use `recorder_for(access_context)` as the assistant tracer. It binds each trace to the current tenant, replaces retained output with `[redacted]` by default, supports tenant-scoped `search`, and returns tenant-scoped safe metadata through `export`. Search is limited to prompt-template, provider, and status metadata; it does not search raw output. A host can provide an explicit output redactor only after its retention, access-control, and compliance policy approves the derived retained value.

Production hosts must implement a durable trace store with the same tenant boundary and an authenticated trace search/export controller. They must persist queued/running/completed/failed operation state before enqueueing any Active Job, retain source material outside job arguments, and render accessible Turbo progress and fallback/error states. The engine does not yet ship that durable operation store or a background provider job, so the companion's synchronous form is not production asynchronous-delivery evidence.

## V1.1 Review Drafts

`ReviewableExtraction` builds context only through the resource's tenant, policy, and `ai_field` rules. It returns a `ReviewDraft` containing provider-proposed attributes, field evidence, and a scoped-context fingerprint with status `pending_review`. It does not write the draft to a resource. Hosts must display field evidence, obtain a reviewer confirmation, apply normal field authorization, and use `MutationPipeline` for any eventual write.

`MultiSourceContextBuilder` composes named sources by running each resource/relation pair through the same scoped context builder. `MultiSourceAnalysis` accepts only `cross_record_analysis` and `dashboard_narrative`; it passes the named scoped context to a provider in `read_only` mode and rejects every tool call that is not in the read-only allowlist. `PromptTemplates` registers named instructions bound to one task, preventing a template intended for one workflow from being substituted into another.

## V2 Approved Automation

`ApprovedAutomation` is an execution boundary, not an autonomous agent. It requires an approval policy that returns exactly `true`, records an actor/roles/tenant/source-fingerprint trace before any write, resolves the target only through the canonical authorized relation, then delegates the approved operation and attributes to `MutationPipeline`. A rejected approval or out-of-scope target returns no mutation result; the trace records `approval_required` or `forbidden` without disclosing another tenant's record.

Hosts must keep proposal generation, reviewer approval, and execution as separately authenticated steps. The engine does not supply a durable proposal store, escalation workflow, retry/outbox, or guided-workflow UI. Never accept an identifier, operation, or attributes directly from provider output without binding it to a reviewed proposal and passing it through `ApprovedAutomation`.