const {beforeUserSignedIn} = require("firebase-functions/v2/identity");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");

module.exports = beforeUserSignedIn(async (event) => {
  const user = event.data;
  const db = getFirestore();

  const userRef = db.collection("users").doc(user.uid);
  const userDoc = await userRef.get();

  // Only create doc if it doesn't exist (first sign-in)
  if (!userDoc.exists) {
    const role = (event.additionalUserInfo && event.additionalUserInfo.isNewUser)
      ? (user.customClaims?.role || "buyer")
      : (user.customClaims?.role || "buyer");

    await userRef.set({
      uid: user.uid,
      email: user.email || null,
      displayName: user.displayName || null,
      photoURL: user.photoURL || null,
      role: role,
      phoneNumber: user.phoneNumber || null,
      businessId: null,
      isActive: true,
      fcmTokens: [],
      defaultAddress: null,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      lastLoginAt: FieldValue.serverTimestamp(),
    });

    await db.collection("analytics").doc("platform").set({
      totalUsers: FieldValue.increment(1),
      updatedAt: FieldValue.serverTimestamp(),
    }, {merge: true});
  } else {
    // Update last login
    await userRef.update({
      lastLoginAt: FieldValue.serverTimestamp(),
    });
  }

  return {};
});