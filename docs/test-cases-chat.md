# Test Cases: Chat & Reactions Features

## Overview
Test cases for the conversation threading and reactions features added in `feature/conversation-threading` branch.

---

## 1. History Tab - View Mode Toggle

### [x] TC-1.1: Grid/Chats Toggle Display
**Steps:**
1. Open app and navigate to History tab
2. Observe the header area

**Expected:**
- Toggle control shows two icons: grid icon and chat bubbles icon
- Current mode is visually highlighted
- Toggle has gray background with selected item showing white highlight

### [x] TC-1.2: Switch to Chats Mode
**Steps:**
1. From History tab in Grid mode
2. Tap the chat bubbles icon

**Expected:**
- Haptic feedback occurs
- View switches to Chats mode with smooth animation
- Filter bar disappears (only visible in Grid mode)
- Conversation list appears

### [x] TC-1.3: Switch to Grid Mode
**Steps:**
1. From History tab in Chats mode
2. Tap the grid icon

**Expected:**
- Haptic feedback occurs
- View switches to Grid mode with smooth animation
- Filter bar appears below header
- Doodle grid appears

---

## 2. Conversation List View

### [ ] TC-2.1: Empty State
**Steps:**
1. Use account with no conversations
2. Navigate to History > Chats mode

**Expected:**
- Empty state displays with appropriate icon and message
- Message indicates no conversations yet

### [ ] TC-2.2: Conversation List Display
**Steps:**
1. Use account with existing conversations
2. Navigate to History > Chats mode

**Expected:**
- Conversations listed in order of most recent activity
- Each row shows:
  - Friend's avatar (profile pic or initials with color)
  - Friend's display name
  - Timestamp of last activity
  - Preview text (e.g., "sent you a doodle" or "You sent a doodle")

### [ ] TC-2.3: Unread Indicator
**Steps:**
1. Have a conversation with unread doodles
2. View conversation list

**Expected:**
- Unread conversations show visual indicator (blue dot or badge)
- Indicator disappears after opening the conversation

### [ ] TC-2.4: Pull to Refresh
**Steps:**
1. In Chats mode, pull down on the list

**Expected:**
- Refresh indicator appears
- Conversations reload from server
- List updates with any new conversations

### [ ] TC-2.5: Open Conversation
**Steps:**
1. Tap on a conversation row

**Expected:**
- Thread view opens as fullscreen cover
- Smooth transition animation
- Thread content loads

---

## 3. Conversation Thread View

### [ ] TC-3.1: Thread Header
**Steps:**
1. Open a conversation thread

**Expected:**
- Header shows blur effect with hard edge (no fade)
- Back chevron on left
- Friend's name and avatar in center
- Settings gear icon on right
- Header blur extends to top of screen

### [ ] TC-3.2: Back Navigation
**Steps:**
1. In thread view, tap the back chevron

**Expected:**
- Thread dismisses with animation
- Returns to conversation list

### [ ] TC-3.3: Doodle Bubble Alignment
**Steps:**
1. Open conversation with both sent and received doodles

**Expected:**
- Received doodles (from friend) aligned to LEFT with colored accent
- Sent doodles (from you) aligned to RIGHT with gray accent
- Each bubble shows the doodle image in white rounded container

### [ ] TC-3.4: Timestamp Display
**Steps:**
1. Open conversation with doodles from different times

**Expected:**
- Timestamps shown between doodle groups
- First doodle always has timestamp
- Subsequent doodles show timestamp only if significant time gap

### [ ] TC-3.5: Scroll Behavior
**Steps:**
1. Open conversation with many doodles

**Expected:**
- Content scrolls behind the floating header
- Header maintains blur effect
- Can scroll to see all doodles
- New doodles appear at bottom (chronological order)

### [ ] TC-3.6: Empty Thread
**Steps:**
1. Create new conversation with no doodles yet

**Expected:**
- Empty state or minimal UI displayed
- "Send Doodle" button visible

---

## 4. Send Doodle from Thread

### [ ] TC-4.1: Send Doodle Button
**Steps:**
1. Open conversation thread
2. Tap "Send Doodle" button at bottom

**Expected:**
- Navigates to Home tab
- Friend is pre-selected as recipient
- Canvas ready for drawing

### [ ] TC-4.2: Doodle Appears in Thread
**Steps:**
1. Send a doodle to a friend
2. Open conversation with that friend

**Expected:**
- New doodle appears in thread
- Positioned on right side (sent by you)
- Shows correct timestamp

