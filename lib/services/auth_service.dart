import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==========================================
  // VALIDAR PERFIL
  // ==========================================

  Future<Map<String, dynamic>> _validarPerfil(User usuario) async {
    final documento = await _db.collection('usuarios').doc(usuario.uid).get();

    if (!documento.exists) {
      throw Exception(
        'Tu cuenta no tiene un perfil registrado. '
        'Contacta al administrador.',
      );
    }

    final perfil = documento.data()!;

    if (perfil['activo'] != true) {
      throw Exception(
        'Tu cuenta está desactivada. '
        'Contacta al administrador.',
      );
    }

    final rol = perfil['rol']?.toString();

    if (rol != 'cliente' && rol != 'tecnico' && rol != 'admin') {
      throw Exception('Tu cuenta no tiene un rol válido.');
    }

    return perfil;
  }

  // ==========================================
  // REGISTRAR CLIENTE
  // ==========================================

  Future<UserCredential> registrarCliente({
    required String nombre,
    required String email,
    required String password,
  }) async {
    final nombreLimpio = nombre.trim();
    final emailLimpio = email.trim().toLowerCase();

    if (nombreLimpio.isEmpty || emailLimpio.isEmpty || password.isEmpty) {
      throw Exception('Completa todos los campos.');
    }

    if (password.length < 6) {
      throw Exception('La contraseña debe tener al menos 6 caracteres.');
    }

    final credencial = await _auth.createUserWithEmailAndPassword(
      email: emailLimpio,
      password: password,
    );

    final usuario = credencial.user;

    if (usuario == null) {
      throw Exception('No se pudo crear la cuenta.');
    }

    try {
      await _db.collection('usuarios').doc(usuario.uid).set({
        'uid': usuario.uid,
        'nombre': nombreLimpio,
        'email': emailLimpio,
        'rol': 'cliente',
        'activo': true,
        'fechaRegistro': FieldValue.serverTimestamp(),
      });

      return credencial;
    } catch (_) {
      // Evitar dejar una cuenta sin perfil.
      try {
        await usuario.delete();
      } catch (_) {
        // Puede requerir recuperación administrativa.
      }

      rethrow;
    }
  }

  // ==========================================
  // INICIAR SESIÓN CON CORREO
  // ==========================================

  Future<UserCredential> iniciarSesion({
    required String email,
    required String password,
  }) async {
    final credencial = await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    final usuario = credencial.user;

    if (usuario == null) {
      await _auth.signOut();
      throw Exception('No se pudo iniciar sesión.');
    }

    try {
      await _validarPerfil(usuario);
      return credencial;
    } catch (_) {
      await _auth.signOut();
      rethrow;
    }
  }

  // ==========================================
  // INICIAR SESIÓN CON GOOGLE
  // ==========================================

  Future<UserCredential> iniciarSesionConGoogle() async {
    final googleSignIn = GoogleSignIn.instance;

    await googleSignIn.initialize();

    final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);

    final usuario = userCredential.user;

    if (usuario == null) {
      await _auth.signOut();
      throw Exception('No se pudo iniciar sesión con Google.');
    }

    try {
      final usuarioRef = _db.collection('usuarios').doc(usuario.uid);

      final documento = await usuarioRef.get();

      // Solo crear perfil si todavía no existe.
      if (!documento.exists) {
        await usuarioRef.set({
          'uid': usuario.uid,
          'nombre': usuario.displayName ?? 'Cliente',
          'email': usuario.email ?? '',
          'rol': 'cliente',
          'activo': true,
          'fechaRegistro': FieldValue.serverTimestamp(),
        });
      }

      // Verificar que el usuario pueda acceder.
      await _validarPerfil(usuario);

      return userCredential;
    } catch (_) {
      await _auth.signOut();
      rethrow;
    }
  }

  // ==========================================
  // CONSULTAR PERFIL ACTUAL
  // ==========================================

  Future<Map<String, dynamic>?> obtenerPerfilActual() async {
    final usuario = _auth.currentUser;

    if (usuario == null) {
      return null;
    }

    return _validarPerfil(usuario);
  }

  // ==========================================
  // CERRAR SESIÓN
  // ==========================================

  Future<void> cerrarSesion() async {
    await _auth.signOut();
  }
}
