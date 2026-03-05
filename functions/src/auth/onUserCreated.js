const {beforeUserCreated} = require("firebase-functions/v2/identity");
const {getAuth} = require("firebase-admin/auth");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");

const DEVELOPER_EMAIL = "tshikotaeats@nortsideconnect.co.za";

module.exports = beforeUserCreated(async (event) => {
  const user = event.data;
  const db = getFirestore();

  let role = "buyer";
  let claims = {role};

  if (user.email === DEVELOPER_EMAIL) {
    role = "developer";
    claims = {role: "developer"};
  }

  await getAuth().setCustomUserClaims(user.uid, claims);

  await db.collection("users").doc(user.uid).set({
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

  console.log("User " + user.uid + " created with role: " + role);

  return {
    customClaims: claims,
  };
});