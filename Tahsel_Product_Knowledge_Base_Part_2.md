# Tahsel Product Knowledge Base
## Part 2 - Customer Management, Debts & Financial Transactions

Version: 1.0

---

# Table of Contents

1. Customer Management
2. Customer Information
3. Customer Debts
4. Creating a Debt
5. Debt Details
6. Payment System
7. Partial Payment
8. Full Settlement
9. Payment History
10. Edit Payment
11. Delete Payment
12. Ledger Architecture
13. Remaining Debt Calculation
14. Debt Status
15. Notifications
16. Reports
17. Collected Amount Feature
18. Business Rules
19. Edge Cases

---

# 1. Customer Management

Customers are the central entity of the application.

Each customer can have:

- Name
- Phone Number
- Address (optional)
- Notes (optional)
- Multiple Debts
- Installments
- Payment History

A customer can exist even if they currently have no active debts.

---

# 2. Customer Information

Customer profile displays:

- Full Name
- Phone Number
- Notes
- Total Debts
- Total Paid
- Remaining Amount
- Number of Transactions

Quick actions:

- Call Customer
- WhatsApp
- Edit Customer
- Delete Customer

Deleting a customer is only allowed if business rules permit.

---

# 3. Customer Debts

A customer may have:

- One debt
- Multiple debts

Each debt is completely independent.

Each debt contains:

- Debt Name
- Original Amount
- Remaining Amount
- Created Date
- Notes
- Transaction History

Example:

Samsung S24

Original:

12000

Remaining:

5000

---

# 4. Creating a Debt

Creating a debt generates the first financial record.

Required fields:

- Debt Name
- Amount

Optional:

- Notes

Business Rules:

Amount must be greater than zero.

Debt is immediately visible in reports.

Debt appears in customer history.

---

# 5. Debt Details Screen

Displays:

Debt Name

Original Amount

Remaining Amount

Paid Amount

Creation Date

Transaction Timeline

Actions

Transactions are shown chronologically.

Newest first.

---

# 6. Payment System

Tahsel supports:

Partial Payment

Full Payment

Every payment creates a financial transaction.

Payments update:

Remaining Debt

Reports

Analytics

Collected Amount

Notifications

Customer Summary

---

# 7. Partial Payment

Partial payment allows paying only part of the debt.

Example

Debt

1000

Customer pays

300

Result

Original

1000

Paid

300

Remaining

700

Original amount never changes.

Only paid amount increases.

Remaining is always recalculated.

---

# 8. Full Settlement

Button:

Full Settlement

Automatically fills payment amount with remaining balance.

Example

Remaining

700

User taps:

Full Settlement

Payment created:

700

Remaining

0

Debt becomes fully paid.

---

# 9. Payment History

Every payment appears as a transaction.

Displayed information:

Amount

Date

Notes

Payment Type

Transactions are immutable in ledger mode.

History is never lost.

---

# 10. Edit Payment

Editing does NOT modify debt directly.

Depending on implementation:

Option A

Traditional

Update payment record.

Recalculate totals.

Option B (Preferred)

Ledger

Create Adjustment transaction.

Original payment remains.

Adjustment stores only difference.

Example

Payment

100

Edited to

60

Creates

Adjustment

-40

Net payment

60

Advantages

Perfect audit trail.

No history loss.

No financial inconsistency.

---

# 11. Delete Payment

Preferred behavior:

Never delete payment permanently.

Create Reversal transaction.

Example

Payment

500

Delete

Creates

Reversal

-500

Net effect

0

History preserved.

---

# 12. Ledger Architecture

Tahsel follows transaction-based accounting.

Every financial event is a transaction.

Transaction Types

Debt Created

Payment

Adjustment

Reversal

Future:

Refund

Transfer

Discount

Interest

Reports never inspect debt directly.

Reports sum transactions.

---

# 13. Remaining Debt Calculation

Remaining debt is NEVER stored as source of truth.

Formula

Remaining =
Original Debt
-
Sum(All Payment Transactions)

Ledger Version

Remaining =
Sum(All Ledger Entries)

Always derived.

Never cached.

Never manually edited.

---

# 14. Debt Status

Possible states

Pending

Partial

Paid

Rules

Remaining > Original

Impossible

Remaining == Original

Pending

Remaining == 0

Paid

Remaining between

Partial

---

# 15. Notifications

Supported channels

WhatsApp

SMS

None

Notifications are sent after:

Partial Payment

Full Settlement

Adjustment

Not sent after:

Delete/Reversal (configurable)

Message contains

Customer Name

Paid Amount

Remaining Amount

Debt Name

---

# 16. Reports

Debt reports update automatically after every transaction.

Affected reports

Daily

Weekly

Monthly

Customer Reports

Dashboard

Analytics

Collected Amount

No manual refresh required.

Cubit reloads state.

---

# 17. Collected Amount Feature

Purpose

Show money collected each month.

Only Payment transactions count.

Excluded

Debt Creation

Adjustment

Reversal

Grouping Key

Payment.createdAt

NOT

Debt.createdAt

Example

Debt created

May

Payment

June

Collected Amount

June + Payment

Never May.

Month card displays

Month

Total Collected

Transaction Count

Details

Opening month shows all payment items belonging to that month.

Summary total MUST equal visible transaction list.

No mismatch allowed.

---

# 18. Business Rules

Rule 1

Debt amount never decreases.

---

Rule 2

Remaining amount is always calculated.

---

Rule 3

Transactions are financial truth.

---

Rule 4

Reports depend on payment date.

Never debt creation date.

---

Rule 5

createdAt is business date.

Never syncedAt.

---

Rule 6

Delete never corrupts history.

---

Rule 7

Multiple rapid taps must never duplicate payment.

Buttons such as:

Full Settlement

Partial Payment

must disable immediately while request executes.

---

Rule 8

No duplicate transactions.

Each payment executes once.

---

Rule 9

Every financial operation refreshes:

Summary Card

Reports

Collected Amount

Timeline

Header

Dashboard

---

Rule 10

UI never performs calculations.

All calculations belong to UseCases.

---

# 19. Edge Cases

Customer pays exact amount.

Remaining becomes zero.

---

Customer overpays.

Operation rejected.

---

Edit payment to zero.

Handled safely.

---

Delete only payment.

Debt returns to original value.

---

Multiple partial payments.

Remaining always equals:

Original

minus

sum(all payments)

---

Offline payment.

Stored locally.

Synced later.

Business date remains original createdAt.

---

Payment notification fails.

Financial operation still succeeds.

---

Network interruption.

Transaction must never duplicate after retry.

---

User taps payment button multiple times.

Only first request executes.

Remaining taps ignored until completion.

---

Debt deleted while payments exist.

Operation rejected.

History protected.

---

Collected Amount report

must always match

Payment History.

No exceptions.

---

End of Part 2
