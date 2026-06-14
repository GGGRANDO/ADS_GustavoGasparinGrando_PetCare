import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../servicos/catalogo_servicos_screen.dart';
import '../profissionais/profissionais_catalogo_screen.dart';
import '../agendamentos/agendamentos_screen.dart';
import '../agendamentos/agendamento_form_screen.dart';

class ClienteDashboardScreen extends StatefulWidget {
  const ClienteDashboardScreen({super.key});

  @override
  State<ClienteDashboardScreen> createState() => _ClienteDashboardScreenState();
}

class _ClienteDashboardScreenState extends State<ClienteDashboardScreen> {
  int _agendamentosHoje = 0;
  int _agendamentosPendentes = 0;
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
      final hoje = DateTime.now();
      final dataStr =
          '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';
      final results = await Future.wait([
        ApiService.getAgendamentos(idCliente: idVinculado, data: dataStr),
        ApiService.getAgendamentos(idCliente: idVinculado, status: 'agendado'),
      ]);
      if (mounted) {
        setState(() {
          _agendamentosHoje = results[0].length;
          _agendamentosPendentes = results[1].length;
          _loadingInfo = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingInfo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nome = auth.usuario?['nome'] as String? ?? 'Cliente';
    final idVinculado = auth.idVinculado;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('PetCare'),
        backgroundColor: Colors.teal,
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
            // ── Header ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.teal,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: _loadingInfo
                  ? const SizedBox(
                      height: 80,
                      child: Center(
                          child:
                              CircularProgressIndicator(color: Colors.white)))
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white,
                          child: Text(
                            nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.teal,
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
                                'Olá, $nome!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _StatBadge(
                                    label: 'Hoje',
                                    value: '$_agendamentosHoje',
                                    icon: Icons.today,
                                  ),
                                  const SizedBox(width: 10),
                                  _StatBadge(
                                    label: 'Pendentes',
                                    value: '$_agendamentosPendentes',
                                    icon: Icons.pending_actions,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),
            // ── Modules ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'O que você precisa?',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  // ── Novo Agendamento (destaque) ────────────────────
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    color: Colors.teal,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AgendamentoFormScreen(
                            modoCliente: true,
                            idClientePre: idVinculado,
                          ),
                        ),
                      ).then((_) => _loadInfo()),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.white24,
                              child: Icon(Icons.add_circle_outline,
                                  color: Colors.white, size: 28),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Novo Agendamento',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(height: 2),
                                  Text('Agende um serviço para seu pet',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 13)),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.white70),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DashTile(
                    icon: Icons.spa,
                    color: Colors.purple,
                    title: 'Serviços Disponíveis',
                    subtitle: 'Veja preços, duração e agende diretamente',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CatalogoServicosScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DashTile(
                    icon: Icons.badge,
                    color: Colors.orange,
                    title: 'Profissionais',
                    subtitle: 'Encontre o profissional ideal',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProfissionaisCatalogoScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DashTile(
                    icon: Icons.calendar_month,
                    color: Colors.teal,
                    title: 'Meus Agendamentos',
                    subtitle: 'Histórico e próximas visitas',
                    onTap: idVinculado == null
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AgendamentosScreen(),
                                settings: RouteSettings(
                                  arguments: {'idCliente': idVinculado},
                                ),
                              ),
                            ).then((_) => _loadInfo()),
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

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatBadge(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 4),
          Text('$value $label',
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

class _DashTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _DashTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onTap,
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
