# Squibble App Store Submission Guide

**Goal: Submit to App Store TODAY**

All technical setup is complete. This guide covers only what remains.

---

## STEP 1: Legal & Support Pages (30 mins)

You need 3 URLs before submitting:

### 1.1 Privacy Policy
- [x] Create privacy policy covering:
  - Data collected: email, name, profile photo, doodles, device token for push notifications
  - Purpose: app functionality, friend connections, notifications
  - Third parties: Supabase (database), Google AdMob (ads for free users)
  - Data deletion: users can delete account in Settings
  - Contact info
- [x] Host at a public URL

**Quick option:** Use a free privacy policy generator like [TermsFeed](https://www.termsfeed.com/privacy-policy-generator/) or [Iubenda](https://www.iubenda.com/)

**Host at:** GitHub Pages, Notion public page, or any free hosting

### 1.2 Terms of Service
- [x] Create terms of service covering:
  - User responsibilities (don't send inappropriate content)
  - Account termination rights
  - Subscription terms
  - Limitation of liability
- [x] Host at a public URL

**Quick option:** Use same generators above, or write a simple one-pager

### 1.3 Support URL
- [x] Create support page or set up support email

Options (pick one):
- Simple webpage with FAQ + contact email
- Just an email link: `mailto:support@youremail.com`
- Notion page with help content

**Support email:** Set up `support@squibble.app` or use your personal email

---

## STEP 2: App Store Assets (1-2 hours)

### 2.1 App Icon
- [x] Create 1024x1024 PNG (no transparency, no rounded corners - Apple adds them)
- [x] Add to Xcode Assets.xcassets → AppIcon

**Quick option:** Use Figma, Canva, or hire someone on Fiverr for $20

### 2.2 Screenshots (Required)
Minimum required:
- **iPhone 6.7" display** (1290 x 2796) - iPhone 15 Pro Max
- **iPhone 6.5" display** (1284 x 2778) - iPhone 14 Plus

Capture these screens:
- [x] Home screen with drawing canvas
- [x] Drawing in progress with colors
- [x] Send sheet with friends selected
- [x] History grid with doodles
- [x] Profile screen with activity calendar

**Quick method:**
1. Run app on iPhone 15 Pro Max simulator
2. Cmd+S to take screenshots
3. Screenshots save to Desktop

### 2.3 App Preview Video (Optional)
- [x] Create app preview video (SKIP - can add later)

---

## STEP 3: Pre-Upload Checklist (15 mins)

In Xcode:

### 3.1 Version & Build
- [x] Select squibble target → General
- [x] Set Version: `1.0.0`
- [x] Set Build: `1`

### 3.2 Production Config
Open `squibble/Utilities/Config.swift` and verify:
- [x] Supabase URL and key are correct
- [x] AdMob IDs are production (not test IDs)
- [x] Google Client ID is correct

### 3.3 Set Production APNs
- [x] Run in Terminal:
```bash
cd ~/Documents/Solopreneurship/Squibble/squibble
supabase secrets set APNS_PRODUCTION=true
```

### 3.4 Final Build Test
- [x] Connect your iPhone
- [x] Build and run on device
- [x] Quick test: sign in, draw, send works

---

## STEP 4: Archive & Upload (30 mins)

### 4.1 Archive
- [x] In Xcode: Product → Destination → Any iOS Device (arm64)
- [x] Product → Archive
- [x] Wait for archive to complete (5-10 mins)

### 4.2 Upload
- [x] Organizer window opens automatically
- [x] Select your archive → Distribute App
- [x] Choose: App Store Connect → Upload
- [x] Let Xcode manage signing
- [x] Click Upload
- [x] Wait for upload (5-10 mins)

### 4.3 Wait for Processing
- [x] Go to App Store Connect → TestFlight
- [x] Build appears as "Processing" - wait 15-30 minutes
- [x] Receive email when processing complete

---

## STEP 5: App Store Connect Listing (30 mins)

Go to [App Store Connect](https://appstoreconnect.apple.com) → Your App → App Store

### 5.1 App Information (left sidebar)
- [x] Name: `Squibble`
- [x] Subtitle: `Draw & Share Doodles`
- [x] Category: Social Networking
- [x] Secondary Category: Entertainment
- [x] Content Rights: "This app does not contain third-party content"

### 5.2 Pricing and Availability
- [x] Price: Free
- [x] Availability: All countries (or select specific ones)

### 5.3 App Privacy
- [x] Click "Get Started" and fill out the privacy questionnaire:

**Data Types Collected:**
| Type | Collected? | Linked to User? | Tracking? |
|------|------------|-----------------|-----------|
| Email | Yes | Yes | No |
| Name | Yes | Yes | No |
| Photos (profile) | Yes | Yes | No |
| User ID | Yes | Yes | No |
| Device ID | Yes | No | No |
| Advertising Data | Yes (AdMob) | No | Yes |

### 5.4 Version Information (iOS App section)
- [x] Screenshots: Upload for 6.7" and 6.5" displays
- [x] Promotional Text: `Send quick doodles to friends! They appear on their home screen widget.`
- [x] Description:
```
Squibble is a fun way to stay connected with friends through doodles!

HOW IT WORKS
• Draw a quick doodle on the canvas
• Send it to friends
• They see it on their home screen widget
• They can reply with their own doodle

FEATURES
• Simple drawing canvas with colors and brush sizes
• Send doodles to multiple friends
• Home screen widget shows latest doodle
• View sent and received doodle history
• Reply to doodles with one tap
• Activity calendar tracks your streak

PREMIUM (Optional)
• Draw on uploaded images
• Unlimited friends (free: 30 limit)
• Ad-free experience

Download and start doodling with friends!
```
- [x] Keywords: `doodle,drawing,friends,widget,sketch,social,messaging,creative,art,fun`
- [x] Support URL: Your support page URL
- [x] Marketing URL: (optional, leave blank)
- [x] Build: Select your uploaded build

### 5.5 Age Rating
- [x] Fill out questionnaire - Squibble should qualify for **4+**:
  - All violence questions: None
  - All mature content questions: None
  - Unrestricted Web Access: No
  - Gambling: No

### 5.6 App Review Information
- [x] Enter contact info (your name, phone, email)
- [x] Sign-In Required: Yes
- [x] Create demo account in app:
```
Email: reviewer@test.com
Password: TestPassword123
```
- [x] Enter demo account credentials in App Store Connect
- [x] Add notes for reviewer:
```
Squibble lets users draw and send doodles to friends.

TO TEST:
1. Sign in with the demo account above
2. Draw on the canvas and tap Send
3. To test with friends: Tap "Add Friends" and use invite code: [YOUR_TEST_CODE]
4. Widget: Add the Squibble widget to home screen

Note: Push notifications require a physical device.
```

---

## STEP 6: Submit for Review (5 mins)

- [x] Review all sections are complete (green checkmarks)
- [x] Click "Add for Review"
- [x] Answer export compliance question: **No** (app doesn't use encryption beyond HTTPS)
- [x] Answer advertising identifier question: **Yes** (AdMob uses it)
- [x] Click "Submit to App Review"

---

## STEP 7: After Submission

### What Happens Next
- [ ] Wait for review (24-48 hours typically)
- [ ] Check email for status updates

### If Rejected
- [ ] Read rejection reason carefully
- [ ] Fix the issue
- [ ] Reply in Resolution Center
- [ ] Resubmit

### If Approved
- [ ] Release the app (if you chose "Manually release")
- [ ] Celebrate!

---

## Quick Reference

| Item | Value |
|------|-------|
| Bundle ID | `com.mehulpandey.squibble` |
| Widget Bundle ID | `com.mehulpandey.squibble.SquibbleWidget` |
| Monthly Product ID | `com.squibble.premium.monthly` |
| Annual Product ID | `com.squibble.premium.annual` |
| AdMob App ID | `ca-app-pub-8866277760401021~5069811424` |
| AdMob Banner ID | `ca-app-pub-8866277760401021/3265775167` |

---

## Today's Checklist Summary

- [x] Create & host Privacy Policy page
- [x] Create & host Terms of Service page
- [x] Create & host Support page (or just use email)
- [x] Create app icon (1024x1024)
- [x] Take screenshots (6.7" and 6.5" iPhone sizes)
- [x] Set APNS_PRODUCTION=true in Supabase
- [x] Archive and upload build
- [x] Create demo account for reviewer
- [x] Fill out App Store Connect listing
- [x] Submit for review

**Estimated time: 3-4 hours total**
