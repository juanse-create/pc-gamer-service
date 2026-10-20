import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrdenesTecnico extends StatefulWidget {
  final String modo;

  const OrdenesTecnico({super.key, this.modo = 'consultar'});

  @override
  State<OrdenesTecnico> createState() => _OrdenesTecnicoState();
}

class _OrdenesTecnicoState extends State<OrdenesTecnico> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  bool procesando = false;

  String get tituloPantalla {
    switch (widget.modo) {
      case 'diagnostico':
        return 'Registrar diagnóstico';
      case 'estado':
        return 'Actualizar estado';
      default:
        return 'Órdenes asignadas';
    }
  }

  String idCorto(String id) {
    return id.length > 8 ? id.substring(0, 8) : id;
  }

  void mensaje(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> registrarDiagnostico(
    QueryDocumentSnapshot<Map<String, dynamic>> documento,
  ) async {
    final datos = documento.data();

    final resultado = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return _DialogoDiagnostico(
          ordenId: documento.id,
          diagnosticoActual: datos['diagnostico']?.toString() ?? '',
        );
      },
    );

    if (!mounted || resultado == null) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      mensaje('La sesión ha terminado');
      return;
    }

    setState(() => procesando = true);

    try {
      final ref = db.collection('ordenes').doc(documento.id);

      await db.runTransaction((transaction) async {
        final actual = await transaction.get(ref);

        if (!actual.exists) {
          throw Exception('La orden ya no existe');
        }

        final orden = actual.data()!;
        final estado = orden['estado'];

        if (orden['tecnicoId'] != uid ||
            (estado != 'Asignado' && estado != 'En diagnóstico')) {
          throw Exception('Esta orden ya no permite registrar diagnósticos');
        }

        transaction.update(ref, {
          'diagnostico': resultado,
          'estado': 'En diagnóstico',
          'fechaDiagnostico': FieldValue.serverTimestamp(),
        });
      });

      mensaje('Diagnóstico guardado correctamente');
    } catch (e) {
      mensaje('Error al guardar diagnóstico: $e');
    } finally {
      if (mounted) {
        setState(() => procesando = false);
      }
    }
  }

  Future<void> actualizarEstado(
    QueryDocumentSnapshot<Map<String, dynamic>> documento,
  ) async {
    final estadoActual = documento.data()['estado']?.toString() ?? '';

    String? nuevoEstado;

    if (estadoActual == 'En diagnóstico') {
      nuevoEstado = 'En mantenimiento';
    } else if (estadoActual == 'En mantenimiento') {
      nuevoEstado = 'Terminado';
    }

    if (nuevoEstado == null) return;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Actualizar estado'),
          content: Text(
            '¿Cambiar la orden #${idCorto(documento.id)} '
            'de "$estadoActual" a "$nuevoEstado"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmado != true) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      mensaje('La sesión ha terminado');
      return;
    }

    setState(() => procesando = true);

    try {
      final ref = db.collection('ordenes').doc(documento.id);

      await db.runTransaction((transaction) async {
        final actual = await transaction.get(ref);

        if (!actual.exists) {
          throw Exception('La orden ya no existe');
        }

        final orden = actual.data()!;

        if (orden['tecnicoId'] != uid ||
            orden['estado'] != estadoActual ||
            (orden['diagnostico'] ?? '').toString().trim().isEmpty) {
          throw Exception('La orden cambió o no tiene diagnóstico');
        }

        transaction.update(ref, {
          'estado': nuevoEstado,
          'fechaActualizacion': FieldValue.serverTimestamp(),
        });
      });

      mensaje('Estado actualizado a $nuevoEstado');
    } catch (e) {
      mensaje('Error al actualizar estado: $e');
    } finally {
      if (mounted) {
        setState(() => procesando = false);
      }
    }
  }

  Widget? botonAccion(QueryDocumentSnapshot<Map<String, dynamic>> documento) {
    final estado = documento.data()['estado']?.toString() ?? '';

    if (widget.modo == 'consultar') {
      return null;
    }

    if (widget.modo == 'diagnostico') {
      if (estado != 'Asignado' && estado != 'En diagnóstico') {
        return null;
      }

      return ElevatedButton.icon(
        onPressed: procesando ? null : () => registrarDiagnostico(documento),
        icon: const Icon(Icons.edit_note),
        label: const Text('Registrar diagnóstico'),
      );
    }

    if (widget.modo == 'estado') {
      if (estado == 'Asignado') {
        return const Text(
          'Primero debes registrar el diagnóstico.',
          style: TextStyle(color: Colors.orange),
        );
      }

      if (estado == 'Terminado' || estado == 'Entregado') {
        return const Text(
          'Esta orden ya está finalizada.',
          style: TextStyle(color: Colors.green),
        );
      }

      if (estado != 'En diagnóstico' && estado != 'En mantenimiento') {
        return null;
      }

      final siguienteEstado = estado == 'En diagnóstico'
          ? 'En mantenimiento'
          : 'Terminado';

      return ElevatedButton.icon(
        onPressed: procesando ? null : () => actualizarEstado(documento),
        icon: const Icon(Icons.update),
        label: Text('Cambiar a $siguienteEstado'),
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return Scaffold(
        appBar: AppBar(title: Text(tituloPantalla)),
        body: const Center(child: Text('Debes iniciar sesión')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(tituloPantalla)),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db
            .collection('ordenes')
            .where('tecnicoId', isEqualTo: usuario.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error al cargar órdenes: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final ordenes = snapshot.data!.docs.toList();

          ordenes.sort((a, b) {
            final fechaA = a.data()['fechaCreacion'];
            final fechaB = b.data()['fechaCreacion'];

            if (fechaA is! Timestamp && fechaB is! Timestamp) {
              return 0;
            }

            if (fechaA is! Timestamp) return 1;
            if (fechaB is! Timestamp) return -1;

            return fechaB.compareTo(fechaA);
          });

          if (ordenes.isEmpty) {
            return const Center(child: Text('No tienes órdenes asignadas'));
          }

          return Column(
            children: [
              if (procesando) const LinearProgressIndicator(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: ordenes.length,
                  itemBuilder: (context, index) {
                    final documento = ordenes[index];
                    final orden = documento.data();

                    final estado = orden['estado']?.toString() ?? 'Pendiente';

                    final diagnostico = orden['diagnostico']?.toString() ?? '';

                    final boton = botonAccion(documento);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Orden #${idCorto(documento.id)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text('PC: ${orden['nombreEquipo'] ?? ''}'),
                            Text('Servicio: ${orden['tipoServicio'] ?? ''}'),
                            Text('Problema: ${orden['descripcion'] ?? ''}'),
                            const Divider(),
                            Text('Estado: $estado'),
                            const SizedBox(height: 8),
                            Text(
                              'Diagnóstico: ${diagnostico.isEmpty ? 'Sin registrar' : diagnostico}',
                            ),
                            if (boton != null) ...[
                              const SizedBox(height: 15),
                              SizedBox(width: double.infinity, child: boton),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DialogoDiagnostico extends StatefulWidget {
  final String ordenId;
  final String diagnosticoActual;

  const _DialogoDiagnostico({
    required this.ordenId,
    required this.diagnosticoActual,
  });

  @override
  State<_DialogoDiagnostico> createState() => _DialogoDiagnosticoState();
}

class _DialogoDiagnosticoState extends State<_DialogoDiagnostico> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();

    controller = TextEditingController(text: widget.diagnosticoActual);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void guardar() {
    final texto = controller.text.trim();

    if (texto.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Escribe un diagnóstico')));
      return;
    }

    Navigator.pop(context, texto);
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.ordenId;

    final idCorto = id.length > 8 ? id.substring(0, 8) : id;

    return AlertDialog(
      title: Text('Diagnóstico de la orden #$idCorto'),
      content: TextField(
        controller: controller,
        maxLines: 5,
        maxLength: 2000,
        decoration: const InputDecoration(
          labelText: 'Diagnóstico',
          hintText: 'Describe la falla encontrada',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: guardar,
          child: const Text('Guardar diagnóstico'),
        ),
      ],
    );
  }
}
