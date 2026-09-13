# Local Belongs-To Field Adapter

P4 provides a `:belongs_to` adapter for small association collections. A declaration names the foreign-key attribute, the associated record method, a target resource, a display attribute, and an explicit label-read decision:

```ruby
field :rank_id, :belongs_to,
  resource: RanksResource,
  association: :rank,
  label: :name,
  label_read: ->(rank, context) { RankPolicy.new(context.actor, rank).show? },
  link: ->(rank, _context) { "/admin/ranks/#{rank.id}" }
```

The target resource must define its normal model, tenant scope, policy scope, and query ordering contract. The adapter uses that resource's `QueryAccessPipeline` for rendered options and submitted IDs, including the configured authorization provider. A target is rendered only when `label_read` returns exactly `true`; labels are never derived from a record that the actor cannot read. `link:` is optional and only renders for a label-readable target.

Submitted nonblank IDs resolve through the same protected target relation before assignment. Cross-tenant, policy-excluded, missing, or label-denied values fail as forbidden before persistence and before an audit event is written. Blank selection is supported by default and can be disabled with `include_blank: false`.

The adapter exposes select filter metadata. P7 owns the filter control and protected association-query behavior. P13 owns final independent browser and accessibility evidence.