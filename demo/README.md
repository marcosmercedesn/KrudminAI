# KrudminAI Companion

This Rails host application is the executable companion for the KrudminAI engine. It demonstrates a local, no-network admin workspace with tenant-scoped tickets, deny-by-default policy rules, audited mutations, dashboard queries, and a read-only companion assistant.

## Run locally

From the repository root, install the compatible bundle when the required ERB version is available, then:

```sh
cd demo
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/rails server
```

Open `http://localhost:3000`. Choose a seeded account: Morgan Lee (Northwind support agent), Avery Patel (Northwind manager), or Jordan Kim (Southwind support agent).

The demo is intentionally local-only. Its companion provider never makes network requests; it receives only tenant- and policy-scoped fields allowlisted by `TicketsResource`.# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
