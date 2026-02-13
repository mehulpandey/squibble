# Squibble Beta Feedback — Consolidated Checklist

Consolidated from 5 testers (Mehul, Sasank, Anshuman, Prath, Aashrita) — February 2026

## Key
[ ] = not implemented
[x] = implemented but not tested
[xy] = implemented and tested
[xyz] = implemented, tested, merged into main

---

## Release 1.01

### PR 1

Critical bugs.

- [xyz] **Push notifications not working** — Multiple testers received zero notifications for doodles, friend requests, or accepted requests. Notifications work in dev but not prod *(Sasank, Anshuman, Prath)* — **Fixed: Edge function was using sandbox APNs server; switched to production. Note: deploy hit internal Supabase error, needs manual redeploy.**
- [xyz] **Friend invite link is incorrect** — Share message contains wrong app URL. Should be: `https://apps.apple.com/us/app/squibble-doodle-widget/id6757321861` *(Mehul)* — **Fixed: Updated URL in AddFriendsView.swift**
- [xyz] **Streak not resetting to 0** — Streak number is not calculating as expected. It should represent number of consecutive days you've sent a doodle (NOT received). It should reset to 0 if a day is missed. *(Mehul)* — **Fixed: Added streak validation on user load that resets to 0 if last doodle was 2+ days ago**
- [xyz] **Duplicate friends in list** — If both users independently send each other a friend request, the friend appears twice in the friend list. *(Prath)* — **Fixed: Added dedup in loadFriends, prevention in sendFriendRequest, DB unique index, and cleaned existing duplicates**
- [xyz] **Gmail login failing** — Login via Gmail was not working for at least one tester. *(Anshuman)* — **Fixed: Added Google Sign-In URL handling in onOpenURL (was missing with multi-scene support)**
- [xyz] **Widget not updating with new doodles** — Widget frequently shows stale content instead of the most recently received doodle. This is sporadic - sometimes is an issue and sometimes is not *(Mehul)* — **Fixed: Added Notification Service Extension that intercepts push notifications, downloads doodle image, and updates widget via App Group even when app is backgrounded/killed. Also updated edge function to include image_url and mutable-content in push payload.**

### PR 2

Backend issues.

- [xyz] **Cached egress usage exceeding free tier limit (5 gb)** - Cached egress should not be exceeding free tier limit since I only have ~20 users. Make app more efficient to mitigate this. Put in separate PR from above issues. — **Fixed: Switched doodles from PNG to JPEG (0.7 quality), added profile image resizing (max 400px), added disk+memory image cache, set Cache-Control headers on uploads (1 year for doodles, 1 hour for profiles).**

### PR 3

Minor bugs and UX friction.

- [xyz] **Tap-to-dot not working** — Tapping the screen to draw a dot doesn't register (only drag works). *(Anshuman)* — **Fixed: `endPath()` now saves single-point paths, and `drawPath()` renders them as filled circles. Also updated export function to render dots.**
- [xyz] **Brush size shared between pen and eraser** — Changing brush size affects both pen and eraser tools. These should be independent. *(Sasank)* — **Fixed: Split `lineWidth` into `penLineWidth` and `eraserLineWidth` in DrawingState. Computed `lineWidth` property delegates to active tool. Each tool remembers its own size.**
- [xyz] **Widget install instructions may be wrong** — Onboarding should say: hold home screen → edit → add widget → search Squibble → etc (use more professional wording). *(Mehul)* — **Fixed: Updated onboarding steps to: Hold home screen/tap Edit → Add Widget → Search "Squibble" → Select size and Add Widget.**
- [xyz] **Trash button clears uploaded images** — Trash icon should only clear drawn strokes, not image. Uploading a new image should replace existing. Need a separate way to remove the image. *(Mehul)* — **Fixed: Trash now calls `clearDrawingOnly()` (strokes only). Added "Remove Image" option in More Options sheet when an image is present.**
- [xyz] **Save image: no confirmation feedback** — No haptic or visual feedback when saving an image. *(Sasank)* — **Fixed: Added dedicated save-to-photos button (download icon) in DoodleDetailView top bar with success haptic feedback and animated "Saved to Photos" toast.**
- [xyz] **Color picker "+" icon confusing** — On color picker circles, replace overlaid "+" icon with an edit icon (pencil/pen or something). *(Sasank, Prath)* — **Fixed: Replaced "plus" icon with "pencil" icon on selected color circles.**
- [xyz] **"Start drawing" empty state styling** — Orange color on text on empty state canvas clashes against some background colors. *(Mehul)* — **Fixed: Empty state hint now uses adaptive color based on perceived brightness of canvas background (dark text on light backgrounds, light text on dark backgrounds).**
- [xyz] **Show outgoing friend requests** — Can't see outgoing pending friend requests in the Friends list. *(Mehul)* — **Fixed: Added "Sent Requests" section in Friends view showing outgoing pending requests with cancel button. Backend fetches outgoing requests via `getOutgoingFriendRequests()` in FriendManager.**
- [xyz] **Friends list** — On Profile screen below Activity calendar, add section that lists all current friends *(Prath)* — **Fixed: Added "Friends" section below Activity calendar on Profile screen showing all friends with avatars. Includes "Add" button that opens AddFriendsView. Shows empty state when no friends.**
- [xyz] **More color options** - In color picker pop-up screen (the screen that appears after a user clicks on a color that is already selected), have 2 tabs at the top - "Preset" and "Custom". Preset should have the 5x5 color grid that already exists in the app. Custom should have a more precise color picker screen where a user can pick an exact color (color wheel or something?) — **Fixed: Added "Preset" and "Custom" tabs to ExpandedColorPickerView. Preset tab has 5x5 grid with 16px vertical spacing. Custom tab has color preview circle on the left with three labeled HSB sliders (H/S/B) on the right. Color applies live as you drag. Brighter active tab text for better contrast.**

