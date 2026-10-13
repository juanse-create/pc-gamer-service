import 'package:flutter/material.dart';

class RegistrarTecnico extends StatefulWidget {
  const RegistrarTecnico({super.key});

  @override
  State<RegistrarTecnico> createState() => _RegistrarTecnicoState();
}

class _RegistrarTecnicoState extends State<RegistrarTecnico> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _mostrarPassword = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _registrarTecnico() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Formulario validado. El registro en Firebase '
          'se habilitará al conectar el backend seguro.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar técnico')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.engineering,
                  size: 75,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 20),

                const Text(
                  'Nuevo técnico',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Ingresa el nombre del técnico';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (valor) {
                    if (valor == null ||
                        !RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch(valor.trim())) {
                      return 'Ingresa un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: !_mostrarPassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
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
                  validator: (valor) {
                    if (valor == null || valor.length < 6) {
                      return 'La contraseña debe tener mínimo 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                ElevatedButton.icon(
                  onPressed: _registrarTecnico,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Validar registro'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  'El registro definitivo en Firebase '
                  'está pendiente de habilitar el backend.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
