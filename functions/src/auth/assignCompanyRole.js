const { https } = require("firebase-functions/v2");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

module.exports = https.onCall(async (request) => {
  if (request.auth?.token?.role !== "developer") {
    throw new https.HttpsError("permission-denied", "Only the developer can assign roles.");
  }

  const { targetUid, businessId } = request.data;

  if (!targetUid || !businessId) {
    throw new https.HttpsError("invalid-argument", "targetUid and businessId are required.");
  }

  const db = getFirestore();

  // Verify business exists
  const bizDoc = await db.collection("businesses").doc(businessId).get();
  if (!bizDoc.exists) {
    throw new https.HttpsError("not-found", "Business not found.");
  }

  // Set claims
  await getAuth().setCustomUserClaims(targetUid, {
    role: "company",
    businessId: businessId,
  });

  // Update user doc
  await db.collection("users").doc(targetUid).update({
    role: "company",
    businessId: businessId,
    updatedAt: FieldValue.serverTimestamp(),
  });

  // Update business owner
  await db.collection("businesses").doc(businessId).update({
    ownerId: targetUid,
    updatedAt: FieldValue.serverTimestamp(),
  });

  // Update analytics
  await db.collection("analytics").doc("platform").set({
    totalBuyers: FieldValue.increment(-1),
    totalCompanys: FieldValue.increment(1),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });

  return { success: true };
});