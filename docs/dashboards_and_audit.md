# Dashboards and Audit

Dashboard widgets receive a resource and relation but always execute through the resource query pipeline. Count, summary, table, and chart widgets therefore retain tenant scope, policy scope, provider scope, filters, sort, and pagination. Table values use resource adapters and remove unreadable fields. Drill-down filters are limited to declared resource filters.

`KrudminAI::Audit::ActiveRecordStore` is the reference durable audit provider. Its model requires `event_type`, `actor_identifier`, `tenant`, `operation`, `record_type`, `record_identifier`, `metadata`, and timestamps. Searches apply tenant scope first, then an optional host policy scope, operation/record-type filters, and descending chronology. Product-facing presentation recursively redacts password, token, secret, and masked-id metadata keys.

The store is compatible with `MutationPipeline#record` and preserves that pipeline's transaction rollback behavior when audit persistence raises. Hosts own audit retention duration and policy scope, which must deny by default.

P13 owns consolidated browser/accessibility proof for dashboard rendering, drill-down navigation, and activity history.
