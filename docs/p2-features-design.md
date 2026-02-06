# P2 High Value Features: Design Plan

## Overview

This document outlines the UX design for the P2 High Value features requested by beta testers. These features are interconnected and require a holistic approach.

**Features covered:**
1. Messaging style UI / Conversation threading
2. Groups
3. Reactions to doodles
4. Per-friend streak count
5. Collaborative drawing / Reply on doodle

---

## The Core Insight

All 5 features share a common thread: they shift Squibble from a **doodle-centric** model to a **conversation-centric** model. Currently, doodles exist in isolation. These features make doodles part of ongoing exchanges between people.

| Current Model | New Model |
|--------------|-----------|
| History → Grid of doodles → Detail | History → Conversations list → Thread → Detail |
| Doodles are standalone objects | Doodles exist within conversation context |
| No concept of "exchange" | Back-and-forth dialogue with a friend/group |

---

## Feature 1: Conversation Threading

### History Tab: Dual View with Segment Control

The History tab will support both the existing grid view and the new conversations view via a segment control at the top. Grid is the default view to preserve the visual appeal.

```
Grid mode (default):              Chats mode:
┌────────────────────────────────┐ ┌────────────────────────────────┐
│ [Grid]  [Chats]                │ │ [Grid]  [Chats]                │
├────────────────────────────────┤ ├────────────────────────────────┤
│ [All] [Sent] [Recv] [Person]   │ │ 🔵 Alex            2m     🔥5 │
├────────────────────────────────┤ │    sent you a doodle          │
│ ┌──┐┌──┐┌──┐┌──┐              │ ├────────────────────────────────┤
│ │  ││  ││  ││  │              │ │ 🟢 Jordan          1h         │
│ └──┘└──┘└──┘└──┘              │ │    you sent a doodle          │
│ ┌──┐┌──┐┌──┐┌──┐              │ ├────────────────────────────────┤
│ │  ││  ││  ││  │              │ │ 👥 The Crew        3h         │
│ └──┘└──┘└──┘└──┘              │ │    Sam sent a doodle          │
└────────────────────────────────┘ └────────────────────────────────┘
```

- **Grid mode**: Unchanged from current implementation (filter pills, doodle grid)
- **Chats mode**: Conversation list showing 1:1 chats and groups

### Conversation List Design

