import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../agendamentos/agendamentos_screen.dart';
import '../servicos/servicos_screen.dart';
import '../../models/profissional.dart';
import '../../services/api_service.dart';
import '../profissionais/horarios_profissional_screen.dart';
import 'edit_meu_perfil_prestador_screen.dart';

class PrestadorDashboardScreen extends StatefulWidget {
  const PrestadorDashboardScreen({super.key});

  @override
  State<PrestadorDashboardScreen> createState() =>
      _PrestadorDashboardScreenState();
}

class _PrestadorDashboardScreenState extends State<PrestadorDashboardScreen> {
  Profissional? _profissional;
  int _agendamentosHoje = 0;
  int _pendentesConfirmacao = 0;
  bool _loadingInfo = true;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final auth = context.read<AuthProvider>();
    final idVinculado = auth.idVinculado;
    if (idVinculado == null) {
      setState(() => _loadingInfo = false);
      return;
    }
    try {
      final profs = await ApiService.getProfissionais();
      final prof = profs.where((p) => p.id == idVinculado).firstOrNull;

      final hoje = DateTime.now();
      final dataStr =
          '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';
      final results = await Future.wait([
        ApiService.getAgendamentos(idProfissional: idVinculado, data: dataStr),
        ApiService.getAgendamentos(
            idProfissional: idVinculado, status: 'aguardando_confirmacao'),
      ]);

      if (mounted) {
        setState(() {
          _profissional = prof;
          _agendamentosHoje = results[0].length;
          _pendentesConfirmacao = results[1].length;
          _loadingInfo = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingInfo = false);
    }
  }

  void _navigate(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nomeUsuario = auth.usuario?['nome'] as String? ?? 'Profissional';
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
              'Olá, $nomeUsuario${_profissional?.especialidade != null ? ' • ${_profissional!.especialidade}' : ''}',
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
                  label: 'Minha Agenda',
                  color: const Color(0xFFF5A623),
                  badge:
                      _pendentesConfirmacao > 0 ? _pendentesConfirmacao : null,
                  onTap: idVinculado == null
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AgendamentosScreen(),
                              settings: RouteSettings(
                                  arguments: {'idProfissional': idVinculado}),
                            ),
                          ).then((_) => _loadInfo()),
                ),
                _MenuCard(
                  icon: Icons.content_cut,
                  label: 'Meus Serviços',
                  color: const Color(0xFF5BA08A),
                  onTap: idVinculado == null
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ServicosScreen(),
                              settings: RouteSettings(
                                  arguments: {'idProfissional': idVinculado}),
                            ),
                          ),
                ),
                _MenuCard(
                  icon: Icons.schedule,
                  label: 'Horários de Atendimento',
                  color: const Color(0xFF7B6FAB),
                  onTap: _profissional == null
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HorariosProfissionalScreen(
                                  profissional: _profissional!),
                            ),
                          ),
                ),
                _MenuCard(
                  icon: Icons.manage_accounts,
                  label: 'Meu Perfil',
                  color: const Color(0xFF4A90A4),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EditMeuPerfilPrestadorScreen()),
                  ).then((updated) {
                    if (updated == true) _loadInfo();
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card widget (mesmo padrão do HomeScreen) ─────────────────────────────────

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final int? badge;

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Stack(
          children: [
            Center(
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
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
