const { https } = require("firebase-functions/v2");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

const VALID_TRANSITIONS = {
  pending: ["accepted", "rejected", "cancelled"],
  accepted: ["preparing", "cancelled"],
  preparing: ["ready", "cancelled"],
  ready: ["completed", "cancelled"],
};

module.exports = https.onCall(async (request) => {
  if (!request.auth) {
    throw new https.HttpsError("unauthenticated", "Must be logged in.");
  }

  const { orderId, newStatus, reason, estimatedReadyTime } = request.data;

  if (!orderId || !newStatus) {
    throw new https.HttpsError("invalid-argument", "orderId and newStatus required.");
  }

  const db = getFirestore();
  const orderRef = db.collection("orders").doc(orderId);
  const orderDoc = await orderRef.get();

  if (!orderDoc.exists) {
    throw new https.HttpsError("not-found", "Order not found.");
  }

  const order = orderDoc.data();
  const role = request.auth.token.role;
  const userBizId = request.auth.token.businessId;

  // Permission check
  if (role === "company" && order.businessId !== userBizId) {
    throw new https.HttpsError("permission-denied", "Not your order.");
  }
  if (role === "buyer" && order.buyerId !== request.auth.uid) {
    throw new https.HttpsError("permission-denied", "Not your order.");
  }

  // Buyers can only cancel pending orders
  if (role === "buyer" && (newStatus !== "cancelled" || order.status !== "pending")) {
    throw new https.HttpsError("permission-denied", "Buyers can only cancel pending orders.");
  }

  // Validate transition
  const allowed = VALID_TRANSITIONS[order.status];
  if (!allowed || !allowed.includes(newStatus)) {
    throw new https.HttpsError(
      "failed-precondition",
      `Cannot transition from "${order.status}" to "${newStatus}".`
    );
  }

  const updateData = {
    status: newStatus,
    updatedAt: FieldValue.serverTimestamp(),
    statusHistory: FieldValue.arrayUnion({
      status: newStatus,
      timestamp: new Date().toISOString(),
      updatedBy: request.auth.uid,
    }),
  };

  if (newStatus === "cancelled") {
    updateData.cancelReason = reason || "No reason provided";
    updateData.cancelledBy = role;
  }
  if (newStatus === "rejected") {
    updateData.cancelReason = reason || "Vendor declined the order";
    updateData.cancelledBy = "company";
  }
  if (newStatus === "accepted" && estimatedReadyTime) {
    updateData.estimatedReadyTime = estimatedReadyTime;
  }
  if (newStatus === "ready") {
    updateData.actualReadyTime = FieldValue.serverTimestamp();
  }

  await orderRef.update(updateData);

  return { success: true, orderId, newStatus };
});