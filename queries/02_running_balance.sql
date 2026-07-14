-- =====================================================================
-- Running Balance Per Account
--
-- Uses a window function (SUM ... OVER) to compute a running total of
-- each account's net position, ordered by transaction time. This is
-- the warm-up for the LAG-based compliance query — same idea (a
-- calculation that looks *across* rows within a partition) applied to
-- a simpler question: "what did this account's balance look like over
-- time?"
--
-- Deposits add, withdrawals subtract, transfers subtract from the
-- sending account (the related_account_id leg is the receiving side
-- and would need its own symmetric row if you wanted double-entry
-- bookkeeping — noted in design_notes.md, deliberately kept single-
-- entry here to keep the query readable).
-- =====================================================================

SELECT
    t.account_id,
    t.transaction_id,
    t.transaction_type,
    t.transaction_timestamp,
    t.amount,
    CASE
        WHEN t.transaction_type = 'deposit' THEN t.amount
        ELSE -t.amount
    END AS signed_amount,
    SUM(
        CASE
            WHEN t.transaction_type = 'deposit' THEN t.amount
            ELSE -t.amount
        END
    ) OVER (
        PARTITION BY t.account_id
        ORDER BY t.transaction_timestamp
        ROWS UNBOUNDED PRECEDING
    ) AS running_balance
FROM transactions t
WHERE t.status = 'completed'
ORDER BY t.account_id, t.transaction_timestamp;
