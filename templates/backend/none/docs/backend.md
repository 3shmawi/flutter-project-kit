# Backend — none in this repo

<!-- @@if api -->
The app's data lives behind **your REST API**: the contract is
`api/openapi.yaml`, the client is generated into `lib/core/api/gen/`, and
feature data sources call it through `ApiClient.api` inside `guard()`
(docs/features/api.md). There is no Supabase or Firebase project, no
database rules here and nothing to deploy from this repo — your API is
deployed on its own.

## Env keys (`env/<name>.json`)
| Key | Value |
|---|---|
| `API_BASE_URL` | `https://…` per environment (dev / staging / prod) |

## What your API provides
| Endpoint | Used by |
|---|---|
| `GET /app-versions/{platform}` (public) | the version-update gate (docs/features/app_update.md) |
<!-- @@if auth -->
| `/auth/*`, `/me` | sign-in, session refresh, sign-out, account deletion (docs/features/auth.md) |
<!-- @@endif -->
| your endpoints | features |

## Rules
Access control is your API's job: check on every endpoint that the
token's user may read or change the data, validate input, rate-limit. The
app's own checks are for UX only.
<!-- @@else -->
The app keeps its data on the device (SharedPreferences for settings).
There is no server, so there's nothing to configure or deploy, and the
version-update gate is off.

Need a server later?
- your own REST API: `scripts/add_module.sh api` (Dio client generated
  from an OpenAPI spec, docs/features/api.md);
- Supabase or Firebase: create a new project with the kit and move the
  features over (switching backends in place isn't automatic).
<!-- @@endif -->
