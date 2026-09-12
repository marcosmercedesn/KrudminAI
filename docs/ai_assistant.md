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