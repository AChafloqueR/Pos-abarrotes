import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'core/theme.dart';
import 'screens/apertura_caja_screen.dart';
import 'screens/login_screen.dart';
import 'state/carrito_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!AppConfig.isConfigured) {
    // Falla rápido y con un mensaje claro en vez de un error críptico más
    // adelante — típico olvido al clonar el repo por primera vez.
    runApp(const _ConfiguracionFaltanteApp());
    return;
  }

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  runApp(const PosAbarrotesApp());
}

class PosAbarrotesApp extends StatelessWidget {
  const PosAbarrotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CarritoProvider(),
      child: MaterialApp(
        title: 'POS Abarrotes',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const _RaizSesion(),
      ),
    );
  }
}

/// Decide la pantalla inicial según si ya hay una sesión de Supabase activa.
class _RaizSesion extends StatelessWidget {
  const _RaizSesion();

  @override
  Widget build(BuildContext context) {
    final sesion = Supabase.instance.client.auth.currentSession;
    return sesion != null ? const AperturaCajaScreen() : const LoginScreen();
  }
}

class _ConfiguracionFaltanteApp extends StatelessWidget {
  const _ConfiguracionFaltanteApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Falta configurar SUPABASE_URL y SUPABASE_ANON_KEY.\n\n'
              'Crea mobile/env.json (ver mobile/.env.example) y ejecuta:\n'
              'flutter run --dart-define-from-file=env.json',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
