import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../../main.dart' show HomeScreen;
import 'registro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _authService = AuthService();

  bool _cargando = false;
  bool _mostrarPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validarEmail(String? valor) {
    final email = (valor ?? '').trim();

    if (email.isEmpty) {
      return 'Ingresa tu correo electrónico';
    }

    final expresion = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    if (!expresion.hasMatch(email)) {
      return 'Ingresa un correo electrónico válido';
    }

    return null;
  }

  String? _validarPassword(String? valor) {
    if (valor == null || valor.isEmpty) {
      return 'Ingresa tu contraseña';
    }

    return null;
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  String _mensajeError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'El correo electrónico no es válido.';

        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return 'Correo o contraseña incorrectos.';

        case 'user-disabled':
          return 'Esta cuenta está deshabilitada.';

        case 'too-many-requests':
          return 'Demasiados intentos. Intenta más tarde.';

        case 'network-request-failed':
          return 'No hay conexión a Internet.';

        case 'account-exists-with-different-credential':
          return 'Este correo ya está asociado a otro método de acceso.';

        default:
          return error.message ?? 'No se pudo iniciar sesión.';
      }
    }

    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'No tienes permisos para acceder a esta cuenta.';
      }

      if (error.code == 'unavailable') {
        return 'No se pudo conectar con Firebase.';
      }

      return error.message ?? 'Ocurrió un error al consultar Firebase.';
    }

    final texto = error.toString();

    if (texto.startsWith('Exception: ')) {
      return texto.substring('Exception: '.length);
    }

    return 'No se pudo completar el inicio de sesión: $texto';
  }

  Future<void> _iniciarSesion() async {
    if (_cargando) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      await _authService.iniciarSesion(
        email: _emailController.text,
        password: _passwordController.text,
      );

      await _verificarUsuario();
    } catch (e) {
      _mostrarMensaje(_mensajeError(e));
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _iniciarConGoogle() async {
    if (_cargando) return;

    setState(() => _cargando = true);

    try {
      await _authService.iniciarSesionConGoogle();

      await _verificarUsuario();
    } catch (e) {
      _mostrarMensaje(_mensajeError(e));
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _verificarUsuario() async {
    final perfil = await _authService.obtenerPerfilActual();

    if (perfil == null) {
      await _authService.cerrarSesion();

      _mostrarMensaje('No se encontró el perfil del usuario.');
      return;
    }

    if (perfil['activo'] != true) {
      await _authService.cerrarSesion();

      _mostrarMensaje('Tu cuenta está desactivada.');
      return;
    }

    final rol = perfil['rol'];

    String nombreRol;

    switch (rol) {
      case 'cliente':
        nombreRol = 'Cliente';
        break;

      case 'tecnico':
        nombreRol = 'Técnico';
        break;

      case 'admin':
        nombreRol = 'Administrador';
        break;

      default:
        await _authService.cerrarSesion();

        _mostrarMensaje('Rol no reconocido.');
        return;
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen(rol: nombreRol)),
    );
  }

  Future<void> _reenviarVerificacion() async {
    if (_cargando) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      await _authService.reenviarVerificacion(
        email: _emailController.text,
        password: _passwordController.text,
      );

      _mostrarMensaje(
        'Correo de verificación enviado correctamente. '
        'Revisa tu bandeja de entrada y spam.',
      );
    } catch (e) {
      _mostrarMensaje(_mensajeError(e));
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  Future<void> _recuperarPassword() async {
    if (_cargando) return;

    final email = _emailController.text.trim().toLowerCase();

    if (_validarEmail(email) != null) {
      _mostrarMensaje('Primero escribe un correo electrónico válido.');
      return;
    }

    setState(() => _cargando = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      _mostrarMensaje(
        'Si existe una cuenta compatible con este correo, '
        'recibirás instrucciones para restablecer '
        'tu contraseña. Revisa también spam.',
      );
    } catch (e) {
      _mostrarMensaje(_mensajeError(e));
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  void _mostrarAyudaAcceso() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF182B3A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Problemas para entrar?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Si aún no verificaste tu correo, escribe tu correo y contraseña en el formulario y solicita otro enlace.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _reenviarVerificacion();
                  },
                  icon: const Icon(Icons.mark_email_unread_outlined),
                  label: const Text('Reenviar correo de verificación'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const cyan = Colors.cyanAccent;
    const azul = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.computer, size: 70, color: cyan),
                    const SizedBox(height: 12),
                    const Text(
                      'PC GAMER SERVICE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Bienvenido de nuevo',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                    const SizedBox(height: 34),
                    TextFormField(
                      controller: _emailController,
                      enabled: !_cargando,
                      keyboardType: TextInputType.emailAddress,
                      textCapitalization: TextCapitalization.none,
                      autocorrect: false,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Correo electrónico',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: cyan,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF182B3A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: _validarEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      enabled: !_cargando,
                      obscureText: !_mostrarPassword,
                      autocorrect: false,
                      enableSuggestions: false,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.lock_outline, color: cyan),
                        filled: true,
                        fillColor: const Color(0xFF182B3A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          tooltip: _mostrarPassword
                              ? 'Ocultar contraseña'
                              : 'Mostrar contraseña',
                          icon: Icon(
                            _mostrarPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: cyan,
                          ),
                          onPressed: () => setState(
                            () => _mostrarPassword = !_mostrarPassword,
                          ),
                        ),
                      ),
                      validator: _validarPassword,
                      onFieldSubmitted: (_) {
                        if (!_cargando) _iniciarSesion();
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _cargando ? null : _recuperarPassword,
                        child: const Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(color: cyan, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _cargando ? null : _iniciarSesion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: azul,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _cargando ? 'Iniciando sesión...' : 'INICIAR SESIÓN',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white24)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'O continúa con',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.white24)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _cargando ? null : _iniciarConGoogle,
                        icon: const Icon(Icons.account_circle_outlined),
                        label: const Text('Continuar con Google'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          '¿No tienes cuenta?',
                          style: TextStyle(color: Colors.white70),
                        ),
                        TextButton(
                          onPressed: _cargando
                              ? null
                              : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegistroScreen(),
                                  ),
                                ),
                          child: const Text(
                            'Regístrate',
                            style: TextStyle(
                              color: cyan,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: _cargando ? null : _mostrarAyudaAcceso,
                      icon: const Icon(Icons.help_outline, size: 18),
                      label: const Text('¿Problemas para entrar?'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white60,
                      ),
                    ),
                    if (_cargando) ...[
                      const SizedBox(height: 12),
                      const Center(child: CircularProgressIndicator()),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
