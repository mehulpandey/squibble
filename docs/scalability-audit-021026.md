# Scalability Audit - February 10, 2026

## Executive Summary

This audit identifies critical performance and scalability issues in the Squibble iOS app that are causing:
- **High Supabase egress** (5GB+ with only ~15 users)
- **Choppy user experience** (elements reloading when they should be cached)
- **Slow app launch** (blocking on multiple network requests)

---

## Critical Findings

### Issue #1: Widget Image Downloads Bypass Cache (CRITICAL)

**Location:** `squibble/Services/DoodleManager.swift` lines 206-214

**Problem:** Widget image downloads use raw `URLSession` without any caching, downloading the full image from Supabase storage on every widget refresh.

```swift
// Current implementation - NO CACHE
private func downloadDoodleImage(from urlString: String) async -> Data? {
    guard let url = URL(string: urlString) else { return nil }
    do {
        let (data, _) = try await URLSession.shared.data(from: url)  // Always downloads
        return data
    }
    // ...
}
```

**Impact Calculation:**
- Widget refreshes every 15 minutes = 96 times/day
- Average doodle image size: 500KB - 2MB
- 15 users × 96 refreshes × 1MB = **1.44 GB/day**
- This single issue accounts for majority of egress

**Additional Trigger Points:**
- `RootView.swift` line 98: Called on app launch
- `RootView.swift` line 124: Called on every realtime doodle event

---

### Issue #2: Conversation Loading N+1 Query Pattern (CRITICAL)

**Location:** `squibble/Services/ConversationManager.swift` lines 76-80, 115-119

**Problem:** Loading conversations triggers a loop of individual queries instead of batch operations.

```swift
// For EACH conversation, makes a separate query
for convID in conversationIDs {
    if let item = try? await supabase.getLatestThreadItem(conversationID: convID) {
        latestItems[convID] = item
    }
}

// Then ANOTHER loop for unread counts
for conv in convos {
    let unreadCount = try await supabase.countUnreadItems(...)
}
```

**Impact:**
- 10 conversations = 20+ individual database queries
- Happens on app launch AND every conversation list refresh
- Multiplied across all users

---

### Issue #3: Realtime Events Trigger Full Reloads (HIGH)

**Location:** `squibble/Views/RootView.swift` lines 119-124

**Problem:** Receiving a single doodle triggers a full reload of all doodles.

```swift
// On realtime doodle event:
await doodleManager.loadDoodles(for: userID)  // Reloads ALL doodles
await doodleManager.updateWidgetWithLatestDoodle(...)  // Downloads image (no cache)
```

**Impact:**
- Every incoming doodle = 2 database queries + 1 image download
- Active chat between users creates cascade of requests

---

### Issue #4: Reaction Reloads on Every State Change (HIGH)

**Location:** `squibble/Views/HistoryView.swift` lines 94-109

**Problem:** Reactions reload on multiple triggers without debouncing.

```swift
.onChange(of: viewMode) { newMode in
    if newMode == .grid {
        Task { await loadReactions() }  // Full reload
    }
}

.onChange(of: doodleManager.allDoodles) { _ in
    Task { await loadReactions() }  // Another full reload
}
```

**Impact:**
- Switching grid/chats triggers reload
- Any doodle change triggers reload
- No debouncing = rapid switching = rapid requests

---

### Issue #5: App Startup Blocks on All Data (HIGH)

**Location:** `squibble/Views/RootView.swift` lines 73-78

**Problem:** App waits for all data before showing UI.

```swift
async let userTask: () = userManager.loadUser(id: userID)
async let friendsTask: () = friendManager.loadFriends(for: userID)
async let doodlesTask: () = doodleManager.loadDoodles(for: userID)

_ = await (userTask, friendsTask, doodlesTask)  // Blocks until ALL complete
```

**Impact:**
- User sees splash screen until 3 parallel network requests complete
- Friends load = 2+ queries (friendships + user lookups)
- Doodles load = 2 queries (sent + received)
- Slow/poor network = long splash screen

---

### Issue #6: Over-fetching Columns (MEDIUM)

**Location:** `squibble/Services/SupabaseService.swift` (multiple locations)

**Problem:** Queries use `.select()` without column specification.

