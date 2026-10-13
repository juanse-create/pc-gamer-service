import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SolicitarMantenimiento extends StatefulWidget {
  const SolicitarMantenimiento({super.key});

  @override
  State<SolicitarMantenimiento> createState() => _SolicitarMantenimientoState();
}

class _SolicitarMantenimientoState extends State<SolicitarMantenimiento> {
  String? equipoSeleccionado;

  String tipoServicio = 'Mantenimiento preventivo';

  final descripcion = TextEditingController();

  bool guardando = false;

  final tipos = [
    'Mantenimiento preventivo',
    'Mantenimiento correctivo',
    'Limpieza profunda',
    'Cambio de componentes',
    'Diagnóstico general',
  ];

  final estadosActivos = [
    'Pendiente',
    'Asignado',
    'En diagnóstico',
    'En mantenimiento',
  ];

  void mensaje(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  // ==========================================
  // GUARDAR SOLICITUD
  // ==========================================

  Future<void> guardarSolicitud() async {
    if (guardando) return;

    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      mensaje('Debes iniciar sesión');
      return;
    }

    final equipoId = equipoSeleccionado;
    final problema = descripcion.text.trim();

    if (equipoId == null) {
      mensaje('Selecciona una PC');
      return;
    }

    if (problema.isEmpty) {
      mensaje('Describe el problema de tu equipo');
      return;
    }

    if (problema.length < 10) {
      mensaje('La descripción debe tener al menos 10 caracteres');
      return;
    }

    if (problema.length > 1000) {
      mensaje('La descripción no puede superar 1000 caracteres');
      return;
    }

    setState(() => guardando = true);

    try {
      final db = FirebaseFirestore.instance;

      // Verificar que la PC existe y pertenece al cliente.
      final equipoDoc = await db.collection('equipos').doc(equipoId).get();

      if (!equipoDoc.exists || equipoDoc.data()?['clienteId'] != usuario.uid) {
        throw Exception('El equipo no existe o no pertenece a tu cuenta');
      }

      // Buscar órdenes existentes de esta PC.
      final ordenesExistentes = await db
          .collection('ordenes')
          .where('clienteId', isEqualTo: usuario.uid)
          .where('equipoId', isEqualTo: equipoId)
          .get();

      // Comprobar si existe una solicitud activa.
      final solicitudActiva = ordenesExistentes.docs.any((documento) {
        final estado = documento.data()['estado']?.toString() ?? '';

        return estadosActivos.contains(estado);
      });

      if (solicitudActiva) {
        mensaje(
          'Esta PC ya tiene una solicitud de mantenimiento '
          'en proceso. Espera a que termine antes '
          'de crear otra.',
        );
        return;
      }

      // Crear nueva orden.
      await db.collection('ordenes').add({
        'clienteId': usuario.uid,
        'equipoId': equipoId,
        'nombreEquipo': equipoDoc.data()?['nombre'] ?? '',
        'tipoServicio': tipoServicio,
        'descripcion': problema,
        'estado': 'Pendiente',
        'tecnicoId': null,
        'diagnostico': '',
        'fechaCreacion': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      mensaje('Solicitud creada correctamente en Firebase');

      Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      mensaje('Error de Firebase: ${e.message ?? e.code}');
    } catch (e) {
      mensaje('Error al guardar solicitud: $e');
    } finally {
      if (mounted) {
        setState(() => guardando = false);
      }
    }
  }

  // ==========================================
  // LIBERAR RECURSOS
  // ==========================================

  @override
  void dispose() {
    descripcion.dispose();
    super.dispose();
  }

  // ==========================================
  // INTERFAZ
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Solicitar mantenimiento')),
        body: const Center(child: Text('Debes iniciar sesión')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Solicitar mantenimiento')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('equipos')
            .where('clienteId', isEqualTo: usuario.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar equipos: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final equipos = snapshot.data!.docs;

          if (equipos.isEmpty) {
            return const Center(child: Text('Primero debes registrar una PC'));
          }

          final idsDisponibles = equipos.map((doc) => doc.id).toSet();

          final seleccionActual = idsDisponibles.contains(equipoSeleccionado)
              ? equipoSeleccionado
              : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecciona tu equipo',
                  style: TextStyle(fontSize: 18),
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  key: ValueKey(seleccionActual),
                  initialValue: seleccionActual,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Seleccionar PC'),
                  items: equipos.map((pc) {
                    return DropdownMenuItem<String>(
                      value: pc.id,
                      child: Text(
                        pc.data()['nombre']?.toString() ?? 'Equipo sin nombre',
                      ),
                    );
                  }).toList(),
                  onChanged: guardando
                      ? null
                      : (valor) {
                          setState(() {
                            equipoSeleccionado = valor;
                          });
                        },
                ),

                const SizedBox(height: 25),

                const Text('Tipo de servicio', style: TextStyle(fontSize: 18)),

                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  initialValue: tipoServicio,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: tipos.map((tipo) {
                    return DropdownMenuItem<String>(
                      value: tipo,
                      child: Text(tipo),
                    );
                  }).toList(),
                  onChanged: guardando
                      ? null
                      : (valor) {
                          if (valor != null) {
                            setState(() {
                              tipoServicio = valor;
                            });
                          }
                        },
                ),

                const SizedBox(height: 25),

                TextField(
                  controller: descripcion,
                  maxLines: 4,
                  maxLength: 1000,
                  enabled: !guardando,
                  decoration: const InputDecoration(
                    labelText: 'Describe el problema',
                    hintText: 'Ejemplo: La PC se apaga al jugar',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: guardando ? null : guardarSolicitud,
                    icon: const Icon(Icons.save),
                    label: Text(
                      guardando ? 'Guardando...' : 'Enviar solicitud',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(18),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
