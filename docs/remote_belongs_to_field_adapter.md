# Remote Belongs-To Field Adapter

P5 provides `:remote_belongs_to` for large authorized associations without jQuery or Select2. It shares P4's explicit target resource, association, label, and `label_read` contracts, so both lookup results and submitted IDs resolve through the target resource's tenant, policy, and authorization-provider-scoped relation.

```ruby
field :recruiter_id, :remote_belongs_to,
  resource: RecruitersResource,
  association: :recruiter,
  label: :name,
  label_read: ->(recruiter, context) { RecruiterPolicy.new(context.actor, recruiter).show? },
  minimum_query_length: 2,
  per_page: 20
```

The resource generator adds `GET /admin/resources/lookups/:field_name`. It accepts `q` and a positive `page`, rejects non-remote fields, and returns only bounded `{ id, label }` entries whose label-read predicate returns exactly `true`. Result labels never expose target records outside tenant, policy, provider, or field-read boundaries. Submitted IDs use the same P4 validation path, so forged values fail before persistence and audit.

The generated Stimulus control uses a hidden canonical ID input plus a labelled search combobox. It debounces input, cancels superseded requests, exposes loading/no-result/error state through a live region, supports arrow navigation, Enter selection, Escape dismissal, selected-label restoration, and explicit next-page loading. P13 owns independent browser and accessibility consolidation.