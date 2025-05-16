import { compare } from 'bcrypt';

const enteredPassword = "123Myyy..";  // Password you entered
const storedHash = "$2b$10$0.JWIXMaKxFPI74Zypo1AuOGeR39q7Jt3G6dfkMrYk5S6829NqPSy"; // Copy from MongoDB

compare(enteredPassword, storedHash, function(err, result) {
  if (err) {
    console.error("❌ Error:", err);
  } else {
    console.log("✅ Password Match Result:", result);
  }
});
