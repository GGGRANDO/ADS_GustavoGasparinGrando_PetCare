import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../servicos/catalogo_servicos_screen.dart';
import '../profissionais/profissionais_catalogo_screen.dart';
import '../agendamentos/agendamentos_screen.dart';
import '../agendamentos/agendamento_form_screen.dart';
import 'edit_perfil_screen.dart';

class ClienteDashboardScreen extends StatefulWidget {
  const ClienteDashboardScreen({super.key});

  @override
  State<ClienteDashboardScreen> createState() => _ClienteDashboardScreenState();
}

class _ClienteDashboardScreenState extends State<ClienteDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nome = auth.usuario?['nome'] as String? ?? 'Cliente';
    final idVinculado = auth.idVinculado;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PetCare'),
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
            color: const Color(0xFF4A90A4).withOpacity(0.08),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              'Olá, $nome!',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(20),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _MenuCard(
                  icon: Icons.event_available,
                  label: 'Novo Agendamento',
                  color: const Color(0xFFF5A623),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AgendamentoFormScreen(
                        modoCliente: true,
                        idClientePre: idVinculado,
                      ),
                    ),
                  ),
                ),
                _MenuCard(
                  icon: Icons.pets,
                  label: 'Meus Agendamentos',
                  color: const Color(0xFF4A90A4),
                  onTap: idVinculado == null
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AgendamentosScreen(),
                              settings: RouteSettings(
                                  arguments: {'idCliente': idVinculado}),
                            ),
                          ),
                ),
                _MenuCard(
                  icon: Icons.medical_services_outlined,
                  label: 'Serviços',
                  color: const Color(0xFF7B6FAB),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CatalogoServicosScreen()),
                  ),
                ),
                _MenuCard(
                  icon: Icons.content_cut,
                  label: 'Profissionais',
                  color: const Color(0xFF5BA08A),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProfissionaisCatalogoScreen()),
                  ),
                ),
                _MenuCard(
                  icon: Icons.manage_accounts,
                  label: 'Meu Perfil',
                  color: const Color(0xFF4A90A4),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditPerfilScreen()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card widget (mesmo padrão do HomeScreen / PrestadorDashboard) ────────────

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
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
