# GymPilot — iPhone

Native iPhone app for a small-gym management SaaS, built with SwiftUI.

## Current beta features
- Dashboard metrics calculated from saved membership, attendance, and payment records
- Member directory search, duplicate-phone validation, profile and membership date editing
- Editable membership plan names, durations, and fees
- Date-aware attendance records and check-in history
- Overdue and upcoming fee reminders
- Payment method selection, dated transactions, and per-member payment history
- Local persistence using Codable data saved to UserDefaults
- Empty states and a dynamic dashboard date

## Build
Open `GymPilot.xcodeproj` in Xcode 15 or newer, select the shared GymPilot scheme, choose an iPhone simulator, then run the GymPilot scheme.

## Important limitations
This beta stores data locally on each device. Android and iPhone do not yet share data. A secure backend with authentication and gym-level data isolation is required before production use. Sample members and transactions are seeded on first launch.

Do not commit signing certificates, API keys, passwords, or real customer data.
