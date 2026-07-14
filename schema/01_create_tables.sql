-- =====================================================================
-- Bank Transaction Analytics - Schema
-- Lesotho branch network: Maseru, Hatikoe, Maputsoe
-- =====================================================================

-- ---------------------------------------------------------------------
-- branches: reference table. Kept separate rather than a free-text
-- column on transactions so branch names can never drift or typo
-- (referential integrity — the DB enforces it, not application code).
-- ---------------------------------------------------------------------
CREATE TABLE branches (
    branch_id       INT PRIMARY KEY,
    branch_name     VARCHAR(50) NOT NULL UNIQUE,
    town            VARCHAR(50) NOT NULL
);

INSERT INTO branches (branch_id, branch_name, town) VALUES
    (1, 'Maseru Central', 'Maseru'),
    (2, 'Hatikoe Branch',  'Maseru'),
    (3, 'Maputsoe Branch', 'Maputsoe');

-- ---------------------------------------------------------------------
-- accounts: one row per customer account. FK to branches enforces
-- that an account can never point to a branch that doesn't exist.
-- ---------------------------------------------------------------------
CREATE TABLE accounts (
    account_id          INT PRIMARY KEY,
    account_holder_name VARCHAR(100) NOT NULL,
    branch_id           INT NOT NULL,
    account_type        VARCHAR(20) NOT NULL CHECK (account_type IN ('savings', 'current', 'business')),
    date_opened         DATE NOT NULL,
    CONSTRAINT fk_accounts_branch FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
);

-- ---------------------------------------------------------------------
-- transactions: the core table.
--
-- Design decisions worth noting (see docs/design_notes.md for the why):
--   1. amount is DECIMAL(12,2), never FLOAT - money must be exact.
--   2. reference_id is UNIQUE — this is the idempotency guard. If the
--      same transaction gets submitted twice (e.g. a retried API call
--      after a network timeout), the duplicate insert fails loudly
--      instead of silently double-crediting an account.
--   3. related_account_id is nullable - only populated for transfers,
--      linking the two legs of a transfer together.
--   4. created_at is separate from transaction_timestamp - the former
--      is when the ROW was written (audit trail), the latter is when
--      the transaction actually happened (business time). They can
--      differ, e.g. backdated corrections.
-- ---------------------------------------------------------------------
CREATE TABLE transactions (
    transaction_id          INT PRIMARY KEY,
    account_id              INT NOT NULL,
    related_account_id      INT NULL,
    transaction_type        VARCHAR(20) NOT NULL CHECK (transaction_type IN ('deposit', 'withdrawal', 'transfer')),
    amount                  DECIMAL(12,2) NOT NULL CHECK (amount > 0),
    reference_id            VARCHAR(40) NOT NULL UNIQUE,
    transaction_timestamp   DATETIME NOT NULL,
    created_at              DATETIME NOT NULL DEFAULT GETDATE(),
    status                  VARCHAR(20) NOT NULL DEFAULT 'completed' CHECK (status IN ('completed', 'reversed', 'pending')),
    CONSTRAINT fk_txn_account          FOREIGN KEY (account_id)         REFERENCES accounts(account_id),
    CONSTRAINT fk_txn_related_account  FOREIGN KEY (related_account_id) REFERENCES accounts(account_id)
);
