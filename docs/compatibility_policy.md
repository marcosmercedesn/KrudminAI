# Compatibility Policy

KrudminAI supports the current stable Rails series and the immediately preceding supported Rails series where their supported Ruby ranges overlap. The gem dependency permits the current and preview Rails major generations; CI, rather than a single pinned version, establishes the verified support window.

The minimum Ruby lane is the oldest Ruby release supported by the oldest supported Rails lane. Stable tracks the project default. Latest tracks the newest generally available Ruby and Rails releases. Preview tracks upstream development releases and may fail without blocking releases.

Rails 8.1.3 and Ruby 4 are required compatibility targets during the initial release cycle. KrudminAI follows Semantic Versioning. Deprecated APIs emit actionable warnings for at least one minor release and document their replacement path before removal, except when security requires earlier removal.

Rails 8.1 requires ERB below 6 because its template handler currently depends on a constant removed in ERB 6. Rails 8.1.3 also requires JSON below 3 because its session and CSRF cookie decoding path invokes `JSON.parse` with the JSON 2.x interface. These are temporary compatibility constraints, tested in every required lane and removed when the Rails support window no longer needs them.