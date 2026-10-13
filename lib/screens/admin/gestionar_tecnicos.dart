import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GestionarTecnicos extends StatelessWidget {
  const GestionarTecnicos({super.key});

  String idCorto(String id) {
    return id.length > 8 ? id.substring(0, 8) : id;
  }

  // ==========================================
  // MOSTRAR ÓRDENES DE UN TÉCNICO
  // ==========================================

  void mostrarOrdenes(BuildContext context, String tecnicoId, String nombre) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _OrdenesDeTecnico(tecnicoId: tecnicoId, nombre: nombre),
      ),
    );
  }

  // ==========================================
  // TARJETA DE TÉCNICO
  // ==========================================

  Widget tarjetaTecnico(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> documento,
  ) {
    final tecnico = documento.data();

    final nombre = tecnico['nombre']?.toString() ?? 'Sin nombre';
    final correo = tecnico['email']?.toString() ?? 'Sin correo';
    final activo = tecnico['activo'] == true;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('ordenes')
          .where('tecnicoId', isEqualTo: documento.id)
          .snapshots(),
      builder: (context, snapshot) {
        final ordenes = snapshot.data?.docs ?? [];

        final total = ordenes.length;

        final activas = ordenes.where((orden) {
          final estado = orden.data()['estado'];

          return estado != 'Terminado' && estado != 'Entregado';
        }).length;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(activo ? Icons.engineering : Icons.person_off),
            ),
            title: Text(
              nombre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(correo),
                const SizedBox(height: 4),
                Text(
                  activo ? 'Activo' : 'Desactivado',
                  style: TextStyle(color: activo ? Colors.green : Colors.red),
                ),
                const SizedBox(height: 4),
                if (snapshot.hasError)
                  const Text('Error al cargar órdenes')
                else if (!snapshot.hasData)
                  const Text('Cargando órdenes...')
                else ...[
                  Text('Órdenes totales: $total'),
                  Text('Órdenes activas: $activas'),
                ],
              ],
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              mostrarOrdenes(context, documento.id, nombre);
            },
          ),
        );
      },
    );
  }

  // ==========================================
  // PANTALLA PRINCIPAL
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar técnicos')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .where('rol', isEqualTo: 'tecnico')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar técnicos: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tecnicos = snapshot.data!.docs.toList();

          tecnicos.sort((a, b) {
            final nombreA = a.data()['nombre']?.toString() ?? '';
            final nombreB = b.data()['nombre']?.toString() ?? '';

            return nombreA.compareTo(nombreB);
          });

          if (tecnicos.isEmpty) {
            return const Center(
              child: Text('Todavía no hay técnicos registrados en Firebase.'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Técnicos registrados en Firebase',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Total de técnicos: ${tecnicos.length}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),

              ...tecnicos.map(
                (documento) => tarjetaTecnico(context, documento),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ==========================================
// ÓRDENES ASIGNADAS A UN TÉCNICO
// ==========================================

class _OrdenesDeTecnico extends StatelessWidget {
  final String tecnicoId;
  final String nombre;

  const _OrdenesDeTecnico({required this.tecnicoId, required this.nombre});

  String idCorto(String id) {
    return id.length > 8 ? id.substring(0, 8) : id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Órdenes de $nombre')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('ordenes')
            .where('tecnicoId', isEqualTo: tecnicoId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar órdenes: ${snapshot.error}',
                textAlign: TextAlign.center,
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
            return const Center(
              child: Text('Este técnico no tiene órdenes asignadas'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ordenes.length,
            itemBuilder: (context, index) {
              final documento = ordenes[index];
              final orden = documento.data();

              final diagnostico = orden['diagnostico']?.toString() ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Orden #${idCorto(documento.id)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('PC: ${orden['nombreEquipo'] ?? ''}'),
                      Text('Servicio: ${orden['tipoServicio'] ?? ''}'),
                      Text('Problema: ${orden['descripcion'] ?? ''}'),
                      const Divider(),
                      Text('Estado: ${orden['estado'] ?? ''}'),
                      const SizedBox(height: 6),
                      Text(
                        'Diagnóstico: ${diagnostico.isEmpty ? 'Sin registrar' : diagnostico}',
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