```swift
// Returns ALL columns
try await client.from("users").select().eq("id", value: id)

// Should be:
try await client.from("users").select("id, display_name, color_hex").eq("id", value: id)
```

**Impact:**
- Larger payloads than necessary
- Wasted bandwidth on unused fields

---

### Issue #7: No Pagination (MEDIUM)

**Location:** `squibble/Services/ConversationManager.swift`

**Problem:** All conversations and doodles loaded at once.

**Impact:**
- User with 100 conversations loads all 100
- No lazy loading as user scrolls
- Memory usage scales linearly with history

---

## Implementation Plan

### Phase 1: Critical Egress Fixes (Priority 1)

#### Task 1.1: Fix Widget Image Caching
**Files:** `DoodleManager.swift`

1. Modify `downloadDoodleImage()` to use `ImageCache.shared`
2. Store cached image path in App Group container
3. Widget reads from disk instead of re-downloading
4. Add cache validation (check if URL changed before using cached)

**Expected Impact:** -60-70% egress reduction

#### Task 1.2: Batch Conversation Queries
**Files:** `ConversationManager.swift`, `SupabaseService.swift`, new migration

1. Create Supabase RPC function: `get_conversations_with_metadata`
   - Returns conversations + latest item + unread count in single query
   - Uses window functions for efficiency
2. Replace N+1 loop with single RPC call
3. Cache results for 30 seconds

**Expected Impact:** -80% queries on conversation load

---

### Phase 2: Realtime & Reload Fixes (Priority 2)

#### Task 2.1: Realtime Append Instead of Reload
**Files:** `RootView.swift`, `DoodleManager.swift`

1. Create `appendReceivedDoodle(doodle:)` method
2. Realtime callback adds to `receivedDoodles` array directly
3. Only reload all if append fails (stale data)

**Expected Impact:** -90% realtime overhead

#### Task 2.2: Debounce Reaction Loads
**Files:** `HistoryView.swift`, `ConversationManager.swift`

1. Add `lastReactionLoadTime` tracking
2. Skip reload if loaded within last 30 seconds
3. Only force-reload on explicit pull-to-refresh

**Expected Impact:** Eliminates choppy UX on view switches

#### Task 2.3: Fix Widget Update Trigger
**Files:** `RootView.swift`

1. Only call `updateWidgetWithLatestDoodle()` if new doodle is more recent
2. Use cached image from `ImageCache.shared`
3. Debounce widget updates (max once per 5 seconds)

---

### Phase 3: Startup Optimization (Priority 3)

#### Task 3.1: Progressive App Startup
**Files:** `RootView.swift`, `squibbleApp.swift`

1. Show home screen immediately with just user data
2. Load friends in background (non-blocking)
3. Load doodles in background (non-blocking)
4. Use skeleton/placeholder UI while loading

**Expected Impact:** 50%+ faster perceived launch

#### Task 3.2: Startup Data Prioritization
**Files:** `SupabaseService.swift`

1. Create lightweight `getUserEssentials()` - just name, color, premium status
2. Defer full user profile load
3. Cache user essentials locally for instant cold start

---

### Phase 4: Query Optimization (Priority 4)

#### Task 4.1: Specify Query Columns
**Files:** `SupabaseService.swift`

1. Audit all `.select()` calls
2. Replace with explicit column lists
3. Create query variants for different use cases (list vs detail)

#### Task 4.2: Add Pagination
**Files:** `ConversationManager.swift`, `DoodleManager.swift`

1. Add cursor-based pagination for conversations
2. Load 20 conversations initially
3. Lazy-load more as user scrolls
4. Same for doodle grid

---

### Phase 5: Request Deduplication (Priority 5)

#### Task 5.1: In-Flight Request Tracking
**Files:** All managers

1. Track active requests by key
2. Return existing promise if request in-flight
3. Prevent duplicate concurrent requests

---

## Database Migration Required

### Migration: 015_batch_conversation_query.sql

