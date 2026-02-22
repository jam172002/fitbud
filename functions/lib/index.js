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
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.scanGym = exports.onNewMessage = exports.onSessionInviteUpdated = exports.onSessionInviteCreated = exports.onBuddyRequestUpdated = exports.onBuddyRequestCreated = void 0;
const admin = __importStar(require("firebase-admin"));
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-functions/v2/firestore");
const luxon_1 = require("luxon");
admin.initializeApp();
const db = admin.firestore();
const TZ = "Asia/Karachi";
const COOLDOWN_MINUTES = 120;
// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
async function getUserFcmToken(uid) {
    var _a;
    const snap = await db.collection("users").doc(uid).get();
    if (!snap.exists)
        return null;
    const data = (_a = snap.data()) !== null && _a !== void 0 ? _a : {};
    const token = data["fcmTokens"];
    if (typeof token === "string" && token.trim().length > 0)
        return token.trim();
    return null;
}
async function writeNotification(uid, type, title, body, data = {}) {
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
async function sendFcmNotification(token, title, body, data = {}) {
    await admin.messaging().send({
        token,
        notification: { title, body },
        data,
        android: { priority: "high" },
        apns: { payload: { aps: { sound: "default" } } },
    });
}
async function notifyUser(uid, type, title, body, data = {}) {
    await writeNotification(uid, type, title, body, data);
    const token = await getUserFcmToken(uid);
    if (token) {
        try {
            await sendFcmNotification(token, title, body, Object.assign(Object.assign({}, data), { type }));
        }
        catch (e) {
            console.error(`FCM send failed for ${uid}:`, e);
        }
    }
}
async function getUserDisplayName(uid) {
    var _a, _b;
    const snap = await db.collection("users").doc(uid).get();
    if (!snap.exists)
        return "Someone";
    return (_b = ((_a = snap.data()) !== null && _a !== void 0 ? _a : {})["displayName"]) !== null && _b !== void 0 ? _b : "Someone";
}
// ---------------------------------------------------------------------------
// Buddy Request: onCreate → notify recipient
// ---------------------------------------------------------------------------
exports.onBuddyRequestCreated = (0, firestore_1.onDocumentCreated)("buddyRequests/{requestId}", async (event) => {
    var _a, _b, _c, _d;
    const data = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
    if (!data)
        return;
    const fromUserId = (_b = data["fromUserId"]) !== null && _b !== void 0 ? _b : "";
    const toUserId = (_c = data["toUserId"]) !== null && _c !== void 0 ? _c : "";
    const status = (_d = data["status"]) !== null && _d !== void 0 ? _d : "";
    const requestId = event.params.requestId;
    if (!fromUserId || !toUserId || status !== "pending")
        return;
    const senderName = await getUserDisplayName(fromUserId);
    await notifyUser(toUserId, "buddy_request", "New Buddy Request", `${senderName} sent you a buddy request`, { fromUserId, requestId });
});
// ---------------------------------------------------------------------------
// Buddy Request: onUpdate → notify sender when accepted
// ---------------------------------------------------------------------------
exports.onBuddyRequestUpdated = (0, firestore_1.onDocumentUpdated)("buddyRequests/{requestId}", async (event) => {
    var _a, _b, _c, _d, _e, _f, _g, _h;
    const before = (_b = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before.data()) !== null && _b !== void 0 ? _b : {};
    const after = (_d = (_c = event.data) === null || _c === void 0 ? void 0 : _c.after.data()) !== null && _d !== void 0 ? _d : {};
    const prevStatus = (_e = before["status"]) !== null && _e !== void 0 ? _e : "";
    const newStatus = (_f = after["status"]) !== null && _f !== void 0 ? _f : "";
    const requestId = event.params.requestId;
    if (prevStatus === newStatus)
        return;
    const fromUserId = (_g = after["fromUserId"]) !== null && _g !== void 0 ? _g : "";
    const toUserId = (_h = after["toUserId"]) !== null && _h !== void 0 ? _h : "";
    if (!fromUserId || !toUserId)
        return;
    if (newStatus === "accepted") {
        const acceptorName = await getUserDisplayName(toUserId);
        await notifyUser(fromUserId, "buddy_accepted", "Buddy Request Accepted", `${acceptorName} accepted your buddy request`, { toUserId, requestId });
    }
});
// ---------------------------------------------------------------------------
// Session Invite: onCreate → notify invited user
// ---------------------------------------------------------------------------
exports.onSessionInviteCreated = (0, firestore_1.onDocumentCreated)("sessions/{sessionId}/invites/{inviteId}", async (event) => {
    var _a, _b, _c, _d, _e;
    const data = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
    if (!data)
        return;
    const invitedUserId = (_b = data["invitedUserId"]) !== null && _b !== void 0 ? _b : "";
    const invitedByUserId = (_c = data["invitedByUserId"]) !== null && _c !== void 0 ? _c : "";
    const sessionId = event.params.sessionId;
    const inviteId = event.params.inviteId;
    const status = (_d = data["status"]) !== null && _d !== void 0 ? _d : "";
    if (!invitedUserId || !invitedByUserId || status !== "pending")
        return;
    const inviterName = data["invitedByName"] || (await getUserDisplayName(invitedByUserId));
    const category = (_e = data["sessionCategory"]) !== null && _e !== void 0 ? _e : "a session";
    await notifyUser(invitedUserId, "session_invite", "Session Invitation", `${inviterName} invited you to ${category}`, { sessionId, inviteId, invitedByUserId });
});
// ---------------------------------------------------------------------------
// Session Invite: onUpdate → notify inviter when accepted
// ---------------------------------------------------------------------------
exports.onSessionInviteUpdated = (0, firestore_1.onDocumentUpdated)("sessions/{sessionId}/invites/{inviteId}", async (event) => {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j;
    const before = (_b = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before.data()) !== null && _b !== void 0 ? _b : {};
    const after = (_d = (_c = event.data) === null || _c === void 0 ? void 0 : _c.after.data()) !== null && _d !== void 0 ? _d : {};
    const prevStatus = (_e = before["status"]) !== null && _e !== void 0 ? _e : "";
    const newStatus = (_f = after["status"]) !== null && _f !== void 0 ? _f : "";
    const sessionId = event.params.sessionId;
    const inviteId = event.params.inviteId;
    if (prevStatus === newStatus)
        return;
    const invitedUserId = (_g = after["invitedUserId"]) !== null && _g !== void 0 ? _g : "";
    const invitedByUserId = (_h = after["invitedByUserId"]) !== null && _h !== void 0 ? _h : "";
    if (!invitedUserId || !invitedByUserId)
        return;
    if (newStatus === "accepted") {
        const acceptorName = await getUserDisplayName(invitedUserId);
        const category = (_j = after["sessionCategory"]) !== null && _j !== void 0 ? _j : "your session";
        await notifyUser(invitedByUserId, "session_invite", "Session Invite Accepted", `${acceptorName} accepted your invite to ${category}`, { sessionId, inviteId, invitedUserId });
    }
});
// ---------------------------------------------------------------------------
// New Message: onCreate → notify other participants
// ---------------------------------------------------------------------------
exports.onNewMessage = (0, firestore_1.onDocumentCreated)("conversations/{conversationId}/messages/{messageId}", async (event) => {
    var _a, _b, _c, _d, _e;
    const data = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
    if (!data)
        return;
    const senderUserId = (_b = data["senderUserId"]) !== null && _b !== void 0 ? _b : "";
    const conversationId = event.params.conversationId;
    const messageId = event.params.messageId;
    const messageType = (_c = data["type"]) !== null && _c !== void 0 ? _c : "text";
    const isDeleted = (_d = data["isDeleted"]) !== null && _d !== void 0 ? _d : false;
    if (!senderUserId || isDeleted)
        return;
    const senderName = await getUserDisplayName(senderUserId);
    let preview;
    switch (messageType) {
        case "image":
            preview = "📷 Photo";
            break;
        case "video":
            preview = "🎥 Video";
            break;
        case "audio":
            preview = "🎵 Audio";
            break;
        case "file":
            preview = "📎 File";
            break;
        default: {
            const text = ((_e = data["text"]) !== null && _e !== void 0 ? _e : "").trim();
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
        .map((uid) => notifyUser(uid, "message", senderName, preview || "Sent you a message", { conversationId, messageId, senderUserId }));
    await Promise.all(notifications);
});
// ---------------------------------------------------------------------------
// scanGym (existing — typo fix: limpit → limit)
// ---------------------------------------------------------------------------
exports.scanGym = (0, https_1.onCall)(async (req) => {
    var _a, _b, _c, _d, _e, _f, _g, _h;
    const uid = (_a = req.auth) === null || _a === void 0 ? void 0 : _a.uid;
    if (!uid)
        throw new https_1.HttpsError("unauthenticated", "User is not signed in.");
    const gymId = String((_c = (_b = req.data) === null || _b === void 0 ? void 0 : _b.gymId) !== null && _c !== void 0 ? _c : "").trim();
    const clientScanId = String((_e = (_d = req.data) === null || _d === void 0 ? void 0 : _d.clientScanId) !== null && _e !== void 0 ? _e : "").trim();
    const deviceId = String((_g = (_f = req.data) === null || _f === void 0 ? void 0 : _f.deviceId) !== null && _g !== void 0 ? _g : "").trim();
    if (!gymId)
        throw new https_1.HttpsError("invalid-argument", "gymId is required.");
    if (!clientScanId)
        throw new https_1.HttpsError("invalid-argument", "clientScanId is required.");
    const gymRef = db.doc(`gyms/${gymId}`);
    const gymSnap = await gymRef.get();
    if (!gymSnap.exists)
        throw new https_1.HttpsError("not-found", "Gym not found.");
    if (((_h = gymSnap.data()) === null || _h === void 0 ? void 0 : _h.isActive) === false) {
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
    const dt = luxon_1.DateTime.fromMillis(now.toMillis(), { zone: TZ });
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
//# sourceMappingURL=index.js.map