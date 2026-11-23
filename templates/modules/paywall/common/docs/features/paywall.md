# Feature: Premium (paid features, RevenueCat)

## What it does
- **Paywall** (`/premium`, Settings → Premium): the plans of the current
  RevenueCat offering with the store's localized price, yearly selected
  first, **Continue** (buy), **Restore purchases**, the auto-renewal terms,
  Terms of use and Privacy policy (Apple guideline 3.1.2 and Google Play
  billing policy require all of these on the paywall).
- **Premium state** everywhere: `Premium.active` (a `ValueNotifier<bool>`)
  follows the `premium` entitlement. Wrap premium-only UI in
  `PremiumGate(child: …)`; free users see a card that opens the paywall.
- **Settings**: a Premium row (Active / Upgrade) and Restore purchases.
<!-- @@if auth -->
- **With sign-in:** RevenueCat's user is the signed-in user id
  (`Purchases.logIn`), so purchases follow the account across devices;
  signing out goes back to an anonymous RevenueCat user.
<!-- @@endif -->

## Architecture
- `lib/core/purchases/purchases.dart` — `PurchasesService` (store-neutral),
  `Premium`, `PaywallPlan`, `UnconfiguredPurchasesService` (no key in the
  env file → nothing for sale, nobody premium).
- `lib/core/purchases/revenuecat_purchases.dart` — RevenueCat
  (`purchases_flutter`). Store errors map to
  `PurchaseFailure(PurchaseFailureReason.x)`; a closed store sheet
  (`cancelled`) shows nothing, a `pending` purchase (Ask to Buy, slow card)
  says it unlocks later.
- `lib/core/purchases/premium_gate.dart` — `PremiumGate`, `PremiumLockedCard`.
- `lib/features/paywall/presentation/` — `PaywallPage` (loads plans,
  buys, restores) and `PaywallView` (pure UI).

## Set up
Check RevenueCat's, Apple's and Google's current docs while you do this;
note the date in this file.

1. **Stores** — create the products:
   - App Store Connect → the app → Monetization → Subscriptions: a
     subscription group with the plans (e.g. monthly, yearly), prices,
     and their localized names in English and Arabic. Agreements, Tax and
     Banking must be active (Business). Add an **App Store Connect API
     in-app purchase key** for RevenueCat.
   - Play Console → Monetize with Play → Products → Subscriptions: the same
     plans. Google needs one uploaded build with the billing permission
     first (any build of this app has it). Give RevenueCat's service
     account access (RevenueCat's guide "Google Play service credentials").
2. **RevenueCat** (app.revenuecat.com) → a project with an App Store and a
   Play Store app → **Entitlements**: `premium` (the id in
   `Premium.entitlement`) with every product attached → **Offerings**:
   a `default` offering, current, with packages (`$rc_monthly`,
   `$rc_annual`, …).
3. **Keys** → Project settings → API keys: the *public* app-specific SDK
   keys (`appl_…`, `goog_…`) go in `env/<flavor>.json` as
   `REVENUECAT_APPLE_API_KEY` and `REVENUECAT_GOOGLE_API_KEY`. They are
   public by design. Never put a RevenueCat **secret** key (`sk_…`) in the
   app or env files.
4. **Testing:** iOS — a Sandbox account (App Store Connect → Users and
   Access → Sandbox) or a StoreKit configuration file; Android — add your
   Google account under Play Console → Settings → License testing, and
   install from an internal-testing track.
5. **Store listing:** the App Store description must say what's included,
   the price and length of each subscription, and link the Terms of use
   (or Apple's standard EULA) and privacy policy. Fill the Play
   **App content → Content rating → Digital purchases** answer (already
   "Yes" in `store/play_app_content.json`).

## Things to know
- `Premium.active` is for showing and hiding UI. Content that must stay
  private needs a server check too: RevenueCat webhooks or its REST API
  (with the secret key, on the server only) can set an `is_premium` flag
  your backend rules read.
- Prices always come from the store (`priceString`), never hard-coded:
  they are localized and change per country.
- Restore is on the paywall and in Settings; Apple rejects apps without it.

## Tests
- `test/features/paywall/presentation/paywall_page_test.dart` — plans and
  prices, default plan, buy, cancelled, pending, restore, load failure +
  retry, RTL, accessibility (`FakePurchasesService` in `test/helpers/`).
- `test/core/purchases/premium_gate_test.dart`.
- Integration: `integration_test/paywall_test.dart` (settings → paywall).

## Analytics events
| Event | Properties |
|---|---|
| `paywall_viewed` | — |
| `purchase_completed` | `plan`: `weekly`, `monthly`, `annual`, `lifetime`, `other` |
| `purchase_failed` | `plan` |
| `purchases_restored` | — |

## Demo & post
- Hook: "Premium in two taps — and Restore is always one tap away."
- Scenario: `integration_test/paywall_test.dart`.
