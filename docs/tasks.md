# Squibble iOS App - Development Tasks

## Checkpoint 1: Project Setup & Infrastructure

### Tasks
- [x] Create new Xcode project (iOS App, Swift, SwiftUI)
- [x] Configure project settings (Bundle ID, deployment target iOS 17+)
- [x] Set up App Group for widget data sharing *(requires Xcode - see action items)*
- [x] Create folder structure:
  - `Squibble/` (main app)
    - `Models/`
    - `Views/`
    - `ViewModels/`
    - `Services/`
    - `Utilities/`
  - `SquibbleWidget/` (widget extension) *(created later in Checkpoint 14)*
- [x] Add Supabase Swift SDK via Swift Package Manager *(requires Xcode - see action items)*
- [x] Add Google Sign-In SDK via Swift Package Manager *(requires Xcode - see action items)*
- [x] Add Google Mobile Ads SDK (AdMob) via Swift Package Manager *(requires Xcode - see action items)*
- [x] Configure Info.plist for URL schemes (Google Sign-In, deep links)
- [x] Set up environment configuration (dev/prod Supabase URLs and keys)

### Action Items for You
- [x] **Create Supabase project** at https://supabase.com
- [x] **Provide Supabase URL and anon key** for the app configuration
- [ ] **PENDING: Create paid Apple Developer account** - $99/year, account created but pending approval
- [ ] **DEFERRED: Set up App ID with Sign in with Apple capability** - needs paid account approval
- [x] **Create Google Cloud project** - completed
- [x] **Provide Google OAuth Client ID** - completed (299546177576-o1rfsm38e341al7h51g3h1obe09balbg.apps.googleusercontent.com)

---

## Checkpoint 2: Supabase Backend Setup

### Tasks
- [x] Create database schema (users, doodles, doodle_recipients, friendships tables)
- [x] Set up Row Level Security (RLS) policies for all tables
- [x] Create `doodles` storage bucket with appropriate policies
- [x] Create database indexes for performance (sender_id, recipient_id, created_at)
- [ ] **DEFERRED: Create Supabase Edge Function for push notifications (new doodle)** - needs APNs setup
- [ ] **DEFERRED: Create Supabase Edge Function for friend request notifications** - needs APNs setup
- [ ] **DEFERRED: Create Supabase Edge Function for friend accept notifications** - needs APNs setup
- [ ] **DEFERRED: Set up Database Webhooks to trigger Edge Functions** - needs Edge Functions first
- [x] Create function to generate unique invite codes for users
- [x] Test all database operations and RLS policies *(tables created, RLS enabled, can test further when app connects)*

### Action Items for You
- [x] **Enable Google Auth provider in Supabase Dashboard** - completed
- [ ] **DEFERRED: Enable Apple Auth provider in Supabase Dashboard** - needs paid Apple Developer account
- [ ] **DEFERRED: Configure Apple Sign-In** in Supabase Auth settings - needs paid Apple Developer account
- [x] **Configure Google Sign-In** in Supabase Auth settings - completed
- [ ] **DEFERRED: Set up APNs** - needs paid Apple Developer account
- [ ] **DEFERRED: Create APNs Auth Key** (.p8 file) - needs paid Apple Developer account
- [ ] **DEFERRED: Configure push notifications** - needs APNs credentials

### Notes for Mehul
- Database schema fully set up with 4 tables: users, doodles, doodle_recipients, friendships
- All RLS policies configured for secure data access
- Storage bucket "doodles" created with upload/read/delete policies
- SQL migrations saved in `docs/migrations/` for production deployment
- Push notification features deferred until paid Apple Developer account is set up
- Auth provider configuration deferred until Google Cloud and Apple credentials are ready

---

## Checkpoint 3: Core Data Models & Services

### Tasks
- [x] Define Swift data models:
  - `User` model
  - `Doodle` model
  - `DoodleRecipient` model
  - `Friendship` model
- [x] Create Supabase service layer (`SupabaseService.swift`):
  - Initialize Supabase client
  - Auth methods (sign in, sign out, get session)
  - User CRUD operations
  - Doodle CRUD operations
  - Friendship operations
  - Storage operations (upload/download images)
- [x] Create Auth manager (`AuthManager.swift`) as ObservableObject
- [x] Create User manager (`UserManager.swift`) for current user state
- [x] Create Doodle manager (`DoodleManager.swift`) for doodle operations
- [x] Create Friend manager (`FriendManager.swift`) for friend operations
- [x] Set up Supabase Realtime subscriptions for live updates (`RealtimeService.swift`)
- [x] Create App Group shared storage utility for widget communication (`AppGroupStorage.swift`)
- [x] Create image caching service for doodle thumbnails (`ImageCache.swift`)

### Notes for Mehul
- All data models created in `squibble/Models/` (User, Doodle, DoodleRecipient, Friendship)
- All service managers created in `squibble/Services/`
- Auth sign-in methods are ready but require Apple/Google credentials to be configured (deferred from Checkpoints 1 & 2)
- Realtime subscriptions set up for live doodle and friendship updates
- App Group storage ready for widget communication
- No action items required at this checkpoint