Each row shows:
- Avatar (with user's color border)
- Name
- Relative timestamp ("2m", "1h", "Yesterday")
- Streak badge (🔥5) — for 1:1 chats only
- Unread indicator (bold text or dot) if applicable
- Preview text: "sent you a doodle", "you sent a doodle", or last text message preview

Sort by most recent activity.

### Conversation Thread Design

```
┌────────────────────────────────┐
│ ← Alex                🔥5  ⚙️  │  ← Header with streak, settings
├────────────────────────────────┤
│        ┌──────────┐            │
│        │ [doodle] │  12:30 PM  │  ← Their doodle (left-aligned)
│        └──────────┘            │
│                    ❤️ 😂       │  ← Reactions (future)
│                                │
│              ┌──────────┐      │
│   2:15 PM    │ [doodle] │      │  ← Your doodle (right-aligned)
│              └──────────┘      │
│                                │
│   Their text message here      │  ← Text message (left)
│                                │
│        ┌──────────┐            │
│        │ [doodle] │   now      │
│        └──────────┘            │
│                                │
├────────────────────────────────┤
│ [Send message...]        [🎨]  │  ← Text input + doodle button
└────────────────────────────────┘
```

### Action Bar Design

The action bar uses a familiar messaging pattern:
- **Text input field** on the left ("Send message..." placeholder)
- **Prominent doodle button** on the right (🎨 icon, visually distinct with color/size)

Tapping the doodle button navigates to the drawing canvas with the recipient pre-selected.

### Chat Settings

**1:1 Chat Settings:**
```
┌────────────────────────────────┐
│ ← Alex                         │
├────────────────────────────────┤
│         [Avatar]               │
│          Alex                  │
│      🔥 12 day streak          │
├────────────────────────────────┤
│ Mute Notifications        [>]  │
├────────────────────────────────┤
│ Unfriend                       │  ← Destructive action
└────────────────────────────────┘
```

**Group Chat Settings:**
```
┌────────────────────────────────┐
│ ← The Crew                     │
├────────────────────────────────┤
│ Group Name                     │
│ [The Crew                    ] │  ← Editable
├────────────────────────────────┤
│ MEMBERS (4)                    │
│ 🔵 Alex                        │
│ 🟢 Jordan                      │
│ 🟣 Sam                         │
│ 🟠 You                         │
│ [+ Add Members]                │
├────────────────────────────────┤
│ Mute Notifications        [>]  │
├────────────────────────────────┤
│ Leave Group                    │  ← Destructive action
└────────────────────────────────┘
```

### Key UX Decisions

- **Doodle bubbles**: Show as rounded thumbnails. Their doodles aligned left with their color accent, yours aligned right
- **Tap to expand**: Tap any doodle → opens full-screen detail (existing DoodleDetailView)
- **Long press for reactions**: Hold on a doodle → reaction picker appears (future phase)
- **Text input**: Familiar iMessage-style input bar with prominent doodle button to maintain app's core identity

---

## Feature 2: Groups

### Creation Flow

```
Add Friends Screen:
┌────────────────────────────────┐
│ ← Add Friends                  │
├────────────────────────────────┤
│ [+ New Group]                  │  ← New prominent action
├────────────────────────────────┤
│ FRIEND REQUESTS                │
│ ...                            │
├────────────────────────────────┤
│ FRIENDS                        │
│ ...                            │
└────────────────────────────────┘

New Group Sheet:
┌────────────────────────────────┐
│ New Group               Create │
├────────────────────────────────┤
│ Group Name: [The Crew        ] │  ← Optional, auto-generates if empty
├────────────────────────────────┤
│ Add Members:                   │
│ ☑️ Alex                        │
│ ☑️ Jordan                      │
│ ☐ Sam                          │
│ ☐ Taylor                       │
└────────────────────────────────┘
```

### Group Thread Design

```
┌────────────────────────────────┐
│ ← The Crew (4)            ⚙️   │  ← Group name, member count
├────────────────────────────────┤
│ Alex                           │
│   ┌──────────┐                 │
│   │ [doodle] │  12:30 PM       │  ← Show sender name above doodle
│   └──────────┘                 │
│               ❤️2 😂1          │  ← Aggregated reactions
│                                │
│ You                            │
│         ┌──────────┐           │
│  2:15   │ [doodle] │           │
│         └──────────┘           │
│                                │
│ Sam                            │
│   ┌──────────┐                 │
│   │ [doodle] │   now           │
│   └──────────┘                 │
└────────────────────────────────┘
```

### Group Settings

- View members
- Add members (any member can add)
- Leave group
- Rename group
- Delete group (creator only)

### Send Sheet Update

```
┌────────────────────────────────┐
│ Send to...                  ✕  │
├────────────────────────────────┤
│ GROUPS                         │
│ ☐ The Crew (4)                 │
│ ☐ Family (3)                   │
├────────────────────────────────┤
│ FRIENDS                        │
│ ☐ Alex                         │
│ ☐ Jordan                       │
│ ...                            │
└────────────────────────────────┘
```

---

## Feature 3: Reactions

### Interaction Pattern

- **Long press** on any doodle in thread → reaction picker slides up
- **Picker design**: 6-8 emoji in a horizontal bar (❤️ 😂 😮 😢 🔥 👍 👎)
- **Tap emoji** → adds your reaction, picker dismisses
- **Tap same emoji again** → removes your reaction

### Display

```
1:1 Conversation:
┌──────────┐
│ [doodle] │
└──────────┘
     ❤️        ← Shows their reaction (just emoji, no count)

Group Conversation:
┌──────────┐
│ [doodle] │
└──────────┘
  ❤️3  😂2    ← Aggregated counts
```

### Notifications

- Push notification when someone reacts to your doodle
- "Alex ❤️ your doodle"
- Tapping opens the conversation thread, scrolls to that doodle

---

## Feature 4: Per-Friend Streaks

### Calculation Logic

**Recommended: One-sided streaks**
- Streak = consecutive days you sent them a doodle
- Resets to 0 if a day passes without sending
- User has full control over maintaining their streaks
- Matches Snapchat's model

### Display Locations

1. **Conversation list row:**
   ```
   🔵 Alex                2m  🔥5
   ```

2. **Conversation thread header:**
   ```
   ← Alex                🔥5  ⚙️
   ```

3. **Profile → Friends section:**
   ```
   FRIENDS
   ┌─────────────────────────────┐
   │ 🔵 Alex              🔥12  │
   │ 🟢 Jordan            🔥5   │
   │ 🟣 Sam               🔥0   │
   └─────────────────────────────┘
   ```

### Streak Warning

- If you haven't sent a doodle today and it's past 6pm, show ⏰ or ⚠️ next to streak
- Optional: streak reminder push notification ("Your streak with Alex is about to expire!")

---

## Feature 5: Collaborative Drawing

### Entry Points

- In conversation thread: "draw on this" icon or long-press menu option
- In DoodleDetailView: "Reply with drawing" button

### Flow

1. User taps "Draw on this" on received doodle
2. Opens drawing canvas
3. Received doodle appears as locked background layer (faded ~30% opacity)
4. User draws on top
5. User taps Send → goes to that same friend/group
6. Sent doodle shows visual link to original (reply indicator)

### Canvas with Background Doodle

```
┌────────────────────────────────┐
│ [Cancel]         [Clear] [Send]│
├────────────────────────────────┤
│ ┌────────────────────────────┐ │
│ │                            │ │
│ │  [faded original doodle]   │ │
│ │     + user's new strokes   │ │
│ │                            │ │
│ └────────────────────────────┘ │
├────────────────────────────────┤
│ [Pen]      [Eraser]    [Color] │
└────────────────────────────────┘
```

### Reply Indicator in Thread

```
┌──────────────────┐
│ ↩️ replied to:   │
│ ┌────┐           │
│ │tiny│           │  ← Small thumbnail of original
│ └────┘           │
│ ┌──────────────┐ │
│ │ [new doodle] │ │
│ └──────────────┘ │
└──────────────────┘
```

---

## Technical Architecture

This architecture is designed for scalability from the start, using a unified data model that efficiently supports all P2 features.

### Core Design Decisions

| Decision | Approach | Rationale |
|----------|----------|-----------|
| Conversation model | Explicit `conversations` table | Fast queries, easy metadata (muted, last_read), cleaner model |
| Timeline data | Unified `thread_items` table | Single query for pagination, no client-side merging, easy to extend |
| Client storage | SwiftData for local persistence | Offline-first, instant UI, background sync |
| Real-time | Supabase Realtime subscriptions | Live updates without polling |

### Database Schema

#### New Tables

```sql
-- Conversations (1:1 or group)
create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  type text not null check (type in ('direct', 'group')),
  group_id uuid references public.groups(id),  -- null for direct
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()  -- bumped on new activity
);

-- Participants with read state and preferences
create table public.conversation_participants (
  conversation_id uuid references public.conversations(id) on delete cascade,
  user_id uuid references public.users(id) on delete cascade,
  last_read_at timestamp with time zone default now(),
  muted boolean default false,
  joined_at timestamp with time zone default now(),
  primary key (conversation_id, user_id)
);

-- Unified timeline for all conversation content (doodles + text)
create table public.thread_items (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid references public.conversations(id) on delete cascade not null,
  sender_id uuid references public.users(id) not null,
  type text not null check (type in ('doodle', 'text')),

  -- For doodles
  doodle_id uuid references public.doodles(id) on delete cascade,

  -- For text messages
  text_content text,

  -- For replies (collaborative drawing)
  reply_to_item_id uuid references public.thread_items(id),

  created_at timestamp with time zone default now(),

  -- Constraints
  constraint valid_doodle check (type != 'doodle' or doodle_id is not null),
  constraint valid_text check (type != 'text' or text_content is not null)
);

-- Groups
create table public.groups (
  id uuid primary key default gen_random_uuid(),
  name text,  -- optional, can be null for auto-generated names
  created_by uuid references public.users(id) not null,
  created_at timestamp with time zone default now()
);

-- Group members
create table public.group_members (
  group_id uuid references public.groups(id) on delete cascade,
  user_id uuid references public.users(id) on delete cascade,
  joined_at timestamp with time zone default now(),
  primary key (group_id, user_id)
);

-- Reactions (attached to thread_items, not directly to doodles)
create table public.reactions (
  id uuid primary key default gen_random_uuid(),
  thread_item_id uuid references public.thread_items(id) on delete cascade not null,
  user_id uuid references public.users(id) on delete cascade not null,
  emoji text not null,
  created_at timestamp with time zone default now(),
  unique(thread_item_id, user_id)  -- one reaction per user per item
);

-- Indexes for common queries
create index idx_thread_items_conversation_time
  on public.thread_items(conversation_id, created_at desc);

create index idx_conversation_participants_user
  on public.conversation_participants(user_id);

create index idx_conversations_updated
  on public.conversations(updated_at desc);

create index idx_reactions_thread_item
  on public.reactions(thread_item_id);
```

#### Schema Modifications to Existing Tables

```sql
-- Add to friendships table: per-friend streak tracking
alter table public.friendships add column streak_count int not null default 0;
alter table public.friendships add column last_doodle_sent_at timestamp with time zone;
```

### Helper Functions

```sql
-- Get or create a direct conversation between two users
create or replace function get_or_create_direct_conversation(
  user_a uuid,
  user_b uuid
) returns uuid as $$
declare
  conv_id uuid;
begin
  -- Find existing conversation
  select cp1.conversation_id into conv_id
  from conversation_participants cp1
  join conversation_participants cp2 on cp1.conversation_id = cp2.conversation_id
  join conversations c on c.id = cp1.conversation_id
  where cp1.user_id = user_a
    and cp2.user_id = user_b
    and c.type = 'direct';

  -- Create if not exists
  if conv_id is null then
    insert into conversations (type) values ('direct') returning id into conv_id;
    insert into conversation_participants (conversation_id, user_id) values (conv_id, user_a);
    insert into conversation_participants (conversation_id, user_id) values (conv_id, user_b);
  end if;

  return conv_id;
end;
$$ language plpgsql;
```

### Optimized Queries

#### Conversation List with Latest Item and Unread Count

```sql
with user_convos as (
  select
    c.id,
    c.type,
    c.updated_at,
    cp.last_read_at,
    cp.muted
  from conversations c
  join conversation_participants cp on cp.conversation_id = c.id
  where cp.user_id = $current_user_id
  order by c.updated_at desc
  limit 50
),
latest_items as (
  select distinct on (ti.conversation_id)
    ti.conversation_id,
    ti.type as item_type,
    ti.text_content,
    ti.sender_id,
    ti.created_at as item_time
  from thread_items ti
  where ti.conversation_id in (select id from user_convos)
  order by ti.conversation_id, ti.created_at desc
),
unread_counts as (
  select
    ti.conversation_id,
    count(*) as unread
  from thread_items ti
  join user_convos uc on uc.id = ti.conversation_id
  where ti.sender_id != $current_user_id
    and ti.created_at > uc.last_read_at
  group by ti.conversation_id
)
select
  uc.*,
  li.item_type,
  li.text_content,
  li.sender_id as last_sender_id,
  li.item_time,
  coalesce(urc.unread, 0) as unread_count
from user_convos uc
left join latest_items li on li.conversation_id = uc.id
left join unread_counts urc on urc.conversation_id = uc.id
order by uc.updated_at desc;
```

#### Paginated Thread Loading

```sql
select
  ti.*,
  u.display_name as sender_name,
  u.color_hex as sender_color,
  u.profile_image_url as sender_avatar,
  d.image_url as doodle_url
from thread_items ti
join users u on u.id = ti.sender_id
left join doodles d on d.id = ti.doodle_id
where ti.conversation_id = $conversation_id
  and ti.created_at < $cursor  -- for "load older"
order by ti.created_at desc
limit 30;
```

### Client Architecture (SwiftData)

```swift
// Local models mirroring server schema
@Model
class LocalConversation {
    @Attribute(.unique) var id: UUID
    var type: String  // "direct" or "group"
    var updatedAt: Date
    var lastReadAt: Date
    var muted: Bool
    var unreadCount: Int

    @Relationship var participants: [LocalUser]
    @Relationship(deleteRule: .cascade) var items: [LocalThreadItem]
}

@Model
class LocalThreadItem {
    @Attribute(.unique) var id: UUID
    var conversationId: UUID
    var senderId: UUID
    var type: String  // "doodle" or "text"
    var textContent: String?
    var doodleUrl: String?
    var replyToItemId: UUID?
    var createdAt: Date
    var syncStatus: String  // "synced", "pending", "failed"
}
```

### Sync Strategy

1. **On app launch**: Load from local SwiftData immediately (instant UI)
2. **Background fetch**: Pull updates from server
3. **Merge**: Update local DB with server data
4. **UI observes**: SwiftData's @Query automatically updates views

### Optimistic Updates

When sending a message:
1. Create `LocalThreadItem` with `syncStatus = "pending"`
2. UI shows message immediately
3. Send to server in background
4. On success: update `syncStatus = "synced"`
5. On failure: update `syncStatus = "failed"`, show retry option

### Real-time Updates

```swift
// Subscribe to new items in user's conversations
let channel = supabase.realtime.channel("user_\(userId)_threads")

channel.on(.postgres_changes,
    event: .insert,
    schema: "public",
    table: "thread_items",
    filter: "conversation_id=in.(\(conversationIds.joined(separator: ",")))"
) { payload in
    // 1. Parse new thread item
    // 2. Insert into local SwiftData
    // 3. Update conversation.updated_at locally
    // 4. If conversation is open, scroll to new item
    // 5. If conversation is closed, increment unread badge
}
```

### Migration Strategy

Existing doodles need to be backfilled into conversations:

```sql
-- Migration script (run once)
-- 1. For each unique sender-recipient pair, create a conversation
-- 2. Create thread_items for each existing doodle

-- Step 1: Create conversations for existing exchanges
insert into conversations (id, type, created_at, updated_at)
select
  gen_random_uuid(),
  'direct',
  min(d.created_at),
  max(d.created_at)
from doodles d
join doodle_recipients dr on dr.doodle_id = d.id
group by least(d.sender_id, dr.recipient_id), greatest(d.sender_id, dr.recipient_id);

-- Step 2: Add participants
-- Step 3: Create thread_items pointing to existing doodles
-- (Full migration script to be written during implementation)
```

### Architecture Summary

```
┌─────────────────────────────────────────────────────────────┐
│                      SERVER (Supabase)                      │
├─────────────────────────────────────────────────────────────┤
│ conversations          - id, type, group_id, updated_at     │
│ conversation_participants - conv_id, user_id, last_read_at  │
│ thread_items           - unified timeline (doodles + text)  │
│ groups                 - id, name, created_by               │
│ group_members          - group_id, user_id                  │
│ reactions              - thread_item_id, user_id, emoji     │
│ doodles                - unchanged (referenced by items)    │
│ friendships            - add streak_count, last_doodle_at   │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ Supabase Realtime
                              │ REST API
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      CLIENT (iOS App)                       │
├─────────────────────────────────────────────────────────────┤
│ SwiftData Local Storage (offline-first)                     │
│   - LocalConversation, LocalThreadItem, etc.                │
│   - Optimistic updates with sync status                     │
│                                                             │
│ Managers                                                    │
│   - ConversationManager (replaces parts of DoodleManager)   │
│   - Handles sync, pagination, real-time subscriptions       │
│                                                             │
│ Views                                                       │
│   - HistoryView (segment: Grid | Chats)                     │
│   - ConversationListView                                    │
│   - ConversationThreadView                                  │
│   - ChatSettingsView                                        │
└─────────────────────────────────────────────────────────────┘
```

---

## Recommended Implementation Phases

### Phase 1: Conversation Threading (Foundation)
- Database migrations (conversations, conversation_participants, thread_items)
- Migration script for existing doodles
- SwiftData local models
- ConversationManager service
- History tab segment control (Grid | Chats)
- ConversationListView
- ConversationThreadView (doodles only, no text yet)
- **This is the foundation all other features build on**

### Phase 2: Text Messaging
- Text input in conversation thread
- Send text messages (create thread_items with type='text')
- Display text bubbles in thread
- Update preview text in conversation list

### Phase 3: Reactions
- Add reactions table
- Long-press gesture → reaction picker
- Display reactions on thread items
- Push notification for reactions

### Phase 4: Per-Friend Streaks
- Add streak columns to friendships table
- Calculate and update streaks on doodle send
- Display streaks in conversation list, thread header, and profile
- Streak warning indicator

### Phase 5: Groups
- Groups and group_members tables
- Group creation flow in Add Friends
- Group conversation threads
- Update Send Sheet to show groups
- Group settings/management

### Phase 6: Collaborative Drawing
- reply_to_item_id support in thread_items
- "Draw on this" action in thread/detail
- Drawing canvas with background image layer
- Reply indicator UI in thread

---

## Design Principles

1. **Preserve what works**: The drawing experience is great. Don't change it. Just improve how doodles are organized and viewed.

2. **Familiar patterns**: The new conversation UI should feel like iMessage/WhatsApp—users already know these patterns.

3. **Doodles first, text second**: If you add text, keep it minimal. The app's magic is in drawing, not typing.

4. **Progressive disclosure**: Don't overwhelm. The basic flow (draw → send → view) should stay simple. Advanced features (groups, reactions) are there when you want them.

5. **Streaks drive retention**: Make streaks visible but not annoying. They should encourage daily use without feeling punitive.

6. **Offline-first**: App should feel instant. Load from local storage first, sync in background.

7. **Scalable from day one**: Unified data model, proper indexing, efficient queries.

---

## Open Questions

_To be filled in as we dive deeper into each feature._
