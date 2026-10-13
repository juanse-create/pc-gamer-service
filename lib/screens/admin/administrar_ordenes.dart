import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdministrarOrdenes extends StatefulWidget {
  const AdministrarOrdenes({super.key});

  @override
  State<AdministrarOrdenes> createState() => _AdministrarOrdenesState();
}

class _AdministrarOrdenesState extends State<AdministrarOrdenes> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  bool asignando = false;

  Future<void> mostrarAsignacion(String ordenId) async {
    try {
      // Consultar técnicos reales de Firebase.
      final resultado = await db
          .collection('usuarios')
          .where('rol', isEqualTo: 'tecnico')
          .get();

      if (!mounted) return;

      final tecnicos = resultado.docs.where((doc) {
        return doc.data()['activo'] == true;
      }).toList();

      if (tecnicos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay técnicos activos registrados en Firebase'),
          ),
        );
        return;
      }

      String? tecnicoSeleccionado;

      final tecnicoId = await showDialog<String>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Asignar técnico'),
              content: DropdownButtonFormField<String>(
                initialValue: tecnicoSeleccionado,
                isExpanded: true,
                hint: const Text('Seleccionar técnico'),
                items: tecnicos.map((tecnico) {
                  final datos = tecnico.data();

                  return DropdownMenuItem<String>(
                    value: tecnico.id,
                    child: Text(
                      datos['nombre']?.toString() ?? 'Técnico sin nombre',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (valor) {
                  setDialogState(() {
                    tecnicoSeleccionado = valor;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: tecnicoSeleccionado == null
                      ? null
                      : () => Navigator.pop(dialogContext, tecnicoSeleccionado),
                  child: const Text('Asignar'),
                ),
              ],
            );
          },
        ),
      );

      if (tecnicoId == null || !mounted) return;

      final tecnico = tecnicos.firstWhere((doc) => doc.id == tecnicoId);

      setState(() => asignando = true);

      // Transacción: impide asignar una orden
      // que ya dejó de estar pendiente.
      await db.runTransaction((transaction) async {
        final ordenRef = db.collection('ordenes').doc(ordenId);
        final ordenDoc = await transaction.get(ordenRef);

        if (!ordenDoc.exists) {
          throw Exception('La orden ya no existe');
        }

        if (ordenDoc.data()?['estado'] != 'Pendiente') {
          throw Exception('La orden ya no está pendiente');
        }

        transaction.update(ordenRef, {
          'tecnicoId': tecnicoId,
          'tecnicoNombre': tecnico.data()['nombre'],
          'estado': 'Asignado',
          'fechaAsignacion': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Técnico asignado correctamente')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al asignar: $e')));
    } finally {
      if (mounted) {
        setState(() => asignando = false);
      }
    }
  }

  Color colorEstado(String estado) {
    switch (estado) {
      case 'Pendiente':
        return Colors.orange;
      case 'Asignado':
        return Colors.indigo;
      case 'En diagnóstico':
        return Colors.blue;
      case 'En mantenimiento':
        return Colors.purple;
      case 'Terminado':
        return Colors.green;
      case 'Entregado':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;

    if (usuario == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Administrar órdenes')),
        body: const Center(child: Text('Debes iniciar sesión')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Administrar órdenes')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db.collection('ordenes').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar órdenes: ${snapshot.error}'),
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
            return const Center(child: Text('No hay órdenes registradas'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ordenes.length,
            itemBuilder: (context, index) {
              final documento = ordenes[index];
              final orden = documento.data();

              final estado = orden['estado']?.toString() ?? 'Pendiente';

              final tecnico =
                  orden['tecnicoNombre']?.toString() ?? 'Sin asignar';

              final idCorto = documento.id.length > 8
                  ? documento.id.substring(0, 8)
                  : documento.id;

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Orden #$idCorto',
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

                      Chip(
                        label: Text(estado),
                        backgroundColor: colorEstado(
                          estado,
                        ).withValues(alpha: 0.2),
                        side: BorderSide(color: colorEstado(estado)),
                      ),

                      const SizedBox(height: 10),

                      Text('Técnico: $tecnico'),

                      const SizedBox(height: 15),

                      if (estado == 'Pendiente')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: asignando
                                ? null
                                : () => mostrarAsignacion(documento.id),
                            icon: const Icon(Icons.person_add),
                            label: const Text('Asignar técnico'),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
