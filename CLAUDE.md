# Squibble iOS App

A widget-based iOS app where users draw and send doodles to friends. Received doodles appear on a home screen widget.

## Project Overview

**Core Loop:**
1. User draws a doodle
2. User sends to one or more friends
3. Recipients see the doodle on their home screen widget
4. Recipients can view in-app and reply with their own doodle

## Tech Stack

- **Platform:** iOS 17+
- **Language:** Swift
- **UI Framework:** SwiftUI
- **Backend:** Supabase (Auth, PostgreSQL, Storage, Realtime)
- **Widget:** WidgetKit
- **Ads:** Google AdMob (banner ads for free users)
- **In-App Purchases:** StoreKit 2

## Project Structure

```
squibble/
├── squibble/                    # Main app target
│   ├── Models/                  # Data models (User, Doodle, Friendship)
│   ├── Views/                   # SwiftUI views
│   ├── ViewModels/              # View models (ObservableObjects)
│   ├── Services/                # API services (Supabase, Auth)
│   ├── Utilities/               # Helpers, extensions, Config
│   ├── Assets.xcassets/         # Images, colors, app icon
│   ├── Info.plist               # App configuration
│   └── squibbleApp.swift        # App entry point
├── SquibbleWidget/              # Widget extension (Checkpoint 14)
├── docs/
│   ├── squibble-app-spec.md     # Full app specification
│   ├── tasks.md                 # Development task checklist
│   └── migrations/              # SQL migrations for Supabase
└── squibble.xcodeproj/
```

## Key Files

- `docs/squibble-app-spec.md` - Complete app specification with screens, data models, flows
- `docs/tasks.md` - Development checklist organized by checkpoints
- `squibble/Utilities/Config.swift` - Environment configuration (Supabase URLs, API keys)
- `docs/migrations/` - SQL files for database schema (run in order for new environments)

## Database Schema

Four main tables in Supabase:
- `users` - User profiles (extends auth.users)
- `doodles` - Doodle records with sender and image URL
- `doodle_recipients` - Junction table for doodle recipients
- `friendships` - Friend relationships with status (pending/accepted)

## Development Commands

```bash
# Open project in Xcode
open squibble.xcodeproj

# Build from command line
xcodebuild -scheme squibble -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Configuration

Environment variables are in `Config.swift`. For development:
- Supabase URL and publishable key are configured
- AdMob uses test ad unit IDs
- App Group: `group.mehulpandey.squibble`

## Current Status

Check `docs/tasks.md` for current progress. Tasks are organized into checkpoints:
1. Project Setup & Infrastructure - COMPLETE
2. Supabase Backend Setup - IN PROGRESS
3. Core Data Models & Services
4. Authentication Flow
5. Tab Bar & Navigation
6. Drawing Canvas & Home Screen
7. Send Sheet & Doodle Upload
8. History Screen & Doodle Grid
9. Doodle Detail View
10. Profile Screen
11. Settings Screen
12. Add Friends Screen
13. Premium & In-App Purchases
14. Widget Implementation
15. Push Notifications
16. Realtime Updates
17. Polish & Edge Cases
18. Testing & QA
19. App Store Preparation

## Deferred Items (Before App Store)

- Paid Apple Developer account ($99/year)
- Sign in with Apple capability setup
- Google Cloud OAuth credentials
- AdMob production ad unit IDs
- APNs setup for push notifications

## Git Workflow

**IMPORTANT:** Follow `docs/git-workflow.md` for all development work.

- Never commit directly to `main` - always create a feature or fix branch
- Branch naming: `feature/<name>` for new features, `fix/<name>` for bug fixes
- Test thoroughly before merging to `main`
- Tag releases with semantic versioning (v1.0.1, v1.1.0, etc.)

## General Instructions

- Follow the tasks list in tasks.md. We will implement this checkpoint by checkpoint. When an item has been completed, mark it complete with a [x].
- Use the frontend-design skill whenever doing any UX/UI work.
- Every step of the way, give me a high level explanation of what changes you made.
- Make every task and code change you do as simple as possible. We want to avoid making any massive or complex changes. Every change should impact as little code as possible. Everything is about simplicity.
- When a spec changes, update it in the logical place in "squibble-app-spec.md"
- After a checkpoint is completed, add any important info to tasks.md in a new section at the end of that checkpoint, such as if any action is needed from my end (setting up accounts, API keys, etc), if anything is partially completed (with placeholder values, etc), or anything else that needs my attention. If there is nothing worth noting, mention there are no notes. Name this section "Notes for Mehul".
- Any important information (approvals, decisions, action items for me) should be documented directly in the specs or in tasks.md's "Notes for Mehul" sections. No extra intermediate documents.
- DO NOT BE LAZY. NEVER BE LAZY. IF THERE IS A BUG FIND THE ROOT CAUSE AND FIX IT. NO TEMPORARY FIXES. YOU ARE A SENIOR DEVELOPER. NEVER BE LAZY
- MAKE ALL FIXES AND CODE CHANGES AS SIMPLE AS HUMANLY POSSIBLE. THEY SHOULD ONLY IMPACT NECESSARY CODE RELEVANT TO THE TASK AND NOTHING ELSE. IT SHOULD IMPACT AS LITTLE CODE AS POSSIBLE. YOUR GOAL IS TO NOT INTRODUCE ANY BUGS. IT'S ALL ABOUT SIMPLICITY
