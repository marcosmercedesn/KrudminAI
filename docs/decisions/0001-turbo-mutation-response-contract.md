# ADR: Turbo mutation response contract

- Status: Accepted
- Date: 2026-09-14
- Owners: KrudminAI maintainers
- Reviewers: KrudminAI maintainers

## Context

A Turbo browser advertises `text/vnd.turbo-stream.html` on every form submission. `respond_to` therefore selected the Turbo Stream branch for every mutation, including full-page create and edit forms, and answered with a stream that only replaced the flash. Turbo rendered the stream and stayed put, so a successful save left the user on the form. The `Turbo-Location` header the engine set is inert on a stream response; Turbo reads it for visits, not for streams.

Nothing caught this. The companion app did not load Turbo at all, so its browser suite exercised plain form posts and never executed a stream, and the engine's request specs asserted the stream body rather than the resulting navigation. Covering the behavior in a browser also exposed that every mutation stream replaced `#krudmin-ai-flash` with a bare paragraph, destroying the element it targets, so feedback rendered once and never again.

The engine needs two different outcomes from the same format: a full-page form should navigate to the record, and the inline editor should update in place without leaving the list. The response format alone cannot express that difference.

## Decision And Consequences

Streaming is opt-in. A submission originating inside an engine inline frame, whose id begins with `krudmin-ai-inline-`, receives the Turbo Stream. Every other successful mutation redirects with 303 so Turbo navigates. Failures continue to stream when the client asked for a stream, so a rejected form re-renders in place with 422. Mutation streams now update the contents of `#krudmin-ai-flash` instead of replacing the element, so the target survives repeated mutations.

Rejected alternatives:

- **Always redirect.** Simple and conventional, but inline editing would leave the list and scroll to the top after every save.
- **Bare `turbo_frame_request?`.** The idiomatic predicate, but ambient: a host that wraps engine content in a frame for a modal, a drawer, or a lazy-loaded panel would silently convert every enclosed full-page form into an in-place update. Scoping to an engine-owned prefix keeps the mechanism idiomatic without capturing host frames.
- **A request parameter (`krudmin_ai_stream=1`).** Explicit and shipped briefly, but it invents an engine-specific protocol where Hotwire already has one.
- **A custom `visit` stream action.** Would preserve the previous contract, but adds engine JavaScript to reimplement navigation that a redirect already provides.

Rollout is a single release; no host migration is required because 0.1.0.pre.1 is unreleased and no published version carried the previous contract. The compatibility policy is unchanged. A host that renders engine resources under its own layout must provide a `#krudmin-ai-flash` element for stream feedback to appear; this is recorded in [mutation_pipeline.md](../mutation_pipeline.md).

Evidence: engine specs assert the outcome and format status matrix; host request tests assert redirect-by-default, streaming inside an engine inline frame, a non-engine host frame still redirecting, and the `Turbo-Location` destination per operation; the browser suite asserts that a full-page save navigates to the record and that an inline edit stays on the list and reports through the flash. The companion app now loads Turbo so these paths execute in a browser.

Rollback is reverting to an unconditional stream response, which restores the previous templates and headers but reinstates the navigation defect. Forward recovery, if the frame prefix proves too narrow, is to widen the predicate to any engine-owned frame while keeping host frames excluded.
