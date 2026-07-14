# Design Notes

Short notes on *why* each decision was made — not just what the schema does.

## Why DECIMAL(12,2), never FLOAT, for money

FLOAT stores an approximation in binary, so values like 0.10 can't be
represented exactly — small rounding errors accumulate across
transactions and eventually produce balances that are off by fractions
of a cent. DECIMAL stores an exact base-10 value, which is what money
actually is. Any column holding currency should be DECIMAL or an
equivalent fixed-point type, never a floating-point type.

## Why `reference_id` is UNIQUE (idempotency)

If a transfer is submitted through an API and the client doesn't
receive a response in time (network timeout), a naive system will
retry the request — and without a safeguard, that retry creates a
second, duplicate transaction, silently double-crediting or
double-debiting an account. Making `reference_id` UNIQUE means the
retried insert fails with a constraint violation instead of silently
succeeding twice. The caller can then check "did this reference_id
already exist?" before treating the retry as a new transaction. This
is the core idea of idempotency: the same operation, submitted twice,
should have the same effect as submitting it once.

## Why `branches` and `accounts` are separate tables (referential integrity)

Branch names could have been a text column directly on `accounts` or
`transactions`. Keeping them in their own table with a foreign key
means the database itself enforces that a transaction can never
reference a branch that doesn't exist, and a branch can never be
renamed inconsistently in one row but not another. The constraint
lives in the schema, not in application code that someone might forget
to write.

## Why `created_at` is separate from `transaction_timestamp`

`transaction_timestamp` is business time — when the transaction
happened. `created_at` is system time — when the row was physically
written to the database. They usually match, but they can diverge:
a backdated correction, a batch import processed the next morning, a
reversal entered after investigation. Keeping them separate preserves
an honest audit trail — you can always tell what the system *recorded*
versus what actually *happened*, which matters for both compliance and
debugging.

## Why single-entry rather than double-entry bookkeeping

A transfer here is one row (the sending account debited, with
`related_account_id` pointing at the receiver) rather than two
symmetric rows (a debit row and a credit row, which is how real
banking ledgers work). Double-entry is the more correct design for a
production ledger, but it roughly doubles the row count and complicates
every query with a join back to itself. Single-entry was chosen
deliberately here to keep the analytical queries readable for a
learning project — this tradeoff is called out explicitly rather than
left for someone to discover the hard way.

## Why the compliance query uses COALESCE with LAG

`LAG()` returns NULL for the first row in each partition (an account's
very first transfer has no "previous transfer" to compare against).
Any arithmetic done directly on that NULL — like a time-gap
calculation — becomes NULL, and rows with a NULL gap effectively
disappear from `WHERE gap <= 360` style filters, which usually just
lets them silently pass through unflagged rather than raising an
error. `COALESCE` substitutes the current row's own timestamp when
`LAG` returns NULL, which forces the gap calculation to come out to
exactly 0 for that first row — an explicit, intentional value instead
of an implicit NULL that behaves unpredictably in later filtering.