---

## 5. Chat Settings

### [ ] TC-5.1: Open Settings Sheet
**Steps:**
1. In thread view, tap settings gear icon

**Expected:**
- Settings sheet presents from bottom
- Shows friend's avatar and name
- Shows available options

### [ ] TC-5.2: Mute Toggle
**Steps:**
1. Open chat settings
2. Toggle mute switch

**Expected:**
- Switch toggles visually
- Mute state persists (close and reopen to verify)
- Muted chats don't send push notifications

### [ ] TC-5.3: Unfriend Flow
**Steps:**
1. Open chat settings
2. Tap "Unfriend" option
3. Confirm in dialog

**Expected:**
- Confirmation dialog appears
- On confirm: friend removed, thread closes
- Conversation no longer appears in list

---

## 6. Doodle Tap Interaction (Thread)

### [ ] TC-6.1: Tap Received Doodle in Thread
**Steps:**
1. In thread view, tap on a doodle you received

**Expected:**
- Doodle overlay opens (fullscreen)
- Shows enlarged doodle
- Reaction picker visible (6 emoji options)
- Share and Reply buttons visible

### [ ] TC-6.1b: Tap Sent Doodle in Thread
**Steps:**
1. In thread view, tap on a doodle you sent

**Expected:**
- Doodle overlay opens (fullscreen)
- Shows enlarged doodle
- NO reaction picker (can't react to own doodle)
- Shows aggregated reactions badge if recipients have reacted
- Share and Forward buttons visible

### [ ] TC-6.2: Long Press Doodle
**Steps:**
1. In thread view, long press (hold) on a doodle

**Expected:**
- Visual scale-up feedback during hold
- After ~0.25s, overlay opens
- Haptic feedback

---

## 7. Reactions - Thread View

### [ ] TC-7.1: Add Reaction
**Steps:**
1. Open doodle overlay in thread
2. Tap an emoji in reaction picker

**Expected:**
- Haptic feedback
- Selected emoji highlights
- Overlay auto-dismisses
- Reaction appears on doodle bubble in thread

### [ ] TC-7.2: Change Reaction
**Steps:**
1. Open doodle that already has your reaction
2. Tap a different emoji

**Expected:**
- Previous reaction replaced with new one
- Only one reaction from you per doodle

### [ ] TC-7.3: Remove Reaction
**Steps:**
1. Open doodle with your existing reaction
2. Tap the same emoji again

**Expected:**
- Reaction removed (toggle behavior)
- Doodle bubble no longer shows your reaction

### [ ] TC-7.4: Reaction Display on Bubble
**Steps:**
1. Add reaction to a doodle
2. View the doodle in thread

**Expected:**
- Reaction emoji displayed on bottom-right of doodle bubble
- White/light background circle behind emoji
- Subtle shadow for visibility

### [ ] TC-7.5: Multiple Reactions (Group Chat - Future)
**Note:** Groups not yet implemented, but reaction display supports counts

**Expected for 1:1 chats:**
- Only unique emojis shown (no count badge)

---

## 8. Reactions - Grid View

### [ ] TC-8.1: Tap Doodle in Grid
**Steps:**
1. In History > Grid mode
2. Tap any doodle

**Expected:**
- Doodle overlay opens at MainTabView level (covers tab bar)
- Shows sender info, reaction picker, enlarged doodle, action buttons

### [ ] TC-8.2: Add Reaction from Grid
**Steps:**
1. Open doodle overlay from grid
2. Tap an emoji

**Expected:**
- Haptic feedback
- Reaction persists to database
- Overlay dismisses
- Grid item shows reaction badge (bottom-right corner)

### [ ] TC-8.3: Reaction Badge on Grid Item
**Steps:**
1. Add reaction to a received doodle via grid
2. View the doodle in grid

**Expected:**
- Small emoji badge visible on bottom-right of grid item
- Blue-tinted background (for your reaction on received doodle)
- Shadow for visibility
- See TC-14 for aggregated reactions on sent doodles

### [ ] TC-8.4: Reaction Syncs Between Views
**Steps:**
1. Add reaction in Grid view
2. Open same conversation in Chats mode
3. Find the doodle in thread

**Expected:**
- Reaction visible on doodle in thread view
- Same emoji shown

### [ ] TC-8.5: Reaction from Thread Syncs to Grid
**Steps:**
1. Add reaction in Thread view
2. Switch to Grid mode
3. Find the doodle in grid

**Expected:**
- Reaction badge visible on grid item
- Same emoji shown

---

## 9. Overlay Action Buttons

### [ ] TC-9.1: Share Button
**Steps:**
1. Open doodle overlay
2. Tap "Share" button

**Expected:**
- iOS share sheet appears
- Doodle image available to share
- Can share to Messages, social apps, save to Photos, etc.

### [ ] TC-9.2: Reply Button (Received Doodle)
**Steps:**
1. Open overlay for a doodle you received
2. Tap "Reply" button

**Expected:**
- Overlay dismisses
- Navigates to Home tab
- Sender pre-selected as recipient
- Ready to draw reply

### [ ] TC-9.3: Forward Button (Sent Doodle)
**Steps:**
1. Open overlay for a doodle you sent
2. Observe action buttons

**Expected:**
- "Forward" button shown instead of "Reply"
- Forward button is active and tappable
- See TC-15 for full Forward flow testing

---

## 10. Header Consistency

### [ ] TC-10.1: History Header Position
**Steps:**
1. View History tab
2. Compare header position to Profile tab

**Expected:**
- "History" text at same vertical position as "Profile" text
- Consistent with all tabs

### [ ] TC-10.2: Blur Effect
**Steps:**
1. In History tab (either mode), scroll content

**Expected:**
- Content scrolls behind header
- Header maintains blur/glass effect
- Blur extends to very top of screen (no gap)
- Hard edge at bottom of header (no fade)

### [ ] TC-10.3: Thread Header Blur
**Steps:**
1. In thread view, scroll content

**Expected:**
- Doodle bubbles scroll behind header
- Header maintains blur effect
- Hard edge at bottom (consistent with History header)

---

## 11. Filter Interaction (Grid Mode)

### [ ] TC-11.1: Filter Pills Style
**Steps:**
1. In Grid mode, observe filter pills

**Expected:**
- Selected filter has orange gradient background
- Unselected filters have gray background
- "All", "Sent", "Received" options available

### [ ] TC-11.2: Person Filter Selected
**Steps:**
1. Tap person filter icon
2. Select a friend

**Expected:**
- Person filter shows orange gradient when friend selected
- Shows chevron indicator when active
- Grid filters to show only doodles with that person

---

## 12. Edge Cases

### [ ] TC-12.1: Network Error - Load Conversations
**Steps:**
1. Disable network
2. Try to load conversation list

**Expected:**
- Graceful error handling
- Error message or cached data shown
- No crash

### [ ] TC-12.2: Network Error - Send Reaction
**Steps:**
1. Add reaction
2. Immediately disable network

**Expected:**
- Optimistic UI update shows reaction
- Background retry or revert on failure
- No crash

### [ ] TC-12.3: Large Thread
**Steps:**
1. Open conversation with 50+ doodles

**Expected:**
- Thread loads without lag
- Smooth scrolling
- Memory usage reasonable

### [ ] TC-12.4: Rapid Tab Switching
**Steps:**
1. Quickly switch between Grid/Chats modes multiple times

**Expected:**
- No visual glitches
- Content loads correctly each time
- No crash

---

## 13. Data Persistence

### [ ] TC-13.1: Conversations Persist
**Steps:**
1. View conversations
2. Force quit app
3. Reopen app

**Expected:**
- Conversations still visible
- Data loads from server
- No data loss

### [ ] TC-13.2: Reactions Persist
**Steps:**
1. Add reaction to doodle
2. Force quit and reopen app
3. Check doodle

**Expected:**
- Reaction still visible
- Synced from server

---

## 14. Aggregated Reactions (Sent Doodles)

### [ ] TC-14.1: Single Reaction Badge
**Steps:**
1. Send a doodle to one friend
2. Have friend react with an emoji
3. View doodle in Grid mode

**Expected:**
- Reaction badge shows single emoji (e.g., "😂")
- Badge has white/light background (Messenger-style for received reactions)
- Badge positioned in bottom-right corner

### [ ] TC-14.2: Multiple Reactions Badge
**Steps:**
1. Send a doodle to 3+ friends
2. Have 2 friends react with same emoji, 1 with different
3. View doodle in Grid mode

**Expected:**
- Badge shows top emojis by frequency + count (e.g., "😂❤️2" or "😂😂❤️3")
- Up to 3 different emojis shown
- Count shown when 2+ total reactions

### [ ] TC-14.3: Aggregated Badge in Detail View
**Steps:**
1. Send doodle to multiple friends who react
2. Tap doodle in Grid to open overlay

**Expected:**
- Aggregated reactions badge visible below doodle image
- Shows same format as grid badge (top emojis + count)
- Badge is tappable

### [ ] TC-14.4: Reactors List Popup
**Steps:**
1. Open detail overlay for sent doodle with reactions
2. Tap the aggregated reactions badge

**Expected:**
- Sheet slides up with "Reactions" title
- Shows list of people who reacted
- Each row shows: avatar, name, and their emoji reaction
- "Done" button dismisses sheet
- Glassy background style (matches other sheets)

### [ ] TC-14.5: Color Differentiation - Sent vs Received
**Steps:**
1. View Grid with both sent and received doodles that have reactions
2. Compare reaction badge backgrounds

**Expected:**
- Sent doodles (reactions from others): White/light badge background
- Received doodles (your reaction): Blue-tinted badge background
- Clear visual distinction between the two

### [ ] TC-14.6: No Reaction Picker for Sent Doodles
**Steps:**
1. Open detail overlay for a doodle you sent

**Expected:**
- Reaction picker NOT shown (can't react to own doodle)
- Only see: header info, doodle image, reactions badge (if any), Forward/Share buttons

---

## 15. Forward Doodle

### [ ] TC-15.1: Forward Button Display
**Steps:**
1. Open detail overlay for a doodle you sent

**Expected:**
- "Forward" button visible (instead of Reply)
- Button has forward arrow icon

### [ ] TC-15.2: Forward Sheet Opens
**Steps:**
1. Open detail overlay for sent doodle
2. Tap "Forward" button

**Expected:**
- Forward sheet slides up
- Shows friend list with checkboxes
- "Cancel" button in header
- No send button until friends selected

### [ ] TC-15.3: Select Friends to Forward
**Steps:**
1. Open forward sheet
2. Tap multiple friends

**Expected:**
- Checkboxes toggle on/off
- Haptic feedback on selection
- Send button appears when 1+ friends selected
- Button shows count (e.g., "Forward to 2 friends")

### [ ] TC-15.4: Forward Success
**Steps:**
1. Select friends and tap send
2. Wait for completion

**Expected:**
- Loading indicator while sending
- Success overlay with checkmark
- Sheet auto-dismisses after ~1 second
- Doodle now visible in those friends' conversations

### [ ] TC-15.5: Forward Empty State
**Steps:**
1. Remove all friends
2. Try to forward a doodle

**Expected:**
- Empty state shown with "No friends to forward to" message
- Person icon displayed

---

## 16. Recipients List (Sent Doodles)

### [ ] TC-16.1: Single Recipient Display
**Steps:**
1. Send doodle to one friend
2. Open doodle in detail overlay

**Expected:**
- Header shows "Sent to [Friend Name]"
- Name is not tappable (no popup needed)

### [ ] TC-16.2: Multiple Recipients Display
**Steps:**
1. Send doodle to 3 friends
2. Open doodle in detail overlay

**Expected:**
- Header shows "Sent to 3 people"
- "3 people" is tappable (orange color)

### [ ] TC-16.3: Recipients List Popup
**Steps:**
1. Open doodle sent to multiple people
2. Tap "X people" link

**Expected:**
- Sheet slides up with "Sent to" title
- Shows list of all recipients
- Each row shows avatar and name
- "Done" button dismisses sheet

---

## 17. Sheet Styling Consistency

### [ ] TC-17.1: Glassy Background
**Steps:**
1. Open various sheets (Send, Friends, Chat Settings, Reactions, Recipients)

**Expected:**
- All sheets have glassy/semi-transparent background
- No opaque dark backgrounds
- System drag indicator visible at top

### [ ] TC-17.2: Navigation Bar Style
**Steps:**
1. Open sheets with navigation bars

**Expected:**
- Inline title display
- Orange "Done" button in top-right
- Consistent across all sheets

### [ ] TC-17.3: List Row Backgrounds
**Steps:**
1. Open sheets with lists (Friends, Recipients, Reactions)

**Expected:**
- List rows have clear/transparent backgrounds
- Content visible through glassy sheet background

---

## Test Environment Notes

- [ ] Test on iPhone with notch (e.g., iPhone 14/15/16) for safe area handling
- [ ] Test on older devices (iPhone SE) for different screen sizes
- [ ] Test with VoiceOver enabled for accessibility
- [ ] Test in both light conditions (outdoor/indoor) for UI visibility
