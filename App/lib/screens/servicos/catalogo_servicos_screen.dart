import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/servico.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../agendamentos/agendamento_form_screen.dart';

class CatalogoServicosScreen extends StatefulWidget {
  const CatalogoServicosScreen({super.key});

  @override
  State<CatalogoServicosScreen> createState() => _CatalogoServicosScreenState();
}

class _CatalogoServicosScreenState extends State<CatalogoServicosScreen> {
  List<Servico> _todos = [];
  List<Servico> _filtrados = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String? _filtroProfissional;
  List<String> _profissionais = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService.getServicos();
      final ativos = list.where((s) => s.status == 'ativo').toList();
      final profs = ativos
          .map((s) => s.profissionalNome)
          .whereType<String>()
          .toSet()
          .toList()
        ..sort();
      setState(() {
        _todos = ativos;
        _profissionais = profs;
        _aplicarFiltro();
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
        setState(() => _loading = false);
      }
    }
  }

  void _aplicarFiltro() {
    final query = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtrados = _todos.where((s) {
        final matchSearch = query.isEmpty ||
            s.descricao.toLowerCase().contains(query) ||
            (s.profissionalNome?.toLowerCase().contains(query) ?? false);
        final matchProf = _filtroProfissional == null ||
            s.profissionalNome == _filtroProfissional;
        return matchSearch && matchProf;
      }).toList();
    });
  }

  void _agendar(Servico s) {
    final auth = context.read<AuthProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AgendamentoFormScreen(
          modoCliente: true,
          idClientePre: auth.idVinculado,
          idProfissionalPre: s.idProfissional,
          idServicoPre: s.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Serviços Disponíveis'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          if (_profissionais.isNotEmpty)
            PopupMenuButton<String?>(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filtrar por profissional',
              onSelected: (v) {
                setState(() => _filtroProfissional = v);
                _aplicarFiltro();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: null, child: Text('Todos')),
                ..._profissionais.map(
                  (p) => PopupMenuItem(value: p, child: Text(p)),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _aplicarFiltro(),
              decoration: InputDecoration(
                hintText: 'Pesquisar serviço ou profissional…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _aplicarFiltro();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_filtroProfissional != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Chip(
                    label: Text(_filtroProfissional!),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() => _filtroProfissional = null);
                      _aplicarFiltro();
                    },
                    backgroundColor: Colors.teal.shade50,
                  ),
                ],
              ),
            ),
          // ── List ──────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _filtrados.isEmpty
                        ? const Center(
                            child: Text('Nenhum serviço encontrado.'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: _filtrados.length,
                            itemBuilder: (_, i) {
                              final s = _filtrados[i];
                              return _ServicoCard(
                                servico: s,
                                onAgendar: () => _agendar(s),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Card widget ──────────────────────────────────────────────────────────────

class _ServicoCard extends StatelessWidget {
  final Servico servico;
  final VoidCallback onAgendar;

  const _ServicoCard({required this.servico, required this.onAgendar});

  @override
  Widget build(BuildContext context) {
    final s = servico;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title row ─────────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.teal.withOpacity(0.12),
                  child: const Icon(Icons.spa, color: Colors.teal, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.descricao,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // ── Info chips ────────────────────────────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (s.valor != null)
                  _InfoChip(
                    icon: Icons.attach_money,
                    label: 'R\$ ${s.valor!.toStringAsFixed(2)}',
                    color: Colors.green,
                  ),
                if (s.duracaoMin != null)
                  _InfoChip(
                    icon: Icons.timer_outlined,
                    label: _fmtDuracao(s.duracaoMin!),
                    color: Colors.blue,
                  ),
                if (s.profissionalNome != null)
                  _InfoChip(
                    icon: Icons.person_outline,
                    label: s.profissionalNome!,
                    color: Colors.orange,
                  ),
              ],
            ),
            if (s.observacao != null && s.observacao!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                s.observacao!,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
            const SizedBox(height: 12),
            // ── Agendar button ────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAgendar,
                icon: const Icon(Icons.calendar_today, size: 18),
                label: const Text('Agendar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDuracao(int min) {
    if (min < 60) return '$min min';
    final h = min ~/ 60;
    final m = min % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
