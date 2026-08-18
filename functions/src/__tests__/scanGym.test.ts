import * as admin from "firebase-admin";
import {CallableRequest} from "firebase-functions/v2/https";
import {initTestApp, clearFirestore} from "./emulator";
import {scanGym} from "../index";

let db: admin.firestore.Firestore;

beforeAll(() => {
  initTestApp();
  db = admin.firestore();
});

beforeEach(async () => {
  await clearFirestore();
});

function callAs(uid: string, data: Record<string, unknown>): CallableRequest {
  return {
    data,
    auth: {uid, token: {uid}},
    rawRequest: {},
  } as unknown as CallableRequest;
}

async function seedGym(gymId: string, status = "active") {
  await db.doc(`gyms/${gymId}`).set({name: "Test Gym", status});
}

describe("scanGym contract", () => {
  it("rejects unauthenticated calls", async () => {
    await expect(
      scanGym.run({data: {gymId: "g1", clientScanId: "c1"}, rawRequest: {}} as unknown as CallableRequest)
    ).rejects.toThrow(/signed in/i);
  });

  it("rejects a missing gymId/clientScanId with invalid-argument", async () => {
    await expect(scanGym.run(callAs("u1", {clientScanId: "c1"}))).rejects.toThrow(/gymId/);
    await expect(scanGym.run(callAs("u1", {gymId: "g1"}))).rejects.toThrow(/clientScanId/);
  });

  it("returns not-found for a gym that doesn't exist", async () => {
    await expect(
      scanGym.run(callAs("u1", {gymId: "nope", clientScanId: "c1"}))
    ).rejects.toThrow(/not found/i);
  });

  it("returns gym_inactive for an inactive gym, without creating a scan", async () => {
    await seedGym("g1", "inactive");
    const result = await scanGym.run(callAs("u1", {gymId: "g1", clientScanId: "c1"}));
    expect(result).toMatchObject({ok: false, result: "gym_inactive"});
    expect((result as {message?: string}).message).toBeTruthy();
    expect((await db.collection("scans").get()).empty).toBe(true);
  });

  it("returns gym_inactive for a suspended gym", async () => {
    await seedGym("g1", "suspended");
    const result = await scanGym.run(callAs("u1", {gymId: "g1", clientScanId: "c1"}));
    expect(result).toMatchObject({ok: false, result: "gym_inactive"});
  });

  it("accepts a fresh scan for an active gym and creates a scans doc", async () => {
    await seedGym("g1", "active");
    const result = await scanGym.run(callAs("u1", {gymId: "g1", clientScanId: "c1", deviceId: "d1"}));
    expect(result).toMatchObject({ok: true, result: "accepted"});
    expect((result as {scanId?: string}).scanId).toBeTruthy();
    expect((result as {message?: string}).message).toBeTruthy();

    const scans = await db.collection("scans").where("userId", "==", "u1").get();
    expect(scans.size).toBe(1);
    expect(scans.docs[0].data().status).toBe("accepted");
  });

  it("returns already_processed for a retried scan with the same clientScanId (idempotency)", async () => {
    await seedGym("g1", "active");
    const first = await scanGym.run(callAs("u1", {gymId: "g1", clientScanId: "dup1"}));
    expect(first).toMatchObject({ok: true, result: "accepted"});

    const second = await scanGym.run(callAs("u1", {gymId: "g1", clientScanId: "dup1"}));
    expect(second).toMatchObject({ok: true, result: "already_processed"});
    expect((second as {message?: string}).message).toBeTruthy();

    const scans = await db.collection("scans").where("userId", "==", "u1").get();
    expect(scans.size).toBe(1);
  });

  it("returns cooldown when scanning the same gym again inside the cooldown window", async () => {
    await seedGym("g1", "active");
    await scanGym.run(callAs("u1", {gymId: "g1", clientScanId: "first"}));

    const second = await scanGym.run(callAs("u1", {gymId: "g1", clientScanId: "second"}));
    expect(second).toMatchObject({ok: false, result: "cooldown"});
    expect((second as {message?: string}).message).toMatch(/minute/i);

    const scans = await db.collection("scans").where("userId", "==", "u1").get();
    expect(scans.size).toBe(1);
  });

  it("allows a different user to check in to the same gym without hitting the first user's cooldown", async () => {
    await seedGym("g1", "active");
    await scanGym.run(callAs("u1", {gymId: "g1", clientScanId: "c1"}));

    const result = await scanGym.run(callAs("u2", {gymId: "g1", clientScanId: "c2"}));
    expect(result).toMatchObject({ok: true, result: "accepted"});
  });
});
