# Bank Transaction Analytics — Lesotho Branch Network

SQL analytics project modeling a simplified banking transaction system
across a three-branch network (Maseru, Hatikoe, Maputsoe), built to
demonstrate schema design and window-function analysis relevant to
retail banking data work.

## What this project shows

- **Schema design with real constraints** — referential integrity via
  foreign keys, `CHECK` constraints on transaction types and positive
  amounts, `DECIMAL` for currency (never `FLOAT`), and a `UNIQUE`
  constraint on `reference_id` as an idempotency guard against
  duplicate transaction writes.
- **Window functions applied to a real compliance use case** — a
  `LAG` + `COALESCE` query that detects transaction structuring
  (multiple transfers just under a reporting threshold, submitted in
  quick succession) — the same technique banks use to flag potential
  money-laundering patterns for review.
- **Design reasoning made explicit** — every non-obvious schema
  decision is documented in [`docs/design_notes.md`](docs/design_notes.md),
  including tradeoffs that were consciously made (e.g. single-entry
  vs. double-entry transaction modeling) rather than left unstated.

## Structure

```
schema/
  01_create_tables.sql      Table definitions with constraints
  02_seed_accounts.sql      10 accounts across 3 branches
  03_seed_transactions.sql  328 transactions over 90 days
queries/
  01_branch_summary.sql     Aggregate volume/count by branch and type
  02_running_balance.sql    Running balance per account (window function)
  03_compliance_flags.sql   Structuring detection (LAG + COALESCE)
data/
  sample_transactions.csv   Raw data, same content as the seed script
docs/
  design_notes.md           Why each schema decision was made
```

## Running it

1. Create a database in SQL Server / SSMS.
2. Run the scripts in order: `01_create_tables.sql` →
   `02_seed_accounts.sql` → `03_seed_transactions.sql`.
3. Run any query in `queries/` against the populated database.

`queries/03_compliance_flags.sql` will return three flagged
transactions from account 106 — a deliberately embedded structuring
pattern (four transfers to the same account, each just under a
10,000 threshold, within a few hours) used to verify the detection
logic actually works rather than just compiling.

## Tech

SQL Server (T-SQL) syntax — `GETDATE()`, `DATEDIFF`, window functions
via `OVER (PARTITION BY ... ORDER BY ...)`.
