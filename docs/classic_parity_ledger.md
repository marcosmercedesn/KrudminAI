# Classic Parity Ledger

[classic_parity_ledger.json](classic_parity_ledger.json) is the authoritative machine-readable inventory of Krudmin Classic public capabilities and their KrudminAI replacement owners. It records only four implementation states: `implemented`, `partial`, `missing`, and `independently_proven`.

An item is not independently proven from engine tests or companion-demo evidence. Its owner prompt must supply the ledger's stated engine, independently generated-host, browser/accessibility, and documentation evidence. The ledger's `progress` section is the durable restart point for the replacement program.

Run `ruby bin/verify_classic_parity` after changing the ledger or [capability_registry.json](capability_registry.json). The verifier checks the inventory, mandatory P1 through P6 ownership, the P0/P1 resume state, registry consistency, and the beta `hold` decision.