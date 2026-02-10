# Test Cases: Chat & Reactions Features

## Overview
Test cases for the conversation threading and reactions features added in `feature/conversation-threading` branch.

---

## 1. History Tab - View Mode Toggle

### [ ] TC-1.1: Grid/Chats Toggle Display
**Steps:**
1. Open app and navigate to History tab
2. Observe the header area

**Expected:**
- Toggle control shows two icons: grid icon and chat bubbles icon
- Current mode is visually highlighted
- Toggle has gray background with selected item showing white highlight

### [ ] TC-1.2: Switch to Chats Mode
**Steps:**
1. From History tab in Grid mode
2. Tap the chat bubbles icon

**Expected:**
- Haptic feedback occurs
- View switches to Chats mode with smooth animation
- Filter bar disappears (only visible in Grid mode)
- Conversation list appears

### [ ] TC-1.3: Switch to Grid Mode
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

### [ ] TC-6.1: Tap Doodle in Thread
**Steps:**
1. In thread view, tap on any doodle

**Expected:**
- Doodle overlay opens (fullscreen)
- Shows enlarged doodle
- Reaction picker visible
- Share and Reply buttons visible

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
1. Add reaction to a doodle via grid
2. View the doodle in grid

**Expected:**
- Small emoji badge visible on bottom-right of grid item
- White circular background behind emoji
- Shadow for visibility
- Matches style of initials badge (bottom-left)

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

### [ ] TC-9.3: Reply Button (Sent Doodle)
**Steps:**
1. Open overlay for a doodle you sent
2. Observe Reply button

**Expected:**
- Reply button disabled/grayed out
- Cannot reply to your own doodle

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

## Test Environment Notes

- [ ] Test on iPhone with notch (e.g., iPhone 14/15/16) for safe area handling
- [ ] Test on older devices (iPhone SE) for different screen sizes
- [ ] Test with VoiceOver enabled for accessibility
- [ ] Test in both light conditions (outdoor/indoor) for UI visibility
