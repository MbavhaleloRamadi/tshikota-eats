const { https } = require("firebase-functions/v2");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { defineSecret } = require("firebase-functions/params");

const stripeSecret = defineSecret("STRIPE_SECRET_KEY");

module.exports = https.onCall(
  { secrets: [stripeSecret] },
  async (request) => {
    if (request.auth?.token?.role !== "company") {
      throw new https.HttpsError("permission-denied", "Only company users can onboard.");
    }

    const businessId = request.auth.token.businessId;
    if (!businessId) {
      throw new https.HttpsError("failed-precondition", "No business linked to account.");
    }

    const stripe = require("stripe")(stripeSecret.value());
    const db = getFirestore();
    const bizDoc = await db.collection("businesses").doc(businessId).get();

    if (!bizDoc.exists) {
      throw new https.HttpsError("not-found", "Business not found.");
    }

    const biz = bizDoc.data();
    let stripeAccountId = biz.stripeAccountId;

    if (!stripeAccountId) {
      const account = await stripe.accounts.create({
        type: "express",
        country: "ZA",
        default_currency: "zar",
        email: biz.contactEmail,
        capabilities: {
          card_payments: { requested: true },
          transfers: { requested: true },
        },
        business_type: "individual",
        metadata: { businessId, platform: "tshikota_eats" },
      });

      stripeAccountId = account.id;
      await db.collection("businesses").doc(businessId).update({
        stripeAccountId,
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    const accountLink = await stripe.accountLinks.create({
      account: stripeAccountId,
      refresh_url: "https://tshikotaeats.co.za/company/stripe-refresh",
      return_url: "https://tshikotaeats.co.za/company/stripe-complete",
      type: "account_onboarding",
    });

    return { url: accountLink.url };
  }
);