```sql
-- Returns conversations with latest item and unread count in single query
CREATE OR REPLACE FUNCTION get_conversations_with_metadata(p_user_id uuid)
RETURNS TABLE (
  conversation_id uuid,
  other_user_id uuid,
  other_user_display_name text,
  other_user_color_hex text,
  other_user_profile_image_url text,
  last_read_at timestamptz,
  muted boolean,
  latest_item_id uuid,
  latest_item_type text,
  latest_item_sender_id uuid,
  latest_item_created_at timestamptz,
  unread_count bigint
) AS $$
BEGIN
  RETURN QUERY
  WITH my_participations AS (
    SELECT cp.conversation_id, cp.last_read_at, cp.muted
    FROM conversation_participants cp
    WHERE cp.user_id = p_user_id
  ),
  other_participants AS (
    SELECT cp.conversation_id, cp.user_id,
           u.display_name, u.color_hex, u.profile_image_url
    FROM conversation_participants cp
    JOIN users u ON u.id = cp.user_id
    WHERE cp.user_id != p_user_id
      AND cp.conversation_id IN (SELECT conversation_id FROM my_participations)
  ),
  latest_items AS (
    SELECT DISTINCT ON (ti.conversation_id)
           ti.conversation_id, ti.id, ti.type, ti.sender_id, ti.created_at
    FROM thread_items ti
    WHERE ti.conversation_id IN (SELECT conversation_id FROM my_participations)
    ORDER BY ti.conversation_id, ti.created_at DESC
  ),
  unread_counts AS (
    SELECT ti.conversation_id, COUNT(*) as cnt
    FROM thread_items ti
    JOIN my_participations mp ON mp.conversation_id = ti.conversation_id
    WHERE ti.created_at > COALESCE(mp.last_read_at, '1970-01-01'::timestamptz)
      AND ti.sender_id != p_user_id
    GROUP BY ti.conversation_id
  )
  SELECT
    mp.conversation_id,
    op.user_id,
    op.display_name,
    op.color_hex,
    op.profile_image_url,
    mp.last_read_at,
    mp.muted,
    li.id,
    li.type,
    li.sender_id,
    li.created_at,
    COALESCE(uc.cnt, 0)
  FROM my_participations mp
  JOIN other_participants op ON op.conversation_id = mp.conversation_id
  LEFT JOIN latest_items li ON li.conversation_id = mp.conversation_id
  LEFT JOIN unread_counts uc ON uc.conversation_id = mp.conversation_id
  ORDER BY COALESCE(li.created_at, '1970-01-01'::timestamptz) DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## Testing Checklist

After each phase, verify:

- [ ] Widget displays correctly without re-downloading on refresh
- [ ] Conversation list loads quickly (< 500ms)
- [ ] Switching grid/chats doesn't cause visible reload
- [ ] App launches to home screen within 1 second
- [ ] Receiving doodle updates UI without full reload
- [ ] Supabase dashboard shows reduced egress

---

## Metrics to Track

Before/after implementation:
1. **Egress per user per day** (Supabase dashboard)
2. **App launch time** (Xcode Instruments)
3. **Time to interactive** on History tab
4. **Number of API calls per session** (logging)

---

## Risk Assessment

| Task | Risk | Mitigation |
|------|------|------------|
| Widget caching | Cache invalidation bugs | Add URL hash validation |
| Batch RPC | Complex SQL, migration | Test thoroughly in dev branch |
| Realtime append | Race conditions | Add sequence numbers |
| Progressive startup | UI flicker | Use skeleton loaders |

---

## Estimated Effort

| Phase | Tasks | Estimated Time |
|-------|-------|----------------|
| Phase 1 | 1.1, 1.2 | 3-4 hours |
| Phase 2 | 2.1, 2.2, 2.3 | 2-3 hours |
| Phase 3 | 3.1, 3.2 | 2 hours |
| Phase 4 | 4.1, 4.2 | 2 hours |
| Phase 5 | 5.1 | 1 hour |
| **Total** | | **10-12 hours** |

---

## Recommended Implementation Order

1. **Task 1.1** - Widget image caching (biggest egress impact)
2. **Task 1.2** - Batch conversation queries (biggest query reduction)
3. **Task 2.1** - Realtime append (cascading request prevention)
4. **Task 2.2** - Debounce reactions (UX improvement)
5. **Task 3.1** - Progressive startup (perceived performance)
6. Remaining tasks in order

---

*Document created: February 10, 2026*
*Author: Claude (Scalability Audit)*
