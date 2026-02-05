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
exports.scanGym = exports.createGymWithOwner = void 0;
const admin = __importStar(require("firebase-admin"));
const https_1 = require("firebase-functions/v2/https");
const luxon_1 = require("luxon");
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
exports.createGymWithOwner = (0, https_1.onCall)(async (req) => {
    var _a, _b, _c, _d, _e, _f, _g, _h;
    const callerUid = (_a = req.auth) === null || _a === void 0 ? void 0 : _a.uid;
    if (!callerUid) {
        throw new https_1.HttpsError("unauthenticated", "Not authenticated.");
    }
    // 🔐 Verify admin privileges
    const caller = await admin.auth().getUser(callerUid);
    if (!((_b = caller.customClaims) === null || _b === void 0 ? void 0 : _b.admin)) {
        throw new https_1.HttpsError("permission-denied", "Admin access required.");
    }
    const email = String((_d = (_c = req.data) === null || _c === void 0 ? void 0 : _c.email) !== null && _d !== void 0 ? _d : "").trim();
    const password = String((_f = (_e = req.data) === null || _e === void 0 ? void 0 : _e.password) !== null && _f !== void 0 ? _f : "").trim();
    const gymId = String((_h = (_g = req.data) === null || _g === void 0 ? void 0 : _g.gymId) !== null && _h !== void 0 ? _h : "").trim();
    if (!email || !password || !gymId) {
        throw new https_1.HttpsError("invalid-argument", "email, password and gymId are required.");
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
exports.scanGym = (0, https_1.onCall)(async (req) => {
    var _a, _b, _c, _d, _e, _f, _g, _h;
    const uid = (_a = req.auth) === null || _a === void 0 ? void 0 : _a.uid;
    if (!uid) {
        throw new https_1.HttpsError("unauthenticated", "User is not signed in.");
    }
    const gymId = String((_c = (_b = req.data) === null || _b === void 0 ? void 0 : _b.gymId) !== null && _c !== void 0 ? _c : "").trim();
    const clientScanId = String((_e = (_d = req.data) === null || _d === void 0 ? void 0 : _d.clientScanId) !== null && _e !== void 0 ? _e : "").trim();
    const deviceId = String((_g = (_f = req.data) === null || _f === void 0 ? void 0 : _f.deviceId) !== null && _g !== void 0 ? _g : "").trim();
    if (!gymId) {
        throw new https_1.HttpsError("invalid-argument", "gymId is required.");
    }
    if (!clientScanId) {
        throw new https_1.HttpsError("invalid-argument", "clientScanId is required.");
    }
    // 1️⃣ Validate gym
    const gymRef = db.doc(`gyms/${gymId}`);
    const gymSnap = await gymRef.get();
    if (!gymSnap.exists) {
        throw new https_1.HttpsError("not-found", "Gym not found.");
    }
    if (((_h = gymSnap.data()) === null || _h === void 0 ? void 0 : _h.status) === "inactive") {
        return { ok: false, result: "gym_inactive" };
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
        if (lastTs &&
            (now.toMillis() - lastTs.toMillis()) / 60000 < COOLDOWN_MINUTES) {
            return { ok: false, result: "cooldown" };
        }
    }
    // 4️⃣ Time bucketing (server-side)
    const dt = luxon_1.DateTime.fromMillis(now.toMillis(), { zone: TZ });
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
        tx.set(dailyRef, {
            total: admin.firestore.FieldValue.increment(1),
            [`hours.${hour}`]: admin.firestore.FieldValue.increment(1),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        tx.set(monthlyRef, {
            total: admin.firestore.FieldValue.increment(1),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        tx.update(gymRef, {
            monthlyScans: admin.firestore.FieldValue.increment(1),
            totalScans: admin.firestore.FieldValue.increment(1),
        });
    });
    return { ok: true, scanId: scanRef.id, result: "accepted" };
});
//# sourceMappingURL=index.js.map