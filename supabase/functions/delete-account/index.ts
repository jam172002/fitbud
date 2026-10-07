// Account deletion - the single trusted place where a user's data is removed.
// Called by the Flutter app (Settings > Delete Account) and by the public web
// deletion page (public/delete-account).
//
// Design (carried over from the Firebase accountDeletion.ts):
//  * The `profiles` row is NOT hard-deleted: it is overwritten with a
//    de-identified tombstone ("Deleted User") so old messages / groups /
//    sessions still resolve a name instead of a missing row.
//  * Wholly personal rows (settings, addresses, notifications, inbox, blocks,
//    memberships) are deleted outright.
//  * Messages the user wrote are redacted in place (kept for the other
//    participants' history).
//  * Sessions the user created are deleted only if nobody else joined.
//  * Buddy requests / friendships / gym check-ins are hard-deleted.
//  * Payment records (`subscriptions`, `transactions`) are deliberately left
//    untouched - confirm a retention period with your accountant/legal.
//  * The auth user is deleted LAST, only after every data step succeeded, so a
//    failed step never leaves someone locked out of an account that still has
//    data in it. Every step is safe to re-run (idempotent).
import { createClient, SupabaseClient } from "npm:@supabase/supabase-js@2";
import { corsHeaders, json } from "../_shared/cors.ts";

const REAUTH_MAX_AGE_MINUTES = 15;

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

type Step =
  | "storageProfile"
  | "storageChatMedia"
  | "messagesRedacted"
  | "conversationMemberships"
  | "groupMemberships"
  | "groupInvites"
  | "sessionInvites"
  | "sessionParticipants"
  | "ownedSessions"
  | "buddyRequests"
  | "friendships"
  | "gymScans"
  | "userData"
  | "profileTombstoned"
  | "authUserDeleted";

async function must<T>(p: PromiseLike<{ data?: T; error: { message: string } | null }>): Promise<T | undefined> {
  const { data, error } = await p;
  if (error) throw new Error(error.message);
  return data;
}

async function removeFolder(admin: SupabaseClient, bucket: string, prefix: string) {
  // Storage has no recursive delete: list (paginated) then remove.
  const paths: string[] = [];
  const walk = async (dir: string) => {
    let offset = 0;
    while (true) {
      const { data, error } = await admin.storage.from(bucket).list(dir, { limit: 100, offset });
      if (error) throw new Error(error.message);
      if (!data || data.length === 0) break;
      for (const item of data) {
        const full = dir ? `${dir}/${item.name}` : item.name;
        if (item.id === null) await walk(full); // folder
        else paths.push(full);
      }
      if (data.length < 100) break;
      offset += 100;
    }
  };
  await walk(prefix);
  for (let i = 0; i < paths.length; i += 100) {
    await must(admin.storage.from(bucket).remove(paths.slice(i, i + 100)));
  }
}

