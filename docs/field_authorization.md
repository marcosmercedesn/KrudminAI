# Field Authorization

KrudminAI fields deny access by default. A resource must explicitly declare both decisions for every field that it presents, accepts, uses in AI context, or emits through a dashboard table.

```ruby
authorize_field :priority,
  read: ->(record, context) { context.roles.include?(:support_agent) || context.roles.include?(:manager) },
  write: ->(_record, context) { context.roles.include?(:manager) }
```

Both handlers receive the record and `AccessContext`. A missing handler, a false result, or an exception denies the decision.

Read-denied fields are absent from generic list, form, show, mutation JSON, AI context, and dashboard table column selection. Readable but write-denied form fields remain visible as disabled controls with an accessible explanation. The server independently validates every submitted scalar field and every declared nested `has_many` child field before assignment. A crafted denied field produces the normal `403` denial in HTML, JSON, and Turbo Stream responses; it does not persist or produce an audit event.

Nested field policies are declared with relationship metadata:

```ruby
has_many :passengers,
  fields: %i[name position],
  field_authorizers: {
    name: { read: ->(_record, _context) { true }, write: ->(_record, _context) { true } },
    position: { read: ->(_record, context) { context.roles.include?(:manager) }, write: ->(_record, context) { context.roles.include?(:manager) } }
  },
  # existing authorize and tenant_record declarations
```

The current engine has no export capability. When export selection is introduced, it must use `resource.readable_fields` for both selectable columns and serialized values; it must not read raw resource metadata directly.