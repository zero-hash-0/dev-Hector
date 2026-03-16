# Opus iOS — Xcode Setup Guide

Get from these Swift files to TestFlight in ~15 minutes.

---

## Prerequisites
- Xcode 16+ installed
- Apple Developer account ($99/yr) — needed for TestFlight
- App registered in [App Store Connect](https://appstoreconnect.apple.com) (or create one now)

---

## Step 1 — Create the Xcode Project

1. Open Xcode → **File → New → Project**
2. Choose **iOS → App** → Next
3. Fill in:
   - **Product Name:** `Opus`
   - **Bundle Identifier:** `com.opus.betaapp` (or your own — must match App Store Connect)
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Uncheck** "Include Tests" (not needed for beta)
4. Save it somewhere convenient (e.g. `~/Developer/OpusiOS/`)

---

## Step 2 — Replace the Source Files

1. In Xcode's file navigator, **delete** the generated `ContentView.swift` (Move to Trash)
2. Drag all 5 files from `ios/Opus/` into the Xcode navigator:
   - `OpusApp.swift`
   - `ContentView.swift`
   - `OpusWebView.swift`
   - `LaunchScreen.swift`
   - `OfflineView.swift`
3. When prompted: ✅ **Copy items if needed**, ✅ **Add to target: Opus**

---

## Step 3 — Configure the Project

### Signing
1. Select the **Opus** project in the navigator (top item)
2. Go to **Signing & Capabilities** tab
3. Set **Team** to your Apple Developer account
4. Bundle ID should match what you registered in App Store Connect

### Deployment Target
- Set **Minimum Deployments** to **iOS 16.0**

### Status Bar (Light Content)
Add these keys to `Info.plist`:
```xml
<key>UIStatusBarStyle</key>
<string>UIStatusBarStyleLightContent</string>
<key>UIViewControllerBasedStatusBarAppearance</key>
<false/>
<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
</array>
```

Or in the project editor: **Info** tab → add rows manually.

### App Icon
- Replace the placeholder in `Assets.xcassets → AppIcon`
- Minimum: provide a 1024×1024 PNG for the App Store icon
- Use the Opus `◉` mark on `#0F0E11` background with amber color

---

## Step 4 — Update Vercel Environment Variable

The iOS app injects cookie `opus_invite=OPUS-BETA-IOS` to bypass the web gate.
You need to add `OPUS-BETA-IOS` to the allowed invite codes on Vercel:

1. Go to [Vercel Dashboard](https://vercel.com) → your project → **Settings → Environment Variables**
2. Find `NEXT_PUBLIC_BETA_INVITE_CODES`
3. Append `,OPUS-BETA-IOS` to the existing list
4. **Redeploy** (Deployments → Redeploy latest) for the change to take effect

---

## Step 5 — Build & Test

```
Product → Run (⌘R)
```

In Simulator:
- ✅ Launch screen (amber ◉ pulse) appears
- ✅ App loads `/opus/app` directly — no invite code prompt
- ✅ Pull down to refresh works (amber spinner)
- ✅ Tap a hypothetical external link → Safari opens

On Device:
- Connect iPhone → select it as destination → ⌘R
- First run may require trusting the dev certificate in iOS Settings

---

## Step 6 — Archive for TestFlight

1. Set destination to **Any iOS Device (arm64)** (not a simulator)
2. **Product → Archive** — takes ~1 min
3. Organizer opens automatically → **Distribute App**
4. Choose **TestFlight & App Store** → Next → Upload
5. Wait ~5 min for processing

---

## Step 7 — Add Testers in App Store Connect

1. [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → your app → **TestFlight**
2. **Internal Testing** → add up to 100 testers by Apple ID
3. **External Testing** → submit for Beta App Review (usually < 24h) → add unlimited testers
4. Testers get an email with TestFlight install link

---

## Updating the App

When the web app updates (no native code changes needed — it's a WKWebView), users automatically get the latest. No new TestFlight build required.

For native code changes (new features, UI tweaks):
1. Edit Swift files → bump version in project settings
2. Archive → Distribute → new TestFlight build

---

## Production URL

The app currently loads:
```
https://unruffled-chaum.vercel.app/opus/app
```

When you get a custom domain (e.g. `app.opus.so`), update `appURL` in `OpusWebView.swift` and `inviteDomain` accordingly.