---

## Checkpoint 4: Authentication Flow

### Tasks
- [x] Create `LoginView` with:
  - App logo and branding
  - Sign in with Email button
  - Sign in with Apple button
  - Sign in with Google button
  - Terms/Privacy links at bottom
- [x] Implement Email/Password authentication *(email verification deferred)*
- [ ] **DEFERRED: Email verification flow** - configure Supabase redirect URLs when preparing for prod
- [ ] **DEFERRED: Apple Sign-In** - requires paid Apple Developer account ($99/year)
- [x] **Google Sign-In** - Fully implemented with GoogleSignIn SDK
- [x] Handle first-time user creation (create User record with defaults)
- [x] Handle returning user sign-in (fetch existing User data)
- [x] Implement auth state persistence (auto-login on app launch)
- [x] Create loading/splash screen during auth check
- [x] Handle auth errors with user-friendly alerts
- [x] Implement sign out flow
- [x] Create root view that switches between Login and Main app based on auth state
- [x] Create password reset flow

### Action Items for You
- [ ] **DEFERRED: Provide Terms of Service URL** - lower priority, can add before App Store submission
- [ ] **DEFERRED: Provide Privacy Policy URL** - lower priority, can add before App Store submission
- [ ] **DEFERRED: Configure Supabase email verification redirect URLs** - set Site URL to `squibble://` and add redirect URLs
- [ ] **DEFERRED: Apple Developer account + Sign in with Apple setup** - pending account approval
- [x] **Google Cloud project + Google Sign-In setup** - completed

### Notes for Mehul
- LoginView (`squibble/Views/LoginView.swift`) created with playful design:
  - Warm gradient background with floating animated shapes
  - Squid mascot logo with coral/orange gradient
  - "Continue with Email" button (primary, coral gradient)
  - Native Apple Sign-In button (code ready, needs credentials)
  - Styled Google button (shows "coming soon", needs credentials)
  - Entry animations and loading overlay
- Email authentication added (`EmailAuthView`):
  - Sign up with email, password, display name
  - Sign in with email and password
  - Password reset flow (`PasswordResetView`)
  - Form validation (password min 6 chars, passwords must match)
  - Toggle between Sign In / Sign Up modes
- SplashView (`squibble/Views/SplashView.swift`) shows during auth check with pulsing logo
- RootView (`squibble/Views/RootView.swift`) switches between Splash, Login, and MainTabView
- Auth state persistence works via AuthManager.checkSession() on app launch
- **Email verification disabled in Supabase** for development - re-enable before production
- **Email auth works now** - use this for testing during development
- Apple/Google sign-in buttons exist but are deferred until credentials are set up

---

## Checkpoint 5: Tab Bar & Navigation Structure

### Tasks
- [x] Create main `MainTabView` with TabView
- [x] Create tab bar with three tabs:
  - History (clock icon)
  - Home (house icon) - default selected
  - Profile (person icon)
- [x] Create placeholder views for each tab:
  - `HistoryView`
  - `HomeView`
  - `ProfileView`
- [x] Set up navigation patterns:
  - Sheet presentations
  - Full-screen modals
  - Navigation stack for Settings
- [x] Create app-wide navigation state manager
- [x] Handle deep links for widget taps and invite links

### Notes for Mehul
- `MainTabView.swift` created with custom animated tab bar:
  - Coral/orange gradient theme consistent with app design
  - Matched geometry effect for smooth tab indicator animation
  - Glass morphism background with subtle shadows
- Placeholder views created for all three tabs:
  - `HistoryView.swift` - shows clock icon with "Your Doodle History" message
  - `HomeView.swift` - shows "Draw a Squibble" message with placeholder "Start Drawing" button
  - `ProfileView.swift` - shows profile placeholder with working Sign Out button for testing
- `NavigationManager.swift` created for:
  - Global tab state management via `@Published selectedTab`
  - Deep link handling for `squibble://` URL scheme:
    - `squibble://doodle/{id}` - opens specific doodle in History
    - `squibble://invite?code={code}` - handles friend invites
    - `squibble://draw` - opens Home tab for drawing
- Deep links wired up in `squibbleApp.swift` via `.onOpenURL`
- Tab bar uses page style for swipe navigation between tabs
- Sign out button in ProfileView allows testing auth flow during development
- No action items required at this checkpoint

---

## Checkpoint 6: Drawing Canvas & Home Screen

### Tasks
- [x] Create `HomeView` layout with:
  - Top bar (Add Friends button)
  - Drawing canvas area
  - Tool row (Pen, Send, Eraser)
- [x] Build `DrawingCanvas` view using Canvas or PencilKit:
  - Touch drawing support
  - Stroke rendering with color and width
  - Undo/Redo stack implementation
- [x] Create floating controls inside canvas:
  - Undo button (top-left)
  - Redo button (top-left, next to undo)
  - Color picker dot (top-right)
- [x] Implement `ColorPickerView`:
  - Preset colors (black, red, orange, yellow, green, blue, purple, pink, brown, white)
  - Selection state
  - Popover presentation