async function runPipeline(admin: SupabaseClient, uid: string) {
  const mark = async (step: Step) => {
    const { data } = await admin.from("account_deletions").select("steps").eq("user_id", uid).maybeSingle();
    const steps = { ...(data?.steps ?? {}), [step]: "done" };
    await admin.from("account_deletions").update({ steps }).eq("user_id", uid);
  };

  // 1) Storage: profile photo folder.
  await removeFolder(admin, "avatars", `users/${uid}`);
  await mark("storageProfile");

  // 2) Storage: chat media this user uploaded ({conversationId}/{uid}/...).
  const { data: inbox } = await admin.from("inbox").select("conversation_id").eq("user_id", uid);
  const { data: parts } = await admin.from("conversation_participants").select("conversation_id").eq("user_id", uid);
  const convIds = [...new Set([...(inbox ?? []), ...(parts ?? [])].map((r) => r.conversation_id as string))];
  for (const cid of convIds) await removeFolder(admin, "chat-media", `${cid}/${uid}`);
  await mark("storageChatMedia");

  // 3) Redact authored messages.
  await must(admin.from("messages").update({
    text: "", media_url: "", thumbnail_url: "", is_deleted: true,
  }).eq("sender_user_id", uid));
  await mark("messagesRedacted");

  // 4) Leave every conversation + drop personal inbox rows.
  await must(admin.from("conversation_participants").delete().eq("user_id", uid));
  await must(admin.from("inbox").delete().eq("user_id", uid));
  await mark("conversationMemberships");

  // 5) Leave groups; keep member_count honest.
  const { data: memberships } = await admin.from("group_members").select("group_id").eq("user_id", uid);
  await must(admin.from("group_members").delete().eq("user_id", uid));
  for (const m of memberships ?? []) {
    const { count } = await admin.from("group_members").select("*", { count: "exact", head: true }).eq("group_id", m.group_id);
    await admin.from("groups").update({ member_count: count ?? 0 }).eq("id", m.group_id);
  }
  await mark("groupMemberships");

  // 6) Group invites in both directions.
  await must(admin.from("group_invites").delete().eq("invited_user_id", uid));
  await must(admin.from("group_invites").delete().eq("invited_by_user_id", uid));
  await mark("groupInvites");

  // 7) Session invites: delete incoming, de-identify the ones this user sent.
  await must(admin.from("session_invites").delete().eq("invited_user_id", uid));
  await must(admin.from("session_invites").update({
    invited_by_name: "Deleted User", invited_by_photo_url: "",
  }).eq("invited_by_user_id", uid));
  await mark("sessionInvites");

  // 8) Session participation.
  await must(admin.from("session_participants").delete().eq("user_id", uid));
  await mark("sessionParticipants");

  // 9) Sessions they created: delete only if nobody else is left.
  const { data: owned } = await admin.from("sessions").select("id").eq("created_by_user_id", uid);
  for (const s of owned ?? []) {
    const { count } = await admin.from("session_participants").select("*", { count: "exact", head: true }).eq("session_id", s.id);
    if ((count ?? 0) === 0) await must(admin.from("sessions").delete().eq("id", s.id));
  }
  await mark("ownedSessions");

  // 10) Buddy requests (either direction) + 11) friendships.
  await must(admin.from("buddy_requests").delete().eq("from_user_id", uid));
  await must(admin.from("buddy_requests").delete().eq("to_user_id", uid));
  await mark("buddyRequests");
  await must(admin.from("friendships").delete().contains("user_ids", [uid]));
  await mark("friendships");

  // 12) Gym check-ins (daily aggregate counters are not user-identifiable).
  await must(admin.from("scans").delete().eq("user_id", uid));
  await mark("gymScans");

  // 13) Wholly personal rows. subscriptions/transactions intentionally kept.
  await must(admin.from("user_settings").delete().eq("user_id", uid));
  await must(admin.from("user_addresses").delete().eq("user_id", uid));
  await must(admin.from("notifications").delete().eq("user_id", uid));
  await must(admin.from("user_blocks").delete().eq("user_id", uid));
  await must(admin.from("user_blocks").delete().eq("blocked_user_id", uid));
  await mark("userData");

  // 14) De-identify the profile (tombstone).
  await must(admin.from("profiles").upsert({
    id: uid,
    display_name: "Deleted User",
    email: null, phone: null, photo_url: "",
    is_active: false, is_profile_complete: false,
    about: "", city: null, gender: null, dob: null,
    activities: [], favourite_activity: null,
    has_gym: false, gym_name: null,
    is_premium: false, premium_until: null,
    active_plan_id: null, active_subscription_id: null,
    fcm_tokens: [],
    deleted_at: new Date().toISOString(),
  }));
  await mark("profileTombstoned");

  // 15) Auth user last.
  const { error } = await admin.auth.admin.deleteUser(uid);
  if (error && !/not.?found/i.test(error.message)) throw new Error(error.message);
  await mark("authUserDeleted");
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader) return json({ error: "unauthenticated" }, 401);

  // Identify the caller from their JWT.
  const userClient = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false },
  });
  const { data: userData, error: userErr } = await userClient.auth.getUser();
  if (userErr || !userData.user) return json({ error: "unauthenticated" }, 401);
  const callerId = userData.user.id;

  // The admin panel may delete another user (`targetUserId`); everyone else
  // can only delete their own account.
  const body = await req.json().catch(() => ({}));
  const isAdmin = userData.user.app_metadata?.admin === true;
  const targetId = typeof body?.targetUserId === "string" ? body.targetUserId : "";
  if (targetId && targetId !== callerId && !isAdmin) {
    return json({ error: "permission_denied", message: "Admins only" }, 403);
  }
  const byAdmin = isAdmin && !!targetId && targetId !== callerId;
  const uid = byAdmin ? targetId : callerId;

  // Defense in depth: the session must be recent, enforced server-side too.
  // (Skipped for admin-initiated deletion: the admin is not the account owner.)
  const { data: age } = byAdmin ? { data: null } : await userClient.rpc("session_age_minutes");
  if (typeof age === "number" && age > REAUTH_MAX_AGE_MINUTES) {
    return json({ error: "failed_precondition", message: "REAUTH_REQUIRED", maxAgeMinutes: REAUTH_MAX_AGE_MINUTES }, 412);
  }

  const admin = createClient(SUPABASE_URL, SERVICE_KEY, { auth: { persistSession: false } });

  const requestedVia = byAdmin ? "admin" : body?.requestedVia === "web" ? "web" : "app";

  const { data: existing } = await admin.from("account_deletions").select("status").eq("user_id", uid).maybeSingle();
  if (existing?.status === "completed") return json({ ok: true, status: "completed", alreadyDone: true });
  if (existing?.status === "in_progress") return json({ ok: true, status: "in_progress" });

  await admin.from("account_deletions").upsert({
    user_id: uid,
    status: "in_progress",
    requested_via: requestedVia,
    started_at: new Date().toISOString(),
    error: null,
  });

  try {
    await runPipeline(admin, uid);
    await admin.from("account_deletions").update({
      status: "completed", completed_at: new Date().toISOString(),
    }).eq("user_id", uid);
    return json({ ok: true, status: "completed" });
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    await admin.from("account_deletions").update({
      status: "failed", failed_at: new Date().toISOString(), error: message,
    }).eq("user_id", uid);
    return json({ error: "internal", message: "Account deletion failed and can be retried." }, 500);
  }
});
