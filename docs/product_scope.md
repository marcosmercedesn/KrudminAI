# Product Scope

## V1

KrudminAI provides an admin-panel-first Rails engine with authenticated resource access, deny-by-default authorization, tenant-aware query composition, CRUD workflows, dashboards, audit extension points, and read-only in-app AI assistance. Primary personas are administrators, managers, auditors, and support operators.

## V1.1 and V2

V1.1 adds reviewable document extraction, cross-record analysis, dashboard narratives, and reusable AI prompt templates. Provider proposals remain drafts until a human reviewer confirms them through normal authorization and mutation paths. V2 adds guided workflow assistants, approved agent automation, and multi-source analysis. Automation is an explicit reviewed proposal with an approval policy, canonical scoped record lookup, mutation-pipeline execution, and actor/role/tenant trace; it is never autonomous.

## Non-goals

KrudminAI is not a public-site CMS, an authentication provider, an authorization framework, or an autonomous mutation agent. Provider integrations remain host-application decisions behind engine contracts.