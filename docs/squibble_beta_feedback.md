# Squibble Beta Feedback — Consolidated Checklist

Consolidated from 5 testers (Mehul, Sasank, Anshuman, Prath, Aashrita) — February 2026

---

## P0 — Fix Before Main Launch

Critical bugs that will cause user churn or bad first impressions.

- [x] **Push notifications not working** — Multiple testers received zero notifications for doodles, friend requests, or accepted requests. Notifications work in dev but not prod *(Sasank, Anshuman, Prath)* — **Fixed: Edge function was using sandbox APNs server; switched to production. Note: deploy hit internal Supabase error, needs manual redeploy.**
- [x] **Friend invite link is incorrect** — Share message contains wrong app URL. Should be: `https://apps.apple.com/us/app/squibble-doodle-widget/id6757321861` *(Mehul)* — **Fixed: Updated URL in AddFriendsView.swift**
- [x] **Streak not resetting to 0** — Streak number is not calculating as expected. It should represent number of consecutive days you've sent a doodle (NOT received). It should reset to 0 if a day is missed. *(Mehul)* — **Fixed: Added streak validation on user load that resets to 0 if last doodle was 2+ days ago**
- [x] **Duplicate friends in list** — If both users independently send each other a friend request, the friend appears twice in the friend list. *(Prath)* — **Fixed: Added dedup in loadFriends, prevention in sendFriendRequest, DB unique index, and cleaned existing duplicates**
- [x] **Gmail login failing** — Login via Gmail was not working for at least one tester. *(Anshuman)* — **Fixed: Added Google Sign-In URL handling in onOpenURL (was missing with multi-scene support)**
- [ ] **Widget not updating with new doodles** — Widget frequently shows stale content instead of the most recently received doodle. This is sporadic - sometimes is an issue and sometimes is not *(Mehul)*

---

## P1 — Fix Soon (Next Release)

Minor bugs and UX friction that meaningfully impact the experience.

### Bugs

- [ ] **Bottom nav: Profile/Home toggle bug** — After visiting Profile then Home, subsequent taps alternate between the two screens. *(Sasank)*
- [ ] **3-dot menu freezing app** — "More options" button to the right of trash icon is unresponsive/freezes on one tester's device (iPhone 15 Pro Max with iOS 17.6.1). This is a one-off error as it works on other testers' devices. *(Anshuman)*
- [ ] **Tap-to-dot not working** — Tapping the screen to draw a dot doesn't register (only drag works). *(Anshuman)*
- [ ] **App lags on initial startup** — Switching tabs is very slow and brush appears non-functional for a few seconds on first time app startup. This gives off a bad first impression for the app. *(Prath)*
- [ ] **Timing out when sending** - In one instance, app is timing out when sending to multiple people (one-off error, doesn't happen every time). *(Sasank)*

### UX Improvements

- [ ] **Brush size shared between pen and eraser** — Changing brush size affects both pen and eraser tools. These should be independent. *(Sasank)*
- [ ] **Widget install instructions may be wrong** — Onboarding should say: hold home screen → edit → add widget → search Squibble → etc (use more professional wording). *(Mehul)*
- [ ] **Trash button clears uploaded images** — Trash icon should only clear drawn strokes, not image. Uploading a new image should replace existing. Need a separate way to remove the image. *(Mehul)*
- [ ] **Save image: no confirmation feedback** — No haptic or visual feedback when saving an image. *(Sasank)*
- [ ] **Color picker "+" icon confusing** — On color picker circles, replace overlaid "+" icon with an edit icon (pencil/pen or something). *(Sasank, Prath)*
- [ ] **More color options** - In color picker pop-up screen (the screen that appears after a user clicks on a color that is already selected), have 2 tabs at the top - "Preset" and "Custom". Preset should have the 5x5 color grid that already exists in the app. Custom should have a more precise color picker screen where a user can pick an exact color (color wheel or something?)
- [ ] **"Start drawing" empty state styling** — Orange color on text on empty state canvas clashes against some background colors. *(Mehul)*
- [ ] **Show outgoing friend requests** — Can't see outgoing pending friend requests in the Friends list. *(Mehul)*
- [ ] **Friends list / Add Friend too buried** — oO Profile screen below Activity calendar, add section that lists all current friends *(Prath)*

---

## P2 — Backlog (Future Releases)

Feature requests and enhancements. Prioritize by engagement impact vs effort.

### High Value

- [ ] **Collaborative drawing / reply on doodle** — Draw on top of a received doodle and send it back. *(Mehul, Prath)*
- [ ] **Reactions to doodles (emojis)** — Quick emoji reactions on received doodles (show all reactions if doodle was sent to multiple people, show on history/detail pages). *(Mehul, Aashrita)*
- [ ] **Per-friend streak count and stats** — Snapchat-style streaks per friend, plus total doodles exchanged. This can show up on the friends section of the profile page *(Prath)*
- [ ] **Messaging style UI for doodle history / conversation threading** — Add a messaging style UI in the History tab. At the top, user should be able to switch between the grid view (which is what the app currently shows) and the messaging style view. Messaging style view should show doodle exchange history between two friends, reaction history, and ability to send text messages. *(Anshuman, Prath)*
- [ ] **Groups** — Create groups and be able to send doodles to entire groups at once, not just by the person. Groups can show up in the messaging view in the History tab (like a group chat). Need to think through mechanics of how this would work (how to add/remove people from groups, name groups, etc) *(Mehul, Sasank)*

### Medium Value

- [ ] **Unviewed doodle indicator on widget** — Visual badge when multiple unseen doodles are queued (only latest shows currently). *(Mehul)*
- [ ] **Resend doodle to a different friend** — Forward an already-sent doodle to someone new without re-uploading. *(Sasank)*
- [ ] **Add-to-story shortcut** — Quick action to post a doodle as your "story". *(Sasank)*

### Lower Value

- [ ] **Text on doodles** — Type and place text labels on doodles. *(Anshuman)*
- [ ] **Shape tools (squares, circles, etc.)** — Basic shape insertion. *(Anshuman)*
- [ ] **Phone number login** — Alternative signup/login via phone number. *(Anshuman)*
- [ ] **Contacts integration for invites** — Import contacts to invite and add friends. *(Aashrita)*
