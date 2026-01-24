import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { DateTime } from "luxon";

admin.initializeApp();
const db = admin.firestore();

const TZ = "Asia/Karachi";
const COOLDOWN_MINUTES = 120; // change as needed

export const checkInToGym = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "User is not signed in.");

  const gymId = String(req.data?.gymId ?? "").trim();
  const clientCheckinId = String(req.data?.clientCheckinId ?? "").trim();
  const deviceId = String(req.data?.deviceId ?? "").trim();

  if (!gymId) throw new HttpsError("invalid-argument", "gymId is required.");
  if (!clientCheckinId) throw new HttpsError("invalid-argument", "clientCheckinId is required.");

  // 1) Validate gym exists (and optionally active)
  const gymRef = db.doc(`gyms/${gymId}`);
  const gymSnap = await gymRef.get();
  if (!gymSnap.exists) throw new HttpsError("not-found", "Gym not found.");

  const gymData = gymSnap.data() ?? {};
  if (gymData["isActive"] === false) {
    return { ok: false, result: "gym_inactive", message: "Gym is not active." };
  }

  // 2) Idempotency (exactly-once): same user + same clientCheckinId
  const idemSnap = await db.collection("scans")
    .where("userId", "==", uid)
    .where("clientCheckinId", "==", clientCheckinId)
    .limit(1)
    .get();

  if (!idemSnap.empty) {
    const d = idemSnap.docs[0];
    return { ok: true, scanId: d.id, result: "already_processed" };
  }

  // 3) Cooldown (same user + same gym): last scannedAt must be older than COOLDOWN_MINUTES
  const lastSnap = await db.collection("scans")
    .where("userId", "==", uid)
    .where("gymId", "==", gymId)
    .orderBy("scannedAt", "desc")
    .limit(1)
    .get();

  const now = admin.firestore.Timestamp.now();
  if (!lastSnap.empty) {
    const lastTs = lastSnap.docs[0].get("scannedAt") as admin.firestore.Timestamp | null;
    if (lastTs) {
      const diffMin = (now.toMillis() - lastTs.toMillis()) / 60000;
      if (diffMin < COOLDOWN_MINUTES) {
        return {
          ok: false,
          result: "cooldown",
          message: `Please wait ${Math.ceil(COOLDOWN_MINUTES - diffMin)} minutes before scanning again.`,
        };
      }
    }
  }

  // 4) Compute dayKey/hour in Pakistan timezone (server-side)
  const dt = DateTime.fromMillis(now.toMillis(), { zone: TZ });
  const dayKey = dt.toFormat("yyyy-LL-dd");
  const hour = dt.hour;

  // 5) Transaction: write scan + update daily stats
  const scanRef = db.collection("scans").doc();
  const statsRef = db.doc(`gyms/${gymId}/statsDaily/${dayKey}`);

  await db.runTransaction(async (tx) => {
    tx.set(scanRef, {
      userId: uid,
      gymId,
      clientCheckinId,
      deviceId,
      dayKey,
      hour,
      scannedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: "accepted",
    });

    tx.set(statsRef, {
      total: admin.firestore.FieldValue.increment(1),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      [`hours.${hour}`]: admin.firestore.FieldValue.increment(1),
    }, { merge: true });
  });

  return { ok: true, scanId: scanRef.id, result: "accepted" };
});
