const { https } = require("firebase-functions/v2");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { defineSecret } = require("firebase-functions/params");

const stripeSecret = defineSecret("STRIPE_SECRET_KEY");

module.exports = https.onCall(
  { secrets: [stripeSecret] },
  async (request) => {
    if (!request.auth) {
      throw new https.HttpsError("unauthenticated", "Must be logged in.");
    }

    const stripe = require("stripe")(stripeSecret.value());
    const { orderId } = request.data;

    if (!orderId) {
      throw new https.HttpsError("invalid-argument", "orderId required.");
    }

    const db = getFirestore();
    const orderDoc = await db.collection("orders").doc(orderId).get();

    if (!orderDoc.exists) {
      throw new https.HttpsError("not-found", "Order not found.");
    }

    const order = orderDoc.data();

    if (order.buyerId !== request.auth.uid) {
      throw new https.HttpsError("permission-denied", "Not your order.");
    }
    if (order.paymentMethod !== "online" || order.paymentStatus !== "pending") {
      throw new https.HttpsError("failed-precondition", "Order not eligible for payment.");
    }

    const bizDoc = await db.collection("businesses").doc(order.businessId).get();
    const biz = bizDoc.data();

    if (!biz.stripeAccountId || !biz.stripeOnboardingComplete) {
      throw new https.HttpsError("failed-precondition", "Vendor hasn't set up payments.");
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount: order.total,
      currency: "zar",
      application_fee_amount: order.platformFee, // R5.00 = 500 cents
      transfer_data: {
        destination: biz.stripeAccountId,
      },
      metadata: {
        orderId,
        businessId: order.businessId,
        buyerId: order.buyerId,
        orderNumber: order.orderNumber,
      },
      receipt_email: order.buyerEmail,
    });

    await db.collection("orders").doc(orderId).update({
      stripePaymentIntentId: paymentIntent.id,
      updatedAt: FieldValue.serverTimestamp(),
    });

    return { clientSecret: paymentIntent.client_secret };
  }
);