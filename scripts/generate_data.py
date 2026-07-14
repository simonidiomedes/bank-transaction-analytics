import csv
import random
from datetime import datetime, timedelta

random.seed(42)

accounts = [101,102,103,104,105,106,107,108,109,110]
start = datetime(2024, 1, 1)

rows = []
txn_id = 1000

def add(account_id, related, ttype, amount, ts, ref, status='completed'):
    global txn_id
    txn_id += 1
    rows.append([txn_id, account_id, related if related else '', ttype, f"{amount:.2f}", ref, ts.strftime('%Y-%m-%d %H:%M:%S'), status])

# Normal activity over ~90 days
current = start
for day in range(90):
    current = start + timedelta(days=day)
    for _ in range(random.randint(2, 5)):
        acc = random.choice(accounts)
        ttype = random.choices(['deposit','withdrawal','transfer'], weights=[0.4,0.35,0.25])[0]
        ts = current + timedelta(hours=random.randint(8,17), minutes=random.randint(0,59))
        ref = f"REF{txn_id+1:06d}"
        if ttype == 'transfer':
            related = random.choice([a for a in accounts if a != acc])
            amount = round(random.uniform(200, 8000), 2)
            add(acc, related, 'transfer', amount, ts, ref)
        elif ttype == 'deposit':
            amount = round(random.uniform(100, 15000), 2)
            add(acc, None, 'deposit', amount, ts, ref)
        else:
            amount = round(random.uniform(50, 6000), 2)
            add(acc, None, 'withdrawal', amount, ts, ref)

# Inject a deliberate compliance pattern: account 106 makes 4 rapid
# transfers just under a round threshold within a few hours - the kind
# of structuring pattern a compliance query should catch.
suspect_day = start + timedelta(days=45)
for i in range(4):
    ts = suspect_day + timedelta(hours=9 + i, minutes=random.randint(0,20))
    ref = f"REF{txn_id+1:06d}"
    add(106, 108, 'transfer', 9800.00 - i*15, ts, ref)

rows.sort(key=lambda r: r[6])

with open('data/sample_transactions.csv', 'w', newline='') as f:
    w = csv.writer(f)
    w.writerow(['transaction_id','account_id','related_account_id','transaction_type','amount','reference_id','transaction_timestamp','status'])
    w.writerows(rows)

print(f"Generated {len(rows)} transactions")
