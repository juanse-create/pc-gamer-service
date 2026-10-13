const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

exports.registrarTecnico = onCall(async (request) => {
  // Verificar que exista una sesión autenticada.
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Debes iniciar sesión.");
  }

  const uidAdmin = request.auth.uid;

  // Consultar el perfil del usuario que solicita el registro.
  const adminDoc = await admin
    .firestore()
    .collection("usuarios")
    .doc(uidAdmin)
    .get();

  if (
    !adminDoc.exists ||
    adminDoc.data().rol !== "admin" ||
    adminDoc.data().activo !== true
  ) {
    throw new HttpsError(
      "permission-denied",
      "Solo los administradores pueden registrar técnicos.",
    );
  }

  const { nombre, email, password } = request.data || {};

  if (
    typeof nombre !== "string" ||
    typeof email !== "string" ||
    typeof password !== "string" ||
    !nombre.trim() ||
    !email.trim() ||
    password.length < 6
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Verifica el nombre, correo y contraseña.",
    );
  }

  let usuario;

  try {
    usuario = await admin.auth().createUser({
      email: email.trim().toLowerCase(),
      password: password,
      displayName: nombre.trim(),
    });

    await admin.firestore().collection("usuarios").doc(usuario.uid).set({
      uid: usuario.uid,
      nombre: nombre.trim(),
      email: email.trim().toLowerCase(),
      rol: "tecnico",
      activo: true,
      fechaRegistro: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      ok: true,
      uid: usuario.uid,
      mensaje: "Técnico registrado correctamente",
    };
  } catch (error) {
    // Evitar dejar una cuenta sin perfil si falla Firestore.
    if (usuario) {
      try {
        await admin.auth().deleteUser(usuario.uid);
      } catch (rollbackError) {
        console.error("No se pudo revertir el registro:", rollbackError);
      }
    }

    console.error("Error al registrar técnico:", error);

    if (error.code === "auth/email-already-exists") {
      throw new HttpsError("already-exists", "Este correo ya está registrado.");
    }

    throw new HttpsError("internal", "No se pudo registrar el técnico.");
  }
});
