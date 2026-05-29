const {beforeUserCreated} = require("firebase-functions/v2/identity");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");

const DEVELOPER_EMAIL = "tshikotaeats@nortsideconnect.co.za";

module.exports = beforeUserCreated(async (event) => {
  const user = event.data;

  let role = "buyer";
  if (user.email === DEVELOPER_EMAIL) {
    role = "developer";
  }

  // Return claims — Firebase sets them automatically
  // Do NOT call setCustomUserClaims here (user doesn't fully exist yet)
  return {
    customClaims: {role},
  };
});