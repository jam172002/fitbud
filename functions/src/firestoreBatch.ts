import * as admin from "firebase-admin";

/**
 * Deletes every document matched by `query`, in bounded batches, retrying
 * safely if called again (a query that returns zero docs is a no-op).
 * Used for filtered deletes that `recursiveDelete` can't express (e.g.
 * "messages where senderUserId == uid" inside someone else's conversation).
 * @param {admin.firestore.Query} query Query selecting the docs to delete.
 * @param {number} batchSize Max docs deleted per Firestore batch commit.
 * @return {Promise<number>} Total number of documents deleted.
 */
export async function deleteQueryInBatches(
  query: admin.firestore.Query,
  batchSize = 300
): Promise<number> {
  let deleted = 0;
  for (;;) {
    const snap = await query.limit(batchSize).get();
    if (snap.empty) break;
    const batch = query.firestore.batch();
    for (const doc of snap.docs) batch.delete(doc.ref);
    await batch.commit();
    deleted += snap.size;
    if (snap.size < batchSize) break;
  }
  return deleted;
}

/**
 * Applies `patch` to every document matched by `query`, in bounded batches.
 * Used for de-identification (scrub a name/photo snapshot) rather than
 * deletion, e.g. session invites the departing user sent to someone else.
 * @param {admin.firestore.Query} query Query selecting the docs to update.
 * @param {admin.firestore.UpdateData<admin.firestore.DocumentData>} patch Fields to apply to every matched doc.
 * @param {number} batchSize Max docs updated per Firestore batch commit.
 * @return {Promise<number>} Total number of documents updated.
 */
export async function updateQueryInBatches(
  query: admin.firestore.Query,
  patch: admin.firestore.UpdateData<admin.firestore.DocumentData>,
  batchSize = 300
): Promise<number> {
  let updated = 0;
  for (;;) {
    const snap = await query.limit(batchSize).get();
    if (snap.empty) break;
    const batch = query.firestore.batch();
    for (const doc of snap.docs) batch.update(doc.ref, patch);
    await batch.commit();
    updated += snap.size;
    if (snap.size < batchSize) break;
  }
  return updated;
}
