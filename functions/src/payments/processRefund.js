const {https} = require("firebase-functions/v2");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {defineSecret} = require("firebase-functions/params");

const stripeSecret = defineSecret("STRIPE_SECRET_KEY");

module.exports = https.onCall(
  {secrets: [stripeSecret]},
  async (request) => {
    if (request.auth?.token?.role !== "developer") {
      throw new https.HttpsError("permission-denied", "Only developers can process refunds.");
    }

    const stripe = require("stripe")(stripeSecret.value());
    const {orderId, reason} = request.data;
    const db = getFirestore();
    const orderDoc = await db.collection("orders").doc(orderId).get();
    const order = orderDoc.data();

    if (!order.stripePaymentIntentId || order.paymentStatus !== "paid") {
      throw new https.HttpsError("failed-precondition", "Order not eligible for refund.");
    }

    const refund = await stripe.refunds.create({
      payment_intent: order.stripePaymentIntentId,
      reason: "requested_by_customer",
      reverse_transfer: true,
      refund_application_fee: true,
    });

    await db.collection("orders").doc(orderId).update({
      paymentStatus: "refunded",
      cancelReason: reason || "Refund processed",
      cancelledBy: "system",
      status: "cancelled",
      updatedAt: FieldValue.serverTimestamp(),
    });

    return {success: true, refundId: refund.id};
  },
);