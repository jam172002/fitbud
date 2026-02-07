import * as admin from "firebase-admin";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import crypto from "crypto";

admin.initializeApp();

const DIRECTPAY_CLIENT_ID = defineSecret("DIRECTPAY_CLIENT_ID");
const DIRECTPAY_CLIENT_SECRET = defineSecret("DIRECTPAY_CLIENT_SECRET");
const DIRECTPAY_BASE_URL = defineSecret("DIRECTPAY_BASE_URL");
const APP_PUBLIC_BASE_URL = defineSecret("APP_PUBLIC_BASE_URL");

// ---------- Helpers ----------
function amountToPaisas(pricePkr: number): string {
  const paisas = Math.round((pricePkr + Number.EPSILON) * 100);
  return String(paisas);
}

function hmacSha256Hex(plainText: string, secret: string): string {
  return crypto.createHmac("sha256", secret).update(plainText, "utf8").digest("hex");
}

function requireString(v: unknown, field: string): string {
  if (typeof v !== "string" || !v.trim()) {
    throw new HttpsError("invalid-argument", `${field} is required`);
  }
  return v.trim();
}

function requireBool(v: unknown, field: string): boolean {
  if (typeof v !== "boolean") {
    throw new HttpsError("invalid-argument", `${field} must be boolean`);
  }
  return v;
}

// ---------- 1) Create Payment URL ----------
export const directPayCreatePaymentUrl = onCall(
  {
    region: "asia-south1",
    secrets: [DIRECTPAY_CLIENT_ID, DIRECTPAY_CLIENT_SECRET, DIRECTPAY_BASE_URL, APP_PUBLIC_BASE_URL],
  },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Login required");

    const orderId = requireString(req.data?.orderId, "orderId");
    const planId = requireString(req.data?.planId, "planId");

    // Fetch user (must contain name/email/msisdn)
    const userSnap = await admin.firestore().collection("users").doc(uid).get();
    if (!userSnap.exists) throw new HttpsError("failed-precondition", "User profile missing");

    const user = userSnap.data() || {};
    const payerName = String(user.name || user.fullName || "").trim();
    const email = String(user.email || "").trim();
    const msisdn = String(user.msisdn || user.phone || "").trim(); // "03xxxxxxxxx"

    if (!payerName) throw new HttpsError("failed-precondition", "User name missing");
    if (!email) throw new HttpsError("failed-precondition", "User email missing");
    if (!msisdn) throw new HttpsError("failed-precondition", "User msisdn/phone missing");

    // Fetch plan
    const planSnap = await admin.firestore().collection("plans").doc(planId).get();
    if (!planSnap.exists) throw new HttpsError("not-found", "Plan not found");

    const plan = planSnap.data() || {};
    if (plan.isActive === false) throw new HttpsError("failed-precondition", "Plan inactive");

    const price = Number(plan.price ?? 0);
    const durationDays = Number(plan.durationDays ?? plan.duration ?? 0);
    if (!durationDays || durationDays <= 0) {
      throw new HttpsError("failed-precondition", "Plan durationDays is invalid");
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
      amount, // paisas string
      description, // URLSearchParams will encode it, checksum used the unencoded description above
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
      .set(
        {
          provider: "directpay_pwa",
          orderId,
          planId,
          planName: plan.name ?? "",
          price: price,
          currency: plan.currency ?? "PKR",
          durationDays, // ✅ IMPORTANT
          status: "pending",
          directPay: {paymentUrl, checksum},
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: true}
      );

    // Also mark on user (optional; your client already does it)
    await admin.firestore().collection("users").doc(uid).set(
      {
        activePlanId: planId,
        activeSubscriptionId: orderId,
        isPremium: false,
        premiumUntil: null,
        premiumUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true}
    );

    return {paymentUrl};
  }
);

// ---------- 2) Finalize From Redirect ----------
export const directPayFinalizeFromRedirect = onCall(
  {
    region: "asia-south1",
    secrets: [APP_PUBLIC_BASE_URL],
  },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Login required");

    const orderId = requireString(req.data?.orderId, "orderId");
    const success = requireBool(req.data?.success, "success");

    const subRef = admin.firestore().collection("users").doc(uid).collection("subscriptions").doc(orderId);
    const subSnap = await subRef.get();
    if (!subSnap.exists) throw new HttpsError("not-found", "Subscription not found");

    const sub = subSnap.data() || {};
    if (sub.status === "active") return {ok: true}; // idempotent

    if (!success) {
      await subRef.set(
        {
          status: "failed",
          failedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: true}
      );

      await admin.firestore().collection("users").doc(uid).set(
        {
          isPremium: false,
          premiumUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: true}
      );

      return {ok: true};
    }

    const durationDays = Number(sub.durationDays ?? 0);
    if (!durationDays || durationDays <= 0) {
      throw new HttpsError("failed-precondition", "Subscription durationDays missing/invalid");
    }

    const now = new Date();
    const endAt = new Date(now.getTime() + durationDays * 24 * 60 * 60 * 1000);

    await subRef.set(
      {
        status: "active",
        startAt: admin.firestore.Timestamp.fromDate(now),
        endAt: admin.firestore.Timestamp.fromDate(endAt),
        activatedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true}
    );

    await admin.firestore().collection("users").doc(uid).set(
      {
        isPremium: true,
        premiumUntil: admin.firestore.Timestamp.fromDate(endAt),
        activeSubscriptionId: orderId,
        activePlanId: sub.planId ?? "",
        premiumUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true}
    );

    return {ok: true, premiumUntil: endAt.toISOString()};
  }
);
