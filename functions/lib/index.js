"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.scanGym = void 0;
const admin = __importStar(require("firebase-admin"));
const https_1 = require("firebase-functions/v2/https");
const luxon_1 = require("luxon");
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
exports.scanGym = (0, https_1.onCall)(async (req) => {
    const uid = req.auth?.uid;
    if (!uid)
        throw new https_1.HttpsError("unauthenticated", "User is not signed in.");
    const gymId = String(req.data?.gymId ?? "").trim();
    const clientScanId = String(req.data?.clientScanId ?? "").trim();
    const deviceId = String(req.data?.deviceId ?? "").trim();
    if (!gymId)
        throw new https_1.HttpsError("invalid-argument", "gymId is required.");
    if (!clientScanId)
        throw new https_1.HttpsError("invalid-argument", "clientScanId is required.");
    // 1️⃣ Validate gym
    const gymRef = db.doc(`gyms/${gymId}`);
    const gymSnap = await gymRef.get();
    if (!gymSnap.exists)
        throw new https_1.HttpsError("not-found", "Gym not found.");
    if (gymSnap.data()?.isActive === false) {
        return { ok: false, result: "gym_inactive" };
    }
    // 2️⃣ Idempotency
    const idem = await db.collection("scans")
        .where("userId", "==", uid)
        .where("clientScanId", "==", clientScanId)
        .limit(1)
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
    const dt = luxon_1.DateTime.fromMillis(now.toMillis(), { zone: TZ });
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
//# sourceMappingURL=index.js.map