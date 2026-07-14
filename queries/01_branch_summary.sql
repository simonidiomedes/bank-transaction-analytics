-- =====================================================================
-- Branch Summary: total volume and transaction count per branch,
-- broken down by transaction type.
--
-- This is the "hello world" of the analytics layer — establishes
-- which branches are busiest and in what way (a branch that's mostly
-- withdrawals behaves differently from one that's mostly deposits).
-- =====================================================================

SELECT
    b.branch_name,
    b.town,
    t.transaction_type,
    COUNT(*)                       AS transaction_count,
    SUM(t.amount)                  AS total_volume,
    AVG(t.amount)                  AS avg_transaction_size
FROM transactions t
JOIN accounts a  ON a.account_id = t.account_id
JOIN branches b  ON b.branch_id  = a.branch_id
WHERE t.status = 'completed'
GROUP BY b.branch_name, b.town, t.transaction_type
ORDER BY b.branch_name, t.transaction_type;
