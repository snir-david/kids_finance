import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

// ── Shared helpers ────────────────────────────────────────────────────────────

/**
 * Asserts the caller is authenticated with the 'parent' role.
 * Throws an HttpsError otherwise.
 */
function assertParentAuth(context: functions.https.CallableContext): void {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Must be authenticated"
    );
  }
  if (context.auth.token.role !== "parent") {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only parents can perform this action"
    );
  }
}

/**
 * Verifies that the authenticated caller is actually in the target family's
 * parentIds array in Firestore. This prevents a malicious user from
 * manipulating their own userProfile.familyId JWT claim to access another
 * family's data.
 */
async function assertFamilyMembership(
  uid: string,
  familyId: string
): Promise<void> {
  const familyDoc = await db.collection("families").doc(familyId).get();
  if (!familyDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Family not found");
  }
  const parentIds = (familyDoc.data()?.parentIds as string[]) ?? [];
  if (!parentIds.includes(uid)) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "You are not a member of this family"
    );
  }
}

/**
 * Asserts a value is a non-empty string.
 */
function assertNonEmptyString(value: unknown, fieldName: string): void {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `${fieldName} must be a non-empty string`
    );
  }
}

// ── Cloud Functions ───────────────────────────────────────────────────────────

export const onMultiplyInvestment = functions.https.onCall(
  async (data, context) => {
    assertParentAuth(context);

    const {familyId, childId, multiplier} = data;

    assertNonEmptyString(familyId, "familyId");
    assertNonEmptyString(childId, "childId");

    if (
      multiplier === undefined ||
      multiplier === null ||
      typeof multiplier !== "number" ||
      !isFinite(multiplier) ||
      multiplier <= 0
    ) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "multiplier must be a finite number greater than 0"
      );
    }

    // Verify Firestore family membership (not just the JWT claim).
    await assertFamilyMembership(context.auth!.uid, familyId);

    const investmentBucketRef = db
      .collection("families")
      .doc(familyId)
      .collection("children")
      .doc(childId)
      .collection("buckets")
      .doc("investment");

    const bucketDoc = await investmentBucketRef.get();
    if (!bucketDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Investment bucket not found");
    }

    const currentBalance: number = bucketDoc.data()?.balance ?? 0;
    const newBalance = currentBalance * multiplier;

    if (newBalance < currentBalance) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Multiplier must not decrease the investment balance"
      );
    }

    const batch = db.batch();

    batch.update(investmentBucketRef, {
      balance: newBalance,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const transactionRef = db
      .collection("families")
      .doc(familyId)
      .collection("transactions")
      .doc();

    batch.set(transactionRef, {
      type: "investment",
      childId,
      multiplier,
      previousBalance: currentBalance,
      newBalance,
      performedBy: context.auth!.uid,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    await batch.commit();

    return {
      success: true,
      newBalance,
      transactionId: transactionRef.id,
    };
  }
);

export const onDonateCharity = functions.https.onCall(
  async (data, context) => {
    assertParentAuth(context);

    const {familyId, childId} = data;

    assertNonEmptyString(familyId, "familyId");
    assertNonEmptyString(childId, "childId");

    await assertFamilyMembership(context.auth!.uid, familyId);

    const charityBucketRef = db
      .collection("families")
      .doc(familyId)
      .collection("children")
      .doc(childId)
      .collection("buckets")
      .doc("charity");

    const bucketDoc = await charityBucketRef.get();
    if (!bucketDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Charity bucket not found");
    }

    const previousBalance: number = bucketDoc.data()?.balance ?? 0;

    if (previousBalance <= 0) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Charity bucket is already empty"
      );
    }

    const batch = db.batch();

    batch.update(charityBucketRef, {
      balance: 0,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const transactionRef = db
      .collection("families")
      .doc(familyId)
      .collection("transactions")
      .doc();

    batch.set(transactionRef, {
      type: "charity_donation",
      childId,
      previousBalance,
      newBalance: 0,
      performedBy: context.auth!.uid,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    await batch.commit();

    return {
      success: true,
      amountDonated: previousBalance,
      transactionId: transactionRef.id,
    };
  }
);

export const onSetMoney = functions.https.onCall(async (data, context) => {
  assertParentAuth(context);

  const {familyId, childId, amount} = data;

  assertNonEmptyString(familyId, "familyId");
  assertNonEmptyString(childId, "childId");

  if (
    amount === undefined ||
    amount === null ||
    typeof amount !== "number" ||
    !isFinite(amount) ||
    amount < 0
  ) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "amount must be a finite number >= 0"
    );
  }

  await assertFamilyMembership(context.auth!.uid, familyId);

  const moneyBucketRef = db
    .collection("families")
    .doc(familyId)
    .collection("children")
    .doc(childId)
    .collection("buckets")
    .doc("money");

  const bucketDoc = await moneyBucketRef.get();
  const previousBalance: number = bucketDoc.exists ?
    bucketDoc.data()?.balance ?? 0 :
    0;

  const batch = db.batch();

  batch.set(
    moneyBucketRef,
    {
      balance: amount,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {merge: true}
  );

  const transactionRef = db
    .collection("families")
    .doc(familyId)
    .collection("transactions")
    .doc();

  batch.set(transactionRef, {
    type: "set_money",
    childId,
    previousBalance,
    newBalance: amount,
    performedBy: context.auth!.uid,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  await batch.commit();

  return {
    success: true,
    newBalance: amount,
    transactionId: transactionRef.id,
  };
});

export const onSetCustomClaims = functions.firestore
  .document("userProfiles/{userId}")
  .onWrite(async (change, context) => {
    const userId = context.params.userId;

    if (!change.after.exists) {
      await admin.auth().setCustomUserClaims(userId, null);
      return;
    }

    const userData = change.after.data();
    const role = userData?.role;
    const familyId = userData?.familyId;
    const childId = userData?.childId;

    // Only the 'parent' role is valid for Firebase Auth accounts.
    // Children authenticate locally via PIN and do not have Firebase Auth accounts.
    const validRoles = ["parent"];
    if (role && !validRoles.includes(role)) {
      functions.logger.warn(
        `onSetCustomClaims: rejected invalid role '${role}' for user ${userId}`
      );
      await admin.auth().setCustomUserClaims(userId, {});
      return;
    }

    const claims: {
      role?: string;
      familyId?: string;
      childId?: string;
    } = {};

    if (role) claims.role = role;
    if (familyId && typeof familyId === "string") claims.familyId = familyId;
    if (childId && typeof childId === "string") claims.childId = childId;

    await admin.auth().setCustomUserClaims(userId, claims);
  });

// ── Allowance Scheduler ───────────────────────────────────────────────────────

/**
 * Advances a nextRunAt date by one period based on frequency.
 */
function advanceNextRunAt(
  frequency: string,
  dayOfWeek: number,
  current: Date
): Date {
  const next = new Date(current);
  switch (frequency) {
    case "weekly":
      next.setDate(next.getDate() + 7);
      break;
    case "biweekly":
      next.setDate(next.getDate() + 14);
      break;
    case "monthly":
      next.setMonth(next.getMonth() + 1);
      // Keep the same day-of-month (clamped at 28)
      next.setDate(Math.min(dayOfWeek, 28));
      break;
    default:
      next.setDate(next.getDate() + 7);
  }
  return next;
}

/**
 * Callable function: processes all overdue allowance schedules for a family.
 * Called by the parent app when the home screen opens.
 * Returns { processed: number } — count of schedules that were distributed.
 *
 * To run automatically without user interaction, upgrade to Firebase Blaze
 * plan and convert to a functions.pubsub.schedule() cron trigger.
 */
export const processScheduledAllowances = functions.https.onCall(
  async (data, context) => {
    assertParentAuth(context);

    const familyId = data?.familyId as string | undefined;
    if (!familyId || typeof familyId !== "string" || familyId.trim() === "") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "familyId is required"
      );
    }

    await assertFamilyMembership(context.auth!.uid, familyId);

    const now = admin.firestore.Timestamp.now();

    // Query all active schedules for this family that are due
    const schedulesSnap = await db
      .collection("families")
      .doc(familyId)
      .collection("schedules")
      .where("isActive", "==", true)
      .where("nextRunAt", "<=", now)
      .get();

    if (schedulesSnap.empty) return { processed: 0 };

    let processed = 0;

    for (const schedDoc of schedulesSnap.docs) {
      const sched = schedDoc.data();
      const childId = sched.childId as string;
      const amount = sched.amount as number;

      // Default 70/20/10 split
      const moneyAmt = Math.round(amount * 70) / 100;
      const investAmt = Math.round(amount * 20) / 100;
      const charityAmt = Math.round(amount * 10) / 100;

      const childRef = db
        .collection("families")
        .doc(familyId)
        .collection("children")
        .doc(childId);

      const moneyRef = childRef.collection("buckets").doc("money");
      const investRef = childRef.collection("buckets").doc("investment");
      const charityRef = childRef.collection("buckets").doc("charity");

      const [moneyDoc, investDoc, charityDoc] = await Promise.all([
        moneyRef.get(),
        investRef.get(),
        charityRef.get(),
      ]);

      const moneyBal = (moneyDoc.data()?.balance ?? 0) as number;
      const investBal = (investDoc.data()?.balance ?? 0) as number;
      const charityBal = (charityDoc.data()?.balance ?? 0) as number;

      const batch = db.batch();

      // Update bucket balances
      batch.update(moneyRef, {
        balance: moneyBal + moneyAmt,
        lastUpdatedAt: now,
      });
      batch.update(investRef, {
        balance: investBal + investAmt,
        lastUpdatedAt: now,
      });
      batch.update(charityRef, {
        balance: charityBal + charityAmt,
        lastUpdatedAt: now,
      });

      // Create one transaction record per bucket
      const txBase = {
        childId,
        type: "distributed",
        performedByUid: "scheduler",
        scheduleId: schedDoc.id,
        performedAt: now,
      };

      for (const [bucketType, bucketAmt, prevBal] of [
        ["money", moneyAmt, moneyBal],
        ["investment", investAmt, investBal],
        ["charity", charityAmt, charityBal],
      ] as [string, number, number][]) {
        const txRef = db
          .collection("families")
          .doc(familyId)
          .collection("transactions")
          .doc();
        batch.set(txRef, {
          ...txBase,
          bucketType,
          amount: bucketAmt,
          previousBalance: prevBal,
          newBalance: prevBal + bucketAmt,
          familyId,
        });
      }

      // Advance nextRunAt by one period
      const nextRunAt = advanceNextRunAt(
        sched.frequency as string,
        sched.dayOfWeek as number,
        (sched.nextRunAt as admin.firestore.Timestamp).toDate()
      );
      batch.update(schedDoc.ref, {
        nextRunAt: admin.firestore.Timestamp.fromDate(nextRunAt),
      });

      await batch.commit();
      processed++;
    }

    functions.logger.info(
      `processScheduledAllowances: processed ${processed} schedule(s) for family ${familyId}`
    );
    return { processed };
  }
);
