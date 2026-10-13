import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GestionarUsuarios extends StatelessWidget {
  const GestionarUsuarios({super.key});

  // ==========================================
  // CONFIGURACIÓN VISUAL POR ROL
  // ==========================================

  IconData iconoRol(String rol) {
    switch (rol) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'tecnico':
        return Icons.engineering;
      case 'cliente':
        return Icons.person;
      default:
        return Icons.person_outline;
    }
  }

  Color colorRol(String rol) {
    switch (rol) {
      case 'admin':
        return Colors.purple;
      case 'tecnico':
        return Colors.orange;
      case 'cliente':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String nombreRol(String rol) {
    switch (rol) {
      case 'admin':
        return 'Administrador';
      case 'tecnico':
        return 'Técnico';
      case 'cliente':
        return 'Cliente';
      default:
        return 'Sin rol';
    }
  }

  // ==========================================
  // EDITAR USUARIO
  // ==========================================

  Future<void> editarUsuario(
    BuildContext context,
    String uid,
    Map<String, dynamic> usuario,
  ) async {
    final nombreActual = usuario['nombre']?.toString() ?? '';

    final activoActual = usuario['activo'] == true;

    final resultado = await showDialog<_CambiosUsuario>(
      context: context,
      builder: (_) => _DialogoEditarUsuario(
        nombreActual: nombreActual,
        activoActual: activoActual,
      ),
    );

    if (resultado == null || !context.mounted) return;

    final cambios = <String, dynamic>{};

    if (resultado.nombre != nombreActual) {
      cambios['nombre'] = resultado.nombre;
    }

    if (resultado.activo != activoActual) {
      cambios['activo'] = resultado.activo;
    }

    if (cambios.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .update(cambios);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario actualizado correctamente')),
      );
    } on FirebaseException catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo actualizar el usuario: ${e.message ?? e.code}',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // ==========================================
  // TARJETA DE USUARIO
  // ==========================================

  Widget tarjetaUsuario(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> documento,
  ) {
    final usuario = documento.data();

    final nombre = usuario['nombre']?.toString() ?? 'Sin nombre';

    final email = usuario['email']?.toString() ?? 'Sin correo';

    final rol = usuario['rol']?.toString() ?? '';

    final activo = usuario['activo'] == true;

    final color = colorRol(rol);

    final esUsuarioActual =
        FirebaseAuth.instance.currentUser?.uid == documento.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(iconoRol(rol), color: color),
        ),
        title: Text(
          nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text(email),
            Text('Rol: ${nombreRol(rol)}'),
            const SizedBox(height: 5),
            Text(
              activo ? 'Activo' : 'Desactivado',
              style: TextStyle(
                color: activo ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (esUsuarioActual)
              const Text(
                'Tu cuenta',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          tooltip: 'Editar usuario',
          onPressed: () {
            editarUsuario(context, documento.id, usuario);
          },
        ),
      ),
    );
  }

  // ==========================================
  // PANTALLA PRINCIPAL
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar usuarios')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error al cargar usuarios: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final usuarios = snapshot.data!.docs.toList();

          usuarios.sort((a, b) {
            final nombreA = a.data()['nombre']?.toString() ?? '';
            final nombreB = b.data()['nombre']?.toString() ?? '';

            return nombreA.toLowerCase().compareTo(nombreB.toLowerCase());
          });

          final clientes = usuarios
              .where((doc) => doc.data()['rol'] == 'cliente')
              .length;

          final tecnicos = usuarios
              .where((doc) => doc.data()['rol'] == 'tecnico')
              .length;

          final administradores = usuarios
              .where((doc) => doc.data()['rol'] == 'admin')
              .length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Usuarios registrados',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text(
                'Información actualizada desde Firebase',
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 20),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total de usuarios: ${usuarios.length}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Clientes: $clientes'),
                      Text('Técnicos: $tecnicos'),
                      Text('Administradores: $administradores'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              if (usuarios.isEmpty)
                const Center(child: Text('No hay usuarios registrados.'))
              else
                ...usuarios.map(
                  (documento) => tarjetaUsuario(context, documento),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ==========================================
// RESULTADO DEL DIÁLOGO
// ==========================================

class _CambiosUsuario {
  final String nombre;
  final bool activo;

  const _CambiosUsuario({required this.nombre, required this.activo});
}

// ==========================================
// DIÁLOGO PARA EDITAR USUARIO
// ==========================================

class _DialogoEditarUsuario extends StatefulWidget {
  final String nombreActual;
  final bool activoActual;

  const _DialogoEditarUsuario({
    required this.nombreActual,
    required this.activoActual,
  });

  @override
  State<_DialogoEditarUsuario> createState() => _DialogoEditarUsuarioState();
}

class _DialogoEditarUsuarioState extends State<_DialogoEditarUsuario> {
  late final TextEditingController nombreController;
  late bool activo;

  @override
  void initState() {
    super.initState();

    nombreController = TextEditingController(text: widget.nombreActual);

    activo = widget.activoActual;
  }

  @override
  void dispose() {
    nombreController.dispose();
    super.dispose();
  }

  void guardar() {
    final nombre = nombreController.text.trim();

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre no puede estar vacío')),
      );
      return;
    }

    Navigator.pop(context, _CambiosUsuario(nombre: nombre, activo: activo));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar usuario'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreController,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Usuario activo'),
              value: activo,
              onChanged: (valor) {
                setState(() {
                  activo = valor;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: guardar, child: const Text('Guardar')),
      ],
    );
  }
}
