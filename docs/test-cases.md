# Squibble App - Comprehensive Test Cases

This document contains all manual test cases to validate the Squibble app before release.

---

## 0. Onboarding Flow (First-Time Users)

### Mehul's Testing Notes:
[x] after account creation, home screen is visible for a brief moment before onboarding screen appears. onboarding screen should appear right away
[x] first onboarding screen:
    [x] "Send doodles to friends. They appear..." gets cut off on iphone X screen. Shorten this to just "Send doodles to friends."
    [x] it still has the temp logo - replace with actual logo
    [x] replace "See doodles on their widget" with "They see doodles on their widget"
[x] add a page explaining how to install the widget on your home screen
[x] from the notification screen (page 2), don't auto-progress to the next page after completion. have the user actually click continue.

### Mehul's Retesting Notes:
[x] all tests passed

### 0.1 Onboarding Display
- [x] First-time user signs up → Onboarding appears after authentication (no home screen flash)
- [x] Page indicators show 4 dots at top
- [x] First dot is active (filled coral color)
- [x] "Skip" button visible at bottom

### 0.2 Welcome Screen (Page 1)
- [x] Logo image (Logo asset) animates in on appearance
- [x] "Welcome to Squibble!" title displayed
- [x] Description text: "Send doodles to friends."
- [x] Three feature rows visible (Draw, Send, "They see doodles on their widget")
- [x] "Get Started" button at bottom
- [x] Tap "Get Started" → Goes to page 2
- [x] Swipe left → Goes to page 2
- [x] Tap "Skip" → Goes to page 2

### 0.3 Notification Screen (Page 2)
- [x] Bell icon displays with wiggle animation
- [x] "Stay in the Loop" title
- [x] Three benefit checkmarks visible
- [x] "Enable Notifications" button
- [x] Tap "Enable Notifications" → iOS permission prompt appears
- [x] Allow → Bell changes to badge icon, title changes to "You're All Set!", "Continue" button shown
- [x] User must tap "Continue" to advance (no auto-advance)
- [x] Deny → Title changes to "No Worries", shows "Continue" button
- [x] Tap "Skip" → Goes to page 3 without requesting permission

### 0.4 Widget Installation Screen (Page 3) - NEW
- [x] Widget icon (square grid) displays
- [x] "Add the Widget" title
- [x] "See doodles right on your home screen!" subtitle
- [x] Four numbered steps shown (Long press, Tap +, Search Squibble, Add widget)
- [x] "Continue" button at bottom
- [x] Tap "Continue" → Goes to page 4
- [x] Tap "Skip" → Goes to page 4

### 0.5 Invite Friends Screen (Page 4)
- [x] Friends icon displays
- [x] "Invite Your Friends" title
- [x] Invite code card visible with user's 6-character code
- [x] Copy button → Copies code, shows "Copied!" with checkmark
- [x] Share button → iOS share sheet opens
- [x] "Start Doodling" button at bottom
- [x] No "Skip" button on last page
- [x] Tap "Start Doodling" → Onboarding dismisses, MainTabView appears

### 0.6 Onboarding Completion
- [x] Complete onboarding → "hasCompletedOnboarding" saved to UserDefaults
- [x] Close and reopen app → Onboarding does NOT appear again
- [x] Sign out and sign in with same account → Onboarding does NOT appear
- [x] Sign in with new account (never completed onboarding) → Onboarding appears

