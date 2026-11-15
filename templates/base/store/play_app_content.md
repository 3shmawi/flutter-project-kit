# Google Play: App content answers (إعداد تطبيقك)

Copy these into **Play Console → Policy and programs → App content**
(«محتوى التطبيق») and **Store settings**, screen by screen. Google Play has
no API for these forms (only Data safety and the contact details have one),
so they are filled by hand once, and again when the app changes in a way a
form asks about.

**Agent:** fill every `TODO` from the code before the first release, the
same way as the store texts: describe only what the prod app does today
(check the feature flags), and say when you checked. Update this file
whenever the app starts collecting new data or adds ads, sign-in, payments
or health features. Checked: TODO (date).

## 1. Privacy policy (سياسة الخصوصية)
- **URL:** `__WEBSITE_URL__/privacy`

## 2. App access (تفاصيل تسجيل الدخول)
- **Answer:** TODO: "All functionality is available without special
  access" when nothing needs an account or a code; otherwise "All or some
  functionality is restricted" with the steps and a demo account or code
  below.
- **Instructions for the reviewer:** TODO (what to tap first, and where the
  demo username / password / code goes; make sure the demo access still
  works before each review).

## 3. Ads (الإعلانات)
- **Does your app contain ads?** TODO: No (the kit adds no ad SDK).
- **Advertising ID:** TODO: No, unless an SDK adds
  `android.permission.AD_ID` to the merged manifest (check it once).

## 4. Content rating (تقييم المحتوى)
- **Email:** `__SUPPORT_EMAIL__`
- **Category:** TODO (usually "All other app types"; "Game" for games).
- **Violence, fear, sexuality, gambling, language, controlled substances,
  crude humour:** TODO (No for each, unless the app shows any of it).
- **Users can interact or exchange content:** TODO (Yes only with chat,
  posts or shared profiles).
- **Shares the user's location:** TODO
- **Digital purchases:** TODO
- **Unrestricted internet access (a browser):** TODO

## 5. Target audience (الجمهور المستهدف)
- **Age groups:** TODO (owner's decision; under 13 brings Google's Families
  policy).
- **Appeals to children:** TODO

## 6. Data safety (أمان البيانات)
List everything that leaves the phone (backend, analytics, monitoring, any
SDK), from the code and each SDK's own data-disclosure page:

| Category → data type | Collected | Shared | Ephemeral | Required / optional | Purposes |
|---|---|---|---|---|---|
| TODO | | | | | |

- **Encrypted in transit:** TODO (Yes: everything goes over HTTPS).
- **Users can ask for their data to be deleted:** TODO (Yes when the app has
  accounts: in the app, and `__WEBSITE_URL__/delete-account`).
- Check the analytics and monitoring dashboards for IP or location settings
  first (PostHog "Discard client IP data", Sentry "Prevent storing of IP
  addresses"); if they stay on, declare approximate location too.

## 7. Government apps (التطبيقات الحكومية)
- **Answer:** TODO: No, unless the app is made by or for a government.

## 8. Financial features (الميزات المالية)
- **Answer:** TODO: "My app doesn't provide any financial features", unless
  it does.

## 9. Health (صحة)
- **Answer:** TODO: the health features it has (for example "Activity and
  fitness"), or none.

## 10. App category and contact details (اختيار فئة التطبيق وتقديم تفاصيل الاتصال)
- **App or game:** TODO
- **Category:** TODO
- **Email:** `__SUPPORT_EMAIL__`
- **Website:** `__WEBSITE_URL__`
- **Phone:** optional.

## 11. Store listing
Done from the repo: `store/android/` → Actions → **Store listing**.
