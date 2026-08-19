import * as admin from "firebase-admin";
import {CallableRequest} from "firebase-functions/v2/https";
import {initTestApp, clearFirestore, clearAuth} from "./emulator";
import {requestAccountDeletion, getAccountDeletionStatus} from "../accountDeletion";

let db: admin.firestore.Firestore;

beforeAll(() => {
  initTestApp();
  db = admin.firestore();
});

beforeEach(async () => {
  await clearFirestore();
  await clearAuth();
});

/**
 * Builds a CallableRequest as if `uid` had just signed in, so the
 * server-side reauth check passes by default.
 * @param {string} uid The calling user's uid.
 * @param {Record<string, unknown>} data The callable's `data` payload.
 * @param {number} authTimeSecondsAgo How long ago the simulated sign-in happened; drive above REAUTH_MAX_AGE_MINUTES to test the stale-session path.
 * @return {CallableRequest} A fake request suitable for `<exportedFn>.run(...)`.
 */
function callAs(uid: string, data: Record<string, unknown> = {}, authTimeSecondsAgo = 0): CallableRequest {
  const authTime = Math.floor(Date.now() / 1000) - authTimeSecondsAgo;
  const fakeRequest = {
    data,
    auth: {
      uid,
      token: {
        uid,
        aud: "fitbud-46f70",
        auth_time: authTime,
        exp: authTime + 3600,
        iat: authTime,
        iss: "https://securetoken.google.com/fitbud-46f70",
        sub: uid,
        firebase: {identities: {}, sign_in_provider: "password"},
      },
    },
    rawRequest: {},
  };
  return fakeRequest as unknown as CallableRequest;
}

async function seedUser(uid: string) {
  await db.collection("users").doc(uid).set({
    displayName: `User ${uid}`,
    email: `${uid}@example.com`,
    photoUrl: "https://example.com/photo.jpg",
    isActive: true,
    isProfileComplete: true,
  });
  await admin.auth().createUser({uid, email: `${uid}@example.com`});
}