## Fixed by above PRs

One-off bugs.

- [xyz] **3-dot menu freezing app** — "More options" button to the right of trash icon is unresponsive/freezes on one tester's device (iPhone 15 Pro Max with iOS 17.6.1). This is a one-off error as it works on other testers' devices. *(Anshuman)*
- [xyz] **Timing out when sending** - In one instance, app is timing out when sending to multiple people (one-off error, doesn't happen every time). *(Sasank)*

## Deployment Notes 

- App version 1.01 sent to the app store - submitted 2/2/2026

---

## Release 1.02

Chat, reactions, UI improvements

- [x] **Messaging style UI for doodle history / conversation threading** — Add a messaging style UI showing doodle exchange history between two friends, reaction history, and ability to send text messages. *(Anshuman, Prath)*
- [x] **Reactions to doodles (emojis)** — Quick emoji reactions on received doodles (show an individual user's reaction in their chat, show cumulative reactions from all people who reacted to a doodle on history + doodle detail pages). *(Mehul, Aashrita)*
- [x] **Improve UI** - Fix tab bar and/or header bars (remove black background bar, add blurring just like chat UI)

### Deployment Notes
- Code deployment needed
- Supabase migrations needed (008 to 015) - double check this
- Enable real-time on thread-items table
- Edge function deployment needed
- Database webhooks setup needed
    1. Go to Supabase Dashboard → Database → Webhooks
    2. Create webhooks for these tables, all pointing to the send-push-notification Edge Function URL:
        - notify-new-message: thread_items → INSERT (for text messages)
        - notify-new-reaction: reactions → INSERT (for reactions)
    3. Make sure "Enable payload" is selected to include record data

---

### Release 1.03

Groups

- [ ] **Groups** — Create groups and be able to send doodles to entire groups at once, not just by the person. Groups can show up in the messaging view in the History tab (like a group chat). Need to think through mechanics of how this would work (how to add/remove people from groups, name groups, etc) *(Mehul, Sasank)*

---

### Release 1.04

Low priority features

- [ ] **Per-friend streak count and stats** — Snapchat-style streaks per friend. Show on the friends section of the profile page as well as their chat *(Prath)*
- [ ] **Collaborative drawing / reply on doodle** — Draw on top of a received doodle and send it back. *(Mehul, Prath)*
- [ ] **Unviewed doodle indicator on widget** — Visual badge when multiple unseen doodles are queued (only latest shows currently). *(Mehul)*
- [ ] **Resend doodle to a different friend** — Forward an already-sent doodle to someone new without re-uploading. *(Sasank)*

---

### Release 1.05 (think through this first before mass marketing)

- [ ] **Switch to usernames** - Switch user profile system to username based instead of invite code based. Let people look up users by their username and add them like other social media apps, rather than typing in an invite code. How complex is this change? How to migrate existing users onto this system?

---

## Deferred List

- [x] **Bottom nav: Profile/Home toggle bug** — After visiting Profile then Home, subsequent taps alternate between the two screens. *(Sasank)* — **Fixed: Replaced spring animation (which caused overshoot interfering with matchedGeometryEffect hit areas) with easeInOut on tab bar selection.** <- partially fixed, sometimes flips back and forth but sometimes does not
- [x] **App lags on initial startup** — For the first few seconds on first time app startup, the whole app is very laggy and unresponsive (switching tabs, brush strokes, etc). This gives off a bad first impression for the app. *(Prath)* — **Fixed: Removed animated splash→main transition that forced expensive layout computation during animation. Batch-fetch friends in single query instead of N+1. Parallel doodle loading (sent+received). Deferred AdMob init by 3s, deferred realtime/widget work by 2s.** <- lag still exists, but not a huge deal (one-time bug per user)
- [ ] **Phone number login** — Alternative signup/login via phone number. *(Anshuman)*
- [ ] **Contacts integration for invites** — Import contacts to invite and add friends. *(Aashrita)*
- [ ] **Text on doodles** — Type and place text labels on doodles. *(Anshuman)*
- [ ] **Shape tools (squares, circles, etc.)** — Basic shape insertion. *(Anshuman)*
- [ ] **More stats per friend** - Show more stats per friend in new friendship detail pages (highest streak, total doodles exchanged, etc) - need to think through friendship page UI, entry/exit points, etc OR just put basic stats in friends section of Profile tab
- [ ] **Add-to-story shortcut** — Quick action to post a doodle as your "story". *(Sasank)*

---

## Production Deployment Checklist (P0 Fixes)

Steps to migrate all P0 fixes from dev/branch to production.

### 1. Deploy Edge Function to Squibble Prod

The updated `send-push-notification` edge function needs to be deployed to the **Squibble Prod** project (`tztdngmabzzrdatgmukh`). Before deploying, change `APNS_HOST` from `"api.sandbox.push.apple.com"` to `"api.push.apple.com"` — prod uses the production APNs server, not sandbox.

Changes in this deploy:
- `mutable-content: 1` added to `aps` payload (enables Notification Service Extension)
- `image_url` and `sender_color_hex` added to push notification data for `new_doodle` type
- Doodle query expanded to include `image_url` and sender's `color_hex`

### 2. Merge Git Branch to Main

The `fix/p0-beta-fixes` branch contains all P0 code fixes (invite link, streak, duplicates, Gmail login). Merge to `main` per git-workflow.md:

```bash
git checkout main
git merge fix/p0-beta-fixes
git tag -a v1.0.1 -m "P0 beta fixes"
git push origin main --tags
```

### 3. Build and Submit App Update

The app update includes all P0 code changes plus the new **NotificationServiceExtension** target. Before building:

- Open project in Xcode and verify the NotificationServiceExtension target builds and signs correctly
- Ensure automatic signing creates the provisioning profile for `mehulpandey.squibble.NotificationService`
- Verify the App Group (`group.mehulpandey.squibble`) is enabled for the NotificationServiceExtension target
- Archive and submit to App Store Connect via Xcode or `xcodebuild`

### 4. Verify After Deploy

- Send a doodle to a test device while the app is completely closed — widget should update within seconds
- Verify push notifications still display correctly
- Verify tapping notification still navigates to the doodle
- Test Gmail login, friend invites, streak reset, and duplicate friend prevention still work

---

## Production Deployment Checklist (P0.5 — Storage Egress Fix)

Steps to migrate the storage egress optimization from `fix/optimize-storage-egress` branch to production.

### 1. Merge Git Branch to Main

```bash
git checkout main
git merge fix/optimize-storage-egress
git push origin main
```

### 2. Add New Files to Xcode Project

The following new files must be added to the `squibble` target in Xcode if not automatically picked up:
- `squibble/Utilities/UIImage+Resize.swift`
- `squibble/Views/Components/CachedAsyncImage.swift`

### 3. Existing Doodle Images (No Migration Needed)

Old doodles stored as `.png` in Supabase will continue to work — the `image_url` stored in the `doodles` table still points to the old `.png` path, and the app loads images by URL. Only **new** doodles will be uploaded as `.jpg`. The `deleteDoodleImage` function now uses `.jpg` extension, so deleting old `.png` doodles from the app will leave orphaned `.png` files in storage. These can be cleaned up manually from the Supabase dashboard if desired, but they are small in aggregate (~16 MB total).

### 4. No Supabase Migrations Required

All changes are client-side only. No database schema changes or Supabase configuration changes are needed. The `cacheControl` headers are set per-upload in the client code and apply to all new uploads automatically.

### 5. Verify After Deploy

- Send a new doodle and confirm it uploads as `.jpg` (check Supabase Storage dashboard)
- Verify doodle images load correctly in History grid and Detail view
- Verify profile images still display after changing profile photo
- Check that old PNG doodles still display correctly (backward compatible)
- Monitor egress usage in Supabase dashboard over the following days
