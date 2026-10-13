import 'package:flutter/material.dart';
import 'screens/cliente/registrar_pc.dart';
import 'screens/cliente/mis_equipos.dart';
import 'screens/cliente/solicitar_mantenimiento.dart';
import 'screens/cliente/mis_ordenes.dart';
import 'screens/admin/administrar_ordenes.dart';
import 'screens/tecnico/ordenes_tecnico.dart';
import 'screens/admin/estadisticas.dart';
import 'screens/admin/gestionar_tecnicos.dart';
import 'screens/admin/gestionar_usuarios.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart' as auth;
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const PCGamerApp());
}

class PCGamerApp extends StatelessWidget {
  const PCGamerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PC Gamer Service',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const auth.LoginScreen(),
    );
  }
}

// PANTALLA PRINCIPAL POR ROL
class HomeScreen extends StatelessWidget {
  final String rol;

  const HomeScreen({super.key, required this.rol});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Panel de $rol'),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().cerrarSesion();

              if (!context.mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const auth.LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Bienvenido, $rol',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 25),

          if (rol == 'Cliente') ...[
            _opcion(context, 'Mis equipos', Icons.devices),
            _opcion(context, 'Registrar PC', Icons.computer),
            _opcion(context, 'Solicitar mantenimiento', Icons.build_circle),
            _opcion(context, 'Mis órdenes', Icons.list_alt),
          ],

          if (rol == 'Técnico') ...[
            _opcion(context, 'Órdenes asignadas', Icons.assignment),
            _opcion(context, 'Registrar diagnóstico', Icons.build),
            _opcion(context, 'Actualizar estado', Icons.update),
          ],

          if (rol == 'Administrador') ...[
            _opcion(context, 'Gestionar usuarios', Icons.people),
            _opcion(context, 'Gestionar técnicos', Icons.engineering),
            _opcion(context, 'Todas las órdenes', Icons.assignment),
            _opcion(context, 'Asignar técnico', Icons.person_add),
            _opcion(context, 'Estadísticas', Icons.bar_chart),
          ],
        ],
      ),
    );
  }

  Widget _opcion(BuildContext context, String titulo, IconData icono) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icono, color: Colors.blueAccent),
        title: Text(titulo),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          if (titulo == 'Registrar PC') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegistrarPC()),
            );
          } else if (titulo == 'Mis equipos') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MisEquipos()),
            );
          } else if (titulo == 'Solicitar mantenimiento') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SolicitarMantenimiento()),
            );
          } else if (titulo == 'Mis órdenes') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MisOrdenes()),
            );
          } else if (titulo == 'Todas las órdenes' ||
              titulo == 'Asignar técnico') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdministrarOrdenes()),
            );
          } else if (titulo == 'Órdenes asignadas') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OrdenesTecnico(modo: 'consultar'),
              ),
            );
          } else if (titulo == 'Registrar diagnóstico') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OrdenesTecnico(modo: 'diagnostico'),
              ),
            );
          } else if (titulo == 'Actualizar estado') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const OrdenesTecnico(modo: 'estado'),
              ),
            );
          } else if (titulo == 'Estadísticas') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Estadisticas()),
            );
          } else if (titulo == 'Gestionar técnicos') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GestionarTecnicos()),
            );
          } else if (titulo == 'Gestionar usuarios') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GestionarUsuarios()),
            );
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Próximamente: $titulo')));
          }
        },
      ),
    );
  }
}
