import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

export const onMultiplyInvestment = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be authenticated"
      );
    }

    const role = context.auth.token.role;
    if (role !== "parent") {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only parents can multiply investments"
      );
    }

    const {familyId, childId, multiplier} = data;

    if (!familyId || !childId || multiplier === undefined) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required fields"
      );
    }

    if (multiplier <= 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Multiplier must be greater than 0"
      );
    }

    if (context.auth.token.familyId !== familyId) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Family ID mismatch"
      );
    }

    const batch = db.batch();

    const investmentBucketRef = db
      .collection("families")
      .doc(familyId)
      .collection("children")
      .doc(childId)
      .collection("buckets")
      .doc("investment");

    const bucketDoc = await investmentBucketRef.get();
    if (!bucketDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Bucket not found");
    }

    const currentBalance = bucketDoc.data()?.balance || 0;
    const newBalance = currentBalance * multiplier;

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
      performedBy: context.auth.uid,
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
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be authenticated"
      );
    }

    const role = context.auth.token.role;
    if (role !== "parent") {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only parents can donate charity"
      );
    }

    const {familyId, childId} = data;

    if (!familyId || !childId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing required fields"
      );
    }

    if (context.auth.token.familyId !== familyId) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Family ID mismatch"
      );
    }

    const batch = db.batch();

    const charityBucketRef = db
      .collection("families")
      .doc(familyId)
      .collection("children")
      .doc(childId)
      .collection("buckets")
      .doc("charity");

    const bucketDoc = await charityBucketRef.get();
    if (!bucketDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Bucket not found");
    }

    const previousBalance = bucketDoc.data()?.balance || 0;

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
      performedBy: context.auth.uid,
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
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Must be authenticated"
    );
  }

  const role = context.auth.token.role;
  if (role !== "parent") {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only parents can set money"
    );
  }

  const {familyId, childId, amount} = data;

  if (!familyId || !childId || amount === undefined) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing required fields"
    );
  }

  if (amount < 0) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Amount must be >= 0"
    );
  }

  if (context.auth.token.familyId !== familyId) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Family ID mismatch"
    );
  }

  const batch = db.batch();

  const moneyBucketRef = db
    .collection("families")
    .doc(familyId)
    .collection("children")
    .doc(childId)
    .collection("buckets")
    .doc("money");

  const bucketDoc = await moneyBucketRef.get();
  const previousBalance = bucketDoc.exists ?
    bucketDoc.data()?.balance || 0 :
    0;

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
    performedBy: context.auth.uid,
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

    const claims: {
      role?: string;
      familyId?: string;
      childId?: string;
    } = {};

    if (role) claims.role = role;
    if (familyId) claims.familyId = familyId;
    if (childId) claims.childId = childId;

    await admin.auth().setCustomUserClaims(userId, claims);

    return;
  });
