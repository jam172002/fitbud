import * as admin from "firebase-admin";

/**
 * Shared emulator test project id. `firebase emulators:exec` sets
 * GCLOUD_PROJECT to the project configured in .firebaserc, but tests set it
 * explicitly here too so they still work if run outside that wrapper against
 * manually-started emulators.
 */
export const TEST_PROJECT_ID = process.env.GCLOUD_PROJECT || "fitbud-46f70";

/**
 * Initializes the Admin SDK against the local emulators exactly once per
 * test process. Safe to call from multiple test files, and safe even when
 * `../index` has already run `admin.initializeApp()` as an import side
 * effect (importing `scanGym` does this) - the default app is a singleton,
 * so this just reuses it rather than re-initializing.
 * @return {admin.app.App} The default Admin SDK app, connected to the local emulators.
 */
export function initTestApp(): admin.app.App {
  if (admin.apps.length === 0) {
    if (!process.env.FIRESTORE_EMULATOR_HOST) {
      throw new Error(
        "FIRESTORE_EMULATOR_HOST is not set - these tests must run via " +
        "`npm test`, which wraps them in `firebase emulators:exec`."
      );
    }
    admin.initializeApp({
      projectId: TEST_PROJECT_ID,
      storageBucket: `${TEST_PROJECT_ID}.appspot.com`,
    });
  }
  return admin.app();
}

/** Wipes all Firestore documents in the emulator so each test starts clean. */
export async function clearFirestore(): Promise<void> {
  const res = await fetch(
    `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${TEST_PROJECT_ID}/databases/(default)/documents`,
    {method: "DELETE"}
  );
  if (!res.ok) {
    throw new Error(`Failed to clear Firestore emulator: ${res.status} ${await res.text()}`);
  }
}

/** Deletes all Auth users in the emulator so each test starts clean. */
export async function clearAuth(): Promise<void> {
  const host = process.env.FIREBASE_AUTH_EMULATOR_HOST;
  if (!host) return;
  const res = await fetch(
    `http://${host}/emulator/v1/projects/${TEST_PROJECT_ID}/accounts`,
    {method: "DELETE", headers: {Authorization: "Bearer owner"}}
  );
  if (!res.ok) {
    throw new Error(`Failed to clear Auth emulator: ${res.status} ${await res.text()}`);
  }
}
