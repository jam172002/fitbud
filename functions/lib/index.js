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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.directPayFinalizeFromRedirect = exports.directPayCreatePaymentUrl = void 0;
const admin = __importStar(require("firebase-admin"));
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const crypto_1 = __importDefault(require("crypto"));
admin.initializeApp();
const DIRECTPAY_CLIENT_ID = (0, params_1.defineSecret)("DIRECTPAY_CLIENT_ID");
const DIRECTPAY_CLIENT_SECRET = (0, params_1.defineSecret)("DIRECTPAY_CLIENT_SECRET");
const DIRECTPAY_BASE_URL = (0, params_1.defineSecret)("DIRECTPAY_BASE_URL");
const APP_PUBLIC_BASE_URL = (0, params_1.defineSecret)("APP_PUBLIC_BASE_URL");
// ---------- Helpers ----------
function amountToPaisas(pricePkr) {
    const paisas = Math.round((pricePkr + Number.EPSILON) * 100);
    return String(paisas);
}
function hmacSha256Hex(plainText, secret) {
    return crypto_1.default.createHmac("sha256", secret).update(plainText, "utf8").digest("hex");
}
function requireString(v, field) {
    if (typeof v !== "string" || !v.trim()) {
        throw new https_1.HttpsError("invalid-argument", `${field} is required`);
    }
    return v.trim();
}
function requireBool(v, field) {
    if (typeof v !== "boolean") {
        throw new https_1.HttpsError("invalid-argument", `${field} must be boolean`);
    }
    return v;
}
// ---------- 1) Create Payment URL ----------
exports.directPayCreatePaymentUrl = (0, https_1.onCall)({
    region: "asia-south1",
    secrets: [DIRECTPAY_CLIENT_ID, DIRECTPAY_CLIENT_SECRET, DIRECTPAY_BASE_URL, APP_PUBLIC_BASE_URL],
}, async (req) => {
    var _a, _b, _c, _d, _e, _f, _g, _h;
    const uid = (_a = req.auth) === null || _a === void 0 ? void 0 : _a.uid;
    if (!uid)
        throw new https_1.HttpsError("unauthenticated", "Login required");
    const orderId = requireString((_b = req.data) === null || _b === void 0 ? void 0 : _b.orderId, "orderId");
    const planId = requireString((_c = req.data) === null || _c === void 0 ? void 0 : _c.planId, "planId");
    // Fetch user (must contain name/email/msisdn)
    const userSnap = await admin.firestore().collection("users").doc(uid).get();
    if (!userSnap.exists)
        throw new https_1.HttpsError("failed-precondition", "User profile missing");
    const user = userSnap.data() || {};
    const payerName = String(user.name || user.fullName || "").trim();
    const email = String(user.email || "").trim();
    const msisdn = String(user.msisdn || user.phone || "").trim(); // "03xxxxxxxxx"
    if (!payerName)
        throw new https_1.HttpsError("failed-precondition", "User name missing");
    if (!email)
        throw new https_1.HttpsError("failed-precondition", "User email missing");
    if (!msisdn)
        throw new https_1.HttpsError("failed-precondition", "User msisdn/phone missing");
    // Fetch plan
    const planSnap = await admin.firestore().collection("plans").doc(planId).get();
    if (!planSnap.exists)
        throw new https_1.HttpsError("not-found", "Plan not found");
    const plan = planSnap.data() || {};
    if (plan.isActive === false)
        throw new https_1.HttpsError("failed-precondition", "Plan inactive");
    const price = Number((_d = plan.price) !== null && _d !== void 0 ? _d : 0);
    const durationDays = Number((_f = (_e = plan.durationDays) !== null && _e !== void 0 ? _e : plan.duration) !== null && _f !== void 0 ? _f : 0);
    if (!durationDays || durationDays <= 0) {
        throw new https_1.HttpsError("failed-precondition", "Plan durationDays is invalid");
    }
    const description = `Fitbud Premium - ${String(plan.name || "Plan").trim()}`; // unencoded for checksum
    const amount = amountToPaisas(price);
    const clientId = DIRECTPAY_CLIENT_ID.value();
    const clientSecret = DIRECTPAY_CLIENT_SECRET.value();
    const baseUrl = DIRECTPAY_BASE_URL.value();
    const appBase = APP_PUBLIC_BASE_URL.value();
    // Checksum per doc:
    // plainText = "DirectPay:{client_transaction_id}:{description}:{amount}"
    const plainText = `DirectPay:${orderId}:${description}:${amount}`;
    const checksum = hmacSha256Hex(plainText, clientSecret);
    // Redirect URLs your WebView will intercept
    const successRedirect = `${appBase}/payments/success?orderId=${encodeURIComponent(orderId)}`;
    const failedRedirect = `${appBase}/payments/failed?orderId=${encodeURIComponent(orderId)}`;
    const params = new URLSearchParams({
        client_id: clientId,
        client_transaction_id: orderId,
        amount,
        description,
        payer_name: payerName,
        email,
        msisdn,
        checksum,
        success_redirect_url: successRedirect,
        failed_redirect_url: failedRedirect,
        currency: String(plan.currency || "PKR"),
    });
    const paymentUrl = `${baseUrl}?${params.toString()}`;
    // Save pending subscription fields needed by finalize
    await admin
        .firestore()
        .collection("users")
        .doc(uid)
        .collection("subscriptions")
        .doc(orderId)
        .set({
        provider: "directpay_pwa",
        orderId,
        planId,
        planName: (_g = plan.name) !== null && _g !== void 0 ? _g : "",
        price: price,
        currency: (_h = plan.currency) !== null && _h !== void 0 ? _h : "PKR",
        durationDays,
        status: "pending",
        directPay: { paymentUrl, checksum },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    // Also mark on user (optional; your client already does it)
    await admin.firestore().collection("users").doc(uid).set({
        activePlanId: planId,
        activeSubscriptionId: orderId,
        isPremium: false,
        premiumUntil: null,
        premiumUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    return { paymentUrl };
});
// ---------- 2) Finalize From Redirect ----------
exports.directPayFinalizeFromRedirect = (0, https_1.onCall)({
    region: "asia-south1",
    secrets: [APP_PUBLIC_BASE_URL],
}, async (req) => {
    var _a, _b, _c, _d, _e;
    const uid = (_a = req.auth) === null || _a === void 0 ? void 0 : _a.uid;
    if (!uid)
        throw new https_1.HttpsError("unauthenticated", "Login required");
    const orderId = requireString((_b = req.data) === null || _b === void 0 ? void 0 : _b.orderId, "orderId");
    const success = requireBool((_c = req.data) === null || _c === void 0 ? void 0 : _c.success, "success");
    const subRef = admin.firestore().collection("users").doc(uid).collection("subscriptions").doc(orderId);
    const subSnap = await subRef.get();
    if (!subSnap.exists)
        throw new https_1.HttpsError("not-found", "Subscription not found");
    const sub = subSnap.data() || {};
    if (sub.status === "active")
        return { ok: true }; // idempotent
    if (!success) {
        await subRef.set({
            status: "failed",
            failedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        await admin.firestore().collection("users").doc(uid).set({
            isPremium: false,
            premiumUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        return { ok: true };
    }
    const durationDays = Number((_d = sub.durationDays) !== null && _d !== void 0 ? _d : 0);
    if (!durationDays || durationDays <= 0) {
        throw new https_1.HttpsError("failed-precondition", "Subscription durationDays missing/invalid");
    }
    const now = new Date();
    const endAt = new Date(now.getTime() + durationDays * 24 * 60 * 60 * 1000);
    await subRef.set({
        status: "active",
        startAt: admin.firestore.Timestamp.fromDate(now),
        endAt: admin.firestore.Timestamp.fromDate(endAt),
        activatedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    await admin.firestore().collection("users").doc(uid).set({
        isPremium: true,
        premiumUntil: admin.firestore.Timestamp.fromDate(endAt),
        activeSubscriptionId: orderId,
        activePlanId: (_e = sub.planId) !== null && _e !== void 0 ? _e : "",
        premiumUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    return { ok: true, premiumUntil: endAt.toISOString() };
});
//# sourceMappingURL=index.js.map