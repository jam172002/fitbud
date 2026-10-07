// Admin-only: create the login for a gym owner (replaces the Firebase
// `createGymWithOwner` callable). The admin panel then creates the gym row with
// `owner_uid` set to the returned id; the gym panel signs the owner in with
// the email + temporary password and finds their gym through that column.
import { createClient } from "npm:@supabase/supabase-js@2";
import { corsHeaders, json } from "../_shared/cors.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader) return json({ error: "unauthenticated" }, 401);

  const userClient = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false },
  });
  const { data: caller, error: callerErr } = await userClient.auth.getUser();
  if (callerErr || !caller.user) return json({ error: "unauthenticated" }, 401);
  if (caller.user.app_metadata?.admin !== true) {
    return json({ error: "permission_denied", message: "Admins only" }, 403);
  }

  const body = await req.json().catch(() => ({}));
  const email = String(body?.email ?? "").trim().toLowerCase();
  const password = String(body?.password ?? "");
  const name = String(body?.name ?? "").trim();
  if (!email || password.length < 8) {
    return json({ error: "invalid_argument", message: "Email and a password of at least 8 characters are required" }, 400);
  }

  const admin = createClient(SUPABASE_URL, SERVICE_KEY, { auth: { persistSession: false } });
  const { data, error } = await admin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: { display_name: name },
    app_metadata: { role: "gymOwner" },
  });
  if (error || !data.user) {
    const exists = /already|registered|exists/i.test(error?.message ?? "");
    return json(
      { error: exists ? "already_exists" : "internal", message: exists ? "Email already used" : (error?.message ?? "Could not create owner") },
      exists ? 409 : 500,
    );
  }

  return json({ ok: true, ownerUid: data.user.id });
});
