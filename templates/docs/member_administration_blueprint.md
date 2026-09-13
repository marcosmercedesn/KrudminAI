# Member Administration Blueprint

This blueprint is a product and security boundary for a new member-administration application. It is designed for a modern replacement of an existing member edit/listing workflow, not a code migration or a copy of the prior application's data model, presentation, credentials, or access rules.

## Product Boundary

The first release manages members, their profile data, team memberships, roles, operational notes, and approved attachments. It supports staff who need to find a member quickly, understand their current standing, make authorized corrections, and see who made each change.

Start with these resources:

| Resource | Purpose | Primary relationships |
| --- | --- | --- |
| `MembersResource` | Directory, profile, contact information, member lifecycle | memberships, teams, attachments, audit events |
| `TeamsResource` | Team identity and operational ownership | memberships, members |
| `MembershipsResource` | Member-to-team assignment, role, start/end dates | member, team |
| `MemberNotesResource` | Restricted operational notes | member, author |
| `MemberAttachmentsResource` | Approved photos and documents | member, uploader |
| `AuditEventsResource` | Read-only evidence of protected activity | actor, subject |

Do not create a generic super-admin screen in the first milestone. Model elevated access as specific, reviewable roles and policies.

## Data Ownership And Tenancy

Choose one verified tenant boundary before writing migrations. Typical options are organization, chapter, region, or operating unit. Every primary model and join model needs the tenant key, including memberships, notes, attachments, and audit records.

The actor's authenticated membership determines the active tenant. The browser never selects a tenant merely by submitting an ID. Cross-tenant staff access, if required, needs an explicit target-tenant selection policy and an audit event that records the actor and target tenant.

## Recommended Member Shape

Use host-owned names that match the business vocabulary. A conservative initial model is:

- Member identity: stable internal identifier, display name, lifecycle status, join date.
- Contact: email, phone, preferred contact method, emergency contact only when a documented retention policy permits it.
- Profile: address and demographic fields only when they have an owner, purpose, retention period, field policy, and parameter filtering rule.
- Membership: team, role, active period, source, and approval metadata.
- Notes: author, visibility class, body, and immutable created-at metadata.
- Attachments: attachment class, uploader, retention date, content validation, and authorized download policy.

Avoid storing formatted identifiers as canonical values. Keep raw typed values in persistence and apply prefixes or presentation formatting in the field adapter.

## Access Matrix To Decide Before Implementation

Write an explicit host-owned matrix for every role before generating resources. At minimum, decide who can list, view, create, update, change lifecycle status, assign teams, upload files, read restricted notes, export, and view audits.

Suggested starting roles:

| Role | Default scope | Typical permissions |
| --- | --- | --- |
| Administrator | Explicitly authorized tenant | Full operational access, role assignment, audit review |
| Membership manager | Assigned tenant | Member and membership changes, no role escalation |
| Team lead | Assigned teams only | Read members and manage assigned team memberships |
| Support staff | Assigned tenant | Read directory and submit limited profile corrections |
| Auditor | Assigned tenant | Read-only audit and approved reports |

These are prompts for a policy decision, not a ready-made authorization model. For each permission, define both the server-side policy and the matching resource/UI visibility predicate.

## Resource And Field Guidance

Use resource fields to make the privacy boundary visible:

- Use `:identifier` for formatted member references, with raw storage.
- Use `:email`, `:phone`, `:date`, `:enum`, `:boolean`, and `:masked` according to the data's semantics.
- Declare `ai_field` only for fields that an approved read-only assistant may receive. Do not allowlist contact details, sensitive notes, attachments, or role assignments by default.
- Use local belongs-to lookup for small, stable lists. Use remote belongs-to lookup for members, teams, or staff directories large enough to require search; its endpoint must use the target resource's tenant and policy scope.
- Use `has_many` nested editing only for a small bounded set of memberships. For bulk reassignment, create a declared action with an explicit policy and audit event.
- Use rich text only for notes that have an owner, classification, and field-level read/write policy. Configure Action Text deliberately.
- Use image/file fields only after configuring Active Storage, content-type/size validation, malware-scanning integration where required, retention, and authorized delivery.

## AI Boundary

The initial AI milestone is read-only. Appropriate early tasks include a summary of allowlisted membership status, a response draft for a reviewer, or an aggregate report insight over a fully scoped relation. It must never infer permissions, expose hidden data, accept provider-suggested member IDs without canonical lookup, or mutate member records.

Any future AI-assisted profile change follows four separate steps: generate proposal, display evidence to an authorized reviewer, record reviewer approval, then execute through the normal mutation pipeline with a pre-mutation trace and audit event.

## Source-System Discovery

Treat the existing application as a stakeholder reference. Document its workflows in a host-owned discovery record using fictionalized examples or approved test data. For each observed workflow, record the user goal, fields needed, role, tenant boundary, approval/audit expectations, retention concerns, and acceptance test. Do not copy source code, production records, session data, private attachments, or implicit access behavior.