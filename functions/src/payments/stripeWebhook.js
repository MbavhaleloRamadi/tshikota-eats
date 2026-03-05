const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");
const { sendNotification } = require("../notifications/sendNotification");

const stripeSecret = defineSecret("STRIPE_SECRET_KEY");
const webhookSecret = defineSecret("STRIPE_WEBHOOK_SECRET");

module.exports = onRequest(
  {
    region: "europe-west1",
    secrets: [stripeSecret, webhookSecret],
    cors: false,
  },
  async (req, res) => {
    if (req.method !== "POST") {
      return res.status(405).send("Method not allowed");
    }

    const stripe = require("stripe")(stripeSecret.value());
    const sig = req.headers["stripe-signature"];

    let event;
    try {
      event = stripe.webhooks.constructEvent(req.rawBody, sig, webhookSecret.value());
    } catch (err) {
      console.error("Webhook sig verification failed:", err.message);
      return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    const db = admin.firestore();

    try {
      switch (event.type) {
        case "payment_intent.succeeded": {
          const pi = event.data.object;
          const orderId = pi.metadata.orderId;
          if (orderId) {
            await db.collection("orders").doc(orderId).update({
              paymentStatus: "paid",
              updatedAt: FieldValue.serverTimestamp(),
              statusHistory: FieldValue.arrayUnion({
                status: "payment_confirmed",
                timestamp: new Date().toISOString(),
                updatedBy: "system",
              }),
            });
            // Notify buyer
            await sendNotification(
              pi.metadata.buyerId,
              "Payment Confirmed 💳",
              `Your payment of R${(pi.amount / 100).toFixed(2)} was successful.`,
              "payment_confirmed",
              { orderId }
            );
            // Notify vendor
            const bizDoc = await db.collection("businesses").doc(pi.metadata.businessId).get();
            if (bizDoc.exists) {
              await sendNotification(
                bizDoc.data().ownerId,
                "New Paid Order! 🛒",
                `Order ${pi.metadata.orderNumber || orderId} — R${(pi.amount / 100).toFixed(2)}`,
                "order_new",
                { orderId, businessId: pi.metadata.businessId }
              );
            }
          }
          break;
        }

        case "payment_intent.payment_failed": {
          const pi = event.data.object;
          const orderId = pi.metadata.orderId;
          if (orderId) {
            await db.collection("orders").doc(orderId).update({
              paymentStatus: "failed",
              updatedAt: FieldValue.serverTimestamp(),
            });
          }
          break;
        }

        case "account.updated": {
          const account = event.data.object;
          const businessId = account.metadata?.businessId;
          if (businessId) {
            await db.collection("businesses").doc(businessId).update({
              stripeOnboardingComplete: account.charges_enabled === true,
              updatedAt: FieldValue.serverTimestamp(),
            });
          }
          break;
        }
      }
    } catch (err) {
      console.error("Webhook processing error:", err);
      // Still return 200 to prevent Stripe retries for processing errors
    }

    res.json({ received: true });
  }
);