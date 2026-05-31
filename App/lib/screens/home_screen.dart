import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final usuario = auth.usuario;
    final perfil = auth.perfil;

    final cards = _cardsParaPerfil(perfil, auth.idVinculado);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PetCare'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.teal.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              'Olá, ${usuario?['nome'] ?? ''}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(20),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: cards,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _cardsParaPerfil(String perfil, int? idVinculado) {
    if (perfil == 'cliente') {
      return [
        _MenuCard(
          icon: Icons.badge,
          label: 'Profissionais',
          route: '/profissionais-catalogo',
          color: Colors.orange,
        ),
        _MenuCard(
          icon: Icons.calendar_month,
          label: 'Meus Agendamentos',
          route: '/agendamentos',
          color: Colors.teal,
          arguments: {'idCliente': idVinculado},
        ),
      ];
    }

    if (perfil == 'profissional') {
      return [
        _MenuCard(
          icon: Icons.calendar_month,
          label: 'Meus Agendamentos',
          route: '/agendamentos',
          color: Colors.teal,
          arguments: {'idProfissional': idVinculado},
        ),
      ];
    }

    // admin / atendente — todos os módulos
    return const [
      _MenuCard(
        icon: Icons.people,
        label: 'Clientes',
        route: '/clientes',
        color: Colors.blue,
      ),
      _MenuCard(
        icon: Icons.badge,
        label: 'Profissionais',
        route: '/profissionais',
        color: Colors.orange,
      ),
      _MenuCard(
        icon: Icons.miscellaneous_services,
        label: 'Serviços',
        route: '/servicos',
        color: Colors.purple,
      ),
      _MenuCard(
        icon: Icons.calendar_month,
        label: 'Agendamentos',
        route: '/agendamentos',
        color: Colors.teal,
      ),
    ];
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final Color color;
  final Object? arguments;

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
    this.arguments,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            Navigator.of(context).pushNamed(route, arguments: arguments),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
