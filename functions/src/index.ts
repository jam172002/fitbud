import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { DateTime } from "luxon";

admin.initializeApp();
const db = admin.firestore();

const TZ = "Asia/Karachi";
const COOLDOWN_MINUTES = 120;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

async function getUserFcmToken(uid: string): Promise<string | null> {
  const snap = await db.collection("users").doc(uid).get();
  if (!snap.exists) return null;
  const data = snap.data() ?? {};
  const token = data["fcmTokens"];
  if (typeof token === "string" && token.trim().length > 0) return token.trim();
  return null;
}

async function writeNotification(
  uid: string,
  type: string,
  title: string,
  body: string,
  data: Record<string, unknown> = {}
): Promise<void> {
  await db.collection(`users/${uid}/notifications`).add({
    userId: uid,
    type,
    title,
    body,
    data,
    isRead: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

async function sendFcmNotification(
  token: string,
  title: string,
  body: string,
  data: Record<string, string> = {}
): Promise<void> {
  await admin.messaging().send({
    token,
    notification: { title, body },
    data,
    android: { priority: "high" },
    apns: { payload: { aps: { sound: "default" } } },
  });
}

async function notifyUser(
  uid: string,
  type: string,
  title: string,
  body: string,
  data: Record<string, string> = {}
): Promise<void> {
  await writeNotification(uid, type, title, body, data);
  const token = await getUserFcmToken(uid);
  if (token) {
    try {
      await sendFcmNotification(token, title, body, { ...data, type });
    } catch (e) {
      console.error(`FCM send failed for ${uid}:`, e);
    }
  }
}

async function getUserDisplayName(uid: string): Promise<string> {
  const snap = await db.collection("users").doc(uid).get();
  if (!snap.exists) return "Someone";
  return (snap.data() ?? {})["displayName"] ?? "Someone";
}

// ---------------------------------------------------------------------------
// Buddy Request: onCreate → notify recipient
// ---------------------------------------------------------------------------
export const onBuddyRequestCreated = onDocumentCreated(
  "buddyRequests/{requestId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const fromUserId: string = data["fromUserId"] ?? "";
    const toUserId: string = data["toUserId"] ?? "";
    const status: string = data["status"] ?? "";
    const requestId: string = event.params.requestId;

    if (!fromUserId || !toUserId || status !== "pending") return;

    const senderName = await getUserDisplayName(fromUserId);

    await notifyUser(
      toUserId,
      "buddy_request",
      "New Buddy Request",
      `${senderName} sent you a buddy request`,
      { fromUserId, requestId }
    );
  }
);

// ---------------------------------------------------------------------------
// Buddy Request: onUpdate → notify sender when accepted
// ---------------------------------------------------------------------------
export const onBuddyRequestUpdated = onDocumentUpdated(
  "buddyRequests/{requestId}",
  async (event) => {
    const before = event.data?.before.data() ?? {};
    const after = event.data?.after.data() ?? {};

    const prevStatus: string = before["status"] ?? "";
    const newStatus: string = after["status"] ?? "";
    const requestId: string = event.params.requestId;

    if (prevStatus === newStatus) return;

    const fromUserId: string = after["fromUserId"] ?? "";
    const toUserId: string = after["toUserId"] ?? "";

    if (!fromUserId || !toUserId) return;

    if (newStatus === "accepted") {
      const acceptorName = await getUserDisplayName(toUserId);
      await notifyUser(
        fromUserId,
        "buddy_accepted",
        "Buddy Request Accepted",
        `${acceptorName} accepted your buddy request`,
        { toUserId, requestId }
      );
    }
  }
);

// ---------------------------------------------------------------------------
// Session Invite: onCreate → notify invited user
// ---------------------------------------------------------------------------
export const onSessionInviteCreated = onDocumentCreated(
  "sessions/{sessionId}/invites/{inviteId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const invitedUserId: string = data["invitedUserId"] ?? "";
    const invitedByUserId: string = data["invitedByUserId"] ?? "";
    const sessionId: string = event.params.sessionId;
    const inviteId: string = event.params.inviteId;
    const status: string = data["status"] ?? "";

    if (!invitedUserId || !invitedByUserId || status !== "pending") return;

    const inviterName = data["invitedByName"] || (await getUserDisplayName(invitedByUserId));
    const category: string = data["sessionCategory"] ?? "a session";

    await notifyUser(
      invitedUserId,
      "session_invite",
      "Session Invitation",
      `${inviterName} invited you to ${category}`,
      { sessionId, inviteId, invitedByUserId }
    );
  }
);

// ---------------------------------------------------------------------------
// Session Invite: onUpdate → notify inviter when accepted
// ---------------------------------------------------------------------------
export const onSessionInviteUpdated = onDocumentUpdated(
  "sessions/{sessionId}/invites/{inviteId}",
  async (event) => {
    const before = event.data?.before.data() ?? {};
    const after = event.data?.after.data() ?? {};

    const prevStatus: string = before["status"] ?? "";
    const newStatus: string = after["status"] ?? "";
    const sessionId: string = event.params.sessionId;
    const inviteId: string = event.params.inviteId;

    if (prevStatus === newStatus) return;

    const invitedUserId: string = after["invitedUserId"] ?? "";
    const invitedByUserId: string = after["invitedByUserId"] ?? "";

    if (!invitedUserId || !invitedByUserId) return;

    if (newStatus === "accepted") {
      const acceptorName = await getUserDisplayName(invitedUserId);
      const category: string = after["sessionCategory"] ?? "your session";

      await notifyUser(
        invitedByUserId,
        "session_invite",
        "Session Invite Accepted",
        `${acceptorName} accepted your invite to ${category}`,
        { sessionId, inviteId, invitedUserId }
      );
    }
  }
);

// ---------------------------------------------------------------------------
// New Message: onCreate → notify other participants
// ---------------------------------------------------------------------------
export const onNewMessage = onDocumentCreated(
  "conversations/{conversationId}/messages/{messageId}",
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const senderUserId: string = data["senderUserId"] ?? "";
    const conversationId: string = event.params.conversationId;
    const messageId: string = event.params.messageId;
    const messageType: string = data["type"] ?? "text";
    const isDeleted: boolean = data["isDeleted"] ?? false;

    if (!senderUserId || isDeleted) return;

    const senderName = await getUserDisplayName(senderUserId);

    let preview: string;
    switch (messageType) {
      case "image": preview = "📷 Photo"; break;
      case "video": preview = "🎥 Video"; break;
      case "audio": preview = "🎵 Audio"; break;
      case "file":  preview = "📎 File";  break;
      default: {
        const text: string = (data["text"] ?? "").trim();
        preview = text.length > 80 ? `${text.substring(0, 80)}…` : text;
        break;
      }
    }

    const participantsSnap = await db
      .collection(`conversations/${conversationId}/participants`)
      .get();

    const notifications = participantsSnap.docs
      .map((d) => d.id)
      .filter((uid) => uid !== senderUserId)
      .map((uid) =>
        notifyUser(
          uid,
          "message",
          senderName,
          preview || "Sent you a message",
          { conversationId, messageId, senderUserId }
        )
      );

    await Promise.all(notifications);
  }
);

