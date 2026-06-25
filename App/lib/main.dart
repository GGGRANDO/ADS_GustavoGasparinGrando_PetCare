import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/clientes/clientes_screen.dart';
import 'screens/profissionais/profissionais_screen.dart';
import 'screens/servicos/servicos_screen.dart';
import 'screens/profissionais/profissionais_catalogo_screen.dart';
import 'screens/agendamentos/agendamentos_screen.dart';
import 'screens/prestador/prestador_dashboard_screen.dart';
import 'screens/cliente/cliente_dashboard_screen.dart';
import 'screens/servicos/catalogo_servicos_screen.dart';
import 'screens/servicos/categorias_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const PetCareApp(),
    ),
  );
}

class PetCareApp extends StatelessWidget {
  const PetCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetCare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90A4),
          primary: const Color(0xFF4A90A4),
          secondary: const Color(0xFFF5A623),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4A90A4),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF4A90A4),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A90A4),
            foregroundColor: Colors.white,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF4A90A4),
            foregroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: const OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: const Color(0xFF4A90A4), width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.black87),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/home': (_) => const HomeScreen(),
        '/clientes': (_) => const ClientesScreen(),
        '/profissionais': (_) => const ProfissionaisScreen(),
        '/servicos': (_) => const ServicosScreen(),
        '/agendamentos': (_) => const AgendamentosScreen(),
        '/profissionais-catalogo': (_) => const ProfissionaisCatalogoScreen(),
        '/prestador-dashboard': (_) => const PrestadorDashboardScreen(),
        '/cliente-dashboard': (_) => const ClienteDashboardScreen(),
        '/servicos-catalogo': (_) => const CatalogoServicosScreen(),
        '/categorias': (_) => const CategoriasScreen(),
      },
      // Redirect to /home if already logged in
      onGenerateRoute: (settings) {
        if (settings.name == '/login') {
          return MaterialPageRoute(builder: (_) => const _AuthGate());
        }
        return null;
      },
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isLoggedIn) {
      if (auth.perfil == 'profissional') {
        return const PrestadorDashboardScreen();
      }
      if (auth.perfil == 'cliente') {
        return const ClienteDashboardScreen();
      }
      return const HomeScreen();
    }
    return const LoginScreen();
  }
}