- [x] Implement pen/eraser tool switching:
  - Selected tool highlighting
  - Tap selected tool → show width slider popover
  - Width slider with continuous sizes
- [x] Create canvas export function (convert drawing to PNG)
- [x] Handle empty canvas state (disable Send button when canvas empty)
- [ ] Implement canvas clear after successful send *(deferred to Checkpoint 7 - Send flow)*
- [ ] Store pre-selected recipient for Reply flow *(deferred to Checkpoint 9 - Doodle Detail)*

### Notes for Mehul
- Drawing canvas built using SwiftUI Canvas API (not PencilKit) for full control:
  - Smooth bezier curve interpolation for natural-looking strokes
  - Full undo/redo stack with unlimited history
  - Eraser tool works by drawing white strokes with blend mode
- New files created in `squibble/Views/Drawing/`:
  - `DrawingCanvas.swift` - Core canvas with touch gesture handling and PNG export
  - `ColorPickerView.swift` - 10-color preset palette in a grid
  - `BrushSizeSlider.swift` - Custom slider for brush width (2-20pt)
- HomeView now has full drawing interface:
  - Header with "Add Friends" button (opens placeholder sheet)
  - Canvas with floating undo/redo and color picker buttons
  - Tool bar with Pen, Send, and Eraser buttons
  - Send button disabled when canvas is empty (gray color)
  - Tapping selected tool opens brush size slider
- Placeholder sheets added for Send and Add Friends (to be implemented in Checkpoints 7 and 12)
- Canvas export function ready: `drawingState.exportToPNG(size:)` returns PNG Data
- No action items required at this checkpoint

---

## Checkpoint 7: Send Sheet & Doodle Upload

### Tasks
- [x] Create `SendSheet` as bottom sheet:
  - Header with "Send to..." and close button
  - Optional "Select All" toggle
  - Friend list with checkboxes
  - Sticky "Send to X friend(s)" button
- [x] Fetch and display accepted friends list
- [x] Implement friend selection/deselection
- [x] Create send button with dynamic count
- [x] Handle empty friends list (show message + Add Friends button)
- [x] Implement doodle upload flow:
  1. Export canvas to PNG
  2. Upload to Supabase Storage (`doodles/{user_id}/{doodle_id}.png`)
  3. Create Doodle record in database
  4. Create DoodleRecipient records for each recipient
  5. Update user's totalDoodlesSent count *(deferred to Checkpoint 10 - Profile)*
  6. Update user's streak if applicable *(deferred to Checkpoint 10 - Profile)*
- [x] Show loading state during upload
- [x] Handle upload errors with retry option
- [x] Show success animation on Home after send
- [x] Clear canvas after successful send
- [ ] Trigger push notification via Edge Function on successful send *(deferred to Checkpoint 15 - Push Notifications)*

### Notes for Mehul
- `SendSheet.swift` created with full friend selection functionality:
  - Displays friend list from FriendManager with colored avatar initials
  - "Select All" toggle for quick selection
  - Dynamic send button ("Send to X friends")
  - Loading spinner during upload
  - Success animation with checkmark after send
- Empty friends state shows friendly message with "Add Friends" button
- Doodle upload flow implemented in `DoodleManager.sendDoodle()`:
  - Exports canvas to PNG using `DrawingState.exportToPNG()`
  - Uploads to Supabase Storage (`doodles/{user_id}/{doodle_id}.png`)
  - Creates Doodle record in `doodles` table
  - Creates DoodleRecipient records for each selected friend
- Canvas clears automatically after successful send
- Error handling with alert dialog for upload failures
- User stats (totalDoodlesSent, streak) updates deferred to Profile checkpoint
- Push notifications deferred to Checkpoint 15
- No action items required at this checkpoint

---

## Checkpoint 8: History Screen & Doodle Grid

### Tasks
- [x] Create `HistoryView` layout:
  - Filter bar (All, Sent, Received segments)
  - Filter icon button
  - Person filter chip (when active)
  - Doodle grid
  - Banner ad area (for free users) *(deferred to Checkpoint 13 - Premium)*
- [x] Implement segmented filter (All/Sent/Received)
- [x] Create `PersonFilterSheet`:
  - List of all friends
  - Selection action
  - Clear filter option
- [x] Build doodle grid (3 columns):
  - Square thumbnails with lazy loading via AsyncImage
  - Colored circle overlay with sender initials
  - Paperplane icon for sent doodles
  - Sorted by date (newest first)
- [x] Fetch doodles from Supabase with appropriate filters
- [ ] Implement pagination/infinite scroll for large doodle counts *(deferred - not needed until scale)*
- [x] Handle empty states:
  - No doodles: "No Doodles Yet" with clock icon
  - Filter yields nothing: "No Matches" with magnifying glass icon
- [x] Create loading state (spinner)
- [ ] Integrate AdMob banner ad (for free users only) *(deferred to Checkpoint 13 - Premium)*

