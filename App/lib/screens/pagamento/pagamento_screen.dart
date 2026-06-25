import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/agendamento.dart';
import '../../models/pagamento.dart';
import '../../services/api_service.dart';

class PagamentoScreen extends StatefulWidget {
  final Agendamento agendamento;

  const PagamentoScreen({super.key, required this.agendamento});

  @override
  State<PagamentoScreen> createState() => _PagamentoScreenState();
}

class _PagamentoScreenState extends State<PagamentoScreen> {
  List<Pagamento> _pagamentos = [];
  bool _loading = true;
  bool _criando = false;
  String _formaSelecionada = 'PIX';

  static const _formas = [
    'PIX',
    'BOLETO',
    'CREDIT_CARD',
    'DINHEIRO',
    'TRANSFERENCIA'
  ];
  static const _formasLabel = {
    'PIX': 'PIX',
    'BOLETO': 'Boleto',
    'CREDIT_CARD': 'Cartão de Crédito',
    'DINHEIRO': 'Dinheiro',
    'TRANSFERENCIA': 'Transferência',
  };

  static const _statusColors = {
    'PENDING': Colors.orange,
    'RECEIVED': Colors.green,
    'CONFIRMED': Colors.green,
    'OVERDUE': Colors.red,
    'REFUNDED': Colors.purple,
    'CANCELLED': Colors.grey,
    'RECEIVED_IN_CASH': Colors.green,
    'REFUND_REQUESTED': Colors.purple,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list =
          await ApiService.getPagamentosAgendamento(widget.agendamento.id!);
      setState(() => _pagamentos = list);
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

  Future<void> _refreshPagamento(Pagamento p) async {
    try {
      final updated = await ApiService.getPagamento(p.id!);
      setState(() {
        final idx = _pagamentos.indexWhere((x) => x.id == p.id);
        if (idx != -1) _pagamentos[idx] = updated;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _criarCobranca() async {
    setState(() => _criando = true);
    try {
      final novo = await ApiService.criarPagamento(
          widget.agendamento.id!, _formaSelecionada);
      setState(() => _pagamentos.insert(0, novo));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cobrança gerada com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      setState(() => _criando = false);
    }
  }

  Future<void> _cancelarCobranca(Pagamento p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar cobrança'),
        content: const Text('Deseja cancelar esta cobrança?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Não')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sim')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ApiService.cancelarPagamento(p.id!);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cobrança cancelada.')),
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

  Widget _buildFormaSelector() {
    return DropdownButtonFormField<String>(
      value: _formaSelecionada,
      decoration: const InputDecoration(
        labelText: 'Forma de pagamento',
        border: OutlineInputBorder(),
      ),
      items: _formas
          .map((f) => DropdownMenuItem(
                value: f,
                child: Text(_formasLabel[f]!),
              ))
          .toList(),
      onChanged: (v) => setState(() => _formaSelecionada = v!),
    );
  }

  Widget _buildPagamentoCard(Pagamento p) {
    final color = _statusColors[p.status] ?? Colors.blueGrey;
    final hasPix = p.formaPagamento == 'PIX' && p.pixCopiaCola != null;
    final hasBoleto = p.linkBoleto != null;
    final hasFatura = p.linkFatura != null;
    final canCancel = p.status != 'CANCELLED' &&
        p.status != 'RECEIVED' &&
        p.status != 'CONFIRMED';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formasLabel[p.formaPagamento] ?? p.formaPagamento,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text(
                    p.statusLabel,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: color,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'R\$ ${p.valor.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            // PIX Copia e Cola
            if (hasPix) ...[
              const Divider(),
              const Text('PIX Copia e Cola',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  p.pixCopiaCola!,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar código PIX'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: p.pixCopiaCola!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Código PIX copiado!')),
                    );
                  },
                ),
              ),
            ],

            // Boleto link
            if (hasBoleto) ...[
              const Divider(),
              Text('Boleto: ${p.linkBoleto}',
                  style: const TextStyle(fontSize: 12)),
            ],

            // Fatura link
            if (hasFatura) ...[
              if (!hasBoleto) const Divider(),
              Text('Link da fatura: ${p.linkFatura}',
                  style: const TextStyle(fontSize: 12)),
            ],

            // Action buttons
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Atualizar'),
                  onPressed: () => _refreshPagamento(p),
                ),
                const SizedBox(width: 8),
                if (canCancel)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.cancel, size: 18, color: Colors.red),
                    label: const Text('Cancelar',
                        style: TextStyle(color: Colors.red)),
                    onPressed: () => _cancelarCobranca(p),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasActivePayment = _pagamentos.any((p) =>
        p.status != 'CANCELLED' &&
        p.status != 'REFUNDED' &&
        p.status != 'OVERDUE');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagamento'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Appointment summary card
                  Card(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.agendamento.servicoDescricao ??
                                'Serviço #${widget.agendamento.idServico}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                              'Cliente: ${widget.agendamento.clienteNome ?? widget.agendamento.idCliente}'),
                          Text(
                              'Data: ${widget.agendamento.dataAtendimento}  ${widget.agendamento.horario}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Block payment when appointment not confirmed
                  if (widget.agendamento.status != 'confirmado') ...[
                    Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: Colors.orange),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.agendamento.status ==
                                        'aguardando_confirmacao'
                                    ? 'Aguardando confirmação do profissional. O pagamento só pode ser gerado após a confirmação.'
                                    : 'O agendamento precisa estar confirmado para gerar cobrança.',
                                style: const TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // New charge form (only if no active payment AND appointment is confirmed)
                  if (!hasActivePayment &&
                      widget.agendamento.status == 'confirmado') ...[
                    const Text('Gerar nova cobrança',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildFormaSelector(),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: _criando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.payment),
                        label: const Text('Gerar cobrança'),
                        onPressed: _criando ? null : _criarCobranca,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Existing payments list
                  if (_pagamentos.isNotEmpty) ...[
                    const Text('Cobranças',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    ..._pagamentos.map(_buildPagamentoCard),
                  ] else if (!_loading && hasActivePayment == false) ...[
                    const Center(
                      child: Text('Nenhuma cobrança gerada ainda.',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
