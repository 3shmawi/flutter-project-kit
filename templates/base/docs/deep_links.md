# Deep links

Routing uses go_router; every route in `lib/core/router/app_routes.dart` is
also a deep link.

| Path | Screen |
|---|---|
| `/` | Home |
| `/settings` | Settings |

## Custom scheme (works now)
`__SCHEME__://settings` — test with:
```bash
adb shell am start -a android.intent.action.VIEW -d "__SCHEME__://settings"
xcrun simctl openurl booted "__SCHEME__://settings"
```

## https links (App Links / Universal Links)
Host: `__DEEPLINK_DOMAIN__`. Needs, once:
1. The website served from that domain (root), including
   `website/.well-known/assetlinks.json` and
   `website/.well-known/apple-app-site-association`.
2. `assetlinks.json`: replace the SHA-256 with Play Console → Setup →
   App signing → "App signing key certificate" fingerprint.
3. `apple-app-site-association`: check the Team ID (`__APPLE_TEAM_ID__`).
4. Apple Developer → Identifiers → `__PACKAGE_ID__` → enable
   **Associated Domains** (then CI regenerates the profile).

If no domain was chosen at creation, add later: intent filter in
`AndroidManifest.xml` (`android:autoVerify="true"`, scheme https) and
`ios/Runner/Runner.entitlements` with `applinks:<domain>`.
