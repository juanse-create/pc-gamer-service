import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../../main.dart' show HomeScreen;

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarController = TextEditingController();

  final _authService = AuthService();

  bool _cargando = false;
  bool _mostrarPassword = false;
  bool _mostrarConfirmacion = false;
  bool _intentoRegistrar = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  // ==========================================
  // VALIDACIONES
  // ==========================================

  String? _validarNombre(String? valor) {
    final nombre = (valor ?? '').trim();

    if (nombre.isEmpty) {
      return 'Ingresa tu nombre completo';
    }

    if (nombre.length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }

    if (nombre.length > 80) {
      return 'El nombre no puede superar 80 caracteres';
    }

    final caracteresValidos = RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚüÜñÑ\s'-]+$");

    if (!caracteresValidos.hasMatch(nombre)) {
      return 'El nombre contiene caracteres no permitidos';
    }

    return null;
  }

  String? _validarEmail(String? valor) {
    final email = (valor ?? '').trim();

    if (email.isEmpty) {
      return 'Ingresa tu correo electrónico';
    }

    if (email.contains(' ')) {
      return 'El correo no debe contener espacios';
    }

    final formatoEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    if (!formatoEmail.hasMatch(email)) {
      return 'Ingresa un correo electrónico válido';
    }

    if (email.length > 254) {
      return 'El correo electrónico es demasiado largo';
    }

    return null;
  }

  String? _validarPassword(String? valor) {
    final password = valor ?? '';

    if (password.isEmpty) {
      return 'Ingresa una contraseña';
    }

    if (password.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }

    if (!RegExp(r'[a-zA-Z]').hasMatch(password)) {
      return 'Incluye al menos una letra';
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Incluye al menos un número';
    }

    return null;
  }

  String? _validarConfirmacion(String? valor) {
    if (valor == null || valor.isEmpty) {
      return 'Confirma tu contraseña';
    }

    if (valor != _passwordController.text) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }

  // ==========================================
  // MENSAJES
  // ==========================================

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  // ==========================================
  // REGISTRAR CLIENTE
  // ==========================================

  Future<void> _registrar() async {
    if (_cargando) return;

    setState(() {
      _intentoRegistrar = true;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      await _authService.registrarCliente(
        nombre: _nombreController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      _mostrarMensaje('Cuenta creada correctamente');

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen(rol: 'Cliente')),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String mensaje;

      switch (e.code) {
        case 'email-already-in-use':
          mensaje = 'Este correo ya está registrado.';
          break;

        case 'invalid-email':
          mensaje = 'El correo electrónico no es válido.';
          break;

        case 'weak-password':
          mensaje = 'La contraseña es demasiado débil.';
          break;

        case 'network-request-failed':
          mensaje = 'No hay conexión a Internet. Intenta nuevamente.';
          break;

        case 'too-many-requests':
          mensaje = 'Demasiados intentos. Espera un momento.';
          break;

        case 'operation-not-allowed':
          mensaje = 'El registro con correo no está habilitado.';
          break;

        default:
          mensaje = e.message ?? 'No se pudo crear la cuenta.';
      }

      _mostrarMensaje(mensaje);
    } on FirebaseException catch (e) {
      _mostrarMensaje('No se pudo guardar el perfil: ${e.message ?? e.code}');
    } catch (e) {
      _mostrarMensaje('No se pudo completar el registro: $e');
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  // ==========================================
  // INTERFAZ
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101820),
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        backgroundColor: const Color(0xFF182B3A),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              autovalidateMode: _intentoRegistrar
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.person_add_alt_1,
                    size: 75,
                    color: Colors.cyanAccent,
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Registro de cliente',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // NOMBRE
                  TextFormField(
                    controller: _nombreController,
                    enabled: !_cargando,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 80,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: _validarNombre,
                  ),

                  const SizedBox(height: 12),

                  // CORREO
                  TextFormField(
                    controller: _emailController,
                    enabled: !_cargando,
                    keyboardType: TextInputType.emailAddress,
                    textCapitalization: TextCapitalization.none,
                    autocorrect: false,
                    maxLength: 254,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: _validarEmail,
                  ),

                  const SizedBox(height: 12),

                  // CONTRASEÑA
                  TextFormField(
                    controller: _passwordController,
                    enabled: !_cargando,
                    obscureText: !_mostrarPassword,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      helperText: 'Mínimo 8 caracteres, letras y números',
                      helperMaxLines: 2,
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _mostrarPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _mostrarPassword = !_mostrarPassword;
                          });
                        },
                      ),
                    ),
                    validator: _validarPassword,
                  ),

                  const SizedBox(height: 16),

                  // CONFIRMAR CONTRASEÑA
                  TextFormField(
                    controller: _confirmarController,
                    enabled: !_cargando,
                    obscureText: !_mostrarConfirmacion,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: 'Confirmar contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _mostrarConfirmacion
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _mostrarConfirmacion = !_mostrarConfirmacion;
                          });
                        },
                      ),
                    ),
                    validator: _validarConfirmacion,
                  ),

                  const SizedBox(height: 28),

                  // BOTÓN
                  ElevatedButton(
                    onPressed: _cargando ? null : _registrar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                    child: Text(
                      _cargando ? 'Creando cuenta...' : 'Crear cuenta',
                      style: const TextStyle(fontSize: 17),
                    ),
                  ),

                  if (_cargando) ...[
                    const SizedBox(height: 20),
                    const Center(child: CircularProgressIndicator()),
                  ],

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: _cargando ? null : () => Navigator.pop(context),
                    child: const Text('¿Ya tienes cuenta? Inicia sesión'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
