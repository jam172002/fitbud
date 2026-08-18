import * as admin from "firebase-admin";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {logger} from "firebase-functions/v2";
import {deleteQueryInBatches} from "./firestoreBatch";

/**
 * ---------------------------------------------------------------------------
 * Retention configuration
 * ---------------------------------------------------------------------------
 * One documented place for how long each category of data is kept, instead
 * of magic numbers scattered through the codebase. Where this repo has no
 * way to know a real legal/business requirement, that's stated explicitly
 * rather than invented - `periodDays: null` plus a `needsOwnerDecision` note
 * means "the project owner needs to set this," not "there is no limit."
 */
export interface RetentionCategory {
  purpose: string;
  /** Days after which a record becomes eligible for deletion/anonymization, or null if not automated. */
  periodDays: number | null;
  mechanism: string;
  exception: string;
}

export const RETENTION: Record<string, RetentionCategory> = {
  activeProfileAccountData: {
    purpose: "Operate the account (profile, matching, chat, sessions) while it's active.",
    periodDays: null,
    mechanism: "Kept for the life of the account; removed/de-identified by the account-deletion pipeline (accountDeletion.ts) on request.",
    exception: "None - this is user-initiated deletion, not a timed expiry.",
  },
  chatMedia: {
    purpose: "Message history and attachments between buddies/groups.",
    periodDays: null,
    mechanism: "Kept until a participant deletes the conversation for themselves, or until account deletion redacts messages that user authored.",
    exception: "No independent expiry job today. If you want chat auto-expiry, that's a product decision to make explicitly, not something this audit should assume.",
  },
  gymCheckins: {
    purpose: "Attendance history shown to the user, and per-gym daily visit counts for gym-side analytics.",
    periodDays: 730,
    mechanism: "Automated - see purgeExpiredGymScans below. Deletes the per-visit `scans` document; the already-incremented gym statsDaily aggregate counters are untouched, since they're not per-user-identifiable.",
    exception: "730 days (24 months) is a placeholder default, not a verified legal requirement - confirm the right number with the project owner and adjust the constant below.",
  },
  notificationTokens: {
    purpose: "Deliver push notifications to a device.",
    periodDays: null,
    mechanism: "Overwritten whenever a new token is registered (see AuthController.updateUserDeviceToken). No automated expiry job exists.",
    exception: "The current schema stores tokens as a flat `fcmTokens` array field on the user doc with no per-token last-seen timestamp, so there's nothing to query by staleness without a schema change (e.g. moving to the already-modeled but unused `users/{uid}/deviceTokens/{tokenId}` subcollection, which does have `lastSeenAt`). Not implemented here - flagged as a follow-up.",
  },
  paymentOrderRecords: {
    purpose: "Financial/audit trail for subscription purchases.",
    periodDays: null,
    mechanism: "Deliberately excluded from the account-deletion pipeline - `users/{uid}/subscriptions/*` is left untouched even when the rest of the account is deleted.",
    exception: "This repo has no basis for asserting a specific financial-record retention period for Pakistan. Treat `periodDays: null` here as \"retain until the project owner confirms a period with their accountant/legal counsel,\" not as \"no limit is needed.\"",
  },
  securityAuditRecords: {
    purpose: "Abuse investigation - UGC reports (moderation.ts) and account-deletion job records (accountDeletion.ts).",
    periodDays: 180,
    mechanism: "Not automated yet - flagged as a follow-up rather than implemented, to avoid deleting evidence needed for an in-progress moderation case without a human review step.",
    exception: "180 days is a placeholder default. Recommend a manual admin review step before any automated purge of report/audit records, given they may be needed for an active investigation.",
  },
  backups: {
    purpose: "Disaster recovery for Firestore/Storage.",
    periodDays: null,
    mechanism: "Unknown from this codebase - Firestore/Storage backup policy (if any) is configured at the GCP project level (Firebase Console > Firestore > Backups, or gcloud), not in this repository.",
    exception: "Needs verification directly in the Firebase/GCP console - this audit cannot see it.",
  },
};

/**
 * Scheduled, indexed, bounded cleanup for the one category above that's
 * automated today. Runs daily, processes at most a few bounded batches per
 * run (not a full-collection scan), and is safe to run again if a previous
 * run was interrupted - it always re-queries for "still-expired" records.
 */
export const purgeExpiredGymScans = onSchedule(
  {schedule: "every 24 hours", timeoutSeconds: 300},
  async () => {
    const days = RETENTION.gymCheckins.periodDays ?? 730;
    const cutoff = admin.firestore.Timestamp.fromMillis(
      Date.now() - days * 24 * 60 * 60 * 1000
    );
    const db = admin.firestore();

    // Bounded: at most 5 batches of 300 per run (1,500 docs/day) so a huge
    // backlog can't turn this into a runaway operation. It'll just take a
    // few days to fully catch up, then keep pace with new expirations.
    let totalDeleted = 0;
    for (let i = 0; i < 5; i++) {
      const query = db
        .collection("scans")
        .where("scannedAt", "<", cutoff)
        .orderBy("scannedAt")
        .limit(300);
      const deleted = await deleteQueryInBatches(query, 300);
      totalDeleted += deleted;
      if (deleted < 300) break;
    }

    logger.info("purgeExpiredGymScans complete", {
      deletedCount: totalDeleted,
      cutoffDays: days,
    });
  }
);