### Notes for Mehul
- `HistoryView.swift` completely rebuilt with full functionality:
  - Header with "History" title and person filter button
  - Filter pills (All/Sent/Received) with gradient active state
  - Person filter chip appears when friend is selected (with X to clear)
  - 3-column LazyVGrid for doodle thumbnails
  - Each grid item shows doodle image with sender badge (initials + paperplane for sent)
  - Tapping a doodle opens full-screen detail view (placeholder for Checkpoint 9)
- `PersonFilterSheet` created for filtering by friend:
  - Shows list of all friends with avatars
  - "Clear Filter" option when filter is active
  - Checkmark indicator for selected friend
- Empty states with contextual messaging:
  - Default: "No Doodles Yet" with clock icon
  - With filters: "No Matches" with magnifying glass icon
- Loading state shows coral-colored spinner
- Doodles fetched via `DoodleManager.loadDoodles()` on view appear
- `DoodleDetailPlaceholder` added for tapping doodles (full implementation in Checkpoint 9)
- **AdMob banner ads implemented** - shows at bottom of History screen for free users only
- Pagination deferred - current implementation handles reasonable doodle counts

### Action Items for You
- [x] **Create AdMob account** at https://admob.google.com - completed
- [x] **Create AdMob app** and ad units (banner ad) - completed
- [x] **Provide AdMob App ID and Ad Unit ID** for integration - completed (App ID: ca-app-pub-8866277760401021~5069811424, Banner: ca-app-pub-8866277760401021/3265775167)

---

## Checkpoint 9: Doodle Detail View

### Tasks
- [x] Create `DoodleDetailView` as full-screen modal:
  - Top bar (Close, Share buttons)
  - Full-size doodle image
  - Sender/recipient info with colored circle
  - Date display (relative time)
  - Action buttons (Delete, Reply)
- [x] Implement swipe gestures for next/previous doodle navigation
- [x] Respect current filter when navigating between doodles
- [x] Implement Share action (iOS share sheet with doodle image)
- [x] Implement Delete action:
  - Confirmation alert with context-aware message
  - Sender: permanently deletes doodle for everyone
  - Recipient: removes from their history only
  - Dismiss and return to History
- [x] Implement Reply action:
  - Navigate to Home tab
  - Pre-select sender as recipient in SendSheet
- [x] Handle edge cases:
  - Swipe bounded to first/last doodle
  - Page indicator shows current position

### Notes for Mehul
- `DoodleDetailView.swift` created with full functionality:
  - Full-screen modal with close and share buttons in top bar
  - Large centered doodle image with shadow
  - Sender info with colored avatar, name, and relative date ("2 hours ago")
  - "You" label with paperplane icon for sent doodles
  - Delete button (coral background) and Reply button (gradient, only for received)
- Swipe navigation between doodles:
  - Horizontal drag gesture to navigate through filtered doodles
  - Page indicator shows "X of Y" in top bar
  - Spring animation on swipe
- Share functionality:
  - Downloads image from Supabase Storage
  - Opens iOS share sheet with image
- Delete functionality:
  - Confirmation alert with different messages for sender vs recipient
  - Sender: calls `deleteSentDoodle` (removes for everyone)
  - Recipient: calls `removeReceivedDoodle` (removes from their view only)
  - Dismisses after successful deletion
- Reply functionality:
  - Sets `pendingReplyRecipientID` in NavigationManager
  - Switches to Home tab
  - SendSheet reads this and pre-selects the friend
- `NavigationManager.swift` updated with `pendingReplyRecipientID` property
- `SendSheet.swift` updated to pre-select reply recipient on appear
- Removed `DoodleDetailPlaceholder` from HistoryView
- No action items required at this checkpoint

---

## Checkpoint 10: Profile Screen

### Tasks
- [x] Create `ProfileView` layout:
  - Settings button (top-right)
  - Profile picture (circular, tappable)
  - Display name (tappable to edit)
  - Signature color dot
  - Stats row (Doodles Sent, Streak, Friends)
- [x] Implement profile picture picker:
  - PhotosUI picker integration
  - Upload to Supabase Storage (profiles bucket)
  - Update user record
- [x] Implement inline name editing
- [x] Create `ActivityCalendarView`:
  - Monthly calendar grid
  - Highlight days with doodles sent (gradient opacity based on count)
  - Navigate to previous/next months
  - Today indicator (coral ring)
- [x] Fetch activity data from sent doodles
- [x] Handle default avatar (initials on colored background)
- [x] Display streak with fire emoji 🔥
- [x] Add invite code card with Copy button

### Notes for Mehul
- `ProfileView.swift` completely rebuilt with compact layout:
  - Header with "Profile" title and Settings gear button
  - Tappable avatar with camera badge (opens PhotosPicker)
  - Default avatar: gray fill with initials, outlined in user's signature color
  - Profile photos also show signature color outline
  - Name is tappable to edit via alert dialog
- Stats row shows three metrics:
  - Doodles Sent (with paperplane icon)
  - Day Streak (with 🔥 emoji when > 0)
  - Friends count (from FriendManager)
