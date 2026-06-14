import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../agendamentos/agendamentos_screen.dart';
import '../profissionais/horarios_profissional_screen.dart';
import '../servicos/servicos_screen.dart';
import '../../models/profissional.dart';
import '../../services/api_service.dart';

class PrestadorDashboardScreen extends StatefulWidget {
  const PrestadorDashboardScreen({super.key});

  @override
  State<PrestadorDashboardScreen> createState() =>
      _PrestadorDashboardScreenState();
}

class _PrestadorDashboardScreenState extends State<PrestadorDashboardScreen> {
  Profissional? _profissional;
  int _agendamentosHoje = 0;
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
      final agendamentos = await ApiService.getAgendamentos(
        idProfissional: idVinculado,
        data: dataStr,
      );

      if (mounted) {
        setState(() {
          _profissional = prof;
          _agendamentosHoje = agendamentos.length;
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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Meu Painel'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
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
      body: RefreshIndicator(
        onRefresh: _loadInfo,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: _loadingInfo
                  ? const SizedBox(
                      height: 80,
                      child: Center(
                          child:
                              CircularProgressIndicator(color: Colors.white)),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white,
                          child: Text(
                            nomeUsuario.isNotEmpty
                                ? nomeUsuario[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Olá, $nomeUsuario',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_profissional?.especialidade != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _profissional!.especialidade!,
                                  style: TextStyle(
                                      color: Colors.orange.shade100,
                                      fontSize: 14),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$_agendamentosHoje agendamento${_agendamentosHoje == 1 ? '' : 's'} hoje',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),
            // ── Menu tiles ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Módulos',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  _DashTile(
                    icon: Icons.calendar_month,
                    color: Colors.teal,
                    title: 'Minha Agenda',
                    subtitle: 'Veja e gerencie seus agendamentos',
                    onTap: idVinculado == null
                        ? null
                        : () => _navigate(const AgendamentosScreen()),
                    args: idVinculado != null
                        ? {'idProfissional': idVinculado}
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _DashTile(
                    icon: Icons.spa,
                    color: Colors.purple,
                    title: 'Meus Serviços',
                    subtitle: 'Cadastre serviços, preços e duração',
                    onTap: idVinculado == null
                        ? null
                        : () => Navigator.pushNamed(
                              context,
                              '/servicos',
                              arguments: {'idProfissional': idVinculado},
                            ),
                  ),
                  const SizedBox(height: 12),
                  _DashTile(
                    icon: Icons.schedule,
                    color: Colors.orange.shade700,
                    title: 'Horários de Atendimento',
                    subtitle: 'Configure dias e horários de trabalho',
                    onTap: (_profissional == null)
                        ? null
                        : () => _navigate(
                              HorariosProfissionalScreen(
                                  profissional: _profissional!),
                            ),
                  ),
                  const SizedBox(height: 12),
                  _DashTile(
                    icon: Icons.person_outline,
                    color: Colors.blue,
                    title: 'Meu Perfil',
                    subtitle: 'Edite suas informações e especialidade',
                    onTap: () => Navigator.pushNamed(context, '/profissionais'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── Tile widget ─────────────────────────────────────────────────────────────

class _DashTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Map<String, dynamic>? args;

  const _DashTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.args,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
