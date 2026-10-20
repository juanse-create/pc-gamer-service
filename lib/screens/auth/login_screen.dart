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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      appBar: AppBar(
        title: const Text('PC Gamer Service'),
        backgroundColor: const Color(0xFF182B3A),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.computer,
                    color: Colors.cyanAccent,
                    size: 85,
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Bienvenido',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 30),

                  TextFormField(
                    controller: _emailController,
                    enabled: !_cargando,
                    keyboardType: TextInputType.emailAddress,
                    textCapitalization: TextCapitalization.none,
                    autocorrect: false,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      labelStyle: TextStyle(color: Colors.white70),
                      prefixIcon: Icon(Icons.email, color: Colors.cyanAccent),
                      border: OutlineInputBorder(),
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
                      prefixIcon: const Icon(
                        Icons.lock,
                        color: Colors.cyanAccent,
                      ),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _mostrarPassword = !_mostrarPassword;
                          });
                        },
                        icon: Icon(
                          _mostrarPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.cyanAccent,
                        ),
                      ),
                    ),
                    validator: _validarPassword,
                    onFieldSubmitted: (_) {
                      if (!_cargando) {
                        _iniciarSesion();
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _cargando ? null : _recuperarPassword,
                      child: const Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(color: Colors.cyanAccent),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _cargando ? null : _iniciarSesion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                      child: Text(
                        _cargando ? 'Iniciando sesión...' : 'Iniciar sesión',
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'O continúa con',
                    style: TextStyle(color: Colors.white70),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _cargando ? null : _iniciarConGoogle,
                      icon: const Icon(Icons.account_circle),
                      label: const Text('Continuar con Google'),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: _cargando
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegistroScreen(),
                              ),
                            );
                          },
                    child: const Text(
                      '¿No tienes cuenta? Regístrate aquí',
                      style: TextStyle(color: Colors.cyanAccent, fontSize: 15),
                    ),
                  ),

                  if (_cargando) ...[
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