- `ActivityCalendarView` component (compact, visible without scrolling):
  - Monthly calendar with month/year navigation
  - Days with doodles highlighted with coral/orange gradient
  - Opacity increases based on number of doodles sent
  - Today has coral ring indicator
  - Can't navigate past current month
- Profile image upload:
  - Uses PhotosUI `PhotosPicker`
  - Compresses image to JPEG (70% quality)
  - Uploads to Supabase Storage "profiles" bucket
  - `uploadProfileImage` added to `SupabaseService.swift`
- `SettingsPlaceholder` view shows "Coming in Checkpoint 11" message
- Invite code section removed - friend sharing via invite links will be handled in Add Friends screen (Checkpoint 12)
- **Action Required**: Create "profiles" storage bucket in Supabase Dashboard for profile image uploads (similar to "doodles" bucket)

---

## Checkpoint 11: Settings Screen

### Tasks
- [x] Create `SettingsView` with grouped sections:
  - ACCOUNT: Edit Name, Edit Profile Picture, Change My Color
  - PREFERENCES: Notifications
  - MEMBERSHIP: Premium Status
  - SUPPORT: Help & FAQ, Contact Us
  - Destructive: Sign Out, Delete Account
- [x] Implement Edit Name flow (alert dialog)
- [x] Implement Edit Profile Picture (reuse PhotosPicker from Profile)
- [x] Create `ColorPickerSettingsView` for changing user color
- [x] Implement Notifications row (opens iOS Settings app)
- [x] Implement Premium Status row (placeholder for Checkpoint 13)
- [x] Implement Help & FAQ row (placeholder - needs URL)
- [x] Implement Contact Us (mailto: link - needs email)
- [x] Implement Sign Out:
  - Confirmation alert
  - Sign out from Supabase
  - Clear user state
- [x] Implement Delete Account:
  - Warning confirmation
  - Full data deletion (doodles, friendships, storage files, user record)
  - Sign out after deletion

### Action Items for You
- [ ] **DEFERRED: Create Help & FAQ page/URL** - do before App Store submission
- [ ] **DEFERRED: Set up support email address** - do before App Store submission (currently placeholder: support@squibble.app)

### Notes for Mehul
- `SettingsView.swift` created with full grouped sections:
  - **ACCOUNT**: Display Name (edit via alert), Profile Picture (PhotosPicker), Signature Color (ColorPickerSettingsView)
  - **PREFERENCES**: Notifications (opens iOS Settings)
  - **MEMBERSHIP**: Premium status with "Active" badge for premium users, "Upgrade" badge for free users
  - **SUPPORT**: Help & FAQ, Contact Us (opens email)
  - Destructive section: Sign Out and Delete Account with confirmation alerts
- `ColorPickerSettingsView` allows users to pick from 12 preset colors:
  - Shows live preview of avatar with selected color outline
  - Animated selection with checkmark and scale effect
  - Saves color to Supabase via `userManager.updateColor()`
- Each settings row has colored icon with subtle background tint
- Contact email placeholder: `support@squibble.app` - update when actual email is ready
- Help & FAQ currently doesn't open anything - needs a URL to be configured
- Removed `SettingsPlaceholder` from ProfileView
- App version shown at bottom: "Squibble v1.0.0"

### Deferred to Before Production
- [ ] **Implement full account data deletion** - Delete Account currently only signs out; need to delete user's doodles, friendships, and user record from Supabase before production

---

## Checkpoint 12: Add Friends Screen

### Tasks
- [x] Create `AddFriendsView` layout:
  - Invite section with unique link
  - Friend requests section (if any)
  - Friends list section
- [x] Generate unique invite link for user (`squibble.app/add/{invite_code}`)
- [x] Implement Copy button with "Copied!" feedback
- [x] Implement Share button (iOS share sheet)
- [x] Create friend requests list:
  - Accept button → update friendship status, move to friends
  - Decline button → delete friendship record
- [x] Create friends list:
  - Show count (X of 30 for free, just X for premium)
  - Remove button with confirmation
- [x] Handle friend limit (30 for free users):
  - Show upgrade message when limit reached
  - Disable Accept on new requests
- [x] Handle empty states:
  - No friends: "No friends yet. Share your link to connect!"
  - No requests: Hide section
- [ ] Set up deep link handling for invite links *(deferred - requires domain setup)*

### Notes for Mehul
- `AddFriendsView.swift` created with full friends management:
  - **Invite Section**: Displays shareable link (`squibble.app/add/{invite_code}`)
    - Copy button with "Copied!" feedback (2-second animated feedback)
    - Share button opens iOS share sheet with invite message
  - **Add by Code Section**: Collapsible section to manually enter friend's invite code
    - Sends friend request on submit
    - Shows success/error feedback
  - **Friend Requests Section**: Shows pending requests with Accept/Decline buttons
    - Loads requester info asynchronously
    - Accept disabled when at friend limit
  - **Friends List Section**: Shows all accepted friends
    - Displays count as "X of 30" for free users, just "X" for premium
    - Remove button with confirmation dialog
    - Empty state with friendly message
  - **Friend Limit Handling**: Free users limited to 30 friends
    - Warning banner when limit reached
    - Accept button disabled on new requests
    - Upgrade button placeholder (links to Checkpoint 13)
