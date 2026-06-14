// GymLog · account-deletion Edge Function (Deno)
// ---------------------------------------------------------------------------
// Completely deletes the CALLER's account: their synced data (`sync_objects`),
// their profile row (`profiles`), and their auth identity (`auth.users`).
//
// Only the service role can delete an `auth.users` row, so this MUST run as an
// Edge Function — the mobile client and the web page both call it with the
// signed-in user's JWT, and the function verifies that JWT before purging.
//
// Deploy:
//   supabase functions deploy delete-account --no-verify-jwt
//   (we verify the JWT ourselves so the same endpoint works from the web page)
//
// Required function secrets (auto-present in Supabase, but set if self-hosting):
//   SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY
//
// Invoked from the app via:  supabase.functions.invoke('delete-account')
// Invoked from the web page via fetch() with the user's access token.
// ---------------------------------------------------------------------------

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ error: "method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return json({ error: "missing Authorization header" }, 401);

  const url = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  // 1. Identify the caller from THEIR JWT (ownership verification).
  const userClient = createClient(url, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user }, error: userErr } = await userClient.auth.getUser();
  if (userErr || !user) return json({ error: "invalid session" }, 401);
  const uid = user.id;

  // 2. Purge with the service role. profiles + sync_objects both FK
  //    auth.users ON DELETE CASCADE, so deleting the auth user alone would
  //    cascade — but we delete explicitly first so the function is correct
  //    even if a deployment forgot the cascade.
  const admin = createClient(url, serviceKey);

  const { error: syncErr } = await admin
    .from("sync_objects")
    .delete()
    .eq("user_id", uid);
  if (syncErr) return json({ error: `sync purge failed: ${syncErr.message}` }, 500);

  const { error: profErr } = await admin
    .from("profiles")
    .delete()
    .eq("id", uid);
  if (profErr) return json({ error: `profile purge failed: ${profErr.message}` }, 500);

  const { error: authErr } = await admin.auth.admin.deleteUser(uid);
  if (authErr) return json({ error: `auth delete failed: ${authErr.message}` }, 500);

  return json({ ok: true, deleted: uid }, 200);
});
