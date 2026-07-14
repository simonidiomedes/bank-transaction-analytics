-- Seed accounts: spread across all three branches, mixed account types.
INSERT INTO accounts (account_id, account_holder_name, branch_id, account_type, date_opened) VALUES
    (101, 'Thabo Mokoena',      1, 'savings',  '2022-03-14'),
    (102, 'Palesa Ntsane',      1, 'current',  '2021-11-02'),
    (103, 'Lehlohonolo Tau',    1, 'business', '2023-06-19'),
    (104, 'Mamello Khoali',     2, 'savings',  '2020-01-25'),
    (105, 'Retšelisitsoe Moshoeshoe', 2, 'current', '2022-09-08'),
    (106, 'Nthabiseng Lerotholi', 2, 'savings', '2023-02-17'),
    (107, 'Teboho Ramaema',     3, 'business', '2021-05-30'),
    (108, 'Litaba Sekonyela',   3, 'current',  '2022-12-11'),
    (109, 'Mpho Letsie',        3, 'savings',  '2024-01-09'),
    (110, 'Karabo Mots\'oene',  1, 'current',  '2023-08-22');
