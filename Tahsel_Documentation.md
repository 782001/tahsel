# Tahsel Documentation

Version: 2.0
Last Updated: June 2026

---

# PART 1 — PROJECT OVERVIEW

# 1. About Tahsel

Tahsel is a complete business management platform designed for Arabic-speaking businesses to simplify debt management, installment sales, employee management, expense tracking, PlayStation & Café management, reporting, and daily business operations.

The system is designed to be extremely simple for non-technical users while maintaining enterprise-level reliability, accurate financial calculations, cloud synchronization, and multi-platform support.

Tahsel focuses on replacing paper notebooks, Excel sheets, and disconnected management tools with one centralized system.

---

# 2. Vision

Tahsel aims to become the all-in-one management system for small and medium businesses in the Arab world.

The main objective is reducing manual work while improving financial accuracy and business visibility.

---

# 3. Supported Businesses

Tahsel currently supports multiple business types.

## Retail Shops

Examples:

- Mobile stores
- Electronics
- Clothing
- Supermarkets
- Grocery stores
- Spare parts
- Accessories
- Furniture
- Pharmacies
- Cosmetic shops
- Hardware stores

---

## PlayStation & Gaming Centers

Supports:

- PlayStation Cafés
- Gaming Rooms
- Console Rentals
- Hourly Sessions
- Timed Sessions

---

## Cafés

Supports:

- Customer management
- Employee management
- Expenses
- Debts
- Reports

---

## Future Expandability

The architecture allows supporting additional business types without changing the core application.

---

# 4. Supported Platforms

Tahsel currently supports:

- Android
- iOS
- Windows Desktop

Each account may be configured to allow:

- Mobile only
- Desktop only
- Both Mobile & Desktop

Platform restrictions are validated during every application launch.

---

# 5. Application Architecture

Tahsel consists of two independent applications.

---

## 5.1 Tahsel Dashboard

Purpose:

Administrative dashboard used by the application owner.

Responsibilities:

- Create accounts
- Renew subscriptions
- Suspend accounts
- Disable accounts
- Delete accounts
- Configure app versions
- Force updates
- Manage subscriptions
- Review users
- View statistics

The Dashboard is not available to customers.

---

## 5.2 Tahsel Client Application

Used by customers to manage their business.

This application contains all business features including:

- Customers
- Debts
- Installments
- Employees
- Expenses
- Reports
- PlayStation Management
- Shop Management

---

# 6. Main Objectives

Tahsel was designed around several business goals.

## Financial Accuracy

Every calculation must be derived from the source data.

No manual totals.

No cached financial values.

No duplicated calculations.

---

## Simplicity

Every screen should require the minimum possible number of user actions.

The application targets business owners, not accountants.

---

## Reliability

The application must remain stable during:

- Internet interruption
- Offline work
- Synchronization
- Multi-device usage

---

## Automation

The application automatically performs many repetitive operations including:

- Reports
- Salary calculations
- Debt calculations
- Payment summaries
- Subscription validation
- Update checks

---

# 7. Core Modules

Tahsel currently contains the following major modules.

## Authentication

Login

Logout

Session Validation

Subscription Validation

Platform Validation

Account Status Validation

---

## Customer Management

Customer Profiles

Customer Debts

Customer Reports

Customer Payment History

---

## Debt Management

Debt Creation

Partial Payments

Full Payments

Payment History

Debt Reports

Remaining Balance

Payment Notifications

---

## Installments

Installment Plans

Monthly Payments

Remaining Installments

Reports

---

## Expenses

Expense Categories

Expense Tracking

Daily Reports

Monthly Reports

Analytics

---

## Employee Management

Employees

Attendance

Check In

Check Out

Salary

Advances

Absence

Excused Absence

Payroll Reports

---

## PlayStation Management

Rooms

Devices

Live Sessions

Session Timers

Automatic Billing

Revenue Reports

---

## Shop Management

Products

Sales

Inventory

Installments

Customers

---

## Reports

Daily

Weekly

Monthly

Yearly

Collected Amount

Expenses

Employees

Debts

Installments

PlayStation

---

## Notifications

WhatsApp

SMS

None

---

## Offline Synchronization

Offline Queue

Synchronization

Conflict Resolution

Cloud Sync

---

# 8. User Roles

Currently, Tahsel contains two major user roles.

---

## Dashboard Administrator

Responsible for:

- Managing subscriptions
- Managing users
- Managing versions
- Monitoring activity
- Sending notifications

---

## Business User

Responsible for managing his own business.

The business user cannot manage other companies.

Each account has isolated data.

---

# 9. Account Types

Each created account has a business type.

Currently supported values are:

CAFE

SHOP

The selected type determines which business modules are enabled.

---

# 10. Platform Types

Each account also stores a platform type.

Possible values:

MOBILE

DESKTOP

BOTH

Platform validation occurs every time the application starts.

Users cannot log in from unsupported platforms.

---

# 11. Subscription System

Each account contains:

- Subscription Start Date
- Subscription End Date
- Grace Period End Date
- Remaining Days
- Account Status

Statuses include:

- Active
- Suspended
- Disabled
- Deleted
- Expired

After the grace period ends, access to the application is denied until the subscription is renewed.

---

# 12. Design Principles

Tahsel follows the following principles.

- Clean Architecture
- SOLID Principles
- Responsive UI
- Dark Mode Support
- Light Mode Support
- Localization Support
- Offline First
- Firebase Synchronization
- Source of Truth Calculations
- Production Ready Code
# PART 2 — Authentication & Account Lifecycle

Version: 2.0

---

# Overview

The Authentication module is responsible for protecting business data while ensuring that only authorized users with valid subscriptions can access the application.

Unlike a traditional login system, Tahsel validates several conditions before allowing access.

Authentication is therefore composed of multiple validation layers rather than simply checking email and password.

---

# Authentication Flow

Every application launch follows the same sequence.

Application Start

↓

Splash Screen

↓

Initialize Firebase

↓

Load Local Preferences

↓

Check Authentication Session

↓

If user not logged in

→ Login Screen

Else

↓

Download latest user document

↓

Validate Account

↓

Validate Subscription

↓

Validate Platform

↓

Validate App Version

↓

Open Home Screen

---

# Splash Screen

The Splash Screen performs all startup validations.

Responsibilities:

- Initialize Firebase
- Initialize Local Storage
- Load Localization
- Load Theme
- Verify User Session
- Download Latest User Information
- Check Application Version
- Validate Subscription
- Validate Platform
- Validate Account Status

The Splash Screen is the application's security gate.

Users never reach the Home Screen before all validations succeed.

---

# Login Screen

The Login Screen allows users to authenticate using:

- Email Address
- Password

Validation Rules:

- Email Required
- Valid Email Format
- Password Required
- Minimum Password Length

After successful authentication, the application immediately performs all account validation rules before navigating to the Main Layout.

---

# Login Process

1.

User enters email.

↓

2.

User enters password.

↓

3.

Firebase Authentication login.

↓

4.

Download user profile.

↓

5.

Validate Account Status.

↓

6.

Validate Subscription.

↓

7.

Validate Platform.

↓

8.

Validate Force Update.

↓

9.

Navigate to Main Layout.

---

# Logout

Logout completely clears the current authenticated session.

Actions performed:

- Firebase Sign Out
- Clear Cached User Data
- Clear Session Information
- Navigate to Login Screen

No business data is deleted during logout.

---

# Delete Account

Apple requires users to be able to delete their account directly inside the application.

Tahsel provides a dedicated Delete Account action.

The delete process performs a soft deletion.

Actions:

- Mark account as Deleted
- Disable future login
- Invalidate active sessions
- Remove local session
- Navigate back to Login Screen

The Dashboard administrator can still review deleted accounts for administrative purposes.

---

# Delete Account Confirmation

Before deletion, the application displays a confirmation dialog.

The dialog explains:

- The account will be deleted.
- The user will lose access.
- Login will no longer be possible.
- The operation cannot be easily reversed.

The dialog supports:

- Arabic
- English

Dark Mode

Light Mode

Existing Design System

---

# Session Management

Tahsel stores authenticated sessions securely.

The application remembers logged-in users.

However...

Every application launch re-validates:

- Account Status
- Subscription
- Platform
- App Version

This guarantees that an outdated session cannot bypass business rules.

---

# Automatic Session Validation

Validation occurs:

- Every App Launch
- Every Cold Start

This approach replaces expensive real-time listeners and Cloud Functions.

---

# Account Status

Each account contains one status.

Possible values:

Active

Suspended

Disabled

Deleted

Expired

---

# Active

The account operates normally.

Allowed:

- Login
- Create Data
- Edit Data
- Delete Data
- Synchronization

---

# Suspended

Temporary administrative suspension.

The user cannot access the application until reactivated.

A dedicated information screen is displayed.

---

# Disabled

The account has been disabled.

The application blocks access.

A dedicated Disabled Screen is shown.

---

# Deleted

The account has been removed.

Login is permanently rejected.

The Deleted Account Screen is displayed.

---

# Expired

The subscription has expired.

The application checks whether the grace period is still active.

If grace period remains:

Access is allowed.

Otherwise:

Access is denied.

---

# Subscription Structure

Each user document stores:

Subscription Start Date

Subscription End Date

Grace Period End Date

Subscription Duration

Remaining Days

Status

Platform Type

Business Type

---

# Grace Period

Tahsel provides a built-in grace period.

Default:

10 Days

Timeline Example

Subscription Start

↓

30 Days

↓

Subscription End

↓

10 Days Grace

↓

Access Blocked

The grace period allows business owners to continue working temporarily before renewing.

---

# Remaining Days Calculation

Remaining Days are calculated dynamically.

Formula:

Remaining Days =
Subscription End Date − Current Date

Negative values indicate expiration.

---

# Expired Subscription Flow

Application Opens

↓

Subscription Expired

↓

Grace Period Active?

↓

YES

↓

Allow Access

Show Remaining Grace Days

↓

NO

↓

Navigate to Subscription Expired Screen

---

# Subscription Expired Screen

Displayed when:

Grace Period has completely ended.

Displayed Information:

Subscription Expired

Subscription Start Date

Subscription End Date

Grace Period End Date

Remaining Days = 0

Current Status

Actions:

Renew Subscription

Logout

The Renew button opens WhatsApp support directly.

---

# Platform Validation

Each account stores:

Platform Type

Possible values:

MOBILE

DESKTOP

BOTH

Validation occurs before entering the application.

---

# Mobile Only Account

Allowed:

Android

iPhone

Blocked:

Windows

---

# Desktop Only Account

Allowed:

Windows

Blocked:

Android

iPhone

---

# Both Platforms

Allowed everywhere.

---

# Platform Rejection Screen

If validation fails:

The application opens a dedicated screen.

Example:

"This subscription is only available for Windows."

or

"This subscription is only available for Mobile."

The screen includes:

Current Platform

Allowed Platform

Logout Button

Dark Mode

Localization

---

# Force Update

The Dashboard controls application versions.

Each platform has independent configuration.

Android

iOS

Windows

Each platform stores:

Version Name

Build Number

Download URL

Force Update

Update Message

---

# Force Update Flow

App Launch

↓

Download Version Config

↓

Current Version < Required Version?

↓

YES

↓

Force Update?

↓

YES

↓

Block Application

↓

Open Update Screen

↓

Download Latest Version

---

# Optional Update

If Force Update = false

The application allows the user to continue.

The update dialog may be dismissed.

---

# Update Screen

Displays:

Latest Version

Update Notes

Update Button

Platform-specific Download Link

---

# Offline Authentication Behavior

When internet is unavailable:

Previously authenticated users may continue working according to offline rules.

Synchronization resumes automatically after reconnection.

Business validations requiring server state occur again on the next online launch.

---

# Security Principles

Authentication never relies on UI state.

All business decisions come from the latest user document stored in Firebase.

The client only displays results.

The Dashboard remains the source of truth.

---

# Localization

All authentication screens support:

Arabic

English

Every text uses localization keys.

No hardcoded strings are allowed.

---

# Theme Support

Authentication fully supports:

Light Theme

Dark Theme

Responsive Layout

Windows

Android

iPhone

---

# Design System

Authentication screens strictly use:

AppColors

TextStyles

Existing Components

Existing Navigation

Existing Dialogs

No custom styling outside the design system.

---

# Business Rules Summary

✓ Validate authentication every launch.

✓ Validate subscription every launch.

✓ Validate account status every launch.

✓ Validate platform every launch.

✓ Validate application version every launch.

✓ Never trust cached account information.

✓ Dashboard is always the source of truth.

✓ Subscription expiration immediately affects access after grace period.

✓ Deleted, Disabled and Suspended accounts cannot continue into the application.

✓ Platform restrictions are always enforced.

✓ Force Update is evaluated independently for Android, iOS and Windows.

✓ Delete Account is available inside the application to satisfy App Store requirements.

PART 3 — Subscription System

3.1 Architecture

3.2 Dashboard Side

3.3 User Creation

3.4 Subscription Lifecycle

3.5 Account Status

3.6 Platform Validation

3.7 User Type

3.8 Automatic Expiration

3.9 Daily Checker

3.10 Tahsel Side

3.11 Settings Screen

3.12 Expired UI

3.13 Disabled UI

3.14 Grace Period

3.15 Logout Flow

3.16 Edge Cases

3.17 Business Rules

# PART 3 — Subscription System

Version: 2.0

---

# 3.1 Subscription System Architecture

## Overview

The Tahsel Subscription System is responsible for controlling user access throughout the entire lifecycle of an account.

Unlike a traditional subscription system that only checks whether a user has paid, Tahsel manages the account from the moment it is created until it is permanently deleted.

The subscription system coordinates between two independent applications:

* Tahsel Dashboard (Administrator)
* Tahsel Client Application

Both applications share the same Firebase user document and always rely on it as the single source of truth.

---

# Main Objectives

The Subscription System is designed to achieve the following goals:

* Prevent unauthorized access.
* Control subscription periods.
* Support automatic expiration.
* Support grace periods.
* Support account suspension.
* Support account disabling.
* Support account deletion.
* Support platform restrictions.
* Support business type restrictions.
* Allow administrators to renew subscriptions easily.
* Keep all subscription information synchronized between Dashboard and Client applications.

---

# Source of Truth

The Dashboard is always considered the authoritative source.

The Tahsel client application never decides whether an account is active.

Instead, every decision is based on the latest user document downloaded from Firebase.

Business rules are never derived from cached values.

---

# Subscription Lifecycle

Every account follows the same lifecycle.

```text
Create User
      │
      ▼
Active Subscription
      │
      ▼
Subscription Expired
      │
      ▼
Grace Period
      │
      ▼
Grace Period Expired
      │
      ▼
Account Disabled
      │
      ▼
Account Deleted (Optional)
```

Each state has different permissions and different UI.

---

# Dashboard Responsibilities

The Dashboard application is responsible for:

* Creating users.
* Assigning subscription duration.
* Assigning business type.
* Assigning supported platform.
* Renewing subscriptions.
* Extending subscriptions.
* Suspending users.
* Disabling users.
* Deleting users.
* Running expiration validation.
* Managing application versions.
* Sending notifications.

The Dashboard owns all subscription modifications.

---

# Tahsel Responsibilities

The client application never modifies subscription information.

Its responsibilities are limited to:

* Reading subscription information.
* Displaying subscription status.
* Validating account state.
* Blocking unauthorized access.
* Redirecting expired users.
* Opening WhatsApp for subscription renewal.
* Logging users out when required.

---

# Subscription Validation Timing

Subscription validation is performed whenever the application starts.

The validation sequence is:

```text
Splash Screen

↓

Firebase Initialization

↓

Authentication Validation

↓

Download User Document

↓

Validate Account Status

↓

Validate Subscription

↓

Validate Platform

↓

Validate Application Version

↓

Navigate to Home
```

No user reaches the application without passing every validation.

---

# Account States

Each user belongs to exactly one state.

Supported states:

* Active
* Suspended
* Disabled
* Deleted
* Expired
* Grace Period

The current state determines what the user is allowed to do.

---

# Platform Restriction

Every account specifies which platforms are allowed.

Supported values:

* Mobile
* Desktop
* Both

The application compares:

Current Device Platform

against

Assigned Platform Type

before allowing access.

---

# Business Type

Every account also specifies the business category.

Supported values:

* CAFE
* SHOP

The business type determines which modules are available inside the application.

Future modules may extend this behavior without changing the subscription architecture.

---

# Grace Period

A grace period allows users to continue working for a limited time after their subscription expires.

Current implementation:

* 10 days

After the grace period ends, access is completely blocked.

---

# Automatic Expiration

Cloud Functions are intentionally not used.

Instead, expiration is handled by the Dashboard application.

Whenever the Dashboard starts, it automatically checks all users and updates expired accounts.

This approach keeps the system compatible with the free Firebase plan.

---

# Manual Daily Check

The administrator is only required to open the Dashboard application periodically.

Opening the Dashboard automatically performs:

* Subscription validation.
* Grace period validation.
* Expiration validation.
* Account status updates.

No manual processing is required.

---

# Security Principles

The Subscription System follows these principles:

* Never trust cached subscription data.
* Never calculate account state inside the UI.
* Always download the latest user document.
* Always validate before entering the application.
* Keep Dashboard as the only authority that modifies subscriptions.
* Keep the client application read-only regarding subscription management.

---

# Architecture

The Subscription System follows Clean Architecture.

Presentation Layer

* Splash Screen
* Login Screen
* Settings Screen
* Subscription Screens

↓

Cubit

↓

Use Cases

↓

Repository

↓

Firebase Data Source

The UI never contains business rules.

---

# Offline Behavior

If the device is offline:

* Cached authentication may remain available according to the existing offline strategy.
* Subscription validation is performed again once internet connectivity is restored.
* The application always synchronizes with Firebase before making long-term subscription decisions.

---

# Localization

Every subscription-related screen supports:

* Arabic
* English

All text is loaded from ARB localization files.

No subscription-related text is hardcoded.

---

# Theme Support

All subscription screens support:

* Light Mode
* Dark Mode

using the existing design system.

---

# Design System

Subscription UI follows:

* AppColors
* TextStyles
* Existing Components
* Existing Dialogs
* Existing Navigation

No custom styling is introduced.

---

# End of Section

Next Section:

**3.2 — Dashboard Side (User Creation & Subscription Management)**

This section explains how subscriptions are created, renewed, extended, suspended, disabled, deleted, and managed from the Dashboard application.
# PART 3 — Subscription System

# 3.2 Dashboard Side

## Overview

The Dashboard application is the only component responsible for creating and managing subscriptions.

All subscription modifications originate from the Dashboard.

The Tahsel client application is read-only regarding subscription management.

---

# Dashboard Responsibilities

The Dashboard is responsible for:

* Creating users
* Renewing subscriptions
* Extending subscriptions
* Suspending users
* Disabling users
* Deleting users
* Checking expired subscriptions
* Updating account status
* Assigning business type
* Assigning supported platform

---

# Create User

A subscription begins when an administrator creates a new user.

Required information:

* Full Name
* Email Address
* Password
* Phone Number
* Subscription Duration
* User Type
* Platform Type

The administrator cannot create a user with missing required information.

---

# Initial User Status

Every newly created account starts as:

```text
Status = Active
```

unless the administrator explicitly changes it afterward.

---

# Initial Subscription State

When the account is created:

```text
Subscription State = Active
```

The countdown starts immediately from the creation date.

---

# Subscription Duration

The Dashboard allows selecting the subscription duration.

Default:

```text
30 Days
```

The administrator may also specify a custom duration if needed.

Examples:

* 30 Days
* 60 Days
* 90 Days
* 365 Days

---

# Subscription Start

The start date is automatically assigned.

```text
subscriptionStart = Current Date
```

It should never be entered manually.

---

# Subscription End

Calculated automatically.

Formula:

```text
subscriptionEnd =
subscriptionStart + subscriptionDuration
```

Example:

```text
Start

01/06/2026

Duration

30 Days

End

01/07/2026
```

---

# Grace Period

Immediately after the subscription expires:

```text
Grace Period = 10 Days
```

Formula:

```text
Grace End

=

Subscription End

+

10 Days
```

---

# Remaining Days

Dashboard continuously calculates:

```text
Remaining Days

=

Subscription End

-

Today
```

If negative:

```text
Remaining Days = 0
```

---

# Subscription Renewal

The administrator may renew an existing subscription.

Renewal creates a new subscription period starting from:

* Current subscription end
* or Today (depending on current implementation)

The Dashboard automatically recalculates:

* Start Date
* End Date
* Remaining Days
* Grace Period

---

# Extend Subscription

The administrator may extend the subscription without replacing it.

Example:

```text
Current End

1 July

Extend

30 Days

↓

New End

31 July
```

The subscription remains active.

---

# Quick Renewal

Dashboard provides a quick renewal action.

Example:

```text
+30 Days
```

One click performs:

* Subscription extension
* End date recalculation
* Remaining days recalculation

---

# Suspend User

The administrator may suspend an account.

Purpose:

Temporary administrative restriction.

Behavior:

* Login denied
* Synchronization denied
* Existing sessions terminated
* Subscription information preserved

Suspension does not modify subscription dates.

---

# Disable User

The administrator may disable an account.

Purpose:

Prevent application access completely.

Behavior:

* Login denied
* Subscription preserved
* User data preserved
* Reports preserved

---

# Delete User

Deletion is implemented as a Soft Delete.

Dashboard performs:

* Status update
* Firebase Authentication cleanup (according to current implementation)
* Data preservation

Purpose:

Avoid accidental data loss.

---

# Manual Status Changes

Dashboard supports manually switching between:

* Active
* Suspended
* Disabled

Changing status immediately affects the client application after the next synchronization.

---

# User Type Assignment

Each account is assigned exactly one business type.

Supported values:

```text
CAFE

SHOP
```

Purpose:

Determine which business modules are enabled.

---

# Platform Assignment

Each account also receives a platform restriction.

Supported values:

```text
Mobile

Desktop

Both
```

Examples:

Desktop

↓

Windows only

---

Mobile

↓

Android / iPhone only

---

Both

↓

Windows + Mobile

---

# Dashboard Validation

Before creating the account:

Dashboard validates:

* Email uniqueness
* Required fields
* Valid subscription duration
* Valid platform type
* Valid user type

Invalid data is rejected before Firebase operations begin.

---

# Dashboard Notifications

Subscription operations may trigger notifications.

Examples:

* User Created
* Subscription Renewed
* Subscription Extended
* Account Suspended
* Account Disabled

Notification behavior depends on the configured notification settings.

---

# Dashboard UI

Subscription controls follow the application's design system.

Requirements:

* Responsive Layout
* Dark Mode
* Light Mode
* Existing AppColors
* Existing TextStyles

No custom styling is introduced.

---

# Business Rules

Dashboard is the only place allowed to:

* Modify subscription dates
* Modify subscription status
* Renew subscriptions
* Extend subscriptions
* Assign user type
* Assign platform type

Tahsel Client must never modify these values.

---

# End of Section

Next Section:

**3.3 — Subscription Lifecycle & Automatic Expiration**

This section explains how subscriptions transition from Active to Grace Period, Expired, Disabled, and Deleted, including the automatic expiration mechanism and daily validation process.

# PART 3 — Subscription System

# 3.3 Subscription Lifecycle & Automatic Expiration

## Overview

The Subscription Lifecycle defines every state an account can pass through from the moment it is created until it is permanently removed.

Every state has its own business rules, UI behavior, and access permissions.

The lifecycle is deterministic and always follows the same validation process.

---

# Complete Lifecycle

```text
Create User
    │
    ▼
Active Subscription
    │
    ▼
Subscription Expired
    │
    ▼
Grace Period
    │
    ▼
Grace Period Expired
    │
    ▼
Disabled Account
    │
    ▼
Deleted Account (Optional)
```

---

# Active Subscription

An account is considered Active when:

* Current Date is before Subscription End Date.
* Account Status = Active.
* Platform validation passes.
* Application version validation passes.

The user has unrestricted access according to their permissions.

---

# Subscription Expiration

A subscription becomes expired immediately after the Subscription End Date.

Example:

```text
Subscription Start

01/06/2026

Subscription End

30/06/2026

Current Date

01/07/2026

↓

Subscription Expired
```

Expiration alone does not immediately block the user because a Grace Period is available.

---

# Grace Period

Tahsel provides a Grace Period after subscription expiration.

Current implementation:

```text
10 Days
```

Purpose:

* Allow users time to renew.
* Prevent unexpected service interruption.
* Improve user experience.

During this period:

* The account remains usable.
* The application continuously displays subscription expiration information.
* The remaining grace days are recalculated every time the application starts.

---

# Grace Period Calculation

Formula:

```text
Grace End Date

=

Subscription End Date

+

10 Days
```

Example:

```text
Subscription End

30 June

Grace Ends

10 July
```

---

# Remaining Grace Days

Formula:

```text
Remaining Grace Days

=

Grace End Date

-

Today
```

Example:

```text
Today

5 July

Grace Ends

10 July

↓

Remaining

5 Days
```

---

# Grace Period Expired

When:

```text
Today > Grace End Date
```

The account is no longer allowed to use the application.

The Dashboard automatically updates the account status during the next expiration validation.

---

# Automatic Account Disable

Once the Grace Period finishes:

Dashboard automatically changes:

```text
Account Status

↓

Disabled
```

No administrator intervention is required.

---

# Why Disable Instead of Delete?

Disabled accounts preserve:

* User profile
* Customers
* Debts
* Expenses
* Employees
* Reports
* PlayStation data
* Settings

This allows the user to renew later without losing data.

Deletion remains an administrator decision.

---

# Automatic Expiration Check

Tahsel intentionally does not use Firebase Cloud Functions.

Instead, expiration validation is performed by the Dashboard application.

Whenever the Dashboard starts, it executes:

```text
Check Every User

↓

Is Subscription Expired?

↓

Is Grace Period Finished?

↓

Update Account Status
```

This solution works entirely within the Firebase free plan.

---

# Daily Manual Trigger

The administrator only needs to open the Dashboard application.

Opening the Dashboard automatically performs:

* Subscription validation
* Grace Period validation
* Status updates
* Remaining day calculations

No additional manual action is required.

---

# Client-Side Validation

Whenever the Tahsel application starts:

The following sequence occurs:

```text
Splash Screen

↓

Initialize Firebase

↓

Read Cached Authentication

↓

Download User Document

↓

Validate Account Status

↓

Validate Subscription

↓

Validate Platform

↓

Validate Application Version

↓

Navigate
```

This guarantees that every session uses the latest subscription state.

---

# Validation Priority

The application validates states in the following order:

```text
1. Deleted

↓

2. Disabled

↓

3. Suspended

↓

4. Platform Restriction

↓

5. Subscription

↓

6. Grace Period

↓

7. Version Validation

↓

8. Home Screen
```

The first failing validation immediately stops navigation.

---

# Expired Subscription Screen

When the subscription has expired but the Grace Period is still active:

The application navigates to a dedicated Subscription screen displaying:

* Subscription Status
* Subscription End Date
* Grace Period End Date
* Remaining Grace Days
* Renewal Button

The user is informed that renewal is required soon.

---

# Grace Period Finished Screen

When the Grace Period has ended:

The application blocks access completely.

Displayed information includes:

* Subscription expired
* Grace Period finished
* Subscription End Date
* Grace Period End Date

Available actions:

* Renew Subscription
* Logout

No business modules are accessible.

---

# Renew Subscription Flow

Selecting "Renew Subscription" opens WhatsApp using the predefined support number.

The generated message requests subscription renewal.

The application itself does not process payments.

---

# Logout Flow

After subscription validation fails:

The application:

* Clears the current session.
* Returns to the authentication flow.
* Prevents re-entry until validation succeeds.

---

# Dashboard Recovery

After the administrator renews the subscription:

Dashboard updates:

* Subscription Start
* Subscription End
* Remaining Days
* Grace Period
* Account Status

On the next application launch, the user regains access automatically.

---

# Edge Cases

## Subscription renewed before expiration

Result:

Grace Period is never entered.

---

## Subscription renewed during Grace Period

Result:

Access continues normally after the next validation.

---

## Subscription renewed after account becomes Disabled

Result:

Dashboard reactivates the account.

The user can log in again immediately.

---

## Administrator manually disables an active subscription

Result:

The account becomes inaccessible regardless of remaining subscription days.

---

## Administrator suspends a user

Result:

Subscription dates remain unchanged.

Only account access is restricted.

---

## Deleted accounts

Deleted accounts never return automatically.

Recovery requires explicit administrator action if supported.

---

# Business Rules

* Subscription dates are immutable except through Dashboard operations.
* Grace Period always follows Subscription End Date.
* Disabled accounts preserve business data.
* Automatic expiration is performed only by the Dashboard.
* Client applications never calculate new subscription dates.
* Client applications only consume subscription information.
* Dashboard remains the single source of truth.

---

# End of Section

Next Section:

**3.4 — User Creation, Subscription Fields & Firebase Data Structure**

This section documents every subscription-related field stored for each user, how each value is generated, validated, synchronized, and consumed by both the Dashboard and Tahsel applications.

# PART 3 — Subscription System

# 3.4 User Creation, Subscription Fields & Firebase Data Structure

## Overview

Every Tahsel account is represented by a single Firebase document.

This document acts as the **single source of truth** for both applications:

* Tahsel Dashboard
* Tahsel Client

Every subscription validation, account validation, platform validation, and business rule depends on this document.

The client application never stores independent subscription information.

---

# User Creation Flow

When an administrator creates a new account from the Dashboard, the following operations occur:

```text
Administrator

↓

Create User Form

↓

Validate Input

↓

Create Firebase Authentication User

↓

Create Firestore User Document

↓

Assign Subscription

↓

Assign Platform

↓

Assign Business Type

↓

User Ready
```

The process is considered successful only after both Firebase Authentication and Firestore document creation complete successfully.

---

# Required User Information

Every user must contain:

* Full Name
* Email Address
* Password
* Phone Number
* Account Status
* Subscription Information
* Platform Type
* Business Type

No account may exist with incomplete required subscription fields.

---

# User Identifier

Each user owns a unique Firebase UID.

Characteristics:

* Immutable
* Globally Unique
* Used across all collections
* Never changes after creation

This UID links every business entity owned by the user.

---

# Basic Profile Fields

The user profile contains:

* uid
* fullName
* email
* phoneNumber
* createdAt
* lastLogin

These fields identify the account independently from the subscription system.

---

# Subscription Fields

Each account stores complete subscription information.

Typical subscription fields include:

```text
subscriptionStart

subscriptionEnd

subscriptionDuration

remainingDays

gracePeriodEnd
```

These values are maintained exclusively by the Dashboard.

---

# Remaining Days

Remaining Days is considered a derived value.

Whenever necessary it should be recalculated from:

```text
Subscription End Date

-

Current Date
```

The application should never trust outdated cached values.

---

# Grace Period End

The grace period end is stored for faster validation.

Formula:

```text
Grace End

=

Subscription End

+

10 Days
```

---

# Account Status

Each account contains one status value.

Supported values:

```text
Active

Suspended

Disabled

Deleted
```

Only one status can exist at any moment.

---

# Subscription State

Besides account status, the subscription itself can be interpreted as:

* Active
* Expired
* Grace Period

These are derived from subscription dates rather than manually assigned.

---

# Platform Type

Every account specifies which operating systems are allowed.

Supported values:

```text
Mobile

Desktop

Both
```

Examples:

Desktop

↓

Windows Application only

---

Mobile

↓

Android + iPhone

---

Both

↓

All supported platforms

---

# Business Type

Each account belongs to one supported business category.

Current values:

```text
CAFE

SHOP
```

This field determines which modules become available inside Tahsel.

Future releases may introduce additional business categories.

---

# User Type Validation

The client application downloads the business type during startup.

Modules that do not belong to the assigned business type are hidden.

The UI must never expose unsupported modules.

---

# Platform Validation

During startup:

Current Platform

is compared with

Allowed Platform.

If validation fails:

Access is denied.

The user is redirected to the Platform Restriction screen.

---

# Created Date

Every user stores:

```text
createdAt
```

Purpose:

* Audit
* Reports
* Administrative history

This field never changes after creation.

---

# Last Login

Each successful login updates:

```text
lastLogin
```

Purpose:

* Activity tracking
* Dashboard statistics
* User monitoring

---

# Notes

Administrators may attach notes to each account.

Examples:

* Payment reminders
* Customer requests
* Internal administrative comments

Notes never affect subscription logic.

---

# Firebase Authentication

Authentication stores:

* Email
* Password

Firestore stores:

* Business data
* Subscription data
* Status
* Configuration

Both remain synchronized.

---

# Soft Delete Strategy

Deleting a user does not immediately remove business information.

Instead:

```text
Account Status

↓

Deleted
```

Business records remain preserved until permanent removal is explicitly performed.

---

# Synchronization Rules

Whenever the Dashboard modifies:

* Subscription
* Status
* Platform
* Business Type

The next application launch downloads the updated document before allowing access.

---

# Security Rules

The client application:

* Never edits subscription fields.
* Never edits account status.
* Never edits platform type.
* Never edits business type.

Only the Dashboard can modify these values.

---

# Business Rules

* Every account owns exactly one subscription.
* Every account owns exactly one platform type.
* Every account owns exactly one business type.
* UID never changes.
* Subscription fields are Dashboard-owned.
* Client application is read-only regarding account management.
* Firestore remains the single source of truth.

---

# End of Section

Next Section:

**3.5 — Account Status Management**

This section documents every account status in detail, including **Active**, **Suspended**, **Disabled**, **Deleted**, their permissions, UI behavior, navigation flow, validation order, recovery process, and business rules.

# PART 3 — Subscription System

# 3.5 Account Status Management

## Overview

The Account Status Management system determines whether a user is allowed to access the Tahsel application.

Unlike the Subscription Lifecycle, which depends on subscription dates, Account Status is an administrative control that can immediately allow or deny access regardless of the subscription validity.

Every login attempt and every application startup must validate the account status before allowing navigation to the Home Screen.

---

# Account Status Types

Tahsel currently supports the following account statuses:

```text
Active
Suspended
Disabled
Deleted
```

Each account can have **only one status** at any given time.

---

# Validation Priority

Account status validation is always executed before any business module is loaded.

Validation order:

```text
Deleted

↓

Disabled

↓

Suspended

↓

Platform Validation

↓

Subscription Validation

↓

Version Validation

↓

Home Screen
```

If any validation fails, the remaining validations are skipped.

---

# Active Status

## Description

An Active account is fully operational.

Requirements:

* Account Status = Active
* Platform Validation Passed
* Subscription Validation Passed
* Application Version Validation Passed

Allowed actions:

* Login
* Synchronization
* CRUD Operations
* Reports
* Notifications
* Offline Synchronization
* PlayStation Module
* Shop Module
* Employee Module

Everything behaves normally.

---

# Suspended Status

## Purpose

Suspended is intended for temporary administrative restrictions.

Examples:

* Payment issue under review
* Policy violation
* Temporary investigation
* Customer request

---

## Behavior

The account:

* Cannot log in
* Cannot synchronize
* Cannot perform CRUD operations
* Cannot receive new data

However:

* User document remains intact
* Subscription dates remain unchanged
* Business data remains intact

---

## Dashboard Behavior

The administrator can restore the account instantly by changing:

```text
Suspended

↓

Active
```

No additional recovery steps are required.

---

# Suspended UI

The client application displays a dedicated screen.

The screen contains:

* Status Title
* Friendly Explanation
* Support Message
* Logout Button

Optional:

* Contact Support Button

---

# Disabled Status

## Purpose

Disabled accounts represent accounts that are no longer allowed to access the system.

Common reasons:

* Subscription expired
* Grace Period finished
* Administrative action

---

## Behavior

Disabled accounts:

* Cannot log in
* Cannot synchronize
* Cannot create records
* Cannot modify records
* Cannot receive updates

Business data remains preserved.

---

# Automatic Disable

The Dashboard automatically disables accounts when:

```text
Today

>

Grace Period End
```

No manual action is required.

---

# Disabled UI

The application navigates to a dedicated screen showing:

* Subscription expired
* Grace Period finished
* Subscription End Date
* Grace Period End Date

Available actions:

* Renew Subscription
* Logout

No access to business modules is granted.

---

# Renew Flow

Pressing:

```text
Renew Subscription
```

opens WhatsApp using the predefined support number.

The generated message requests subscription renewal.

The application itself does not process payments.

---

# Deleted Status

## Purpose

Deleted accounts are permanently blocked.

Deletion is considered the final administrative action.

---

# Behavior

Deleted accounts:

* Cannot log in
* Cannot synchronize
* Cannot renew from the client application
* Cannot access any module

---

# Data Preservation

Tahsel currently uses a Soft Delete strategy.

This means:

Business data remains available until an administrator permanently removes it.

Purpose:

* Prevent accidental data loss
* Allow administrative review
* Maintain audit history

---

# Recovery

Deleted accounts cannot recover themselves.

Recovery requires Dashboard intervention (if supported).

---

# Login Validation

Every successful authentication is followed by:

```text
Download User Document

↓

Validate Account Status

↓

Continue
```

Authentication success alone never grants access.

---

# Startup Validation

Every application startup executes:

```text
Splash Screen

↓

Firebase Initialization

↓

Authentication

↓

User Document

↓

Status Validation

↓

Navigation
```

Even previously logged-in users are revalidated.

---

# Cached Sessions

Cached authentication sessions are not trusted.

Whenever internet connectivity is available:

The latest account status is downloaded before granting access.

---

# Offline Behavior

If the device is offline:

Existing offline behavior remains unchanged according to the application's offline strategy.

Once connectivity returns:

The account status is revalidated immediately.

---

# Administrator Actions

Dashboard supports:

* Activate User
* Suspend User
* Disable User
* Delete User

Every action immediately updates the Firebase user document.

---

# Client Synchronization

The Tahsel client never modifies account status.

It only:

* Downloads status
* Interprets status
* Displays appropriate UI
* Restricts access

---

# Navigation Matrix

| Status    | Login | Home | Reports | CRUD | Sync |
| --------- | ----- | ---- | ------- | ---- | ---- |
| Active    | ✅     | ✅    | ✅       | ✅    | ✅    |
| Suspended | ❌     | ❌    | ❌       | ❌    | ❌    |
| Disabled  | ❌     | ❌    | ❌       | ❌    | ❌    |
| Deleted   | ❌     | ❌    | ❌       | ❌    | ❌    |

---

# Edge Cases

## Administrator suspends an active account

Result:

The next application launch blocks access immediately.

---

## Administrator activates a suspended account

Result:

Access is restored immediately after the next validation.

---

## Subscription renewed after account was disabled

Result:

Dashboard changes:

```text
Disabled

↓

Active
```

The user can log in again.

---

## Deleted account attempts login

Authentication may succeed if credentials still exist.

However:

Status validation blocks access immediately.

---

## Platform validation fails before status validation

This should never happen.

Status validation always executes first.

---

# Business Rules

* Account Status is controlled exclusively by the Dashboard.
* Client applications never modify account status.
* Status validation always precedes business logic.
* Deleted accounts have the highest priority.
* Disabled accounts override valid subscriptions.
* Suspended accounts preserve subscription dates.
* Active is the only status that grants application access.

---

# Architecture

```text
Dashboard

↓

Update Status

↓

Firestore

↓

Client Startup

↓

Download User Document

↓

Validate Status

↓

Allow / Deny Access
```

---

# End of Section

Next Section:

**3.6 — Platform Validation**

This section documents the complete platform restriction system, including **Mobile**, **Desktop**, **Both**, platform detection, validation flow, restriction screens, startup checks, and all business rules related to platform-specific subscriptions.

# PART 3 — Subscription System

# 3.6 Platform Validation

## Overview

Tahsel supports multiple platforms while allowing administrators to control which platforms each account is permitted to use.

Platform validation ensures that every account only accesses the devices included in its subscription.

This validation is performed every time the application starts.

---

# Supported Platforms

Tahsel currently supports:

* Android
* iPhone (iOS)
* Windows Desktop

Internally these are grouped into subscription platform types.

---

# Platform Types

Each account is assigned exactly one platform type.

Supported values:

```text id="kq1v8p"
Mobile

Desktop

Both
```

The Dashboard assigns this value during user creation or later modification.

---

# Mobile Platform

The **Mobile** platform type allows the account to access only mobile devices.

Supported devices:

* Android Phones
* Android Tablets
* iPhone
* iPad

Blocked devices:

* Windows Desktop

---

# Desktop Platform

The **Desktop** platform type allows the account to access only the Windows application.

Supported devices:

* Windows Desktop
* Windows Laptop

Blocked devices:

* Android
* iPhone
* iPad

---

# Both Platform

The **Both** platform type grants unrestricted access across all supported platforms.

Supported devices:

* Android
* iPhone
* Windows

The same account can be used across supported devices according to the application's synchronization rules.

---

# Dashboard Assignment

During user creation, the administrator selects:

```text id="v9rqm2"
Platform Type
```

Default value:

```text id="tnx4ef"
Mobile
```

The administrator can later change the assigned platform.

---

# Startup Validation Flow

Every application startup performs the following sequence:

```text id="m2o7jp"
Splash Screen

↓

Initialize Firebase

↓

Authentication

↓

Download User Document

↓

Read Platform Type

↓

Detect Current Device

↓

Compare

↓

Allow / Deny Access
```

No business module is initialized before platform validation succeeds.

---

# Device Detection

The application automatically detects its running platform.

Examples:

Android Device

↓

Current Platform = Mobile

---

Windows Application

↓

Current Platform = Desktop

---

iPhone

↓

Current Platform = Mobile

The user never selects this manually.

---

# Validation Rules

## Mobile Account

Allowed:

```text id="wgnjlwm"
Current Platform

=

Mobile
```

Denied:

```text id="ywsyd4"
Current Platform

=

Desktop
```

---

## Desktop Account

Allowed:

```text id="f9ltj0"
Current Platform

=

Desktop
```

Denied:

```text id="pbjlwm"
Current Platform

=

Mobile
```

---

## Both Account

Allowed:

```text id="2l5djm"
Desktop

Mobile
```

No restrictions are applied.

---

# Platform Restriction Screen

When validation fails, the user is redirected to a dedicated screen.

The screen explains why access was denied.

Examples:

Desktop subscription opened on mobile:

```text id="6tqjgd"
Your subscription supports
Windows Desktop only.
```

---

Mobile subscription opened on Windows:

```text id="vyyiha"
Your subscription supports
Mobile devices only.
```

---

# Platform Restriction UI

The screen follows Tahsel's design system.

Requirements:

* Responsive Layout
* Dark Mode
* Light Mode
* AppColors
* Existing Typography
* Existing Components

---

# Screen Content

The restriction screen displays:

* Status Illustration
* Platform Icon
* Title
* Description
* Assigned Platform
* Current Platform

Available actions:

* Logout
* Contact Support (optional)

---

# Logout Behavior

Selecting Logout:

* Clears current session
* Returns to Login Screen

No cached session remains active.

---

# Platform Change

Administrators may change a user's platform at any time.

Example:

```text id="5mz41x"
Mobile

↓

Both
```

The user gains desktop access after reopening the application.

---

# Platform Upgrade

Typical upgrade path:

```text id="bd3v1x"
Mobile

↓

Both
```

or

```text id="r5sqww"
Desktop

↓

Both
```

No additional client configuration is required.

---

# Platform Downgrade

Example:

```text id="7lb2tx"
Both

↓

Mobile
```

The Windows application will immediately refuse access on the next launch.

---

# Offline Behavior

If platform information already exists locally:

The application follows the existing offline validation strategy.

Once online:

The latest platform type is downloaded from Firestore before allowing access.

---

# Synchronization

Platform changes originate exclusively from the Dashboard.

The client application:

* Downloads platform type
* Validates platform
* Displays restriction UI when necessary

The client never edits platform information.

---

# Edge Cases

## Mobile user installs Windows version

Result:

Platform validation fails.

Restriction screen is displayed.

---

## Desktop user logs into Android

Result:

Access denied.

---

## Administrator upgrades account while user is logged in

Result:

The new platform becomes effective after the next application startup.

---

## Both account

Result:

All supported platforms continue working normally.

---

# Business Rules

* Every account has exactly one Platform Type.
* Platform Type is assigned only by the Dashboard.
* Platform validation runs during every startup.
* Client applications never modify platform assignments.
* Restriction screens replace the Home Screen when validation fails.
* Platform validation always occurs before loading business modules.

---

# Architecture

```text id="g0c4el"
Dashboard

↓

Assign Platform Type

↓

Firestore

↓

Client Startup

↓

Detect Device

↓

Validate Platform

↓

Allow / Deny Access
```

---

# End of Section

Next Section:

**3.7 — User Type Validation**

This section documents how Tahsel enables or disables modules based on the assigned business type (**CAFE** or **SHOP**), including module visibility, navigation rules, feature restrictions, and future extensibility.

# PART 3 — Subscription System

# 3.7 User Type Validation

## Overview

Tahsel is designed to support multiple business types within a single application.

Instead of maintaining separate applications for different industries, Tahsel enables or disables modules based on the assigned **User Type**.

Each account belongs to exactly one business category.

The application dynamically adapts its interface according to this value.

---

# Supported User Types

Current supported business types are:

```text
CAFE

SHOP
```

Future versions may introduce additional types without requiring major architectural changes.

---

# Purpose

User Type determines:

* Visible modules
* Hidden modules
* Dashboard navigation
* Reports availability
* Feature access
* Business workflows

It does **not** affect authentication or subscription.

---

# Dashboard Assignment

When an administrator creates a user, they must choose the business type.

Field:

```text
User Type
```

Default value:

```text
CAFE
```

The administrator may later change the assigned business type if needed.

---

# User Type Storage

The value is stored inside the user document.

Example:

```text
userType = CAFE
```

or

```text
userType = SHOP
```

The client application downloads this value during startup.

---

# Startup Flow

After authentication:

```text
Splash Screen

↓

Firebase Initialization

↓

Authentication

↓

Download User Document

↓

Read userType

↓

Configure Available Modules

↓

Navigate Home
```

No business module is initialized before the user type is known.

---

# CAFE Business Type

The CAFE type is intended for businesses such as:

* PlayStation Cafés
* Gaming Centers
* Internet Cafés
* Coffee Shops
* Entertainment Centers

Available modules include:

* Customer Debts
* My Debts
* Expenses
* Employees
* Reports
* PlayStation Module
* Installments
* Notifications
* Settings

---

# SHOP Business Type

The SHOP type is intended for:

* Mobile Stores
* Electronics Stores
* Retail Shops
* Grocery Stores
* Clothing Stores
* Spare Parts Shops
* General Trading Businesses

Available modules include:

* Customer Debts
* My Debts
* Expenses
* Employees
* Shop Module
* Installments
* Reports
* Notifications
* Settings

---

# PlayStation Module Visibility

The PlayStation module is displayed only when:

```text
userType == CAFE
```

Otherwise:

* Hidden from navigation
* Hidden from dashboard
* Hidden from reports
* Hidden from statistics

The module should not simply be disabled—it should not appear at all.

---

# Shop Module Visibility

The Shop module is displayed only when:

```text
userType == SHOP
```

Otherwise:

* Completely hidden
* Navigation removed
* Reports removed
* Statistics removed

---

# Shared Modules

The following modules are shared across all business types:

* Authentication
* Customer Debts
* My Debts
* Expenses
* Employees
* Reports
* Notifications
* Settings
* Subscription System

These modules behave identically regardless of business type.

---

# Dashboard Behavior

Whenever the administrator changes:

```text
User Type
```

The client application automatically adapts after the next startup.

No reinstall is required.

---

# Dynamic Navigation

Navigation is generated dynamically.

Example:

CAFE:

```text
Home

Customer Debts

Expenses

Employees

PlayStation

Reports

Settings
```

SHOP:

```text
Home

Customer Debts

Expenses

Employees

Shop

Reports

Settings
```

---

# Dynamic Dashboard Cards

Statistics displayed on the Home Dashboard depend on the assigned business type.

Examples:

CAFE:

* Today's Sessions
* Active Devices
* PlayStation Revenue

SHOP:

* Products
* Sales
* Inventory
* Installments

Shared statistics remain visible for both.

---

# Reports

Report categories are also filtered.

CAFE:

Includes:

* PlayStation Revenue
* Session Reports
* Device Usage

SHOP:

Includes:

* Sales Reports
* Product Reports
* Inventory Reports

Shared reports remain available.

---

# Security

The client application hides unsupported modules.

Additionally:

Business logic must also validate userType.

Example:

```text
If userType != CAFE

↓

PlayStation APIs should never execute.
```

UI hiding alone is not considered sufficient protection.

---

# Future Expansion

The architecture supports adding new business types.

Example:

```text
RESTAURANT

PHARMACY

CLINIC

WAREHOUSE
```

Each new type can register:

* Navigation
* Modules
* Reports
* Dashboard Cards

without modifying existing business types.

---

# Edge Cases

## Administrator changes SHOP → CAFE

Result:

* Shop Module disappears.
* PlayStation Module appears.
* Reports update automatically.

---

## Administrator changes CAFE → SHOP

Result:

* PlayStation Module disappears.
* Shop Module appears.
* Shared modules remain unchanged.

---

## Invalid User Type

If an unsupported value is received:

The application should:

* Prevent navigation.
* Display a friendly error screen.
* Log the issue for debugging.

---

# Business Rules

* Every account has exactly one User Type.
* User Type is assigned only by the Dashboard.
* The client application never edits User Type.
* Unsupported modules must never be visible.
* Business logic must validate User Type in addition to UI visibility.
* Shared modules remain available for all supported business types.

---

# Architecture

```text
Dashboard

↓

Assign User Type

↓

Firestore

↓

Client Startup

↓

Download User Document

↓

Read userType

↓

Configure Modules

↓

Home Screen
```

---

# End of Section

Next Section:

**3.8 — Complete Startup Validation Flow**

This section documents the entire application startup process from the Splash Screen until the Home Screen, including authentication, account status validation, subscription validation, platform validation, user type configuration, version checking, offline handling, and navigation decisions.

# PART 3 — Subscription System

# 3.8 Complete Startup Validation Flow

## Overview

The startup process is one of the most critical components of Tahsel.

Every time the application starts, it must determine whether the current user is allowed to use the application before loading any business data.

The startup sequence guarantees that:

* Unauthorized users cannot access the system.
* Expired subscriptions are blocked.
* Platform restrictions are respected.
* Business modules are configured correctly.
* Mandatory updates are enforced.
* Navigation is always deterministic.

The Splash Screen is responsible for orchestrating this entire process.

---

# Startup Sequence

The complete startup flow is:

```text
Application Launch

↓

Initialize Flutter

↓

Initialize Firebase

↓

Load Local Settings

↓

Check Internet Connection

↓

Read Cached Session

↓

Authentication Validation

↓

Download User Document

↓

Validate Account Status

↓

Validate Platform Type

↓

Validate Subscription

↓

Validate App Version

↓

Configure User Type

↓

Load Initial Data

↓

Navigate
```

Every step depends on the success of the previous one.

---

# Step 1 — Application Launch

When the application starts:

* Flutter initializes.
* Theme is loaded.
* Localization is loaded.
* Dependency Injection is initialized.
* Firebase is initialized.

No user validation occurs before Firebase initialization.

---

# Step 2 — Local Configuration

Before contacting Firebase:

The application loads:

* Selected Language
* Theme Mode
* Cached Preferences

These settings are local and do not require authentication.

---

# Step 3 — Internet Detection

The application determines whether internet connectivity is available.

Two modes exist:

### Online Mode

Latest account information can be downloaded.

### Offline Mode

Existing offline rules are applied.

---

# Step 4 — Authentication Check

The application checks:

```text
Current Firebase User
```

Possible outcomes:

No User

↓

Navigate Login

---

Authenticated User

↓

Continue Validation

---

# Step 5 — Download User Document

Using the authenticated UID:

```text
users/{uid}
```

is downloaded.

This document becomes the source of truth for:

* Subscription
* Status
* Platform
* User Type
* Version Rules

---

# Step 6 — Account Status Validation

The application validates:

```text
status
```

Supported values:

```text
Active

Suspended

Disabled

Deleted
```

If validation fails:

The application immediately navigates to the corresponding status screen.

No further validations occur.

---

# Step 7 — Platform Validation

The application detects:

Current Device Platform

and compares it with:

```text
platformType
```

Supported values:

```text
Mobile

Desktop

Both
```

If not compatible:

↓

Platform Restriction Screen

---

# Step 8 — Subscription Validation

Current Date

is compared with:

```text
subscriptionEnd

gracePeriodEnd
```

Possible states:

* Active
* Grace Period
* Expired

---

# Active Subscription

Condition:

```text
Today

<=

Subscription End
```

Access continues.

---

# Grace Period

Condition:

```text
Subscription End

<

Today

<=

Grace End
```

Access is allowed.

The Settings screen displays the remaining grace period.

---

# Expired Subscription

Condition:

```text
Today

>

Grace End
```

Result:

Access denied.

Navigate to:

Expired Subscription Screen.

---

# Step 9 — Version Validation

The Dashboard stores platform-specific version information.

For example:

Android:

* Latest Version
* Build Number
* Force Update
* Update Message

Windows:

Independent configuration.

iOS:

Independent configuration.

The client downloads only the configuration matching its current platform.

---

# Force Update

If:

```text
Current Version

<

Minimum Supported Version
```

and

```text
Force Update = true
```

Result:

Force Update Screen.

The user cannot continue.

---

# Optional Update

If:

```text
Force Update = false
```

An update dialog appears.

User may:

* Update
* Skip

---

# Step 10 — Configure User Type

The application reads:

```text
userType
```

Supported values:

```text
CAFE

SHOP
```

Navigation and modules are generated dynamically.

---

# Step 11 — Load Initial Data

After all validations succeed:

The application begins loading:

* Customers
* Debts
* Expenses
* Employees
* Reports
* PlayStation or Shop module
* Notifications

No business queries occur before validation finishes.

---

# Final Navigation

Possible destinations:

```text
Login Screen
```

```text
Home Screen
```

```text
Platform Restriction
```

```text
Subscription Expired
```

```text
Suspended Screen
```

```text
Disabled Screen
```

```text
Deleted Screen
```

```text
Force Update Screen
```

Only one destination is possible per startup.

---

# Offline Startup

If no internet exists:

The application follows the existing offline strategy.

When connectivity returns:

The next startup downloads the latest account information before granting access.

---

# Logout Handling

Whenever Logout occurs:

The application:

* Clears Firebase session.
* Clears local session.
* Clears cached navigation state.

The next launch starts from the Login Screen.

---

# Error Handling

If the user document cannot be downloaded:

The application should:

* Display a friendly error message.
* Allow retry.
* Avoid crashing.

---

# Loading Experience

During validation:

The Splash Screen remains visible.

No intermediate screens should flash before the final destination.

The startup experience must feel seamless.

---

# Performance Considerations

Startup validation should:

* Execute sequentially.
* Avoid duplicate Firestore requests.
* Download the user document only once.
* Reuse the downloaded data for all validations.

---

# Validation Summary

Validation order:

```text
Firebase Initialization

↓

Authentication

↓

User Document

↓

Account Status

↓

Platform

↓

Subscription

↓

Version

↓

User Type

↓

Load Business Data

↓

Home Screen
```

This order must never change.

---

# Business Rules

* Splash Screen owns the startup flow.
* The user document is downloaded only once.
* Every validation uses the same downloaded document.
* Business data loads only after all validations pass.
* Navigation is deterministic.
* Failed validations stop the startup sequence immediately.
* Offline mode follows the existing synchronization strategy.

---

# Architecture

```text
Splash Screen

↓

Initialize Services

↓

Authentication

↓

Firestore User Document

↓

Status Validation

↓

Platform Validation

↓

Subscription Validation

↓

Version Validation

↓

User Type Configuration

↓

Load Initial Modules

↓

Navigate
```

---

# End of Section

Next Section:

**PART 4 — Dashboard Administration**

The next part documents the complete Dashboard system, including:

* Dashboard Statistics
* User Management
* Search & Filtering
* User Details
* Notes
* Notifications
* Subscription Management
* Version Management (Android / iOS / Windows)
* Activity Logs
* Audit System
* Administrative Business Rules
# PART 4 — Dashboard Administration

## 4.1 Dashboard Overview

### Overview

The Dashboard is the administrative control center of the Tahsel ecosystem.

It is used by the application owner (administrator) to manage all customer accounts, subscriptions, application versions, notifications, and overall system operations.

The Dashboard communicates directly with Firebase and acts as the single source of administrative actions.

End users never access Dashboard functionality.

---

# Main Responsibilities

The Dashboard is responsible for:

* User Management
* Subscription Management
* Platform Assignment
* User Type Assignment
* Application Version Management
* Global Notifications
* User Notes
* Activity Monitoring
* Subscription Validation
* Account Status Control

---

# Supported Platforms

Dashboard supports:

* Windows Desktop (Primary)
* Android (Optional)

The interface is fully responsive and optimized for desktop usage.

---

# Main Navigation

The Dashboard contains the following primary sections:

```text id="4a2nq1"
Dashboard

Users

Notifications

Settings

Activity Logs
```

Future modules can be added without changing the existing navigation structure.

---

# Dashboard Home

The Dashboard Home provides a real-time overview of the system.

Its purpose is to give the administrator immediate insight into the current platform status.

Displayed information includes:

* Total Users
* Active Users
* Disabled Users
* Suspended Users
* Expired Accounts
* Expiring Soon
* Monthly Revenue
* New Users This Month

---

# Dashboard Cards

Each statistic is displayed inside a reusable dashboard card.

Each card contains:

* Icon
* Title
* Numeric Value
* Optional Trend Indicator

The cards automatically update whenever user data changes.

---

# User Management Entry

The Users section is the primary working area of the Dashboard.

From this page the administrator can:

* Search users
* Create users
* Edit users
* Renew subscriptions
* Suspend users
* Disable users
* Delete users
* View notes
* Force logout
* Open user details

---

# Search System

The Dashboard provides an instant search field.

Supported search keys:

* Full Name
* Email Address
* Phone Number
* User ID (UID)

Search updates automatically while typing.

Search should use debounce to prevent unnecessary rebuilds.

---

# Filtering

Future versions may support filtering by:

* Account Status
* Platform Type
* User Type
* Subscription Status
* Expiration Date

The architecture is designed to support these filters without major refactoring.

---

# User List

Each user card displays:

* Full Name
* Email
* Phone Number
* User ID
* Platform Type
* User Type
* Subscription Status
* Remaining Days
* Current Status
* Last Activity

Quick actions are available directly from the list.

---

# Quick Actions

Available quick actions include:

* Open Details
* Renew Subscription
* Extend 30 Days
* Suspend
* Disable
* Activate
* Delete
* Force Logout

These actions allow administrators to perform common tasks without opening the full user profile.

---

# Real-Time Updates

Whenever administrative actions occur:

* Firestore is updated.
* Dashboard UI refreshes.
* Connected Tahsel clients receive the changes during their next startup validation.

The Dashboard always reflects the latest server state.

---

# Design Principles

The Dashboard follows the same design system as Tahsel.

Requirements:

* Responsive Layout
* Dark Mode
* Light Mode
* AppColors
* Shared Typography
* Shared Components

This keeps both applications visually consistent.

---

# Performance

The Dashboard is optimized for large user lists.

Optimizations include:

* Lazy List Rendering
* Debounced Search
* Efficient Firestore Queries
* Minimal Widget Rebuilds
* Cached UI Components

---

# Security

Only authenticated administrators can access the Dashboard.

Regular Tahsel users cannot access any Dashboard functionality.

Administrative actions are always performed through authenticated Firebase sessions.

---

# Architecture

```text id="3fcw8m"
Administrator

↓

Dashboard UI

↓

Cubit

↓

Use Cases

↓

Repository

↓

Firestore
```

The Dashboard follows the same Clean Architecture principles as the Tahsel application.

---

# Business Rules

* Dashboard is the only administrative interface.
* Every administrative action updates Firestore.
* End users never modify administrative fields.
* Dashboard is the source of truth for account management.
* Administrative actions propagate to Tahsel clients through startup validation.

---

# End of Section

Next Section:

**4.2 — User Management**

This section documents the complete user lifecycle, including:

* Create User
* Edit User
* User Details
* Notes
* Renew Subscription
* Suspend
* Disable
* Delete
* Force Logout
* Subscription Extension
* Platform Assignment
* User Type Assignment
* Administrative Business Rules


# PART 3 — Subscription System

# 3.8 Automatic Expiration

## Overview

Tahsel automatically determines whether a subscription is still valid based on the current date and the subscription information stored in Firebase.

The expiration process is fully automatic and requires no manual action from the administrator under normal conditions.

Unlike traditional systems, expiration is not triggered by background servers or Cloud Functions. Instead, it is evaluated whenever the Dashboard or Tahsel application starts.

This design allows the entire subscription system to operate on Firebase's free tier while remaining reliable.

---

# Purpose

Automatic expiration is responsible for:

* Detecting expired subscriptions
* Starting the grace period
* Ending the grace period
* Updating account status
* Preventing unauthorized access
* Keeping Dashboard statistics accurate

---

# Source of Truth

Expiration is calculated using:

```text
subscriptionStart

subscriptionEnd

gracePeriodEnd

accountStatus
```

The current device date must never be trusted.

Instead, all comparisons should rely on the current synchronized date/time whenever possible.

---

# Expiration Flow

```text
Application Starts

↓

Download User Document

↓

Read Subscription Dates

↓

Compare Current Date

↓

Subscription Active?

↓

Yes
↓

Continue

──────────────

No

↓

Inside Grace Period?

↓

Yes

↓

Allow Access

↓

Show Grace Warning

──────────────

No

↓

Mark Expired

↓

Logout

↓

Expired Screen
```

---

# Subscription Active

Condition:

```text
Current Date <= Subscription End
```

Result:

* User can use the application normally.
* Remaining days are calculated.
* No warning is displayed.

---

# Grace Period Begins

Once:

```text
Current Date

>

Subscription End
```

the subscription becomes expired.

However, access is still allowed until:

```text
Grace Period End
```

During this period:

* User can continue working.
* Dashboard still considers the account in Grace Period.
* Settings screen displays the remaining grace days.

---

# Grace Period Ends

Condition:

```text
Current Date

>

Grace Period End
```

Result:

The account is no longer allowed to access Tahsel.

The application immediately:

* Clears the current session.
* Navigates to Expired Screen.
* Prevents all business operations.

---

# Dashboard Behavior

The Dashboard automatically detects expired users.

Their status changes from:

```text
Active
```

to:

```text
Expired
```

without requiring manual intervention.

Dashboard statistics update accordingly.

---

# Daily Validation

Expiration is checked every time:

* Dashboard starts.
* Tahsel starts.

No scheduled background service is required.

---

# Remaining Days Calculation

Remaining days are calculated dynamically.

Formula:

```text
Remaining Days

=

Subscription End

-

Current Date
```

Values should never be stored permanently.

---

# Grace Days Calculation

If the subscription has expired:

```text
Grace Remaining

=

Grace End

-

Current Date
```

When the value reaches zero:

The account becomes inaccessible.

---

# Negative Values

Negative remaining days should never be displayed.

Instead:

* Remaining Days = 0
* Grace Days = 0

The application transitions to the appropriate status screen.

---

# Subscription Renewal

Whenever the administrator renews a subscription:

The following values are recalculated:

* Subscription Start
* Subscription End
* Grace Period End
* Remaining Days

The account immediately returns to Active status.

---

# Reactivation

If an expired account is renewed:

The user regains access automatically on the next application launch.

No additional setup is required.

---

# Offline Considerations

Offline mode must never extend a subscription.

If the application cannot verify subscription information:

Existing offline synchronization rules are applied until the next successful validation.

---

# Performance

Expiration validation requires only:

* One Firestore document
* One comparison
* One navigation decision

No additional collections are queried.

---

# Security

Users cannot modify:

* Subscription dates
* Grace dates
* Account status

These fields are controlled exclusively by the Dashboard.

---

# Business Rules

* Subscription validity is always calculated dynamically.
* Remaining days are never permanently stored.
* Grace period begins immediately after subscription expiration.
* Expired users cannot access the application.
* Dashboard remains the single source of truth for subscription data.
* Automatic expiration works without Cloud Functions.

---

# Architecture

```text
Application Start

↓

Download User Document

↓

Read Subscription Dates

↓

Calculate Remaining Days

↓

Validate Grace Period

↓

Allow Access

OR

Navigate to Expired Screen
```

---

# End of Section

Next Section:

**3.9 — Daily Checker**

This section explains how the Dashboard performs the daily account validation process, automatically updates expired users, refreshes statistics, and keeps the system synchronized without relying on Cloud Functions.

# PART 3 — Subscription System

# 3.9 Daily Checker

## Overview

The Daily Checker is responsible for keeping all subscriptions synchronized without relying on Cloud Functions or any paid backend services.

Instead of running continuously on a server, the Dashboard performs the validation automatically whenever it is opened by the administrator.

This approach was intentionally chosen to keep the project compatible with the Firebase free tier while maintaining reliable subscription management.

---

# Purpose

The Daily Checker is responsible for:

* Detecting expired subscriptions
* Detecting expired grace periods
* Updating account status
* Refreshing Dashboard statistics
* Preparing Tahsel clients for the next startup validation
* Keeping all subscription information consistent

---

# Trigger

The Daily Checker executes automatically when:

* Dashboard starts.
* Dashboard returns from background (optional future enhancement).
* Administrator manually refreshes the Dashboard (optional).

No manual button is required during normal operation.

---

# Startup Flow

```text
Dashboard Starts

↓

Administrator Login

↓

Initialize Firebase

↓

Run Daily Checker

↓

Validate All Users

↓

Update Expired Accounts

↓

Refresh Dashboard Statistics

↓

Load Dashboard UI
```

The Daily Checker always executes before the Dashboard becomes fully interactive.

---

# User Validation

Each user document is inspected individually.

The checker reads:

```text
subscriptionEnd

gracePeriodEnd

accountStatus
```

No business collections are involved.

---

# Validation Logic

For every user:

## Case 1 — Subscription Active

Condition:

```text
Current Date

<=

Subscription End
```

Result:

No changes.

---

## Case 2 — Grace Period

Condition:

```text
Subscription End

<

Current Date

<=

Grace Period End
```

Result:

* Account remains Active.
* Grace period continues.
* No status modification.

---

## Case 3 — Grace Period Finished

Condition:

```text
Current Date

>

Grace Period End
```

Result:

The checker updates:

```text
accountStatus

=

Expired
```

No administrator interaction is required.

---

# Account Status Update

Only users whose status changes are written back to Firestore.

Users that are already valid are ignored.

This minimizes unnecessary database writes.

---

# Dashboard Statistics Refresh

After validation completes:

Dashboard statistics are recalculated.

Examples:

* Total Users
* Active Users
* Expired Users
* Suspended Users
* Disabled Users
* Expiring Soon

All cards immediately reflect the latest state.

---

# Expiring Soon

The Dashboard also identifies subscriptions that will expire soon.

Recommended threshold:

```text
7 Days
```

These users appear inside:

```text
Expiring Soon
```

This allows the administrator to renew subscriptions before they expire.

---

# Firestore Optimization

The Daily Checker should:

* Read user documents only once.
* Update only changed users.
* Batch writes whenever possible.
* Avoid multiple reads for the same document.

This reduces Firestore usage significantly.

---

# Failure Handling

If validation fails:

* Dashboard should continue loading.
* An error message may be logged.
* Existing user data should remain unchanged.
* The administrator may retry by refreshing the Dashboard.

No account should be modified when validation fails.

---

# Performance

The checker must remain lightweight.

Requirements:

* Single pass through users.
* No nested queries.
* No unnecessary rebuilds.
* Efficient batch updates.

Even with thousands of users, validation should remain responsive.

---

# Security

Only the Dashboard can execute the Daily Checker.

Tahsel clients never modify:

* accountStatus
* subscriptionEnd
* gracePeriodEnd

Tahsel clients only read these values.

---

# Relationship with Tahsel

The Dashboard determines account validity.

Tahsel enforces account validity.

This separation guarantees that business logic exists in one place while client applications remain simple and secure.

---

# Example Timeline

```text
01 Jul

Subscription Ends

↓

01–10 Jul

Grace Period

↓

11 Jul

Administrator Opens Dashboard

↓

Daily Checker Executes

↓

Account Status

↓

Expired

↓

Next Tahsel Startup

↓

User Redirected to Expired Screen
```

---

# Cloud Functions

The Daily Checker intentionally replaces Cloud Functions.

Advantages:

* No paid Firebase plan required.
* Simpler architecture.
* Easier maintenance.
* Lower operational cost.

The only requirement is that the administrator opens the Dashboard periodically (ideally once per day).

---

# Business Rules

* Daily Checker executes automatically when Dashboard starts.
* No manual action is normally required.
* Only changed users are updated.
* Firestore writes are minimized.
* Dashboard is responsible for updating account statuses.
* Tahsel never updates subscription states.
* Cloud Functions are not required.

---

# Architecture

```text
Dashboard Startup

↓

Daily Checker

↓

Read Users

↓

Validate Subscription

↓

Update Changed Accounts

↓

Refresh Statistics

↓

Dashboard Ready
```

---

# End of Section

Next Section:

**3.10 — Tahsel Side**

This section documents how the Tahsel application consumes subscription information from Firebase, validates user access at startup, displays subscription information in the Settings screen, enforces account restrictions, and synchronizes with the Dashboard without duplicating business logic.

# PART 3 — Subscription System

# 3.10 Tahsel Side

## Overview

The Tahsel application is responsible for enforcing all subscription and account validation rules defined by the Dashboard.

Unlike the Dashboard, Tahsel never modifies subscription information. It only reads the latest user document from Firebase and reacts accordingly.

This guarantees that all business decisions originate from a single source of truth while keeping the client application lightweight and secure.

---

# Responsibilities

Tahsel is responsible for:

* Authenticating the user.
* Downloading the latest user profile.
* Validating account status.
* Validating platform permissions.
* Validating subscription status.
* Validating grace period.
* Loading application configuration.
* Loading force update configuration.
* Loading localization.
* Starting the application only after all validations succeed.

Tahsel does **not**:

* Renew subscriptions.
* Change subscription dates.
* Modify account status.
* Modify platform assignments.
* Modify user type.

These actions are reserved exclusively for the Dashboard.

---

# Startup Sequence

Every application launch follows the same validation sequence.

```text id="pwq6rs"
Splash Screen

↓

Firebase Initialize

↓

Restore Login Session

↓

Download User Document

↓

Validate Account Status

↓

Validate Platform

↓

Validate Subscription

↓

Validate App Version

↓

Load User Data

↓

Open Main Application
```

If any validation fails, startup stops immediately and the appropriate screen is displayed.

---

# Downloaded User Information

Tahsel downloads the latest user document before loading any business data.

The following fields are considered essential:

```text id="g0s8lu"
uid

email

fullName

accountStatus

subscriptionStart

subscriptionEnd

gracePeriodEnd

platformType

userType

forceLogoutVersion

latestAppVersion

forceUpdate

createdAt
```

Additional fields may be added in future versions without changing the validation flow.

---

# Source of Truth

Tahsel always trusts Firebase.

Local cached values are never considered authoritative for:

* Subscription dates
* Account status
* Platform permissions
* Version information

Whenever internet is available, Firebase data overrides local cache.

---

# Account Validation

After downloading the user document:

Tahsel validates:

```text id="it0lrq"
accountStatus
```

Possible values include:

* Active
* Disabled
* Suspended
* Deleted
* Expired

Each status has its own dedicated handling flow.

---

# Platform Validation

Tahsel validates:

```text id="ofztvn"
platformType
```

Supported values:

```text id="5wlc4s"
mobile

desktop

both
```

Examples:

Mobile application:

* mobile → Allowed
* both → Allowed
* desktop → Rejected

Desktop application:

* desktop → Allowed
* both → Allowed
* mobile → Rejected

This guarantees that subscriptions are respected across supported platforms.

---

# User Type

Tahsel also downloads:

```text id="nq5kpl"
userType
```

Supported values:

```text id="kn0zjlwm"
CAFE

SHOP
```

The application uses this value to determine which business modules should be enabled.

Example:

CAFE users:

* PlayStation Module
* Café-specific workflows

SHOP users:

* Shop Inventory
* Installments
* Product Sales

Future user types can be introduced without changing the startup architecture.

---

# Subscription Validation

Tahsel validates:

```text id="03j7df"
subscriptionEnd

gracePeriodEnd
```

Possible outcomes:

* Subscription Active
* Grace Period
* Expired

Only one state can exist at a time.

---

# Force Update Validation

Tahsel downloads:

```text id="rjlwmk"
latestVersion

forceUpdate

updateMessage

downloadUrl
```

The application compares its current version with the Dashboard configuration.

If an update is required:

Optional Update:

User may continue.

Mandatory Update:

Application access is blocked until the update is installed.

Each platform uses its own update configuration.

Android never reads Windows configuration.

Windows never reads iOS configuration.

iOS never reads Android configuration.

---

# Force Logout

The Dashboard can invalidate active sessions.

Tahsel compares:

```text id="jlwmqg"
forceLogoutVersion
```

If the server value is newer than the local value:

The application:

* Clears session
* Clears cached credentials
* Returns to Login Screen

This allows administrators to remotely terminate sessions.

---

# Loading Business Data

Business collections are loaded **only after** all startup validations succeed.

Examples:

* Customers
* Debts
* Expenses
* Employees
* Installments
* PlayStation Sessions

No business data should be requested before account validation completes.

---

# Offline Behavior

If internet is unavailable:

Tahsel follows the existing offline synchronization strategy.

However:

Subscription information cannot be permanently trusted while offline.

Once internet becomes available:

The full startup validation executes again.

---

# Performance

Startup validation is intentionally lightweight.

Typical startup requires:

* One user document
* One version document
* Minimal comparisons

Business collections are loaded afterward.

This keeps application startup fast even with large datasets.

---

# Security

Tahsel never assumes local values are correct.

Critical decisions always depend on Firebase.

Users cannot bypass:

* Subscription expiration
* Platform restrictions
* Disabled accounts
* Forced logout
* Mandatory updates

---

# Business Rules

* Firebase is the single source of truth.
* Tahsel never modifies subscription information.
* Startup validation always runs before loading business data.
* Platform restrictions are always enforced.
* Version validation executes before entering the application.
* Business collections load only after successful validation.
* Local cache never overrides server decisions.

---

# Architecture

```text id="7mclwu"
Tahsel Startup

↓

Restore Session

↓

Download User

↓

Validate Account

↓

Validate Platform

↓

Validate Subscription

↓

Validate Version

↓

Load Business Data

↓

Open Main Layout
```

---

# End of Section

Next Section:

**3.11 — Settings Screen**

This section documents the subscription information displayed inside the Settings screen, including remaining days, subscription dates, grace period, account status, renewal actions, and platform information.
# PART 3 — Subscription System

# 3.11 Settings Screen

## Overview

The Settings screen is the central place where users can view information related to their account and application status.

Its purpose is to provide transparency about the user's subscription, account status, application version, and platform permissions without exposing administrative operations.

The Settings screen is **informational only** regarding subscription management. Users cannot renew or modify their subscription directly from within the application.

---

# Objectives

The Settings screen allows users to:

* View account information.
* View subscription details.
* View remaining subscription time.
* View grace period information.
* View account status.
* View assigned platform.
* View account type.
* Change application language.
* Change theme.
* Delete account.
* Logout.

---

# Sections

The screen is divided into logical sections:

```text id="a91m2k"
Profile

↓

Subscription

↓

Application

↓

Preferences

↓

Danger Zone
```

---

# Profile Section

Displays basic user information.

Fields include:

```text id="qpl82m"
Full Name

Email

Phone Number

User ID (optional)
```

These fields are read-only.

---

# Subscription Section

This section displays all subscription-related information.

Displayed items:

* Subscription Start Date
* Subscription End Date
* Grace Period End
* Remaining Days
* Account Status

Everything is downloaded directly from Firebase.

---

# Subscription Start

Display:

```text id="o8pnfw"
Subscription Started

01 July 2026
```

Read only.

---

# Subscription End

Display:

```text id="ow8dti"
Subscription Ends

31 July 2026
```

Read only.

---

# Grace Period End

Display:

```text id="1c6g4v"
Grace Period Ends

10 August 2026
```

Visible only after the subscription has expired.

If the subscription is still active, this field may remain hidden or displayed with a descriptive label depending on the UI design.

---

# Remaining Days

Calculated dynamically.

Formula:

```text id="gv0d0m"
Remaining Days

=

Subscription End

-

Current Date
```

Example:

```text id="d04h5r"
18 Days Remaining
```

Negative values must never appear.

---

# Account Status

Possible values:

```text id="ktc0pv"
Active

Grace Period

Expired

Suspended

Disabled

Deleted
```

Each status is accompanied by an appropriate icon and color.

Example:

Active → Green

Grace Period → Orange

Expired → Red

Disabled → Gray

Suspended → Amber

---

# Platform Information

Displays the allowed platform.

Possible values:

```text id="qmyj3g"
Mobile

Desktop

Both
```

This information helps users understand where their account is permitted to operate.

---

# User Type

Displays the business category assigned by the Dashboard.

Possible values:

```text id="9zy0jq"
Cafe

Shop
```

Future business types can be added without changing the Settings architecture.

---

# Application Section

Displays application information.

Items include:

* Current App Version
* Build Number
* Last Sync Time (optional)
* Language
* Theme

These values are informational only.

---

# Preferences

Users can configure:

* Language
* Dark Mode
* Light Mode
* System Theme (optional future enhancement)

Preference changes are applied immediately.

---

# Logout

The Logout button:

* Clears the active session.
* Removes locally cached authentication data.
* Preserves synchronized business data according to the existing offline strategy.
* Returns the user to the Login screen.

Logout never deletes the account.

---

# Delete Account

The Settings screen includes a dedicated **Delete Account** button to comply with App Store requirements.

Workflow:

```text id="5fd3py"
Delete Account

↓

Confirmation Dialog

↓

User Confirms

↓

Delete Account Request

↓

Logout

↓

Login Screen
```

The confirmation dialog should clearly explain that:

* The account will be permanently removed.
* Access to the application will no longer be possible.
* This action cannot be undone.

The dialog must **not** mention subscription cancellation or billing.

---

# iOS Compliance

On iOS:

The Settings screen must **not** contain:

* Subscription renewal buttons.
* Pricing information.
* External payment links.
* WhatsApp purchase links.
* Landing Page purchase shortcuts.

This ensures compliance with App Store Guideline 3.1.1.

---

# Android & Windows

Android and Windows may include additional informational shortcuts if desired.

However, subscription management remains outside the application and is handled by the Dashboard administrator.

---

# Localization

All texts must use the ARB localization system.

Supported languages:

* Arabic
* English

No hardcoded strings are allowed.

---

# UI Guidelines

The screen must follow the existing design system.

Requirements:

* AppColors only.
* TextStyles only.
* Fully responsive.
* Dark Mode support.
* Light Mode support.
* Consistent spacing.
* Existing reusable widgets.

---

# Performance

The Settings screen should reuse the user document already downloaded during startup.

It must not trigger unnecessary Firestore requests every time the screen is opened.

---

# Security

Users cannot edit:

* Subscription dates
* Platform type
* User type
* Account status

These values are read-only and controlled exclusively by the Dashboard.

---

# Business Rules

* Subscription information is informational only.
* Remaining days are calculated dynamically.
* Subscription dates are read-only.
* Delete Account is always available.
* Logout never deletes user data.
* Platform information is read-only.
* User type is read-only.
* No purchase or renewal flow is exposed inside the iOS application.

---

# Architecture

```text id="n41m6b"
Settings Screen

↓

Load Cached User

↓

Display Profile

↓

Display Subscription

↓

Display Platform

↓

Display Preferences

↓

Display Logout

↓

Display Delete Account
```

---

# End of Section

Next Section:

**3.12 — Expired UI**

This section documents the dedicated screens shown when a subscription expires, including the user experience for expired accounts, grace period completion, blocked access, logout behavior, and platform-specific handling.
# PART 3 — Subscription System

# 3.12 Expired UI

## Overview

The Expired UI is a dedicated screen displayed when a user's subscription has completely expired and the grace period has ended.

Its purpose is to clearly explain why access has been restricted while providing a professional user experience consistent with the rest of the application.

Unlike ordinary dialogs, the Expired UI completely replaces the application interface. Users cannot access any business data until their account becomes active again.

---

# Objectives

The Expired UI should:

* Explain why the application cannot continue.
* Display subscription information.
* Display expiration information.
* Prevent access to business modules.
* Allow the user to sign out.
* Support localization.
* Support Dark Mode.
* Support Light Mode.
* Follow the existing design system.

---

# When It Appears

The screen appears immediately after startup validation if:

```text id="z2jwma"
Current Date

>

Grace Period End
```

OR

```text id="b8xlxv"
accountStatus

=

Expired
```

The user must never enter the Main Layout before this validation completes.

---

# Startup Flow

```text id="hv4e2k"
Splash Screen

↓

Restore Session

↓

Download User

↓

Validate Subscription

↓

Expired

↓

Expired Screen
```

The Home Screen is never opened.

---

# Screen Layout

Recommended layout:

```text id="xy6m3v"
Illustration

↓

Title

↓

Description

↓

Subscription Information

↓

Buttons
```

The screen should remain simple and easy to understand.

---

# Illustration

Display an illustration representing:

* Subscription expired
* Locked access
* Calendar expiration

Avoid alarming or aggressive imagery.

The style should match the application's overall branding.

---

# Title

Example:

```text id="v5tg7m"
Subscription Expired
```

Localized using ARB files.

---

# Description

Explain that:

* The subscription has expired.
* The grace period has also ended.
* Access is temporarily unavailable.
* The user's business data remains محفوظة (safe).
* Access will be restored automatically once the administrator renews the subscription.

Do not mention payment methods.

---

# Information Card

Display:

```text id="1ff8um"
Subscription End

Grace Period End

Today's Date

Account Status
```

These values help the user understand why access is blocked.

---

# Status Badge

Display:

```text id="ff2rmj"
Expired
```

Recommended color:

Red.

---

# Buttons

The screen contains only two actions.

## Logout

Action:

* Clear session.
* Return to Login Screen.

---

## Contact Support

On Android and Windows:

Opens WhatsApp conversation with the predefined support number.

Suggested message:

```text id="0l5jti"
Hello,

My subscription has expired.

I would like to renew my account.
```

---

## iOS

To remain compatible with App Store policies:

The Contact Support button should:

* Open the Support page, OR
* Open the official support website.

It must **not** initiate a purchase flow or advertise subscription pricing.

---

# User Restrictions

While this screen is displayed:

Users cannot access:

* Customers
* Debts
* Expenses
* Employees
* PlayStation
* Reports
* Settings
* Synchronization
* Offline Queue

The application remains fully locked.

---

# Navigation Rules

Back navigation must be disabled.

Android back button:

Ignored.

Desktop close button:

Allowed.

The only available navigation options are:

* Logout
* Contact Support

---

# Offline Behavior

If the account has already been determined to be expired:

Offline mode must not bypass the restriction.

The application remains blocked until a successful online validation confirms that the subscription has been renewed.

---

# Automatic Recovery

If the administrator renews the subscription in the Dashboard:

Next application launch:

```text id="1uvb3t"
Download User

↓

Subscription Active

↓

Main Layout
```

The Expired Screen disappears automatically.

No application update is required.

---

# Localization

All text uses ARB localization.

Supported languages:

* Arabic
* English

No hardcoded text.

---

# UI Requirements

Must follow:

* AppColors
* TextStyles
* Existing Button widgets
* Existing Dialog style
* Responsive layout
* Dark Mode
* Light Mode

The design should remain visually consistent with the Login Screen.

---

# Accessibility

Buttons must be large enough for touch interaction.

Text must remain readable on:

* Phones
* Tablets
* Windows

Icons should include semantic labels where applicable.

---

# Security

The screen is not dismissible.

Users cannot bypass it by:

* Back navigation
* Deep links
* Opening another screen
* Restoring a previous route

The validation result controls the entire application state.

---

# Performance

The screen uses the user data already downloaded during startup.

No additional Firebase requests should occur while it is displayed.

---

# Business Rules

* Display only after grace period ends.
* Home screen must never open first.
* Business data remains preserved.
* Logout is always available.
* Android and Windows may provide a support shortcut.
* iOS must avoid purchase-related actions.
* Next startup automatically re-validates the subscription.

---

# Architecture

```text id="lnn18d"
Splash

↓

Subscription Validation

↓

Expired

↓

Expired Screen

↓

Logout

OR

↓

Support

↓

Next Startup

↓

Subscription Renewed

↓

Home Screen
```

---

# End of Section

Next Section:

**3.13 — Disabled UI**

This section documents the user experience when an account has been manually disabled by the administrator, including startup validation, blocked access, UI behavior, logout flow, and recovery process.
# PART 3 — Subscription System

# 3.13 Disabled UI

## Overview

The Disabled UI is displayed when an administrator manually disables a user's account from the Dashboard.

Unlike an expired subscription, a disabled account is an administrative decision. The user is authenticated correctly, but access has been intentionally revoked.

The application must immediately prevent access to all business data while clearly informing the user about the account status.

---

# Objectives

The Disabled UI should:

* Clearly explain that the account has been disabled.
* Prevent access to every application module.
* Display account status.
* Allow the user to log out.
* Provide a way to contact support.
* Preserve all business data.
* Follow the existing design system.

---

# Trigger Conditions

The Disabled UI is displayed when:

```text id="m7jd9a"
accountStatus

=

Disabled
```

This validation happens during every application startup.

---

# Startup Flow

```text id="u8dk1f"
Splash Screen

↓

Restore Session

↓

Download User Document

↓

Validate Account Status

↓

Disabled

↓

Disabled Screen
```

The Main Layout must never be opened.

---

# Why an Account Becomes Disabled

A disabled account may occur because:

* Administrative action.
* Violation of terms.
* Security concerns.
* Duplicate accounts.
* Requested account deactivation.
* Internal business decision.

Tahsel does not determine the reason.

Only the Dashboard controls this status.

---

# Screen Layout

Recommended layout:

```text id="j9fh2m"
Illustration

↓

Title

↓

Description

↓

Status Card

↓

Buttons
```

---

# Illustration

Suggested illustration:

* Shield
* Locked Account
* User Disabled

The design should remain friendly and professional.

---

# Title

Example:

```text id="q1kp5s"
Account Disabled
```

Localized through ARB.

---

# Description

Explain:

* The account has been disabled.
* Login is currently restricted.
* Business data has not been deleted.
* Access may be restored after administrator review.

Avoid mentioning subscriptions or payments.

---

# Status Card

Display:

```text id="y5nw8p"
Status

Disabled

Last Validation

Current Date
```

Optionally display:

* User ID
* Email

---

# Status Badge

Display:

```text id="fw4r2x"
Disabled
```

Recommended color:

Gray.

---

# Buttons

The screen contains two actions.

---

## Logout

Action:

* Clear authentication session.
* Return to Login Screen.

---

## Contact Support

Android & Windows:

Open support through WhatsApp.

Suggested message:

```text id="vt2n8z"
Hello,

My account has been disabled.

Could you please review my account?
```

---

iOS:

Open the support page or website.

Do not initiate any purchase flow.

---

# User Restrictions

While Disabled:

Users cannot access:

* Dashboard Data
* Customers
* Debts
* Expenses
* Employees
* Reports
* Installments
* PlayStation Module
* Synchronization
* Offline Queue

Everything remains locked.

---

# Offline Behavior

If the account was previously validated as Disabled:

Offline mode must not unlock the application.

The Disabled screen remains active until a successful online validation changes the account status.

---

# Automatic Recovery

Administrator changes:

```text id="a7px3r"
Disabled

↓

Active
```

Next startup:

```text id="y8dq4b"
Download User

↓

Validate Status

↓

Active

↓

Open Main Layout
```

No manual action is required from the user except reopening the application.

---

# Localization

All strings must use:

* Arabic ARB
* English ARB

No hardcoded messages.

---

# UI Requirements

Must support:

* Dark Mode
* Light Mode
* Responsive Layout
* AppColors
* TextStyles
* Existing button components
* Existing typography system

The screen should visually match the Login and Expired screens.

---

# Security

The Disabled screen cannot be bypassed by:

* Back navigation
* Route manipulation
* Offline cache
* Deep links

Only Firebase validation determines access.

---

# Performance

No additional Firestore requests are required after the startup validation completes.

The Disabled screen uses the already downloaded user document.

---

# Business Rules

* Only the Dashboard can disable accounts.
* Disabled accounts cannot access any business data.
* Business data is preserved.
* Logout remains available.
* Contact Support is available.
* Recovery happens automatically after administrator reactivates the account.
* Startup validation always takes precedence over cached state.

---

# Architecture

```text id="c5rw9m"
Splash

↓

Restore Session

↓

Download User

↓

Validate Account

↓

Disabled

↓

Disabled Screen

↓

Logout

OR

↓

Support

↓

Administrator Reactivates

↓

Next Startup

↓

Home Screen
```

---

# End of Section

Next Section:

**3.14 — Grace Period**

This section documents the complete Grace Period lifecycle, including how the 10-day grace period is calculated, user experience during the grace period, startup validation, remaining grace days calculation, automatic transition to Expired status, and all related business rules.

# PART 3 — Subscription System

# 3.14 Grace Period

## Overview

The Grace Period is a temporary access window that begins immediately after a user's subscription expires.

Its purpose is to provide users with a short period during which they can continue using Tahsel while arranging a subscription renewal with the administrator.

The Grace Period is **not** a subscription extension. It is a business rule that temporarily delays account lockout.

---

# Objectives

The Grace Period exists to:

* Prevent sudden service interruption.
* Give businesses time to renew.
* Reduce accidental account lockouts.
* Improve user experience.
* Preserve business continuity.

---

# Duration

Current implementation:

```text id="3fa2m1"
Grace Period

=

10 Days
```

The duration is configurable from the Dashboard if future requirements change.

---

# Timeline

Example:

```text id="o81xp7"
Subscription Start

01 July

↓

Subscription End

31 July

↓

Grace Period Starts

01 August

↓

Grace Period Ends

10 August

↓

11 August

Account Locked
```

---

# Calculation

Formula:

```text id="w91ta8"
Grace End Date

=

Subscription End Date

+

10 Days
```

Example:

```text id="p73vdc"
Subscription End

20 July

↓

Grace End

30 July
```

---

# Remaining Grace Days

Formula:

```text id="6af9z2"
Remaining Grace Days

=

Grace End Date

-

Current Date
```

Negative values must never be shown.

---

# Startup Validation

Every application launch performs:

```text id="bt1kr5"
Restore Session

↓

Download User

↓

Current Date

↓

Compare

↓

Subscription End

↓

Grace End

↓

Decision
```

---

# Decision Tree

```text id="d8kt52"
Subscription Active

↓

Open App


Subscription Expired

↓

Inside Grace

↓

Open App


Grace Finished

↓

Expired Screen
```

---

# User Experience During Grace Period

The user can continue using:

* Customers
* Debts
* Expenses
* Employees
* Reports
* Installments
* PlayStation
* Synchronization
* Offline Mode

The application behaves exactly like an active subscription.

The only difference is that the account status becomes:

```text id="7dnv2a"
Grace Period
```

---

# Settings Screen

The Settings screen displays:

```text id="wh3x19"
Subscription End

Grace Period End

Remaining Grace Days

Current Status
```

Example:

```text id="zb62w4"
Subscription End

31 July

Grace Ends

10 August

Remaining

4 Days
```

---

# Account Status

During this period:

```text id="m3aw82"
Status

=

Grace Period
```

Recommended badge color:

Orange.

---

# Notifications

Tahsel itself does not automatically notify the user.

The Dashboard administrator may optionally send reminders through the existing notification system.

Examples:

* WhatsApp
* SMS
* Push Notification (future)

---

# Administrator Renewal

If the administrator renews the subscription during the Grace Period:

```text id="x0tf68"
Grace Period

↓

Renew

↓

Active
```

The next startup immediately restores the account to:

```text id="r7lv83"
Active
```

No additional migration is required.

---

# Grace Period Expiration

Once:

```text id="q8mw91"
Current Date

>

Grace End Date
```

The account immediately becomes:

```text id="g2fc94"
Expired
```

The user is redirected to the Expired Screen.

---

# Offline Behavior

Offline mode cannot extend the Grace Period.

If the last online validation confirms that:

```text id="j6bz15"
Grace Period Finished
```

The application remains blocked.

The Grace Period is always determined using server-synchronized account data.

---

# Platform Independence

The Grace Period behaves identically on:

* Android
* iOS
* Windows

No platform-specific rules exist.

---

# Data Preservation

During the Grace Period:

* No customer data is removed.
* No debts are modified.
* No expenses are deleted.
* No employees are affected.
* No reports are regenerated.

Business data remains fully intact.

---

# Security Rules

Users cannot:

* Reset the Grace Period.
* Modify dates locally.
* Extend remaining days.
* Bypass expiration through offline mode.
* Change device time to gain extra access.

All validation is based on trusted account information.

---

# Performance

The Grace Period check occurs only during application startup.

It reuses the user document already downloaded during authentication.

No additional Firebase requests are required.

---

# Edge Cases

## Renewal On Final Grace Day

Example:

```text id="n4vt83"
Grace Ends

10 August

↓

Renewed

10 August

↓

Status

Active
```

The account never reaches the Expired state.

---

## Renewal After Expiration

Example:

```text id="m1fy48"
Grace Ends

10 August

↓

11 August

Expired Screen

↓

Administrator Renews

↓

Next Startup

↓

Home Screen
```

Recovery is automatic.

---

## Device Offline

If the application cannot verify updated account data after previously reaching the Expired state:

The application remains locked until successful synchronization.

---

# Business Rules

* Grace Period begins immediately after Subscription End.
* Default duration is 10 days.
* Users retain full application functionality during Grace Period.
* Remaining Grace Days are calculated dynamically.
* Expired status begins immediately after Grace End.
* Administrator renewal instantly restores Active status.
* Business data is never modified by Grace Period logic.
* Grace Period cannot be extended locally.

---

# Architecture

```text id="c7hk31"
Subscription End

↓

Grace Period Starts

↓

User Continues Working

↓

Daily Startup Validation

↓

Grace Finished?

↓

Yes

↓

Expired Screen

↓

Administrator Renews

↓

Next Startup

↓

Active Account
```

---

# End of Section

Next Section:

**3.15 — Logout Flow**

This section documents every logout scenario in Tahsel, including manual logout, forced logout from the Dashboard, logout caused by subscription expiration, account suspension, account deletion, session invalidation, token cleanup, and navigation behavior across all supported platforms.

# PART 3 — Subscription System

# 3.15 Logout Flow

## Overview

The Logout Flow defines every scenario in which a user session ends within Tahsel.

Its purpose is to guarantee:

* Secure session termination.
* Consistent behavior across Android, iOS, and Windows.
* Complete cleanup of locally stored authentication data.
* Automatic handling of administrator-initiated session invalidation.
* Protection against unauthorized access.

Logout behavior is centralized and must be identical regardless of platform.

---

# Logout Types

Tahsel supports the following logout scenarios:

1. Manual Logout
2. Forced Logout
3. Session Expired
4. Account Disabled
5. Account Suspended
6. Account Deleted
7. Platform Restriction
8. Subscription Validation Failure
9. Authentication Failure

Each scenario eventually reaches the same logout process.

---

# 1. Manual Logout

The user presses:

```text id="lg01"
Settings

↓

Logout
```

---

## Process

```text id="lg02"
User Presses Logout

↓

Confirmation Dialog

↓

Confirm

↓

Clear Local Session

↓

Navigate Login Screen
```

---

## Confirmation Dialog

Display:

Title:

```text id="lg03"
Logout
```

Message:

```text id="lg04"
Are you sure you want to logout?
```

Buttons:

* Cancel
* Logout

---

## Local Cleanup

Manual logout clears:

* Firebase Authentication session
* Cached User
* Saved UID
* Saved Email
* Saved Remember Login flag
* Local Session Cache
* Temporary Runtime Data

Business data stored in Firebase remains untouched.

---

# Navigation

After logout:

```text id="lg05"
Login Screen
```

The user must never return to the previous route using the back button.

Navigation stack should be cleared.

---

# 2. Forced Logout

The Dashboard administrator can invalidate all active sessions.

Example:

```text id="lg06"
Dashboard

↓

Force Logout

↓

Save

↓

User Opens App

↓

Session Invalid

↓

Logout
```

---

## Startup Validation

During startup:

```text id="lg07"
Restore Session

↓

Download User

↓

Check Session Version

↓

Invalid

↓

Logout
```

---

# User Experience

Show a dialog:

Example:

```text id="lg08"
Your session has expired.

Please login again.
```

After confirmation:

Navigate Login Screen.

---

# 3. Subscription Validation Failure

Startup sequence:

```text id="lg09"
Restore Session

↓

Subscription Validation

↓

Expired

↓

Expired Screen
```

This is **not** a logout.

The authentication session remains valid.

The user can still:

* Logout manually.

The application simply blocks access.

---

# 4. Disabled Account

Startup:

```text id="lg10"
Restore Session

↓

Disabled

↓

Disabled Screen
```

Authentication remains valid.

User chooses:

```text id="lg11"
Logout
```

Only then is the session removed.

---

# 5. Suspended Account

Same behavior:

```text id="lg12"
Restore Session

↓

Suspended

↓

Suspended Screen
```

Logout remains optional.

---

# 6. Deleted Account

Deleted accounts behave differently.

Startup:

```text id="lg13"
Restore Session

↓

Deleted

↓

Immediately Logout

↓

Login Screen
```

Reason:

Deleted accounts should not keep authenticated sessions.

---

# 7. Platform Restriction

Example:

Dashboard:

```text id="lg14"
Platform

=

Desktop
```

User opens Android app.

Startup:

```text id="lg15"
Platform Validation

↓

Not Allowed

↓

Platform Screen
```

The session remains authenticated.

The user may:

* Logout
* Close the application

---

# 8. Authentication Failure

Examples:

* Firebase token invalid.
* Refresh token expired.
* Authentication revoked.

Flow:

```text id="lg16"
Authentication Error

↓

Logout

↓

Login Screen
```

---

# Session Restoration

When opening Tahsel:

```text id="lg17"
Launch

↓

Has Session?

↓

Yes

↓

Restore

↓

Validate User

↓

Continue
```

---

# Remember Login

Tahsel supports automatic login.

If enabled:

```text id="lg18"
App Opens

↓

Restore Saved Session

↓

Validate

↓

Main Layout
```

Manual logout removes this capability.

---

# Navigation Rules

Logout always clears:

```text id="lg19"
Navigation Stack
```

The Login Screen becomes the root route.

---

# Offline Behavior

If already authenticated:

Offline launch:

```text id="lg20"
Restore Session

↓

Offline Validation

↓

Open Cached State
```

If previous validation required logout:

The application must remain logged out.

---

# Security

Logout must remove:

* Cached Tokens
* Cached User
* Remember Login
* Session Cache
* Temporary Authentication Objects

Sensitive information must never remain in memory after logout.

---

# Performance

Logout performs only local cleanup.

No expensive synchronization is required.

Firebase SignOut should complete before navigation.

---

# Edge Cases

## Logout While Sync Running

Flow:

```text id="lg21"
Sync

↓

Logout

↓

Cancel Pending Operations

↓

Cleanup

↓

Login Screen
```

---

## Logout During Startup

If the user manually logs out while initialization is still running:

Initialization should immediately stop.

---

## Multiple Windows (Desktop)

Future support:

Logging out from one application instance should invalidate all active windows for that user.

---

## Account Deleted During Active Session

Dashboard:

```text id="lg22"
Delete User
```

Next validation:

```text id="lg23"
Deleted

↓

Logout

↓

Login
```

---

# Business Rules

* Logout always clears local authentication data.
* Business data is never deleted during logout.
* Manual logout requires confirmation.
* Forced logout bypasses manual confirmation.
* Deleted accounts always trigger automatic logout.
* Expired, Suspended, and Disabled states display dedicated screens before optional logout.
* Navigation stack must always be cleared.
* Logout behavior is identical across Android, iOS, and Windows.

---

# Architecture

```text id="lg24"
User

↓

Logout Request

↓

Clear Session

↓

Firebase SignOut

↓

Clear Local Cache

↓

Reset Navigation

↓

Login Screen
```

---

# End of Section

Next Section:

**3.16 — Edge Cases**

This section documents every subscription-related edge case, including renewal timing, administrator actions, offline scenarios, multi-device synchronization, platform switching, session conflicts, grace period transitions, and all exceptional business scenarios that Tahsel must handle consistently.
# PART 3 — Subscription System

# 3.16 Edge Cases

## Overview

This section documents every exceptional subscription scenario that Tahsel must handle correctly.

These are situations that occur infrequently but are critical for ensuring data integrity, business continuity, and predictable user behavior.

Every edge case must produce deterministic behavior without corrupting subscription data or user access.

---

# Edge Case 1 — Renew Before Subscription Expires

## Scenario

Current Date:

```text
15 July
```

Subscription End:

```text
30 July
```

Administrator renews the subscription early.

---

## Expected Behavior

The remaining subscription period must not be lost.

Example:

```text
Current End

30 July

+

30 Days

=

29 August
```

Do **not** restart from today's date.

---

# Business Rule

Renewal extends from the current Subscription End when the subscription is still active.

---

# Edge Case 2 — Renew During Grace Period

## Scenario

```text
Subscription End

30 July

Grace

31 July → 9 August

Today

5 August
```

Administrator renews.

---

## Expected Behavior

The account immediately returns to:

```text
Active
```

Grace Period is cancelled automatically.

---

# New Dates

Subscription Start:

Current Date

Subscription End:

Current Date + Purchased Duration

---

# Edge Case 3 — Renew After Grace Ends

## Scenario

```text
Subscription End

30 July

Grace Ends

9 August

Today

12 August
```

Administrator renews.

---

## Expected Behavior

User launches application.

Startup validation:

```text
Expired

↓

Renewed

↓

Active
```

The Expired Screen disappears automatically.

---

# Edge Case 4 — Multiple Renewals

Administrator performs:

```text
Renew

↓

Renew Again

↓

Renew Again
```

---

## Expected Behavior

Subscription duration accumulates correctly.

No duplicate calculations.

No lost days.

---

# Edge Case 5 — User Logged In During Renewal

Administrator renews while the user is actively using Tahsel.

---

## Expected Behavior

Current session continues.

Next validation immediately reflects:

```text
Active
```

No restart required.

---

# Edge Case 6 — Account Disabled During Session

User is currently working.

Administrator presses:

```text
Disable
```

---

## Expected Behavior

Next validation:

```text
Disabled

↓

Disabled Screen
```

User immediately loses access to business modules.

---

# Edge Case 7 — Account Suspended During Session

Same flow.

Startup or refresh:

```text
Suspended

↓

Suspended Screen
```

---

# Edge Case 8 — Account Deleted During Session

Dashboard:

```text
Delete User
```

---

## Expected Behavior

Application performs:

```text
Delete

↓

Logout

↓

Login Screen
```

Deleted accounts never remain authenticated.

---

# Edge Case 9 — Force Logout During Session

Administrator:

```text
Force Logout
```

---

## Expected Behavior

Next validation:

```text
Session Invalid

↓

Logout

↓

Login
```

---

# Edge Case 10 — Device Time Changed

User manually changes:

* Date
* Time
* Timezone

---

## Expected Behavior

Subscription calculations must **never** depend on local device time.

Validation relies only on trusted subscription information downloaded from Firebase.

---

# Edge Case 11 — Internet Lost During Grace Period

Current state:

```text
Grace Period
```

Internet disconnects.

---

## Expected Behavior

Application continues operating using the last valid subscription state.

No unexpected logout occurs.

---

# Edge Case 12 — Internet Lost After Expiration

Previous validation:

```text
Expired
```

User goes offline.

---

## Expected Behavior

Application remains locked.

Offline mode must never reactivate an expired account.

---

# Edge Case 13 — Wrong Platform

Dashboard:

```text
Platform

Desktop Only
```

User installs Android.

---

## Expected Behavior

Platform validation fails.

Display Platform Restriction Screen.

Business data remains inaccessible.

---

# Edge Case 14 — Platform Changed

Administrator changes:

```text
Desktop

↓

Both
```

---

## Expected Behavior

Next validation immediately allows access.

No logout required.

---

# Edge Case 15 — Subscription Shortened

Administrator manually reduces remaining subscription days.

---

## Expected Behavior

New dates become effective immediately.

If today's date exceeds the new expiration:

Grace Period begins instantly.

---

# Edge Case 16 — Subscription Set To Zero Days

Administrator creates:

```text
Subscription

0 Days
```

---

## Expected Behavior

Subscription immediately enters:

Grace Period

No negative durations.

---

# Edge Case 17 — Corrupted Local Cache

Cached user:

Missing.

Firebase:

Valid.

---

## Expected Behavior

Restore everything from Firebase.

Never trust incomplete local cache.

---

# Edge Case 18 — Firebase Temporarily Unavailable

Startup cannot download user document.

---

## Expected Behavior

If previous validation exists:

Continue using last verified state.

Otherwise:

Display connection error.

Do not guess subscription status.

---

# Edge Case 19 — Simultaneous Dashboard Updates

Two administrators update:

* Subscription
* Platform
* Status

at nearly the same time.

---

## Expected Behavior

Latest successful Firebase write becomes the source of truth.

No duplicated calculations.

---

# Edge Case 20 — Multiple Devices

Same account:

Android

Windows

iPhone

---

## Expected Behavior

All devices observe identical subscription status after synchronization.

---

# Edge Case 21 — Application Updated

User installs a newer version.

---

## Expected Behavior

Subscription information remains unchanged.

Only application binaries are updated.

---

# Edge Case 22 — First Login After Renewal

User was previously expired.

Administrator renews.

User logs in again.

---

## Expected Behavior

Application skips Expired Screen completely.

Startup enters:

```text
Active

↓

Home
```

---

# Edge Case 23 — Logout During Validation

User presses Logout while startup validation is still executing.

---

## Expected Behavior

Cancel validation.

Clear session.

Navigate Login Screen.

---

# Edge Case 24 — Reinstall Application

User uninstalls Tahsel.

Installs again.

Logs in.

---

## Expected Behavior

Subscription data is restored from Firebase.

Nothing depends on local storage.

---

# Edge Case 25 — Trial Ends (Future Support)

If Trial accounts are introduced later:

Trial expiration follows the same lifecycle:

```text
Trial

↓

Grace

↓

Expired
```

No separate implementation should exist.

---

# Business Rules

* Subscription dates must never become negative.
* Grace Period begins automatically after expiration.
* Renewal immediately restores Active status.
* Platform restrictions override valid subscriptions.
* Deleted accounts always logout.
* Disabled accounts always display Disabled Screen.
* Suspended accounts always display Suspended Screen.
* Offline mode never extends subscriptions.
* Firebase is always the source of truth.
* Local cache is used only for temporary continuity.

---

# Testing Checklist

The following scenarios must be verified before every production release:

* Renew before expiration.
* Renew during Grace Period.
* Renew after expiration.
* Disable account.
* Suspend account.
* Delete account.
* Force logout.
* Platform mismatch.
* Platform reassignment.
* Multiple renewals.
* Offline startup.
* Online recovery.
* Device time manipulation.
* Multiple devices synchronization.
* Firebase unavailable.
* Corrupted cache recovery.
* Logout during validation.
* Reinstall application.
* Version update.
* Daily expiration check.

All scenarios must produce deterministic behavior without data loss.

---

# End of Section

Next Section:

**3.17 — Business Rules**

This final section consolidates all subscription system rules into a single authoritative specification, defining the source of truth, lifecycle constraints, validation order, administrator permissions, user permissions, and the non-negotiable business rules that govern Tahsel's subscription system.

# PART 3 — Subscription System

# 3.17 Business Rules

## Overview

This section defines the official business rules governing the entire subscription system.

Every component of Tahsel — including the Dashboard, Tahsel application, Firebase structure, startup validation, and future services — must comply with these rules.

These rules take precedence over implementation details.

---

# Source of Truth

The Dashboard is the only authority responsible for subscription management.

Only the Dashboard may:

* Create users.
* Renew subscriptions.
* Extend subscriptions.
* Shorten subscriptions.
* Suspend accounts.
* Disable accounts.
* Delete accounts.
* Change platform permissions.
* Change user type.

Tahsel never modifies subscription-related information.

---

# Firebase Source of Truth

Firebase is the authoritative storage for:

* Subscription dates
* Account status
* Platform type
* User type
* Application version
* Force update configuration
* Force logout version

Local storage is only a temporary cache.

---

# Authentication Rule

A successful Firebase Authentication login **does not automatically grant application access**.

Access is granted only after all startup validations succeed.

Authentication and authorization are treated as separate concepts.

---

# Startup Validation Order

The validation sequence is fixed.

```text id="br01"
Splash

↓

Restore Session

↓

Download User

↓

Validate Account Status

↓

Validate Platform

↓

Validate Subscription

↓

Validate Version

↓

Load Business Data

↓

Open Main Layout
```

This order must never be changed.

---

# Subscription Rule

Every account has:

```text id="br02"
Subscription Start

Subscription End

Grace Period End
```

Subscription status is always derived from these dates.

No manual flags should replace date calculations.

---

# Grace Period Rule

Grace Period begins immediately after:

```text id="br03"
Subscription End
```

Default duration:

```text id="br04"
10 Days
```

Users continue working normally during Grace Period.

---

# Expiration Rule

An account becomes Expired when:

```text id="br05"
Current Date

>

Grace Period End
```

No additional administrator action is required.

---

# Daily Checker Rule

Dashboard executes the Daily Checker automatically when it starts.

Responsibilities:

* Detect expired users.
* Update statuses.
* Refresh statistics.

Cloud Functions are intentionally not required.

---

# Platform Rule

Allowed platform values:

```text id="br06"
mobile

desktop

both
```

Every startup validates platform compatibility.

Unsupported platforms must never enter the application.

---

# User Type Rule

Supported business categories:

```text id="br07"
CAFE

SHOP
```

The assigned user type determines which business modules are available.

Future user types may be introduced without modifying the startup architecture.

---

# Account Status Rule

Supported statuses:

```text id="br08"
Active

Grace Period

Expired

Disabled

Suspended

Deleted
```

Exactly one status applies at any time.

---

# Dashboard Ownership Rule

Only the Dashboard may change:

* Subscription dates.
* Account status.
* Platform type.
* User type.
* Force update configuration.
* Force logout version.

Tahsel has read-only access.

---

# Renewal Rule

Renewing an active subscription extends the existing expiration date.

Renewing an expired subscription starts a new subscription from the renewal date.

Grace Period ends immediately upon successful renewal.

---

# Logout Rule

Logout always:

* Clears authentication.
* Clears local session.
* Clears cached credentials.
* Resets navigation.

Logout never deletes business data.

---

# Business Data Rule

Subscription events never modify:

* Customers
* Debts
* Expenses
* Employees
* Installments
* PlayStation Sessions
* Reports

Business data remains intact regardless of account status.

---

# Offline Rule

Offline mode exists for business continuity only.

Offline mode must never:

* Extend subscriptions.
* Bypass expiration.
* Ignore disabled accounts.
* Ignore platform restrictions.

Once online, Firebase immediately becomes the source of truth again.

---

# Version Rule

Each platform has independent update settings.

Supported platforms:

* Android
* iOS
* Windows

Each platform maintains:

* Version Name
* Build Number
* Download URL
* Update Message
* Force Update Flag

No platform reads another platform's configuration.

---

# Security Rule

The client application must never trust:

* Device date
* Device time
* Cached subscription values
* Cached account status

Every startup performs server validation before granting access.

---

# Synchronization Rule

All devices connected to the same account observe identical subscription status after synchronization.

No device maintains an independent subscription state.

---

# Delete Rule

Deleted accounts:

* Cannot login.
* Cannot restore sessions.
* Are automatically logged out.
* Cannot access business data.

---

# Disabled Rule

Disabled accounts:

* Remain authenticated until logout.
* Cannot access business modules.
* Display the Disabled Screen.

---

# Suspended Rule

Suspended accounts behave similarly to Disabled accounts but represent a temporary administrative restriction.

---

# Performance Rule

Startup validation should:

* Download the user document once.
* Download version configuration once.
* Avoid redundant Firestore reads.
* Delay business collection loading until validation completes.

---

# Localization Rule

All subscription-related UI must use:

* Arabic ARB
* English ARB

No hardcoded strings are permitted.

---

# UI Rule

All subscription screens must follow the design system.

Requirements:

* AppColors
* TextStyles
* Responsive Layout
* Dark Mode
* Light Mode
* Existing reusable widgets

---

# Apple Compliance Rule

The iOS application must not expose:

* External purchase links.
* Subscription pricing.
* WhatsApp renewal buttons.
* Landing Page purchase shortcuts.
* Account registration flows leading to purchases.

Subscription management occurs outside the application.

---

# Android & Windows Rule

Android and Windows may expose additional support shortcuts where platform policies permit.

The core subscription validation remains identical across all platforms.

---

# Future Scalability Rule

The subscription architecture must support future additions without breaking existing behavior.

Possible future extensions include:

* Trial subscriptions.
* Enterprise plans.
* Multiple subscription tiers.
* Additional platform types.
* Additional business categories.
* Cloud Functions (optional).
* Organization-level subscriptions.

---

# Golden Rules

The following rules are absolute:

1. Firebase is the single source of truth.
2. Dashboard owns subscription management.
3. Tahsel only consumes subscription data.
4. Startup validation always executes before loading business data.
5. Business data is never deleted due to subscription expiration.
6. Grace Period always lasts 10 days unless configured otherwise.
7. Platform validation always precedes application access.
8. Version validation always occurs before entering the application.
9. Offline mode never bypasses business rules.
10. Every platform follows the same subscription lifecycle.

---

# Complete Subscription Lifecycle

```text id="br09"
Dashboard Creates User

↓

Subscription Active

↓

User Works Normally

↓

Subscription Ends

↓

Grace Period (10 Days)

↓

Daily Checker

↓

Expired

↓

User Sees Expired Screen

↓

Administrator Renews

↓

Next Startup Validation

↓

Subscription Active

↓

Home Screen
```

---

# Architecture Summary

```text id="br10"
Dashboard

↓

Firebase

↓

Tahsel Startup Validation

↓

Business Rules

↓

Application Access
```

---

# End of PART 3

**PART 3 — Subscription System** is now complete.

The next major section is:

# **PART 4 — Dashboard Administration**

This part documents every administrative feature in the Dashboard, including user management, statistics, notifications, audit logs, version management, application updates, search, notes, analytics, and administrator workflows.

# PART 4 — Dashboard Administration

# 4.1 Overview

## Introduction

The Dashboard is the administrative control center of the Tahsel ecosystem.

It is responsible for managing:

* Users
* Subscriptions
* Application Versions
* Notifications
* Reports
* Platform Restrictions
* Security Policies

The Dashboard is the only component allowed to modify business-critical account information.

Tahsel clients (Android, iOS, Windows) are **read-only** regarding administrative operations.

---

# Objectives

The Dashboard is designed to:

* Manage all users.
* Monitor subscription lifecycle.
* Control application updates.
* Monitor application activity.
* Send notifications.
* Maintain business integrity.
* Prevent unauthorized access.
* Support future scalability.

---

# Supported Platforms

Dashboard currently supports:

* Windows

Future support:

* Web Dashboard
* macOS
* Linux

The internal architecture should remain platform-independent.

---

# Authentication

Only administrators can access the Dashboard.

Authentication requires:

* Valid Firebase Authentication
* Administrator Role
* Active Account

Regular Tahsel users must never access Dashboard routes.

---

# Main Navigation

The Dashboard sidebar is divided into logical modules.

```text id="db01"
Dashboard

↓

Users

↓

Notifications

↓

Audit Logs

↓

Version Management

↓

Settings
```

Future modules can be added without changing the navigation architecture.

---

# Dashboard Home

The Dashboard Home provides an overview of the entire system.

It serves as the administrator's landing page after login.

---

# Dashboard Responsibilities

The Dashboard is responsible for:

* Creating users.
* Managing subscriptions.
* Viewing statistics.
* Sending notifications.
* Updating application versions.
* Monitoring account activity.
* Managing platform permissions.
* Managing business categories.

Tahsel applications consume this data but never modify it.

---

# Source of Truth

The Dashboard owns all administrative decisions.

Examples:

* Subscription renewal
* User suspension
* Account deletion
* Platform assignment
* User type assignment
* Version configuration
* Forced updates
* Forced logout

Firebase stores these decisions.

Tahsel clients synchronize with Firebase.

---

# Security Model

Permissions are centralized.

Only administrators may:

* Create users
* Delete users
* Suspend accounts
* Disable accounts
* Change subscriptions
* Modify versions

Regular users have no administrative privileges.

---

# Dashboard Layout

Recommended structure:

```text id="db02"
Sidebar

↓

Header

↓

Statistics

↓

Content Area

↓

Dialogs
```

The layout should remain responsive for different screen sizes.

---

# Sidebar Modules

Current modules:

```text id="db03"
Dashboard

Users

Notifications

Audit

Versions

Settings
```

Future modules should integrate seamlessly.

---

# Header

Displays:

* Administrator Name
* Logout Button
* Current Version
* Active Language

Optional future additions:

* Notification Bell
* Quick Search
* Profile Menu

---

# Dashboard Theme

Supports:

* Dark Mode
* Light Mode

Uses:

* AppColors
* TextStyles

No hardcoded colors.

---

# Localization

Supported languages:

* Arabic
* English

Every administrative string must exist in:

* app_ar.arb
* app_en.arb

---

# Performance

Dashboard should:

* Minimize Firestore reads.
* Reuse downloaded collections.
* Avoid rebuilding entire screens.
* Paginate large datasets when necessary.

---

# Business Rules

* Dashboard is the only administrative authority.
* Every administrative operation is persisted in Firebase.
* Tahsel clients consume Dashboard decisions.
* Administrator authentication is mandatory.
* Dashboard actions must remain auditable.

---

# Architecture

```text id="db04"
Administrator

↓

Dashboard

↓

Cubit

↓

UseCases

↓

Repository

↓

Firebase

↓

Tahsel Clients
```

---

# End of Section

Next Section:

**4.2 Dashboard Statistics**

This section documents all statistics displayed on the Dashboard home screen, including user counts, subscription metrics, revenue indicators, expiring accounts, and real-time administrative insights.

# PART 4 — Dashboard Administration

# 4.2 Dashboard Statistics

## Overview

The Dashboard Statistics screen provides administrators with a real-time overview of the entire Tahsel ecosystem.

Rather than navigating through individual modules, administrators can immediately understand the health of the system from the Dashboard Home.

Statistics are informational only and do not directly modify data.

---

# Objectives

The Dashboard Statistics module should:

* Display system health.
* Monitor subscription status.
* Monitor business growth.
* Highlight important actions.
* Help administrators identify problems quickly.

---

# Data Source

All statistics are calculated from Firebase.

The Dashboard itself does not permanently store calculated values.

Whenever possible, values should be derived from the current data rather than cached totals.

---

# Statistics Cards

The Home Dashboard displays the following cards.

---

# Total Users

Displays:

```text id="ds01"
Total Registered Users
```

Includes:

* Active
* Grace Period
* Expired
* Suspended
* Disabled

Does NOT include:

Soft-deleted accounts.

---

# Active Users

Displays:

```text id="ds02"
Currently Active Accounts
```

Condition:

```text id="ds03"
Status == Active
```

These users can currently access Tahsel.

---

# Expired Users

Displays:

```text id="ds04"
Expired Accounts
```

Condition:

```text id="ds05"
Current Date > Grace Period End
```

These accounts require administrator renewal.

---

# Grace Period Users

Displays:

```text id="ds06"
Accounts Inside Grace Period
```

Condition:

```text id="ds07"
Subscription End < Today

AND

Today <= Grace End
```

These users still have access.

---

# Disabled Users

Displays:

```text id="ds08"
Disabled Accounts
```

Condition:

```text id="ds09"
Status == Disabled
```

---

# Suspended Users

Displays:

```text id="ds10"
Suspended Accounts
```

Condition:

```text id="ds11"
Status == Suspended
```

---

# Deleted Users

Displays:

```text id="ds12"
Deleted Accounts
```

Soft-deleted users are counted separately for administrative purposes.

---

# Expiring Soon

Displays:

```text id="ds13"
Subscriptions Expiring Soon
```

Definition:

Subscriptions ending within the administrator-defined warning period.

Current recommendation:

```text id="ds14"
Remaining Days

<=

7
```

---

# New Users This Month

Displays:

```text id="ds15"
New Users
```

Calculation:

Users created during the current calendar month.

---

# User Distribution

Future visualization.

Displays:

* Shop Users
* Cafe Users

Based on:

```text id="ds16"
User Type
```

---

# Platform Distribution

Displays:

Number of users assigned to:

* Mobile
* Desktop
* Both

Based on:

```text id="ds17"
Platform Type
```

This helps administrators understand platform adoption.

---

# Revenue Indicator (Optional)

If subscription pricing is tracked in future versions:

Dashboard may display:

```text id="ds18"
Estimated Monthly Revenue
```

Current implementation:

Hidden.

---

# Quick Health Indicators

Dashboard should visually highlight:

* Expired users
* Grace Period users
* Disabled accounts
* Force Update enabled
* Pending administrator actions

These indicators improve operational awareness.

---

# Refresh Strategy

Statistics refresh automatically:

* When Dashboard opens.
* After any user update.
* After subscription renewal.
* After account deletion.
* After status changes.

Manual refresh should also be available.

---

# Empty State

If there are no users:

Display:

```text id="ds19"
No users found.
```

Instead of empty statistic cards.

---

# Loading State

While statistics are loading:

Display skeleton cards matching the final layout.

Avoid sudden layout shifts.

---

# Error State

If statistics cannot be loaded:

Display:

```text id="ds20"
Unable to load dashboard statistics.
```

Provide:

Retry Button.

---

# Performance

Statistics should:

* Avoid downloading unnecessary collections.
* Use aggregation where possible.
* Minimize Firestore reads.
* Recalculate only affected values after updates.

---

# UI Requirements

Statistics Cards must support:

* Dark Mode
* Light Mode
* Responsive Layout
* Windows scaling
* Existing AppColors
* Existing TextStyles

Cards should have consistent spacing and elevation.

---

# Future Analytics

The Dashboard architecture should support adding:

* Daily Active Users
* Monthly Active Users
* User Retention
* Average Subscription Length
* Churn Rate
* Renewal Rate
* Platform Growth
* Business Category Growth
* Revenue Trends

without redesigning the Home screen.

---

# Business Rules

* Statistics are read-only.
* Firebase remains the source of truth.
* Deleted users are excluded from Total Users.
* Grace Period users are counted separately from Expired users.
* Statistics refresh automatically after administrative actions.
* Dashboard cards never modify business data.

---

# Architecture

```text id="ds21"
Firebase

↓

Repository

↓

Dashboard Statistics UseCase

↓

Dashboard Cubit

↓

Statistics State

↓

Dashboard Home
```

---

# End of Section

Next Section:

**4.3 User Search**

This section documents the global user search engine, including searching by name, email, phone number, UID, subscription status, platform type, business type, and performance optimizations such as debounce and indexed queries.
# PART 4 — Dashboard Administration

# 4.3 User Search

## Overview

The User Search module allows administrators to quickly locate any account in the system.

As the number of users grows, efficient search becomes critical for support, subscription management, troubleshooting, and daily administration.

The search experience must remain fast, responsive, and scalable even with tens of thousands of users.

---

# Objectives

The search system should allow administrators to:

* Find users instantly.
* Search using multiple criteria.
* Reduce navigation time.
* Support future filtering capabilities.
* Minimize Firebase reads.
* Remain responsive on slow networks.

---

# Search Entry Point

The search bar is located at the top of the Users screen.

Example layout:

```text
Search Bar

[ 🔍 Search by Name, Email, Phone or UID ]
```

---

# Supported Search Fields

The administrator can search using:

* Full Name
* Partial Name
* Email Address
* Phone Number
* User UID
* Notes (optional future)

The search engine should automatically determine which field matches the entered text.

---

# Search by Full Name

Example:

```text
Ahmed Mohamed
```

Returns:

Users whose full name matches.

---

# Search by Partial Name

Example:

```text
Ahmed
```

Should return:

* Ahmed Ali
* Ahmed Hassan
* Mohamed Ahmed
* Ahmed Mahmoud

Search should not require exact matches.

---

# Search by Email

Example:

```text
ahmed@gmail.com
```

Returns the exact account.

---

# Search by Phone Number

Example:

```text
01012345678
```

Returns:

Matching user.

Phone formatting differences should be ignored where possible.

---

# Search by UID

Example:

```text
U-849235
```

Returns:

Exactly one user.

UID search should always have the highest priority.

---

# Search Results

Each result card displays:

* Profile Image (if available)
* Full Name
* Email
* Phone Number
* User Type
* Platform Type
* Subscription Status
* Remaining Days

Example:

```text
Ahmed Ali

ahmed@gmail.com

01012345678

Shop

Desktop

Active

28 Days Remaining
```

---

# Result Ordering

Priority:

1. Exact UID
2. Exact Email
3. Exact Phone
4. Exact Name
5. Partial Name

This improves search accuracy.

---

# Empty Search

If the search field is empty:

Display:

Entire users list.

No filtering occurs.

---

# No Results

Display:

```text
No matching users found.
```

Optionally suggest:

* Check spelling.
* Try another search term.

---

# Search Performance

Searching should not execute on every keystroke.

Use:

```text
Debounce

300 ms
```

This prevents unnecessary Firebase reads and Cubit rebuilds.

---

# Local Filtering

If the user list has already been loaded:

Filtering should occur locally.

Avoid repeated Firebase requests whenever possible.

---

# Remote Search

For very large datasets:

Future versions may:

* Query Firestore directly.
* Use indexed fields.
* Paginate results.

The architecture should support this without UI changes.

---

# Search State

Cubit states:

```text
Idle

↓

Typing

↓

Searching

↓

Results

↓

Empty

↓

Error
```

---

# Loading Indicator

While searching:

Display a lightweight loading indicator.

Avoid blocking the entire screen.

---

# Search Persistence

If the administrator opens User Details and returns:

The previous search text should remain.

Results should also remain visible.

This improves workflow efficiency.

---

# Keyboard Behavior

Desktop:

* Enter → optional search trigger.
* Escape → clear search.
* Ctrl + F (future support) → focus search field.

Mobile:

* Search keyboard action.

---

# Search Filters (Future)

Future filters may include:

* Active Users
* Expired Users
* Grace Period
* Disabled
* Suspended
* Deleted
* Shop
* Cafe
* Mobile
* Desktop
* Both Platforms

Filters should integrate with the existing search engine.

---

# Security

Search results are visible only to authenticated administrators.

Regular Tahsel users never have access to this functionality.

---

# Performance Rules

The search system must:

* Use debounce.
* Avoid unnecessary rebuilds.
* Avoid downloading duplicate user lists.
* Reuse cached collections.
* Keep UI responsive.

---

# Business Rules

* Search is case-insensitive.
* UID search has highest priority.
* Empty search displays all users.
* Search supports partial matches.
* Search results update instantly after user modifications.
* Debounce is mandatory.
* Search never modifies user data.

---

# Architecture

```text
Administrator

↓

Search Field

↓

Debounce

↓

Dashboard Cubit

↓

Search UseCase

↓

Repository

↓

Firebase / Local Cache

↓

Filtered Results
```

---

# End of Section

Next Section:

**4.4 User Details**

This section documents the complete User Details screen, including profile information, subscription information, platform assignment, business type, statistics, notes, administrative actions (renew, suspend, disable, delete, force logout), and all related business rules.

# PART 4 — Dashboard Administration

# 4.4 User Details

## Overview

The User Details screen is the central administrative page for managing an individual Tahsel account.

After selecting a user from the Users list, administrators are navigated to this screen, where they can view all account information and perform authorized administrative actions.

This screen serves as the primary operational workspace for user management.

---

# Objectives

The User Details screen allows administrators to:

* View complete account information.
* Monitor subscription status.
* Review business usage statistics.
* Manage subscriptions.
* Manage account status.
* Add internal notes.
* Force logout active sessions.
* Reset passwords.
* Send notifications.
* Access audit information.

---

# Screen Layout

Recommended layout:

```text id="ud01"
App Bar

↓

Profile Card

↓

Subscription Card

↓

Usage Statistics

↓

Internal Notes

↓

Administrative Actions
```

Each section is visually separated using reusable cards.

---

# App Bar

Displays:

* User Name
* Back Button
* Optional More Menu (Future)

---

# Profile Card

Displays basic user information.

Fields:

* Full Name
* Email Address
* Phone Number
* User UID
* Created Date
* Last Login Date

Example:

```text id="ud02"
Ahmed Ali

ahmed@gmail.com

01012345678

UID-847392

Created

12 May 2026

Last Login

26 June 2026
```

---

# Profile Image

If available:

Display user's avatar.

Otherwise:

Generate initials avatar.

Example:

```text id="ud03"
AA
```

---

# Copy Actions

Administrator can copy:

* UID
* Email
* Phone Number

Each action displays:

```text id="ud04"
Copied Successfully
```

---

# Account Status Card

Displays:

Current Status

Possible values:

* Active
* Grace Period
* Expired
* Disabled
* Suspended
* Deleted

Each status has a dedicated badge color.

---

# Subscription Card

Displays:

* Subscription Start
* Subscription End
* Grace Period End
* Remaining Days

Example:

```text id="ud05"
Subscription Start

01 July

Subscription End

31 July

Grace Ends

10 August

Remaining

22 Days
```

Remaining Days are calculated dynamically.

---

# Platform Information

Displays:

Platform Type

Supported values:

* Mobile
* Desktop
* Both

Example:

```text id="ud06"
Desktop + Mobile
```

---

# Business Type

Displays:

User Category

Supported values:

* Shop
* Cafe / PlayStation

Future business types can be added.

---

# Usage Statistics

Displays high-level business metrics.

Current cards:

* Customers
* Debts
* Expenses
* Employees
* Transactions

These values are informational only.

---

# Internal Notes

Administrators may save private notes.

Notes are:

* Visible only inside Dashboard.
* Never synchronized to Tahsel users.

Examples:

```text id="ud07"
Customer requested yearly subscription.

Call before renewal.

VIP Client.
```

---

# Edit Notes

Actions:

```text id="ud08"
Add Note

Edit Note

Delete Note
```

Changes are saved immediately.

---

# Force Logout

Administrator can terminate all active sessions.

Flow:

```text id="ud09"
Press

Force Logout

↓

Confirm

↓

Update Session Version

↓

User Logs Out Automatically
```

---

# Password Reset

Action:

```text id="ud10"
Send Password Reset Email
```

Firebase sends the email directly.

Dashboard does not handle passwords.

---

# Quick Subscription Actions

Buttons:

* Renew
* Extend
* Shorten

Each opens its corresponding dialog.

---

# Renew

Purpose:

Start or extend subscription.

Administrator selects:

* Duration

Confirmation required.

---

# Extend

Adds predefined duration.

Current implementation:

```text id="ud11"
+30 Days
```

Future versions may support:

* 7 Days
* 15 Days
* 90 Days
* Custom Duration

---

# Shorten

Allows reducing remaining subscription duration.

Validation:

Remaining duration must never become negative.

---

# Suspend Account

Flow:

```text id="ud12"
Suspend

↓

Confirmation

↓

Update Firebase

↓

Success
```

User sees Suspended Screen on next validation.

---

# Disable Account

Flow:

```text id="ud13"
Disable

↓

Confirmation

↓

Firebase

↓

Disabled Screen
```

---

# Activate Account

Available when:

Status is:

* Disabled
* Suspended

Action:

```text id="ud14"
Activate
```

Restores Active status.

---

# Delete Account

Delete is a **soft delete**.

Flow:

```text id="ud15"
Delete

↓

Confirmation

↓

Status

Deleted
```

Business data remains stored.

---

# Confirmation Dialogs

Every destructive action requires confirmation.

Examples:

* Suspend
* Disable
* Delete
* Shorten Subscription
* Force Logout

---

# Success Messages

Examples:

```text id="ud16"
Subscription Updated

User Suspended

Account Activated

Password Reset Sent

Session Terminated
```

---

# Error Handling

Examples:

```text id="ud17"
Unable to update subscription.

Please try again.
```

Provide Retry where appropriate.

---

# Loading State

Administrative actions display:

* Button loading indicator.
* Disable repeated clicks.
* Prevent duplicate requests.

---

# Real-Time Refresh

After any successful action:

Refresh:

* Subscription Card
* Status Card
* Remaining Days
* Notes
* Statistics

Without leaving the screen.

---

# Security

Only authenticated administrators may access User Details.

Users cannot open this screen from Tahsel.

---

# Performance

The screen should:

* Download user document once.
* Reuse loaded statistics.
* Refresh only changed sections.
* Avoid rebuilding the entire page.

---

# Business Rules

* UID is immutable.
* Email changes follow Firebase Authentication rules.
* Subscription dates are Dashboard-controlled.
* Force Logout invalidates all active sessions.
* Delete performs soft deletion.
* Notes are Dashboard-only.
* Every destructive action requires confirmation.
* Real-time refresh occurs after successful updates.

---

# Architecture

```text id="ud18"
User List

↓

Select User

↓

User Details Screen

↓

Dashboard Cubit

↓

User Management UseCases

↓

Repository

↓

Firebase

↓

Updated UI
```

---

# End of Section

Next Section:

**4.5 User Management Actions**

This section documents every administrative operation available for managing users, including Create User, Edit User, Renew Subscription, Extend Subscription, Suspend, Disable, Activate, Delete, Force Logout, Reset Password, and the complete lifecycle and business rules for each action.
# PART 4 — Dashboard Administration

# 4.5 User Management Actions

## Overview

This section documents every administrative action that can be performed on a user account.

These actions are available from the **User Details** screen and represent the core operational capabilities of the Dashboard.

All actions must follow the same architecture:

```text
UI

↓

Cubit

↓

UseCase

↓

Repository

↓

Firebase

↓

Refresh User Details
```

Every successful action immediately updates the Dashboard UI.

---

# 4.5.1 Create User

## Overview

The Dashboard is responsible for creating all Tahsel accounts.

Tahsel applications never allow users to register themselves.

---

## Required Fields

The administrator must provide:

* Full Name
* Email
* Phone Number
* Password
* Subscription Duration
* Platform Type
* User Type

---

## Generated Automatically

During creation:

* UID
* Created At
* Subscription Start
* Subscription End
* Grace End
* Status
* Last Login
* Session Version
* App Version Metadata

---

## Initial Status

New accounts always begin as:

```text
Active
```

---

## Default Subscription

Example:

```text
30 Days
```

Configurable by administrator.

---

## Platform Assignment

Administrator chooses:

* Mobile
* Desktop
* Both

This controls where login is permitted.

---

## User Type

Administrator selects:

* Shop
* Cafe / PlayStation

Future business types can be added.

---

## Success Flow

```text
Create User

↓

Firebase Authentication

↓

Firestore Document

↓

Success

↓

Refresh Users List
```

---

# 4.5.2 Edit User

Administrators may edit:

* Full Name
* Phone Number
* Notes
* Platform Type
* User Type

Not editable:

* UID
* Created At

Email changes should follow Firebase Authentication rules.

---

# 4.5.3 Renew Subscription

Purpose:

Renew expired accounts or extend active subscriptions.

---

## Required Input

Administrator chooses:

* Subscription Duration

Example:

```text
30 Days

90 Days

365 Days
```

---

## Business Rule

If subscription is active:

Extend existing end date.

If expired:

Start new subscription from today.

---

# 4.5.4 Extend Subscription

Quick administrative action.

Example:

```text
+30 Days
```

Adds days without changing other account information.

---

# 4.5.5 Shorten Subscription

Allows administrators to reduce remaining duration.

Validation:

Subscription must never become negative.

---

# 4.5.6 Suspend User

Purpose:

Temporarily prevent business access.

---

## Flow

```text
Suspend

↓

Confirmation

↓

Firebase

↓

Refresh UI
```

---

## User Experience

Tahsel displays:

Suspended Screen.

Business data remains untouched.

---

# 4.5.7 Disable User

Purpose:

Completely prevent application usage.

---

## Flow

```text
Disable

↓

Confirmation

↓

Firebase

↓

Disabled Screen
```

Unlike suspension, disabling generally represents a stronger administrative restriction.

---

# 4.5.8 Activate User

Available when account status is:

* Disabled
* Suspended

Result:

```text
Status

↓

Active
```

---

# 4.5.9 Delete User

Tahsel performs **Soft Delete**.

The account is marked as deleted instead of permanently removing all data.

---

## Advantages

* Audit history preserved.
* Business data preserved.
* Recovery remains possible.
* Prevents accidental data loss.

---

## Flow

```text
Delete

↓

Confirmation

↓

Status = Deleted

↓

Force Logout
```

---

# 4.5.10 Force Logout

Purpose:

Terminate every active session.

---

## Flow

```text
Force Logout

↓

Increase Session Version

↓

User Validation

↓

Logout
```

Works across:

* Android
* iOS
* Windows

---

# 4.5.11 Reset Password

Dashboard sends Firebase password reset email.

Administrators never view or modify passwords directly.

---

# Confirmation Dialogs

Every destructive action requires confirmation.

Examples:

* Suspend
* Disable
* Delete
* Shorten
* Force Logout

Confirmation reduces accidental administrative mistakes.

---

# Loading State

While performing any action:

* Disable action buttons.
* Display loading indicator.
* Prevent duplicate requests.

---

# Success Messages

Examples:

```text
User Created Successfully

Subscription Updated

User Suspended

User Activated

Account Deleted

Password Reset Email Sent

Session Terminated
```

---

# Error Messages

Examples:

```text
Unable to complete action.

Please try again.
```

Retry should be available where appropriate.

---

# Automatic Refresh

After any successful action:

Refresh:

* User Details
* Users List
* Statistics
* Remaining Days
* Status Badge

Without reopening the screen.

---

# Audit Integration

Every action generates an audit entry.

Example:

```text
Admin

↓

Renewed Subscription

↓

Ahmed Ali

↓

26 June 2026

↓

30 Days
```

This enables complete administrative traceability.

---

# Security Rules

Only administrators may perform user management actions.

Tahsel clients never expose these capabilities.

Every action must be authenticated.

---

# Performance

Administrative operations should:

* Update only affected documents.
* Avoid reloading unrelated collections.
* Refresh only impacted Cubit states.

---

# Business Rules

* Only Dashboard creates users.
* UID never changes.
* Subscription changes are Dashboard-controlled.
* Delete performs soft deletion.
* Force Logout invalidates all active sessions.
* Password reset uses Firebase Authentication.
* Every destructive action requires confirmation.
* All actions generate audit records.
* Dashboard refreshes automatically after success.

---

# Architecture

```text
Administrator

↓

Dashboard UI

↓

Cubit

↓

User Management UseCases

↓

Repository

↓

Firebase

↓

Realtime Refresh

↓

Updated Dashboard
```

---

# End of Section

Next Section:

**4.6 Notes Management**

This section documents the administrator notes system, including creating, editing, deleting, and displaying private internal notes for each user, along with business rules, synchronization behavior, and future extensibility.
# PART 4 — Dashboard Administration

# 4.7 Notification Management

## Overview

The Notification Management module enables administrators to send announcements, reminders, maintenance notices, and important updates to Tahsel users.

The notification system is designed to support both broadcast and targeted communication while respecting the existing notification architecture.

---

# Objectives

The notification system allows administrators to:

* Notify all users.
* Notify selected users.
* Notify specific user groups.
* Announce new application updates.
* Inform users about maintenance.
* Send subscription reminders.
* Send important business announcements.

---

# Notification Types

Current supported types:

* General Announcement
* Application Update
* Maintenance Notice
* Subscription Reminder
* Custom Message

Future notification types can be added without changing the architecture.

---

# Notification Entry Point

Dashboard Sidebar

↓

Notifications

↓

Compose Notification

---

# Notification Form

Administrator provides:

* Notification Title
* Notification Body
* Target Audience

Optional future fields:

* Image
* Deep Link
* Expiration Time

---

# Notification Title

Example:

```text id="nt01"
New Version Available
```

Maximum recommendation:

```text id="nt02"
60 Characters
```

---

# Notification Body

Example:

```text id="nt03"
A new version of Tahsel is now available with performance improvements and bug fixes.
```

Recommended limit:

```text id="nt04"
250 Characters
```

---

# Target Audience

Supported options:

```text id="nt05"
All Users

Specific Users

Specific Group
```

Administrator selects one target before sending.

---

# Send To All

Broadcast notification.

Recipients:

Every active Tahsel account.

---

# Send To Specific Users

Administrator manually selects one or more users.

Examples:

* Ahmed
* Mohamed
* Ali

Only selected users receive the notification.

---

# Send To Groups

Future implementation.

Supported groups may include:

* Active Users
* Expired Users
* Grace Period Users
* Shop Users
* Cafe Users
* Mobile Users
* Desktop Users

---

# Notification Preview

Before sending:

Display preview.

Example:

```text id="nt06"
Title

New Version Available

-------------------

Body

Performance improvements and bug fixes.
```

---

# Confirmation Dialog

Administrator presses:

```text id="nt07"
Send
```

Confirmation dialog:

```text id="nt08"
Are you sure you want to send this notification?
```

---

# Sending Flow

```text id="nt09"
Compose

↓

Validate

↓

Confirmation

↓

Firebase

↓

FCM

↓

Recipients
```

---

# Delivery

Notifications are delivered using Firebase Cloud Messaging (FCM).

Supported platforms:

* Android
* iOS
* Windows (future if supported)

---

# Receiving Notifications

Tahsel application:

Receives push notification.

Displays:

* System notification.
* In-app handling (future).

---

# Background Delivery

When application is closed:

Push notification appears through the operating system.

---

# Foreground Delivery

When application is open:

Future implementation:

Administrator may choose:

* Snackbar
* Dialog
* Notification Center

---

# Notification History (Future)

Future Dashboard screen:

Displays:

* Title
* Body
* Sent Time
* Recipient Count
* Delivery Status

Allows administrators to review previous broadcasts.

---

# Scheduling (Future)

Future support:

Administrator chooses:

```text id="nt10"
Send Now

or

Schedule Later
```

Examples:

* Tomorrow
* Specific Date
* Weekly Reminder

---

# Localization

Notifications may be composed in:

* Arabic
* English

Current implementation:

Administrator manually writes notification content.

Future support may include localized notification templates.

---

# Empty State

If no notifications have been sent:

Display:

```text id="nt11"
No notifications yet.
```

---

# Error Handling

Examples:

```text id="nt12"
Unable to send notification.

Please try again.
```

Retry option should be available.

---

# Loading State

During sending:

* Disable Send button.
* Display loading indicator.
* Prevent duplicate submissions.

---

# Security

Only administrators can:

* Compose notifications.
* Send notifications.
* Broadcast announcements.

Tahsel users cannot create notifications.

---

# Performance

The notification module should:

* Avoid duplicate sends.
* Batch large recipient lists.
* Reuse Firebase messaging services.
* Keep the Dashboard responsive during delivery.

---

# Business Rules

* Notifications are Dashboard-controlled.
* Sending requires confirmation.
* Empty title is not allowed.
* Empty body is not allowed.
* Broadcasts are delivered through Firebase Cloud Messaging.
* Notification creation is restricted to administrators.
* Future scheduling must not affect current architecture.

---

# Architecture

```text id="nt13"
Administrator

↓

Compose Notification

↓

Dashboard Cubit

↓

Notification UseCase

↓

Repository

↓

Firebase Cloud Messaging

↓

Tahsel Devices
```

---

# End of Section

Next Section:

**4.8 Version Management**

This section documents the complete application version management system, including independent Android, iOS, and Windows version configurations, force update behavior, update messages, download URLs, platform-specific settings, and the business rules governing the update mechanism.
# PART 4 — Dashboard Administration

# 4.8 Version Management

## Overview

The Version Management module allows administrators to control application updates for every supported platform independently.

Unlike the original implementation, each platform maintains its own version information, update policy, download URL, and update message.

This prevents Android updates from affecting iOS or Windows users and vice versa.

---

# Objectives

The Version Management system should allow administrators to:

* Manage Android versions independently.
* Manage iOS versions independently.
* Manage Windows versions independently.
* Enable or disable Force Update per platform.
* Configure platform-specific update messages.
* Configure platform-specific download URLs.
* Publish updates without affecting other platforms.

---

# Supported Platforms

Current supported platforms:

* Android
* iOS
* Windows

Each platform maintains an isolated configuration.

---

# Architecture

Instead of one shared version object:

```text id="vm01"
Application Versions

↓

Android

↓

iOS

↓

Windows
```

Every platform has its own configuration document.

---

# Platform Configuration

Each platform stores:

* Build Number
* Version Name
* Download URL
* Force Update
* Update Message

These values never overlap.

---

# Android Configuration

Fields:

```text id="vm02"
Build Number

Version Name

Download URL

Force Update

Update Message
```

Only Android devices read this configuration.

---

# iOS Configuration

Fields:

```text id="vm03"
Build Number

Version Name

App Store URL

Force Update

Update Message
```

Only iOS devices read this configuration.

---

# Windows Configuration

Fields:

```text id="vm04"
Build Number

Version Name

Release URL

Force Update

Update Message
```

Only Windows devices read this configuration.

---

# Build Number

Represents the internal application version.

Example:

```text id="vm05"
12
```

Used for update comparison.

---

# Version Name

Human-readable version.

Example:

```text id="vm06"
1.3.0
```

Displayed to users.

---

# Download URL

Each platform has its own download destination.

Examples:

Android

```text id="vm07"
Google Play
```

iOS

```text id="vm08"
App Store
```

Windows

```text id="vm09"
GitHub Releases
```

---

# Force Update

Boolean value.

Possible values:

```text id="vm10"
True

False
```

When enabled:

Users cannot continue until updating.

---

# Optional Update

If Force Update is disabled:

Users may:

* Update now.
* Skip.
* Continue using current version.

---

# Update Message

Administrator defines platform-specific message.

Example:

```text id="vm11"
This version includes performance improvements and important bug fixes.
```

Different platforms may display different messages.

---

# Publishing Flow

Administrator updates Android configuration.

↓

Only Android users receive update prompts.

iOS and Windows remain unchanged.

The same applies independently for every platform.

---

# Client Validation

When Tahsel starts:

Application determines current platform.

Example:

```text id="vm12"
Android

↓

Load Android Version

↓

Compare Versions

↓

Display Result
```

The application never downloads unrelated platform configurations.

---

# Version Comparison

Logic:

```text id="vm13"
Current Build

<

Latest Build

↓

Update Required
```

Otherwise:

Continue normally.

---

# Force Update Flow

```text id="vm14"
Launch App

↓

Download Platform Version

↓

Compare Build

↓

Force Update?

↓

Yes

↓

Block Application

↓

Update Screen
```

---

# Optional Update Flow

```text id="vm15"
Launch App

↓

Compare Version

↓

Update Available

↓

Display Dialog

↓

Later

↓

Continue Application
```

---

# Platform Independence

Changing Android:

Must never affect:

* iOS
* Windows

Changing Windows:

Must never affect:

* Android
* iOS

Changing iOS:

Must never affect:

* Android
* Windows

---

# Dashboard UI

Recommended layout:

```text id="vm16"
Android Card

↓

Save

-----------------

iOS Card

↓

Save

-----------------

Windows Card

↓

Save
```

Each card saves independently.

---

# Save Operation

Each platform has its own Save button.

Updating Android does not trigger updates for other platforms.

---

# Validation

Required fields:

* Build Number
* Version Name
* Download URL

Optional:

* Update Message

---

# Error Handling

Examples:

```text id="vm17"
Invalid Download URL

Build Number Required

Unable to Save
```

---

# Loading State

While saving:

* Disable Save button.
* Display loading indicator.
* Prevent duplicate requests.

---

# Success Message

Example:

```text id="vm18"
Android Version Updated Successfully.
```

Platform name should appear in the success message.

---

# Synchronization

After saving:

Dashboard immediately refreshes displayed configuration.

Tahsel applications receive the new version configuration on the next version check.

---

# Future Features

The architecture supports:

* Minimum Supported Version
* Staged Rollouts
* Beta Channel
* Internal Testing Builds
* Percentage Rollout
* Release Notes
* Release History
* Rollback Support

without redesigning the Version Management module.

---

# Security

Only authenticated administrators may:

* Update versions.
* Enable Force Update.
* Change download URLs.
* Publish new releases.

---

# Performance

The Version Management module should:

* Save only modified platform documents.
* Avoid unnecessary reads.
* Refresh only affected UI sections.
* Keep version checks lightweight for Tahsel clients.

---

# Business Rules

* Every platform has an independent configuration.
* Force Update is evaluated per platform.
* Update messages are platform-specific.
* Download URLs are platform-specific.
* Version checks occur during application startup.
* Saving Android settings must not affect iOS or Windows.
* Saving iOS settings must not affect Android or Windows.
* Saving Windows settings must not affect Android or iOS.

---

# Architecture

```text id="vm19"
Dashboard

↓

Version Management Screen

↓

Dashboard Cubit

↓

Version UseCase

↓

Repository

↓

Firebase

↓

Platform Configuration

↓

Tahsel Application
```

---

# End of Section

Next Section:

**4.9 Audit & Activity Logs**

This section documents the complete audit logging system, including administrator actions, login history, subscription changes, user management operations, version updates, notification history, timestamps, filtering, and traceability rules.

# PART 4 — Dashboard Administration

# 4.9 Audit & Activity Logs

## Overview

The Audit & Activity Logs module records every important administrative action performed inside the Dashboard.

Its primary purpose is to provide full traceability, accountability, and historical tracking of all sensitive operations.

Unlike analytics or reports, Audit Logs are immutable historical records and should never be modified manually.

---

# Objectives

The Audit module allows administrators to:

* Track all administrative actions.
* Identify who performed each action.
* Know when an action occurred.
* Review historical account changes.
* Investigate unexpected behavior.
* Support customer service.
* Improve security and accountability.

---

# Principles

Audit records are:

* Automatically generated.
* Read-only.
* Chronological.
* Permanent.
* Immutable.

Administrators cannot edit or delete audit records.

---

# Logged Actions

The system should create an audit record for every important operation.

Examples include:

* Login
* Logout
* User Creation
* User Update
* User Suspension
* User Activation
* User Disable
* User Delete
* Subscription Renewal
* Subscription Extension
* Subscription Reduction
* Force Logout
* Password Reset Email
* Note Update
* Notification Sent
* Version Configuration Update

Future modules should automatically register their own actions.

---

# Audit Record Structure

Each record contains:

* Audit ID
* Timestamp
* Administrator UID
* Administrator Name
* Target User UID (if applicable)
* Target User Name
* Action Type
* Action Description
* Platform
* Additional Metadata (optional)

---

# Example Record

```text id="au01"
26 June 2026

Administrator

Ahmed Hassan

↓

Renewed Subscription

↓

User

Mohamed Ali

↓

30 Days
```

---

# Action Types

Current action categories:

```text id="au02"
Authentication

User Management

Subscription

Notifications

Version Management

Settings

Security
```

Future categories may be added.

---

# Login Audit

Whenever an administrator signs in:

Record:

```text id="au03"
Administrator Login
```

Includes:

* Time
* Device
* Platform

---

# Logout Audit

Whenever an administrator logs out:

Create:

```text id="au04"
Administrator Logout
```

---

# User Creation Audit

Example:

```text id="au05"
Created User

Ahmed Ali

Platform

Desktop

Subscription

30 Days
```

---

# Subscription Audit

Every subscription modification creates a record.

Examples:

```text id="au06"
Renewed Subscription

Extended Subscription

Shortened Subscription
```

---

# Status Changes

Examples:

```text id="au07"
User Suspended

User Activated

User Disabled

User Deleted
```

---

# Password Reset

Example:

```text id="au08"
Password Reset Email Sent
```

---

# Force Logout

Example:

```text id="au09"
Force Logout Executed
```

This identifies who terminated user sessions.

---

# Notification Audit

Whenever a notification is sent:

Store:

* Title
* Recipient Count
* Administrator
* Timestamp

Example:

```text id="au10"
Maintenance Notice

↓

428 Users
```

---

# Version Management Audit

Every version update should be logged.

Example:

```text id="au11"
Android Version Updated

↓

1.3.0

↓

Build 18
```

This applies independently to:

* Android
* iOS
* Windows

---

# Settings Audit

Future Dashboard settings should also generate logs.

Examples:

* Theme Configuration
* System Settings
* Feature Flags

---

# Search

Audit screen should support searching by:

* Administrator Name
* User Name
* UID
* Action Type

Future search should support full-text queries.

---

# Filtering

Recommended filters:

* Today
* Yesterday
* Last 7 Days
* Last 30 Days
* Custom Range

Action filters:

* Authentication
* Subscription
* Notifications
* User Management
* Version Updates

---

# Sorting

Default:

Newest First

Optional:

Oldest First

---

# Pagination

Large audit histories should use pagination or lazy loading.

Never download the entire history at once.

---

# Detail Screen (Future)

Selecting an audit record may display:

* Full Metadata
* Before / After Values
* Device Information
* Additional Context

---

# Export (Future)

Support exporting logs:

* CSV
* Excel
* PDF

Useful for business reporting and compliance.

---

# Security

Audit records are visible only to authenticated administrators.

Tahsel users never have access.

---

# Performance

The Audit module should:

* Load incrementally.
* Paginate large datasets.
* Cache recent entries.
* Minimize Firestore reads.
* Avoid rebuilding the entire list.

---

# Business Rules

* Audit records are immutable.
* Records cannot be deleted manually.
* Every administrative action generates exactly one audit record.
* Audit timestamps use server time when available.
* Audit records are ordered chronologically.
* Dashboard actions must remain traceable indefinitely.

---

# Architecture

```text id="au12"
Administrator Action

↓

Audit Service

↓

Audit UseCase

↓

Repository

↓

Firebase Audit Collection

↓

Audit Screen
```

---

# End of PART 4 — Dashboard Administration

The Dashboard Administration module is now fully documented, including:

* Dashboard Statistics
* User Search
* User Details
* User Management Actions
* Notes Management
* Notification Management
* Version Management
* Audit & Activity Logs

---

# Next Part

**PART 5 — Debt Management ⭐**

This is the largest and most complex module in Tahsel.

It will document, in exhaustive detail:

* Customer Debts
* Debt Lifecycle
* Ledger-Based Transactions
* Debt Creation
* Editing
* Deletion Rules
* Partial Payments
* Full Payments
* Payment Adjustments
* Reversals
* Slidable Actions
* Reports
* Notifications
* Remaining Debt Calculations
* Ledger Architecture
* Business Rules
* Financial Integrity
* Edge Cases
* Offline Synchronization
* Firebase Structure
* Production Safety Rules

This section will be significantly larger than PART 4 because it represents the financial core of the Tahsel system.

# PART 5 — Debt Management

# 5.1 Overview

## Introduction

The **Debt Management Module** is the core feature of the Tahsel ecosystem.

It is responsible for managing customer debts, recording payments, maintaining financial history, generating reports, sending notifications, and preserving financial integrity across Android, iOS, Windows, and Dashboard.

Almost every other module interacts directly or indirectly with the Debt Management module.

Because of this, the implementation prioritizes **accuracy, traceability, auditability, scalability, and consistency** over convenience.

---

# Objectives

The Debt Management module enables business owners to:

* Register customer debts.
* Record partial payments.
* Record full payments.
* Track payment history.
* Review complete debt history.
* Generate financial reports.
* Send payment notifications.
* Monitor outstanding balances.
* Work safely across multiple devices.
* Support offline synchronization.
* Prevent financial inconsistencies.

---

# Supported Business Types

The debt module is available for all supported business categories.

Examples include:

* Retail Shops
* Electronics Stores
* Furniture Stores
* Mobile Shops
* Grocery Stores
* Cafes
* PlayStation Centers
* Service Providers

Future business categories automatically inherit the same debt engine.

---

# Supported Platforms

The module is available on:

* Android
* iOS
* Windows

The Dashboard accesses debt information indirectly through reports and user statistics but does not perform daily debt operations.

---

# Core Concepts

The debt engine revolves around four primary concepts:

1. Customer
2. Debt
3. Transaction
4. Report

Every financial event ultimately becomes a transaction.

---

# Source of Truth

The debt system never trusts cached financial values.

Instead, every balance is derived from transaction history.

Examples:

* Remaining Amount
* Total Paid
* Outstanding Balance
* Monthly Collections

are all calculated dynamically.

---

# Financial Integrity

The debt system is designed to guarantee:

* No duplicated payments.
* No missing payments.
* No inconsistent balances.
* No manual balance editing.
* Complete historical traceability.

Every calculation must be reproducible using stored transactions.

---

# Ledger Philosophy

Tahsel follows a ledger-inspired financial model.

Instead of relying on mutable totals, the application stores financial operations as historical records.

Examples:

* Debt Created
* Partial Payment
* Full Payment
* Adjustment
* Reversal

Each transaction contributes to the final balance.

This design improves:

* Auditability
* Offline synchronization
* Conflict resolution
* Future accounting integrations

---

# Debt Lifecycle

Every debt passes through the following lifecycle:

```text id="dm01"
Create Debt

↓

Partial Payments

↓

More Payments

↓

Fully Paid

↓

Archived (Future)
```

Some debts may remain partially paid indefinitely.

---

# Customer Relationship

Each debt belongs to exactly one customer.

A customer may own multiple debts.

Example:

```text id="dm02"
Ahmed

↓

Debt #1

Debt #2

Debt #3
```

Debts are completely independent.

---

# Multiple Employees

If multiple employees work simultaneously:

Each transaction is synchronized safely.

The system must prevent:

* Duplicate payments.
* Lost updates.
* Overwritten balances.

---

# Offline Support

Debt operations support offline mode.

Offline-created transactions:

* Keep original creation date.
* Preserve business timestamps.
* Synchronize automatically.

Financial calculations remain correct after synchronization.

---

# Business Date

All reports rely on:

```text id="dm03"
createdAt
```

Never:

* syncedAt
* uploadTime
* Firebase Server Timestamp

Business reports always represent the real operation date.

---

# Currency

All monetary values use the application's formatting utilities.

Examples:

```text id="dm04"
150 EGP

2,350 EGP

10,500 EGP
```

Formatting is centralized.

---

# Localization

Every debt-related text uses ARB localization.

Supported languages:

* Arabic
* English

No hardcoded UI strings are allowed.

---

# Notifications

Debt operations integrate with the notification system.

Supported methods:

* WhatsApp
* SMS
* None

Notification behavior depends on the selected communication preference.

---

# Reports Integration

The debt engine feeds:

* Daily Reports
* Weekly Reports
* Monthly Reports
* Customer Reports
* Collected Amount Analytics
* Dashboard Statistics

Reports never maintain duplicated balances.

They always derive values from transactions.

---

# Security

Only authenticated users with valid subscriptions may perform debt operations.

Validation occurs before:

* Creating debts.
* Recording payments.
* Editing transactions.
* Viewing reports.

---

# Performance

The debt module is optimized for:

* Thousands of customers.
* Tens of thousands of transactions.
* Fast searching.
* Smooth scrolling.
* Incremental loading.
* Minimal rebuilds.

Heavy calculations may use isolates where appropriate.

---

# Clean Architecture

The module strictly follows Clean Architecture.

```text id="dm05"
Presentation

↓

Cubit

↓

UseCases

↓

Repository

↓

Data Sources

↓

Firebase
```

Business rules never live inside widgets.

---

# Business Rules

* Every debt belongs to one customer.
* Customers may have multiple debts.
* Financial values are derived, never manually maintained.
* Reports use createdAt.
* Notifications respect user preferences.
* Offline transactions preserve original business dates.
* Financial history must remain consistent across all platforms.

---

# Architecture Summary

```text id="dm06"
Customer

↓

Debt

↓

Transactions

↓

Business Calculations

↓

Reports

↓

Analytics

↓

Dashboard Statistics
```

---

# End of Section

Next Section:

**5.2 Debt Architecture**

This section will document the complete internal architecture of the Debt module, including entities, repositories, use cases, Cubit responsibilities, transaction flow, financial calculation pipeline, synchronization strategy, and the complete ledger-based design principles that power the Tahsel debt engine.

# PART 5 — Debt Management

# 5.2 Debt Architecture

## Overview

The Debt Management module is one of the most critical components in Tahsel.

Its architecture is designed to ensure:

* Financial integrity
* High performance
* Offline compatibility
* Multi-device synchronization
* Scalability
* Complete transaction history
* Clean Architecture compliance

The architecture separates UI, business logic, and data access completely.

---

# Core Architecture

Tahsel follows Clean Architecture.

```text id="da01"
Presentation Layer

↓

Cubit

↓

UseCases

↓

Repository

↓

Data Sources

↓

Firebase / Local Cache
```

Each layer has a single responsibility.

---

# Presentation Layer

Responsible only for:

* Displaying debts
* Receiving user interaction
* Rendering UI
* Showing dialogs
* Navigation

The Presentation Layer never performs business calculations.

---

# Cubit Layer

The Cubit orchestrates business operations.

Responsibilities:

* Receive UI events
* Call UseCases
* Emit states
* Refresh UI
* Handle loading
* Handle errors

Cubit never calculates financial values.

---

# Domain Layer

The Domain Layer contains the business rules.

Components:

* Entities
* Repository Interfaces
* UseCases

This layer has no dependency on Flutter or Firebase.

---

# Data Layer

Responsible for:

* Firebase
* Offline storage
* Serialization
* Mapping Models ↔ Entities
* Remote synchronization

Business logic never belongs here.

---

# Main Entities

The Debt module revolves around several core entities.

Primary entities:

* Customer
* Debt
* Debt Transaction
* Payment
* Report

Each entity has a distinct responsibility.

---

# Customer Entity

Represents a customer.

Contains:

* Customer ID
* Name
* Phone Number
* Notes
* Status

Customer does not contain calculated financial values.

---

# Debt Entity

Represents a debt account.

Contains information such as:

* Debt ID
* Customer ID
* Total Amount
* Created Date
* Created By
* Current Status

Financial totals are derived from transactions.

---

# Transaction Entity

Every financial operation becomes a transaction.

Examples:

* Debt Created
* Payment
* Adjustment
* Reversal

Transactions are immutable historical records.

---

# Relationship Diagram

```text id="da02"
Customer

↓

Debt

↓

Transactions

↓

Reports
```

One customer

↓

Many debts

↓

Many transactions

---

# Repository Responsibilities

Repository abstracts data access.

Responsibilities:

* Create Debt
* Get Debts
* Update Debt Metadata
* Create Transaction
* Get Transactions
* Generate Reports
* Sync Offline Data

Repository never performs UI operations.

---

# UseCases

Every business action has its own UseCase.

Examples:

```text id="da03"
CreateDebtUseCase

GetCustomerDebtsUseCase

GetDebtDetailsUseCase

AddPaymentUseCase

EditPaymentUseCase

DeletePaymentUseCase

CalculateRemainingDebtUseCase

GenerateMonthlyReportUseCase

GetCollectedAmountsUseCase
```

Each UseCase performs one business responsibility.

---

# Cubits

Recommended Cubits:

```text id="da04"
CustomerDebtsCubit

DebtDetailsCubit

PaymentCubit

ReportsCubit

CollectedAmountCubit
```

Each Cubit owns a specific workflow.

---

# UI Flow

Example:

```text id="da05"
User

↓

Press Add Payment

↓

Cubit

↓

AddPaymentUseCase

↓

Repository

↓

Firebase

↓

Refresh Transactions

↓

Recalculate Totals

↓

Emit Success

↓

UI Updated
```

---

# Data Flow

```text id="da06"
Firestore

↓

Repository

↓

Entity Mapping

↓

UseCase

↓

Cubit

↓

UI
```

Flow is always one-directional.

---

# State Flow

Each screen follows:

```text id="da07"
Initial

↓

Loading

↓

Success

↓

Error
```

Additional refresh states may exist when needed.

---

# Dependency Direction

Dependencies always point inward.

```text id="da08"
Presentation

↓

Domain

↓

Data
```

Presentation never directly accesses Firebase.

---

# Financial Calculation Layer

All financial calculations occur inside dedicated UseCases.

Examples:

* Remaining Debt
* Total Paid
* Monthly Collections
* Customer Balance

Widgets never calculate money.

---

# Synchronization Layer

Synchronization occurs after repository operations.

Flow:

```text id="da09"
Offline Queue

↓

Repository

↓

Firebase Sync

↓

Refresh Cubit

↓

UI
```

Synchronization is transparent to users.

---

# Error Handling

Every layer handles only its own errors.

Example:

Presentation

↓

Displays snackbar

Domain

↓

Business validation

Repository

↓

Firebase exceptions

---

# Extensibility

The architecture supports future modules such as:

* Installment Engine
* Accounting
* Invoices
* Multi-Currency
* Tax System
* Ledger Export

Without modifying existing business logic.

---

# Testing Strategy

Each layer can be tested independently.

Examples:

* Cubit Tests
* UseCase Tests
* Repository Tests

Business rules are isolated from UI.

---

# Performance Considerations

The architecture minimizes:

* Firestore reads
* Widget rebuilds
* Duplicate calculations
* Repeated queries

Heavy reports use isolates when necessary.

---

# Business Rules

* UI never performs financial calculations.
* Cubit coordinates only.
* UseCases contain business rules.
* Repository handles persistence.
* Transactions are the source of truth.
* Calculated values are never manually edited.
* Every layer has a single responsibility.

---

# Architecture Diagram

```text id="da10"
User

↓

UI

↓

Cubit

↓

UseCases

↓

Repository

↓

Firebase

↓

Entities

↓

Calculated Result

↓

Updated UI
```

---

# End of Section

Next Section:

**5.3 Debt Lifecycle**

This section documents the complete lifecycle of a debt—from the moment it is created until it is fully paid or archived—including creation flow, transaction creation, state transitions, payment progression, ledger history, and all business rules governing the debt lifecycle.

# PART 5 — Debt Management

# 5.3 Debt Lifecycle

## Overview

The Debt Lifecycle defines every stage a debt passes through from creation until its financial completion.

A debt is never treated as a simple record.

Instead, it represents a living financial object whose state evolves based on recorded transactions.

The lifecycle guarantees:

* Financial consistency
* Complete historical traceability
* Accurate reporting
* Safe synchronization
* Predictable business behavior

---

# Lifecycle Diagram

```text id="dl01"
Create Debt

↓

Open Debt

↓

Receive Payments

↓

Partial Paid

↓

More Payments

↓

Fully Paid

↓

Archived (Future)
```

Every transition is driven by transactions.

---

# Stage 1 — Debt Creation

A debt begins when the user creates a new customer debt.

Required information:

* Customer
* Total Amount
* Debt Date
* Notes (Optional)

Automatically generated:

* Debt ID
* Created At
* Created By
* Initial Status

---

# Transaction Created

Creating a debt immediately generates the first ledger transaction.

Transaction Type:

```text id="dl02"
Debt Created
```

This becomes the financial origin of the debt.

---

# Initial State

Immediately after creation:

```text id="dl03"
Status

↓

Open
```

Remaining Debt equals Total Amount.

Total Paid equals zero.

---

# Stage 2 — Open Debt

Open Debt means:

* Customer still owes money.
* Payments are allowed.
* Reports include this debt.
* Notifications may be sent.

Most debts spend the majority of their lifecycle in this state.

---

# Stage 3 — First Payment

When a payment is recorded:

Transaction created:

```text id="dl04"
Payment
```

The original debt remains unchanged.

Only transaction history grows.

---

# Remaining Calculation

Remaining Debt is always calculated as:

```text id="dl05"
Remaining

=

Total Debt

-

Net Payments
```

The Remaining value is never edited directly.

---

# Stage 4 — Partial Payment

If:

```text id="dl06"
Remaining > 0
```

then:

Debt Status becomes:

```text id="dl07"
Partially Paid
```

The customer still owes money.

Additional payments remain allowed.

---

# Stage 5 — Multiple Payments

A debt may contain any number of payment transactions.

Example:

```text id="dl08"
Debt

1000

↓

Payment

200

↓

Payment

300

↓

Payment

150
```

Total Paid:

650

Remaining:

350

Every payment remains visible in history.

---

# Stage 6 — Full Payment

When:

```text id="dl09"
Remaining = 0
```

Debt Status becomes:

```text id="dl10"
Fully Paid
```

The debt is financially complete.

---

# Characteristics of Fully Paid

* Appears in reports.
* Payment history remains available.
* Customer history remains available.
* Future reporting remains accurate.

No financial data is deleted.

---

# Reopening a Debt

If an Adjustment or Reversal is later added:

Remaining becomes positive again.

Status automatically changes:

```text id="dl11"
Fully Paid

↓

Partially Paid
```

Status is always derived.

---

# Ledger Principle

The lifecycle never destroys history.

Example:

```text id="dl12"
Debt

1000

↓

Payment

1000

↓

Adjustment

-300
```

Net Paid:

700

Remaining:

300

History remains complete.

---

# Status Transitions

```text id="dl13"
Open

↓

Partially Paid

↓

Fully Paid

↓

Partially Paid

↓

Fully Paid
```

Transitions are dynamic.

---

# Allowed Operations

Open:

* Add Payment
* View Details
* Reports

Partially Paid:

* Add Payment
* Edit Latest Transaction (Business Rules)
* Reverse Transaction (Ledger)
* Reports

Fully Paid:

* View History
* Adjustment
* Reversal

No state blocks historical viewing.

---

# Customer History

Each customer maintains:

```text id="dl14"
Customer

↓

Debt A

↓

Debt B

↓

Debt C
```

Each debt has an independent lifecycle.

---

# Reports During Lifecycle

Reports always reflect current calculated values.

Examples:

* Outstanding Debt
* Collected Amount
* Monthly Collections
* Customer Balance

No cached balances are stored.

---

# Offline Lifecycle

If a debt is created offline:

Lifecycle begins immediately.

Synchronization later uploads:

* Debt
* Transactions

without modifying:

```text id="dl15"
createdAt
```

Business dates remain accurate.

---

# Failure Recovery

If synchronization fails:

Debt remains valid locally.

Transactions stay queued.

Lifecycle continues after successful synchronization.

---

# Notifications

Payment operations may trigger:

* WhatsApp
* SMS
* None

depending on customer configuration.

Debt creation itself does not necessarily notify customers.

---

# Business Rules

* Every debt begins with a Debt Created transaction.
* Every payment creates a new transaction.
* Remaining is always calculated.
* Status is always derived.
* History is never deleted.
* Ledger integrity must never be broken.
* Multiple payments are fully supported.
* Offline operations preserve lifecycle order.
* Reports always use transaction history.

---

# Architecture

```text id="dl16"
Create Debt

↓

Ledger Transaction

↓

Payments

↓

Net Calculation

↓

Derived Status

↓

Reports

↓

Analytics
```

---

# End of Section

Next Section:

**5.4 Customer Debts Screen**

This section documents the complete Customer Debts screen, including list layout, searching, filtering, customer cards, debt summaries, actions, navigation, UI behavior, performance optimizations, and business rules governing the main debt list.
# PART 5 — Debt Management

# 5.4 Customer Debts Screen

## Overview

The Customer Debts screen is the primary entry point to the Debt Management module.

It provides a real-time overview of every customer with outstanding or historical debts, allowing business owners to monitor collections, review balances, and quickly access detailed debt information.

This screen is designed for high performance, even with thousands of customers.

---

# Objectives

The Customer Debts screen allows users to:

* View all customers with debts.
* Search customers instantly.
* Review remaining balances.
* View total debt information.
* Navigate to debt details.
* Create new debts.
* Monitor payment status.
* Identify overdue customers.
* Access reports.

---

# Navigation

Users reach this screen from:

```text id="cd01"
Home

↓

Customer Debts
```

It is one of the application's main modules.

---

# Screen Layout

Recommended layout:

```text id="cd02"
App Bar

↓

Summary Card

↓

Search

↓

Customers List

↓

Floating Add Button
```

The UI follows Tahsel's design system.

---

# App Bar

Displays:

* Screen Title
* Search Shortcut (optional future)
* Reports Shortcut (future)

---

# Summary Card

Displays aggregated statistics.

Example:

```text id="cd03"
Customers

152

----------------

Total Debt

185,000 EGP

----------------

Remaining

64,500 EGP
```

These values are calculated dynamically.

---

# Search Bar

Supports searching by:

* Customer Name
* Phone Number

Search behavior:

* Case-insensitive.
* Instant filtering.
* Debounced.

---

# Search Debounce

Recommended:

```text id="cd04"
300 ms
```

Avoids unnecessary rebuilds.

---

# Empty Search

If search field is empty:

Display all customers.

---

# Customer List

Each customer appears as a reusable card.

The list uses:

```text id="cd05"
ListView.builder
```

to ensure scalability.

---

# Customer Card

Each card displays:

* Customer Name
* Phone Number
* Remaining Debt
* Total Debt
* Paid Amount
* Debt Status

Example:

```text id="cd06"
Ahmed Ali

01012345678

Remaining

2,350 EGP

Paid

650 EGP
```

---

# Customer Avatar

If no profile image exists:

Display initials.

Example:

```text id="cd07"
AA
```

---

# Debt Status Badge

Possible statuses:

* Open
* Partially Paid
* Fully Paid

Status is derived from transactions.

---

# Remaining Amount

Calculated dynamically.

Never stored manually.

Example:

```text id="cd08"
Remaining

1,250 EGP
```

---

# Paid Amount

Calculated from transactions.

Example:

```text id="cd09"
Paid

4,750 EGP
```

---

# Total Debt

Represents original debt amount.

Example:

```text id="cd10"
Total

6,000 EGP
```

---

# Card Interaction

Tapping a customer card:

Navigates to:

```text id="cd11"
Debt Details Screen
```

---

# Floating Action Button

Displays:

```text id="cd12"
+

Add Debt
```

Opens:

Add Debt dialog or screen.

---

# Pull To Refresh

Supports:

```text id="cd13"
Swipe Down

↓

Refresh
```

Refreshes:

* Customer List
* Summary
* Calculated Values

---

# Empty State

If no customers exist:

Display:

```text id="cd14"
No Customers Yet

Create your first debt.
```

Include Add button.

---

# Loading State

During loading:

Display shimmer placeholders or loading cards.

Avoid blank screens.

---

# Error State

Example:

```text id="cd15"
Unable to load customers.

Retry
```

Retry button reloads the screen.

---

# Sorting

Current recommendation:

Newest customer first.

Future options:

* Alphabetical
* Largest Remaining
* Highest Total Debt
* Most Recent Activity

---

# Filtering (Future)

Future filters:

* Open Debts
* Fully Paid
* Partially Paid
* Overdue
* Recently Added

---

# Real-Time Updates

Whenever:

* Debt created.
* Payment added.
* Adjustment recorded.
* Reversal created.

The customer card refreshes automatically.

No manual refresh required.

---

# Performance

The list must support:

* Thousands of customers.
* Lazy loading.
* Cached calculations.
* Minimal widget rebuilds.

Only affected customer cards should rebuild after updates.

---

# Offline Behavior

Offline mode allows:

* Viewing cached customers.
* Creating debts.
* Recording payments.

Changes synchronize automatically later.

---

# Security

Only authenticated users with valid subscriptions may access this screen.

Access validation occurs before loading customer data.

---

# Localization

All labels use ARB localization.

Supported languages:

* Arabic
* English

No hardcoded strings.

---

# Dark Mode

The screen fully supports:

* Light Theme
* Dark Theme

Using only:

* AppColors
* TextStyles

---

# Responsive Design

Optimized for:

* Android Phones
* iPhone
* Windows Desktop
* Tablets

Desktop may display wider customer cards while preserving identical functionality.

---

# Business Rules

* Customer cards display calculated values only.
* Remaining balance is never stored manually.
* Search is debounced.
* Customer status is derived from transaction history.
* Pull-to-refresh recalculates summaries.
* Opening a customer always navigates to Debt Details.
* UI must remain responsive for very large datasets.

---

# Architecture

```text id="cd16"
Customer Debts Screen

↓

CustomerDebtsCubit

↓

GetCustomerDebtsUseCase

↓

Repository

↓

Firebase / Offline Cache

↓

Calculated Customer Cards
```

---

# End of Section

Next Section:

**5.5 Create Debt**

This section documents the complete debt creation workflow, including the Add Debt dialog, customer validation, financial validation, ledger initialization, first transaction creation, notifications, offline support, synchronization, and all business rules governing debt creation.

# PART 5 — Debt Management

# 5.5 Create Debt

## Overview

The Create Debt feature is the entry point of the entire Debt Management system.

It allows business owners to register a new financial obligation for a customer.

Creating a debt initializes its financial lifecycle and generates the first ledger transaction.

Every debt must be created through this feature.

---

# Objectives

The Create Debt feature allows users to:

* Create a new customer debt.
* Select an existing customer.
* Enter the original debt amount.
* Add optional notes.
* Record the debt creation date.
* Initialize the ledger.
* Refresh reports automatically.

---

# Navigation

Users access this feature from:

```text id="cr01"
Customer Debts

↓

Floating Action Button

↓

Create Debt
```

---

# Screen Layout

Recommended layout:

```text id="cr02"
App Bar

↓

Customer Selector

↓

Debt Amount

↓

Notes

↓

Save Button
```

The screen follows the Tahsel design system.

---

# Required Fields

The following fields are mandatory:

* Customer
* Total Debt Amount

The debt cannot be created without them.

---

# Optional Fields

Optional inputs:

* Notes
* Custom Created Date (if permitted by business rules)

---

# Customer Selection

Users choose an existing customer.

The selector supports:

* Search by Name
* Search by Phone Number

If the customer does not exist:

The user should first create the customer.

---

# Customer Validation

Validation rules:

* Customer must exist.
* Customer must not be deleted.
* Customer must belong to the current workspace.

---

# Debt Amount

The original debt amount entered by the user.

Example:

```text id="cr03"
5000 EGP
```

This value becomes the reference amount for all future calculations.

---

# Amount Validation

Rules:

* Greater than zero.
* Numeric only.
* Supports decimal values if enabled.
* Maximum value follows application limits.

Examples:

Valid:

```text id="cr04"
100

2500

12000
```

Invalid:

```text id="cr05"
0

-500

Empty
```

---

# Notes

Optional.

Examples:

```text id="cr06"
Laptop installment.

Paid after delivery.

First purchase.
```

Notes remain attached to the debt.

---

# Save Button

Action:

```text id="cr07"
Create Debt
```

Disabled while saving.

---

# Creation Flow

```text id="cr08"
Validate Form

↓

Create Debt Entity

↓

Create Ledger Transaction

↓

Save Firebase

↓

Refresh Cubit

↓

Update UI
```

---

# Ledger Initialization

Creating a debt automatically creates the first transaction.

Transaction Type:

```text id="cr09"
Debt Created
```

Example:

```text id="cr10"
Debt

5000
```

This transaction represents the financial origin of the debt.

---

# Initial Financial Values

Immediately after creation:

```text id="cr11"
Total Debt

5000

Paid

0

Remaining

5000
```

Remaining is calculated, not stored.

---

# Initial Status

Every new debt starts as:

```text id="cr12"
Open
```

Status changes later based on payments.

---

# Automatic Calculations

After saving:

Recalculate:

* Customer Remaining Balance
* Customer Total Debt
* Dashboard Statistics
* Reports
* Collection Metrics

All values are derived from transactions.

---

# Notifications

Creating a debt does **not** automatically send customer notifications.

Only payment-related operations may trigger:

* WhatsApp
* SMS
* None

according to user settings.

---

# Offline Support

If no internet connection exists:

Debt is stored locally.

Transaction is added to the offline queue.

Synchronization occurs automatically when connectivity returns.

---

# Offline Synchronization

During synchronization:

The following values must remain unchanged:

```text id="cr13"
createdAt

Debt Amount

Customer ID
```

Synchronization only uploads pending operations.

---

# Duplicate Prevention

The Create button is disabled immediately after submission.

This prevents:

* Duplicate debts.
* Double clicks.
* Multiple Firebase writes.

---

# Loading State

While saving:

* Disable all inputs.
* Show loading indicator.
* Prevent navigation until completion.

---

# Success Flow

After successful creation:

```text id="cr14"
Debt Created Successfully

↓

Navigate Back

↓

Customer List Refreshes

↓

Summary Updates
```

---

# Error Handling

Examples:

```text id="cr15"
Unable to create debt.

Please try again.
```

Retry should preserve entered values.

---

# Empty State

If no customers exist:

Display:

```text id="cr16"
No customers available.

Create a customer first.
```

Provide shortcut to Customer Creation.

---

# Security

Only authenticated users with:

* Active Subscription
* Valid Platform
* Authorized Workspace

may create debts.

---

# Performance

Optimizations:

* Single Firestore write.
* Minimal Cubit rebuilds.
* Refresh only affected customer.
* Avoid recalculating unrelated data.

---

# Localization

All labels and validation messages use ARB localization.

Supported:

* Arabic
* English

---

# Business Rules

* Debt Amount must be greater than zero.
* Customer is required.
* Creating a debt always creates a "Debt Created" transaction.
* Remaining Debt is derived from transaction history.
* Initial status is Open.
* Duplicate submissions are prevented.
* Offline-created debts preserve createdAt.
* Reports update automatically after creation.
* Business calculations never occur inside UI.

---

# Architecture

```text id="cr17"
Create Debt Screen

↓

DebtCubit

↓

CreateDebtUseCase

↓

Repository

↓

Firebase / Offline Queue

↓

Ledger Initialization

↓

Refresh Reports

↓

Updated Customer List
```

---

# End of Section

Next Section:

**5.6 Edit Debt**

This section documents the complete debt editing workflow, including editable fields, restrictions, ledger implications, validation rules, synchronization behavior, notifications, and business rules governing debt modifications.

# PART 5 — Debt Management

# 5.6 Edit Debt

## Overview

The Edit Debt feature allows users to modify non-financial information of an existing debt while preserving the integrity of the financial ledger.

Unlike payments, editing a debt must **never** alter historical financial transactions.

The debt record may be updated, but the transaction history remains immutable.

---

# Objectives

The Edit Debt feature allows users to:

* Correct customer assignment (if allowed).
* Update debt notes.
* Update debt metadata.
* Correct creation information (depending on permissions).
* Keep financial history intact.

---

# Design Principle

Editing a debt **must never rewrite financial history**.

Historical transactions remain unchanged.

Only editable metadata may be modified.

---

# Navigation

Users access Edit Debt from:

```text id="ed01"
Customer Debt Details

↓

More Actions

↓

Edit Debt
```

---

# Editable Fields

Current editable fields:

* Notes
* Customer (optional if business rules allow)
* Debt Description (future)
* Reference Number (future)

---

# Non-Editable Fields

The following fields must never be edited after creation:

* Debt ID
* CreatedAt
* Ledger Transactions
* Transaction IDs
* Payment History
* Total Paid History

---

# Debt Amount Rules

### Current Implementation

Tahsel currently allows updating the debt amount.

However, changing the original debt amount is considered a sensitive financial operation.

---

### Recommended Business Rule

If the debt already has payment transactions:

Original debt amount should not be edited directly.

Instead:

Future versions should create an adjustment transaction.

This preserves accounting integrity.

---

# Notes Editing

Notes may be updated freely.

Example:

```text id="ed02"
Customer requested extension.

Delivery delayed.

Warranty included.
```

Updating notes has no financial impact.

---

# Customer Reassignment

If enabled:

Changing the customer should only be allowed when:

* No payment transactions exist.

Otherwise:

Reject the operation.

Reason:

Moving debts between customers breaks financial history.

---

# Validation

Before saving:

Validate:

* Required fields.
* Customer exists.
* Customer active.
* Valid amount (if editable).

---

# Save Flow

```text id="ed03"
Open Edit Screen

↓

Modify Fields

↓

Validate

↓

Update Repository

↓

Refresh Debt

↓

Refresh Reports

↓

Update UI
```

---

# Ledger Protection

Editing debt metadata must never:

* Delete transactions.
* Modify payments.
* Change payment order.
* Rewrite history.

Ledger remains untouched.

---

# Calculations

After editing:

Recalculate:

* Remaining Debt
* Customer Totals
* Reports

Although metadata changes usually do not affect calculations, recalculation ensures consistency.

---

# Notifications

Editing debt metadata does not automatically notify customers.

Only payment-related events may trigger:

* WhatsApp
* SMS
* None

---

# Offline Support

Offline edits are stored locally.

Synchronization uploads:

Only modified fields.

Original:

```text id="ed04"
createdAt
```

must remain unchanged.

---

# Conflict Resolution

If two devices edit the same debt:

Repository resolves using synchronization rules.

Financial history always takes priority.

Metadata conflicts should never overwrite ledger transactions.

---

# Loading State

While saving:

* Disable Save button.
* Show progress indicator.
* Prevent duplicate updates.

---

# Success Flow

```text id="ed05"
Debt Updated Successfully

↓

Refresh Details

↓

Refresh Customer List

↓

Refresh Reports
```

---

# Error Handling

Examples:

```text id="ed06"
Unable to update debt.

Please try again.
```

User input should remain available for retry.

---

# Permissions

Only authenticated users with valid subscriptions may edit debts.

Future versions may include role-based permissions:

* Owner
* Manager
* Employee

---

# Performance

Optimizations:

* Update only modified fields.
* Avoid rewriting entire documents.
* Refresh only affected debt.
* Prevent unnecessary list rebuilds.

---

# Localization

All labels and messages use ARB localization.

Supported languages:

* Arabic
* English

---

# Future Ledger Enhancement

As Tahsel evolves toward a fully ledger-based accounting model:

Editing the original debt amount should no longer mutate the debt record.

Instead:

```text id="ed07"
Debt Created

↓

Adjustment

↓

Net Debt
```

This preserves a complete audit trail.

---

# Business Rules

* Editing debt metadata must not affect ledger transactions.
* Payment history is immutable.
* createdAt is never modified.
* Ledger integrity has higher priority than convenience.
* Notes are freely editable.
* Customer reassignment is restricted if payments exist.
* Reports refresh automatically after updates.

---

# Architecture

```text id="ed08"
Edit Debt Screen

↓

DebtCubit

↓

EditDebtUseCase

↓

Repository

↓

Firebase

↓

Refresh Customer

↓

Refresh Reports
```

---

# End of Section

Next Section:

**5.7 Delete Debt**

This section documents the complete debt deletion workflow, including soft delete strategy, deletion validation, financial restrictions, ledger preservation, synchronization behavior, recovery options, and business rules that prevent accidental financial data loss.

# PART 5 — Debt Management

# 5.7 Delete Debt

## Overview

The Delete Debt feature allows removing a debt from the active customer list while preserving the application's financial integrity.

Deleting a debt is considered one of the most sensitive operations in Tahsel because it directly affects customer balances, reports, collections, and historical financial data.

For this reason, deletion is heavily validated before execution.

---

# Objectives

The Delete Debt feature allows users to:

* Remove an incorrect debt.
* Clean accidental entries.
* Preserve financial consistency.
* Prevent accidental financial loss.
* Protect transaction history.

---

# Current Strategy

Tahsel currently uses a **Soft Delete** strategy.

The debt is marked as deleted instead of being permanently removed from the database.

Advantages:

* Recovery possibility.
* Audit preservation.
* Synchronization safety.
* Prevent broken references.

---

# Navigation

Users access Delete Debt from:

```text id="dd01"
Debt Details

↓

More Actions

↓

Delete Debt
```

---

# Confirmation Dialog

Deleting a debt always requires confirmation.

Example:

```text id="dd02"
Delete this debt?

This action cannot be easily undone.

[Cancel]

[Delete]
```

The Delete button should use the application's error color.

---

# Validation Before Delete

Before allowing deletion, the system validates:

* Debt exists.
* User has permission.
* Debt is not already deleted.
* Financial history remains valid.

---

# Critical Financial Validation

A debt **cannot** be deleted if it already contains payment transactions.

Example:

```text id="dd03"
Debt

↓

Payment

↓

Payment
```

Delete must be rejected.

Reason:

Removing the debt would orphan financial transactions and break reports.

---

# Allowed Deletion

Deletion is allowed only when:

```text id="dd04"
Debt

↓

No Payments
```

The debt has never received any payment.

---

# Future Ledger Rule

As Tahsel transitions to a complete ledger system:

Deleting a debt should eventually become:

```text id="dd05"
Debt Created

↓

Reversal Transaction
```

instead of deleting the record.

This preserves a complete accounting trail.

---

# Soft Delete Flow

```text id="dd06"
User Requests Delete

↓

Validation

↓

Mark Deleted

↓

Refresh Customer

↓

Refresh Reports

↓

Update UI
```

---

# Database Update

Instead of removing the document:

Fields such as:

```text id="dd07"
isDeleted = true

deletedAt

deletedBy
```

are updated.

The document remains available for auditing.

---

# Customer Totals

After deletion:

Recalculate:

* Total Debt
* Remaining Debt
* Dashboard Statistics
* Reports
* Collections

Only active debts contribute to calculations.

---

# Reports

Deleted debts are excluded from:

* Daily Reports
* Weekly Reports
* Monthly Reports
* Customer Reports
* Dashboard Statistics

unless a future Audit View explicitly requests deleted records.

---

# Notifications

Deleting a debt does **not** send:

* WhatsApp
* SMS

Customers should not receive deletion notifications.

---

# Offline Support

Offline deletion:

* Marks debt locally.
* Queues deletion.
* Synchronizes automatically.

The original:

```text id="dd08"
createdAt
```

must never change.

---

# Synchronization

When connectivity returns:

Repository synchronizes:

* isDeleted
* deletedAt
* deletedBy

without modifying financial history.

---

# Error Handling

Example:

```text id="dd09"
Unable to delete debt.

Please try again.
```

The debt remains visible if deletion fails.

---

# Undo (Future)

A future enhancement may allow:

```text id="dd10"
Undo Delete
```

within a limited time before permanent archival.

---

# Security

Only authorized users may delete debts.

Future permissions:

* Owner ✅
* Manager (optional)
* Employee (configurable)

---

# Performance

Optimizations:

* Soft delete updates only required fields.
* Refresh affected customer only.
* Recalculate summaries incrementally.
* Avoid full list rebuilds.

---

# Business Rules

* Deletion always requires confirmation.
* Soft Delete is preferred over permanent deletion.
* Debts with payments cannot be deleted.
* Reports exclude deleted debts.
* No customer notification is sent.
* Financial integrity takes precedence over convenience.
* Offline deletions preserve createdAt.
* Synchronization updates deletion metadata only.

---

# Architecture

```text id="dd11"
Delete Debt

↓

DebtCubit

↓

DeleteDebtUseCase

↓

Repository

↓

Soft Delete

↓

Refresh Reports

↓

Refresh Customer List
```

---

# Future Improvement

Once the ledger architecture becomes the only supported financial model:

Deleting a debt should be replaced by:

```text id="dd12"
Debt Created

↓

Debt Reversal

↓

Net Debt = 0
```

This completely eliminates destructive financial operations while preserving the full accounting history.

---

# End of Section

Next Section:

**5.8 Debt Details Screen**

This section will document the complete Debt Details screen, including the header summary, payment timeline, ledger transaction list, Slidable actions, customer information, calculated financial summary, reports integration, real-time updates, offline behavior, and all UI/business rules governing debt details.

# PART 5 — Debt Management

# 5.8 Debt Details Screen

## Overview

The Debt Details Screen provides a complete financial view of a single debt.

It is one of the most frequently used screens in Tahsel because nearly all daily collection activities happen here.

The screen allows users to:

* Review debt information.
* Record payments.
* Review payment history.
* Track remaining balance.
* Send payment notifications.
* Analyze transaction history.
* Manage debt lifecycle.

Everything displayed on this screen is derived from the ledger transactions.

---

# Navigation

Users reach this screen by selecting a customer debt.

```text id="dds01"
Customer Debts

↓

Customer Card

↓

Debt Details
```

---

# Screen Structure

Recommended layout:

```text id="dds02"
App Bar

↓

Debt Summary Card

↓

Customer Information

↓

Financial Summary

↓

Transaction Timeline

↓

Floating Payment Button
```

The screen is scrollable.

---

# App Bar

Displays:

* Customer Name
* More Actions Menu
* Back Button

Future:

* Share Debt
* Export PDF

---

# Debt Summary Card

The first section shows the overall debt summary.

Displayed values:

* Original Debt
* Total Paid
* Remaining Debt
* Debt Status

Example:

```text id="dds03"
Original Debt

10,000 EGP

Paid

3,500 EGP

Remaining

6,500 EGP
```

---

# Financial Calculation

Displayed values are always calculated.

Never read cached values.

Formula:

```text id="dds04"
Remaining

=

Original Debt

-

Net Payments
```

---

# Debt Status

Possible values:

```text id="dds05"
Open

Partially Paid

Fully Paid
```

Status is derived.

---

# Customer Information

Displays:

* Name
* Phone Number
* Notes (if available)

Future:

* Customer Avatar
* Customer Statistics

---

# Financial Summary

Additional statistics:

* Number of Payments
* Last Payment Date
* Debt Creation Date

Example:

```text id="dds06"
Payments

6

Created

12 Jan 2026

Last Payment

8 Mar 2026
```

---

# Transaction Timeline

The largest section of the screen.

Displays every transaction in chronological order.

Supported transaction types:

* Debt Created
* Payment
* Adjustment
* Reversal

---

# Transaction Card

Each transaction displays:

* Transaction Type
* Amount
* Date
* Time
* Notes (optional)

Example:

```text id="dds07"
Partial Payment

500 EGP

Today

10:35 AM
```

---

# Transaction Ordering

Transactions are ordered by:

```text id="dds08"
createdAt
```

Ascending by default.

Future option:

Newest first.

---

# Date Rules

Business reports and timeline always rely on:

```text id="dds09"
createdAt
```

Never:

* syncedAt
* uploadedAt
* serverTimestamp

---

# Slidable Actions

Each eligible transaction supports:

```text id="dds10"
Swipe Right

↓

Edit

----------------

Swipe Left

↓

Delete
```

Only transactions allowed by business rules expose these actions.

---

# Debt Creation Transaction

The initial **Debt Created** transaction behaves differently.

Current business rule:

If it is **not the latest transaction**, editing and deleting are disabled.

Reason:

Protect financial history.

---

# Edit Payment

Selecting:

```text id="dds11"
Edit Payment
```

opens:

MyPartialPaymentDialog

The dialog contains:

* Paid Amount
* Notes

After confirmation:

* Only the selected transaction is updated (or adjusted, depending on ledger mode).
* Summary refreshes.
* Reports refresh.
* Cubit emits updated state.

---

# Delete Payment

Selecting:

```text id="dds12"
Delete Payment
```

opens:

Confirmation Dialog

After confirmation:

* Transaction is removed or reversed according to the active accounting model.
* Remaining balance recalculates.
* Reports refresh.
* Timeline updates immediately.

---

# Add Payment Button

Floating Action Button:

```text id="dds13"
+

Add Payment
```

Opens:

Partial Payment Dialog.

---

# Payment Flow

```text id="dds14"
Add Payment

↓

Validation

↓

Save Transaction

↓

Recalculate

↓

Refresh Timeline

↓

Update Summary
```

---

# Notification Integration

After successful payment:

Notification dialog appears.

Supported methods:

* WhatsApp
* SMS
* None

Message includes:

* Paid Amount
* Remaining Debt

Deleting a payment never sends notifications.

---

# Real-Time Updates

Any operation:

* Add Payment
* Edit Payment
* Delete Payment
* Synchronization

automatically refreshes:

* Summary Card
* Remaining Balance
* Timeline
* Reports

No manual refresh required.

---

# Empty Timeline

If no payments exist:

Display:

```text id="dds15"
No payment history yet.
```

Only the initial Debt Created transaction is visible.

---

# Loading State

While loading:

* Summary placeholders
* Transaction shimmer cards
* Disabled actions

---

# Error State

Example:

```text id="dds16"
Unable to load debt details.

Retry
```

---

# Offline Behavior

The screen supports:

* Viewing cached transactions.
* Recording offline payments.
* Editing queued transactions.
* Automatic synchronization later.

Business dates remain unchanged.

---

# Performance

Optimizations:

* Lazy transaction rendering.
* Minimal Cubit rebuilds.
* Efficient timeline updates.
* Cached customer information.
* Derived calculations only when necessary.

---

# Localization

All labels use ARB localization.

Supported:

* Arabic
* English

---

# Dark Mode

Fully supports:

* Light Theme
* Dark Theme

Using:

* AppColors
* TextStyles

---

# Business Rules

* All balances are calculated dynamically.
* Timeline uses createdAt.
* Slidable actions respect business validation.
* Debt Created transaction is protected.
* Payment edits refresh every dependent widget.
* Payment deletion recalculates financial summaries.
* Reports update immediately.
* UI never performs financial calculations.

---

# Architecture

```text id="dds17"
Debt Details Screen

↓

DebtDetailsCubit

↓

GetDebtDetailsUseCase

↓

Repository

↓

Transactions

↓

Financial Calculations

↓

Updated Timeline
```

---

# End of Section

Next Section:

**5.9 Payment System**

This section documents the complete payment engine, including partial payments, full payments, payment validation, notification flow, ledger integration, remaining balance calculation, synchronization, and all business rules governing payment processing.
# PART 5 — Debt Management

# 5.9 Payment System

## Overview

The Payment System is the financial engine of the Debt Management module.

Its responsibility is to record every payment made by customers while preserving complete financial accuracy and historical traceability.

Every payment immediately affects:

* Remaining Debt
* Total Paid
* Customer Balance
* Reports
* Dashboard Statistics
* Monthly Collections
* Analytics

All calculations originate from payment transactions.

---

# Objectives

The Payment System allows users to:

* Record partial payments.
* Record full payments.
* Track payment history.
* Send customer notifications.
* Recalculate debt balances.
* Support offline recording.
* Maintain ledger integrity.

---

# Payment Types

Tahsel currently supports:

```text id="ps01"
Partial Payment

Full Payment
```

Future:

* Scheduled Payment
* Installment Payment
* Refund
* Discount
* Write-off

---

# Payment Entry Point

Users add payments from:

```text id="ps02"
Debt Details

↓

Add Payment
```

---

# Payment Dialog

Current implementation opens:

```text id="ps03"
MyPartialPaymentDialog
```

The dialog contains:

* Paid Amount
* Notes (Optional)

Future additions:

* Payment Method
* Receipt Number
* Attachment
* Collector Name

---

# Required Fields

Mandatory:

* Paid Amount

Optional:

* Notes

---

# Amount Validation

Rules:

* Must be numeric.
* Greater than zero.
* Cannot exceed allowed business rules.
* Cannot be empty.

Examples:

Valid:

```text id="ps04"
100

500

2500
```

Invalid:

```text id="ps05"
0

-50

Empty
```

---

# Payment Creation Flow

```text id="ps06"
Open Dialog

↓

Validate Amount

↓

Create Transaction

↓

Save

↓

Recalculate

↓

Refresh UI

↓

Notification
```

---

# Transaction Type

Every payment creates a ledger transaction.

Type:

```text id="ps07"
Payment
```

No existing transactions are modified.

---

# Ledger Entry Example

```text id="ps08"
Debt Created

5000

↓

Payment

1000

↓

Payment

700

↓

Payment

500
```

History remains complete.

---

# Total Paid Calculation

Formula:

```text id="ps09"
Total Paid

=

Sum(All Payment Transactions)
```

Never manually updated.

---

# Remaining Debt Calculation

Formula:

```text id="ps10"
Remaining

=

Original Debt

-

Net Paid
```

Always calculated dynamically.

---

# Full Payment Detection

If:

```text id="ps11"
Remaining = 0
```

Status automatically becomes:

```text id="ps12"
Fully Paid
```

No manual status updates.

---

# Partial Payment Detection

If:

```text id="ps13"
Remaining > 0
```

Status becomes:

```text id="ps14"
Partially Paid
```

---

# Overpayment Protection

Business rule:

Users should never create payments that produce:

```text id="ps15"
Remaining < 0
```

The operation must be rejected unless a future feature explicitly supports customer credit balances.

---

# Notes

Payment notes remain attached to their transaction.

Example:

```text id="ps16"
Paid in cash.

Paid after delivery.

Collected by employee.
```

---

# Notification Flow

After successful payment:

Show Notification Dialog.

Available methods:

* WhatsApp
* SMS
* None

---

# WhatsApp Message

Example contents:

* Customer Name
* Paid Amount
* Remaining Debt

Message text is localized.

---

# SMS

Uses the same financial information.

Only delivery channel changes.

---

# None

No customer communication occurs.

Payment is still recorded.

---

# Offline Payments

Offline payments are fully supported.

Flow:

```text id="ps17"
Create Payment

↓

Store Locally

↓

Queue Sync

↓

Upload Later
```

The user continues working normally.

---

# Synchronization

When internet returns:

Upload:

* Payment Transaction
* Notes
* createdAt

Never modify:

* createdAt
* Business Date

---

# Timeline Update

Immediately after payment:

Refresh:

* Timeline
* Remaining Balance
* Total Paid
* Debt Status

No manual refresh.

---

# Reports Integration

Every payment immediately contributes to:

* Daily Reports
* Weekly Reports
* Monthly Reports
* Collected Amount
* Customer Reports
* Dashboard Statistics

---

# Monthly Collection

Only Payment transactions contribute.

Debt creation transactions are ignored.

Adjustments are ignored unless business rules explicitly include them.

---

# Error Handling

Example:

```text id="ps18"
Unable to save payment.

Please try again.
```

Entered values remain available.

---

# Loading State

While saving:

* Disable Confirm button.
* Prevent duplicate taps.
* Display loading indicator.

---

# Security

Only authenticated users with:

* Active Subscription
* Valid Account
* Authorized Workspace

may record payments.

---

# Performance

Optimizations:

* Single transaction write.
* Incremental recalculation.
* Refresh only affected debt.
* Efficient Cubit updates.
* Minimal widget rebuilds.

---

# Localization

All payment labels use ARB localization.

Supported:

* Arabic
* English

---

# Business Rules

* Every payment creates a new transaction.
* Remaining is always calculated.
* Total Paid is always derived.
* Full Paid status is automatic.
* Partial Paid status is automatic.
* Overpayments are prevented.
* Notifications respect selected communication method.
* Offline payments preserve createdAt.
* Reports update immediately after successful payment.
* UI never performs financial calculations.

---

# Architecture

```text id="ps19"
Payment Dialog

↓

PaymentCubit

↓

AddPaymentUseCase

↓

Repository

↓

Firebase / Offline Queue

↓

Ledger Transaction

↓

Financial Recalculation

↓

Updated UI
```

---

# End of Section

Next Section:

**5.10 Partial Payments**

This section will document the complete Partial Payment workflow in detail, including validation rules, payment scenarios, edge cases, customer communication, remaining balance calculations, and interaction with the ledger system.
# PART 5 — Debt Management

# 5.10 Partial Payments

## Overview

Partial Payment is the most frequently used financial operation inside Tahsel.

It allows customers to pay only a portion of their outstanding debt while keeping the remaining balance active until future payments are received.

Unlike a Full Payment, a Partial Payment never closes the debt unless the cumulative amount paid reaches the total debt amount.

---

# Objectives

The Partial Payment feature allows users to:

* Record a payment smaller than the remaining balance.
* Keep the debt active.
* Update the remaining balance.
* Maintain complete payment history.
* Trigger customer notifications.
* Refresh reports immediately.

---

# Definition

A Partial Payment is any payment where:

```text id="pp01"
Payment Amount

<

Remaining Debt
```

Example:

Debt:

```text id="pp02"
10,000 EGP
```

Payment:

```text id="pp03"
2,000 EGP
```

Remaining:

```text id="pp04"
8,000 EGP
```

---

# Entry Point

Users access Partial Payment through:

```text id="pp05"
Debt Details

↓

Add Payment
```

The same dialog is used for both Partial and Full payments.

The system determines the payment type automatically.

---

# Payment Dialog

Current implementation:

```text id="pp06"
MyPartialPaymentDialog
```

Displayed fields:

* Paid Amount
* Notes (Optional)

---

# Payment Validation

Before saving:

Validate:

* Amount entered.
* Amount > 0.
* Numeric value.
* Amount does not exceed remaining debt.
* Debt is active.

---

# Automatic Classification

Tahsel automatically classifies the payment.

Example:

Remaining:

```text id="pp07"
5,000
```

User enters:

```text id="pp08"
1,500
```

Result:

Automatically classified as:

```text id="pp09"
Partial Payment
```

No manual selection required.

---

# Ledger Transaction

Every Partial Payment creates:

```text id="pp10"
Payment Transaction
```

No previous transaction is modified.

---

# Example Timeline

```text id="pp11"
Debt Created

10,000

↓

Payment

2,000

↓

Payment

1,000

↓

Payment

500
```

History remains permanent.

---

# Remaining Calculation

Formula:

```text id="pp12"
Remaining

=

Original Debt

-

Sum(All Payments)
```

Always calculated dynamically.

---

# Total Paid Calculation

Formula:

```text id="pp13"
Total Paid

=

Sum(Payment Transactions)
```

Never stored manually.

---

# Status Update

After Partial Payment:

Status becomes:

```text id="pp14"
Partially Paid
```

unless Remaining becomes zero.

---

# Customer Summary Refresh

Immediately after saving:

Refresh:

* Remaining Debt
* Paid Amount
* Status
* Summary Card
* Timeline

---

# Dashboard Refresh

The Dashboard receives updated values automatically.

Affected statistics include:

* Remaining Debt
* Monthly Collections
* Customer Totals
* Overall Collections

---

# Reports Refresh

Partial Payments immediately affect:

* Daily Reports
* Weekly Reports
* Monthly Reports
* Customer Reports
* Collected Amount Reports

No delayed calculations.

---

# Notification Flow

After saving:

Display Notification Dialog.

Supported methods:

* WhatsApp
* SMS
* None

---

# WhatsApp Message

Message includes:

* Customer Name
* Paid Amount
* Remaining Balance

Example:

```text id="pp15"
Paid:

2,000 EGP

Remaining:

8,000 EGP
```

---

# SMS

Contains the same financial information.

Only delivery channel changes.

---

# None

No notification sent.

Payment is still recorded successfully.

---

# Offline Support

Partial Payments support offline mode.

Flow:

```text id="pp16"
Create Payment

↓

Local Storage

↓

Offline Queue

↓

Firebase Sync
```

---

# Synchronization Rules

Synchronization uploads:

* Transaction
* Notes
* createdAt

Never modifies:

* createdAt
* Debt Creation Date

---

# Multiple Devices

If multiple employees collect payments:

Synchronization preserves every payment.

No payment is overwritten.

Conflict resolution maintains transaction integrity.

---

# Duplicate Prevention

Save button becomes disabled during submission.

Prevents:

* Double taps.
* Duplicate transactions.
* Duplicate notifications.

---

# Error Handling

Examples:

```text id="pp17"
Invalid Amount

Payment Failed

Network Error
```

The dialog remains open for correction.

---

# Loading State

While saving:

* Disable Confirm button.
* Show loading spinner.
* Prevent closing dialog.

---

# Performance

Optimizations:

* Single transaction write.
* Incremental recalculation.
* Refresh only affected debt.
* Efficient Cubit state updates.
* Minimal rebuilds.

---

# Security

Only authenticated users with:

* Active Subscription
* Authorized Workspace
* Valid Account Status

may record Partial Payments.

---

# Business Rules

* Partial Payment amount must be greater than zero.
* Partial Payment must not exceed remaining debt.
* Every Partial Payment creates a new transaction.
* Remaining Debt is recalculated after every payment.
* Total Paid is always derived.
* Payment history is immutable.
* Notifications respect the selected communication method.
* Offline payments preserve createdAt.
* Reports refresh immediately.
* UI never calculates financial values.

---

# Architecture

```text id="pp18"
Partial Payment Dialog

↓

PaymentCubit

↓

AddPaymentUseCase

↓

Repository

↓

Ledger Transaction

↓

Financial Recalculation

↓

Updated Debt Details

↓

Updated Reports
```

---

# End of Section

Next Section:

**5.11 Full Payments**

This section documents the complete Full Payment workflow, including automatic debt completion, status transitions, final notifications, reporting impact, ledger integration, synchronization behavior, and all business rules governing debt settlement.
# PART 5 — Debt Management

# 5.11 Full Payments

## Overview

A Full Payment occurs when the customer's payment settles the remaining outstanding balance completely.

Unlike a Partial Payment, a Full Payment closes the financial obligation while preserving the complete transaction history.

The debt is **never removed**, and no financial history is deleted.

Instead, its status changes automatically to **Fully Paid**.

---

# Objectives

The Full Payment feature allows users to:

* Settle the remaining debt completely.
* Automatically close the debt.
* Update customer balance.
* Update reports instantly.
* Preserve transaction history.
* Notify customers.
* Keep the ledger consistent.

---

# Definition

A Full Payment occurs when:

```text id="fp01"
Payment Amount

=

Remaining Debt
```

Example:

Debt:

```text id="fp02"
8,000 EGP
```

Paid Previously:

```text id="fp03"
5,000 EGP
```

Remaining:

```text id="fp04"
3,000 EGP
```

Customer Pays:

```text id="fp05"
3,000 EGP
```

Debt becomes fully paid.

---

# Automatic Detection

Users never manually select:

```text id="fp06"
Full Payment
```

Tahsel automatically determines the payment type.

If:

```text id="fp07"
Remaining After Payment = 0
```

Then:

```text id="fp08"
Status = Fully Paid
```

---

# User Flow

```text id="fp09"
Debt Details

↓

Add Payment

↓

Enter Remaining Amount

↓

Confirm

↓

Payment Saved

↓

Debt Closed

↓

Reports Updated

↓

Notification
```

---

# Ledger Transaction

Even for Full Payments,

Tahsel creates:

```text id="fp10"
Payment Transaction
```

There is no special transaction type.

The payment amount determines the final debt status.

---

# Timeline Example

```text id="fp11"
Debt Created

8,000

↓

Payment

2,000

↓

Payment

3,000

↓

Payment

3,000
```

Debt Status:

```text id="fp12"
Fully Paid
```

---

# Financial Calculation

After saving:

```text id="fp13"
Total Paid

=

Original Debt
```

Remaining:

```text id="fp14"
0
```

---

# Status Transition

Automatic transition:

```text id="fp15"
Open

↓

Partially Paid

↓

Fully Paid
```

No manual status editing.

---

# Fully Paid Badge

Debt Details should display:

```text id="fp16"
✔ Fully Paid
```

The badge should visually distinguish completed debts.

---

# Customer Summary

Immediately after Full Payment:

Update:

* Remaining = 0
* Paid = Original Debt
* Status = Fully Paid

---

# Dashboard Impact

Immediately refresh:

* Outstanding Debt
* Collected Amount
* Customer Statistics
* Overall Collections
* Monthly Revenue

---

# Reports

The payment contributes to:

* Daily Reports
* Weekly Reports
* Monthly Reports
* Customer Reports
* Collected Amount Analytics

The debt itself remains available for historical reports.

---

# Notifications

After successful Full Payment:

Display Notification Dialog.

Supported methods:

* WhatsApp
* SMS
* None

---

# WhatsApp Example

Localized message contains:

```text id="fp17"
Paid:

3,000 EGP

Remaining:

0 EGP

Status:

Fully Paid
```

---

# SMS

Uses identical financial information.

---

# None

No customer notification.

Financial operation still succeeds.

---

# Offline Support

Full Payments work offline.

Flow:

```text id="fp18"
Create Payment

↓

Store Offline

↓

Queue Sync

↓

Upload Later
```

Debt status updates locally immediately.

---

# Synchronization

When synchronized:

Upload:

* Payment Transaction
* Notes
* createdAt

Never overwrite:

```text id="fp19"
createdAt
```

---

# Reopening a Debt

If a future Adjustment or Reversal is added:

Example:

```text id="fp20"
Debt

8,000

↓

Paid

8,000

↓

Adjustment

-1,000
```

Remaining becomes:

```text id="fp21"
1,000
```

Status automatically changes:

```text id="fp22"
Fully Paid

↓

Partially Paid
```

---

# Duplicate Protection

During submission:

* Disable Confirm.
* Ignore repeated taps.
* Prevent duplicate writes.

---

# Error Handling

Examples:

```text id="fp23"
Payment Failed

Please Try Again
```

Dialog remains open.

---

# Loading State

While saving:

* Disable inputs.
* Show loading indicator.
* Prevent closing.

---

# Performance

Optimizations:

* Single transaction write.
* Incremental calculations.
* Refresh affected debt only.
* Efficient Cubit updates.

---

# Security

Only authorized users with:

* Active Subscription
* Valid Account
* Workspace Access

may record Full Payments.

---

# Business Rules

* Full Payment is detected automatically.
* Remaining becomes exactly zero.
* Debt status becomes Fully Paid automatically.
* Every Full Payment creates a Payment transaction.
* Ledger history remains unchanged.
* Reports refresh immediately.
* Notifications respect selected communication method.
* Offline payments preserve createdAt.
* UI never manually sets debt status.

---

# Architecture

```text id="fp24"
Payment Dialog

↓

PaymentCubit

↓

AddPaymentUseCase

↓

Repository

↓

Payment Transaction

↓

Remaining Calculation

↓

Status Update

↓

Reports Refresh

↓

Updated UI
```

---

# End of Section

Next Section:

**5.12 Edit Payment**

This section documents the complete payment editing workflow, including Slidable Edit actions, payment modification rules, ledger compatibility, recalculation logic, notification behavior, synchronization, and all business rules governing payment updates.
# PART 5 — Debt Management

# 5.12 Edit Payment

## Overview

The Edit Payment feature allows correcting an existing payment while maintaining complete financial consistency throughout the system.

Unlike adding a payment, editing an existing payment affects every calculated financial value derived from the debt.

After a successful edit, Tahsel automatically recalculates:

* Remaining Debt
* Total Paid
* Debt Status
* Customer Balance
* Dashboard Statistics
* Reports
* Monthly Collections

The user never manually updates these values.

---

# Objectives

The Edit Payment feature allows users to:

* Correct an incorrectly entered payment amount.
* Update payment notes.
* Preserve financial consistency.
* Refresh all dependent calculations.
* Maintain an accurate payment timeline.

---

# Entry Point

Users edit payments from:

```text id="ep01"
Debt Details

↓

Swipe Right

↓

Edit
```

This action is implemented using:

```text id="ep02"
flutter_slidable

↓

SlidableAction
```

---

# Slidable UI

Each editable transaction supports:

```text id="ep03"
Swipe Right

↓

✏ Edit Payment
```

The action uses:

* Primary Color
* Existing Design System
* Smooth Animation

---

# Editable Transactions

Current business rules:

Editable:

* Payment Transactions

Restricted:

* Debt Created Transaction
* Reversal Transactions (future)
* Adjustment Transactions (future)

---

# Protected Transaction

The initial:

```text id="ep04"
Debt Created
```

transaction cannot normally be edited.

Current Tahsel rule:

Only allow editing if it is the latest operation and business validation passes.

Otherwise:

Hide the Edit action.

---

# Edit Dialog

Current implementation reuses:

```text id="ep05"
MyPartialPaymentDialog
```

Fields:

* Paid Amount
* Notes

This keeps the UI consistent.

---

# Editable Fields

Users may edit:

* Paid Amount
* Notes

Future:

* Receipt Number
* Payment Method

---

# Save Flow

```text id="ep06"
Open Dialog

↓

Modify Amount

↓

Validate

↓

Save

↓

Recalculate

↓

Refresh UI

↓

Notification
```

---

# Validation

Before saving:

Validate:

* Amount > 0
* Numeric
* Valid payment
* Does not violate debt rules

Reject invalid edits.

---

# Current Financial Model

Current Tahsel implementation updates only the selected payment.

After update:

Recalculate:

```text id="ep07"
Total Paid

=

Sum(All Payments)

----------------

Remaining

=

Original Debt

-

Total Paid
```

No manual balance editing.

---

# Future Ledger Mode

Future ledger implementation replaces mutation with:

```text id="ep08"
Original Payment

↓

Adjustment Transaction
```

Example:

```text id="ep09"
Original Payment

1000

↓

Adjustment

-300
```

Net Payment:

700

History remains complete.

---

# Timeline Update

After editing:

Refresh:

* Edited transaction
* Timeline
* Summary Card
* Remaining Debt
* Paid Amount

Immediately.

---

# Status Recalculation

Debt status is recalculated.

Possible transitions:

```text id="ep10"
Fully Paid

↓

Partially Paid
```

or

```text id="ep11"
Partially Paid

↓

Fully Paid
```

Status is always derived.

---

# Reports Refresh

Editing affects:

* Daily Reports
* Weekly Reports
* Monthly Reports
* Customer Reports
* Collected Amount Reports
* Dashboard Statistics

Reports update immediately.

---

# Notification Flow

Unlike deletion,

Editing a payment **does** trigger the notification system.

After saving:

Display:

```text id="ep12"
Notification Dialog
```

Supported methods:

* WhatsApp
* SMS
* None

---

# Notification Contents

Include:

* Updated Paid Amount
* Remaining Debt

Example:

```text id="ep13"
Updated Payment

1,500 EGP

Remaining

3,500 EGP
```

---

# Offline Support

Editing supports offline mode.

Flow:

```text id="ep14"
Edit

↓

Store Offline

↓

Queue

↓

Sync Later
```

---

# Synchronization

Synchronization uploads:

* Updated Amount
* Updated Notes

Business timestamp:

```text id="ep15"
createdAt
```

must remain unchanged.

---

# Duplicate Protection

While saving:

* Disable Save button.
* Ignore repeated taps.
* Prevent duplicate writes.

---

# Error Handling

Examples:

```text id="ep16"
Invalid Payment

Unable to Update

Network Error
```

Dialog remains open.

---

# Loading State

During update:

* Disable inputs.
* Show loading spinner.
* Prevent multiple submissions.

---

# Performance

Optimizations:

* Update only one transaction.
* Refresh affected debt only.
* Efficient Cubit state updates.
* Minimal widget rebuilds.

---

# Security

Only authenticated users with:

* Active Subscription
* Authorized Workspace

may edit payments.

---

# Business Rules

* Edit is available only for allowed transaction types.
* Debt Created transaction is protected.
* Editing recalculates all financial values.
* Remaining Debt is never edited manually.
* Reports update automatically.
* Notification is shown after successful edit.
* Offline edits preserve createdAt.
* UI never performs financial calculations.

---

# Architecture

```text id="ep17"
Slidable Edit

↓

PaymentCubit

↓

EditPaymentUseCase

↓

Repository

↓

Update Transaction

↓

Financial Recalculation

↓

Refresh Reports

↓

Updated UI
```

---

# End of Section

Next Section:

**5.13 Delete Payment**

This section documents the complete payment deletion workflow, including Slidable Delete actions, confirmation dialogs, remaining balance restoration, ledger compatibility, recalculation rules, synchronization behavior, and all business rules governing payment deletion.
# PART 5 — Debt Management

# 5.13 Delete Payment

## Overview

The Delete Payment feature allows users to remove an incorrectly recorded payment while ensuring that the financial state of the debt remains completely consistent.

Deleting a payment affects every financial calculation related to the debt.

Immediately after deletion, Tahsel recalculates:

* Remaining Debt
* Total Paid
* Debt Status
* Customer Balance
* Reports
* Dashboard Statistics
* Monthly Collections

No financial values are edited manually.

---

# Objectives

The Delete Payment feature allows users to:

* Remove an incorrect payment.
* Restore the customer's remaining balance.
* Maintain financial consistency.
* Refresh all dependent reports.
* Preserve transaction integrity.

---

# Entry Point

Users delete payments from:

```text id="dp01"
Debt Details

↓

Swipe Left

↓

Delete
```

Implemented using:

```text id="dp02"
flutter_slidable

↓

SlidableAction
```

---

# Slidable UI

Each eligible payment supports:

```text id="dp03"
Swipe Left

↓

🗑 Delete Payment
```

Uses:

* Error Color
* Existing Design System
* Smooth Animation

---

# Protected Transactions

The following transactions cannot normally be deleted:

* Debt Created
* Adjustment (Future)
* Reversal (Future)

Only Payment transactions expose Delete.

---

# Current Business Rule

The initial:

```text id="dp04"
Debt Created
```

transaction is protected.

Delete is hidden unless business validation explicitly allows it.

---

# Confirmation Dialog

Before deletion:

Display:

```text id="dp05"
Delete this payment?

This action will update the remaining debt.

[Cancel]

[Delete]
```

Deletion never occurs immediately.

---

# Delete Flow

```text id="dp06"
Swipe

↓

Delete

↓

Confirmation

↓

Delete Transaction

↓

Recalculate

↓

Refresh UI
```

---

# Current Financial Model

Current Tahsel implementation physically removes the selected payment transaction.

After deletion:

Recalculate:

```text id="dp07"
Total Paid

=

Sum(All Remaining Payments)

----------------

Remaining

=

Original Debt

-

Total Paid
```

---

# Future Ledger Mode

Future versions replace deletion with:

```text id="dp08"
Original Payment

↓

Reversal Transaction
```

Example:

```text id="dp09"
Payment

1000

↓

Reversal

-1000
```

Net Payment:

0

Original payment remains visible.

---

# Remaining Restoration

Example:

Original Debt:

```text id="dp10"
5,000
```

Payment:

```text id="dp11"
1,000
```

Remaining before deletion:

```text id="dp12"
4,000
```

After deletion:

```text id="dp13"
Remaining

5,000
```

The remaining balance is restored automatically.

---

# Multiple Payments Example

```text id="dp14"
Debt

10,000

↓

Payment

2,000

↓

Payment

1,500

↓

Payment

500
```

Delete:

```text id="dp15"
500
```

Result:

Paid:

```text id="dp16"
3,500
```

Remaining:

```text id="dp17"
6,500
```

Everything is recalculated automatically.

---

# Status Recalculation

Possible transitions:

```text id="dp18"
Fully Paid

↓

Partially Paid
```

or

```text id="dp19"
Partially Paid

↓

Open
```

Status is always derived from financial calculations.

---

# Timeline Refresh

Immediately after deletion:

Refresh:

* Transaction Timeline
* Summary Card
* Remaining Debt
* Total Paid
* Status Badge

No manual refresh required.

---

# Reports Refresh

Deletion updates:

* Daily Reports
* Weekly Reports
* Monthly Reports
* Customer Reports
* Dashboard Statistics
* Monthly Collections

Reports always reflect the latest financial state.

---

# Notification Behavior

Deleting a payment **does not** trigger:

* WhatsApp
* SMS

No customer notification is sent.

This follows the current Tahsel business rules.

---

# Offline Support

Delete operations work offline.

Flow:

```text id="dp20"
Delete

↓

Offline Queue

↓

Sync

↓

Refresh
```

---

# Synchronization

Synchronization removes the payment (or uploads a reversal in future ledger mode).

Business timestamps remain unchanged.

```text id="dp21"
createdAt
```

is never modified.

---

# Duplicate Protection

During deletion:

* Disable Delete button.
* Ignore repeated taps.
* Prevent duplicate delete requests.

---

# Error Handling

Examples:

```text id="dp22"
Unable to Delete Payment

Network Error

Try Again
```

If deletion fails:

Transaction remains visible.

---

# Loading State

During deletion:

* Disable dialog buttons.
* Show loading indicator.
* Prevent closing dialog.

---

# Performance

Optimizations:

* Delete only one transaction.
* Refresh only affected debt.
* Efficient Cubit updates.
* Incremental financial recalculation.
* Minimal widget rebuilds.

---

# Security

Only authenticated users with:

* Active Subscription
* Authorized Workspace

may delete payments.

---

# Business Rules

* Delete always requires confirmation.
* Only payment transactions may be deleted.
* Remaining Debt is recalculated automatically.
* Total Paid is recalculated automatically.
* Reports refresh immediately.
* No customer notification is sent.
* Offline deletion preserves business dates.
* UI never updates balances manually.
* All financial values are derived from transaction history.

---

# Architecture

```text id="dp23"
Slidable Delete

↓

PaymentCubit

↓

DeletePaymentUseCase

↓

Repository

↓

Delete Transaction

↓

Financial Recalculation

↓

Reports Refresh

↓

Updated UI
```

---

# End of Section

Next Section:

**5.14 Payment Notifications**

This section documents the complete payment notification engine, including WhatsApp, SMS, None, notification dialog workflow, localized message generation, delivery rules, retry behavior, and all business rules governing customer payment notifications.
# PART 5 — Debt Management

# 5.14 Payment Notifications

## Overview

The Payment Notification System keeps customers informed whenever a payment is successfully recorded.

Its purpose is to provide immediate confirmation of collections while reducing misunderstandings regarding paid and remaining balances.

Notifications are **optional** and always respect the user's preferred communication method.

---

# Objectives

The notification system allows users to:

* Notify customers after recording a payment.
* Confirm the collected amount.
* Inform customers of the remaining balance.
* Use the customer's preferred communication channel.
* Skip notifications when appropriate.

---

# Supported Notification Methods

Tahsel currently supports three notification methods:

```text id="pn01"
WhatsApp

SMS

None
```

The selected method determines how the customer is contacted.

---

# Notification Trigger

The notification dialog appears only after a **successful payment operation**.

Supported operations:

* Partial Payment
* Full Payment
* Edit Payment (Current Implementation)

Not triggered for:

* Delete Payment
* View Debt
* Reports
* Debt Creation

---

# Notification Flow

```text id="pn02"
Payment Saved

↓

Recalculate Debt

↓

Refresh UI

↓

Open Notification Dialog

↓

User Chooses Method

↓

Send (Optional)
```

---

# Notification Dialog

Immediately after a successful payment:

Display:

```text id="pn03"
Notify Customer?

( ) WhatsApp

( ) SMS

( ) None

[Confirm]
```

The dialog respects the application's current design system.

---

# WhatsApp Notification

Selecting:

```text id="pn04"
WhatsApp
```

opens WhatsApp using the integrated WhatsApp service.

The application pre-fills the message.

The user reviews it before sending.

---

# WhatsApp Requirements

Before opening WhatsApp:

Validate:

* Customer has a phone number.
* Phone number format is valid.
* WhatsApp can be launched.

If launch fails:

Display:

```text id="pn05"
WhatsApp is not installed.
```

---

# WhatsApp Message Contents

The generated message includes:

* Customer Name
* Paid Amount
* Remaining Debt

Optional future additions:

* Business Name
* Collector Name
* Payment Date
* Receipt Number

---

# Example WhatsApp Message

```text id="pn06"
Hello Ahmed,

A payment of 1,500 EGP has been successfully recorded.

Remaining balance:

3,500 EGP.

Thank you.
```

The message is localized.

---

# SMS Notification

Selecting:

```text id="pn07"
SMS
```

opens the device SMS application.

The message is generated automatically.

The user confirms sending.

---

# SMS Contents

Same financial information:

* Paid Amount
* Remaining Debt

No sensitive internal IDs are included.

---

# None Option

Selecting:

```text id="pn08"
None
```

Closes the dialog immediately.

The payment remains recorded.

No communication occurs.

---

# Localization

Notification messages support:

* Arabic
* English

Message language follows the current application language.

---

# Dynamic Data

Messages are generated using the latest calculated values.

Included values:

* Customer Name
* Payment Amount
* Remaining Debt

These values are always calculated after saving.

---

# Financial Accuracy

Notification values are generated **after** recalculation.

Flow:

```text id="pn09"
Save Payment

↓

Recalculate Remaining

↓

Generate Message

↓

Send
```

This guarantees message accuracy.

---

# Offline Behavior

If the payment is recorded offline:

The payment is stored successfully.

Notifications are **not sent automatically**.

Reason:

External communication requires network connectivity.

---

# Edit Payment Notification

Current Tahsel implementation:

Editing a payment triggers the notification dialog.

Updated values are included:

* Updated Paid Amount
* Updated Remaining Balance

---

# Delete Payment Notification

Deleting a payment **never** sends:

* WhatsApp
* SMS

This follows current business rules.

---

# Failure Handling

Possible failures:

* WhatsApp unavailable.
* SMS unavailable.
* Invalid phone number.

The payment remains successful.

Notification failure never rolls back financial data.

---

# Retry Behavior

If sending fails:

User may manually retry later.

Tahsel does not automatically resend failed messages.

---

# Privacy

Messages contain only business information.

Never include:

* Internal IDs
* Firebase IDs
* Technical metadata
* Authentication information

---

# Security

Only authenticated users with valid permissions may trigger payment notifications.

Notifications are available only after successful payment operations.

---

# Performance

Optimizations:

* Message generated only when required.
* No unnecessary background processing.
* No duplicate notifications.
* No repeated financial calculations.

---

# Business Rules

* Notifications appear only after successful payment operations.
* Supported methods are WhatsApp, SMS, and None.
* Messages always contain calculated financial values.
* Delete Payment never sends notifications.
* Offline payments do not trigger automatic notifications.
* Notification failures never affect payment success.
* Localization follows the current application language.
* Sensitive internal data is never included.

---

# Architecture

```text id="pn10"
Payment Saved

↓

Financial Recalculation

↓

Notification Dialog

↓

Selected Channel

↓

WhatsApp / SMS / None

↓

External Application
```

---

# End of Section

Next Section:

**5.15 Remaining Balance Calculation**

This section documents the complete financial calculation engine, including Total Paid, Remaining Debt, debt status derivation, ledger aggregation, edge cases, validation rules, and the business formulas that drive every debt-related calculation throughout Tahsel.
# PART 5 — Debt Management

# 5.15 Remaining Balance Calculation

## Overview

The Remaining Balance Calculation Engine is the financial core of the entire Debt Management module.

Every screen that displays debt information depends on this engine.

Examples include:

* Customer Debts
* My Debts
* Debt Details
* Reports
* Dashboard
* Collected Amount
* Analytics
* Employee Collections (Future)

A single incorrect calculation can propagate throughout the application.

For this reason, all financial values are derived from the source of truth instead of being manually maintained.

---

# Design Philosophy

Tahsel follows a strict rule:

> **Never trust stored financial balances. Always calculate from transaction history.**

This guarantees:

* Financial consistency
* Auditability
* Offline reliability
* Synchronization safety

---

# Source of Truth

The only financial source of truth is:

```text id="rb01"
Transactions
```

Never:

```text id="rb02"
remainingDebt

paidAmount

cachedBalance
```

Those values are considered derived values.

---

# Original Debt

The original debt amount is created once.

Example:

```text id="rb03"
Original Debt

10,000 EGP
```

It never changes during normal payment operations.

---

# Total Paid Formula

Formula:

```text id="rb04"
Total Paid

=

Σ(Payment Transactions)
```

Example:

```text id="rb05"
Payment

2,000

+

Payment

1,500

+

Payment

500

=

4,000
```

---

# Remaining Formula

Formula:

```text id="rb06"
Remaining

=

Original Debt

-

Total Paid
```

Example:

```text id="rb07"
Original Debt

10,000

Paid

4,000

Remaining

6,000
```

---

# Ledger Formula (Future)

When Ledger mode becomes the default:

Formula becomes:

```text id="rb08"
Net Paid

=

Σ(All Financial Transactions)
```

Including:

* Payment
* Adjustment
* Reversal

Example:

```text id="rb09"
Payment

1000

+

Adjustment

-300

+

Payment

500

=

1200
```

---

# Status Formula

Debt Status is calculated automatically.

Rules:

```text id="rb10"
Remaining > 0

↓

Partially Paid
```

---

```text id="rb11"
Remaining = Original Debt

↓

Open
```

---

```text id="rb12"
Remaining = 0

↓

Fully Paid
```

No status field is manually maintained.

---

# Example 1

```text id="rb13"
Debt

5000

↓

No Payments
```

Results:

Paid:

0

Remaining:

5000

Status:

Open

---

# Example 2

```text id="rb14"
Debt

5000

↓

Payment

1000
```

Results:

Paid:

1000

Remaining:

4000

Status:

Partially Paid

---

# Example 3

```text id="rb15"
Debt

5000

↓

Payment

5000
```

Results:

Paid:

5000

Remaining:

0

Status:

Fully Paid

---

# Example 4

Multiple payments:

```text id="rb16"
Debt

10000

↓

1000

↓

2500

↓

500

↓

3000
```

Paid:

7000

Remaining:

3000

---

# Example 5

Future Ledger Adjustment:

```text id="rb17"
Debt

10000

↓

Payment

6000

↓

Adjustment

-1000
```

Net Paid:

5000

Remaining:

5000

---

# Calculation Timing

Remaining is recalculated after:

* Add Debt
* Add Payment
* Edit Payment
* Delete Payment
* Adjustment
* Reversal
* Synchronization

No manual refresh required.

---

# Dashboard Dependency

Dashboard statistics depend on:

```text id="rb18"
Remaining

Paid

Debt Status
```

Any calculation error immediately affects dashboard accuracy.

---

# Reports Dependency

The following reports consume Remaining Balance:

* Daily Reports
* Weekly Reports
* Monthly Reports
* Customer Reports
* Debt Reports
* Collection Reports

No report stores independent balances.

---

# Customer Card Dependency

Each customer card displays:

```text id="rb19"
Remaining

Paid

Status
```

These values are recalculated before rendering.

---

# Debt Details Dependency

Debt Details Summary uses:

```text id="rb20"
Original Debt

↓

Transactions

↓

Remaining

↓

Status
```

The summary never reads cached values.

---

# Offline Calculations

Offline mode uses the exact same formulas.

Calculations occur locally.

Synchronization never recalculates using server timestamps.

---

# createdAt Rule

Calculations ignore:

```text id="rb21"
syncedAt

uploadedAt

serverTimestamp
```

Business calculations only depend on:

```text id="rb22"
createdAt
```

for chronological ordering.

---

# Performance Strategy

To avoid expensive recalculations:

* Recalculate only affected debts.
* Refresh only affected customer cards.
* Avoid rebuilding unrelated widgets.
* Cache transaction lists, not financial totals.

---

# Validation Rules

Remaining must never become:

```text id="rb23"
Negative
```

Reject invalid payment operations before saving.

---

# Precision

Currency calculations should:

* Preserve decimal precision.
* Avoid floating-point accumulation errors.
* Format using the application's currency formatter.

---

# Error Recovery

If an invalid transaction is detected:

* Reject the operation.
* Preserve previous financial state.
* Display validation message.

Never partially update balances.

---

# Business Rules

* Remaining is always derived.
* Total Paid is always derived.
* Debt Status is always derived.
* Transactions are the only financial source of truth.
* Cached financial values are never trusted.
* Every payment triggers recalculation.
* Every edit triggers recalculation.
* Every deletion triggers recalculation.
* Offline calculations use the same formulas.
* Reports always consume calculated values.
* Negative remaining balances are prohibited.

---

# Architecture

```text id="rb24"
Transactions

↓

Financial Engine

↓

Total Paid

↓

Remaining

↓

Debt Status

↓

Customer Summary

↓

Dashboard

↓

Reports

↓

Analytics
```

---

# End of Section

Next Section:

**5.16 Reports Integration**

This section documents how the Debt Management module integrates with the reporting engine, including Daily, Weekly, Monthly, Customer, Collection, and Dashboard reports, along with filtering rules, aggregation logic, `createdAt` usage, and report consistency across online and offline modes.
# PART 5 — Debt Management

# 5.16 Reports Integration

## Overview

The Debt Management module is deeply integrated with Tahsel's Reporting Engine.

Every debt-related financial operation immediately affects one or more reports.

Reports are never manually updated.

Instead, every report is generated from the latest transaction data to ensure complete financial consistency.

---

# Objectives

The Reports Integration layer allows Tahsel to:

* Generate real-time financial reports.
* Track customer collections.
* Analyze outstanding debts.
* Monitor payment trends.
* Support business decision-making.
* Provide accurate historical analytics.

---

# Reports Depending on Debt Module

Debt operations contribute to:

* Daily Reports
* Weekly Reports
* Monthly Reports
* Customer Reports
* Debt Reports
* Collected Amount Reports
* Dashboard Statistics
* Financial Analytics

Future:

* Yearly Reports
* Employee Collection Reports
* Branch Reports

---

# Report Trigger Events

Reports refresh automatically after:

* Create Debt
* Edit Debt
* Delete Debt
* Add Payment
* Edit Payment
* Delete Payment
* Offline Synchronization

No manual refresh is required.

---

# Real-Time Update Flow

```text id="ri01"
Financial Operation

↓

Save Transaction

↓

Recalculate Debt

↓

Refresh Cubit

↓

Refresh Reports

↓

Update UI
```

---

# Daily Report

Daily Reports include:

* Debts Created Today
* Payments Collected Today
* Outstanding Remaining
* Fully Paid Debts
* Active Customers

Grouping:

```text id="ri02"
createdAt

↓

Day
```

---

# Weekly Report

Weekly Reports aggregate:

* Weekly Collections
* New Debts
* Customer Activity
* Outstanding Balance

Grouping:

```text id="ri03"
createdAt

↓

Week
```

---

# Monthly Report

Monthly Reports display:

* Total Collections
* Total New Debts
* Remaining Balance
* Payment Count
* Customer Growth

Grouping:

```text id="ri04"
createdAt

↓

Month + Year
```

---

# Customer Report

Each customer report includes:

* Original Debt
* Total Paid
* Remaining
* Payment Timeline
* Debt Status

Everything is calculated dynamically.

---

# Debt Report

Displays:

* Active Debts
* Closed Debts
* Partially Paid Debts
* Remaining Totals

Useful for collection tracking.

---

# Collected Amount Report

Only Payment transactions contribute.

Included:

```text id="ri05"
Payment

Partial Payment
```

Ignored:

* Debt Created
* Adjustment (Current Rules)
* Reversal (Current Rules)

Grouping:

```text id="ri06"
Payment.createdAt
```

---

# Dashboard Statistics

Dashboard receives:

* Total Debt
* Total Paid
* Remaining Balance
* Fully Paid Count
* Active Debt Count

Every statistic originates from transaction calculations.

---

# Historical Accuracy

Reports preserve historical values.

Example:

A payment created on:

```text id="ri07"
8 May
```

and synchronized on:

```text id="ri08"
10 May
```

still appears in:

```text id="ri09"
8 May Report
```

because reports use:

```text id="ri10"
createdAt
```

---

# Timestamp Rule

Reports must never group using:

```text id="ri11"
syncedAt

uploadedAt

serverTimestamp
```

Business reports depend only on:

```text id="ri12"
createdAt
```

---

# Offline Integration

Offline-created transactions immediately appear inside reports.

When synchronization occurs:

Only upload status changes.

Report dates remain unchanged.

---

# Deleted Payments

After deleting a payment:

Reports immediately:

* Remove payment value.
* Restore remaining balance.
* Refresh statistics.

No cached values remain.

---

# Edited Payments

After editing:

Reports automatically:

* Update payment amount.
* Update monthly totals.
* Update customer summaries.
* Update dashboard statistics.

---

# Deleted Debts

Soft-deleted debts are excluded from:

* Active Reports
* Dashboard Statistics
* Customer Lists

Future Audit Reports may include them.

---

# Filtering

Reports support filtering by:

* Customer
* Date Range
* Status
* Payment State

Future:

* Employee
* Branch
* Category

---

# Sorting

Recommended sorting:

Newest first.

Future options:

* Largest Collection
* Largest Remaining
* Alphabetical
* Highest Activity

---

# Performance

Optimizations:

* Incremental recalculation.
* Refresh only affected report sections.
* Lazy loading for large datasets.
* Cached transaction queries.
* No duplicated calculations.

---

# Large Dataset Support

Designed for:

* Thousands of customers.
* Tens of thousands of transactions.
* Multi-year historical reports.

Without blocking the UI thread.

---

# Security

Reports are visible only to authenticated users.

Future role-based access:

* Owner
* Manager
* Employee

Each role may receive different report visibility.

---

# Localization

All report labels support:

* Arabic
* English

Using ARB localization.

---

# Business Rules

* Reports never store financial totals.
* Reports always calculate from transactions.
* Reports refresh automatically after every financial operation.
* createdAt is the only business timestamp.
* Offline transactions immediately appear in reports.
* Synchronization never changes report dates.
* Payment edits update reports instantly.
* Payment deletions update reports instantly.
* Debt deletions remove debts from active reports.
* Dashboard consumes the same calculation engine.

---

# Architecture

```text id="ri13"
Transactions

↓

Financial Calculation Engine

↓

Report Engine

↓

Daily

Weekly

Monthly

Customer

Dashboard

Analytics

↓

UI
```

---

# End of Section

Next Section:

**5.17 Business Rules & Edge Cases**

This section documents every financial rule, validation, exceptional scenario, conflict resolution, and edge case that governs the Debt Management module, ensuring consistent behavior across online, offline, synchronization, and future ledger-based implementations.
# PART 5 — Debt Management

# 5.17 Business Rules & Edge Cases

## Overview

This section defines the core financial rules that govern the Debt Management module.

These rules are considered the highest level of business logic and must be respected across:

* Android
* iOS
* Windows
* Offline Mode
* Firebase Synchronization
* Future Ledger Architecture

Every feature inside the Debt module depends on these rules.

---

# Core Financial Principles

Tahsel follows four fundamental principles:

1. Every financial operation must be traceable.
2. Financial values are always calculated.
3. Business dates always use `createdAt`.
4. Financial history must never become inconsistent.

---

# Source of Truth Rule

The only financial source of truth is:

```text id="br01"
Transactions
```

Never use:

```text id="br02"
remainingDebt

paidAmount

cachedBalance
```

Those are always derived values.

---

# Remaining Balance Rule

Formula:

```text id="br03"
Remaining

=

Original Debt

-

Net Paid
```

Never store Remaining manually.

---

# Total Paid Rule

Formula:

```text id="br04"
Total Paid

=

Σ(Payment Transactions)
```

Never update Paid manually.

---

# Debt Status Rule

Debt Status is always calculated.

Possible values:

```text id="br05"
Open

Partially Paid

Fully Paid
```

No manual status updates.

---

# Transaction Immutability

Financial history should never become inconsistent.

Current implementation:

* Payment editing updates the selected transaction.
* Payment deletion removes the selected transaction.

Future Ledger Mode:

* Edit → Adjustment Transaction.
* Delete → Reversal Transaction.

History remains complete.

---

# createdAt Rule

Business operations always depend on:

```text id="br06"
createdAt
```

Never:

* syncedAt
* uploadedAt
* serverTimestamp

---

# Offline Rule

Offline-created operations preserve:

```text id="br07"
createdAt
```

Synchronization uploads data without changing business dates.

---

# Notification Rule

Notifications are sent only after:

* Partial Payment
* Full Payment
* Edit Payment

Notifications are **not** sent after:

* Delete Payment
* Delete Debt
* Reports
* Login

---

# Debt Creation Rule

Creating a debt automatically creates:

```text id="br08"
Debt Created
```

transaction.

No debt exists without its initial transaction.

---

# Payment Rule

Every payment creates:

```text id="br09"
Payment
```

transaction.

No payment directly edits customer balances.

---

# Edit Rule

Editing a payment:

Current:

Updates selected payment.

Future:

Creates Adjustment Transaction.

Both approaches require complete recalculation.

---

# Delete Rule

Deleting a payment:

Current:

Deletes selected transaction.

Future:

Creates Reversal Transaction.

Both restore Remaining automatically.

---

# Debt Protection Rule

The initial:

```text id="br10"
Debt Created
```

transaction is protected.

Current Tahsel implementation:

Editing or deleting it is allowed only under restricted business conditions (for example, when it is the latest operation and validation passes).

Otherwise:

Actions remain disabled.

---

# Negative Balance Rule

Remaining Balance must never become:

```text id="br11"
Negative
```

Reject operation before saving.

---

# Duplicate Submission Rule

While saving:

* Disable buttons.
* Ignore repeated taps.
* Prevent duplicate writes.

Applies to:

* Debt Creation
* Payment
* Edit
* Delete

---

# Report Consistency Rule

Reports never store balances.

Reports always calculate from:

```text id="br12"
Transactions
```

---

# Synchronization Rule

Synchronization must never modify:

```text id="br13"
createdAt
```

Only upload pending operations.

---

# UI Rule

Widgets never perform business calculations.

UI only displays values received from Cubit.

---

# Cubit Rule

Cubit responsibilities:

* Execute UseCases.
* Emit states.
* Refresh UI.

Cubit never contains financial formulas.

---

# UseCase Rule

Every business calculation belongs inside:

```text id="br14"
UseCases
```

Never inside:

* Widgets
* Cubits
* Repository

---

# Repository Rule

Repository responsibilities:

* Read data.
* Write data.
* Synchronize.

Repository never owns business rules.

---

# Edge Case 1

Customer pays:

```text id="br15"
0
```

Result:

Reject operation.

---

# Edge Case 2

Negative payment:

```text id="br16"
-500
```

Reject operation.

---

# Edge Case 3

Payment larger than Remaining:

Example:

Remaining:

```text id="br17"
1000
```

User enters:

```text id="br18"
1500
```

Reject operation.

---

# Edge Case 4

Delete Last Payment

Example:

```text id="br19"
Debt

5000

↓

Payment

5000
```

Delete payment.

Result:

Remaining:

```text id="br20"
5000
```

Status:

```text id="br21"
Open
```

---

# Edge Case 5

Edit Fully Paid Debt

Example:

Debt:

```text id="br22"
5000
```

Paid:

```text id="br23"
5000
```

Edit payment to:

```text id="br24"
3000
```

Result:

Remaining:

```text id="br25"
2000
```

Status automatically changes:

```text id="br26"
Fully Paid

↓

Partially Paid
```

---

# Edge Case 6

Offline Payment

Payment created offline.

Reports update immediately.

Synchronization later uploads only the transaction.

Business date remains unchanged.

---

# Edge Case 7

Offline Edit

Edit stored locally.

Synchronization updates payment without changing:

```text id="br27"
createdAt
```

---

# Edge Case 8

Offline Delete

Delete queued locally.

Remaining recalculated locally.

Synchronization removes or reverses transaction later.

---

# Edge Case 9

Large Transaction History

Debt with:

* Hundreds of payments.
* Multiple years.

System still calculates Remaining from transaction history.

No cached balances.

---

# Edge Case 10

Synchronization Delay

Payment created:

```text id="br28"
8 May
```

Uploaded:

```text id="br29"
12 May
```

Reports still display:

```text id="br30"
8 May
```

because business reports use:

```text id="br31"
createdAt
```

---

# Performance Rules

Always:

* Refresh only affected debt.
* Avoid unnecessary rebuilds.
* Cache transaction queries.
* Never cache financial totals.

---

# Security Rules

Financial operations require:

* Authenticated account.
* Active subscription.
* Valid platform assignment.
* Authorized workspace.

---

# Business Rules Summary

* Financial history is the source of truth.
* Remaining is always calculated.
* Paid is always calculated.
* Status is always calculated.
* Reports always calculate from transactions.
* Business dates always use createdAt.
* Notifications respect user preference.
* Offline mode preserves financial integrity.
* Synchronization never changes business dates.
* UI never performs financial calculations.
* Ledger integrity always has higher priority than convenience.

---

# Architecture

```text id="br32"
UI

↓

Cubit

↓

UseCases

↓

Repository

↓

Transactions

↓

Financial Engine

↓

Reports

↓

Updated UI
```

---

# End of PART 5 — Debt Management

This completes the **Debt Management** documentation.

The next major section is:

# PART 6 — My Debts

This section documents the complete **My Debts** module, including its architecture, workflows, business rules, reports, notifications, synchronization behavior, and how it differs from the Customer Debts module.
# PART 6 — My Debts

# 6.1 Overview

## Introduction

The **My Debts** module is the personal debt management system inside Tahsel.

Unlike **Customer Debts**, which tracks money owed **to the business**, My Debts tracks money that the business **owes to other people or organizations**.

Examples include:

* Supplier debts
* Personal loans
* Rent obligations
* Equipment purchases
* Installment purchases
* Business liabilities

The module uses the same financial engine as Customer Debts, ensuring identical calculation accuracy while representing the opposite financial direction.

---

# Objectives

The My Debts module allows users to:

* Record debts owed by the business.
* Record payments made toward those debts.
* Track remaining liabilities.
* Review payment history.
* Analyze outstanding obligations.
* Generate reports.
* Work offline.
* Synchronize across devices.

---

# Financial Direction

Customer Debts:

```text id="md01"
Customers

↓

Pay Money

↓

To You
```

---

My Debts:

```text id="md02"
You

↓

Pay Money

↓

To Others
```

Although the financial direction changes, the calculation engine remains identical.

---

# Shared Financial Engine

Both modules use:

* Remaining Calculation
* Total Paid Calculation
* Ledger Transactions
* Reports Engine
* Offline Queue
* Synchronization Engine

Only terminology changes.

---

# Examples

Examples of My Debts:

```text id="md03"
Supplier Invoice

Store Rent

Office Furniture

Company Loan

Equipment Purchase

Installment Purchase
```

---

# Navigation

Users access the module through:

```text id="md04"
Main Menu

↓

My Debts
```

---

# Main Screen

The main screen displays:

* Summary Card
* Search
* My Debts List
* Floating Action Button

---

# Summary Card

Displays:

* Total Debt
* Total Paid
* Remaining Balance
* Active Debts

Example:

```text id="md05"
Total Debt

50,000

Paid

18,000

Remaining

32,000
```

---

# Debt List

Each debt card displays:

* Creditor Name
* Original Amount
* Remaining
* Status
* Last Payment Date

The layout follows the same design language as Customer Debts.

---

# Debt Status

Possible statuses:

```text id="md06"
Open

Partially Paid

Fully Paid
```

Calculated automatically.

---

# Search

Users may search using:

* Creditor Name
* Phone Number
* Notes

Search supports debounce for performance.

---

# Sorting

Supported sorting:

* Newest First
* Oldest First
* Highest Remaining
* Highest Original Amount

Future:

* Last Payment
* Alphabetical

---

# Filtering

Future filters:

* Open Debts
* Fully Paid
* Partially Paid
* Date Range

---

# Add Debt

Users create new liabilities through:

```text id="md07"
Floating Action Button

↓

Add My Debt
```

The workflow mirrors Customer Debts.

---

# Debt Details

Selecting a debt opens:

```text id="md08"
My Debt Details
```

The screen displays:

* Summary
* Payment Timeline
* Remaining
* Transactions
* Add Payment

---

# Payments

Supports:

* Partial Payment
* Full Payment
* Edit Payment
* Delete Payment

Using the same payment engine as Customer Debts.

---

# Reports

My Debts contribute to:

* Daily Reports
* Weekly Reports
* Monthly Reports
* Outstanding Liabilities
* Financial Analytics

Separated from Customer Debt reports.

---

# Notifications

Supports:

* WhatsApp
* SMS
* None

Depending on current notification settings.

Notifications are optional.

---

# Offline Mode

Fully supported.

Users can:

* Add debts.
* Record payments.
* Edit payments.
* Delete payments.

Synchronization occurs automatically later.

---

# Synchronization

Business timestamps always use:

```text id="md09"
createdAt
```

Never:

* syncedAt
* uploadedAt

---

# Performance

Optimizations include:

* Lazy list rendering.
* Incremental updates.
* Efficient Cubit states.
* Derived calculations only.

---

# Security

Access requires:

* Authenticated account.
* Active subscription.
* Authorized workspace.
* Correct platform assignment.

---

# Localization

Supports:

* Arabic
* English

Using the existing ARB localization system.

---

# Business Rules

* Uses the same financial engine as Customer Debts.
* All balances are calculated dynamically.
* Remaining is never manually stored.
* Reports update automatically.
* Offline mode behaves identically.
* createdAt is the business timestamp.
* Financial consistency is preserved across all platforms.

---

# Architecture

```text id="md10"
My Debts Screen

↓

MyDebtsCubit

↓

UseCases

↓

Repository

↓

Transactions

↓

Financial Engine

↓

Updated UI
```

---

# End of Section

Next Section:

**6.2 My Debts Architecture**

This section explains the complete architecture of the My Debts module, including Presentation Layer, Domain Layer, Data Layer, Cubits, UseCases, Repository responsibilities, synchronization flow, and how it reuses the Customer Debts financial engine while maintaining independent business data.
# PART 6 — My Debts

# 6.2 Architecture

## Overview

The **My Debts** module follows the exact same Clean Architecture adopted throughout Tahsel.

Although the business direction differs from Customer Debts (money owed by the business instead of money owed to the business), the architecture remains identical.

This ensures:

* Maximum code reuse.
* Consistent financial calculations.
* Easier maintenance.
* High scalability.
* Predictable application behavior.

---

# Architecture Layers

The module is divided into three primary layers:

```text id="mda01"
Presentation Layer

↓

Domain Layer

↓

Data Layer
```

Each layer has a clearly defined responsibility.

---

# Presentation Layer

Responsibilities:

* Display UI.
* Handle user interaction.
* Listen to Cubit states.
* Render updated financial information.

The Presentation Layer never performs financial calculations.

---

# Presentation Components

Contains:

* My Debts Screen
* My Debt Details Screen
* Add My Debt Screen
* Payment Dialogs
* Summary Cards
* Transaction Timeline
* Slidable Actions

---

# Cubit Responsibilities

Cubits orchestrate the module.

Responsibilities include:

* Calling UseCases.
* Emitting Loading states.
* Emitting Success states.
* Emitting Error states.
* Refreshing UI.

Cubits never calculate:

* Remaining
* Paid
* Status

---

# Example Flow

```text id="mda02"
User Adds Payment

↓

Cubit

↓

AddPaymentUseCase

↓

Repository

↓

Firebase

↓

Updated State
```

---

# Domain Layer

The Domain Layer contains all business rules.

It is completely independent from:

* Flutter
* Firebase
* UI

This layer represents the business itself.

---

# Domain Components

Contains:

* Entities
* UseCases
* Repository Contracts

---

# Entities

Examples:

```text id="mda03"
MyDebtEntity

TransactionEntity

PaymentEntity
```

Entities contain pure business data.

---

# UseCases

Examples:

```text id="mda04"
CreateMyDebtUseCase

UpdateMyDebtUseCase

DeleteMyDebtUseCase

AddPaymentUseCase

EditPaymentUseCase

DeletePaymentUseCase

GetMyDebtDetailsUseCase
```

Each UseCase performs exactly one business responsibility.

---

# Business Rules

Every financial calculation belongs inside UseCases.

Examples:

* Remaining Calculation
* Total Paid
* Status
* Validation
* Report Aggregation

Never inside UI.

---

# Repository Contract

The Domain layer depends only on interfaces.

Example:

```text id="mda05"
BaseMyDebtRepository
```

The Domain layer never knows Firebase implementation details.

---

# Data Layer

Responsibilities:

* Read data.
* Write data.
* Offline storage.
* Synchronization.
* Serialization.

---

# Repository Implementation

Example:

```text id="mda06"
MyDebtRepositoryImpl
```

Responsibilities:

* Call Remote DataSource.
* Call Local DataSource.
* Handle synchronization.

No business calculations.

---

# Remote Data Source

Responsibilities:

* Firebase reads.
* Firebase writes.
* Query execution.
* Cloud synchronization.

---

# Local Data Source

Responsibilities:

* Offline queue.
* Cached debts.
* Cached transactions.
* Pending synchronization.

---

# Models

The Data Layer converts between:

```text id="mda07"
JSON

↓

Models

↓

Entities
```

Models should never contain business rules.

---

# Financial Engine

The financial engine is shared with Customer Debts.

Responsible for:

* Remaining Calculation
* Total Paid
* Status
* Reports
* Dashboard Statistics

Only the business context changes.

---

# State Flow

Typical operation:

```text id="mda08"
UI

↓

Cubit

↓

UseCase

↓

Repository

↓

DataSource

↓

Firebase

↓

Repository

↓

Cubit

↓

Updated UI
```

---

# Offline Architecture

When offline:

```text id="mda09"
UI

↓

Cubit

↓

Repository

↓

Local Queue

↓

Synchronization Later
```

The user continues working normally.

---

# Synchronization

Synchronization uploads:

* New Debts
* Payments
* Updates
* Deletions

Business timestamps remain unchanged.

---

# Timestamp Rules

Business logic always depends on:

```text id="mda10"
createdAt
```

Never:

* syncedAt
* uploadedAt
* serverTimestamp

---

# Report Integration

The architecture automatically updates:

* Daily Reports
* Weekly Reports
* Monthly Reports
* Outstanding Liability Reports
* Dashboard

after every successful operation.

---

# Error Flow

If an operation fails:

```text id="mda11"
Repository

↓

Failure

↓

Cubit

↓

Error State

↓

Error UI
```

Business state remains unchanged.

---

# Dependency Injection

Every layer is injected using Tahsel's dependency injection container.

Benefits:

* Loose coupling.
* Easier testing.
* Better scalability.

---

# Testing Strategy

The architecture supports independent testing for:

* Cubits.
* UseCases.
* Repository.
* Data Sources.

Each layer can be tested in isolation.

---

# Performance

Architecture optimizations include:

* Minimal Cubit rebuilds.
* Single responsibility UseCases.
* Incremental report updates.
* Efficient repository caching.
* Lazy UI rendering.

---

# SOLID Compliance

The module follows:

* Single Responsibility Principle
* Open/Closed Principle
* Liskov Substitution Principle
* Interface Segregation Principle
* Dependency Inversion Principle

---

# Business Rules

* UI never performs calculations.
* Cubit orchestrates only.
* UseCases own business logic.
* Repository owns data access.
* Data Sources communicate with storage.
* Models serialize data only.
* Entities represent business objects.
* Reports consume calculated values.
* createdAt is the business timestamp.
* Financial integrity has higher priority than implementation convenience.

---

# Architecture Diagram

```text id="mda12"
Presentation

↓

Cubit

↓

UseCases

↓

Repository Interface

↓

Repository Implementation

↓

Remote Data Source

↓

Local Data Source

↓

Firebase / Offline Storage
```

---

# End of Section

Next Section:

**6.3 Create My Debt**

This section documents the complete workflow for creating a new personal/business liability, including creditor selection, validation, ledger initialization, financial calculations, synchronization, reports, and all related business rules.
# PART 6 — My Debts

# 6.3 Create My Debt

## Overview

The **Create My Debt** feature allows users to register a new financial liability that the business owes to another person or organization.

A newly created debt becomes immediately available across the entire application and participates in:

* Remaining Balance Calculation
* Reports
* Dashboard Statistics
* Financial Analytics
* Offline Synchronization

Creating a debt is considered the starting point of the debt lifecycle.

---

# Objectives

The Create My Debt feature allows users to:

* Register new liabilities.
* Record supplier debts.
* Record personal loans.
* Record installment obligations.
* Track future payments.
* Generate financial reports.

---

# Entry Point

Users access the feature through:

```text id="cmd01"
My Debts

↓

Floating Action Button

↓

Add My Debt
```

---

# Screen Layout

The Add My Debt screen contains:

* Creditor Information
* Debt Information
* Notes
* Save Button

Future:

* Attachments
* Images
* Documents

---

# Required Fields

Mandatory:

* Creditor Name
* Total Debt Amount

Optional:

* Phone Number
* Notes
* Address

---

# Creditor Information

Displays:

* Name
* Phone Number
* Notes

Future:

* Company Name
* Tax Number
* Email

---

# Debt Information

Displays:

* Original Amount
* Creation Date

Future:

* Due Date
* Category
* Currency

---

# Amount Validation

Rules:

* Required
* Numeric
* Greater than zero

Example:

Valid:

```text id="cmd02"
500

2500

10000
```

Invalid:

```text id="cmd03"
0

-100

Empty
```

---

# Save Flow

```text id="cmd04"
Enter Information

↓

Validate

↓

Create Debt

↓

Create Initial Transaction

↓

Save

↓

Refresh UI

↓

Refresh Reports
```

---

# Initial Transaction

Creating a debt automatically creates:

```text id="cmd05"
Debt Created
```

transaction.

This transaction represents the original debt.

Example:

```text id="cmd06"
Debt Created

15,000 EGP
```

---

# Initial Financial State

Immediately after creation:

```text id="cmd07"
Original Debt

15,000

Paid

0

Remaining

15,000

Status

Open
```

Everything is calculated automatically.

---

# Timeline

The Debt Details screen immediately displays:

```text id="cmd08"
Debt Created

↓

(No Payments Yet)
```

The payment history starts empty except for the creation transaction.

---

# Reports Integration

Immediately after saving:

Update:

* Daily Reports
* Weekly Reports
* Monthly Reports
* Outstanding Liabilities
* Dashboard Statistics

No manual refresh.

---

# Dashboard Update

Dashboard statistics increase:

* Total Debt
* Outstanding Balance
* Active Debt Count

Collected Amount remains unchanged because no payment exists.

---

# Notification Behavior

Creating a debt **does not** trigger:

* WhatsApp
* SMS

Customer communication begins only after payment operations.

---

# Offline Support

Debt creation works offline.

Flow:

```text id="cmd09"
Create Debt

↓

Store Locally

↓

Offline Queue

↓

Synchronize Later
```

---

# Synchronization

Synchronization uploads:

* Debt Information
* Initial Transaction
* Notes

Business timestamp:

```text id="cmd10"
createdAt
```

must remain unchanged.

---

# Timestamp Rules

Business operations always depend on:

```text id="cmd11"
createdAt
```

Never:

* syncedAt
* uploadedAt
* serverTimestamp

---

# Duplicate Protection

During saving:

* Disable Save button.
* Prevent repeated taps.
* Prevent duplicate debt creation.

---

# Error Handling

Examples:

```text id="cmd12"
Invalid Amount

Missing Creditor Name

Unable to Save

Network Error
```

The entered information remains available for correction.

---

# Loading State

While saving:

* Disable all inputs.
* Show loading indicator.
* Prevent leaving the screen accidentally.

---

# Performance

Optimizations:

* Single database write.
* Single initial transaction.
* Incremental dashboard update.
* Incremental report update.
* Minimal Cubit rebuilds.

---

# Security

Only authenticated users with:

* Active Subscription
* Authorized Workspace
* Valid Account Status

may create new debts.

---

# Business Rules

* Every debt automatically creates one **Debt Created** transaction.
* Remaining equals Original Debt immediately after creation.
* Paid equals zero.
* Status equals Open.
* Reports update automatically.
* Dashboard updates automatically.
* Offline creation preserves createdAt.
* Notifications are not sent during debt creation.
* UI never calculates financial values.

---

# Architecture

```text id="cmd13"
Add My Debt Screen

↓

MyDebtsCubit

↓

CreateMyDebtUseCase

↓

Repository

↓

Create Debt

↓

Create Initial Transaction

↓

Refresh Reports

↓

Updated UI
```

---

# End of Section

Next Section:

**6.4 Edit My Debt**

This section documents the complete workflow for editing personal/business liabilities, including editable fields, financial validation, transaction protection, synchronization behavior, report updates, and all business rules governing debt modifications.
# PART 6 — My Debts

# 6.4 Edit My Debt

## Overview

The **Edit My Debt** feature allows users to update the information of an existing liability while preserving financial integrity.

Editing a debt is different from editing a payment.

A debt edit modifies the debt itself, while payment edits modify financial transactions related to that debt.

Tahsel validates every modification before saving to prevent inconsistent financial data.

---

# Objectives

The Edit My Debt feature allows users to:

* Correct creditor information.
* Update debt notes.
* Update debt amount (when business rules allow).
* Correct creation mistakes.
* Refresh reports automatically.

---

# Entry Point

Users edit a debt from:

```text id="emd01"
My Debt Details

↓

More Menu

↓

Edit Debt
```

or

```text id="emd02"
Swipe Right

↓

Edit
```

depending on the platform UI.

---

# Editable Fields

Current editable fields:

* Creditor Name
* Phone Number
* Notes

Conditionally editable:

* Original Debt Amount

---

# Protected Fields

The following fields cannot be edited directly:

* Debt ID
* createdAt
* Firebase Document ID
* Transaction History

These fields are immutable.

---

# Original Amount Rule

Changing the original debt amount is a sensitive operation.

Current business rules:

If **no payment transactions exist**, the amount may be edited.

If **payments already exist**, editing the original amount requires additional validation or should be restricted according to business policy.

---

# Validation Flow

Before saving:

Validate:

* Required fields.
* Numeric amount.
* Amount greater than zero.
* Business rule compliance.

Reject invalid updates.

---

# Edit Flow

```text id="emd03"
Open Edit Screen

↓

Modify Data

↓

Validate

↓

Update Debt

↓

Recalculate

↓

Refresh Reports

↓

Refresh UI
```

---

# Financial Recalculation

If the original debt amount changes:

Automatically recalculate:

```text id="emd04"
Remaining

=

Original Debt

-

Total Paid
```

No manual updates.

---

# Example

Before edit:

```text id="emd05"
Debt

10,000

Paid

3,000

Remaining

7,000
```

After changing debt to:

```text id="emd06"
12,000
```

Automatically:

```text id="emd07"
Remaining

9,000
```

---

# Timeline

Editing debt information does **not** create a new payment transaction.

Current implementation:

Debt information is updated.

Future Ledger mode may introduce:

```text id="emd08"
Debt Adjustment
```

transaction for audit purposes.

---

# Reports Update

Immediately refresh:

* Outstanding Liabilities
* Dashboard
* Monthly Reports
* Customer Statistics
* Financial Analytics

---

# Dashboard Update

Dashboard recalculates:

* Total Debt
* Remaining Balance
* Active Debts

No manual refresh required.

---

# Notification Behavior

Editing debt information does **not** automatically notify the creditor.

Future versions may optionally support:

* WhatsApp
* SMS

for debt amount changes.

---

# Offline Support

Debt editing is fully supported offline.

Flow:

```text id="emd09"
Edit Debt

↓

Store Offline

↓

Queue Sync

↓

Synchronize Later
```

---

# Synchronization

Synchronization uploads:

* Updated Debt Information
* Updated Notes

Never overwrite:

```text id="emd10"
createdAt
```

---

# Duplicate Protection

While saving:

* Disable Save button.
* Ignore repeated taps.
* Prevent duplicate updates.

---

# Error Handling

Examples:

```text id="emd11"
Unable to Update

Invalid Amount

Network Error
```

Changes remain available for correction.

---

# Loading State

During update:

* Disable inputs.
* Show loading indicator.
* Prevent duplicate submissions.

---

# Performance

Optimizations:

* Update only affected debt.
* Refresh only dependent reports.
* Efficient Cubit state updates.
* Minimal widget rebuilds.

---

# Security

Only authenticated users with:

* Active Subscription
* Authorized Workspace
* Valid Account Status

may edit debts.

---

# Business Rules

* Debt ID never changes.
* createdAt never changes.
* Transaction history is preserved.
* Remaining is always recalculated after amount changes.
* Reports update automatically.
* Dashboard refreshes automatically.
* Offline edits preserve business dates.
* UI never performs financial calculations.
* Business validation determines whether the original amount may be edited after payments exist.

---

# Architecture

```text id="emd12"
Edit My Debt Screen

↓

MyDebtsCubit

↓

UpdateMyDebtUseCase

↓

Repository

↓

Update Debt

↓

Financial Recalculation

↓

Reports Refresh

↓

Updated UI
```

---

# End of Section

Next Section:

**6.5 Delete My Debt**

This section documents the complete workflow for deleting a liability, including validation rules, confirmation dialogs, protection against deleting debts with existing payments, synchronization behavior, report updates, and all business rules governing debt deletion.
# PART 6 — My Debts

# 6.5 Delete My Debt

## Overview

The **Delete My Debt** feature allows users to remove an existing liability from the system.

Because deleting a debt directly affects financial records, Tahsel applies strict business validation before allowing the operation.

The primary objective is to prevent accidental data loss and maintain financial integrity.

---

# Objectives

The Delete My Debt feature allows users to:

* Remove incorrectly created debts.
* Prevent orphaned payment records.
* Preserve financial consistency.
* Refresh reports immediately.
* Maintain synchronization integrity.

---

# Entry Point

Users delete a debt from:

```text id="dmd01"
My Debt Details

↓

More Menu

↓

Delete Debt
```

or

```text id="dmd02"
Swipe Left

↓

Delete
```

depending on the platform.

---

# Confirmation Dialog

Before deletion, Tahsel displays:

```text id="dmd03"
Delete this debt?

This action may affect reports and financial history.

[Cancel]

[Delete]
```

Deletion never occurs without confirmation.

---

# Validation Flow

Before deleting, the system validates:

* Debt exists.
* User has permission.
* Debt is not protected.
* Business rules are satisfied.

---

# Payment Validation

Current business rule:

If the debt contains existing payment transactions:

```text id="dmd04"
Deletion Not Allowed
```

Reason:

Removing the debt would orphan payment history.

The user should instead:

* Delete payments first (if permitted), or
* Archive the debt (future feature).

---

# Safe Deletion Scenario

Deletion is allowed when:

```text id="dmd05"
Debt

↓

No Payments

↓

Delete
```

This removes:

* Debt Record
* Initial Debt Transaction

---

# Protected Scenario

Example:

```text id="dmd06"
Debt

10,000

↓

Payment

2,000
```

Attempting deletion results in:

```text id="dmd07"
Cannot delete a debt that already has payment history.
```

---

# Future Soft Delete

Future versions may replace physical deletion with:

```text id="dmd08"
Soft Delete
```

Benefits:

* Preserves history.
* Supports audit logs.
* Allows recovery.
* Improves accounting compliance.

---

# Delete Flow

```text id="dmd09"
Open Delete

↓

Confirmation

↓

Validate

↓

Delete Debt

↓

Refresh Reports

↓

Refresh UI
```

---

# Dashboard Impact

After successful deletion:

Update:

* Total Debt
* Remaining Balance
* Active Debt Count

Dashboard refreshes automatically.

---

# Reports Impact

Immediately update:

* Daily Reports
* Weekly Reports
* Monthly Reports
* Outstanding Liabilities
* Dashboard Statistics

Deleted debts disappear from active reports.

---

# Timeline Impact

If deletion succeeds:

The entire debt timeline is removed.

If deletion is rejected:

Timeline remains unchanged.

---

# Notification Behavior

Deleting a debt **does not** send:

* WhatsApp
* SMS

No external communication occurs.

---

# Offline Support

Deletion works offline.

Flow:

```text id="dmd10"
Delete

↓

Store Operation

↓

Offline Queue

↓

Synchronize Later
```

The UI updates immediately.

---

# Synchronization

Synchronization uploads:

* Delete Operation

Business timestamps remain unchanged.

```text id="dmd11"
createdAt
```

is never modified.

---

# Error Handling

Examples:

```text id="dmd12"
Unable to Delete

Debt Contains Payments

Network Error
```

The debt remains intact.

---

# Loading State

During deletion:

* Disable buttons.
* Show loading indicator.
* Prevent duplicate requests.

---

# Duplicate Protection

Tahsel ignores:

* Double taps.
* Repeated delete requests.
* Multiple simultaneous operations.

---

# Performance

Optimizations:

* Delete only affected debt.
* Refresh dependent reports.
* Incremental Cubit updates.
* Avoid unnecessary rebuilds.

---

# Security

Only authenticated users with:

* Active Subscription
* Authorized Workspace
* Valid Permissions

may delete debts.

---

# Business Rules

* Every deletion requires confirmation.
* Debts with payment history cannot be deleted.
* Reports refresh automatically after deletion.
* Dashboard updates immediately.
* Offline deletion is supported.
* createdAt remains unchanged.
* Notifications are never sent after deletion.
* UI never performs business validation.

---

# Architecture

```text id="dmd13"
Delete My Debt

↓

MyDebtsCubit

↓

DeleteMyDebtUseCase

↓

Repository

↓

Delete Record

↓

Refresh Reports

↓

Updated UI
```

---

# End of Section

Next Section:

**6.6 My Debt Details**

This section documents the complete My Debt Details screen, including the summary card, payment timeline, transaction history, financial calculations, Slidable actions, reports integration, synchronization behavior, and all business rules governing debt details.
# PART 6 — My Debts

# 6.6 My Debt Details

## Overview

The **My Debt Details** screen is the central workspace for managing a single liability.

It displays all financial information related to one debt and serves as the entry point for every operation performed on that debt.

Users can:

* View debt information.
* Review payment history.
* Add payments.
* Edit payments.
* Delete payments.
* Analyze remaining balance.
* View complete transaction history.

This screen always displays the latest calculated financial state.

---

# Objectives

The My Debt Details screen allows users to:

* Understand the current debt status.
* Record new payments.
* Track historical payments.
* Review remaining balance.
* Verify payment timeline.
* Manage debt operations safely.

---

# Navigation Flow

```text id="mdd01"
My Debts

↓

Select Debt

↓

My Debt Details
```

The selected debt is loaded immediately.

---

# Screen Structure

The screen consists of:

* Header
* Summary Card
* Debt Information
* Payment Timeline
* Floating Action Button

---

# Header

Displays:

* Creditor Name
* Debt Status
* More Actions

Supported actions:

* Edit Debt
* Delete Debt

---

# Summary Card

Displays:

* Original Debt
* Total Paid
* Remaining
* Status

Example:

```text id="mdd02"
Original

15,000

Paid

6,000

Remaining

9,000

Status

Partially Paid
```

---

# Debt Information

Displays:

* Creditor Name
* Phone Number
* Notes
* Creation Date

Future:

* Due Date
* Category
* Attachments

---

# Status Badge

Possible values:

```text id="mdd03"
Open

Partially Paid

Fully Paid
```

Status is calculated automatically.

---

# Transaction Timeline

The timeline displays every financial operation.

Current implementation:

```text id="mdd04"
Debt Created

↓

Payment

↓

Payment

↓

Payment
```

Future Ledger implementation:

```text id="mdd05"
Debt Created

↓

Payment

↓

Adjustment

↓

Reversal

↓

Payment
```

---

# Timeline Ordering

Transactions are ordered using:

```text id="mdd06"
createdAt
```

Newest transactions appear first.

Synchronization timestamps are ignored.

---

# Transaction Card

Each transaction displays:

* Operation Type
* Amount
* Date
* Notes

Future:

* Employee
* Device
* Receipt Number

---

# Slidable Actions

Payment transactions support:

```text id="mdd07"
Swipe Right

↓

Edit
```

and

```text id="mdd08"
Swipe Left

↓

Delete
```

Implemented using:

```text id="mdd09"
flutter_slidable
```

---

# Protected Transactions

The following transactions cannot normally be edited or deleted:

* Debt Created
* Future Adjustment
* Future Reversal

Only payment transactions expose Slidable actions.

---

# Floating Action Button

The FAB allows users to:

```text id="mdd10"
Add Payment
```

Selecting it opens the payment dialog.

---

# Financial Summary

Every displayed value is calculated from transactions.

Formula:

```text id="mdd11"
Remaining

=

Original Debt

-

Total Paid
```

No cached balances are displayed.

---

# Real-Time Updates

After:

* Add Payment
* Edit Payment
* Delete Payment

Automatically refresh:

* Summary Card
* Timeline
* Status
* Reports
* Dashboard

---

# Reports Integration

The screen contributes to:

* Daily Reports
* Weekly Reports
* Monthly Reports
* Outstanding Liabilities
* Dashboard Statistics

No manual synchronization is required.

---

# Offline Support

The screen is fully functional offline.

Users may:

* View debt.
* Add payment.
* Edit payment.
* Delete payment.

Operations synchronize automatically later.

---

# Synchronization

Business ordering always depends on:

```text id="mdd12"
createdAt
```

Never:

* syncedAt
* uploadedAt
* serverTimestamp

---

# Empty State

If no payments exist:

Display:

```text id="mdd13"
Debt Created

↓

No Payments Yet
```

---

# Loading State

While loading:

* Display loading indicator.
* Disable interactions.
* Prevent incomplete rendering.

---

# Error State

Examples:

```text id="mdd14"
Unable to Load Debt

Network Error

Try Again
```

Existing cached data remains visible when available.

---

# Performance

Optimizations:

* Lazy transaction rendering.
* Incremental Cubit updates.
* Minimal widget rebuilds.
* Cached transaction queries.
* Derived financial calculations.

---

# Security

Access requires:

* Authenticated account.
* Active subscription.
* Authorized workspace.

Users may only view debts they have permission to access.

---

# Business Rules

* Summary values are always calculated.
* Timeline uses createdAt ordering.
* Payment transactions support Slidable actions.
* Debt Created transaction is protected.
* Reports refresh after every financial operation.
* Offline mode behaves identically to online mode.
* UI never performs financial calculations.
* Financial history remains the source of truth.

---

# Architecture

```text id="mdd15"
My Debt Details Screen

↓

MyDebtDetailsCubit

↓

GetMyDebtDetailsUseCase

↓

Repository

↓

Transactions

↓

Financial Engine

↓

Updated UI
```

---

# End of Section

Next Section:

**6.7 Add Payment**

This section documents the complete payment workflow for **My Debts**, including partial payments, full payments, dialog behavior, validation, notifications, synchronization, financial calculations, and all related business rules.
# PART 6 — My Debts

# 6.7 Add Payment

## Overview

The **Add Payment** feature allows users to record payments made toward a liability.

Every payment immediately affects the financial state of the debt and automatically updates:

* Remaining Balance
* Total Paid
* Debt Status
* Reports
* Dashboard Statistics
* Financial Analytics

The payment becomes part of the permanent transaction history.

---

# Objectives

The Add Payment feature allows users to:

* Record partial payments.
* Record full payments.
* Track payment history.
* Reduce outstanding liabilities.
* Keep reports synchronized.
* Maintain financial accuracy.

---

# Entry Point

Users add a payment from:

```text id="map01"
My Debt Details

↓

Add Payment
```

using the Floating Action Button.

---

# Payment Dialog

The payment dialog contains:

* Paid Amount
* Notes (Optional)

Future:

* Payment Method
* Receipt Number
* Attachment

---

# Required Fields

Mandatory:

* Paid Amount

Optional:

* Notes

---

# Validation

Before saving:

Validate:

* Amount is entered.
* Amount is numeric.
* Amount is greater than zero.
* Amount does not exceed the remaining balance.

Reject invalid submissions.

---

# Payment Flow

```text id="map02"
Open Dialog

↓

Enter Amount

↓

Validate

↓

Create Payment Transaction

↓

Recalculate

↓

Refresh UI

↓

Show Notification Dialog
```

---

# Payment Transaction

Saving a payment creates:

```text id="map03"
Payment
```

transaction.

Example:

```text id="map04"
Payment

2,500 EGP
```

The transaction is added to the timeline.

---

# Partial Payment Example

Before payment:

```text id="map05"
Debt

10,000

Paid

2,000

Remaining

8,000
```

User pays:

```text id="map06"
3,000
```

Result:

```text id="map07"
Paid

5,000

Remaining

5,000

Status

Partially Paid
```

---

# Full Payment Example

Before payment:

```text id="map08"
Remaining

2,000
```

User pays:

```text id="map09"
2,000
```

Result:

```text id="map10"
Paid

10,000

Remaining

0

Status

Fully Paid
```

---

# Financial Calculation

Tahsel immediately recalculates:

```text id="map11"
Total Paid

=

Σ(Payment Transactions)

--------------------

Remaining

=

Original Debt

-

Total Paid
```

All calculations come from transaction history.

---

# Timeline Update

Immediately after saving:

```text id="map12"
Debt Created

↓

Payment

(New)
```

The newest payment appears at the top of the timeline.

---

# Notification Dialog

After successful payment:

Display:

```text id="map13"
Notify Creditor?

○ WhatsApp

○ SMS

○ None

[Confirm]
```

The notification system follows the same implementation used throughout Tahsel.

---

# Reports Update

Immediately refresh:

* Daily Reports
* Weekly Reports
* Monthly Reports
* Outstanding Liabilities
* Dashboard Statistics
* Financial Analytics

---

# Dashboard Update

Automatically update:

* Total Paid
* Remaining Balance
* Fully Paid Count
* Outstanding Debt

No manual refresh.

---

# Offline Support

Payments can be recorded offline.

Flow:

```text id="map14"
Create Payment

↓

Offline Queue

↓

Local Calculation

↓

Synchronize Later
```

The user experiences identical behavior online and offline.

---

# Synchronization

Synchronization uploads:

* Payment Transaction
* Notes

Business timestamps always preserve:

```text id="map15"
createdAt
```

Never overwrite with:

* syncedAt
* uploadedAt
* serverTimestamp

---

# Duplicate Protection

While saving:

* Disable Confirm button.
* Prevent repeated taps.
* Ignore duplicate requests.

---

# Error Handling

Examples:

```text id="map16"
Invalid Amount

Payment Exceeds Remaining

Unable to Save

Network Error
```

No financial data changes if validation fails.

---

# Loading State

During payment creation:

* Disable dialog inputs.
* Show loading indicator.
* Prevent duplicate submissions.

---

# Performance

Optimizations:

* Single transaction write.
* Incremental recalculation.
* Refresh only affected debt.
* Efficient Cubit state updates.
* Minimal widget rebuilds.

---

# Security

Only authenticated users with:

* Active Subscription
* Authorized Workspace
* Valid Permissions

may record payments.

---

# Business Rules

* Every payment creates a new Payment transaction.
* Remaining is always recalculated.
* Total Paid is always recalculated.
* Status is always recalculated.
* Reports refresh automatically.
* Dashboard refreshes automatically.
* Notification dialog appears after successful payment.
* Offline payments preserve createdAt.
* UI never performs financial calculations.

---

# Architecture

```text id="map17"
Add Payment Dialog

↓

MyDebtsCubit

↓

AddPaymentUseCase

↓

Repository

↓

Create Payment Transaction

↓

Financial Recalculation

↓

Reports Refresh

↓

Notification Dialog

↓

Updated UI
```

---

# End of Section

Next Section:

**6.8 Edit Payment**

This section documents the complete payment editing workflow for My Debts, including Slidable actions, edit dialog, validation rules, recalculation engine, notification behavior, synchronization, and all business rules governing payment modifications.
# PART 6 — My Debts

# 6.8 Edit Payment

## Overview

The **Edit Payment** feature allows users to correct an existing payment made toward a liability while maintaining complete financial consistency.

Every successful edit immediately updates all dependent financial values without requiring manual recalculation.

The payment history remains accurate and synchronized across all supported platforms.

---

# Objectives

The Edit Payment feature allows users to:

* Correct an incorrect payment amount.
* Update payment notes.
* Refresh financial calculations.
* Update reports automatically.
* Keep payment history accurate.

---

# Entry Point

Users edit payments from:

```text id="mep01"
My Debt Details

↓

Payment Timeline

↓

Swipe Right

↓

✏ Edit
```

Implemented using:

```text id="mep02"
flutter_slidable

↓

SlidableAction
```

---

# Supported Transactions

Editable:

* Payment Transactions

Not Editable:

* Debt Created
* Adjustment (Future)
* Reversal (Future)

---

# Protected Transaction

The initial:

```text id="mep03"
Debt Created
```

transaction is protected.

Current business rule:

It may only be edited when business validation explicitly allows it (for example, when it is the latest operation).

Otherwise:

The Edit action remains hidden.

---

# Edit Dialog

Tahsel reuses the same payment dialog.

Current implementation:

```text id="mep04"
MyPartialPaymentDialog
```

Fields:

* Paid Amount
* Notes

Future:

* Payment Method
* Receipt Number

---

# Validation

Before saving:

Validate:

* Amount entered.
* Numeric value.
* Greater than zero.
* Does not violate remaining balance rules.

Reject invalid edits.

---

# Edit Flow

```text id="mep05"
Swipe Right

↓

Edit

↓

Modify Amount

↓

Validate

↓

Update Payment

↓

Recalculate

↓

Refresh Reports

↓

Refresh UI

↓

Notification
```

---

# Financial Recalculation

Immediately after editing:

```text id="mep06"
Total Paid

=

Σ(All Payments)

----------------

Remaining

=

Original Debt

-

Total Paid
```

The user never edits Remaining manually.

---

# Example

Before edit:

```text id="mep07"
Debt

12,000

Paid

7,000

Remaining

5,000
```

Payment edited:

```text id="mep08"
2,000

↓

1,000
```

Automatically:

```text id="mep09"
Paid

6,000

Remaining

6,000
```

---

# Status Update

Possible transitions:

```text id="mep10"
Fully Paid

↓

Partially Paid
```

or

```text id="mep11"
Partially Paid

↓

Fully Paid
```

Debt status is always calculated.

---

# Timeline Refresh

Immediately update:

* Edited Payment
* Summary Card
* Remaining
* Paid
* Status

No manual refresh.

---

# Reports Update

Editing updates:

* Daily Reports
* Weekly Reports
* Monthly Reports
* Outstanding Liabilities
* Dashboard Statistics
* Financial Analytics

Reports always reflect the latest payment values.

---

# Notification Behavior

Unlike deletion,

editing a payment displays the Notification Dialog.

Supported methods:

* WhatsApp
* SMS
* None

---

# Notification Content

Include:

* Updated Payment Amount
* Updated Remaining Balance

Example:

```text id="mep12"
Updated Payment

1,500 EGP

Remaining

4,500 EGP
```

---

# Offline Support

Editing works offline.

Flow:

```text id="mep13"
Edit Payment

↓

Store Offline

↓

Offline Queue

↓

Synchronize Later
```

---

# Synchronization

Synchronization uploads:

* Updated Payment
* Updated Notes

Business timestamp:

```text id="mep14"
createdAt
```

remains unchanged.

---

# Duplicate Protection

While updating:

* Disable Save button.
* Ignore repeated taps.
* Prevent duplicate requests.

---

# Error Handling

Examples:

```text id="mep15"
Invalid Payment

Unable to Update

Network Error
```

The dialog remains open.

No financial values change until the update succeeds.

---

# Loading State

During update:

* Disable inputs.
* Show loading spinner.
* Prevent multiple submissions.

---

# Performance

Optimizations:

* Update only affected payment.
* Incremental recalculation.
* Refresh affected debt only.
* Efficient Cubit updates.
* Minimal widget rebuilds.

---

# Security

Only authenticated users with:

* Active Subscription
* Authorized Workspace
* Valid Permissions

may edit payments.

---

# Business Rules

* Only Payment transactions are editable.
* Debt Created transaction is protected.
* Remaining is recalculated after every edit.
* Total Paid is recalculated after every edit.
* Reports update automatically.
* Notification dialog appears after successful edits.
* Offline edits preserve createdAt.
* UI never performs financial calculations.
* Business rules determine whether protected transactions may be edited.

---

# Architecture

```text id="mep16"
Slidable Edit

↓

MyDebtsCubit

↓

EditPaymentUseCase

↓

Repository

↓

Update Payment

↓

Financial Recalculation

↓

Reports Refresh

↓

Notification Dialog

↓

Updated UI
```

---

# End of Section

Next Section:

**6.9 Delete Payment**

This section documents the complete payment deletion workflow for My Debts, including Slidable Delete actions, confirmation dialogs, remaining balance restoration, report synchronization, offline behavior, and all business rules governing payment deletion.
# PART 6 — My Debts

# 6.9 Delete Payment

## Overview

The **Delete Payment** feature allows users to remove an incorrectly recorded payment from a liability while maintaining complete financial consistency.

Deleting a payment immediately updates every dependent financial calculation throughout the application.

The payment is removed from the debt history (current implementation), and all reports are refreshed automatically.

---

# Objectives

The Delete Payment feature allows users to:

* Remove incorrect payment records.
* Restore the remaining liability.
* Keep reports synchronized.
* Preserve financial consistency.
* Refresh the debt timeline automatically.

---

# Entry Point

Users delete payments from:

```text id="mdp01"
My Debt Details

↓

Payment Timeline

↓

Swipe Left

↓

🗑 Delete
```

Implemented using:

```text id="mdp02"
flutter_slidable

↓

SlidableAction
```

---

# Supported Transactions

Delete is available only for:

* Payment Transactions

Protected:

* Debt Created
* Adjustment (Future)
* Reversal (Future)

---

# Protected Transaction

The initial:

```text id="mdp03"
Debt Created
```

transaction is protected.

Delete is unavailable unless business validation explicitly allows it.

---

# Confirmation Dialog

Before deleting:

Display:

```text id="mdp04"
Delete this payment?

This will update the remaining debt.

[Cancel]

[Delete]
```

Deletion always requires confirmation.

---

# Delete Flow

```text id="mdp05"
Swipe Left

↓

Delete

↓

Confirmation

↓

Delete Transaction

↓

Recalculate

↓

Refresh Reports

↓

Refresh UI
```

---

# Financial Recalculation

Immediately after deletion:

```text id="mdp06"
Total Paid

=

Σ(All Remaining Payments)

----------------

Remaining

=

Original Debt

-

Total Paid
```

Remaining is never edited manually.

---

# Example

Before deletion:

```text id="mdp07"
Debt

20,000

Paid

8,000

Remaining

12,000
```

Delete payment:

```text id="mdp08"
2,000
```

Automatically:

```text id="mdp09"
Paid

6,000

Remaining

14,000
```

---

# Delete Last Payment

Example:

```text id="mdp10"
Debt

5,000

↓

Payment

5,000
```

Delete payment.

Result:

```text id="mdp11"
Paid

0

Remaining

5,000

Status

Open
```

---

# Multiple Payments

Example:

```text id="mdp12"
Debt

15,000

↓

Payment

3,000

↓

Payment

2,000

↓

Payment

1,000
```

Delete:

```text id="mdp13"
2,000
```

Result:

```text id="mdp14"
Paid

4,000

Remaining

11,000
```

Everything updates automatically.

---

# Status Update

Deleting a payment may change:

```text id="mdp15"
Fully Paid

↓

Partially Paid
```

or

```text id="mdp16"
Partially Paid

↓

Open
```

Status is always calculated.

---

# Timeline Refresh

Immediately refresh:

* Timeline
* Summary Card
* Remaining
* Paid
* Status

No manual refresh required.

---

# Reports Update

Automatically refresh:

* Daily Reports
* Weekly Reports
* Monthly Reports
* Outstanding Liabilities
* Dashboard Statistics
* Financial Analytics

Deleted payments disappear from every report.

---

# Notification Behavior

Deleting a payment **never** sends:

* WhatsApp
* SMS

No notification dialog appears.

---

# Offline Support

Deletion works offline.

Flow:

```text id="mdp17"
Delete

↓

Offline Queue

↓

Local Recalculation

↓

Synchronize Later
```

Users see the updated balance immediately.

---

# Synchronization

Synchronization uploads:

* Delete Operation

Business timestamp:

```text id="mdp18"
createdAt
```

is preserved.

Never overwrite with:

* syncedAt
* uploadedAt
* serverTimestamp

---

# Duplicate Protection

During deletion:

* Disable Delete button.
* Prevent repeated taps.
* Ignore duplicate delete requests.

---

# Error Handling

Examples:

```text id="mdp19"
Unable to Delete

Network Error

Try Again
```

The payment remains unchanged if deletion fails.

---

# Loading State

While deleting:

* Disable dialog buttons.
* Show loading spinner.
* Prevent duplicate operations.

---

# Performance

Optimizations:

* Delete only one transaction.
* Refresh only affected debt.
* Incremental financial recalculation.
* Minimal Cubit rebuilds.
* Efficient report refresh.

---

# Future Ledger Mode

Current implementation:

```text id="mdp20"
Delete

↓

Remove Payment
```

Future implementation:

```text id="mdp21"
Delete

↓

Create Reversal Transaction

↓

Original Payment Remains

↓

Net Payment = 0
```

This preserves a complete audit trail.

---

# Security

Only authenticated users with:

* Active Subscription
* Authorized Workspace
* Valid Permissions

may delete payments.

---

# Business Rules

* Only Payment transactions can be deleted.
* Debt Created transaction is protected.
* Remaining is recalculated after deletion.
* Total Paid is recalculated after deletion.
* Reports refresh automatically.
* Dashboard refreshes automatically.
* Delete operations never trigger notifications.
* Offline deletion preserves createdAt.
* UI never performs financial calculations.
* Future Ledger mode replaces deletion with reversal transactions.

---

# Architecture

```text id="mdp22"
Slidable Delete

↓

MyDebtsCubit

↓

DeletePaymentUseCase

↓

Repository

↓

Delete Payment

↓

Financial Recalculation

↓

Reports Refresh

↓

Updated UI
```

---

# End of Section

Next Section:

**6.10 Payment Notifications**

This section documents the complete notification engine for **My Debts**, including WhatsApp, SMS, None, localized message generation, notification dialog workflow, retry behavior, offline considerations, and all business rules governing payment notifications.
# PART 6 — My Debts

# 6.10 Payment Notifications

## Overview

The **Payment Notification System** for My Debts informs creditors whenever a payment has been successfully recorded.

Although the notification engine is shared with the Customer Debts module, the message content differs because the payment direction is reversed.

In Customer Debts:

> The customer pays **you**.

In My Debts:

> **You** pay the creditor.

---

# Objectives

The notification system allows users to:

* Inform creditors of successful payments.
* Confirm transferred amounts.
* Display remaining liability.
* Support multiple communication methods.
* Keep communication optional.

---

# Supported Notification Methods

Tahsel currently supports:

```text id="mpn01"
WhatsApp

SMS

None
```

The user chooses the preferred communication channel after every successful payment.

---

# Notification Trigger

The notification dialog appears only after:

* Partial Payment
* Full Payment
* Edit Payment

It does **not** appear after:

* Delete Payment
* Delete Debt
* Create Debt
* Reports
* Synchronization

---

# Notification Flow

```text id="mpn02"
Payment Saved

↓

Financial Recalculation

↓

Refresh UI

↓

Notification Dialog

↓

User Selects Method

↓

Send (Optional)
```

---

# Notification Dialog

Immediately after a successful payment:

Display:

```text id="mpn03"
Notify Creditor?

○ WhatsApp

○ SMS

○ None

[Confirm]
```

The dialog uses:

* AppColors
* TextStyles
* Dark Mode
* Light Mode

---

# WhatsApp Notification

Selecting:

```text id="mpn04"
WhatsApp
```

launches WhatsApp with a pre-generated message.

The user reviews the message before sending.

---

# WhatsApp Validation

Before opening WhatsApp:

Validate:

* Phone number exists.
* Phone number format is valid.
* WhatsApp is installed.

If validation fails:

Display:

```text id="mpn05"
Unable to open WhatsApp.
```

---

# WhatsApp Message

The generated message includes:

* Creditor Name
* Paid Amount
* Remaining Liability

Example:

```text id="mpn06"
Hello,

A payment of

2,500 EGP

has been paid toward your outstanding balance.

Remaining amount:

7,500 EGP.

Thank you.
```

The message is fully localized.

---

# SMS Notification

Selecting:

```text id="mpn07"
SMS
```

opens the device SMS application.

The payment message is generated automatically.

---

# SMS Content

Contains:

* Paid Amount
* Remaining Balance

No internal identifiers are included.

---

# None Option

Selecting:

```text id="mpn08"
None
```

Closes the dialog.

The payment remains successfully recorded.

No communication occurs.

---

# Localization

Notifications support:

* Arabic
* English

The generated message always follows the application's active language.

---

# Dynamic Financial Data

The notification is generated **after** recalculation.

Included values:

* Creditor Name
* Payment Amount
* Remaining Balance

No cached values are used.

---

# Financial Accuracy

Generation order:

```text id="mpn09"
Save Payment

↓

Recalculate

↓

Generate Message

↓

Open Communication App
```

This guarantees that every notification contains accurate financial information.

---

# Edit Payment Notifications

Editing a payment displays the notification dialog again.

Updated values include:

* Updated Paid Amount
* Updated Remaining Balance

---

# Delete Payment Notifications

Deleting a payment never displays:

* WhatsApp
* SMS

No creditor notification is generated.

---

# Offline Behavior

If payment is recorded offline:

The payment succeeds locally.

External notifications are **not** sent until network connectivity is available.

Tahsel does not automatically retry sending notifications.

---

# Retry Behavior

If sending fails:

The payment remains successful.

Users may manually send another notification later.

No automatic retry mechanism exists.

---

# Privacy

Messages never contain:

* Firebase IDs
* Internal Database IDs
* Authentication Tokens
* Technical Metadata

Only business-related financial information is included.

---

# Security

Only authenticated users with:

* Active Subscription
* Authorized Workspace

may trigger payment notifications.

---

# Performance

Optimizations:

* Generate messages only when requested.
* No unnecessary background work.
* No repeated calculations.
* No duplicate notifications.

---

# Business Rules

* Notifications appear only after successful payment operations.
* Supported methods are WhatsApp, SMS, and None.
* Messages always use recalculated financial values.
* Delete Payment never triggers notifications.
* Offline payments do not automatically send notifications.
* Notification failures never affect payment success.
* Localization follows the current application language.
* Sensitive technical information is never included.

---

# Architecture

```text id="mpn10"
Payment Saved

↓

Financial Engine

↓

Notification Dialog

↓

Selected Method

↓

WhatsApp / SMS / None

↓

External Application
```

---

# End of Section

Next Section:

**6.11 Remaining Balance Calculation**

This section documents the financial calculation engine used by the **My Debts** module, including Total Paid, Remaining Balance, debt status derivation, ledger compatibility, validation rules, report integration, and all business formulas that ensure financial consistency.
# PART 6 — My Debts

# 6.10 Payment Notifications

## Overview

The **Payment Notification System** for My Debts informs creditors whenever a payment has been successfully recorded.

Although the notification engine is shared with the Customer Debts module, the message content differs because the payment direction is reversed.

In Customer Debts:

> The customer pays **you**.

In My Debts:

> **You** pay the creditor.

---

# Objectives

The notification system allows users to:

* Inform creditors of successful payments.
* Confirm transferred amounts.
* Display remaining liability.
* Support multiple communication methods.
* Keep communication optional.

---

# Supported Notification Methods

Tahsel currently supports:

```text id="mpn01"
WhatsApp

SMS

None
```

The user chooses the preferred communication channel after every successful payment.

---

# Notification Trigger

The notification dialog appears only after:

* Partial Payment
* Full Payment
* Edit Payment

It does **not** appear after:

* Delete Payment
* Delete Debt
* Create Debt
* Reports
* Synchronization

---

# Notification Flow

```text id="mpn02"
Payment Saved

↓

Financial Recalculation

↓

Refresh UI

↓

Notification Dialog

↓

User Selects Method

↓

Send (Optional)
```

---

# Notification Dialog

Immediately after a successful payment:

Display:

```text id="mpn03"
Notify Creditor?

○ WhatsApp

○ SMS

○ None

[Confirm]
```

The dialog uses:

* AppColors
* TextStyles
* Dark Mode
* Light Mode

---

# WhatsApp Notification

Selecting:

```text id="mpn04"
WhatsApp
```

launches WhatsApp with a pre-generated message.

The user reviews the message before sending.

---

# WhatsApp Validation

Before opening WhatsApp:

Validate:

* Phone number exists.
* Phone number format is valid.
* WhatsApp is installed.

If validation fails:

Display:

```text id="mpn05"
Unable to open WhatsApp.
```

---

# WhatsApp Message

The generated message includes:

* Creditor Name
* Paid Amount
* Remaining Liability

Example:

```text id="mpn06"
Hello,

A payment of

2,500 EGP

has been paid toward your outstanding balance.

Remaining amount:

7,500 EGP.

Thank you.
```

The message is fully localized.

---

# SMS Notification

Selecting:

```text id="mpn07"
SMS
```

opens the device SMS application.

The payment message is generated automatically.

---

# SMS Content

Contains:

* Paid Amount
* Remaining Balance

No internal identifiers are included.

---

# None Option

Selecting:

```text id="mpn08"
None
```

Closes the dialog.

The payment remains successfully recorded.

No communication occurs.

---

# Localization

Notifications support:

* Arabic
* English

The generated message always follows the application's active language.

---

# Dynamic Financial Data

The notification is generated **after** recalculation.

Included values:

* Creditor Name
* Payment Amount
* Remaining Balance

No cached values are used.

---

# Financial Accuracy

Generation order:

```text id="mpn09"
Save Payment

↓

Recalculate

↓

Generate Message

↓

Open Communication App
```

This guarantees that every notification contains accurate financial information.

---

# Edit Payment Notifications

Editing a payment displays the notification dialog again.

Updated values include:

* Updated Paid Amount
* Updated Remaining Balance

---

# Delete Payment Notifications

Deleting a payment never displays:

* WhatsApp
* SMS

No creditor notification is generated.

---

# Offline Behavior

If payment is recorded offline:

The payment succeeds locally.

External notifications are **not** sent until network connectivity is available.

Tahsel does not automatically retry sending notifications.

---

# Retry Behavior

If sending fails:

The payment remains successful.

Users may manually send another notification later.

No automatic retry mechanism exists.

---

# Privacy

Messages never contain:

* Firebase IDs
* Internal Database IDs
* Authentication Tokens
* Technical Metadata

Only business-related financial information is included.

---

# Security

Only authenticated users with:

* Active Subscription
* Authorized Workspace

may trigger payment notifications.

---

# Performance

Optimizations:

* Generate messages only when requested.
* No unnecessary background work.
* No repeated calculations.
* No duplicate notifications.

---

# Business Rules

* Notifications appear only after successful payment operations.
* Supported methods are WhatsApp, SMS, and None.
* Messages always use recalculated financial values.
* Delete Payment never triggers notifications.
* Offline payments do not automatically send notifications.
* Notification failures never affect payment success.
* Localization follows the current application language.
* Sensitive technical information is never included.

---

# Architecture

```text id="mpn10"
Payment Saved

↓

Financial Engine

↓

Notification Dialog

↓

Selected Method

↓

WhatsApp / SMS / None

↓

External Application
```

---

# End of Section

Next Section:

**6.11 Remaining Balance Calculation**

This section documents the financial calculation engine used by the **My Debts** module, including Total Paid, Remaining Balance, debt status derivation, ledger compatibility, validation rules, report integration, and all business formulas that ensure financial consistency.
# PART 6 — My Debts

# 6.11 Remaining Balance Calculation

## Overview

The **Remaining Balance Calculation Engine** used in the My Debts module is identical to the engine used in Customer Debts.

The only difference is the business perspective:

* Customer Debts → Customers owe money to the business.
* My Debts → The business owes money to others.

Because both modules share the same financial engine, calculations remain consistent across the entire application.

---

# Financial Philosophy

Tahsel follows one fundamental accounting principle:

> **Financial values are never stored as the source of truth. They are always derived from transaction history.**

This guarantees:

* Accurate balances
* Reliable reports
* Offline consistency
* Synchronization safety
* Future ledger compatibility

---

# Source of Truth

The only trusted financial source is:

```text id="mrc01"
Transaction History
```

Never calculate from:

```text id="mrc02"
remainingBalance

paidAmount

cachedValues

summaryCards
```

These are derived values only.

---

# Original Debt

The original liability is recorded once during debt creation.

Example:

```text id="mrc03"
Supplier Debt

50,000 EGP
```

The original debt represents the maximum amount owed before any payments.

---

# Total Paid Formula

Formula:

```text id="mrc04"
Total Paid

=

Σ(All Payment Transactions)
```

Example:

```text id="mrc05"
Payment

10,000

+

Payment

5,000

+

Payment

3,000

=

18,000
```

---

# Remaining Formula

Formula:

```text id="mrc06"
Remaining

=

Original Debt

-

Total Paid
```

Example:

```text id="mrc07"
Original Debt

50,000

Paid

18,000

Remaining

32,000
```

---

# Future Ledger Formula

When Ledger mode becomes the default:

Formula changes to:

```text id="mrc08"
Net Paid

=

Σ(All Financial Transactions)
```

Including:

* Payment
* Adjustment
* Reversal

Example:

```text id="mrc09"
Payment

5000

+

Adjustment

-1000

+

Payment

3000

=

7000
```

---

# Debt Status Formula

Status is never stored.

It is derived.

Rules:

```text id="mrc10"
Remaining

=

Original Debt

↓

Open
```

---

```text id="mrc11"
Remaining

>

0

↓

Partially Paid
```

---

```text id="mrc12"
Remaining

=

0

↓

Fully Paid
```

---

# Example 1

New debt:

```text id="mrc13"
Debt

20,000

↓

No Payments
```

Results:

Paid:

0

Remaining:

20,000

Status:

Open

---

# Example 2

Partial payment:

```text id="mrc14"
Debt

20,000

↓

Payment

5,000
```

Results:

Paid:

5,000

Remaining:

15,000

Status:

Partially Paid

---

# Example 3

Full payment:

```text id="mrc15"
Debt

20,000

↓

Payment

20,000
```

Results:

Paid:

20,000

Remaining:

0

Status:

Fully Paid

---

# Example 4

Multiple payments:

```text id="mrc16"
Debt

30,000

↓

10,000

↓

7,000

↓

3,000
```

Results:

Paid:

20,000

Remaining:

10,000

---

# Example 5

Future Ledger Adjustment:

```text id="mrc17"
Debt

30,000

↓

Payment

15,000

↓

Adjustment

-2,000
```

Net Paid:

13,000

Remaining:

17,000

---

# Recalculation Events

Financial recalculation occurs after:

* Create Debt
* Edit Debt
* Delete Debt
* Add Payment
* Edit Payment
* Delete Payment
* Synchronization

No manual recalculation exists.

---

# Summary Card Dependency

The Summary Card displays:

* Original Debt
* Total Paid
* Remaining
* Status

Every displayed value comes directly from the calculation engine.

---

# Reports Dependency

The following reports consume Remaining Balance:

* Daily Reports
* Weekly Reports
* Monthly Reports
* Outstanding Liabilities
* Dashboard Statistics
* Financial Analytics

Reports never calculate independently.

---

# Timeline Dependency

The payment timeline itself does not store balances.

Balances are calculated separately from:

```text id="mrc18"
Transaction History
```

---

# Offline Calculation

Offline mode performs exactly the same calculations.

No alternative formulas exist.

Synchronization never changes financial values.

---

# Timestamp Rule

Financial calculations use:

```text id="mrc19"
createdAt
```

Never:

```text id="mrc20"
syncedAt

uploadedAt

serverTimestamp
```

Business calculations depend only on business timestamps.

---

# Validation Rules

The Remaining Balance must never become:

```text id="mrc21"
Negative
```

Attempting to overpay a debt results in validation failure.

---

# Currency Precision

Financial calculations must:

* Preserve decimal precision.
* Avoid floating-point rounding issues.
* Use the application's standard currency formatter.

---

# Error Recovery

If an invalid payment is detected:

* Reject the operation.
* Preserve previous balances.
* Display validation message.

The calculation engine never enters an inconsistent state.

---

# Performance

Optimizations:

* Recalculate only affected debts.
* Refresh only dependent widgets.
* Cache transaction collections.
* Never cache Remaining values.

---

# Business Rules

* Remaining is always derived.
* Total Paid is always derived.
* Debt Status is always derived.
* Transactions are the only source of truth.
* Financial summaries are never manually updated.
* Reports always consume calculated values.
* Offline calculations follow identical formulas.
* createdAt defines financial chronology.
* Negative remaining balances are prohibited.
* Future Ledger mode remains compatible with the same calculation engine.

---

# Architecture

```text id="mrc22"
Transactions

↓

Financial Calculation Engine

↓

Total Paid

↓

Remaining

↓

Debt Status

↓

Summary Card

↓

Reports

↓

Dashboard

↓

Analytics
```

---

# End of Section

Next Section:

**6.12 My Debts Reports**

This section documents all reporting capabilities of the **My Debts** module, including Daily, Weekly, Monthly, Outstanding Liability Reports, Dashboard integration, report grouping rules, `createdAt` behavior, filtering, aggregation, and synchronization consistency.
# PART 6 — My Debts

# 6.12 My Debts Reports

## Overview

The **My Debts Reports** module provides a complete financial overview of all liabilities owed by the business.

Unlike the Customer Debts reports, which analyze incoming collections, My Debts Reports focus on:

* Money paid by the business.
* Outstanding liabilities.
* Payment trends.
* Creditor analysis.
* Business obligations.

Every report is generated dynamically from transaction history.

No financial report stores calculated values.

---

# Objectives

The reporting engine allows users to:

* Analyze liabilities.
* Monitor outgoing payments.
* Track remaining obligations.
* Compare payment periods.
* Support financial decision making.

---

# Report Categories

The My Debts module contributes to:

* Daily Reports
* Weekly Reports
* Monthly Reports
* Outstanding Liabilities Report
* Creditor Reports
* Dashboard Statistics
* Financial Analytics

Future:

* Quarterly Reports
* Yearly Reports
* Category Reports
* Supplier Performance Reports

---

# Daily Report

Displays:

* New debts created today.
* Payments made today.
* Outstanding balance.
* Number of active liabilities.
* Fully paid liabilities.

Grouping:

```text id="mdr01"
createdAt

↓

Day
```

---

# Weekly Report

Displays:

* Weekly outgoing payments.
* New liabilities.
* Remaining obligations.
* Creditor activity.

Grouping:

```text id="mdr02"
createdAt

↓

Week
```

---

# Monthly Report

Displays:

* Monthly payments.
* Total liabilities created.
* Remaining balance.
* Fully paid liabilities.
* Outstanding liabilities.

Grouping:

```text id="mdr03"
createdAt

↓

Month + Year
```

---

# Outstanding Liabilities Report

Displays only liabilities that still have money remaining.

Each item contains:

* Creditor Name
* Original Debt
* Total Paid
* Remaining
* Status

Sorting:

Highest Remaining first.

---

# Creditor Report

Each creditor report includes:

* Number of debts.
* Original total.
* Total paid.
* Remaining.
* Last payment.
* Current status.

Useful for supplier relationship management.

---

# Dashboard Statistics

Dashboard receives:

* Total My Debts.
* Total Paid.
* Remaining Liabilities.
* Active Debts.
* Fully Paid Debts.

Every statistic comes from the financial engine.

---

# Financial Analytics

Analytics include:

* Monthly payment trends.
* Liability growth.
* Average payment size.
* Outstanding balance trend.

Future:

* Cash Flow Forecast.
* Expense Forecast.
* Debt Aging Analysis.

---

# Report Refresh

Reports automatically refresh after:

* Create Debt
* Edit Debt
* Delete Debt
* Add Payment
* Edit Payment
* Delete Payment
* Offline Synchronization

Users never manually update reports.

---

# Report Source

Reports always calculate from:

```text id="mdr04"
Transaction History
```

Never from:

* Summary Cards
* Cached Totals
* Remaining Fields
* Paid Fields

---

# Timestamp Rule

Business reports always use:

```text id="mdr05"
createdAt
```

Never:

```text id="mdr06"
syncedAt

uploadedAt

serverTimestamp
```

Historical reports always reflect the real operation date.

---

# Historical Accuracy

Example:

Payment created:

```text id="mdr07"
8 June
```

Uploaded:

```text id="mdr08"
11 June
```

Appears inside:

```text id="mdr09"
8 June Report
```

because reports always use:

```text id="mdr10"
createdAt
```

---

# Offline Integration

Offline-created liabilities immediately appear in reports.

Synchronization uploads data only.

Historical report dates never change.

---

# Report Filtering

Current filters:

* Date Range
* Creditor
* Status

Future:

* Category
* Amount Range
* Payment Method

---

# Report Sorting

Supported sorting:

* Newest First
* Oldest First
* Highest Remaining
* Largest Debt

Future:

* Highest Paid
* Last Activity
* Alphabetical

---

# Empty Reports

If no data exists:

Display:

```text id="mdr11"
No Data Available
```

Localized using ARB.

---

# Performance

Optimizations:

* Incremental report refresh.
* Lazy loading.
* Cached transaction queries.
* Derived calculations only.
* Efficient Cubit updates.

Supports:

* Thousands of debts.
* Tens of thousands of payments.
* Multi-year reporting.

---

# Synchronization

Synchronization updates reports automatically.

No duplicate records.

No duplicated totals.

Business dates remain unchanged.

---

# Security

Reports require:

* Authenticated account.
* Active subscription.
* Authorized workspace.

Future role-based visibility:

* Owner
* Manager
* Accountant
* Employee

---

# Localization

Reports fully support:

* Arabic
* English

Using ARB localization.

No hardcoded strings.

---

# Business Rules

* Reports always calculate from transactions.
* Reports never store financial totals.
* createdAt is the only business timestamp.
* Offline reports behave identically.
* Synchronization never changes report dates.
* Dashboard consumes the same report engine.
* Outstanding balances are always recalculated.
* Report refresh is automatic.
* Financial consistency has priority over rendering speed.

---

# Architecture

```text id="mdr12"
Transactions

↓

Financial Engine

↓

Report Engine

↓

Daily

Weekly

Monthly

Outstanding

Creditor

Dashboard

↓

Updated UI
```

---

# End of Section

Next Section:

**6.13 Business Rules & Edge Cases**

This section documents every business rule, validation, financial constraint, exceptional scenario, synchronization case, offline behavior, ledger compatibility, and edge case specific to the **My Debts** module, ensuring complete financial integrity across the entire system.
# PART 6 — My Debts

# 6.13 Business Rules & Edge Cases

## Overview

This section defines the official business rules governing the **My Debts** module.

These rules guarantee:

* Financial integrity
* Data consistency
* Offline reliability
* Synchronization safety
* Report accuracy

Every operation performed inside My Debts must comply with these rules.

---

# Source of Truth

The single financial source of truth is:

```text id="mbr01"
Transaction History
```

Everything else is derived.

Never trust:

* Remaining field
* Paid field
* Dashboard values
* Summary cards
* Cached balances

---

# Financial Formula

The official formula is:

```text id="mbr02"
Total Paid

=

Σ(All Payment Transactions)
```

```text id="mbr03"
Remaining

=

Original Debt

-

Total Paid
```

No alternative formulas exist.

---

# Debt Creation Rules

Creating a debt automatically:

* Creates Debt Created transaction.
* Sets Paid = 0.
* Sets Remaining = Original Amount.
* Sets Status = Open.

No payment transaction exists initially.

---

# Payment Rules

Every payment:

* Creates a new transaction.
* Updates reports.
* Updates dashboard.
* Recalculates remaining.
* Recalculates status.

Payments never overwrite previous payments.

---

# Edit Payment Rules

Editing a payment:

* Updates that payment only (current implementation).
* Recalculates Total Paid.
* Recalculates Remaining.
* Recalculates Status.

Future Ledger implementation:

Creates an Adjustment transaction instead of modifying the original payment.

---

# Delete Payment Rules

Current implementation:

Deletes the selected payment transaction.

Then:

* Recalculates Paid.
* Recalculates Remaining.
* Updates reports.

Future Ledger implementation:

Creates a Reversal transaction.

Original payment remains preserved.

---

# Remaining Balance Rules

Remaining must always satisfy:

```text id="mbr04"
Remaining

≥

0
```

Negative balances are never allowed.

---

# Payment Limit

Users cannot pay:

```text id="mbr05"
More

>

Remaining
```

Validation rejects the operation.

---

# Zero Payment Rule

Payments equal to:

```text id="mbr06"
0
```

are invalid.

They cannot be saved.

---

# Negative Payment Rule

Negative payment values are prohibited.

Example:

```text id="mbr07"
-500
```

Validation fails immediately.

---

# Status Rules

Debt Status is always derived.

Rules:

Remaining == Original Debt

↓

Open

---

Remaining > 0

↓

Partially Paid

---

Remaining == 0

↓

Fully Paid

No manual status updates exist.

---

# Timeline Rules

Timeline ordering always uses:

```text id="mbr08"
createdAt
```

Never:

* syncedAt
* uploadedAt
* serverTimestamp

---

# Offline Rules

Offline mode supports:

* Create Debt
* Edit Debt
* Delete Debt
* Add Payment
* Edit Payment
* Delete Payment

Behavior matches online mode.

---

# Synchronization Rules

Synchronization:

Uploads business data only.

Must never modify:

```text id="mbr09"
createdAt
```

Business chronology remains unchanged.

---

# Report Rules

Reports always:

* Calculate dynamically.
* Refresh automatically.
* Use transaction history.
* Ignore cached balances.

---

# Dashboard Rules

Dashboard statistics:

* Never maintain separate calculations.
* Consume Financial Engine output.
* Update after every successful operation.

---

# Notification Rules

Notifications appear only after:

* Add Payment
* Edit Payment

Never after:

* Delete Payment
* Create Debt
* Delete Debt

---

# Permission Rules

Users must have:

* Active account.
* Active subscription.
* Authorized workspace.

Otherwise:

Operations are blocked.

---

# Duplicate Request Protection

Tahsel ignores:

* Double taps.
* Rapid repeated requests.
* Duplicate save operations.

Only one operation executes.

---

# Validation Rules

Before every financial operation:

Validate:

* Required fields.
* Numeric values.
* Business constraints.
* Remaining balance.
* User permissions.

---

# Error Recovery

If an operation fails:

* Previous financial state remains unchanged.
* Reports remain unchanged.
* Dashboard remains unchanged.
* User receives localized error.

---

# Data Integrity Rules

Every financial operation must guarantee:

* No duplicate transactions.
* No orphaned payments.
* No inconsistent reports.
* No incorrect remaining balances.

---

# Ledger Compatibility

Current system:

```text id="mbr10"
Mutation
```

Future system:

```text id="mbr11"
Ledger
```

The calculation engine already supports both approaches.

Future migration will not require report changes.

---

# Edge Case 1

New debt.

No payments.

Result:

```text id="mbr12"
Paid

0

Remaining

Original Amount

Status

Open
```

---

# Edge Case 2

Single payment equals debt.

Result:

```text id="mbr13"
Remaining

0

Status

Fully Paid
```

---

# Edge Case 3

Delete last payment.

Result:

```text id="mbr14"
Paid

0

Remaining

Original Amount

Status

Open
```

---

# Edge Case 4

Multiple partial payments.

Delete middle payment.

Remaining automatically recalculates.

---

# Edge Case 5

Edit payment from:

```text id="mbr15"
5,000

↓

2,000
```

Remaining increases automatically.

---

# Edge Case 6

Attempt payment larger than remaining.

Operation rejected.

Financial state unchanged.

---

# Edge Case 7

Offline payment.

Reports update locally.

Synchronization uploads later.

History remains correct.

---

# Edge Case 8

Offline debt creation.

Appears in reports immediately.

After synchronization:

Business date remains:

```text id="mbr16"
createdAt
```

---

# Edge Case 9

Network interruption during payment.

Transaction is not duplicated.

Queue resumes after connectivity returns.

---

# Edge Case 10

Two rapid payment requests.

Only one succeeds.

Duplicate ignored.

---

# Performance Rules

* Avoid unnecessary rebuilds.
* Refresh only affected debts.
* Use debounce for search.
* Use lazy list rendering.
* Recalculate incrementally.

---

# Security Rules

Financial operations require:

* Authentication.
* Active subscription.
* Valid account status.
* Workspace authorization.

No cached session bypasses these validations.

---

# Business Rules Summary

* Transactions are the only financial source of truth.
* Remaining is always derived.
* Paid is always derived.
* Status is always derived.
* Reports are always recalculated.
* Dashboard uses Financial Engine results.
* createdAt defines business chronology.
* Offline mode behaves identically to online mode.
* Synchronization never changes business timestamps.
* Financial integrity always has higher priority than UI convenience.

---

# Architecture

```text id="mbr17"
User Action

↓

Validation

↓

UseCase

↓

Repository

↓

Transaction Update

↓

Financial Engine

↓

Reports

↓

Dashboard

↓

Updated UI
```

---

# End of PART 6 — My Debts

The **My Debts** module documentation is now complete.

**Next Part:**

# **PART 7 — Expenses**

This section will comprehensively document the Expenses module, including expense categories, creation, editing, deletion, reports, analytics, offline mode, synchronization, business rules, edge cases, and architecture.
# PART 6 — My Debts

# 6.13 Business Rules & Edge Cases

## Overview

This section defines the official business rules governing the **My Debts** module.

These rules guarantee:

* Financial integrity
* Data consistency
* Offline reliability
* Synchronization safety
* Report accuracy

Every operation performed inside My Debts must comply with these rules.

---

# Source of Truth

The single financial source of truth is:

```text id="mbr01"
Transaction History
```

Everything else is derived.

Never trust:

* Remaining field
* Paid field
* Dashboard values
* Summary cards
* Cached balances

---

# Financial Formula

The official formula is:

```text id="mbr02"
Total Paid

=

Σ(All Payment Transactions)
```

```text id="mbr03"
Remaining

=

Original Debt

-

Total Paid
```

No alternative formulas exist.

---

# Debt Creation Rules

Creating a debt automatically:

* Creates Debt Created transaction.
* Sets Paid = 0.
* Sets Remaining = Original Amount.
* Sets Status = Open.

No payment transaction exists initially.

---

# Payment Rules

Every payment:

* Creates a new transaction.
* Updates reports.
* Updates dashboard.
* Recalculates remaining.
* Recalculates status.

Payments never overwrite previous payments.

---

# Edit Payment Rules

Editing a payment:

* Updates that payment only (current implementation).
* Recalculates Total Paid.
* Recalculates Remaining.
* Recalculates Status.

Future Ledger implementation:

Creates an Adjustment transaction instead of modifying the original payment.

---

# Delete Payment Rules

Current implementation:

Deletes the selected payment transaction.

Then:

* Recalculates Paid.
* Recalculates Remaining.
* Updates reports.

Future Ledger implementation:

Creates a Reversal transaction.

Original payment remains preserved.

---

# Remaining Balance Rules

Remaining must always satisfy:

```text id="mbr04"
Remaining

≥

0
```

Negative balances are never allowed.

---

# Payment Limit

Users cannot pay:

```text id="mbr05"
More

>

Remaining
```

Validation rejects the operation.

---

# Zero Payment Rule

Payments equal to:

```text id="mbr06"
0
```

are invalid.

They cannot be saved.

---

# Negative Payment Rule

Negative payment values are prohibited.

Example:

```text id="mbr07"
-500
```

Validation fails immediately.

---

# Status Rules

Debt Status is always derived.

Rules:

Remaining == Original Debt

↓

Open

---

Remaining > 0

↓

Partially Paid

---

Remaining == 0

↓

Fully Paid

No manual status updates exist.

---

# Timeline Rules

Timeline ordering always uses:

```text id="mbr08"
createdAt
```

Never:

* syncedAt
* uploadedAt
* serverTimestamp

---

# Offline Rules

Offline mode supports:

* Create Debt
* Edit Debt
* Delete Debt
* Add Payment
* Edit Payment
* Delete Payment

Behavior matches online mode.

---

# Synchronization Rules

Synchronization:

Uploads business data only.

Must never modify:

```text id="mbr09"
createdAt
```

Business chronology remains unchanged.

---

# Report Rules

Reports always:

* Calculate dynamically.
* Refresh automatically.
* Use transaction history.
* Ignore cached balances.

---

# Dashboard Rules

Dashboard statistics:

* Never maintain separate calculations.
* Consume Financial Engine output.
* Update after every successful operation.

---

# Notification Rules

Notifications appear only after:

* Add Payment
* Edit Payment

Never after:

* Delete Payment
* Create Debt
* Delete Debt

---

# Permission Rules

Users must have:

* Active account.
* Active subscription.
* Authorized workspace.

Otherwise:

Operations are blocked.

---

# Duplicate Request Protection

Tahsel ignores:

* Double taps.
* Rapid repeated requests.
* Duplicate save operations.

Only one operation executes.

---

# Validation Rules

Before every financial operation:

Validate:

* Required fields.
* Numeric values.
* Business constraints.
* Remaining balance.
* User permissions.

---

# Error Recovery

If an operation fails:

* Previous financial state remains unchanged.
* Reports remain unchanged.
* Dashboard remains unchanged.
* User receives localized error.

---

# Data Integrity Rules

Every financial operation must guarantee:

* No duplicate transactions.
* No orphaned payments.
* No inconsistent reports.
* No incorrect remaining balances.

---

# Ledger Compatibility

Current system:

```text id="mbr10"
Mutation
```

Future system:

```text id="mbr11"
Ledger
```

The calculation engine already supports both approaches.

Future migration will not require report changes.

---

# Edge Case 1

New debt.

No payments.

Result:

```text id="mbr12"
Paid

0

Remaining

Original Amount

Status

Open
```

---

# Edge Case 2

Single payment equals debt.

Result:

```text id="mbr13"
Remaining

0

Status

Fully Paid
```

---

# Edge Case 3

Delete last payment.

Result:

```text id="mbr14"
Paid

0

Remaining

Original Amount

Status

Open
```

---

# Edge Case 4

Multiple partial payments.

Delete middle payment.

Remaining automatically recalculates.

---

# Edge Case 5

Edit payment from:

```text id="mbr15"
5,000

↓

2,000
```

Remaining increases automatically.

---

# Edge Case 6

Attempt payment larger than remaining.

Operation rejected.

Financial state unchanged.

---

# Edge Case 7

Offline payment.

Reports update locally.

Synchronization uploads later.

History remains correct.

---

# Edge Case 8

Offline debt creation.

Appears in reports immediately.

After synchronization:

Business date remains:

```text id="mbr16"
createdAt
```

---

# Edge Case 9

Network interruption during payment.

Transaction is not duplicated.

Queue resumes after connectivity returns.

---

# Edge Case 10

Two rapid payment requests.

Only one succeeds.

Duplicate ignored.

---

# Performance Rules

* Avoid unnecessary rebuilds.
* Refresh only affected debts.
* Use debounce for search.
* Use lazy list rendering.
* Recalculate incrementally.

---

# Security Rules

Financial operations require:

* Authentication.
* Active subscription.
* Valid account status.
* Workspace authorization.

No cached session bypasses these validations.

---

# Business Rules Summary

* Transactions are the only financial source of truth.
* Remaining is always derived.
* Paid is always derived.
* Status is always derived.
* Reports are always recalculated.
* Dashboard uses Financial Engine results.
* createdAt defines business chronology.
* Offline mode behaves identically to online mode.
* Synchronization never changes business timestamps.
* Financial integrity always has higher priority than UI convenience.

---

# Architecture

```text id="mbr17"
User Action

↓

Validation

↓

UseCase

↓

Repository

↓

Transaction Update

↓

Financial Engine

↓

Reports

↓

Dashboard

↓

Updated UI
```

---

# End of PART 6 — My Debts

The **My Debts** module documentation is now complete.

**Next Part:**

# **PART 7 — Expenses**

This section will comprehensively document the Expenses module, including expense categories, creation, editing, deletion, reports, analytics, offline mode, synchronization, business rules, edge cases, and architecture.
# PART 7 — Expenses

# 7.1 Overview

## Introduction

The **Expenses** module manages every outgoing financial transaction made by the business that is **not** considered a debt payment.

It is one of the core financial modules inside Tahsel and directly affects:

* Financial Reports
* Dashboard Statistics
* Profit Analysis
* Cash Flow
* Business Analytics

Unlike **My Debts**, expenses represent immediate business costs rather than future financial obligations.

---

# Purpose

The Expenses module helps business owners:

* Record daily expenses.
* Monitor operating costs.
* Analyze spending patterns.
* Reduce unnecessary expenses.
* Improve profitability.

---

# Examples of Expenses

Typical expenses include:

* Electricity
* Water
* Internet
* Salaries
* Rent
* Transportation
* Maintenance
* Fuel
* Office Supplies
* Cleaning
* Taxes
* Advertising

Future:

* Custom Categories
* Fixed Expenses
* Recurring Expenses

---

# Scope

The module covers:

* Expense Categories
* Expense Creation
* Expense Editing
* Expense Deletion
* Daily Reports
* Weekly Reports
* Monthly Reports
* Analytics
* Offline Mode
* Synchronization

---

# Supported Platforms

Expenses are supported on:

* Android
* iOS
* Windows

All platforms behave identically.

---

# Main Features

Current features:

* Add Expense
* Edit Expense
* Delete Expense
* Expense Categories
* Search Expenses
* Daily Reports
* Weekly Reports
* Monthly Reports

Future features:

* Attach Receipts
* OCR Receipt Scanner
* Recurring Expenses
* Budget Limits
* Expense Approval Workflow

---

# Financial Role

Expenses contribute to:

```text id="exp01"
Outgoing Cash Flow
```

Unlike debt payments:

Expenses do not belong to any creditor.

They are standalone financial operations.

---

# Dashboard Integration

Expenses automatically update:

* Today's Expenses
* Weekly Expenses
* Monthly Expenses
* Total Expenses
* Cash Flow

No manual refresh required.

---

# Reports Integration

Every expense immediately appears in:

* Daily Reports
* Weekly Reports
* Monthly Reports
* Expense Analytics

Future:

* Quarterly Reports
* Yearly Reports

---

# Offline Support

Expenses fully support offline mode.

Users can:

* Create
* Edit
* Delete

without internet.

Synchronization occurs automatically later.

---

# Synchronization

Synchronization uploads:

* Expense Information
* Category
* Notes

Business timestamps always preserve:

```text id="exp02"
createdAt
```

Never replace it with:

* syncedAt
* uploadedAt
* serverTimestamp

---

# Source of Truth

Expense reports always depend on:

```text id="exp03"
createdAt
```

Business reports never depend on synchronization timestamps.

---

# Expense Categories

Every expense belongs to one category.

Examples:

```text id="exp04"
Electricity

Water

Internet

Rent

Salary

Fuel

Maintenance
```

Future:

Unlimited user-defined categories.

---

# Localization

The Expenses module supports:

* Arabic
* English

Using ARB localization.

No hardcoded strings.

---

# UI Design

The Expenses module follows:

* AppColors
* TextStyles
* Dark Mode
* Light Mode
* Responsive Layout

The experience is identical across all supported platforms.

---

# Security

Expense operations require:

* Authenticated account.
* Active subscription.
* Authorized workspace.

Unauthorized users cannot access financial information.

---

# Performance

Optimizations include:

* Lazy loading.
* Incremental Cubit updates.
* Efficient list rendering.
* Automatic report refresh.
* Offline-first architecture.

Supports:

* Tens of thousands of expense records.

---

# Business Rules

* Every expense is independent.
* Expenses never belong to debts.
* Expenses immediately affect reports.
* Dashboard updates automatically.
* Offline mode behaves identically to online mode.
* createdAt is the official business timestamp.
* Synchronization never changes historical dates.
* Reports are always calculated dynamically.

---

# Architecture

```text id="exp05"
Expenses Screen

↓

ExpensesCubit

↓

Expense UseCases

↓

Repository

↓

Firestore / Local Storage

↓

Reports

↓

Dashboard

↓

Updated UI
```

---

# End of Section

Next Section:

**7.2 Expense Categories**

This section documents the complete Expense Categories system, including predefined categories, custom categories, category management, localization, reporting behavior, synchronization, validation rules, and future extensibility.
# PART 7 — Expenses

# 7.2 Expense Categories

## Overview

Expense Categories organize business expenses into logical groups, making financial reports easier to read and analyze.

Every expense must belong to **exactly one category**.

Categories improve:

* Report readability
* Spending analysis
* Dashboard statistics
* Financial planning
* Future budgeting features

---

# Objectives

Expense Categories allow users to:

* Organize expenses.
* Filter reports.
* Analyze spending by category.
* Compare monthly expenses.
* Identify high-cost business areas.

---

# Current Implementation

The current implementation uses predefined categories.

Examples:

```text id="ec01"
Electricity

Water

Internet

Rent

Salary

Fuel

Maintenance

Transportation

Cleaning

Office Supplies

Taxes

Advertising

Miscellaneous
```

---

# Future Implementation

Future versions will allow:

* User-created categories.
* Category editing.
* Category deletion.
* Category icons.
* Category colors.

The current architecture already supports future expansion.

---

# Category Selection

When creating an expense:

```text id="ec02"
Add Expense

↓

Select Category

↓

Save Expense
```

Category selection is mandatory.

---

# Default Category

If future migration introduces old expenses without categories:

Assign:

```text id="ec03"
Miscellaneous
```

to maintain compatibility.

---

# Category Validation

Before saving:

Validate:

* Category selected.
* Category exists.
* Category is active.

Reject invalid categories.

---

# Reports Integration

Expense Categories are used inside:

* Daily Reports
* Weekly Reports
* Monthly Reports
* Expense Analytics

Future:

* Category Charts
* Budget Reports
* Cost Distribution

---

# Dashboard Integration

Dashboard can display:

```text id="ec04"
Highest Expense Category

↓

Salary
```

or

```text id="ec05"
Most Frequent Category

↓

Fuel
```

These values are calculated dynamically.

---

# Category Statistics

Future analytics:

For each category:

* Number of Expenses
* Total Amount
* Monthly Average
* Percentage of Total Spending

---

# Filtering

Users may filter expenses by:

```text id="ec06"
Category
```

Examples:

* Rent
* Fuel
* Internet

Reports refresh instantly after filtering.

---

# Search

Category filtering works together with:

* Date Range
* Amount
* Notes

Search uses debounce to improve performance.

---

# Localization

Every category has:

Arabic

Example:

```text id="ec07"
كهرباء

مياه

إيجار

رواتب

وقود
```

English

Example:

```text id="ec08"
Electricity

Water

Rent

Salary

Fuel
```

Localization uses ARB files only.

---

# UI Representation

Each category is displayed as:

* Label
* Optional Icon (Future)
* Optional Color (Future)

The current implementation displays localized text.

---

# Offline Support

Categories remain available offline.

Expense creation never depends on internet access.

---

# Synchronization

Categories synchronize automatically.

Expense records preserve their assigned category.

No category reassignment occurs during synchronization.

---

# Performance

Optimizations:

* Cached category list.
* Local lookup.
* Minimal rebuilds.
* Fast filtering.

Supports large datasets.

---

# Security

Categories inherit workspace permissions.

Users cannot assign unavailable categories.

Future:

Role-based category visibility.

---

# Business Rules

* Every expense belongs to one category.
* Category selection is mandatory.
* Reports group expenses by category.
* Localization always applies.
* Categories remain stable after synchronization.
* Missing categories default to Miscellaneous during migrations.
* Search supports category filtering.
* Dashboard statistics are calculated dynamically.

---

# Architecture

```text id="ec09"
Expense Screen

↓

Category Selector

↓

ExpensesCubit

↓

CreateExpenseUseCase

↓

Repository

↓

Expense Saved

↓

Reports

↓

Dashboard

↓

Updated UI
```

---

# End of Section

Next Section:

**7.3 Add Expense**

This section documents the complete expense creation workflow, including form fields, validation, category selection, financial updates, offline behavior, synchronization, report integration, and all business rules governing expense creation.
# PART 7 — Expenses

# 7.3 Add Expense

## Overview

The **Add Expense** feature allows users to record a new business expense.

Every expense immediately becomes part of the business's financial history and contributes to:

* Daily Reports
* Weekly Reports
* Monthly Reports
* Dashboard Statistics
* Expense Analytics
* Cash Flow

Unlike debts, expenses represent immediate outgoing cash and do not create future liabilities.

---

# Objectives

The Add Expense feature allows users to:

* Record operating costs.
* Categorize expenses.
* Improve financial tracking.
* Keep reports accurate.
* Support offline operation.

---

# Entry Point

Users access the feature through:

```text id="ae01"
Expenses

↓

Floating Action Button

↓

Add Expense
```

---

# Screen Layout

The Add Expense screen contains:

* Expense Amount
* Expense Category
* Notes
* Expense Date
* Save Button

Future:

* Receipt Image
* Invoice Number
* Vendor
* Payment Method

---

# Required Fields

Mandatory:

* Amount
* Category

Optional:

* Notes
* Expense Date

---

# Default Date

When opening the screen:

Default:

```text id="ae02"
Today

↓

createdAt
```

The user may modify the business date if allowed by application settings.

---

# Expense Amount Validation

Rules:

* Required
* Numeric
* Greater than zero

Valid:

```text id="ae03"
50

150

1250

5000
```

Invalid:

```text id="ae04"
0

-25

Empty
```

---

# Category Validation

Before saving:

Validate:

* Category selected.
* Category exists.
* Category is active.

Reject invalid selections.

---

# Notes

Notes are optional.

Examples:

```text id="ae05"
Office Internet

Printer Maintenance

Fuel for Delivery

Electricity Bill
```

---

# Save Flow

```text id="ae06"
Open Screen

↓

Enter Information

↓

Validate

↓

Create Expense

↓

Save

↓

Refresh Reports

↓

Refresh Dashboard

↓

Return
```

---

# Expense Record

Each expense contains:

* Expense ID
* Amount
* Category
* Notes
* createdAt
* createdBy

Future:

* Receipt URL
* Vendor
* Invoice Number

---

# Financial Impact

Immediately after saving:

Update:

* Total Expenses
* Daily Expenses
* Weekly Expenses
* Monthly Expenses
* Cash Flow

No manual recalculation.

---

# Dashboard Update

Dashboard automatically updates:

* Today's Expenses
* Monthly Expenses
* Total Expenses

Reports refresh immediately.

---

# Reports Integration

Expense creation updates:

* Daily Reports
* Weekly Reports
* Monthly Reports
* Expense Analytics

No refresh button required.

---

# Timeline Integration

Future Expense Timeline:

```text id="ae07"
Expense Created

↓

Appears Immediately
```

Ordered using:

```text id="ae08"
createdAt
```

---

# Offline Support

Expense creation fully supports offline mode.

Flow:

```text id="ae09"
Create Expense

↓

Store Locally

↓

Offline Queue

↓

Synchronize Later
```

Users continue working without interruption.

---

# Synchronization

Synchronization uploads:

* Expense
* Category
* Notes

Business timestamp:

```text id="ae10"
createdAt
```

is preserved.

Never overwrite with:

* syncedAt
* uploadedAt
* serverTimestamp

---

# Duplicate Protection

During saving:

* Disable Save button.
* Ignore repeated taps.
* Prevent duplicate expense creation.

---

# Error Handling

Examples:

```text id="ae11"
Invalid Amount

Category Required

Unable to Save

Network Error
```

The entered information remains available for correction.

---

# Loading State

While saving:

* Disable all inputs.
* Display loading indicator.
* Prevent duplicate submissions.

---

# Performance

Optimizations:

* Single database write.
* Incremental report updates.
* Incremental dashboard updates.
* Efficient Cubit state changes.
* Minimal widget rebuilds.

---

# Security

Only authenticated users with:

* Active Subscription
* Authorized Workspace
* Valid Permissions

may create expenses.

---

# Localization

Supports:

* Arabic
* English

All labels and validation messages are loaded from ARB localization files.

---

# Business Rules

* Every expense belongs to exactly one category.
* Amount must be greater than zero.
* Expense creation immediately updates reports.
* Dashboard refreshes automatically.
* Offline creation behaves identically.
* createdAt is the official business timestamp.
* Synchronization never modifies business dates.
* UI never performs financial calculations.
* Duplicate submissions are prevented.

---

# Architecture

```text id="ae12"
Add Expense Screen

↓

ExpensesCubit

↓

CreateExpenseUseCase

↓

Repository

↓

Save Expense

↓

Reports Engine

↓

Dashboard

↓

Updated UI
```

---

# End of Section

Next Section:

**7.4 Edit Expense**

This section documents the complete expense editing workflow, including editable fields, validation, category changes, report synchronization, offline behavior, financial consistency, and all business rules governing expense modifications.
# PART 7 — Expenses

# 7.4 Edit Expense

## Overview

The **Edit Expense** feature allows users to correct or update an existing expense while maintaining complete financial consistency.

Editing an expense immediately updates every report, statistic, and analytical calculation that depends on that expense.

Unlike debt payments, editing an expense does **not** affect any remaining balance calculation because expenses are standalone financial records.

---

# Objectives

The Edit Expense feature allows users to:

* Correct an incorrect amount.
* Change the expense category.
* Update notes.
* Correct the expense date (when permitted).
* Keep reports synchronized.

---

# Entry Point

Users edit an expense from:

```text id="ee01"
Expenses List

↓

Select Expense

↓

Edit
```

or

```text id="ee02"
Swipe Right

↓

✏ Edit
```

depending on the current platform design.

---

# Editable Fields

Current editable fields:

* Amount
* Category
* Notes

Conditionally editable:

* Expense Date (`createdAt`) if the application configuration allows historical corrections.

---

# Protected Fields

The following fields are never editable:

* Expense ID
* Firebase Document ID
* Creator Information
* Workspace ID

These identifiers remain immutable.

---

# Validation

Before saving:

Validate:

* Amount entered.
* Amount is numeric.
* Amount is greater than zero.
* Category selected.
* Category exists.

Reject invalid updates.

---

# Edit Flow

```text id="ee03"
Open Edit Screen

↓

Modify Fields

↓

Validate

↓

Update Expense

↓

Refresh Reports

↓

Refresh Dashboard

↓

Return
```

---

# Financial Impact

Editing an expense immediately updates:

* Total Expenses
* Daily Expenses
* Weekly Expenses
* Monthly Expenses
* Cash Flow

No manual recalculation is required.

---

# Example

Before edit:

```text id="ee04"
Amount

500 EGP

Category

Fuel
```

After edit:

```text id="ee05"
Amount

700 EGP

Category

Transportation
```

All reports immediately reflect:

* New Amount
* New Category

---

# Category Change

Changing the category:

Example:

```text id="ee06"
Fuel

↓

Maintenance
```

Automatically updates:

* Category Reports
* Dashboard Analytics
* Expense Distribution

No manual refresh.

---

# Date Modification

If business rules allow editing the expense date:

Reports regroup the expense automatically.

Example:

```text id="ee07"
Created

5 July

↓

Edited

7 July
```

The expense moves from:

* July 5 Daily Report

to:

* July 7 Daily Report

This regrouping is based on:

```text id="ee08"
createdAt
```

---

# Reports Update

Immediately refresh:

* Daily Reports
* Weekly Reports
* Monthly Reports
* Expense Analytics
* Dashboard Statistics

Reports always remain synchronized.

---

# Offline Support

Expense editing fully supports offline mode.

Flow:

```text id="ee09"
Edit Expense

↓

Store Locally

↓

Offline Queue

↓

Synchronize Later
```

---

# Synchronization

Synchronization uploads:

* Updated Amount
* Updated Category
* Updated Notes

Business timestamps remain unchanged unless the user explicitly edits the business date.

---

# Duplicate Protection

While updating:

* Disable Save button.
* Prevent repeated taps.
* Ignore duplicate update requests.

---

# Error Handling

Examples:

```text id="ee10"
Invalid Amount

Category Required

Unable to Update

Network Error
```

No changes are committed if validation fails.

---

# Loading State

During update:

* Disable form inputs.
* Display loading indicator.
* Prevent duplicate submissions.

---

# Performance

Optimizations:

* Update only affected expense.
* Refresh only dependent reports.
* Efficient Cubit state updates.
* Minimal widget rebuilds.

---

# Security

Only authenticated users with:

* Active Subscription
* Authorized Workspace
* Valid Permissions

may edit expenses.

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

No hardcoded validation messages.

---

# Business Rules

* Amount must always be greater than zero.
* Every expense belongs to one category.
* Editing updates reports immediately.
* Dashboard refreshes automatically.
* Offline edits behave identically.
* createdAt remains the official business timestamp unless intentionally changed according to business rules.
* Synchronization preserves historical accuracy.
* UI never performs financial calculations.

---

# Architecture

```text id="ee11"
Edit Expense Screen

↓

ExpensesCubit

↓

UpdateExpenseUseCase

↓

Repository

↓

Update Expense

↓

Reports Engine

↓

Dashboard

↓

Updated UI
```

---

# End of Section

Next Section:

**7.5 Delete Expense**

This section documents the complete expense deletion workflow, including confirmation dialogs, report synchronization, dashboard updates, offline behavior, synchronization rules, validation, and all business rules governing expense deletion.
# PART 7 — Expenses

# 7.5 Delete Expense

## Overview

The **Delete Expense** feature allows users to permanently remove an expense that was created incorrectly.

Since every expense contributes to the financial reports and business analytics, deleting an expense immediately updates all dependent calculations.

Deletion is considered a sensitive financial operation and therefore always requires user confirmation.

---

# Objectives

The Delete Expense feature allows users to:

* Remove incorrect expenses.
* Correct accidental entries.
* Maintain accurate reports.
* Keep dashboard statistics synchronized.
* Preserve financial consistency.

---

# Entry Point

Users delete an expense from:

```text id="de01"
Expenses List

↓

Swipe Left

↓

🗑 Delete
```

or

```text id="de02"
Expense Details

↓

More Menu

↓

Delete
```

depending on the platform.

---

# Confirmation Dialog

Before deleting:

Display:

```text id="de03"
Delete this expense?

This action cannot be undone.

[Cancel]

[Delete]
```

Deletion never occurs without confirmation.

---

# Delete Flow

```text id="de04"
Select Expense

↓

Delete

↓

Confirmation

↓

Delete Record

↓

Refresh Reports

↓

Refresh Dashboard

↓

Return
```

---

# Financial Impact

Immediately after deletion:

Update:

* Daily Expenses
* Weekly Expenses
* Monthly Expenses
* Total Expenses
* Cash Flow
* Dashboard Statistics

All financial summaries are recalculated automatically.

---

# Example

Before deletion:

```text id="de05"
Today's Expenses

2,500 EGP
```

Delete:

```text id="de06"
500 EGP
```

Result:

```text id="de07"
Today's Expenses

2,000 EGP
```

The dashboard updates instantly.

---

# Reports Update

Deleting an expense automatically refreshes:

* Daily Reports
* Weekly Reports
* Monthly Reports
* Expense Analytics
* Dashboard

No manual refresh is necessary.

---

# Analytics Update

Expense analytics immediately update:

* Category Totals
* Monthly Totals
* Spending Trends

Deleted expenses no longer participate in any calculation.

---

# Timeline Impact

Future Expense Timeline:

Deleted expenses are removed from the timeline immediately.

---

# Offline Support

Expense deletion fully supports offline mode.

Flow:

```text id="de08"
Delete Expense

↓

Store Operation

↓

Offline Queue

↓

Synchronize Later
```

The UI reflects the deletion immediately.

---

# Synchronization

Synchronization uploads:

* Delete Operation

Business timestamps remain unchanged.

The deletion operation itself does not modify:

```text id="de09"
createdAt
```

---

# Duplicate Protection

During deletion:

* Disable Delete button.
* Prevent repeated taps.
* Ignore duplicate delete requests.

Only one delete operation executes.

---

# Error Handling

Examples:

```text id="de10"
Unable to Delete

Network Error

Try Again
```

If deletion fails:

The expense remains unchanged.

Reports are not modified.

---

# Loading State

While deleting:

* Disable dialog buttons.
* Display loading spinner.
* Prevent duplicate operations.

---

# Performance

Optimizations:

* Delete only affected expense.
* Refresh dependent reports only.
* Efficient Cubit state updates.
* Minimal widget rebuilds.

Supports very large expense datasets.

---

# Security

Only authenticated users with:

* Active Subscription
* Authorized Workspace
* Valid Permissions

may delete expenses.

---

# Localization

Supports:

* Arabic
* English

All confirmation dialogs and error messages are localized using ARB files.

---

# Future Soft Delete

Future versions may introduce:

```text id="de11"
Soft Delete
```

Benefits:

* Expense Recovery
* Audit History
* Financial Audit Compliance

Current implementation performs a permanent deletion.

---

# Business Rules

* Every deletion requires confirmation.
* Deleted expenses disappear from all reports.
* Dashboard refreshes automatically.
* Expense analytics update immediately.
* Offline deletion behaves identically to online deletion.
* createdAt remains the official business timestamp for historical records until deletion.
* Synchronization never corrupts report integrity.
* UI never performs business validation.

---

# Architecture

```text id="de12"
Delete Expense

↓

ExpensesCubit

↓

DeleteExpenseUseCase

↓

Repository

↓

Delete Record

↓

Reports Engine

↓

Dashboard

↓

Updated UI
```

---

# End of Section

Next Section:

**7.6 Expense Reports**

This section documents the complete reporting engine for the **Expenses** module, including Daily, Weekly, Monthly, Category Reports, Analytics, Dashboard integration, `createdAt` grouping rules, filtering, synchronization, and all business rules governing expense reports.
# PART 7 — Expenses

# 7.6 Expense Reports

## Overview

The **Expense Reports Engine** provides a complete analysis of all business expenses.

Its purpose is to help business owners understand:

* Where money is being spent.
* How spending changes over time.
* Which categories consume the largest budget.
* How expenses affect overall business performance.

All reports are generated dynamically.

No report stores financial totals.

---

# Objectives

Expense Reports allow users to:

* Monitor daily spending.
* Compare weekly expenses.
* Analyze monthly costs.
* Track category distribution.
* Support financial decision making.

---

# Report Categories

The Expenses module contributes to:

* Daily Expense Report
* Weekly Expense Report
* Monthly Expense Report
* Category Report
* Expense Analytics
* Dashboard Statistics

Future:

* Quarterly Report
* Yearly Report
* Budget Report
* Branch Comparison Report

---

# Daily Expense Report

Displays:

* Total Expenses Today
* Number of Expenses
* Categories Used
* Largest Expense
* Average Expense

Grouping:

```text id="er01"
createdAt

↓

Day
```

---

# Weekly Expense Report

Displays:

* Weekly Total
* Daily Breakdown
* Highest Spending Day
* Expense Count

Grouping:

```text id="er02"
createdAt

↓

Week
```

---

# Monthly Expense Report

Displays:

* Monthly Total
* Category Totals
* Number of Expenses
* Spending Trend
* Highest Category

Grouping:

```text id="er03"
createdAt

↓

Month + Year
```

---

# Category Report

Displays:

For every category:

* Total Amount
* Number of Expenses
* Average Expense
* Percentage of Total Spending

Example:

```text id="er04"
Fuel

↓

8,500 EGP
```

---

```text id="er05"
Rent

↓

15,000 EGP
```

---

# Dashboard Statistics

Dashboard receives:

* Today's Expenses
* Weekly Expenses
* Monthly Expenses
* Total Expenses
* Largest Category

All values are calculated dynamically.

---

# Expense Analytics

Analytics include:

* Monthly Trend
* Expense Growth
* Category Distribution
* Average Daily Spending

Future:

* Forecasting
* Budget Prediction
* Cost Optimization Suggestions

---

# Report Refresh

Reports automatically refresh after:

* Add Expense
* Edit Expense
* Delete Expense
* Offline Synchronization

No manual refresh is required.

---

# Report Source

Reports always calculate from:

```text id="er06"
Expense Records
```

No cached totals are used.

Every calculation is performed dynamically.

---

# Timestamp Rule

Expense reports always depend on:

```text id="er07"
createdAt
```

Never:

```text id="er08"
syncedAt

uploadedAt

serverTimestamp
```

Historical reports always reflect the actual expense date.

---

# Historical Accuracy

Example:

Expense created:

```text id="er09"
8 July
```

Uploaded:

```text id="er10"
12 July
```

Appears inside:

```text id="er11"
8 July Report
```

because:

```text id="er12"
createdAt
```

is the official business timestamp.

---

# Offline Integration

Offline-created expenses appear immediately in reports.

Synchronization uploads only the records.

Historical dates never change.

---

# Filtering

Current filters:

* Date Range
* Category
* Amount Range

Future:

* Notes
* Creator
* Payment Method

---

# Sorting

Supported sorting:

* Newest First
* Oldest First
* Highest Amount
* Lowest Amount

Future:

* Category
* Frequency

---

# Empty Report

If no expenses exist:

Display:

```text id="er13"
No Expense Data Available
```

Localized using ARB.

---

# Large Dataset Support

The reporting engine supports:

* Thousands of expenses.
* Multi-year history.
* Large category collections.

Performance remains stable.

---

# Performance

Optimizations:

* Incremental report refresh.
* Lazy loading.
* Efficient Cubit updates.
* Cached queries.
* Dynamic calculations.

No duplicated calculations.

---

# Synchronization

Synchronization automatically updates:

* Reports
* Dashboard
* Analytics

No duplicated expenses.

No duplicated totals.

---

# Localization

Reports fully support:

* Arabic
* English

Using ARB localization.

No hardcoded report labels.

---

# Security

Expense reports require:

* Authenticated account.
* Active subscription.
* Authorized workspace.

Future:

Role-based report visibility.

---

# Business Rules

* Reports always calculate dynamically.
* Reports never store totals.
* createdAt defines report grouping.
* Offline reports behave identically.
* Synchronization never changes report dates.
* Dashboard consumes the same reporting engine.
* Category totals are recalculated automatically.
* Report refresh occurs after every expense operation.
* Financial accuracy has priority over rendering performance.

---

# Architecture

```text id="er14"
Expense Records

↓

Report Engine

↓

Daily

↓

Weekly

↓

Monthly

↓

Category

↓

Analytics

↓

Dashboard

↓

Updated UI
```

---

# End of Section

Next Section:

**7.7 Expense Analytics**

This section documents the complete analytics engine for the **Expenses** module, including spending trends, category distribution, monthly comparisons, financial insights, charts, KPI calculations, dashboard integration, and future predictive analytics support.
# PART 7 — Expenses

# 7.7 Expense Analytics

## Overview

The **Expense Analytics** module transforms raw expense records into meaningful business insights.

Unlike standard reports, analytics focus on:

* Trends
* Comparisons
* KPIs
* Spending behavior
* Financial performance

The goal is to help business owners make better financial decisions.

Expense Analytics never modify financial data.

They are read-only.

---

# Objectives

Expense Analytics help users:

* Understand spending habits.
* Detect abnormal expenses.
* Monitor business growth.
* Compare historical periods.
* Improve budgeting decisions.

---

# Data Source

Analytics always calculate from:

```text id="ea01"
Expense Records
```

No cached totals.

No duplicated calculations.

Every KPI is generated dynamically.

---

# Dashboard KPIs

The dashboard may display:

* Today's Expenses
* This Week's Expenses
* This Month's Expenses
* Average Daily Expense
* Largest Expense
* Largest Category

Future:

* Budget Utilization
* Expense Forecast
* Savings Opportunities

---

# Monthly Trend

Displays:

Expense totals grouped by:

```text id="ea02"
Month + Year
```

Example:

```text id="ea03"
January

↓

18,500 EGP

February

↓

21,300 EGP

March

↓

17,900 EGP
```

Useful for identifying seasonal spending.

---

# Daily Trend

Displays:

Daily expense totals.

Grouping:

```text id="ea04"
createdAt

↓

Day
```

Supports:

* Daily charts.
* Spending timeline.

---

# Weekly Trend

Displays:

Weekly totals.

Grouping:

```text id="ea05"
createdAt

↓

Week
```

Useful for monitoring weekly operational costs.

---

# Category Distribution

Displays:

Each category's contribution.

Example:

```text id="ea06"
Rent

45%
```

```text id="ea07"
Salary

28%
```

```text id="ea08"
Fuel

12%
```

The percentages always total:

```text id="ea09"
100%
```

---

# Largest Category

Analytics determine:

```text id="ea10"
Highest Spending Category
```

Example:

```text id="ea11"
Salary

↓

42,000 EGP
```

Automatically updates after every expense modification.

---

# Largest Expense

Displays:

```text id="ea12"
Largest Individual Expense
```

Example:

```text id="ea13"
Rent

15,000 EGP
```

---

# Average Expense

Formula:

```text id="ea14"
Average Expense

=

Total Expenses

÷

Number of Expenses
```

Useful for benchmarking spending behavior.

---

# Expense Frequency

Displays:

Number of expenses per category.

Example:

```text id="ea15"
Fuel

↓

28 Expenses
```

Future:

* Heatmaps.
* Calendar visualization.

---

# Spending Growth

Compare:

Current Month

vs

Previous Month

Possible results:

```text id="ea16"
+15%

-8%

0%
```

Future:

Visual trend indicators.

---

# Charts

Current recommendation:

* Bar Chart
* Pie Chart
* Line Chart

Future:

* Area Chart
* Heat Map
* Interactive Dashboard

Charts always consume the same analytics engine.

---

# Dashboard Integration

Dashboard automatically refreshes:

* KPIs
* Charts
* Spending Trends
* Category Distribution

No manual refresh required.

---

# Offline Support

Analytics remain fully functional offline.

Calculations use locally available expense records.

Synchronization updates analytics automatically.

---

# Timestamp Rule

Analytics always depend on:

```text id="ea17"
createdAt
```

Never:

```text id="ea18"
syncedAt

uploadedAt

serverTimestamp
```

Historical analysis remains accurate.

---

# Filtering

Current filters:

* Date Range
* Category

Future:

* Expense Creator
* Amount Range
* Vendor

---

# Performance

Optimizations:

* Incremental analytics refresh.
* Lazy calculations.
* Cached queries.
* Efficient Cubit updates.

Suitable for:

* Thousands of expense records.
* Multi-year datasets.

---

# Future AI Analytics

Future versions may provide:

* Expense anomaly detection.
* Spending recommendations.
* Budget alerts.
* Cash flow predictions.
* Automatic financial insights.

These features will reuse the existing analytics engine.

---

# Security

Analytics require:

* Authenticated account.
* Active subscription.
* Authorized workspace.

Future role-based visibility:

* Owner
* Accountant
* Manager

---

# Business Rules

* Analytics never modify financial records.
* Analytics always calculate dynamically.
* createdAt defines historical grouping.
* Offline analytics behave identically.
* Synchronization never changes historical calculations.
* Dashboard consumes the analytics engine directly.
* Charts always use calculated values.
* Financial insights remain read-only.
* Performance is prioritized for large datasets.

---

# Architecture

```text id="ea19"
Expense Records

↓

Analytics Engine

↓

KPIs

↓

Category Analysis

↓

Trend Analysis

↓

Charts

↓

Dashboard

↓

Updated UI
```

---

# End of Section

Next Section:

**7.8 Business Rules & Edge Cases**

This section documents every business rule, validation, synchronization scenario, offline case, report dependency, analytics behavior, and exceptional scenario related to the **Expenses** module, ensuring complete financial consistency across the application.
# PART 7 — Expenses

# 7.8 Business Rules & Edge Cases

## Overview

This section defines the official business rules governing the **Expenses** module.

These rules ensure:

* Financial consistency
* Accurate reporting
* Reliable synchronization
* Offline stability
* Predictable application behavior

Every expense operation must follow these rules.

---

# Financial Philosophy

Tahsel treats every expense as a completed financial transaction.

Unlike debts:

* Expenses do not create future liabilities.
* Expenses do not have remaining balances.
* Expenses do not support partial payments.

Each expense is independent.

---

# Source of Truth

The single source of truth is:

```text id="ebr01"
Expense Records
```

Reports, analytics, and dashboard statistics are always derived from these records.

Never calculate from:

* Cached totals
* Dashboard values
* Summary widgets

---

# Expense Creation Rules

Creating an expense:

* Creates one expense record.
* Updates reports immediately.
* Updates dashboard immediately.
* Updates analytics immediately.

No additional financial transaction is created.

---

# Edit Rules

Editing an expense:

* Updates only the selected expense.
* Refreshes dependent reports.
* Refreshes dashboard.
* Refreshes analytics.

No duplicate expense is created.

---

# Delete Rules

Deleting an expense:

* Removes the expense.
* Refreshes reports.
* Refreshes dashboard.
* Refreshes analytics.

Deleted expenses no longer participate in any calculation.

---

# Amount Validation

The expense amount must satisfy:

```text id="ebr02"
Amount

>

0
```

Rejected values:

```text id="ebr03"
0

Negative

Empty
```

---

# Category Rules

Every expense must belong to:

```text id="ebr04"
Exactly One Category
```

No uncategorized expense may be created.

---

# Date Rules

Business date:

```text id="ebr05"
createdAt
```

defines:

* Daily Reports
* Weekly Reports
* Monthly Reports
* Analytics
* Historical Timeline

Never use:

```text id="ebr06"
syncedAt

uploadedAt

serverTimestamp
```

---

# Historical Reports

Example:

Expense created:

```text id="ebr07"
10 August
```

Uploaded:

```text id="ebr08"
13 August
```

Appears inside:

```text id="ebr09"
10 August Report
```

Historical reports always preserve the original business date.

---

# Offline Rules

Offline mode supports:

* Add Expense
* Edit Expense
* Delete Expense

Behavior is identical to online mode.

---

# Synchronization Rules

Synchronization:

* Uploads pending expense operations.
* Never changes createdAt.
* Never duplicates expenses.
* Never modifies historical reports.

---

# Report Rules

Expense reports:

* Always calculate dynamically.
* Never cache totals.
* Always refresh after successful operations.

Manual recalculation is never required.

---

# Analytics Rules

Analytics:

* Consume expense records directly.
* Never store intermediate totals.
* Refresh automatically.

Charts always display the latest calculations.

---

# Dashboard Rules

Dashboard:

* Uses the same report engine.
* Never performs independent calculations.
* Updates after every successful operation.

---

# Search Rules

Search supports:

* Notes
* Category
* Date

Performance requirement:

Use debounce.

Avoid unnecessary queries.

---

# Sorting Rules

Supported sorting:

* Newest First
* Oldest First
* Highest Amount
* Lowest Amount

Future:

* Category
* Frequency

---

# Duplicate Protection

Tahsel ignores:

* Double taps.
* Duplicate save requests.
* Multiple delete requests.

Only one operation executes.

---

# Error Recovery

If an operation fails:

* Previous expense data remains unchanged.
* Reports remain unchanged.
* Dashboard remains unchanged.
* Analytics remain unchanged.

Users receive a localized error message.

---

# Large Dataset Support

The module supports:

* Thousands of expense records.
* Multi-year financial history.
* Large report datasets.

Performance optimizations ensure smooth rendering.

---

# Edge Case 1

Create expense.

Result:

Appears immediately in:

* Reports
* Dashboard
* Analytics

---

# Edge Case 2

Edit amount.

Reports update automatically.

Analytics update automatically.

---

# Edge Case 3

Change category.

Expense immediately moves to the new category.

Old category totals decrease.

New category totals increase.

---

# Edge Case 4

Delete expense.

Expense disappears from:

* Reports
* Dashboard
* Analytics

Immediately.

---

# Edge Case 5

Offline expense creation.

Appears locally.

Synchronization uploads later.

Business date remains:

```text id="ebr10"
createdAt
```

---

# Edge Case 6

Offline expense edit.

Local reports update immediately.

Synchronization preserves financial consistency.

---

# Edge Case 7

Offline expense deletion.

Expense disappears locally.

Synchronization removes it remotely.

---

# Edge Case 8

Network interruption.

Pending operation enters:

```text id="ebr11"
Offline Queue
```

No duplicate records are created.

---

# Edge Case 9

Very large datasets.

The application continues using:

* Lazy loading.
* Incremental Cubit updates.
* Cached queries.

Performance remains stable.

---

# Edge Case 10

Synchronization after several offline operations.

Operations execute in order.

Historical dates remain correct.

Reports remain accurate.

---

# Security Rules

Expense operations require:

* Authenticated account.
* Active subscription.
* Authorized workspace.

Unauthorized users cannot modify financial records.

---

# Business Rules Summary

* Every expense is independent.
* Expenses never have remaining balances.
* Every expense belongs to one category.
* Reports are always dynamic.
* Analytics are always dynamic.
* Dashboard consumes report results.
* createdAt defines business chronology.
* Offline mode behaves identically.
* Synchronization never changes historical dates.
* Financial accuracy has higher priority than UI performance.

---

# Architecture

```text id="ebr12"
Expense Operation

↓

Validation

↓

ExpensesCubit

↓

UseCase

↓

Repository

↓

Expense Records

↓

Reports

↓

Analytics

↓

Dashboard

↓

Updated UI
```

---

# End of PART 7 — Expenses

The **Expenses** module documentation is now complete.

**Next Part:**

# **PART 8 — Employee Management**

This is one of the largest modules in Tahsel and will comprehensively document employee management, attendance, salaries, payroll, advances, reports, business rules, validations, offline mode, synchronization, and financial calculations.
# PART 8 — Employee Management

# 8.1 Overview

## Introduction

The **Employee Management** module enables businesses to manage employees, attendance, payroll, salary calculations, advances, and workforce reporting from a single centralized system.

It is designed for businesses that have one or more employees and need an integrated Human Resources (HR) and Payroll solution.

The module integrates directly with:

* Dashboard
* Reports Engine
* Expenses Module
* Notifications
* Offline Synchronization

Future integrations:

* Fingerprint Devices
* Face Recognition
* QR Attendance
* Shift Management

---

# Purpose

The Employee Management module helps businesses:

* Maintain employee records.
* Monitor attendance.
* Track absences.
* Calculate salaries automatically.
* Manage payroll.
* Analyze workforce performance.

---

# Supported Businesses

The module supports:

* Cafés
* Restaurants
* Shops
* Retail Stores
* Service Centers
* PlayStation Cafés

Future:

* Warehouses
* Clinics
* Gyms
* Salons

---

# Core Features

Current features:

* Employee Management
* Attendance
* Check-In
* Check-Out
* Absence Tracking
* Salary Calculation
* Salary Payment
* Payroll History
* Reports

Future:

* Shift Scheduling
* Leave Requests
* Overtime
* Commissions
* Performance Reviews

---

# Employee Lifecycle

Every employee follows this lifecycle:

```text id="emp01"
Create Employee

↓

Active

↓

Attendance

↓

Salary Calculation

↓

Payroll

↓

Suspend (Optional)

↓

Disable (Optional)

↓

Delete (Optional)
```

---

# Module Structure

The Employee Management module consists of:

* Employee Profiles
* Attendance
* Salary Engine
* Payroll
* Reports
* Analytics

Each subsystem works independently while remaining fully synchronized.

---

# Financial Integration

Employee salaries contribute directly to:

* Expenses Module
* Financial Reports
* Dashboard Statistics
* Cash Flow

Salary payments automatically become business expenses.

---

# Dashboard Integration

Dashboard displays:

* Total Employees
* Active Employees
* Suspended Employees
* Today's Attendance
* Absent Employees
* Monthly Payroll

All statistics are calculated dynamically.

---

# Reports Integration

Employee information contributes to:

* Daily Reports
* Monthly Payroll Reports
* Attendance Reports
* Salary Reports
* Expense Reports

Future:

* Performance Reports
* Productivity Reports

---


# Synchronization

Synchronization uploads:

* Employee Data
* Attendance
* Payroll
* Salary Payments

Business timestamps preserve:

```text id="emp02"
createdAt
```

Never replace with:

* syncedAt
* uploadedAt
* serverTimestamp

---

# Source of Truth

The source of truth is:

```text id="emp03"
Employee Records
```

Attendance records.

Payroll records.

Salary records.

No derived financial data is permanently stored.

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

No hardcoded employee labels.

---

# UI Design

Employee Management follows:

* AppColors
* TextStyles
* Responsive Layout
* Dark Mode
* Light Mode

Supports:

* Android
* iOS
* Windows

---

# Security

Employee operations require:

* Authenticated account.
* Active subscription.
* Authorized workspace.
* Employee management permission.

Future role permissions:

* Owner
* HR
* Manager
* Accountant

---

# Performance

Optimizations:

* Lazy loading.
* Incremental Cubit updates.
* Efficient employee search.
* Debounced filters.
* Minimal widget rebuilds.

Supports:

* Thousands of employees.
* Millions of attendance records.

---

# Business Rules

* Every employee has a unique profile.
* Attendance belongs to one employee.
* Payroll is calculated dynamically.
* Salary payments automatically affect expenses.
* createdAt is the official business timestamp.
* Synchronization never changes historical records.
* Dashboard always consumes calculated data.

---

# Architecture

```text id="emp04"
Employee Module

↓

Employees

Attendance

Payroll

Reports

↓

Dashboard

↓

Updated UI
```

---

# End of Section

Next Section:

**8.2 Employee Profile**

This section documents the complete employee profile system, including employee creation, personal information, employment status, profile editing, validation rules, synchronization, permissions, and business rules governing employee records.
# PART 8 — Employee Management

# 8.2 Employee Profile

## Overview

The **Employee Profile** represents the master record for every employee inside Tahsel.

Every employee must have exactly one profile.

This profile acts as the central reference for:

* Attendance
* Payroll
* Salary Calculation
* Reports
* Notifications
* Future HR features

All employee-related modules reference this profile using the employee's unique identifier.

---

# Objectives

The Employee Profile allows businesses to:

* Register employees.
* Store employee information.
* Manage employment status.
* Track employee history.
* Connect payroll with attendance.

---

# Employee Lifecycle

Every employee progresses through the following lifecycle:

```text id="ep01"
Create Employee

↓

Active

↓

Working

↓

Suspended (Optional)

↓

Inactive (Optional)

↓

Deleted
```

Each transition follows defined business rules.

---

# Employee Fields

Every employee profile contains:

* Employee ID
* Full Name
* Phone Number
* Position
* Salary
* Hire Date
* Employment Status
* Notes
* createdAt

Future fields:

* National ID
* Email
* Address
* Emergency Contact
* Birth Date
* Profile Image

---

# Employee ID

Every employee receives a unique identifier.

Rules:

* Generated automatically.
* Never reused.
* Never editable.

The Employee ID is used internally for relationships across the system.

---

# Employee Name

Rules:

* Required.
* Cannot be empty.
* Supports Arabic and English.
* Displayed in reports exactly as stored.

---

# Phone Number

Optional in the current implementation.

Future usage:

* WhatsApp Notifications
* SMS Notifications
* Employee Contact
* Authentication

Validation:

* Numeric.
* Valid format.
* Country-specific validation may be added later.

---

# Position

Examples:

```text id="ep02"
Cashier

Barista

Manager

Cleaner

Delivery

Technician
```

Future:

Custom job titles.

---

# Salary

Each employee has a base salary.

Rules:

* Required.
* Greater than zero.
* Used by the Payroll Engine.

The value represents the agreed monthly salary before adjustments.

---

# Hire Date

The hire date records when employment began.

Future usage:

* Seniority Reports.
* Employee Anniversary.
* Leave Eligibility.

---

# Employment Status

Current statuses:

```text id="ep03"
Active

Suspended

Inactive

Deleted
```

Meaning:

Active

* Employee can work.
* Attendance allowed.
* Salary calculated.

Suspended

* Employee cannot check in.
* Salary calculation paused (based on business configuration).

Inactive

* Employee retained for historical purposes.
* No attendance.
* No future payroll.

Deleted

* Employee removed or soft deleted depending on implementation.

---

# Notes

Optional field.

Examples:

```text id="ep04"
Night Shift

Part-Time

Temporary Employee

Seasonal Worker
```

---

# Profile Creation

Flow:

```text id="ep05"
Employees

↓

Add Employee

↓

Fill Information

↓

Validate

↓

Create Profile

↓

Employee Available
```

---

# Validation

Before saving:

Validate:

* Name entered.
* Salary greater than zero.
* Position selected (if required).
* No invalid values.

Reject invalid profiles.

---

# Editing

Editable fields:

* Name
* Phone
* Position
* Salary
* Notes

Protected fields:

* Employee ID
* createdAt

Future:

Hire Date editing may be restricted.

---

# Reports Integration

Employee Profile contributes to:

* Employee Reports
* Payroll Reports
* Attendance Reports
* Dashboard Statistics

Changing profile information updates reports immediately.

---

# Dashboard Integration

Dashboard displays:

* Employee Count
* Active Employees
* Suspended Employees
* Payroll Summary

All values are calculated dynamically.

---

# Synchronization

Synchronization uploads:

* Employee Information
* Status Changes
* Salary Updates

Business timestamp:

```text id="ep06"
createdAt
```

is always preserved.

---

# Security

Only authorized users with Employee Management permission may:

* Create Employees
* Edit Employees
* Suspend Employees
* Delete Employees

Future:

Role-based permissions for HR staff.

---

# Performance

Optimizations:

* Lazy employee loading.
* Debounced employee search.
* Incremental Cubit updates.
* Cached profile retrieval.

Supports thousands of employee profiles.

---

# Business Rules

* Every employee has one unique profile.
* Employee ID is immutable.
* Salary must be greater than zero.
* Employment status controls future operations.
* Reports consume employee profiles dynamically.
* Offline profile management behaves identically.
* createdAt is the official business timestamp.
* Synchronization never alters historical records.
* Profile editing never breaks payroll relationships.

---

# Architecture

```text id="ep07"
Employee Profile Screen

↓

EmployeesCubit

↓

Create / Update Employee UseCase

↓

Repository

↓

Employee Record

↓

Attendance

Payroll

Reports

↓

Dashboard
```

---

# End of Section

Next Section:

**8.3 Create Employee**

This section documents the complete employee creation workflow, including form fields, validation, employment initialization, salary setup, synchronization, offline behavior, and all business rules governing new employee registration.
# PART 8 — Employee Management

# 8.3 Create Employee

## Overview

The **Create Employee** feature registers a new employee in the Tahsel system.

After successful creation, the employee becomes available for:

* Attendance
* Check-In / Check-Out
* Salary Calculation
* Payroll
* Reports
* Dashboard Statistics

Creating an employee does **not** generate any financial transaction.

Salary expenses are generated only when payroll is processed.

---

# Objectives

The Create Employee feature allows businesses to:

* Register new employees.
* Initialize employment information.
* Prepare payroll records.
* Enable attendance tracking.
* Keep workforce information organized.

---

# Entry Point

Users access the feature from:

```text id="ce01"
Employees

↓

Floating Action Button

↓

Add Employee
```

---

# Screen Layout

The Create Employee screen contains:

* Full Name
* Phone Number
* Position
* Monthly Salary
* Hire Date
* Notes
* Save Button

Future:

* National ID
* Email
* Address
* Profile Picture
* Emergency Contact

---

# Required Fields

Mandatory:

* Full Name
* Position
* Monthly Salary

Optional:

* Phone Number
* Notes

Default:

* Hire Date = Today

---

# Default Values

When opening the screen:

```text id="ce02"
Employment Status

↓

Active
```

```text id="ce03"
Hire Date

↓

Today
```

The employee is immediately eligible for attendance.

---

# Validation

Before saving:

Validate:

* Name entered.
* Name not empty.
* Salary entered.
* Salary greater than zero.
* Position selected (if required).

Reject invalid data.

---

# Creation Flow

```text id="ce04"
Open Screen

↓

Enter Employee Information

↓

Validate

↓

Create Employee

↓

Refresh Employee List

↓

Refresh Dashboard

↓

Return
```

---

# Employee Record

Creating an employee stores:

* Employee ID
* Name
* Phone
* Position
* Salary
* Status
* Hire Date
* Notes
* createdAt

Future:

* Employee Number
* Department
* Branch

---

# Attendance Initialization

Immediately after creation:

Employee becomes available inside:

* Attendance Screen
* Check-In
* Check-Out

No additional setup is required.

---

# Payroll Initialization

The Payroll Engine recognizes the employee immediately.

Salary calculation begins according to:

* Salary Period
* Attendance
* Business Rules

No salary is generated during creation.

---

# Dashboard Update

Dashboard automatically updates:

* Total Employees
* Active Employees

Reports refresh immediately.

---

# Reports Integration

Employee creation updates:

* Employee Reports
* Dashboard Statistics

Future:

* HR Analytics
* Workforce Growth Reports

---


# Synchronization

Synchronization uploads:

* Employee Profile
* Status
* Salary

Business timestamp:

```text id="ce06"
createdAt
```

is preserved.

Never overwrite with:

* syncedAt
* uploadedAt
* serverTimestamp

---

# Duplicate Protection

During saving:

* Disable Save button.
* Ignore repeated taps.
* Prevent duplicate employee creation.

---

# Error Handling

Examples:

```text id="ce07"
Name Required

Salary Required

Invalid Salary

Unable to Save
```

Entered information remains available for correction.

---

# Loading State

During creation:

* Disable all form inputs.
* Show loading indicator.
* Prevent duplicate submissions.

---

# Security

Only users with Employee Management permission may create employees.

Required:

* Authenticated account.
* Active subscription.
* Authorized workspace.

---

# Localization

Supports:

* Arabic
* English

All labels, validation messages, and dialogs use ARB localization.

---

# Business Rules

* Every employee receives one unique Employee ID.
* New employees are Active by default.
* Salary must be greater than zero.
* Hire Date defaults to today.
* Employee creation does not generate expenses.
* Attendance becomes available immediately.
* Payroll recognizes the employee immediately.
* Dashboard updates automatically.
* createdAt is the official business timestamp.

---

# Architecture

```text id="ce08"
Create Employee Screen

↓

EmployeesCubit

↓

CreateEmployeeUseCase

↓

Repository

↓

Employee Record

↓

Attendance Engine

↓

Payroll Engine

↓

Dashboard

↓

Updated UI
```

---

# End of Section

Next Section:

**8.4 Edit Employee**

This section documents the complete employee editing workflow, including editable fields, validation, employment status updates, salary modifications, synchronization, offline behavior, and all business rules governing employee profile updates.
# PART 8 — Employee Management

# 8.4 Edit Employee

## Overview

The **Edit Employee** feature allows authorized users to update an employee's profile while preserving historical attendance, payroll, and reporting integrity.

Editing an employee updates only the employee profile.

It never modifies:

* Previous attendance records.
* Previous payroll records.
* Previous salary payments.
* Historical reports.

Historical records always preserve the information that existed when they were created.

---

# Objectives

The Edit Employee feature allows users to:

* Correct employee information.
* Update salary.
* Change position.
* Update contact information.
* Modify notes.
* Change employment status.

---

# Entry Point

Users access editing from:

```text id="eep01"
Employees List

↓

Select Employee

↓

Edit
```

or

```text id="eep02"
Employee Details

↓

✏ Edit
```

depending on the platform.

---

# Editable Fields

Current editable fields:

* Full Name
* Phone Number
* Position
* Monthly Salary
* Notes
* Employment Status

Future:

* Department
* Branch
* Email
* Emergency Contact

---

# Protected Fields

The following fields are immutable:

* Employee ID
* createdAt

These values are never changed after creation.

---

# Salary Update

Updating the salary:

```text id="eep03"
Old Salary

↓

New Salary
```

Only affects:

* Future payroll calculations.

It does **not** modify:

* Previous payroll.
* Paid salaries.
* Historical reports.

---

# Position Update

Changing:

```text id="eep04"
Cashier

↓

Supervisor
```

Immediately updates:

* Employee Profile
* Employee List
* Future reports

Historical payroll remains unchanged.

---

# Phone Update

Updating the phone number affects:

* Employee profile.
* Future notifications.

No historical records are modified.

---

# Notes Update

Notes may be edited freely.

Example:

```text id="eep05"
Promoted

Transferred

Temporary Schedule

Night Shift
```

---

# Employment Status Update

Status options:

```text id="eep06"
Active

Suspended

Inactive

Deleted
```

Each status affects future employee operations only.

---

# Validation

Before saving:

Validate:

* Name entered.
* Salary greater than zero.
* Position valid.
* Phone format (if provided).

Reject invalid values.

---

# Edit Flow

```text id="eep07"
Open Employee

↓

Modify Information

↓

Validate

↓

Update Employee

↓

Refresh Employee List

↓

Refresh Dashboard

↓

Return
```

---

# Dashboard Update

Dashboard automatically refreshes:

* Employee Count
* Active Employees
* Suspended Employees

Reports update automatically.

---

# Reports Integration

Profile updates immediately affect:

* Employee Reports
* Dashboard Statistics

Future payroll uses the updated information.

Historical payroll remains unchanged.

---

# Attendance Integration

Editing profile information does **not** modify:

* Previous attendance.
* Previous absences.
* Previous check-in records.

Attendance history remains immutable.

---

# Payroll Integration

Salary changes affect:

Future salary periods only.

Already-paid salaries remain unchanged.

This guarantees financial audit integrity.

---


# Synchronization

Synchronization uploads:

* Updated Employee Profile
* Updated Salary
* Updated Status

Business timestamp:

```text id="eep09"
createdAt
```

is preserved.

---

# Duplicate Protection

While updating:

* Disable Save button.
* Ignore repeated taps.
* Prevent duplicate updates.

---

# Error Handling

Examples:

```text id="eep10"
Invalid Salary

Invalid Phone Number

Unable to Update

Network Error
```

Previous data remains unchanged if the update fails.

---

# Loading State

During update:

* Disable all inputs.
* Display loading indicator.
* Prevent duplicate submissions.

---

# Security

Only users with Employee Management permission may edit employees.

Requirements:

* Authenticated account.
* Active subscription.
* Authorized workspace.

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

No hardcoded labels or validation messages.

---

# Business Rules

* Employee ID is immutable.
* createdAt is immutable.
* Salary updates affect future payroll only.
* Historical payroll is never modified.
* Attendance history is never modified.
* Reports refresh automatically.
* Dashboard refreshes automatically.
* Offline editing behaves identically.
* Synchronization preserves historical integrity.
* UI never performs payroll calculations.

---

# Architecture

```text id="eep11"
Edit Employee Screen

↓

EmployeesCubit

↓

UpdateEmployeeUseCase

↓

Repository

↓

Employee Profile

↓

Reports

↓

Dashboard

↓

Updated UI
```

---

# End of Section

Next Section:

**8.5 Suspend / Disable Employee**

This section documents the complete employee status management workflow, including suspension, disabling, reactivation, attendance restrictions, payroll behavior, synchronization, business rules, and security validations governing employee availability.
# PART 8 — Employee Management

# 8.5 Suspend / Disable Employee

## Overview

The **Suspend / Disable Employee** feature allows administrators to temporarily or permanently prevent an employee from participating in daily operations without necessarily deleting their profile.

This preserves historical information while controlling future employee activity.

Employee status directly affects:

* Attendance
* Check-In
* Check-Out
* Payroll
* Dashboard Statistics
* Reports

Historical records always remain intact.

---

# Objectives

The feature allows administrators to:

* Suspend employees temporarily.
* Disable employees permanently without deletion.
* Reactivate employees.
* Preserve employment history.
* Prevent unauthorized attendance.

---

# Supported Statuses

Employee status values:

```text id="es01"
Active

Suspended

Inactive

Deleted
```

Each status controls employee behavior throughout the application.

---

# Active

Meaning:

```text id="es02"
Employee may:

✔ Check In

✔ Check Out

✔ Receive Salary

✔ Appear in Attendance

✔ Participate in Reports
```

This is the default status after employee creation.

---

# Suspended

Meaning:

```text id="es03"
Employee Profile Exists

❌ Cannot Check In

❌ Cannot Check Out

❌ Cannot Start New Attendance

✔ Historical Records Preserved
```

Used for temporary administrative actions.

Examples:

* Vacation without payroll.
* Investigation.
* Temporary suspension.

---

# Inactive

Meaning:

```text id="es04"
Employee No Longer Works

✔ Historical Data Preserved

❌ Attendance Disabled

❌ Future Payroll Disabled
```

Used when an employee permanently leaves the company but records must remain.

---

# Deleted

Meaning:

```text id="es05"
Employee Removed

OR

Soft Deleted

Depending on application configuration.
```

Future recommendation:

Prefer soft deletion for payroll auditing.

---

# Status Change Flow

```text id="es06"
Employee Details

↓

Change Status

↓

Confirmation

↓

Update Status

↓

Refresh Dashboard

↓

Refresh Reports
```

---

# Suspension Confirmation

Display:

```text id="es07"
Suspend Employee?

The employee will not be able to check in until reactivated.

[Cancel]

[Suspend]
```

---

# Disable Confirmation

Display:

```text id="es08"
Disable Employee?

Future attendance and payroll will stop.

Historical records will remain.

[Cancel]

[Disable]
```

---

# Reactivation

Suspended or inactive employees may return to:

```text id="es09"
Active
```

After activation:

* Attendance enabled.
* Payroll resumes.
* Employee appears normally throughout the application.

Historical records remain unchanged.

---

# Attendance Integration

Status directly affects attendance.

Rules:

Active

↓

Attendance Allowed

---

Suspended

↓

Attendance Blocked

---

Inactive

↓

Attendance Blocked

---

Deleted

↓

Attendance Not Available

---

# Payroll Integration

Status affects future payroll.

Rules:

Active

↓

Salary Calculated

---

Suspended

↓

Configurable

Current recommendation:

Do not generate payroll while suspended.

---

Inactive

↓

No future payroll.

Historical payroll remains.

---

Deleted

↓

No future payroll.

---

# Dashboard Integration

Dashboard statistics update immediately.

Examples:

* Active Employees
* Suspended Employees
* Inactive Employees

No manual refresh required.

---

# Reports Integration

Historical reports remain unchanged.

Future reports respect the employee's current status.

Attendance reports exclude inactive employees from future attendance calculations.

---

# Notifications

Future versions may notify:

* Employee suspended.
* Employee reactivated.
* Employee disabled.

Current implementation does not send notifications.

---


# Synchronization

Synchronization uploads:

* Employee Status

Historical timestamps remain unchanged.

Business timestamp:

```text id="es11"
createdAt
```

is preserved.

---

# Duplicate Protection

While updating:

* Disable action buttons.
* Ignore repeated taps.
* Prevent duplicate status changes.

---

# Error Handling

Examples:

```text id="es12"
Unable to Update Status

Network Error

Try Again
```

Previous status remains active if update fails.

---

# Security

Only authorized users may:

* Suspend Employees
* Disable Employees
* Reactivate Employees

Required:

* Authenticated account.
* Active subscription.
* Employee Management permission.

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

No hardcoded status labels.

---

# Business Rules

* Active employees may attend work.
* Suspended employees cannot attend.
* Inactive employees cannot attend.
* Deleted employees cannot participate.
* Historical attendance is never modified.
* Historical payroll is never modified.
* Future payroll depends on current status.
* Dashboard refreshes automatically.
* Reports refresh automatically.
* Offline status changes behave identically.
* Synchronization preserves historical integrity.

---

# Architecture

```text id="es13"
Employee Details

↓

EmployeesCubit

↓

UpdateEmployeeStatusUseCase

↓

Repository

↓

Employee Profile

↓

Attendance Engine

↓

Payroll Engine

↓

Reports

↓

Dashboard

↓

Updated UI
```

---

# End of Section

Next Section:

**8.6 Attendance System**

This section documents the complete Attendance module, including Check-In, Check-Out, attendance validation, absence handling, late arrivals, attendance history, offline support, synchronization, payroll integration, and all business rules governing employee attendance.
# PART 8 — Employee Management

# 8.6 Attendance System

## Overview

The **Attendance System** records every employee's working day.

It is the primary source of information used by the Payroll Engine to determine:

* Worked Days
* Absent Days
* Excused Absences
* Attendance Percentage
* Salary Eligibility

Every attendance record is independent and immutable once completed.

Future corrections should be handled through dedicated administrative adjustments rather than modifying historical records.

---

# Objectives

The Attendance System allows businesses to:

* Record daily attendance.
* Monitor employee presence.
* Track absences.
* Calculate working days.
* Support payroll calculations.
* Produce attendance reports.

---

# Attendance Lifecycle

Every working day follows:

```text id="att01"
Employee Active

↓

Check In

↓

Working

↓

Check Out

↓

Attendance Record Closed
```

---

# Attendance Record

Each attendance record contains:

* Attendance ID
* Employee ID
* Check-In Time
* Check-Out Time
* Attendance Date
* Attendance Status
* createdAt

Future fields:

* Shift ID
* Device ID
* GPS Location
* Notes

---

# Attendance Status

Supported statuses:

```text id="att02"
Present

Absent

Excused Absence
```

Future:

* Late
* Half Day
* Vacation
* Sick Leave

---

# Daily Rule

Each employee may have:

```text id="att03"
One Attendance Record

Per Day
```

Duplicate attendance records are prohibited.

---

# Check-In

Check-In marks the beginning of a workday.

After successful check-in:

Store:

* Employee
* Check-In Time
* Date

Status becomes:

```text id="att04"
Present
```

---

# Check-Out

Check-Out completes the attendance record.

Store:

* Check-Out Time

Attendance record becomes final.

Future:

Working hours calculation.

---

# Validation

Before Check-In:

Validate:

* Employee is Active.
* Employee is not Suspended.
* Employee is not Inactive.
* Employee has not already checked in today.

Reject invalid requests.

---

# Duplicate Check-In Protection

If today's attendance already exists:

Reject:

```text id="att05"
Already Checked In Today
```

No duplicate attendance is created.

---

# Missing Check-Out

Future implementation:

Automatically detect:

```text id="att06"
Checked In

↓

No Check-Out
```

Allow administrator review.

Current implementation keeps the record open until checkout.

---

# Attendance History

Attendance history is immutable.

Editing historical attendance is discouraged.

Future corrections should create adjustment records.

---

# Payroll Integration

Attendance directly affects:

* Worked Days
* Missing Days
* Salary Calculation

Attendance is one of the Payroll Engine's primary inputs.

---

# Dashboard Integration

Dashboard displays:

* Present Employees
* Absent Employees
* Attendance Rate

Automatically refreshed.

---

# Reports Integration

Attendance contributes to:

* Daily Attendance Report
* Monthly Attendance Report
* Payroll Reports

Future:

* Productivity Reports
* Shift Reports

---


# Synchronization

Synchronization uploads:

* Attendance Records

Business timestamp:

```text id="att08"
createdAt
```

is preserved.

Attendance chronology never changes.

---

# Timestamp Rule

Attendance reports always use:

```text id="att09"
createdAt
```

Never:

* syncedAt
* uploadedAt
* serverTimestamp

---

# Performance

Optimizations:

* Daily attendance lookup.
* Incremental Cubit updates.
* Cached employee list.
* Efficient report refresh.

Supports very large employee counts.

---

# Security

Attendance requires:

* Active employee.
* Authenticated administrator (if managed manually).
* Authorized workspace.

Future:

Employee self check-in.

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

No hardcoded attendance labels.

---

# Business Rules

* One attendance record per employee per day.
* Duplicate check-in is prohibited.
* Suspended employees cannot check in.
* Inactive employees cannot check in.
* Deleted employees cannot check in.
* Attendance records are immutable after completion.
* Attendance contributes directly to payroll.

* Synchronization preserves historical records.
* createdAt defines attendance chronology.

---

# Architecture

```text id="att10"
Attendance Screen

↓

AttendanceCubit

↓

CheckInUseCase

CheckOutUseCase

↓

Repository

↓

Attendance Record

↓

Payroll Engine

↓

Reports

↓

Dashboard
```

---

# End of Section

Next Section:

**8.7 Check-In**

This section documents the complete Check-In workflow, including validation, duplicate prevention, business rules, offline support, synchronization, and attendance initialization.
# PART 8 — Employee Management

# 8.7 Check-In

## Overview

The **Check-In** feature records the beginning of an employee's working day.

It creates a new attendance record that is later completed by the Check-Out operation.

Check-In is one of the core inputs used by the Payroll Engine to determine worked days and salary eligibility.

---

# Objectives

The Check-In feature allows businesses to:

* Record employee arrival.
* Prevent duplicate attendance.
* Calculate worked days.
* Track attendance history.
* Feed payroll calculations.

---

# Entry Point

Users access Check-In from:

```text id="ci01"
Employees

↓

Attendance

↓

Check-In
```

---

# Check-In Flow

```text id="ci02"
Select Employee

↓

Validate Employee

↓

Validate Today's Attendance

↓

Create Attendance Record

↓

Update Dashboard

↓

Refresh Reports
```

---

# Validation Rules

Before allowing Check-In, the system validates:

* Employee exists.
* Employee status is **Active**.
* Employee has not already checked in today.
* Internet connection is available.
* Firestore request succeeds.

If any validation fails, Check-In is rejected.

---

# Attendance Record

A successful Check-In creates:

* Attendance ID
* Employee ID
* Attendance Date
* Check-In Time
* Status = Present
* createdAt

Check-Out remains empty until the employee finishes work.

---

# Duplicate Prevention

Each employee may perform:

```text id="ci03"
One Check-In

Per Day
```

If today's attendance already exists:

Display:

```text id="ci04"
Employee has already checked in today.
```

No duplicate record is created.

---

# Dashboard Update

Successful Check-In immediately updates:

* Present Employees
* Attendance Percentage
* Today's Attendance

Dashboard refreshes automatically.

---

# Reports Integration

Check-In immediately appears in:

* Daily Attendance Report
* Monthly Attendance Report
* Payroll Preparation

---

# Internet Requirement

Employee attendance requires an active internet connection.

If no internet connection exists:

```text id="ci05"
Unable to Check In.

Please connect to the internet and try again.
```

No attendance record is created locally.

---

# Synchronization

Not Applicable.

The Employee module does **not** support offline synchronization.

Every attendance record is written directly to Firestore.

---

# Error Handling

Examples:

```text id="ci06"
Employee Not Found

Employee Suspended

Already Checked In

Network Error

Unable to Save Attendance
```

No partial attendance record is created.

---

# Loading State

During Check-In:

* Disable action buttons.
* Show loading indicator.
* Prevent duplicate requests.

---

# Security

Only employees with:

* Active Status
* Valid Workspace
* Authorized Account

may perform Check-In.

Suspended, inactive, and deleted employees are always rejected.

---

# Performance

Optimizations:

* Single Firestore write.
* Minimal document reads.
* Efficient Cubit state updates.
* Automatic dashboard refresh.

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

---

# Business Rules

* One Check-In per employee per day.
* Check-In always precedes Check-Out.
* Duplicate Check-In is prohibited.
* Attendance is written directly to Firestore.
* Offline attendance is **not supported**.
* createdAt is the official business timestamp.
* Dashboard refreshes immediately.
* Reports update immediately.
* Attendance records are immutable after creation except for Check-Out completion.

---

# Architecture

```text id="ci07"
Attendance Screen

↓

AttendanceCubit

↓

CheckInUseCase

↓

Repository

↓

Firestore

↓

Attendance Record

↓

Reports

↓

Dashboard
```

---

# End of Section

Next Section:

**8.8 Check-Out**

This section documents the complete Check-Out workflow, including attendance completion, validation, worked time calculation, payroll integration, and all business rules governing the end of an employee's working day.
# PART 8 — Employee Management

# 8.8 Check-Out

## Overview

The **Check-Out** feature marks the end of an employee's working day by completing an existing attendance record.

Unlike Check-In, Check-Out does **not** create a new attendance record.

Instead, it updates the attendance record created earlier during Check-In by adding the employee's departure time.

After Check-Out is completed, the attendance record is considered finalized.

---

# Objectives

The Check-Out feature allows businesses to:

* Record employee departure.
* Complete the attendance record.
* Calculate worked hours.
* Prepare payroll calculations.
* Improve attendance reporting.

---

# Entry Point

Users access Check-Out from:

```text id="co01"
Employees

↓

Attendance

↓

Check-Out
```

---

# Check-Out Flow

```text id="co02"
Select Employee

↓

Locate Today's Attendance

↓

Validate Record

↓

Update Check-Out Time

↓

Finalize Attendance

↓

Refresh Reports

↓

Refresh Dashboard
```

---

# Validation Rules

Before Check-Out:

Validate:

* Employee exists.
* Employee is Active.
* Today's attendance exists.
* Employee has already checked in.
* Employee has not already checked out.
* Internet connection is available.
* Firestore update succeeds.

If validation fails, Check-Out is rejected.

---

# Attendance Update

A successful Check-Out updates:

* Check-Out Time
* Attendance Status (Completed)

The existing attendance document remains the same.

No additional attendance record is created.

---

# Duplicate Prevention

Each attendance record supports:

```text id="co03"
One Check-Out Only
```

If Check-Out already exists:

Display:

```text id="co04"
Employee has already checked out today.
```

---

# Missing Check-In

If today's attendance record does not exist:

Reject Check-Out.

Display:

```text id="co05"
Employee has not checked in today.
```

The system never creates attendance during Check-Out.

---

# Worked Hours

Current implementation:

Store:

* Check-In Time
* Check-Out Time

Future versions may calculate:

```text id="co06"
Worked Hours

=

Check-Out

-

Check-In
```

Worked hours will later support:

* Overtime
* Late arrival
* Early leave
* Hourly payroll

---

# Payroll Integration

Completed attendance becomes available to the Payroll Engine.

Payroll may later calculate:

* Worked Days
* Worked Hours
* Overtime
* Salary Adjustments

No salary calculation occurs during Check-Out itself.

---

# Dashboard Update

Successful Check-Out updates:

* Completed Attendance
* Employees Currently Working (future)
* Daily Attendance Summary

Dashboard refreshes automatically.

---

# Reports Integration

Check-Out updates:

* Daily Attendance Report
* Monthly Attendance Report
* Payroll Reports

Historical attendance remains immutable after completion.

---

# Internet Requirement

Employee attendance requires an active internet connection.

If internet is unavailable:

```text id="co07"
Unable to Check Out.

Please connect to the internet and try again.
```

No local update is performed.

---

# Synchronization

Not applicable.

Employee Management does not support offline synchronization.

Attendance records are updated directly in Firestore.

---

# Error Handling

Examples:

```text id="co08"
Employee Not Found

No Check-In Found

Already Checked Out

Network Error

Unable to Update Attendance
```

Attendance remains unchanged if the update fails.

---

# Loading State

During Check-Out:

* Disable action buttons.
* Show loading indicator.
* Prevent duplicate requests.

---

# Security

Only:

* Active Employees
* Authorized Users
* Valid Workspace Members

may perform Check-Out.

Suspended, inactive, or deleted employees cannot complete attendance.

---

# Performance

Optimizations:

* Single Firestore update.
* Minimal document reads.
* Incremental Cubit refresh.
* Automatic report updates.

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

---

# Business Rules

* Check-Out always requires an existing Check-In.
* Only one Check-Out is allowed per attendance record.
* Check-Out completes the attendance record.
* No new attendance record is created.
* Attendance is updated directly in Firestore.
* Offline attendance is **not supported**.
* Payroll consumes completed attendance records.
* Dashboard refreshes automatically.
* Reports refresh immediately.
* Historical attendance remains immutable after completion.

---

# Architecture

```text id="co09"
Attendance Screen

↓

AttendanceCubit

↓

CheckOutUseCase

↓

Repository

↓

Firestore

↓

Attendance Record

↓

Payroll Engine

↓

Reports

↓

Dashboard
```

---

# End of Section

Next Section:

**8.9 Attendance Reports**

This section documents the complete attendance reporting system, including daily reports, monthly reports, absence statistics, attendance KPIs, payroll integration, dashboard metrics, filtering, and all business rules governing attendance analytics.
# PART 8 — Employee Management

# 8.9 Attendance Reports

## Overview

The **Attendance Reports** module provides a complete overview of employee attendance performance.

Its primary purpose is to help business owners monitor workforce availability, attendance consistency, and payroll readiness.

Attendance reports are generated dynamically from attendance records.

No attendance statistics are permanently stored.

---

# Objectives

Attendance Reports allow businesses to:

* Monitor daily attendance.
* Track employee absences.
* Analyze attendance trends.
* Prepare payroll calculations.
* Evaluate workforce performance.

---

# Data Source

Attendance reports always calculate from:

```text id="ar01"
Attendance Records
```

Reports never calculate from:

* Dashboard totals
* Cached statistics
* Payroll summaries

Attendance records remain the only source of truth.

---

# Daily Attendance Report

Displays:

* Total Employees
* Present Employees
* Absent Employees
* Excused Absences
* Attendance Percentage

Grouping:

```text id="ar02"
createdAt

↓

Day
```

---

# Monthly Attendance Report

Displays:

For every employee:

* Working Days
* Present Days
* Absent Days
* Excused Absence Days
* Attendance Percentage

Grouping:

```text id="ar03"
createdAt

↓

Month + Year
```

---

# Employee Attendance Report

Displays attendance history for one employee.

Includes:

* Date
* Check-In
* Check-Out
* Attendance Status

Future:

* Worked Hours
* Overtime
* Late Arrival

---

# Attendance Percentage

Formula:

```text id="ar04"
Attendance %

=

Present Days

÷

Expected Working Days

×

100
```

This value is calculated dynamically.

---

# Absent Employees Report

Displays employees who did not attend.

Includes:

* Employee Name
* Date
* Status

Future:

* Consecutive Absence Detection
* Automatic Alerts

---

# Excused Absence Report

Displays employees marked as:

```text id="ar05"
Excused Absence
```

Future integration:

* Leave Requests
* Medical Leave
* Vacation Management

---

# Dashboard Integration

Dashboard automatically updates:

* Present Employees
* Absent Employees
* Attendance Percentage

All values are calculated from attendance records.

---

# Payroll Integration

Attendance reports directly support payroll.

Payroll consumes:

* Present Days
* Absent Days
* Excused Absences

Salary calculations depend on these values.

---

# Report Refresh

Attendance reports automatically refresh after:

* Check-In
* Check-Out
* Attendance Adjustment (future)

Manual refresh is unnecessary.

---

# Timestamp Rule

Attendance reports always use:

```text id="ar06"
createdAt
```

Never:

```text id="ar07"
syncedAt

uploadedAt

serverTimestamp
```

Business chronology is always preserved.

---

# Filtering

Current filters:

* Employee
* Date Range
* Attendance Status

Future:

* Position
* Department
* Branch

---

# Sorting

Supported sorting:

* Newest First
* Oldest First
* Employee Name

Future:

* Highest Attendance
* Lowest Attendance

---

# Empty Report

If no attendance exists:

Display:

```text id="ar08"
No Attendance Records Found
```

Localized using ARB.

---

# Internet Requirement

Attendance reports require an active internet connection because the Employee module operates online only.

If data cannot be loaded:

Display:

```text id="ar09"
Unable to load attendance reports.

Please check your internet connection.
```

---

# Performance

Optimizations:

* Paginated attendance queries.
* Incremental Cubit updates.
* Efficient Firestore reads.
* Lazy report generation.

Supports:

* Thousands of employees.
* Millions of attendance records.

---

# Security

Attendance reports require:

* Authenticated account.
* Active subscription.
* Authorized workspace.

Future:

Role-based report permissions.

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

---

# Business Rules

* Reports always calculate dynamically.
* Attendance records are the only source of truth.
* Payroll consumes attendance reports.
* Dashboard consumes attendance reports.
* createdAt defines report chronology.
* Historical attendance is immutable.
* Employee Management does **not** support offline mode.
* Reports are generated directly from Firestore.
* Report refresh occurs automatically after attendance updates.

---

# Architecture

```text id="ar10"
Attendance Records

↓

Attendance Report Engine

↓

Daily Reports

↓

Monthly Reports

↓

Employee Reports

↓

Payroll

↓

Dashboard

↓

Updated UI
```

---

# End of Section

Next Section:

**8.10 Absence Management**

This section documents the complete absence management system, including absent employees, excused absences, validation rules, payroll impact, reporting, dashboard integration, and all business rules governing employee absences.
# PART 8 — Employee Management

# 8.9 Attendance Reports

## Overview

The **Attendance Reports** module provides a complete overview of employee attendance performance.

Its primary purpose is to help business owners monitor workforce availability, attendance consistency, and payroll readiness.

Attendance reports are generated dynamically from attendance records.

No attendance statistics are permanently stored.

---

# Objectives

Attendance Reports allow businesses to:

* Monitor daily attendance.
* Track employee absences.
* Analyze attendance trends.
* Prepare payroll calculations.
* Evaluate workforce performance.

---

# Data Source

Attendance reports always calculate from:

```text id="ar01"
Attendance Records
```

Reports never calculate from:

* Dashboard totals
* Cached statistics
* Payroll summaries

Attendance records remain the only source of truth.

---

# Daily Attendance Report

Displays:

* Total Employees
* Present Employees
* Absent Employees
* Excused Absences
* Attendance Percentage

Grouping:

```text id="ar02"
createdAt

↓

Day
```

---

# Monthly Attendance Report

Displays:

For every employee:

* Working Days
* Present Days
* Absent Days
* Excused Absence Days
* Attendance Percentage

Grouping:

```text id="ar03"
createdAt

↓

Month + Year
```

---

# Employee Attendance Report

Displays attendance history for one employee.

Includes:

* Date
* Check-In
* Check-Out
* Attendance Status

Future:

* Worked Hours
* Overtime
* Late Arrival

---

# Attendance Percentage

Formula:

```text id="ar04"
Attendance %

=

Present Days

÷

Expected Working Days

×

100
```

This value is calculated dynamically.

---

# Absent Employees Report

Displays employees who did not attend.

Includes:

* Employee Name
* Date
* Status

Future:

* Consecutive Absence Detection
* Automatic Alerts

---

# Excused Absence Report

Displays employees marked as:

```text id="ar05"
Excused Absence
```

Future integration:

* Leave Requests
* Medical Leave
* Vacation Management

---

# Dashboard Integration

Dashboard automatically updates:

* Present Employees
* Absent Employees
* Attendance Percentage

All values are calculated from attendance records.

---

# Payroll Integration

Attendance reports directly support payroll.

Payroll consumes:

* Present Days
* Absent Days
* Excused Absences

Salary calculations depend on these values.

---

# Report Refresh

Attendance reports automatically refresh after:

* Check-In
* Check-Out
* Attendance Adjustment (future)

Manual refresh is unnecessary.

---

# Timestamp Rule

Attendance reports always use:

```text id="ar06"
createdAt
```

Never:

```text id="ar07"
syncedAt

uploadedAt

serverTimestamp
```

Business chronology is always preserved.

---

# Filtering

Current filters:

* Employee
* Date Range
* Attendance Status

Future:

* Position
* Department
* Branch

---

# Sorting

Supported sorting:

* Newest First
* Oldest First
* Employee Name

Future:

* Highest Attendance
* Lowest Attendance

---

# Empty Report

If no attendance exists:

Display:

```text id="ar08"
No Attendance Records Found
```

Localized using ARB.

---

# Internet Requirement

Attendance reports require an active internet connection because the Employee module operates online only.

If data cannot be loaded:

Display:

```text id="ar09"
Unable to load attendance reports.

Please check your internet connection.
```

---

# Performance

Optimizations:

* Paginated attendance queries.
* Incremental Cubit updates.
* Efficient Firestore reads.
* Lazy report generation.

Supports:

* Thousands of employees.
* Millions of attendance records.

---

# Security

Attendance reports require:

* Authenticated account.
* Active subscription.
* Authorized workspace.

Future:

Role-based report permissions.

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

---

# Business Rules

* Reports always calculate dynamically.
* Attendance records are the only source of truth.
* Payroll consumes attendance reports.
* Dashboard consumes attendance reports.
* createdAt defines report chronology.
* Historical attendance is immutable.
* Employee Management does **not** support offline mode.
* Reports are generated directly from Firestore.
* Report refresh occurs automatically after attendance updates.

---

# Architecture

```text id="ar10"
Attendance Records

↓

Attendance Report Engine

↓

Daily Reports

↓

Monthly Reports

↓

Employee Reports

↓

Payroll

↓

Dashboard

↓

Updated UI
```

---

# End of Section

Next Section:

**8.10 Absence Management**

This section documents the complete absence management system, including absent employees, excused absences, validation rules, payroll impact, reporting, dashboard integration, and all business rules governing employee absences.
# PART 8 — Employee Management

# 8.10 Absence Management

## Overview

The **Absence Management** module tracks employees who do not attend work during scheduled working days.

It is responsible for distinguishing between:

* Unexcused Absence
* Excused Absence

This module provides the Payroll Engine with the information required to calculate salary deductions according to the business rules configured by the organization.

Absence management does not create financial transactions directly.

Its purpose is to provide accurate attendance data that payroll later consumes.

---

# Objectives

The Absence Management module allows businesses to:

* Identify absent employees.
* Record excused absences.
* Calculate attendance statistics.
* Prepare payroll deductions.
* Improve workforce monitoring.

---

# Absence Types

Current supported types:

```text id="am01"
Absent

Excused Absence
```

Future types:

* Sick Leave
* Annual Leave
* Official Holiday
* Emergency Leave
* Unpaid Leave
* Half-Day Leave

---

# Unexcused Absence

Meaning:

The employee was expected to work but did not attend.

Characteristics:

* No Check-In.
* No Check-Out.
* No approved excuse.

Future payroll may deduct salary according to company policy.

---

# Excused Absence

Meaning:

The employee was authorized to be absent.

Examples:

* Medical appointment.
* Personal emergency.
* Approved leave.

Payroll treatment depends on business configuration.

---

# Daily Validation

At the end of each working day:

The system identifies employees who:

* Are Active.
* Were expected to work.
* Have no attendance record.

These employees may later be classified as absent.

> **Note:** The current implementation does not perform automatic end-of-day processing. Absences are determined according to the application's existing attendance workflow and business rules.

---

# Attendance Relationship

Attendance determines absence.

Rules:

Attendance Exists

↓

Employee Present

---

Attendance Missing

↓

Employee May Be Absent

No separate attendance record is created automatically for absent employees.

---

# Payroll Integration

Absence information becomes available to:

* Payroll Engine
* Salary Calculation
* Attendance Reports

Future payroll may apply:

* Daily deductions.
* Attendance bonuses.
* Performance incentives.

---

# Dashboard Integration

Dashboard displays:

* Present Employees
* Absent Employees
* Attendance Percentage

Statistics update automatically after attendance changes.

---

# Reports Integration

Absence data contributes to:

* Daily Attendance Reports
* Monthly Attendance Reports
* Payroll Reports

Future:

* Employee Performance Reports
* HR Analytics

---

# Manual Absence Registration

Administrators may manually classify an employee as:

```text id="am02"
Excused Absence
```

when business policy requires it.

The attendance history remains internally consistent.

---

# Validation Rules

Before registering an excused absence:

Validate:

* Employee exists.
* Employee is Active.
* Employee does not already have attendance for the selected day.
* Internet connection is available.

Reject invalid requests.

---

# Internet Requirement

Employee Management is online only.

If internet is unavailable:

```text id="am03"
Unable to update absence information.

Please check your internet connection.
```

No local data is stored.

---

# Error Handling

Examples:

```text id="am04"
Employee Not Found

Attendance Already Exists

Unable to Save

Network Error
```

No partial updates occur.

---

# Performance

Optimizations:

* Efficient Firestore queries.
* Incremental Cubit updates.
* Report refresh only when necessary.

Supports organizations with large employee counts.

---

# Security

Only authorized users may:

* Register excused absences.
* Modify absence status.
* Review absence reports.

Requirements:

* Authenticated account.
* Active subscription.
* Employee Management permission.

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

---

# Business Rules

* Every absence belongs to one employee.
* Attendance always has priority over absence classification.
* Excused absences require administrative action.
* Payroll consumes absence information.
* Dashboard updates automatically.
* Reports update automatically.
* Employee Management does **not** support offline mode.
* All absence operations communicate directly with Firestore.
* Historical attendance records are never modified.

---

# Architecture

```text id="am05"
Attendance Records

↓

Absence Validation

↓

AttendanceCubit

↓

AbsenceUseCase

↓

Repository

↓

Firestore

↓

Attendance Reports

↓

Payroll Engine

↓

Dashboard
```

---

# End of Section

Next Section:

**8.11 Payroll Engine**

This section documents the complete payroll calculation engine, including salary computation, worked days, absence deductions, future bonuses and overtime support, payroll generation, payment history, financial integration with the Expenses module, and all business rules governing employee salaries.
# PART 8 — Employee Management

# 8.11 Payroll Engine

## Overview

The **Payroll Engine** is responsible for calculating employee salaries based on attendance records and business rules.

It is the financial core of the Employee Management module.

The Payroll Engine does **not** rely on manually entered salary values after employee creation.

Instead, salaries are calculated dynamically using:

* Employee Profile
* Salary Configuration
* Attendance Records
* Absence Records
* Payroll Rules

Future versions will also support:

* Overtime
* Bonuses
* Commissions
* Penalties

---

# Objectives

The Payroll Engine allows businesses to:

* Calculate monthly salaries.
* Apply attendance rules.
* Process payroll.
* Generate salary history.
* Feed financial reports.

---

# Source of Truth

Payroll calculations depend on:

```text id="pe01"
Employee Profile

+

Attendance Records

+

Payroll Rules
```

Never calculate from:

* Dashboard values
* Cached payroll totals
* Previous salary payments

---

# Payroll Lifecycle

Every payroll period follows:

```text id="pe02"
Employee

↓

Attendance Collection

↓

Salary Calculation

↓

Payroll Review

↓

Pay Salary

↓

Payroll History
```

---

# Payroll Inputs

The engine consumes:

* Monthly Salary
* Attendance Days
* Absent Days
* Excused Absence Days

Future:

* Overtime Hours
* Bonuses
* Advances
* Penalties

---

# Payroll Output

The engine produces:

* Expected Salary
* Deductions
* Final Salary

Future:

* Tax
* Insurance
* Net Salary

---

# Salary Period

Current implementation:

```text id="pe03"
Monthly Payroll
```

Future support:

* Weekly Payroll
* Biweekly Payroll
* Custom Payroll Cycle

---

# Payroll Generation

Payroll is generated for one employee at a time.

Future versions may support:

```text id="pe04"
Generate Payroll

↓

All Employees
```

---

# Attendance Dependency

Payroll depends on attendance.

Example:

```text id="pe05"
Attendance

↓

Worked Days

↓

Salary Calculation
```

If attendance changes before payroll is finalized, salary calculations are updated automatically.

---

# Expense Integration

After salary payment:

A new expense is created automatically.

Category:

```text id="pe06"
Salary
```

This updates:

* Expenses Module
* Dashboard
* Financial Reports

No duplicate expense is created.

---

# Dashboard Integration

Dashboard displays:

* Monthly Payroll
* Payroll Paid
* Outstanding Payroll (future)

Statistics refresh automatically.

---

# Reports Integration

Payroll contributes to:

* Salary Reports
* Expense Reports
* Financial Reports

Future:

* Payroll Analytics
* Department Payroll Reports

---

# Internet Requirement

Payroll processing requires an active internet connection.

If connectivity is unavailable:

```text id="pe07"
Unable to process payroll.

Please check your internet connection.
```

Payroll is never generated locally.

---

# Validation

Before payroll generation:

Validate:

* Employee exists.
* Employee is Active.
* Salary configured.
* Attendance available.
* Payroll not already processed for the selected period.

Reject invalid payroll requests.

---

# Duplicate Payroll Protection

Each employee may receive:

```text id="pe08"
One Payroll

Per Payroll Period
```

Duplicate payroll generation is prohibited.

---

# Error Handling

Examples:

```text id="pe09"
Salary Not Configured

Payroll Already Generated

Attendance Missing

Network Error
```

No payroll record is created if validation fails.

---

# Performance

Optimizations:

* Efficient attendance aggregation.
* Incremental payroll calculation.
* Minimal Firestore reads.
* Automatic dashboard refresh.

Supports organizations with large employee counts.

---

# Security

Payroll requires:

* Authenticated account.
* Active subscription.
* Payroll management permission.

Future permissions:

* HR
* Accountant
* Owner

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

---

# Business Rules

* Payroll is calculated dynamically.
* Attendance is the primary payroll input.
* Employee profile provides salary configuration.
* Salary payment automatically creates an expense.
* One payroll per employee per payroll period.
* Employee Management does **not** support offline mode.
* Payroll communicates directly with Firestore.
* Dashboard refreshes automatically.
* Reports refresh automatically after payroll generation.

---

# Architecture

```text id="pe10"
Employee Profile

+

Attendance Records

↓

Payroll Engine

↓

Payroll Record

↓

Salary Payment

↓

Expenses Module

↓

Reports

↓

Dashboard
```

---

# End of Section

Next Section:

**8.12 Salary Calculation**

This section documents the complete salary calculation process, including expected working days, attendance deductions, excused absences, advances, future overtime and bonus support, formulas, validations, and all business rules governing salary computation.
# PART 8 — Employee Management

# 8.12 Salary Calculation

## Overview

The **Salary Calculation** module determines the amount an employee should receive for a payroll period.

It is responsible only for calculating the salary.

It does **not**:

* Pay the salary.
* Create expense records.
* Generate payroll history.

Those responsibilities belong to the Payroll Engine.

Salary calculation is deterministic.

The same inputs always produce the same result.

---

# Objectives

The Salary Calculation module:

* Calculates employee salary.
* Applies attendance rules.
* Applies business deductions.
* Produces the payable salary.
* Provides the Payroll Engine with the final calculated value.

---

# Source of Truth

Salary calculation always depends on:

```text id="sc01"
Employee Profile

+

Attendance Records

+

Payroll Configuration
```

Never calculate using:

* Cached salary.
* Dashboard values.
* Previous payroll records.

---

# Required Inputs

Current inputs:

* Monthly Salary
* Attendance Records
* Working Days

Future:

* Overtime
* Bonuses
* Commissions
* Penalties
* Advances
* Taxes
* Insurance

---

# Monthly Salary

Each employee has:

```text id="sc02"
Base Monthly Salary
```

configured in the Employee Profile.

Example:

```text id="sc03"
8,000 EGP
```

---

# Working Days

Every payroll period has:

```text id="sc04"
Expected Working Days
```

configured according to business policy.

Example:

```text id="sc05"
26 Working Days
```

This value may differ between organizations.

---

# Present Days

Present Days are obtained from:

```text id="sc06"
Attendance Records
```

Only completed attendance records contribute to salary calculations.

---

# Absent Days

Absent Days are calculated from:

```text id="sc07"
Expected Working Days

-

Present Days
```

Future business policies may distinguish between paid and unpaid absences.

---

# Daily Salary

The daily salary is derived dynamically.

Formula:

```text id="sc08"
Daily Salary

=

Monthly Salary

÷

Expected Working Days
```

Example:

```text id="sc09"
Monthly Salary

=

6,000

Working Days

=

30

↓

Daily Salary

=

200
```

---

# Attendance Deduction

If attendance deductions are enabled:

Formula:

```text id="sc10"
Deduction

=

Daily Salary

×

Absent Days
```

The deduction is always derived.

It is never stored.

---

# Current Salary Formula

Current implementation:

```text id="sc11"
Final Salary

=

Monthly Salary

-

Attendance Deductions
```

Future versions will extend this formula.

---

# Future Formula

Future payroll may calculate:

```text id="sc12"
Final Salary

=

Base Salary

+

Overtime

+

Bonuses

+

Commissions

-

Advances

-

Penalties

-

Attendance Deductions

-

Taxes
```

The architecture is designed to support these additions without changing existing payroll history.

---

# Salary Preview

Before payroll generation, administrators may preview:

* Monthly Salary
* Attendance Days
* Absent Days
* Total Deduction
* Final Salary

No financial record is created during preview.

---

# Payroll Integration

Salary Calculation provides:

```text id="sc13"
Final Salary
```

to the Payroll Engine.

Payroll is responsible for:

* Recording payment.
* Creating payroll history.
* Creating salary expenses.

---

# Expense Integration

Salary Calculation itself never creates expenses.

Expenses are generated only after successful salary payment.

---

# Validation

Before calculating:

Validate:

* Employee exists.
* Employee is Active.
* Monthly Salary configured.
* Working Days greater than zero.
* Attendance available.

Reject invalid calculations.

---

# Internet Requirement

Salary calculation requires:

* Active internet connection.
* Live Firestore access.

Employee Management does **not** support offline calculations.

---

# Error Handling

Examples:

```text id="sc14"
Salary Not Configured

Attendance Missing

Working Days Invalid

Unable to Calculate Salary

Network Error
```

No partial payroll data is produced.

---

# Performance

Optimizations:

* Efficient attendance aggregation.
* Reusable calculation methods.
* Minimal Firestore reads.
* Calculation performed only when required.

Supports payroll for very large organizations.

---

# Security

Salary calculations require:

* Authenticated account.
* Active subscription.
* Payroll permission.

Unauthorized users cannot calculate employee salaries.

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

No hardcoded calculation labels.

---

# Business Rules

* Salary is always calculated dynamically.
* Attendance records determine worked days.
* Monthly salary comes from the employee profile.
* Daily salary is derived from monthly salary.
* Attendance deductions are derived.
* Final salary is never manually entered.
* Salary calculation never creates expenses.
* Employee Management does **not** support offline mode.
* Firestore is the only data source.
* The same inputs always produce the same salary.

---

# Architecture

```text id="sc15"
Employee Profile

+

Attendance Records

+

Payroll Configuration

↓

SalaryCalculationUseCase

↓

Final Salary

↓

Payroll Engine

↓

Salary Payment

↓

Expenses Module
```

---

# End of Section

Next Section:

**8.13 Salary Payment**

This section documents the complete salary payment workflow, including payroll confirmation, expense creation, payment history, validation, reporting, dashboard integration, and all business rules governing employee salary payments.
# PART 8 — Employee Management

# 8.13 Salary Payment

## Overview

The **Salary Payment** module is responsible for completing the payroll process by recording that an employee has been paid.

Unlike **Salary Calculation**, this feature performs a financial operation.

A successful salary payment:

* Creates a Payroll History record.
* Creates an Expense record.
* Updates Dashboard statistics.
* Updates Financial Reports.

Salary payment is considered a financial transaction.

---

# Objectives

The Salary Payment feature allows businesses to:

* Pay employee salaries.
* Record payment history.
* Generate salary expenses.
* Update financial reports.
* Maintain payroll audit history.

---

# Payment Lifecycle

Every payment follows:

```text id="sp01"
Salary Calculated

↓

Payroll Review

↓

Confirm Payment

↓

Create Payroll Record

↓

Create Expense

↓

Refresh Reports

↓

Dashboard Updated
```

---

# Payment Trigger

Salary payment is initiated from:

```text id="sp02"
Payroll Screen

↓

Employee Payroll

↓

Pay Salary
```

---

# Confirmation Dialog

Before payment:

Display:

```text id="sp03"
Pay Salary?

Employee:

Ahmed Ali

Amount:

7,850 EGP

[Cancel]

[Confirm]
```

Payment never occurs without confirmation.

---

# Payment Record

After confirmation:

Create a Payroll History record containing:

* Payroll ID
* Employee ID
* Payroll Period
* Paid Amount
* Payment Date
* createdAt

Future:

* Payment Method
* Reference Number
* Notes

---

# Expense Creation

Immediately after payment:

Automatically create:

```text id="sp04"
Expense

Category

Salary
```

This expense becomes part of:

* Expenses Module
* Financial Reports
* Dashboard Statistics

No manual expense entry is required.

---

# Financial Impact

Successful salary payment updates:

* Total Expenses
* Salary Expenses
* Monthly Expenses
* Cash Flow

All values refresh automatically.

---

# Dashboard Update

Dashboard automatically updates:

* Payroll Paid
* Monthly Expenses
* Total Expenses

No manual refresh.

---

# Reports Integration

Salary payment contributes to:

* Payroll Reports
* Expense Reports
* Monthly Financial Reports

Future:

* Salary Trend Reports
* Payroll Analytics

---

# Duplicate Payment Protection

Each payroll period supports:

```text id="sp05"
One Salary Payment

Per Employee
```

If already paid:

Reject the operation.

Display:

```text id="sp06"
Salary Already Paid
```

---

# Validation

Before payment:

Validate:

* Employee exists.
* Employee is Active.
* Payroll calculated.
* Payroll not previously paid.
* Internet connection available.

Reject invalid requests.

---

# Internet Requirement

Salary payment requires:

* Active internet connection.
* Firestore availability.

Employee Management operates online only.

No local payroll storage exists.

---

# Error Handling

Examples:

```text id="sp07"
Payroll Not Calculated

Salary Already Paid

Network Error

Unable to Process Payment
```

No payroll history or expense is created if payment fails.

---

# Loading State

During payment:

* Disable confirmation button.
* Show loading indicator.
* Prevent duplicate payment requests.

---

# Payroll History

Every successful payment becomes part of:

```text id="sp08"
Payroll History
```

History is immutable.

Future corrections should use adjustment records rather than editing historical payments.

---

# Security

Only users with Payroll permission may:

* Pay salaries.
* View payroll history.

Requirements:

* Authenticated account.
* Active subscription.
* Authorized workspace.

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

---

# Performance

Optimizations:

* Single payroll write.
* Single expense write.
* Batched updates where applicable.
* Incremental dashboard refresh.

Supports large payroll operations.

---

# Business Rules

* Salary must be calculated before payment.
* One payment per employee per payroll period.
* Salary payment automatically creates a Salary expense.
* Payroll history is immutable.
* Reports refresh automatically.
* Dashboard refreshes automatically.
* Employee Management does **not** support offline mode.
* Firestore is the only persistence layer.
* Financial records are created only after successful confirmation.

---

# Architecture

```text id="sp09"
Payroll Screen

↓

PayrollCubit

↓

PaySalaryUseCase

↓

Repository

↓

Firestore

↓

Payroll History

+

Salary Expense

↓

Reports

↓

Dashboard
```

---

# End of Section

Next Section:

**8.14 Payroll History**

This section documents the complete payroll history module, including payment records, filtering, employee salary history, auditing, reporting, search, and all business rules governing historical payroll records.
# PART 8 — Employee Management

# 8.14 Payroll History

## Overview

The **Payroll History** module maintains a permanent record of every salary payment processed through the Payroll Engine.

It serves as the official financial audit trail for employee salary payments.

Payroll History is **read-only** after creation.

Historical payroll records are never edited or deleted during normal business operations.

Future corrections should be performed using adjustment records rather than modifying existing payroll history.

---

# Objectives

Payroll History allows businesses to:

* Review previous salary payments.
* Audit payroll transactions.
* Track payment dates.
* Analyze payroll costs.
* Support accounting and financial reporting.

---

# Source of Truth

Payroll History is generated only after a successful salary payment.

Every history record originates from:

```text id="ph01"
Salary Payment
```

Manual payroll history creation is not supported.

---

# Payroll History Record

Each record contains:

* Payroll ID
* Employee ID
* Employee Name
* Payroll Period
* Base Salary
* Final Salary
* Payment Date
* createdAt

Future:

* Payment Method
* Reference Number
* Notes
* Approved By

---

# Record Creation

Payroll History is created automatically.

Flow:

```text id="ph02"
Salary Calculated

↓

Salary Paid

↓

Payroll History Created
```

Administrators never create history manually.

---

# Record Immutability

Payroll History is immutable.

Rules:

* No editing.
* No deletion.
* No salary modification.

If corrections are required:

Future versions should create adjustment entries.

---

# Payroll Timeline

Example:

```text id="ph03"
January Payroll

↓

Paid

↓

History Saved

↓

Available Forever
```

Each payroll period produces one historical record.

---

# Employee Payroll History

Users may open:

```text id="ph04"
Employee Details

↓

Payroll History
```

to view all salary payments for a single employee.

---

# Payroll List

History may be displayed as:

```text id="ph05"
Employee

Payroll Period

Paid Amount

Payment Date
```

Future:

Status indicators.

---

# Searching

Search supports:

* Employee Name
* Payroll Period

Future:

* Amount
* Payment Method

Search uses debounce for performance.

---

# Filtering

Supported filters:

* Employee
* Month
* Year

Future:

* Position
* Department
* Payment Status

---

# Sorting

Supported sorting:

* Newest First
* Oldest First
* Employee Name

Future:

* Highest Salary
* Lowest Salary

---

# Reports Integration

Payroll History contributes to:

* Payroll Reports
* Financial Reports
* Expense Reports

Historical payroll data is never recalculated.

---

# Dashboard Integration

Dashboard may display:

* Total Payroll Paid
* Monthly Payroll Cost

Values are derived from payroll history.

---

# Expense Relationship

Every Payroll History record has a corresponding:

```text id="ph06"
Salary Expense
```

The relationship ensures complete financial traceability.

---

# Timestamp Rule

Payroll History always uses:

```text id="ph07"
createdAt
```

This represents the business payment date.

Never use:

* syncedAt
* uploadedAt
* serverTimestamp

---

# Internet Requirement

Payroll History is loaded directly from Firestore.

Employee Management does **not** support offline history.

If internet is unavailable:

```text id="ph08"
Unable to load payroll history.

Please check your internet connection.
```

---

# Error Handling

Examples:

```text id="ph09"
No Payroll History

Network Error

Unable to Load Data
```

The system never creates incomplete history records.

---

# Performance

Optimizations:

* Paginated queries.
* Lazy loading.
* Incremental Cubit updates.
* Efficient Firestore indexes.

Supports organizations with many years of payroll history.

---

# Security

Payroll History requires:

* Authenticated account.
* Active subscription.
* Payroll viewing permission.

Future role permissions:

* Owner
* Accountant
* HR

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

---

# Business Rules

* Payroll History is created automatically after salary payment.
* Payroll History is immutable.
* One payroll history record exists per employee per payroll period.
* Reports consume payroll history.
* Dashboard derives payroll statistics from history.
* Salary expenses correspond to payroll history.
* Employee Management does **not** support offline mode.
* Firestore is the single source of truth.
* Historical payroll data is never modified.

---

# Architecture

```text id="ph10"
Salary Payment

↓

Payroll History Record

↓

Firestore

↓

Payroll Reports

↓

Financial Reports

↓

Dashboard

↓

Employee Details
```

---

# End of Section

Next Section:

**8.15 Employee Reports**

This section documents the complete Employee Reporting Engine, including employee statistics, attendance reports, payroll reports, salary analytics, dashboard KPIs, filtering, searching, and all business rules governing employee-related reporting.
# PART 8 — Employee Management

# 8.15 Employee Reports

## Overview

The **Employee Reports Engine** provides comprehensive reports about employees, attendance, payroll, and workforce statistics.

Unlike the Payroll Engine, Employee Reports are analytical.

They never create or modify business data.

Instead, they generate insights from existing records.

Employee Reports help business owners answer questions such as:

* How many employees are currently active?
* Who has the best attendance?
* How much has been spent on salaries?
* Which employees have the highest absence rate?

---

# Objectives

Employee Reports allow businesses to:

* Monitor workforce performance.
* Analyze attendance.
* Review payroll history.
* Track salary expenses.
* Support business decisions.

---

# Source of Truth

Employee Reports are generated dynamically from:

```text id="erp01"
Employee Profiles

+

Attendance Records

+

Payroll History
```

Reports never use:

* Cached totals.
* Dashboard values.
* Stored statistics.

---

# Available Reports

Current reports include:

* Employee List Report
* Attendance Report
* Payroll Report
* Salary Report

Future reports:

* Department Report
* Performance Report
* Productivity Report
* Employee Growth Report

---

# Employee List Report

Displays:

* Employee Name
* Position
* Status
* Monthly Salary

Supports:

* Searching
* Filtering
* Sorting

---

# Attendance Report

Displays:

For each employee:

* Present Days
* Absent Days
* Excused Absence Days
* Attendance Percentage

Generated dynamically from attendance records.

---

# Payroll Report

Displays:

* Payroll Period
* Paid Amount
* Payment Date
* Employee Name

Derived directly from Payroll History.

---

# Salary Report

Displays:

* Monthly Salary
* Total Salary Paid
* Payroll Summary

Future:

* Salary Growth
* Salary Comparison

---

# Dashboard KPIs

Dashboard statistics include:

* Total Employees
* Active Employees
* Suspended Employees
* Monthly Payroll
* Attendance Percentage

All values are calculated dynamically.

---

# Searching

Search supports:

* Employee Name
* Position

Future:

* Phone Number
* Department

Performance requirement:

Use debounce.

---

# Filtering

Supported filters:

* Employee Status
* Payroll Period
* Date Range

Future:

* Position
* Salary Range
* Department

---

# Sorting

Supported sorting:

* Employee Name
* Newest Employees
* Oldest Employees

Future:

* Highest Salary
* Lowest Salary
* Best Attendance

---

# Timestamp Rule

Reports always use:

```text id="erp02"
createdAt
```

Never:

* syncedAt
* uploadedAt
* serverTimestamp

Historical employee reports remain accurate.

---

# Dashboard Integration

Employee Reports automatically update:

* Dashboard KPIs
* Charts (future)
* Employee Statistics

No manual refresh required.

---

# Internet Requirement

Employee Reports require an active internet connection.

If Firestore cannot be reached:

```text id="erp03"
Unable to load employee reports.

Please check your internet connection.
```

Employee Management operates online only.

---

# Empty State

If no employee records exist:

Display:

```text id="erp04"
No Employee Data Available
```

Localized using ARB.

---

# Performance

Optimizations:

* Paginated Firestore queries.
* Lazy loading.
* Incremental Cubit updates.
* Efficient indexes.
* Debounced searching.

Supports thousands of employees.

---

# Security

Employee Reports require:

* Authenticated account.
* Active subscription.
* Report viewing permission.

Future role permissions:

* Owner
* HR
* Accountant
* Manager

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

---

# Business Rules

* Reports are always generated dynamically.
* Employee Profiles are the source of employee information.
* Attendance Records are the source of attendance reports.
* Payroll History is the source of payroll reports.
* Dashboard consumes Employee Reports.
* createdAt defines report chronology.
* Employee Management does **not** support offline reporting.
* Firestore is the only data source.
* Reports are read-only.
* Reports never modify business data.

---

# Architecture

```text id="erp05"
Employee Profiles

+

Attendance Records

+

Payroll History

↓

Employee Reports Engine

↓

Attendance Reports

↓

Payroll Reports

↓

Salary Reports

↓

Dashboard

↓

Updated UI
```

---

# End of Section

Next Section:

**8.16 Delete Employee**

The Delete Employee feature removes an employee from future business operations while preserving the integrity of historical attendance, payroll, and financial records.

# PART 8 — Employee Management

# 8.16 Delete Employee

## Overview

The **Delete Employee** feature removes an employee from future business operations while preserving the integrity of historical attendance, payroll, and financial records.

Employee deletion is an administrative operation and must never compromise audit history.

The system follows a **Soft Delete First** strategy to ensure historical data remains available for reporting and financial compliance.

---

# Objectives

The Delete Employee feature allows administrators to:

* Remove employees from active operations.
* Prevent future attendance.
* Prevent future payroll generation.
* Preserve historical records.
* Maintain financial audit integrity.

---

# Deletion Strategy

The system supports two deletion strategies.

## Soft Delete (Recommended)

Employee remains in Firestore.

Only the employee status changes to:

```text id="de01"
Deleted
```

Employee:

* Cannot appear in active employee lists.
* Cannot perform Check-In.
* Cannot perform Check-Out.
* Cannot receive future payroll.
* Cannot participate in future reports as an active employee.

Historical information remains available.

---

## Hard Delete

Employee document is permanently removed.

Hard Delete should only be allowed when:

* No attendance history exists.
* No payroll history exists.
* No salary expenses exist.

Otherwise:

The operation must automatically fall back to **Soft Delete**.

---

# Delete Flow

```text id="de02"
Employee Details

↓

Delete Employee

↓

Confirmation Dialog

↓

Validation

↓

Soft Delete

↓

Refresh Employees

↓

Refresh Dashboard

↓

Refresh Reports
```

---

# Confirmation Dialog

Display:

```text id="de03"
Delete Employee?

The employee will no longer be able to use the system.

Historical attendance and payroll will remain available.

[Cancel]

[Delete]
```

Deletion must never occur without explicit confirmation.

---

# Validation

Before deleting:

Validate:

* Employee exists.
* Internet connection available.
* Firestore accessible.
* User has permission.

Then verify:

Historical Attendance Exists?

Historical Payroll Exists?

Salary Expenses Exist?

---

If any historical data exists:

↓

Soft Delete.

Otherwise:

↓

Hard Delete may be performed according to business configuration.

---

# Effects of Soft Delete

After deletion:

Employee:

* Disappears from active employee lists.
* Cannot attend work.
* Cannot receive payroll.
* Cannot be selected during payroll generation.
* Cannot participate in future attendance.

Historical records remain untouched.

---

# Attendance Integration

Attendance history:

✔ Preserved forever.

Future attendance:

❌ Blocked.

Attendance reports remain historically accurate.

---

# Payroll Integration

Payroll History:

✔ Preserved.

Future payroll:

❌ Disabled.

Historical salary payments remain available.

---

# Expense Integration

Salary expenses linked to previous payroll remain unchanged.

Financial reports continue to include historical salary expenses.

---

# Reports Integration

Employee Reports continue displaying:

Historical:

* Attendance.
* Payroll.
* Salary.

Current active employee statistics exclude deleted employees.

---

# Dashboard Integration

Dashboard automatically refreshes:

* Active Employees
* Deleted Employees (future KPI)
* Payroll Statistics
* Attendance Statistics

---

# Firestore Update

Soft Delete updates only:

```text id="de04"
status = deleted

deletedAt = currentDateTime
```

Employee identity remains unchanged.

Employee ID is preserved.

---

# Internet Requirement

Employee deletion requires:

* Active internet connection.
* Firestore availability.

Employee Management is online-only.

---

# Error Handling

Examples:

```text id="de05"
Employee Not Found

Permission Denied

Unable to Delete Employee

Network Error
```

If deletion fails:

Employee remains unchanged.

No partial updates occur.

---

# Loading State

During deletion:

* Disable Delete button.
* Display loading indicator.
* Prevent duplicate deletion requests.

---

# Duplicate Protection

Multiple delete requests for the same employee are ignored.

Only one successful deletion operation is allowed.

---

# Security

Only authorized administrators may delete employees.

Requirements:

* Authenticated account.
* Active subscription.
* Employee Management permission.

Future permissions:

* Owner
* HR Manager

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

No hardcoded messages.

---

# Performance

Optimizations:

* Single Firestore update for Soft Delete.
* No unnecessary queries.
* Incremental Cubit refresh.
* Dashboard updates only affected statistics.

---

# Business Rules

* Soft Delete is the default deletion strategy.
* Hard Delete is only allowed when no historical records exist.
* Attendance history is never deleted.
* Payroll history is never deleted.
* Salary expenses are never deleted.
* Deleted employees cannot attend work.
* Deleted employees cannot receive payroll.
* Reports preserve historical integrity.
* Dashboard refreshes automatically.
* Employee Management does **not** support offline mode.
* Firestore is the single source of truth.
* Historical financial data is immutable.

---

# Architecture

```text id="de06"
Employee Details

↓

EmployeesCubit

↓

DeleteEmployeeUseCase

↓

Repository

↓

Firestore

↓

Employee Status

↓

Reports

↓

Dashboard

↓

Updated UI
```

---

# End of Section

Next Section:

**8.17 Salary Period**

This section documents payroll periods, payroll cycles, monthly salary scheduling, payroll closing rules, salary periods, and the business rules governing payroll execution.
# PART 8 — Employee Management

# 8.17 Salary Period

## Overview

The **Salary Period** defines the time range used by the Payroll Engine when calculating employee salaries.

A payroll period groups attendance records into a single salary cycle.

All salary calculations, payroll generation, and salary payments are based on a specific payroll period.

The Payroll Engine never mixes attendance records from different payroll periods.

---

# Objectives

The Salary Period module allows businesses to:

* Define payroll cycles.
* Organize attendance into salary periods.
* Prevent duplicate payroll generation.
* Maintain payroll consistency.
* Support historical payroll reporting.

---

# Current Payroll Cycle

The current implementation supports:

```text id="spd01"
Monthly Payroll
```

Each payroll period represents one calendar month.

Examples:

* January 2026
* February 2026
* March 2026

---

# Payroll Period Structure

Each period contains:

* Period ID
* Month
* Year
* Start Date
* End Date

Future fields:

* Status
* Closed Date
* Approved By

---

# Payroll Timeline

Example:

```text id="spd02"
January

↓

Attendance Collection

↓

Salary Calculation

↓

Payroll Generation

↓

Salary Payment

↓

Payroll History
```

After the payroll period is completed, a new payroll period begins.

---

# Attendance Relationship

Attendance records belong to one payroll period.

Grouping rule:

```text id="spd03"
Attendance createdAt

↓

Month

↓

Payroll Period
```

Attendance from another month is never included.

---

# Salary Calculation Relationship

Salary Calculation consumes:

* Attendance within the payroll period.
* Employee salary configuration.

No attendance outside the selected payroll period is considered.

---

# Payroll Generation

Payroll is generated independently for each payroll period.

Example:

```text id="spd04"
January Payroll

↓

Generated

↓

February Payroll

↓

Generated
```

Each period is isolated.

---

# Payroll Closing

Current implementation:

Payroll remains available after generation.

Future versions may introduce:

```text id="spd05"
Open

↓

Processing

↓

Closed
```

Closed payroll periods become read-only.

---

# Payroll History

Every payroll history record belongs to exactly one payroll period.

Historical payroll always references:

* Month
* Year

This ensures long-term financial traceability.

---

# Reports Integration

Payroll Period contributes to:

* Payroll Reports
* Salary Reports
* Monthly Financial Reports

Reports group payroll records using the payroll period.

---

# Dashboard Integration

Dashboard displays:

* Current Payroll Period
* Monthly Payroll Cost

Future:

* Payroll Completion Percentage

---

# Duplicate Protection

Each employee may have:

```text id="spd06"
One Payroll

Per Payroll Period
```

Attempts to generate payroll again for the same employee and period are rejected.

---

# Internet Requirement

Salary Period operations require:

* Active internet connection.
* Firestore availability.

Employee Management is online-only.

---

# Error Handling

Examples:

```text id="spd07"
Invalid Payroll Period

Payroll Already Generated

Unable to Load Payroll Period

Network Error
```

No partial payroll is created.

---

# Performance

Optimizations:

* Efficient month-based Firestore queries.
* Incremental payroll generation.
* Minimal reads.
* Indexed period filtering.

Supports many years of payroll history.

---

# Security

Payroll Period management requires:

* Authenticated account.
* Active subscription.
* Payroll permission.

Future permissions:

* Accountant
* HR
* Owner

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

---

# Business Rules

* One payroll period represents one calendar month.
* Attendance belongs to exactly one payroll period.
* Salary calculations use only attendance within the selected period.
* Payroll History references one payroll period.
* Duplicate payroll generation is prohibited.
* Payroll periods remain historically immutable.
* Employee Management does **not** support offline mode.
* Firestore is the single source of truth.

---

# Architecture

```text id="spd08"
Attendance Records

↓

Payroll Period

↓

Salary Calculation

↓

Payroll Engine

↓

Payroll History

↓

Reports

↓

Dashboard
```

---

# End of Section

Next Section:

**8.18 Expected Working Days**

This section documents how expected working days are configured, how they affect salary calculations, attendance validation, missing day calculations, and all business rules governing working-day expectations.
# PART 8 — Employee Management

# 8.18 Expected Working Days

## Overview

The **Expected Working Days** configuration defines the number of days an employee is expected to work during a payroll period.

This value is one of the primary inputs to the Salary Calculation Engine.

It is used to:

* Calculate daily salary.
* Determine missing working days.
* Calculate attendance percentage.
* Apply salary deductions.
* Generate payroll accurately.

Expected Working Days are **configuration data**, not calculated data.

---

# Objectives

The Expected Working Days feature allows businesses to:

* Define monthly working expectations.
* Standardize payroll calculations.
* Support different business schedules.
* Calculate attendance percentages consistently.

---

# Configuration

Each payroll period has:

```text id="ewd01"
Expected Working Days
```

Examples:

```text id="ewd02"
26 Days

22 Days

30 Days
```

The value depends on business policy.

---

# Relationship with Payroll

Salary Calculation consumes:

```text id="ewd03"
Monthly Salary

+

Expected Working Days

+

Attendance Records
```

Expected Working Days directly affect salary computation.

---

# Daily Salary Calculation

Daily Salary is derived dynamically.

Formula:

```text id="ewd04"
Daily Salary

=

Monthly Salary

÷

Expected Working Days
```

Example:

```text id="ewd05"
Monthly Salary

=

9000

Expected Working Days

=

30

↓

Daily Salary

=

300
```

The value is recalculated whenever salary calculation occurs.

---

# Attendance Relationship

Attendance records are compared against:

```text id="ewd06"
Expected Working Days
```

to determine:

* Present Days
* Missing Days
* Attendance Percentage

---

# Attendance Percentage

Formula:

```text id="ewd07"
Attendance %

=

Present Days

÷

Expected Working Days

×

100
```

Attendance percentage is always derived.

---

# Missing Days

Missing Days are calculated dynamically.

Formula:

```text id="ewd08"
Missing Days

=

Expected Working Days

-

Present Days
```

No separate field stores Missing Days.

---

# Payroll Integration

Expected Working Days contribute to:

* Daily Salary
* Attendance Deductions
* Final Salary

Payroll consumes only the derived values.

---

# Reports Integration

Employee Reports display:

* Expected Working Days
* Present Days
* Missing Days
* Attendance Percentage

Future:

* Department Attendance
* Workforce Productivity

---

# Dashboard Integration

Dashboard statistics indirectly depend on:

Expected Working Days through:

* Attendance Percentage
* Payroll Statistics

---

# Configuration Changes

If Expected Working Days change:

Future payroll calculations use the updated configuration.

Historical payroll records remain unchanged.

Historical salary calculations are never recalculated automatically.

---

# Validation

Validate:

* Expected Working Days > 0
* Reasonable business value
* Payroll period exists

Reject invalid configurations.

---

# Internet Requirement

Configuration changes require:

* Active internet connection.
* Firestore availability.

Employee Management is online-only.

---

# Error Handling

Examples:

```text id="ewd09"
Invalid Working Days

Payroll Period Not Found

Unable to Save Configuration

Network Error
```

Configuration remains unchanged if validation fails.

---

# Performance

Optimizations:

* Configuration loaded once per payroll calculation.
* Reused across salary computations.
* Indexed Firestore access.

Minimal read operations.

---

# Security

Only authorized administrators may modify:

Expected Working Days.

Requirements:

* Authenticated account.
* Active subscription.
* Payroll configuration permission.

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

---

# Business Rules

* Expected Working Days are configured per payroll period.
* Daily Salary is always derived.
* Attendance Percentage is always derived.
* Missing Days are always derived.
* Historical payroll is never recalculated after configuration changes.
* Employee Management does **not** support offline mode.
* Firestore is the single source of truth.
* Expected Working Days must always be greater than zero.

---

# Architecture

```text id="ewd10"
Payroll Configuration

↓

Expected Working Days

↓

SalaryCalculationUseCase

↓

Daily Salary

↓

Attendance Analysis

↓

Payroll Engine

↓

Reports

↓

Dashboard
```

---

# End of Section

Next Section:

**8.19 Weekend Configuration**

This section documents how weekends are configured, how non-working days are excluded from payroll calculations, attendance validation, expected working days, and all business rules governing weekly schedules.
# PART 8 — Employee Management

# 8.19 Weekend Configuration

## Overview

The **Weekend Configuration** module defines the official non-working days for the business.

Weekend days are excluded from attendance expectations and salary calculations.

This configuration ensures that employees are not marked absent on scheduled weekly holidays.

The Weekend Configuration is shared across the Employee Management module and is consumed by:

* Attendance
* Salary Calculation
* Payroll
* Employee Reports

Future versions may support different weekend schedules for individual employees or departments.

---

# Objectives

The Weekend Configuration allows businesses to:

* Define weekly holidays.
* Exclude non-working days from payroll calculations.
* Prevent false absence detection.
* Improve payroll accuracy.
* Standardize attendance expectations.

---

# Configuration

Current implementation supports:

```text id="wk01"
One

or

Multiple Weekend Days
```

Examples:

```text id="wk02"
Friday

Saturday
```

or

```text id="wk03"
Sunday
```

The selected configuration depends entirely on the business.

---

# Relationship with Expected Working Days

Expected Working Days are derived after excluding:

* Weekend Days
* Future Official Holidays (if implemented)

Example:

```text id="wk04"
Calendar Days

↓

Remove Weekend Days

↓

Expected Working Days
```

---

# Attendance Relationship

Attendance is **not expected** on configured weekend days.

Therefore:

* No employee is considered absent.
* No attendance deduction is generated.
* No attendance warning is shown.

---

# Salary Calculation Relationship

Weekend days never reduce employee salary.

Salary calculations ignore configured weekends completely.

Only expected working days participate in payroll.

---

# Payroll Integration

Payroll consumes:

* Expected Working Days
* Attendance Records

Weekend days never contribute to:

* Missing Days
* Salary Deductions

---

# Reports Integration

Attendance Reports exclude weekend days from:

* Attendance Percentage
* Missing Days
* Absence Statistics

Reports remain historically accurate.

---

# Dashboard Integration

Dashboard attendance KPIs consider:

Configured weekend days.

Attendance percentages are calculated correctly.

---

# Future Enhancements

Future versions may support:

* Department-specific weekends.
* Employee-specific weekends.
* Rotating shifts.
* Weekly schedules.
* Public holidays.
* Company holidays.

The current architecture is prepared for these extensions.

---

# Configuration Changes

When weekend configuration changes:

Future payroll periods use the new configuration.

Historical payroll and attendance remain unchanged.

Business history is never recalculated.

---

# Validation

Before saving:

Validate:

* At least one valid weekday selected.
* No duplicate weekdays.
* Configuration saved successfully.

Reject invalid configurations.

---

# Internet Requirement

Weekend configuration requires:

* Active internet connection.
* Firestore availability.

Employee Management is online-only.

---

# Error Handling

Examples:

```text id="wk05"
Invalid Weekend Configuration

Unable to Save

Network Error
```

Configuration remains unchanged if the operation fails.

---

# Performance

Optimizations:

* Weekend configuration loaded once.
* Cached during salary calculation.
* Reused across attendance processing.

Minimal Firestore reads.

---

# Security

Only authorized administrators may modify:

* Weekend Configuration

Requirements:

* Authenticated account.
* Active subscription.
* Payroll configuration permission.

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

Weekday names are fully localized.

---

# Business Rules

* Weekend days are excluded from attendance expectations.
* Weekend days never generate absences.
* Weekend days never generate salary deductions.
* Expected Working Days exclude configured weekends.
* Historical payroll is never recalculated after weekend changes.
* Historical attendance remains unchanged.
* Employee Management does **not** support offline mode.
* Firestore is the single source of truth.
* Weekend configuration affects future payroll periods only.

---

# Architecture

```text id="wk06"
Payroll Configuration

↓

Weekend Configuration

↓

Expected Working Days

↓

Attendance Validation

↓

SalaryCalculationUseCase

↓

Payroll Engine

↓

Reports

↓

Dashboard
```

---

# End of Section

Next Section:

**8.20 Bonus System**

This section documents the complete employee bonus system, including bonus configuration, payroll integration, salary adjustments, reporting, future bonus categories, and all business rules governing employee bonuses.
# PART 8 — Employee Management

# 8.20 Bonus System

## Overview

The **Bonus System** allows businesses to reward employees by adding extra compensation to their salary for a specific payroll period.

A bonus is an **additional financial amount**.

It never modifies:

* Employee Base Salary.
* Historical Payroll.
* Previous Salary Payments.

Bonuses are applied only during payroll calculation for the selected payroll period.

---

# Objectives

The Bonus System allows businesses to:

* Reward employee performance.
* Add temporary salary incentives.
* Support seasonal bonuses.
* Increase payroll flexibility.
* Maintain complete financial traceability.

---

# Bonus Types

Current implementation supports:

```text id="bn01"
Fixed Amount Bonus
```

Example:

```text id="bn02"
500 EGP
```

Future bonus types:

* Performance Bonus
* Sales Bonus
* Attendance Bonus
* Holiday Bonus
* Commission
* Annual Bonus

The current architecture supports these extensions without changing payroll history.

---

# Bonus Lifecycle

```text id="bn03"
Administrator

↓

Create Bonus

↓

Payroll Calculation

↓

Salary Payment

↓

Payroll History
```

---

# Bonus Relationship

Bonus belongs to:

* One Employee.
* One Payroll Period.

The same bonus is never reused automatically in another payroll period.

---

# Salary Calculation Relationship

Current salary formula becomes:

```text id="bn04"
Final Salary

=

Base Salary

+

Bonus

-

Attendance Deductions
```

Bonus is always added before salary payment.

---

# Payroll Integration

Payroll consumes:

* Base Salary
* Attendance
* Bonus

Then generates:

* Final Salary
* Payroll History

---

# Payroll History

Payroll History stores:

* Bonus Amount

This preserves the exact salary breakdown for every payroll period.

Future reports may display:

```text id="bn05"
Base Salary

+

Bonus

=

Paid Salary
```

---

# Expense Integration

Bonuses are **not** recorded as independent expenses.

They become part of:

```text id="bn06"
Salary Expense
```

This prevents duplicated financial records.

---

# Reports Integration

Bonus information contributes to:

* Payroll Reports
* Salary Reports

Future:

* Bonus Reports
* Employee Reward Analytics

---

# Dashboard Integration

Future Dashboard statistics may include:

* Total Bonuses Paid
* Monthly Bonus Cost

Current dashboard reflects bonuses indirectly through payroll totals.

---

# Bonus Validation

Before applying a bonus:

Validate:

* Employee exists.
* Employee is Active.
* Bonus amount greater than zero.
* Payroll not yet paid.

Reject invalid bonuses.

---

# Bonus Modification

Current payroll period:

Bonus may be modified until salary payment.

After payroll payment:

Bonus becomes immutable.

Historical payroll is never edited.

---

# Internet Requirement

Bonus operations require:

* Active internet connection.
* Firestore availability.

Employee Management is online-only.

---

# Error Handling

Examples:

```text id="bn07"
Invalid Bonus Amount

Payroll Already Paid

Unable to Save Bonus

Network Error
```

No partial bonus record is created.

---

# Performance

Optimizations:

* Bonus loaded only during payroll calculation.
* Efficient Firestore reads.
* Incremental Cubit updates.

Supports organizations with many employees.

---

# Security

Only users with Payroll Management permission may:

* Add Bonus
* Edit Bonus
* Remove Bonus before payroll payment

Requirements:

* Authenticated account.
* Active subscription.

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

---

# Business Rules

* Bonuses never modify Base Salary.
* Bonuses belong to one payroll period.
* Bonuses are included during salary calculation.
* Bonuses become immutable after salary payment.
* Bonuses are included inside Salary Expense.
* Historical payroll is never recalculated.
* Employee Management does **not** support offline mode.
* Firestore is the single source of truth.
* Payroll History preserves bonus values permanently.

---

# Architecture

```text id="bn08"
Employee Bonus

↓

BonusUseCase

↓

SalaryCalculationUseCase

↓

Payroll Engine

↓

Salary Payment

↓

Payroll History

↓

Reports

↓

Dashboard
```

---

# End of Section

Next Section:

**8.21 Missing Days**

This section documents how missing working days are determined, how they affect attendance statistics, salary deductions, payroll calculations, reporting, and all business rules governing employee absences from expected working days.
# PART 8 — Employee Management

# 8.21 Missing Days

## Overview

The **Missing Days** module determines the number of expected working days during which an employee did not attend work.

Missing Days are **derived values**.

They are never stored in Firestore.

Instead, they are calculated dynamically whenever salary calculations, attendance reports, or payroll processing are performed.

This guarantees that Missing Days always reflect the latest attendance data.

---

# Objectives

The Missing Days module allows businesses to:

* Calculate employee absences.
* Apply payroll deductions.
* Generate attendance statistics.
* Improve payroll accuracy.
* Support attendance reports.

---

# Source of Truth

Missing Days always depend on:

```text id="md01"
Expected Working Days

+

Attendance Records
```

Missing Days never rely on:

* Cached values.
* Dashboard totals.
* Stored deduction amounts.

---

# Calculation Formula

Formula:

```text id="md02"
Missing Days

=

Expected Working Days

-

Present Days
```

Example:

```text id="md03"
Expected Working Days

26

Present Days

24

↓

Missing Days

2
```

The value is recalculated every time it is requested.

---

# Present Days

Present Days are determined from:

```text id="md04"
Completed Attendance Records
```

Only valid attendance records contribute to the calculation.

---

# Weekend Relationship

Configured weekend days are excluded.

Employees are **never** considered absent during:

* Friday (if configured)
* Saturday (if configured)

or any configured weekly holiday.

---

# Excused Absence Relationship

Current implementation:

Excused Absence counts as a non-present day.

Future business rules may allow:

* Paid Excused Absence
* Unpaid Excused Absence

without changing the overall architecture.

---

# Salary Calculation Relationship

Missing Days directly affect:

* Attendance Deductions
* Final Salary

Formula:

```text id="md05"
Attendance Deduction

=

Daily Salary

×

Missing Days
```

The deduction itself is also derived.

---

# Payroll Integration

Payroll consumes:

* Missing Days
* Attendance Deduction

Then calculates:

Final Salary.

No payroll value stores Missing Days permanently.

---

# Reports Integration

Missing Days appear in:

* Employee Attendance Reports
* Monthly Reports
* Payroll Reports

Future:

* Productivity Reports
* HR Analytics

---

# Dashboard Integration

Dashboard may display:

* Total Missing Days
* Attendance Percentage

These values are calculated dynamically.

---

# Validation

Before calculating:

Validate:

* Employee exists.
* Expected Working Days configured.
* Attendance records available.

Invalid calculations are rejected.

---

# Timestamp Rule

Attendance grouping always depends on:

```text id="md06"
createdAt
```

Never:

* syncedAt
* uploadedAt
* serverTimestamp

Business chronology remains accurate.

---

# Internet Requirement

Missing Day calculations require:

* Active internet connection.
* Firestore availability.

Employee Management is online-only.

---

# Error Handling

Examples:

```text id="md07"
Attendance Not Found

Invalid Payroll Period

Unable to Calculate

Network Error
```

No partial calculations are produced.

---

# Performance

Optimizations:

* Attendance aggregation.
* Efficient monthly queries.
* Incremental Cubit updates.
* Indexed Firestore reads.

Supports large attendance datasets.

---

# Security

Missing Day calculations require:

* Authenticated account.
* Active subscription.
* Payroll viewing permission.

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

---

# Business Rules

* Missing Days are always derived.
* Missing Days are never stored.
* Weekend days are excluded.
* Attendance records define Present Days.
* Missing Days affect salary deductions.
* Historical payroll is never recalculated.
* Employee Management does **not** support offline mode.
* Firestore is the single source of truth.
* createdAt determines attendance chronology.

---

# Architecture

```text id="md08"
Attendance Records

+

Expected Working Days

↓

MissingDaysUseCase

↓

Attendance Deduction

↓

SalaryCalculationUseCase

↓

Payroll Engine

↓

Reports

↓

Dashboard
```

---

# End of Section

Next Section:

**8.22 Attendance & Absence Rules**

This section documents the complete set of business rules governing employee attendance, absences, excused absences, validation logic, payroll effects, and attendance consistency across the entire Employee Management module.
# PART 8 — Employee Management

# 8.22 Attendance & Absence Rules

## Overview

The **Attendance & Absence Rules** define the official business logic governing employee attendance throughout the application.

These rules ensure that:

* Attendance remains consistent.
* Payroll calculations are accurate.
* Reports remain reliable.
* Historical records preserve financial integrity.

Every attendance-related feature must comply with these rules.

---

# Core Principle

Attendance is the foundation of employee payroll.

Every salary calculation ultimately depends on attendance records.

The attendance lifecycle is:

```text id="aar01"
Employee

↓

Check-In

↓

Working Day

↓

Check-Out

↓

Completed Attendance

↓

Payroll

↓

Reports
```

Attendance records are the only source of truth for employee presence.

---

# Rule 1 — One Attendance Record Per Day

Each employee may have:

```text id="aar02"
One Attendance Record

Per Calendar Day
```

The system rejects duplicate attendance creation.

---

# Rule 2 — Check-In Before Check-Out

Check-Out requires:

* Existing attendance record.
* Valid Check-In.

Sequence:

```text id="aar03"
Check-In

↓

Check-Out
```

The reverse order is never allowed.

---

# Rule 3 — Attendance Status

Current attendance statuses:

```text id="aar04"
Present

Absent

Excused Absence
```

Future statuses may include:

* Late
* Half Day
* Vacation
* Sick Leave

The architecture already supports future expansion.

---

# Rule 4 — Active Employees Only

Only employees with:

```text id="aar05"
Active
```

status may:

* Check-In.
* Check-Out.
* Generate future payroll.

Employees marked as:

* Suspended
* Inactive
* Deleted

are blocked from attendance operations.

---

# Rule 5 — Weekend Exclusion

Configured weekend days are never counted as absences.

Employees are not expected to attend during:

* Friday (if configured).
* Saturday (if configured).
* Any configured weekly holiday.

---

# Rule 6 — Missing Attendance

If an expected working day contains:

* No attendance record.
* No approved excused absence.

The employee is considered to have a Missing Day.

Missing Days are calculated dynamically.

---

# Rule 7 — Excused Absence

Excused Absence is an administrative decision.

It must:

* Belong to one employee.
* Belong to one working day.

It never creates a normal attendance record.

Future payroll policy determines whether it is paid or unpaid.

---

# Rule 8 — Historical Integrity

Historical attendance must never be modified after completion.

If future corrections are required:

Use adjustment records instead of editing history.

Historical payroll must always remain reproducible.

---

# Rule 9 — Attendance Chronology

Attendance reports always group by:

```text id="aar06"
createdAt
```

Never use:

* syncedAt
* uploadedAt
* serverTimestamp

Business chronology must remain accurate.

---

# Rule 10 — Payroll Dependency

Payroll consumes:

* Attendance Records.
* Missing Days.
* Excused Absences.

Attendance data directly affects salary calculations.

---

# Rule 11 — Report Dependency

Attendance Reports derive:

* Present Days.
* Missing Days.
* Attendance Percentage.

Reports never store calculated values.

Everything is recalculated dynamically.

---

# Rule 12 — Dashboard Dependency

Dashboard consumes:

* Attendance Reports.
* Payroll Reports.

Dashboard never performs independent attendance calculations.

---

# Rule 13 — Duplicate Protection

The system prevents:

* Duplicate Check-In.
* Duplicate Check-Out.
* Duplicate attendance records.

Repeated user actions must not create duplicated data.

---

# Rule 14 — Validation Sequence

Before every attendance operation:

Validate:

* Employee exists.
* Employee is Active.
* Internet connection available.
* Firestore accessible.
* Business rules satisfied.

Only then execute the operation.

---

# Rule 15 — Online Operation

Attendance requires:

* Active internet connection.
* Live Firestore access.

Employee Management is online-only.

No attendance information is stored locally.

---

# Rule 16 — Error Recovery

If attendance creation fails:

* No partial attendance record is created.
* Dashboard remains unchanged.
* Reports remain unchanged.
* Payroll remains unchanged.

The user receives a localized error message.

---

# Rule 17 — Performance

Attendance operations are optimized using:

* Indexed Firestore queries.
* Efficient employee lookup.
* Incremental Cubit updates.
* Lazy report generation.

Supports organizations with thousands of attendance records.

---

# Rule 18 — Security

Attendance requires:

* Authenticated account.
* Active subscription.
* Employee Management permission.

Unauthorized users cannot modify attendance.

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

---

# Business Rules Summary

* One attendance record per employee per day.
* Check-In always precedes Check-Out.
* Weekend days are excluded from absences.
* Missing Days are derived dynamically.
* Attendance records are immutable after completion.
* Attendance directly affects payroll.
* Reports calculate attendance dynamically.
* Dashboard consumes attendance reports.
* Employee Management does **not** support offline mode.
* Firestore is the single source of truth.
* createdAt defines attendance chronology.

---

# Architecture

```text id="aar07"
Attendance Validation

↓

AttendanceUseCase

↓

Firestore

↓

Attendance Records

↓

Payroll Engine

↓

Reports Engine

↓

Dashboard
```

---

# End of Section

Next Section:

**8.23 Salary Advances**

This section documents employee salary advances, advance requests, payroll deductions, repayment rules, reporting, financial integration, and all business rules governing salary advances.
# PART 8 — Employee Management

# 8.23 Salary Advances

## Overview

The **Salary Advances** module allows administrators to provide employees with an advance payment before payroll is processed.

A salary advance is **not** an additional salary.

It is an early payment that will be deducted from the employee's next salary payment.

Salary Advances are financial transactions and must always remain traceable.

Every advance must be linked to:

* One Employee.
* One Financial Transaction.
* One Payroll Period (when deducted).

---

# Objectives

The Salary Advances module allows businesses to:

* Record employee advances.
* Deduct advances automatically from payroll.
* Maintain complete financial history.
* Support payroll transparency.
* Improve financial tracking.

---

# Source of Truth

Salary Advances are stored as independent financial records.

They are **not** stored inside:

* Employee Profile.
* Payroll History.
* Salary Configuration.

Each advance exists as its own business transaction.

---

# Advance Lifecycle

```text id="sa01"
Create Advance

↓

Save Advance

↓

Payroll Calculation

↓

Automatic Deduction

↓

Payroll History
```

---

# Advance Record

Each Salary Advance contains:

* Advance ID
* Employee ID
* Advance Amount
* Advance Date
* Notes (Optional)
* Payroll Period (Future deduction period)
* createdAt

Future fields:

* Approved By
* Remaining Balance
* Installment Count

---

# Advance Creation

Administrators create advances from:

```text id="sa02"
Employee Details

↓

Salary Advances

↓

Add Advance
```

---

# Validation

Before saving:

Validate:

* Employee exists.
* Employee is Active.
* Advance Amount > 0.
* Internet connection available.
* Firestore available.

Reject invalid advances.

---

# Payroll Integration

During salary calculation:

Formula becomes:

```text id="sa03"
Final Salary

=

Base Salary

+

Bonus

-

Attendance Deductions

-

Salary Advances
```

Advances are deducted automatically.

No manual calculation is required.

---

# Multiple Advances

Current payroll period may contain:

```text id="sa04"
Multiple Salary Advances
```

Payroll deducts:

```text id="sa05"
Sum(All Advances)
```

The deduction is always calculated dynamically.

---

# Payroll History

Payroll History stores:

* Total Advance Deduction.

Historical payroll always preserves the exact deducted amount.

---

# Expense Integration

Creating a Salary Advance immediately creates:

```text id="sa06"
Expense

Category

Salary Advance
```

This ensures financial statements remain accurate.

Future salary payment does **not** create another advance expense.

Only the original advance transaction is recorded as an expense.

---

# Reports Integration

Salary Advances contribute to:

* Payroll Reports.
* Expense Reports.
* Employee Financial Reports.

Future:

* Outstanding Advances Report.
* Advance Analytics.

---

# Dashboard Integration

Dashboard may display:

* Total Salary Advances.
* Monthly Advance Amount.

Current financial totals include Salary Advance expenses automatically.

---

# Advance Modification

Before payroll deduction:

Advance may be:

* Updated.
* Deleted.

After payroll processing:

Advance becomes immutable.

Historical payroll is never modified.

---

# Internet Requirement

Salary Advances require:

* Active internet connection.
* Firestore availability.

Employee Management is online-only.

---

# Error Handling

Examples:

```text id="sa07"
Invalid Advance Amount

Employee Not Found

Unable to Save Advance

Network Error
```

No partial financial record is created.

---

# Loading State

During creation:

* Disable Save button.
* Show loading indicator.
* Prevent duplicate submissions.

---

# Performance

Optimizations:

* Efficient Firestore writes.
* Aggregated advance calculation.
* Incremental Cubit updates.

Supports organizations with many employees and frequent advances.

---

# Security

Only authorized users may:

* Create Salary Advances.
* Edit Salary Advances.
* Delete Salary Advances before payroll processing.

Requirements:

* Authenticated account.
* Active subscription.
* Payroll Management permission.

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

---

# Business Rules

* Salary Advances are independent financial transactions.
* Every advance belongs to one employee.
* Multiple advances are supported.
* Payroll deducts the total advance amount automatically.
* Advance expenses are created immediately upon approval.
* Historical payroll is immutable.
* Historical advances are immutable after payroll processing.
* Employee Management does **not** support offline mode.
* Firestore is the single source of truth.
* All advance deductions are calculated dynamically.

---

# Architecture

```text id="sa08"
Employee

↓

SalaryAdvanceUseCase

↓

Firestore

↓

Salary Advance

↓

Expense

↓

SalaryCalculationUseCase

↓

Payroll Engine

↓

Payroll History

↓

Reports

↓

Dashboard
```

---

# End of Section

Next Section:

**8.24 Salary Availability**

This section documents when employee salaries become available for payment, payroll eligibility rules, payment readiness validation, payroll locking, and all business rules governing salary availability before payroll execution.
# PART 8 — Employee Management

# 8.24 Salary Availability

## Overview

The **Salary Availability** module determines whether an employee's salary is ready to be paid for a specific payroll period.

This module acts as the final validation layer before salary payment.

It ensures that payroll can only be processed after all required conditions have been satisfied.

Salary Availability does **not** calculate salaries.

It only determines whether payroll is eligible for payment.

---

# Objectives

The Salary Availability module allows businesses to:

* Prevent invalid salary payments.
* Ensure payroll readiness.
* Validate payroll completeness.
* Protect financial integrity.
* Prevent duplicate salary payments.

---

# Source of Truth

Salary Availability depends on:

```text id="sav01"
Employee Profile

+

Attendance Records

+

Salary Calculation

+

Payroll Status
```

Availability is always calculated dynamically.

It is never stored in Firestore.

---

# Availability Flow

```text id="sav02"
Employee

↓

Attendance Complete

↓

Salary Calculated

↓

Payroll Ready

↓

Salary Available

↓

Salary Payment
```

Only when all validation steps succeed does the salary become payable.

---

# Availability Conditions

A salary is considered **Available** only when all of the following are true:

* Employee exists.
* Employee status is **Active**.
* Monthly salary is configured.
* Payroll period exists.
* Salary calculation completed.
* Payroll has not already been paid.

If any condition fails:

Salary is **Not Available**.

---

# Employee Status Validation

Only employees with:

```text id="sav03"
Active
```

status may receive salary payments.

Employees marked as:

* Suspended
* Inactive
* Deleted

cannot receive payroll.

---

# Payroll Status Validation

Before payment:

Validate:

```text id="sav04"
Payroll Paid?
```

If:

```text id="sav05"
Yes
```

↓

Reject payment.

Display:

```text id="sav06"
Salary Already Paid
```

---

# Attendance Validation

Current implementation:

Attendance records are used during salary calculation.

Salary Availability verifies that salary calculation has already completed successfully.

It does not re-evaluate attendance independently.

---

# Advance Validation

If salary advances exist:

Salary remains available.

The Payroll Engine automatically deducts advances during salary calculation.

Salary Availability does not block payroll because of advances.

---

# Bonus Validation

Bonuses are included in salary calculation before payroll becomes available.

Availability only verifies that salary calculation has finished successfully.

---

# Payroll Lock

After successful salary payment:

Payroll becomes locked.

The following operations are no longer allowed:

* Edit Salary Calculation
* Modify Bonus
* Modify Salary Advances
* Pay Salary Again

Historical payroll remains immutable.

---

# Dashboard Integration

Dashboard may display:

* Employees Ready for Payroll
* Employees Already Paid

Future KPI:

```text id="sav07"
Payroll Completion %
```

---

# Reports Integration

Salary Availability contributes to:

* Payroll Reports
* Payroll Status Reports

Future:

* Pending Payroll Report
* Payroll Readiness Report

---

# Internet Requirement

Salary Availability requires:

* Active internet connection.
* Firestore availability.

Employee Management is online-only.

---

# Error Handling

Examples:

```text id="sav08"
Salary Not Calculated

Payroll Already Paid

Employee Inactive

Network Error

Unable to Validate Payroll
```

Salary payment is blocked until validation succeeds.

---

# Loading State

During validation:

* Disable payment button.
* Show loading indicator.
* Prevent duplicate validation requests.

---

# Performance

Optimizations:

* Minimal Firestore reads.
* Reuse salary calculation results.
* Incremental Cubit updates.

Supports payroll validation for large organizations.

---

# Security

Salary Availability requires:

* Authenticated account.
* Active subscription.
* Payroll Management permission.

Unauthorized users cannot validate payroll availability.

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

---

# Business Rules

* Salary Availability is always derived dynamically.
* Salary must be calculated before payment.
* Only Active employees may receive salary.
* Salary cannot be paid twice.
* Paid payroll becomes immutable.
* Salary advances and bonuses are resolved during salary calculation.
* Employee Management does **not** support offline mode.
* Firestore is the single source of truth.
* Salary Availability never modifies business data.

---

# Architecture

```text id="sav09"
Employee Profile

+

Salary Calculation

+

Payroll Status

↓

SalaryAvailabilityUseCase

↓

Payroll Ready

↓

PaySalaryUseCase

↓

Payroll History

↓

Reports

↓

Dashboard
```

---

# End of Section

Next Section:

**8.25 Business Rules & Edge Cases**

This final section consolidates all Employee Management business rules, validation rules, edge cases, architectural guarantees, financial integrity requirements, and system-wide constraints that govern the entire Employee Management module.
# PART 8 — Employee Management

# 8.25 Business Rules & Edge Cases

## Overview

This section defines the official business rules governing the entire **Employee Management** module.

These rules are mandatory and apply to every feature within the module.

Their purpose is to guarantee:

* Data consistency.
* Payroll accuracy.
* Financial integrity.
* Attendance correctness.
* Stable application behavior.

Business rules always take precedence over UI behavior.

---

# Core Architecture Rule

Employee Management follows Clean Architecture.

Business flow:

```text id="ebr01"
UI

↓

Cubit

↓

UseCase

↓

Repository

↓

DataSource

↓

Firestore
```

Business logic must live inside **UseCases**.

Widgets must never contain business rules.

---

# Source of Truth Rule

Every subsystem has one source of truth.

Employee Information

↓

Employee Profile

---

Attendance

↓

Attendance Records

---

Salary Calculation

↓

SalaryCalculationUseCase

---

Payroll

↓

Payroll History

---

Expenses

↓

Expenses Module

---

Dashboard values are derived only.

Dashboard is never a source of truth.

---

# Employee Identity Rule

Every employee has:

* One Employee ID.
* One Employee Profile.
* One Monthly Salary.
* One Employment Status.

Employee ID never changes.

---

# Employment Status Rule

Supported statuses:

```text id="ebr02"
Active

Inactive

Suspended

Deleted
```

Only:

```text id="ebr03"
Active
```

employees may:

* Check-In.
* Check-Out.
* Receive payroll.
* Receive bonuses.
* Receive salary advances.

---

# Attendance Rules

Each employee may have:

```text id="ebr04"
One Attendance Record

Per Calendar Day
```

Duplicate Check-In:

❌ Rejected.

Duplicate Check-Out:

❌ Rejected.

Attendance records become immutable after completion.

---

# Weekend Rules

Configured weekend days:

* Never generate absences.
* Never generate deductions.
* Never reduce salary.

Weekend configuration affects future payroll periods only.

---

# Missing Day Rules

Missing Days are:

✔ Calculated dynamically.

❌ Never stored.

Formula:

```text id="ebr05"
Expected Working Days

-

Present Days
```

---

# Salary Rules

Salary is always derived.

Current calculation depends on:

* Base Salary.
* Bonus.
* Attendance Deduction.
* Salary Advances.

Historical salary values are never recalculated.

---

# Bonus Rules

Bonuses:

* Never modify Base Salary.
* Apply only to one payroll period.
* Become immutable after payroll payment.

---

# Salary Advance Rules

Salary Advances:

* Are independent financial transactions.
* May exist multiple times.
* Are deducted automatically during payroll calculation.

Paid payroll cannot modify advances.

---

# Payroll Rules

Each employee may receive:

```text id="ebr06"
One Payroll

Per Payroll Period
```

Duplicate payroll generation is prohibited.

Duplicate salary payment is prohibited.

---

# Expense Rules

Successful salary payment creates:

```text id="ebr07"
Salary Expense
```

Exactly one Salary Expense corresponds to one successful payroll payment.

Duplicate expenses are prohibited.

---

# Historical Data Rule

Historical data must never be modified.

Includes:

* Attendance.
* Payroll History.
* Salary Payments.
* Salary Expenses.

Future corrections should be implemented through adjustment records rather than editing historical records.

---

# Report Rules

Reports are always:

✔ Generated dynamically.

Reports never:

* Modify business data.
* Store calculated totals.
* Override source records.

---

# Dashboard Rules

Dashboard consumes:

* Attendance Reports.
* Payroll Reports.
* Employee Reports.

Dashboard never performs independent financial calculations.

---

# Firestore Rules

Firestore is the only persistence layer.

Employee Management does not use:

* Offline Queue.
* Deferred Synchronization.
* Local Attendance Storage.
* Local Payroll Storage.

All successful operations are written directly to Firestore.

---

# Internet Rules

Employee Management requires an active internet connection.

The following operations require connectivity:

* Create Employee
* Edit Employee
* Delete Employee
* Check-In
* Check-Out
* Salary Calculation
* Salary Payment
* Salary Advance
* Bonus Management
* Reports

If internet is unavailable:

The operation fails safely.

No partial write occurs.

---

# Validation Rules

Before every write operation:

Validate:

* Employee exists.
* Employee is Active (when applicable).
* User has permission.
* Required data exists.
* Firestore available.
* Business rules satisfied.

Invalid operations are rejected before writing.

---

# Duplicate Protection

The system prevents:

* Duplicate employee creation.
* Duplicate attendance.
* Duplicate payroll generation.
* Duplicate salary payment.
* Duplicate financial transactions.
* Duplicate requests caused by rapid user interaction.

---

# Error Recovery

If an operation fails:

* No partial attendance record is created.
* No partial payroll record is created.
* No orphan expense is created.
* Dashboard remains consistent.
* Reports remain consistent.

Users receive localized error messages.

---

# Performance Rules

Employee Management is optimized using:

* Firestore indexes.
* Pagination.
* Lazy loading.
* Debounced searching.
* Incremental Cubit updates.

Supports organizations with thousands of employees.

---

# Security Rules

Every operation requires:

* Authenticated account.
* Active subscription.
* Authorized workspace.

Future role-based permissions:

* Owner
* HR
* Accountant
* Manager

---

# Edge Case 1

Employee deleted after years of work.

Result:

* Historical attendance remains.
* Historical payroll remains.
* Historical expenses remain.
* Future operations blocked.

---

# Edge Case 2

Duplicate Check-In.

Result:

Rejected.

Attendance remains unchanged.

---

# Edge Case 3

Check-Out without Check-In.

Result:

Rejected.

No attendance record created.

---

# Edge Case 4

Salary already paid.

Result:

Second payment rejected.

No duplicate expense created.

---

# Edge Case 5

Payroll already generated.

Result:

Second payroll generation rejected.

---

# Edge Case 6

Multiple bonuses.

Result:

All bonuses included in salary calculation according to business rules implemented by the Payroll Engine.

---

# Edge Case 7

Multiple salary advances.

Result:

Total advances are aggregated and deducted automatically.

---

# Edge Case 8

Internet disconnected during operation.

Result:

Operation fails safely.

No partial data is written.

---

# Edge Case 9

Weekend configuration changes.

Result:

Future payroll periods use the new configuration.

Historical payroll remains unchanged.

---

# Edge Case 10

Expected Working Days updated.

Result:

Future salary calculations use the updated configuration.

Historical salary history remains immutable.

---

# Final Business Rules Summary

* Employee Profile is the source of employee information.
* Attendance Records are the source of attendance.
* Salary Calculation derives payroll values.
* Payroll History stores completed payroll.
* Salary Expenses belong to the Expenses module.
* Dashboard consumes reports only.
* Reports are dynamically generated.
* Historical records are immutable.
* Duplicate financial operations are prohibited.
* Employee Management operates online only.
* Firestore is the single source of persistence.
* Business logic resides exclusively in UseCases.
* UI is responsible only for presentation.

---

# Complete Employee Management Architecture

```text id="ebr08"
Employee Profile

↓

Attendance

↓

Salary Calculation

↓

Bonus

↓

Salary Advances

↓

Payroll Engine

↓

Salary Payment

↓

Payroll History

↓

Salary Expense

↓

Reports Engine

↓

Dashboard
```

---

# End of PART 8 — Employee Management

The Employee Management module is now fully documented, covering:

* Employee lifecycle
* Attendance management
* Payroll engine
* Salary calculation
* Salary payment
* Salary advances
* Bonuses
* Reports
* Business rules
* Financial integrity
* Security
* Architectural guarantees

---

# Next Part

**PART 9 — PlayStation Module**

This section documents the complete PlayStation management system, including rooms, devices, gaming sessions, live timers, countdowns, pause/resume, automatic session ending, price calculation, revenue tracking, session history, reporting, and all business rules governing PlayStation operations.
# PART 9 — PlayStation Module

# 9.1 Module Overview

## Overview

The **PlayStation Module** enables businesses such as gaming cafés and entertainment centers to manage PlayStation rooms, gaming devices, customer sessions, pricing, and revenue.

The module is designed to automate the complete lifecycle of a gaming session, from the moment a customer starts playing until the session is closed and its revenue is recorded.

It minimizes manual calculations, reduces operational mistakes, and provides accurate financial reporting.

---

# Objectives

The PlayStation Module allows businesses to:

* Manage PlayStation rooms.
* Manage gaming devices.
* Start customer sessions.
* Track live playing time.
* Automatically calculate session prices.
* Record revenue.
* Generate reports.
* Monitor device availability.

---

# Supported Businesses

The module is suitable for:

* PlayStation Cafés
* Gaming Centers
* Console Rental Shops
* Entertainment Lounges

Future support:

* VR Rooms
* PC Gaming Rooms
* Xbox
* Nintendo Switch

---

# Source of Truth

PlayStation operations depend on:

```text id="ps01"
Gaming Sessions
```

Revenue is always calculated from completed sessions.

Dashboard values are derived from session history.

---

# Main Components

The PlayStation Module consists of:

* Rooms
* Devices
* Sessions
* Timer
* Price Calculation
* Revenue
* Reports

Each component has a dedicated responsibility.

---

# Session Lifecycle

Every gaming session follows:

```text id="ps02"
Select Room

↓

Select Device

↓

Start Session

↓

Live Timer

↓

Pause / Resume (Optional)

↓

End Session

↓

Price Calculation

↓

Revenue Record

↓

Reports

↓

Dashboard
```

Every completed session becomes a permanent historical record.

---

# Device States

Each PlayStation device may have one of the following states:

```text id="ps03"
Available

Occupied

Maintenance (Future)

Disabled (Future)
```

Only **Available** devices may start new sessions.

---

# Revenue Relationship

Completed gaming sessions automatically contribute to:

* Daily Revenue
* Weekly Revenue
* Monthly Revenue
* Dashboard Statistics
* Financial Reports

No manual revenue entry is required.

---

# Reports Integration

The PlayStation Module contributes to:

* Daily Reports
* Weekly Reports
* Monthly Reports
* Revenue Reports

Future:

* Device Utilization Reports
* Peak Hour Reports
* Customer Statistics

---

# Dashboard Integration

Dashboard displays:

* Active Sessions
* Available Devices
* Occupied Devices
* Today's Revenue

Statistics refresh automatically.

---

# Internet Requirement

The PlayStation Module requires:

* Active internet connection.
* Firestore availability.

The module operates online only.

---

# Security

Access requires:

* Authenticated account.
* Active subscription.
* Authorized workspace.

Future permissions:

* Owner
* Manager
* Cashier

---

# Performance

Optimizations:

* Efficient Firestore queries.
* Incremental Cubit updates.
* Lazy loading.
* Automatic dashboard refresh.

Supports gaming centers with many rooms and devices.

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

---

# Business Rules

* Every session belongs to one device.
* Every device belongs to one room.
* Revenue is generated only after session completion.
* Dashboard consumes session data.
* Reports are generated dynamically.
* Firestore is the single source of truth.
* The PlayStation Module currently operates online only.

---

# Architecture

```text id="ps04"
Rooms

↓

Devices

↓

Gaming Session

↓

Timer

↓

Price Calculation

↓

Revenue

↓

Reports

↓

Dashboard
```

---

# End of Section

Next Section:

**9.2 Rooms**

This section documents room management, room creation, room updates, room deletion, room organization, room capacity, device assignment, reporting, and all business rules governing PlayStation rooms.
# PART 9 — PlayStation Module

# 9.2 Rooms

## Overview

The **Rooms** module organizes PlayStation devices into logical locations inside the gaming center.

A room represents a physical area containing one or more gaming devices.

Examples:

* VIP Room
* Standard Room
* Family Room
* Tournament Room

Rooms improve organization, simplify device management, and make reports easier to understand.

---

# Objectives

The Rooms module allows administrators to:

* Create gaming rooms.
* Edit room information.
* Delete unused rooms.
* Organize PlayStation devices.
* Monitor room occupancy.
* Generate room-based reports.

---

# Source of Truth

Room information is stored in Firestore.

Every room has its own document.

Devices reference the room they belong to.

The room itself does **not** store device information directly.

Relationships are maintained through Device records.

---

# Room Information

Each room contains:

* Room ID
* Room Name
* Description (Optional)
* createdAt

Future fields:

* Display Order
* Capacity
* Room Type
* Color Theme
* Notes

---

# Room Lifecycle

```text id="rm01"
Create Room

↓

Assign Devices

↓

Operate Sessions

↓

Generate Reports

↓

Archive / Delete (If Allowed)
```

---

# Room Creation

Administrators can create a room by providing:

Required:

* Room Name

Optional:

* Description

Validation:

* Room Name is required.
* Room Name must be unique.
* Internet connection available.

---

# Edit Room

Editable fields:

* Room Name
* Description

The Room ID never changes.

Editing a room never affects:

* Existing gaming sessions.
* Revenue history.
* Historical reports.

---

# Delete Room

Before deletion:

Validate:

* Room exists.
* No active gaming sessions.
* No devices assigned.

If devices are still assigned:

Reject deletion.

Display:

```text id="rm02"
This room still contains assigned devices.

Please move or remove all devices before deleting the room.
```

---

# Device Assignment

Each PlayStation device belongs to:

```text id="rm03"
One Room
```

A room may contain:

```text id="rm04"
Many Devices
```

Relationship:

```text
Room 1

↓

Device A

Device B

Device C
```

---

# Active Sessions

A room may contain multiple active sessions simultaneously.

Example:

Room A

↓

PS1 → Active

PS2 → Active

PS3 → Available

Room statistics update automatically.

---

# Reports Integration

Rooms contribute to:

* Revenue Reports
* Session Reports
* Device Utilization Reports (Future)

Future reports may compare room performance.

---

# Dashboard Integration

Dashboard displays:

* Total Rooms
* Active Rooms
* Devices Per Room
* Active Sessions Per Room (Future)

Statistics refresh automatically.

---

# Searching

Search supports:

* Room Name

Future:

* Description
* Room Type

Search uses debounce for optimal performance.

---

# Sorting

Supported sorting:

* Room Name
* Creation Date

Future:

* Device Count
* Revenue
* Active Sessions

---

# Validation

Before saving:

Validate:

* Room Name not empty.
* Room Name unique.
* Firestore available.

Reject invalid operations.

---

# Internet Requirement

Room management requires:

* Active internet connection.
* Firestore availability.

The PlayStation Module currently operates online only.

---

# Error Handling

Examples:

```text id="rm05"
Room Already Exists

Room Not Found

Unable to Save Room

Unable to Delete Room

Network Error
```

No partial room data is created.

---

# Loading State

During create/update/delete:

* Disable action buttons.
* Display loading indicator.
* Prevent duplicate requests.

---

# Performance

Optimizations:

* Indexed room queries.
* Lazy loading.
* Incremental Cubit updates.
* Minimal Firestore reads.

Supports gaming centers with many rooms.

---

# Security

Room management requires:

* Authenticated account.
* Active subscription.
* PlayStation Management permission.

Future permissions:

* Owner
* Manager

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

---

# Business Rules

* Every room has one unique ID.
* Room names must be unique.
* A room may contain multiple devices.
* A device belongs to only one room.
* Rooms with assigned devices cannot be deleted.
* Historical gaming sessions remain unchanged after room edits.
* Reports derive room information dynamically.
* Dashboard updates automatically.
* The PlayStation Module currently operates online only.
* Firestore is the single source of truth.

---

# Architecture

```text id="rm06"
Rooms

↓

Devices

↓

Gaming Sessions

↓

Revenue

↓

Reports

↓

Dashboard
```

---

# End of Section

Next Section:

**9.3 Devices**

This section documents PlayStation device management, device creation, editing, deletion, room assignment, pricing configuration, availability status, validation rules, and all business rules governing gaming devices.
# PART 9 — PlayStation Module

# 9.3 Devices

## Overview

The **Devices** module manages every gaming console available inside the PlayStation business.

A device represents a physical gaming station that customers use during gaming sessions.

Examples:

* PlayStation 5 #1
* PlayStation 5 #2
* PlayStation 4 Pro #1

Each device belongs to exactly one room and may have its own pricing configuration.

Devices are the primary resource used when creating gaming sessions.

---

# Objectives

The Devices module allows administrators to:

* Add gaming devices.
* Edit device information.
* Delete unused devices.
* Assign devices to rooms.
* Configure pricing.
* Monitor device availability.
* Track device utilization.

---

# Source of Truth

Device information is stored in Firestore.

Every device has its own document.

Gaming Sessions reference Device IDs.

Historical sessions never duplicate device information.

---

# Device Information

Each device contains:

* Device ID
* Device Name
* Room ID
* Device Status
* Hourly Price
* createdAt

Future fields:

* Device Type
* Serial Number
* Purchase Date
* Maintenance Notes
* Display Order

---

# Device Lifecycle

```text id="dv01"
Create Device

↓

Assign Room

↓

Configure Pricing

↓

Receive Sessions

↓

Generate Revenue

↓

Reports

↓

Archive / Delete
```

---

# Device Creation

Required information:

* Device Name
* Assigned Room
* Hourly Price

Validation:

* Device Name required.
* Device Name unique.
* Hourly Price greater than zero.
* Room exists.

---

# Edit Device

Editable fields:

* Device Name
* Assigned Room
* Hourly Price
* Status

Device ID never changes.

Historical sessions remain unaffected.

---

# Delete Device

Before deletion:

Validate:

* Device exists.
* No active session.

If an active session exists:

Reject deletion.

Display:

```text id="dv02"
Cannot delete a device while a gaming session is active.
```

Historical sessions remain preserved.

---

# Device Status

Current supported statuses:

```text id="dv03"
Available

Occupied
```

Future statuses:

```text id="dv04"
Maintenance

Disabled

Reserved
```

Only **Available** devices may start new gaming sessions.

---

# Room Relationship

Each device belongs to:

```text id="dv05"
One Room
```

A room may contain multiple devices.

Moving a device between rooms affects only future sessions.

Historical sessions retain their original room information.

---

# Pricing Configuration

Each device has:

```text id="dv06"
Hourly Price
```

Example:

```text id="dv07"
40 EGP / Hour
```

Future pricing options:

* Half Hour
* Quarter Hour
* Daily Rate
* Weekend Pricing
* Holiday Pricing

---

# Gaming Session Relationship

Each gaming session references:

* Device ID

During an active session:

Device status automatically becomes:

```text id="dv08"
Occupied
```

When the session ends:

Status returns to:

```text id="dv09"
Available
```

This transition is automatic.

---

# Revenue Relationship

Device revenue is derived from:

Completed gaming sessions.

Revenue is never entered manually.

Future reports may display:

* Revenue Per Device
* Most Used Device
* Least Used Device

---

# Reports Integration

Devices contribute to:

* Revenue Reports
* Session Reports
* Device Usage Reports

Future:

* Maintenance Reports
* Profitability Reports

---

# Dashboard Integration

Dashboard displays:

* Total Devices
* Available Devices
* Occupied Devices

Future:

* Devices Under Maintenance
* Device Utilization Percentage

---

# Validation

Before saving:

Validate:

* Device Name unique.
* Room exists.
* Hourly Price valid.
* Internet connection available.
* Firestore available.

Reject invalid operations.

---

# Internet Requirement

Device management requires:

* Active internet connection.
* Firestore availability.

The PlayStation Module currently operates online only.

---

# Error Handling

Examples:

```text id="dv10"
Device Already Exists

Room Not Found

Invalid Price

Device Has Active Session

Network Error
```

No partial device record is created.

---

# Loading State

During create/update/delete:

* Disable action buttons.
* Display loading indicator.
* Prevent duplicate requests.

---

# Performance

Optimizations:

* Indexed Firestore queries.
* Incremental Cubit updates.
* Lazy loading.
* Minimal Firestore reads.

Supports gaming centers with hundreds of devices.

---

# Security

Device management requires:

* Authenticated account.
* Active subscription.
* PlayStation Management permission.

Future permissions:

* Owner
* Manager

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

---

# Business Rules

* Every device has one unique ID.
* Every device belongs to one room.
* Device names must be unique.
* Only Available devices may start sessions.
* Devices with active sessions cannot be deleted.
* Historical sessions are immutable.
* Revenue is derived from completed sessions.
* Dashboard updates automatically.
* Reports calculate dynamically.
* The PlayStation Module currently operates online only.
* Firestore is the single source of truth.

---

# Architecture

```text id="dv11"
Rooms

↓

Devices

↓

Gaming Sessions

↓

Price Calculation

↓

Revenue

↓

Reports

↓

Dashboard
```

---

# End of Section

Next Section:

**9.4 Gaming Sessions**

This section documents the complete gaming session lifecycle, including session creation, customer assignment, live status, validations, state transitions, and all business rules governing PlayStation gaming sessions.
# PART 9 — PlayStation Module

# 9.4 Gaming Sessions

## Overview

The **Gaming Sessions** module is the core of the PlayStation system.

Every customer interaction with a PlayStation device is represented as a gaming session.

A session begins when a customer starts using a device and ends when the session is completed.

All timing, pricing, revenue, and reporting depend on gaming sessions.

Gaming Sessions are the primary source of truth for the PlayStation Module.

---

# Objectives

The Gaming Sessions module allows businesses to:

* Start gaming sessions.
* Monitor live sessions.
* Track playing duration.
* Calculate pricing.
* Generate revenue.
* Produce historical reports.

---

# Source of Truth

Gaming Sessions are stored independently.

Every completed session becomes part of the permanent business history.

Revenue, reports, and dashboard statistics are always derived from session records.

---

# Session Lifecycle

Every gaming session follows:

```text id="gs01"
Available Device

↓

Start Session

↓

Running

↓

Pause (Optional)

↓

Resume

↓

End Session

↓

Price Calculation

↓

Revenue

↓

Reports
```

---

# Session Information

Each session contains:

* Session ID
* Device ID
* Room ID
* Customer Name (Optional)
* Start Time
* End Time
* Duration
* Total Price
* Session Status
* createdAt

Future fields:

* Discount
* Notes
* Operator
* Payment Method

---

# Session Creation

Administrator selects:

* Room
* Device

Optional:

* Customer Name

Then presses:

```text id="gs02"
Start Session
```

Validation begins before session creation.

---

# Validation

Before creating a session:

Validate:

* Device exists.
* Device status is Available.
* Room exists.
* Internet connection available.
* Firestore available.

If validation fails:

Session is not created.

---

# Device Locking

Immediately after session creation:

Device status changes to:

```text id="gs03"
Occupied
```

No additional session may start on that device.

---

# Session Status

Current statuses:

```text id="gs04"
Running

Paused

Completed
```

Future:

```text id="gs05"
Cancelled

Expired

Reserved
```

---

# Active Sessions

An active session is any session with status:

```text id="gs06"
Running

or

Paused
```

Completed sessions become historical records.

---

# Customer Name

Customer Name is optional.

Examples:

```text id="gs07"
Ahmed

Mohamed

Walk-in Customer
```

Future:

Customer Account Integration.

---

# Session Duration

Duration is always calculated dynamically.

Formula:

```text id="gs08"
End Time

-

Start Time
```

Duration is never entered manually.

---

# Revenue Relationship

Revenue is generated only after:

```text id="gs09"
Completed Session
```

Running sessions do not contribute to financial reports.

---

# Reports Integration

Gaming Sessions contribute to:

* Daily Reports
* Weekly Reports
* Monthly Reports
* Revenue Reports

Future:

* Peak Hours
* Device Usage
* Customer Statistics

---

# Dashboard Integration

Dashboard displays:

* Active Sessions
* Completed Sessions Today
* Revenue Today

Values refresh automatically.

---

# Historical Integrity

Completed sessions become immutable.

Historical sessions are never edited.

Future corrections should create adjustment records instead of modifying completed sessions.

---

# Internet Requirement

Gaming Sessions require:

* Active internet connection.
* Firestore availability.

The PlayStation Module currently operates online only.

---

# Error Handling

Examples:

```text id="gs10"
Device Unavailable

Session Already Running

Unable to Start Session

Network Error
```

No partial session is created.

---

# Loading State

During session creation:

* Disable Start button.
* Display loading indicator.
* Prevent duplicate requests.

---

# Performance

Optimizations:

* Indexed Firestore queries.
* Incremental Cubit updates.
* Efficient session lookup.
* Minimal Firestore writes.

Supports hundreds of simultaneous gaming sessions.

---

# Security

Gaming Sessions require:

* Authenticated account.
* Active subscription.
* PlayStation Management permission.

Future permissions:

* Owner
* Manager
* Cashier

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

---

# Business Rules

* One device may have only one active session.
* Only Available devices may start sessions.
* Session duration is always derived.
* Revenue is generated only after session completion.
* Historical sessions are immutable.
* Dashboard consumes session data.
* Reports derive information dynamically.
* The PlayStation Module currently operates online only.
* Firestore is the single source of truth.

---

# Architecture

```text id="gs11"
Device

↓

StartSessionUseCase

↓

Gaming Session

↓

Live Timer

↓

Price Calculation

↓

Revenue

↓

Reports

↓

Dashboard
```

---

# End of Section

Next Section:

**9.5 Live Timer**

This section documents the real-time session timer, elapsed time tracking, automatic UI updates, synchronization rules, timer recovery after app restart, and all business rules governing active gaming sessions.
# PART 9 — PlayStation Module

# 9.5 Live Timer

## Overview

The **Live Timer** is responsible for displaying the real-time duration of every active gaming session.

The timer begins immediately after a gaming session starts and continues updating until the session ends.

Unlike a traditional stopwatch, the Live Timer is **derived from timestamps**, not from continuously stored elapsed seconds.

This design guarantees accurate timing even if:

* The application is restarted.
* The page is refreshed.
* The device temporarily loses internet connectivity.
* The timer widget rebuilds.

---

# Objectives

The Live Timer allows businesses to:

* Display elapsed play time.
* Monitor active sessions.
* Calculate pricing accurately.
* Recover automatically after app restart.
* Prevent timer drift.

---

# Source of Truth

The Live Timer depends on:

```text id="lt01"
Session Start Time

+

Current Time
```

Elapsed time is never stored.

The timer is always calculated dynamically.

---

# Timer Formula

Formula:

```text id="lt02"
Elapsed Time

=

Current Time

-

Session Start Time
```

Example:

```text id="lt03"
Start

15:00

Current

16:20

↓

Elapsed

1 Hour

20 Minutes
```

---

# Timer Start

The timer starts immediately after:

```text id="lt04"
Start Session
```

The session status becomes:

```text id="lt05"
Running
```

---

# UI Refresh

The timer updates continuously while the session is active.

Only the timer widget should rebuild.

The rest of the screen should remain unchanged.

This minimizes unnecessary UI rebuilds.

---

# Application Restart Recovery

If the application closes unexpectedly:

The timer is recovered using:

```text id="lt06"
Session Start Time
```

Example:

Session started:

```text
10:00
```

Application reopened:

```text
11:30
```

Displayed timer:

```text
1 Hour

30 Minutes
```

No timer information is lost.

---

# Firestore Relationship

Firestore stores:

* Session Start Time
* Session End Time

Firestore never stores:

* Running seconds
* Timer counters
* Elapsed duration

Elapsed duration is always calculated.

---

# Multiple Active Timers

Each active session owns an independent timer.

Example:

```text id="lt07"
PS1

00:45

---

PS2

01:12

---

PS3

02:05
```

Timers operate independently.

---

# Pause Relationship

When a session is paused:

The timer stops increasing.

Resume continues from the paused duration.

Pause behavior is documented in the next section.

---

# End Session Relationship

When a session ends:

The timer stops permanently.

Final duration becomes part of:

* Session History
* Revenue Calculation
* Reports

---

# Price Calculation Relationship

Price Calculation consumes:

```text id="lt08"
Elapsed Time
```

Live Timer itself does not calculate prices.

It only provides accurate duration.

---

# Reports Integration

Completed timer values contribute to:

* Session Reports
* Revenue Reports
* Daily Reports
* Monthly Reports

---

# Dashboard Integration

Dashboard may display:

* Number of Active Sessions
* Longest Active Session (Future)

Dashboard never maintains its own timer.

---

# Validation

Before updating:

Validate:

* Session exists.
* Session status is Running.
* Session not completed.

Completed sessions never continue counting.

---

# Internet Requirement

Live Timer requires:

* Active session.
* Firestore synchronization.

The displayed timer is calculated locally using stored timestamps.

If Firestore becomes temporarily unavailable:

The timer continues using the existing session timestamps.

Synchronization resumes automatically once connectivity returns.

---

# Error Handling

Examples:

```text id="lt09"
Session Not Found

Invalid Session

Unable to Load Session
```

Timer stops gracefully if the session becomes invalid.

---

# Performance

Optimizations:

* Rebuild only timer widgets.
* Avoid rebuilding the entire session list.
* Derive elapsed time instead of writing updates to Firestore.
* No continuous Firestore writes.
* No unnecessary database traffic.

Supports many simultaneous active sessions efficiently.

---

# Security

Timer visibility requires:

* Authenticated account.
* Active subscription.
* PlayStation Management permission.

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

Time formatting follows the selected locale.

---

# Business Rules

* Live Timer always derives elapsed time from timestamps.
* Timer never stores elapsed seconds.
* Session Start Time is immutable.
* Completed sessions stop permanently.
* Each active session has an independent timer.
* Timer survives application restart.
* Timer does not generate revenue directly.
* Price Calculation consumes elapsed time.
* The PlayStation Module currently operates online only.
* Firestore is the single source of truth for session timestamps.

---

# Architecture

```text id="lt10"
Session Start Time

↓

LiveTimerUseCase

↓

Elapsed Time

↓

UI Timer

↓

Price Calculation

↓

Revenue

↓

Reports

↓

Dashboard
```

---

# End of Section

Next Section:

**9.6 Countdown Timer**

This section documents countdown sessions, fixed-duration gameplay, automatic session completion, countdown synchronization, pricing behavior, and all business rules governing countdown-based gaming sessions.
# PART 9 — PlayStation Module

# 9.6 Countdown Timer

## Overview

The **Countdown Timer** is used for gaming sessions that have a predefined duration.

Unlike the Live Timer, which measures elapsed playing time, the Countdown Timer measures the **remaining time** until the purchased session expires.

This mode is commonly used for:

* 30-minute sessions.
* 1-hour sessions.
* 2-hour sessions.
* Prepaid gaming packages.

The Countdown Timer automatically ends the session when the remaining time reaches zero.

---

# Objectives

The Countdown Timer allows businesses to:

* Sell fixed-duration sessions.
* Display remaining play time.
* Automatically end expired sessions.
* Prevent overtime.
* Improve operational automation.

---

# Source of Truth

Countdown Timer depends on:

```text id="cd01"
Session Start Time

+

Purchased Duration
```

Remaining time is always derived.

It is never stored in Firestore.

---

# Timer Formula

Formula:

```text id="cd02"
Remaining Time

=

Purchased Duration

-

(Current Time

-

Session Start Time)
```

Example:

```text id="cd03"
Purchased

2 Hours

Elapsed

35 Minutes

↓

Remaining

1 Hour

25 Minutes
```

---

# Session Creation

Administrator selects:

* Room
* Device
* Purchased Duration

Examples:

```text id="cd04"
30 Minutes

1 Hour

2 Hours

3 Hours
```

The timer starts immediately after the session begins.

---

# Countdown Display

The UI displays:

```text id="cd05"
Remaining Time
```

Example:

```text id="cd06"
01:18:42
```

The countdown updates continuously while the session is running.

---

# Timer Completion

When:

```text id="cd07"
Remaining Time

=

00:00:00
```

The system automatically performs:

```text id="cd08"
End Session

↓

Price Calculation

↓

Revenue Recording

↓

Device Available
```

No manual intervention is required.

---

# Automatic Session Ending

Automatic ending performs:

* Stop timer.
* Mark session Completed.
* Save End Time.
* Calculate duration.
* Generate revenue.
* Update dashboard.
* Free the device.

All operations occur atomically.

---

# Device Relationship

While countdown is active:

Device status:

```text id="cd09"
Occupied
```

After automatic completion:

Device status becomes:

```text id="cd10"
Available
```

---

# Live Timer Relationship

Countdown mode and Live Timer share:

* Session Start Time.
* Session History.
* Revenue Engine.

The difference:

Live Timer displays:

```text id="cd11"
Elapsed Time
```

Countdown Timer displays:

```text id="cd12"
Remaining Time
```

---

# Pause Relationship

If the session is paused:

Countdown stops decreasing.

Resume continues from the remaining duration.

Paused time is excluded from the countdown.

---

# Price Calculation

Current implementation:

Price is determined from the purchased duration.

Future support:

* Overtime Billing
* Extra Time Purchase
* Dynamic Extension

The architecture supports these enhancements.

---

# Reports Integration

Countdown sessions contribute to:

* Revenue Reports.
* Session Reports.
* Daily Reports.
* Monthly Reports.

Reports do not distinguish between Live Timer and Countdown sessions unless requested.

---

# Dashboard Integration

Dashboard displays:

* Active Countdown Sessions.
* Completed Sessions.
* Revenue.

Future KPI:

* Sessions Ending Soon.

---

# Restart Recovery

If the application restarts:

Remaining time is recalculated using:

* Session Start Time.
* Purchased Duration.

No timer information is lost.

---

# Validation

Before starting:

Validate:

* Device Available.
* Purchased Duration > 0.
* Session not already running.

Reject invalid sessions.

---

# Internet Requirement

Countdown sessions require:

* Active internet connection.
* Firestore availability.

Remaining time is calculated locally from timestamps.

---

# Error Handling

Examples:

```text id="cd13"
Invalid Duration

Device Busy

Unable to Start Session

Network Error
```

No partial session is created.

---

# Performance

Optimizations:

* Timer rebuilds only countdown widgets.
* No continuous Firestore writes.
* Remaining time calculated locally.
* Automatic completion writes only once.

Supports many simultaneous countdown sessions.

---

# Security

Countdown sessions require:

* Authenticated account.
* Active subscription.
* PlayStation Management permission.

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

Time formatting follows the selected language.

---

# Business Rules

* Countdown is always derived from timestamps.
* Remaining time is never stored.
* Purchased duration is immutable after session start.
* Session automatically ends at zero.
* Device becomes Available immediately after completion.
* Historical sessions are immutable.
* Revenue is generated only after completion.
* Countdown survives application restart.
* The PlayStation Module currently operates online only.
* Firestore is the single source of truth.

---

# Architecture

```text id="cd14"
Purchased Duration

+

Session Start Time

↓

CountdownTimerUseCase

↓

Remaining Time

↓

Automatic Session End

↓

Price Calculation

↓

Revenue

↓

Reports

↓

Dashboard
```

---

# End of Section

Next Section:

**9.7 Pause & Resume Sessions**

This section documents pausing active gaming sessions, resuming gameplay, timer synchronization, countdown preservation, live timer behavior, and all business rules governing session interruptions.
# PART 9 — PlayStation Module

# 9.7 Pause & Resume Sessions

## Overview

The **Pause & Resume** feature allows an active gaming session to be temporarily suspended without ending it.

This is useful when:

* The customer takes a short break.
* The controller is being replaced.
* The customer leaves temporarily.
* Technical issues occur.

A paused session remains active but stops accumulating billable time until it is resumed.

---

# Objectives

The Pause & Resume feature allows businesses to:

* Suspend an active session temporarily.
* Preserve elapsed gameplay time.
* Prevent charging customers during breaks.
* Continue the same session without creating a new one.
* Maintain accurate billing.

---

# Source of Truth

Pause & Resume depends on:

```text id="pr01"
Session Status

+

Pause Timestamp

+

Accumulated Duration
```

These values determine the current timer state.

---

# Session Lifecycle

```text id="pr02"
Start Session

↓

Running

↓

Pause

↓

Paused

↓

Resume

↓

Running

↓

End Session
```

A session may be paused and resumed multiple times before completion.

---

# Pause Operation

When the administrator presses:

```text id="pr03"
Pause
```

The system performs:

* Change session status to **Paused**.
* Save Pause Timestamp.
* Preserve accumulated duration.
* Stop timer updates.
* Keep device status as **Occupied**.

The session is **not** completed.

---

# Resume Operation

When the administrator presses:

```text id="pr04"
Resume
```

The system performs:

* Change session status to **Running**.
* Save Resume Timestamp.
* Continue timer from previous accumulated duration.
* Resume billing time.

No new session is created.

---

# Timer Relationship

## Live Timer

While paused:

Elapsed gameplay remains constant.

Example:

```text id="pr05"
Paused At

01:32:15
```

The timer remains:

```text id="pr06"
01:32:15
```

until resumed.

---

## Countdown Timer

While paused:

Remaining time remains constant.

Example:

```text id="pr07"
Remaining

00:48:10
```

The countdown does not decrease until the session resumes.

---

# Billing Relationship

Paused duration is **excluded** from billable time.

Formula:

```text id="pr08"
Billable Time

=

Running Duration Only
```

Breaks never increase the final session price.

---

# Multiple Pause Cycles

A session may contain:

```text id="pr09"
Run

↓

Pause

↓

Resume

↓

Pause

↓

Resume

↓

End
```

All pause intervals are excluded from billing.

---

# Device Relationship

While paused:

Device status remains:

```text id="pr10"
Occupied
```

The device cannot be assigned to another session.

Only after session completion does it become:

```text id="pr11"
Available
```

---

# Session History

Session History stores:

* Total Running Time.
* Total Paused Time (Future).
* Pause Count (Future).

Historical sessions remain immutable.

---

# Reports Integration

Pause information contributes to:

Future reports:

* Average Pause Time.
* Device Idle Analysis.
* Customer Break Statistics.

Current revenue reports are based only on billable time.

---

# Dashboard Integration

Dashboard displays:

Future statistics:

* Running Sessions.
* Paused Sessions.

Current implementation counts paused sessions as active sessions.

---

# Restart Recovery

If the application restarts while a session is paused:

The session is restored using:

* Session Status.
* Pause Timestamp.
* Accumulated Duration.

The timer remains paused until Resume is executed.

---

# Validation

Before pausing:

Validate:

* Session exists.
* Session status is Running.

Before resuming:

Validate:

* Session exists.
* Session status is Paused.

Invalid transitions are rejected.

---

# Internet Requirement

Pause & Resume requires:

* Active internet connection.
* Firestore availability.

The PlayStation Module currently operates online only.

---

# Error Handling

Examples:

```text id="pr12"
Session Not Found

Session Already Paused

Session Already Running

Unable to Resume

Network Error
```

No partial state transition occurs.

---

# Loading State

During Pause or Resume:

* Disable action buttons.
* Display loading indicator.
* Prevent duplicate requests.

---

# Performance

Optimizations:

* Single Firestore update per state transition.
* No continuous writes while paused.
* Incremental Cubit updates.
* Timer widget rebuild only.

Supports many concurrent sessions efficiently.

---

# Security

Pause & Resume requires:

* Authenticated account.
* Active subscription.
* PlayStation Management permission.

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

---

# Business Rules

* Only Running sessions may be paused.
* Only Paused sessions may be resumed.
* Pause never creates a new session.
* Paused time is excluded from billing.
* Devices remain Occupied while paused.
* Historical sessions remain immutable.
* Revenue depends only on running time.
* Timer state survives application restart.
* The PlayStation Module currently operates online only.
* Firestore is the single source of truth.

---

# Architecture

```text id="pr13"
Gaming Session

↓

PauseResumeUseCase

↓

Session Status

↓

Timer Engine

↓

Price Calculation

↓

Revenue

↓

Reports

↓

Dashboard
```

---

# End of Section

Next Section:

**9.8 End Session**

This section documents manual session completion, automatic completion, final duration calculation, revenue generation, device release, session history, and all business rules governing gaming session termination.
# PART 9 — PlayStation Module

# 9.8 End Session

## Overview

The **End Session** feature completes an active gaming session and permanently records its financial and operational data.

Ending a session is one of the most critical operations in the PlayStation Module because it:

* Stops the timer.
* Finalizes the playing duration.
* Calculates the session price.
* Records business revenue.
* Releases the gaming device.
* Creates a permanent historical record.

Once a session is completed, it becomes immutable.

---

# Objectives

The End Session feature allows businesses to:

* Finish customer sessions.
* Generate accurate revenue.
* Release occupied devices.
* Preserve complete session history.
* Update reports and dashboard statistics automatically.

---

# Source of Truth

Session completion depends on:

```text id="es01"
Session Start Time

+

Session End Time

+

Session Status
```

The final duration is always derived dynamically.

---

# Session Completion Flow

```text id="es02"
Running Session

↓

End Session

↓

Calculate Duration

↓

Calculate Price

↓

Generate Revenue

↓

Save Session History

↓

Release Device

↓

Refresh Dashboard
```

All operations execute as a single business transaction.

---

# End Types

The system supports:

### Manual End

Administrator presses:

```text id="es03"
End Session
```

---

### Automatic End

Used by:

* Countdown Sessions.

When remaining time reaches zero:

The system automatically executes the same completion flow.

Both paths produce identical business results.

---

# End Validation

Before ending a session:

Validate:

* Session exists.
* Session status is Running or Paused.
* Device exists.
* Internet connection available.
* Firestore available.

If validation fails:

The session remains active.

---

# Duration Calculation

Formula:

```text id="es04"
End Time

-

Start Time

-

Paused Duration
```

Paused intervals are excluded.

Duration is never entered manually.

---

# Price Calculation

After duration is determined:

Price Calculation Engine computes:

```text id="es05"
Final Price
```

Current pricing depends on:

* Hourly Price.
* Billable Duration.

Future pricing may include:

* Discounts.
* Overtime.
* Promotions.
* Holiday Pricing.

---

# Revenue Generation

Successful completion automatically generates:

```text id="es06"
Revenue Record
```

Revenue becomes available in:

* Daily Reports.
* Monthly Reports.
* Dashboard Statistics.

No manual revenue entry is required.

---

# Device Release

Immediately after completion:

Device status changes from:

```text id="es07"
Occupied
```

to:

```text id="es08"
Available
```

The device becomes ready for a new customer.

---

# Session History

Completed session stores:

* Session ID.
* Room ID.
* Device ID.
* Start Time.
* End Time.
* Duration.
* Final Price.
* Customer Name (Optional).
* createdAt.

Historical session data is immutable.

---

# Reports Integration

Completed sessions contribute to:

* Revenue Reports.
* Session Reports.
* Daily Reports.
* Weekly Reports.
* Monthly Reports.

Future:

* Device Utilization Reports.
* Peak Hour Analysis.

---

# Dashboard Integration

Dashboard refreshes automatically:

* Active Sessions decreases.
* Completed Sessions increases.
* Revenue increases.
* Available Devices increases.

No manual refresh is required.

---

# Restart Recovery

If the application closes before session completion:

The session remains active.

After reopening:

The administrator may continue or end the session normally.

No session information is lost.

---

# Internet Requirement

Ending a session requires:

* Active internet connection.
* Firestore availability.

The PlayStation Module currently operates online only.

---

# Error Handling

Examples:

```text id="es09"
Session Not Found

Session Already Completed

Unable to Calculate Price

Unable to End Session

Network Error
```

No partial completion occurs.

Revenue is never generated twice.

---

# Loading State

During completion:

* Disable End button.
* Display loading indicator.
* Prevent duplicate requests.

---

# Duplicate Protection

If:

```text id="es10"
End Session
```

is pressed multiple times:

Only the first request succeeds.

Subsequent requests are ignored.

Duplicate revenue generation is impossible.

---

# Performance

Optimizations:

* Single Firestore transaction.
* Single dashboard refresh.
* Incremental Cubit updates.
* Minimal database writes.

Supports many concurrent session completions.

---

# Security

Ending sessions requires:

* Authenticated account.
* Active subscription.
* PlayStation Management permission.

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

---

# Business Rules

* Running and Paused sessions may be completed.
* Completed sessions become immutable.
* Revenue is generated exactly once.
* Device becomes Available immediately after completion.
* Duration is always derived dynamically.
* Price Calculation occurs after duration calculation.
* Dashboard refreshes automatically.
* Reports derive revenue dynamically.
* The PlayStation Module currently operates online only.
* Firestore is the single source of truth.

---

# Architecture

```text id="es11"
Gaming Session

↓

EndSessionUseCase

↓

Duration Calculation

↓

Price Calculation

↓

Revenue Record

↓

Session History

↓

Device Release

↓

Reports

↓

Dashboard
```

---

# End of Section

Next Section:

**9.9 Manual End vs Automatic End**

This section documents the differences between administrator-initiated session completion and automatically completed countdown sessions, including execution flow, validation, revenue generation, and all business rules governing both completion methods.
# PART 9 — PlayStation Module

# 9.9 Manual End vs Automatic End

## Overview

Gaming sessions may finish in one of two ways:

1. **Manual End** — initiated by the administrator.
2. **Automatic End** — initiated by the system.

Although the trigger is different, both methods must produce **exactly the same business result**.

Regardless of how the session ends, the system must:

* Calculate the final duration.
* Calculate the final price.
* Generate revenue.
* Save session history.
* Release the device.
* Refresh reports and dashboard.

The only difference is **who initiated the completion**.

---

# Objectives

This feature ensures:

* Consistent business behavior.
* No duplicated logic.
* Reliable revenue generation.
* Unified session completion.
* Predictable reporting.

---

# Manual End

Manual End occurs when an administrator presses:

```text id="me01"
End Session
```

Typical scenarios:

* Customer finishes early.
* Customer requests to stop.
* Staff manually closes the session.

The administrator decides when the session ends.

---

# Automatic End

Automatic End occurs without administrator interaction.

Current implementation:

```text id="me02"
Countdown Timer

↓

Remaining Time

=

00:00

↓

End Session Automatically
```

The system detects timer expiration and immediately completes the session.

---

# Shared Completion Flow

Both Manual and Automatic End execute:

```text id="me03"
Stop Timer

↓

Calculate Duration

↓

Calculate Price

↓

Generate Revenue

↓

Save Session History

↓

Release Device

↓

Refresh Reports

↓

Refresh Dashboard
```

This flow must always remain identical.

---

# Business Logic Rule

Both completion methods must call:

```text id="me04"
EndSessionUseCase
```

Business logic must never be duplicated.

The UI only decides **when** to invoke the UseCase.

The UseCase determines **how** completion is processed.

---

# Duration Calculation

Both methods derive:

```text id="me05"
Final Duration
```

using:

* Session Start Time.
* Session End Time.
* Paused Duration.

No manual duration entry is allowed.

---

# Price Calculation

Both methods use:

```text id="me06"
PriceCalculationUseCase
```

Price calculation is completely independent of:

* Manual End.
* Automatic End.

Only duration matters.

---

# Revenue Generation

Revenue generation occurs exactly once.

Formula:

```text id="me07"
Completed Session

↓

Revenue Record
```

Revenue never depends on the completion trigger.

---

# Session History

Historical records are identical.

Stored fields include:

* Start Time.
* End Time.
* Duration.
* Price.
* Device.
* Room.
* Customer Name.
* createdAt.

No distinction is required unless future analytics demand it.

Future enhancement:

```text id="me08"
Completion Method

Manual

Automatic
```

---

# Device Release

Regardless of completion type:

Device status becomes:

```text id="me09"
Available
```

The device immediately becomes eligible for another session.

---

# Reports Integration

Reports consume:

Completed Sessions only.

They do not distinguish between:

* Manual End.
* Automatic End.

Future analytics may provide completion statistics.

---

# Dashboard Integration

Dashboard updates identically after both completion methods.

Statistics include:

* Active Sessions.
* Revenue.
* Available Devices.

No special dashboard logic exists for either completion type.

---

# Restart Recovery

If the application closes:

### Manual Sessions

Remain active until manually completed.

---

### Countdown Sessions

Upon reopening:

The system recalculates remaining time.

If the countdown already expired:

Automatic completion is executed immediately.

No expired countdown session remains active.

---

# Validation

Before completion:

Validate:

* Session exists.
* Session not already completed.
* Device exists.
* Firestore available.

Invalid requests are rejected.

---

# Duplicate Protection

Whether completion is triggered:

* Automatically.
* Manually.

The system guarantees:

```text id="me10"
One Session

↓

One Completion

↓

One Revenue Record
```

Duplicate completion is impossible.

---

# Internet Requirement

Both completion methods require:

* Active internet connection.
* Firestore availability.

The PlayStation Module currently operates online only.

---

# Error Handling

Examples:

```text id="me11"
Session Already Completed

Unable to Complete Session

Revenue Generation Failed

Network Error
```

The session remains consistent if any validation fails.

---

# Performance

Optimizations:

* Shared EndSessionUseCase.
* Single Firestore transaction.
* Single dashboard refresh.
* Incremental Cubit updates.

No duplicated execution path exists.

---

# Security

Session completion requires:

* Authenticated account.
* Active subscription.
* PlayStation Management permission.

Automatic completion executes with the same business rules as manual completion.

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

---

# Business Rules

* Manual End and Automatic End must produce identical results.
* Both methods use the same EndSessionUseCase.
* Revenue is generated exactly once.
* Session History is immutable.
* Device becomes Available immediately after completion.
* Reports consume completed sessions only.
* Dashboard refreshes automatically.
* Duplicate completion is prohibited.
* The PlayStation Module currently operates online only.
* Firestore is the single source of truth.

---

# Architecture

```text id="me12"
Manual End

──────────┐

Automatic End

──────────┘

↓

EndSessionUseCase

↓

PriceCalculationUseCase

↓

Revenue

↓

Session History

↓

Reports

↓

Dashboard
```

---

# End of Section

Next Section:

**9.10 Price Calculation**

This section documents the complete pricing engine, including hourly pricing, duration calculation, billing rules, future pricing strategies, discounts, overtime handling, and all business rules governing PlayStation session pricing.
# PART 9 — PlayStation Module

# 9.10 Price Calculation

## Overview

The **Price Calculation Engine** is responsible for determining the final amount a customer must pay for a completed gaming session.

It is the financial core of the PlayStation Module.

The engine receives the completed session information and calculates the payable amount according to the configured pricing rules.

Price Calculation is implemented entirely inside the Domain Layer.

No pricing logic exists in the UI.

---

# Objectives

The Price Calculation Engine allows businesses to:

* Calculate gaming session prices accurately.
* Eliminate manual calculations.
* Support different pricing models.
* Maintain financial consistency.
* Produce reliable revenue reports.

---

# Source of Truth

Price Calculation depends on:

```text id="pc01"
Device Pricing

+

Billable Duration
```

The engine never depends on:

* UI values.
* Cached totals.
* Dashboard statistics.

---

# Current Pricing Model

Current implementation supports:

```text id="pc02"
Hourly Pricing
```

Every device has:

```text id="pc03"
Price Per Hour
```

Example:

```text id="pc04"
PS5

50 EGP

Per Hour
```

---

# Billable Duration

The engine receives:

```text id="pc05"
Billable Duration
```

Billable Duration excludes:

* Paused Time.

Formula:

```text id="pc06"
Billable Duration

=

Total Session Time

-

Paused Duration
```

---

# Price Formula

Current formula:

```text id="pc07"
Final Price

=

Hourly Rate

×

Billable Duration
```

The calculation always uses derived duration.

No manual price entry is permitted.

---

# Countdown Sessions

For Countdown Sessions:

Current implementation:

The purchased duration determines the billable duration.

Example:

```text id="pc08"
Purchased

2 Hours

↓

Billable

2 Hours
```

No overtime is currently supported.

---

# Live Sessions

For Live Timer sessions:

Billable duration equals:

```text id="pc09"
Elapsed Playing Time
```

The engine calculates the final price using the same pricing rules.

---

# Device Pricing

Each device owns its own pricing configuration.

Example:

```text id="pc10"
PS4

40 EGP / Hour

---

PS5

60 EGP / Hour
```

Changing a device's hourly rate affects only future sessions.

Historical sessions preserve their original calculated prices.

---

# Historical Integrity

Completed sessions store:

```text id="pc11"
Final Price
```

Future pricing changes never modify historical revenue.

Historical financial records remain immutable.

---

# Revenue Relationship

Price Calculation produces:

```text id="pc12"
Revenue
```

Revenue is recorded immediately after successful session completion.

Revenue is never edited manually.

---

# Reports Integration

Calculated prices contribute to:

* Daily Revenue Reports.
* Weekly Revenue Reports.
* Monthly Revenue Reports.
* Session Reports.

Future:

* Device Profitability.
* Peak Hour Revenue.
* Room Revenue.

---

# Dashboard Integration

Dashboard displays:

* Today's Revenue.
* Monthly Revenue.
* Total Revenue.

All values are derived from completed session prices.

---

# Future Pricing Features

The architecture supports future pricing strategies:

* Half-Hour Pricing.
* Quarter-Hour Pricing.
* Fixed Packages.
* Happy Hour Discounts.
* Weekend Pricing.
* Holiday Pricing.
* VIP Pricing.
* Promotional Discounts.
* Overtime Billing.

Current implementation remains compatible with these future enhancements.

---

# Validation

Before calculation:

Validate:

* Device exists.
* Hourly Price configured.
* Billable Duration greater than zero.
* Session completed successfully.

Reject invalid calculations.

---

# Internet Requirement

Price Calculation requires:

* Active internet connection.
* Firestore availability.

The PlayStation Module currently operates online only.

---

# Error Handling

Examples:

```text id="pc13"
Invalid Device Price

Invalid Duration

Unable to Calculate Price

Network Error
```

Revenue is not generated if pricing fails.

---

# Performance

Optimizations:

* Single price calculation per completed session.
* No repeated recalculations.
* Efficient Cubit updates.
* Minimal Firestore writes.

Supports large numbers of completed sessions.

---

# Security

Price Calculation requires:

* Authenticated account.
* Active subscription.
* PlayStation Management permission.

Business rules execute only inside:

```text id="pc14"
PriceCalculationUseCase
```

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

Currency formatting follows the application's localization rules.

---

# Business Rules

* Price is always derived dynamically.
* Hourly Price belongs to the device.
* Billable Duration excludes paused time.
* Completed sessions store the calculated final price.
* Historical prices are immutable.
* Revenue is generated only after successful calculation.
* Dashboard consumes completed revenue.
* Reports calculate totals dynamically.
* The PlayStation Module currently operates online only.
* Firestore is the single source of truth.

---

# Architecture

```text id="pc15"
Device Pricing

+

Billable Duration

↓

PriceCalculationUseCase

↓

Final Price

↓

Revenue

↓

Session History

↓

Reports

↓

Dashboard
```

---

# End of Section

Next Section:

**9.11 Revenue Management**

This section documents revenue generation, revenue aggregation, financial reporting, dashboard integration, historical revenue preservation, and all business rules governing PlayStation income.
# PART 9 — PlayStation Module

# 9.11 Revenue Management

## Overview

The **Revenue Management** module records, aggregates, and reports all income generated from completed PlayStation gaming sessions.

Revenue is **never entered manually**.

Every revenue value originates from a successfully completed gaming session after the **Price Calculation Engine** determines the final payable amount.

This guarantees that financial reports always match actual business operations.

---

# Objectives

The Revenue Management module allows businesses to:

* Record gaming income automatically.
* Aggregate revenue across different periods.
* Produce financial reports.
* Monitor business performance.
* Eliminate manual accounting mistakes.

---

# Source of Truth

Revenue depends on:

```text id="rev01"
Completed Gaming Sessions
```

More specifically:

```text id="rev02"
Completed Session

↓

Final Price

↓

Revenue
```

Revenue is never calculated directly from:

* Dashboard totals.
* UI values.
* Cached numbers.

---

# Revenue Lifecycle

```text id="rev03"
Gaming Session

↓

End Session

↓

Price Calculation

↓

Revenue Generated

↓

Session History

↓

Reports

↓

Dashboard
```

Revenue exists only after successful session completion.

---

# Revenue Record

Each completed session contributes:

```text id="rev04"
One Revenue Record
```

Current implementation stores revenue within the completed session.

Future architecture may introduce:

```text id="rev05"
Revenue Collection
```

for advanced accounting without affecting the current design.

---

# Revenue Amount

Revenue Amount equals:

```text id="rev06"
Final Session Price
```

Example:

```text id="rev07"
Session Price

120 EGP

↓

Revenue

120 EGP
```

No additional calculations occur.

---

# Daily Revenue

Daily Revenue formula:

```text id="rev08"
Sum

All Completed Sessions

For Today
```

The value is always calculated dynamically.

---

# Weekly Revenue

Formula:

```text id="rev09"
Sum

Completed Sessions

Within Current Week
```

---

# Monthly Revenue

Formula:

```text id="rev10"
Sum

Completed Sessions

Within Current Month
```

---

# Yearly Revenue

Future support:

```text id="rev11"
Sum

Completed Sessions

Within Current Year
```

The architecture already supports yearly aggregation.

---

# Revenue Timestamp Rule

Revenue grouping always depends on:

```text id="rev12"
createdAt
```

Never:

* syncedAt
* uploadedAt
* serverTimestamp

Business chronology must remain accurate.

---

# Historical Integrity

Historical revenue must never change.

Changing:

* Device Price.
* Room.
* Session Configuration.

does not affect previously generated revenue.

Historical financial records remain immutable.

---

# Reports Integration

Revenue contributes to:

* Daily Reports.
* Weekly Reports.
* Monthly Reports.
* PlayStation Revenue Reports.

Future:

* Annual Reports.
* Device Profitability.
* Room Profitability.

---

# Dashboard Integration

Dashboard displays:

* Today's Revenue.
* Weekly Revenue.
* Monthly Revenue.
* Active Sessions.
* Completed Sessions.

Dashboard values are always derived dynamically.

---

# Revenue Correction

Current implementation:

Revenue cannot be edited manually.

If a correction is required in the future:

Use:

```text id="rev13"
Adjustment Transactions
```

Historical sessions remain unchanged.

---

# Internet Requirement

Revenue generation requires:

* Active internet connection.
* Firestore availability.

The PlayStation Module currently operates online only.

---

# Error Handling

Examples:

```text id="rev14"
Unable To Generate Revenue

Invalid Session

Price Calculation Failed

Network Error
```

If revenue generation fails:

The session is not marked as successfully completed.

---

# Performance

Optimizations:

* Revenue calculated once.
* Dynamic aggregation.
* Indexed Firestore queries.
* Incremental Cubit updates.

Supports large revenue histories efficiently.

---

# Security

Revenue requires:

* Authenticated account.
* Active subscription.
* PlayStation Management permission.

Revenue records cannot be edited directly.

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

Currency formatting follows localization settings.

---

# Business Rules

* Revenue originates only from completed sessions.
* Revenue equals the final calculated session price.
* Revenue is never entered manually.
* Revenue grouping depends on createdAt.
* Historical revenue is immutable.
* Dashboard consumes derived revenue.
* Reports aggregate revenue dynamically.
* Revenue corrections must use adjustment records in future implementations.
* The PlayStation Module currently operates online only.
* Firestore is the single source of truth.

---

# Architecture

```text id="rev15"
Completed Session

↓

Price Calculation

↓

Revenue

↓

Session History

↓

Reports Engine

↓

Dashboard
```

---

# End of Section

Next Section:

**9.12 Session History**

This section documents historical gaming sessions, immutable business records, searching, filtering, historical reporting, financial traceability, and all business rules governing completed PlayStation sessions.
# PART 9 — PlayStation Module

# 9.12 Session History

## Overview

The **Session History** module stores every completed gaming session as a permanent business record.

Session History provides complete traceability for:

* Gaming activity.
* Revenue.
* Device utilization.
* Customer visits (when applicable).
* Financial reporting.

Every completed session is preserved for historical analysis.

Historical sessions are immutable.

---

# Objectives

The Session History module allows businesses to:

* Review completed sessions.
* Audit revenue.
* Search historical activity.
* Generate reports.
* Analyze business performance.

---

# Source of Truth

Session History depends on:

```text id="sh01"
Completed Gaming Sessions
```

Only successfully completed sessions become historical records.

Running sessions never appear in Session History.

---

# Session Lifecycle

```text id="sh02"
Start Session

↓

Running

↓

Completed

↓

Session History

↓

Reports

↓

Dashboard
```

Session History is the final destination of every gaming session.

---

# Stored Information

Each historical session stores:

* Session ID
* Room ID
* Device ID
* Customer Name (Optional)
* Start Time
* End Time
* Billable Duration
* Final Price
* createdAt

Future fields:

* Discount
* Payment Method
* Operator
* Notes

---

# Historical Integrity

Historical sessions must never be modified.

The following changes never affect history:

* Device name changes.
* Room name changes.
* Device pricing changes.
* Future business rule updates.

History always represents what actually happened.

---

# Searching

Supported search:

* Customer Name
* Device Name
* Room Name

Future:

* Session ID
* Operator
* Payment Method

Search uses debounce for performance.

---

# Filtering

Supported filters:

* Today
* This Week
* This Month

Future:

* Device
* Room
* Customer
* Operator
* Revenue Range

---

# Sorting

Supported sorting:

* Newest First
* Oldest First

Future:

* Highest Revenue
* Longest Session
* Shortest Session

---

# Reports Integration

Session History contributes to:

* Daily Reports
* Weekly Reports
* Monthly Reports
* Revenue Reports

Future:

* Customer Analytics
* Device Analytics
* Peak Hour Reports

---

# Dashboard Integration

Dashboard derives:

* Completed Sessions
* Revenue
* Device Usage

Dashboard never stores historical summaries.

---

# Revenue Relationship

Every historical session contributes exactly:

```text id="sh03"
One Revenue Entry
```

Historical revenue is never recalculated.

---

# Timestamp Rule

Session History always groups by:

```text id="sh04"
createdAt
```

Never:

* syncedAt
* uploadedAt
* serverTimestamp

Business chronology always reflects the actual session date.

---

# Session Deletion

Completed sessions:

❌ Cannot be deleted.

Historical business records are preserved permanently.

Future implementation may support:

Soft Archive

without affecting reports.

---

# Internet Requirement

Session History requires:

* Active internet connection.
* Firestore availability.

The PlayStation Module currently operates online only.

---

# Error Handling

Examples:

```text id="sh05"
Unable To Load Session History

No Historical Sessions Found

Network Error
```

No historical data is modified during retrieval.

---

# Loading State

During loading:

* Display loading indicator.
* Support pagination.
* Prevent duplicate requests.

---

# Performance

Optimizations:

* Firestore pagination.
* Indexed queries.
* Lazy loading.
* Incremental Cubit updates.
* Debounced searching.

Supports very large historical datasets.

---

# Security

Session History requires:

* Authenticated account.
* Active subscription.
* PlayStation Management permission.

Historical records cannot be modified directly.

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

---

# Business Rules

* Only completed sessions enter Session History.
* Historical sessions are immutable.
* Historical revenue never changes.
* Searching uses debounce.
* Reports consume Session History dynamically.
* Dashboard derives completed session statistics.
* Historical grouping depends on createdAt.
* Completed sessions cannot be deleted.
* The PlayStation Module currently operates online only.
* Firestore is the single source of truth.

---

# Architecture

```text id="sh06"
Completed Session

↓

Session History

↓

Search

↓

Filtering

↓

Reports

↓

Dashboard
```

---

# End of Section

Next Section:

**9.13 PlayStation Reports**

This section documents all PlayStation reports, including daily, weekly, monthly, revenue, session statistics, device utilization, room performance, filtering, aggregation, and the complete reporting business rules for the PlayStation Module.
# PART 9 — PlayStation Module

# 9.12 Session History

## Overview

The **Session History** module stores every completed gaming session as a permanent business record.

Session History provides complete traceability for:

* Gaming activity.
* Revenue.
* Device utilization.
* Customer visits (when applicable).
* Financial reporting.

Every completed session is preserved for historical analysis.

Historical sessions are immutable.

---

# Objectives

The Session History module allows businesses to:

* Review completed sessions.
* Audit revenue.
* Search historical activity.
* Generate reports.
* Analyze business performance.

---

# Source of Truth

Session History depends on:

```text id="sh01"
Completed Gaming Sessions
```

Only successfully completed sessions become historical records.

Running sessions never appear in Session History.

---

# Session Lifecycle

```text id="sh02"
Start Session

↓

Running

↓

Completed

↓

Session History

↓

Reports

↓

Dashboard
```

Session History is the final destination of every gaming session.

---

# Stored Information

Each historical session stores:

* Session ID
* Room ID
* Device ID
* Customer Name (Optional)
* Start Time
* End Time
* Billable Duration
* Final Price
* createdAt

Future fields:

* Discount
* Payment Method
* Operator
* Notes

---

# Historical Integrity

Historical sessions must never be modified.

The following changes never affect history:

* Device name changes.
* Room name changes.
* Device pricing changes.
* Future business rule updates.

History always represents what actually happened.

---

# Searching

Supported search:

* Customer Name
* Device Name
* Room Name

Future:

* Session ID
* Operator
* Payment Method

Search uses debounce for performance.

---

# Filtering

Supported filters:

* Today
* This Week
* This Month

Future:

* Device
* Room
* Customer
* Operator
* Revenue Range

---

# Sorting

Supported sorting:

* Newest First
* Oldest First

Future:

* Highest Revenue
* Longest Session
* Shortest Session

---

# Reports Integration

Session History contributes to:

* Daily Reports
* Weekly Reports
* Monthly Reports
* Revenue Reports

Future:

* Customer Analytics
* Device Analytics
* Peak Hour Reports

---

# Dashboard Integration

Dashboard derives:

* Completed Sessions
* Revenue
* Device Usage

Dashboard never stores historical summaries.

---

# Revenue Relationship

Every historical session contributes exactly:

```text id="sh03"
One Revenue Entry
```

Historical revenue is never recalculated.

---

# Timestamp Rule

Session History always groups by:

```text id="sh04"
createdAt
```

Never:

* syncedAt
* uploadedAt
* serverTimestamp

Business chronology always reflects the actual session date.

---

# Session Deletion

Completed sessions:

❌ Cannot be deleted.

Historical business records are preserved permanently.

Future implementation may support:

Soft Archive

without affecting reports.

---

# Internet Requirement

Session History requires:

* Active internet connection.
* Firestore availability.

The PlayStation Module currently operates online only.

---

# Error Handling

Examples:

```text id="sh05"
Unable To Load Session History

No Historical Sessions Found

Network Error
```

No historical data is modified during retrieval.

---

# Loading State

During loading:

* Display loading indicator.
* Support pagination.
* Prevent duplicate requests.

---

# Performance

Optimizations:

* Firestore pagination.
* Indexed queries.
* Lazy loading.
* Incremental Cubit updates.
* Debounced searching.

Supports very large historical datasets.

---

# Security

Session History requires:

* Authenticated account.
* Active subscription.
* PlayStation Management permission.

Historical records cannot be modified directly.

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

---

# Business Rules

* Only completed sessions enter Session History.
* Historical sessions are immutable.
* Historical revenue never changes.
* Searching uses debounce.
* Reports consume Session History dynamically.
* Dashboard derives completed session statistics.
* Historical grouping depends on createdAt.
* Completed sessions cannot be deleted.
* The PlayStation Module currently operates online only.
* Firestore is the single source of truth.

---

# Architecture

```text id="sh06"
Completed Session

↓

Session History

↓

Search

↓

Filtering

↓

Reports

↓

Dashboard
```

---

# End of Section

Next Section:

**9.13 PlayStation Reports**

This section documents all PlayStation reports, including daily, weekly, monthly, revenue, session statistics, device utilization, room performance, filtering, aggregation, and the complete reporting business rules for the PlayStation Module.
# PART 9 — PlayStation Module

# 9.13 PlayStation Reports

## Overview

The **PlayStation Reports** module provides comprehensive analytics for all gaming activity.

Reports are generated dynamically from completed gaming sessions.

No report stores calculated values permanently.

Every report is derived from the underlying business data at the time it is requested.

---

# Objectives

The PlayStation Reports module allows businesses to:

* Monitor daily operations.
* Analyze revenue.
* Measure device utilization.
* Compare room performance.
* Review historical gaming activity.
* Support business decisions.

---

# Source of Truth

PlayStation Reports depend on:

```text id="rpt01"
Completed Gaming Sessions
```

Reports derive:

* Revenue.
* Session Count.
* Playing Duration.
* Device Usage.

Reports never depend on cached totals.

---

# Report Types

Current reports include:

* Daily Reports
* Weekly Reports
* Monthly Reports

Future reports:

* Yearly Reports
* Device Reports
* Room Reports
* Peak Hours Reports
* Customer Reports

---

# Daily Report

Daily Report displays:

* Total Sessions
* Total Revenue
* Average Session Duration
* Active Devices
* Completed Sessions

Formula:

```text id="rpt02"
Sessions

Where

createdAt

=

Today
```

---

# Weekly Report

Weekly Report displays:

* Weekly Revenue
* Weekly Session Count
* Average Daily Revenue

Formula:

```text id="rpt03"
Sessions

Within Current Week
```

---

# Monthly Report

Monthly Report displays:

* Monthly Revenue
* Monthly Sessions
* Average Session Duration

Formula:

```text id="rpt04"
Sessions

Within Current Month
```

---

# Revenue Report

Revenue Report displays:

* Total Revenue
* Revenue Per Day
* Revenue Per Week
* Revenue Per Month

Revenue always originates from:

Completed Sessions.

---

# Device Utilization Report

Future report:

Displays:

* Total Sessions Per Device.
* Total Playing Time.
* Total Revenue Per Device.

Formula:

```text id="rpt05"
Sum

Completed Sessions

Grouped By Device
```

---

# Room Performance Report

Future report:

Displays:

* Revenue Per Room.
* Session Count Per Room.
* Average Session Duration.

Formula:

```text id="rpt06"
Completed Sessions

Grouped By Room
```

---

# Peak Hours Report

Future report:

Displays:

* Most Active Hours.
* Highest Revenue Periods.
* Highest Session Density.

Supports business optimization.

---

# Filtering

Reports support:

* Date Range
* Today
* This Week
* This Month

Future filters:

* Device
* Room
* Customer
* Revenue Range

---

# Searching

Future search:

* Device Name
* Room Name
* Customer Name

Search uses debounce.

---

# Sorting

Supported sorting:

* Latest First

Future:

* Highest Revenue
* Most Sessions
* Longest Duration

---

# Timestamp Rule

Reports always group by:

```text id="rpt07"
createdAt
```

Never:

* syncedAt
* uploadedAt
* serverTimestamp

Business chronology always reflects the real gaming date.

---

# Dashboard Relationship

Dashboard consumes:

* Daily Revenue.
* Active Sessions.
* Completed Sessions.

Dashboard never stores report totals.

---

# Session Relationship

Reports only include:

```text id="rpt08"
Completed Sessions
```

Running sessions are excluded from revenue reports.

---

# Historical Integrity

Reports never modify:

* Sessions.
* Revenue.
* Devices.
* Rooms.

Reports are read-only.

---

# Internet Requirement

Reports require:

* Active internet connection.
* Firestore availability.

The PlayStation Module currently operates online only.

---

# Error Handling

Examples:

```text id="rpt09"
No Report Data

Unable To Generate Report

Network Error
```

No business data is modified.

---

# Loading State

During report generation:

* Display loading indicator.
* Prevent duplicate requests.
* Support pagination for large datasets.

---

# Performance

Optimizations:

* Indexed Firestore queries.
* Lazy loading.
* Incremental Cubit updates.
* Aggregation performed inside UseCases.

Supports large gaming histories efficiently.

---

# Security

Reports require:

* Authenticated account.
* Active subscription.
* PlayStation Management permission.

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

Dates and currency follow localization settings.

---

# Business Rules

* Reports are always generated dynamically.
* Reports consume completed sessions only.
* Revenue is always derived.
* Reports never modify business data.
* Grouping depends on createdAt.
* Dashboard consumes report data.
* Searching uses debounce.
* Historical data remains immutable.
* The PlayStation Module currently operates online only.
* Firestore is the single source of truth.

---

# Architecture

```text id="rpt10"
Completed Sessions

↓

ReportsUseCase

↓

Aggregation

↓

Filtering

↓

Report Result

↓

Dashboard
```

---

# End of PART 9 — PlayStation Module

The PlayStation Module is now fully documented, covering:

* Rooms
* Devices
* Gaming Sessions
* Live Timer
* Countdown Timer
* Pause & Resume
* Session Completion
* Price Calculation
* Revenue Management
* Session History
* Reporting
* Financial Integrity
* Business Rules

---

# Next Part

**PART 10 — Shop Module**

This section documents the complete Shop Management system, including products, categories, inventory management, sales, stock movement, customer purchases, financial integration, reporting, and all business rules governing retail operations.
# PART 10 — Shop Module

# 10.1 Module Overview

## Overview

The **Shop Module** manages all retail operations inside Tahsel.

It enables businesses to organize products, track inventory, process customer sales, manage stock movement, and generate financial reports.

The Shop Module is designed to work alongside the existing:

* Customer Debts Module
* Expenses Module
* Reports Engine

allowing businesses to manage both services and physical products from a single system.

---

# Objectives

The Shop Module allows businesses to:

* Manage products.
* Organize categories.
* Track inventory.
* Sell products.
* Manage installment sales.
* Monitor stock movement.
* Generate financial reports.
* Analyze business performance.

---

# Supported Businesses

The Shop Module is suitable for:

* Grocery Stores
* Mobile Shops
* Electronics Stores
* Cafés
* Retail Shops
* Pharmacies (basic inventory)
* Bookstores
* General Trading Businesses

Future support:

* Barcode Systems
* Multi-Branch Inventory
* Supplier Management

---

# Source of Truth

The Shop Module depends on:

```text id="shop01"
Products

+

Sales

+

Inventory Movement
```

Reports and dashboard values are always derived dynamically.

---

# Main Components

The Shop Module consists of:

* Categories
* Products
* Inventory
* Sales
* Installment Sales
* Reports

Each component has a dedicated responsibility.

---

# Product Lifecycle

```text id="shop02"
Create Category

↓

Create Product

↓

Receive Stock

↓

Sell Product

↓

Inventory Updated

↓

Reports

↓

Dashboard
```

Every stock movement becomes part of the business history.

---

# Sales Lifecycle

```text id="shop03"
Customer

↓

Select Products

↓

Calculate Total

↓

Complete Sale

↓

Reduce Inventory

↓

Generate Revenue

↓

Reports
```

---

# Inventory Relationship

Inventory is automatically updated after:

* Product creation.
* Stock addition.
* Product sale.

Manual inventory modification should be minimized.

---

# Revenue Relationship

Completed product sales contribute to:

* Daily Revenue
* Weekly Revenue
* Monthly Revenue
* Dashboard Statistics
* Financial Reports

Revenue is never entered manually.

---

# Customer Debts Relationship

If a customer purchases using installments:

The Shop Module integrates with:

```text id="shop04"
Customer Debts Module
```

The sale creates a customer debt instead of an immediate completed payment.

Cash sales and installment sales follow different business flows.

---

# Expenses Relationship

Future support:

Inventory purchasing may automatically generate:

```text id="shop05"
Expense Records
```

allowing stock purchases to appear inside the Expenses module.

---

# Reports Integration

The Shop Module contributes to:

* Sales Reports
* Inventory Reports
* Revenue Reports

Future:

* Best Selling Products
* Low Stock Reports
* Profit Analysis

---

# Dashboard Integration

Dashboard displays:

* Total Products
* Total Sales
* Total Revenue
* Low Stock Products (Future)

Statistics refresh automatically.

---

# Internet Requirement

The Shop Module requires:

* Active internet connection.
* Firestore availability.

The Shop Module currently operates online only.

---

# Security

Access requires:

* Authenticated account.
* Active subscription.
* Authorized workspace.

Future permissions:

* Owner
* Manager
* Cashier

---

# Performance

Optimizations:

* Indexed Firestore queries.
* Incremental Cubit updates.
* Lazy loading.
* Debounced searching.

Supports thousands of products efficiently.

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

---

# Business Rules

* Every product belongs to one category.
* Inventory updates automatically after sales.
* Revenue originates from completed sales.
* Installment sales integrate with Customer Debts.
* Dashboard consumes derived values.
* Reports are generated dynamically.
* Firestore is the single source of truth.
* The Shop Module currently operates online only.

---

# Architecture

```text id="shop06"
Categories

↓

Products

↓

Inventory

↓

Sales

↓

Revenue

↓

Reports

↓

Dashboard
```

---

# End of Section

Next Section:

**10.2 Categories**

This section documents category management, category creation, editing, deletion, product organization, validation rules, reporting integration, and all business rules governing product categories.
# PART 10 — Shop Module

# 10.2 Categories

## Overview

The **Categories** module organizes products into logical groups, making inventory management, product searching, sales processing, and reporting more efficient.

A category acts as a container for products that share similar characteristics.

Examples:

* Beverages
* Snacks
* Accessories
* Mobile Phones
* Chargers
* Headphones

Categories improve navigation throughout the Shop Module and simplify business analytics.

---

# Objectives

The Categories module allows administrators to:

* Create product categories.
* Edit category information.
* Delete unused categories.
* Organize products logically.
* Simplify inventory management.
* Improve reporting accuracy.

---

# Source of Truth

Category information is stored in Firestore.

Every category has its own document.

Products reference the category through its ID.

A category does **not** store product information directly.

---

# Category Information

Each category contains:

* Category ID
* Category Name
* Description (Optional)
* createdAt

Future fields:

* Display Order
* Category Icon
* Color
* Notes

---

# Category Lifecycle

```text id="cat01"
Create Category

↓

Assign Products

↓

Product Sales

↓

Reports

↓

Archive / Delete
```

---

# Category Creation

Required fields:

* Category Name

Optional fields:

* Description

Validation:

* Category Name is required.
* Category Name must be unique.
* Internet connection available.

---

# Edit Category

Editable fields:

* Category Name
* Description

Category ID never changes.

Editing a category affects only future display.

Historical sales remain unchanged.

---

# Delete Category

Before deletion:

Validate:

* Category exists.
* No products belong to the category.

If products still reference the category:

Reject deletion.

Display:

```text id="cat02"
This category still contains products.

Please move or delete all products before deleting the category.
```

---

# Product Relationship

Each product belongs to:

```text id="cat03"
One Category
```

A category may contain:

```text id="cat04"
Many Products
```

Relationship:

```text id="cat05"
Category

↓

Product A

Product B

Product C
```

---

# Inventory Relationship

Categories do not store inventory.

Inventory belongs to individual products.

Category reports aggregate inventory dynamically.

---

# Sales Relationship

Product sales automatically contribute to category statistics.

Future analytics:

* Revenue Per Category
* Best Performing Category
* Most Sold Category

---

# Reports Integration

Categories contribute to:

* Sales Reports
* Inventory Reports

Future:

* Revenue By Category
* Product Distribution
* Stock Value By Category

---

# Dashboard Integration

Dashboard may display:

* Total Categories
* Products Per Category

Future:

* Revenue Per Category
* Category Performance

---

# Searching

Supported search:

* Category Name

Future:

* Description

Search uses debounce.

---

# Sorting

Supported sorting:

* Category Name
* Creation Date

Future:

* Product Count
* Revenue

---

# Validation

Before saving:

Validate:

* Category Name not empty.
* Category Name unique.
* Firestore available.

Reject invalid operations.

---

# Internet Requirement

Category management requires:

* Active internet connection.
* Firestore availability.

The Shop Module currently operates online only.

---

# Error Handling

Examples:

```text id="cat06"
Category Already Exists

Category Not Found

Unable To Save Category

Unable To Delete Category

Network Error
```

No partial category record is created.

---

# Loading State

During create/update/delete:

* Disable action buttons.
* Display loading indicator.
* Prevent duplicate requests.

---

# Performance

Optimizations:

* Indexed Firestore queries.
* Lazy loading.
* Incremental Cubit updates.
* Minimal Firestore reads.

Supports hundreds of product categories.

---

# Security

Category management requires:

* Authenticated account.
* Active subscription.
* Shop Management permission.

Future permissions:

* Owner
* Manager

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

---

# Business Rules

* Every category has one unique ID.
* Category names must be unique.
* A category may contain multiple products.
* Every product belongs to one category.
* Categories containing products cannot be deleted.
* Historical sales remain unchanged after category edits.
* Reports aggregate category data dynamically.
* Dashboard updates automatically.
* The Shop Module currently operates online only.
* Firestore is the single source of truth.

---

# Architecture

```text id="cat07"
Categories

↓

Products

↓

Inventory

↓

Sales

↓

Reports

↓

Dashboard
```

---

# End of Section
# PART 11 — Installments

# 11.1 Module Overview

## Overview

The **Installments Module** enables businesses to sell products to customers through scheduled payments instead of requiring full payment at the time of purchase.

This module extends the Shop Module by integrating directly with the **Customer Debts Module**, allowing every installment sale to become a managed financial obligation until it is fully paid.

Unlike normal product sales, installment sales create an outstanding balance that is gradually reduced through customer payments.

---

# Objectives

The Installments Module allows businesses to:

* Sell products through installments.
* Record customer installment contracts.
* Track remaining balances.
* Receive installment payments.
* Monitor overdue balances.
* Generate installment reports.
* Integrate seamlessly with Customer Debts.

---

# Source of Truth

The Installments Module depends on:

```text id="ins01"
Installment Contracts

+

Payment Transactions
```

Remaining balances are always derived dynamically.

No manually maintained remaining balance should exist.

---

# Relationship With Other Modules

The Installments Module integrates with:

* Shop Module
* Customer Debts Module
* Notifications Module
* Reports Engine
* Dashboard

Every completed installment payment automatically updates the customer's financial status.

---

# Installment Lifecycle

```text id="ins02"
Create Installment Sale

↓

Deliver Products

↓

Generate Customer Debt

↓

Receive Payments

↓

Update Remaining Balance

↓

Fully Paid

↓

Reports

↓

Dashboard
```

---

# Core Components

The Installments Module consists of:

* Installment Contracts
* Customer Information
* Products
* Payment Schedule
* Payment Transactions
* Remaining Balance
* Reports

---

# Installment Contract

Each contract contains:

* Contract ID
* Customer ID
* Sale Date
* Total Amount
* Down Payment (Optional)
* Remaining Balance
* Payment Schedule
* Contract Status
* createdAt

Future fields:

* Interest Rate
* Guarantor
* Contract Notes
* Attachment Files

---

# Contract Status

Supported statuses:

```text id="ins03"
Active

Completed
```

Future statuses:

```text id="ins04"
Cancelled

Defaulted

Legal Action
```

---

# Customer Relationship

Each installment contract belongs to:

```text id="ins05"
One Customer
```

A customer may own:

```text id="ins06"
Multiple Installment Contracts
```

---

# Product Relationship

One installment contract may include:

* One Product
* Multiple Products

The contract stores the sold products at the time of sale.

Future product updates never modify historical contracts.

---

# Payment Relationship

Every payment creates:

```text id="ins07"
Payment Transaction
```

Payments reduce the remaining balance dynamically.

---

# Remaining Balance

Formula:

```text id="ins08"
Remaining Balance

=

Total Contract Amount

-

Sum(All Payments)
```

Remaining balance is never edited manually.

---

# Revenue Relationship

Revenue recognition depends on current business rules.

Current implementation:

Revenue is generated when payments are received.

Future implementations may support accounting-based recognition.

---

# Reports Integration

Installments contribute to:

* Customer Reports
* Installment Reports
* Payment Reports
* Revenue Reports

Future:

* Overdue Reports
* Collection Performance
* Expected Cash Flow

---

# Dashboard Integration

Dashboard displays:

Future:

* Active Installments
* Completed Installments
* Outstanding Balance
* Payments Collected

Values are always derived dynamically.

---

# Timestamp Rule

Business grouping always depends on:

```text id="ins09"
createdAt
```

Never:

* syncedAt
* uploadedAt
* serverTimestamp

---

# Internet Requirement

The Installments Module requires:

* Active internet connection.
* Firestore availability.

The Installments Module currently operates online only.

---

# Security

Requires:

* Authenticated account.
* Active subscription.
* Installment Management permission.

Future permissions:

* Owner
* Manager
* Sales Employee

---

# Performance

Optimizations:

* Indexed Firestore queries.
* Incremental Cubit updates.
* Debounced searching.
* Lazy loading.
* Derived calculations.

Supports thousands of installment contracts.

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

---

# Business Rules

* Every installment belongs to one customer.
* Remaining balance is always derived.
* Payments generate payment transactions.
* Historical contracts are immutable.
* Dashboard consumes derived values.
* Reports aggregate installment data dynamically.
* Business grouping depends on createdAt.
* The Installments Module currently operates online only.
* Firestore is the single source of truth.

---

# Architecture

```text id="ins10"
Installment Contract

↓

Payment Transactions

↓

Remaining Balance

↓

Reports

↓

Dashboard
```

---

# End of Section

Next Section:

**11.2 Create Installment Contract**

This section documents creating installment sales, customer selection, product selection, contract generation, initial validation, down payment handling, inventory synchronization, and all business rules governing installment contract creation.
# PART 11 — Installments

# 11.2 Create Installment Contract

## Overview

The **Create Installment Contract** feature allows a business to sell one or more products to a customer through deferred payments.

Creating an installment contract establishes a legally and financially trackable agreement between the business and the customer.

Once created, the contract becomes the foundation for all future payment transactions.

---

# Objectives

The Create Installment Contract feature allows businesses to:

* Create installment agreements.
* Associate contracts with customers.
* Sell one or more products.
* Record total contract value.
* Record optional down payment.
* Generate the customer's financial obligation.
* Synchronize inventory automatically.

---

# Source of Truth

Contract creation depends on:

```text id="crt01"
Customer

+

Selected Products

+

Contract Information
```

Everything else is derived from these values.

---

# Contract Creation Flow

```text id="crt02"
Select Customer

↓

Select Products

↓

Enter Contract Details

↓

(Optional) Down Payment

↓

Validate

↓

Create Contract

↓

Update Inventory

↓

Generate Customer Debt

↓

Dashboard

↓

Reports
```

---

# Required Information

Administrator must provide:

* Customer
* At least one Product
* Product Quantity
* Contract Date

Optional:

* Down Payment
* Notes

Future:

* Installment Period
* Monthly Installment Value
* First Due Date

---

# Customer Selection

Each contract belongs to:

```text id="crt03"
One Customer
```

Customer must already exist inside the system.

Contract creation is rejected if the customer does not exist.

---

# Product Selection

Administrator selects:

* One Product

or

* Multiple Products

Each selected product stores:

* Product ID
* Quantity
* Selling Price at sale time

Historical product prices remain unchanged.

---

# Quantity Validation

Before contract creation:

Validate:

```text id="crt04"
Current Inventory

>=

Requested Quantity
```

If validation fails:

Reject contract creation.

Display:

```text id="crt05"
Insufficient Stock
```

---

# Contract Total

Formula:

```text id="crt06"
Contract Total

=

Sum

(Product Price

×

Quantity)
```

The total is always calculated dynamically.

Manual total entry is not allowed.

---

# Down Payment

Down Payment is optional.

Formula:

```text id="crt07"
Remaining Balance

=

Contract Total

-

Down Payment
```

If no down payment exists:

```text id="crt08"
Remaining Balance

=

Contract Total
```

---

# Customer Debt Integration

Immediately after contract creation:

Generate:

```text id="crt09"
Customer Debt
```

The Customer Debts Module becomes responsible for:

* Payment tracking.
* Remaining balance.
* Payment history.

The Installments Module does not duplicate debt logic.

---

# Inventory Synchronization

After successful contract creation:

Inventory is automatically reduced.

Formula:

```text id="crt10"
New Quantity

=

Current Quantity

-

Sold Quantity
```

Inventory updates occur atomically with contract creation.

---

# Revenue Relationship

Current implementation:

Revenue is recognized when installment payments are received.

Creating a contract alone does not represent collected cash.

---

# Reports Integration

New contracts contribute to:

* Installment Reports.
* Customer Reports.

Payments contribute separately to:

* Collection Reports.
* Revenue Reports.

---

# Dashboard Integration

Dashboard updates:

Future statistics:

* Active Installment Contracts.
* Outstanding Balance.
* Total Customers with Installments.

Values are always derived dynamically.

---

# Timestamp Rule

Contract creation uses:

```text id="crt11"
createdAt
```

Business grouping never depends on:

* syncedAt
* uploadedAt
* serverTimestamp

---

# Validation

Before saving:

Validate:

* Customer exists.
* Products exist.
* Inventory sufficient.
* Product quantities valid.
* Down Payment not greater than Contract Total.
* Firestore available.

Reject invalid contracts.

---

# Internet Requirement

Contract creation requires:

* Active internet connection.
* Firestore availability.

The Installments Module currently operates online only.

---

# Error Handling

Examples:

```text id="crt12"
Customer Not Found

Product Not Found

Insufficient Stock

Invalid Down Payment

Unable To Create Contract

Network Error
```

No partial contract is created.

Inventory is never reduced if creation fails.

---

# Loading State

During creation:

* Disable Save button.
* Display loading indicator.
* Prevent duplicate submissions.

---

# Performance

Optimizations:

* Single Firestore transaction.
* Atomic inventory update.
* Incremental Cubit refresh.
* Minimal Firestore writes.

Supports large numbers of installment contracts efficiently.

---

# Security

Contract creation requires:

* Authenticated account.
* Active subscription.
* Installment Management permission.

Future permissions:

* Owner
* Manager
* Sales Employee

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

---

# Business Rules

* Every contract belongs to one customer.
* Every contract contains at least one product.
* Contract total is always derived.
* Down payment is optional.
* Remaining balance is derived.
* Customer Debt is generated automatically.
* Inventory updates automatically after successful creation.
* Historical product prices remain immutable.
* Business grouping depends on createdAt.
* The Installments Module currently operates online only.
* Firestore is the single source of truth.

---

# Architecture

```text id="crt13"
Customer

↓

Products

↓

Installment Contract

↓

Inventory Update

↓

Customer Debt

↓

Reports

↓

Dashboard
```

---

# End of Section

Next Section:

**11.3 Installment Payments**

This section documents installment payment processing, partial payments, full settlement, payment transactions, remaining balance calculation, notifications, reporting integration, and all business rules governing installment payments.
# PART 11 — Installments

# 11.3 Installment Payments

## Overview

The **Installment Payments** feature records every payment made toward an installment contract.

Each payment reduces the customer's remaining balance until the contract is fully settled.

Payments are recorded as **independent financial transactions**, ensuring a complete payment history and financial traceability.

The installment contract itself is never modified directly to represent payment history.

---

# Objectives

The Installment Payments feature allows businesses to:

* Receive installment payments.
* Support partial payments.
* Support full settlement.
* Maintain complete payment history.
* Calculate remaining balance dynamically.
* Generate collection reports.
* Synchronize customer debt automatically.

---

# Source of Truth

Payments depend on:

```text id="pay01"
Installment Contract

+

Payment Transactions
```

The remaining balance is always calculated from these two sources.

---

# Payment Lifecycle

```text id="pay02"
Installment Contract

↓

Receive Payment

↓

Create Payment Transaction

↓

Recalculate Remaining Balance

↓

Update Contract Status

↓

Reports

↓

Dashboard
```

---

# Payment Transaction

Every payment creates a new transaction.

Each transaction stores:

* Payment ID
* Contract ID
* Paid Amount
* Payment Date
* Notes (Optional)
* createdAt

Future fields:

* Payment Method
* Receipt Number
* Employee ID

Transactions are immutable after creation.

---

# Payment Types

Supported:

### Partial Payment

Example:

```text id="pay03"
Contract

5,000

Payment

1,000

↓

Remaining

4,000
```

---

### Full Payment

Example:

```text id="pay04"
Remaining

1,200

Payment

1,200

↓

Remaining

0

↓

Completed
```

---

# Remaining Balance

Formula:

```text id="pay05"
Remaining Balance

=

Contract Total

-

Sum(All Payments)
```

The remaining balance is never entered manually.

---

# Contract Completion

When:

```text id="pay06"
Remaining Balance

=

0
```

The contract status becomes:

```text id="pay07"
Completed
```

Completed contracts no longer accept additional payments.

---

# Customer Debt Synchronization

Each installment payment automatically updates the corresponding record inside the:

```text id="pay08"
Customer Debts Module
```

The Customer Debts Module remains the single source of truth for outstanding balances.

No duplicated financial calculations exist.

---

# Payment Validation

Before accepting payment:

Validate:

* Contract exists.
* Contract status is Active.
* Payment amount greater than zero.
* Payment amount less than or equal to remaining balance.

Reject invalid payments.

---

# Overpayment Prevention

Formula:

```text id="pay09"
Payment

≤

Remaining Balance
```

If payment exceeds the remaining balance:

Reject the transaction.

Display:

```text id="pay10"
Payment exceeds remaining balance.
```

Overpayments are never permitted.

---

# Revenue Relationship

Current implementation:

Revenue is recognized when payment is successfully received.

Every payment contributes to collection reports.

---

# Notifications

After successful payment:

Use the existing notification system.

Supported methods:

* WhatsApp
* SMS
* None

Notification includes:

* Paid Amount
* Remaining Balance

The user's configured notification preference is always respected.

---

# Reports Integration

Payments contribute to:

* Collection Reports
* Customer Reports
* Installment Reports
* Revenue Reports

Future:

* Monthly Collections
* Payment Performance
* Collector Statistics

---

# Dashboard Integration

Dashboard updates:

Future statistics:

* Payments Collected Today
* Remaining Installment Balance
* Completed Contracts

Values are always derived dynamically.

---

# Timestamp Rule

Payment grouping always depends on:

```text id="pay11"
createdAt
```

Never:

* syncedAt
* uploadedAt
* serverTimestamp

---

# Internet Requirement

Installment payments require:

* Active internet connection.
* Firestore availability.

The Installments Module currently operates online only.

---

# Error Handling

Examples:

```text id="pay12"
Contract Not Found

Contract Already Completed

Invalid Payment Amount

Payment Exceeds Remaining Balance

Network Error
```

No partial payment transaction is created.

---

# Loading State

During payment:

* Disable Confirm button.
* Display loading indicator.
* Prevent duplicate submissions.

---

# Performance

Optimizations:

* Single Firestore transaction.
* Dynamic remaining balance calculation.
* Incremental Cubit updates.
* Minimal Firestore writes.

Supports high payment volumes efficiently.

---

# Security

Installment payments require:

* Authenticated account.
* Active subscription.
* Installment Management permission.

Future permissions:

* Owner
* Manager
* Cashier

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

---

# Business Rules

* Every payment creates a new immutable transaction.
* Remaining balance is always derived dynamically.
* Overpayments are prohibited.
* Completed contracts cannot receive additional payments.
* Customer Debt updates automatically.
* Revenue is generated from received payments.
* Reports aggregate payment transactions dynamically.
* Business grouping depends on createdAt.
* The Installments Module currently operates online only.
* Firestore is the single source of truth.

---

# Architecture

```text id="pay13"
Installment Contract

↓

Payment Transaction

↓

Remaining Balance

↓

Customer Debt

↓

Reports

↓

Dashboard
```

---

# End of Section

Next Section:

**11.4 Installment Reports**

This section documents installment reporting, outstanding balances, collection reports, completed contracts, customer analytics, filtering, aggregation, and all business rules governing installment reports.
# PART 11 — Installments

# 11.4 Installment Reports

## Overview

The **Installment Reports** module provides complete financial visibility into all installment activities.

These reports allow businesses to monitor:

* Active installment contracts.
* Completed installment contracts.
* Outstanding balances.
* Collected payments.
* Customer payment history.

All reports are generated dynamically from installment contracts and payment transactions.

No report stores calculated totals permanently.

---

# Objectives

The Installment Reports module allows businesses to:

* Monitor installment performance.
* Track customer payments.
* Review outstanding balances.
* Analyze collections.
* Generate financial reports.
* Support business decision-making.

---

# Source of Truth

Reports depend on:

```text id="ir01"
Installment Contracts

+

Payment Transactions
```

Reports never depend on:

* Cached totals.
* Dashboard summaries.
* Manually entered balances.

---

# Report Types

Current reports include:

* Active Contracts
* Completed Contracts
* Outstanding Balance
* Payment History
* Customer Installment Report

Future:

* Monthly Collection Report
* Overdue Contracts
* Expected Cash Flow
* Employee Collection Performance

---

# Active Contracts Report

Displays:

* Customer
* Contract Date
* Total Amount
* Remaining Balance
* Status

Formula:

```text id="ir02"
Contract Status

=

Active
```

---

# Completed Contracts Report

Displays:

* Customer
* Contract Value
* Total Paid
* Completion Date

Formula:

```text id="ir03"
Remaining Balance

=

0
```

---

# Outstanding Balance Report

Displays:

* Customer
* Remaining Balance
* Contract Total

Formula:

```text id="ir04"
Sum

Remaining Balance

For All Active Contracts
```

This report provides the total amount still owed to the business.

---

# Payment History Report

Displays every payment transaction.

Each entry contains:

* Customer
* Contract
* Payment Date
* Paid Amount
* Notes

Transactions are displayed chronologically.

---

# Customer Installment Report

Displays:

* Active Contracts
* Completed Contracts
* Total Paid
* Remaining Balance
* Payment History

Allows reviewing a customer's complete installment history.

---

# Collection Report

Displays:

* Total Payments Collected
* Number of Payments
* Average Payment Amount

Formula:

```text id="ir05"
Sum

All Payment Transactions
```

Revenue reports consume payment transactions only.

---

# Filtering

Supported filters:

* Today
* This Week
* This Month
* Date Range

Future:

* Customer
* Contract Status
* Amount Range

---

# Searching

Supported search:

* Customer Name

Future:

* Contract ID
* Phone Number

Search uses debounce.

---

# Sorting

Supported sorting:

* Newest Contracts
* Oldest Contracts

Future:

* Highest Remaining Balance
* Largest Contract Value

---

# Timestamp Rule

Reports always group by:

```text id="ir06"
createdAt
```

Never:

* syncedAt
* uploadedAt
* serverTimestamp

Business reports always reflect the real operation date.

---

# Dashboard Integration

Dashboard consumes:

* Outstanding Balance
* Active Contracts
* Completed Contracts
* Payments Collected

Values are always derived dynamically.

---

# Historical Integrity

Reports never modify:

* Contracts.
* Payments.
* Customer Debts.

Reports are read-only.

Historical information remains immutable.

---

# Internet Requirement

Installment Reports require:

* Active internet connection.
* Firestore availability.

The Installments Module currently operates online only.

---

# Error Handling

Examples:

```text id="ir07"
No Installment Data

Unable To Generate Report

Network Error
```

No business data is modified.

---

# Loading State

During report generation:

* Display loading indicator.
* Prevent duplicate requests.
* Support pagination.

---

# Performance

Optimizations:

* Indexed Firestore queries.
* Lazy loading.
* Incremental Cubit updates.
* Aggregation inside UseCases.
* Debounced searching.

Supports thousands of installment contracts efficiently.

---

# Security

Reports require:

* Authenticated account.
* Active subscription.
* Installment Management permission.

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

Dates and currency formatting follow localization settings.

---

# Business Rules

* Reports are generated dynamically.
* Remaining balances are always derived.
* Collection reports consume payment transactions only.
* Historical contracts remain immutable.
* Reports never modify business data.
* Dashboard consumes derived report values.
* Searching uses debounce.
* Business grouping depends on createdAt.
* The Installments Module currently operates online only.
* Firestore is the single source of truth.

---

# Architecture

```text id="ir08"
Installment Contracts

+

Payment Transactions

↓

ReportsUseCase

↓

Aggregation

↓

Filtering

↓

Report Result

↓

Dashboard
```

---

# End of PART 11 — Installments

The Installments Module is now fully documented, covering:

* Installment Contracts
* Customer Integration
* Product Integration
* Payment Transactions
* Remaining Balance Calculation
* Customer Debt Synchronization
* Revenue Recognition
* Installment Reports
* Business Rules
* Financial Integrity

---

# Next Part

**PART 12 — Notifications**

This section documents the complete notification system, including WhatsApp notifications, SMS notifications, notification preferences, message generation, localization, business triggers, and all business rules governing application notifications.
# PART 12 — Notifications

# 12.1 Module Overview

## Overview

The **Notifications Module** is responsible for informing customers about important financial operations performed within Tahsel.

Notifications are generated automatically after specific business events and delivered using the customer's preferred communication method.

The module currently supports:

* WhatsApp
* SMS
* None

The notification system is fully integrated with the:

* Customer Debts Module
* Installments Module

Future integrations may include additional modules.

---

# Objectives

The Notifications Module allows businesses to:

* Notify customers automatically.
* Reduce manual communication.
* Improve payment transparency.
* Confirm successful financial operations.
* Respect each customer's preferred notification method.

---

# Source of Truth

Notifications depend on:

```text id="not01"
Business Events
```

The UI never sends notifications directly.

Every notification is generated after a successful business operation.

---

# Notification Lifecycle

```text id="not02"
Business Operation

↓

Generate Message

↓

Determine Notification Method

↓

Send Notification

↓

Complete Operation
```

---

# Supported Notification Methods

Current implementation supports:

```text id="not03"
WhatsApp

SMS

None
```

Exactly one method is selected for each customer.

---

# Notification Preference

Every customer stores:

```text id="not04"
Notification Method
```

Possible values:

* WhatsApp
* SMS
* None

The system always respects this preference.

---

# Supported Business Events

Current notifications are generated after:

* Customer Debt Creation
* Partial Payment
* Full Payment
* Installment Payment

Future:

* Subscription Renewal
* Subscription Expiration
* Appointment Reminder
* Promotional Campaigns

---

# Notification Flow

```text id="not05"
Business Operation

↓

Business Validation

↓

Database Updated

↓

Notification Generated

↓

Notification Sent
```

Notifications are sent only after successful business completion.

---

# Failure Policy

Notification failure never rolls back:

* Payments.
* Debts.
* Installments.

Business data remains committed.

Notification delivery failure is treated independently.

---

# Message Generation

Messages are generated dynamically.

Values inserted include:

* Customer Name
* Paid Amount
* Remaining Balance

No hardcoded financial values exist.

---

# Localization

Messages support:

* Arabic
* English

The message language follows the application's localization settings.

---

# WhatsApp Integration

When notification method equals:

```text id="not06"
WhatsApp
```

The application prepares a WhatsApp message containing:

* Customer information.
* Payment information.
* Remaining balance.

Future:

Automatic WhatsApp Business API integration.

Current implementation uses the existing WhatsApp workflow.

---

# SMS Integration

When notification method equals:

```text id="not07"
SMS
```

The application generates an SMS message containing:

* Payment confirmation.
* Remaining balance.

Future providers may be integrated without changing business rules.

---

# None

When notification preference equals:

```text id="not08"
None
```

The business operation completes normally.

No notification is generated.

---

# Customer Debts Integration

Notifications are generated after:

* Creating a debt.
* Receiving a payment.

Supported payment types:

* Partial Payment
* Full Payment

Delete operations do not generate notifications.

---

# Installments Integration

Notifications are generated after:

* Installment Payments

Future:

* Upcoming Installment Reminder
* Missed Installment Reminder

---

# Reports Relationship

Notification activity does not affect:

* Revenue
* Financial Reports
* Business Calculations

Notifications are communication only.

---

# Dashboard Relationship

Future dashboard statistics:

* Notifications Sent
* WhatsApp Usage
* SMS Usage

Current implementation does not expose notification analytics.

---

# Internet Requirement

Notifications require:

* Active internet connection.

The Notifications Module currently operates online only.

---

# Error Handling

Examples:

```text id="not09"
Unable To Send Notification

WhatsApp Not Available

SMS Service Unavailable

Network Error
```

Business operations remain successful.

---

# Performance

Optimizations:

* Notification generated only after successful business operations.
* No duplicate notifications.
* Minimal business overhead.

---

# Security

Notification generation requires:

* Authenticated account.
* Active subscription.
* Authorized business operation.

---

# Business Rules

* Notifications are generated only after successful business operations.
* Customer preference always determines notification method.
* Only one notification method is used per operation.
* Notification failure never rolls back financial data.
* Delete operations do not generate notifications.
* Messages are generated dynamically.
* Financial calculations never depend on notifications.
* The Notifications Module currently operates online only.
* Firestore remains the single source of truth for business data.

---

# Architecture

```text id="not10"
Business Operation

↓

Notification Service

↓

Message Builder

↓

WhatsApp

SMS

None
```

---

# End of Section

Next Section:

**12.2 WhatsApp Notifications**

This section documents WhatsApp message generation, payment templates, debt templates, localization, customer preferences, error handling, and all business rules governing WhatsApp notifications.
# PART 12 — Notifications

# 12.2 WhatsApp Notifications

## Overview

**WhatsApp Notifications** are the primary communication channel used by Tahsel to notify customers about financial transactions.

Whenever a supported business event occurs, the system generates a localized WhatsApp message containing the relevant financial information.

The notification is prepared only if the customer's preferred notification method is set to **WhatsApp**.

---

# Objectives

WhatsApp Notifications allow businesses to:

* Inform customers immediately.
* Confirm successful payments.
* Share remaining balances.
* Improve customer communication.
* Reduce manual messaging.

---

# Source of Truth

WhatsApp messages depend on:

```text id="wa01"
Completed Business Operation
```

Messages are generated only after successful database updates.

The UI never creates financial message content manually.

---

# Supported Business Events

Current implementation sends WhatsApp notifications after:

* Customer Debt Creation
* Partial Payment
* Full Payment
* Installment Payment

Future support:

* Subscription Renewal
* Subscription Expiration
* Appointment Reminder
* Promotional Campaigns

---

# Notification Flow

```text id="wa02"
Business Operation

↓

Database Updated

↓

Generate WhatsApp Message

↓

Open WhatsApp

↓

User Sends Message
```

The message is always generated before opening WhatsApp.

---

# Customer Preference

Notification is generated only when:

```text id="wa03"
Notification Method

=

WhatsApp
```

Otherwise:

The WhatsApp workflow is skipped completely.

---

# Message Content

Messages are generated dynamically.

Current variables include:

* Customer Name
* Paid Amount
* Remaining Balance

Future variables:

* Business Name
* Receipt Number
* Due Date
* Installment Number

---

# Localization

Messages support:

* Arabic
* English

Language follows the application's localization settings.

No hardcoded multilingual messages are used.

---

# Payment Confirmation

Example message contains:

* Payment received successfully.
* Paid amount.
* Remaining balance.

Exact wording is generated dynamically based on localization.

---

# Debt Creation Notification

When a new customer debt is created:

Customer receives:

* Total debt.
* Initial remaining balance.

Future:

* Due date.
* Payment instructions.

---

# Installment Payment Notification

After every successful installment payment:

Customer receives:

* Paid amount.
* Updated remaining balance.

Future:

* Next installment date.

---

# Full Payment Notification

When remaining balance becomes zero:

Customer receives confirmation that:

```text id="wa04"
Debt Fully Paid
```

Future:

Digital payment receipt.

---

# Unsupported Operations

WhatsApp notifications are **not** generated for:

* Delete Payment
* Delete Debt
* Internal Administrative Changes

Communication occurs only for customer-relevant financial events.

---

# Error Handling

Examples:

```text id="wa05"
WhatsApp Not Installed

Unable To Open WhatsApp

Invalid Phone Number

Network Error
```

Business operations remain successful.

No financial rollback occurs.

---

# Phone Number Validation

Before opening WhatsApp:

Validate:

* Customer phone exists.
* Phone number format is valid.

Invalid phone numbers prevent notification generation.

---

# Duplicate Protection

Each successful business operation generates:

```text id="wa06"
One WhatsApp Notification
```

Duplicate payment requests must never create duplicate notifications.

---

# Performance

Optimizations:

* Generate messages only when required.
* Avoid duplicate generation.
* Reuse localization templates.
* Minimal processing overhead.

---

# Security

WhatsApp notifications require:

* Authenticated account.
* Successful business operation.
* Valid customer phone number.

---

# Business Rules

* WhatsApp notifications depend on customer preference.
* Messages are generated only after successful database updates.
* Financial values are inserted dynamically.
* Localization is mandatory.
* Delete operations never generate WhatsApp notifications.
* Notification failures never affect business data.
* Duplicate notifications are prohibited.
* The Notifications Module currently operates online only.
* Firestore is the single source of truth for business operations.

---

# Architecture

```text id="wa07"
Business Operation

↓

Notification Service

↓

Message Builder

↓

Localization

↓

WhatsApp

↓

User Sends Message
```

---

# End of Section

Next Section:

**12.3 SMS Notifications**

This section documents SMS message generation, localization, customer preferences, supported business events, validation, delivery flow, and all business rules governing SMS notifications.
# PART 12 — Notifications

# 12.3 SMS Notifications

## Overview

The **SMS Notifications** feature allows Tahsel to generate text messages for customers after specific financial operations.

SMS serves as an alternative communication channel when the customer's preferred notification method is **SMS**.

Like WhatsApp notifications, SMS messages are generated only after a successful business operation.

---

# Objectives

SMS Notifications allow businesses to:

* Confirm financial transactions.
* Notify customers without requiring WhatsApp.
* Improve payment transparency.
* Respect customer communication preferences.

---

# Source of Truth

SMS notifications depend on:

```text id="sms01"
Completed Business Operation
```

Messages are generated only after the database has been successfully updated.

The UI never constructs financial messages manually.

---

# Supported Business Events

Current implementation supports SMS notifications after:

* Customer Debt Creation
* Partial Payment
* Full Payment
* Installment Payment

Future support:

* Subscription Renewal
* Subscription Expiration
* Payment Reminder
* Promotional Messages

---

# Notification Flow

```text id="sms02"
Business Operation

↓

Database Updated

↓

Generate SMS Message

↓

Open SMS Application

↓

User Sends Message
```

SMS generation occurs only after the financial transaction succeeds.

---

# Customer Preference

SMS workflow executes only when:

```text id="sms03"
Notification Method

=

SMS
```

Otherwise:

The SMS workflow is skipped.

---

# Message Content

Messages are generated dynamically.

Current variables include:

* Customer Name
* Paid Amount
* Remaining Balance

Future variables:

* Receipt Number
* Due Date
* Installment Number
* Business Name

---

# Localization

Messages support:

* Arabic
* English

Language follows the application's localization settings.

No hardcoded multilingual messages are used.

---

# Partial Payment Notification

Message includes:

* Payment confirmation.
* Paid amount.
* Updated remaining balance.

---

# Full Payment Notification

When remaining balance reaches zero:

Customer receives confirmation that:

```text id="sms04"
Debt Fully Paid
```

Future support:

Receipt reference number.

---

# Debt Creation Notification

After creating a customer debt:

Customer receives:

* Total debt amount.
* Remaining balance.

Future:

Payment instructions.

---

# Installment Payment Notification

After each installment payment:

Customer receives:

* Paid amount.
* Remaining balance.

Future:

Next payment reminder.

---

# Unsupported Operations

SMS notifications are **not** generated for:

* Delete Payment
* Delete Debt
* Internal Administrative Updates

Only customer-facing financial operations trigger notifications.

---

# Phone Number Validation

Before opening SMS:

Validate:

* Customer phone number exists.
* Phone number format is valid.

If validation fails:

SMS generation is cancelled.

---

# Error Handling

Examples:

```text id="sms05"
SMS Application Not Available

Invalid Phone Number

Unable To Open SMS

Network Error
```

Business operations remain successful.

Financial data is never rolled back.

---

# Duplicate Protection

Each successful business operation generates:

```text id="sms06"
One SMS Notification
```

Duplicate payment submissions must never generate duplicate SMS messages.

---

# Performance

Optimizations:

* Generate SMS only when required.
* Reuse localization templates.
* Prevent duplicate message generation.
* Minimal processing overhead.

---

# Security

SMS notifications require:

* Authenticated account.
* Successful business transaction.
* Valid customer phone number.

---

# Business Rules

* SMS notifications depend on customer preference.
* Messages are generated only after successful business operations.
* Financial values are inserted dynamically.
* Localization is mandatory.
* Delete operations never generate SMS notifications.
* Notification failures never affect business data.
* Duplicate notifications are prohibited.
* The Notifications Module currently operates online only.
* Firestore is the single source of truth for business operations.

---

# Architecture

```text id="sms07"
Business Operation

↓

Notification Service

↓

Message Builder

↓

Localization

↓

SMS Application

↓

User Sends Message
```

---

# End of Section

Next Section:

**12.4 Notification Preferences**

This section documents notification method selection, customer preferences, default behavior, preference updates, synchronization, and all business rules governing notification settings.
# PART 12 — Notifications

# 12.4 Notification Preferences

## Overview

The **Notification Preferences** feature determines how each customer prefers to receive business notifications.

Every customer has exactly **one active notification method**, which is respected by all supported modules.

This preference is stored with the customer record and is used whenever a supported business event occurs.

---

# Objectives

The Notification Preferences feature allows businesses to:

* Respect customer communication preferences.
* Avoid sending unwanted notifications.
* Centralize notification behavior.
* Ensure consistent communication across all modules.

---

# Source of Truth

Notification preferences are stored inside the customer record.

Example value:

```text id="pref01"
notificationMethod
```

Supported values:

* WhatsApp
* SMS
* None

The stored value is always considered the single source of truth.

---

# Preference Lifecycle

```text id="pref02"
Create Customer

↓

Select Notification Method

↓

Save Customer

↓

Business Operation

↓

Read Notification Preference

↓

Execute Selected Notification Method
```

---

# Supported Methods

Current implementation supports:

```text id="pref03"
WhatsApp

SMS

None
```

Exactly one option must be selected.

---

# Default Behavior

When creating a new customer:

Administrator selects:

* WhatsApp
* SMS
* None

No automatic fallback exists.

The selected value is saved immediately.

---

# Preference Update

Notification preference may be updated from:

Customer Details

Administrator may change:

```text
WhatsApp

↓

SMS

↓

None
```

The update affects only future notifications.

Historical notifications remain unchanged.

---

# Preference Resolution

When a supported business operation completes:

The system performs:

```text id="pref04"
Read Notification Method

↓

Switch

↓

WhatsApp

OR

SMS

OR

None
```

No additional business logic is required.

---

# WhatsApp Behavior

If preference equals:

```text id="pref05"
WhatsApp
```

The WhatsApp workflow is executed.

No SMS message is generated.

---

# SMS Behavior

If preference equals:

```text id="pref06"
SMS
```

The SMS workflow is executed.

No WhatsApp message is generated.

---

# None Behavior

If preference equals:

```text id="pref07"
None
```

The business operation completes normally.

No notification workflow executes.

---

# Customer Relationship

Each customer owns:

```text id="pref08"
One Notification Preference
```

One customer cannot simultaneously use multiple notification methods.

---

# Business Module Integration

Notification Preferences are respected by:

* Customer Debts
* Installments

Future integrations:

* Subscription System
* Shop Module
* Employee Module
* Appointment System

---

# Dashboard Integration

Customer Details displays:

* Current Notification Method

Administrator may modify it at any time.

---

# Validation

Before saving:

Validate:

* Notification method exists.
* Selected value is supported.

Reject invalid values.

---

# Synchronization

Preference updates are written directly to Firestore.

Future business operations always read the latest value.

No local cache should override Firestore.

---

# Internet Requirement

Updating notification preferences requires:

* Active internet connection.
* Firestore availability.

The Notifications Module currently operates online only.

---

# Error Handling

Examples:

```text id="pref09"
Invalid Notification Method

Unable To Update Notification Preference

Network Error
```

Existing customer information remains unchanged if the update fails.

---

# Performance

Optimizations:

* Read preference only when needed.
* Single Firestore update.
* Minimal database reads.
* No continuous listeners.

---

# Security

Updating notification preferences requires:

* Authenticated account.
* Active subscription.
* Customer Management permission.

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

---

# Business Rules

* Every customer has exactly one notification preference.
* Supported methods are WhatsApp, SMS, and None.
* Notification preference is stored in Firestore.
* Future notifications always use the latest saved preference.
* Historical notifications are never modified.
* Invalid notification methods are rejected.
* The Notifications Module currently operates online only.
* Firestore is the single source of truth.

---

# Architecture

```text id="pref10"
Customer

↓

Notification Preference

↓

Business Operation

↓

Notification Service

↓

WhatsApp

SMS

None
```

---

# End of PART 12 — Notifications

The Notifications Module is now fully documented, covering:

* Notification System Overview
* WhatsApp Notifications
* SMS Notifications
* Notification Preferences
* Localization
* Business Rules
* Customer Preference Resolution
* Financial Integrity

---

# Next Part

**PART 13 — Reports Engine**

This section documents the centralized reporting engine, including daily, weekly, monthly, yearly reports, financial aggregation, cross-module reporting, filtering, grouping, analytics, and all business rules governing report generation throughout the application.
# PART 13 — Reports Engine

# 13.1 Reports Engine Overview

## Overview

The **Reports Engine** is the centralized analytics and reporting system of Tahsel.

It collects business data from all supported modules and generates real-time reports that help business owners monitor financial performance, operational activity, and historical trends.

Unlike individual modules, the Reports Engine does **not own business data**.

Its responsibility is to aggregate, filter, calculate, and present information from multiple modules.

---

# Objectives

The Reports Engine allows businesses to:

* View financial performance.
* Monitor daily activity.
* Analyze revenue.
* Review expenses.
* Monitor customer debts.
* Analyze employee performance.
* Generate management reports.

---

# Source of Truth

The Reports Engine never stores report values.

Reports are generated dynamically from:

* Customer Debts
* My Debts
* Expenses
* Employees
* Shop
* Installments
* PlayStation

Every report is derived from business data.

---

# Report Generation Flow

```text id="rep01"
Business Modules

↓

Reports Engine

↓

Filtering

↓

Aggregation

↓

Calculation

↓

Report Result

↓

Dashboard
```

---

# Supported Report Types

The Reports Engine currently supports:

* Daily Reports
* Weekly Reports
* Monthly Reports

Future:

* Yearly Reports
* Custom Date Range Reports
* Comparative Reports
* Trend Analysis

---

# Supported Business Modules

Reports consume information from:

* Customer Debts
* My Debts
* Expenses
* Employees
* Installments
* PlayStation
* Shop

Each module contributes only its own business data.

---

# Dynamic Calculations

All report values are calculated dynamically.

Examples:

* Total Revenue
* Total Expenses
* Total Collected
* Outstanding Balance
* Employee Salaries

No calculated totals are stored permanently.

---

# Business Date Rule

Every report groups business operations using:

```text id="rep02"
createdAt
```

Reports never group data using:

* syncedAt
* uploadedAt
* serverTimestamp

Business chronology always reflects the actual operation date.

---

# Aggregation

Reports aggregate:

* Monetary values.
* Quantities.
* Counts.
* Durations.

Aggregation occurs inside UseCases.

Widgets never calculate report values.

---

# Dashboard Relationship

Dashboard consumes:

* Report summaries.
* Statistics.
* Financial indicators.

Dashboard never performs business calculations.

---

# Filtering

Every report supports:

* Today
* This Week
* This Month

Future:

* Date Range
* Business Module
* Customer
* Employee
* Product

---

# Searching

Modules supporting reports may expose search.

Search always uses debounce.

Reports themselves do not modify business data.

---

# Sorting

Supported sorting:

* Latest First

Future:

* Highest Revenue
* Lowest Revenue
* Largest Expense
* Largest Collection

---

# Historical Integrity

Reports never modify:

* Debts
* Payments
* Expenses
* Employees
* Installments
* Sales

Reports are strictly read-only.

---

# Financial Integrity

Every financial value displayed inside reports must be derived from:

```text id="rep03"
Business Transactions
```

Never from cached summaries.

---

# Internet Requirement

Reports require:

* Active internet connection.
* Firestore availability.

The Reports Engine currently operates online only.

---

# Error Handling

Examples:

```text id="rep04"
No Report Data

Unable To Generate Report

Network Error
```

Business data remains unchanged.

---

# Loading State

During report generation:

* Display loading indicator.
* Prevent duplicate requests.
* Support pagination where applicable.

---

# Performance

Optimizations:

* Indexed Firestore queries.
* Lazy loading.
* Incremental Cubit updates.
* Business aggregation inside UseCases.
* Debounced searching.

Supports very large business datasets efficiently.

---

# Security

Reports require:

* Authenticated account.
* Active subscription.

Future permissions:

* Owner
* Manager
* Accountant

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

Currency and date formatting follow localization settings.

---

# Business Rules

* Reports never own business data.
* Reports are always generated dynamically.
* Financial calculations occur inside UseCases.
* Widgets never calculate report values.
* Dashboard consumes derived report values.
* Reports never modify business data.
* Grouping depends on createdAt.
* Searching uses debounce.
* The Reports Engine currently operates online only.
* Firestore is the single source of truth.

---

# Architecture

```text id="rep05"
Business Modules

↓

Reports Engine

↓

UseCases

↓

Aggregation

↓

Filtering

↓

Report Result

↓

Dashboard
```

---

# End of Section

Next Section:

**13.2 Daily Reports**

This section documents daily report generation, financial aggregation, daily business activity, supported modules, calculations, filtering, and all business rules governing daily reports.
# PART 13 — Reports Engine

# 13.2 Daily Reports

## Overview

The **Daily Reports** feature provides a complete summary of all business activities performed during a single business day.

It enables business owners to quickly understand daily performance by aggregating financial and operational data from every supported module.

Daily Reports are generated dynamically and always reflect the current state of business data.

---

# Objectives

Daily Reports allow businesses to:

* Monitor daily revenue.
* Review daily expenses.
* Track collected payments.
* Monitor employee activity.
* Review installment collections.
* Analyze daily business performance.

---

# Source of Truth

Daily Reports consume data from:

* Customer Debts
* My Debts
* Expenses
* Employees
* Installments
* Shop
* PlayStation

The Reports Engine never stores daily totals.

---

# Business Date Rule

Daily grouping always depends on:

```text id="daily01"
createdAt
```

Reports never use:

* syncedAt
* uploadedAt
* serverTimestamp

Example:

If a payment is created offline on:

```text id="daily02"
08-05-2026
```

and synchronized on:

```text id="daily03"
09-05-2026
```

The payment belongs to:

```text id="daily04"
08-05-2026
```

because this represents the actual business operation date.

---

# Daily Report Flow

```text id="daily05"
Business Modules

↓

Filter

(createdAt = Selected Day)

↓

Aggregation

↓

Daily Report

↓

Dashboard
```

---

# Customer Debts

Daily Reports include:

* New Debts
* Partial Payments
* Full Payments
* Remaining Balance Changes

Delete operations do not contribute to financial collections.

---

# My Debts

Daily Reports include:

* Personal Debt Payments
* Personal Remaining Balances

Used only for personal business analytics.

---

# Expenses

Daily Reports include:

* Expenses created during the selected day.

Displayed values include:

* Total Expenses
* Expense Count

---

# Employees

Daily Reports include:

* Employee Attendance
* Check-In Count
* Check-Out Count

Future:

* Daily Payroll
* Daily Productivity

---

# Installments

Daily Reports include:

* Installment Payments
* New Installment Contracts

Outstanding balances remain derived dynamically.

---

# Shop

Daily Reports include:

Future support:

* Product Sales
* Revenue
* Quantity Sold

Inventory itself is not reported as daily revenue.

---

# PlayStation

Daily Reports include:

Future support:

* Sessions
* Revenue
* Total Playing Time

---

# Financial Aggregation

Daily Reports aggregate:

* Revenue
* Expenses
* Collections
* Outstanding Balances

All calculations occur inside UseCases.

---

# Dashboard Relationship

Dashboard consumes:

* Today's Revenue
* Today's Expenses
* Today's Collections

Dashboard never recalculates business values.

---

# Filtering

Current filters:

* Today
* Selected Date

Future:

* Business Module
* Employee
* Customer

---

# Searching

Modules supporting search continue using debounce.

Daily Reports themselves do not perform free-text searching.

---

# Sorting

Supported sorting:

* Chronological

Future:

* Highest Amount
* Lowest Amount

---

# Empty State

If no operations exist:

Display:

```text id="daily06"
No Data Available
```

No calculated values are fabricated.

---

# Historical Integrity

Daily Reports never modify:

* Debts
* Payments
* Expenses
* Employees
* Installments

Reports remain read-only.

---

# Internet Requirement

Daily Reports require:

* Active internet connection.
* Firestore availability.

The Reports Engine currently operates online only.

---

# Error Handling

Examples:

```text id="daily07"
Unable To Generate Daily Report

No Data Available

Network Error
```

Business data remains unchanged.

---

# Loading State

During report generation:

* Display loading indicator.
* Prevent duplicate requests.
* Update UI after successful aggregation.

---

# Performance

Optimizations:

* Indexed createdAt queries.
* Incremental Cubit updates.
* Aggregation inside UseCases.
* Minimal Firestore reads.

Supports large business datasets efficiently.

---

# Security

Daily Reports require:

* Authenticated account.
* Active subscription.

Future permissions:

* Owner
* Manager
* Accountant

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

Date and currency formatting follow localization settings.

---

# Business Rules

* Daily Reports are generated dynamically.
* Business grouping always depends on createdAt.
* syncedAt never affects report grouping.
* Dashboard consumes derived report values.
* Reports remain read-only.
* Financial aggregation occurs inside UseCases.
* Widgets never calculate report values.
* The Reports Engine currently operates online only.
* Firestore is the single source of truth.

---

# Architecture

```text id="daily08"
Business Modules

↓

createdAt Filter

↓

Aggregation

↓

Daily Report

↓

Dashboard
```

---

# End of Section

Next Section:

**13.3 Weekly Reports**

This section documents weekly report generation, week-based aggregation, financial summaries, operational analytics, filtering, and all business rules governing weekly reports.
# PART 13 — Reports Engine

# 13.3 Weekly Reports

## Overview

The **Weekly Reports** feature summarizes all business activities that occur within a calendar week.

It provides business owners with a broader operational view than Daily Reports by aggregating financial and operational data over seven consecutive days.

Weekly Reports are generated dynamically and always reflect the latest business data.

---

# Objectives

Weekly Reports allow businesses to:

* Analyze weekly revenue.
* Monitor weekly collections.
* Review weekly expenses.
* Evaluate business performance.
* Compare operational activity across weeks.

---

# Source of Truth

Weekly Reports consume data from:

* Customer Debts
* My Debts
* Expenses
* Employees
* Installments
* Shop
* PlayStation

Weekly totals are never stored permanently.

---

# Business Date Rule

Weekly grouping always depends on:

```text id="week01"
createdAt
```

Reports never group operations using:

* syncedAt
* uploadedAt
* serverTimestamp

Business operations always appear in the week during which they actually occurred.

---

# Weekly Report Flow

```text id="week02"
Business Modules

↓

Determine Week Range

↓

Filter

(createdAt)

↓

Aggregation

↓

Weekly Report

↓

Dashboard
```

---

# Week Definition

A weekly report includes:

```text id="week03"
7 Consecutive Calendar Days
```

All business operations whose `createdAt` falls within the selected week are included.

---

# Customer Debts

Weekly Reports include:

* New Debts
* Partial Payments
* Full Payments
* Outstanding Balance Changes

Payment transactions are aggregated automatically.

---

# My Debts

Weekly Reports include:

* Personal Debt Payments
* Personal Outstanding Balances

These values remain separate from customer debt reports.

---

# Expenses

Weekly Reports include:

* Weekly Expenses
* Expense Count

Future:

* Expense Categories
* Expense Distribution

---

# Employees

Weekly Reports include:

* Attendance Summary
* Check-In Statistics
* Check-Out Statistics

Future:

* Weekly Payroll
* Productivity Metrics

---

# Installments

Weekly Reports include:

* Installment Payments
* New Installment Contracts

Outstanding balances remain dynamically calculated.

---

# Shop

Future weekly reports include:

* Product Sales
* Revenue
* Quantity Sold

Inventory movements are not treated as revenue.

---

# PlayStation

Future weekly reports include:

* Sessions
* Revenue
* Playing Hours

---

# Financial Aggregation

Weekly Reports aggregate:

* Revenue
* Expenses
* Collections
* Outstanding Balances

All aggregation occurs inside UseCases.

---

# Dashboard Relationship

Dashboard consumes:

* Weekly Revenue
* Weekly Expenses
* Weekly Collections

Dashboard never performs financial calculations.

---

# Filtering

Supported filters:

* Current Week
* Previous Week

Future:

* Custom Week
* Business Module
* Employee
* Customer

---

# Searching

Weekly Reports do not perform free-text searching.

Underlying modules continue using debounce where applicable.

---

# Sorting

Supported sorting:

* Chronological

Future:

* Highest Revenue
* Highest Collection
* Largest Expense

---

# Empty State

If no business operations exist during the selected week:

Display:

```text id="week04"
No Data Available
```

No derived values are fabricated.

---

# Historical Integrity

Weekly Reports never modify:

* Payments
* Debts
* Expenses
* Employees
* Installments

Reports remain read-only.

---

# Internet Requirement

Weekly Reports require:

* Active internet connection.
* Firestore availability.

The Reports Engine currently operates online only.

---

# Error Handling

Examples:

```text id="week05"
Unable To Generate Weekly Report

No Data Available

Network Error
```

Business data remains unchanged.

---

# Loading State

During report generation:

* Display loading indicator.
* Prevent duplicate requests.
* Update UI after aggregation completes.

---

# Performance

Optimizations:

* Indexed createdAt queries.
* Incremental Cubit updates.
* Aggregation inside UseCases.
* Lazy loading.
* Minimal Firestore reads.

Supports very large business datasets efficiently.

---

# Security

Weekly Reports require:

* Authenticated account.
* Active subscription.

Future permissions:

* Owner
* Manager
* Accountant

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

Dates and currency formatting follow localization settings.

---

# Business Rules

* Weekly Reports are generated dynamically.
* Business grouping always depends on createdAt.
* syncedAt never affects report grouping.
* Dashboard consumes derived report values.
* Reports remain read-only.
* Financial aggregation occurs inside UseCases.
* Widgets never calculate report values.
* The Reports Engine currently operates online only.
* Firestore is the single source of truth.

---

# Architecture

```text id="week06"
Business Modules

↓

Week Range

↓

createdAt Filter

↓

Aggregation

↓

Weekly Report

↓

Dashboard
```

---

# End of Section

Next Section:

**13.4 Monthly Reports**

This section documents monthly report generation, month-based aggregation, financial summaries, trend analysis, filtering, and all business rules governing monthly reports.
# PART 13 — Reports Engine

# 13.4 Monthly Reports

## Overview

The **Monthly Reports** feature provides a comprehensive financial and operational summary for an entire calendar month.

Monthly Reports are one of the most important business analytics tools in Tahsel because they allow business owners to evaluate long-term performance, compare monthly growth, monitor profitability, and make strategic business decisions.

All values are generated dynamically from business transactions.

---

# Objectives

Monthly Reports allow businesses to:

* Analyze monthly revenue.
* Monitor monthly collections.
* Review monthly expenses.
* Track customer debt activity.
* Evaluate overall business performance.
* Compare business performance between months.

---

# Source of Truth

Monthly Reports consume data from:

* Customer Debts
* My Debts
* Expenses
* Employees
* Installments
* Shop
* PlayStation

Monthly summaries are never stored inside Firestore.

---

# Business Date Rule

Monthly grouping always depends on:

```text id="month01"
createdAt
```

Reports never group operations using:

* syncedAt
* uploadedAt
* serverTimestamp

Business history always reflects the real operation date.

---

# Monthly Report Flow

```text id="month02"
Business Modules

↓

Determine Month

↓

createdAt Filter

↓

Aggregation

↓

Monthly Report

↓

Dashboard
```

---

# Month Definition

A monthly report contains every business operation whose:

```text id="month03"
createdAt
```

belongs to the selected:

* Month
* Year

Example:

```text id="month04"
May 2026
```

includes all operations performed during May 2026 only.

---

# Customer Debts

Monthly Reports include:

* New Debts
* Partial Payments
* Full Payments
* Outstanding Balance Changes

Payment transactions are aggregated dynamically.

---

# My Debts

Monthly Reports include:

* Personal Debt Payments
* Personal Outstanding Balances

Displayed independently from customer debts.

---

# Expenses

Monthly Reports include:

* Monthly Expenses
* Expense Count

Future:

* Expense Categories
* Monthly Expense Breakdown

---

# Employees

Monthly Reports include:

* Attendance Summary
* Employee Activity

Future:

* Payroll Summary
* Productivity Analysis

---

# Installments

Monthly Reports include:

* Installment Payments
* New Installment Contracts

Outstanding balances remain dynamically calculated.

---

# Shop

Future monthly reports include:

* Product Sales
* Revenue
* Best Selling Products

Inventory movements are excluded from financial revenue.

---

# PlayStation

Future monthly reports include:

* Sessions
* Revenue
* Playing Hours

---

# Financial Aggregation

Monthly Reports aggregate:

* Revenue
* Expenses
* Collections
* Outstanding Balances

Aggregation always occurs inside UseCases.

---

# Dashboard Relationship

Dashboard consumes:

* Monthly Revenue
* Monthly Expenses
* Monthly Collections

Dashboard never recalculates business values.

---

# Trend Analysis

Monthly Reports enable comparison between months.

Future analytics include:

* Revenue Growth
* Expense Growth
* Collection Growth
* Business Performance Trends

Historical values remain unchanged.

---

# Filtering

Supported filters:

* Current Month
* Previous Month

Future:

* Month + Year
* Custom Date Range
* Business Module
* Customer
* Employee

---

# Searching

Monthly Reports themselves do not support free-text searching.

Underlying modules continue using debounce where applicable.

---

# Sorting

Supported sorting:

* Chronological

Future:

* Highest Revenue
* Highest Collection
* Largest Expense

---

# Empty State

If no operations exist during the selected month:

Display:

```text id="month05"
No Data Available
```

No estimated values are generated.

---

# Historical Integrity

Monthly Reports never modify:

* Debts
* Payments
* Expenses
* Employees
* Installments

Reports remain completely read-only.

---

# Internet Requirement

Monthly Reports require:

* Active internet connection.
* Firestore availability.

The Reports Engine currently operates online only.

---

# Error Handling

Examples:

```text id="month06"
Unable To Generate Monthly Report

No Data Available

Network Error
```

Business data remains unchanged.

---

# Loading State

During report generation:

* Display loading indicator.
* Prevent duplicate requests.
* Refresh UI after aggregation completes.

---

# Performance

Optimizations:

* Indexed createdAt queries.
* Incremental Cubit updates.
* Aggregation inside UseCases.
* Lazy loading.
* Minimal Firestore reads.

Supports very large historical datasets efficiently.

---

# Security

Monthly Reports require:

* Authenticated account.
* Active subscription.

Future permissions:

* Owner
* Manager
* Accountant

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

Month names, dates, and currency formatting follow localization settings.

---

# Business Rules

* Monthly Reports are generated dynamically.
* Business grouping always depends on createdAt.
* Reports separate data by both month and year.
* syncedAt never affects report grouping.
* Dashboard consumes derived report values.
* Reports remain read-only.
* Financial aggregation occurs inside UseCases.
* Widgets never calculate report values.
* The Reports Engine currently operates online only.
* Firestore is the single source of truth.

---

# Architecture

```text id="month07"
Business Modules

↓

Month + Year Filter

↓

createdAt Filter

↓

Aggregation

↓

Monthly Report

↓

Dashboard
```

---

# End of Section

Next Section:

**13.5 Yearly Reports**

This section documents yearly report generation, annual financial aggregation, long-term analytics, yearly comparisons, filtering, and all business rules governing yearly reports.
# PART 13 — Reports Engine

# 13.5 Yearly Reports

## Overview

The **Yearly Reports** feature provides a complete business summary for an entire calendar year.

Yearly Reports are designed for long-term business analysis and strategic decision-making.

They aggregate all financial and operational activities performed throughout the selected year and allow business owners to evaluate overall business growth.

All values are generated dynamically from business transactions.

---

# Objectives

Yearly Reports allow businesses to:

* Analyze annual revenue.
* Monitor yearly collections.
* Review yearly expenses.
* Measure annual business growth.
* Compare business performance between years.
* Support strategic planning.

---

# Source of Truth

Yearly Reports consume data from:

* Customer Debts
* My Debts
* Expenses
* Employees
* Installments
* Shop
* PlayStation

Annual summaries are never stored permanently.

---

# Business Date Rule

Yearly grouping always depends on:

```text id="year01"
createdAt
```

Reports never depend on:

* syncedAt
* uploadedAt
* serverTimestamp

Business operations always belong to the year in which they actually occurred.

---

# Yearly Report Flow

```text id="year02"
Business Modules

↓

Determine Year

↓

createdAt Filter

↓

Aggregation

↓

Yearly Report

↓

Dashboard
```

---

# Year Definition

A yearly report includes every business operation whose:

```text id="year03"
createdAt
```

belongs to the selected calendar year.

Example:

```text id="year04"
2026
```

contains every operation performed during 2026.

---

# Customer Debts

Yearly Reports include:

* New Debts
* Partial Payments
* Full Payments
* Outstanding Balance Changes

Payment transactions are aggregated dynamically.

---

# My Debts

Yearly Reports include:

* Personal Debt Payments
* Personal Outstanding Balances

These values remain independent from customer debt reports.

---

# Expenses

Yearly Reports include:

* Annual Expenses
* Expense Count

Future:

* Expense Categories
* Expense Trends

---

# Employees

Yearly Reports include:

* Attendance Summary
* Employee Activity

Future:

* Payroll Summary
* Productivity Trends

---

# Installments

Yearly Reports include:

* Installment Payments
* New Installment Contracts

Outstanding balances remain dynamically calculated.

---

# Shop

Future yearly reports include:

* Product Sales
* Revenue
* Best Selling Products

Inventory movements are excluded from financial revenue.

---

# PlayStation

Future yearly reports include:

* Sessions
* Revenue
* Playing Hours

---

# Financial Aggregation

Yearly Reports aggregate:

* Revenue
* Expenses
* Collections
* Outstanding Balances

Aggregation always occurs inside UseCases.

---

# Dashboard Relationship

Dashboard consumes:

* Annual Revenue
* Annual Expenses
* Annual Collections

Dashboard never performs financial calculations.

---

# Trend Analysis

Yearly Reports support long-term business analysis.

Future analytics include:

* Year-over-Year Revenue Growth
* Expense Growth
* Collection Growth
* Business Expansion Metrics

Historical data remains immutable.

---

# Filtering

Supported filters:

* Current Year
* Previous Year

Future:

* Custom Year
* Year Range
* Business Module
* Customer
* Employee

---

# Searching

Yearly Reports themselves do not support free-text searching.

Underlying modules continue using debounce where applicable.

---

# Sorting

Supported sorting:

* Chronological

Future:

* Highest Revenue
* Highest Collection
* Largest Expense

---

# Empty State

If no operations exist during the selected year:

Display:

```text id="year05"
No Data Available
```

No estimated values are generated.

---

# Historical Integrity

Yearly Reports never modify:

* Debts
* Payments
* Expenses
* Employees
* Installments

Reports remain completely read-only.

---

# Internet Requirement

Yearly Reports require:

* Active internet connection.
* Firestore availability.

The Reports Engine currently operates online only.

---

# Error Handling

Examples:

```text id="year06"
Unable To Generate Yearly Report

No Data Available

Network Error
```

Business data remains unchanged.

---

# Loading State

During report generation:

* Display loading indicator.
* Prevent duplicate requests.
* Refresh UI after aggregation completes.

---

# Performance

Optimizations:

* Indexed createdAt queries.
* Incremental Cubit updates.
* Aggregation inside UseCases.
* Lazy loading.
* Minimal Firestore reads.

Supports multiple years of historical data efficiently.

---

# Security

Yearly Reports require:

* Authenticated account.
* Active subscription.

Future permissions:

* Owner
* Manager
* Accountant

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

Year formatting, dates, and currency formatting follow localization settings.

---

# Business Rules

* Yearly Reports are generated dynamically.
* Business grouping always depends on createdAt.
* Reports separate data by calendar year.
* syncedAt never affects report grouping.
* Dashboard consumes derived report values.
* Reports remain read-only.
* Financial aggregation occurs inside UseCases.
* Widgets never calculate report values.
* The Reports Engine currently operates online only.
* Firestore is the single source of truth.

---

# Architecture

```text id="year07"
Business Modules

↓

Year Filter

↓

createdAt Filter

↓

Aggregation

↓

Yearly Report

↓

Dashboard
```

---

# End of Section

Next Section:

**13.6 Cross-Module Financial Aggregation**

This section documents how the Reports Engine aggregates financial data across Customer Debts, My Debts, Expenses, Employees, Installments, Shop, and PlayStation while maintaining data consistency and preventing duplicated calculations.
# PART 13 — Reports Engine

# 13.6 Cross-Module Financial Aggregation

## Overview

The **Cross-Module Financial Aggregation** layer is the core component of the Reports Engine.

Its responsibility is to collect business data from all supported modules, aggregate it into unified financial summaries, and provide accurate analytics without duplicating business logic.

The Reports Engine never owns financial data.

It only consumes data from the business modules.

---

# Objectives

Cross-Module Financial Aggregation allows the system to:

* Produce unified financial reports.
* Combine multiple business modules.
* Prevent duplicated calculations.
* Maintain financial consistency.
* Ensure all reports use identical business rules.

---

# Source of Truth

Aggregation consumes data from:

* Customer Debts
* My Debts
* Expenses
* Employees
* Installments
* Shop
* PlayStation

Every module remains responsible for its own business logic.

---

# Aggregation Flow

```text id="agg01"
Business Modules

↓

Repositories

↓

Reports UseCases

↓

Aggregation Engine

↓

Report Result

↓

Dashboard
```

---

# Customer Debts Contribution

Customer Debts contribute:

* Debt Payments
* Outstanding Balance
* Collection Amount
* Customer Statistics

Only completed payment transactions contribute to financial collections.

Debt creation itself is **not** treated as revenue.

---

# My Debts Contribution

My Debts contribute:

* Personal Payments
* Personal Outstanding Balances

These values remain isolated from customer financial analytics.

---

# Expenses Contribution

Expenses contribute:

* Expense Amount
* Expense Count

Expenses always reduce business profitability.

Expense values are never mixed with collections.

---

# Employees Contribution

Current contribution:

* Attendance Statistics

Future:

* Payroll
* Bonuses
* Salary Expenses

Salary expenses will contribute to annual business costs.

---

# Installments Contribution

Installments contribute:

* Installment Payments
* Outstanding Installment Balance
* Active Contracts

Only received installment payments contribute to collections.

Outstanding balances remain separate from collected revenue.

---

# Shop Contribution

Future contribution:

* Product Revenue
* Sales Count
* Best Selling Products

Inventory movements alone never generate financial revenue.

---

# PlayStation Contribution

Future contribution:

* Session Revenue
* Session Count
* Playing Time

Revenue is generated only from completed sessions.

---

# Unified Revenue

Revenue is derived from:

```text id="agg02"
Customer Payments

+

Installment Payments

+

Shop Sales

+

PlayStation Revenue
```

Each module contributes only completed financial transactions.

---

# Unified Expenses

Expenses include:

```text id="agg03"
Business Expenses

+

Future Payroll

+

Future Operational Costs
```

Expense calculations remain independent from revenue.

---

# Net Profit

Future reports derive profitability using:

```text id="agg04"
Net Profit

=

Revenue

-

Expenses
```

Profit is always derived dynamically.

No stored profit value exists.

---

# Outstanding Balance

Outstanding Balance aggregates:

* Customer Debts
* Installment Contracts

Formula:

```text id="agg05"
Outstanding Balance

=

Sum

(All Remaining Balances)
```

Remaining balances remain dynamically calculated.

---

# Duplicate Prevention

The Reports Engine prevents duplicate calculations.

Example:

Customer Debt Payment:

* Appears once inside Collections.
* Does not appear twice inside Revenue.

Every financial transaction contributes exactly once.

---

# Business Date Rule

Cross-module aggregation always depends on:

```text id="agg06"
createdAt
```

Never:

* syncedAt
* uploadedAt
* serverTimestamp

Every module follows the same business chronology.

---

# Dashboard Relationship

Dashboard consumes:

* Revenue
* Expenses
* Outstanding Balance
* Collections

Dashboard never performs aggregation itself.

---

# Filtering

Aggregation supports:

* Daily
* Weekly
* Monthly
* Yearly

Future:

* Custom Date Range
* Business Module
* Customer
* Employee

---

# Historical Integrity

Aggregation never modifies:

* Payments
* Debts
* Expenses
* Employees
* Installments
* Sales

Reports remain read-only.

---

# Internet Requirement

Cross-module aggregation requires:

* Active internet connection.
* Firestore availability.

The Reports Engine currently operates online only.

---

# Error Handling

Examples:

```text id="agg07"
Unable To Aggregate Reports

Missing Business Data

Network Error
```

Business data remains unchanged.

---

# Loading State

During aggregation:

* Display loading indicator.
* Prevent duplicate requests.
* Refresh UI after aggregation completes.

---

# Performance

Optimizations:

* Aggregation inside UseCases.
* Indexed Firestore queries.
* Incremental Cubit updates.
* Lazy loading.
* Minimal Firestore reads.
* Reuse aggregated values within a single report request.

Supports enterprise-scale datasets efficiently.

---

# Security

Cross-module reports require:

* Authenticated account.
* Active subscription.

Future permissions:

* Owner
* Manager
* Accountant

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

Financial formatting follows localization settings.

---

# Business Rules

* Reports never own business data.
* Every module contributes only its own transactions.
* Revenue and expenses remain independent.
* Outstanding balances are always derived.
* Financial transactions contribute exactly once.
* Business grouping always depends on createdAt.
* Reports remain read-only.
* Aggregation occurs inside UseCases.
* Widgets never perform financial aggregation.
* The Reports Engine currently operates online only.
* Firestore is the single source of truth.

---

# Architecture

```text id="agg08"
Customer Debts

My Debts

Expenses

Employees

Installments

Shop

PlayStation

↓

Repositories

↓

Reports UseCases

↓

Aggregation Engine

↓

Dashboard

↓

Reports
```

---

# End of PART 13 — Reports Engine

The Reports Engine is now fully documented, covering:

* Reports Engine Overview
* Daily Reports
* Weekly Reports
* Monthly Reports
* Yearly Reports
* Cross-Module Financial Aggregation
* Business Rules
* Financial Integrity
* Performance
* Security

---

# Next Part

**PART 14 — Collected Amount Feature**

This section documents the **Collected Amount** analytics feature, including monthly collection calculations, payment grouping, analytics, charts, filtering, `createdAt` rules, and all business rules governing collected amount reporting.
# PART 14 — Collected Amount Feature

# 14.1 Feature Overview

## Overview

The **Collected Amount** feature is an advanced financial analytics module that answers one of the most important business questions:

> **"How much money has actually been collected?"**

Unlike debt reports, which display outstanding obligations, the Collected Amount feature focuses exclusively on **money that has already been received**.

It provides business owners with a clear view of cash inflow over time.

---

# Objectives

The Collected Amount feature allows businesses to:

* Monitor collected cash.
* Analyze payment trends.
* Compare monthly collections.
* Evaluate business performance.
* Support financial planning.

---

# Source of Truth

Collected Amount is derived exclusively from:

```text id="ca01"
Payment Transactions
```

Supported sources:

* Customer Debt Payments
* Installment Payments

Future:

* Shop Payments
* PlayStation Payments

The feature never uses:

* Debt Amount
* Remaining Balance
* Cached Totals

---

# Feature Flow

```text id="ca02"
Payment Transactions

↓

Filter

↓

Group

↓

Aggregate

↓

Collected Amount Report

↓

Dashboard
```

---

# Core Concept

The feature measures:

```text id="ca03"
Money Received
```

It does **not** measure:

* Money Owed
* Debt Created
* Expected Revenue

Only completed payment transactions are considered.

---

# Supported Payment Sources

Current implementation includes:

### Customer Debts

* Partial Payments
* Full Payments

---

### Installments

* Installment Payments

Future support:

* Shop Sales
* PlayStation Sessions

---

# Excluded Operations

The following operations never contribute:

* Debt Creation
* Installment Contract Creation
* Outstanding Balance
* Adjustments
* Reversals
* Deleted Records

Only real payments increase collected amount.

---

# Financial Integrity

Formula:

```text id="ca04"
Collected Amount

=

Sum

(All Payment Transactions)
```

No manual totals exist.

---

# Business Date Rule

Collected Amount always depends on:

```text id="ca05"
createdAt
```

Never:

* syncedAt
* uploadedAt
* serverTimestamp

Collections always appear on the actual payment date.

---

# Example

Customer pays:

```text id="ca06"
500

On

08-05-2026
```

Device synchronizes:

```text id="ca07"
09-05-2026
```

Collected Amount belongs to:

```text id="ca08"
08-05-2026
```

because this represents the real business event.

---

# Dashboard Integration

Dashboard consumes:

* Today's Collection
* Weekly Collection
* Monthly Collection

Dashboard never recalculates collection values.

---

# Reports Relationship

Collected Amount contributes to:

* Daily Reports
* Weekly Reports
* Monthly Reports
* Yearly Reports

The feature becomes one of the primary financial indicators.

---

# Future Analytics

Future enhancements include:

* Collection Growth
* Collection Trend
* Average Daily Collection
* Highest Collection Day
* Monthly Comparison

Historical values remain immutable.

---

# Historical Integrity

Collected Amount never modifies:

* Payments
* Debts
* Installments

The feature is strictly analytical.

---

# Internet Requirement

Collected Amount requires:

* Active internet connection.
* Firestore availability.

The feature currently operates online only.

---

# Error Handling

Examples:

```text id="ca09"
Unable To Calculate Collection

No Payment Data

Network Error
```

Business data remains unchanged.

---

# Loading State

During calculation:

* Display loading indicator.
* Prevent duplicate requests.
* Refresh UI after aggregation completes.

---

# Performance

Optimizations:

* Indexed createdAt queries.
* Aggregation inside UseCases.
* Incremental Cubit updates.
* Lazy loading.
* Minimal Firestore reads.

Supports very large payment histories efficiently.

---

# Security

Collected Amount requires:

* Authenticated account.
* Active subscription.

Future permissions:

* Owner
* Manager
* Accountant

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

Dates, currency, and month names follow localization settings.

---

# Business Rules

* Only completed payment transactions contribute.
* Debt creation never contributes.
* Remaining balances never contribute.
* Outstanding balances never contribute.
* Business grouping always depends on createdAt.
* Financial aggregation occurs inside UseCases.
* Widgets never calculate collection values.
* The feature is read-only.
* The feature currently operates online only.
* Firestore is the single source of truth.

---

# Architecture

```text id="ca10"
Payment Transactions

↓

Reports UseCase

↓

Grouping

↓

Aggregation

↓

Collected Amount

↓

Dashboard

↓

Reports
```

---

# End of Section

Next Section:

**14.2 Monthly Collection Calculation**

This section documents monthly grouping, payment aggregation, month/year separation, calculation formulas, analytics, charts, filtering, and all business rules governing monthly collected amount calculations.
# PART 14 — Collected Amount Feature

# 14.2 Monthly Collection Calculation

## Overview

The **Monthly Collection Calculation** feature groups payment transactions by calendar month and calculates the total amount of money collected during each month.

It is one of the primary business analytics tools because it provides a clear view of cash flow trends over time.

Monthly Collection is calculated dynamically every time the report is requested.

No monthly totals are stored in the database.

---

# Objectives

Monthly Collection Calculation allows businesses to:

* View total collections per month.
* Compare business performance across months.
* Identify seasonal trends.
* Monitor business growth.
* Support financial planning.

---

# Source of Truth

Monthly Collection depends exclusively on:

```text id="mc01"
Payment Transactions
```

Current sources:

* Customer Debt Payments
* Installment Payments

Future sources:

* Shop Payments
* PlayStation Sessions

---

# Monthly Calculation Flow

```text id="mc02"
Payment Transactions

↓

createdAt Filter

↓

Group By

Month + Year

↓

Sum Payments

↓

Monthly Collection Result

↓

Dashboard
```

---

# Grouping Rule

Grouping depends on:

```text id="mc03"
Month

+

Year
```

Example:

```text id="mc04"
May 2025
```

and

```text id="mc05"
May 2026
```

are treated as **two completely independent months**.

They are never merged.

---

# Calculation Formula

Formula:

```text id="mc06"
Monthly Collection

=

Sum

(All Payments

Within Selected Month)
```

Only completed payment transactions participate.

---

# Included Transactions

Current implementation includes:

### Customer Debts

* Partial Payments
* Full Payments

---

### Installments

* Installment Payments

Future:

* Shop Revenue
* PlayStation Revenue

---

# Excluded Transactions

The following never contribute:

* Debt Creation
* Installment Creation
* Remaining Balance
* Outstanding Balance
* Deleted Records
* Future Adjustments
* Future Reversals

Only real incoming payments increase monthly collection.

---

# Business Date Rule

Monthly Collection always depends on:

```text id="mc07"
createdAt
```

Never:

* syncedAt
* uploadedAt
* serverTimestamp

Business history always reflects the real payment date.

---

# Example

Transactions:

```text id="mc08"
05 May

500

10 May

700

18 May

300
```

Result:

```text id="mc09"
May Collection

=

1500
```

---

# Empty Month

If a month contains no payment transactions:

Display:

```text id="mc10"
No Data Available
```

The system never fabricates values.

---

# Dashboard Relationship

Dashboard consumes:

* Current Month Collection
* Previous Month Collection

Future:

* Monthly Growth
* Collection Comparison

Dashboard never recalculates collection values.

---

# Reports Relationship

Monthly Collection contributes to:

* Monthly Reports
* Yearly Reports
* Financial Analytics

The same aggregation rules are reused throughout the Reports Engine.

---

# Historical Integrity

Monthly Collection never modifies:

* Payments
* Debts
* Installments

It is strictly analytical.

---

# Filtering

Current filters:

* Current Month
* Previous Month

Future:

* Month + Year
* Custom Date Range

---

# Sorting

Default sorting:

Newest Month First

Future:

* Highest Collection
* Lowest Collection

---

# Visualization

Current implementation displays:

* Monthly Collection List

Future enhancements:

* Bar Chart
* Line Chart
* Monthly Trend Graph

Charts consume the same aggregated dataset used by the list.

---

# Internet Requirement

Monthly Collection requires:

* Active internet connection.
* Firestore availability.

The feature currently operates online only.

---

# Error Handling

Examples:

```text id="mc11"
Unable To Calculate Monthly Collection

No Payment Data

Network Error
```

Business data remains unchanged.

---

# Loading State

During calculation:

* Display loading indicator.
* Prevent duplicate requests.
* Refresh UI after aggregation completes.

---

# Performance

Optimizations:

* Indexed createdAt queries.
* Aggregation inside UseCases.
* Incremental Cubit updates.
* Minimal Firestore reads.
* Efficient grouping by Month + Year.

Supports thousands of payment transactions efficiently.

---

# Security

Monthly Collection requires:

* Authenticated account.
* Active subscription.

Future permissions:

* Owner
* Manager
* Accountant

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

Month names and currency formatting follow localization settings.

---

# Business Rules

* Monthly Collection is generated dynamically.
* Only completed payment transactions contribute.
* Grouping depends on Month + Year.
* Business grouping always depends on createdAt.
* Debt creation never contributes.
* Outstanding balances never contribute.
* Reports remain read-only.
* Aggregation occurs inside UseCases.
* Widgets never calculate collection values.
* The feature currently operates online only.
* Firestore is the single source of truth.

---

# Architecture

```text id="mc12"
Payment Transactions

↓

createdAt Filter

↓

Month + Year Grouping

↓

Aggregation

↓

Monthly Collection

↓

Reports

↓

Dashboard
```

---

# End of Section

Next Section:

**14.3 Payment Date Logic & createdAt Rules**

This section documents why **createdAt** is the only valid business timestamp, how offline synchronization affects reports, why **syncedAt** must never be used for financial analytics, and all business rules governing payment chronology.
# PART 14 — Collected Amount Feature

# 14.3 Payment Date Logic & createdAt Rules

## Overview

One of the most critical business rules in Tahsel is that **every financial report, collection calculation, and business timeline must depend exclusively on the actual business operation date**.

For this reason, the system uses:

```text id="pd01"
createdAt
```

as the **only valid business timestamp**.

Technical timestamps such as synchronization time must never influence financial reports.

---

# Objectives

This rule guarantees:

* Accurate historical reports.
* Correct financial analytics.
* Reliable monthly collections.
* Consistent offline synchronization.
* Identical reports across all devices.

---

# Business Timestamp

The official business timestamp is:

```text id="pd02"
createdAt
```

It represents:

```text id="pd03"
The Exact Time

The Business Operation Happened
```

Examples:

* Debt Creation
* Payment
* Expense
* Installment Payment

---

# Technical Timestamps

Technical timestamps include:

* syncedAt
* uploadedAt
* Firebase Server Timestamp

These timestamps exist only for synchronization purposes.

They never represent business history.

---

# Business Rule

Business calculations always depend on:

```text id="pd04"
createdAt
```

Business calculations never depend on:

```text id="pd05"
syncedAt

uploadedAt

serverTimestamp
```

---

# Offline Scenario

Example:

Customer makes a payment:

```text id="pd06"
08-05-2026
```

Device has no internet.

Payment is stored locally.

Internet returns:

```text id="pd07"
09-05-2026
```

Synchronization uploads the payment.

Correct behavior:

The payment belongs to:

```text id="pd08"
08-05-2026
```

because this is the real business operation date.

---

# Incorrect Behavior

If reports depend on:

```text id="pd09"
syncedAt
```

The payment would incorrectly appear on:

```text id="pd10"
09-05-2026
```

This creates:

* Incorrect daily reports.
* Incorrect weekly reports.
* Incorrect monthly collections.
* Incorrect yearly analytics.

Therefore this behavior is prohibited.

---

# Monthly Collection Example

Payments:

```text id="pd11"
31 May

500
```

Internet returns:

```text id="pd12"
01 June
```

Correct result:

```text id="pd13"
May Collection

+

500
```

Incorrect result:

```text id="pd14"
June Collection

+

500
```

The second result is financially incorrect.

---

# Reports Affected

The following reports always use:

```text id="pd15"
createdAt
```

* Daily Reports
* Weekly Reports
* Monthly Reports
* Yearly Reports
* Collected Amount
* Expenses Reports
* Debt Reports
* Installment Reports

---

# Dashboard Relationship

Dashboard statistics also depend on:

```text id="pd16"
createdAt
```

Dashboard never groups values using synchronization timestamps.

---

# Firestore Synchronization

During synchronization:

The application uploads:

* Business Data
* createdAt

Synchronization must never overwrite:

```text id="pd17"
createdAt
```

The original timestamp remains immutable.

---

# Serialization Rules

Each business record contains:

```text id="pd18"
createdAt

syncedAt
```

Responsibilities:

createdAt

↓

Business Logic

Reports

Analytics

History

---

syncedAt

↓

Synchronization

Debugging

Conflict Resolution

Only.

---

# Immutability

After creation:

```text id="pd19"
createdAt
```

must never change.

Future updates modify business fields only.

Historical business dates remain preserved forever.

---

# Financial Integrity

Using:

```text id="pd20"
createdAt
```

guarantees:

* Correct monthly collections.
* Correct yearly reports.
* Correct historical analytics.
* Reliable business auditing.

---

# Historical Consistency

Multiple devices always produce identical reports because every device groups operations using the same business timestamp.

Synchronization timing never changes financial history.

---

# Internet Requirement

The Reports Engine currently operates online only.

However, business timestamps remain independent from synchronization timing.

---

# Performance

Optimizations:

* Indexed createdAt queries.
* Efficient date filtering.
* Reuse grouped datasets.
* Minimal Firestore reads.

---

# Security

Business timestamps cannot be modified during report generation.

Reports consume immutable business history.

---

# Business Rules

* createdAt is the only valid business timestamp.
* syncedAt is technical metadata only.
* uploadedAt is technical metadata only.
* serverTimestamp never affects reports.
* createdAt is immutable.
* All business grouping depends on createdAt.
* Synchronization must never overwrite createdAt.
* Dashboard uses createdAt exclusively.
* Financial reports must never depend on synchronization time.
* Firestore remains the single source of truth.

---

# Architecture

```text id="pd21"
Business Operation

↓

createdAt

↓

Firestore

↓

Reports Engine

↓

Grouping

↓

Analytics

↓

Dashboard
```

---

# End of Section

Next Section:

**14.4 Collected Amount Analytics & Visualization**

This section documents monthly collection analytics, trend analysis, charts, growth indicators, comparisons between months, dashboard widgets, and all business rules governing financial visualization.
# PART 14 — Collected Amount Feature

# 14.4 Collected Amount Analytics & Visualization

## Overview

The **Collected Amount Analytics & Visualization** feature transforms raw payment data into meaningful business insights.

While previous sections describe how collections are calculated, this section explains how those values are presented to business owners through dashboards, reports, charts, and financial indicators.

The visualization layer never performs calculations.

It only displays the aggregated results produced by the Reports Engine.

---

# Objectives

Collected Amount Analytics allows businesses to:

* Monitor collection trends.
* Compare monthly performance.
* Detect revenue growth.
* Identify weak business periods.
* Support business decision-making.

---

# Source of Truth

All analytics consume data from:

```text id="vis01"
Collected Amount UseCases
```

The visualization layer never queries Firestore directly.

It receives already-calculated data.

---

# Visualization Flow

```text id="vis02"
Payment Transactions

↓

Reports UseCase

↓

Aggregation

↓

Analytics Model

↓

Charts

Cards

Lists

↓

Dashboard
```

---

# Current Visualization

Current implementation displays:

* Monthly Collection Cards
* Monthly Collection List

Each item contains:

* Month Name
* Year
* Total Collected Amount

---

# Monthly Card

Each card displays:

```text id="vis03"
Month

↓

Collected Amount
```

Example:

```text id="vis04"
May 2026

15,400
```

Cards are ordered chronologically.

---

# Sorting

Default sorting:

Newest Month First

Future options:

* Oldest First
* Highest Collection
* Lowest Collection

---

# Trend Analysis

Future analytics include:

* Month-over-Month Growth
* Revenue Trend
* Collection Stability
* Seasonal Performance

Trend calculations are always derived dynamically.

---

# Monthly Comparison

Future implementation supports:

Comparison between:

```text id="vis05"
Current Month

↓

Previous Month
```

Possible indicators:

* Increased Collection
* Decreased Collection
* No Change

---

# Growth Indicator

Future dashboard widgets may display:

```text id="vis06"
Growth %

Compared To Previous Month
```

Growth values are calculated dynamically.

No percentage values are stored.

---

# Charts

Future visualization supports:

* Bar Chart
* Line Chart

Both chart types consume the same aggregated monthly collection dataset.

No separate chart calculations exist.

---

# Dashboard Widgets

Future dashboard widgets include:

* Current Month Collection
* Previous Month Collection
* Highest Collection Month
* Lowest Collection Month

Widgets reuse the Reports Engine aggregation results.

---

# Empty State

If no payment transactions exist:

Display:

```text id="vis07"
No Collection Data Available
```

Charts remain hidden.

No placeholder financial values are displayed.

---

# Large Dataset Handling

For businesses with many years of history:

Visualization supports:

* Lazy loading.
* Incremental rendering.
* Efficient scrolling.

Historical data is loaded only when necessary.

---

# Financial Integrity

Charts and cards never calculate values.

Displayed amounts always originate from:

```text id="vis08"
Reports UseCases
```

This guarantees consistency between:

* Dashboard
* Reports
* Analytics

---

# Historical Integrity

Visualization never modifies:

* Payments
* Debts
* Installments

The analytics layer remains completely read-only.

---

# Internet Requirement

Collected Amount Analytics requires:

* Active internet connection.
* Firestore availability.

The analytics module currently operates online only.

---

# Error Handling

Examples:

```text id="vis09"
Unable To Load Analytics

No Collection Data

Network Error
```

Business data remains unchanged.

---

# Loading State

During analytics generation:

* Display loading indicator.
* Prevent duplicate requests.
* Render visualization after aggregation completes.

---

# Performance

Optimizations:

* Analytics generated inside UseCases.
* Charts consume existing aggregated data.
* No duplicate calculations.
* Lazy rendering.
* Minimal Firestore reads.

Supports very large payment histories efficiently.

---

# Security

Collected Amount Analytics requires:

* Authenticated account.
* Active subscription.

Future permissions:

* Owner
* Manager
* Accountant

---

# Localization

Supports:

* Arabic
* English

Using ARB localization.

Month names, currency, chart labels, and number formatting follow localization settings.

---

# Business Rules

* Visualization never performs business calculations.
* Charts consume aggregated data only.
* Cards consume aggregated data only.
* Financial values always originate from Reports UseCases.
* Growth indicators are calculated dynamically.
* Empty reports display an appropriate empty state.
* Historical data remains immutable.
* The analytics module is read-only.
* The feature currently operates online only.
* Firestore is the single source of truth.

---

# Architecture

```text id="vis10"
Payment Transactions

↓

Reports UseCases

↓

Aggregation

↓

Analytics Model

↓

Charts

Cards

Lists

↓

Dashboard
```

---

# End of PART 14 — Collected Amount Feature

The Collected Amount Feature is now fully documented, covering:

* Feature Overview
* Monthly Collection Calculation
* Payment Date Logic & createdAt Rules
* Analytics & Visualization
* Business Rules
* Financial Integrity
* Performance
* Security

---

# Next Part

**PART 15 — Offline Mode**

This section documents the application's offline architecture, synchronization lifecycle, conflict resolution, `createdAt` vs `syncedAt`, synchronization queues, Firebase synchronization strategy, and all business rules governing offline data handling. (Note: sections related to Employee Management will reflect your decision to remove offline support for employees.)
# PART 15 — Offline Mode

# 15.1 Offline Mode Overview

## Overview

The **Offline Mode** feature allows Tahsel to continue operating when internet connectivity is unavailable.

When the device loses connection, supported business modules continue accepting operations locally. Once connectivity is restored, pending operations are synchronized automatically with Firestore while preserving business integrity.

Offline Mode is implemented selectively.

**Not every module supports offline operation.**

---

# Objectives

Offline Mode allows businesses to:

* Continue working without internet.
* Prevent business interruption.
* Preserve financial history.
* Synchronize safely after reconnection.
* Maintain data consistency across devices.

---

# Supported Modules

The following modules currently support offline operation:

* Customer Debts
* My Debts
* Expenses
* Installments (where applicable)

Future support:

* Shop
* PlayStation

---

# Unsupported Modules

The following modules currently **do NOT support Offline Mode**:

* Employee Management

Employee operations always require an active internet connection.

No employee records, attendance events, salary operations, or administrative actions are queued locally.

---

# Source of Truth

Regardless of offline capability:

```text id="off01"
Firestore
```

remains the permanent source of truth.

Local storage exists only until synchronization completes.

---

# Offline Workflow

```text id="off02"
Business Operation

↓

No Internet

↓

Store Locally

↓

Waiting For Connection

↓

Internet Restored

↓

Synchronization

↓

Firestore
```

---

# Online Workflow

If internet is available:

```text id="off03"
Business Operation

↓

Firestore

↓

Completed
```

No local queue is created.

---

# Local Queue

When offline:

Supported operations are stored inside:

```text id="off04"
Offline Queue
```

The queue preserves:

* Business Data
* createdAt
* Operation Type

Future synchronization processes the queue sequentially.

---

# Queue Order

Synchronization always preserves operation order.

Example:

```text id="off05"
Create Debt

↓

Partial Payment

↓

Full Payment
```

Synchronization must execute the same sequence.

Operations are never reordered.

---

# Business Integrity

Offline Mode never changes business calculations.

Financial formulas remain identical whether operations occur online or offline.

---

# Immutable Business Date

Every offline operation stores:

```text id="off06"
createdAt
```

immediately.

Synchronization never replaces this value.

---

# Synchronization Trigger

Synchronization starts when:

* Internet connection becomes available.
* User manually refreshes (where supported).
* Application resumes and detects connectivity.

No user intervention is required in normal scenarios.

---

# Duplicate Prevention

Each queued operation has a unique identifier.

Synchronization guarantees:

```text id="off07"
One Operation

↓

One Synchronization
```

Duplicate uploads are prohibited.

---

# Failed Synchronization

If synchronization fails:

The operation remains inside the queue.

The system retries later.

Business data is never discarded automatically.

---

# Dashboard Relationship

Dashboard always displays synchronized Firestore data.

Unsynchronized local operations are not visible on other devices until synchronization completes.

---

# Report Relationship

Reports consume synchronized Firestore data.

After synchronization finishes, reports automatically reflect the new business operations.

---

# Internet Requirement

Offline Mode activates automatically whenever internet becomes unavailable.

No manual offline switch exists.

---

# Performance

Optimizations:

* Sequential synchronization.
* Minimal Firestore writes.
* Retry failed operations only.
* Preserve operation ordering.
* Avoid duplicate synchronization.

---

# Security

Offline queue is available only for authenticated users.

Synchronization requires:

* Valid authentication.
* Active subscription.
* Firestore access.

---

# Business Rules

* Offline Mode is available only for supported modules.
* Employee Management does not support Offline Mode.
* Firestore remains the permanent source of truth.
* Offline operations are stored locally until synchronization.
* Synchronization preserves operation order.
* createdAt is assigned immediately when the operation occurs.
* Synchronization never overwrites createdAt.
* Duplicate synchronization is prohibited.
* Failed synchronization never deletes queued operations.
* Financial calculations remain identical online and offline.

---

# Architecture

```text id="off08"
Business Operation

↓

Offline Queue

↓

Internet Restored

↓

Synchronization Engine

↓

Firestore

↓

Reports

↓

Dashboard
```

---

# End of Section

Next Section:

**15.2 Offline Queue Management**

This section documents queue creation, queue lifecycle, retry strategy, operation ordering, duplicate prevention, queue cleanup, and all business rules governing offline synchronization.
# PART 15 — Offline Mode

# 15.2 Offline Queue Management

## Overview

The **Offline Queue Management** system is responsible for temporarily storing business operations performed while the device is offline.

Its primary responsibility is to ensure that no supported business operation is lost before it reaches Firestore.

The queue guarantees reliable synchronization while preserving operation order and financial integrity.

---

# Objectives

Offline Queue Management allows the application to:

* Store offline operations safely.
* Preserve business history.
* Retry failed synchronizations.
* Prevent duplicated uploads.
* Synchronize operations in the correct order.

---

# Source of Truth

While offline:

```text id="queue01"
Offline Queue
```

acts as temporary storage.

After successful synchronization:

```text id="queue02"
Firestore
```

becomes the permanent source of truth.

---

# Queue Lifecycle

```text id="queue03"
Business Operation

↓

Offline Queue

↓

Waiting

↓

Synchronization

↓

Firestore

↓

Remove From Queue
```

Every queued item follows this lifecycle.

---

# Queue Entry

Each queue item contains:

* Unique Queue Identifier
* Operation Type
* Business Data
* createdAt
* Synchronization Status

Future metadata may include:

* Retry Count
* Error Reason
* Last Synchronization Attempt

---

# Supported Operations

Only modules supporting Offline Mode create queue entries.

Current supported examples:

* Create Customer Debt
* Add Payment
* Create Expense
* Installment Payment

Employee Management never creates queue entries because offline support has been intentionally removed.

---

# Queue Order

Synchronization always respects insertion order.

Example:

```text id="queue04"
Create Debt

↓

Payment 1

↓

Payment 2

↓

Expense
```

Synchronization executes exactly this sequence.

No reordering occurs.

---

# Queue Status

Possible synchronization states:

```text id="queue05"
Pending

Synchronizing

Completed

Failed
```

Only completed operations are removed from the queue.

---

# Successful Synchronization

After Firestore confirms success:

The queue item:

```text id="queue06"
Completed

↓

Removed
```

The operation is never synchronized again.

---

# Failed Synchronization

If synchronization fails:

The queue item remains:

```text id="queue07"
Failed
```

The system retries automatically when synchronization is triggered again.

Business data is never discarded.

---

# Retry Strategy

Retries occur when:

* Internet connection returns.
* User performs a manual refresh (where supported).
* Application restarts with internet available.

Future enhancements may introduce exponential retry delays.

---

# Duplicate Prevention

Every queue entry owns a unique identifier.

Synchronization validates:

```text id="queue08"
Already Uploaded?
```

If yes:

The operation is skipped.

Duplicate business transactions are prohibited.

---

# Queue Cleanup

Queue cleanup occurs only after:

* Firestore confirms success.
* Local synchronization finishes successfully.

Failed operations remain stored.

---

# Queue Consistency

The queue must always satisfy:

* No missing operations.
* No duplicate operations.
* No reordered operations.
* No partially synchronized operations.

---

# Business Date Preservation

Every queued operation preserves:

```text id="queue09"
createdAt
```

Synchronization never modifies the original business timestamp.

---

# Financial Integrity

Queue processing never changes:

* Payment Amount
* Debt Amount
* Expense Amount
* Installment Amount

Financial values remain identical before and after synchronization.

---

# Dashboard Relationship

Dashboard displays synchronized Firestore data only.

Queued operations become visible after successful synchronization.

---

# Reports Relationship

Reports automatically include queued operations only after synchronization completes.

Report calculations never consume unsynchronized queue data.

---

# Internet Requirement

Queue processing requires:

* Active internet connection.
* Firestore availability.

Without internet, operations remain safely stored.

---

# Performance

Optimizations:

* Sequential processing.
* Batch synchronization where applicable.
* Minimal Firestore writes.
* Efficient queue cleanup.
* Automatic retry mechanism.

Supports large offline workloads without blocking the UI.

---

# Security

Offline Queue requires:

* Authenticated account.
* Valid local session.

Queued operations remain associated with the authenticated user.

---

# Business Rules

* Offline Queue is temporary storage only.
* Firestore remains the permanent source of truth.
* Queue order is preserved.
* Synchronization never reorders operations.
* createdAt remains immutable.
* Duplicate synchronization is prohibited.
* Failed operations remain queued.
* Queue cleanup occurs only after successful synchronization.
* Employee Management does not participate in Offline Queue processing.
* Financial integrity is preserved throughout synchronization.

---

# Architecture

```text id="queue10"
Business Operation

↓

Offline Queue

↓

Pending

↓

Synchronization Engine

↓

Firestore

↓

Queue Cleanup

↓

Reports

↓

Dashboard
```

---

# End of Section

Next Section:

**15.3 Synchronization Lifecycle**

This section documents synchronization triggers, synchronization phases, validation, upload sequence, failure recovery, completion handling, and all business rules governing the complete synchronization lifecycle.
# PART 15 — Offline Mode

# 15.3 Synchronization Lifecycle

## Overview

The **Synchronization Lifecycle** defines the complete process of transferring locally queued business operations to Firestore once internet connectivity becomes available.

Its primary purpose is to ensure that every offline operation is synchronized exactly once while preserving financial integrity, chronological order, and historical accuracy.

Synchronization is fully automatic.

No manual intervention is required during normal operation.

---

# Objectives

The Synchronization Lifecycle ensures:

* Reliable data upload.
* Preservation of business history.
* Prevention of duplicate records.
* Safe recovery after network failures.
* Consistent Firestore state.

---

# Source of Truth

Before synchronization:

```text id="sync01"
Offline Queue
```

After successful synchronization:

```text id="sync02"
Firestore
```

Firestore always becomes the permanent business record.

---

# Synchronization Flow

```text id="sync03"
Offline Queue

↓

Internet Available

↓

Validation

↓

Upload Operation

↓

Firestore

↓

Verification

↓

Queue Cleanup

↓

Completed
```

Every queued operation follows this lifecycle independently.

---

# Synchronization Trigger

Synchronization starts automatically when:

* Internet connection becomes available.
* Application launches while internet is available.
* Application resumes with connectivity.
* User performs a supported manual refresh.

No background polling is required.

---

# Validation Phase

Before uploading each operation:

Validate:

* User is authenticated.
* Active subscription exists.
* Firestore is reachable.
* Queue item is valid.
* Operation has not already been synchronized.

Invalid operations are rejected.

---

# Upload Phase

Each queue item is uploaded individually.

Sequence:

```text id="sync04"
Queue Item 1

↓

Queue Item 2

↓

Queue Item 3
```

Operation order is always preserved.

---

# Verification Phase

After upload:

Firestore confirms:

* Successful write.
* Valid document.
* No duplication.

Only after verification is the queue item considered complete.

---

# Completion Phase

When synchronization succeeds:

```text id="sync05"
Queue Item

↓

Completed

↓

Removed From Queue
```

The business operation is now permanently stored.

---

# Failure Recovery

If synchronization fails:

The queue item remains stored locally.

Examples:

```text id="sync06"
Network Failure

Permission Error

Firestore Unavailable
```

The application retries later.

Business data is never discarded.

---

# Partial Synchronization

Example:

```text id="sync07"
5 Queue Items

↓

3 Uploaded

↓

2 Failed
```

Only the successful operations are removed.

Failed operations remain queued.

---

# Duplicate Protection

Before uploading:

The synchronization engine validates whether the operation has already been synchronized.

Result:

```text id="sync08"
Already Exists

↓

Skip Upload
```

Duplicate financial records are prohibited.

---

# Business Date Preservation

Synchronization never changes:

```text id="sync09"
createdAt
```

The original business timestamp remains unchanged forever.

---

# Technical Metadata

Synchronization may update:

```text id="sync10"
syncedAt
```

This timestamp is used only for:

* Debugging
* Synchronization Monitoring

It never affects:

* Reports
* Financial Calculations
* Business History

---

# Dashboard Relationship

After synchronization:

Dashboard automatically reflects the updated Firestore data.

No manual refresh of business calculations is required.

---

# Reports Relationship

Once synchronization completes:

Reports automatically include:

* Newly synchronized payments.
* Newly synchronized expenses.
* Newly synchronized debts.

Grouping continues using:

```text id="sync11"
createdAt
```

---

# Internet Requirement

Synchronization requires:

* Active internet connection.
* Firestore availability.

Without connectivity:

The queue remains unchanged.

---

# Performance

Optimizations:

* Sequential synchronization.
* Minimal Firestore writes.
* Retry failed items only.
* Preserve operation order.
* Avoid duplicate uploads.

Designed for reliable synchronization with large offline queues.

---

# Security

Synchronization requires:

* Authenticated account.
* Active subscription.
* Firestore write permission.

Unauthorized synchronization is rejected.

---

# Business Rules

* Synchronization is automatic.
* Queue order is preserved.
* Firestore is the permanent source of truth.
* createdAt never changes.
* syncedAt is technical metadata only.
* Reports always depend on createdAt.
* Duplicate uploads are prohibited.
* Failed operations remain queued.
* Successfully synchronized operations are removed from the queue.
* Employee Management is excluded from Offline Mode synchronization.

---

# Architecture

```text id="sync12"
Offline Queue

↓

Validation

↓

Synchronization Engine

↓

Firestore

↓

Verification

↓

Queue Cleanup

↓

Dashboard

↓

Reports
```

---

# End of Section

Next Section:

**15.4 Conflict Resolution**

This section documents conflict detection, synchronization conflicts, duplicate prevention, timestamp handling, multi-device consistency, and all business rules governing conflict resolution during offline synchronization.
# PART 15 — Offline Mode

# 15.4 Conflict Resolution

## Overview

The **Conflict Resolution** system guarantees that synchronized business data remains accurate, consistent, and free from duplication even when the same business entity is accessed from multiple devices.

Its responsibility is to detect synchronization conflicts, determine the correct resolution strategy, and preserve financial integrity.

Conflicts must never corrupt business history.

---

# Objectives

Conflict Resolution ensures:

* No duplicated business records.
* Consistent financial history.
* Reliable multi-device synchronization.
* Safe conflict recovery.
* Preservation of business chronology.

---

# Source of Truth

The permanent source of truth remains:

```text id="conf01"
Firestore
```

Local offline data exists only until synchronization completes.

---

# Conflict Flow

```text id="conf02"
Offline Queue

↓

Synchronization

↓

Conflict Detection

↓

Resolution Strategy

↓

Firestore

↓

Completed
```

Every synchronized operation passes through conflict validation.

---

# Conflict Definition

A conflict occurs when:

* The same business record already exists.
* A queued operation has already been synchronized.
* Multiple devices attempt to synchronize the same logical operation.

---

# Supported Conflict Types

Current implementation protects against:

* Duplicate Upload
* Duplicate Queue Item

Future conflict handling may include:

* Simultaneous Updates
* Merge Conflicts
* Version Conflicts

---

# Duplicate Upload

Example:

Device uploads:

```text id="conf03"
Payment A
```

Synchronization retries unexpectedly.

Before uploading again:

Validation detects:

```text id="conf04"
Already Exists
```

Result:

Upload skipped.

Financial duplication is prevented.

---

# Queue Duplication

Each offline operation owns:

```text id="conf05"
Unique Operation Identifier
```

Only one synchronized document may exist for each identifier.

---

# Multi-Device Scenario

Example:

Device A:

Creates payment.

Device B:

Reads updated Firestore after synchronization.

Result:

Both devices display identical business history.

Financial reports remain consistent.

---

# Business Timestamp

Conflict resolution never changes:

```text id="conf06"
createdAt
```

Business chronology always remains intact.

---

# Technical Metadata

Conflict resolution may inspect:

```text id="conf07"
syncedAt
```

only to understand synchronization history.

It never uses syncedAt for:

* Reports
* Collections
* Business grouping

---

# Resolution Strategy

Current strategy:

```text id="conf08"
Existing Record

↓

Skip Duplicate Upload

↓

Preserve Firestore
```

The existing Firestore record always wins because it has already been synchronized successfully.

---

# Financial Integrity

Conflict resolution never modifies:

* Payment Amount
* Expense Amount
* Debt Amount
* Installment Amount

Financial transactions remain immutable.

---

# Historical Integrity

Conflict resolution preserves:

* Business history.
* Transaction chronology.
* Financial reports.

Historical business records are never rewritten.

---

# Dashboard Relationship

After successful synchronization:

Dashboard automatically consumes the synchronized Firestore data.

Conflict handling remains invisible to end users.

---

# Reports Relationship

Reports automatically remain consistent because duplicate financial records are prevented before aggregation.

All reports continue grouping by:

```text id="conf09"
createdAt
```

---

# Failure Handling

If conflict resolution cannot determine a safe result:

Synchronization stops for that operation.

The queue item remains stored locally.

Future synchronization retries the operation.

No business data is deleted automatically.

---

# Internet Requirement

Conflict Resolution requires:

* Active internet connection.
* Firestore availability.

Without connectivity:

Conflict detection cannot execute.

---

# Performance

Optimizations:

* Validate unique identifiers before upload.
* Skip duplicated writes.
* Preserve queue order.
* Retry failed operations only.
* Minimize Firestore writes.

Designed for reliable synchronization with enterprise-scale datasets.

---

# Security

Conflict Resolution requires:

* Authenticated account.
* Firestore access.
* Valid synchronization permissions.

Unauthorized synchronization attempts are rejected.

---

# Business Rules

* Firestore is the permanent source of truth.
* Duplicate uploads are prohibited.
* Every offline operation owns a unique identifier.
* createdAt is immutable.
* syncedAt is technical metadata only.
* Reports never depend on syncedAt.
* Financial transactions remain immutable.
* Failed conflict resolution never deletes queued operations.
* Employee Management does not participate in Offline Mode.
* Financial integrity always has priority over synchronization speed.

---

# Architecture

```text id="conf10"
Offline Queue

↓

Conflict Detection

↓

Duplicate Validation

↓

Resolution Strategy

↓

Firestore

↓

Reports

↓

Dashboard
```

---

# End of Section

Next Section:

**15.5 Firestore Synchronization Rules**

This section documents Firestore write rules, document creation, update policies, timestamp preservation, synchronization metadata, and all business rules governing synchronization with Firebase Firestore.
# PART 15 — Offline Mode

# 15.5 Firestore Synchronization Rules

## Overview

The **Firestore Synchronization Rules** define how business data is written, updated, and maintained inside Firebase Firestore.

These rules ensure that synchronization remains predictable, financially accurate, and historically consistent regardless of network conditions.

Every supported module follows the same synchronization principles.

---

# Objectives

The Firestore Synchronization Rules guarantee:

* Reliable business data storage.
* Consistent synchronization behavior.
* Immutable business history.
* Accurate financial reports.
* Safe multi-device operation.

---

# Source of Truth

After successful synchronization:

```text id="fs01"
Firebase Firestore
```

becomes the permanent source of truth.

The local queue is only temporary storage.

---

# Synchronization Flow

```text id="fs02"
Offline Queue

↓

Validation

↓

Firestore Write

↓

Verification

↓

Queue Cleanup
```

Firestore acknowledges every successful write before the queue item is removed.

---

# Document Creation

When a new business operation is synchronized:

A new Firestore document is created.

Examples:

* Customer Debt
* Payment
* Expense
* Installment Payment

Each operation creates exactly one document.

---

# Document Updates

Synchronization updates only when required.

Examples:

* Synchronization metadata
* Business status changes

Business history itself is never rewritten.

---

# Immutable Business Fields

The following fields must never change after creation:

```text id="fs03"
createdAt

Document ID

Original Business Values
```

These fields preserve historical accuracy.

---

# Mutable Fields

The following fields may be updated later:

* Synchronization Status
* syncedAt
* Technical Metadata

Business calculations never depend on these fields.

---

# Timestamp Rules

Business timestamp:

```text id="fs04"
createdAt
```

Technical timestamp:

```text id="fs05"
syncedAt
```

Responsibilities:

createdAt

↓

Business Logic

Reports

Analytics

History

---

syncedAt

↓

Synchronization Tracking

Debugging

Monitoring

Only

---

# Synchronization Metadata

Synchronization metadata exists only for technical purposes.

It must never affect:

* Revenue
* Collections
* Reports
* Financial calculations

---

# Firestore Write Policy

Before writing:

Validate:

* User authentication.
* Active subscription.
* Valid operation.
* Duplicate protection.

Only valid operations reach Firestore.

---

# Duplicate Prevention

Before document creation:

Verify:

```text id="fs06"
Unique Operation Identifier
```

If the operation already exists:

The write is skipped.

Duplicate business transactions are prohibited.

---

# Business Date Preservation

During synchronization:

```text id="fs07"
createdAt
```

is uploaded exactly as originally recorded.

Synchronization never replaces it with:

* Current Device Time
* Firestore Server Timestamp
* Synchronization Time

---

# Multi-Device Consistency

Because every synchronized document preserves:

```text id="fs08"
createdAt
```

all devices generate identical:

* Daily Reports
* Weekly Reports
* Monthly Reports
* Yearly Reports

---

# Reports Relationship

Reports consume only synchronized Firestore documents.

Grouping always depends on:

```text id="fs09"
createdAt
```

Technical synchronization metadata is ignored.

---

# Dashboard Relationship

Dashboard reads synchronized Firestore data only.

No dashboard calculation depends on:

```text id="fs10"
syncedAt
```

---

# Internet Requirement

Synchronization requires:

* Active internet connection.
* Firestore availability.

Without internet:

Business operations remain queued locally.

---

# Performance

Optimizations:

* Minimal Firestore writes.
* Indexed createdAt queries.
* Batch synchronization where appropriate.
* Skip duplicated writes.
* Preserve queue order.

Designed for efficient synchronization at scale.

---

# Security

Synchronization requires:

* Authenticated account.
* Active subscription.
* Firestore write permission.

Unauthorized writes are rejected.

---

# Business Rules

* Firestore is the permanent source of truth.
* Every business operation creates exactly one Firestore record.
* createdAt is immutable.
* syncedAt is technical metadata only.
* Reports always depend on createdAt.
* Synchronization never overwrites business timestamps.
* Duplicate writes are prohibited.
* Technical metadata never affects financial calculations.
* Employee Management does not participate in Offline Mode synchronization.
* Financial integrity always takes precedence over synchronization speed.

---

# Architecture

```text id="fs11"
Business Operation

↓

Offline Queue

↓

Synchronization Engine

↓

Firestore

↓

Reports

↓

Dashboard
```

---

# End of PART 15 — Offline Mode

The Offline Mode module is now fully documented, covering:

* Offline Mode Overview
* Offline Queue Management
* Synchronization Lifecycle
* Conflict Resolution
* Firestore Synchronization Rules
* createdAt vs syncedAt
* Financial Integrity
* Performance
* Security

---

# Next Part

**PART 16 — Firebase Data Model**

This section documents the complete Firestore database architecture, including collections, documents, relationships, field definitions, naming conventions, indexing strategy, and how every module stores and retrieves data.
