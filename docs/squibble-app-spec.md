# Squibble — iOS App MVP Specification

## Overview

**Squibble** is a widget-based iOS app where users can draw and send doodles to friends. Received doodles appear on a home screen widget. The app emphasizes quick, casual communication through simple drawings.

**Core Loop:**
1. User draws a doodle
2. User sends to one or more friends
3. Recipients see the doodle on their home screen widget
4. Recipients can view in-app and reply with their own doodle

---

## Technical Stack

- **Platform:** iOS 17+
- **Language:** Swift
- **UI Framework:** SwiftUI
- **Backend:** Supabase
  - **Auth:** Supabase Auth (Apple Sign-In, Google Sign-In)
  - **Database:** Supabase PostgreSQL
  - **Storage:** Supabase Storage (for doodle images)
  - **Realtime:** Supabase Realtime (for live updates when receiving doodles)
- **Widget:** WidgetKit
- **Ads:** Google AdMob (banner ads)
- **In-App Purchases:** StoreKit 2
- **Push Notifications:** APNs (triggered via Supabase Edge Functions or Database Webhooks)

---

## Data Models

### User
```swift
struct User {
    let id: String
    var displayName: String
    var profileImageURL: String?
    var colorHex: String          // User's signature color for initials circle
    var isPremium: Bool
    var createdAt: Date
    var streak: Int
    var totalDoodlesSent: Int
}
```

### Doodle
```swift
struct Doodle {
    let id: String
    let senderID: String
    let senderName: String
    let senderColorHex: String
    let recipientIDs: [String]
    let imageURL: String
    let createdAt: Date
    let type: DoodleType          // .sent or .received (relative to viewer)
}

enum DoodleType {
    case sent
    case received
}
```

### Friendship
```swift
struct Friendship {
    let id: String
    let userID: String
    let friendID: String
    let status: FriendshipStatus
    let createdAt: Date
}

enum FriendshipStatus {
    case pending
    case accepted
}
```

---

## Supabase Database Schema

### Tables

```sql
-- Users table (extends Supabase auth.users)
create table public.users (
  id uuid references auth.users(id) primary key,
  display_name text not null,
  profile_image_url text,
  color_hex text not null default '#007AFF',
  is_premium boolean not null default false,
  streak int not null default 0,
  total_doodles_sent int not null default 0,
  device_token text,
  invite_code text unique not null,
  created_at timestamp with time zone default now()
);

-- Doodles table
create table public.doodles (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid references public.users(id) not null,
  image_url text not null,
  created_at timestamp with time zone default now()
);

-- Doodle recipients (junction table for many-to-many)
create table public.doodle_recipients (
  id uuid primary key default gen_random_uuid(),
  doodle_id uuid references public.doodles(id) on delete cascade not null,
  recipient_id uuid references public.users(id) not null,
  created_at timestamp with time zone default now(),
  unique(doodle_id, recipient_id)
);

-- Friendships table
create table public.friendships (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid references public.users(id) not null,
  addressee_id uuid references public.users(id) not null,
  status text not null default 'pending' check (status in ('pending', 'accepted')),
  created_at timestamp with time zone default now(),
  unique(requester_id, addressee_id)
);
```

### Storage Buckets

```
doodles/
  └── {user_id}/
      └── {doodle_id}.png
```

- Bucket: `doodles`
- Public read access for authenticated users
- Write access only for own user_id folder

### Row Level Security (RLS) Policies

Enable RLS on all tables. Key policies:

