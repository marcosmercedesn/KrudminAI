# Scalar Field Adapters

P2 adds native-control adapters for text, email, password, hidden, number, decimal, currency, percentage, boolean, date, time, datetime, JSON, enum, and identifier fields. Resource declarations use `field :price, :currency, unit: "$", precision: 2` and enum declarations require an explicit `values:` collection, hash, or callable. An enum hash maps stored values to visible labels: `field :state, :enum, values: { "draft" => "Draft" }`. A blank enum is valid only with `allow_blank: true`.

Blank number, decimal, boolean, date, time, datetime, and JSON inputs normalize to `nil`. Dates accept ISO 8601 dates; times accept `HH:MM` or `HH:MM:SS` and normalize to `HH:MM:SS`; datetimes accept ISO 8601 values and parse in the configured adapter `time_zone` or `Time.zone`. List and detail datetimes display in that same zone with `%Y-%m-%d %H:%M` by default, while time values display with `%H:%M`; hosts can override either with `format:`. Hosts must configure the Rails application time zone deliberately.

Decimal, currency, and percentage values use `precision:` for display. Currency uses `unit:` (default `$`); identifiers inherit integer formatting and accept `prefix:` and `padding:`. JSON form values must parse as valid JSON; list, detail, and CSV values use compact JSON text, while JSON and AI preserve the parsed structured value. Password and hidden values never appear in list, detail, JSON, CSV, or AI adapter output.

Applicable scalar adapters expose typed filter metadata, but do not apply filters themselves. P7 owns the protected query and accessible control behavior for text, enum, boolean, numeric, date, and datetime filters. P13 owns independent browser/accessibility proof once the field, discovery, and presentation contracts are complete.

This P2 slice has engine-level coverage only. Parameter normalization must be integrated into the mutation pipeline and generated-host evidence must cover every scalar adapter before P2 is complete.