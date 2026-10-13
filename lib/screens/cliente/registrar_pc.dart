import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrarPC extends StatefulWidget {
  const RegistrarPC({super.key});

  @override
  State<RegistrarPC> createState() => _RegistrarPCState();
}

class _RegistrarPCState extends State<RegistrarPC> {
  final _formKey = GlobalKey<FormState>();

  final nombre = TextEditingController();
  final procesador = TextEditingController();
  final grafica = TextEditingController();
  final ram = TextEditingController();
  final almacenamiento = TextEditingController();
  final descripcion = TextEditingController();

  bool guardando = false;
  bool intentoGuardar = false;

  void mensaje(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  String normalizar(String texto) {
    return texto.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  String? validarTexto(
    String? valor, {
    required String nombreCampo,
    int minimo = 3,
    int maximo = 100,
  }) {
    final texto = (valor ?? '').trim();

    if (texto.isEmpty) {
      return 'Ingresa $nombreCampo';
    }

    if (texto.length < minimo) {
      return 'Debe tener al menos $minimo caracteres';
    }

    if (texto.length > maximo) {
      return 'Máximo $maximo caracteres';
    }

    return null;
  }

  String? validarRAM(String? valor) {
    final texto = (valor ?? '').trim();

    if (texto.isEmpty) {
      return 'Ingresa la memoria RAM';
    }

    final formato = RegExp(
      r'^(\d+(?:\.\d+)?)\s*(GB|TB)$',
      caseSensitive: false,
    );

    final coincidencia = formato.firstMatch(texto);

    if (coincidencia == null) {
      return 'Ejemplo: 8 GB, 16 GB o 32 GB';
    }

    final cantidad = double.tryParse(coincidencia.group(1) ?? '');

    if (cantidad == null || cantidad <= 0) {
      return 'La capacidad debe ser mayor a cero';
    }

    return null;
  }

  String? validarAlmacenamiento(String? valor) {
    final texto = (valor ?? '').trim();

    if (texto.isEmpty) {
      return 'Ingresa el almacenamiento';
    }

    final capacidad = RegExp(r'\d+(?:\.\d+)?\s*(GB|TB)', caseSensitive: false);

    if (!capacidad.hasMatch(texto)) {
      return 'Ejemplo: 512 GB SSD o 1 TB NVMe';
    }

    return null;
  }

  Future<void> guardar() async {
    if (guardando) return;

    setState(() => intentoGuardar = true);

    if (!_formKey.currentState!.validate()) return;

    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      mensaje('Debes iniciar sesión para registrar una PC');
      return;
    }

    setState(() => guardando = true);

    try {
      final db = FirebaseFirestore.instance;

      final equiposExistentes = await db
          .collection('equipos')
          .where('clienteId', isEqualTo: usuario.uid)
          .get(const GetOptions(source: Source.server));

      final duplicado = equiposExistentes.docs.any((documento) {
        final equipo = documento.data();

        return normalizar(equipo['nombre']?.toString() ?? '') ==
                normalizar(nombre.text) &&
            normalizar(equipo['procesador']?.toString() ?? '') ==
                normalizar(procesador.text) &&
            normalizar(equipo['grafica']?.toString() ?? '') ==
                normalizar(grafica.text) &&
            normalizar(equipo['ram']?.toString() ?? '') ==
                normalizar(ram.text) &&
            normalizar(equipo['almacenamiento']?.toString() ?? '') ==
                normalizar(almacenamiento.text);
      });

      if (duplicado) {
        mensaje(
          'Ya tienes registrada una PC con estas '
          'mismas características.',
        );
        return;
      }

      await db.collection('equipos').add({
        'clienteId': usuario.uid,
        'nombre': nombre.text.trim(),
        'procesador': procesador.text.trim(),
        'grafica': grafica.text.trim(),
        'ram': ram.text.trim(),
        'almacenamiento': almacenamiento.text.trim(),
        'descripcion': descripcion.text.trim(),
        'fechaRegistro': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      mensaje('PC registrada correctamente en Firebase');

      Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        mensaje('No tienes permisos para registrar equipos.');
      } else if (e.code == 'unavailable') {
        mensaje('Sin conexión con Firebase. Intenta nuevamente.');
      } else {
        mensaje('Error de Firebase: ${e.message ?? e.code}');
      }
    } catch (e) {
      mensaje('Error al registrar PC: $e');
    } finally {
      if (mounted) {
        setState(() => guardando = false);
      }
    }
  }

  Widget campo(
    String titulo,
    TextEditingController controller, {
    String? ejemplo,
    int maximo = 100,
    int lineas = 1,
    String? Function(String?)? validator,
    bool obligatorio = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: !guardando,
        maxLines: lineas,
        maxLength: maximo,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: titulo,
          hintText: ejemplo,
          border: const OutlineInputBorder(),
        ),
        validator:
            validator ??
            (valor) {
              if (!obligatorio) return null;

              return validarTexto(
                valor,
                nombreCampo: titulo.toLowerCase(),
                maximo: maximo,
              );
            },
      ),
    );
  }

  @override
  void dispose() {
    nombre.dispose();
    procesador.dispose();
    grafica.dispose();
    ram.dispose();
    almacenamiento.dispose();
    descripcion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar PC Gamer')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            autovalidateMode: intentoGuardar
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              children: [
                const Icon(Icons.computer, size: 70, color: Colors.blueAccent),

                const SizedBox(height: 20),

                campo(
                  'Nombre del equipo',
                  nombre,
                  ejemplo: 'PC Gamer Principal',
                  maximo: 60,
                ),

                campo('Procesador (CPU)', procesador, ejemplo: 'Ryzen 5 5600X'),

                campo(
                  'Tarjeta gráfica (GPU)',
                  grafica,
                  ejemplo: 'RTX 3060 o Integrada',
                  validator: (valor) => validarTexto(
                    valor,
                    nombreCampo: 'la tarjeta gráfica',
                    minimo: 2,
                  ),
                ),

                campo(
                  'Memoria RAM',
                  ram,
                  ejemplo: '16 GB',
                  maximo: 30,
                  validator: validarRAM,
                ),

                campo(
                  'Almacenamiento',
                  almacenamiento,
                  ejemplo: '1 TB NVMe',
                  validator: validarAlmacenamiento,
                ),

                campo(
                  'Descripción',
                  descripcion,
                  ejemplo: 'Detalles adicionales del equipo',
                  maximo: 500,
                  lineas: 3,
                  obligatorio: false,
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: guardando ? null : guardar,
                    icon: const Icon(Icons.save),
                    label: Text(guardando ? 'Guardando...' : 'Guardar equipo'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(18),
                    ),
                  ),
                ),

                if (guardando) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
