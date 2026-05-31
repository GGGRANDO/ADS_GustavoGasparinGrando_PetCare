import 'package:flutter/material.dart';
import '../../models/profissional.dart';
import '../../services/api_service.dart';

class ProfissionaisCatalogoScreen extends StatefulWidget {
  const ProfissionaisCatalogoScreen({super.key});

  @override
  State<ProfissionaisCatalogoScreen> createState() =>
      _ProfissionaisCatalogoScreenState();
}

class _ProfissionaisCatalogoScreenState
    extends State<ProfissionaisCatalogoScreen> {
  List<Profissional> _lista = [];
  List<Profissional> _listaFiltrada = [];
  bool _loading = true;
  String? _filtroEspecialidade;
  List<String> _especialidades = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService.getProfissionais();
      final ativos = list.where((p) => p.status == 'ativo').toList();
      final especialidades = ativos
          .map((p) => p.especialidade)
          .whereType<String>()
          .toSet()
          .toList()
        ..sort();
      setState(() {
        _lista = ativos;
        _especialidades = especialidades;
        _aplicarFiltro();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  void _aplicarFiltro() {
    if (_filtroEspecialidade == null) {
      _listaFiltrada = _lista;
    } else {
      _listaFiltrada =
          _lista.where((p) => p.especialidade == _filtroEspecialidade).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profissionais Disponíveis'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar por especialidade',
            onSelected: (v) {
              setState(() {
                _filtroEspecialidade = v;
                _aplicarFiltro();
              });
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('Todas')),
              ..._especialidades.map(
                (e) => PopupMenuItem(value: e, child: Text(e)),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _listaFiltrada.isEmpty
                  ? const Center(child: Text('Nenhum profissional disponível.'))
                  : ListView.builder(
                      itemCount: _listaFiltrada.length,
                      itemBuilder: (_, i) {
                        final p = _listaFiltrada[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange.withOpacity(0.15),
                              child: const Icon(Icons.person,
                                  color: Colors.orange),
                            ),
                            title: Text(p.nome,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (p.especialidade != null)
                                  Text('Especialidade: ${p.especialidade}'),
                                if (p.telefone != null)
                                  Text('Telefone: ${p.telefone}'),
                                if (p.disponibilidade != null)
                                  Text('Disponibilidade: ${p.disponibilidade}'),
                              ],
                            ),
                            isThreeLine: p.especialidade != null &&
                                p.disponibilidade != null,
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