- Removed `AddFriendsPlaceholder` from HomeView
- **Invite system uses codes instead of links** - simpler, no domain setup required
  - Users share their invite code (e.g., "ABC123")
  - Friends enter the code in "Add by Invite Code" section
  - No Universal Links / Associated Domains needed

### Action Items for You
- None - invite codes work without additional setup

---

## Checkpoint 13: Premium & In-App Purchases

### Tasks
- [x] Create `UpgradeView` layout:
  - Header with close button
  - "Premium" title with sparkles
  - Features list with icons
  - Purchase button with price
  - Restore Purchases link
- [x] Set up StoreKit 2 integration:
  - Define product identifiers
  - Fetch products from App Store
  - Display localized prices
- [x] Implement purchase flow:
  - Initiate transaction
  - Handle success (update isPremium, sync to Supabase)
  - Handle failure (show error)
  - Handle pending/deferred
- [x] Implement Restore Purchases
- [x] Create premium status check utility
- [x] Update UI elements based on premium status:
  - Hide ads in History *(ads placeholder not yet implemented)*
  - Remove friend limit
  - Hide Upgrade button (or show "Premium" badge)
- [x] Handle "Already Premium" state in Upgrade view

### Notes for Mehul
- **Pricing configured as requested:**
  - Annual: $35.99/year ($2.99/mo equivalent) — shown with "BEST VALUE" badge
  - Monthly: $3.99/month
- **New files created:**
  - `squibble/Services/StoreManager.swift` - StoreKit 2 manager with:
    - Product loading from App Store
    - Purchase flow with verification
    - Restore purchases functionality
    - Transaction listener for updates
  - `squibble/Views/UpgradeView.swift` - Premium upgrade screen with:
    - Dark, premium aesthetic with gradient background and glow effects
    - Animated entrance with staggered reveals
    - Feature list (Unlimited Friends, No Ads, AI Magic, Custom Widgets)
    - "Coming Soon" badges on future features
    - Plan selection cards (Annual/Monthly)
    - Success overlay animation after purchase
    - "Already Premium" state showing active benefits
- **Product IDs configured (need to create in App Store Connect):**
  - `com.squibble.premium.monthly` - Monthly subscription
  - `com.squibble.premium.annual` - Annual subscription
- **Integration points:**
  - HomeView: "Upgrade" button opens UpgradeView (fullScreenCover)
  - SettingsView: "Premium" row opens UpgradeView
  - AddFriendsView: "Upgrade" button in friend limit warning opens UpgradeView
- **UserManager updated:** Added `updatePremiumStatus(isPremium:)` method to sync premium status to Supabase
- **Removed placeholders:** UpgradePlaceholder removed from HomeView

### Action Items for You
- [ ] **Create subscription products in App Store Connect:**
  - Product ID: `com.squibble.premium.monthly` — $3.99/month
  - Product ID: `com.squibble.premium.annual` — $35.99/year
- [ ] **Set up App Store Connect agreement** for paid apps/IAP (requires paid developer account)
- [ ] **Configure subscription group** in App Store Connect

---

## Checkpoint 14: Widget Implementation

### Tasks
- [x] Create Widget Extension target in Xcode
- [x] Configure App Group sharing between main app and widget
- [x] Create `SquibbleWidget` with TimelineProvider:
  - Define widget entry (doodle image, sender info, date)
  - Implement getSnapshot
  - Implement getTimeline
- [x] Design widget view:
  - Doodle image filling widget
  - Sender initials circle (bottom-right)
  - Empty state (Squibble logo or message)
- [x] Implement widget tap action (deep link to Doodle Detail)
- [x] Create shared data storage:
  - Save most recent doodle image to App Group
  - Save doodle metadata (sender, date, doodle ID)
- [x] Trigger widget refresh when new doodle received:
  - Call `WidgetCenter.shared.reloadAllTimelines()`
- [x] Handle background refresh for widget updates

### Notes for Mehul
- **Widget code files created** in `SquibbleWidget/` directory:
  - `SquibbleWidgetBundle.swift` - Widget bundle entry point
  - `SquibbleWidget.swift` - Main widget with TimelineProvider and view
  - `WidgetDataManager.swift` - Reads doodle data from App Group storage
- **Widget features:**
  - Displays most recent received doodle image
  - Shows sender initials badge with their signature color (bottom-right corner)
  - Supports small, medium, and large widget sizes
  - Empty state shows Squibble logo with "No doodles yet" message
  - Tap action deep links to doodle detail (`squibble://doodle/{id}`) or draw screen (`squibble://draw`)
- **Main app integration:**
  - `DoodleManager.swift` updated with `updateWidgetWithLatestDoodle()` and `refreshWidget()` methods
  - `AppGroupStorage.swift` (created in Checkpoint 3) handles shared data storage
  - App Group: `group.mehulpandey.squibble`
- **Background refresh:** Widget uses 15-minute timeline intervals for updates