### 0.7 Onboarding Navigation
- [x] Swipe gestures work to navigate between all 4 pages
- [x] Swipe right on page 1 → No action (can't go before first page)
- [x] Page indicators update correctly when swiping
- [x] Smooth animations between pages

---

## 1. Authentication Flow

### Mehul's Testing Notes:
[x] the app allowed me to create an account with an invalid email. no validation error appeared
[x] when clicking on the password reset link in email, it takes me to a safari page that redirects me to the squibble app (whichever page I was on last). the reset password email sends successfully, there is no way for me to reset my password through the link
[x] when clicking on "delete account", warning message appears correctly but clicking on delete from there doesn't do anything, just removes the warning. account still exists. it should delete the account, sign the user out, and return them to login

### Mehul's Retesting Notes:
[x] app still lets me create account with an email that doesn't exist. I tested it with a valid email with random characters appended to the end. is it complex to validate if an email exists before letting the user create the account? if it's too complex, don't worry about it as this is not essential
    - SKIPPED: Validating email existence requires sending verification emails or using paid verification services. Too complex for non-essential feature.
[x] when deleting account, record gets deleted from supabase table "users" but not from the user list when navigating to authentication tab. it still lets me login with a deleted account.
[x] when clicking on forgot password, password reset link in email still only routes to a blank safari page, which reroutes back to the app. it just opens the last opened page in the app. there is no way to reset the password

### 1.1 Email Sign Up (New User)
- [x] Open app → See splash screen briefly → Login screen appears
- [x] Tap "Continue with Email" → Email auth sheet opens
- [x] Toggle to "Sign Up" mode
- [x] Enter invalid email format → Should show validation error
- [x] Enter password less than 6 characters → Should show validation error
- [x] Enter mismatched password confirmation → Should show "Passwords don't match" error
- [x] Enter valid email, password (6+ chars), matching confirmation, display name
- [x] Tap "Create Account" → Loading spinner appears
- [x] On success → Navigates to main app (Home tab)
- [x] User profile created with random color and invite code

### 1.2 Email Sign In (Existing User)
- [x] Open app → Login screen
- [x] Tap "Continue with Email" → Email auth sheet opens
- [x] Ensure "Sign In" mode is selected
- [x] Enter wrong email/password → Error alert appears
- [x] Enter correct email/password → Loading spinner
- [x] On success → Navigates to main app
- [x] User data loads (profile, friends, doodles)

### 1.3 Password Reset
- [x] On Email auth sheet → Tap "Forgot Password?"
- [x] Password reset view appears
- [x] Enter email → Tap "Send Reset Link"
- [x] Success message appears
- [x] (Check email for reset link - requires Supabase email setup)

### 1.4 Auto-Login (Session Persistence)
- [x] Sign in successfully → Close app completely
- [x] Reopen app → Should auto-login without showing login screen
- [x] User data should load automatically

### 1.5 Sign Out
- [x] Go to Profile → Settings → Tap "Sign Out"
- [x] Confirmation alert appears
- [x] Tap "Sign Out" → Returns to Login screen
- [x] Reopen app → Should show Login screen (not auto-login)

### 1.6 Delete Account
- [x] Go to Profile → Settings → Tap "Delete Account"
- [x] Warning confirmation appears
- [x] Tap "Delete" → Signs out and returns to Login

---

## 2. Drawing Canvas (Home Screen)

### Mehul's Testing Notes:
[x] do pen and eraser buttons need some visual indicator that they are clickable? it might be hard for a user to know how to change the brush size. you use your best judgment and tell me if this is needed and implement this if so. if not needed, let me know
[x] clear button (trash icon) should not reset the background color, only the drawing. currently it resets it to white
[x] make the default brush size bigger (medium size)
[x] premium upload image feature:
    [x] I uploaded a 9:16 image which is taller than the 1:1 drawing canvas ratio, but I couldn't move it up or down from the starting position. it always centers the image vertically. when I try to move it up/down, it snaps back into the centered position. it should be able to be moved up/down even if not zoomed in
    [x] when trying to drag an image off-screen, currently the image just sharply snaps back into position (no transition). make the image smoothly snap back into place so it doesn't look so abrupt
    [x] currently, zoom requires 2 fingers and dragging requires 1 finger. this is a problem because the user can never draw, as this is the same 1 finger gesture as dragging an image. they will always be stuck on dragging. zoom and dragging should both require 2 fingers and they should be able to happen in the same gesture. currently you can only zoom or drag at the same time, which is clunky

### Mehul's Retesting Notes:
[x] 2 finger drag/zoom with 1 finger draw works now, but there's a weird bug that only happens sometimes. occasionally when I drag with 2 fingers it starts to draw a line instead. next time I click on the screen it completes the drawn line and only then can I undo it. is there a minor code change to fix this? if not, don't worry about it. it's not a huge deal so I want to avoid major code changes to fix this

### 2.1 Basic Drawing
- [x] Home tab shows drawing canvas
- [x] Touch and drag on canvas → Draws smooth lines
- [x] Lines should have natural bezier curve interpolation
- [x] Default pen color is black
- [x] Default pen width is medium

### 2.2 Color Selection
- [x] Tap color dot (top-right of canvas) → Color picker popover appears
- [x] 10 preset colors available (black, red, orange, yellow, green, blue, purple, pink, brown, white)
- [x] Tap a color → Popover closes, color dot updates
- [x] Draw → New strokes use selected color

### 2.3 Brush Size
- [x] Pen tool is selected by default (highlighted in toolbar)
- [x] Tap Pen tool again → Brush size slider appears
- [x] Drag slider → Size preview updates
- [x] Draw → Stroke width matches selected size

### 2.4 Eraser Tool
- [x] Tap Eraser in toolbar → Eraser becomes highlighted
- [x] Draw on canvas → Erases existing strokes (draws white)
- [x] Tap Eraser again → Brush size slider for eraser appears
- [x] Tap Pen → Switches back to drawing mode

### 2.5 Undo/Redo
- [x] Draw several strokes
- [x] Tap Undo (top-left) → Last stroke removed
- [x] Tap Undo multiple times → Removes strokes in reverse order
- [x] Tap Redo → Restores undone strokes
- [x] Draw new stroke after undo → Clears redo stack

### 2.6 Send Button State
- [x] Empty canvas → Send button is gray/disabled
- [x] Draw something → Send button becomes active (coral gradient)
- [x] Undo all strokes → Send button becomes gray again

### 2.7 Canvas Background Color
- [x] Tap "..." (More Options) button → More Options sheet appears
- [x] Tap "Background Color" → Color picker opens
- [x] Select a color → Canvas background changes to selected color
- [x] Draw on colored background → Strokes visible
- [x] Send doodle → Background color included in exported image
- [x] Tap "Abort" → Background color resets to white

### 2.8 Upload Image (Premium Feature)
- [x] As free user: Tap "..." → Tap "Upload Image" → Upgrade view opens
- [x] As premium user: Tap "..." → Tap "Upload Image" → Photo picker opens
- [x] Select a photo → Photo appears as canvas background
- [x] "Pinch & drag to adjust image" hint appears at bottom of canvas
- [x] Pinch to zoom in → Image scales up (max 3x)
- [x] Pinch to zoom out → Image scales down (min 1x, can't go smaller)
- [x] Drag image → Image moves/pans within canvas bounds
- [x] Image stays within canvas boundaries (can't pan completely off screen)
- [x] Start drawing → Hint disappears, image locked in place
- [x] Draw on top of photo → Strokes overlay the image
- [x] Image adjustments persist while drawing more strokes
- [x] Send doodle → Image with adjustments and strokes included in exported PNG
- [x] Tap trash button → Background image and adjustments reset

### 2.9 Canvas Control Buttons
- [x] Four circular buttons in bottom row: Undo, Redo, Trash, More (...)
- [x] All four buttons are same size (40x40 circular)
- [x] Undo button disabled when no strokes to undo
- [x] Redo button disabled when no strokes to redo
- [x] Trash button disabled when canvas is empty
- [x] More (...) button has coral/orange border for prominence
- [x] Tap "..." → More Options sheet opens
- [x] Sheet shows 3 options: Background Color, Upload Image, Animate with AI
- [x] "Upload Image" shows "PRO" badge for free users
- [x] "Animate with AI" shows "SOON" badge and is disabled

### 2.10 Canvas State Persistence
- [x] Draw something on canvas
- [x] Switch to History tab → Switch back to Home tab
- [x] Drawing persists (not cleared)
- [x] Change background color → Switch tabs → Switch back
- [x] Background color persists
- [x] Upload image → Switch tabs → Switch back
- [x] Background image persists

---

## 3. Send Doodle Flow

### Mehul's Testing Notes:
[x] friend invite text only includes the invite code right now, but it should also include a link to the app. I think the invite text sent via onboarding does include the app link, but not from the add friend page. make them both consistent with the app link
[x] when I have the app open in iphone A, and I send a friend request to iphone A from iphone B, the app crashes in iphone A. conversely, when I re-open the app from iphone A and accept the friend request, the app crashes in iphone B
[x] when I get a friend request, there is no visual indicator from the home screen that I have a request. I have to click into the add friends page to know. can you add a little visual indicator (like a hovering number or something) on the add friend icon from the home page so it's clear how many unresolved friend requests you have
[x] when trying to send a doodle to a friend, currently they show up with a colored circle with their initials next to their name. the circle should instead be their profile picture. it should be outlined in their chosen color, similar to how it looks in the profile screen. if the friend has no profile picture, then it should be a gray circle with their initials and a colored outline, exactly as it is currently in the profile screen
[x] when sending a doodle to a friend, getting an error pop-up saying "new row violates row-level security policy". send does not go through

### Mehul's Retesting Notes:
[x] when sending a doodle to a friend, still getting the error "new row violates row-level security policy". send does not go through

### 3.1 Send Sheet (No Friends)
- [x] Draw something → Tap Send button
- [x] Send sheet appears as bottom sheet
- [x] If no friends → Shows empty state with "No Friends Yet" message
- [x] "Add Friends" button visible
- [x] Close button (X) dismisses sheet

### 3.2 Send Sheet (With Friends)
- [x] Have at least one friend added
- [x] Draw and tap Send → Send sheet shows friend list
- [x] Each friend shows avatar (initials + color) and name
- [x] Checkbox on right side of each row

### 3.3 Friend Selection
- [x] Tap a friend → Checkbox fills with gradient checkmark
- [x] Tap again → Deselects (checkbox empties)
- [x] Haptic feedback on each selection
- [x] "Select All" toggle at top
- [x] Tap "Select All" → All friends selected
- [x] Tap again → All deselected

### 3.4 Send Button Dynamic Text
- [x] No friends selected → "Select friends to send" (disabled)
- [x] 1 friend selected → "Send to 1 friend"
- [x] 3 friends selected → "Send to 3 friends"

### 3.5 Sending Doodle
- [x] Select friend(s) → Tap send button
- [x] Loading spinner appears on button
- [x] On success → Success overlay with checkmark animation
- [x] Haptic success feedback
- [x] After ~1.5 seconds → Sheet dismisses
- [x] Canvas is cleared automatically
- [x] Doodle appears in History (Sent filter)

### 3.6 Send Error Handling
- [x] (Simulate network error or disconnect wifi)
- [x] Try to send → Error alert appears
- [x] Haptic error feedback
- [x] Can dismiss and retry

---

## 4. History Screen

### Mehul's Testing Notes:
[x] when person filter is active (i.e. user has clicked on person filter and selected people), person icon gets highlighted and an additional pill is added to the row with the person name and an X. for simplicity and to keep all filters in one line, only highlight the person icon but don't add the additional pill with the person name - that is redundant with the highlighted pill
[x] person filter sheet should also show people's profile pictures, outlined with their chosen color, not just initials in a circle

### Mehul's Retesting Notes:
[x] when clicking on "all" filter, should reset filter by person 
[x] when sending image with doodle, doodle and image are not lined up correctly in BOTH history page and widget. make sure they are always lined up correctly to match what the user drew
[x] when going to image detail page by clicking on doodle in history page, when scrolling left and right through doodles, animation is a little awkward. make it smoothly transition from one doodle to the next
[x] in history page, change the initials overlay on each doodle to be the same as how it looks in the widget (just a colored circle with initials, no gray outline, no additional icon for sent doodles, slight shadow)
[x] when in doodle detail page, have it so you can exit the detail page and go back to history by swiping down on the page
[x] in history page when pulling page down to refresh, animation is a little choppy. make this smoother
[x] in doodle detail page, remove circle with initials. put name and time received on the same line and make the fonts the same size. keep the name in white font and the time in gray font as it is now.

### Mehul's Retesting Notes 2:
[x] when person filter is active, "all" filter button should not be highlighted
[x] when sending a doodle with an image from my test iphone X to my iphone 14, the doodle and image are lined up correctly. however, when doing it the other way around, they are not lined up. make sure they are lined up regardless of source/target iphone type
[x] when I'm in the doodle detail page and I try to scroll left or right through doodles, the animation is still awkward. for example, when I drag a doodle to the left, it snaps back into the original position first, and THEN fades to the next doodle. instead, it should just slide smoothly into the next doodle. 
[x] when in doodle detail page, I requested the ability to exit the page and go back to history by swiping down. currently this works when you swipe anywhere on the page except the actual doodle area. make it so it works in the doodle area too. also, there's an awkward black screen that shows up momentarily after swiping down and before the history page shows up. remove this so that it goes immediately to the history screen when swiping down
[x] in history page when pulling page down to refresh, it's still a little choppy. make it so it only refreshes after the user lets go

### Mehul's Retesting Notes 3:
[x] when I'm in the doodle detail page and I try to scroll left or right from doodle A to doodle B, currently doodle A slides over and then doodle B just appears abruptly. in one sliding gesture, doodle A should slide out and doodle B should slide in at the same time, right next to each other. the subtext (name, relative time) should slide in or out with the doodle above it. for sent doodles, keep the same 2 buttons (delete, reply) as received doodles but gray out the reply button.
[x] when in doodle detail page, I requested the ability to be able to slide down to exit the page and go back to history. I should be able to do this from ALL points on the page, including the doodle and everything around it. currently it's only possible from the doodle area

### 4.1 History Layout
- [x] Tap History tab → Shows History screen
- [x] Header says "History"
- [x] Filter pills below header (All, Sent, Received)
- [x] Person filter button (person icon)
- [x] 3-column grid of doodle thumbnails

### 4.2 Filter Pills
- [x] "All" selected by default (gradient background)
- [x] Tap "Sent" → Shows only sent doodles
- [x] Tap "Received" → Shows only received doodles
- [x] Tap "All" → Shows all doodles
- [x] Active filter has gradient, inactive has gray background

### 4.3 Person Filter
- [x] Tap person icon → Person filter sheet appears
- [x] Lists all friends with avatars
- [x] Tap a friend → Sheet closes, filter chip appears
- [x] Only doodles from/to that person shown
- [x] Tap X on filter chip → Clears person filter
- [x] "Clear Filter" option in sheet when filter active

### 4.4 Doodle Grid Items
- [x] Each doodle shows thumbnail image
- [x] Sender badge in bottom-left (initials + color)
- [x] Sent doodles show paperplane icon next to badge
- [x] Images load with placeholder/spinner

### 4.5 Pull-to-Refresh
- [x] Pull down on grid → Refresh indicator appears
- [x] Release → Doodles reload from server
- [x] New doodles appear if any

### 4.6 Empty States
- [x] No doodles at all → "No Doodles Yet" with clock icon
- [x] Filters yield no results → "No Matches" with magnifying glass

### 4.7 Doodle Detail
- [x] Tap a doodle thumbnail → Full-screen detail view opens
- [x] Shows large doodle image
- [x] Sender info with avatar, name, relative date ("2 hours ago")
- [x] "You" label for sent doodles
- [x] Page indicator "X of Y" in top bar

### 4.8 Doodle Detail Navigation
- [x] Swipe left → Next doodle
- [x] Swipe right → Previous doodle
- [x] Respects current filter when navigating
- [x] Can't swipe past first/last doodle

### 4.9 Doodle Detail Actions
- [x] Share button → iOS share sheet with doodle image
- [x] Reply button (received doodles only) → Goes to Home, pre-selects sender in Send sheet
- [x] Delete button → Confirmation alert
- [x] Delete sent doodle → "Delete for everyone" message
- [x] Delete received doodle → "Remove from your history" message
- [x] After delete → Returns to History, doodle removed

---

## 5. Profile Screen

### Mehul's Testing Notes:
[x] all tests passed

### Mehul's Retesting Notes:
[x] after sending doodle(s), "doodles sent" and "day streak" counters are not updating in profile page. activity calendar is not updating either

### 5.1 Profile Layout
- [x] Tap Profile tab → Shows Profile screen
- [x] Settings gear button (top-right)
- [x] Profile avatar (tappable)
- [x] Display name (tappable)
- [x] Stats row: Doodles Sent, Streak, Friends

### 5.2 Profile Avatar
- [x] Default: Gray circle with initials, signature color outline
- [x] Tap avatar → Photo picker opens
- [x] Select photo → Uploads to Supabase
- [x] Avatar updates with new photo
- [x] Photo has signature color outline

### 5.3 Edit Name
- [x] Tap display name → Alert with text field appears
- [x] Enter new name → Tap Save
- [x] Name updates in profile
- [x] Name updates in Supabase

### 5.4 Stats Display
- [x] Doodles Sent shows correct count
- [x] Streak shows with 🔥 emoji (if > 0)
- [x] Friends count matches friend list

### 5.5 Activity Calendar
- [x] Monthly calendar grid visible
- [x] Days with doodles sent highlighted (coral gradient)
- [x] More doodles = more opaque highlight
- [x] Today has coral ring outline
- [x] Navigate months with < > arrows
- [x] Can't go past current month

---

## 6. Settings Screen

### Mehul's Testing Notes:
[x] membership option in settings always says "Premium" regardless of whether on free or premium account. even though the badge changes from "upgrade" to "active", this is confusing for the user. it should say "Free" if on the free plan and "Premium" if premium. badges can remain unchanged
[x] is there an easy way to make the whole settings button clickable? for example, if I want to click on display name from settings, it only responds to me clicking on the text/icon/arrow, not when I click on the empty space in the button between the text and arrow. this is slightly frustrating for the user as the clickable area is somewhat precise

### Mehul's Retesting Notes:
[x] all tests passed

### 6.1 Settings Access
- [x] Profile → Tap gear icon → Settings screen opens
- [x] Navigation title "Settings"
- [x] Back button returns to Profile

### 6.2 Account Section
- [x] Edit Display Name → Alert with current name → Can change
- [x] Edit Profile Picture → Photo picker → Can change
- [x] Change My Color → Color picker screen → 12 color options
- [x] Select color → Preview updates → Save updates signature color

### 6.3 Preferences Section
- [x] Notifications row → Tap opens iOS Settings app

### 6.4 Membership Section
- [x] Premium Status row
- [x] If free user → Shows "Upgrade" badge → Tap opens Upgrade view
- [x] If premium → Shows "Active" badge with checkmark

### 6.5 Support Section
- [x] Help & FAQ row (placeholder - needs URL)
- [x] Contact Us → Opens email composer with mpan.apps@gmail.com

### 6.6 Destructive Section
- [x] Sign Out → Confirmation → Signs out
- [x] Delete Account → Warning confirmation → Signs out

### 6.7 App Version
- [x] "Squibble v1.0.0" shown at bottom

---

## 7. Add Friends Screen

### Mehul's Testing Notes:
[x] friend requests section has the same profile picture issue as before where it shows a solid colored circle with initials instead of a profile picture in a circle outlined in their color. "your friends" section below does it correctly. fix this so it's consistent.

### Mehul's Retesting Notes:
[x] all tests passed

### 7.1 Access Add Friends
- [x] Home → Tap "Add Friends" button → Add Friends sheet opens
- [x] Header says "Friends" with close button (X)

### 7.2 Invite Section
- [x] Shows unique invite link (squibble.app/add/{code})
- [x] Copy button → Copies link, shows "Copied!" feedback
- [x] Haptic feedback on copy
- [x] Share button → iOS share sheet

### 7.3 Add by Code Section
- [x] Collapsible section (tap to expand)
- [x] Text field for entering invite code
- [x] Add button (disabled when empty)
- [x] Enter invalid code → Error message "No user found with that code"
- [x] Enter valid code → Success message "Friend request sent!"
- [x] Haptic feedback on success/error

### 7.4 Friend Requests Section
- [x] Only shows if pending requests exist
- [x] Badge shows request count
- [x] Each request shows requester avatar, name, "Wants to be friends"
- [x] Accept button (green checkmark)
- [x] Decline button (gray X)
- [x] Accept → Friend moves to friends list, haptic success
- [x] Decline → Request disappears

### 7.5 Friends List Section
- [x] Shows "Your Friends" header
- [x] Count shows "X of 30" for free users, just "X" for premium
- [x] Each friend shows avatar, name, remove button (-)
- [x] Remove button → Confirmation alert → Friend removed
- [x] Empty state if no friends: "No friends yet. Share your link to connect!"

### 7.6 Friend Limit (Free Users)
- [x] At 30 friends → Warning banner appears
- [x] "Upgrade" button in warning → Opens Upgrade view
- [x] Accept button disabled on new requests when at limit
- [x] Add by code disabled when at limit

### 7.7 Pull-to-Refresh
- [x] Pull down → Refreshes friend list and requests

---

## 8. Premium & In-App Purchases

### Mehul's Testing Notes:
[x] when upgrading to premium, when "Welcome to Premium" pop-up appears, it looks a little awkward because the pop-up background is fully transparent so there's overlapping text/icons etc with the actual app behind it (screenshot). can you make the pop-up have a more opaque background while keeping it sleek and consistent with the app? 
[x] once account is premium, the "level up" button on the homepage should change to something else to indicate you have already bought premium

### Mehul's Retesting Notes:
[x] undo the change you made to switch out the "level up" button to a "pro" badge in the home page when a user is premium. just keep the old button but change the wording from "Level Up" if free to "Premium" if premium. it should still be a clickable button
[x] there is no way for a user to downgrade from premium to free in the app. once premium they are stuck. there should be a way to change this back from settings and/or the upgrade to premium page

### 8.1 Upgrade View Access
- [x] Home → "Upgrade" button → Opens Upgrade view
- [x] Settings → Premium Status → Opens Upgrade view
- [x] Add Friends → Upgrade button in limit warning → Opens Upgrade view

### 8.2 Upgrade View Layout
- [x] Dark premium aesthetic
- [x] "PRO" badge with crown
- [x] "Unlock the Full Experience" title
- [x] Feature list (Unlimited Friends, No Ads, Upload Image, AI Animation)
- [x] "SOON" badge on AI Animation feature only

### 8.3 Plan Selection
- [x] Two plan cards: Annual and Monthly
- [x] Annual shows "$2.99/month" with "Billed $35.99/year" subtitle
- [x] Annual has "BEST VALUE" badge
- [x] Monthly shows "$3.99/month"
- [x] Tap to select → Card highlights with coral border

### 8.4 Purchase Flow
- [x] Select plan → Tap "Continue"
- [x] (In sandbox/TestFlight) → iOS purchase sheet appears
- [x] Complete purchase → Success overlay with checkmark
- [x] View changes to "Already Premium" state

### 8.5 Restore Purchases
- [x] "Restore Purchases" link at bottom
- [x] Tap → Loading state
- [x] If previous purchase found → Updates to premium
- [x] If none found → Error message "No purchases to restore"

### 8.6 Already Premium State
- [x] Open Upgrade view when premium → Shows benefits list with checkmarks
- [x] "You're all set!" message
- [x] Close button dismisses

---

## 9. Widget

### Mehul's Testing Notes:
[x] in the empty widget state, the scribble icon is a slightly different orange than the rest of the app and the icon. adjust this so it matches the orange in the app's color scheme
[ ] received doodles are updating very inconsistently in widget. sometimes it updates right away when a new doodle is received and sometimes it doesn't update at all. when deleting most recent received doodle from history, it should also remove it from the widget and replace it with the next most recent doodle received
[x] when clicking on widget, it should open the doodle detail page for that doodle in the app. currently it just opens the last opened page in the app

### 9.1 Add Widget
- [x] Long press home screen → Edit mode
- [x] Tap + → Search "Squibble"
- [x] Squibble widget appears
- [x] Available in small, medium, large sizes
- [x] Add widget to home screen

### 9.2 Empty Widget State
- [x] No doodles received → Widget shows scribble icon
- [x] "No doodles yet" text

### 9.3 Widget with Doodle
- [x] Receive a doodle in app
- [x] Widget updates to show doodle image
- [x] Sender initials badge in bottom-right corner
- [x] Badge shows sender's signature color

### 9.4 Widget Tap Action
- [x] Tap widget with doodle → Opens app to doodle detail
- [x] Tap empty widget → Opens app to Home (draw) screen

---

## 10. Push Notifications (Requires APNs Setup)

**IMPORTANT: Push notifications MUST be tested on a physical iOS device.** The iOS Simulator cannot receive push notifications - it generates fake device tokens that APNs always rejects with "BadDeviceToken" error.

### Mehul's Testing Notes:
- [x] All push notification tests passed on physical devices

### 10.1 Permission Request
- [x] First login → Notification permission prompt appears
- [x] Allow → App registered for notifications
- [x] Device token saved to Supabase

### 10.2 Notification Types (When Backend Configured)
- [x] Receive doodle → "[Name] sent you a doodle!" notification
- [x] Friend request → "[Name] wants to connect" notification
- [x] Friend accepted → "[Name] accepted your request" notification

### 10.3 Notification Tap Actions
- [x] Tap doodle notification → Opens doodle detail
- [x] Tap friend request notification → Opens Add Friends
- [x] Tap friend accepted notification → Opens Home

### 10.4 Foreground Notifications
- [x] App open → Notification still shows as banner

---

## 11. Realtime Updates

### Mehul's Testing Notes:
[x] all tests passed

### 11.1 Realtime Connection
- [x] Login → Console shows "Realtime: Connected for user {id}"
- [x] Logout → Console shows "Realtime: Disconnected"

### 11.2 Realtime Doodle Received
- [x] Have two test accounts (A and B) logged in on different devices/simulators
- [x] A sends doodle to B
- [x] B's History updates automatically (without refresh)
- [x] B's widget updates

### 11.3 Realtime Friend Request
- [x] A sends friend request to B
- [x] B's pending requests count updates automatically
- [x] B sees new request in Add Friends

### 11.4 Realtime Friend Accept
- [x] B accepts A's friend request
- [x] A's friends list updates automatically

---

## 12. Deep Links

### Mehul's Testing Notes:
[x] all tests skipped for now. will revisit post MVP

### 12.1 Doodle Deep Link
- [x] URL: squibble://doodle/{doodle-id}
- [x] Opens app → Goes to History → Opens doodle detail

### 12.2 Draw Deep Link
- [x] URL: squibble://draw
- [x] Opens app → Goes to Home tab

### 12.3 Invite Deep Link (When Domain Configured)
- [x] URL: squibble://invite?code={code}
- [x] Opens app → Goes to Profile
- [x] (Full flow requires domain setup)

---

## 13. Edge Cases & Error Handling

### Mehul's Testing Notes:
[x] all tests passed

### 13.1 Network Errors
- [x] Turn off wifi/data mid-action → Error alert appears
- [x] Reconnect → Can retry action

### 13.2 Empty Data States
- [x] New user → All lists empty with appropriate messages
- [x] No doodles → History shows empty state
- [x] No friends → Send sheet, Add Friends show empty states

### 13.3 Image Loading Failures
- [x] Doodle image fails to load → Placeholder with error icon shown
- [x] Can still view other doodles

### 13.4 Form Validation
- [x] Email field validates format
- [x] Password requires 6+ characters
- [x] Display name cannot be empty
- [x] Invite code input auto-capitalizes

### 13.5 Session Expiry
- [x] (After long time) Session expires → App handles gracefully
- [x] Should redirect to login if needed

---

## 14. Device Compatibility

### Mehul's Testing Notes:
[x] all tests passed

### 14.1 Screen Sizes
- [x] Test on iPhone SE (smallest)
- [x] Test on iPhone 15/16 (standard)
- [x] Test on iPhone 15/16 Pro Max (largest)
- [x] All UI elements visible and properly sized

### 14.2 Orientations
- [x] App should be portrait-only
- [x] Rotating device doesn't break layout

### 14.3 iOS Versions
- [x] Test on iOS 17.0 (minimum)
- [x] Test on iOS 18.x (latest)

---

## 15. Performance

### Mehul's Testing Notes:
[x] all tests passed

### 15.1 App Launch
- [x] Cold launch < 3 seconds to interactive
- [x] Splash screen displays during auth check

### 15.2 Drawing Performance
- [x] Drawing is smooth, no lag
- [x] Complex drawings (many strokes) still perform well

### 15.3 History with Many Doodles
- [x] 50+ doodles → Scrolling remains smooth
- [x] Images lazy load as needed

### 15.4 Memory
- [x] Use app extensively → No memory warnings
- [x] Images cached appropriately

---

## Test Data Setup

### Required Test Accounts
1. **Primary Test Account** - Main testing account
2. **Secondary Test Account** - For friend/doodle sending tests
3. **Premium Test Account** - For premium feature testing (sandbox purchase)

### Required Test Data
- Several doodles sent between accounts
- Friend relationship established between accounts
- Pending friend request for testing accept/decline

---

## Test Completion Checklist

- [x] All authentication flows pass
- [x] Drawing canvas fully functional
- [x] Send doodle flow works end-to-end
- [x] History displays and filters correctly
- [x] Doodle detail with all actions works
- [x] Profile displays and edits correctly
- [x] Settings all functional
- [x] Add Friends flow complete
- [x] Premium purchase flow works (sandbox)
- [ ] Widget displays correctly
- [x] Realtime updates working
- [x] No crashes during testing
- [x] No UI glitches or layout issues
- [x] Performance acceptable

---

*Last Updated: January 2025*
*App Version: 1.0.0*
