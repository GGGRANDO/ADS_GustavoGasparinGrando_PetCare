import 'package:flutter/material.dart';
import '../../models/agendamento.dart';
import '../../services/api_service.dart';
import 'agendamento_form_screen.dart';
import '../pagamento/pagamento_screen.dart';

class AgendamentosScreen extends StatefulWidget {
  const AgendamentosScreen({super.key});

  @override
  State<AgendamentosScreen> createState() => _AgendamentosScreenState();
}

class _AgendamentosScreenState extends State<AgendamentosScreen> {
  List<Agendamento> _lista = [];
  bool _loading = true;
  String? _filtroStatus;

  // argumentos injetados via Navigator (home_screen)
  int? _idCliente;
  int? _idProfissional;
  bool _somenteLeitura = false;

  static const _statusColors = {
    'agendado': Colors.blue,
    'confirmado': Colors.green,
    'cancelado': Colors.red,
    'concluido': Colors.grey,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _idCliente = args['idCliente'] as int?;
      _idProfissional = args['idProfissional'] as int?;
      _somenteLeitura = _idCliente != null || _idProfissional != null;
    }
    if (_lista.isEmpty) _load();
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService.getAgendamentos(
        status: _filtroStatus,
        idCliente: _idCliente,
        idProfissional: _idProfissional,
      );
      setState(() => _lista = list);
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

  Future<void> _updateStatus(Agendamento a, String novoStatus) async {
    try {
      await ApiService.updateAgendamento(Agendamento(
        id: a.id,
        idCliente: a.idCliente,
        idProfissional: a.idProfissional,
        idServico: a.idServico,
        dataAtendimento: a.dataAtendimento,
        horario: a.horario,
        status: novoStatus,
        observacao: a.observacao,
      ));
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _delete(Agendamento a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir agendamento'),
        content: const Text('Deseja excluir este agendamento?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.deleteAgendamento(a.id!);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendamentos'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar por status',
            onSelected: (v) {
              setState(() => _filtroStatus = v);
              _load();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('Todos')),
              const PopupMenuItem(value: 'agendado', child: Text('Agendado')),
              const PopupMenuItem(
                  value: 'confirmado', child: Text('Confirmado')),
              const PopupMenuItem(value: 'cancelado', child: Text('Cancelado')),
              const PopupMenuItem(value: 'concluido', child: Text('Concluído')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _lista.isEmpty
                  ? const Center(child: Text('Nenhum agendamento encontrado.'))
                  : ListView.builder(
                      itemCount: _lista.length,
                      itemBuilder: (_, i) {
                        final a = _lista[i];
                        final color =
                            _statusColors[a.status] ?? Colors.blueGrey;
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withOpacity(0.15),
                              child: Icon(Icons.calendar_today, color: color),
                            ),
                            title: Text(
                                a.clienteNome ?? 'Cliente #${a.idCliente}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${a.dataAtendimento.substring(0, 10)}  ${a.horario.substring(0, 5)}',
                                ),
                                Text(
                                  a.servicoDescricao ??
                                      'Serviço #${a.idServico}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  a.profissionalNome ??
                                      'Prof. #${a.idProfissional}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: _somenteLeitura
                                ? Chip(
                                    label: Text(a.status,
                                        style: const TextStyle(fontSize: 11)),
                                    backgroundColor: color.withOpacity(0.15),
                                  )
                                : PopupMenuButton<String>(
                                    icon: Chip(
                                      label: Text(a.status,
                                          style: const TextStyle(fontSize: 11)),
                                      backgroundColor: color.withOpacity(0.15),
                                    ),
                                    onSelected: (v) {
                                      if (v == '_edit') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  AgendamentoFormScreen(
                                                      agendamento: a)),
                                        ).then((_) => _load());
                                      } else if (v == '_delete') {
                                        _delete(a);
                                      } else if (v == '_pagamento') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => PagamentoScreen(
                                                  agendamento: a)),
                                        );
                                      } else {
                                        _updateStatus(a, v);
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(
                                          value: 'confirmado',
                                          child: Text('Confirmar')),
                                      const PopupMenuItem(
                                          value: 'concluido',
                                          child: Text('Concluir')),
                                      const PopupMenuItem(
                                          value: 'cancelado',
                                          child: Text('Cancelar')),
                                      const PopupMenuDivider(),
                                      const PopupMenuItem(
                                          value: '_pagamento',
                                          child: Row(
                                            children: [
                                              Icon(Icons.payment, size: 18),
                                              SizedBox(width: 8),
                                              Text('Pagamento'),
                                            ],
                                          )),
                                      const PopupMenuDivider(),
                                      const PopupMenuItem(
                                          value: '_edit',
                                          child: Text('Editar')),
                                      const PopupMenuItem(
                                          value: '_delete',
                                          child: Text('Excluir')),
                                    ],
                                  ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: _somenteLeitura
          ? null
          : FloatingActionButton(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AgendamentoFormScreen()),
                );
                _load();
              },
              child: const Icon(Icons.add),
            ),
    );
  }
}