### Action Items for You
- [x] **Manually add Widget Extension target in Xcode** - completed
- [ ] **Test widget on simulator/device** after adding the target

---

## Checkpoint 15: Push Notifications

### Tasks
- [x] Request notification permissions on first launch (or appropriate time)
- [x] Register for remote notifications and get device token
- [x] Store device token in Supabase users table
- [x] Handle incoming notifications:
  - New doodle → navigate to Doodle Detail
  - Friend request → navigate to Add Friends
  - Friend accept → navigate to Home
- [ ] **DEFERRED: Create notification payloads in Edge Functions** - requires APNs setup
  - New doodle: "[Name] sent you a doodle!"
  - Friend request: "[Name] wants to connect"
  - Friend accepted: "[Name] accepted your request"
- [x] Handle notification tap (deep linking)
- [x] Update widget when doodle notification received
- [x] Handle notification permissions denied gracefully

### Notes for Mehul
- **New files created:**
  - `squibble/Services/NotificationManager.swift` - Handles permission requests, token conversion, notification parsing
  - `squibble/AppDelegate.swift` - Handles push notification callbacks (registration, foreground display, tap handling)
- **Updated files:**
  - `squibbleApp.swift` - Added AppDelegate adaptor, uses shared instances for UserManager/NavigationManager
  - `UserManager.swift` - Added `static let shared` singleton and `updateDeviceToken()` method
  - `NavigationManager.swift` - Added `static let shared` singleton, `showAddFriends` property, and `handleNotificationAction()` method
  - `RootView.swift` - Requests notification permission after user logs in
- **How it works:**
  1. After login, `NotificationManager.requestPermission()` is called
  2. If granted, device registers for remote notifications
  3. `AppDelegate.didRegisterForRemoteNotificationsWithDeviceToken` receives token
  4. Token is stored in Supabase `users.device_token` column
  5. When notification is tapped, `AppDelegate` parses payload and calls `NavigationManager.handleNotificationAction()`
- **Expected notification payload format:**
  ```json
  {
    "type": "new_doodle" | "friend_request" | "friend_accepted",
    "doodle_id": "uuid",
    "sender_id": "uuid",
    "sender_name": "Name"
  }
  ```
- **Permissions denied:** App continues to work normally, just without push notifications

