import * as admin from "firebase-admin";
import {initTestApp, clearFirestore} from "./emulator";
import {deleteQueryInBatches, updateQueryInBatches} from "../firestoreBatch";

let db: admin.firestore.Firestore;

beforeAll(() => {
  initTestApp();
  db = admin.firestore();
});

beforeEach(async () => {
  await clearFirestore();
});

describe("deleteQueryInBatches", () => {
  it("deletes every matching document and leaves non-matching ones alone", async () => {
    const col = db.collection("scans");
    for (let i = 0; i < 5; i++) {
      await col.doc(`match-${i}`).set({userId: "u1"});
    }
    await col.doc("other").set({userId: "u2"});

    const deleted = await deleteQueryInBatches(col.where("userId", "==", "u1"), 300);

    expect(deleted).toBe(5);
    const remaining = await col.get();
    expect(remaining.docs.map((d) => d.id)).toEqual(["other"]);
  });

  it("pages across multiple batches when the result set exceeds batchSize", async () => {
    const col = db.collection("scans");
    for (let i = 0; i < 7; i++) {
      await col.doc(`d${i}`).set({userId: "u1"});
    }

    const deleted = await deleteQueryInBatches(col.where("userId", "==", "u1"), 3);

    expect(deleted).toBe(7);
    const remaining = await col.get();
    expect(remaining.empty).toBe(true);
  });

  it("is a safe no-op when nothing matches (retry-safety)", async () => {
    const col = db.collection("scans");
    const deleted = await deleteQueryInBatches(col.where("userId", "==", "nobody"), 300);
    expect(deleted).toBe(0);
  });
});

describe("updateQueryInBatches", () => {
  it("applies the patch to every matching document only", async () => {
    const col = db.collection("messages");
    await col.doc("m1").set({senderUserId: "u1", text: "hello"});
    await col.doc("m2").set({senderUserId: "u1", text: "world"});
    await col.doc("m3").set({senderUserId: "u2", text: "untouched"});

    const updated = await updateQueryInBatches(
      col.where("senderUserId", "==", "u1"),
      {text: "", isDeleted: true},
      300
    );

    expect(updated).toBe(2);
    const m1 = await col.doc("m1").get();
    const m2 = await col.doc("m2").get();
    const m3 = await col.doc("m3").get();
    expect(m1.data()?.isDeleted).toBe(true);
    expect(m1.data()?.text).toBe("");
    expect(m2.data()?.isDeleted).toBe(true);
    expect(m3.data()?.text).toBe("untouched");
    expect(m3.data()?.isDeleted).toBeUndefined();
  });
});
