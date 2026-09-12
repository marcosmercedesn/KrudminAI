# Compatibility Policy

KrudminAI supports Rails $[8.1, 10)$ on Ruby $[3.3, \infty)$. The gemspec is the installation contract; CI is the executable evidence for the supported portion of that contract. Rails 8.1.3 and Ruby 4 are mandatory initial-release targets.

The matrix resolves both the engine and demo host after setting `RAILS_VERSION`, then runs engine RSpec/lint/static showcase checks, demo integration tests, and the disposable generated-showcase host verifier in every lane.

| Lane | Ruby | Rails | Release effect |
| --- | --- | --- | --- |
| minimum | 3.3 | `~> 8.1.3` | Blocking |
| stable | 3.4 | `>= 8.1, < 10.0` | Blocking |
| latest | 4.0 | `>= 8.1, < 10.0` | Blocking |
| preview | `head` | `>= 9.0.a` | Non-blocking |

The browser suite runs separately on Ruby 4 with the default Rails 8.1.3 demo dependency. It is companion visual evidence, not compatibility proof for every lane.

KrudminAI follows Semantic Versioning. Deprecated APIs emit an actionable warning, name the replacement, and remain supported for at least one minor release before removal. A security fix may remove an API earlier; the release notes must describe the affected versions, migration, and mitigation.

Before a release, maintainers review blocking lane results, dependency-resolution changes, generator/disposable-host results, and deprecation warnings. A blocking-lane resolution or test failure stops release publication. Preview failures do not block a release, but require a tracked issue stating the upstream version, failure mode, owner, and next review date. A supported Rails or Ruby bound changes only in a release that updates this document, the gemspec, registry, and CI matrix together.

Rails 8.1 is verified only with ERB 4.x in this support window. Rails 8.1.3 also requires JSON below 3 because its session and CSRF cookie decoding path invokes `JSON.parse` with the JSON 2.x interface. These are temporary compatibility constraints, covered by the compatibility spec and dependency resolution in every blocking lane; remove them only once the supported Rails window no longer needs them.