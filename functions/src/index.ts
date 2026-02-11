import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { DateTime } from "luxon";

admin.initializeApp();
const db = admin.firestore();

const TZ = "Asia/Karachi";
const COOLDOWN_MINUTES = 120;

/**
 * scanGym
 * ------------------------------------
 * Canonical gym scan entry point.
 * Replaces legacy checkInToGym.
 *
 * Responsibilities:
 * - Auth validation
 * - Gym validation
 * - Idempotency
 * - Cooldown enforcement
 * - Atomic scan + analytics write
 */
export const scanGym = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "User is not signed in.");

  const gymId = String(req.data?.gymId ?? "").trim();
  const clientScanId = String(req.data?.clientScanId ?? "").trim();
  const deviceId = String(req.data?.deviceId ?? "").trim();

  if (!gymId) throw new HttpsError("invalid-argument", "gymId is required.");
  if (!clientScanId) throw new HttpsError("invalid-argument", "clientScanId is required.");

  // 1️⃣ Validate gym
  const gymRef = db.doc(`gyms/${gymId}`);
  const gymSnap = await gymRef.get();
  if (!gymSnap.exists) throw new HttpsError("not-found", "Gym not found.");

  if (gymSnap.data()?.isActive === false) {
    return { ok: false, result: "gym_inactive" };
  }

  // 2️⃣ Idempotency
  const idem = await db.collection("scans")
    .where("userId", "==", uid)
    .where("clientScanId", "==", clientScanId)
    .limpit(1)
    .get();

  if (!idem.empty) {
    return { ok: true, scanId: idem.docs[0].id, result: "already_processed" };
  }

  // 3️⃣ Cooldown
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

  // 4️⃣ Time bucketing
  const dt = DateTime.fromMillis(now.toMillis(), { zone: TZ });
  const dayKey = dt.toFormat("yyyy-LL-dd");
  const hour = dt.hour;

  // 5️⃣ Atomic write
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
