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

      final clienteDoc = await db.collection('usuarios').doc(usuario.uid).get();

      if (!clienteDoc.exists) {
        throw Exception('No se encontró el perfil del cliente');
      }

      final nombreCliente =
          clienteDoc.data()?['nombre']?.toString().trim() ?? '';

      if (nombreCliente.isEmpty) {
        throw Exception('El cliente no tiene un nombre registrado');
      }

      final equipoDoc = await db.collection('equipos').doc(equipoId).get();

      if (!equipoDoc.exists || equipoDoc.data()?['clienteId'] != usuario.uid) {
        throw Exception('El equipo no existe o no pertenece a tu cuenta');
      }

      final ordenesExistentes = await db
          .collection('ordenes')
          .where('clienteId', isEqualTo: usuario.uid)
          .where('equipoId', isEqualTo: equipoId)
          .get();

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

      await db.collection('ordenes').add({
        'clienteId': usuario.uid,
        'nombreCliente': nombreCliente,
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

      mensaje('Solicitud creada correctamente');

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

  @override
  void dispose() {
    descripcion.dispose();
    super.dispose();
  }

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
      appBar: AppBar(
        title: const Text('Solicitar mantenimiento'),
        backgroundColor: const Color(0xFF1E293B),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('equipos')
            .where('clienteId', isEqualTo: usuario.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error al cargar equipos: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final equipos = snapshot.data!.docs;

          if (equipos.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.computer_outlined,
                      size: 70,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'No tienes equipos registrados',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Primero registra una PC para poder '
                      'solicitar un servicio de mantenimiento.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            );
          }

          final idsDisponibles = equipos.map((doc) => doc.id).toSet();

          final seleccionActual = idsDisponibles.contains(equipoSeleccionado)
              ? equipoSeleccionado
              : null;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 650),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF2563EB),
                              Color(0xFF1E40AF),
                              Color(0xFF172554),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.build_circle_outlined,
                              size: 65,
                              color: Colors.white,
                            ),
                            SizedBox(height: 15),
                            Text(
                              'Cuida tu PC Gamer',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Solicita un servicio de mantenimiento '
                              'para mantener tu equipo en las mejores '
                              'condiciones.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.computer, color: Colors.blueAccent),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Selecciona tu equipo',
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            const Text(
                              'Elige la PC que necesita mantenimiento.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),

                            const SizedBox(height: 20),

                            DropdownButtonFormField<String>(
                              key: ValueKey(seleccionActual),
                              initialValue: seleccionActual,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Equipo registrado',
                                prefixIcon: const Icon(
                                  Icons.devices,
                                  color: Color(0xFF60A5FA),
                                ),
                                filled: true,
                                fillColor: const Color(0xFF0F172A),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              hint: const Text('Seleccionar PC'),
                              items: equipos.map((pc) {
                                return DropdownMenuItem<String>(
                                  value: pc.id,
                                  child: Text(
                                    pc.data()['nombre']?.toString() ??
                                        'Equipo sin nombre',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.build_outlined,
                                  color: Colors.blueAccent,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Tipo de mantenimiento',
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            const Text(
                              'Selecciona el servicio que necesitas.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),

                            const SizedBox(height: 20),

                            DropdownButtonFormField<String>(
                              initialValue: tipoServicio,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Servicio',
                                prefixIcon: const Icon(
                                  Icons.handyman_outlined,
                                  color: Color(0xFF60A5FA),
                                ),
                                filled: true,
                                fillColor: const Color(0xFF0F172A),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              items: tipos.map((tipo) {
                                return DropdownMenuItem<String>(
                                  value: tipo,
                                  child: Text(
                                    tipo,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
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
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  color: Colors.blueAccent,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Describe el problema',
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            const Text(
                              'Explica qué ocurre con tu PC para '
                              'ayudar al tecnico a identificar el problema.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),

                            const SizedBox(height: 20),

                            TextField(
                              controller: descripcion,
                              maxLines: 5,
                              maxLength: 1000,
                              enabled: !guardando,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                labelText: 'Descripción del problema',
                                hintText:
                                    'Ejemplo: Mi PC se apaga cuando juego '
                                    'y presenta temperaturas altas.',
                                alignLabelWithHint: true,
                                filled: true,
                                fillColor: const Color(0xFF0F172A),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A5F),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(
                              0xFF3B82F6,
                            ).withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: Color(0xFF93C5FD)),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'DespuEs de enviar tu solicitud, '
                                'podras consultar su estado en '
                                '"Mis órdenes". También podras '
                                'cancelarla mientras siga pendiente.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      SizedBox(
                        height: 58,
                        child: ElevatedButton.icon(
                          onPressed: guardando ? null : guardarSolicitud,
                          icon: Icon(
                            guardando
                                ? Icons.hourglass_top
                                : Icons.send_outlined,
                          ),
                          label: Text(
                            guardando
                                ? 'Enviando solicitud...'
                                : 'Enviar solicitud',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFF334155),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),

                      if (guardando) ...[
                        const SizedBox(height: 20),
                        const Center(child: CircularProgressIndicator()),
                      ],

                      const SizedBox(height: 25),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
