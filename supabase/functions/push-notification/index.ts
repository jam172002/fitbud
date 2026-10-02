// Sends an FCM push for every new row in public.notifications.
//
// Triggered by the `notifications_push_trg` database trigger (pg_net) with the
// shared secret from Vault in the `x-webhook-secret` header. FCM delivery via
// the HTTP v1 API is free (it does NOT require the Firebase Blaze plan); this
// function only needs a Firebase service-account key.
//
// Secrets (supabase secrets set ...):
//   PUSH_WEBHOOK_SECRET        same value as Vault secret `push_webhook_secret`
//   FIREBASE_SERVICE_ACCOUNT   the service-account JSON, as one string
import { createClient } from "npm:@supabase/supabase-js@2";
import { importPKCS8, SignJWT } from "npm:jose@5";
import { json } from "../_shared/cors.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const WEBHOOK_SECRET = Deno.env.get("PUSH_WEBHOOK_SECRET") ?? "";

const sa = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT") ?? "{}");

let cachedToken: { value: string; exp: number } | null = null;

async function accessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.exp - 60 > now) return cachedToken.value;

  const key = await importPKCS8(sa.private_key, "RS256");
  const assertion = await new SignJWT({ scope: "https://www.googleapis.com/auth/firebase.messaging" })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(sa.client_email)
    .setSubject(sa.client_email)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(key);

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!res.ok) throw new Error(`token exchange failed: ${res.status} ${await res.text()}`);
  const body = await res.json();
  cachedToken = { value: body.access_token, exp: now + (body.expires_in ?? 3600) };
  return cachedToken.value;
}

async function send(token: string, title: string, body: string, data: Record<string, string>) {
  const res = await fetch(`https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${await accessToken()}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      message: {
        token,
        notification: { title, body },
        data,
        android: { priority: "HIGH" },
        apns: { payload: { aps: { sound: "default" } } },
      },
    }),
  });
  return { ok: res.ok, status: res.status, text: res.ok ? "" : await res.text() };
}

Deno.serve(async (req) => {
  if (!WEBHOOK_SECRET || req.headers.get("x-webhook-secret") !== WEBHOOK_SECRET) {
    return json({ error: "forbidden" }, 403);
  }
  if (!sa.private_key) return json({ skipped: "FIREBASE_SERVICE_ACCOUNT not configured" });

  const { record } = await req.json();
  if (!record?.user_id) return json({ skipped: "no record" });

  const admin = createClient(SUPABASE_URL, SERVICE_KEY, { auth: { persistSession: false } });
  const { data: profile } = await admin
    .from("profiles").select("fcm_tokens").eq("id", record.user_id).maybeSingle();
  const { data: settings } = await admin
    .from("user_settings").select("push_enabled").eq("user_id", record.user_id).maybeSingle();

  if (settings && settings.push_enabled === false) return json({ skipped: "push disabled by user" });

  const tokens: string[] = profile?.fcm_tokens ?? [];
  if (tokens.length === 0) return json({ skipped: "no device tokens" });

  const data: Record<string, string> = { type: String(record.type ?? "") };
  for (const [k, v] of Object.entries(record.data ?? {})) data[k] = String(v);

  const dead: string[] = [];
  for (const t of tokens) {
    const r = await send(t, record.title ?? "", record.body ?? "", data);
    // UNREGISTERED / INVALID_ARGUMENT => the token is stale; prune it.
    if (!r.ok && (r.status === 404 || r.status === 400)) dead.push(t);
    else if (!r.ok) console.error(`FCM send failed for ${record.user_id}:`, r.status, r.text);
  }
  if (dead.length) {
    await admin.from("profiles")
      .update({ fcm_tokens: tokens.filter((t) => !dead.includes(t)) })
      .eq("id", record.user_id);
  }
  return json({ ok: true, sent: tokens.length - dead.length, pruned: dead.length });
});