// ---------------------------------------------------------------------------
// scanGym (existing — typo fix: limpit → limit)
// ---------------------------------------------------------------------------
export const scanGym = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "User is not signed in.");

  const gymId = String(req.data?.gymId ?? "").trim();
  const clientScanId = String(req.data?.clientScanId ?? "").trim();
  const deviceId = String(req.data?.deviceId ?? "").trim();

  if (!gymId) throw new HttpsError("invalid-argument", "gymId is required.");
  if (!clientScanId) throw new HttpsError("invalid-argument", "clientScanId is required.");

  const gymRef = db.doc(`gyms/${gymId}`);
  const gymSnap = await gymRef.get();
  if (!gymSnap.exists) throw new HttpsError("not-found", "Gym not found.");

  if (gymSnap.data()?.isActive === false) {
    return { ok: false, result: "gym_inactive" };
  }

  const idem = await db.collection("scans")
    .where("userId", "==", uid)
    .where("clientScanId", "==", clientScanId)
    .limit(1)
    .get();

  if (!idem.empty) {
    return { ok: true, scanId: idem.docs[0].id, result: "already_processed" };
  }

  const last = await db.collection("scans")
    .where("userId", "==", uid)
    .where("gymId", "==", gymId)
    .orderBy("scannedAt", "desc")
    .limit(1)
    .get();

  const now = admin.firestore.Timestamp.now();

  if (!last.empty) {
    const lastTs = last.docs[0].get("scannedAt");
    if (lastTs && (now.toMillis() - lastTs.toMillis()) / 60000 < COOLDOWN_MINUTES) {
      return { ok: false, result: "cooldown" };
    }
  }

  const dt = DateTime.fromMillis(now.toMillis(), { zone: TZ });
  const dayKey = dt.toFormat("yyyy-LL-dd");
  const hour = dt.hour;

  const scanRef = db.collection("scans").doc();
  const statsRef = db.doc(`gyms/${gymId}/statsDaily/${dayKey}`);

  await db.runTransaction(async (tx) => {
    tx.set(scanRef, {
      userId: uid,
      gymId,
      clientScanId,
      deviceId,
      scannedAt: admin.firestore.FieldValue.serverTimestamp(),
      dayKey,
      hour,
      status: "accepted",
    });

    tx.set(statsRef, {
      total: admin.firestore.FieldValue.increment(1),
      [`hours.${hour}`]: admin.firestore.FieldValue.increment(1),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  });

  return { ok: true, scanId: scanRef.id, result: "accepted" };
});
