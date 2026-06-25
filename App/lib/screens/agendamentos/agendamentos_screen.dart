import 'package:flutter/material.dart';
import '../../models/agendamento.dart';
import '../../services/api_service.dart';
import 'agendamento_form_screen.dart';

class AgendamentosScreen extends StatefulWidget {
  const AgendamentosScreen({super.key});

  @override
  State<AgendamentosScreen> createState() => _AgendamentosScreenState();
}

class _AgendamentosScreenState extends State<AgendamentosScreen> {
  List<Agendamento> _lista = [];
  bool _loading = true;
  String? _filtroStatus;

  int? _idCliente;
  int? _idProfissional;
  bool _isClienteView = false;
  bool _isPrestadorView = false;

  static const _statusColors = {
    'aguardando_confirmacao': Colors.orange,
    'confirmado': Colors.blue,
    'cancelado': Colors.red,
    'concluido': Colors.grey,
    'agendado': Colors.blue,
  };

  static const _statusLabels = {
    'aguardando_confirmacao': 'Aguardando',
    'confirmado': 'Confirmado',
    'cancelado': 'Cancelado',
    'concluido': 'Concluído',
    'agendado': 'Agendado',
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _idCliente = args['idCliente'] as int?;
      _idProfissional = args['idProfissional'] as int?;
      _isClienteView = _idCliente != null;
      _isPrestadorView = _idProfissional != null;
    }
    if (_lista.isEmpty) _load();
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

  Future<void> _confirmar(Agendamento a) async {
    try {
      await ApiService.confirmarAgendamento(a.id!);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Agendamento confirmado! O cliente receberá um e-mail.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _recusar(Agendamento a) async {
    final motivoCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Recusar agendamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Informe o motivo (opcional):'),
            const SizedBox(height: 8),
            TextField(
              controller: motivoCtrl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ex.: Horário não disponível',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Voltar')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Recusar', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ApiService.recusarAgendamento(a.id!,
          motivo:
              motivoCtrl.text.trim().isEmpty ? null : motivoCtrl.text.trim());
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agendamento recusado.')),
        );
      }
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

  Widget _buildTrailing(Agendamento a) {
    final color = _statusColors[a.status] ?? Colors.blueGrey;
    final label = _statusLabels[a.status] ?? a.status;

    // Prestador: botões confirmar/recusar para pendentes
    if (_isPrestadorView && a.status == 'aguardando_confirmacao') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green),
            tooltip: 'Confirmar',
            onPressed: () => _confirmar(a),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red),
            tooltip: 'Recusar',
            onPressed: () => _recusar(a),
          ),
        ],
      );
    }

    // Cliente ou prestador (outros status): só chip
    if (_isClienteView || _isPrestadorView) {
      return Chip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        backgroundColor: color.withOpacity(0.15),
      );
    }

    // Admin: popup com todas as ações
    return PopupMenuButton<String>(
      icon: Chip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        backgroundColor: color.withOpacity(0.15),
      ),
      onSelected: (v) {
        switch (v) {
          case '_edit':
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AgendamentoFormScreen(agendamento: a)),
            ).then((_) => _load());
          case '_delete':
            _delete(a);
          case '_confirmar':
            _confirmar(a);
          case '_recusar':
            _recusar(a);
          default:
            _updateStatus(a, v);
        }
      },
      itemBuilder: (_) => [
        if (a.status == 'aguardando_confirmacao') ...[
          const PopupMenuItem(
              value: '_confirmar',
              child: Row(children: [
                Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                SizedBox(width: 8),
                Text('Confirmar'),
              ])),
          const PopupMenuItem(
              value: '_recusar',
              child: Row(children: [
                Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
                SizedBox(width: 8),
                Text('Recusar'),
              ])),
          const PopupMenuDivider(),
        ],
        if (a.status == 'confirmado') ...[
          const PopupMenuItem(value: 'concluido', child: Text('Concluir')),
        ],
        const PopupMenuItem(value: 'cancelado', child: Text('Cancelar')),
        const PopupMenuDivider(),
        const PopupMenuItem(value: '_edit', child: Text('Editar')),
        const PopupMenuItem(value: '_delete', child: Text('Excluir')),
      ],
    );
  }

  Widget? _buildPendenteBanner() {
    if (!_isPrestadorView) return null;
    final n = _lista.where((a) => a.status == 'aguardando_confirmacao').length;
    if (n == 0) return null;
    return Container(
      width: double.infinity,
      color: Colors.orange.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.pending_actions, color: Colors.orange),
          const SizedBox(width: 8),
          Text(
            '$n agendamento${n == 1 ? '' : 's'} aguardando sua confirmação',
            style: const TextStyle(
                color: Colors.orange, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendamentos'),
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
              const PopupMenuItem(
                  value: 'aguardando_confirmacao',
                  child: Text('Aguardando confirmação')),
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
              child: Column(
                children: [
                  if (_buildPendenteBanner() != null) _buildPendenteBanner()!,
                  Expanded(
                    child: _lista.isEmpty
                        ? const Center(
                            child: Text('Nenhum agendamento encontrado.'))
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
                                    child: Icon(Icons.calendar_today,
                                        color: color),
                                  ),
                                  title: Text(a.clienteNome ??
                                      'Cliente #${a.idCliente}'),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      if (a.motivoCancelamento != null)
                                        Text(
                                          'Motivo: ${a.motivoCancelamento}',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.red.shade700),
                                        ),
                                    ],
                                  ),
                                  isThreeLine: true,
                                  trailing: _buildTrailing(a),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: (_isClienteView || _isPrestadorView)
          ? null
          : FloatingActionButton(
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
