// Deletes the calling user's account (Apple and Google require in-app
// account deletion). Rows that reference auth.users with `on delete
// cascade` go with it; delete files in Storage here too if the app keeps any.
//
// Called by the app with the user's session (supabase.functions.invoke).
// The platform checks the JWT (verify_jwt, the default); this function
// checks it again with the Auth server and only ever deletes that user.
// Deployed on merge by .github/workflows/supabase.yml.
import { createClient } from "npm:@supabase/supabase-js@2.118.0";

const json = (body: unknown, status: number) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

/** The project's secret key: the new `sb_secret_…` key, or the legacy service role key. */
function secretKey(): string {
  const keys = Deno.env.get("SUPABASE_SECRET_KEYS");
  if (keys) {
    const parsed = JSON.parse(keys) as Record<string, string>;
    if (parsed.default) return parsed.default;
  }
  const legacy = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!legacy) throw new Error("no secret key available");
  return legacy;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  if (!token) return json({ error: "unauthorized" }, 401);

  const admin = createClient(Deno.env.get("SUPABASE_URL")!, secretKey(), {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data, error } = await admin.auth.getUser(token);
  if (error || !data.user) return json({ error: "unauthorized" }, 401);

  const { error: deleteError } = await admin.auth.admin.deleteUser(data.user.id);
  if (deleteError) {
    // No user id or email in logs.
    console.error("delete-account failed:", deleteError.status ?? "", deleteError.code ?? "");
    return json({ error: "delete_failed" }, 500);
  }
  return json({ deleted: true }, 200);
});