describe("requestAccountDeletion", () => {
  it("rejects unauthenticated calls", async () => {
    await expect(
      requestAccountDeletion.run({data: {}, rawRequest: {}} as unknown as CallableRequest)
    ).rejects.toThrow(/signed in/i);
  });

  it("requires recent sign-in and reports REAUTH_REQUIRED when auth_time is stale", async () => {
    await seedUser("staleUser");
    await expect(
      requestAccountDeletion.run(callAs("staleUser", {}, 60 * 60)) // 1 hour ago > 15 min max
    ).rejects.toThrow(/REAUTH_REQUIRED/);
  });

  it("de-identifies the profile, deletes personal subcollections, and deletes the Auth user", async () => {
    const uid = "soloUser";
    await seedUser(uid);
    await db.collection("users").doc(uid).collection("settings").doc("prefs").set({theme: "dark"});
    await db.collection("users").doc(uid).collection("addresses").doc("home").set({line1: "123 St"});
    await db.collection("users").doc(uid).collection("notifications").doc("n1").set({title: "hi"});

    const result = await requestAccountDeletion.run(callAs(uid));
    expect(result).toEqual({ok: true, status: "completed"});

    const profile = await db.collection("users").doc(uid).get();
    expect(profile.exists).toBe(true);
    expect(profile.data()?.displayName).toBe("Deleted User");
    expect(profile.data()?.photoUrl).toBe("");
    expect(profile.data()?.isActive).toBe(false);
    expect(profile.data()?.email).toBeUndefined();

    const settings = await db.collection("users").doc(uid).collection("settings").get();
    const addresses = await db.collection("users").doc(uid).collection("addresses").get();
    const notifications = await db.collection("users").doc(uid).collection("notifications").get();
    expect(settings.empty).toBe(true);
    expect(addresses.empty).toBe(true);
    expect(notifications.empty).toBe(true);

    await expect(admin.auth().getUser(uid)).rejects.toThrow(/no user record|not-found/i);

    const job = await db.collection("accountDeletions").doc(uid).get();
    expect(job.data()?.status).toBe("completed");
  });

  it("redacts messages the user authored but keeps the conversation and the other participant's copy intact", async () => {
    const uid = "chatUserA";
    const otherUid = "chatUserB";
    await seedUser(uid);
    await seedUser(otherUid);

    const conversationId = "conv1";
    await db.doc(`conversations/${conversationId}`).set({participantIds: [uid, otherUid]});
    await db.doc(`conversations/${conversationId}/participants/${uid}`).set({userId: uid});
    await db.doc(`conversations/${conversationId}/participants/${otherUid}`).set({userId: otherUid});
    await db.doc(`users/${uid}/inbox/${conversationId}`).set({conversationId});
    const myMsg = db.collection(`conversations/${conversationId}/messages`).doc();
    await myMsg.set({senderUserId: uid, text: "secret plan", isDeleted: false});
    const theirMsg = db.collection(`conversations/${conversationId}/messages`).doc();
    await theirMsg.set({senderUserId: otherUid, text: "reply", isDeleted: false});

    await requestAccountDeletion.run(callAs(uid));

    const myMsgAfter = await myMsg.get();
    expect(myMsgAfter.data()?.isDeleted).toBe(true);
    expect(myMsgAfter.data()?.text).toBe("");

    const theirMsgAfter = await theirMsg.get();
    expect(theirMsgAfter.data()?.text).toBe("reply");
    expect(theirMsgAfter.data()?.isDeleted).toBe(false);

    const myParticipant = await db.doc(`conversations/${conversationId}/participants/${uid}`).get();
    expect(myParticipant.exists).toBe(false);
    const theirParticipant = await db.doc(`conversations/${conversationId}/participants/${otherUid}`).get();
    expect(theirParticipant.exists).toBe(true);

    const conversation = await db.doc(`conversations/${conversationId}`).get();
    expect(conversation.exists).toBe(true);
  });

  it("hard-deletes friendships and buddy requests involving the user, in both directions", async () => {
    const uid = "buddyUserA";
    const otherUid = "buddyUserB";
    await seedUser(uid);
    await seedUser(otherUid);

    await db.collection("friendships").doc("f1").set({userIds: [uid, otherUid]});
    await db.collection("buddyRequests").doc("r1").set({fromUserId: uid, toUserId: otherUid, status: "pending"});
    await db.collection("buddyRequests").doc("r2").set({fromUserId: otherUid, toUserId: uid, status: "pending"});

    await requestAccountDeletion.run(callAs(uid));

    expect((await db.collection("friendships").get()).empty).toBe(true);
    expect((await db.collection("buddyRequests").get()).empty).toBe(true);
  });

  it("removes group membership and decrements memberCount without deleting the group", async () => {
    const uid = "groupUser";
    const otherUid = "groupUser2";
    await seedUser(uid);
    await seedUser(otherUid);

    await db.collection("groups").doc("g1").set({name: "Runners", memberCount: 2});
    await db.doc("groups/g1/members/" + uid).set({userId: uid});
    await db.doc("groups/g1/members/" + otherUid).set({userId: otherUid});
    await db.doc(`users/${uid}/groupMemberships/g1`).set({groupId: "g1"});
    await db.doc(`conversations/group_g1/participants/${uid}`).set({userId: uid});

    await requestAccountDeletion.run(callAs(uid));

    const group = await db.collection("groups").doc("g1").get();
    expect(group.exists).toBe(true);
    expect(group.data()?.memberCount).toBe(1);
    const member = await db.doc("groups/g1/members/" + uid).get();
    expect(member.exists).toBe(false);
    const membership = await db.doc(`users/${uid}/groupMemberships/g1`).get();
    expect(membership.exists).toBe(false);
  });

  it("deletes an owned session with no other participants, but keeps one that others joined", async () => {
    const uid = "sessionOwner";
    const otherUid = "sessionJoiner";
    await seedUser(uid);
    await seedUser(otherUid);

    await db.collection("sessions").doc("soloSession").set({createdByUserId: uid});
    await db.collection("sessions").doc("sharedSession").set({createdByUserId: uid});
    await db.doc("sessions/sharedSession/participants/" + otherUid).set({userId: otherUid});

    await requestAccountDeletion.run(callAs(uid));

    const solo = await db.collection("sessions").doc("soloSession").get();
    expect(solo.exists).toBe(false);
    const shared = await db.collection("sessions").doc("sharedSession").get();
    expect(shared.exists).toBe(true);
  });

  it("deletes gym check-in (scans) history for the user", async () => {
    const uid = "scanUser";
    await seedUser(uid);
    await db.collection("scans").doc("s1").set({userId: uid, gymId: "g1"});
    await db.collection("scans").doc("s2").set({userId: "someoneElse", gymId: "g1"});

    await requestAccountDeletion.run(callAs(uid));

    const mine = await db.collection("scans").doc("s1").get();
    expect(mine.exists).toBe(false);
    const theirs = await db.collection("scans").doc("s2").get();
    expect(theirs.exists).toBe(true);
  });

  it("does NOT touch subscriptions/order records (payment retention exception)", async () => {
    const uid = "payingUser";
    await seedUser(uid);
    await db.doc(`users/${uid}/subscriptions/order1`).set({status: "paid", amount: 999});

    await requestAccountDeletion.run(callAs(uid));

    const sub = await db.doc(`users/${uid}/subscriptions/order1`).get();
    expect(sub.exists).toBe(true);
    expect(sub.data()?.status).toBe("paid");
  });

  it("deletes the user's Storage files under users/{uid}/", async () => {
    const uid = "storageUser";
    await seedUser(uid);
    const bucket = admin.storage().bucket();
    const file = bucket.file(`users/${uid}/profile.jpg`);
    await file.save(Buffer.from("fake-image-bytes"), {contentType: "image/jpeg"});
    expect((await file.exists())[0]).toBe(true);

    await requestAccountDeletion.run(callAs(uid));

    expect((await file.exists())[0]).toBe(false);
  });

  it("is idempotent: calling twice after completion returns alreadyDone without re-running the pipeline", async () => {
    const uid = "idempotentUser";
    await seedUser(uid);

    const first = await requestAccountDeletion.run(callAs(uid));
    expect(first).toEqual({ok: true, status: "completed"});

    // Auth user is gone now, but the callable only trusts req.auth.uid (which
    // a client can't fabricate for someone else's account) - simulate the
    // retry the way the client would actually trigger one, by reusing the uid.
    const second = await requestAccountDeletion.run(callAs(uid));
    expect(second).toEqual({ok: true, status: "completed", alreadyDone: true});
  });

  it("marks the job failed (not completed) and rethrows if a pipeline step throws", async () => {
    const uid = "failingUser";
    await seedUser(uid);

    const storageService = admin.storage();
    const spy = jest.spyOn(storageService, "bucket").mockImplementation(() => {
      throw new Error("simulated storage outage");
    });

    await expect(requestAccountDeletion.run(callAs(uid))).rejects.toThrow(/internal/i);

    const job = await db.collection("accountDeletions").doc(uid).get();
    expect(job.data()?.status).toBe("failed");
    expect(job.data()?.error).toMatch(/simulated storage outage/);

    spy.mockRestore();
  });
});

describe("getAccountDeletionStatus", () => {
  it("returns status 'none' when no job exists", async () => {
    await seedUser("neverDeleted");
    const result = await getAccountDeletionStatus.run(callAs("neverDeleted"));
    expect(result).toEqual({status: "none"});
  });

  it("returns the job status after a completed deletion", async () => {
    const uid = "checkStatusUser";
    await seedUser(uid);
    await requestAccountDeletion.run(callAs(uid));
    const result = await getAccountDeletionStatus.run(callAs(uid));
    expect(result).toEqual({status: "completed", error: null});
  });

  it("rejects unauthenticated calls", async () => {
    await expect(
      getAccountDeletionStatus.run({data: {}, rawRequest: {}} as unknown as CallableRequest)
    ).rejects.toThrow(/signed in/i);
  });
});
