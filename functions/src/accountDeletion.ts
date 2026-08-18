import * as admin from "firebase-admin";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {deleteQueryInBatches, updateQueryInBatches} from "./firestoreBatch";

/**
 * ---------------------------------------------------------------------------
 * Account deletion
 * ---------------------------------------------------------------------------
 * Single authoritative deletion workflow, callable from both the Flutter app
 * (Settings > Delete Account) and the public web deletion page, since both
 * are just authenticated Firebase clients hitting the same callable.
 *
 * Design decisions (documented here since they're judgment calls the spec
 * left open, not requirements pulled from a legal source):
 *
 *  - The `users/{uid}` profile document is NOT hard-deleted. It's overwritten
 *    with a de-identified tombstone (no name/photo/contact info, isActive:
 *    false, deletedAt set). Several places in the app resolve a user's
 *    identity by live-reading `users/{uid}` with no denormalized copy of the
 *    name (e.g. Message has only senderUserId, Conversation/GroupMember have
 *    no name snapshot) - if the doc vanished outright, every one of those
 *    screens would be reading a nonexistent document instead of gracefully
 *    showing "Deleted User". Subcollections that are wholly personal
 *    (settings, addresses, notifications, inbox, groupMemberships) ARE
 *    deleted outright.
 *  - `users/{uid}/subscriptions/*` (payment/order records) are deliberately
 *    NOT touched by this pipeline - see functions/src/retention.ts for why
 *    and what still needs sign-off from the project owner.
 *  - Messages the user authored are redacted in place (text/media cleared,
 *    isDeleted: true) rather than removed, so a shared conversation doesn't
 *    lose history for the other participant(s). Their own conversation
 *    membership (participants/{uid}) and personal inbox index are removed.
 *  - Sessions the user created are deleted only if no other participant
 *    remains once the user's own participant record is removed; otherwise
 *    the session is left in place for the remaining participants.
 *  - Buddy requests and friendships are hard-deleted in both directions -
 *    they only describe a relationship between two people, so once one side
 *    is gone the record has no remaining purpose.
 */

const REAUTH_MAX_AGE_MINUTES = 15;

type StepStatus = "pending" | "done";

interface DeletionJob {
  uid: string;
  status: "pending" | "in_progress" | "completed" | "failed";
  requestedAt: FirebaseFirestore.FieldValue | FirebaseFirestore.Timestamp;
  requestedVia: "app" | "web";
  startedAt?: FirebaseFirestore.FieldValue | FirebaseFirestore.Timestamp;
  completedAt?: FirebaseFirestore.FieldValue | FirebaseFirestore.Timestamp;
  failedAt?: FirebaseFirestore.FieldValue | FirebaseFirestore.Timestamp;
  error?: string | null;
  steps: Record<string, StepStatus>;
}

const STEP_NAMES = [
  "storageProfile",
  "storageChatMedia",
  "messagesRedacted",
  "conversationMemberships",
  "groupMemberships",
  "groupInvites",
  "sessionInvites",
  "sessionParticipants",
  "ownedSessions",
  "buddyRequests",
  "friendships",
  "gymScans",
  "userSubcollections",
  "profileTombstoned",
  "authUserDeleted",
] as const;

function jobRef(db: admin.firestore.Firestore, uid: string) {
  return db.collection("accountDeletions").doc(uid);
}

async function markStep(
  db: admin.firestore.Firestore,
  uid: string,
  step: (typeof STEP_NAMES)[number]
) {
  await jobRef(db, uid).set({steps: {[step]: "done"}}, {merge: true});
}

/**
 * Runs every deletion/de-identification step. Every step is safe to re-run:
 * queries that already return zero rows are no-ops, and overwriting the
 * tombstone or re-deleting Storage objects that are already gone is a no-op
 * too. This is what makes the whole job retry-safe rather than needing
 * fragile "have I already done this?" checks per step.
 * @param {admin.firestore.Firestore} db Firestore instance.
 * @param {string} uid The account being deleted.
 */
