import * as admin from "firebase-admin";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {DateTime} from "luxon";

/* -------------------------------------------------------------------------- */
/*                                INITIAL SETUP                               */
/* -------------------------------------------------------------------------- */

admin.initializeApp();

const db = admin.firestore();

const TZ = "Asia/Karachi";
const COOLDOWN_MINUTES = 120;

/* -------------------------------------------------------------------------- */
/*                         CREATE GYM WITH OWNER (ADMIN)                       */
/* -------------------------------------------------------------------------- */
/**
 * createGymWithOwner
 * ------------------
 * Creates:
 * - Firebase Auth user for gym owner
 * - Links owner to existing gym document
 *
 * Security:
 * - Callable only by authenticated admins
 */
export const createGymWithOwner = onCall(async (req) => {
  const callerUid = req.auth?.uid;
  if (!callerUid) {
    throw new HttpsError("unauthenticated", "Not authenticated.");
  }

  // 🔐 Verify admin privileges
  const caller = await admin.auth().getUser(callerUid);
  if (!caller.customClaims?.admin) {
    throw new HttpsError("permission-denied", "Admin access required.");
  }

  const email = String(req.data?.email ?? "").trim();
  const password = String(req.data?.password ?? "").trim();
  const gymId = String(req.data?.gymId ?? "").trim();

  if (!email || !password || !gymId) {
    throw new HttpsError(
      "invalid-argument",
      "email, password and gymId are required."
    );
  }

  // 1️⃣ Create Auth user
  const user = await admin.auth().createUser({
    email,
    password,
    emailVerified: false,
    disabled: false,
  });

  // 2️⃣ Assign custom claims
  await admin.auth().setCustomUserClaims(user.uid, {
    gymOwner: true,
    gymId,
  });

  // 3️⃣ Attach owner to gym
  await db.doc(`gyms/${gymId}`).update({
    ownerUid: user.uid,
    ownerEmail: email,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    ok: true,
    uid: user.uid,
  };
});

/* -------------------------------------------------------------------------- */
/*                                   SCAN GYM                                 */
/* -------------------------------------------------------------------------- */
/**
 * scanGym
 * -------
 * Canonical scan/check-in entry point.
 *
 * Responsibilities:
 * - Auth validation
 * - Gym validation
 * - Idempotency
 * - Cooldown enforcement
 * - Atomic scan + analytics updates
 */
export const scanGym = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "User is not signed in.");
  }

  const gymId = String(req.data?.gymId ?? "").trim();
  const clientScanId = String(req.data?.clientScanId ?? "").trim();
  const deviceId = String(req.data?.deviceId ?? "").trim();

  if (!gymId) {
    throw new HttpsError("invalid-argument", "gymId is required.");
  }
  if (!clientScanId) {
    throw new HttpsError("invalid-argument", "clientScanId is required.");
  }

  // 1️⃣ Validate gym
  const gymRef = db.doc(`gyms/${gymId}`);
  const gymSnap = await gymRef.get();

  if (!gymSnap.exists) {
    throw new HttpsError("not-found", "Gym not found.");
  }

  if (gymSnap.data()?.status === "inactive") {
    return {ok: false, result: "gym_inactive"};
  }

  // 2️⃣ Idempotency check
  const idemSnap = await db
    .collection("scans")
    .where("userId", "==", uid)
    .where("clientScanId", "==", clientScanId)
    .limit(1)
    .get();

  if (!idemSnap.empty) {
    return {
      ok: true,
      scanId: idemSnap.docs[0].id,
      result: "already_processed",
    };
  }

  // 3️⃣ Cooldown enforcement
  const lastSnap = await db
    .collection("scans")
    .where("userId", "==", uid)
    .where("gymId", "==", gymId)
    .orderBy("scannedAt", "desc")
    .limit(1)
    .get();

  const now = admin.firestore.Timestamp.now();

  if (!lastSnap.empty) {
    const lastTs = lastSnap.docs[0].get("scannedAt");
    if (
      lastTs &&
      (now.toMillis() - lastTs.toMillis()) / 60000 < COOLDOWN_MINUTES
    ) {
      return {ok: false, result: "cooldown"};
    }
  }

  // 4️⃣ Time bucketing (server-side)
  const dt = DateTime.fromMillis(now.toMillis(), {zone: TZ});
  const dayKey = dt.toFormat("yyyy-LL-dd");
  const monthKey = dt.toFormat("yyyy-LL");
  const hour = dt.hour;

  const scanRef = db.collection("scans").doc();
  const dailyRef = db.doc(`gyms/${gymId}/statsDaily/${dayKey}`);
  const monthlyRef = db.doc(`gyms/${gymId}/statsMonthly/${monthKey}`);

  // 5️⃣ Atomic transaction
  await db.runTransaction(async (tx) => {
    tx.set(scanRef, {
      userId: uid,
      gymId,
      clientScanId,
      deviceId,
      scannedAt: admin.firestore.FieldValue.serverTimestamp(),
      dayKey,
      monthKey,
      hour,
      status: "accepted",
    });

    tx.set(
      dailyRef,
      {
        total: admin.firestore.FieldValue.increment(1),
        [`hours.${hour}`]: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true}
    );

    tx.set(
      monthlyRef,
      {
        total: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true}
    );

    tx.update(gymRef, {
      monthlyScans: admin.firestore.FieldValue.increment(1),
      totalScans: admin.firestore.FieldValue.increment(1),
    });
  });

  return {ok: true, scanId: scanRef.id, result: "accepted"};
});