- **users:** Users can read any user's public info, can only update their own row
- **doodles:** Users can read doodles they sent or received, can only insert their own
- **doodle_recipients:** Users can read entries where they are the recipient
- **friendships:** Users can read friendships they're part of, can insert requests, can update status only if they're the addressee
```

---

## App Structure

### Tab Bar
Three tabs at bottom of screen:
1. **History** (left) — clock icon
2. **Home** (center) — house icon, default selected
3. **Profile** (right) — person icon

---

## Screens

### 1. Login/Signup Screen

**Purpose:** Authenticate users

**Entry points:** App launch when logged out

**Components:**
- App logo (squid mascot) and name "Squibble" at top
- "Sign in with Apple" button (required for App Store)
- "Sign in with Google" button
- Terms of service and privacy policy links at bottom

**Actions:**
- Sign in with Apple → authenticate → navigate to Home
- Sign in with Google → authenticate → navigate to Home
- First-time users → create User record with default values

**Edge cases:**
- Auth failure: show error alert with retry option
- Network error: show "No connection" message

---

### 2. Home Screen (Draw)

**Purpose:** Create and send doodles

**Entry points:** Tab bar (center tab), Reply action from Doodle Detail

**Layout:**
```
┌────────────────────────────────┐
│ [👑 Upgrade]    [Add Friends]  │  ← Top bar buttons
├────────────────────────────────┤
│ ┌────────────────────────────┐ │
│ │ [↩️][↪️]              [🔴] │ │  ← Floating controls inside canvas
│ │                            │ │
│ │                            │ │
│ │     [ Drawing Canvas ]     │ │  ← White background, rounded corners
│ │                            │ │
│ │                            │ │
│ │                            │ │
│ └────────────────────────────┘ │
├────────────────────────────────┤
│    [✏️]       [➤]       [◯]   │  ← Pen, Send (large), Eraser
├────────────────────────────────┤
│   [🕐]      [🏠]       [👤]   │  ← Tab bar
└────────────────────────────────┘
```

**Components:**

1. **Top Bar**
   - Left: "Upgrade" button with crown icon → opens Upgrade to Premium screen
   - Right: "Add Friends" button → opens Add Friends screen

2. **Drawing Canvas**
   - Large rounded rectangle, white background
   - Supports touch drawing with finger
   - Floating controls inside canvas corners:
     - Top-left: Undo button, Redo button (side by side)
     - Top-right: Color picker dot (shows current color, tap to open color selection)

3. **Color Picker**
   - Tapping the color dot opens a popover/modal with color options
   - Preset colors: black, red, orange, yellow, green, blue, purple, pink, brown, white
   - Selected color updates the dot and active stroke color

4. **Tool Row** (below canvas)
   - Left: Pen tool icon (circular button)
   - Center: Send button (larger, prominent, circular with arrow icon)
   - Right: Eraser tool icon (circular button)

5. **Pen/Eraser Tool Behavior**
   - Default: Pen is selected on screen load
   - Tap unselected tool → select it, activate that mode
   - Tap already-selected tool → show popover with width slider
   - Width slider: thin to thick (5 discrete sizes or continuous)
   - Selected tool has highlighted/filled appearance; unselected is outlined

**Actions:**
- Draw on canvas → strokes appear in current color/width
- Tap Undo → remove last stroke
- Tap Redo → restore last undone stroke
- Tap color dot → open color picker
- Tap Pen/Eraser → select tool or open settings if already selected
- Tap Send → open Send Sheet (if canvas has content)
- Tap Send with empty canvas → show brief tooltip "Draw something first"
- Tap Upgrade → navigate to Upgrade to Premium screen
- Tap Add Friends → navigate to Add Friends screen

**Edge cases:**
- Empty canvas: Send button disabled or shows tooltip on tap
- Returning from Send Sheet after successful send: canvas clears, brief success animation (checkmark or flash)

**Pre-selected Recipient (Reply flow):**
- When navigating from Doodle Detail "Reply" action, store the sender's ID
- When Send Sheet opens, that friend is pre-selected
- Clear pre-selection after send or if user navigates away

---

### 3. Send Sheet

**Purpose:** Select recipients and send the doodle

**Entry points:** Tap Send button on Home screen

**Type:** Bottom sheet (60-70% screen height)

**Layout:**
```
┌────────────────────────────────┐
│ Send to...               [✕]  │  ← Header with close button
├────────────────────────────────┤
│ [ ] Select All                 │  ← Optional toggle
├────────────────────────────────┤
│ 🔵 Alex                   [✓] │
│ 🟢 Jordan                 [ ] │  ← Friend list with checkboxes
│ 🟣 Sam                    [✓] │
│ 🟠 Taylor                 [ ] │
│ ...                           │
├────────────────────────────────┤
│    [ Send to 2 friends ]      │  ← Sticky footer button
└────────────────────────────────┘
```

**Components:**

1. **Header**
   - Title: "Send to..."
   - Close button (X) on right

2. **Select All Toggle** (optional, include if easy)
   - Toggles all friends selected/deselected

3. **Friend List**
   - Scrollable list of accepted friends
   - Each row: colored circle with initials, friend's display name, checkbox on right
   - Tap row to toggle selection
   - Selected rows show filled checkbox or checkmark

4. **Send Button** (sticky at bottom)
   - Disabled state when no friends selected: grayed out, shows "Select friends"
   - Enabled state: "Send to X friend(s)" with count
   - Tap sends the doodle

**Actions:**
- Tap friend row → toggle selection, update send button count
- Tap Select All → select/deselect all
- Tap Send → upload doodle image, create Doodle records for each recipient, dismiss sheet, show success feedback on Home, clear canvas
- Tap Close or swipe down → dismiss sheet, return to Home with canvas intact

**Edge cases:**
- No friends yet: show message "Add friends to send doodles" with button to Add Friends screen
- Network error on send: show error alert, keep sheet open to retry

---

### 4. History Screen (Grid)

**Purpose:** View sent and received doodles

**Entry points:** Tab bar (left tab)

**Layout:**
```
┌────────────────────────────────┐
│ [All] [Sent] [Received] [Filter]│  ← Filter controls
├────────────────────────────────┤
│ (From: Alex ✕)                 │  ← Person filter chip (when active)
├────────────────────────────────┤
│ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐│
│ │     │ │     │ │     │ │     ││
│ │ 🔵  │ │ 🟢  │ │ 🔵  │ │ 🟣  ││  ← Grid of doodles
│ └─────┘ └─────┘ └─────┘ └─────┘│
│ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐│
│ │     │ │     │ │     │ │     ││
│ │ 🟠  │ │ 🔵  │ │ 🟢  │ │ 🔵  ││
│ └─────┘ └─────┘ └─────┘ └─────┘│
│ ...                            │
├────────────────────────────────┤
│        [ Banner Ad ]           │  ← AdMob banner (free users only)
├────────────────────────────────┤
│   [🕐]      [🏠]       [👤]   │
└────────────────────────────────┘
```

**Components:**

1. **Filter Bar**
   - Segmented control: All (default), Sent, Received
   - Filter icon button on right → opens person filter sheet

2. **Person Filter Chip**
   - Only visible when a specific person is filtered
   - Shows "From: [Name]" with X button to clear
   - Tap X → clear person filter, return to showing all

3. **Person Filter Sheet**
   - Bottom sheet listing all friends
   - Tap friend → set filter, dismiss sheet, show chip
   - "Clear filter" option at top

4. **Doodle Grid**
   - Scrollable grid, 4 columns
   - Each cell: square thumbnail of doodle with colored circle overlay showing sender's initials (bottom-left or bottom-right corner)
   - For sent doodles: show your own color/initials
   - For received doodles: show sender's color/initials
   - Sorted by date, newest first

5. **Banner Ad**
   - Fixed at bottom, above tab bar
   - Only shown for free users
   - Standard AdMob banner size

**Actions:**
- Tap filter segment → filter grid to All/Sent/Received
- Tap Filter icon → open person filter sheet
- Tap person filter chip X → clear person filter
- Tap doodle cell → open Doodle Detail modal

**Edge cases:**
- Empty state (no doodles): show friendly message "No doodles yet. Send one to a friend!"
- Empty after filter: show "No doodles match this filter"
- Loading: show skeleton grid or spinner

---

### 5. Doodle Detail View

**Purpose:** View a single doodle full-screen with metadata and actions

**Entry points:** 
- Tap doodle in History grid
- Tap widget (opens app directly to this view)

**Type:** Full-screen modal

**Layout:**
```
┌────────────────────────────────┐
│ [✕ Close]            [Share]  │  ← Top bar
├────────────────────────────────┤
│                                │
│                                │
│        [ Doodle Image ]        │  ← Full-size doodle
│                                │
│                                │
├────────────────────────────────┤
│   🔵 From: Alex                │  ← Sender info
│   December 26, 2024            │  ← Date
├────────────────────────────────┤
│   [🗑️ Delete]    [↩️ Reply]   │  ← Action buttons
└────────────────────────────────┘
```

**Components:**

1. **Top Bar**
   - Left: Close button (X) → returns to History grid
   - Right: Share button → opens iOS share sheet

2. **Doodle Image**
   - Full-width display of the doodle
   - Maintain aspect ratio (square)
   - Swipe left → next doodle (respects active filter)
   - Swipe right → previous doodle (respects active filter)

3. **Metadata**
   - Sender's colored circle with initials + "From: [Name]"
   - For sent doodles: show "To: [Name(s)]" instead
   - Date in readable format

4. **Action Buttons**
   - Delete: trash icon + "Delete" label
   - Reply: reply icon + "Reply" label (only shown for received doodles)

**Actions:**
- Tap Close → dismiss modal, return to History
- Tap Share → open iOS share sheet with doodle image
- Swipe left/right → navigate to next/previous doodle in current filtered set
- Tap Delete → show confirmation alert → if confirmed, delete from user's history, dismiss modal
- Tap Reply → navigate to Home screen with sender pre-selected as recipient

**Edge cases:**
- Last doodle in set: swipe shows subtle bounce, no navigation
- First doodle in set: swipe shows subtle bounce, no navigation
- Opened from widget: Close returns to History (not dismissing to nothing)

---

### 6. Profile Screen

**Purpose:** View user info, stats, and access settings

**Entry points:** Tab bar (right tab)

**Layout:**
```
┌────────────────────────────────┐
│                    [Settings]  │  ← Settings button top-right
├────────────────────────────────┤
│         [ Avatar ]             │
│        User's Name             │  ← Profile section
│         🔵 (color)             │
├────────────────────────────────┤
│  Doodles Sent        Streak    │
│      127              14 🔥    │  ← Stats row
├────────────────────────────────┤
│ ┌─────────────────────────────┐│
│ │     [ Calendar View ]       ││  ← Activity calendar
│ │  Shows days doodles sent    ││
│ └─────────────────────────────┘│
├────────────────────────────────┤
│   [🕐]      [🏠]       [👤]   │
└────────────────────────────────┘
```

**Components:**

1. **Settings Button**
   - Gear icon, top-right
   - Tap → navigate to Settings screen

2. **Profile Section**
   - Profile picture (circular, tap to change)
   - Display name
   - User's signature color shown as colored dot

3. **Stats Row**
   - Total doodles sent (count)
   - Current streak (count + fire emoji)

4. **Activity Calendar**
   - Monthly calendar view (similar to GitHub contribution graph)
   - Days where user sent a doodle are highlighted/marked
   - Can scroll to previous months

**Actions:**
- Tap Settings → navigate to Settings screen
- Tap profile picture → open image picker to change photo
- Tap name → open edit name flow (inline or sheet)

**Edge cases:**
- No profile picture: show default avatar with initials
- Zero stats: show "0" values

---

### 7. Settings Screen

**Purpose:** Manage account settings and preferences

**Entry points:** Settings button on Profile screen

**Type:** Full-screen navigation push

**Layout:**
```
┌────────────────────────────────┐
│ [← Back]        Settings       │
├────────────────────────────────┤
│ ACCOUNT                        │
│ ┌─────────────────────────────┐│
│ │ Edit Name                  >││
│ │ Edit Profile Picture       >││
│ │ Change My Color            >││
│ └─────────────────────────────┘│
├────────────────────────────────┤
│ PREFERENCES                    │
│ ┌─────────────────────────────┐│
│ │ Notifications              >││
│ └─────────────────────────────┘│
├────────────────────────────────┤
│ MEMBERSHIP                     │
│ ┌─────────────────────────────┐│
│ │ Premium Status      Free   >││
│ └─────────────────────────────┘│
├────────────────────────────────┤
│ SUPPORT                        │
│ ┌─────────────────────────────┐│
│ │ Help & FAQ                 >││
│ │ Contact Us                 >││
│ └─────────────────────────────┘│
├────────────────────────────────┤
│ ┌─────────────────────────────┐│
│ │ Sign Out                    ││
│ │ Delete Account              ││  ← Destructive actions
│ └─────────────────────────────┘│
└────────────────────────────────┘
```

**Components:**

Standard iOS settings list with grouped sections:

1. **Account**
   - Edit Name → inline edit or sheet
   - Edit Profile Picture → image picker
   - Change My Color → color picker (same preset colors as drawing)

2. **Preferences**
   - Notifications → system notification settings

3. **Membership**
   - Shows current status (Free/Premium)
   - Tap → navigate to Upgrade to Premium screen

4. **Support**
   - Help & FAQ → web view or in-app FAQ
   - Contact Us → opens email composer

5. **Destructive Actions**
   - Sign Out → confirmation → sign out → return to Login
   - Delete Account → confirmation with warning → delete all data → return to Login

**Actions:**
- Tap Back → return to Profile
- Each row navigates to appropriate edit flow or screen

---

### 8. Add Friends Screen

**Purpose:** Manage friends and friend requests

**Entry points:** "Add Friends" button on Home screen

**Type:** Full-screen modal or navigation push

**Layout:**
```
┌────────────────────────────────┐
│ [← Back]      Add Friends      │
├────────────────────────────────┤
│ INVITE FRIENDS                 │
│ ┌─────────────────────────────┐│
│ │ 🔗 Your invite link  [Copy] ││
│ │ squibble.app/add/abc123     ││
│ └─────────────────────────────┘│
├────────────────────────────────┤
│ FRIEND REQUESTS (2)            │
│ ┌─────────────────────────────┐│
│ │ 🟢 Jordan      [✓] [✕]     ││  ← Accept / Decline buttons
│ │ 🟣 Riley       [✓] [✕]     ││
│ └─────────────────────────────┘│
├────────────────────────────────┤
│ FRIENDS (12 of 30)             │  ← Count shown for free users
│ ┌─────────────────────────────┐│
│ │ 🔵 Alex                [✕] ││
│ │ 🟠 Sam                 [✕] ││  ← Remove friend button
│ │ 🔴 Taylor              [✕] ││
│ │ ...                        ││
│ └─────────────────────────────┘│
└────────────────────────────────┘
```

**Components:**

1. **Invite Section**
   - Unique shareable link for user
   - Copy button → copies link to clipboard, shows "Copied!" feedback
   - Optionally: Share button to open iOS share sheet

2. **Friend Requests Section**
   - List of pending incoming requests
   - Each row: colored circle, name, Accept (checkmark) button, Decline (X) button
   - Only shows if there are pending requests

3. **Friends List Section**
   - Header shows count: "FRIENDS (X of 30)" for free users, "FRIENDS (X)" for premium
   - List of accepted friends
   - Each row: colored circle, name, Remove (X) button on right
   - Remove button → confirmation alert → remove friend

**Actions:**
- Tap Copy → copy link to clipboard
- Tap Accept → accept request, move to friends list
- Tap Decline → remove request
- Tap Remove friend → confirmation → remove from friends list
- Tap Back → return to Home

**Edge cases:**
- Free user at 30 friends: show message "Friend limit reached. Upgrade to Premium for unlimited friends." Accept button disabled on new requests.
- No friend requests: hide that section entirely
- No friends: show "No friends yet. Share your link to connect!"

---

### 9. Upgrade to Premium Screen

**Purpose:** Show premium features and allow purchase

**Entry points:** "Upgrade" button on Home screen, Premium row in Settings

**Type:** Full-screen modal

**Layout:**
```
┌────────────────────────────────┐
│ [✕]                            │
├────────────────────────────────┤
│          ✨ Premium ✨          │
│                                │
│   Unlock the full experience   │
├────────────────────────────────┤
│ ┌─────────────────────────────┐│
│ │ 👥 Unlimited Friends        ││
│ │    No more 30 friend limit  ││
│ ├─────────────────────────────┤│
│ │ 🚫 Remove Ads               ││
│ │    Enjoy an ad-free         ││
│ │    experience               ││
│ ├─────────────────────────────┤│
│ │ 🎨 AI Magic (Coming Soon)   ││
│ │    Transform doodles into   ││
│ │    AI art or animations     ││
│ ├─────────────────────────────┤│
│ │ 🖼️ Custom Widgets           ││
│ │    Unique frames and app    ││
│ │    icons                    ││
│ └─────────────────────────────┘│
├────────────────────────────────┤
│   [ Upgrade for $X.XX/month ]  │  ← Purchase button
│                                │
│   Restore Purchases            │
└────────────────────────────────┘
```

**Components:**

1. **Header**
   - Close button (X) top-left
   - "Premium" title with sparkle emojis
   - Subtitle: "Unlock the full experience"

2. **Features List**
   - Each feature: icon/emoji, title, short description
   - Features:
     - Unlimited Friends: "No more 30 friend limit"
     - Remove Ads: "Enjoy an ad-free experience"
     - AI Magic (Coming Soon): "Transform doodles into AI art or animations" — show "Coming Soon" badge
     - Custom Widgets: "Unique frames and app icons"

3. **Pricing Options**
   - Two subscription tiers:
     - **Annual**: $35.99/year ($2.99/mo equivalent) — Best Value badge
     - **Monthly**: $3.99/month
   - Show localized prices from StoreKit
   - Annual plan highlighted as recommended

4. **Purchase Button**
   - Large, prominent button for selected plan
   - Shows price from StoreKit
   - Tap → initiate StoreKit purchase flow

5. **Restore Purchases**
   - Text button below main CTA
   - Tap → restore previous purchases

**Actions:**
- Tap Close → dismiss modal
- Tap Upgrade → StoreKit purchase flow → on success, update user.isPremium, dismiss modal, show success message
- Tap Restore → restore purchases → update premium status if applicable

**Edge cases:**
- Already premium: show "You're a Premium member!" with feature list, no purchase button
- Purchase failed: show error alert
- No network: show error message

---

## Widget Specification

### Widget Type
- **Size:** Small (single size for MVP)
- **Kind:** Static content, refreshed via background updates

### Widget Display
```
┌─────────────────┐
│                 │
│   [ Doodle ]    │
│                 │
│            🔵   │  ← Sender initials circle (bottom-right corner)
└─────────────────┘
```

**Components:**
- Doodle image fills widget (square aspect ratio)
- Small colored circle with sender's initials in bottom-right corner
- If no doodles received yet: show empty state (Squibble logo or "No doodles yet" message)

### Widget Behavior
- **Content:** Most recently received doodle
- **Tap action:** Open app to Doodle Detail view for that specific doodle
- **Refresh:** Update when new doodle is received (via push notification trigger or background refresh)

### Widget Configuration
- No configuration for MVP (single widget showing most recent doodle)
- Future: allow selecting specific friend to show doodles from

### Implementation Notes
- Use WidgetKit with TimelineProvider
- Store most recent doodle info in shared App Group container (for widget access)
- Use Supabase Realtime to subscribe to new doodles for current user
- When new doodle received:
  1. Download doodle image from Supabase Storage
  2. Save doodle image to App Group container
  3. Update stored metadata (sender, date, doodle ID)
  4. Reload widget timeline via WidgetCenter.shared.reloadAllTimelines()

---

## Navigation Flows

### Main Navigation
- Tab bar always visible on Home, History, Profile
- Modals/sheets overlay without hiding tabs when appropriate

### Key Flows

**Send Doodle Flow:**
1. User draws on Home canvas
2. Tap Send → Send Sheet opens
3. Select friends → Tap "Send to X friends"
4. Sheet dismisses, success feedback, canvas clears

**Reply Flow:**
1. View received doodle in Doodle Detail (from History or widget)
2. Tap Reply
3. Navigate to Home with sender pre-selected
4. Draw and tap Send → Send Sheet opens with sender pre-checked
5. Complete send flow

**Widget Tap Flow:**
1. User taps widget
2. App opens directly to Doodle Detail showing that doodle
3. User can Reply, Share, Delete, or Close
4. Close → goes to History grid

**Add Friend Flow:**
1. User A shares invite link
2. User B opens link → Squibble opens (or App Store if not installed)
3. If User B logged in: friend request sent to User A
4. User A sees request in Add Friends screen
5. User A accepts → both users now friends

---

## Premium Features Summary

| Feature | Free | Premium |
|---------|------|---------|
| Friends limit | 30 | Unlimited |
| Ads | Banner ads in History | No ads |
| AI features | — | Coming soon |
| Widget frames | Default only | Custom frames |
| App icon | Default only | Custom icons |

---

## Push Notifications

### Notification Types
1. **New doodle received**
   - Title: "[Name] sent you a doodle!"
   - Body: "Tap to view"
   - Action: Open Doodle Detail for that doodle

2. **Friend request received**
   - Title: "New friend request"
   - Body: "[Name] wants to connect"
   - Action: Open Add Friends screen

3. **Friend request accepted**
   - Title: "[Name] accepted your request"
   - Body: "You can now send each other doodles"
   - Action: Open app to Home

### Implementation Notes
- Use APNs for push notifications
- Store device tokens in `users` table
- Trigger notifications via Supabase Edge Functions when relevant database events occur (new doodle inserted, friend request created, friend request accepted)
- Use Supabase Database Webhooks to call Edge Functions on table inserts/updates

---

## Empty States

| Screen | Empty State Message |
|--------|---------------------|
| History (no doodles) | "No doodles yet. Send one to a friend!" with illustration |
| History (filter yields nothing) | "No doodles match this filter" |
| Send Sheet (no friends) | "Add friends to send doodles" with button to Add Friends |
| Add Friends (no friends) | "No friends yet. Share your link to connect!" |
| Add Friends (no requests) | Hide friend requests section entirely |
| Widget (no doodles) | Squibble logo or "No doodles yet" text |

---

## Error Handling

| Scenario | Handling |
|----------|----------|
| Network error on send | Alert: "Couldn't send doodle. Check your connection and try again." Keep Send Sheet open. |
| Network error on load | Show cached data if available, or "Couldn't load. Pull to refresh." |
| Auth error | Return to Login screen |
| Image upload failure | Alert: "Upload failed. Try again." |
| Friend limit reached | Alert: "You've reached the 30 friend limit. Upgrade to Premium for unlimited friends." |

---

## Future Enhancements (Post-MVP)

- Messages/chat feature with captions
- AI doodle transformation (convert to AI art)
- AI doodle animation
- Multiple widget sizes (medium, large)
- Widget configuration (select specific friend)
- Custom widget frames
- Custom app icons
- Brush variety (marker, pencil, etc.)
- Sound effects on send/receive
- Reactions to doodles