async function runDeletionPipeline(db: admin.firestore.Firestore, uid: string) {
  const userRef = db.collection("users").doc(uid);

  // 1) Storage: the user's own profile folder (covers profile.jpg and
  //    anything else ever written under users/{uid}/...).
  await admin.storage().bucket().deleteFiles({prefix: `users/${uid}/`});
  await markStep(db, uid, "storageProfile");

  // 2) Storage: chat media this user uploaded, discovered via their inbox
  //    index (chat/{conversationId}/{uid}/... is namespaced by uploader, so
  //    this never touches media other participants uploaded).
  const inboxSnap = await userRef.collection("inbox").get();
  const conversationIds = inboxSnap.docs.map((d) => d.id);
  for (const cid of conversationIds) {
    await admin.storage().bucket().deleteFiles({prefix: `chat/${cid}/${uid}/`});
  }
  await markStep(db, uid, "storageChatMedia");

  // 3) Messages authored by this user, anywhere: redact rather than delete
  //    so shared conversations keep their history for the other side.
  await updateQueryInBatches(
    db.collectionGroup("messages").where("senderUserId", "==", uid),
    {
      text: "",
      mediaUrl: "",
      thumbnailUrl: "",
      isDeleted: true,
    }
  );
  await markStep(db, uid, "messagesRedacted");

  // 4) This user's own membership record in every conversation they were
  //    part of, plus their personal inbox index (both wholly theirs).
  for (const cid of conversationIds) {
    await db.doc(`conversations/${cid}/participants/${uid}`).delete();
  }
  await db.recursiveDelete(userRef.collection("inbox"));
  await markStep(db, uid, "conversationMemberships");

  // 5) Group memberships: leave every group the user belonged to.
  const membershipSnap = await userRef.collection("groupMemberships").get();
  for (const membershipDoc of membershipSnap.docs) {
    const gid = membershipDoc.id;
    const groupRef = db.collection("groups").doc(gid);
    await db.runTransaction(async (tx) => {
      const memberRef = groupRef.collection("members").doc(uid);
      const memberSnap = await tx.get(memberRef);
      if (!memberSnap.exists) return;
      tx.delete(memberRef);
      tx.update(groupRef, {
        memberCount: admin.firestore.FieldValue.increment(-1),
      });
    });
    // Leave the group's conversation too, mirroring group_repo's
    // `group_{gid}` convention for the conversation id.
    await db.doc(`conversations/group_${gid}/participants/${uid}`).delete();
  }
  await db.recursiveDelete(userRef.collection("groupMemberships"));
  await markStep(db, uid, "groupMemberships");

  // 6) Group invites: 'invites' is a subcollection name shared by both
  //    groups and sessions, so a plain collectionGroup('invites') query
  //    would mix the two together. Disambiguate by walking up to the
  //    grandparent collection ('groups' vs 'sessions').
  const isUnderCollection = (
    doc: FirebaseFirestore.QueryDocumentSnapshot,
    collectionName: string
  ) => doc.ref.parent.parent?.parent.id === collectionName;

  const incomingGroupInvites = await db
    .collectionGroup("invites")
    .where("invitedUserId", "==", uid)
    .get();
  await Promise.all(
    incomingGroupInvites.docs
      .filter((d) => isUnderCollection(d, "groups"))
      .map((d) => d.ref.delete())
  );

  const sentGroupInvites = await db
    .collectionGroup("invites")
    .where("invitedByUserId", "==", uid)
    .get();
  await Promise.all(
    sentGroupInvites.docs
      .filter((d) => isUnderCollection(d, "groups"))
      .map((d) => d.ref.delete())
  );
  await markStep(db, uid, "groupInvites");

  // 7) Session invites: invites *to* this user are no longer relevant once
  //    they're gone, so delete them. Invites this user *sent* are still
  //    meaningful to the recipient, so de-identify the inviter snapshot
  //    instead of deleting the invite outright.
  const incomingSessionInvites = incomingGroupInvites.docs.filter((d) =>
    isUnderCollection(d, "sessions")
  );
  await Promise.all(incomingSessionInvites.map((d) => d.ref.delete()));

  const sentSessionInvites = sentGroupInvites.docs.filter((d) =>
    isUnderCollection(d, "sessions")
  );
  await Promise.all(
    sentSessionInvites.map((d) =>
      d.ref.update({
        invitedByName: "Deleted User",
        invitedByPhotoUrl: "",
      })
    )
  );
  await markStep(db, uid, "sessionInvites");

  // 8) Session participant records for this user, wherever they joined a
  //    session. Same 'participants' name-collision issue as (6) - disambiguate
  //    the same way.
  const participantDocs = await db
    .collectionGroup("participants")
    .where("userId", "==", uid)
    .get();
  const sessionParticipantDocs = participantDocs.docs.filter((d) =>
    isUnderCollection(d, "sessions")
  );
  await Promise.all(sessionParticipantDocs.map((d) => d.ref.delete()));
  await markStep(db, uid, "sessionParticipants");

  // 9) Sessions this user created: delete only if nobody else ever joined;
  //    otherwise leave it for the remaining participants.
  const ownedSessions = await db
    .collection("sessions")
    .where("createdByUserId", "==", uid)
    .get();
  for (const sessionDoc of ownedSessions.docs) {
    const remaining = await sessionDoc.ref.collection("participants").limit(1).get();
    if (remaining.empty) {
      await db.recursiveDelete(sessionDoc.ref);
    }
  }
  await markStep(db, uid, "ownedSessions");

  // 10) Buddy requests, either direction - pure relationship metadata.
  await deleteQueryInBatches(
    db.collection("buddyRequests").where("fromUserId", "==", uid)
  );
  await deleteQueryInBatches(
    db.collection("buddyRequests").where("toUserId", "==", uid)
  );
  await markStep(db, uid, "buddyRequests");

  // 11) Friendships - `userIds` is the array-contains field the app's own
  //     BuddyRepo already queries by.
  await deleteQueryInBatches(
    db.collection("friendships").where("userIds", "array-contains", uid)
  );
  await markStep(db, uid, "friendships");

  // 12) Gym check-in history. Gym-side aggregate counters
  //     (gyms/{gymId}/statsDaily/*) were already incremented at scan time and
  //     aren't per-user-identifiable, so they're intentionally left alone.
  await deleteQueryInBatches(db.collection("scans").where("userId", "==", uid));
  await markStep(db, uid, "gymScans");

  // 13) Wholly-personal user subcollections. `subscriptions` is
  //     deliberately excluded - see retention.ts.
  await db.recursiveDelete(userRef.collection("settings"));
  await db.recursiveDelete(userRef.collection("addresses"));
  await db.recursiveDelete(userRef.collection("notifications"));
  await markStep(db, uid, "userSubcollections");

  // 14) De-identify the profile document rather than deleting it outright
  //     (see the module doc comment for why).
  await userRef.set(
    {
      displayName: "Deleted User",
      email: admin.firestore.FieldValue.delete(),
      phone: admin.firestore.FieldValue.delete(),
      photoUrl: "",
      isActive: false,
      isProfileComplete: false,
      about: "",
      city: admin.firestore.FieldValue.delete(),
      gender: admin.firestore.FieldValue.delete(),
      dob: admin.firestore.FieldValue.delete(),
      activities: [],
      favouriteActivity: admin.firestore.FieldValue.delete(),
      hasGym: false,
      gymName: admin.firestore.FieldValue.delete(),
      isPremium: false,
      premiumUntil: admin.firestore.FieldValue.delete(),
      activePlanId: admin.firestore.FieldValue.delete(),
      activeSubscriptionId: admin.firestore.FieldValue.delete(),
      fcmTokens: admin.firestore.FieldValue.delete(),
      deletedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {merge: true}
  );
  await markStep(db, uid, "profileTombstoned");

  // 15) Auth user is deleted last, only after every data step above has
  //     succeeded - requirement from the spec, and it also means a failed
  //     data-deletion step never leaves someone locked out of an account
  //     that still has their data sitting in it.
  try {
    await admin.auth().deleteUser(uid);
  } catch (e) {
    // Already deleted (e.g. a retry after the auth-delete step previously
    // succeeded but the job doc write that follows it failed) is fine.
    const code = (e as { code?: string }).code;
    if (code !== "auth/user-not-found") throw e;
  }
  await markStep(db, uid, "authUserDeleted");
}

/**
 * Callable entry point. Both the Flutter app and the public web deletion
 * page call this - it's the one trusted place deletion actually happens,
 * per the spec's "don't trust the client to delete arbitrary records"
 * requirement.
 *
 * `enforceAppCheck: false` mirrors the existing `scanGym` function: this
 * repo's web reCAPTCHA App Check site key is an unconfigured placeholder
 * (see main.dart's `initAppCheck()`), so enforcing App Check here today
 * would just break the web deletion page for everyone. Revisit once App
 * Check is actually configured for web.
 */
export const requestAccountDeletion = onCall(
  {timeoutSeconds: 540, memory: "512MiB", enforceAppCheck: false},
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "You must be signed in.");

    // Defense in depth: enforce recent sign-in server-side too, even though
    // the client also gates this. `auth_time` is a standard Firebase ID
    // token claim (seconds since epoch of the last real sign-in).
    const authTimeSec = (req.auth?.token as { auth_time?: number } | undefined)
      ?.auth_time;
    if (authTimeSec) {
      const ageMinutes = (Date.now() / 1000 - authTimeSec) / 60;
      if (ageMinutes > REAUTH_MAX_AGE_MINUTES) {
        throw new HttpsError(
          "failed-precondition",
          "REAUTH_REQUIRED",
          {maxAgeMinutes: REAUTH_MAX_AGE_MINUTES}
        );
      }
    }

    const db = admin.firestore();
    const ref = jobRef(db, uid);
    const existing = await ref.get();

    // Idempotent no-op: already finished, tell the caller it succeeded.
    if (existing.exists && existing.data()?.status === "completed") {
      return {ok: true, status: "completed", alreadyDone: true};
    }

    // A job is already running (e.g. the client retried while the first
    // call was still in flight) - don't start a second one concurrently.
    if (existing.exists && existing.data()?.status === "in_progress") {
      return {ok: true, status: "in_progress"};
    }

    const requestedVia: "app" | "web" =
      (req.data?.requestedVia === "web" ? "web" : "app");

    await ref.set(
      {
        uid,
        status: "in_progress",
        requestedVia,
        requestedAt: existing.exists ?
          existing.data()?.requestedAt :
          admin.firestore.FieldValue.serverTimestamp(),
        startedAt: admin.firestore.FieldValue.serverTimestamp(),
        error: null,
      } as Partial<DeletionJob>,
      {merge: true}
    );

    try {
      await runDeletionPipeline(db, uid);
      await ref.set(
        {
          status: "completed",
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: true}
      );
      return {ok: true, status: "completed"};
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      await ref.set(
        {
          status: "failed",
          failedAt: admin.firestore.FieldValue.serverTimestamp(),
          error: message,
        },
        {merge: true}
      );
      throw new HttpsError("internal", "Account deletion failed and can be retried.");
    }
  }
);

/** Lets a client (or support) check on an in-progress/failed job. */
export const getAccountDeletionStatus = onCall({enforceAppCheck: false}, async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "You must be signed in.");
  const db = admin.firestore();
  const snap = await jobRef(db, uid).get();
  if (!snap.exists) return {status: "none"};
  const data = snap.data() as DeletionJob;
  return {status: data.status, error: data.error ?? null};
});
