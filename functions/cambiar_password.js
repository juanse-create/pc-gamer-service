const admin = require("firebase-admin");

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

async function main() {
  const uid = process.env.TECNICO_UID;
  const password = process.env.NUEVA_PASSWORD;

  if (!uid || !password) {
    throw new Error("Faltan UID o contraseña");
  }

  await admin.auth().updateUser(uid, {
    password: password,
  });

  console.log("Contraseña actualizada correctamente");
}

main().catch((error) => {
  console.error("Error:", error.message);
  process.exitCode = 1;
});
