# Tahsel Product Knowledge Base
## Part 1 - Product Overview, Vision & Core Business Rules

Version: 1.0

---

# Table of Contents

1. Product Overview
2. Vision
3. Goals
4. Target Users
5. Supported Platforms
6. Supported Business Types
7. Core Modules
8. General Workflow
9. Authentication
10. Subscription System
11. Account Status
12. Platform Restrictions
13. User Roles
14. Design Philosophy
15. Core Financial Principles
16. Global Business Rules
17. Localization
18. Notifications
19. Offline Philosophy
20. Security
21. Future Scalability

---

# 1. Product Overview

Tahsel is a complete Arabic-first business management system designed for small and medium businesses.

The application focuses on simplifying daily business operations through an easy-to-use interface while maintaining high financial accuracy.

Tahsel is not only a debt management application.

It is a complete business management platform.

---

Current supported modules include:

- Customer Management
- Customer Debts
- Personal Debts
- Installments
- Expenses
- Employee Management
- Salaries
- Attendance
- Advances (Loans)
- Reports
- Notifications
- WhatsApp Integration
- Playstation Management
- Shop Management
- Dashboard
- Subscription Management

---

# 2. Vision

Tahsel aims to become the easiest Arabic ERP solution for small businesses.

The main principles are:

- Simplicity
- Speed
- Financial Accuracy
- Beautiful UI
- Minimum user effort
- Automation whenever possible

---

# 3. Product Goals

The application should allow business owners to:

- Manage debts.
- Record expenses.
- Track employees.
- Calculate salaries.
- Track installments.
- Manage Playstation sessions.
- Generate financial reports.
- Receive statistics.
- Synchronize data between devices.

without requiring accounting experience.

---

# 4. Target Users

Tahsel targets:

- Electronics shops
- Mobile shops
- Grocery stores
- Clothing stores
- Restaurants
- Cafes
- Playstation Cafes
- Service Centers
- Workshops
- Retail Stores
- Small Companies

---

# 5. Supported Platforms

Tahsel currently supports:

## Android

Full support.

---

## iOS

Full support.

---

## Windows

Desktop management.

---

One account may support:

- Mobile only
- Desktop only
- Both

Platform availability depends on dashboard configuration.

---

# 6. Supported Business Types

Dashboard creates accounts with:

```
userType
```

Possible values:

```
CAFE
SHOP
```

---

## SHOP

Suitable for:

- Electronics
- Clothing
- Grocery
- Furniture
- Retail

---

## CAFE

Suitable for:

- Playstation
- Internet Cafe
- Gaming Center

---

Different UI sections become available depending on userType.

---

# 7. Core Modules

Current production modules:

## Customers

Stores customer information.

---

## Customer Debts

Tracks debts owed by customers.

Supports:

- Full Payment
- Partial Payment
- Notifications
- Reports

---

## My Debts

Tracks debts that business owner owes.

---

## Installments

Installment plans.

---

## Expenses

Tracks all business expenses.

---

## Employees

Employee profiles.

Attendance.

Salary.

Loans.

Reports.

---

## Reports

Daily

Weekly

Monthly

Collected Amount

Expenses

Debt Reports

Salary Reports

---

## Playstation

Timer-based room management.

Live sessions.

Pricing.

Devices.

History.

---

## Dashboard

User Management.

Subscriptions.

Updates.

Notifications.

Versions.

---

# 8. General Workflow

Typical business workflow:

Customer

↓

Create Debt

↓

Receive Partial Payments

↓

Receive Remaining Payment

↓

Debt Closed

↓

Reports Updated

↓

Notifications Sent

↓

Analytics Updated

---

# 9. Authentication

Authentication uses Firebase Authentication.

Every account belongs to exactly one business.

Authentication only grants access.

Permissions determine available features.

---

# 10. Subscription System

Tahsel uses subscription-based licensing.

Each account stores:

Subscription Start

Subscription End

Grace Period End

Remaining Days

Status

Platform Type

User Type

---

Grace Period

10 days.

After grace expires:

Application access is blocked.

---

Dashboard automatically validates subscriptions.

Client application validates on every launch.

---

# 11. Account Status

Possible states:

ACTIVE

SUSPENDED

DISABLED

DELETED

EXPIRED

GRACE_PERIOD

---

ACTIVE

Normal usage.

---

SUSPENDED

Temporary restriction.

No attendance.

No salary.

No debt modifications.

Read-only mode.

---

DISABLED

Login blocked.

---

DELETED

Soft delete.

Cannot login.

---

EXPIRED

Subscription expired.

Grace period active.

---

GRACE_PERIOD

User can continue using until grace ends.

---

# 12. Platform Restrictions

Each account has:

platformType

Possible values:

```
mobile
desktop
both
```

---

If account is mobile only:

Desktop login is rejected.

---

If account is desktop only:

Mobile login is rejected.

---

Both:

Unlimited.

---

Validation occurs every application launch.

---

# 13. User Roles

Business Owner

Primary user.

---

Employees

Future support.

Limited permissions.

---

Dashboard Admin

Controls:

Users

Subscriptions

Versions

Notifications

Account Status

---

# 14. Design Philosophy

Every screen follows:

Minimal clicks.

Clear typography.

Financial readability.

Responsive layouts.

Dark mode.

Light mode.

Localization.

No clutter.

---

# 15. Core Financial Principles

This is the most important section.

Financial calculations NEVER depend on UI.

They NEVER depend on cached values.

Everything is derived from source data.

Source of Truth:

Transactions.

Payments.

Expenses.

Attendance.

Ledger entries.

NOT displayed totals.

---

Example:

Wrong:

remainingDebt stored directly.

Correct:

remainingDebt =
totalDebt
-
sum(payments)

Always.

---

# 16. Global Business Rules

Rule 1

Never duplicate calculations.

---

Rule 2

Never calculate inside Widgets.

---

Rule 3

Business logic belongs to UseCases.

---

Rule 4

Cubit orchestrates only.

---

Rule 5

Repository handles persistence only.

---

Rule 6

UI displays state only.

---

Rule 7

Reports always derive from transactions.

---

Rule 8

Dates use createdAt.

Never syncedAt.

Never uploadedAt.

---

Rule 9

Notifications never modify business logic.

---

Rule 10

Deleting data must preserve consistency.

---

# 17. Localization

Languages:

Arabic

English

All text uses ARB files.

Hardcoded strings are forbidden.

---

# 18. Notifications

Current supported methods:

WhatsApp

SMS

None

Notifications are optional.

Business operations must not depend on notification success.

---

# 19. Offline Philosophy

Offline mode is supported.

Business date:

createdAt

must never change after synchronization.

Sync metadata:

syncedAt

is technical only.

Never used in reports.

---

# 20. Security

Authentication:

Firebase Authentication.

Authorization:

Firestore account status.

Soft delete preferred.

Critical actions require confirmation dialogs.

Sensitive operations:

Delete Account

Delete Payment

Salary Payment

Debt Settlement

always require confirmation.

---

# 21. Future Scalability

Tahsel architecture is designed to support future modules including:

Inventory

Suppliers

Invoices

Barcode

POS

Accounting

Taxes

Purchase Orders

Multi Branch

Role Management

Cloud Printing

Advanced Analytics

AI Assistant

without requiring architectural redesign.

---

End of Part 1
