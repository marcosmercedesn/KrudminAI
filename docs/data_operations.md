# Data Operations

KrudminAI provides profile-driven CSV export and import processors for authenticated admin workflows. A resource must opt into each operation explicitly:

```ruby
export_profile :compliance_csv,
  fields: %i[id email salary],
  masks: { salary: ->(_value, _record, _context) { "[redacted]" } }

import_profile :contacts_csv,
  mapping: { "Email" => :email, "Name" => :name },
  required: [:email]

authorize(:export) { |record, context| ContactPolicy.new(context.actor, record).export? }
authorize(:import) { |record, context| ContactPolicy.new(context.actor, record).import? }
```

Exports start with the canonical tenant, resource-policy, provider-policy, archive, eager-load, filter, and sort pipeline. They deliberately do not use index pagination. An export profile is intersected with field read authorization for the current actor, then its optional callable masks run per output value. A requested profile with no readable columns is denied. The exporter creates a completion audit event only after CSV construction succeeds.

`Importer#preview` parses CSV with headers and returns every mapped row and its validation errors without persistence. It reports unknown columns, missing required headers, missing required values, and fields that are not writable for the current context. Import mappings may only target the resource's declared permitted attributes.

`Importer#commit` requires a non-empty idempotency key and performs every accepted row through `MutationPipeline#create`. Tenant checks, writer authorization, model validation, row-level audit events, and the enclosing import audit event therefore retain their normal semantics. For Active Record models, an audit or row failure rolls back the complete import. Retrying a completed key returns the stored `ImportResult` rather than writing again.

## Host Responsibilities

The current engine processors accept an idempotency store with `fetch(key)` and `record(key, result)`. That minimal interface is appropriate for synchronous development and test use only. Production background imports must supply a durable store that atomically claims a tenant-bound idempotency key before enqueueing or writing rows, records terminal success/failure states, and retains the uploaded source outside job arguments. A crash after database commit but before a separate `record` call can otherwise be retried as a duplicate import.

Hosts must establish CSV file-size, encoding, retention, and access-control limits; review fields for spreadsheet-formula injection before allowing spreadsheet consumers; and define explicit matching/upsert policy before adding update-capable imports. The supplied profiles are create-only and do not infer matching or overwrite behavior. Large imports should use a host-owned persisted operation and job, with retries restricted to transient failures after an atomic claim.

Do not use profiles to export arbitrary associations or to bypass field policy. Every compliance export needs an authorization predicate, audit retention policy, and an approved delivery path. Import and export telemetry emits redacted `import.completed` and `export.completed` events under the current request correlation ID.