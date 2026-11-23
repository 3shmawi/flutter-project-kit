# __APP_NAME__ — documentation

Start with [`../CLAUDE.md`](../CLAUDE.md) (rules + stack), then:

- [Design](design.md) — Claude Design links, tokens → code, screen checklist
- [Getting started](getting_started.md) — run the app, env files
- [Backend](backend.md) — __BACKEND_LABEL__: setup, credentials, deploys, rules
- [Release & CI/CD](release.md) — how merging to `main` ships to the stores
- [Deep links](deep_links.md)
- [Security](security.md) — what is tested and how
- [Decisions](decisions/) — why the stack looks the way it does
- [Designs](designs/) — approved specs for big features, reviewed with EGM
  ([getting started](getting_started.md) → "Design reviews")

## Features
- [App update gate](features/app_update.md)
- [Settings (language & theme)](features/settings.md)
<!-- @@if auth -->
- [Sign-in and account](features/auth.md)
<!-- @@endif -->
<!-- @@if paywall -->
- [Premium (paid features)](features/paywall.md)
<!-- @@endif -->
