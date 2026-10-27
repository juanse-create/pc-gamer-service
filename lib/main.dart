import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/admin/administrar_ordenes.dart';
import 'screens/admin/estadisticas.dart';
import 'screens/admin/gestionar_tecnicos.dart';
import 'screens/admin/gestionar_usuarios.dart';
import 'screens/auth/login_screen.dart' as auth;
import 'screens/cliente/mis_equipos.dart';
import 'screens/cliente/mis_ordenes.dart';
import 'screens/cliente/registrar_pc.dart';
import 'screens/cliente/solicitar_mantenimiento.dart';
import 'screens/tecnico/ordenes_tecnico.dart';
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

class HomeScreen extends StatelessWidget {
  final String rol;

  const HomeScreen({super.key, required this.rol});

  Future<void> _cerrarSesion(BuildContext context) async {
    await AuthService().cerrarSesion();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const auth.LoginScreen()),
      (route) => false,
    );
  }

  void _abrirPantalla(BuildContext context, Widget pantalla) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));
  }

  Widget _opcion(
    BuildContext context,
    String titulo,
    IconData icono,
    Widget pantalla,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icono, color: Colors.blueAccent),
        title: Text(titulo),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _abrirPantalla(context, pantalla),
      ),
    );
  }

  List<Widget> _opcionesPorRol(BuildContext context) {
    switch (rol) {
      case 'Técnico':
        return [
          _opcion(
            context,
            'Órdenes asignadas',
            Icons.assignment,
            const OrdenesTecnico(modo: 'consultar'),
          ),
          _opcion(
            context,
            'Registrar diagnóstico',
            Icons.build,
            const OrdenesTecnico(modo: 'diagnostico'),
          ),
          _opcion(
            context,
            'Actualizar estado',
            Icons.update,
            const OrdenesTecnico(modo: 'estado'),
          ),
        ];

      case 'Administrador':
        return [
          _opcion(
            context,
            'Gestionar usuarios',
            Icons.people,
            const GestionarUsuarios(),
          ),
          _opcion(
            context,
            'Gestionar técnicos',
            Icons.engineering,
            const GestionarTecnicos(),
          ),
          _opcion(
            context,
            'Todas las órdenes',
            Icons.assignment,
            const AdministrarOrdenes(),
          ),
          _opcion(
            context,
            'Asignar técnico',
            Icons.person_add,
            const AdministrarOrdenes(),
          ),
          _opcion(
            context,
            'Estadísticas',
            Icons.bar_chart,
            const Estadisticas(),
          ),
        ];

      default:
        return [const ListTile(title: Text('Rol no reconocido'))];
    }
  }

  Widget _tarjetaCliente(
    BuildContext context, {
    required String titulo,
    required String descripcion,
    required IconData icono,
    required Color color,
    required Widget pantalla,
  }) {
    return Material(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _abrirPantalla(context, pantalla),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icono, color: color, size: 30),
              ),

              const Spacer(),

              Text(
                titulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                descripcion,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _panelCliente(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final anchoDisponible = constraints.maxWidth;

        final columnas = anchoDisponible >= 700 ? 3 : 2;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1D4ED8),
                    Color(0xFF1E40AF),
                    Color(0xFF172554),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.sports_esports, size: 45, color: Colors.white),

                  SizedBox(height: 18),

                  Text(
                    '¡Bienvenido a PC Gamer Service!',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: 10),

                  Text(
                    'Administra tus equipos y solicita '
                    'mantenimiento de forma rapida y sencilla.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              '¿Qué necesitas hacer?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'Selecciona una opción para continuar',
              style: TextStyle(fontSize: 14, color: Colors.white60),
            ),

            const SizedBox(height: 22),

            Material(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () =>
                    _abrirPantalla(context, const SolicitarMantenimiento()),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.build_circle,
                          size: 38,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(width: 16),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Solicitar mantenimiento',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),

                            SizedBox(height: 5),

                            Text(
                              'Solicita un servicio para tu PC',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            GridView.count(
              crossAxisCount: columnas,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: anchoDisponible >= 700 ? 1.5 : 0.95,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _tarjetaCliente(
                  context,
                  titulo: 'Mis equipos',
                  descripcion: 'Consulta tus PCs',
                  icono: Icons.devices,
                  color: Colors.cyanAccent,
                  pantalla: const MisEquipos(),
                ),

                _tarjetaCliente(
                  context,
                  titulo: 'Registrar PC',
                  descripcion: 'Agrega un equipo',
                  icono: Icons.computer,
                  color: Colors.greenAccent,
                  pantalla: const RegistrarPC(),
                ),

                _tarjetaCliente(
                  context,
                  titulo: 'Mis órdenes',
                  descripcion: 'Revisa tus solicitudes',
                  icono: Icons.assignment,
                  color: Colors.orangeAccent,
                  pantalla: const MisOrdenes(),
                ),
              ],
            ),

            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blueAccent),

                  SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      'Manten tus equipos en buen estado '
                      'con nuestros servicios de mantenimiento.',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(rol == 'Cliente' ? 'PC Gamer Service' : 'Panel de $rol'),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => _cerrarSesion(context),
          ),
        ],
      ),

      body: rol == 'Cliente'
          ? _panelCliente(context)
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Bienvenido, $rol',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 25),

                ..._opcionesPorRol(context),
              ],
            ),
    );
  }
}
