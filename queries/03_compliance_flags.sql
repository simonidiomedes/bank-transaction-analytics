-- =====================================================================
-- Compliance Flags: Rapid Transfer / Structuring Detection
--
-- Real compliance logic banks run: flag an account when it makes
-- multiple transfers in quick succession, each just under a reporting
-- threshold — a classic "structuring" pattern (splitting a large
-- transfer into smaller ones to dodge a reporting trigger, commonly
-- set around 10,000 in local currency).
--
-- The mechanics:
--   - LAG(transaction_timestamp) looks at the PREVIOUS transfer's
--     timestamp for the SAME account, without a self-join.
--   - COALESCE handles the first transfer for each account, where
--     there IS no previous row — LAG returns NULL, and COALESCE
--     substitutes the current timestamp itself, which makes the
--     time-gap calculation come out to 0 instead of NULL (0 correctly
--     means "not flagged" rather than the query breaking on NULL
--     arithmetic).
--
-- Flag condition: a transfer where the previous transfer from the
-- same account was within 6 hours AND was also close to the
-- threshold. This will catch the structuring pattern in the seed data
-- (account 106 → 108, four transfers just under 9,800 within hours).
-- =====================================================================

WITH transfer_gaps AS (
    SELECT
        t.transaction_id,
        t.account_id,
        t.related_account_id,
        t.amount,
        t.transaction_timestamp,
        LAG(t.transaction_timestamp) OVER (
            PARTITION BY t.account_id
            ORDER BY t.transaction_timestamp
        ) AS prev_transfer_time,
        DATEDIFF(
            MINUTE,
            COALESCE(
                LAG(t.transaction_timestamp) OVER (
                    PARTITION BY t.account_id
                    ORDER BY t.transaction_timestamp
                ),
                t.transaction_timestamp   -- no previous row: gap collapses to 0
            ),
            t.transaction_timestamp
        ) AS minutes_since_prev_transfer
    FROM transactions t
    WHERE t.transaction_type = 'transfer'
      AND t.status = 'completed'
)
SELECT
    account_id,
    transaction_id,
    related_account_id,
    amount,
    transaction_timestamp,
    prev_transfer_time,
    minutes_since_prev_transfer
FROM transfer_gaps
WHERE minutes_since_prev_transfer > 0                -- exclude the first-in-series rows (gap = 0)
  AND minutes_since_prev_transfer <= 360              -- within 6 hours of the previous transfer
  AND amount BETWEEN 8000 AND 9999                    -- close to (just under) a 10,000 threshold
ORDER BY account_id, transaction_timestamp;
