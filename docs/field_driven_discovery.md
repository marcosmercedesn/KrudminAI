# Field-Driven Discovery

Resources opt into discovery through `filter_field :attribute`. The declaration obtains its type, allowed operators, and select options from the resource-owned field adapter. It does not accept a client-supplied database column or arbitrary operator.

Supported adapter metadata:

- Text fields support contains, exact, prefix, and suffix matching; LIKE input is escaped.
- Enum, boolean, and belongs-to fields use constrained select values.
- Numeric, date, and datetime fields use optional inclusive `from` and `to` bounds.

Every request builds its relation in this order: tenant scope, policy scope, provider scope, archive visibility, eager loading, declared filters, declared sort, then bounded pagination. Unknown filter names, unrecognized sort fields, malformed operators, and unsupported structured keys are ignored before reaching the relation.

Sortable list headers toggle a declared field between ascending and descending order. Pagination retains current discovery parameters; Reset returns to the resource collection without filters, sort, archive selection, or pagination state.

Saved searches and views are deliberately not persisted in this release. Persisting them would require an owner/tenant authorization model, protected filter serialization, and audit behavior; those requirements have not been introduced, so this feature does not store potentially sensitive discovery state.
