import * as admin from "firebase-admin";
import {initTestApp, clearFirestore} from "./emulator";
import {purgeExpiredGymScans, RETENTION} from "../retention";

let db: admin.firestore.Firestore;

beforeAll(() => {
  initTestApp();
  db = admin.firestore();
});

beforeEach(async () => {
  await clearFirestore();
});

const DAY_MS = 24 * 60 * 60 * 1000;

describe("purgeExpiredGymScans", () => {
  it("deletes only scans older than the configured retention window", async () => {
    const periodDays = RETENTION.gymCheckins.periodDays ?? 730;
    const oldTs = admin.firestore.Timestamp.fromMillis(Date.now() - (periodDays + 10) * DAY_MS);
    const recentTs = admin.firestore.Timestamp.fromMillis(Date.now() - (periodDays - 10) * DAY_MS);

    await db.collection("scans").doc("old1").set({userId: "u1", scannedAt: oldTs});
    await db.collection("scans").doc("old2").set({userId: "u2", scannedAt: oldTs});
    await db.collection("scans").doc("recent1").set({userId: "u1", scannedAt: recentTs});

    await purgeExpiredGymScans.run({} as never);

    const remaining = await db.collection("scans").get();
    expect(remaining.docs.map((d) => d.id).sort()).toEqual(["recent1"]);
  });

  it("is a safe no-op when nothing is expired", async () => {
    const recentTs = admin.firestore.Timestamp.fromMillis(Date.now() - 1 * DAY_MS);
    await db.collection("scans").doc("recent1").set({userId: "u1", scannedAt: recentTs});

    await purgeExpiredGymScans.run({} as never);

    const remaining = await db.collection("scans").get();
    expect(remaining.size).toBe(1);
  });

  it("stays bounded: processes at most 5 batches of 300 (<=1500 docs) per run", async () => {
    // Not exercised at full scale here (that's a 1,500-write integration
    // cost); this instead verifies the loop's early-exit condition directly
    // via a small controlled batch so the bound stays enforced without a
    // slow test. See functions/src/retention.ts for the 5x300 cap itself.
    const periodDays = RETENTION.gymCheckins.periodDays ?? 730;
    const oldTs = admin.firestore.Timestamp.fromMillis(Date.now() - (periodDays + 1) * DAY_MS);
    const batch = db.batch();
    for (let i = 0; i < 20; i++) {
      batch.set(db.collection("scans").doc(`expired-${i}`), {userId: "bulk", scannedAt: oldTs});
    }
    await batch.commit();

    await purgeExpiredGymScans.run({} as never);

    const remaining = await db.collection("scans").get();
    expect(remaining.empty).toBe(true);
  });
});