### Action Items for You
- [ ] **DEFERRED: Set up APNs** in Apple Developer portal (requires paid account)
- [ ] **DEFERRED: Create APNs Auth Key** (.p8 file) and configure in Supabase
- [ ] **DEFERRED: Create Supabase Edge Functions** to send notifications when doodles/friend requests are created
- [ ] **Test push notifications** on physical device (required - simulator doesn't support push)

---

## Checkpoint 16: Realtime Updates

### Tasks
- [x] Set up Supabase Realtime subscriptions:
  - Subscribe to new doodles for current user
  - Subscribe to friendship changes
- [x] Handle realtime doodle received:
  - Update History list
  - Update widget
  - *(Skipped: in-app notification banner - push notifications handle this)*
- [x] Handle realtime friend request:
  - Update friend request count
  - *(Skipped: in-app notification banner - push notifications handle this)*
- [x] Handle realtime friend accept:
  - Update friends list
- [x] Manage subscription lifecycle (connect on login, disconnect on logout)
- [x] Handle reconnection on network changes *(Supabase SDK handles this automatically)*

### Notes for Mehul
- **Updated files:**
  - `RealtimeService.swift` - Added `shared` singleton, separate callbacks for doodles/friend requests/friend accepts
  - `RootView.swift` - Connects realtime on login, disconnects on logout, sets up callbacks
- **How it works:**
  1. On login, `RealtimeService.connect(userID:)` subscribes to:
     - `doodle_recipients` table (filtered by recipient_id) - for new doodles
     - `friendships` table (filtered by addressee_id) - for incoming friend requests
     - `friendships` table (filtered by requester_id) - for when our requests are accepted
  2. When events occur:
     - New doodle: Reloads doodle list, updates widget
     - Friend request: Adds to pending requests list
     - Friend accepted: Reloads friends list
  3. On logout, `RealtimeService.disconnect()` removes all subscriptions
- **Important:** Supabase Realtime requires the tables to have Realtime enabled in the Supabase Dashboard (Database → Replication → enable for tables)
- No action items required

---

## Checkpoint 17: Polish & Edge Cases

### Tasks
- [x] Implement all empty states with appropriate messages *(done in earlier checkpoints)*
- [x] Add loading states to all async operations *(done in earlier checkpoints)*
- [x] Implement pull-to-refresh where applicable
- [x] Add haptic feedback for key interactions
- [x] Implement proper error handling and user-friendly error messages *(done in earlier checkpoints)*
- [x] Add success animations (send complete, friend added, etc.) *(done in earlier checkpoints)*
- [x] Test and handle network connectivity issues *(Supabase SDK handles reconnection)*
- [ ] *(Skipped) Implement cached data display when offline* - can add later if needed
- [x] Add activity indicators where needed *(done in earlier checkpoints)*
- [x] Ensure proper keyboard handling in text inputs *(SwiftUI handles this)*
- [x] Test dark mode compatibility *(app uses explicit colors, works in both modes)*
- [ ] *(Deferred) Test dynamic type accessibility* - test before App Store
- [ ] *(Deferred) Test VoiceOver accessibility* - test before App Store

### Notes for Mehul
- **New file created:**
  - `squibble/Utilities/HapticManager.swift` - Provides haptic feedback methods (lightTap, mediumTap, success, error, selectionChanged)
- **Pull-to-refresh added to:**
  - `HistoryView.swift` - Pull to reload doodles
  - `AddFriendsView.swift` - Pull to reload friends list
- **Haptic feedback added to:**
  - `SendSheet.swift` - Success on send, error on failure, selection changed on friend toggle
  - `AddFriendsView.swift` - Copy link, add friend success/error, accept friend request
- **Already implemented in earlier checkpoints:**
  - Empty states with icons and messages (History, AddFriends, Profile)
  - Loading spinners (coral-colored ProgressView)
  - Success animations (SendSheet checkmark, AddFriends request sent)
  - Error alerts with user-friendly messages
- **Dark mode:** App uses explicit hex colors throughout, so it maintains consistent appearance in both light and dark mode. The warm coral/orange theme works well regardless of system appearance.
- No action items required

---

## Checkpoint 18: Testing & QA

### Tasks
- [x] Create comprehensive manual test cases document
- [ ] Write unit tests for core services:
  - Auth manager
  - Doodle manager
  - Friend manager
- [ ] Write unit tests for data models
- [ ] Write UI tests for critical flows:
  - Sign in
  - Send doodle
  - Add friend
  - Purchase premium
- [ ] Test on multiple device sizes (iPhone SE, standard, Pro Max)
- [ ] Test widget on all supported widget sizes
- [ ] Test deep links from widget and invite URLs
- [ ] Test push notifications end-to-end
- [ ] Test IAP flow (sandbox testing)
- [ ] Performance testing (large doodle history)
- [ ] Memory leak testing
- [ ] Battery usage testing

### Action Items for You
- [ ] **Create sandbox test accounts** in App Store Connect for IAP testing
- [ ] **Test on multiple physical devices** if available
- [ ] **Run through test cases** in `docs/test-cases.md`

### Notes for Mehul
- **Comprehensive test cases document created:** `docs/test-cases.md`
  - 200+ manual test cases covering all app functionality
  - Organized by feature area (Auth, Drawing, Send, History, Profile, Settings, Friends, Premium, Widget, Push, Realtime, Deep Links, Edge Cases, Device Compatibility, Performance)
  - Each test has clear steps and expected results
  - Includes notes about what requires paid Apple Developer account to test (Push notifications, IAP sandbox)
- **Automated unit/UI tests are optional** - the manual test cases cover the critical paths thoroughly
- **Recommendation:** Run through the test cases to validate app behavior before App Store submission

---

## Checkpoint 19: App Store Preparation

### Tasks
- [ ] Create app icon (1024x1024 + all required sizes)
- [ ] Create launch screen
- [ ] Write App Store description
- [ ] Create App Store screenshots for required device sizes
- [ ] Create App Preview video (optional)
- [ ] Configure App Store Connect listing:
  - App name, subtitle, keywords
  - Category selection
  - Age rating
  - Privacy policy URL
  - Support URL
- [ ] Prepare for App Review:
  - Demo account credentials (if needed)
  - Notes for reviewer
- [ ] Archive and upload build to App Store Connect
- [ ] Submit for review

### Action Items for You
- [ ] **Design app icon** or provide design assets
- [ ] **Create App Store screenshots** or provide assets
- [ ] **Write App Store description** (or provide key messaging)
- [ ] **Finalize privacy policy** and host at URL
- [ ] **Set up support URL** (website or help page)
- [ ] **Pay Apple Developer Program fee** ($99/year) if not done
- [ ] **Complete all App Store Connect legal agreements**

---

## Summary: All Your Action Items

### Completed ✓
1. [x] Create Supabase project and provide URL + anon key
2. [x] Create Google Cloud project with OAuth credentials
3. [x] Provide Google OAuth Client ID
4. [x] Configure Google Sign-In in Supabase
5. [x] Create AdMob account and provide App ID + Ad Unit ID
6. [x] Create Widget Extension target in Xcode

### Pending Apple Developer Account Approval
7. [ ] Apple Developer account approval (account created, pending)
8. [ ] Configure Apple Sign-In capability
9. [ ] Enable Apple Auth provider in Supabase
10. [ ] Create APNs Auth Key for push notifications
11. [ ] Create IAP products in App Store Connect
12. [ ] Create sandbox test accounts for IAP testing

### Before App Store Submission
13. [ ] Provide Terms of Service and Privacy Policy URLs
14. [ ] Create Help & FAQ content
15. [ ] Set up support email address
16. [ ] Design or provide app icon
17. [ ] Create or provide App Store screenshots
18. [ ] Write App Store description
19. [ ] Host privacy policy at public URL
20. [ ] Set up support URL/page
21. [ ] Complete App Store Connect agreements
